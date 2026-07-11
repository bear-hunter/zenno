import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/input/pen_input_processor.dart';
import 'package:zenno/canvas/input/pen_profile.dart';
import 'package:zenno/canvas/model/stroke.dart';

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

  test('stabilizer damps large point jumps', () {
    final processor = PenInputProcessor(
      const PenProfile(stabilizer: 0.5, smoothing: 0),
    );

    processor.begin(Offset.zero, 0.5);
    final sample = processor.next(const Offset(100, 0), 0.5);

    expect(sample.point.dx, closeTo(50, 0.01));
    expect(sample.point.dy, 0);
  });

  test('adaptive smoothing increases damping on fast movement', () {
    final processor = PenInputProcessor(
      const PenProfile(stabilizer: 0, smoothing: 0.8),
    );

    processor.begin(Offset.zero, 0.5);
    final sample = processor.next(const Offset(240, 0), 0.5);

    expect(sample.point.dx, lessThan(240));
    expect(sample.point.dx, greaterThan(0));
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

  test('taper lowers start and end pressure only', () {
    const points = <StrokePoint>[
      StrokePoint(0, 0, 1, tiltX: 0.1, timestampMicros: 10),
      StrokePoint(10, 0, 1, tiltX: 0.2, timestampMicros: 20),
      StrokePoint(20, 0, 1, tiltX: 0.3, timestampMicros: 30),
    ];

    final tapered = PenInputProcessor.applyTaper(
      points,
      const PenProfile(startTaper: 0.5, endTaper: 0.75),
    );

    expect(tapered.first.pressure, 0.5);
    expect(tapered[1].pressure, 1);
    expect(tapered.last.pressure, 0.75);
    expect(tapered.first.tiltX, 0.1);
    expect(tapered.last.timestampMicros, 30);
  });
}
