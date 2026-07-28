import 'dart:convert';
import 'dart:ui' show Rect, Size, Offset;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:zenno/canvas/model/canvas_bookmark.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/canvas_layer.dart';
import 'package:zenno/canvas/model/canvas_style.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/persistence/ink_codec.dart';
// The Drift table `CanvasElements` generates a row class also called
// `CanvasElement`, colliding with the engine's sealed `CanvasElement`; the
// database import is aliased `as db` so Drift types are reached via `db.`.
import 'package:zenno/core/database/database.dart' as db;
import 'package:zenno/core/database/tables/canvas_tables.dart' as tables;

/// Raised when an editor route points at a canvas that has been deleted.
class CanvasNotFoundException implements Exception {
  const CanvasNotFoundException(this.canvasId);

  final String canvasId;

  @override
  String toString() => 'CanvasNotFoundException($canvasId)';
}

/// Drift-backed persistence for one infinite canvas.
///
/// This is the seam between the in-memory engine (`CanvasController`,
/// `CanvasElement`) and SQLite. It reconstructs hand-written [CanvasElement]
/// instances from the `canvas_elements` table joined to its per-kind detail
/// tables, and writes each element back as a `canvas_elements` row plus the
/// matching detail row inside one transaction.
///
/// It is deliberately **not** reactive — a canvas editor owns its element list
/// in memory and writes through on every committed mutation, so there is no
/// `.watch()` here. Runtime rasters (`ImageElement.raster`, `PdfElement.raster`)
/// are never persisted: a loaded element has a `null` raster and re-rasterises
/// from its source file on view.
///
/// The `canvas_elements.kind` column drives reconstruction:
///
/// | kind                       | detail table     | engine type    |
/// |----------------------------|------------------|----------------|
/// | `stroke`                   | `ink_strokes`    | [InkElement]   |
/// | `image`                    | `images`         | [ImageElement] |
/// | `pdf`                      | `pdf_documents`  | [PdfElement]   |
/// | `link`                     | `canvas_links`   | [LinkElement]  |
/// | `text`                     | `canvas_texts`   | [TextElement]  |
///
/// A `z_index` is an `int` in the engine model but a `REAL` column; the
/// conversion is a plain `int` ↔ `double` round-trip (engine z-indices are
/// always whole numbers).
class CanvasRepository {
  /// Creates a repository persisting to [_db].
  CanvasRepository(this._db);

  final db.ZennoDatabase _db;

  /// Updates the canvas thumbnail path after a snapshot is written.
  Future<void> updateThumbnailPath(String canvasId, String path) {
    return (_db.update(
      _db.canvases,
    )..where((c) => c.id.equals(canvasId))).write(
      db.CanvasesCompanion(
        thumbnailPath: Value(path),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Elements — read
  // ---------------------------------------------------------------------------

  /// Loads every non-deleted element of canvas [canvasId], in paint order.
  ///
  /// Rows are read ordered by `z_index` ascending (back to front) and each is
  /// reconstructed from its per-kind detail row. An element whose detail row is
  /// missing — a partially-written corruption — is skipped rather than crashing
  /// the load. Runtime rasters are left `null`.
  Future<List<CanvasElement>> loadElements(String canvasId) async {
    await _ensureDefaultContentLayer(canvasId);
    final List<db.CanvasElement> rows =
        await (_db.select(_db.canvasElements)
              ..where(
                (e) => e.canvasId.equals(canvasId) & e.isDeleted.equals(false),
              )
              ..orderBy([(e) => OrderingTerm(expression: e.zIndex)]))
            .get();

    final List<String> strokeIds = <String>[];
    final List<String> imageIds = <String>[];
    final List<String> pdfIds = <String>[];
    final List<String> linkIds = <String>[];
    final List<String> textIds = <String>[];
    final List<String> shapeIds = <String>[];
    for (final db.CanvasElement row in rows) {
      switch (row.kind) {
        case tables.ElementKind.stroke:
          strokeIds.add(row.id);
        case tables.ElementKind.image:
          imageIds.add(row.id);
        case tables.ElementKind.pdf:
          pdfIds.add(row.id);
        case tables.ElementKind.link:
          linkIds.add(row.id);
        case tables.ElementKind.text:
          textIds.add(row.id);
        case tables.ElementKind.card:
        case tables.ElementKind.shape:
          shapeIds.add(row.id);
      }
    }

    final Map<String, db.InkStroke> inkById = <String, db.InkStroke>{};
    if (strokeIds.isNotEmpty) {
      final rows = await (_db.select(
        _db.inkStrokes,
      )..where((s) => s.elementId.isIn(strokeIds))).get();
      for (final db.InkStroke row in rows) {
        inkById[row.elementId] = row;
      }
    }

    final Map<String, db.Image> imageById = <String, db.Image>{};
    if (imageIds.isNotEmpty) {
      final rows = await (_db.select(
        _db.images,
      )..where((i) => i.elementId.isIn(imageIds))).get();
      for (final db.Image row in rows) {
        imageById[row.elementId] = row;
      }
    }

    final Map<String, db.PdfDocument> pdfById = <String, db.PdfDocument>{};
    if (pdfIds.isNotEmpty) {
      final rows = await (_db.select(
        _db.pdfDocuments,
      )..where((p) => p.elementId.isIn(pdfIds))).get();
      for (final db.PdfDocument row in rows) {
        pdfById[row.elementId] = row;
      }
    }

    final Map<String, db.CanvasLink> linkById = <String, db.CanvasLink>{};
    if (linkIds.isNotEmpty) {
      final rows = await (_db.select(
        _db.canvasLinks,
      )..where((l) => l.elementId.isIn(linkIds))).get();
      for (final db.CanvasLink row in rows) {
        linkById[row.elementId] = row;
      }
    }

    final Map<String, db.CanvasText> textById = <String, db.CanvasText>{};
    if (textIds.isNotEmpty) {
      final rows = await (_db.select(
        _db.canvasTexts,
      )..where((t) => t.elementId.isIn(textIds))).get();
      for (final db.CanvasText row in rows) {
        textById[row.elementId] = row;
      }
    }

    final Map<String, db.CanvasShape> shapeById = <String, db.CanvasShape>{};
    if (shapeIds.isNotEmpty) {
      final rows = await (_db.select(
        _db.canvasShapes,
      )..where((s) => s.elementId.isIn(shapeIds))).get();
      for (final db.CanvasShape row in rows) {
        shapeById[row.elementId] = row;
      }
    }

    final Map<String, List<StrokePoint>> inkPointsById =
        await _decodedInkPoints(inkById);

    final List<CanvasElement> elements = <CanvasElement>[];
    for (final db.CanvasElement row in rows) {
      final CanvasElement? element = _reconstruct(
        row,
        inkDetail: inkById[row.id],
        inkPoints: inkPointsById[row.id],
        imageDetail: imageById[row.id],
        pdfDetail: pdfById[row.id],
        linkDetail: linkById[row.id],
        textDetail: textById[row.id],
        shapeDetail: shapeById[row.id],
      );
      if (element != null) {
        elements.add(element);
      }
    }
    return elements;
  }

  /// Decodes every ink BLOB for a canvas, off the UI isolate when it matters.
  ///
  /// A dense study canvas is thousands of strokes at 48 bytes/point — decoding
  /// that in one synchronous burst on the UI isolate stalled the open
  /// animation. Above the threshold the BLOBs ship to a worker isolate
  /// (`Uint8List`s transfer cheaply, and `compute` returns via `Isolate.exit`,
  /// so nothing is copied back). Below it the isolate spawn would cost more
  /// than the decode.
  Future<Map<String, List<StrokePoint>>> _decodedInkPoints(
    Map<String, db.InkStroke> inkById,
  ) async {
    if (inkById.isEmpty) {
      return const <String, List<StrokePoint>>{};
    }
    final Map<String, Uint8List> blobs = <String, Uint8List>{};
    var totalBytes = 0;
    for (final MapEntry<String, db.InkStroke> entry in inkById.entries) {
      blobs[entry.key] = entry.value.points;
      totalBytes += entry.value.points.length;
    }
    if (totalBytes < _inkDecodeIsolateThresholdBytes) {
      return _decodeInkBlobs(blobs);
    }
    return compute(_decodeInkBlobs, blobs, debugLabel: 'zenno-ink-decode');
  }

  /// Total BLOB bytes below which spawning a decode isolate is not worth it.
  static const int _inkDecodeIsolateThresholdBytes = 256 * 1024;

  /// Top of the isolate: pure bytes in, points out. Must stay static.
  static Map<String, List<StrokePoint>> _decodeInkBlobs(
    Map<String, Uint8List> blobs,
  ) {
    return <String, List<StrokePoint>>{
      for (final MapEntry<String, Uint8List> entry in blobs.entries)
        entry.key: InkCodec.decodePoints(entry.value),
    };
  }

  /// Rebuilds the engine [CanvasElement] for a `canvas_elements` [row].
  ///
  /// Returns `null` when the row's kind has no engine representation, or when
  /// its detail row is absent.
  CanvasElement? _reconstruct(
    db.CanvasElement row, {
    db.InkStroke? inkDetail,
    List<StrokePoint>? inkPoints,
    db.Image? imageDetail,
    db.PdfDocument? pdfDetail,
    db.CanvasLink? linkDetail,
    db.CanvasText? textDetail,
    db.CanvasShape? shapeDetail,
  }) {
    final Rect bounds = Rect.fromLTWH(row.x, row.y, row.width, row.height);
    final int zIndex = _zIndexFromColumn(row.zIndex);
    final String layerId =
        row.layerId ?? CanvasLayer.defaultContentLayerId(row.canvasId);
    switch (row.kind) {
      case tables.ElementKind.stroke:
        final db.InkStroke? detail = inkDetail;
        if (detail == null) {
          return null;
        }
        return InkElement(
          id: row.id,
          zIndex: zIndex,
          layerId: layerId,
          rotation: row.rotation,
          worldBounds: bounds,
          stroke: Stroke(
            id: row.id,
            // Bulk loads pre-decode every BLOB in one (possibly off-isolate)
            // pass — see [_decodedInkPoints]; the inline decode is the
            // single-row fallback.
            points: inkPoints ?? InkCodec.decodePoints(detail.points),
            color: detail.color,
            width: detail.strokeWidth,
            tool: _strokeToolToModel(detail.tool),
          ),
        );
      case tables.ElementKind.image:
        final db.Image? detail = imageDetail;
        if (detail == null) {
          return null;
        }
        return ImageElement(
          id: row.id,
          zIndex: zIndex,
          layerId: layerId,
          rotation: row.rotation,
          worldBounds: bounds,
          sourceFilePath: detail.filePath,
          intrinsicSize: Size(detail.intrinsicWidth, detail.intrinsicHeight),
        );
      case tables.ElementKind.pdf:
        final db.PdfDocument? detail = pdfDetail;
        if (detail == null) {
          return null;
        }
        return PdfElement(
          id: row.id,
          zIndex: zIndex,
          layerId: layerId,
          rotation: row.rotation,
          worldBounds: bounds,
          sourceFilePath: detail.filePath,
          pageNumber: detail.pageNumber,
          pageSize: Size(
            detail.cropRight ?? bounds.width,
            detail.cropBottom ?? bounds.height,
          ),
        );
      case tables.ElementKind.link:
        final db.CanvasLink? detail = linkDetail;
        if (detail == null) {
          return null;
        }
        return LinkElement(
          id: row.id,
          zIndex: zIndex,
          layerId: layerId,
          rotation: row.rotation,
          worldBounds: bounds,
          label: detail.label,
          target: LinkTarget(
            targetCanvasId: detail.targetCanvasId ?? '',
            targetViewport: _viewportFromLinkColumns(detail),
          ),
        );
      case tables.ElementKind.text:
        final db.CanvasText? detail = textDetail;
        if (detail == null) {
          return null;
        }
        return TextElement(
          id: row.id,
          zIndex: zIndex,
          layerId: layerId,
          rotation: row.rotation,
          worldBounds: bounds,
          text: detail.noteText,
          color: detail.color,
          fontSize: detail.fontSize,
        );
      case tables.ElementKind.card:
      case tables.ElementKind.shape:
        final db.CanvasShape? detail = shapeDetail;
        if (detail == null) {
          return null;
        }
        return ShapeElement(
          id: row.id,
          zIndex: zIndex,
          layerId: layerId,
          rotation: row.rotation,
          shapeKind: detail.shapeKind,
          start: Offset(detail.startX, detail.startY),
          end: Offset(detail.endX, detail.endY),
          color: detail.color,
          strokeWidth: detail.strokeWidth,
          arrowBody: _arrowBodyToModel(detail.arrowBodyKind),
          arrowStartHead: _arrowHeadToModel(detail.arrowStartHead),
          arrowEndHead: _arrowHeadToModel(detail.arrowEndHead),
          arrowHeadScale: detail.arrowHeadScale,
          controlPoints: _decodeControlPoints(detail.controlPointsJson),
          legacyArrow: detail.arrowLegacy,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Elements — write
  // ---------------------------------------------------------------------------

  /// Inserts or updates [element] on canvas [canvasId].
  ///
  /// Writes the generic `canvas_elements` row and the matching per-kind detail
  /// row in one transaction (insert-or-replace, so an existing element is
  /// overwritten). The owning canvas's `updated_at` is bumped in the same
  /// transaction. PDF page geometry (`page_size`) is stored in the unused
  /// `crop_right` / `crop_bottom` columns so a page round-trips its aspect
  /// ratio.
  Future<void> upsertElement(String canvasId, CanvasElement element) async {
    await upsertElements(canvasId, <CanvasElement>[element]);
  }

  /// Inserts or updates [elements] on canvas [canvasId] in one transaction.
  Future<void> upsertElements(
    String canvasId,
    Iterable<CanvasElement> elements,
  ) async {
    final List<CanvasElement> batch = List<CanvasElement>.of(elements);
    if (batch.isEmpty) {
      return;
    }
    final DateTime now = DateTime.now();
    await _db.transaction(() async {
      await _ensureDefaultContentLayer(canvasId);
      for (final CanvasElement element in batch) {
        final String layerId =
            element.layerId ?? CanvasLayer.defaultContentLayerId(canvasId);
        final Rect storedBounds = _storedBoundsOf(element);
        await _db
            .into(_db.canvasElements)
            .insert(
              db.CanvasElementsCompanion.insert(
                id: element.id,
                canvasId: canvasId,
                layerId: Value(layerId),
                kind: _kindOf(element),
                x: storedBounds.left,
                y: storedBounds.top,
                width: storedBounds.width,
                height: storedBounds.height,
                rotation: Value(element.rotation),
                zIndex: _zIndexToColumn(element.zIndex),
                createdAt: now,
                updatedAt: now,
              ),
              mode: InsertMode.insertOrReplace,
            );
        await _writeDetail(element);
      }
      await _touchCanvas(canvasId, now);
    });
  }

  /// Writes the per-kind detail row for [element].
  ///
  /// Runs inside [upsertElement]'s transaction. Uses insert-or-replace keyed on
  /// `element_id`, so re-saving an element overwrites its detail row.
  Future<void> _writeDetail(CanvasElement element) async {
    switch (element) {
      case InkElement():
        final Stroke stroke = element.stroke;
        await _db
            .into(_db.inkStrokes)
            .insert(
              db.InkStrokesCompanion.insert(
                elementId: element.id,
                points: InkCodec.encodePoints(stroke.points),
                pointCount: stroke.points.length,
                color: stroke.color,
                strokeWidth: stroke.width,
                tool: _strokeToolToColumn(stroke.tool),
                isHighlighter: Value(stroke.tool == StrokeToolKind.highlighter),
              ),
              mode: InsertMode.insertOrReplace,
            );
      case ImageElement():
        await _db
            .into(_db.images)
            .insert(
              db.ImagesCompanion.insert(
                elementId: element.id,
                filePath: element.sourceFilePath,
                intrinsicWidth: element.intrinsicSize.width,
                intrinsicHeight: element.intrinsicSize.height,
              ),
              mode: InsertMode.insertOrReplace,
            );
      case PdfElement():
        await _db
            .into(_db.pdfDocuments)
            .insert(
              db.PdfDocumentsCompanion.insert(
                elementId: element.id,
                filePath: element.sourceFilePath,
                // The engine PdfElement does not carry the original filename;
                // the basename of the stored path is a faithful stand-in.
                originalFilename: _baseName(element.sourceFilePath),
                pageNumber: element.pageNumber,
                // The engine PdfElement is one page and does not carry the
                // source's page count; it is not reconstructed into the
                // element, so storing this page's number is a safe stand-in.
                totalPages: element.pageNumber,
                // page_size has no dedicated columns; the (otherwise unused)
                // crop_right / crop_bottom hold it so the page round-trips its
                // aspect ratio. crop_left / crop_top stay null.
                cropRight: Value(element.pageSize.width),
                cropBottom: Value(element.pageSize.height),
              ),
              mode: InsertMode.insertOrReplace,
            );
      case LinkElement():
        final ViewportState? vp = element.target.targetViewport;
        await _db
            .into(_db.canvasLinks)
            .insert(
              db.CanvasLinksCompanion.insert(
                elementId: element.id,
                linkKind: vp == null
                    ? tables.CanvasLinkKind.canvas
                    : tables.CanvasLinkKind.region,
                targetCanvasId: Value(element.target.targetCanvasId),
                targetVpTx: Value(vp?.translation.dx),
                targetVpTy: Value(vp?.translation.dy),
                targetVpScale: Value(vp?.scale),
                targetVpRotation: Value(vp?.rotation),
                label: element.label,
              ),
              mode: InsertMode.insertOrReplace,
            );
      case TextElement():
        await _db
            .into(_db.canvasTexts)
            .insert(
              db.CanvasTextsCompanion.insert(
                elementId: element.id,
                noteText: element.text,
                color: element.color,
                fontSize: element.fontSize,
              ),
              mode: InsertMode.insertOrReplace,
            );
      case ShapeElement():
        await _db
            .into(_db.canvasShapes)
            .insert(
              db.CanvasShapesCompanion.insert(
                elementId: element.id,
                shapeKind: element.shapeKind,
                startX: element.start.dx,
                startY: element.start.dy,
                endX: element.end.dx,
                endY: element.end.dy,
                color: element.color,
                strokeWidth: element.strokeWidth,
                arrowBodyKind: Value(element.arrowBody.index),
                arrowStartHead: Value(element.arrowStartHead.index),
                arrowEndHead: Value(element.arrowEndHead.index),
                arrowHeadScale: Value(element.arrowHeadScale),
                controlPointsJson: Value(
                  _encodeControlPoints(element.controlPoints),
                ),
                arrowLegacy: Value(element.legacyArrow),
              ),
              mode: InsertMode.insertOrReplace,
            );
    }
  }

  /// Deletes the element [id] and its detail row.
  ///
  /// Only the `canvas_elements` row is deleted explicitly — the `ON DELETE
  /// CASCADE` foreign key on every detail table removes the matching detail
  /// row (the FK pragma is enabled in `beforeOpen`). A no-op when no element
  /// has that id.
  Future<void> deleteElement(String id) async {
    await deleteElements(<String>[id]);
  }

  /// Deletes all element [ids] and their cascading detail rows.
  Future<void> deleteElements(Iterable<String> ids) async {
    final List<String> batch = ids.toSet().toList(growable: false);
    if (batch.isEmpty) {
      return;
    }
    final DateTime now = DateTime.now();
    await _db.transaction(() async {
      final rows =
          await (_db.selectOnly(_db.canvasElements)
                ..addColumns([_db.canvasElements.canvasId])
                ..where(_db.canvasElements.id.isIn(batch)))
              .get();
      final canvasIds = rows
          .map((row) => row.read(_db.canvasElements.canvasId))
          .whereType<String>()
          .toSet();
      await (_db.delete(
        _db.canvasElements,
      )..where((element) => element.id.isIn(batch))).go();
      for (final canvasId in canvasIds) {
        await _touchCanvas(canvasId, now);
      }
    });
  }

  /// Applies one command's deletes and replacement upserts atomically.
  Future<void> applyElementBatch(
    String canvasId, {
    required Iterable<String> deletes,
    required Iterable<CanvasElement> upserts,
  }) async {
    final deleteBatch = deletes.toSet().toList(growable: false);
    final upsertBatch = List<CanvasElement>.of(upserts);
    if (deleteBatch.isEmpty && upsertBatch.isEmpty) return;

    await _db.transaction(() async {
      if (deleteBatch.isNotEmpty) {
        await (_db.delete(
          _db.canvasElements,
        )..where((element) => element.id.isIn(deleteBatch))).go();
      }
      if (upsertBatch.isNotEmpty) {
        await upsertElements(canvasId, upsertBatch);
      } else {
        await _touchCanvas(canvasId, DateTime.now());
      }
    });
  }

  /// Reconciles durable canvas state with the controller's latest snapshot.
  /// Used after one or more asynchronous writes failed, so stale mutations are
  /// never replayed over newer edits.
  Future<void> syncCanvasState(
    String canvasId, {
    required Iterable<CanvasElement> elements,
    required Iterable<CanvasLayer> layers,
    required Iterable<Bookmark> bookmarks,
    required ViewportState viewport,
    required bool rotationLocked,
    required CanvasPaperStyle paperStyle,
    required CanvasToolSettings toolSettings,
  }) async {
    final elementBatch = List<CanvasElement>.of(elements);
    final layerBatch = List<CanvasLayer>.of(layers);
    final bookmarkBatch = List<Bookmark>.of(bookmarks);
    final DateTime now = DateTime.now();

    await _db.transaction(() async {
      await upsertLayers(layerBatch);

      final storedElementRows =
          await (_db.selectOnly(_db.canvasElements)
                ..addColumns([_db.canvasElements.id])
                ..where(_db.canvasElements.canvasId.equals(canvasId)))
              .get();
      final currentElementIds = elementBatch
          .map((element) => element.id)
          .toSet();
      final staleElementIds = storedElementRows
          .map((row) => row.read(_db.canvasElements.id))
          .whereType<String>()
          .where((id) => !currentElementIds.contains(id));
      await applyElementBatch(
        canvasId,
        deletes: staleElementIds,
        upserts: elementBatch,
      );

      final storedBookmarks = await (_db.select(
        _db.canvasBookmarks,
      )..where((bookmark) => bookmark.canvasId.equals(canvasId))).get();
      final currentBookmarkNames = bookmarkBatch
          .map((bookmark) => bookmark.name)
          .toSet();
      final staleBookmarkNames = storedBookmarks
          .map((bookmark) => bookmark.name)
          .where((name) => !currentBookmarkNames.contains(name))
          .toList(growable: false);
      if (staleBookmarkNames.isNotEmpty) {
        await (_db.delete(_db.canvasBookmarks)..where(
              (bookmark) =>
                  bookmark.canvasId.equals(canvasId) &
                  bookmark.name.isIn(staleBookmarkNames),
            ))
            .go();
      }
      for (var i = 0; i < bookmarkBatch.length; i++) {
        await upsertBookmark(canvasId, bookmarkBatch[i], position: i);
      }

      await (_db.update(
        _db.canvases,
      )..where((canvas) => canvas.id.equals(canvasId))).write(
        db.CanvasesCompanion(
          vpTx: Value(viewport.translation.dx),
          vpTy: Value(viewport.translation.dy),
          vpScale: Value(viewport.scale),
          vpRotation: Value(viewport.rotation),
          rotationLocked: Value(rotationLocked),
          backgroundKind: Value(paperStyle.kind),
          canvasBackgroundColor: Value(paperStyle.backgroundColor),
          gridColor: Value(paperStyle.gridColor),
          gridSpacing: Value(paperStyle.gridSpacing),
          gridOpacity: Value(paperStyle.gridOpacity),
          graphMajorInterval: Value(paperStyle.graphMajorInterval),
          paperTexture: Value(paperStyle.texture),
          paperTextureOpacity: Value(paperStyle.textureOpacity),
          activePenColor: Value(toolSettings.penColor),
          activePenWidth: Value(toolSettings.penWidth),
          activePenWidthMode: Value(
            _penWidthModeToColumn(toolSettings.penWidthMode),
          ),
          activePenTool: Value(_strokeToolToColumn(toolSettings.penKind)),
          toolWheelJson: Value(_encodeToolWheel(toolSettings)),
          pressureEnabled: Value(toolSettings.pressureEnabled),
          updatedAt: Value(now),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Layers
  // ---------------------------------------------------------------------------

  /// Loads canvas layers in paint/order-panel order.
  ///
  /// Every canvas is guaranteed to have a default content layer before the
  /// list is returned, so older databases with null element layer ids can still
  /// participate in layer-aware editing without data rewriting.
  Future<List<CanvasLayer>> loadLayers(String canvasId) async {
    await _ensureDefaultContentLayer(canvasId);
    final rows =
        await (_db.select(_db.canvasLayers)
              ..where((l) => l.canvasId.equals(canvasId))
              ..orderBy([(l) => OrderingTerm(expression: l.position)]))
            .get();
    return <CanvasLayer>[
      for (final row in rows)
        CanvasLayer(
          id: row.id,
          canvasId: row.canvasId,
          name: row.name,
          position: row.position,
          visible: row.visible,
          locked: row.locked,
          opacity: row.opacity,
          blendMode: row.blendMode,
          kind: row.kind,
        ),
    ];
  }

  /// Inserts or updates a layer row.
  Future<void> upsertLayer(CanvasLayer layer) async {
    final DateTime now = DateTime.now();
    await _upsertLayerRow(layer, now);
    await _touchCanvas(layer.canvasId, now);
  }

  /// Atomically persists a reordered layer list.
  Future<void> upsertLayers(List<CanvasLayer> layers) async {
    if (layers.isEmpty) return;
    final DateTime now = DateTime.now();
    await _db.transaction(() async {
      for (final layer in layers) {
        await _upsertLayerRow(layer, now);
      }
      await _touchCanvas(layers.first.canvasId, now);
    });
  }

  Future<void> _upsertLayerRow(CanvasLayer layer, DateTime now) async {
    await _db
        .into(_db.canvasLayers)
        .insert(
          db.CanvasLayersCompanion.insert(
            id: layer.id,
            canvasId: layer.canvasId,
            name: layer.name,
            position: layer.position,
            visible: Value(layer.visible),
            locked: Value(layer.locked),
            opacity: Value(layer.opacity),
            blendMode: Value(layer.blendMode),
            kind: Value(layer.kind),
            createdAt: now,
            updatedAt: now,
          ),
          onConflict: DoUpdate(
            (_) => db.CanvasLayersCompanion(
              canvasId: Value(layer.canvasId),
              name: Value(layer.name),
              position: Value(layer.position),
              visible: Value(layer.visible),
              locked: Value(layer.locked),
              opacity: Value(layer.opacity),
              blendMode: Value(layer.blendMode),
              kind: Value(layer.kind),
              updatedAt: Value(now),
            ),
          ),
        );
  }

  /// Canvases whose default content layer this instance has already ensured.
  ///
  /// The insert-or-ignore below is idempotent, but it was issued on every
  /// element load *and* every element save — a write statement on the read
  /// path, and one per save batch, for a row that can only be created once.
  final Set<String> _ensuredDefaultLayers = <String>{};

  Future<void> _ensureDefaultContentLayer(String canvasId) async {
    if (_ensuredDefaultLayers.contains(canvasId)) {
      return;
    }
    final CanvasLayer layer = CanvasLayer.defaultContent(canvasId);
    final DateTime now = DateTime.now();
    await _db
        .into(_db.canvasLayers)
        .insert(
          db.CanvasLayersCompanion.insert(
            id: layer.id,
            canvasId: canvasId,
            name: layer.name,
            position: layer.position,
            visible: Value(layer.visible),
            locked: Value(layer.locked),
            opacity: Value(layer.opacity),
            blendMode: Value(layer.blendMode),
            kind: Value(layer.kind),
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    _ensuredDefaultLayers.add(canvasId);
  }

  // ---------------------------------------------------------------------------
  // Bookmarks
  // ---------------------------------------------------------------------------

  Future<List<Bookmark>> loadBookmarks(String canvasId) async {
    final rows =
        await (_db.select(_db.canvasBookmarks)
              ..where((bookmark) => bookmark.canvasId.equals(canvasId))
              ..orderBy([
                (bookmark) => OrderingTerm(expression: bookmark.position),
              ]))
            .get();
    return [
      for (final row in rows)
        Bookmark(
          name: row.name,
          viewport: ViewportState(
            translation: Offset(row.vpTx, row.vpTy),
            scale: row.vpScale,
            rotation: row.vpRotation,
          ),
        ),
    ];
  }

  Future<void> upsertBookmark(
    String canvasId,
    Bookmark bookmark, {
    required int position,
  }) async {
    final DateTime now = DateTime.now();
    await _db.transaction(() async {
      await _db
          .into(_db.canvasBookmarks)
          .insert(
            db.CanvasBookmarksCompanion.insert(
              canvasId: canvasId,
              name: bookmark.name,
              vpTx: bookmark.viewport.translation.dx,
              vpTy: bookmark.viewport.translation.dy,
              vpScale: bookmark.viewport.scale,
              vpRotation: bookmark.viewport.rotation,
              position: position,
            ),
            onConflict: DoUpdate(
              (_) => db.CanvasBookmarksCompanion(
                vpTx: Value(bookmark.viewport.translation.dx),
                vpTy: Value(bookmark.viewport.translation.dy),
                vpScale: Value(bookmark.viewport.scale),
                vpRotation: Value(bookmark.viewport.rotation),
                position: Value(position),
              ),
            ),
          );
      await _touchCanvas(canvasId, now);
    });
  }

  Future<void> deleteBookmark(String canvasId, String name) async {
    final DateTime now = DateTime.now();
    await _db.transaction(() async {
      await (_db.delete(_db.canvasBookmarks)..where(
            (bookmark) =>
                bookmark.canvasId.equals(canvasId) & bookmark.name.equals(name),
          ))
          .go();
      await _touchCanvas(canvasId, now);
    });
  }

  // ---------------------------------------------------------------------------
  // Viewport
  // ---------------------------------------------------------------------------

  /// Reads the last saved viewport of canvas [canvasId].
  ///
  /// Returns `null` when the canvas row does not exist. A canvas that has never
  /// had a viewport saved returns the schema-default identity viewport.
  Future<ViewportState?> loadViewport(String canvasId) async {
    final db.Canvase? row = await (_db.select(
      _db.canvases,
    )..where((c) => c.id.equals(canvasId))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return ViewportState(
      translation: Offset(row.vpTx, row.vpTy),
      scale: row.vpScale,
      rotation: row.vpRotation,
    );
  }

  /// Reads whether viewport rotation is locked for canvas [canvasId].
  Future<bool> loadRotationLocked(String canvasId) async {
    final db.Canvase? row = await (_db.select(
      _db.canvases,
    )..where((c) => c.id.equals(canvasId))).getSingleOrNull();
    return row?.rotationLocked ?? false;
  }

  Future<CanvasPaperStyle> loadPaperStyle(String canvasId) async {
    final db.Canvase? row = await (_db.select(
      _db.canvases,
    )..where((c) => c.id.equals(canvasId))).getSingleOrNull();
    if (row == null) {
      return const CanvasPaperStyle();
    }
    return CanvasPaperStyle(
      kind: row.backgroundKind,
      backgroundColor: row.canvasBackgroundColor,
      gridColor: row.gridColor,
      gridSpacing: row.gridSpacing,
      gridOpacity: row.gridOpacity,
      graphMajorInterval: row.graphMajorInterval,
      texture: row.paperTexture,
      textureOpacity: row.paperTextureOpacity,
    );
  }

  Future<void> savePaperStyle(String canvasId, CanvasPaperStyle style) {
    return (_db.update(
      _db.canvases,
    )..where((c) => c.id.equals(canvasId))).write(
      db.CanvasesCompanion(
        backgroundKind: Value(style.kind),
        canvasBackgroundColor: Value(style.backgroundColor),
        gridColor: Value(style.gridColor),
        gridSpacing: Value(style.gridSpacing),
        gridOpacity: Value(style.gridOpacity),
        graphMajorInterval: Value(style.graphMajorInterval),
        paperTexture: Value(style.texture),
        paperTextureOpacity: Value(style.textureOpacity),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<CanvasToolSettings> loadToolSettings(String canvasId) async {
    final db.Canvase? row = await (_db.select(
      _db.canvases,
    )..where((c) => c.id.equals(canvasId))).getSingleOrNull();
    if (row == null) {
      return const CanvasToolSettings();
    }
    final CanvasToolSettings legacy = CanvasToolSettings(
      penColor: row.activePenColor,
      penWidth: row.activePenWidth,
      penWidthMode: _penWidthModeToModel(row.activePenWidthMode),
      penKind: _strokeToolToModel(row.activePenTool),
      pressureEnabled: row.pressureEnabled,
    );
    final config = _decodeToolWheel(row.toolWheelJson, legacy);
    return CanvasToolSettings(
      penColor: legacy.penColor,
      penWidth: legacy.penWidth,
      penWidthMode: legacy.penWidthMode,
      penKind: legacy.penKind,
      pressureEnabled: legacy.pressureEnabled,
      toolWheelPresets: config.presets,
      activeToolWheelIndex: config.activeIndex,
    );
  }

  Future<void> saveToolSettings(String canvasId, CanvasToolSettings settings) {
    return (_db.update(
      _db.canvases,
    )..where((c) => c.id.equals(canvasId))).write(
      db.CanvasesCompanion(
        activePenColor: Value(settings.penColor),
        activePenWidth: Value(settings.penWidth),
        activePenWidthMode: Value(_penWidthModeToColumn(settings.penWidthMode)),
        activePenTool: Value(_strokeToolToColumn(settings.penKind)),
        toolWheelJson: Value(_encodeToolWheel(settings)),
        pressureEnabled: Value(settings.pressureEnabled),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Persists [vp] as the last viewport of canvas [canvasId].
  ///
  /// Writes the four `canvases.vp_*` columns and bumps `updated_at`. A no-op
  /// when no canvas has that id.
  Future<void> saveViewport(String canvasId, ViewportState vp) async {
    await (_db.update(_db.canvases)..where((c) => c.id.equals(canvasId))).write(
      db.CanvasesCompanion(
        vpTx: Value(vp.translation.dx),
        vpTy: Value(vp.translation.dy),
        vpScale: Value(vp.scale),
        vpRotation: Value(vp.rotation),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Persists whether viewport rotation is locked for canvas [canvasId].
  Future<void> saveRotationLocked(String canvasId, {required bool locked}) {
    return (_db.update(
      _db.canvases,
    )..where((c) => c.id.equals(canvasId))).write(
      db.CanvasesCompanion(
        rotationLocked: Value(locked),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Canvas row
  // ---------------------------------------------------------------------------

  /// Returns whether [canvasId] still identifies a persisted canvas.
  Future<bool> canvasExists(String canvasId) async {
    return await (_db.selectOnly(_db.canvases)
              ..addColumns([_db.canvases.id])
              ..where(_db.canvases.id.equals(canvasId))
              ..limit(1))
            .getSingleOrNull() !=
        null;
  }

  /// Ensures a `canvases` row exists for [canvasId], creating an empty one if
  /// not.
  ///
  /// Creation/import workflows use this before writing child rows so their
  /// foreign keys have a parent canvas. Editor navigation itself deliberately
  /// refuses unknown ids instead of resurrecting deleted canvases.
  /// Returns whether a row was created.
  Future<bool> ensureCanvasExists(
    String canvasId, {
    String title = 'Canvas',
  }) async {
    final bool exists =
        await (_db.select(
          _db.canvases,
        )..where((c) => c.id.equals(canvasId))).getSingleOrNull() !=
        null;
    if (exists) {
      await _ensureDefaultContentLayer(canvasId);
      return false;
    }
    final DateTime now = DateTime.now();
    await _db
        .into(_db.canvases)
        .insert(
          db.CanvasesCompanion.insert(
            id: canvasId,
            title: title,
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    await _ensureDefaultContentLayer(canvasId);
    return true;
  }

  /// Bumps `canvases.updated_at` for [canvasId] to [now].
  Future<void> _touchCanvas(String canvasId, DateTime now) async {
    await (_db.update(_db.canvases)..where((c) => c.id.equals(canvasId))).write(
      db.CanvasesCompanion(updatedAt: Value(now)),
    );
  }

  // ---------------------------------------------------------------------------
  // Conversions
  // ---------------------------------------------------------------------------

  /// The `canvas_elements.kind` enum value for an engine [element].
  static tables.ElementKind _kindOf(CanvasElement element) {
    return switch (element) {
      InkElement() => tables.ElementKind.stroke,
      ImageElement() => tables.ElementKind.image,
      PdfElement() => tables.ElementKind.pdf,
      LinkElement() => tables.ElementKind.link,
      TextElement() => tables.ElementKind.text,
      ShapeElement() => tables.ElementKind.shape,
    };
  }

  /// Bounds stored in `canvas_elements`.
  ///
  /// Rectangular elements persist their unrotated placement rectangle plus the
  /// separate `rotation` column. Their public [CanvasElement.worldBounds] is a
  /// rotated axis-aligned culling box, which must not be written back as the
  /// placement rect or every save would slowly inflate the element.
  static Rect _storedBoundsOf(CanvasElement element) {
    return switch (element) {
      ImageElement(:final placementBounds) => placementBounds,
      PdfElement(:final placementBounds) => placementBounds,
      LinkElement(:final placementBounds) => placementBounds,
      TextElement(:final placementBounds) => placementBounds,
      _ => element.worldBounds,
    };
  }

  /// Narrows the `REAL` `z_index` column to the engine's `int` z-index.
  static int _zIndexFromColumn(double value) => value.round();

  /// Widens the engine's `int` z-index to the `REAL` `z_index` column.
  static double _zIndexToColumn(int value) => value.toDouble();

  /// Maps a persisted [tables.StrokeTool] to the engine [StrokeToolKind].
  static StrokeToolKind _strokeToolToModel(tables.StrokeTool tool) {
    return switch (tool) {
      tables.StrokeTool.pen => StrokeToolKind.pen,
      tables.StrokeTool.highlighter => StrokeToolKind.highlighter,
      tables.StrokeTool.pencil => StrokeToolKind.pencil,
      tables.StrokeTool.marker => StrokeToolKind.marker,
      tables.StrokeTool.airbrush => StrokeToolKind.airbrush,
      tables.StrokeTool.fill => StrokeToolKind.fill,
    };
  }

  /// Maps an engine [StrokeToolKind] to the persisted [tables.StrokeTool].
  static tables.StrokeTool _strokeToolToColumn(StrokeToolKind tool) {
    return switch (tool) {
      StrokeToolKind.pen => tables.StrokeTool.pen,
      StrokeToolKind.highlighter => tables.StrokeTool.highlighter,
      StrokeToolKind.pencil => tables.StrokeTool.pencil,
      StrokeToolKind.marker => tables.StrokeTool.marker,
      StrokeToolKind.airbrush => tables.StrokeTool.airbrush,
      StrokeToolKind.fill => tables.StrokeTool.fill,
    };
  }

  static String _encodeToolWheel(CanvasToolSettings settings) {
    final List<ToolWheelPreset> presets = List<ToolWheelPreset>.of(
      settings.toolWheelPresets,
    );
    while (presets.length < defaultToolWheelPresets.length) {
      presets.add(defaultToolWheelPresets[presets.length]);
    }
    if (presets.length > defaultToolWheelPresets.length) {
      presets.removeRange(defaultToolWheelPresets.length, presets.length);
    }
    final int activeIndex = settings.activeToolWheelIndex
        .clamp(0, presets.length - 1)
        .toInt();
    if (presets[activeIndex].kind.isInk) {
      presets[activeIndex] = presets[activeIndex].copyWith(
        kind: ToolWheelSlotKind.fromStrokeKind(settings.penKind),
        color: settings.penColor | 0xFF000000,
        size: settings.penWidth,
        opacity: ((settings.penColor >>> 24) & 0xFF) / 255,
        widthMode: settings.penWidthMode,
        pressureEnabled: settings.pressureEnabled,
      );
    }
    return jsonEncode(<String, Object>{
      'version': 1,
      'activeIndex': activeIndex,
      'presets': <Map<String, Object>>[
        for (final ToolWheelPreset preset in presets) preset.toJson(),
      ],
    });
  }

  static ({List<ToolWheelPreset> presets, int activeIndex}) _decodeToolWheel(
    String raw,
    CanvasToolSettings legacy,
  ) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map && decoded['presets'] is List) {
        final List<Object?> rawPresets = List<Object?>.of(
          decoded['presets'] as List,
        );
        final List<ToolWheelPreset> presets = <ToolWheelPreset>[
          for (var index = 0; index < defaultToolWheelPresets.length; index++)
            ToolWheelPreset.fromJson(
                  index < rawPresets.length ? rawPresets[index] : null,
                ) ??
                defaultToolWheelPresets[index],
        ];
        final int activeIndex = ((decoded['activeIndex'] as num?)?.toInt() ?? 0)
            .clamp(0, presets.length - 1)
            .toInt();
        return (
          presets: List<ToolWheelPreset>.unmodifiable(presets),
          activeIndex: activeIndex,
        );
      }
    } catch (_) {
      // Fall back to the legacy active-pen columns below.
    }

    final List<ToolWheelPreset> presets = List<ToolWheelPreset>.of(
      defaultToolWheelPresets,
    );
    final ToolWheelSlotKind legacyKind = ToolWheelSlotKind.fromStrokeKind(
      legacy.penKind,
    );
    final int activeIndex = presets.indexWhere(
      (ToolWheelPreset preset) => preset.kind == legacyKind,
    );
    final int safeIndex = activeIndex < 0 ? 0 : activeIndex;
    presets[safeIndex] = presets[safeIndex].copyWith(
      color: legacy.penColor | 0xFF000000,
      size: legacy.penWidth,
      opacity: ((legacy.penColor >>> 24) & 0xFF) / 255,
      widthMode: legacy.penWidthMode,
      pressureEnabled: legacy.pressureEnabled,
    );
    return (
      presets: List<ToolWheelPreset>.unmodifiable(presets),
      activeIndex: safeIndex,
    );
  }

  static PenWidthMode _penWidthModeToModel(int value) {
    if (value < 0 || value >= PenWidthMode.values.length) {
      return PenWidthMode.screen;
    }
    return PenWidthMode.values[value];
  }

  static int _penWidthModeToColumn(PenWidthMode mode) => mode.index;

  static ArrowBodyKind _arrowBodyToModel(int value) {
    if (value < 0 || value >= ArrowBodyKind.values.length) {
      return ArrowBodyKind.straight;
    }
    return ArrowBodyKind.values[value];
  }

  static ArrowHeadStyle _arrowHeadToModel(int value) {
    if (value < 0 || value >= ArrowHeadStyle.values.length) {
      return ArrowHeadStyle.filled;
    }
    return ArrowHeadStyle.values[value];
  }

  static String _encodeControlPoints(List<Offset> points) {
    return jsonEncode(<List<double>>[
      for (final Offset point in points) <double>[point.dx, point.dy],
    ]);
  }

  static List<Offset> _decodeControlPoints(String json) {
    try {
      final Object? decoded = jsonDecode(json);
      if (decoded is! List) {
        return const <Offset>[];
      }
      return <Offset>[
        for (final Object? point in decoded)
          if (point is List && point.length >= 2)
            Offset((point[0] as num).toDouble(), (point[1] as num).toDouble()),
      ];
    } catch (_) {
      return const <Offset>[];
    }
  }

  /// Rebuilds a link's target [ViewportState] from a [db.CanvasLink] row.
  ///
  /// Returns `null` (a plain canvas link) unless every `target_vp_*` column is
  /// populated — they are written and read as an all-or-nothing group.
  static ViewportState? _viewportFromLinkColumns(db.CanvasLink link) {
    final double? tx = link.targetVpTx;
    final double? ty = link.targetVpTy;
    final double? scale = link.targetVpScale;
    final double? rotation = link.targetVpRotation;
    if (tx == null || ty == null || scale == null || rotation == null) {
      return null;
    }
    return ViewportState(
      translation: Offset(tx, ty),
      scale: scale,
      rotation: rotation,
    );
  }

  /// Returns the file-name component of [path] (after the last separator).
  static String _baseName(String path) {
    final int slash = path.lastIndexOf(RegExp(r'[\\/]'));
    return slash < 0 ? path : path.substring(slash + 1);
  }
}
