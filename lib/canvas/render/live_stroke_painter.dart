import 'package:flutter/rendering.dart';
import 'package:zenno/canvas/engine/canvas_transform.dart';
import 'package:zenno/canvas/engine/stroke_builder.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';

/// Paints the single in-progress [liveStroke] under the current [viewport].
///
/// This mirrors `ElementsPainter` but for the stroke the user is actively
/// drawing: the outline is built with `isComplete: false` so the tail follows
/// the latest sample, and a null [liveStroke] paints nothing. The live stroke
/// has its own layer so in-progress ink never triggers a committed-layer
/// repaint, protecting ink latency.
class LiveStrokePainter extends CustomPainter {
  /// Creates a painter for the in-progress [liveStroke] and [viewport].
  const LiveStrokePainter({required this.liveStroke, required this.viewport});

  /// The stroke currently being drawn, or `null` when nothing is in progress.
  final Stroke? liveStroke;

  /// The camera through which the world stroke is observed.
  final ViewportState viewport;

  /// Opacity applied to highlighter ink so it reads as a translucent marker.
  static const double _highlighterOpacity = 0.35;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = liveStroke;
    if (stroke == null || stroke.points.isEmpty) {
      return;
    }

    canvas.save();
    canvas.transform(CanvasTransform.worldToScreenMatrix(viewport).storage);

    final path = buildStrokeOutline(
      stroke.points,
      size: stroke.width,
      isComplete: false,
    );

    final paint = Paint()..style = PaintingStyle.fill;
    final color = Color(stroke.color);
    if (stroke.tool == StrokeToolKind.highlighter) {
      paint
        ..color = color.withValues(alpha: _highlighterOpacity)
        ..blendMode = BlendMode.multiply;
    } else {
      paint.color = color;
    }

    canvas.drawPath(path, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(LiveStrokePainter oldDelegate) =>
      oldDelegate.liveStroke != liveStroke ||
      oldDelegate.viewport != viewport;
}
