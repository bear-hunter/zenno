import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart' hide StrokePoint;

import 'package:zenno/canvas/engine/stroke_builder.dart';
import 'package:zenno/canvas/model/stroke.dart';

void main() {
  test('stroke outline uses continuous curves between outline samples', () {
    const points = <StrokePoint>[
      StrokePoint(0, 0, 0.35),
      StrokePoint(16, 6, 0.5),
      StrokePoint(28, 22, 0.75),
      StrokePoint(44, 15, 0.6),
      StrokePoint(60, 32, 0.45),
    ];
    final options = StrokeOptions(
      size: 8,
      thinning: 0.6,
      smoothing: 0.5,
      streamline: 0.4,
      simulatePressure: false,
      isComplete: true,
    );
    final List<Offset> outline = getStroke(<PointVector>[
      for (final point in points) PointVector(point.x, point.y, point.pressure),
    ], options: options);
    final Path path = buildStrokeOutline(
      points,
      size: options.size,
      thinning: options.thinning,
      smoothing: options.smoothing,
      streamline: options.streamline,
      simulatePressure: options.simulatePressure,
      isComplete: options.isComplete,
    );

    final PathMetric metric = path.computeMetrics().single;
    final Set<int> tangentAngles = <int>{};
    final int sampleCount = outline.length * 8;
    for (var i = 0; i < sampleCount; i += 1) {
      final Tangent? tangent = metric.getTangentForOffset(
        metric.length * i / sampleCount,
      );
      if (tangent != null) {
        tangentAngles.add((tangent.angle * 10000 / math.pi).round());
      }
    }

    expect(tangentAngles.length, greaterThan(outline.length));
  });

  test('high-zoom resampling stays inside the sampled centerline bounds', () {
    const points = <StrokePoint>[
      StrokePoint(0, 0, 0.5),
      StrokePoint(10, 0, 0.5),
      StrokePoint(20, 0, 0.5),
      StrokePoint(30, -40, 0.5),
    ];

    final Path path = buildStrokeOutline(
      points,
      size: 0.1,
      viewportScale: 16,
      quality: StrokeRenderQuality.highZoom,
      thinning: 0,
      smoothing: 0,
      streamline: 0,
      isComplete: true,
    );

    expect(path.getBounds().bottom, lessThanOrEqualTo(0.1));
  });
}
