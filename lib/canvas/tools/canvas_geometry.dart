import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:zenno/canvas/model/stroke.dart';

/// Pure world-space geometry used by the editing tools.
///
/// Everything here is a side-effect-free function of its inputs — hit-testing
/// for the object eraser, the centerline splitting that powers the vector
/// (partial) eraser, the even-odd point-in-polygon test the lasso relies on,
/// and the perimeter point generators for the shape tool. Keeping it isolated
/// from the controller and the render layer makes the tricky bits (stroke
/// splitting in particular) trivially unit-testable in plain Dart.
abstract final class CanvasGeometry {
  /// Returns the shortest distance from point [p] to the segment [a]–[b].
  ///
  /// Degenerate segments (where [a] and [b] coincide) reduce to the
  /// point-to-point distance. Used by the eraser to decide whether its circular
  /// footprint touches a stroke's centerline.
  static double distanceToSegment(Offset p, Offset a, Offset b) {
    final double dx = b.dx - a.dx;
    final double dy = b.dy - a.dy;
    final double lengthSquared = dx * dx + dy * dy;
    if (lengthSquared == 0) {
      return (p - a).distance;
    }
    // Projection parameter of `p` onto the infinite line through a,b, clamped
    // to the [0, 1] segment so the nearest point stays on the segment itself.
    double t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / lengthSquared;
    t = t.clamp(0.0, 1.0);
    final Offset projection = Offset(a.dx + t * dx, a.dy + t * dy);
    return (p - projection).distance;
  }

  /// Whether a circle of [radius] centred at [center] touches the polyline
  /// through [points].
  ///
  /// A single-point polyline is treated as that point. The check is inclusive:
  /// a circle exactly grazing the centerline counts as a hit. This is the
  /// precise per-stroke test the object eraser runs after the spatial-index
  /// broad phase.
  static bool circleHitsPolyline(
    Offset center,
    double radius,
    List<Offset> points,
  ) {
    if (points.isEmpty) {
      return false;
    }
    if (points.length == 1) {
      return (center - points.first).distance <= radius;
    }
    for (int i = 0; i < points.length - 1; i++) {
      if (distanceToSegment(center, points[i], points[i + 1]) <= radius) {
        return true;
      }
    }
    return false;
  }

  /// Whether any point of polyline [a] comes within [distance] of polyline [b].
  ///
  /// Each vertex of [a] is tested against every segment of [b] (and, so the
  /// check is symmetric for short inputs, single-vertex polylines are treated
  /// as a lone point). This is the proximity test the eraser's broad/narrow
  /// phase uses to decide whether the swept eraser path touches a stroke's
  /// centerline at all — `splitStrokeByEraser` then decides which points die.
  static bool polylinesWithinDistance(
    List<Offset> a,
    List<Offset> b,
    double distance,
  ) {
    if (a.isEmpty || b.isEmpty) {
      return false;
    }
    for (final Offset vertex in a) {
      if (circleHitsPolyline(vertex, distance, b)) {
        return true;
      }
    }
    // Also test b's vertices against a, so a short eraser dab crossing a long
    // stroke segment (with no stroke vertex nearby) is still detected.
    for (final Offset vertex in b) {
      if (circleHitsPolyline(vertex, distance, a)) {
        return true;
      }
    }
    for (int i = 0; i < a.length - 1; i++) {
      for (int j = 0; j < b.length - 1; j++) {
        if (_segmentIntersectionT(a[i], a[i + 1], b[j], b[j + 1]) != null) {
          return true;
        }
        final double? t = _closestParameterBetweenSegments(
          a[i],
          a[i + 1],
          b[j],
          b[j + 1],
        );
        if (t != null &&
            distanceToSegment(_pointAt(a[i], a[i + 1], t), b[j], b[j + 1]) <=
                distance) {
          return true;
        }
      }
    }
    return false;
  }

  /// Whether [point] lies inside the closed [polygon], by the even-odd rule.
  ///
  /// The polygon is treated as implicitly closed (the last vertex links back to
  /// the first). A polygon with fewer than three vertices encloses no area and
  /// always returns `false`. This is the containment test the lasso uses to
  /// decide which elements a freehand loop selects.
  static bool polygonContainsPoint(List<Offset> polygon, Offset point) {
    if (polygon.length < 3) {
      return false;
    }
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final Offset vi = polygon[i];
      final Offset vj = polygon[j];
      // A ray cast along +x crosses edge (vj, vi) when the edge straddles
      // point.dy and the crossing x lies to the right of point.dx.
      final bool straddles = (vi.dy > point.dy) != (vj.dy > point.dy);
      if (straddles) {
        final double crossingX =
            (vj.dx - vi.dx) * (point.dy - vi.dy) / (vj.dy - vi.dy) + vi.dx;
        if (point.dx < crossingX) {
          inside = !inside;
        }
      }
    }
    return inside;
  }

  /// Fraction of [points] that fall inside the closed [polygon], in `0..1`.
  ///
  /// Used by lasso selection to decide whether a stroke is "substantially
  /// inside" the loop: the caller compares the result against a coverage
  /// threshold. An empty point list yields `0`.
  static double polygonCoverage(List<Offset> polygon, List<Offset> points) {
    if (points.isEmpty) {
      return 0;
    }
    int inside = 0;
    for (final Offset point in points) {
      if (polygonContainsPoint(polygon, point)) {
        inside++;
      }
    }
    return inside / points.length;
  }

  /// Axis-aligned bounding box enclosing every offset in [points].
  ///
  /// Returns [Rect.zero] for an empty list. Handy for turning a freehand lasso
  /// path or a selection into a rectangle for broad-phase queries.
  static Rect boundsOfPoints(Iterable<Offset> points) {
    final Iterator<Offset> it = points.iterator;
    if (!it.moveNext()) {
      return Rect.zero;
    }
    double minX = it.current.dx;
    double maxX = it.current.dx;
    double minY = it.current.dy;
    double maxY = it.current.dy;
    while (it.moveNext()) {
      final Offset p = it.current;
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Splits [stroke] wherever an eraser circle crosses its centerline.
  ///
  /// The eraser is modelled as a circle of [radius] swept along [eraserPath].
  /// Stroke samples covered by that swept circle are removed, and sparse
  /// stroke segments that cross the eraser are cut at projected intersection
  /// points so fast strokes with few samples still split reliably.
  ///
  /// The result is a list of new point lists, in original stroke order:
  ///
  /// * empty — the eraser covered the whole stroke (the stroke is fully erased);
  /// * one list equal to the input — the eraser missed the stroke entirely;
  /// * two or more lists — the stroke was cut into that many surviving pieces.
  ///
  /// Single-point fragments are kept (an isolated surviving dot is still ink).
  /// Everything stays vector: inserted split points are interpolated from the
  /// original segment, including pressure.
  static List<List<StrokePoint>> splitStrokeByEraser({
    required Stroke stroke,
    required List<Offset> eraserPath,
    required double radius,
  }) {
    final List<StrokePoint> points = stroke.points;
    if (points.isEmpty || eraserPath.isEmpty) {
      return <List<StrokePoint>>[
        if (points.isNotEmpty) List<StrokePoint>.of(points),
      ];
    }
    if (points.length == 1) {
      return _eraserCoversPoint(points.single.offset, eraserPath, radius)
          ? const <List<StrokePoint>>[]
          : <List<StrokePoint>>[List<StrokePoint>.of(points)];
    }

    final List<List<StrokePoint>> fragments = <List<StrokePoint>>[];
    List<StrokePoint> current = <StrokePoint>[];

    final bool firstErased = _eraserCoversPoint(
      points.first.offset,
      eraserPath,
      radius,
    );
    if (!firstErased) {
      current.add(points.first);
    }

    for (int i = 0; i < points.length - 1; i++) {
      final StrokePoint a = points[i];
      final StrokePoint b = points[i + 1];
      final bool aErased = _eraserCoversPoint(a.offset, eraserPath, radius);
      final bool bErased = _eraserCoversPoint(b.offset, eraserPath, radius);
      final List<_StrokeCut> cuts = _segmentCutsByEraser(
        a: a,
        b: b,
        eraserPath: eraserPath,
        radius: radius,
      );

      if (aErased && !bErased) {
        final StrokePoint? exit = cuts.isEmpty ? null : cuts.last.point;
        if (exit != null) {
          current = <StrokePoint>[exit, b];
        } else {
          current = <StrokePoint>[b];
        }
      } else if (!aErased && bErased) {
        final StrokePoint? entry = cuts.isEmpty ? null : cuts.first.point;
        if (entry != null && current.isNotEmpty) {
          current.add(entry);
        }
        if (current.isNotEmpty) {
          fragments.add(current);
          current = <StrokePoint>[];
        }
      } else if (!aErased && !bErased) {
        if (cuts.length >= 2) {
          current.add(cuts.first.point);
          if (current.isNotEmpty) {
            fragments.add(current);
          }
          current = <StrokePoint>[cuts.last.point, b];
        } else if (cuts.length == 1) {
          current.add(cuts.single.point);
          fragments.add(current);
          current = <StrokePoint>[cuts.single.point, b];
        } else {
          current.add(b);
        }
      }
    }
    if (current.isNotEmpty) {
      fragments.add(current);
    }
    return fragments;
  }

  /// Whether the swept eraser circle of [radius] along [eraserPath] covers [p].
  ///
  /// A single eraser sample is treated as a lone circle; multiple samples form
  /// the polyline the circle sweeps along.
  static bool _eraserCoversPoint(
    Offset p,
    List<Offset> eraserPath,
    double radius,
  ) {
    if (eraserPath.length == 1) {
      return (p - eraserPath.first).distance <= radius;
    }
    for (int i = 0; i < eraserPath.length - 1; i++) {
      if (distanceToSegment(p, eraserPath[i], eraserPath[i + 1]) <= radius) {
        return true;
      }
    }
    return false;
  }

  static List<_StrokeCut> _segmentCutsByEraser({
    required StrokePoint a,
    required StrokePoint b,
    required List<Offset> eraserPath,
    required double radius,
  }) {
    final List<_StrokeCut> cuts = <_StrokeCut>[];
    final Offset start = a.offset;
    final Offset end = b.offset;
    if (eraserPath.length == 1) {
      for (final double t in _segmentCircleIntersectionTs(
        start,
        end,
        eraserPath.first,
        radius,
      )) {
        cuts.add(_StrokeCut(t, _interpolate(a, b, t)));
      }
    } else {
      for (int i = 0; i < eraserPath.length - 1; i++) {
        final Offset ea = eraserPath[i];
        final Offset eb = eraserPath[i + 1];
        final double? intersectionT = _segmentIntersectionT(start, end, ea, eb);
        if (intersectionT != null) {
          cuts.add(
            _StrokeCut(intersectionT, _interpolate(a, b, intersectionT)),
          );
          continue;
        }
        final double? t = _closestParameterBetweenSegments(start, end, ea, eb);
        if (t != null &&
            distanceToSegment(_pointAt(start, end, t), ea, eb) <= radius) {
          cuts.add(_StrokeCut(t, _interpolate(a, b, t)));
        }
      }
    }
    cuts.sort((left, right) => left.t.compareTo(right.t));
    final List<_StrokeCut> deduped = <_StrokeCut>[];
    for (final _StrokeCut cut in cuts) {
      if (deduped.isEmpty || (cut.t - deduped.last.t).abs() > 1e-4) {
        deduped.add(cut);
      }
    }
    return deduped;
  }

  static List<double> _segmentCircleIntersectionTs(
    Offset a,
    Offset b,
    Offset center,
    double radius,
  ) {
    final Offset d = b - a;
    final Offset f = a - center;
    final double aa = d.dx * d.dx + d.dy * d.dy;
    if (aa == 0) {
      return const <double>[];
    }
    final double bb = 2 * (f.dx * d.dx + f.dy * d.dy);
    final double cc = f.dx * f.dx + f.dy * f.dy - radius * radius;
    final double discriminant = bb * bb - 4 * aa * cc;
    if (discriminant < 0) {
      return const <double>[];
    }
    final double root = math.sqrt(discriminant);
    final double t1 = (-bb - root) / (2 * aa);
    final double t2 = (-bb + root) / (2 * aa);
    return <double>[
      if (t1 >= 0 && t1 <= 1) t1,
      if (t2 >= 0 && t2 <= 1 && (t2 - t1).abs() > 1e-9) t2,
    ]..sort();
  }

  static double? _projectionOnSegment(Offset p, Offset a, Offset b) {
    final double dx = b.dx - a.dx;
    final double dy = b.dy - a.dy;
    final double lengthSquared = dx * dx + dy * dy;
    if (lengthSquared == 0) {
      return null;
    }
    return (((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / lengthSquared).clamp(
      0.0,
      1.0,
    );
  }

  static double? _segmentIntersectionT(Offset a, Offset b, Offset c, Offset d) {
    final Offset r = b - a;
    final Offset s = d - c;
    final double denominator = _cross(r, s);
    if (denominator.abs() < 1e-9) {
      return null;
    }
    final Offset cMinusA = c - a;
    final double t = _cross(cMinusA, s) / denominator;
    final double u = _cross(cMinusA, r) / denominator;
    if (t < 0 || t > 1 || u < 0 || u > 1) {
      return null;
    }
    return t;
  }

  static double? _closestParameterBetweenSegments(
    Offset a,
    Offset b,
    Offset c,
    Offset d,
  ) {
    final double? t1 = _projectionOnSegment(c, a, b);
    final double? t2 = _projectionOnSegment(d, a, b);
    final List<double> candidates = <double>[?t1, ?t2, 0, 1];
    double? bestT;
    double bestDistance = double.infinity;
    for (final double t in candidates) {
      final double distance = distanceToSegment(_pointAt(a, b, t), c, d);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestT = t;
      }
    }
    return bestT;
  }

  static Offset _pointAt(Offset a, Offset b, double t) {
    return Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
  }

  static StrokePoint _interpolate(StrokePoint a, StrokePoint b, double t) {
    return StrokePoint(
      a.x + (b.x - a.x) * t,
      a.y + (b.y - a.y) * t,
      a.pressure + (b.pressure - a.pressure) * t,
    );
  }

  static double _cross(Offset a, Offset b) => a.dx * b.dy - a.dy * b.dx;

  // ---------------------------------------------------------------------------
  // Shape perimeter generators
  // ---------------------------------------------------------------------------

  /// World-space centerline for a straight line from [start] to [end].
  static List<Offset> linePoints(Offset start, Offset end) {
    return <Offset>[start, end];
  }

  /// World-space perimeter of the axis-aligned rectangle spanned by [a]–[b].
  ///
  /// Emitted as a closed loop of corner points (the first corner is repeated at
  /// the end) so the shape reads as a continuous stroke.
  static List<Offset> rectanglePoints(Offset a, Offset b) {
    final Rect rect = Rect.fromPoints(a, b);
    return <Offset>[
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
      rect.topLeft,
    ];
  }

  /// World-space perimeter of the ellipse inscribed in the [a]–[b] bounding box.
  ///
  /// Sampled at [segments] evenly-spaced angles (default 64) and closed back to
  /// the start, giving a smooth ovaloid the same pipeline as freehand ink can
  /// render, erase and select.
  static List<Offset> ovalPoints(Offset a, Offset b, {int segments = 64}) {
    final Rect rect = Rect.fromPoints(a, b);
    final Offset center = rect.center;
    final double rx = rect.width / 2;
    final double ry = rect.height / 2;
    final int count = math.max(segments, 8);
    return <Offset>[
      for (int i = 0; i <= count; i++)
        Offset(
          center.dx + rx * math.cos(2 * math.pi * i / count),
          center.dy + ry * math.sin(2 * math.pi * i / count),
        ),
    ];
  }

  /// World-space centerline of an arrow from [start] to [end].
  ///
  /// The shaft runs [start] → [end]; two short barbs are then traced back from
  /// the head so the whole arrow is one continuous polyline. The head size
  /// scales with shaft length (clamped) so short and long arrows both look
  /// proportionate. A zero-length drag yields just the two coincident points.
  static List<Offset> arrowPoints(Offset start, Offset end) {
    final Offset shaft = end - start;
    final double length = shaft.distance;
    if (length == 0) {
      return <Offset>[start, end];
    }
    final double headLength = (length * 0.22).clamp(8.0, 56.0);
    const double headAngle = math.pi / 7;
    final double shaftAngle = math.atan2(shaft.dy, shaft.dx);

    final Offset barbLeft = Offset(
      end.dx - headLength * math.cos(shaftAngle - headAngle),
      end.dy - headLength * math.sin(shaftAngle - headAngle),
    );
    final Offset barbRight = Offset(
      end.dx - headLength * math.cos(shaftAngle + headAngle),
      end.dy - headLength * math.sin(shaftAngle + headAngle),
    );

    // Shaft, then out to one barb, back to the tip, out to the other barb —
    // one unbroken stroke.
    return <Offset>[start, end, barbLeft, end, barbRight];
  }
}

class _StrokeCut {
  const _StrokeCut(this.t, this.point);

  final double t;
  final StrokePoint point;
}
