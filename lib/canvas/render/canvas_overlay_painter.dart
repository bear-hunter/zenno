import 'package:flutter/rendering.dart';

import 'package:zenno/canvas/engine/canvas_transform.dart';
import 'package:zenno/canvas/model/viewport_state.dart';

/// Paints transient canvas chrome that sits above the ink layers.
///
/// This is the top compositing layer: it draws non-persisted feedback —
/// the tool hover ring, the eraser footprint and its swept trail, the
/// in-progress lasso loop, and the bounding box around a lasso selection.
/// Everything is projected through [viewport]; world-anchored radii and the
/// selection box scale with the camera, while purely cosmetic strokes (the
/// lasso outline, the selection border) keep a constant on-screen weight.
class CanvasOverlayPainter extends CustomPainter {
  /// Creates an overlay painter for the given [viewport].
  const CanvasOverlayPainter({
    required this.viewport,
    this.hoverPointWorld,
    this.hoverRadius = 0,
    this.isEraserHover = false,
    this.eraserPath,
    this.eraserRadius = 0,
    this.lassoPath,
    this.selectionBounds,
  });

  /// The camera through which world points are projected to screen.
  final ViewportState viewport;

  /// World-space position of the hover indicator, or `null` to draw nothing.
  final Offset? hoverPointWorld;

  /// World-space radius of the hover ring, in logical pixels at `scale == 1`.
  final double hoverRadius;

  /// Whether the hover ring represents the eraser (drawn as a dashed-feel
  /// circle) rather than the pen (a thin solid ring).
  final bool isEraserHover;

  /// World-space samples of the in-progress eraser drag, or `null`.
  ///
  /// When present, the eraser footprint is drawn at the last sample and a
  /// faint trail is stroked along the whole path so the user sees what the
  /// drag has covered.
  final List<Offset>? eraserPath;

  /// World-space radius of the eraser footprint, in logical px at `scale == 1`.
  final double eraserRadius;

  /// World-space vertices of the in-progress lasso loop, or `null`.
  ///
  /// Stroked as an auto-closed dashed-style polygon while the loop is being
  /// traced.
  final List<Offset>? lassoPath;

  /// World-space bounding box of the current lasso selection, or `null`.
  ///
  /// Drawn as a rounded outline with corner ticks so a committed selection is
  /// visible (and obviously draggable) after the lasso closes.
  final Rect? selectionBounds;

  /// Accent colour for selection and lasso chrome (gold, matching the theme).
  static const Color _accent = Color(0xFFE8B84B);

  @override
  void paint(Canvas canvas, Size size) {
    _paintSelectionBox(canvas);
    _paintLasso(canvas);
    _paintEraserTrail(canvas);
    _paintHoverRing(canvas);
  }

  /// Draws the tool hover ring at [hoverPointWorld], if any.
  void _paintHoverRing(Canvas canvas) {
    final Offset? hoverPoint = hoverPointWorld;
    if (hoverPoint == null) {
      return;
    }
    // Skip the static hover ring while an eraser drag is live — the eraser
    // footprint at the drag head already shows the cursor.
    if (isEraserHover && (eraserPath?.isNotEmpty ?? false)) {
      return;
    }

    final Offset center = CanvasTransform.toScreen(viewport, hoverPoint);
    final double radius = hoverRadius * viewport.scale;
    if (radius <= 0) {
      return;
    }

    if (isEraserHover) {
      _strokeEraserCircle(canvas, center, radius);
    } else {
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x66FFFFFF);
      canvas.drawCircle(center, radius, paint);
    }
  }

  /// Draws the eraser footprint and the trail it has swept this drag.
  void _paintEraserTrail(Canvas canvas) {
    final List<Offset>? path = eraserPath;
    if (path == null || path.isEmpty) {
      return;
    }

    final List<Offset> screenPath = <Offset>[
      for (final Offset world in path)
        CanvasTransform.toScreen(viewport, world),
    ];
    final double screenRadius = eraserRadius * viewport.scale;

    // Faint trail along the drag.
    if (screenPath.length > 1) {
      final Path trail = Path()
        ..moveTo(screenPath.first.dx, screenPath.first.dy);
      for (int i = 1; i < screenPath.length; i++) {
        trail.lineTo(screenPath[i].dx, screenPath[i].dy);
      }
      canvas.drawPath(
        trail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (screenRadius * 2).clamp(2.0, double.infinity)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0x1FFFFFFF),
      );
    }

    // Footprint at the drag head.
    if (screenRadius > 0) {
      _strokeEraserCircle(canvas, screenPath.last, screenRadius);
    }
  }

  /// Strokes one eraser footprint circle: a soft fill plus a crisp ring.
  void _strokeEraserCircle(Canvas canvas, Offset center, double radius) {
    canvas
      ..drawCircle(center, radius, Paint()..color = const Color(0x14FFFFFF))
      ..drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xCCFFFFFF),
      );
  }

  /// Draws the in-progress lasso loop as an auto-closed outline.
  void _paintLasso(Canvas canvas) {
    final List<Offset>? path = lassoPath;
    if (path == null || path.length < 2) {
      return;
    }

    final Path screenPath = Path();
    final Offset first = CanvasTransform.toScreen(viewport, path.first);
    screenPath.moveTo(first.dx, first.dy);
    for (int i = 1; i < path.length; i++) {
      final Offset p = CanvasTransform.toScreen(viewport, path[i]);
      screenPath.lineTo(p.dx, p.dy);
    }
    // Auto-closed: a faint segment links the head back to the start so the
    // user previews the loop the controller will close on pointer-up.
    screenPath.close();

    canvas
      ..drawPath(screenPath, Paint()..color = _accent.withValues(alpha: 0.10))
      ..drawPath(
        screenPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round
          ..color = _accent.withValues(alpha: 0.9),
      );
  }

  /// Draws the bounding box around a committed lasso selection.
  void _paintSelectionBox(Canvas canvas) {
    final Rect? bounds = selectionBounds;
    if (bounds == null || bounds.isEmpty) {
      return;
    }

    // Project the four world corners; rotation means the screen-space box is
    // the bounds of the (possibly skewed) projected corners.
    final List<Offset> corners = <Offset>[
      CanvasTransform.toScreen(viewport, bounds.topLeft),
      CanvasTransform.toScreen(viewport, bounds.topRight),
      CanvasTransform.toScreen(viewport, bounds.bottomRight),
      CanvasTransform.toScreen(viewport, bounds.bottomLeft),
    ];
    double minX = corners.first.dx;
    double maxX = corners.first.dx;
    double minY = corners.first.dy;
    double maxY = corners.first.dy;
    for (final Offset c in corners) {
      if (c.dx < minX) minX = c.dx;
      if (c.dx > maxX) maxX = c.dx;
      if (c.dy < minY) minY = c.dy;
      if (c.dy > maxY) maxY = c.dy;
    }
    final Rect screenRect = Rect.fromLTRB(minX, minY, maxX, maxY).inflate(6);

    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(screenRect, const Radius.circular(4)),
        Paint()..color = _accent.withValues(alpha: 0.08),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(screenRect, const Radius.circular(4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = _accent,
      );

    // Corner ticks — a light affordance that the box can be grabbed.
    const double tick = 7;
    final Paint tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = _accent;
    for (final Offset corner in <Offset>[
      screenRect.topLeft,
      screenRect.topRight,
      screenRect.bottomLeft,
      screenRect.bottomRight,
    ]) {
      final double sx = corner.dx < screenRect.center.dx ? 1 : -1;
      final double sy = corner.dy < screenRect.center.dy ? 1 : -1;
      canvas
        ..drawLine(corner, corner + Offset(tick * sx, 0), tickPaint)
        ..drawLine(corner, corner + Offset(0, tick * sy), tickPaint);
    }
  }

  @override
  bool shouldRepaint(CanvasOverlayPainter oldDelegate) =>
      oldDelegate.viewport != viewport ||
      oldDelegate.hoverPointWorld != hoverPointWorld ||
      oldDelegate.hoverRadius != hoverRadius ||
      oldDelegate.isEraserHover != isEraserHover ||
      !identical(oldDelegate.eraserPath, eraserPath) ||
      oldDelegate.eraserRadius != eraserRadius ||
      !identical(oldDelegate.lassoPath, lassoPath) ||
      oldDelegate.selectionBounds != selectionBounds;
}
