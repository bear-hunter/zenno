import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:zenno/canvas/engine/stroke_builder.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';

/// A single positioned object living on the infinite canvas.
///
/// This is the unified element type the engine deals in: the committed layer,
/// the spatial index and the undo/redo commands all operate on
/// [CanvasElement]s rather than on any one concrete content type. Geometry is
/// always expressed in **world space**.
///
/// The type is a Dart 3 [sealed] class, so a `switch` over a [CanvasElement]
/// is exhaustively checked at compile time. The concrete variants today are
/// [InkElement] (freehand ink and geometric shapes), [ImageElement] (an
/// imported raster picture), [PdfElement] (one rasterised page of an imported
/// PDF), [LinkElement] (a tappable chip that navigates to another canvas), and
/// [TextElement] (a positioned typed note).
///
/// Elements are treated as immutable: a mutation produces a new instance
/// (see [InkElement.copyWith]) so the command stack and `CustomPainter`
/// repaint checks can rely on identity. The one exception is a *runtime raster
/// cache* — see [ImageElement.raster] / [PdfElement.raster] — which is a
/// decoded `ui.Image` populated asynchronously after construction. The raster
/// is never part of an element's identity, equality or persistence: it is a
/// pure render-time optimisation that can be rebuilt from the element's source
/// file at any time.
sealed class CanvasElement {
  /// Creates the shared element fields.
  const CanvasElement({required this.id, required this.zIndex});

  /// Stable unique identifier (uuid v7). Doubles as the key in the spatial
  /// index and in any element-keyed command.
  final String id;

  /// Paint order within the canvas: lower values are painted first (further
  /// back). The controller keeps its element list sorted by this value.
  final int zIndex;

  /// Axis-aligned bounding box of this element in world coordinates.
  ///
  /// Used for viewport culling: the committed-layer painter only draws
  /// elements whose [worldBounds] intersect the visible world rectangle, and
  /// the spatial index is keyed on this rect. Concrete variants either store
  /// it or compute it from their geometry.
  Rect get worldBounds;

  /// Returns a copy of this element shifted by [delta] in world space.
  ///
  /// Every concrete variant offsets its own geometry — so the engine can move
  /// a mixed selection (ink, image, PDF) without knowing each kind's
  /// internals. Backs `MoveElementsCommand` and the lasso drag. The [id] and
  /// [zIndex] are preserved; only the geometry changes.
  CanvasElement translated(Offset delta);
}

/// A [CanvasElement] wrapping a single freehand ink [Stroke].
///
/// This is the concrete element produced when the user finishes drawing.
/// [worldBounds] is derived once from the stroke's centerline (inflated by
/// half the stroke width so the painted outline is fully covered) and cached,
/// because strokes are immutable once committed.
final class InkElement extends CanvasElement {
  /// Creates an ink element wrapping [stroke].
  ///
  /// Prefer [InkElement.fromStroke], which fills [zIndex] and [id] from the
  /// stroke and computes the cached [worldBounds].
  InkElement({
    required super.id,
    required super.zIndex,
    required this.stroke,
    Rect? worldBounds,
  }) : _worldBounds = worldBounds ?? computeBounds(stroke);

  /// Creates an ink element from [stroke], taking its [id] from the stroke and
  /// placing it at [zIndex] in the canvas paint order.
  factory InkElement.fromStroke(Stroke stroke, {required int zIndex}) {
    return InkElement(id: stroke.id, zIndex: zIndex, stroke: stroke);
  }

  /// The ink geometry and style this element renders.
  final Stroke stroke;

  /// Cached world-space bounds, computed from [stroke] at construction.
  final Rect _worldBounds;

  /// Lazily-built, then cached, `perfect_freehand` outline of [stroke].
  ///
  /// `null` until [outlinePath] is first read. Because an [InkElement] is
  /// immutable, the outline is geometry-stable for the element's whole life,
  /// so it is built once and reused on every repaint instead of being
  /// recomputed per frame — the per-element path cache that, together with
  /// viewport culling, keeps the committed layer cheap. A mutation produces a
  /// new [InkElement] (see [copyWith]) with its own empty cache, so the path
  /// is rebuilt exactly when — and only when — the stroke actually changes.
  Path? _outlinePath;

  @override
  Rect get worldBounds => _worldBounds;

  /// The committed (`isComplete: true`) world-space fill outline of [stroke].
  ///
  /// Built on first access via [buildStrokeOutline] and cached for reuse; see
  /// [_outlinePath]. The committed-layer painter draws this path directly.
  Path get outlinePath {
    return _outlinePath ??= buildStrokeOutline(
      stroke.points,
      size: stroke.width,
      isComplete: true,
    );
  }

  /// Returns a copy with the given fields replaced.
  ///
  /// When [stroke] changes the [worldBounds] are recomputed unless an explicit
  /// [worldBounds] is supplied.
  InkElement copyWith({
    String? id,
    int? zIndex,
    Stroke? stroke,
    Rect? worldBounds,
  }) {
    final Stroke nextStroke = stroke ?? this.stroke;
    return InkElement(
      id: id ?? this.id,
      zIndex: zIndex ?? this.zIndex,
      stroke: nextStroke,
      worldBounds:
          worldBounds ??
          (stroke == null ? _worldBounds : computeBounds(nextStroke)),
    );
  }

  @override
  InkElement translated(Offset delta) {
    final List<StrokePoint> shifted = <StrokePoint>[
      for (final StrokePoint p in stroke.points)
        StrokePoint(p.x + delta.dx, p.y + delta.dy, p.pressure),
    ];
    return copyWith(
      stroke: stroke.copyWith(points: shifted),
      worldBounds: _worldBounds.shift(delta),
    );
  }

  /// Computes the axis-aligned world bounds of [stroke].
  ///
  /// The bounds enclose every centerline point, inflated on all sides by half
  /// the stroke [Stroke.width] so the variable-width painted outline — which
  /// extends up to that far from the centerline — is fully contained. This
  /// keeps viewport culling conservative: an element is never culled while any
  /// of its ink is still on screen. An empty stroke yields [Rect.zero].
  static Rect computeBounds(Stroke stroke) {
    final List<StrokePoint> points = stroke.points;
    if (points.isEmpty) {
      return Rect.zero;
    }

    double minX = points.first.x;
    double maxX = points.first.x;
    double minY = points.first.y;
    double maxY = points.first.y;
    for (final StrokePoint p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final double pad = stroke.width / 2;
    return Rect.fromLTRB(minX - pad, minY - pad, maxX + pad, maxY + pad);
  }

  @override
  String toString() =>
      'InkElement(id: $id, zIndex: $zIndex, bounds: $_worldBounds)';
}

/// A [CanvasElement] wrapping a single imported raster image.
///
/// Unlike [InkElement] — whose geometry is a centerline of points — an image
/// has no internal geometry: its placement on the canvas *is* a world-space
/// [worldBounds] rectangle, stored directly. A move just shifts that rect; a
/// (future) resize just replaces it. The intrinsic pixel size of the source
/// file is kept in [intrinsicSize] so the placement rectangle can preserve the
/// image's aspect ratio.
///
/// [sourceFilePath] is an absolute filesystem path to the picture *inside the
/// app's documents directory* — the importer copies the picked file there so
/// the path stays valid for persistence (step 1.7). It is the only field that
/// is persisted; everything needed to repaint the element is reproducible from
/// it.
///
/// [raster] is a **runtime-only** decoded `ui.Image`. It is `null` immediately
/// after import and is filled in asynchronously once the file has been decoded
/// off the UI path; until then the painter draws a neutral placeholder. The
/// raster is deliberately excluded from [==] / [hashCode]: two image elements
/// are equal when their *placement and source* match, regardless of whether
/// either has decoded its bitmap yet. This keeps undo/redo snapshots and the
/// command stack reasoning purely about persistent state.
final class ImageElement extends CanvasElement {
  /// Creates an image element placed at [worldBounds].
  ///
  /// [sourceFilePath] is the absolute path of the (app-local copy of the)
  /// picture; [intrinsicSize] is its native pixel size. [raster], when given,
  /// seeds the runtime bitmap cache — callers translating or re-z-indexing an
  /// existing element pass the already-decoded image straight through so the
  /// picture never has to be re-decoded for a move.
  const ImageElement({
    required super.id,
    required super.zIndex,
    required Rect worldBounds,
    required this.sourceFilePath,
    required this.intrinsicSize,
    this.raster,
  }) : _worldBounds = worldBounds;

  /// World-space placement rectangle — this element's geometry in full.
  final Rect _worldBounds;

  /// Absolute filesystem path of the imported picture.
  ///
  /// Points at the app-documents-directory copy made by the importer, so it
  /// remains valid across app launches and is safe to persist.
  final String sourceFilePath;

  /// Native pixel dimensions of the source image, used to preserve aspect
  /// ratio when the placement rectangle is created or resized.
  final Size intrinsicSize;

  /// Runtime-only decoded bitmap, or `null` until the image has been loaded.
  ///
  /// Never persisted and never part of equality — see the class doc. The
  /// painter draws a placeholder while this is `null`.
  final ui.Image? raster;

  @override
  Rect get worldBounds => _worldBounds;

  /// Returns a copy with the given fields replaced.
  ///
  /// Passing [raster] explicitly (including a fresh decode) swaps the runtime
  /// bitmap without disturbing placement; omitting it keeps the current one.
  /// Set [clearRaster] to drop the runtime bitmap back to `null` (used when
  /// the controller evicts an off-screen raster under memory pressure) —
  /// [clearRaster] and a non-null [raster] are mutually exclusive.
  ImageElement copyWith({
    String? id,
    int? zIndex,
    Rect? worldBounds,
    String? sourceFilePath,
    Size? intrinsicSize,
    ui.Image? raster,
    bool clearRaster = false,
  }) {
    assert(
      !(clearRaster && raster != null),
      'copyWith: pass either a new raster or clearRaster, not both.',
    );
    return ImageElement(
      id: id ?? this.id,
      zIndex: zIndex ?? this.zIndex,
      worldBounds: worldBounds ?? _worldBounds,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
      intrinsicSize: intrinsicSize ?? this.intrinsicSize,
      raster: clearRaster ? null : (raster ?? this.raster),
    );
  }

  @override
  ImageElement translated(Offset delta) {
    // The runtime raster is carried through verbatim: a move does not change
    // the pixels, so the decoded bitmap stays valid and is never re-decoded.
    return copyWith(worldBounds: _worldBounds.shift(delta));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    // `raster` is intentionally excluded — it is a runtime cache, not state.
    return other is ImageElement &&
        other.id == id &&
        other.zIndex == zIndex &&
        other._worldBounds == _worldBounds &&
        other.sourceFilePath == sourceFilePath &&
        other.intrinsicSize == intrinsicSize;
  }

  @override
  int get hashCode =>
      Object.hash(id, zIndex, _worldBounds, sourceFilePath, intrinsicSize);

  @override
  String toString() =>
      'ImageElement(id: $id, zIndex: $zIndex, bounds: $_worldBounds, '
      'source: $sourceFilePath, raster: ${raster == null ? 'pending' : 'ready'})';
}

/// A [CanvasElement] wrapping a single rasterised page of an imported PDF.
///
/// Each PDF page imported onto the canvas is its own [PdfElement] — a ten-page
/// PDF import yields ten elements. Like [ImageElement], its placement *is* a
/// world-space [worldBounds] rectangle, stored directly; a move shifts the
/// rect.
///
/// [sourceFilePath] is the absolute path of the PDF copied into the app's
/// documents directory; [pageNumber] is the 1-based page this element shows;
/// [pageSize] is that page's intrinsic size in PDF points (1/72"), used to
/// keep the placement rectangle's aspect ratio correct. Those three fields,
/// together with [id]/[zIndex]/[worldBounds], are the persistent state — they
/// map onto the `canvas_elements` + `pdf_documents` tables in step 1.7.
///
/// [raster] is a **runtime-only** decoded `ui.Image` of the page. PDF page
/// rasterisation is CPU-heavy, so it is produced asynchronously off the UI
/// path; [raster] is `null` until that finishes and the painter shows a
/// placeholder meanwhile. [rasterScaleBucket] records the zoom bucket the
/// current [raster] was rendered for, so the controller can re-rasterise at a
/// higher resolution when the user zooms in well past it. The raster and its
/// bucket are excluded from [==] / [hashCode]: equality is about the page and
/// its placement, not about which resolution happens to be cached.
final class PdfElement extends CanvasElement {
  /// Creates a PDF-page element placed at [worldBounds].
  ///
  /// [sourceFilePath] is the absolute path of the (app-local copy of the) PDF;
  /// [pageNumber] is 1-based; [pageSize] is the page size in PDF points.
  /// [raster] / [rasterScaleBucket] seed the runtime page-bitmap cache.
  const PdfElement({
    required super.id,
    required super.zIndex,
    required Rect worldBounds,
    required this.sourceFilePath,
    required this.pageNumber,
    required this.pageSize,
    this.raster,
    this.rasterScaleBucket = 0,
  }) : _worldBounds = worldBounds;

  /// World-space placement rectangle — this element's geometry in full.
  final Rect _worldBounds;

  /// Absolute filesystem path of the imported PDF.
  ///
  /// Points at the app-documents-directory copy made by the importer, so it
  /// remains valid across app launches and is safe to persist.
  final String sourceFilePath;

  /// 1-based index of the page this element renders within the source PDF.
  final int pageNumber;

  /// Intrinsic size of the page in PDF points (1/72"), used to preserve the
  /// page's aspect ratio when the placement rectangle is created.
  final Size pageSize;

  /// Runtime-only decoded page bitmap, or `null` until the page is rendered.
  ///
  /// Never persisted and never part of equality — see the class doc.
  final ui.Image? raster;

  /// Zoom bucket the current [raster] was rendered for.
  ///
  /// A coarse index into a ladder of render resolutions (see the controller's
  /// raster scheduling). When the live zoom moves into a higher bucket than
  /// this, the page is re-rasterised sharper. `0` while no raster exists yet.
  /// Runtime-only, like [raster].
  final int rasterScaleBucket;

  @override
  Rect get worldBounds => _worldBounds;

  /// Returns a copy with the given fields replaced.
  ///
  /// Passing [raster] / [rasterScaleBucket] swaps the runtime page bitmap (and
  /// records the resolution it was rendered for) without disturbing
  /// placement; omitting them keeps the current cache. Set [clearRaster] to
  /// drop the runtime bitmap back to `null` and reset the bucket to `0` (used
  /// when the controller evicts an off-screen raster under memory pressure) —
  /// [clearRaster] and a non-null [raster] are mutually exclusive.
  PdfElement copyWith({
    String? id,
    int? zIndex,
    Rect? worldBounds,
    String? sourceFilePath,
    int? pageNumber,
    Size? pageSize,
    ui.Image? raster,
    int? rasterScaleBucket,
    bool clearRaster = false,
  }) {
    assert(
      !(clearRaster && raster != null),
      'copyWith: pass either a new raster or clearRaster, not both.',
    );
    return PdfElement(
      id: id ?? this.id,
      zIndex: zIndex ?? this.zIndex,
      worldBounds: worldBounds ?? _worldBounds,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      raster: clearRaster ? null : (raster ?? this.raster),
      rasterScaleBucket: clearRaster
          ? 0
          : (rasterScaleBucket ?? this.rasterScaleBucket),
    );
  }

  @override
  PdfElement translated(Offset delta) {
    // The runtime raster is carried through verbatim: a move does not change
    // the page pixels, so the decoded bitmap (and its bucket) stay valid.
    return copyWith(worldBounds: _worldBounds.shift(delta));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    // `raster` / `rasterScaleBucket` are intentionally excluded — runtime
    // cache, not persistent state.
    return other is PdfElement &&
        other.id == id &&
        other.zIndex == zIndex &&
        other._worldBounds == _worldBounds &&
        other.sourceFilePath == sourceFilePath &&
        other.pageNumber == pageNumber &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
    id,
    zIndex,
    _worldBounds,
    sourceFilePath,
    pageNumber,
    pageSize,
  );

  @override
  String toString() =>
      'PdfElement(id: $id, zIndex: $zIndex, bounds: $_worldBounds, '
      'source: $sourceFilePath, page: $pageNumber, '
      'raster: ${raster == null ? 'pending' : 'ready'})';
}

/// Where a [LinkElement] sends the reader when its chip is tapped.
///
/// A small immutable value type — not a [CanvasElement] — describing the
/// navigation destination of a link. v1 covers the one destination kind the
/// app needs: **another canvas in the library**, identified by
/// [targetCanvasId]. A link may additionally pin a [targetViewport]: the camera
/// the destination canvas should "fly to" on open, so a link can point not just
/// at a canvas but at a *specific region* of it (a diagram, a paragraph). When
/// [targetViewport] is `null` the destination simply opens at its own last
/// saved viewport.
///
/// The type is deliberately a plain value (manual [==] / [hashCode], a
/// [copyWith], no codegen) so it is trivially serialisable. It maps directly
/// onto the `canvas_links` Drift table in step 1.7 — see the class doc on
/// [LinkElement] for the column mapping.
@immutable
class LinkTarget {
  /// Creates a link target pointing at the canvas [targetCanvasId], optionally
  /// framing [targetViewport] on arrival.
  const LinkTarget({required this.targetCanvasId, this.targetViewport});

  /// Identifier of the destination canvas document (a `canvases.id` value).
  ///
  /// Navigating a [LinkElement] pushes the `/canvas/:id` route for this id.
  final String targetCanvasId;

  /// Camera the destination canvas should frame when opened, or `null` to open
  /// at the destination's own last viewport.
  ///
  /// Stored as a full [ViewportState] (translation + scale + rotation) so a
  /// link can pin an exact framing — the destination editor applies it as a
  /// "fly-to" on load. A region-style link is just a [targetViewport] computed
  /// to centre that region; there is no separate rect field.
  final ViewportState? targetViewport;

  /// Whether this target pins a specific [targetViewport] to fly to.
  bool get hasViewport => targetViewport != null;

  /// Returns a copy with the given fields replaced.
  ///
  /// [clearViewport] drops [targetViewport] back to `null`; it and a non-null
  /// [targetViewport] are mutually exclusive.
  LinkTarget copyWith({
    String? targetCanvasId,
    ViewportState? targetViewport,
    bool clearViewport = false,
  }) {
    assert(
      !(clearViewport && targetViewport != null),
      'copyWith: pass either a new targetViewport or clearViewport, not both.',
    );
    return LinkTarget(
      targetCanvasId: targetCanvasId ?? this.targetCanvasId,
      targetViewport: clearViewport
          ? null
          : (targetViewport ?? this.targetViewport),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LinkTarget &&
        other.targetCanvasId == targetCanvasId &&
        other.targetViewport == targetViewport;
  }

  @override
  int get hashCode => Object.hash(targetCanvasId, targetViewport);

  @override
  String toString() =>
      'LinkTarget(canvas: $targetCanvasId, '
      'viewport: $targetViewport)';
}

/// A [CanvasElement] that renders as a small tappable chip and navigates to
/// another canvas when tapped.
///
/// A link is placed like a sticker: its [worldBounds] is a small world-space
/// rectangle — the chip — holding an icon and a short [label]. Tapping the chip
/// with the pan tool opens the [target]'s canvas (and, if the target pins one,
/// flies to its viewport). Unlike ink, a link has no centerline: its geometry
/// *is* the [worldBounds] rectangle, exactly like [ImageElement] / [PdfElement].
/// A move shifts that rect.
///
/// Links are object-only for editing: the eraser and lasso hit-test the chip
/// rectangle and a link can only ever be erased or selected *whole* — there is
/// no vector splitting (a chip is not a stroke).
///
/// All four fields ([id], [zIndex], [worldBounds], [label]) plus the flattened
/// [target] are persistent state. In step 1.7 a [LinkElement] maps onto a
/// `canvas_elements` row (`kind = link`, with `x/y/width/height` from
/// [worldBounds]) plus a 1:1 `canvas_links` detail row: `label` ← [label],
/// `link_kind` ← `canvas` or `region` (`region` when [LinkTarget.hasViewport]),
/// `target_canvas_id` ← [LinkTarget.targetCanvasId], and the
/// `target_rect_*` / viewport columns ← a serialised [LinkTarget.targetViewport].
final class LinkElement extends CanvasElement {
  /// Creates a link chip placed at [worldBounds] pointing at [target].
  const LinkElement({
    required super.id,
    required super.zIndex,
    required Rect worldBounds,
    required this.label,
    required this.target,
  }) : _worldBounds = worldBounds;

  /// Default chip size, in world units, used when placing a fresh link.
  ///
  /// A link is placed at this size (scaled to stay visually constant for the
  /// current zoom — see `CanvasController._linkPlacementRect`). Width and
  /// height are independent so the chip is a wide pill rather than a square.
  static const Size defaultChipSize = Size(220, 56);

  /// World-space placement rectangle — this chip's geometry in full.
  final Rect _worldBounds;

  /// Short human-readable text shown on the chip (e.g. the destination's
  /// title). May be empty, in which case the painter shows a generic label.
  final String label;

  /// Where tapping this link navigates. See [LinkTarget].
  final LinkTarget target;

  @override
  Rect get worldBounds => _worldBounds;

  /// Returns a copy with the given fields replaced.
  LinkElement copyWith({
    String? id,
    int? zIndex,
    Rect? worldBounds,
    String? label,
    LinkTarget? target,
  }) {
    return LinkElement(
      id: id ?? this.id,
      zIndex: zIndex ?? this.zIndex,
      worldBounds: worldBounds ?? _worldBounds,
      label: label ?? this.label,
      target: target ?? this.target,
    );
  }

  @override
  LinkElement translated(Offset delta) {
    return copyWith(worldBounds: _worldBounds.shift(delta));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LinkElement &&
        other.id == id &&
        other.zIndex == zIndex &&
        other._worldBounds == _worldBounds &&
        other.label == label &&
        other.target == target;
  }

  @override
  int get hashCode => Object.hash(id, zIndex, _worldBounds, label, target);

  @override
  String toString() =>
      'LinkElement(id: $id, zIndex: $zIndex, bounds: $_worldBounds, '
      'label: $label, target: $target)';
}

/// A positioned typed note on the canvas.
///
/// Text notes are intentionally plain v1 objects: multiline text, one colour
/// and one font size. The placement rect is persisted directly, and moving a
/// note simply shifts that rect like images, PDFs and links.
final class TextElement extends CanvasElement {
  /// Creates a text note placed at [worldBounds].
  const TextElement({
    required super.id,
    required super.zIndex,
    required Rect worldBounds,
    required this.text,
    required this.color,
    required this.fontSize,
  }) : _worldBounds = worldBounds;

  /// Default note size, in screen pixels before conversion to world units.
  static const Size defaultNoteSize = Size(320, 180);

  final Rect _worldBounds;

  /// Multiline note body.
  final String text;

  /// Packed ARGB note text colour.
  final int color;

  /// Font size in world units at scale 1.
  final double fontSize;

  @override
  Rect get worldBounds => _worldBounds;

  /// Returns a copy with the given fields replaced.
  TextElement copyWith({
    String? id,
    int? zIndex,
    Rect? worldBounds,
    String? text,
    int? color,
    double? fontSize,
  }) {
    return TextElement(
      id: id ?? this.id,
      zIndex: zIndex ?? this.zIndex,
      worldBounds: worldBounds ?? _worldBounds,
      text: text ?? this.text,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  @override
  TextElement translated(Offset delta) {
    return copyWith(worldBounds: _worldBounds.shift(delta));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextElement &&
        other.id == id &&
        other.zIndex == zIndex &&
        other._worldBounds == _worldBounds &&
        other.text == text &&
        other.color == color &&
        other.fontSize == fontSize;
  }

  @override
  int get hashCode =>
      Object.hash(id, zIndex, _worldBounds, text, color, fontSize);

  @override
  String toString() =>
      'TextElement(id: $id, zIndex: $zIndex, bounds: $_worldBounds, '
      'text: $text)';
}
