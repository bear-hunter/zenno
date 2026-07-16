import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/focus_tables.dart';
import 'package:zenno/features/focus/application/focus_providers.dart';
import 'package:zenno/features/focus/application/focus_wakelock_service.dart';
import 'package:zenno/features/focus/domain/focus_session_config.dart';
import 'package:zenno/features/focus/domain/timer_engine.dart';
import 'package:zenno/features/settings/application/settings_providers.dart';

part 'active_session_controller.g.dart';

/// Injectable wall clock for deterministic active-session controller tests.
typedef FocusClock = DateTime Function();

/// Injectable clock for deterministic active-session controller tests.
@Riverpod(keepAlive: true)
FocusClock focusClock(Ref ref) =>
    () => DateTime.now().toUtc();

/// The live state of an in-progress focus session, as the Active screen and
/// the global shell pill render it.
///
/// Wraps the engine [snapshot] with the persisted session id and the original
/// [config]. `null` for [sessionId] means no session is running.
class ActiveSessionState {
  /// Creates an active-session state.
  const ActiveSessionState({
    required this.sessionId,
    required this.startedAt,
    required this.config,
    required this.snapshot,
    this.reviewPending = false,
    this.isRestoring = false,
  });

  /// The "no session running" state.
  static const ActiveSessionState none = ActiveSessionState(
    sessionId: null,
    startedAt: null,
    config: null,
    snapshot: null,
  );

  /// Startup state while persisted live/review-pending work is being checked.
  static const ActiveSessionState restoring = ActiveSessionState(
    sessionId: null,
    startedAt: null,
    config: null,
    snapshot: null,
    isRestoring: true,
  );

  /// Id of the `focus_sessions` row, or `null` when nothing is running.
  final String? sessionId;

  /// Session wall-clock start time, used for distraction timing.
  final DateTime? startedAt;

  /// The configuration the running session was started with.
  final FocusSessionConfig? config;

  /// The latest timer-engine snapshot, or `null` when nothing is running.
  final TimerSnapshot? snapshot;

  /// Whether the timer is finished and the post-session Review is still due.
  final bool reviewPending;

  /// Whether startup restoration is still reading the database.
  final bool isRestoring;

  /// Whether a session is currently active (running, paused, or just-ended but
  /// not yet reviewed).
  bool get hasSession => sessionId != null;
}

/// Owns the [TimerEngine] for the one in-progress focus session and persists
/// that session's lifecycle.
///
/// `keepAlive` so the timer keeps running across navigation — the user can
/// leave the Active screen, browse a canvas, and return without losing time.
/// A `Timer.periodic` at 1 Hz only drives UI repaint: it pushes a fresh
/// [ActiveSessionState] each second and lets a Pomodoro engine auto-advance
/// work↔break. Because [TimerEngine] is wall-clock correct, a stalled or
/// throttled ticker never corrupts elapsed time — the next emission is still
/// accurate. The ticker is suspended while the app is backgrounded or the
/// session is paused, then reconciled immediately when foreground work resumes.
///
/// DB writes are deliberately sparse: the opening row at start, a tally write
/// on each phase transition and on finish/abandon. The reactive
/// `focusHistoryProvider` picks those up automatically.
@Riverpod(keepAlive: true)
class ActiveSessionController extends _$ActiveSessionController
    with WidgetsBindingObserver {
  TimerEngine? _engine;
  Timer? _ticker;
  bool _starting = false;
  Future<void> _restoreFuture = Future<void>.value();
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  int _secondsSinceRuntimePersist = 0;

  @override
  ActiveSessionState build() {
    final wakelockService = ref.read(focusWakelockServiceProvider);
    _appLifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    // The ticker holds a resource; tear it down if the provider is ever
    // disposed (it is keepAlive, so in practice only at app shutdown).
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _stopTicker();
      unawaited(
        wakelockService.setEnabled(false).catchError((Object error) {
          debugPrint('Could not disable focus wakelock: $error');
        }),
      );
    });
    _restoreFuture = Future<void>.microtask(_restoreAtStartup);
    return ActiveSessionState.restoring;
  }

  bool get _isForeground => _appLifecycleState == AppLifecycleState.resumed;

  /// Exposes resource state only so lifecycle regressions can be tested.
  @visibleForTesting
  bool get debugTickerActive => _ticker?.isActive ?? false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasForeground = _isForeground;
    _appLifecycleState = state;
    if (wasForeground == _isForeground) return;

    if (_isForeground) {
      unawaited(_resumeForegroundResources());
    } else {
      _stopTicker();
      unawaited(_suspendForegroundResources());
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Starts a session from [config]: writes the opening `focus_sessions` row,
  /// snapshots the ritual, builds and starts the [TimerEngine], and begins the
  /// 1 Hz ticker.
  ///
  /// [checkedRitualItems] is the ritual as it stood on the Setup screen — each
  /// `(itemId, label, wasChecked)` tuple is snapshotted verbatim. A session
  /// already in progress is left untouched.
  Future<bool> startFrom(
    FocusSessionConfig config, {
    required List<({String itemId, String label, bool wasChecked})>
    checkedRitualItems,
  }) async {
    await _restoreFuture;
    if (state.hasSession || _starting) return false;
    _starting = true;

    try {
      final repo = ref.read(focusRepositoryProvider);
      final timerKind = config.mode == TimerMode.pomodoro
          ? TimerKind.pomodoro
          : TimerKind.flowmodoro;
      final startedAt = ref.read(focusClockProvider)();

      final sessionId = await repo.createSession(
        startedAt: startedAt,
        goalText: config.goalText,
        preEnergy: config.preEnergy,
        timerKind: timerKind,
        plannedDurationSecs: config.plannedDuration.inSeconds,
        pomodoroWorkSecs: config.mode == TimerMode.pomodoro
            ? config.pomodoroWork.inSeconds
            : null,
        pomodoroBreakSecs: config.mode == TimerMode.pomodoro
            ? config.pomodoroBreak.inSeconds
            : null,
        flowBreakRatio: config.mode == TimerMode.flowmodoro
            ? config.flowBreakRatio
            : null,
        linkedCanvasId: config.linkedCanvasId,
        ritualItems: checkedRitualItems,
      );

      final engine = _buildEngine(config)..start();
      _engine = engine;

      state = ActiveSessionState(
        sessionId: sessionId,
        startedAt: startedAt,
        config: config,
        snapshot: engine.snapshot(),
      );
      _startTicker();
      try {
        await _syncWakelockWithSettings();
      } catch (error) {
        debugPrint('Could not enable focus wakelock: $error');
      }
      try {
        await _persistRuntime();
      } catch (error) {
        debugPrint('Could not persist initial focus runtime: $error');
      }
      return true;
    } finally {
      _starting = false;
    }
  }

  /// Pauses the running timer.
  Future<void> pause() async {
    _engine?.pause();
    _stopTicker();
    _emit();
    await _persistRuntime();
  }

  /// Resumes the paused timer.
  Future<void> resume() async {
    _engine?.resume();
    _emit();
    _startTicker();
    await _persistRuntime();
  }

  /// Ends the current Flowmodoro work stretch and starts a proportional break.
  ///
  /// A no-op for a Pomodoro session. The new cycle tally is persisted.
  Future<void> endStretch() async {
    _engine?.endStretch();
    _emit();
    await _persistRuntime();
  }

  /// Skips the current break and starts the next work phase.
  Future<void> skipBreak() async {
    _engine?.skipBreak();
    _emit();
    await _persistRuntime();
  }

  /// Records a distraction against the running session.
  ///
  /// [elapsedSecs] defaults to the session's current accumulated focus time —
  /// "how far in" the capture happened — but the caller may override it.
  Future<void> captureDistraction({
    required DistractionKind kind,
    required String note,
    int? elapsedSecs,
  }) async {
    final sessionId = state.sessionId;
    final engine = _engine;
    if (sessionId == null || engine == null) return;

    final startedAt = state.startedAt;
    final now = ref.read(focusClockProvider)();
    final wallSecs = startedAt == null
        ? engine.accumulatedFocus.inSeconds
        : now.difference(startedAt).inSeconds;

    await ref
        .read(focusRepositoryProvider)
        .addDistraction(
          sessionId: sessionId,
          capturedAt: now,
          kind: kind,
          note: note,
          elapsedSecs: elapsedSecs ?? wallSecs.clamp(0, 1 << 31),
        );
  }

  /// Stops the timer and closes the session row with the given lifecycle
  /// [status].
  ///
  /// - [FocusSessionStatus.reviewPending] (the default) is used when the user
  ///   finishes normally and proceeds to the Review screen — the controller
  ///   keeps holding the session id so Review can attach the post-energy
  ///   rating and note via [submitReview].
  /// - [FocusSessionStatus.abandoned] is used when the user quits early; the
  ///   row is closed immediately and the controller is cleared.
  ///
  /// Either way the engine banks any in-progress work time before stopping, so
  /// `actual_focus_secs` reflects the focus actually done.
  Future<void> stop({
    FocusSessionStatus status = FocusSessionStatus.reviewPending,
  }) async {
    final sessionId = state.sessionId;
    final engine = _engine;
    if (sessionId == null || engine == null) return;

    if (status == FocusSessionStatus.abandoned) {
      engine.abandon();
    } else {
      engine.finish();
    }
    _stopTicker();
    _emit();

    await ref
        .read(focusRepositoryProvider)
        .finishSession(
          sessionId: sessionId,
          endedAt: ref.read(focusClockProvider)(),
          status: status,
          actualFocusSecs: engine.accumulatedFocus.inSeconds,
          cyclesCompleted: engine.cyclesCompleted,
        );

    // An abandoned session has no Review step — clear the controller now.
    // A finished session keeps its state so the Review screen can use it.
    if (status == FocusSessionStatus.abandoned) {
      _clear();
      await _disableWakelockBestEffort();
    } else {
      state = ActiveSessionState(
        sessionId: state.sessionId,
        startedAt: state.startedAt,
        config: state.config,
        snapshot: engine.snapshot(),
        reviewPending: true,
      );
      await _disableWakelockBestEffort();
    }
  }

  /// Persists the post-session Review (`post_energy`, optional `notes`), marks
  /// the session [FocusSessionStatus.completed], and clears the controller.
  ///
  /// Called from the Review screen after the user has already [stop]ped the
  /// timer. A no-op if there is no held session.
  Future<void> submitReview({required int postEnergy, String? notes}) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;

    await ref
        .read(focusRepositoryProvider)
        .completeReview(
          sessionId: sessionId,
          postEnergy: postEnergy.clamp(1, 5),
          notes: (notes != null && notes.trim().isEmpty) ? null : notes?.trim(),
        );
    _clear();
    await _disableWakelockBestEffort();
  }

  /// Discards the held session without writing a Review.
  ///
  /// Used if the user backs out of the Review screen — the session row is
  /// already closed by [stop]; this just releases the controller so a new
  /// session can begin.
  Future<void> discard() async {
    final sessionId = state.sessionId;
    if (sessionId != null && state.reviewPending) {
      await ref.read(focusRepositoryProvider).discardReview(sessionId);
    }
    _clear();
    await _disableWakelockBestEffort();
  }

  // ---------------------------------------------------------------------------
  // Ticker
  // ---------------------------------------------------------------------------

  void _startTicker() {
    if (!_isForeground || _engine?.status != TimerStatus.running) return;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// The 1 Hz repaint tick. For a Pomodoro engine it also lets the engine
  /// self-advance work↔break when a phase target is reached, persisting the
  /// new cycle tally on a transition.
  Future<void> _onTick() async {
    final engine = _engine;
    if (!_isForeground || engine == null) return;
    if (engine.status != TimerStatus.running) return;
    final advanced = engine.advanceIfPhaseComplete();
    _emit();
    _secondsSinceRuntimePersist += 1;
    if (advanced || _secondsSinceRuntimePersist >= 15) {
      try {
        await _persistRuntime();
      } catch (error) {
        // Keep the wall-clock timer alive and retry on the next tick. The
        // counter resets only after a successful write.
        debugPrint('Could not checkpoint focus runtime: $error');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _suspendForegroundResources() async {
    try {
      await _persistRuntime();
    } catch (error) {
      debugPrint('Could not checkpoint focus runtime in background: $error');
    }
    await _disableWakelockBestEffort();
  }

  Future<void> _resumeForegroundResources() async {
    await _onTick();
    if (!_isForeground) return;
    _startTicker();
    try {
      await _syncWakelockWithSettings();
    } catch (error) {
      debugPrint('Could not restore focus wakelock in foreground: $error');
    }
  }

  /// Pushes a fresh [ActiveSessionState] from the current engine snapshot.
  void _emit() {
    final engine = _engine;
    if (engine == null) return;
    state = ActiveSessionState(
      sessionId: state.sessionId,
      startedAt: state.startedAt,
      config: state.config,
      snapshot: engine.snapshot(),
      reviewPending: state.reviewPending,
    );
  }

  Future<void> _persistRuntime() async {
    final sessionId = state.sessionId;
    final engine = _engine;
    if (sessionId == null || engine == null) return;
    final actualFocusSecs = engine.accumulatedFocus.inSeconds;
    await ref
        .read(focusRepositoryProvider)
        .updateRuntime(
          sessionId: sessionId,
          runtime: engine.runtimeSnapshot,
          actualFocusSecs: actualFocusSecs,
        );
    _secondsSinceRuntimePersist = 0;
  }

  Future<void> _restoreLatestInProgressSession() async {
    if (state.hasSession) return;
    final repository = ref.read(focusRepositoryProvider);
    final session = await repository.readLatestInProgressSession();
    if (session == null) {
      final pending = await repository.readPendingReviewSession();
      if (pending != null && !state.hasSession) {
        _restorePendingReview(pending);
      }
      return;
    }
    if (state.hasSession) return;

    final config = _configFromSession(session);
    final runtime = _runtimeFromSession(session);
    final engine = TimerEngine.fromRuntime(
      mode: config.mode,
      runtime: runtime,
      clock: ref.read(focusClockProvider),
      pomodoroWork: config.pomodoroWork,
      pomodoroBreak: config.pomodoroBreak,
      flowBreakRatio: config.flowBreakRatio,
    );
    _engine = engine;
    state = ActiveSessionState(
      sessionId: session.id,
      startedAt: session.startedAt,
      config: config,
      snapshot: engine.snapshot(),
    );
    _startTicker();
    try {
      await _syncWakelockWithSettings();
    } catch (error) {
      debugPrint('Could not restore focus wakelock: $error');
    }
    try {
      await _persistRuntime();
    } catch (error) {
      debugPrint('Could not persist restored focus runtime: $error');
    }
  }

  Future<void> _restoreAtStartup() async {
    try {
      await _restoreLatestInProgressSession();
    } finally {
      if (state.isRestoring) state = ActiveSessionState.none;
    }
  }

  void _restorePendingReview(FocusSession session) {
    final config = _configFromSession(session);
    state = ActiveSessionState(
      sessionId: session.id,
      startedAt: session.startedAt,
      config: config,
      snapshot: TimerSnapshot(
        status: TimerStatus.finished,
        phase: TimerPhase.work,
        mode: config.mode,
        elapsed: Duration(seconds: session.actualFocusSecs),
        remaining: Duration.zero,
        target: config.mode == TimerMode.pomodoro ? config.pomodoroWork : null,
        cyclesCompleted: session.cyclesCompleted,
        accumulatedFocus: Duration(seconds: session.actualFocusSecs),
      ),
      reviewPending: true,
    );
  }

  Future<void> _syncWakelockWithSettings() async {
    if (!_isForeground || !state.hasSession || state.reviewPending) {
      await _setWakelock(false);
      return;
    }
    final settings = await ref.read(settingsRepositoryProvider).readSettings();
    await _setWakelock(
      _isForeground && state.hasSession && !state.reviewPending
          ? settings.keepScreenOnInFocus
          : false,
    );
  }

  Future<void> _setWakelock(bool enabled) {
    return ref.read(focusWakelockServiceProvider).setEnabled(enabled);
  }

  Future<void> _disableWakelockBestEffort() async {
    try {
      await _setWakelock(false);
    } catch (error) {
      debugPrint('Could not disable focus wakelock: $error');
    }
  }

  TimerEngine _buildEngine(FocusSessionConfig config) {
    return TimerEngine(
      mode: config.mode,
      clock: ref.read(focusClockProvider),
      pomodoroWork: config.pomodoroWork,
      pomodoroBreak: config.pomodoroBreak,
      flowBreakRatio: config.flowBreakRatio,
    );
  }

  FocusSessionConfig _configFromSession(FocusSession session) {
    return FocusSessionConfig(
      mode: session.timerKind == TimerKind.pomodoro
          ? TimerMode.pomodoro
          : TimerMode.flowmodoro,
      goalText: session.goalText,
      preEnergy: session.preEnergy,
      plannedDuration: Duration(seconds: session.plannedDurationSecs),
      pomodoroWork: Duration(seconds: session.pomodoroWorkSecs ?? 1500),
      pomodoroBreak: Duration(seconds: session.pomodoroBreakSecs ?? 300),
      flowBreakRatio: session.flowBreakRatio ?? 0.2,
      linkedCanvasId: session.linkedCanvasId,
    );
  }

  TimerEngineRuntimeSnapshot _runtimeFromSession(FocusSession session) {
    final hasPersistedRuntime = session.runtimeStatus != null;
    final status = _enumAt(
      TimerStatus.values,
      session.runtimeStatus,
      TimerStatus.paused,
    );
    final phase = _enumAt(
      TimerPhase.values,
      session.runtimePhase,
      TimerPhase.work,
    );
    final phaseTargetSecs =
        session.runtimePhaseTargetSecs ??
        (session.timerKind == TimerKind.pomodoro
            ? session.pomodoroWorkSecs
            : null);
    return TimerEngineRuntimeSnapshot(
      status: status == TimerStatus.idle ? TimerStatus.paused : status,
      phase: phase,
      phaseStartedAt: session.runtimePhaseStartedAt,
      carried: Duration(
        seconds: hasPersistedRuntime
            ? session.runtimeCarriedPhaseSecs
            : session.actualFocusSecs,
      ),
      phaseTarget: phaseTargetSecs == null
          ? null
          : Duration(seconds: phaseTargetSecs),
      bankedFocus: Duration(seconds: session.runtimeBankedFocusSecs),
      cyclesCompleted: session.cyclesCompleted,
    );
  }

  T _enumAt<T>(List<T> values, int? index, T fallback) {
    if (index == null || index < 0 || index >= values.length) {
      return fallback;
    }
    return values[index];
  }

  /// Tears down the timer and resets to [ActiveSessionState.none].
  void _clear() {
    _stopTicker();
    _engine = null;
    _secondsSinceRuntimePersist = 0;
    state = ActiveSessionState.none;
  }
}
