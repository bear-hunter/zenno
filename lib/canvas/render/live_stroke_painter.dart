import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:zenno/canvas/engine/canvas_transform.dart';
import 'package:zenno/canvas/engine/stroke_builder.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/render/shape_painter.dart';

/// The two pieces a live stroke is drawn from: a frozen head and a live tail.
class LiveStrokeGeometry {
  const LiveStrokeGeometry({required this.tail, this.prefix});

  /// Everything tessellated so far, pre-recorded. `null` for a young stroke
  /// that is still cheap to rebuild whole.
  final ui.Picture? prefix;

  /// The freshly tessellated end of the stroke, rebuilt every frame.
  final Path tail;
}

/// Builds the in-progress stroke's geometry incrementally.
///
/// A live stroke grows by a sample every few milliseconds. Re-running
/// `getStroke` over the whole buffer each frame makes a stroke cost O(n²) over
/// its life, so a long annotation visibly degrades as it is drawn.
///
/// Instead the settled head of the stroke is tessellated once and folded into a
/// [ui.Picture]; only the last [_blockSize] or so samples are rebuilt per
/// frame. Each frozen block re-consumes [_overlap] samples from before its
/// start, and the tail does the same, so the smoothing filter has continuous
/// input across the seams and the filled regions overlap rather than gap.
class LiveStrokePathCache {
  /// Samples accumulated before the head is extended again.
  static const int _blockSize = 48;

  /// Samples each block and the tail re-consume for smoothing continuity.
  static const int _overlap = 10;

  /// Below this length a stroke is rebuilt whole — the bookkeeping is not
  /// worth it, and short strokes are where end-cap fidelity matters most.
  static const int _incrementalThreshold = 96;

  String? _strokeId;
  ui.Picture? _prefix;
  int _prefixEnd = 0;

  Path? _tail;
  int? _tailRevision;

  void clear() {
    _prefix?.dispose();
    _prefix = null;
    _prefixEnd = 0;
    _strokeId = null;
    _tail = null;
    _tailRevision = null;
  }

  /// Returns the geometry for [stroke] at [revision], reusing frozen work.
  ///
  /// [blockPaint] is the opaque paint the frozen blocks are recorded with; the
  /// painter applies any transparency to the composed result instead, so
  /// overlapping blocks cannot double-darken at a seam.
  LiveStrokeGeometry geometryFor({
    required Stroke stroke,
    required int revision,
    required Paint blockPaint,
  }) {
    if (_strokeId != stroke.id) {
      clear();
      _strokeId = stroke.id;
    }

    final List<StrokePoint> points = stroke.points;
    if (stroke.tool == StrokeToolKind.fill) {
      return LiveStrokeGeometry(tail: buildFillBoundaryPath(points));
    }

    if (points.length >= _incrementalThreshold &&
        points.length - _prefixEnd > _blockSize + _overlap) {
      _freezeBlock(stroke, blockPaint);
    }

    if (_tailRevision != revision || _tail == null) {
      final int tailStart = _prefixEnd == 0
          ? 0
          : (_prefixEnd - _overlap).clamp(0, points.length);
      _tail = _outlineFor(stroke, tailStart, points.length, predictTail: true);
      _tailRevision = revision;
    }

    return LiveStrokeGeometry(prefix: _prefix, tail: _tail!);
  }

  /// Folds the next settled block of samples into the frozen prefix picture.
  ///
  /// The previous picture is replayed into the new recording rather than
  /// re-tessellated, so extending the head costs one block, not one stroke.
  void _freezeBlock(Stroke stroke, Paint blockPaint) {
    final List<StrokePoint> points = stroke.points;
    final int newPrefixEnd = points.length - _overlap;
    final int blockStart = _prefixEnd == 0
        ? 0
        : (_prefixEnd - _overlap).clamp(0, points.length);
    if (newPrefixEnd <= blockStart) {
      return;
    }

    final Path blockPath = _outlineFor(stroke, blockStart, newPrefixEnd);
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final ui.Picture? previous = _prefix;
    if (previous != null) {
      canvas.drawPicture(previous);
    }
    canvas.drawPath(blockPath, blockPaint);

    _prefix = recorder.endRecording();
    previous?.dispose();
    _prefixEnd = newPrefixEnd;
  }

  Path _outlineFor(
    Stroke stroke,
    int start,
    int end, {
    bool predictTail = false,
  }) {
    final List<StrokePoint> slice = start == 0 && end == stroke.points.length
        ? stroke.points
        : stroke.points.sublist(start, end);
    return buildStrokeOutline(
      predictTail ? _withPredictedTip(slice) : slice,
      size: stroke.width,
      tool: stroke.tool,
      isComplete: false,
    );
  }

  /// Appends one extrapolated sample ahead of the newest one.
  ///
  /// A sample reaches the screen roughly a frame after the nib produced it, so
  /// ink visibly trails the pen. Extending the drawn tail by about one frame of
  /// travel closes most of that gap. It is deliberately applied to the painted
  /// tail only and never to the stroke buffer, so nothing predicted is ever
  /// committed or persisted.
  ///
  /// The step is capped, and dropped entirely when the stroke is turning
  /// sharply, so a corner cannot overshoot into a visible spike.
  static List<StrokePoint> _withPredictedTip(List<StrokePoint> points) {
    if (points.length < 3) {
      return points;
    }
    final StrokePoint last = points[points.length - 1];
    final StrokePoint previous = points[points.length - 2];
    final StrokePoint earlier = points[points.length - 3];

    final Offset recent = last.offset - previous.offset;
    final Offset prior = previous.offset - earlier.offset;
    final double recentLength = recent.distance;
    final double priorLength = prior.distance;
    if (recentLength < 0.01 || priorLength < 0.01) {
      return points;
    }

    // cos of the turn angle: 1 is straight ahead, 0 a right-angle corner.
    final double alignment =
        (recent.dx * prior.dx + recent.dy * prior.dy) /
        (recentLength * priorLength);
    if (alignment < _minPredictionAlignment) {
      return points;
    }

    final double step = math.min(
      recentLength * _predictionFraction,
      _maxPredictionDistance,
    );
    final Offset direction = recent / recentLength;
    final Offset tip = last.offset + direction * step;

    return <StrokePoint>[
      ...points,
      StrokePoint(
        tip.dx,
        tip.dy,
        last.pressure,
        tiltX: last.tiltX,
        tiltY: last.tiltY,
        azimuth: last.azimuth,
        timestampMicros: last.timestampMicros,
        velocity: last.velocity,
      ),
    ];
  }

  /// Fraction of the last sample's travel to extrapolate forward.
  static const double _predictionFraction = 0.8;

  /// Hard cap on the predicted step, in world units.
  static const double _maxPredictionDistance = 12.0;

  /// Straightness required before predicting, as cos of the turn angle.
  static const double _minPredictionAlignment = 0.7;
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

    final Color color = Color(stroke.color);
    final double userOpacity = ((stroke.color >>> 24) & 0xFF) / 255;
    final double toolOpacity = switch (stroke.tool) {
      StrokeToolKind.highlighter => _highlighterOpacity,
      StrokeToolKind.pencil => _pencilOpacity,
      StrokeToolKind.marker => _markerOpacity,
      StrokeToolKind.airbrush => _airbrushOpacity,
      StrokeToolKind.fill || StrokeToolKind.pen => 1.0,
    };
    final double alpha = toolOpacity * userOpacity;
    final BlendMode blendMode = stroke.tool == StrokeToolKind.highlighter
        ? BlendMode.multiply
        : BlendMode.srcOver;

    // Blocks are composed opaque and the stroke's transparency is applied to
    // the composed result, so the overlap between blocks cannot show as a
    // darker seam.
    final Paint opaquePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 1);

    final LiveStrokeGeometry geometry =
        pathCache?.geometryFor(
          stroke: stroke,
          revision: liveStrokeRevision,
          blockPaint: opaquePaint,
        ) ??
        LiveStrokeGeometry(
          tail: stroke.tool == StrokeToolKind.fill
              ? buildFillBoundaryPath(stroke.points)
              : buildStrokeOutline(
                  stroke.points,
                  size: stroke.width,
                  tool: stroke.tool,
                  isComplete: false,
                ),
        );

    final bool needsLayer = alpha < 1 || blendMode != BlendMode.srcOver;
    if (needsLayer) {
      canvas.saveLayer(
        null,
        Paint()
          ..color = const Color(0xFF000000).withValues(alpha: alpha)
          ..blendMode = blendMode,
      );
    }
    if (geometry.prefix case final ui.Picture prefix) {
      canvas.drawPicture(prefix);
    }
    canvas.drawPath(
      geometry.tail,
      needsLayer ? opaquePaint : (Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: alpha)),
    );
    if (needsLayer) {
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(LiveStrokePainter oldDelegate) =>
      oldDelegate.liveStrokeRevision != liveStrokeRevision ||
      oldDelegate.liveStroke != liveStroke ||
      oldDelegate.liveShape != liveShape ||
      oldDelegate.viewport != viewport;
}
