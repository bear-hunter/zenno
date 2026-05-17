import 'package:drift/drift.dart';

/// How a canvas background grid is rendered.
enum BackgroundKind { blank, grid, lined, dotted }

/// The visual/behavioural type of a positioned canvas element.
enum ElementKind { stroke, pdf, link, image, text, card, shape }

/// The freehand drawing tool used to author an [InkStrokes] row.
enum StrokeTool { pen, highlighter }

/// The kind of destination a [CanvasLinks] row points at.
enum CanvasLinkKind { web, canvas, region, bookmark }

/// Library documents. Each row is one infinite canvas.
@TableIndex(name: 'idx_canvases_folder_id', columns: {#folderId})
@TableIndex(name: 'idx_canvases_updated_at', columns: {#updatedAt})
class Canvases extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
  TextColumn get thumbnailPath => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get folderId =>
      text().nullable().references(CanvasFolders, #id, onDelete: KeyAction.cascade)();

  /// Viewport rebasing anchor — keeps active world coordinates small.
  RealColumn get worldOriginX => real().withDefault(const Constant(0))();
  RealColumn get worldOriginY => real().withDefault(const Constant(0))();

  /// Last viewport, restored when the canvas is reopened.
  RealColumn get vpTx => real().withDefault(const Constant(0))();
  RealColumn get vpTy => real().withDefault(const Constant(0))();
  RealColumn get vpScale => real().withDefault(const Constant(1))();
  RealColumn get vpRotation => real().withDefault(const Constant(0))();

  IntColumn get backgroundKind =>
      intEnum<BackgroundKind>().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One-level grouping for canvases in the library.
class CanvasFolders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Fractional ordering position.
  RealColumn get position => real()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Generic positioned element on a canvas. Detail tables hold kind-specific data.
@TableIndex(name: 'idx_canvas_elements_canvas_id', columns: {#canvasId})
@TableIndex(
  name: 'idx_canvas_elements_canvas_id_z_index',
  columns: {#canvasId, #zIndex},
)
class CanvasElements extends Table {
  TextColumn get id => text()();
  TextColumn get canvasId =>
      text().references(Canvases, #id, onDelete: KeyAction.cascade)();
  IntColumn get kind => intEnum<ElementKind>()();

  /// World-space bounds — stored so the spatial index loads without
  /// decoding element payloads.
  RealColumn get x => real()();
  RealColumn get y => real()();
  RealColumn get width => real()();
  RealColumn get height => real()();
  RealColumn get rotation => real().withDefault(const Constant(0))();

  /// Fractional z-ordering within the canvas.
  RealColumn get zIndex => real()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 1:1 detail for [ElementKind.stroke] elements. The only BLOB in the schema.
class InkStrokes extends Table {
  TextColumn get elementId =>
      text().references(CanvasElements, #id, onDelete: KeyAction.cascade)();

  /// Packed `Float32List` `[x, y, pressure, ...]` with a leading
  /// 1-byte format version.
  BlobColumn get points => blob()();
  IntColumn get pointCount => integer()();

  /// ARGB colour value.
  IntColumn get color => integer()();

  /// Logical stroke width.
  RealColumn get strokeWidth => real()();
  IntColumn get tool => intEnum<StrokeTool>()();
  BoolColumn get isHighlighter => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {elementId};
}

/// 1:1 detail for [ElementKind.pdf] elements.
class PdfDocuments extends Table {
  TextColumn get elementId =>
      text().references(CanvasElements, #id, onDelete: KeyAction.cascade)();

  /// Path of the PDF copied into the app documents directory.
  TextColumn get filePath => text()();
  TextColumn get originalFilename => text()();
  IntColumn get pageNumber => integer()();
  IntColumn get totalPages => integer()();

  /// Optional excerpt sub-region (fraction of the page).
  RealColumn get cropLeft => real().nullable()();
  RealColumn get cropTop => real().nullable()();
  RealColumn get cropRight => real().nullable()();
  RealColumn get cropBottom => real().nullable()();

  /// Content hash used to dedupe repeated imports.
  TextColumn get importHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {elementId};
}

/// 1:1 detail for [ElementKind.image] elements.
///
/// Holds an imported raster picture's source path and its native pixel size.
/// The decoded bitmap itself is a runtime-only cache and is never persisted —
/// it is re-decoded from [filePath] when the element scrolls into view.
class Images extends Table {
  TextColumn get elementId =>
      text().references(CanvasElements, #id, onDelete: KeyAction.cascade)();

  /// Path of the image copied into the app documents directory.
  TextColumn get filePath => text()();

  /// Native pixel width of the source image, used to preserve aspect ratio.
  RealColumn get intrinsicWidth => real()();

  /// Native pixel height of the source image, used to preserve aspect ratio.
  RealColumn get intrinsicHeight => real()();

  @override
  Set<Column> get primaryKey => {elementId};
}

/// 1:1 detail for [ElementKind.link] elements. Also persisted as elements,
/// these rows enable back-link and graph queries.
///
/// A link target is a full [ViewportState] (translation + scale + rotation),
/// so the destination camera round-trips losslessly through the four
/// `target_vp_*` columns. The legacy `target_rect_*` columns are retained but
/// unused — a region link no longer stores a bare rect.
class CanvasLinks extends Table {
  TextColumn get elementId =>
      text().references(CanvasElements, #id, onDelete: KeyAction.cascade)();
  IntColumn get linkKind => intEnum<CanvasLinkKind>()();
  TextColumn get url => text().nullable()();
  TextColumn get title => text().nullable()();
  // Soft reference — NOT a DB foreign key: a link may point at a canvas that
  // does not exist yet or was later deleted. Dangling links are handled in the
  // UI (shown broken), never enforced by a constraint.
  TextColumn get targetCanvasId => text().nullable()();

  /// Optional target region rectangle in world space (legacy — unused; a
  /// region link stores its destination camera in the `target_vp_*` columns).
  RealColumn get targetRectX => real().nullable()();
  RealColumn get targetRectY => real().nullable()();
  RealColumn get targetRectWidth => real().nullable()();
  RealColumn get targetRectHeight => real().nullable()();

  /// Optional destination viewport — the camera the target canvas flies to on
  /// open. All four are non-null together (a region link) or all null (a plain
  /// canvas link), mirroring the `canvases.vp_*` column shape.
  RealColumn get targetVpTx => real().nullable()();
  RealColumn get targetVpTy => real().nullable()();
  RealColumn get targetVpScale => real().nullable()();
  RealColumn get targetVpRotation => real().nullable()();

  TextColumn get label => text()();

  @override
  Set<Column> get primaryKey => {elementId};
}
