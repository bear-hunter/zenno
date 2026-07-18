import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'package:zenno/canvas/engine/canvas_transform.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/render/selection_overlay_geometry.dart';

/// Paints transient canvas chrome that sits above the ink layers.
///
/// This is the top compositing layer: it draws non-persisted feedback —
/// the tool hover ring, the eraser footprint and its swept trail, the
/// in-progress lasso loop, and the bounding box around a lasso selection.
/// Everything is projected through [viewport]; tool chrome such as hover
/// rings, lasso outlines and selection borders keeps a constant on-screen
/// weight.
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
    this.hasClipboardContent = false,
  });

  /// The camera through which world points are projected to screen.
  final ViewportState viewport;

  /// World-space position of the hover indicator, or `null` to draw nothing.
  final Offset? hoverPointWorld;

  /// Screen-space radius of the hover ring.
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

  /// Screen-space radius of the eraser footprint.
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

  /// Whether the selection-overlay Paste action is currently available.
  final bool hasClipboardContent;

  /// Accent colour for selection and lasso chrome (gold, matching the theme).
  static const Color _accent = Color(0xFFE8B84B);

  @override
  void paint(Canvas canvas, Size size) {
    _paintSelectionBox(canvas, size);
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
    final double radius = hoverRadius;
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
    final double screenRadius = eraserRadius;

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

  /// Draws the interactive frame around a committed lasso selection.
  void _paintSelectionBox(Canvas canvas, Size size) {
    final Rect? bounds = selectionBounds;
    if (bounds == null || bounds.isEmpty) {
      return;
    }
    final SelectionOverlayGeometry geometry =
        SelectionOverlayGeometry.fromWorldBounds(
          bounds: bounds,
          viewport: viewport,
          canvasSize: size,
        );
    final Rect screenRect = geometry.frameRect;

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

    final Paint connectorPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = _accent.withValues(alpha: 0.85);
    canvas.drawLine(
      geometry.connectorStart,
      geometry.rotationCenter,
      connectorPaint,
    );

    final Paint handleFill = Paint()..color = const Color(0xFF181820);
    final Paint handleBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _accent;
    for (final SelectionOverlayTarget target in geometry.scaleTargets) {
      final Offset center = geometry.centerFor(target);
      canvas
        ..drawCircle(
          center,
          SelectionOverlayGeometry.cornerVisualRadius,
          handleFill,
        )
        ..drawCircle(
          center,
          SelectionOverlayGeometry.cornerVisualRadius,
          handleBorder,
        );
    }

    _paintRotationHandle(canvas, geometry.rotationCenter);
    _paintDoneHandle(canvas, geometry.doneCenter);
    _paintCopyHandle(canvas, geometry.copyCenter);
    _paintPasteHandle(
      canvas,
      geometry.pasteCenter,
      enabled: hasClipboardContent,
    );
    _paintDeleteHandle(canvas, geometry.deleteCenter);
  }

  void _paintRotationHandle(Canvas canvas, Offset center) {
    _paintActionBase(canvas, center);
    final Rect arcRect = Rect.fromCircle(center: center, radius: 5.5);
    final Paint glyph = _actionGlyph(strokeWidth: 1.8);
    canvas.drawArc(arcRect, -math.pi * 0.15, math.pi * 1.45, false, glyph);
    final Offset arrow = center + const Offset(5.4, -2.2);
    canvas
      ..drawLine(arrow, arrow + const Offset(-3.2, -0.4), glyph)
      ..drawLine(arrow, arrow + const Offset(-0.5, 3.1), glyph);
  }

  void _paintDoneHandle(Canvas canvas, Offset center) {
    _paintActionBase(canvas, center);
    final Paint glyph = _actionGlyph(strokeWidth: 2);
    const double extent = 3.5;
    canvas
      ..drawLine(
        center - const Offset(extent, extent),
        center + const Offset(extent, extent),
        glyph,
      )
      ..drawLine(
        center + const Offset(extent, -extent),
        center + const Offset(-extent, extent),
        glyph,
      );
  }

  void _paintCopyHandle(Canvas canvas, Offset center) {
    _paintActionBase(canvas, center);
    final Paint glyph = _actionGlyph(strokeWidth: 1.5);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center - const Offset(2, 2),
            width: 7,
            height: 9,
          ),
          const Radius.circular(1),
        ),
        glyph,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center + const Offset(2, 2),
            width: 7,
            height: 9,
          ),
          const Radius.circular(1),
        ),
        glyph,
      );
  }

  void _paintPasteHandle(
    Canvas canvas,
    Offset center, {
    required bool enabled,
  }) {
    _paintActionBase(canvas, center, enabled: enabled);
    final Paint glyph = _actionGlyph(strokeWidth: 1.5, enabled: enabled);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center + const Offset(0, 1),
            width: 9,
            height: 11,
          ),
          const Radius.circular(1.5),
        ),
        glyph,
      )
      ..drawLine(
        center - const Offset(2.5, 4.5),
        center + const Offset(2.5, -4.5),
        glyph,
      );
  }

  void _paintDeleteHandle(Canvas canvas, Offset center) {
    _paintActionBase(canvas, center);
    final Paint glyph = _actionGlyph(strokeWidth: 1.5);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center + const Offset(0, 1.5),
            width: 7,
            height: 8,
          ),
          const Radius.circular(1),
        ),
        glyph,
      )
      ..drawLine(
        center - const Offset(5, 3.5),
        center + const Offset(5, -3.5),
        glyph,
      )
      ..drawLine(
        center - const Offset(2, 5.5),
        center + const Offset(2, -5.5),
        glyph,
      );
  }

  void _paintActionBase(Canvas canvas, Offset center, {bool enabled = true}) {
    final Color color = enabled ? _accent : _accent.withValues(alpha: 0.35);
    canvas
      ..drawCircle(
        center,
        SelectionOverlayGeometry.actionVisualRadius,
        Paint()..color = const Color(0xFF181820),
      )
      ..drawCircle(
        center,
        SelectionOverlayGeometry.actionVisualRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color,
      );
  }

  Paint _actionGlyph({double strokeWidth = 2, bool enabled = true}) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = enabled ? _accent : _accent.withValues(alpha: 0.35);

  @override
  bool shouldRepaint(CanvasOverlayPainter oldDelegate) =>
      oldDelegate.viewport != viewport ||
      oldDelegate.hoverPointWorld != hoverPointWorld ||
      oldDelegate.hoverRadius != hoverRadius ||
      oldDelegate.isEraserHover != isEraserHover ||
      !identical(oldDelegate.eraserPath, eraserPath) ||
      oldDelegate.eraserRadius != eraserRadius ||
      !identical(oldDelegate.lassoPath, lassoPath) ||
      oldDelegate.selectionBounds != selectionBounds ||
      oldDelegate.hasClipboardContent != hasClipboardContent;
}
