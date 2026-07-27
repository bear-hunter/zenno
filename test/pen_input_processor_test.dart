import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/input/pen_input_processor.dart';
import 'package:zenno/canvas/input/pen_profile.dart';

void main() {
  test('pressure curves make light easier and firm harder', () {
    const raw = 0.25;

    final light = const PenProfile(
      pressureCurve: PressureCurveKind.light,
    ).mapPressure(raw);
    final firm = const PenProfile(
      pressureCurve: PressureCurveKind.firm,
    ).mapPressure(raw);

    expect(light, greaterThan(raw));
    expect(firm, lessThan(raw));
  });

  test('the stabilizer damps a slow, jittery sample', () {
    final processor = PenInputProcessor(
      const PenProfile(stabilizer: 0.9, smoothing: 0),
    );

    // 2 units over 8 ms: a hand tremor, not a stroke.
    processor.begin(Offset.zero, 0.5, timestampMicros: 0);
    final sample = processor.next(
      const Offset(2, 0),
      0.5,
      timestampMicros: 8000,
    );

    expect(sample.point.dx, lessThan(2));
    expect(sample.point.dx, greaterThan(0));
    expect(sample.point.dy, 0);
  });

  test('a fast stroke tracks the nib more closely than a slow one', () {
    double followedFraction({required double distance, required int micros}) {
      final processor = PenInputProcessor(
        const PenProfile(stabilizer: 0.9, smoothing: 0),
      );
      processor.begin(Offset.zero, 0.5, timestampMicros: 0);
      final sample = processor.next(
        Offset(distance, 0),
        0.5,
        timestampMicros: micros,
      );
      return sample.point.dx / distance;
    }

    // Same elapsed time, very different speeds. Jitter lives in slow strokes,
    // so those are filtered hardest; a fast stroke must stay on the nib.
    final double slow = followedFraction(distance: 2, micros: 8000);
    final double fast = followedFraction(distance: 200, micros: 8000);

    expect(fast, greaterThan(slow));
  });

  test('lag does not depend on the pen report rate', () {
    // The same 120-unit sweep over 48 ms, delivered as 4 samples and as 12.
    // Flutter emits every historical MotionEvent as its own move event, so a
    // per-sample filter weight would make a fast writer's ink lag differently
    // from a slow one's.
    Offset sweep({required int steps}) {
      final processor = PenInputProcessor(
        const PenProfile(stabilizer: 0.6, smoothing: 0),
      );
      processor.begin(Offset.zero, 0.5, timestampMicros: 0);
      Offset last = Offset.zero;
      for (int i = 1; i <= steps; i++) {
        last = processor
            .next(
              Offset(120 * i / steps, 0),
              0.5,
              timestampMicros: (48000 * i / steps).round(),
            )
            .point;
      }
      return last;
    }

    final Offset coarse = sweep(steps: 4);
    final Offset dense = sweep(steps: 12);

    expect(dense.dx, closeTo(coarse.dx, 6));
  });

  test('samples carry stylus metadata and cached velocity', () {
    final processor = PenInputProcessor(const PenProfile());

    final first = processor.begin(
      Offset.zero,
      0.5,
      tiltX: 0.1,
      tiltY: 0.2,
      azimuth: 0.3,
      timestampMicros: 1000000,
    );
    final second = processor.next(
      const Offset(10, 0),
      0.5,
      tiltX: 0.4,
      tiltY: 0.5,
      azimuth: 0.6,
      timestampMicros: 1100000,
    );

    expect(first.tiltX, 0.1);
    expect(first.timestampMicros, 1000000);
    expect(second.tiltX, 0.4);
    expect(second.tiltY, 0.5);
    expect(second.azimuth, 0.6);
    expect(second.velocity, greaterThan(0));
  });
}
