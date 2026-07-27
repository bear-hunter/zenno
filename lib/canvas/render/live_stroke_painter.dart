import 'package:flutter/rendering.dart';
import 'package:zenno/canvas/engine/canvas_transform.dart';
import 'package:zenno/canvas/engine/stroke_builder.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/render/shape_painter.dart';

class LiveStrokePathCache {
  static const int _stableBatchSize = 64;
  static const int _tailPointLimit = 128;
  static const int _overlapPointCount = 16;

  String? _strokeId;
  int? _revision;
  int? _scaleBucket;
  StrokeRenderQuality? _quality;
  Path? _path;
  Path? _stablePath;
  int _stablePointCount = 0;
  int _lastPointCount = 0;
  StrokePoint? _firstPoint;
  StrokePoint? _lastPoint;
  double? _strokeWidth;
  StrokeToolKind? _strokeTool;
  int _lastRebuiltPointCount = 0;

  /// Largest input slice rebuilt by the latest [pathFor] call.
  int get lastRebuiltPointCount => _lastRebuiltPointCount;

  void clear() {
    _strokeId = null;
    _revision = null;
    _scaleBucket = null;
    _quality = null;
    _path = null;
    _stablePath = null;
    _stablePointCount = 0;
    _lastPointCount = 0;
    _firstPoint = null;
    _lastPoint = null;
    _strokeWidth = null;
    _strokeTool = null;
    _lastRebuiltPointCount = 0;
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

    final bool appendCompatible =
        _strokeId == stroke.id &&
        _scaleBucket == scaleBucket &&
        _quality == quality &&
        _strokeWidth == stroke.width &&
        _strokeTool == stroke.tool &&
        stroke.points.length >= _lastPointCount &&
        (stroke.points.isEmpty || stroke.points.first == _firstPoint) &&
        (_lastPointCount == 0 ||
            stroke.points[_lastPointCount - 1] == _lastPoint);
    if (!appendCompatible) {
      _stablePath = null;
      _stablePointCount = 0;
    }

    _lastRebuiltPointCount = 0;
    final Path next;
    if (stroke.tool == StrokeToolKind.fill) {
      next = buildFillBoundaryPath(stroke.points);
      _lastRebuiltPointCount = stroke.points.length;
    } else {
      _extendStablePrefix(
        stroke: stroke,
        viewportScale: viewportScale,
        quality: quality,
      );
      final int tailStart = (_stablePointCount - _overlapPointCount).clamp(
        0,
        stroke.points.length,
      );
      final List<StrokePoint> tailPoints = stroke.points.sublist(tailStart);
      final Path tailPath = buildStrokeOutline(
        tailPoints,
        size: stroke.width,
        viewportScale: viewportScale,
        quality: quality,
        isComplete: false,
      );
      _lastRebuiltPointCount = tailPoints.length > _lastRebuiltPointCount
          ? tailPoints.length
          : _lastRebuiltPointCount;
      next = _stablePath == null
          ? tailPath
          : (Path.from(_stablePath!)..addPath(tailPath, Offset.zero));
    }
    _strokeId = stroke.id;
    _revision = revision;
    _scaleBucket = scaleBucket;
    _quality = quality;
    _path = next;
    _lastPointCount = stroke.points.length;
    _firstPoint = stroke.points.isEmpty ? null : stroke.points.first;
    _lastPoint = stroke.points.isEmpty ? null : stroke.points.last;
    _strokeWidth = stroke.width;
    _strokeTool = stroke.tool;
    return next;
  }

  void _extendStablePrefix({
    required Stroke stroke,
    required double viewportScale,
    required StrokeRenderQuality quality,
  }) {
    final int availableStablePoints = stroke.points.length - _tailPointLimit;
    while (availableStablePoints - _stablePointCount >= _stableBatchSize) {
      final int nextStablePointCount = _stablePointCount + _stableBatchSize;
      final int chunkStart = _stablePointCount == 0
          ? 0
          : _stablePointCount - _overlapPointCount;
      final int chunkEnd = (nextStablePointCount + _overlapPointCount).clamp(
        0,
        stroke.points.length,
      );
      final List<StrokePoint> chunkPoints = stroke.points.sublist(
        chunkStart,
        chunkEnd,
      );
      final Path chunkPath = buildStrokeOutline(
        chunkPoints,
        size: stroke.width,
        viewportScale: viewportScale,
        quality: quality,
        isComplete: false,
      );
      if (_stablePath == null) {
        _stablePath = chunkPath;
      } else {
        _stablePath!.addPath(chunkPath, Offset.zero);
      }
      _stablePointCount = nextStablePointCount;
      if (chunkPoints.length > _lastRebuiltPointCount) {
        _lastRebuiltPointCount = chunkPoints.length;
      }
    }
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
        (stroke.tool == StrokeToolKind.fill
            ? buildFillBoundaryPath(stroke.points)
            : buildStrokeOutline(
                stroke.points,
                size: stroke.width,
                viewportScale: viewport.scale,
                quality: strokeRenderQualityForScale(viewport.scale),
                isComplete: false,
              ));

    final paint = Paint()..style = PaintingStyle.fill;
    final color = Color(stroke.color);
    final double userOpacity = ((stroke.color >>> 24) & 0xFF) / 255;
    switch (stroke.tool) {
      case StrokeToolKind.highlighter:
        paint
          ..color = color.withValues(alpha: _highlighterOpacity * userOpacity)
          ..blendMode = BlendMode.multiply;
      case StrokeToolKind.pencil:
        paint.color = color.withValues(alpha: _pencilOpacity * userOpacity);
      case StrokeToolKind.marker:
        paint.color = color.withValues(alpha: _markerOpacity * userOpacity);
      case StrokeToolKind.airbrush:
        paint.color = color.withValues(alpha: _airbrushOpacity * userOpacity);
      case StrokeToolKind.fill:
        paint.color = color;
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
