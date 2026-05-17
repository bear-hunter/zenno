import 'dart:ui' show Rect, Size, Offset;

import 'package:drift/drift.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/persistence/ink_codec.dart';
// The Drift table `CanvasElements` generates a row class also called
// `CanvasElement`, colliding with the engine's sealed `CanvasElement`; the
// database import is aliased `as db` so Drift types are reached via `db.`.
import 'package:zenno/core/database/database.dart' as db;
import 'package:zenno/core/database/tables/canvas_tables.dart' as tables;

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
///
/// A `z_index` is an `int` in the engine model but a `REAL` column; the
/// conversion is a plain `int` ↔ `double` round-trip (engine z-indices are
/// always whole numbers).
class CanvasRepository {
  /// Creates a repository persisting to [_db].
  CanvasRepository(this._db);

  final db.ZennoDatabase _db;

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
    final List<db.CanvasElement> rows =
        await (_db.select(_db.canvasElements)
              ..where(
                (e) => e.canvasId.equals(canvasId) & e.isDeleted.equals(false),
              )
              ..orderBy([
                (e) => OrderingTerm(expression: e.zIndex),
              ]))
            .get();

    final List<CanvasElement> elements = <CanvasElement>[];
    for (final db.CanvasElement row in rows) {
      final CanvasElement? element = await _reconstruct(row);
      if (element != null) {
        elements.add(element);
      }
    }
    return elements;
  }

  /// Rebuilds the engine [CanvasElement] for a `canvas_elements` [row].
  ///
  /// Returns `null` when the row's kind has no engine representation, or when
  /// its detail row is absent.
  Future<CanvasElement?> _reconstruct(db.CanvasElement row) async {
    final Rect bounds = Rect.fromLTWH(row.x, row.y, row.width, row.height);
    final int zIndex = _zIndexFromColumn(row.zIndex);
    switch (row.kind) {
      case tables.ElementKind.stroke:
        final db.InkStroke? detail = await (_db.select(_db.inkStrokes)
              ..where((s) => s.elementId.equals(row.id)))
            .getSingleOrNull();
        if (detail == null) {
          return null;
        }
        return InkElement(
          id: row.id,
          zIndex: zIndex,
          worldBounds: bounds,
          stroke: Stroke(
            id: row.id,
            points: InkCodec.decodePoints(detail.points),
            color: detail.color,
            width: detail.strokeWidth,
            tool: _strokeToolToModel(detail.tool),
          ),
        );
      case tables.ElementKind.image:
        final db.Image? detail = await (_db.select(_db.images)
              ..where((i) => i.elementId.equals(row.id)))
            .getSingleOrNull();
        if (detail == null) {
          return null;
        }
        return ImageElement(
          id: row.id,
          zIndex: zIndex,
          worldBounds: bounds,
          sourceFilePath: detail.filePath,
          intrinsicSize: Size(detail.intrinsicWidth, detail.intrinsicHeight),
        );
      case tables.ElementKind.pdf:
        final db.PdfDocument? detail = await (_db.select(_db.pdfDocuments)
              ..where((p) => p.elementId.equals(row.id)))
            .getSingleOrNull();
        if (detail == null) {
          return null;
        }
        return PdfElement(
          id: row.id,
          zIndex: zIndex,
          worldBounds: bounds,
          sourceFilePath: detail.filePath,
          pageNumber: detail.pageNumber,
          pageSize: Size(
            detail.cropRight ?? bounds.width,
            detail.cropBottom ?? bounds.height,
          ),
        );
      case tables.ElementKind.link:
        final db.CanvasLink? detail = await (_db.select(_db.canvasLinks)
              ..where((l) => l.elementId.equals(row.id)))
            .getSingleOrNull();
        if (detail == null) {
          return null;
        }
        return LinkElement(
          id: row.id,
          zIndex: zIndex,
          worldBounds: bounds,
          label: detail.label,
          target: LinkTarget(
            targetCanvasId: detail.targetCanvasId ?? '',
            targetViewport: _viewportFromLinkColumns(detail),
          ),
        );
      case tables.ElementKind.text:
      case tables.ElementKind.card:
      case tables.ElementKind.shape:
        // No engine representation yet — a later phase reconstructs these.
        return null;
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
    final DateTime now = DateTime.now();
    await _db.transaction(() async {
      await _db
          .into(_db.canvasElements)
          .insert(
            db.CanvasElementsCompanion.insert(
              id: element.id,
              canvasId: canvasId,
              kind: _kindOf(element),
              x: element.worldBounds.left,
              y: element.worldBounds.top,
              width: element.worldBounds.width,
              height: element.worldBounds.height,
              zIndex: _zIndexToColumn(element.zIndex),
              createdAt: now,
              updatedAt: now,
            ),
            mode: InsertMode.insertOrReplace,
          );
      await _writeDetail(element);
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
                isHighlighter: Value(
                  stroke.tool == StrokeToolKind.highlighter,
                ),
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
    }
  }

  /// Deletes the element [id] and its detail row.
  ///
  /// Only the `canvas_elements` row is deleted explicitly — the `ON DELETE
  /// CASCADE` foreign key on every detail table removes the matching detail
  /// row (the FK pragma is enabled in `beforeOpen`). A no-op when no element
  /// has that id.
  Future<void> deleteElement(String id) async {
    await (_db.delete(_db.canvasElements)..where((e) => e.id.equals(id))).go();
  }

  // ---------------------------------------------------------------------------
  // Viewport
  // ---------------------------------------------------------------------------

  /// Reads the last saved viewport of canvas [canvasId].
  ///
  /// Returns `null` when the canvas row does not exist. A canvas that has never
  /// had a viewport saved returns the schema-default identity viewport.
  Future<ViewportState?> loadViewport(String canvasId) async {
    final db.Canvase? row = await (_db.select(_db.canvases)
          ..where((c) => c.id.equals(canvasId)))
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return ViewportState(
      translation: Offset(row.vpTx, row.vpTy),
      scale: row.vpScale,
      rotation: row.vpRotation,
    );
  }

  /// Persists [vp] as the last viewport of canvas [canvasId].
  ///
  /// Writes the four `canvases.vp_*` columns and bumps `updated_at`. A no-op
  /// when no canvas has that id.
  Future<void> saveViewport(String canvasId, ViewportState vp) async {
    await (_db.update(_db.canvases)..where((c) => c.id.equals(canvasId)))
        .write(
      db.CanvasesCompanion(
        vpTx: Value(vp.translation.dx),
        vpTy: Value(vp.translation.dy),
        vpScale: Value(vp.scale),
        vpRotation: Value(vp.rotation),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Canvas row
  // ---------------------------------------------------------------------------

  /// Ensures a `canvases` row exists for [canvasId], creating an empty one if
  /// not.
  ///
  /// The library normally creates the canvas row before the editor opens, but
  /// the editor can also be reached directly (a deep link, a test). This makes
  /// the editor self-sufficient: a fresh canvas gets a placeholder row so its
  /// elements and viewport have a parent to hang off (and the FK holds).
  /// Returns whether a row was created.
  Future<bool> ensureCanvasExists(String canvasId, {String title = 'Canvas'}) async {
    final bool exists =
        await (_db.select(_db.canvases)..where((c) => c.id.equals(canvasId)))
                .getSingleOrNull() !=
            null;
    if (exists) {
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
    return true;
  }

  /// Bumps `canvases.updated_at` for [canvasId] to [now].
  Future<void> _touchCanvas(String canvasId, DateTime now) async {
    await (_db.update(_db.canvases)..where((c) => c.id.equals(canvasId)))
        .write(db.CanvasesCompanion(updatedAt: Value(now)));
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
    };
  }

  /// Maps an engine [StrokeToolKind] to the persisted [tables.StrokeTool].
  static tables.StrokeTool _strokeToolToColumn(StrokeToolKind tool) {
    return switch (tool) {
      StrokeToolKind.pen => tables.StrokeTool.pen,
      StrokeToolKind.highlighter => tables.StrokeTool.highlighter,
    };
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
