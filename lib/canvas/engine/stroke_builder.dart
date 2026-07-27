import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:perfect_freehand/perfect_freehand.dart' hide StrokePoint;
import 'package:zenno/canvas/model/stroke.dart';

/// Rendering strategy for converting a stroke centerline into a filled path.
enum StrokeRenderQuality { overview, normal, highZoom }

const double _overviewScaleThreshold = 0.06;
const double _highZoomScaleThreshold = 4.0;

StrokeRenderQuality strokeRenderQualityForScale(double scale) {
  if (scale < _overviewScaleThreshold) {
    return StrokeRenderQuality.overview;
  }
  if (scale >= _highZoomScaleThreshold) {
    return StrokeRenderQuality.highZoom;
  }
  return StrokeRenderQuality.normal;
}

/// Coarse logarithmic scale bucket for render-path cache keys.
int strokeScaleBucket(double scale) {
  if (!scale.isFinite || scale <= 0) {
    return 0;
  }
  return (math.log(scale) / math.ln2).floor();
}

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
/// The outline is emitted as quadratic curves, which Skia tessellates against
/// the device transform — so one path renders smoothly at every zoom level and
/// the result is deliberately independent of the viewport.
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
    for (final point in points) PointVector(point.x, point.y, point.pressure),
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

  return _outlineToPath(outline);
}

/// Converts a closed outline polygon into a smooth path.
///
/// Each outline vertex becomes a quadratic control point and each edge midpoint
/// an on-curve point — the construction `perfect_freehand` uses upstream. Skia
/// tessellates curves against the *device* transform, so the result stays
/// smooth at any zoom, where a `lineTo` polygon would show its facets and need
/// resampling to hide them.
Path _outlineToPath(List<Offset> outline) {
  final Offset first = outline.first;
  final Offset second = outline[1];
  final Path path = Path()
    ..moveTo((first.dx + second.dx) / 2, (first.dy + second.dy) / 2);
  for (var i = 1; i < outline.length; i++) {
    final Offset control = outline[i];
    final Offset next = outline[(i + 1) % outline.length];
    path.quadraticBezierTo(
      control.dx,
      control.dy,
      (control.dx + next.dx) / 2,
      (control.dy + next.dy) / 2,
    );
  }
  return path..close();
}

/// Builds the closed polygon covered by a freeform fill gesture.
///
/// Fill points describe the boundary itself rather than a pressure-sensitive
/// centreline, so stroke width and pressure deliberately do not affect this
/// path. Fewer than three points cannot enclose an area and yield an empty
/// path.
Path buildFillBoundaryPath(List<StrokePoint> points) {
  if (points.length < 3) {
    return Path();
  }
  final Path path = Path()
    ..fillType = PathFillType.evenOdd
    ..moveTo(points.first.x, points.first.y);
  for (final StrokePoint point in points.skip(1)) {
    path.lineTo(point.x, point.y);
  }
  return path..close();
}

/// Whether [points] enclose a non-degenerate freeform fill region.
bool isValidFillBoundary(List<StrokePoint> points) {
  if (points.length < 3) {
    return false;
  }
  final Offset origin = points.first.offset;
  StrokePoint? baselinePoint;
  for (final StrokePoint point in points.skip(1)) {
    if ((point.offset - origin).distanceSquared > 1) {
      baselinePoint = point;
      break;
    }
  }
  if (baselinePoint == null) {
    return false;
  }
  final Offset baseline = baselinePoint.offset - origin;
  for (final StrokePoint point in points.skip(1)) {
    final Offset candidate = point.offset - origin;
    final double cross =
        baseline.dx * candidate.dy - baseline.dy * candidate.dx;
    if (cross.abs() > 1) {
      return true;
    }
  }
  return false;
}

/// A small filled circle marking an isolated single-point stroke.
///
/// The dot radius tracks the stroke [size] and the point's [StrokePoint.pressure]
/// so a light tap reads thinner than a firm one, while never collapsing to a
/// zero-radius (invisible) path.
Path _dotPath(StrokePoint point, double size) {
  final radius = (size / 2) * (0.5 + 0.5 * point.pressure.clamp(0.0, 1.0));
  return Path()..addOval(
    Rect.fromCircle(center: point.offset, radius: radius <= 0 ? 0.5 : radius),
  );
}
