import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:perfect_freehand/perfect_freehand.dart' hide StrokePoint;
import 'package:zenno/canvas/engine/stroke_style.dart';
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
/// same coordinate space. [tool] selects the thinning, smoothing, cap and
/// taper appropriate to that instrument — see [strokeStyleFor]. Set
/// [isComplete] once the stroke is finished so the tail is drawn fully rather
/// than slightly behind the last sample. When [simulatePressure] is true the
/// per-point pressure values are ignored and pressure is inferred from
/// velocity instead, which is what a device with no pressure sensor wants.
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
  StrokeToolKind tool = StrokeToolKind.pen,
  bool isComplete = false,
  bool simulatePressure = false,
}) {
  if (points.isEmpty) {
    return Path();
  }

  final StrokeToolStyle style = strokeStyleFor(tool);
  final double arcLength = _arcLength(points);

  // Below roughly one nib width of travel there is no line to draw, only a
  // mark. Routing it here — rather than only at exactly one point — is what
  // makes a light tap always leave a dot: a tap is almost never a single
  // sample, because the pen-up position is appended and a real nib drifts a
  // fraction of a unit between contact and lift.
  if (points.length == 1 || arcLength < size * _dotArcLengthFactor) {
    return _dotPath(points, size);
  }

  // A taper is interpolated across whatever samples exist, so a sparse stroke
  // can have no sample between its two ramps and collapse to a hairline even
  // when the ramps themselves are short enough. Short strokes are exactly the
  // sparse ones — a comma is three or four samples — so they are subdivided
  // first. Dense strokes already clear the threshold and are left alone.
  final List<StrokePoint> centerline = _densified(points, arcLength);

  final inputPoints = <PointVector>[
    for (final point in centerline)
      PointVector(
        point.x,
        point.y,
        _flooredPressure(point.pressure, style.thinning),
      ),
  ];

  // `customTaper` is an absolute arc length, but a stroke's length is not
  // fixed: an unclamped taper longer than half the stroke lets the two ramps
  // meet and cancel, collapsing the whole outline to a hairline. Capping each
  // ramp guarantees a full-width middle survives at any length, so a comma is
  // as thick as a sweep.
  final double taperBudget = arcLength * _maxTaperShareOfStroke;
  final double startTaper = math.min(style.startTaperFactor * size, taperBudget);
  final double endTaper = math.min(style.endTaperFactor * size, taperBudget);

  final outline = getStroke(
    inputPoints,
    options: StrokeOptions(
      size: size,
      thinning: style.thinning,
      smoothing: style.smoothing,
      // Shape smoothing is spatial and lives here — see [streamlineFor]. It is
      // deliberately a constant rather than a live setting: the outline is
      // rebuilt from stored points on every paint, so sourcing it from the
      // current pen profile would retroactively reshape ink already written.
      streamline: streamlineFor(_centerlineSmoothing),
      simulatePressure: simulatePressure,
      isComplete: isComplete,
      start: StrokeEndOptions.start(
        cap: style.cap,
        taperEnabled: style.tapersStart,
        customTaper: style.tapersStart ? startTaper : null,
      ),
      end: StrokeEndOptions.end(
        cap: style.cap,
        taperEnabled: style.tapersEnd,
        customTaper: style.tapersEnd ? endTaper : null,
      ),
    ),
  );

  if (outline.isEmpty) {
    return Path();
  }

  // A degenerate outline (everything collapsed to one location) still draws as
  // a dot rather than an invisible zero-area path.
  if (outline.length < 3) {
    return _dotPath(points, size);
  }

  return _outlineToPath(outline);
}

/// [points], subdivided until there are enough of them to carry a taper.
///
/// Returns [points] itself once the count is sufficient, so the common case of
/// an ordinary stroke costs one comparison and no allocation. Interpolation is
/// linear in position and pressure: this adds resolution, never new shape.
List<StrokePoint> _densified(List<StrokePoint> points, double arcLength) {
  if (points.length >= _minCenterlinePoints || arcLength <= 0) {
    return points;
  }
  final int subdivisions =
      (_minCenterlinePoints / (points.length - 1)).ceil().clamp(1, 64);
  if (subdivisions <= 1) {
    return points;
  }

  final List<StrokePoint> dense = <StrokePoint>[points.first];
  for (var i = 1; i < points.length; i++) {
    final StrokePoint from = points[i - 1];
    final StrokePoint to = points[i];
    for (var step = 1; step <= subdivisions; step++) {
      final double t = step / subdivisions;
      dense.add(
        StrokePoint(
          from.x + (to.x - from.x) * t,
          from.y + (to.y - from.y) * t,
          from.pressure + (to.pressure - from.pressure) * t,
          tiltX: to.tiltX,
          tiltY: to.tiltY,
          azimuth: to.azimuth,
          timestampMicros: to.timestampMicros,
          velocity: to.velocity,
        ),
      );
    }
  }
  return dense;
}

/// Total travel along the sampled centreline.
double _arcLength(List<StrokePoint> points) {
  var total = 0.0;
  for (var i = 1; i < points.length; i++) {
    total += (points[i].offset - points[i - 1].offset).distance;
  }
  return total;
}

/// [pressure] raised so a pressure-sensitive tool cannot thin away to nothing.
///
/// `thinning` scales width by pressure directly, so a raw 0.02 becomes an
/// invisible line. Remapping the range onto `[minPressureFraction, 1]` keeps
/// the tool expressive while guaranteeing the lightest touch still marks.
double _flooredPressure(double pressure, double thinning) {
  if (thinning <= 0) {
    return pressure;
  }
  final double p = pressure.clamp(0.0, 1.0);
  return minPressureFraction + (1 - minPressureFraction) * p;
}

/// Travel below which a stroke is drawn as a mark rather than a line.
///
/// A stroke shorter than its own nib is not a line by any reading.
const double _dotArcLengthFactor = 1.0;

/// Samples a centreline needs before a taper interpolates cleanly across it.
const int _minCenterlinePoints = 24;

/// Largest share of a stroke's length either end taper may consume.
const double _maxTaperShareOfStroke = 0.4;

/// Centreline smoothing strength, fixed so stored ink never reshapes.
const double _centerlineSmoothing = 0.35;

/// Converts a closed outline polygon into a smooth path.
///
/// Each outline vertex becomes a quadratic control point and each edge midpoint
/// an on-curve point — the construction `perfect_freehand` uses upstream. Skia
/// tessellates curves against the *device* transform, so the result stays
/// smooth at any zoom, where a `lineTo` polygon would show its facets and need
/// resampling to hide them.
Path _outlineToPath(List<Offset> outline) {
  final Offset closingMidpoint = Offset(
    (outline.last.dx + outline.first.dx) / 2,
    (outline.last.dy + outline.first.dy) / 2,
  );
  final path = Path()..moveTo(closingMidpoint.dx, closingMidpoint.dy);
  for (var i = 0; i < outline.length; i++) {
    final Offset current = outline[i];
    final Offset next = outline[(i + 1) % outline.length];
    path.quadraticBezierTo(
      current.dx,
      current.dy,
      (current.dx + next.dx) / 2,
      (current.dy + next.dy) / 2,
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

/// A small filled circle marking a stroke too short to draw as a line.
///
/// The radius tracks the stroke [size] and the firmest pressure in [points], so
/// a light tap reads thinner than a firm one while still being unmistakably a
/// dot. The floor is deliberately high: the point of this path is that every
/// touch marks, and a tap that leaves a speck reads as the pen having failed.
///
/// Peak rather than first pressure, because a tap ramps up and back down within
/// its handful of samples — the first one is always the lightest.
Path _dotPath(List<StrokePoint> points, double size) {
  var pressure = 0.0;
  Offset centre = points.first.offset;
  for (final StrokePoint point in points) {
    final double p = point.pressure.clamp(0.0, 1.0);
    if (p > pressure) {
      pressure = p;
      centre = point.offset;
    }
  }
  final double radius = (size / 2) * (0.62 + 0.38 * pressure);
  return Path()
    ..addOval(Rect.fromCircle(center: centre, radius: radius <= 0 ? 0.5 : radius));
}
