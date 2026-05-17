import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/features/focus/domain/timer_engine.dart';

/// A controllable clock for the timer-engine tests.
///
/// [now] returns the current fake instant; [advance] moves it forward (or, for
/// the "time jump" cases, by a large leap that models the device sleeping).
class _FakeClock {
  _FakeClock(this._now);

  DateTime _now;

  DateTime now() => _now;

  void advance(Duration by) => _now = _now.add(by);
}

void main() {
  final epoch = DateTime.utc(2026);

  group('lifecycle', () {
    test('starts idle with no elapsed time', () {
      final engine = TimerEngine(mode: TimerMode.pomodoro);
      final snap = engine.snapshot();
      expect(snap.status, TimerStatus.idle);
      expect(snap.phase, TimerPhase.work);
      expect(snap.elapsed, Duration.zero);
      expect(snap.cyclesCompleted, 0);
      expect(snap.accumulatedFocus, Duration.zero);
    });

    test('start moves idle to running work', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(mode: TimerMode.pomodoro, clock: clock.now);
      engine.start();
      expect(engine.status, TimerStatus.running);
      expect(engine.phase, TimerPhase.work);
    });

    test('start is a no-op once already running', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(mode: TimerMode.pomodoro, clock: clock.now);
      engine.start();
      clock.advance(const Duration(minutes: 3));
      engine.start(); // should not reset the phase
      expect(engine.elapsed, const Duration(minutes: 3));
    });
  });

  group('wall-clock elapsed', () {
    test('elapsed is computed from the clock, not a counter', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(
        mode: TimerMode.pomodoro,
        clock: clock.now,
        pomodoroWork: const Duration(minutes: 25),
      );
      engine.start();
      clock.advance(const Duration(minutes: 7));
      expect(engine.elapsed, const Duration(minutes: 7));
      expect(engine.remaining, const Duration(minutes: 18));
    });

    test('a large time jump while running is reflected exactly', () {
      // Models the device sleeping for hours mid-session: a naive incrementing
      // counter would be hours behind; wall-clock elapsed is always correct.
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(
        mode: TimerMode.pomodoro,
        clock: clock.now,
        pomodoroWork: const Duration(minutes: 25),
      );
      engine.start();
      clock.advance(const Duration(hours: 4));
      expect(engine.elapsed, const Duration(hours: 4));
      // Past target — remaining floors at zero, never goes negative.
      expect(engine.remaining, Duration.zero);
      expect(engine.snapshot().isPhaseComplete, isTrue);
    });

    test('a backward clock jump does not produce negative elapsed', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(mode: TimerMode.pomodoro, clock: clock.now);
      engine.start();
      clock.advance(const Duration(minutes: -5));
      expect(engine.elapsed, Duration.zero);
      expect(engine.elapsed.isNegative, isFalse);
    });
  });

  group('pause / resume', () {
    test('elapsed freezes while paused', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(mode: TimerMode.pomodoro, clock: clock.now);
      engine.start();
      clock.advance(const Duration(minutes: 6));
      engine.pause();
      // Wall clock keeps moving while paused — elapsed must not.
      clock.advance(const Duration(minutes: 30));
      expect(engine.status, TimerStatus.paused);
      expect(engine.elapsed, const Duration(minutes: 6));
    });

    test('resume does not count the paused gap', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(mode: TimerMode.pomodoro, clock: clock.now);
      engine.start();
      clock.advance(const Duration(minutes: 6));
      engine.pause();
      clock.advance(const Duration(minutes: 30)); // paused gap, discarded
      engine.resume();
      clock.advance(const Duration(minutes: 4));
      // 6 min before pause + 4 min after resume = 10 min; the 30 min gap is
      // intentionally ignored.
      expect(engine.elapsed, const Duration(minutes: 10));
    });

    test('multiple pause/resume cycles accumulate run time only', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(mode: TimerMode.pomodoro, clock: clock.now);
      engine.start();
      clock.advance(const Duration(minutes: 2));
      engine.pause();
      clock.advance(const Duration(minutes: 10));
      engine.resume();
      clock.advance(const Duration(minutes: 3));
      engine.pause();
      clock.advance(const Duration(minutes: 10));
      engine.resume();
      clock.advance(const Duration(minutes: 5));
      // 2 + 3 + 5 = 10 min of running time.
      expect(engine.elapsed, const Duration(minutes: 10));
    });

    test('pause is a no-op when not running', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(mode: TimerMode.pomodoro, clock: clock.now);
      engine.pause();
      expect(engine.status, TimerStatus.idle);
    });

    test('resume is a no-op when not paused', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(mode: TimerMode.pomodoro, clock: clock.now);
      engine.start();
      engine.resume();
      expect(engine.status, TimerStatus.running);
    });
  });

  group('pomodoro work → break', () {
    test('advanceIfPhaseComplete moves work to break at the target', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(
        mode: TimerMode.pomodoro,
        clock: clock.now,
        pomodoroWork: const Duration(minutes: 25),
        pomodoroBreak: const Duration(minutes: 5),
      );
      engine.start();
      // One second short of the work target — no advance yet.
      clock.advance(const Duration(minutes: 24, seconds: 59));
      expect(engine.advanceIfPhaseComplete(), isFalse);
      expect(engine.phase, TimerPhase.work);
      // Cross the target.
      clock.advance(const Duration(seconds: 1));
      expect(engine.advanceIfPhaseComplete(), isTrue);
      expect(engine.phase, TimerPhase.breakTime);
      expect(engine.cyclesCompleted, 1);
      expect(engine.remaining, const Duration(minutes: 5));
    });

    test('break elapsed resets — it does not carry work elapsed', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(
        mode: TimerMode.pomodoro,
        clock: clock.now,
        pomodoroWork: const Duration(minutes: 25),
        pomodoroBreak: const Duration(minutes: 5),
      );
      engine.start();
      clock.advance(const Duration(minutes: 25));
      engine.advancePhase();
      clock.advance(const Duration(minutes: 2));
      expect(engine.phase, TimerPhase.breakTime);
      expect(engine.elapsed, const Duration(minutes: 2));
      expect(engine.remaining, const Duration(minutes: 3));
    });

    test('a full cycle returns to a fresh work phase', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(
        mode: TimerMode.pomodoro,
        clock: clock.now,
        pomodoroWork: const Duration(minutes: 25),
        pomodoroBreak: const Duration(minutes: 5),
      );
      engine.start();
      clock.advance(const Duration(minutes: 25));
      engine.advancePhase(); // → break
      clock.advance(const Duration(minutes: 5));
      engine.advancePhase(); // → work again
      expect(engine.phase, TimerPhase.work);
      expect(engine.elapsed, Duration.zero);
      expect(engine.remaining, const Duration(minutes: 25));
      expect(engine.cyclesCompleted, 1);
    });

    test('accumulatedFocus counts work phases only', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(
        mode: TimerMode.pomodoro,
        clock: clock.now,
        pomodoroWork: const Duration(minutes: 25),
        pomodoroBreak: const Duration(minutes: 5),
      );
      engine.start();
      clock.advance(const Duration(minutes: 25));
      engine.advancePhase(); // bank 25 min of work, now on break
      clock.advance(const Duration(minutes: 5));
      expect(engine.accumulatedFocus, const Duration(minutes: 25));
      engine.advancePhase(); // back to work
      clock.advance(const Duration(minutes: 10));
      // 25 banked + 10 in-progress = 35 min of focus, break excluded.
      expect(engine.accumulatedFocus, const Duration(minutes: 35));
    });

    test('skipBreak ends a break early and starts work', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(
        mode: TimerMode.pomodoro,
        clock: clock.now,
        pomodoroWork: const Duration(minutes: 25),
        pomodoroBreak: const Duration(minutes: 5),
      );
      engine.start();
      clock.advance(const Duration(minutes: 25));
      engine.advancePhase(); // → break
      clock.advance(const Duration(minutes: 1));
      engine.skipBreak();
      expect(engine.phase, TimerPhase.work);
      expect(engine.elapsed, Duration.zero);
    });
  });

  group('flowmodoro', () {
    test('work is open-ended — no target, count-up', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(mode: TimerMode.flowmodoro, clock: clock.now);
      engine.start();
      clock.advance(const Duration(minutes: 40));
      final snap = engine.snapshot();
      expect(snap.phase, TimerPhase.work);
      expect(snap.target, isNull);
      expect(snap.remaining, Duration.zero);
      expect(snap.elapsed, const Duration(minutes: 40));
      // An open-ended stretch never auto-advances.
      expect(engine.advanceIfPhaseComplete(), isFalse);
    });

    test('endStretch starts a proportional break', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(
        mode: TimerMode.flowmodoro,
        clock: clock.now,
        flowBreakRatio: 0.2,
      );
      engine.start();
      clock.advance(const Duration(minutes: 50));
      engine.endStretch();
      // 50 min * 0.2 = 10 min break, within [2, 30].
      expect(engine.phase, TimerPhase.breakTime);
      expect(engine.remaining, const Duration(minutes: 10));
      expect(engine.cyclesCompleted, 1);
      expect(engine.accumulatedFocus, const Duration(minutes: 50));
    });

    test('the proportional break is clamped to the minimum', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(
        mode: TimerMode.flowmodoro,
        clock: clock.now,
        flowBreakRatio: 0.2,
      );
      engine.start();
      clock.advance(const Duration(minutes: 4)); // 4 * 0.2 = 48 s < 2 min
      engine.endStretch();
      expect(engine.remaining, const Duration(minutes: 2));
    });

    test('the proportional break is clamped to the maximum', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(
        mode: TimerMode.flowmodoro,
        clock: clock.now,
        flowBreakRatio: 0.2,
      );
      engine.start();
      clock.advance(const Duration(hours: 4)); // 48 min > 30 min
      engine.endStretch();
      expect(engine.remaining, const Duration(minutes: 30));
    });

    test('a custom break clamp is honoured', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(
        mode: TimerMode.flowmodoro,
        clock: clock.now,
        flowBreakRatio: 0.5,
        flowBreakMax: const Duration(minutes: 45),
      );
      engine.start();
      clock.advance(const Duration(minutes: 100)); // 50 min, capped at 45
      engine.endStretch();
      expect(engine.remaining, const Duration(minutes: 45));
    });

    test('skipBreak after a stretch returns to open-ended work', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(
        mode: TimerMode.flowmodoro,
        clock: clock.now,
        flowBreakRatio: 0.2,
      );
      engine.start();
      clock.advance(const Duration(minutes: 30));
      engine.endStretch();
      clock.advance(const Duration(minutes: 1));
      engine.skipBreak();
      expect(engine.phase, TimerPhase.work);
      expect(engine.snapshot().target, isNull);
      expect(engine.elapsed, Duration.zero);
    });

    test('endStretch is a no-op during a break', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(mode: TimerMode.flowmodoro, clock: clock.now);
      engine.start();
      clock.advance(const Duration(minutes: 30));
      engine.endStretch(); // → break
      final cyclesAfterFirst = engine.cyclesCompleted;
      engine.endStretch(); // should do nothing during the break
      expect(engine.cyclesCompleted, cyclesAfterFirst);
      expect(engine.phase, TimerPhase.breakTime);
    });

    test('endStretch is a no-op in pomodoro mode', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(mode: TimerMode.pomodoro, clock: clock.now);
      engine.start();
      clock.advance(const Duration(minutes: 10));
      engine.endStretch();
      expect(engine.phase, TimerPhase.work);
      expect(engine.cyclesCompleted, 0);
    });

    test('endStretch works while paused, using frozen elapsed', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(
        mode: TimerMode.flowmodoro,
        clock: clock.now,
        flowBreakRatio: 0.2,
      );
      engine.start();
      clock.advance(const Duration(minutes: 50));
      engine.pause();
      clock.advance(const Duration(minutes: 99)); // ignored — paused
      engine.endStretch();
      // Break is based on the 50 min stretch, not the paused gap.
      expect(engine.phase, TimerPhase.breakTime);
      expect(engine.remaining, const Duration(minutes: 10));
    });
  });

  group('finish / abandon', () {
    test('finish banks in-progress work into accumulatedFocus', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(mode: TimerMode.flowmodoro, clock: clock.now);
      engine.start();
      clock.advance(const Duration(minutes: 18));
      engine.finish();
      expect(engine.status, TimerStatus.finished);
      expect(engine.accumulatedFocus, const Duration(minutes: 18));
    });

    test('abandon banks in-progress work too', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(
        mode: TimerMode.pomodoro,
        clock: clock.now,
        pomodoroWork: const Duration(minutes: 25),
      );
      engine.start();
      clock.advance(const Duration(minutes: 12));
      engine.abandon();
      expect(engine.status, TimerStatus.abandoned);
      expect(engine.accumulatedFocus, const Duration(minutes: 12));
    });

    test('finishing during a break does not add break time to focus', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(
        mode: TimerMode.pomodoro,
        clock: clock.now,
        pomodoroWork: const Duration(minutes: 25),
        pomodoroBreak: const Duration(minutes: 5),
      );
      engine.start();
      clock.advance(const Duration(minutes: 25));
      engine.advancePhase(); // bank 25 min, now on break
      clock.advance(const Duration(minutes: 3));
      engine.finish();
      expect(engine.accumulatedFocus, const Duration(minutes: 25));
    });

    test('finish is a no-op once the session is over', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(mode: TimerMode.pomodoro, clock: clock.now);
      engine.start();
      clock.advance(const Duration(minutes: 10));
      engine.finish();
      final focusAtFinish = engine.accumulatedFocus;
      clock.advance(const Duration(minutes: 10));
      engine.finish(); // second call must not bank more time
      expect(engine.accumulatedFocus, focusAtFinish);
      expect(engine.status, TimerStatus.finished);
    });

    test('elapsed stops advancing once finished', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(mode: TimerMode.pomodoro, clock: clock.now);
      engine.start();
      clock.advance(const Duration(minutes: 10));
      engine.finish();
      clock.advance(const Duration(minutes: 10));
      expect(engine.elapsed, const Duration(minutes: 10));
    });
  });

  group('snapshot', () {
    test('isOver reflects finished and abandoned', () {
      final finished = TimerEngine(mode: TimerMode.pomodoro)
        ..start()
        ..finish();
      expect(finished.snapshot().isOver, isTrue);

      final abandoned = TimerEngine(mode: TimerMode.pomodoro)
        ..start()
        ..abandon();
      expect(abandoned.snapshot().isOver, isTrue);
    });

    test('snapshot carries the configured mode', () {
      expect(
        TimerEngine(mode: TimerMode.flowmodoro).snapshot().mode,
        TimerMode.flowmodoro,
      );
    });
  });

  group('runtime restore', () {
    test('restores a running Pomodoro phase from durable runtime', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(
        mode: TimerMode.pomodoro,
        clock: clock.now,
        pomodoroWork: const Duration(minutes: 25),
        pomodoroBreak: const Duration(minutes: 5),
      )..start();
      clock.advance(const Duration(minutes: 7));

      final restored = TimerEngine.fromRuntime(
        mode: TimerMode.pomodoro,
        runtime: engine.runtimeSnapshot,
        clock: clock.now,
        pomodoroWork: const Duration(minutes: 25),
        pomodoroBreak: const Duration(minutes: 5),
      );

      expect(restored.status, TimerStatus.running);
      expect(restored.phase, TimerPhase.work);
      expect(restored.elapsed, const Duration(minutes: 7));
      expect(restored.remaining, const Duration(minutes: 18));
    });

    test('restores a paused Flowmodoro break without counting paused time', () {
      final clock = _FakeClock(epoch);
      final engine = TimerEngine(
        mode: TimerMode.flowmodoro,
        clock: clock.now,
        flowBreakRatio: 0.5,
      )..start();
      clock.advance(const Duration(minutes: 10));
      engine.endStretch();
      clock.advance(const Duration(minutes: 2));
      engine.pause();
      clock.advance(const Duration(minutes: 20));

      final restored = TimerEngine.fromRuntime(
        mode: TimerMode.flowmodoro,
        runtime: engine.runtimeSnapshot,
        clock: clock.now,
        flowBreakRatio: 0.5,
      );

      expect(restored.status, TimerStatus.paused);
      expect(restored.phase, TimerPhase.breakTime);
      expect(restored.elapsed, const Duration(minutes: 2));
      expect(restored.accumulatedFocus, const Duration(minutes: 10));
      expect(restored.cyclesCompleted, 1);
    });
  });
}
