import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/engine/stroke_builder.dart';
import 'package:zenno/canvas/model/stroke.dart';

void main() {
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
