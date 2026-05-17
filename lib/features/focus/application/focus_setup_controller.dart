import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/features/focus/application/focus_providers.dart';
import 'package:zenno/features/focus/domain/focus_session_config.dart';
import 'package:zenno/features/focus/domain/timer_engine.dart';

part 'focus_setup_controller.g.dart';

/// The editable draft state of the Focus Setup screen.
///
/// Immutable; the controller swaps in a new instance on every edit. It carries
/// the per-checklist-item checked flags plus everything needed to assemble a
/// [FocusSessionConfig].
class FocusSetupState {
  /// Creates a setup-draft state.
  const FocusSetupState({
    required this.goalText,
    required this.preEnergy,
    required this.mode,
    required this.pomodoroWork,
    required this.pomodoroBreak,
    required this.flowBreakRatio,
    required this.plannedDuration,
    required this.checkedItemIds,
    this.linkedCanvasId,
  });

  /// The draft as it stands before the user has touched anything, seeded from
  /// the `app_settings` defaults.
  factory FocusSetupState.fromSettings(AppSetting settings) {
    return FocusSetupState(
      goalText: '',
      preEnergy: 3,
      mode: TimerMode.pomodoro,
      pomodoroWork: Duration(seconds: settings.defaultPomodoroWorkSecs),
      pomodoroBreak: Duration(seconds: settings.defaultPomodoroBreakSecs),
      flowBreakRatio: settings.defaultFlowBreakRatio,
      plannedDuration: Duration(seconds: settings.defaultSessionLengthSecs),
      checkedItemIds: const <String>{},
      linkedCanvasId: null,
    );
  }

  /// What the user intends to study. May be empty.
  final String goalText;

  /// Self-rated starting energy, 1–5.
  final int preEnergy;

  /// The chosen timing model.
  final TimerMode mode;

  /// Pomodoro work-interval length.
  final Duration pomodoroWork;

  /// Pomodoro break-interval length.
  final Duration pomodoroBreak;

  /// Flowmodoro break ratio.
  final double flowBreakRatio;

  /// Target total session length.
  final Duration plannedDuration;

  /// Ids of ritual items the user has ticked.
  final Set<String> checkedItemIds;

  /// Optional working canvas for this focus session.
  final String? linkedCanvasId;

  /// Returns a copy with the given fields replaced.
  FocusSetupState copyWith({
    String? goalText,
    int? preEnergy,
    TimerMode? mode,
    Duration? pomodoroWork,
    Duration? pomodoroBreak,
    double? flowBreakRatio,
    Duration? plannedDuration,
    Set<String>? checkedItemIds,
    String? linkedCanvasId,
    bool clearLinkedCanvas = false,
  }) {
    return FocusSetupState(
      goalText: goalText ?? this.goalText,
      preEnergy: preEnergy ?? this.preEnergy,
      mode: mode ?? this.mode,
      pomodoroWork: pomodoroWork ?? this.pomodoroWork,
      pomodoroBreak: pomodoroBreak ?? this.pomodoroBreak,
      flowBreakRatio: flowBreakRatio ?? this.flowBreakRatio,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      checkedItemIds: checkedItemIds ?? this.checkedItemIds,
      linkedCanvasId: clearLinkedCanvas
          ? null
          : (linkedCanvasId ?? this.linkedCanvasId),
    );
  }

  /// Builds the immutable [FocusSessionConfig] this draft describes, ready to
  /// hand to `ActiveSessionController`.
  FocusSessionConfig toConfig() {
    return FocusSessionConfig(
      goalText: goalText.trim(),
      preEnergy: preEnergy,
      mode: mode,
      plannedDuration: plannedDuration,
      pomodoroWork: pomodoroWork,
      pomodoroBreak: pomodoroBreak,
      flowBreakRatio: flowBreakRatio,
      linkedCanvasId: linkedCanvasId,
    );
  }
}

/// Owns the Focus Setup screen's draft state and assembles a
/// [FocusSessionConfig] from it.
///
/// Seeds itself from the `app_settings` singleton; each mutator swaps in a
/// fresh [FocusSetupState] so watching widgets rebuild. It performs no DB
/// writes — `ActiveSessionController.startFrom` persists the opening session
/// row once the user taps "Start".
@riverpod
class FocusSetupController extends _$FocusSetupController {
  @override
  FocusSetupState build() {
    // Read the settings singleton *once* for the defaults — deliberately
    // `ref.read`, not `ref.watch`: a later settings emission must not rebuild
    // this controller and wipe the user's in-progress draft. The Setup screen
    // gates itself on `focusSettingsProvider`, so the row is already loaded by
    // the time this builds; the fallback only covers a cold first frame.
    final settings = ref.read(focusSettingsProvider).value;
    return settings == null
        ? const FocusSetupState(
            goalText: '',
            preEnergy: 3,
            mode: TimerMode.pomodoro,
            pomodoroWork: Duration(minutes: 25),
            pomodoroBreak: Duration(minutes: 5),
            flowBreakRatio: 0.2,
            plannedDuration: Duration(minutes: 50),
            checkedItemIds: <String>{},
            linkedCanvasId: null,
          )
        : FocusSetupState.fromSettings(settings);
  }

  /// Sets the study-goal text.
  void setGoalText(String value) {
    state = state.copyWith(goalText: value);
  }

  /// Sets the self-rated starting energy, clamped to 1–5.
  void setPreEnergy(int value) {
    state = state.copyWith(preEnergy: value.clamp(1, 5));
  }

  /// Switches the timing model.
  void setMode(TimerMode mode) {
    state = state.copyWith(mode: mode);
  }

  /// Sets the Pomodoro work-interval length (minimum one minute).
  void setPomodoroWork(Duration value) {
    state = state.copyWith(pomodoroWork: _atLeastOneMinute(value));
  }

  /// Sets the Pomodoro break-interval length (minimum one minute).
  void setPomodoroBreak(Duration value) {
    state = state.copyWith(pomodoroBreak: _atLeastOneMinute(value));
  }

  /// Sets the Flowmodoro break ratio, clamped to a sensible `0.05`–`1.0`.
  void setFlowBreakRatio(double value) {
    state = state.copyWith(flowBreakRatio: value.clamp(0.05, 1.0));
  }

  /// Sets the target total session length (minimum five minutes).
  void setPlannedDuration(Duration value) {
    state = state.copyWith(
      plannedDuration: value < const Duration(minutes: 5)
          ? const Duration(minutes: 5)
          : value,
    );
  }

  /// Toggles whether the ritual item [itemId] is ticked.
  void toggleRitualItem(String itemId) {
    final next = Set<String>.of(state.checkedItemIds);
    if (!next.remove(itemId)) {
      next.add(itemId);
    }
    state = state.copyWith(checkedItemIds: next);
  }

  /// Links a working canvas to the draft session.
  void setLinkedCanvas(String canvasId) {
    state = state.copyWith(linkedCanvasId: canvasId);
  }

  /// Clears the draft session's working canvas.
  void clearLinkedCanvas() {
    state = state.copyWith(clearLinkedCanvas: true);
  }

  /// Resets the draft to the `app_settings` defaults.
  void reset() {
    ref.invalidateSelf();
  }

  Duration _atLeastOneMinute(Duration value) =>
      value < const Duration(minutes: 1) ? const Duration(minutes: 1) : value;
}
