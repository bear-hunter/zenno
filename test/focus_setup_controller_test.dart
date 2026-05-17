import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/features/focus/application/focus_setup_controller.dart';
import 'package:zenno/features/focus/domain/timer_engine.dart';

void main() {
  test('linked canvas id survives setup state to session config', () {
    const setup = FocusSetupState(
      goalText: 'Renal physiology',
      preEnergy: 4,
      mode: TimerMode.pomodoro,
      pomodoroWork: Duration(minutes: 25),
      pomodoroBreak: Duration(minutes: 5),
      flowBreakRatio: 0.2,
      plannedDuration: Duration(minutes: 50),
      checkedItemIds: <String>{},
      linkedCanvasId: 'canvas-1',
    );

    expect(setup.toConfig().linkedCanvasId, 'canvas-1');
  });
}
