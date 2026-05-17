import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/features/focus/domain/flowmodoro_calc.dart';

void main() {
  group('flowmodoroBreak', () {
    test('scales the stretch by the ratio when inside the clamp', () {
      // 50 min * 0.2 = 10 min, comfortably within [2, 30].
      final result = flowmodoroBreak(const Duration(minutes: 50), 0.2);
      expect(result, const Duration(minutes: 10));
    });

    test('clamps up to the minimum for a short stretch', () {
      // 4 min * 0.2 = 48 s, below the 2 min floor.
      final result = flowmodoroBreak(const Duration(minutes: 4), 0.2);
      expect(result, const Duration(minutes: 2));
    });

    test('clamps down to the maximum for a marathon stretch', () {
      // 4 h * 0.2 = 48 min, above the 30 min ceiling.
      final result = flowmodoroBreak(const Duration(hours: 4), 0.2);
      expect(result, const Duration(minutes: 30));
    });

    test('returns the minimum for a zero-length stretch', () {
      final result = flowmodoroBreak(Duration.zero, 0.2);
      expect(result, const Duration(minutes: 2));
    });

    test('returns the minimum for a non-positive stretch', () {
      final result = flowmodoroBreak(const Duration(minutes: -10), 0.2);
      expect(result, const Duration(minutes: 2));
    });

    test('honours custom clamp bounds', () {
      // 100 min * 0.5 = 50 min, clamped to a custom 45 min ceiling.
      final result = flowmodoroBreak(
        const Duration(minutes: 100),
        0.5,
        min: const Duration(minutes: 1),
        max: const Duration(minutes: 45),
      );
      expect(result, const Duration(minutes: 45));
    });

    test('preserves sub-minute precision before clamping', () {
      // 10 min * 0.3 = 3 min exactly — must not round to a whole-minute grid.
      final result = flowmodoroBreak(
        const Duration(minutes: 10),
        0.3,
        min: const Duration(seconds: 30),
      );
      expect(result, const Duration(minutes: 3));
    });

    test('a fractional second result lands between the clamp bounds', () {
      // 7 min (420 s) * 0.2 = 84 s, inside a [30 s, 30 min] clamp.
      final result = flowmodoroBreak(
        const Duration(minutes: 7),
        0.2,
        min: const Duration(seconds: 30),
      );
      expect(result, const Duration(seconds: 84));
    });

    test('a zero ratio always yields the minimum', () {
      final result = flowmodoroBreak(const Duration(hours: 2), 0);
      expect(result, const Duration(minutes: 2));
    });
  });
}
