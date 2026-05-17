// Pure Dart — no Flutter, no Drift. Unit-tested in
// `test/timer_engine_test.dart`.
import 'package:zenno/features/focus/domain/flowmodoro_calc.dart';

/// The high-level lifecycle state of a [TimerEngine].
enum TimerStatus {
  /// Created but not yet started — no phase is running.
  idle,

  /// A phase is actively counting (see [TimerPhase] for which one).
  running,

  /// A phase is suspended; elapsed time is frozen until [TimerEngine.resume].
  paused,

  /// The session ended normally via [TimerEngine.finish].
  finished,

  /// The session was ended early via [TimerEngine.abandon].
  abandoned,
}

/// Which kind of interval the engine is currently in.
enum TimerPhase {
  /// Focused study work — the only phase that accumulates `actual_focus_secs`.
  work,

  /// A rest interval between work phases.
  breakTime,
}

/// The timing model the engine runs.
///
/// Mirrors `TimerKind` on the `focus_sessions` table; kept as a separate
/// domain enum so this file stays free of any Drift import.
enum TimerMode {
  /// Fixed work / break intervals; work counts *down* from a set length.
  pomodoro,

  /// Open-ended work the user ends manually; the break is proportional to the
  /// stretch just completed and work counts *up*.
  flowmodoro,
}

/// An immutable, plain-value snapshot of a [TimerEngine] for the UI to render.
///
/// The UI never reads the engine's mutable internals directly — it asks for a
/// [snapshot] each repaint tick. Every field is already resolved against the
/// wall clock at the moment the snapshot was taken.
class TimerSnapshot {
  /// Creates a snapshot. All fields are required and pre-computed.
  const TimerSnapshot({
    required this.status,
    required this.phase,
    required this.mode,
    required this.elapsed,
    required this.remaining,
    required this.target,
    required this.cyclesCompleted,
    required this.accumulatedFocus,
  });

  /// High-level lifecycle state.
  final TimerStatus status;

  /// The interval kind currently in effect.
  final TimerPhase phase;

  /// The timing model in use.
  final TimerMode mode;

  /// Time spent in the *current* phase so far, wall-clock accurate.
  final Duration elapsed;

  /// Time left in the current phase, or [Duration.zero] for an open-ended
  /// Flowmodoro work phase (which has no fixed end).
  final Duration remaining;

  /// The intended length of the current phase, or `null` when the phase is
  /// open-ended (a Flowmodoro work stretch).
  final Duration? target;

  /// How many full work→break cycles have completed.
  final int cyclesCompleted;

  /// Total focused work time across the whole session (work phases only),
  /// including the in-progress phase if it is a work phase.
  final Duration accumulatedFocus;

  /// Whether the current fixed-length phase has run past its [target].
  ///
  /// Always `false` for an open-ended Flowmodoro work stretch.
  bool get isPhaseComplete {
    final t = target;
    if (t == null) return false;
    return elapsed >= t;
  }

  /// Whether a user could meaningfully start the timer right now.
  bool get isIdle => status == TimerStatus.idle;

  /// Whether the timer is actively counting.
  bool get isRunning => status == TimerStatus.running;

  /// Whether the timer is paused mid-phase.
  bool get isPaused => status == TimerStatus.paused;

  /// Whether the session has ended (either [TimerStatus.finished] or
  /// [TimerStatus.abandoned]).
  bool get isOver =>
      status == TimerStatus.finished || status == TimerStatus.abandoned;
}

/// A wall-clock-correct focus-session timer state machine.
///
/// ## Why wall-clock
/// Elapsed time is *always* computed as `clock() - phaseStartedAt + carried`,
/// never accumulated by an incrementing counter. A 1 Hz UI ticker only drives
/// repaint; if it stalls — the app is backgrounded, the screen sleeps, the
/// isolate is throttled — the next snapshot still reports the true elapsed
/// time. There is no drift to reconcile.
///
/// ## Lifecycle
/// ```
/// idle
///   └─ start ──▶ running(work) ⇄ pause/resume ⇄ paused(work)
///                   │
///                   ├─ (pomodoro) auto/skip when work target hit ──▶ break
///                   └─ (flowmodoro) endStretch ──▶ break
///                running(break) ⇄ pause/resume ⇄ paused(break)
///                   │
///                   └─ skipBreak / break target hit ──▶ running(work) …
///   any running/paused state ── finish ──▶ finished
///                            ── abandon ─▶ abandoned
/// ```
///
/// ## Clock injection
/// The constructor takes a [clock] callback (default [DateTime.now]). Tests
/// inject a fake clock to fast-forward time and to simulate "time jumps" that
/// model the device sleeping. The engine itself starts no timers and imports
/// no Flutter — driving repaint is the caller's job.
class TimerEngine {
  /// Creates an engine for the given [mode].
  ///
  /// Pomodoro requires [pomodoroWork] and [pomodoroBreak]. Flowmodoro requires
  /// [flowBreakRatio] (the proportion of a stretch granted as a break) and may
  /// override the break clamp via [flowBreakMin] / [flowBreakMax].
  ///
  /// [clock] is injectable for testing; production passes nothing.
  TimerEngine({
    required this.mode,
    DateTime Function() clock = DateTime.now,
    Duration pomodoroWork = const Duration(minutes: 25),
    Duration pomodoroBreak = const Duration(minutes: 5),
    double flowBreakRatio = 0.2,
    Duration flowBreakMin = const Duration(minutes: 2),
    Duration flowBreakMax = const Duration(minutes: 30),
  }) : _clock = clock,
       _pomodoroWork = pomodoroWork,
       _pomodoroBreak = pomodoroBreak,
       _flowBreakRatio = flowBreakRatio,
       _flowBreakMin = flowBreakMin,
       _flowBreakMax = flowBreakMax,
       assert(
         pomodoroWork > Duration.zero,
         'pomodoroWork must be positive',
       ),
       assert(
         pomodoroBreak > Duration.zero,
         'pomodoroBreak must be positive',
       ),
       assert(flowBreakRatio >= 0, 'flowBreakRatio must be non-negative');

  /// The timing model this engine runs.
  final TimerMode mode;

  final DateTime Function() _clock;
  final Duration _pomodoroWork;
  final Duration _pomodoroBreak;
  final double _flowBreakRatio;
  final Duration _flowBreakMin;
  final Duration _flowBreakMax;

  TimerStatus _status = TimerStatus.idle;
  TimerPhase _phase = TimerPhase.work;

  /// Wall-clock instant the current phase last (re)started running.
  ///
  /// `null` while [TimerStatus.idle]. On [pause] this is folded into
  /// [_carried] and cleared; on [resume] it is set fresh — so a pause never
  /// loses time and a resume never double-counts the paused interval.
  DateTime? _phaseStartedAt;

  /// Elapsed time in the current phase accumulated *before* the most recent
  /// running interval — i.e. the sum of all earlier run intervals of this
  /// phase, banked at each [pause].
  Duration _carried = Duration.zero;

  /// The intended length of the current phase. `null` for an open-ended
  /// Flowmodoro work stretch.
  Duration? _phaseTarget;

  int _cyclesCompleted = 0;

  /// Focused work time banked from *completed* work phases. The in-progress
  /// work phase is added on top in [accumulatedFocus].
  Duration _bankedFocus = Duration.zero;

  // ---------------------------------------------------------------------------
  // Read-only state
  // ---------------------------------------------------------------------------

  /// High-level lifecycle state.
  TimerStatus get status => _status;

  /// The interval kind currently in effect.
  TimerPhase get phase => _phase;

  /// How many full work→break cycles have completed.
  int get cyclesCompleted => _cyclesCompleted;

  /// Time spent in the current phase, computed against the wall clock.
  ///
  /// While running: `carried + (now - phaseStartedAt)`. While paused or idle:
  /// just `carried` (frozen). Never negative even if the clock jumps backward.
  Duration get elapsed {
    final started = _phaseStartedAt;
    if (_status == TimerStatus.running && started != null) {
      final live = _clock().difference(started);
      // Guard against a backward clock jump producing negative elapsed time.
      final safeLive = live.isNegative ? Duration.zero : live;
      return _carried + safeLive;
    }
    return _carried;
  }

  /// Time left in the current phase.
  ///
  /// [Duration.zero] for an open-ended Flowmodoro work stretch, and clamped at
  /// [Duration.zero] once a fixed phase has run past its target (it never goes
  /// negative — overrun is reported via [TimerSnapshot.isPhaseComplete]).
  Duration get remaining {
    final target = _phaseTarget;
    if (target == null) return Duration.zero;
    final left = target - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  /// Total focused work time for the whole session (work phases only).
  ///
  /// Equals [_bankedFocus] plus the current phase's [elapsed] when a work
  /// phase is in progress.
  Duration get accumulatedFocus {
    if (_phase == TimerPhase.work &&
        (_status == TimerStatus.running || _status == TimerStatus.paused)) {
      return _bankedFocus + elapsed;
    }
    return _bankedFocus;
  }

  /// Whether the current fixed-length phase has reached or passed its target.
  ///
  /// Always `false` for an open-ended Flowmodoro work stretch. The caller's
  /// ticker polls this to drive auto-advance (see [advanceIfPhaseComplete]).
  bool get isCurrentPhaseComplete {
    final target = _phaseTarget;
    if (target == null) return false;
    return elapsed >= target;
  }

  /// A plain-value snapshot of the engine for the UI to render this frame.
  TimerSnapshot snapshot() => TimerSnapshot(
    status: _status,
    phase: _phase,
    mode: mode,
    elapsed: elapsed,
    remaining: remaining,
    target: _phaseTarget,
    cyclesCompleted: _cyclesCompleted,
    accumulatedFocus: accumulatedFocus,
  );

  // ---------------------------------------------------------------------------
  // Transitions
  // ---------------------------------------------------------------------------

  /// Starts the session from [TimerStatus.idle] into the first work phase.
  ///
  /// No-op if the engine is not idle. Pomodoro work counts down from the
  /// configured work length; Flowmodoro work is open-ended (no target).
  void start() {
    if (_status != TimerStatus.idle) return;
    _phase = TimerPhase.work;
    _phaseTarget = mode == TimerMode.pomodoro ? _pomodoroWork : null;
    _beginRunning();
  }

  /// Suspends the running phase, banking elapsed time into [_carried].
  ///
  /// No-op unless the engine is [TimerStatus.running]. Because elapsed time is
  /// frozen on pause, a backgrounded *paused* session never gains time.
  void pause() {
    if (_status != TimerStatus.running) return;
    _carried = elapsed; // fold the live interval into the bank
    _phaseStartedAt = null;
    _status = TimerStatus.paused;
  }

  /// Resumes a paused phase, restarting the wall-clock interval.
  ///
  /// No-op unless the engine is [TimerStatus.paused]. The paused wall-clock
  /// gap is intentionally discarded — only running time counts.
  void resume() {
    if (_status != TimerStatus.paused) return;
    _phaseStartedAt = _clock();
    _status = TimerStatus.running;
  }

  /// Ends the current Flowmodoro work stretch and begins a proportional break.
  ///
  /// Only valid in Flowmodoro mode while in a running or paused work phase.
  /// The break length is [flowmodoroBreak] of the stretch just completed,
  /// clamped to the configured bounds. No-op in any other situation.
  void endStretch() {
    if (mode != TimerMode.flowmodoro) return;
    if (_phase != TimerPhase.work) return;
    if (_status != TimerStatus.running && _status != TimerStatus.paused) {
      return;
    }
    final stretch = elapsed;
    _bankedFocus += stretch; // bank the completed work stretch
    _cyclesCompleted += 1;
    _phase = TimerPhase.breakTime;
    _phaseTarget = flowmodoroBreak(
      stretch,
      _flowBreakRatio,
      min: _flowBreakMin,
      max: _flowBreakMax,
    );
    _beginRunning();
  }

  /// Advances out of the current phase as if its timer naturally elapsed.
  ///
  /// - From a **work** phase: banks the work time, counts a cycle, and starts
  ///   the break (Pomodoro break length, or a Flowmodoro proportional break).
  /// - From a **break** phase: starts the next work phase.
  ///
  /// Valid in a running or paused state. This is what a Pomodoro caller invokes
  /// when [isCurrentPhaseComplete] becomes true, and what the user's
  /// "skip break" button calls; see [advanceIfPhaseComplete] and [skipBreak].
  void advancePhase() {
    if (_status != TimerStatus.running && _status != TimerStatus.paused) {
      return;
    }
    if (_phase == TimerPhase.work) {
      final stretch = elapsed;
      _bankedFocus += stretch;
      _cyclesCompleted += 1;
      _phase = TimerPhase.breakTime;
      _phaseTarget = mode == TimerMode.pomodoro
          ? _pomodoroBreak
          : flowmodoroBreak(
              stretch,
              _flowBreakRatio,
              min: _flowBreakMin,
              max: _flowBreakMax,
            );
    } else {
      _phase = TimerPhase.work;
      _phaseTarget = mode == TimerMode.pomodoro ? _pomodoroWork : null;
    }
    _beginRunning();
  }

  /// Advances the phase only if a fixed-length phase has hit its target.
  ///
  /// Returns `true` if it advanced. A convenience for a Pomodoro 1 Hz ticker:
  /// call it each tick and it self-advances work↔break exactly when due. It is
  /// a no-op for an open-ended Flowmodoro work stretch (which the user ends
  /// with [endStretch]).
  bool advanceIfPhaseComplete() {
    if (_status != TimerStatus.running) return false;
    if (!isCurrentPhaseComplete) return false;
    advancePhase();
    return true;
  }

  /// Ends the current break early and starts the next work phase.
  ///
  /// Valid only while in a running or paused break phase. No-op otherwise.
  void skipBreak() {
    if (_phase != TimerPhase.breakTime) return;
    if (_status != TimerStatus.running && _status != TimerStatus.paused) {
      return;
    }
    _phase = TimerPhase.work;
    _phaseTarget = mode == TimerMode.pomodoro ? _pomodoroWork : null;
    _beginRunning();
  }

  /// Ends the session normally.
  ///
  /// Banks any in-progress *work* time into [accumulatedFocus] before moving
  /// to [TimerStatus.finished], so a session finished mid-work still records
  /// that focus. No-op once the session is already over.
  void finish() {
    if (_status == TimerStatus.finished ||
        _status == TimerStatus.abandoned) {
      return;
    }
    _bankFinalPhase();
    _carried = elapsed; // freeze elapsed so it stays correct after finishing
    _status = TimerStatus.finished;
    _phaseStartedAt = null;
  }

  /// Ends the session early.
  ///
  /// Like [finish] it banks any in-progress work time first — abandoning a
  /// session does not erase the focus actually done — then moves to
  /// [TimerStatus.abandoned]. No-op once the session is already over.
  void abandon() {
    if (_status == TimerStatus.finished ||
        _status == TimerStatus.abandoned) {
      return;
    }
    _bankFinalPhase();
    _carried = elapsed; // freeze elapsed so it stays correct after abandoning
    _status = TimerStatus.abandoned;
    _phaseStartedAt = null;
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Begins a fresh running phase: resets the carry, stamps the wall clock.
  void _beginRunning() {
    _carried = Duration.zero;
    _phaseStartedAt = _clock();
    _status = TimerStatus.running;
  }

  /// On [finish] / [abandon], folds an in-progress work phase's elapsed time
  /// into [_bankedFocus] so it is reflected in [accumulatedFocus]. A break
  /// phase contributes nothing. Idempotent guards in the callers ensure this
  /// runs at most once per session.
  void _bankFinalPhase() {
    if (_phase == TimerPhase.work &&
        (_status == TimerStatus.running || _status == TimerStatus.paused)) {
      _bankedFocus += elapsed;
    }
  }
}
