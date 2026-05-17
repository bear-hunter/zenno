import 'dart:ui' show PointMode;

import 'package:flutter/rendering.dart';
import 'package:zenno/canvas/engine/canvas_transform.dart';
import 'package:zenno/canvas/model/viewport_state.dart';

/// Paints an infinite dotted grid that stays fixed in world space.
///
/// The grid step is chosen from powers of two so the on-screen dot spacing
/// (`step * viewport.scale`) stays roughly within a comfortable 32–96 logical
/// pixel band regardless of zoom. Only intersections inside the visible world
/// rectangle are emitted, and they are drawn in a single batched
/// [Canvas.drawPoints] call.
class GridPainter extends CustomPainter {
  /// Creates a grid painter for the given [viewport].
  const GridPainter({required this.viewport});

  /// The camera through which the world grid is observed.
  final ViewportState viewport;

  /// Lower bound of the desired on-screen dot spacing, in logical pixels.
  static const double _minSpacing = 32;

  /// Upper bound of the desired on-screen dot spacing, in logical pixels.
  static const double _maxSpacing = 96;

  /// Smallest world-space grid step considered when searching for a fit.
  static const double _minStep = 1;

  /// Largest world-space grid step considered when searching for a fit.
  static const double _maxStep = 1048576.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || viewport.scale <= 0) {
      return;
    }

    // Bounding box of the visible region, in world coordinates. The four
    // screen corners are mapped back to world space; rotation means the world
    // rect must be the bounds of those (possibly skewed) points.
    final corners = <Offset>[
      CanvasTransform.toWorld(viewport, Offset.zero),
      CanvasTransform.toWorld(viewport, Offset(size.width, 0)),
      CanvasTransform.toWorld(viewport, Offset(0, size.height)),
      CanvasTransform.toWorld(viewport, Offset(size.width, size.height)),
    ];

    var minX = corners.first.dx;
    var maxX = corners.first.dx;
    var minY = corners.first.dy;
    var maxY = corners.first.dy;
    for (final corner in corners) {
      if (corner.dx < minX) minX = corner.dx;
      if (corner.dx > maxX) maxX = corner.dx;
      if (corner.dy < minY) minY = corner.dy;
      if (corner.dy > maxY) maxY = corner.dy;
    }

    final step = _gridStep(viewport.scale);

    // Snap the world rect outwards to the grid so the first/last lines of dots
    // are still drawn when they sit just off the visible edge.
    final startX = (minX / step).floorToDouble() * step;
    final startY = (minY / step).floorToDouble() * step;

    final points = <Offset>[];
    for (var x = startX; x <= maxX; x += step) {
      for (var y = startY; y <= maxY; y += step) {
        points.add(CanvasTransform.toScreen(viewport, Offset(x, y)));
      }
    }
    if (points.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = const Color(0x24FFFFFF)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPoints(PointMode.points, points, paint);
  }

  /// Picks a power-of-two world step whose on-screen spacing falls within the
  /// `[_minSpacing, _maxSpacing]` band for the given [scale].
  ///
  /// Starts at the smallest candidate step and doubles until the projected
  /// spacing reaches `_minSpacing`; the search is clamped to `[_minStep,
  /// _maxStep]` so extreme zoom levels still yield a sane step.
  double _gridStep(double scale) {
    var step = _minStep;
    while (step * scale < _minSpacing && step < _maxStep) {
      step *= 2;
    }
    while (step * scale > _maxSpacing && step > _minStep) {
      step /= 2;
    }
    return step;
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) =>
      oldDelegate.viewport != viewport;
}
