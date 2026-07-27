import 'dart:math' as math;
import 'dart:ui';

import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/stroke.dart';

/// Deterministic synthetic canvas content for performance regression tests.
///
/// These fixtures never read production data. Stable ids and geometry make
/// before/after samples comparable across revisions and devices.
abstract final class CanvasPerformanceFixtures {
  static List<CanvasElement> inkGrid({
    int count = 10000,
    int columns = 100,
    double spacing = 64,
    double markSize = 12,
  }) {
    assert(count >= 0);
    assert(columns > 0);
    return List<CanvasElement>.generate(count, (int index) {
      final int column = index % columns;
      final int row = index ~/ columns;
      final double left = column * spacing;
      final double top = row * spacing;
      return InkElement.fromStroke(
        Stroke(
          id: 'perf-ink-$index',
          points: <StrokePoint>[
            StrokePoint(left, top, 0.45),
            StrokePoint(left + markSize, top + markSize, 0.65),
          ],
          color: 0xFFFFFFFF,
          width: 2,
        ),
        zIndex: index,
      );
    }, growable: false);
  }

  static Stroke longStroke({int pointCount = 8192}) {
    assert(pointCount > 1);
    return Stroke(
      id: 'perf-long-stroke',
      points: List<StrokePoint>.generate(pointCount, (int index) {
        final double x = index * 0.75;
        final double y = math.sin(index / 20) * 32;
        return StrokePoint(
          x,
          y,
          0.35 + ((index % 100) / 250),
          timestampMicros: index * 8000,
          velocity: 0.75,
        );
      }, growable: false),
      color: 0xFFFFFFFF,
      width: 4,
    );
  }

  static Rect viewportRect({
    double left = 0,
    double top = 0,
    double width = 256,
    double height = 256,
  }) => Rect.fromLTWH(left, top, width, height);
}
