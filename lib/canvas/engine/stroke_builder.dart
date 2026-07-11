import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:perfect_freehand/perfect_freehand.dart' hide StrokePoint;
import 'package:zenno/canvas/model/stroke.dart';

/// Rendering strategy for converting a stroke centerline into a filled path.
enum StrokeRenderQuality { overview, normal, highZoom }

const double _overviewScaleThreshold = 0.06;
const double _highZoomScaleThreshold = 4.0;
const int _maxHighZoomPoints = 4096;

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
/// Empty input yields an empty [Path]. A single point yields a small round dot
/// so an isolated tap still leaves a mark.
Path buildStrokeOutline(
  List<StrokePoint> points, {
  required double size,
  double viewportScale = 1,
  StrokeRenderQuality quality = StrokeRenderQuality.normal,
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

  final List<StrokePoint> renderPoints = switch (quality) {
    StrokeRenderQuality.highZoom => _resampleForHighZoom(
      points,
      viewportScale: viewportScale,
    ),
    StrokeRenderQuality.overview || StrokeRenderQuality.normal => points,
  };

  final inputPoints = <PointVector>[
    for (final point in renderPoints)
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
    return _dotPath(renderPoints.first, size);
  }

  final path = Path()..moveTo(outline.first.dx, outline.first.dy);
  for (var i = 1; i < outline.length; i++) {
    path.lineTo(outline[i].dx, outline[i].dy);
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

List<StrokePoint> _resampleForHighZoom(
  List<StrokePoint> points, {
  required double viewportScale,
}) {
  if (points.length < 3 || points.length >= _maxHighZoomPoints) {
    return points;
  }
  final double targetScreenSegment = viewportScale >= 16 ? 4.0 : 6.0;
  final List<StrokePoint> resampled = <StrokePoint>[];
  final int lastSegment = points.length - 2;
  for (var i = 0; i <= lastSegment; i += 1) {
    final StrokePoint p0 = points[(i - 1).clamp(0, points.length - 1).toInt()];
    final StrokePoint p1 = points[i];
    final StrokePoint p2 = points[i + 1];
    final StrokePoint p3 = points[(i + 2).clamp(0, points.length - 1).toInt()];
    if (resampled.isEmpty) {
      resampled.add(p1);
    }

    final double screenDistance =
        (p2.offset - p1.offset).distance * math.max(1, viewportScale);
    final int wantedSteps = (screenDistance / targetScreenSegment)
        .ceil()
        .clamp(1, 24)
        .toInt();
    final int remainingSegments = lastSegment - i + 1;
    final int remainingSlots = _maxHighZoomPoints - resampled.length - 1;
    final int allowedSteps = remainingSlots <= 0
        ? 1
        : math.max(1, remainingSlots ~/ remainingSegments);
    final int steps = math.min(wantedSteps, allowedSteps);

    for (var j = 1; j <= steps; j += 1) {
      final double t = j / steps;
      resampled.add(_interpolateStrokePoint(p0, p1, p2, p3, t));
    }
  }
  return resampled;
}

StrokePoint _interpolateStrokePoint(
  StrokePoint p0,
  StrokePoint p1,
  StrokePoint p2,
  StrokePoint p3,
  double t,
) {
  final double x = _catmullRom(p0.x, p1.x, p2.x, p3.x, t);
  final double y = _catmullRom(p0.y, p1.y, p2.y, p3.y, t);
  return StrokePoint(
    x,
    y,
    _lerpDouble(p1.pressure, p2.pressure, t),
    tiltX: _lerpDouble(p1.tiltX, p2.tiltX, t),
    tiltY: _lerpDouble(p1.tiltY, p2.tiltY, t),
    azimuth: _lerpDouble(p1.azimuth, p2.azimuth, t),
    timestampMicros: _lerpDouble(
      p1.timestampMicros.toDouble(),
      p2.timestampMicros.toDouble(),
      t,
    ).round(),
    velocity: _lerpDouble(p1.velocity, p2.velocity, t),
  );
}

double _catmullRom(double p0, double p1, double p2, double p3, double t) {
  final double t2 = t * t;
  final double t3 = t2 * t;
  return 0.5 *
      ((2 * p1) +
          (-p0 + p2) * t +
          (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
          (-p0 + 3 * p1 - 3 * p2 + p3) * t3);
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

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
