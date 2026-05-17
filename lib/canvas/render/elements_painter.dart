import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/rendering.dart';

import 'package:zenno/canvas/engine/canvas_transform.dart';
import 'package:zenno/canvas/engine/spatial_index.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';

/// Paints the committed [elements] layer, culled to the visible viewport.
///
/// The world-to-screen transform is applied to the [Canvas] once, so every
/// element is drawn in world coordinates. Before drawing, the visible region
/// is mapped back into world space and the [spatialIndex] is queried for the
/// ids whose [CanvasElement.worldBounds] intersect it — only those elements
/// are painted. Render cost is therefore bounded by what is on screen, not by
/// the total element count.
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
  }

  /// Releases native picture resources.
  void dispose() => clear();

  void _syncRevision(List<CanvasElement> elements) {
    final int nextRevision = Object.hashAll(elements.map(_elementRevisionPart));
    if (nextRevision == _revision) {
      return;
    }
    _revision = nextRevision;
    clear();
  }

  ui.Picture _pictureFor({
    required _TileKey key,
    required Rect tileRect,
    required List<CanvasElement> elements,
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

    final Set<String> tileIds = spatialIndex.query(tileRect).toSet();
    for (final element in elements) {
      if (tileIds.contains(element.id)) {
        paintElement(canvas, element);
      }
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
  /// [spatialIndex] must be the index the controller keeps in sync with
  /// [elements]; it is used purely to cull off-screen elements. [selectedIds]
  /// are the ids of lasso-selected elements; while [selectionDragDelta] is
  /// non-zero those elements are painted shifted by it for live drag feedback.
  const ElementsPainter({
    required this.elements,
    required this.spatialIndex,
    required this.viewport,
    this.tileCache,
    this.selectedIds = const <String>{},
    this.selectionDragDelta = Offset.zero,
  });

  /// The committed elements, in paint order (ascending z-index).
  final List<CanvasElement> elements;

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

  /// Live world-space offset applied to selected elements during a drag.
  ///
  /// [Offset.zero] when no selection drag is in progress.
  final Offset selectionDragDelta;

  /// Opacity applied to highlighter ink so it reads as a translucent marker.
  static const double _highlighterOpacity = 0.35;

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

  @override
  void paint(Canvas canvas, Size size) {
    if (elements.isEmpty || size.isEmpty) {
      return;
    }

    // The set of element ids whose world bounds intersect the visible region.
    final Rect visibleWorldRect = _visibleWorldRect(size);
    final Set<String> visibleIds = spatialIndex.query(visibleWorldRect).toSet();
    // Fast path: nothing visible and no drag that could pull an off-screen
    // selected element into view — there is nothing to paint.
    if (visibleIds.isEmpty && !_dragging) {
      return;
    }

    canvas.save();
    canvas.transform(CanvasTransform.worldToScreenMatrix(viewport).storage);

    if (!_dragging && selectedIds.isEmpty && tileCache != null) {
      _paintCachedTiles(canvas, visibleWorldRect);
      canvas.restore();
      return;
    }

    // Iterate `elements` (already z-ordered) and skip the culled ones, so the
    // surviving elements are still painted back-to-front. A selected element
    // mid-drag is never culled — its dragged copy can leave the culled bounds.
    for (final CanvasElement element in elements) {
      final bool selected = selectedIds.contains(element.id);
      if (!visibleIds.contains(element.id) && !(selected && _dragging)) {
        continue;
      }
      // While dragging, selected elements render at the live offset.
      final CanvasElement drawn = (selected && _dragging)
          ? element.translated(selectionDragDelta)
          : element;
      switch (drawn) {
        case InkElement():
          _paintInk(canvas, drawn, selected: selected);
        case ImageElement():
          _paintImage(canvas, drawn, selected: selected);
        case PdfElement():
          _paintPdf(canvas, drawn, selected: selected);
        case LinkElement():
          _paintLink(canvas, drawn, selected: selected);
      }
    }

    canvas.restore();
  }

  void _paintCachedTiles(Canvas canvas, Rect visibleRect) {
    final ElementsTileCache cache = tileCache!;
    cache._syncRevision(elements);

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
          elements: elements,
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
    }
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
    final Path path = element.outlinePath;

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
    if (stroke.tool == StrokeToolKind.highlighter) {
      paint
        ..color = color.withValues(alpha: _highlighterOpacity)
        ..blendMode = BlendMode.multiply;
    } else {
      paint.color = color;
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
    final Rect dst = element.worldBounds;
    if (raster == null) {
      _paintPlaceholder(canvas, dst);
    } else {
      _blitImage(canvas, raster, dst);
    }
    if (selected) {
      _paintSelectionOutline(canvas, dst);
    }
  }

  /// Paints a PDF [element]'s rendered page into its world rectangle.
  ///
  /// Identical strategy to [_paintImage]: the decoded page raster is blitted
  /// into the element's world rect, or a placeholder is shown while the page
  /// is still being rasterised on the background path.
  void _paintPdf(Canvas canvas, PdfElement element, {required bool selected}) {
    final ui.Image? raster = element.raster;
    final Rect dst = element.worldBounds;
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
    final Rect rect = element.worldBounds;
    if (rect.isEmpty) {
      return;
    }
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
      label.paint(canvas, Offset(labelLeft, rect.center.dy - label.height / 2));
    }

    if (selected) {
      _paintSelectionOutline(canvas, rect);
    }
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
  bool shouldRepaint(ElementsPainter oldDelegate) =>
      !identical(oldDelegate.elements, elements) ||
      oldDelegate.elements.length != elements.length ||
      !identical(oldDelegate.spatialIndex, spatialIndex) ||
      oldDelegate.viewport != viewport ||
      !setEquals(oldDelegate.selectedIds, selectedIds) ||
      oldDelegate.selectionDragDelta != selectionDragDelta;
}
