import 'package:flutter/rendering.dart';
import 'package:zenno/canvas/engine/canvas_transform.dart';
import 'package:zenno/canvas/engine/stroke_builder.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/render/shape_painter.dart';

class LiveStrokePathCache {
  String? _strokeId;
  int? _revision;
  int? _scaleBucket;
  StrokeRenderQuality? _quality;
  Path? _path;

  void clear() {
    _strokeId = null;
    _revision = null;
    _scaleBucket = null;
    _quality = null;
    _path = null;
  }

  Path pathFor({
    required Stroke stroke,
    required int revision,
    required double viewportScale,
  }) {
    final StrokeRenderQuality quality = strokeRenderQualityForScale(
      viewportScale,
    );
    final int scaleBucket = strokeScaleBucket(viewportScale);
    final Path? cached = _path;
    if (cached != null &&
        _strokeId == stroke.id &&
        _revision == revision &&
        _scaleBucket == scaleBucket &&
        _quality == quality) {
      return cached;
    }
    final Path next = buildStrokeOutline(
      stroke.points,
      size: stroke.width,
      viewportScale: viewportScale,
      quality: quality,
      isComplete: false,
    );
    _strokeId = stroke.id;
    _revision = revision;
    _scaleBucket = scaleBucket;
    _quality = quality;
    _path = next;
    return next;
  }
}

/// Paints the single in-progress [liveStroke] under the current [viewport].
///
/// This mirrors `ElementsPainter` but for the stroke the user is actively
/// drawing: the outline is built with `isComplete: false` so the tail follows
/// the latest sample, and a null [liveStroke] paints nothing. The live stroke
/// has its own layer so in-progress ink never triggers a committed-layer
/// repaint, protecting ink latency.
class LiveStrokePainter extends CustomPainter {
  /// Creates a painter for the in-progress [liveStroke] and [viewport].
  const LiveStrokePainter({
    required this.liveStroke,
    required this.liveStrokeRevision,
    required this.viewport,
    this.liveShape,
    this.pathCache,
  });

  /// The stroke currently being drawn, or `null` when nothing is in progress.
  final Stroke? liveStroke;

  /// Monotonic token bumped when the active stroke's point buffer changes.
  final int liveStrokeRevision;

  /// The crisp shape currently being drawn, or `null`.
  final ShapeElement? liveShape;

  /// The camera through which the world stroke is observed.
  final ViewportState viewport;

  /// Optional cache owned by the view so path work survives painter instances.
  final LiveStrokePathCache? pathCache;

  /// Opacity applied to highlighter ink so it reads as a translucent marker.
  static const double _highlighterOpacity = 0.35;
  static const double _pencilOpacity = 0.72;
  static const double _markerOpacity = 0.78;
  static const double _airbrushOpacity = 0.42;

  @override
  void paint(Canvas canvas, Size size) {
    final ShapeElement? shape = liveShape;
    if (shape != null) {
      canvas.save();
      canvas.transform(CanvasTransform.worldToScreenMatrix(viewport).storage);
      paintShapeElement(canvas, shape, selected: false);
      canvas.restore();
      return;
    }

    final stroke = liveStroke;
    if (stroke == null || stroke.points.isEmpty) {
      return;
    }

    canvas.save();
    canvas.transform(CanvasTransform.worldToScreenMatrix(viewport).storage);

    final path =
        pathCache?.pathFor(
          stroke: stroke,
          revision: liveStrokeRevision,
          viewportScale: viewport.scale,
        ) ??
        buildStrokeOutline(
          stroke.points,
          size: stroke.width,
          viewportScale: viewport.scale,
          quality: strokeRenderQualityForScale(viewport.scale),
          isComplete: false,
        );

    final paint = Paint()..style = PaintingStyle.fill;
    final color = Color(stroke.color);
    switch (stroke.tool) {
      case StrokeToolKind.highlighter:
        paint
          ..color = color.withValues(alpha: _highlighterOpacity)
          ..blendMode = BlendMode.multiply;
      case StrokeToolKind.pencil:
        paint.color = color.withValues(alpha: _pencilOpacity);
      case StrokeToolKind.marker:
        paint.color = color.withValues(alpha: _markerOpacity);
      case StrokeToolKind.airbrush:
        paint.color = color.withValues(alpha: _airbrushOpacity);
      case StrokeToolKind.pen:
        paint.color = color;
    }

    canvas.drawPath(path, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(LiveStrokePainter oldDelegate) =>
      oldDelegate.liveStrokeRevision != liveStrokeRevision ||
      oldDelegate.liveStroke != liveStroke ||
      oldDelegate.liveShape != liveShape ||
      oldDelegate.viewport != viewport;
}
