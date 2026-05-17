import 'package:flutter/widgets.dart';
import 'package:perfect_freehand/perfect_freehand.dart' hide StrokePoint;
import 'package:zenno/canvas/model/stroke.dart';

/// Builds a filled, closed outline [Path] from a pressure-varying centerline.
///
/// This wraps `perfect_freehand`'s [getStroke], which expands a polyline of
/// sampled centerline points into the polygon that surrounds the variable-width
/// stroke. The returned [Path] is intended to be drawn with a fill paint
/// (`PaintingStyle.fill`); the variable thickness lives in the outline itself,
/// not in a stroke width.
///
/// [points] are world-space (or whatever coordinate space the caller wants the
/// path produced in — see [size]). [size] is the base stroke diameter in that
/// same coordinate space. [thinning] controls how strongly pressure modulates
/// width, [smoothing] softens the outline edges, and [streamline] removes
/// jitter from the input samples. Set [isComplete] once the stroke is finished
/// so the tail is drawn fully rather than slightly behind the last sample. When
/// [simulatePressure] is true the per-point pressure values are ignored and
/// pressure is inferred from velocity instead.
///
/// Empty input yields an empty [Path]. A single point yields a small round dot
/// so an isolated tap still leaves a mark.
Path buildStrokeOutline(
  List<StrokePoint> points, {
  required double size,
  double thinning = 0.6,
  double smoothing = 0.5,
  double streamline = 0.4,
  bool isComplete = false,
  bool simulatePressure = false,
}) {
  if (points.isEmpty) {
    return Path();
  }

  if (points.length == 1) {
    return _dotPath(points.first, size);
  }

  final inputPoints = <PointVector>[
    for (final point in points)
      PointVector(point.x, point.y, point.pressure),
  ];

  final outline = getStroke(
    inputPoints,
    options: StrokeOptions(
      size: size,
      thinning: thinning,
      smoothing: smoothing,
      streamline: streamline,
      simulatePressure: simulatePressure,
      isComplete: isComplete,
    ),
  );

  if (outline.isEmpty) {
    return Path();
  }

  // A degenerate outline (everything collapsed to one location) still draws as
  // a dot rather than an invisible zero-area path.
  if (outline.length < 3) {
    return _dotPath(points.first, size);
  }

  final path = Path()..moveTo(outline.first.dx, outline.first.dy);
  for (var i = 1; i < outline.length; i++) {
    path.lineTo(outline[i].dx, outline[i].dy);
  }
  return path..close();
}

/// A small filled circle marking an isolated single-point stroke.
///
/// The dot radius tracks the stroke [size] and the point's [StrokePoint.pressure]
/// so a light tap reads thinner than a firm one, while never collapsing to a
/// zero-radius (invisible) path.
Path _dotPath(StrokePoint point, double size) {
  final radius = (size / 2) * (0.5 + 0.5 * point.pressure.clamp(0.0, 1.0));
  return Path()
    ..addOval(
      Rect.fromCircle(
        center: point.offset,
        radius: radius <= 0 ? 0.5 : radius,
      ),
    );
}
