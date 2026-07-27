import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/rendering.dart';

import 'package:zenno/canvas/engine/canvas_transform.dart';
import 'package:zenno/canvas/engine/spatial_index.dart';
import 'package:zenno/canvas/engine/stroke_builder.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/selection_transform.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/render/shape_painter.dart';

/// Paints the committed [elements] layer, culled to the visible viewport.
///
/// The world-to-screen transform is applied to the [Canvas] once, so every
/// element is drawn in world coordinates. In interactive use the controller
/// supplies only the spatial-query hits in [elements], already in paint order.
/// Standalone callers may omit [allElementsById] and [paintOrderById], in which
/// case the painter performs its legacy query-and-filter fallback.
///
/// Elements are painted in ascending [CanvasElement.zIndex] order (the order
/// the controller already keeps [elements] in). The `switch` over the element
/// kind is exhaustive: [InkElement] draws its cached outline path, while
/// [ImageElement] and [PdfElement] blit their decoded `ui.Image` into the
/// element's world rectangle (or, while the raster is still loading, a neutral
/// placeholder), and [LinkElement] draws a rounded gold chip. Highlighter ink
/// is rendered semi-transparent with [BlendMode.multiply] for a marker look.
///
/// The expensive `perfect_freehand` outline of each ink element is **not**
/// rebuilt here per frame: [InkElement.outlinePath] builds it once and caches
/// it for the element's (immutable) lifetime. This painter only walks the
/// culled subset and issues a `drawPath` per element, so a pan or repaint with
/// unchanged elements does no geometry work.
//
/// Cache for committed element pictures grouped by fixed world-space tiles.
///
/// Owned by the view rather than the painter so pictures survive repaint
/// delegate instances. A changed element/raster signature invalidates the
/// whole cache; otherwise each visible tile is recorded once and reused while
/// panning/zooming.
class ElementsTileCache {
  /// Creates a tile-picture cache.
  ElementsTileCache({this.maxTiles = 96});

  /// Maximum cached tile pictures before least-recently-used eviction.
  final int maxTiles;

  static const double tileSize = 2048.0;

  final Map<_TileKey, _TilePicture> _pictures = <_TileKey, _TilePicture>{};
  final StrokePathCache strokePathCache = StrokePathCache();
  int _revision = 0;
  int _tick = 0;

  /// Number of currently retained tile pictures.
  int get tileCount => _pictures.length;

  /// Clears all retained pictures.
  void clear() {
    for (final picture in _pictures.values) {
      picture.picture.dispose();
    }
    _pictures.clear();
    strokePathCache.clear();
  }

  /// Releases native picture resources.
  void dispose() => clear();

  void _syncRevision({
    required List<CanvasElement> elements,
    required int? revision,
  }) {
    final int nextRevision =
        revision ?? Object.hashAll(elements.map(_elementRevisionPart));
    if (nextRevision == _revision) {
      return;
    }
    _revision = nextRevision;
    clear();
  }

  ui.Picture _pictureFor({
    required _TileKey key,
    required Rect tileRect,
    required Map<String, CanvasElement> elementsById,
    required Map<String, int> paintOrderById,
    required SpatialIndex spatialIndex,
    required void Function(Canvas canvas, CanvasElement element) paintElement,
  }) {
    final cached = _pictures[key];
    if (cached != null) {
      cached.lastUsed = ++_tick;
      return cached.picture;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.clipRect(tileRect);

    final List<CanvasElement> tileElements =
        <CanvasElement>[
          for (final String id in spatialIndex.query(tileRect))
            if (elementsById[id] != null) elementsById[id]!,
        ]..sort(
          (CanvasElement a, CanvasElement b) =>
              paintOrderById[a.id]!.compareTo(paintOrderById[b.id]!),
        );
    for (final element in tileElements) {
      paintElement(canvas, element);
    }

    final picture = recorder.endRecording();
    _pictures[key] = _TilePicture(picture, ++_tick);
    _evictIfNeeded();
    return picture;
  }

  void _evictIfNeeded() {
    while (_pictures.length > maxTiles) {
      _TileKey? oldestKey;
      int oldestTick = 1 << 62;
      for (final entry in _pictures.entries) {
        if (entry.value.lastUsed < oldestTick) {
          oldestTick = entry.value.lastUsed;
          oldestKey = entry.key;
        }
      }
      final removed = _pictures.remove(oldestKey);
      removed?.picture.dispose();
    }
  }

  static Object _elementRevisionPart(CanvasElement element) {
    final Rect b = element.worldBounds;
    final Object rasterPart = switch (element) {
      ImageElement(:final raster) => Object.hash(
        identityHashCode(raster),
        raster?.width,
        raster?.height,
      ),
      PdfElement(:final raster) => Object.hash(
        identityHashCode(raster),
        raster?.width,
        raster?.height,
      ),
      TextElement(:final text, :final color, :final fontSize) => Object.hash(
        text,
        color,
        fontSize,
      ),
      ShapeElement(
        :final shapeKind,
        :final start,
        :final end,
        :final color,
        :final strokeWidth,
        :final arrowBody,
        :final arrowStartHead,
        :final arrowEndHead,
        :final arrowHeadScale,
        :final controlPoints,
        :final legacyArrow,
      ) =>
        Object.hashAll(<Object?>[
          shapeKind,
          start,
          end,
          color,
          strokeWidth,
          arrowBody,
          arrowStartHead,
          arrowEndHead,
          arrowHeadScale,
          Object.hashAll(controlPoints),
          legacyArrow,
        ]),
      _ => 0,
    };
    return Object.hash(
      element.id,
      element.zIndex,
      b.left,
      b.top,
      b.width,
      b.height,
      element.hashCode,
      rasterPart,
    );
  }
}

class StrokePathCacheKey {
  const StrokePathCacheKey({
    required this.strokeId,
    required this.revision,
    required this.scaleBucket,
    required this.quality,
    required this.isComplete,
  });

  final String strokeId;
  final int revision;
  final int scaleBucket;
  final StrokeRenderQuality quality;
  final bool isComplete;

  @override
  bool operator ==(Object other) {
    return other is StrokePathCacheKey &&
        other.strokeId == strokeId &&
        other.revision == revision &&
        other.scaleBucket == scaleBucket &&
        other.quality == quality &&
        other.isComplete == isComplete;
  }

  @override
  int get hashCode =>
      Object.hash(strokeId, revision, scaleBucket, quality, isComplete);
}

class StrokePathCache {
  StrokePathCache({this.maxEntries = 2048});

  final int maxEntries;
  final Map<StrokePathCacheKey, Path> _paths = <StrokePathCacheKey, Path>{};

  void clear() => _paths.clear();

  Path pathFor({
    required StrokePathCacheKey key,
    required Stroke stroke,
    required double viewportScale,
  }) {
    final cached = _paths.remove(key);
    if (cached != null) {
      _paths[key] = cached;
      return cached;
    }
    final path = stroke.tool == StrokeToolKind.fill
        ? buildFillBoundaryPath(stroke.points)
        : buildStrokeOutline(
            stroke.points,
            size: stroke.width,
            viewportScale: viewportScale,
            quality: key.quality,
            isComplete: key.isComplete,
          );
    _paths[key] = path;
    while (_paths.length > maxEntries) {
      _paths.remove(_paths.keys.first);
    }
    return path;
  }
}

class _TileKey {
  const _TileKey(this.x, this.y);

  final int x;
  final int y;

  Rect get rect {
    return Rect.fromLTWH(
      x * ElementsTileCache.tileSize,
      y * ElementsTileCache.tileSize,
      ElementsTileCache.tileSize,
      ElementsTileCache.tileSize,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _TileKey && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}

class _TilePicture {
  _TilePicture(this.picture, this.lastUsed);

  final ui.Picture picture;
  int lastUsed;
}

class ElementsPainter extends CustomPainter {
  /// Creates a painter for the committed [elements] under [viewport].
  ///
  /// [spatialIndex] must be the index kept in sync with the full element store.
  /// [selectedIds] are the ids of lasso-selected elements; while
  /// [selectionDragDelta] or [selectionTransformPreview] is active those
  /// elements are painted as live previews before the edit is committed.
  const ElementsPainter({
    required this.elements,
    required this.spatialIndex,
    required this.viewport,
    this.allElementsById,
    this.paintOrderById,
    this.elementsRevision,
    this.selectionRevision,
    this.selectionPreviewRevision,
    this.tileCache,
    this.selectedIds = const <String>{},
    this.selectionDragDelta = Offset.zero,
    this.selectionTransformPreview,
  });

  /// The committed elements, in paint order (ascending z-index).
  final List<CanvasElement> elements;

  /// Full constant-time lookup supplied by the interactive controller.
  ///
  /// When this and [paintOrderById] are present, [elements] is already the
  /// ordered viewport-visible subset and no full-list paint scan is needed.
  final Map<String, CanvasElement>? allElementsById;

  /// Full id-to-paint-order lookup paired with [allElementsById].
  final Map<String, int>? paintOrderById;

  /// Monotonic token bumped when committed element content changes.
  final int? elementsRevision;

  /// Viewport-culling index over [elements], keyed by element id.
  final SpatialIndex spatialIndex;

  /// The camera through which the world elements are observed.
  final ViewportState viewport;

  /// Optional committed-layer tile cache, owned outside the painter.
  final ElementsTileCache? tileCache;

  /// Ids of the elements currently in the lasso selection.
  ///
  /// Selected elements get a faint accent halo, and — while
  /// [selectionDragDelta] is non-zero — are painted at the dragged offset so
  /// the move previews before it is committed.
  final Set<String> selectedIds;

  /// Monotonic token bumped when [selectedIds] changes.
  final int? selectionRevision;

  /// Live world-space offset applied to selected elements during a drag.
  ///
  /// [Offset.zero] when no selection drag is in progress.
  final Offset selectionDragDelta;

  /// Live transform applied to selected elements during a pinch/rotate gesture.
  ///
  /// This transform is preview-only; the controller commits actual geometry once
  /// on pointer-up so the whole gesture is one undoable edit.
  final SelectionTransformPreview? selectionTransformPreview;

  /// Monotonic token bumped when [selectionTransformPreview] changes.
  final int? selectionPreviewRevision;

  /// Opacity applied to highlighter ink so it reads as a translucent marker.
  static const double _highlighterOpacity = 0.35;

  static const double _pencilOpacity = 0.72;
  static const double _markerOpacity = 0.78;
  static const double _airbrushOpacity = 0.42;

  /// Accent colour for the selected-element halo (gold, matching the theme).
  static const Color _selectionHalo = Color(0x55E8B84B);

  /// Fill colour of an image / PDF placeholder while its raster loads.
  static const Color _placeholderFill = Color(0x14FFFFFF);

  /// Border colour of an image / PDF placeholder while its raster loads.
  static const Color _placeholderBorder = Color(0x33FFFFFF);

  /// The gold brand accent — link chip border, icon and text.
  static const Color _accent = Color(0xFFE8B84B);

  /// Translucent gold fill behind a link chip.
  static const Color _linkChipFill = Color(0x1FE8B84B);

  /// Fallback text shown on a link chip whose label is empty.
  static const String _linkFallbackLabel = 'Link';

  /// Whether a selection drag is currently in progress.
  bool get _dragging => selectionDragDelta != Offset.zero;

  bool get _transforming => selectionTransformPreview != null;

  @override
  void paint(Canvas canvas, Size size) {
    if (elements.isEmpty || size.isEmpty) {
      return;
    }

    final Rect visibleWorldRect = _visibleWorldRect(size);

    canvas.save();
    canvas.transform(CanvasTransform.worldToScreenMatrix(viewport).storage);
    tileCache?._syncRevision(elements: elements, revision: elementsRevision);

    if (_canUseTileCache(visibleWorldRect)) {
      final ElementsTileCache cache = tileCache!;
      // At overview zoom one screen can cover hundreds or thousands of
      // fixed-size world tiles. Recording all of those pictures is slower than
      // one culled element pass and causes visible browser jank while zooming.
      if (_visibleTileCount(visibleWorldRect) <= cache.maxTiles) {
        _paintCachedTiles(canvas, visibleWorldRect);
        canvas.restore();
        return;
      }
    }

    if (allElementsById != null && paintOrderById != null) {
      _paintVisibleElements(canvas);
    } else {
      final Set<String> visibleIds = spatialIndex
          .query(visibleWorldRect)
          .toSet();
      if (visibleIds.isNotEmpty || _dragging || _transforming) {
        _paintVisibleElements(canvas, visibleIds: visibleIds);
      }
    }
    canvas.restore();
  }

  bool _canUseTileCache(Rect visibleWorldRect) {
    if (_dragging ||
        _transforming ||
        selectedIds.isNotEmpty ||
        tileCache == null ||
        allElementsById == null ||
        paintOrderById == null) {
      return false;
    }
    return strokeRenderQualityForScale(viewport.scale) !=
        StrokeRenderQuality.highZoom;
  }

  void _paintVisibleElements(Canvas canvas, {Set<String>? visibleIds}) {
    // Iterate `elements` (already z-ordered) and skip the culled ones, so the
    // surviving elements are still painted back-to-front. A selected element
    // mid-preview is never culled — its preview copy can leave the original
    // culled bounds.
    for (final CanvasElement element in elements) {
      final bool selected = selectedIds.contains(element.id);
      if (visibleIds != null &&
          !visibleIds.contains(element.id) &&
          !(selected && (_dragging || _transforming))) {
        continue;
      }
      final SelectionTransformPreview? transform = selectionTransformPreview;
      if (selected && transform != null) {
        canvas.save();
        transform.applyToCanvas(canvas);
        _paintElement(canvas, element, selected: selected);
        canvas.restore();
        continue;
      }
      if (selected && _dragging) {
        canvas.save();
        canvas.translate(selectionDragDelta.dx, selectionDragDelta.dy);
        _paintElement(canvas, element, selected: selected);
        canvas.restore();
        continue;
      }
      _paintElement(canvas, element, selected: selected);
    }
  }

  void _paintElement(
    Canvas canvas,
    CanvasElement element, {
    required bool selected,
  }) {
    switch (element) {
      case InkElement():
        _paintInk(canvas, element, selected: selected);
      case ImageElement():
        _paintImage(canvas, element, selected: selected);
      case PdfElement():
        _paintPdf(canvas, element, selected: selected);
      case LinkElement():
        _paintLink(canvas, element, selected: selected);
      case TextElement():
        _paintText(canvas, element, selected: selected);
      case ShapeElement():
        _paintShape(canvas, element, selected: selected);
    }
  }

  int _visibleTileCount(Rect visibleRect) {
    final int minX = (visibleRect.left / ElementsTileCache.tileSize).floor();
    final int maxX = (visibleRect.right / ElementsTileCache.tileSize).floor();
    final int minY = (visibleRect.top / ElementsTileCache.tileSize).floor();
    final int maxY = (visibleRect.bottom / ElementsTileCache.tileSize).floor();
    if (maxX < minX || maxY < minY) {
      return 0;
    }
    return (maxX - minX + 1) * (maxY - minY + 1);
  }

  void _paintCachedTiles(Canvas canvas, Rect visibleRect) {
    final ElementsTileCache cache = tileCache!;
    final Map<String, CanvasElement> elementsById = allElementsById!;
    final Map<String, int> paintOrder = paintOrderById!;

    final int minX = (visibleRect.left / ElementsTileCache.tileSize).floor();
    final int maxX = (visibleRect.right / ElementsTileCache.tileSize).floor();
    final int minY = (visibleRect.top / ElementsTileCache.tileSize).floor();
    final int maxY = (visibleRect.bottom / ElementsTileCache.tileSize).floor();

    for (int y = minY; y <= maxY; y += 1) {
      for (int x = minX; x <= maxX; x += 1) {
        final key = _TileKey(x, y);
        final picture = cache._pictureFor(
          key: key,
          tileRect: key.rect,
          elementsById: elementsById,
          paintOrderById: paintOrder,
          spatialIndex: spatialIndex,
          paintElement: _paintUnselectedElement,
        );
        canvas.drawPicture(picture);
      }
    }
  }

  void _paintUnselectedElement(Canvas canvas, CanvasElement element) {
    switch (element) {
      case InkElement():
        _paintInk(canvas, element, selected: false);
      case ImageElement():
        _paintImage(canvas, element, selected: false);
      case PdfElement():
        _paintPdf(canvas, element, selected: false);
      case LinkElement():
        _paintLink(canvas, element, selected: false);
      case TextElement():
        _paintText(canvas, element, selected: false);
      case ShapeElement():
        _paintShape(canvas, element, selected: false);
    }
  }

  void _paintShape(
    Canvas canvas,
    ShapeElement element, {
    required bool selected,
  }) {
    paintShapeElement(
      canvas,
      element,
      selected: selected,
      selectionHalo: _selectionHalo,
    );
  }

  /// Paints a single [element]'s ink stroke onto the world-space [canvas].
  ///
  /// Uses the element's cached [InkElement.outlinePath]; the outline is built
  /// once per element, never per frame. A [selected] element first gets a
  /// faint accent halo stroked behind its fill so the lasso selection reads
  /// clearly. (A dragged copy is a fresh element with its own cache, so its
  /// outline is built once per move — acceptable for a small selection.)
  void _paintInk(Canvas canvas, InkElement element, {required bool selected}) {
    final Stroke stroke = element.stroke;
    if (stroke.tool != StrokeToolKind.fill &&
        !selected &&
        strokeRenderQualityForScale(viewport.scale) ==
            StrokeRenderQuality.overview) {
      _paintInkOverview(canvas, element);
      return;
    }
    final Path path = _strokePathFor(element);

    if (selected) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (stroke.width * 0.6).clamp(2.0, double.infinity)
          ..strokeJoin = StrokeJoin.round
          ..color = _selectionHalo,
      );
    }

    final Paint paint = Paint()..style = PaintingStyle.fill;
    final Color color = Color(stroke.color);
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
  }

  Path _strokePathFor(InkElement element) {
    if (element.stroke.tool == StrokeToolKind.fill) {
      return element.outlinePath;
    }
    final StrokeRenderQuality quality = strokeRenderQualityForScale(
      viewport.scale,
    );
    if (quality != StrokeRenderQuality.highZoom) {
      return element.outlinePath;
    }
    final Stroke stroke = element.stroke;
    final key = StrokePathCacheKey(
      strokeId: stroke.id,
      revision: _strokeRevision(stroke),
      scaleBucket: strokeScaleBucket(viewport.scale),
      quality: quality,
      isComplete: true,
    );
    final StrokePathCache? cache = tileCache?.strokePathCache;
    if (cache == null) {
      return buildStrokeOutline(
        stroke.points,
        size: stroke.width,
        viewportScale: viewport.scale,
        quality: quality,
        isComplete: true,
      );
    }
    return cache.pathFor(
      key: key,
      stroke: stroke,
      viewportScale: viewport.scale,
    );
  }

  int _strokeRevision(Stroke stroke) {
    final StrokePoint? first = stroke.points.isEmpty
        ? null
        : stroke.points.first;
    final StrokePoint? last = stroke.points.isEmpty ? null : stroke.points.last;
    // Committed strokes are immutable by contract; edits replace the points
    // list, so the list identity plus endpoints avoids hashing every sample.
    return Object.hashAll(<Object?>[
      stroke.id,
      stroke.width,
      stroke.tool,
      stroke.points.length,
      identityHashCode(stroke.points),
      first,
      last,
    ]);
  }

  /// Cheap low-zoom stroke rendering for overview/deep-map navigation.
  void _paintInkOverview(Canvas canvas, InkElement element) {
    final Stroke stroke = element.stroke;
    final double screenWidth = stroke.width * viewport.scale;
    if (screenWidth < 0.2 &&
        element.worldBounds.width * viewport.scale < 0.75 &&
        element.worldBounds.height * viewport.scale < 0.75) {
      return;
    }
    final List<StrokePoint> points = stroke.points;
    if (points.isEmpty) {
      return;
    }
    if (stroke.tool == StrokeToolKind.fill) {
      canvas.drawPath(
        buildFillBoundaryPath(points),
        Paint()
          ..style = PaintingStyle.fill
          ..color = Color(stroke.color),
      );
      return;
    }
    final Path path = Path()..moveTo(points.first.x, points.first.y);
    for (var i = 1; i < points.length; i += 1) {
      path.lineTo(points[i].x, points[i].y);
    }
    final Color color = Color(stroke.color);
    final double opacity = switch (stroke.tool) {
      StrokeToolKind.highlighter => _highlighterOpacity,
      StrokeToolKind.pencil => _pencilOpacity,
      StrokeToolKind.marker => _markerOpacity,
      StrokeToolKind.airbrush => _airbrushOpacity,
      StrokeToolKind.fill => 1,
      StrokeToolKind.pen => 1,
    };
    final double userOpacity = ((stroke.color >>> 24) & 0xFF) / 255;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: opacity * userOpacity);
    if (stroke.tool == StrokeToolKind.highlighter) {
      paint.blendMode = BlendMode.multiply;
    }
    canvas.drawPath(path, paint);
  }

  /// Paints an imported [element]'s picture into its world rectangle.
  ///
  /// When the raster is decoded it is blitted with [Canvas.drawImageRect],
  /// which scales the source bitmap into the element's world-space placement
  /// rect (the canvas already carries the world→screen transform). Until the
  /// decode finishes [element.raster] is `null` and a neutral placeholder is
  /// drawn instead so the element still occupies its space.
  void _paintImage(
    Canvas canvas,
    ImageElement element, {
    required bool selected,
  }) {
    final ui.Image? raster = element.raster;
    final Rect dst = element.placementBounds;
    _paintRotatedRect(canvas, dst, element.rotation, () {
      if (raster == null) {
        _paintPlaceholder(canvas, dst);
      } else {
        _blitImage(canvas, raster, dst);
      }
      if (selected) {
        _paintSelectionOutline(canvas, dst);
      }
    });
  }

  /// Paints a PDF [element]'s rendered page into its world rectangle.
  ///
  /// Identical strategy to [_paintImage]: the decoded page raster is blitted
  /// into the element's world rect, or a placeholder is shown while the page
  /// is still being rasterised on the background path.
  void _paintPdf(Canvas canvas, PdfElement element, {required bool selected}) {
    final ui.Image? raster = element.raster;
    final Rect dst = element.placementBounds;
    _paintRotatedRect(canvas, dst, element.rotation, () {
      if (raster == null) {
        _paintPlaceholder(canvas, dst);
      } else {
        // A PDF page has an opaque white background; paint one so a page with
        // transparency does not show the canvas grid through it.
        canvas.drawRect(dst, Paint()..color = const Color(0xFFFFFFFF));
        _blitImage(canvas, raster, dst);
      }
      if (selected) {
        _paintSelectionOutline(canvas, dst);
      }
    });
  }

  /// Paints a [LinkElement] as a rounded gold chip in its world rectangle.
  ///
  /// The chip is drawn entirely in world space (the canvas already carries the
  /// world→screen transform): a translucent gold fill, a gold border, a link
  /// glyph and the element's [LinkElement.label] (or a generic fallback when
  /// the label is empty). The corner radius and inner padding scale with the
  /// chip so it reads consistently at any size. A [selected] chip gets the same
  /// gold halo as a selected image / PDF.
  void _paintLink(
    Canvas canvas,
    LinkElement element, {
    required bool selected,
  }) {
    final Rect rect = element.placementBounds;
    if (rect.isEmpty) {
      return;
    }
    _paintRotatedRect(canvas, rect, element.rotation, () {
      final double radius = (rect.shortestSide * 0.32).clamp(4.0, 28.0);
      final RRect chip = RRect.fromRectAndRadius(rect, Radius.circular(radius));

      // Fill, then border.
      canvas
        ..drawRRect(chip, Paint()..color = _linkChipFill)
        ..drawRRect(
          chip,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (rect.shortestSide * 0.035).clamp(1.0, 3.0)
            ..color = _accent,
        );

      // The link glyph sits at the leading edge, vertically centred; the label
      // fills the remaining width. Both are sized relative to the chip height so
      // a chip placed at any zoom keeps its proportions.
      final double pad = rect.shortestSide * 0.28;
      final double iconSize = (rect.height - pad).clamp(8.0, rect.height);
      final TextPainter icon = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: String.fromCharCode(Icons.link.codePoint),
          style: TextStyle(
            fontSize: iconSize,
            fontFamily: Icons.link.fontFamily,
            package: Icons.link.fontPackage,
            color: _accent,
          ),
        ),
      )..layout();
      icon.paint(
        canvas,
        Offset(rect.left + pad / 2, rect.center.dy - icon.height / 2),
      );

      final double labelLeft = rect.left + pad / 2 + icon.width + pad / 3;
      final double labelWidth = rect.right - pad / 2 - labelLeft;
      if (labelWidth > 0) {
        final String text = element.label.trim().isEmpty
            ? _linkFallbackLabel
            : element.label;
        final TextPainter label = TextPainter(
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: (rect.height * 0.34).clamp(8.0, rect.height),
              color: _accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        )..layout(maxWidth: labelWidth);
        label.paint(
          canvas,
          Offset(labelLeft, rect.center.dy - label.height / 2),
        );
      }

      if (selected) {
        _paintSelectionOutline(canvas, rect);
      }
    });
  }

  /// Paints a [TextElement] as plain multiline text in its world rectangle.
  void _paintText(
    Canvas canvas,
    TextElement element, {
    required bool selected,
  }) {
    final Rect rect = element.placementBounds;
    if (rect.isEmpty || element.text.trim().isEmpty) {
      return;
    }
    _paintRotatedRect(canvas, rect, element.rotation, () {
      final double pad = (element.fontSize * 0.35).clamp(4.0, 14.0);
      final Rect inner = rect.deflate(pad);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = const Color(0x1AFFFFFF),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x22FFFFFF),
      );

      if (inner.width > 0 && inner.height > 0) {
        final TextPainter painter = TextPainter(
          textDirection: TextDirection.ltr,
          maxLines: null,
          text: TextSpan(
            text: element.text,
            style: TextStyle(
              color: Color(element.color),
              fontSize: element.fontSize,
              height: 1.25,
            ),
          ),
        )..layout(maxWidth: inner.width);
        canvas.save();
        canvas.clipRect(inner);
        painter.paint(canvas, inner.topLeft);
        canvas.restore();
      }

      if (selected) {
        _paintSelectionOutline(canvas, rect);
      }
    });
  }

  /// Runs [paint] with [rect] visually rotated around its centre.
  void _paintRotatedRect(
    Canvas canvas,
    Rect rect,
    double radians,
    void Function() paint,
  ) {
    if (radians == 0 || rect.isEmpty) {
      paint();
      return;
    }
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(radians);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    paint();
    canvas.restore();
  }

  /// Blits [image] into the world-space [dst] rectangle.
  ///
  /// `filterQuality` is set to [FilterQuality.medium] so the bitmap stays
  /// smooth when the viewport scales it up or down between re-rasterisations.
  void _blitImage(Canvas canvas, ui.Image image, Rect dst) {
    final Rect src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  /// Draws a neutral placeholder for an element whose raster is not ready.
  ///
  /// A soft filled rectangle with a thin border so an image / PDF page still
  /// reads as a placed object while its bitmap loads in the background.
  void _paintPlaceholder(Canvas canvas, Rect rect) {
    canvas
      ..drawRect(rect, Paint()..color = _placeholderFill)
      ..drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _placeholderBorder,
      );
  }

  /// Strokes the gold selection outline around a rectangular element.
  void _paintSelectionOutline(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _selectionHalo,
    );
  }

  /// Bounding box of the visible region in world coordinates.
  ///
  /// The four screen corners are mapped back to world space; rotation means
  /// the world rect is the axis-aligned bounds of those (possibly skewed)
  /// points. Inflated slightly so an element straddling the edge is never
  /// culled a frame early.
  Rect _visibleWorldRect(Size size) {
    final List<Offset> corners = <Offset>[
      CanvasTransform.toWorld(viewport, Offset.zero),
      CanvasTransform.toWorld(viewport, Offset(size.width, 0)),
      CanvasTransform.toWorld(viewport, Offset(0, size.height)),
      CanvasTransform.toWorld(viewport, Offset(size.width, size.height)),
    ];

    double minX = corners.first.dx;
    double maxX = corners.first.dx;
    double minY = corners.first.dy;
    double maxY = corners.first.dy;
    for (final Offset corner in corners) {
      if (corner.dx < minX) minX = corner.dx;
      if (corner.dx > maxX) maxX = corner.dx;
      if (corner.dy < minY) minY = corner.dy;
      if (corner.dy > maxY) maxY = corner.dy;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY).inflate(1);
  }

  @override
  bool shouldRepaint(ElementsPainter oldDelegate) {
    final bool elementsChanged =
        oldDelegate.elementsRevision != null || elementsRevision != null
        ? oldDelegate.elementsRevision != elementsRevision
        : !identical(oldDelegate.elements, elements) ||
              oldDelegate.elements.length != elements.length;
    final bool selectionChanged =
        oldDelegate.selectionRevision != null || selectionRevision != null
        ? oldDelegate.selectionRevision != selectionRevision
        : !setEquals(oldDelegate.selectedIds, selectedIds);
    final bool previewChanged =
        oldDelegate.selectionPreviewRevision != null ||
            selectionPreviewRevision != null
        ? oldDelegate.selectionPreviewRevision != selectionPreviewRevision
        : oldDelegate.selectionTransformPreview != selectionTransformPreview;
    return elementsChanged ||
        !identical(oldDelegate.spatialIndex, spatialIndex) ||
        oldDelegate.viewport != viewport ||
        selectionChanged ||
        oldDelegate.selectionDragDelta != selectionDragDelta ||
        previewChanged;
  }
}
