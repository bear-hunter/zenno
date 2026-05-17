// Pure Dart — no Flutter, no Drift.
import 'package:zenno/features/focus/domain/timer_engine.dart';

/// The fully-resolved configuration for one focus session, assembled on the
/// Setup screen before the session starts.
///
/// This is the hand-off value between `FocusSetupController` (which builds it
/// from user input) and `ActiveSessionController` (which turns it into a
/// [TimerEngine] and persists the opening `focus_sessions` row). It is plain,
/// immutable data with no Drift or Flutter dependency.
class FocusSessionConfig {
  /// Creates a session configuration.
  const FocusSessionConfig({
    required this.goalText,
    required this.preEnergy,
    required this.mode,
    required this.plannedDuration,
    required this.pomodoroWork,
    required this.pomodoroBreak,
    required this.flowBreakRatio,
    this.linkedCanvasId,
  });

  /// What the user intends to study this session. May be empty.
  final String goalText;

  /// Self-rated energy at the start, on a 1–5 scale.
  final int preEnergy;

  /// The timing model the session runs.
  final TimerMode mode;

  /// The user's target total length for the session. Persisted as
  /// `planned_duration_secs`; the timer itself does not hard-stop at it.
  final Duration plannedDuration;

  /// Pomodoro work-interval length. Ignored when [mode] is
  /// [TimerMode.flowmodoro], but always carried so the row can record it.
  final Duration pomodoroWork;

  /// Pomodoro break-interval length. Ignored for Flowmodoro.
  final Duration pomodoroBreak;

  /// Flowmodoro break ratio (break = stretch × ratio). Ignored for Pomodoro.
  final double flowBreakRatio;

  /// Optional canvas this session is associated with.
  final String? linkedCanvasId;

  /// Builds the [TimerEngine] this configuration describes.
  ///
  /// [clock] is forwarded for testability; production omits it.
  TimerEngine buildEngine({DateTime Function() clock = DateTime.now}) {
    return TimerEngine(
      mode: mode,
      clock: clock,
      pomodoroWork: pomodoroWork,
      pomodoroBreak: pomodoroBreak,
      flowBreakRatio: flowBreakRatio,
    );
  }

  /// Returns a copy with the given fields replaced.
  FocusSessionConfig copyWith({
    String? goalText,
    int? preEnergy,
    TimerMode? mode,
    Duration? plannedDuration,
    Duration? pomodoroWork,
    Duration? pomodoroBreak,
    double? flowBreakRatio,
    String? linkedCanvasId,
    bool clearLinkedCanvas = false,
  }) {
    return FocusSessionConfig(
      goalText: goalText ?? this.goalText,
      preEnergy: preEnergy ?? this.preEnergy,
      mode: mode ?? this.mode,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      pomodoroWork: pomodoroWork ?? this.pomodoroWork,
      pomodoroBreak: pomodoroBreak ?? this.pomodoroBreak,
      flowBreakRatio: flowBreakRatio ?? this.flowBreakRatio,
      linkedCanvasId: clearLinkedCanvas
          ? null
          : (linkedCanvasId ?? this.linkedCanvasId),
    );
  }
}
