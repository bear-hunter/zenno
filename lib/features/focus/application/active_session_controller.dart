import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenno/core/database/tables/focus_tables.dart';
import 'package:zenno/features/focus/application/focus_providers.dart';
import 'package:zenno/features/focus/domain/focus_session_config.dart';
import 'package:zenno/features/focus/domain/timer_engine.dart';

part 'active_session_controller.g.dart';

/// The live state of an in-progress focus session, as the Active screen and
/// the global shell pill render it.
///
/// Wraps the engine [snapshot] with the persisted session id and the original
/// [config]. `null` for [sessionId] means no session is running.
class ActiveSessionState {
  /// Creates an active-session state.
  const ActiveSessionState({
    required this.sessionId,
    required this.config,
    required this.snapshot,
  });

  /// The "no session running" state.
  static const ActiveSessionState none = ActiveSessionState(
    sessionId: null,
    config: null,
    snapshot: null,
  );

  /// Id of the `focus_sessions` row, or `null` when nothing is running.
  final String? sessionId;

  /// The configuration the running session was started with.
  final FocusSessionConfig? config;

  /// The latest timer-engine snapshot, or `null` when nothing is running.
  final TimerSnapshot? snapshot;

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
/// accurate, which is also why no `AppLifecycleListener` reconciliation is
/// needed here.
///
/// DB writes are deliberately sparse: the opening row at start, a tally write
/// on each phase transition and on finish/abandon. The reactive
/// `focusHistoryProvider` picks those up automatically.
@Riverpod(keepAlive: true)
class ActiveSessionController extends _$ActiveSessionController {
  TimerEngine? _engine;
  Timer? _ticker;

  /// Seconds of `actual_focus_secs` last written to the DB — lets the tally
  /// write be skipped when nothing changed.
  int _lastPersistedFocusSecs = -1;

  @override
  ActiveSessionState build() {
    // The ticker holds a resource; tear it down if the provider is ever
    // disposed (it is keepAlive, so in practice only at app shutdown).
    ref.onDispose(_stopTicker);
    return ActiveSessionState.none;
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
  Future<void> startFrom(
    FocusSessionConfig config, {
    required List<({String itemId, String label, bool wasChecked})>
    checkedRitualItems,
  }) async {
    if (state.hasSession) return;

    final repo = ref.read(focusRepositoryProvider);
    final timerKind = config.mode == TimerMode.pomodoro
        ? TimerKind.pomodoro
        : TimerKind.flowmodoro;

    final sessionId = await repo.createSession(
      startedAt: DateTime.now().toUtc(),
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
    );

    await repo.snapshotRitualChecks(
      sessionId: sessionId,
      items: checkedRitualItems,
    );

    final engine = config.buildEngine()..start();
    _engine = engine;
    _lastPersistedFocusSecs = 0;

    state = ActiveSessionState(
      sessionId: sessionId,
      config: config,
      snapshot: engine.snapshot(),
    );
    _startTicker();
  }

  /// Pauses the running timer.
  void pause() {
    _engine?.pause();
    _emit();
  }

  /// Resumes the paused timer.
  void resume() {
    _engine?.resume();
    _emit();
  }

  /// Ends the current Flowmodoro work stretch and starts a proportional break.
  ///
  /// A no-op for a Pomodoro session. The new cycle tally is persisted.
  Future<void> endStretch() async {
    _engine?.endStretch();
    _emit();
    await _persistTally();
  }

  /// Skips the current break and starts the next work phase.
  void skipBreak() {
    _engine?.skipBreak();
    _emit();
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

    await ref
        .read(focusRepositoryProvider)
        .addDistraction(
          sessionId: sessionId,
          capturedAt: DateTime.now().toUtc(),
          kind: kind,
          note: note,
          elapsedSecs:
              elapsedSecs ?? engine.accumulatedFocus.inSeconds,
        );
  }

  /// Stops the timer and closes the session row with the given lifecycle
  /// [status].
  ///
  /// - [FocusSessionStatus.completed] (the default) is used when the user
  ///   finishes normally and proceeds to the Review screen — the controller
  ///   keeps holding the session id so Review can attach the post-energy
  ///   rating and note via [submitReview].
  /// - [FocusSessionStatus.abandoned] is used when the user quits early; the
  ///   row is closed immediately and the controller is cleared.
  ///
  /// Either way the engine banks any in-progress work time before stopping, so
  /// `actual_focus_secs` reflects the focus actually done.
  Future<void> stop({
    FocusSessionStatus status = FocusSessionStatus.completed,
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
          endedAt: DateTime.now().toUtc(),
          status: status,
          actualFocusSecs: engine.accumulatedFocus.inSeconds,
          cyclesCompleted: engine.cyclesCompleted,
        );

    // An abandoned session has no Review step — clear the controller now.
    // A finished session keeps its state so the Review screen can use it.
    if (status == FocusSessionStatus.abandoned) {
      _clear();
    }
  }

  /// Persists the post-session Review (`post_energy`, optional `notes`), marks
  /// the session [FocusSessionStatus.completed], and clears the controller.
  ///
  /// Called from the Review screen after the user has already [stop]ped the
  /// timer. A no-op if there is no held session.
  Future<void> submitReview({
    required int postEnergy,
    String? notes,
  }) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;

    await ref
        .read(focusRepositoryProvider)
        .completeReview(
          sessionId: sessionId,
          postEnergy: postEnergy.clamp(1, 5),
          notes: (notes != null && notes.trim().isEmpty)
              ? null
              : notes?.trim(),
        );
    _clear();
  }

  /// Discards the held session without writing a Review.
  ///
  /// Used if the user backs out of the Review screen — the session row is
  /// already closed by [stop]; this just releases the controller so a new
  /// session can begin.
  void discard() {
    _clear();
  }

  // ---------------------------------------------------------------------------
  // Ticker
  // ---------------------------------------------------------------------------

  void _startTicker() {
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
    if (engine == null) return;
    final advanced = engine.advanceIfPhaseComplete();
    _emit();
    if (advanced) {
      await _persistTally();
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Pushes a fresh [ActiveSessionState] from the current engine snapshot.
  void _emit() {
    final engine = _engine;
    if (engine == null) return;
    state = ActiveSessionState(
      sessionId: state.sessionId,
      config: state.config,
      snapshot: engine.snapshot(),
    );
  }

  /// Writes `actual_focus_secs` / `cycles_completed` to the DB if the focus
  /// tally has moved since the last write — cheap idempotent durability.
  Future<void> _persistTally() async {
    final sessionId = state.sessionId;
    final engine = _engine;
    if (sessionId == null || engine == null) return;

    final focusSecs = engine.accumulatedFocus.inSeconds;
    if (focusSecs == _lastPersistedFocusSecs) return;
    _lastPersistedFocusSecs = focusSecs;

    await ref
        .read(focusRepositoryProvider)
        .updateProgress(
          sessionId: sessionId,
          actualFocusSecs: focusSecs,
          cyclesCompleted: engine.cyclesCompleted,
        );
  }

  /// Tears down the timer and resets to [ActiveSessionState.none].
  void _clear() {
    _stopTicker();
    _engine = null;
    _lastPersistedFocusSecs = -1;
    state = ActiveSessionState.none;
  }
}
