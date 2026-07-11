import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/rendering.dart';
import 'package:zenno/canvas/engine/canvas_transform.dart';
import 'package:zenno/canvas/model/canvas_style.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/core/database/tables/canvas_tables.dart';

/// Paints an infinite dotted grid that stays fixed in world space.
///
/// The grid step is chosen from powers of two so the on-screen dot spacing
/// (`step * viewport.scale`) stays roughly within a comfortable 32–96 logical
/// pixel band regardless of zoom. Only intersections inside the visible world
/// rectangle are emitted, and they are drawn in a single batched
/// [Canvas.drawPoints] call.
class GridPainter extends CustomPainter {
  /// Creates a grid painter for the given [viewport].
  const GridPainter({required this.viewport, required this.style});

  /// The camera through which the world grid is observed.
  final ViewportState viewport;
  final CanvasPaperStyle style;

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

    if (style.kind == BackgroundKind.blank) {
      return;
    }

    final step = _gridStep(viewport.scale, style.gridSpacing);

    // Snap the world rect outwards to the grid so the first/last lines of dots
    // are still drawn when they sit just off the visible edge.
    final startX = (minX / step).floorToDouble() * step;
    final startY = (minY / step).floorToDouble() * step;

    final Color color = Color(
      style.gridColor,
    ).withValues(alpha: style.gridOpacity.clamp(0.0, 1.0));
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    if (style.kind == BackgroundKind.lined) {
      for (var y = startY; y <= maxY; y += step) {
        canvas.drawLine(
          CanvasTransform.toScreen(viewport, Offset(minX, y)),
          CanvasTransform.toScreen(viewport, Offset(maxX, y)),
          paint,
        );
      }
      return;
    }

    if (style.kind == BackgroundKind.grid) {
      final majorEvery = style.graphMajorInterval <= 1
          ? 0
          : style.graphMajorInterval;
      for (var x = startX; x <= maxX; x += step) {
        final major = majorEvery > 0 && ((x / step).round() % majorEvery == 0);
        canvas.drawLine(
          CanvasTransform.toScreen(viewport, Offset(x, minY)),
          CanvasTransform.toScreen(viewport, Offset(x, maxY)),
          paint..strokeWidth = major ? 1.5 : 1,
        );
      }
      for (var y = startY; y <= maxY; y += step) {
        final major = majorEvery > 0 && ((y / step).round() % majorEvery == 0);
        canvas.drawLine(
          CanvasTransform.toScreen(viewport, Offset(minX, y)),
          CanvasTransform.toScreen(viewport, Offset(maxX, y)),
          paint..strokeWidth = major ? 1.5 : 1,
        );
      }
      return;
    }

    if (style.kind == BackgroundKind.isometric) {
      _drawLineFamily(canvas, minX, maxX, minY, maxY, step, math.pi / 2, paint);
      _drawLineFamily(canvas, minX, maxX, minY, maxY, step, math.pi / 6, paint);
      _drawLineFamily(
        canvas,
        minX,
        maxX,
        minY,
        maxY,
        step,
        -math.pi / 6,
        paint,
      );
      return;
    }

    if (style.kind == BackgroundKind.triangle) {
      _drawLineFamily(canvas, minX, maxX, minY, maxY, step, 0, paint);
      _drawLineFamily(canvas, minX, maxX, minY, maxY, step, math.pi / 3, paint);
      _drawLineFamily(
        canvas,
        minX,
        maxX,
        minY,
        maxY,
        step,
        -math.pi / 3,
        paint,
      );
      return;
    }

    final points = <Offset>[];
    for (var x = startX; x <= maxX; x += step) {
      for (var y = startY; y <= maxY; y += step) {
        points.add(CanvasTransform.toScreen(viewport, Offset(x, y)));
      }
    }
    if (points.isEmpty) {
      return;
    }

    final dotPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPoints(PointMode.points, points, dotPaint);
  }

  /// Picks a power-of-two world step whose on-screen spacing falls within the
  /// `[_minSpacing, _maxSpacing]` band for the given [scale].
  ///
  /// Starts at the smallest candidate step and doubles until the projected
  /// spacing reaches `_minSpacing`; the search is clamped to `[_minStep,
  /// _maxStep]` so extreme zoom levels still yield a sane step.
  double _gridStep(double scale, double preferredStep) {
    var step = preferredStep.clamp(_minStep, _maxStep).toDouble();
    while (step * scale < _minSpacing && step < _maxStep) {
      step *= 2;
    }
    while (step * scale > _maxSpacing && step > _minStep) {
      step /= 2;
    }
    return step;
  }

  void _drawLineFamily(
    Canvas canvas,
    double minX,
    double maxX,
    double minY,
    double maxY,
    double step,
    double angle,
    Paint paint,
  ) {
    final Offset direction = Offset(math.cos(angle), math.sin(angle));
    final Offset normal = Offset(-direction.dy, direction.dx);
    final List<Offset> corners = <Offset>[
      Offset(minX, minY),
      Offset(maxX, minY),
      Offset(maxX, maxY),
      Offset(minX, maxY),
    ];
    double minProjection = _dot(corners.first, normal);
    double maxProjection = minProjection;
    for (final Offset corner in corners.skip(1)) {
      final double projection = _dot(corner, normal);
      minProjection = math.min(minProjection, projection);
      maxProjection = math.max(maxProjection, projection);
    }

    final double extent =
        math.sqrt(math.pow(maxX - minX, 2) + math.pow(maxY - minY, 2)) + step;
    final double start = (minProjection / step).floorToDouble() * step;
    for (
      double projection = start;
      projection <= maxProjection;
      projection += step
    ) {
      final Offset anchor = normal * projection;
      canvas.drawLine(
        CanvasTransform.toScreen(viewport, anchor - direction * extent),
        CanvasTransform.toScreen(viewport, anchor + direction * extent),
        paint,
      );
    }
  }

  static double _dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

  @override
  bool shouldRepaint(GridPainter oldDelegate) =>
      oldDelegate.viewport != viewport || oldDelegate.style != style;
}
