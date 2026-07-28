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

  test('the same path drawn fast and slow produces the same shape', () {
    // The property that makes handwriting look consistent. A temporal filter
    // carrying all the smoothing violates it: identical letters written at
    // different speeds come out as different geometry. Shape smoothing
    // therefore lives in `streamline`, over the centreline, and what remains
    // here is small enough not to bend the stroke.
    Offset replay({required int microsPerSample}) {
      final processor = PenInputProcessor(const PenProfile());
      processor.begin(Offset.zero, 0.5, timestampMicros: 0);
      Offset last = Offset.zero;
      for (int i = 1; i <= 10; i++) {
        last = processor
            .next(
              Offset(i * 12.0, i * 4.0),
              0.5,
              timestampMicros: i * microsPerSample,
            )
            .point;
      }
      return last;
    }

    final Offset slow = replay(microsPerSample: 16000);
    final Offset fast = replay(microsPerSample: 4000);

    expect((slow - fast).distance, lessThan(1));
  });

  test('pressure noise is damped without damping position', () {
    final processor = PenInputProcessor(const PenProfile());
    processor.begin(Offset.zero, 0.5, timestampMicros: 0);

    // The S Pen jitters by a few hundredths sample to sample, and `thinning`
    // turns that straight into a rippling stroke edge.
    var peak = 0.0;
    for (int i = 1; i <= 12; i++) {
      final double noisy = i.isEven ? 0.54 : 0.46;
      final sample = processor.next(
        Offset(i * 8.0, 0),
        noisy,
        timestampMicros: i * 8000,
      );
      final double deviation = (sample.pressure - 0.5).abs();
      if (deviation > peak) {
        peak = deviation;
      }
    }

    expect(peak, lessThan(0.04 * 0.34));
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
