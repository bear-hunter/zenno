import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:zenno/canvas/model/canvas_element.dart';

/// Pure geometry helpers for styled arrow shapes.
abstract final class ArrowGeometry {
  /// Builds the world-space body path for an arrow.
  static Path bodyPath({
    required ArrowBodyKind body,
    required Offset start,
    required Offset end,
    required List<Offset> controls,
    required double strokeWidth,
  }) {
    switch (body) {
      case ArrowBodyKind.straight:
        return Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(end.dx, end.dy);
      case ArrowBodyKind.curved:
        final Offset control = controls.isEmpty
            ? _defaultCurveControl(start, end)
            : controls.first;
        return Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      case ArrowBodyKind.elbow:
        final Offset bend = controls.isEmpty
            ? Offset(end.dx, start.dy)
            : controls.first;
        return Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(bend.dx, bend.dy)
          ..lineTo(end.dx, end.dy);
      case ArrowBodyKind.sketch:
        return _sketchPath(start, end, strokeWidth);
    }
  }

  /// Tangent pointing away from [start] along the first part of the body.
  static Offset startTangent({
    required ArrowBodyKind body,
    required Offset start,
    required Offset end,
    required List<Offset> controls,
    required double strokeWidth,
  }) {
    switch (body) {
      case ArrowBodyKind.straight:
        return _nonZero(end - start);
      case ArrowBodyKind.curved:
        final Offset control = controls.isEmpty
            ? _defaultCurveControl(start, end)
            : controls.first;
        return _nonZero(control - start);
      case ArrowBodyKind.elbow:
        final Offset bend = controls.isEmpty
            ? Offset(end.dx, start.dy)
            : controls.first;
        return _nonZero(bend - start);
      case ArrowBodyKind.sketch:
        final List<Offset> points = _sketchPoints(start, end, strokeWidth);
        return _nonZero(points[1] - points.first);
    }
  }

  /// Tangent pointing into [end] along the final part of the body.
  static Offset endTangent({
    required ArrowBodyKind body,
    required Offset start,
    required Offset end,
    required List<Offset> controls,
    required double strokeWidth,
  }) {
    switch (body) {
      case ArrowBodyKind.straight:
        return _nonZero(end - start);
      case ArrowBodyKind.curved:
        final Offset control = controls.isEmpty
            ? _defaultCurveControl(start, end)
            : controls.first;
        return _nonZero(end - control);
      case ArrowBodyKind.elbow:
        final Offset bend = controls.isEmpty
            ? Offset(end.dx, start.dy)
            : controls.first;
        return _nonZero(end - bend);
      case ArrowBodyKind.sketch:
        final List<Offset> points = _sketchPoints(start, end, strokeWidth);
        return _nonZero(points.last - points[points.length - 2]);
    }
  }

  /// Stroke-width-first arrow head length for modern styled arrows.
  static double styledHeadLength({
    required double strokeWidth,
    required double headScale,
    double? maxLength,
  }) {
    final double scaled = (strokeWidth * 4.25).clamp(8.0, 30.0);
    final double bounded = scaled * headScale.clamp(0.35, 2.5);
    final double? cap = maxLength == null ? null : maxLength * 0.48;
    return cap == null ? bounded : math.min(bounded, cap);
  }

  /// Pre-style-system arrow head length. Kept for old rows only.
  static double legacyHeadLength(Offset start, Offset end) {
    return ((end - start).distance * 0.22).clamp(12.0, 56.0);
  }

  static Offset _defaultCurveControl(Offset start, Offset end) {
    final Offset midpoint = Offset.lerp(start, end, 0.5)!;
    final Offset delta = end - start;
    final double distance = delta.distance;
    if (distance == 0) {
      return midpoint;
    }
    final Offset normal = Offset(-delta.dy / distance, delta.dx / distance);
    return midpoint + normal * math.min(80.0, distance * 0.22);
  }

  static Path _sketchPath(Offset start, Offset end, double strokeWidth) {
    final List<Offset> points = _sketchPoints(start, end, strokeWidth);
    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i += 1) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    return path;
  }

  static List<Offset> _sketchPoints(
    Offset start,
    Offset end,
    double strokeWidth,
  ) {
    final Offset delta = end - start;
    final double distance = delta.distance;
    if (distance == 0) {
      return <Offset>[start, end];
    }
    final Offset normal = Offset(-delta.dy / distance, delta.dx / distance);
    final double wobble = math.min(9.0, math.max(1.5, strokeWidth * 0.75));
    return <Offset>[
      for (var i = 0; i <= 8; i += 1)
        Offset.lerp(start, end, i / 8)! +
            normal * (math.sin(i * math.pi * 0.82) * wobble),
    ];
  }

  static Offset _nonZero(Offset value) {
    if (value.distance == 0) {
      return const Offset(1, 0);
    }
    return value;
  }
}
