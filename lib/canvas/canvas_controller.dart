import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'package:zenno/canvas/engine/canvas_commands.dart';
import 'package:zenno/canvas/engine/canvas_transform.dart';
import 'package:zenno/canvas/engine/spatial_index.dart';
import 'package:zenno/canvas/engine/stroke_builder.dart';
import 'package:zenno/canvas/input/pen_input_processor.dart';
import 'package:zenno/canvas/input/pen_profile.dart';
import 'package:zenno/canvas/io/canvas_import.dart';
import 'package:zenno/canvas/model/canvas_bookmark.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/canvas_layer.dart';
import 'package:zenno/canvas/model/canvas_style.dart';
import 'package:zenno/canvas/model/selection_transform.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/pdf/pdf_raster_service.dart';
import 'package:zenno/canvas/persistence/canvas_repository.dart';
import 'package:zenno/canvas/tools/arrow_geometry.dart';
import 'package:zenno/canvas/tools/canvas_geometry.dart';
import 'package:zenno/core/util/id.dart';

/// The active canvas interaction tool.
///
/// The setting decides what a stylus (and a mouse) do on press-drag. Fingers
/// normally transform the viewport, but selected content can be manipulated
/// directly with touch gestures — see `CanvasView` for the routing.
enum CanvasTool {
  /// A stylus or mouse drag pans the viewport.
  pan,

  /// A stylus or mouse drag draws ink with the current pen settings.
  pen,

  /// A stylus or mouse drag erases — whole elements, or vector stroke
  /// fragments, depending on [CanvasController.eraserMode].
  eraser,

  /// A stylus or mouse drag traces a freehand selection loop.
  lasso,

  /// A stylus or mouse press-drag-release defines a geometric shape of the
  /// current [CanvasController.shapeKind].
  shape,

  /// A stylus or mouse tap places a link chip; the view then collects the
  /// chip's label and target canvas. With the [CanvasTool.pan] tool a tap on an
  /// existing chip instead *follows* the link.
  link,

  /// A stylus or mouse tap places a typed multiline note.
  text,
}

/// How the eraser tool removes ink.
enum EraserMode {
  /// Deletes every whole element the eraser path crosses.
  object,

  /// Splits crossed ink strokes, keeping the untouched sub-strokes as vector
  /// fragments. Never rasterises.
  partial,
}

/// How a lasso or item-pick gesture changes the current selection.
enum SelectionMode { replace, add, subtract }

/// Committed-element damage accumulated between two render revisions.
@immutable
class CanvasElementDamage {
  const CanvasElementDamage({
    required this.fromRevision,
    required this.toRevision,
    required this.isFull,
    this.bounds,
  });

  final int fromRevision;
  final int toRevision;
  final bool isFull;
  final Rect? bounds;
}

/// The geometric primitive produced by [CanvasTool.shape].
///
/// Each kind is generated as a normal [InkElement] whose centerline is computed
/// geometrically (see `CanvasGeometry`), so shapes erase, lasso-select, undo
/// and persist through the exact same pipeline as freehand ink.
enum ShapeKind {
  /// A straight line between the drag's two endpoints.
  line,

  /// An axis-aligned rectangle spanning the drag's bounding box.
  rectangle,

  /// An ellipse inscribed in the drag's bounding box.
  oval,

  /// A single-headed arrow from the drag's start to its end.
  arrow,
}

class _TemporaryToolSnapshot {
  const _TemporaryToolSnapshot({required this.tool, required this.shapeKind});

  final CanvasTool tool;
  final ShapeKind shapeKind;
}

class _LiveStrokeBuilder {
  _LiveStrokeBuilder({
    required this.id,
    required StrokePoint firstPoint,
    required this.color,
    required this.width,
    required this.tool,
  }) : _points = <StrokePoint>[firstPoint];

  final String id;
  final int color;
  final double width;
  final StrokeToolKind tool;
  final List<StrokePoint> _points;
  Stroke? _snapshot;

  StrokePoint get last => _points.last;

  void append(StrokePoint point) {
    _points.add(point);
    _snapshot = null;
  }

  Stroke snapshot() {
    return _snapshot ??= Stroke(
      id: id,
      points: List<StrokePoint>.unmodifiable(_points),
      color: color,
      width: width,
      tool: tool,
    );
  }
}

enum _RasterJobKind { image, pdf }

class _RasterJob {
  const _RasterJob({
    required this.elementId,
    required this.kind,
    required this.bucket,
    required this.priority,
  });

  final String elementId;
  final _RasterJobKind kind;
  final int bucket;
  final double priority;
}

/// Mutable, observable state for a single infinite canvas.
///
/// Holds the [viewport] camera, the committed [elements] (a z-ordered list of
/// [CanvasElement]s), the in-progress [liveStroke] and the current tool / pen
/// settings, plus a command-backed undo/redo history.
///
/// Every structural change to [elements] is routed through a [CanvasCommand]
/// pushed onto [_undoStack], so [undo] / [redo] are robust: each command knows
/// how to reverse itself. The controller also keeps a [SpatialIndex] in sync
/// with [elements] on every add/remove so the render layer can cull to the
/// visible viewport. The controller implements [ElementStore] — the surface
/// commands mutate — which keeps z-ordering and the index inside one place.
///
/// Every mutating method ends with [notifyListeners] so widgets rebuilt via a
/// [ListenableBuilder] stay in sync.
///
/// ## Persistence
///
/// When constructed with a [CanvasRepository] and a `canvasId`, the controller
/// is **persistence-aware**: [load] hydrates the elements and viewport from
/// SQLite, and thereafter every committed element mutation writes through to
/// the repository. Element mutations all funnel through [addElementToStore] /
/// [removeElementFromStore] — the [ElementStore] surface every command, undo
/// and redo uses — so a single write-through there covers add, remove, move,
/// replace, clear and their undo/redo for free. Each element write is its own
/// small transaction and fires immediately; viewport changes are debounced
/// (~[_viewportSaveDebounce]) because pan/zoom is continuous. Runtime raster
/// swaps go through a separate in-place path and are deliberately *not*
/// persisted. With no repository the controller is purely in-memory, exactly
/// as before — every persistence hook becomes a no-op.
class _CanvasSignal extends ChangeNotifier {
  void emit() => notifyListeners();
}

class CanvasController extends ChangeNotifier implements ElementStore {
  /// Creates a canvas controller.
  ///
  /// With both [repository] and [canvasId] supplied the controller persists to
  /// SQLite — call [load] once after construction to hydrate it. Omitting
  /// either keeps the controller fully in-memory (the Phase-1-and-earlier
  /// behaviour); the two are an all-or-nothing pair.
  CanvasController({
    CanvasRepository? repository,
    String? canvasId,
    PdfRasterService? pdfRasterService,
    CanvasImporter? importer,
  }) : assert(
         (repository == null) == (canvasId == null),
         'repository and canvasId must be supplied together, or neither.',
       ),
       _repository = repository,
       _canvasId = canvasId,
       _pdfRasterService = pdfRasterService ?? PdfRasterService() {
    _importer = importer ?? CanvasImporter(pdfRasterService: _pdfRasterService);
    _layers.add(CanvasLayer.defaultContent(_layerCanvasId));
    _activeLayerId = _layers.single.id;
  }

  /// Persistence backend, or `null` for an in-memory canvas.
  final CanvasRepository? _repository;

  /// Identifier of the canvas document being edited, or `null` in memory-only
  /// mode. Required whenever [_repository] is non-null.
  final String? _canvasId;

  /// Whether [load] has finished hydrating this controller.
  ///
  /// `true` immediately for an in-memory controller. The editor page shows a
  /// brief loading state until this flips.
  bool get isLoaded => _isLoaded;
  bool _isLoaded = false;

  /// Set while [load] is replaying persisted elements into the store, so the
  /// [ElementStore] write-through hooks do not write hydrated rows straight
  /// back to the database they just came from.
  bool _hydrating = false;

  /// Debounce window for persisting a viewport change.
  ///
  /// Pan/zoom/rotate fire many [setViewport] calls per gesture; the viewport
  /// is written at most once per this interval (and once more on [flush]) so a
  /// drag is not a write storm.
  static const Duration _viewportSaveDebounce = Duration(milliseconds: 400);
  static const Duration _toolSettingsSaveDebounce = Duration(milliseconds: 300);

  /// Pending debounced viewport-save timer, or `null` when none is scheduled.
  Timer? _viewportSaveTimer;
  Timer? _toolSettingsSaveTimer;
  bool _toolSettingsDirty = false;

  final _CanvasSignal _editorStateSignal = _CanvasSignal();
  final _CanvasSignal _viewportSignal = _CanvasSignal();
  final _CanvasSignal _elementsSignal = _CanvasSignal();
  final _CanvasSignal _liveStrokeSignal = _CanvasSignal();
  final _CanvasSignal _selectionSignal = _CanvasSignal();
  final _CanvasSignal _overlaySignal = _CanvasSignal();
  final _CanvasSignal _toolStateSignal = _CanvasSignal();
  final _CanvasSignal _canvasStyleSignal = _CanvasSignal();
  final _CanvasSignal _bookmarksSignal = _CanvasSignal();

  /// Narrow editor/load state updates.
  Listenable get editorStateListenable => _editorStateSignal;

  /// Camera changes only.
  Listenable get viewportListenable => _viewportSignal;

  /// Committed element and layer changes only.
  Listenable get elementsListenable => _elementsSignal;

  /// In-progress ink changes only.
  Listenable get liveStrokeListenable => _liveStrokeSignal;

  /// Selection membership and transform-preview changes only.
  Listenable get selectionListenable => _selectionSignal;

  /// Hover, eraser, lasso, and shape-preview changes only.
  Listenable get overlayListenable => _overlaySignal;

  /// Toolbar, tool, undo, save, import, and layer-control changes only.
  Listenable get toolStateListenable => _toolStateSignal;

  /// Paper and grid appearance changes only.
  Listenable get canvasStyleListenable => _canvasStyleSignal;

  /// Bookmark collection changes only.
  Listenable get bookmarksListenable => _bookmarksSignal;

  /// In-flight persistence futures, awaited by [flush] so the editor page can
  /// guarantee every write has hit SQLite before it disposes.
  final Set<Future<void>> _pendingWrites = <Future<void>>{};

  bool _collectingPersistenceMutations = false;
  final Map<String, CanvasElement> _batchedUpserts = <String, CanvasElement>{};
  final Set<String> _batchedDeletes = <String>{};

  final List<Future<void> Function()> _failedWrites =
      <Future<void> Function()>[];
  Object? _saveError;

  /// Latest persistence error, if a canvas write failed.
  Object? get saveError => _saveError;

  /// Whether there are failed writes the user can retry.
  bool get hasSaveError => _saveError != null;

  /// Whether any failed persistence mutation still needs to be recovered.
  /// This remains true when the user hides the banner.
  bool get hasUnsavedWrites => _failedWrites.isNotEmpty;

  /// The camera through which the world is observed.
  ViewportState viewport = ViewportState.initial;

  /// Whether two-finger gestures are allowed to rotate the viewport.
  bool rotationLocked = false;

  /// Committed elements, kept sorted ascending by [CanvasElement.zIndex]
  /// (back to front). Mutated only via [addElementToStore] /
  /// [removeElementFromStore], which keep [_spatialIndex] in sync.
  final List<CanvasElement> _elements = <CanvasElement>[];
  final Map<String, CanvasElement> _elementsById = <String, CanvasElement>{};
  final Map<String, int> _paintOrderById = <String, int>{};
  List<CanvasElement>? _elementsView;
  List<CanvasElement>? _visibleElementsView;
  List<CanvasElement>? _viewportElementsView;
  Map<String, CanvasElement>? _elementsByIdView;
  Map<String, int>? _paintOrderView;

  /// Viewport-culling index over [_elements], keyed by element id.
  final SpatialIndex _spatialIndex = SpatialIndex();

  /// Ordered canvas layers. Lower positions paint first.
  final List<CanvasLayer> _layers = <CanvasLayer>[];

  /// Layer receiving newly created content.
  String? _activeLayerId;

  int _elementsRevision = 0;
  int _selectionRevision = 0;
  int _selectionPreviewRevision = 0;
  int _viewportRevision = 0;
  int _liveStrokeRevision = 0;
  bool _liveStrokeNotifyScheduled = false;
  final List<({int revision, Rect? bounds})> _elementDamageHistory =
      <({int revision, Rect? bounds})>[];

  static const int _maxElementDamageHistory = 64;

  /// Applied commands available to be reversed by [undo], oldest at the front.
  final List<CanvasCommand> _undoStack = <CanvasCommand>[];

  /// Reverted commands available to be re-applied by [redo].
  final List<CanvasCommand> _redoStack = <CanvasCommand>[];

  /// Next z-index handed to a newly committed element.
  ///
  /// Monotonically increasing so later elements paint on top. Re-derived from
  /// the element list whenever history is reverted, so it never collides.
  int _nextZIndex = 0;

  /// The committed canvas elements in paint order (back to front), as an
  /// unmodifiable view.
  List<CanvasElement> get elements =>
      _elementsView ??= List<CanvasElement>.unmodifiable(_elements);

  /// Constant-time element lookup used by the committed-layer tile cache.
  Map<String, CanvasElement> get elementsById => _elementsByIdView ??=
      UnmodifiableMapView<String, CanvasElement>(_elementsById);

  /// Stable paint-order lookup used to sort only spatial-query hits.
  Map<String, int> get paintOrderById =>
      _paintOrderView ??= UnmodifiableMapView<String, int>(_paintOrderById);

  void _rebuildPaintOrder() {
    _paintOrderById.clear();
    for (var index = 0; index < _elements.length; index += 1) {
      _paintOrderById[_elements[index].id] = index;
    }
  }

  int get elementsRevision => _elementsRevision;

  /// Returns all committed-element damage after [revision].
  ///
  /// A full invalidation is returned when the caller is ahead of this
  /// controller or when the bounded history no longer reaches the requested
  /// revision. This defensive fallback prevents stale tile pictures.
  CanvasElementDamage elementDamageSince(int revision) {
    if (revision == _elementsRevision) {
      return CanvasElementDamage(
        fromRevision: revision,
        toRevision: _elementsRevision,
        isFull: false,
        bounds: Rect.zero,
      );
    }
    if (revision < 0 ||
        revision > _elementsRevision ||
        _elementDamageHistory.isEmpty ||
        _elementDamageHistory.first.revision > revision + 1) {
      return CanvasElementDamage(
        fromRevision: revision,
        toRevision: _elementsRevision,
        isFull: true,
      );
    }

    Rect? damageBounds;
    var expectedRevision = revision + 1;
    for (final damage in _elementDamageHistory) {
      if (damage.revision < expectedRevision) {
        continue;
      }
      if (damage.revision != expectedRevision || damage.bounds == null) {
        return CanvasElementDamage(
          fromRevision: revision,
          toRevision: _elementsRevision,
          isFull: true,
        );
      }
      damageBounds = damageBounds == null
          ? damage.bounds
          : damageBounds.expandToInclude(damage.bounds!);
      expectedRevision += 1;
    }
    if (expectedRevision != _elementsRevision + 1) {
      return CanvasElementDamage(
        fromRevision: revision,
        toRevision: _elementsRevision,
        isFull: true,
      );
    }
    return CanvasElementDamage(
      fromRevision: revision,
      toRevision: _elementsRevision,
      isFull: false,
      bounds: damageBounds ?? Rect.zero,
    );
  }

  int get selectionRevision => _selectionRevision;

  int get selectionPreviewRevision => _selectionPreviewRevision;

  int get viewportRevision => _viewportRevision;

  int get liveStrokeRevision => _liveStrokeRevision;

  /// The spatial index over the committed elements, for viewport culling.
  ///
  /// Exposed read-only for the render layer; callers must not mutate it
  /// directly — the controller keeps it consistent with [elements].
  SpatialIndex get spatialIndex => _spatialIndex;

  /// Ordered layers, from back to front.
  List<CanvasLayer> get layers => List<CanvasLayer>.unmodifiable(_layers);

  /// Id of the layer receiving new elements.
  String get activeLayerId => _activeLayerId ?? _defaultLayerId;

  CanvasLayer get activeLayer =>
      _layerById(activeLayerId) ?? CanvasLayer.defaultContent(_layerCanvasId);

  /// Whether a visible, unlocked content layer can receive new elements.
  bool get canCreateContent => _firstEditableLayerId() != null;

  /// Elements whose layers are currently visible.
  List<CanvasElement> get visibleElements {
    return _visibleElementsView ??=
        List<CanvasElement>.unmodifiable(<CanvasElement>[
          for (final CanvasElement element in _elements)
            if (_isElementVisible(element)) element,
        ]);
  }

  /// Layer-visible elements intersecting the viewport, in paint order.
  List<CanvasElement> get viewportElements {
    final List<CanvasElement>? cached = _viewportElementsView;
    if (cached != null) {
      return cached;
    }
    final List<CanvasElement> visible = <CanvasElement>[
      for (final String id in _spatialIndex.query(_visibleWorldRect))
        if (_elementsById[id] case final CanvasElement element)
          if (_isElementVisible(element)) element,
    ];
    if (_selectionDragDelta != null || _selectionTransformOriginals != null) {
      for (final String id in _selectedIds) {
        final CanvasElement? element = _elementsById[id];
        if (element != null &&
            _isElementVisible(element) &&
            !visible.contains(element)) {
          visible.add(element);
        }
      }
    }
    visible.sort(_compareElements);
    return _viewportElementsView = List<CanvasElement>.unmodifiable(visible);
  }

  /// The stroke currently being drawn, or `null` when nothing is in progress.
  ///
  /// The live stroke is not yet a [CanvasElement]; it becomes an [InkElement]
  /// only when [endStroke] commits it.
  Stroke? get liveStroke => _liveStrokeBuilder?.snapshot();
  _LiveStrokeBuilder? _liveStrokeBuilder;

  /// The active interaction tool. Drawing always starts as [CanvasTool.pen].
  CanvasTool activeTool = CanvasTool.pen;

  CanvasTool _previousTool = CanvasTool.pen;
  final List<_TemporaryToolSnapshot> _temporaryTools =
      <_TemporaryToolSnapshot>[];

  /// Packed ARGB colour applied to new strokes. Defaults to opaque white.
  int penColor = 0xFFFFFFFF;

  /// On-screen width (logical px at `scale == 1`) applied to new strokes.
  double penWidth = 4.0;

  /// Whether [penWidth] is interpreted as screen-space or canvas-space width.
  PenWidthMode penWidthMode = PenWidthMode.screen;

  /// Whether new marks keep the same apparent width while the canvas zooms.
  bool get adaptivePenEnabled => penWidthMode == PenWidthMode.screen;

  /// The ink tool kind applied to new strokes.
  StrokeToolKind penKind = StrokeToolKind.pen;

  final List<ToolWheelPreset> _toolWheelPresets = List<ToolWheelPreset>.of(
    defaultToolWheelPresets,
  );

  /// Stable eight-slot preset rack shown by the canvas tool wheel.
  List<ToolWheelPreset> get toolWheelPresets =>
      List<ToolWheelPreset>.unmodifiable(_toolWheelPresets);

  int activeToolWheelIndex = 0;

  ToolWheelPreset get activeToolWheelPreset =>
      _toolWheelPresets[activeToolWheelIndex
          .clamp(0, _toolWheelPresets.length - 1)
          .toInt()];

  /// User-controlled opacity of the active ink preset.
  double get penOpacity => ((penColor >>> 24) & 0xFF) / 255;

  /// Whether stylus pressure affects new ink width.
  bool pressureEnabled = true;

  /// Capture-side pressure and smoothing profile for new pen strokes.
  PenProfile penProfile = const PenProfile();

  /// Per-canvas paper/background styling.
  CanvasPaperStyle paperStyle = const CanvasPaperStyle();

  /// Whether new precision objects snap to the active paper grid.
  bool snapToGridEnabled = false;

  /// Whether the eraser deletes whole elements or splits strokes into vector
  /// fragments. See [EraserMode].
  EraserMode eraserMode = EraserMode.object;

  /// On-screen radius (logical px at `scale == 1`) of the eraser footprint.
  double eraserRadius = 14.0;

  /// Selection edit mode used by lasso and tap item picking.
  SelectionMode selectionMode = SelectionMode.replace;

  /// The shape primitive [CanvasTool.shape] currently produces.
  ShapeKind shapeKind = ShapeKind.line;

  /// Arrow body style for newly-created arrow shapes.
  ArrowBodyKind arrowBody = ArrowBodyKind.straight;

  /// Start arrowhead style for newly-created arrow shapes.
  ArrowHeadStyle arrowStartHead = ArrowHeadStyle.none;

  /// End arrowhead style for newly-created arrow shapes.
  ArrowHeadStyle arrowEndHead = ArrowHeadStyle.open;

  /// Scale multiplier for newly-created arrowheads.
  double arrowHeadScale = 1.0;

  /// World-space position of the stylus hover indicator, or `null`.
  Offset? hoverPointWorld;

  /// Renders imported PDF pages to `ui.Image`s on a background path.
  ///
  /// Created lazily on the first import and disposed with the controller; the
  /// importer and the PDF raster scheduler both borrow it.
  final PdfRasterService _pdfRasterService;

  /// Picks media files (image / PDF) and stages them for the canvas.
  late final CanvasImporter _importer;

  /// Size of the canvas viewport in logical pixels, kept in sync by the view.
  ///
  /// Used to place a freshly imported element centred in what the user is
  /// currently looking at, and to size PDF page rasters to the on-screen zoom.
  /// [Size.zero] until the view first reports its size.
  Size _viewportSize = Size.zero;

  /// Monotonic token bumped whenever the element list is structurally cleared
  /// or reset, so a raster load that finishes late can tell its element is
  /// gone and drop its result instead of resurrecting it.
  int _rasterEpoch = 0;

  /// Whether [dispose] has run. Async raster loads check this before touching
  /// the (now dead) store or calling [notifyListeners].
  bool _disposed = false;

  /// Running estimate of decoded raster bytes held by [_elements].
  ///
  /// Bookkeeping for [_rasterBudgetBytes]: when this exceeds the budget the
  /// controller evicts rasters from off-screen image/PDF elements.
  int _rasterBytesInUse = 0;

  @visibleForTesting
  int get debugRasterBytesInUse => _rasterBytesInUse;

  /// Soft ceiling on total decoded raster memory across all elements.
  ///
  /// ~96 MB of `ui.Image` pixels. Past this, off-screen image/PDF rasters are
  /// dropped (and their `ui.Image`s disposed) oldest-first; they re-rasterise
  /// from the source file when scrolled back into view. Keeps the canvas
  /// inside a sane memory envelope on a mid-range tablet.
  static const int _rasterBudgetBytes = 96 * 1024 * 1024;

  final List<_RasterJob> _rasterJobQueue = <_RasterJob>[];
  int _activeImageRasterJobs = 0;
  int _activePdfRasterJobs = 0;

  /// Bound expensive raster work so a PDF-heavy viewport cannot start every
  /// page render at once.
  static const int _maxConcurrentImageRasterJobs = 2;
  static const int _maxConcurrentPdfRasterJobs = 1;

  /// Default longest-edge world size for a freshly imported element.
  ///
  /// The imported picture / PDF page is placed at this size (preserving aspect
  /// ratio) unless the viewport is small, in which case it is scaled to fit.
  static const double _importDefaultWorldSize = 720.0;

  /// Minimum screen-space movement before a pointer press becomes a drag.
  static const double tapSlop = 8.0;

  /// Default font size for newly-created typed notes.
  static const double defaultTextFontSize = 22.0;

  /// World-space points sampled along the in-progress eraser drag, or `null`
  /// when the eraser is not active. Drawn by the overlay as the eraser cursor
  /// trail; consumed on pointer-up to erase.
  List<Offset>? _eraserPath;

  /// World-space vertices of the in-progress lasso loop, or `null` when no
  /// lasso is being drawn. The overlay strokes this while dragging.
  List<Offset>? _lassoPath;

  /// Ids of the currently selected elements (built by lasso select).
  ///
  /// A [Set] for O(1) membership checks from the painters; the controller
  /// keeps it consistent with [_elements] — undo/erase prune missing ids.
  final Set<String> _selectedIds = <String>{};
  Set<String>? _selectedIdsView;

  /// In-memory snapshots copied from the current selection.
  List<CanvasElement> _clipboardElements = const <CanvasElement>[];
  int _clipboardPasteCount = 0;

  /// Selection present at replace-lasso start, restored if it is cancelled.
  Set<String>? _selectionBeforeReplaceLasso;

  /// World-space anchor of an in-progress shape drag, or `null`.
  Offset? _shapeStart;

  /// World-space current point of an in-progress shape drag, or `null`.
  Offset? _shapeEnd;

  /// World-space accumulated offset of an in-progress selection drag, or
  /// `null` when the selection is not being dragged. Live drag feedback only —
  /// the store is mutated once, on pointer-up, via [MoveElementsCommand].
  Offset? _selectionDragDelta;

  /// Original selected elements captured at the start of a live pinch/rotate
  /// selection transform.
  List<CanvasElement>? _selectionTransformOriginals;

  /// Matrix-style live selection transform preview.
  ///
  /// Like [_selectionDragDelta], this is preview-only; committed geometry is
  /// written once on pointer-up as a single [TransformElementsCommand].
  SelectionTransformPreview _selectionTransformPreview =
      const SelectionTransformPreview.identity();
  double _selectionTransformScale = 1;
  double _selectionTransformRotation = 0;
  Offset _selectionTransformTranslation = Offset.zero;

  /// Named viewport locations saved on this canvas, newest last.
  ///
  /// Hydrated from and written through to the canvas bookmarks table.
  /// Exposed read-only via [bookmarks].
  final List<Bookmark> _bookmarks = <Bookmark>[];

  /// Whether [undo] currently has an applied command to reverse.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether [redo] currently has a reverted command to re-apply.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Number of committed elements on the canvas.
  int get elementCount => _elements.length;

  /// World-space points of the in-progress eraser drag, or `null`. Read-only
  /// view for the overlay painter.
  List<Offset>? get eraserPath =>
      _eraserPath == null ? null : List<Offset>.unmodifiable(_eraserPath!);

  /// World-space vertices of the in-progress lasso loop, or `null`. Read-only
  /// view for the overlay painter.
  List<Offset>? get lassoPath =>
      _lassoPath == null ? null : List<Offset>.unmodifiable(_lassoPath!);

  /// Ids of the currently selected elements, as an unmodifiable view.
  Set<String> get selectedIds =>
      _selectedIdsView ??= Set<String>.unmodifiable(_selectedIds);

  /// Whether at least one element is currently selected.
  bool get hasSelection => _selectedIds.isNotEmpty;

  /// Whether copied canvas content is ready to paste.
  bool get hasClipboardContent => _clipboardElements.isNotEmpty;

  /// Live world-space offset of an in-progress selection drag, or [Offset.zero]
  /// when the selection is not being dragged.
  Offset get selectionDragDelta => _selectionDragDelta ?? Offset.zero;

  /// Whether a selection is currently being dragged.
  bool get isDraggingSelection => _selectionDragDelta != null;

  /// Whether a selection is currently being scaled or rotated.
  bool get isTransformingSelection => _selectionTransformOriginals != null;

  /// Live transform applied by the painter while scaling/rotating a selection.
  SelectionTransformPreview? get selectionTransformPreview =>
      _selectionTransformOriginals == null ? null : _selectionTransformPreview;

  /// The committed elements that are currently selected, in paint order.
  List<CanvasElement> get selectedElements => <CanvasElement>[
    for (final CanvasElement e in _elements)
      if (_selectedIds.contains(e.id) && _isElementEditable(e)) e,
  ];

  /// World-space bounding box enclosing every selected element, or `null` when
  /// nothing is selected. Reflects in-progress selection move/scale/rotate
  /// previews.
  Rect? get selectionBounds {
    if (_selectionTransformOriginals != null) {
      return _transformedSelectionBounds();
    }
    final Rect? bounds = _boundsForSelectedElements(_elements);
    if (bounds == null) {
      return null;
    }
    return bounds.shift(selectionDragDelta);
  }

  Rect? _boundsForSelectedElements(Iterable<CanvasElement> elements) {
    Rect? bounds;
    for (final CanvasElement element in elements) {
      if (!_selectedIds.contains(element.id)) {
        continue;
      }
      if (!_isElementVisible(element)) {
        continue;
      }
      bounds = bounds == null
          ? element.worldBounds
          : bounds.expandToInclude(element.worldBounds);
    }
    return bounds;
  }

  Rect? _transformedSelectionBounds() {
    final List<CanvasElement>? originals = _selectionTransformOriginals;
    if (originals == null) {
      return null;
    }
    Rect? bounds;
    for (final CanvasElement element in originals) {
      if (!_selectedIds.contains(element.id) || !_isElementVisible(element)) {
        continue;
      }
      final Rect transformed = _selectionTransformPreview.transformRect(
        element.worldBounds,
      );
      bounds = bounds == null
          ? transformed
          : bounds.expandToInclude(transformed);
    }
    return bounds;
  }

  String get _layerCanvasId => _canvasId ?? 'memory';

  String get _defaultLayerId =>
      CanvasLayer.defaultContentLayerId(_layerCanvasId);

  CanvasLayer? _layerById(String id) {
    for (final CanvasLayer layer in _layers) {
      if (layer.id == id) {
        return layer;
      }
    }
    return null;
  }

  String _effectiveLayerId(CanvasElement element) =>
      element.layerId ?? _defaultLayerId;

  bool _isLayerVisible(String layerId) => _layerById(layerId)?.visible ?? true;

  bool _isLayerLocked(String layerId) => _layerById(layerId)?.locked ?? false;

  bool _isElementVisible(CanvasElement element) {
    return _isLayerVisible(_effectiveLayerId(element));
  }

  bool _isElementEditable(CanvasElement element) {
    final String layerId = _effectiveLayerId(element);
    return _isLayerVisible(layerId) && !_isLayerLocked(layerId);
  }

  Rect _damageBoundsForElements(bool Function(CanvasElement element) matches) {
    Rect? bounds;
    for (final CanvasElement element in _elements) {
      if (!matches(element)) {
        continue;
      }
      bounds = bounds == null
          ? element.worldBounds
          : bounds.expandToInclude(element.worldBounds);
    }
    return bounds ?? Rect.zero;
  }

  CanvasElement _normalizeElementLayer(CanvasElement element) {
    final String layerId =
        element.layerId ?? _editableActiveLayerId() ?? _defaultLayerId;
    if (element.layerId == layerId) {
      return element;
    }
    return _copyElementWithLayer(element, layerId);
  }

  void _markElementsChanged({Rect? damageBounds}) {
    _elementsRevision += 1;
    _elementDamageHistory.add((
      revision: _elementsRevision,
      bounds: damageBounds,
    ));
    if (_elementDamageHistory.length > _maxElementDamageHistory) {
      _elementDamageHistory.removeAt(0);
    }
    _elementsView = null;
    _visibleElementsView = null;
    _viewportElementsView = null;
  }

  void _markSelectionChanged() {
    _selectionRevision += 1;
    _selectedIdsView = null;
    _viewportElementsView = null;
  }

  void _markSelectionPreviewChanged() {
    _selectionPreviewRevision += 1;
    _viewportElementsView = null;
  }

  void _markViewportChanged() {
    _viewportRevision += 1;
    _viewportElementsView = null;
  }

  void _notifyEditorState() {
    _editorStateSignal.emit();
    notifyListeners();
  }

  void _notifyViewport() {
    _viewportSignal.emit();
    _toolStateSignal.emit();
    notifyListeners();
  }

  void _notifyElements({
    bool selectionMayChange = true,
    bool toolMayChange = true,
  }) {
    _elementsSignal.emit();
    if (selectionMayChange) {
      _selectionSignal.emit();
      _overlaySignal.emit();
    }
    if (toolMayChange) {
      _toolStateSignal.emit();
    }
    notifyListeners();
  }

  void _notifyLiveStroke() {
    _liveStrokeSignal.emit();
    notifyListeners();
  }

  void _notifySelection() {
    _viewportElementsView = null;
    _selectionSignal.emit();
    _overlaySignal.emit();
    _toolStateSignal.emit();
    notifyListeners();
  }

  void _notifyOverlay() {
    _overlaySignal.emit();
    notifyListeners();
  }

  void _notifyToolState() {
    _toolStateSignal.emit();
    notifyListeners();
  }

  void _notifyCanvasStyle() {
    _canvasStyleSignal.emit();
    _toolStateSignal.emit();
    notifyListeners();
  }

  void _notifyBookmarks() {
    _bookmarksSignal.emit();
    notifyListeners();
  }

  void _notifyAllChannels() {
    _editorStateSignal.emit();
    _viewportSignal.emit();
    _elementsSignal.emit();
    _liveStrokeSignal.emit();
    _selectionSignal.emit();
    _overlaySignal.emit();
    _toolStateSignal.emit();
    _canvasStyleSignal.emit();
    _bookmarksSignal.emit();
    notifyListeners();
  }

  bool _clearSelectedIds() {
    if (_selectedIds.isEmpty) {
      return false;
    }
    _selectedIds.clear();
    _markSelectionChanged();
    return true;
  }

  bool _removeSelectedIdsWhere(bool Function(String id) test) {
    final int before = _selectedIds.length;
    _selectedIds.removeWhere(test);
    if (_selectedIds.length == before) {
      return false;
    }
    _markSelectionChanged();
    _cancelSelectionManipulation();
    return true;
  }

  bool _cancelSelectionManipulation() {
    var changed = false;
    if (_selectionDragDelta != null) {
      _selectionDragDelta = null;
      changed = true;
    }
    if (_selectionTransformOriginals != null) {
      _clearSelectionTransformPreview();
      changed = true;
    }
    return changed;
  }

  void _notifyLiveStrokeSoon() {
    if (_liveStrokeNotifyScheduled) {
      return;
    }
    _liveStrokeNotifyScheduled = true;
    try {
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        _liveStrokeNotifyScheduled = false;
        if (!_disposed) {
          _notifyLiveStroke();
        }
      });
      SchedulerBinding.instance.ensureVisualUpdate();
    } on Object {
      _liveStrokeNotifyScheduled = false;
      _notifyLiveStroke();
    }
  }

  String? _editableActiveLayerId() {
    final CanvasLayer? active = _layerById(activeLayerId);
    if (active != null && active.isEditable) {
      return active.id;
    }
    final String? firstEditable = _firstEditableLayerId();
    if (firstEditable != null) {
      _activeLayerId = firstEditable;
      return firstEditable;
    }
    return null;
  }

  String? _firstEditableLayerId() {
    for (final CanvasLayer layer in _layers) {
      if (layer.isEditable) {
        return layer.id;
      }
    }
    return null;
  }

  int _compareElements(CanvasElement a, CanvasElement b) {
    final double layerA = _layerById(_effectiveLayerId(a))?.position ?? 0;
    final double layerB = _layerById(_effectiveLayerId(b))?.position ?? 0;
    final int layerOrder = layerA.compareTo(layerB);
    if (layerOrder != 0) {
      return layerOrder;
    }
    return a.zIndex.compareTo(b.zIndex);
  }

  CanvasElement _copyElementWithLayer(CanvasElement element, String? layerId) {
    return switch (element) {
      InkElement() => element.copyWith(layerId: layerId),
      ImageElement() => element.copyWith(layerId: layerId),
      PdfElement() => element.copyWith(layerId: layerId),
      LinkElement() => element.copyWith(layerId: layerId),
      TextElement() => element.copyWith(layerId: layerId),
      ShapeElement() => element.copyWith(layerId: layerId),
    };
  }

  // ---------------------------------------------------------------------------
  // ElementStore — the mutation surface used by CanvasCommands.
  // ---------------------------------------------------------------------------

  @override
  List<CanvasElement> get currentElements => elements;

  @override
  void addElementToStore(CanvasElement element) {
    final CanvasElement stored = _normalizeElementLayer(element);
    // Idempotent: a command replay must not duplicate an element.
    if (_elementsById.containsKey(stored.id)) {
      return;
    }
    // Insert keeping the list sorted ascending by zIndex.
    var insertAt = _elements.length;
    for (var i = 0; i < _elements.length; i++) {
      if (_compareElements(_elements[i], stored) > 0) {
        insertAt = i;
        break;
      }
    }
    _elements.insert(insertAt, stored);
    _elementsById[stored.id] = stored;
    _rebuildPaintOrder();
    _spatialIndex.insert(stored.id, stored.worldBounds);
    final ui.Image? raster = _elementRaster(stored);
    if (raster != null) {
      _trackRaster(raster);
    }
    _markElementsChanged(damageBounds: stored.worldBounds);

    // Keep the z-index allocator ahead of every committed element.
    if (stored.zIndex >= _nextZIndex) {
      _nextZIndex = stored.zIndex + 1;
    }

    // Write-through: an add (including a redo, or the re-add half of a move)
    // upserts the element. Skipped while [load] is hydrating the store.
    _persistUpsert(stored);
  }

  @override
  void removeElementFromStore(String id) {
    final int? index = paintOrderById[id];
    if (index == null) {
      return;
    }
    final CanvasElement removed = _elements.removeAt(index);
    _elementsById.remove(id);
    _rebuildPaintOrder();
    _disposeElementRaster(removed);
    _spatialIndex.remove(id);
    _markElementsChanged(damageBounds: removed.worldBounds);
    // Keep the selection consistent: a removed element can no longer be
    // selected. (A MoveElementsCommand removes-then-re-adds with the same id,
    // so it re-selects itself below via _reconcileSelection.)
    if (_selectedIds.remove(id)) {
      _markSelectionChanged();
    }

    // Write-through: a remove (including an undo, or the remove half of a
    // move) deletes the element row. A move's immediately-following re-add
    // re-inserts it; the net effect is a position update. Skipped during load.
    _persistDelete(id);
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  void _replaceElementsForHydration(List<CanvasElement> loaded) {
    for (final CanvasElement element in _elements) {
      _disposeElementRaster(element);
    }
    _elements
      ..clear()
      ..addAll(loaded.map(_normalizeElementLayer))
      ..sort(_compareElements);
    _elementsById
      ..clear()
      ..addEntries(
        _elements.map(
          (CanvasElement element) =>
              MapEntry<String, CanvasElement>(element.id, element),
        ),
      );
    _rebuildPaintOrder();
    _spatialIndex.rebuild(
      _elements.map(
        (CanvasElement element) =>
            MapEntry<String, Rect>(element.id, element.worldBounds),
      ),
    );
    for (final CanvasElement element in _elements) {
      final ui.Image? raster = _elementRaster(element);
      if (raster != null) {
        _trackRaster(raster);
      }
    }
    _selectedIds.clear();
    _undoStack.clear();
    _redoStack.clear();
    _nextZIndex = _elements.fold<int>(
      0,
      (int next, CanvasElement element) => math.max(next, element.zIndex + 1),
    );
    _markElementsChanged();
    _markSelectionChanged();
  }

  /// Hydrates this controller from its [CanvasRepository].
  ///
  /// Loads the persisted elements (in z-order) and the last saved viewport,
  /// replaying the elements into the store with the write-through hooks
  /// suppressed so nothing is written straight back. The undo/redo history
  /// starts empty — a freshly opened canvas has nothing to undo. Sets
  /// [isLoaded] and notifies listeners when done.
  ///
  /// A no-op (but still flips [isLoaded]) for an in-memory controller. Safe to
  /// call exactly once, from the editor page's init path.
  Future<void> load() async {
    final CanvasRepository? repo = _repository;
    final String? canvasId = _canvasId;
    if (repo == null || canvasId == null) {
      _isLoaded = true;
      return;
    }
    // Every supported entry point creates the canvas before opening it. Do not
    // recreate a deleted canvas from a stale link or route: that would turn a
    // broken reference into a new, misleading blank note.
    if (!await repo.canvasExists(canvasId)) {
      throw CanvasNotFoundException(canvasId);
    }

    final List<CanvasLayer> loadedLayers = await repo.loadLayers(canvasId);
    final List<CanvasElement> loaded = await repo.loadElements(canvasId);
    final List<Bookmark> loadedBookmarks = await repo.loadBookmarks(canvasId);
    final ViewportState? savedViewport = await repo.loadViewport(canvasId);
    final bool savedRotationLocked = await repo.loadRotationLocked(canvasId);
    final CanvasPaperStyle savedPaper = await repo.loadPaperStyle(canvasId);
    final CanvasToolSettings savedTool = await repo.loadToolSettings(canvasId);
    if (_disposed) {
      return;
    }

    _hydrating = true;
    try {
      _layers
        ..clear()
        ..addAll(loadedLayers);
      _activeLayerId = _firstEditableLayerId() ?? _defaultLayerId;
      _bookmarks
        ..clear()
        ..addAll(loadedBookmarks);
      _replaceElementsForHydration(loaded);
    } finally {
      _hydrating = false;
    }
    if (savedViewport != null) {
      viewport = savedViewport;
      _markViewportChanged();
    }
    rotationLocked = savedRotationLocked;
    paperStyle = savedPaper;
    penColor = savedTool.penColor;
    penWidth = savedTool.penWidth;
    penWidthMode = savedTool.penWidthMode;
    penKind = savedTool.penKind;
    pressureEnabled = savedTool.pressureEnabled;
    _toolWheelPresets
      ..clear()
      ..addAll(savedTool.toolWheelPresets);
    activeToolWheelIndex = savedTool.activeToolWheelIndex
        .clamp(0, _toolWheelPresets.length - 1)
        .toInt();
    _applyToolWheelPresetValues(activeToolWheelPreset);
    activeTool = _canvasToolForPreset(activeToolWheelPreset.kind);
    _isLoaded = true;
    _notifyAllChannels();
  }

  /// Flushes any pending debounced writes and awaits every in-flight write.
  ///
  /// The editor page calls this on dispose so a canvas closed mid-gesture —
  /// after a pan but before the viewport-save debounce elapsed — still has its
  /// final state on disk. A no-op for an in-memory controller.
  Future<void> flush() async {
    final Timer? timer = _viewportSaveTimer;
    if (timer != null && timer.isActive) {
      timer.cancel();
      _viewportSaveTimer = null;
      _saveViewportNow();
    }
    commitToolSettings();
    // Drain in waves: awaiting a write may itself enqueue another (a viewport
    // save scheduled just before flush, an upsert mid-transaction).
    while (_pendingWrites.isNotEmpty) {
      await Future.wait(_pendingWrites.toList());
    }
  }

  /// Persists [element] via the repository, if persistence is enabled.
  ///
  /// A no-op while [load] is hydrating (the element came *from* the database)
  /// or for an in-memory controller. The write runs asynchronously; [flush]
  /// awaits it.
  void _persistUpsert(CanvasElement element) {
    final CanvasRepository? repo = _repository;
    final String? canvasId = _canvasId;
    if (_hydrating || repo == null || canvasId == null) {
      return;
    }
    if (_collectingPersistenceMutations) {
      _batchedDeletes.remove(element.id);
      _batchedUpserts[element.id] = element;
      return;
    }
    _track(() => repo.upsertElement(canvasId, element));
  }

  /// Deletes the element [id] via the repository, if persistence is enabled.
  ///
  /// A no-op while hydrating or for an in-memory controller. Command-backed
  /// mutations are coalesced so a move/transform becomes one final upsert
  /// instead of a delete followed by an insert for every selected element.
  void _persistDelete(String id) {
    final CanvasRepository? repo = _repository;
    if (_hydrating || repo == null) {
      return;
    }
    if (_collectingPersistenceMutations) {
      _batchedUpserts.remove(id);
      _batchedDeletes.add(id);
      return;
    }
    _track(() => repo.deleteElement(id));
  }

  void _beginPersistenceBatch() {
    if (_repository == null || _canvasId == null || _hydrating) {
      return;
    }
    _collectingPersistenceMutations = true;
    _batchedUpserts.clear();
    _batchedDeletes.clear();
  }

  void _endPersistenceBatch() {
    if (!_collectingPersistenceMutations) {
      return;
    }
    _collectingPersistenceMutations = false;
    final CanvasRepository? repo = _repository;
    final String? canvasId = _canvasId;
    if (repo == null || canvasId == null || _hydrating) {
      _batchedUpserts.clear();
      _batchedDeletes.clear();
      return;
    }
    final List<CanvasElement> upserts = _batchedUpserts.values.toList(
      growable: false,
    );
    final List<String> deletes = _batchedDeletes.toList(growable: false);
    _batchedUpserts.clear();
    _batchedDeletes.clear();
    if (deletes.isNotEmpty || upserts.isNotEmpty) {
      _track(
        () => repo.applyElementBatch(
          canvasId,
          deletes: deletes,
          upserts: upserts,
        ),
      );
    }
  }

  void _persistLayer(CanvasLayer layer) {
    final CanvasRepository? repo = _repository;
    if (_hydrating || repo == null) {
      return;
    }
    _track(() => repo.upsertLayer(layer));
  }

  void _persistLayers(List<CanvasLayer> layers) {
    final CanvasRepository? repo = _repository;
    if (_hydrating || repo == null) {
      return;
    }
    _track(() => repo.upsertLayers(layers));
  }

  /// Schedules a debounced save of the current [viewport].
  ///
  /// Pan/zoom emits a stream of viewport changes; this collapses them to one
  /// write per [_viewportSaveDebounce]. A no-op for an in-memory controller.
  void _scheduleViewportSave() {
    if (_repository == null || _canvasId == null) {
      return;
    }
    _viewportSaveTimer?.cancel();
    _viewportSaveTimer = Timer(_viewportSaveDebounce, _saveViewportNow);
  }

  /// Writes the current [viewport] to the repository immediately.
  void _saveViewportNow() {
    final CanvasRepository? repo = _repository;
    final String? canvasId = _canvasId;
    if (repo == null || canvasId == null) {
      return;
    }
    _viewportSaveTimer = null;
    _track(() => repo.saveViewport(canvasId, viewport));
  }

  /// Retries failed persistence writes.
  Future<void> retryFailedWrites() async {
    if (_failedWrites.isEmpty) return;
    _failedWrites.clear();
    _saveError = null;
    _notifyToolState();
    _track(_syncCurrentCanvasState);
    await flush();
  }

  Future<void> _syncCurrentCanvasState() async {
    final CanvasRepository? repo = _repository;
    final String? canvasId = _canvasId;
    if (repo == null || canvasId == null) return;
    await repo.syncCanvasState(
      canvasId,
      elements: List<CanvasElement>.of(_elements),
      layers: List<CanvasLayer>.of(_layers),
      bookmarks: List<Bookmark>.of(_bookmarks),
      viewport: viewport,
      rotationLocked: rotationLocked,
      paperStyle: paperStyle,
      toolSettings: CanvasToolSettings(
        penColor: penColor,
        penWidth: penWidth,
        penWidthMode: penWidthMode,
        penKind: penKind,
        pressureEnabled: pressureEnabled,
        toolWheelPresets: toolWheelPresets,
        activeToolWheelIndex: activeToolWheelIndex,
      ),
    );
  }

  /// Dismisses the visible save error without dropping retry information.
  void dismissSaveError() {
    _saveError = null;
    _notifyToolState();
  }

  /// Registers [write] in [_pendingWrites] until it completes.
  ///
  /// [flush] awaits this set, so a write in flight when the page disposes is
  /// still finished. A failed write is surfaced and retained for retry.
  void _track(Future<void> Function() write) {
    late final Future<void> tracked;
    tracked = write()
        .catchError((Object error) {
          _saveError = error;
          _failedWrites.add(write);
          if (!_disposed) {
            _notifyToolState();
          }
        })
        .whenComplete(() {
          _pendingWrites.remove(tracked);
        });
    _pendingWrites.add(tracked);
  }

  // ---------------------------------------------------------------------------
  // Command history
  // ---------------------------------------------------------------------------

  /// Applies [command], pushes it on the undo stack and forks the redo stack.
  ///
  /// The single entry point for every structural change to [elements]: it runs
  /// [CanvasCommand.apply], records the command for [undo], and clears the
  /// redo stack because a fresh edit forks history. Ends with [notifyListeners].
  void _runCommand(CanvasCommand command) {
    _applyCommandMutation(command.apply);
    _undoStack.add(command);
    _redoStack.clear();
    _reconcileSelectionFor(command);
    _scheduleVisibleRasters();
    _notifyElements();
  }

  /// Reverses the most recently applied command, moving it onto the redo stack.
  ///
  /// A no-op when [canUndo] is false.
  void undo() {
    if (_undoStack.isEmpty) {
      return;
    }
    final CanvasCommand command = _undoStack.removeLast();
    _applyCommandMutation(command.revert);
    _redoStack.add(command);
    _recomputeNextZIndex();
    _reconcileSelectionFor(command);
    _scheduleVisibleRasters();
    _notifyElements();
  }

  /// Re-applies the most recently undone command, moving it back onto the undo
  /// stack.
  ///
  /// A no-op when [canRedo] is false.
  void redo() {
    if (_redoStack.isEmpty) {
      return;
    }
    final CanvasCommand command = _redoStack.removeLast();
    _applyCommandMutation(command.apply);
    _undoStack.add(command);
    _reconcileSelectionFor(command);
    _scheduleVisibleRasters();
    _notifyElements();
  }

  void _applyCommandMutation(void Function(ElementStore store) mutate) {
    _beginPersistenceBatch();
    try {
      mutate(this);
    } finally {
      _endPersistenceBatch();
    }
  }

  /// Repairs the selection after [command] ran (forward or reverse).
  ///
  /// [removeElementFromStore] drops removed ids from [_selectedIds] as it goes,
  /// so after a `MoveElementsCommand` — which removes then re-adds elements
  /// under the same ids — the moved elements would be left unselected. Here the
  /// moved ids are re-selected (only those still present in [_elements]) so a
  /// selection survives undo/redo of its own move and stays draggable.
  void _reconcileSelectionFor(CanvasCommand command) {
    final Iterable<CanvasElement> selectedAfterCommand = switch (command) {
      MoveElementsCommand(:final moved) => moved,
      TransformElementsCommand(:final transformed) => transformed,
      _ => const <CanvasElement>[],
    };
    if (selectedAfterCommand.isEmpty) {
      return;
    }
    var changed = false;
    for (final CanvasElement element in selectedAfterCommand) {
      if (_elements.any((CanvasElement e) => e.id == element.id)) {
        changed = _selectedIds.add(element.id) || changed;
      }
    }
    if (changed) {
      _markSelectionChanged();
    }
  }

  /// Re-derives [_nextZIndex] from the current elements.
  ///
  /// Called after an [undo] removes elements: the allocator must stay strictly
  /// above every remaining element's z-index so the next committed element
  /// still paints on top.
  void _recomputeNextZIndex() {
    var maxZ = -1;
    for (final CanvasElement element in _elements) {
      if (element.zIndex > maxZ) {
        maxZ = element.zIndex;
      }
    }
    _nextZIndex = maxZ + 1;
  }

  // ---------------------------------------------------------------------------
  // Stroke lifecycle
  // ---------------------------------------------------------------------------

  /// Starts a new stroke at the [world] point with the given [pressure].
  ///
  /// Replaces any existing [liveStroke]; pen settings are snapshotted onto the
  /// new stroke so later tool changes do not retroactively affect it.
  void beginStroke(
    Offset world,
    double pressure, {
    double tiltX = 0,
    double tiltY = 0,
    double azimuth = 0,
    int timestampMicros = 0,
    double velocity = 0,
  }) {
    if (_editableActiveLayerId() == null) {
      _liveStrokeBuilder = null;
      _liveStrokeRevision += 1;
      _notifyLiveStroke();
      return;
    }
    _liveStrokeBuilder = _LiveStrokeBuilder(
      id: newId(),
      firstPoint: StrokePoint(
        world.dx,
        world.dy,
        pressure,
        tiltX: tiltX,
        tiltY: tiltY,
        azimuth: azimuth,
        timestampMicros: timestampMicros,
        velocity: velocity,
      ),
      color: penColor,
      width: resolvedPenWidthWorld(),
      tool: penKind,
    );
    _liveStrokeRevision += 1;
    _notifyLiveStroke();
  }

  /// Appends a sample at the [world] point with [pressure] to [liveStroke].
  ///
  /// A no-op when no stroke is in progress.
  void appendToStroke(
    Offset world,
    double pressure, {
    double tiltX = 0,
    double tiltY = 0,
    double azimuth = 0,
    int timestampMicros = 0,
    double velocity = 0,
  }) {
    final _LiveStrokeBuilder? stroke = _liveStrokeBuilder;
    if (stroke == null) {
      return;
    }
    final StrokePoint last = stroke.last;
    final double minDistance = _strokeSampleMinDistanceWorld(stroke.width);
    final bool movedEnough = (world - last.offset).distance >= minDistance;
    final bool pressureChanged = (pressure - last.pressure).abs() >= 0.035;
    if (!movedEnough && !pressureChanged) {
      return;
    }
    stroke.append(
      StrokePoint(
        world.dx,
        world.dy,
        pressure,
        tiltX: tiltX,
        tiltY: tiltY,
        azimuth: azimuth,
        timestampMicros: timestampMicros,
        velocity: velocity,
      ),
    );
    _liveStrokeRevision += 1;
    _notifyLiveStrokeSoon();
  }

  /// Commits the in-progress [liveStroke] to the canvas as an [InkElement].
  ///
  /// A stroke with at least one point is wrapped in an [InkElement] and added
  /// through an [AddElementCommand], so the commit is undoable. The
  /// [liveStroke] is always cleared.
  void endStroke() {
    final Stroke? stroke = _liveStrokeBuilder?.snapshot();
    final String? layerId = _editableActiveLayerId();
    _liveStrokeBuilder = null;
    _liveStrokeRevision += 1;
    if (stroke != null &&
        layerId != null &&
        (stroke.tool == StrokeToolKind.fill
            ? isValidFillBoundary(stroke.points)
            : stroke.points.isNotEmpty)) {
      final Stroke committed = stroke.copyWith(
        points: stroke.tool == StrokeToolKind.fill
            ? stroke.points
            : PenInputProcessor.applyTaper(stroke.points, penProfile),
      );
      final InkElement element = InkElement.fromStroke(
        committed,
        zIndex: _nextZIndex,
        layerId: layerId,
      );
      _liveStrokeSignal.emit();
      _runCommand(AddElementCommand(element));
      return;
    }
    _notifyLiveStroke();
  }

  /// Discards the in-progress [liveStroke] without committing it.
  void cancelStroke() {
    _liveStrokeBuilder = null;
    _liveStrokeRevision += 1;
    _notifyLiveStroke();
  }

  // ---------------------------------------------------------------------------
  // Viewport
  // ---------------------------------------------------------------------------

  /// Replaces the viewport with [next].
  ///
  /// Schedules a debounced persist of the new camera (a no-op in memory-only
  /// mode) — so the canvas reopens framed where it was left.
  void setViewport(ViewportState next) {
    if (viewport == next) {
      return;
    }
    viewport = next;
    _markViewportChanged();
    _scheduleViewportSave();
    _notifyViewport();
  }

  /// Pans the viewport by [screenDelta] screen pixels.
  void panBy(Offset screenDelta) {
    if (screenDelta == Offset.zero) {
      return;
    }
    viewport = CanvasTransform.panBy(viewport, screenDelta);
    _markViewportChanged();
    _scheduleViewportSave();
    _notifyViewport();
  }

  /// Zooms around the visible viewport center.
  void zoomBy(double scaleFactor) {
    final Offset focus = _viewportSize.isEmpty
        ? Offset.zero
        : Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    setViewport(
      CanvasTransform.zoomAround(
        current: viewport,
        focusScreen: focus,
        scaleFactor: scaleFactor,
      ),
    );
  }

  /// Resets the viewport to [ViewportState.initial].
  void resetView() {
    if (viewport == ViewportState.initial) {
      return;
    }
    viewport = ViewportState.initial;
    _markViewportChanged();
    _scheduleViewportSave();
    _notifyViewport();
  }

  /// Frames all committed canvas content, if any exists.
  void fitContent() {
    final Rect? bounds = contentBounds;
    if (bounds == null) {
      return;
    }
    frameRegion(bounds);
  }

  /// Frames the current lasso selection, if any exists.
  void fitSelection() {
    final Rect? bounds = selectionBounds;
    if (bounds == null) {
      return;
    }
    frameRegion(bounds);
  }

  /// Zooms to paper scale while keeping the visible centre anchored.
  void zoomTo100() {
    if (viewport.scale == 1.0) {
      return;
    }
    final Offset focus = _viewportSize.isEmpty
        ? Offset.zero
        : Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    setViewport(
      CanvasTransform.zoomAround(
        current: viewport,
        focusScreen: focus,
        scaleFactor: 1 / viewport.scale,
      ),
    );
  }

  /// Resets only the viewport rotation, preserving pan and zoom.
  void resetRotation() {
    if (viewport.rotation == 0) {
      return;
    }
    viewport = viewport.copyWith(rotation: 0);
    _markViewportChanged();
    _scheduleViewportSave();
    _notifyViewport();
  }

  /// Snaps a nearly-upright viewport to the nearest quarter turn.
  ///
  /// This removes tiny accidental twists from pinch-to-zoom while preserving
  /// deliberate canvas rotations. The visible center stays anchored so the
  /// correction does not shift the user's work under their hand.
  void snapRotationToCardinalIfClose() {
    const double quarterTurn = math.pi / 2;
    const double threshold = math.pi / 60; // 3 degrees.
    final double target =
        (viewport.rotation / quarterTurn).roundToDouble() * quarterTurn;
    final double delta = _normalizeRadians(target - viewport.rotation);
    if (delta == 0 || delta.abs() > threshold) {
      return;
    }
    final Offset focus = _viewportSize.isEmpty
        ? Offset.zero
        : Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    final ViewportState snapped = CanvasTransform.interactiveUpdate(
      start: viewport,
      anchorScreenAtStart: focus,
      currentFocusScreen: focus,
      scaleFactor: 1,
      rotationDelta: delta,
    );
    setViewport(
      snapped.copyWith(rotation: _normalizeRadians(snapped.rotation)),
    );
  }

  /// Toggles whether pinch gestures may rotate the viewport.
  void toggleRotationLock() {
    rotationLocked = !rotationLocked;
    final CanvasRepository? repo = _repository;
    final String? canvasId = _canvasId;
    if (repo != null && canvasId != null) {
      _track(() => repo.saveRotationLocked(canvasId, locked: rotationLocked));
    }
    _notifyToolState();
  }

  /// Records the current canvas viewport [size] in logical pixels.
  ///
  /// The view calls this on layout. The size feeds two things: centring a
  /// freshly imported element in what the user is looking at, and choosing the
  /// PDF page raster resolution. A no-op (no notify) when the size is
  /// unchanged, so a relayout never triggers a spurious repaint.
  void setViewportSize(Size size) {
    if (size == _viewportSize) {
      return;
    }
    _viewportSize = size;
    _viewportElementsView = null;
  }

  /// World-space rectangle currently visible in the viewport.
  ///
  /// The four screen corners are mapped to world space and bounded; under
  /// rotation this is the axis-aligned hull of the (skewed) projected corners.
  /// Falls back to a unit rect at the world origin before the view has
  /// reported its size.
  Rect get _visibleWorldRect {
    final Size size = _viewportSize;
    if (size.isEmpty) {
      return const Rect.fromLTWH(0, 0, 1, 1);
    }
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
    for (final Offset c in corners) {
      if (c.dx < minX) minX = c.dx;
      if (c.dx > maxX) maxX = c.dx;
      if (c.dy < minY) minY = c.dy;
      if (c.dy > maxY) maxY = c.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Public world-space rectangle currently visible in the viewport.
  Rect get visibleWorldRect => _visibleWorldRect;

  /// World-space bounding box of all committed content, or `null` when empty.
  Rect? get contentBounds {
    Rect? bounds;
    for (final CanvasElement element in _elements) {
      if (!_isElementVisible(element)) {
        continue;
      }
      bounds = bounds == null
          ? element.worldBounds
          : bounds.expandToInclude(element.worldBounds);
    }
    return bounds;
  }

  // ---------------------------------------------------------------------------
  // Tools
  // ---------------------------------------------------------------------------

  /// Sets the active interaction tool.
  ///
  /// Switching tools discards only an in-progress lasso loop. Committed
  /// selections intentionally survive so they can be moved, scaled, rotated or
  /// deleted without forcing the user to stay in the lasso tool.
  void setTool(CanvasTool tool) {
    if (activeTool == tool) {
      return;
    }
    if (activeTool != tool) {
      _previousTool = activeTool;
    }
    activeTool = tool;
    final int matchingPreset = _toolWheelPresets.indexWhere(
      (ToolWheelPreset preset) =>
          _canvasToolForPreset(preset.kind) == tool &&
          (!preset.kind.isInk || preset.kind.strokeKind == penKind),
    );
    if (matchingPreset >= 0) {
      activeToolWheelIndex = matchingPreset;
      _saveToolSettings();
    }
    _discardLasso(restoreSelection: true);
    _overlaySignal.emit();
    _notifyToolState();
  }

  /// Atomically activates one of the eight remembered wheel presets.
  void selectToolWheelPreset(int index) {
    if (index < 0 || index >= _toolWheelPresets.length) return;
    final ToolWheelPreset preset = _toolWheelPresets[index];
    final CanvasTool nextTool = _canvasToolForPreset(preset.kind);
    if (activeTool != nextTool) {
      _previousTool = activeTool;
    }
    activeToolWheelIndex = index;
    activeTool = nextTool;
    _discardLasso(restoreSelection: true);
    _applyToolWheelPresetValues(preset);
    _saveToolSettings();
    _overlaySignal.emit();
    _notifyToolState();
  }

  /// Reassigns a favorite slot, then immediately activates its defaults.
  void replaceToolWheelPreset(int index, ToolWheelSlotKind kind) {
    if (index < 0 || index >= _toolWheelPresets.length) return;
    _toolWheelPresets[index] = defaultToolWheelPresetFor(kind);
    selectToolWheelPreset(index);
  }

  static CanvasTool _canvasToolForPreset(ToolWheelSlotKind kind) {
    return switch (kind) {
      ToolWheelSlotKind.pen ||
      ToolWheelSlotKind.pencil ||
      ToolWheelSlotKind.highlighter ||
      ToolWheelSlotKind.marker ||
      ToolWheelSlotKind.airbrush ||
      ToolWheelSlotKind.fill => CanvasTool.pen,
      ToolWheelSlotKind.eraser => CanvasTool.eraser,
      ToolWheelSlotKind.lasso => CanvasTool.lasso,
      ToolWheelSlotKind.shape => CanvasTool.shape,
      ToolWheelSlotKind.text => CanvasTool.text,
      ToolWheelSlotKind.link => CanvasTool.link,
      ToolWheelSlotKind.pan => CanvasTool.pan,
    };
  }

  void _applyToolWheelPresetValues(ToolWheelPreset preset) {
    if (preset.kind.isInk) {
      penKind = preset.kind.strokeKind!;
      penColor = _argbWithOpacity(preset.color, preset.opacity);
      penWidth = preset.size;
      penWidthMode = preset.widthMode;
      pressureEnabled = preset.pressureEnabled;
      penProfile = penProfile.copyWith(smoothing: preset.smoothing);
    } else if (preset.kind == ToolWheelSlotKind.eraser) {
      eraserRadius = preset.size;
    }
  }

  static int _argbWithOpacity(int color, double opacity) {
    final int alpha = (opacity.clamp(0, 1) * 255).round();
    return (alpha << 24) | (color & 0x00FFFFFF);
  }

  /// Toggles between the current tool and the last explicit tool.
  void togglePreviousTool() {
    final CanvasTool next = _previousTool;
    _previousTool = activeTool;
    activeTool = next;
    _discardLasso(restoreSelection: true);
    _overlaySignal.emit();
    _notifyToolState();
  }

  /// Temporarily swaps tools for a held stylus-button gesture.
  void pushTemporaryTool(CanvasTool tool, {ShapeKind? shapeKindOverride}) {
    _temporaryTools.add(
      _TemporaryToolSnapshot(tool: activeTool, shapeKind: shapeKind),
    );
    activeTool = tool;
    if (shapeKindOverride != null) {
      shapeKind = shapeKindOverride;
    }
    _overlaySignal.emit();
    _notifyToolState();
  }

  /// Restores the most recent temporary tool swap.
  void popTemporaryTool() {
    if (_temporaryTools.isEmpty) {
      return;
    }
    final _TemporaryToolSnapshot snapshot = _temporaryTools.removeLast();
    activeTool = snapshot.tool;
    shapeKind = snapshot.shapeKind;
    _overlaySignal.emit();
    _notifyToolState();
  }

  /// Sets how the eraser removes ink (whole elements vs. vector fragments).
  void setEraserMode(EraserMode mode) {
    if (eraserMode == mode) {
      return;
    }
    eraserMode = mode;
    _notifyToolState();
  }

  /// Sets how lasso and tap item-picking update the current selection.
  void setSelectionMode(SelectionMode mode) {
    if (selectionMode == mode) {
      return;
    }
    selectionMode = mode;
    _notifyToolState();
  }

  /// Makes [layerId] the destination for new canvas content.
  void setActiveLayer(String layerId) {
    final CanvasLayer? layer = _layerById(layerId);
    if (layer == null || !layer.isEditable) {
      return;
    }
    _activeLayerId = layerId;
    _notifyToolState();
  }

  /// Adds a new content layer above the current topmost layer.
  CanvasLayer addLayer({String name = 'Layer'}) {
    final double position = _layers.isEmpty
        ? 0
        : _layers
                  .map((CanvasLayer layer) => layer.position)
                  .reduce((double a, double b) => a > b ? a : b) +
              1;
    final CanvasLayer layer = CanvasLayer(
      id: newId(),
      canvasId: _layerCanvasId,
      name: name,
      position: position,
    );
    _layers.add(layer);
    _layers.sort(
      (CanvasLayer a, CanvasLayer b) => a.position.compareTo(b.position),
    );
    _activeLayerId = layer.id;
    _markElementsChanged(damageBounds: Rect.zero);
    _persistLayer(layer);
    _notifyElements();
    return layer;
  }

  void setLayerVisible(String layerId, {required bool visible}) {
    final int index = _layers.indexWhere((CanvasLayer l) => l.id == layerId);
    if (index < 0) {
      return;
    }
    final CanvasLayer layer = _layers[index];
    final CanvasLayer next = layer.copyWith(visible: visible);
    _layers[index] = next;
    _markElementsChanged(
      damageBounds: _damageBoundsForElements(
        (CanvasElement element) => _effectiveLayerId(element) == layerId,
      ),
    );
    if (!visible) {
      _removeSelectedIdsWhere(
        (String id) => _elements.any(
          (CanvasElement element) =>
              element.id == id && _effectiveLayerId(element) == layerId,
        ),
      );
      if (_activeLayerId == layerId) {
        _activeLayerId = _firstEditableLayerId() ?? _defaultLayerId;
      }
    }
    _persistLayer(next);
    _notifyElements();
  }

  void setLayerLocked(String layerId, {required bool locked}) {
    final int index = _layers.indexWhere((CanvasLayer l) => l.id == layerId);
    if (index < 0) {
      return;
    }
    final CanvasLayer layer = _layers[index];
    final CanvasLayer next = layer.copyWith(locked: locked);
    _layers[index] = next;
    if (locked) {
      _removeSelectedIdsWhere(
        (String id) => _elements.any(
          (CanvasElement element) =>
              element.id == id && _effectiveLayerId(element) == layerId,
        ),
      );
      if (_activeLayerId == layerId) {
        _activeLayerId = _firstEditableLayerId() ?? _defaultLayerId;
      }
    }
    _persistLayer(next);
    _notifyElements();
  }

  void moveLayer(String layerId, int direction) {
    if (direction == 0 || _layers.length < 2) {
      return;
    }
    _layers.sort(
      (CanvasLayer a, CanvasLayer b) => a.position.compareTo(b.position),
    );
    final int index = _layers.indexWhere((CanvasLayer l) => l.id == layerId);
    if (index < 0) {
      return;
    }
    final int nextIndex = (index + direction).clamp(0, _layers.length - 1);
    if (nextIndex == index) {
      return;
    }
    final CanvasLayer moving = _layers.removeAt(index);
    _layers.insert(nextIndex, moving);
    for (var i = 0; i < _layers.length; i += 1) {
      final CanvasLayer updated = _layers[i].copyWith(position: i.toDouble());
      _layers[i] = updated;
    }
    _persistLayers(List<CanvasLayer>.of(_layers));
    _elements.sort(_compareElements);
    _rebuildPaintOrder();
    _markElementsChanged(
      damageBounds: _damageBoundsForElements((CanvasElement element) => true),
    );
    _notifyElements();
  }

  /// Sets the on-screen radius of the eraser footprint.
  void setEraserRadius(double radius) {
    final double normalized = radius.clamp(1, 96).toDouble();
    if (eraserRadius == normalized) {
      return;
    }
    eraserRadius = normalized;
    final ToolWheelPreset preset = activeToolWheelPreset;
    if (preset.kind == ToolWheelSlotKind.eraser) {
      _toolWheelPresets[activeToolWheelIndex] = preset.copyWith(
        size: eraserRadius,
      );
      _saveToolSettings(debounce: true);
    }
    _notifyToolState();
  }

  /// Sets the shape primitive the shape tool produces.
  void setShapeKind(ShapeKind kind) {
    if (shapeKind == kind) {
      return;
    }
    shapeKind = kind;
    _notifyToolState();
  }

  /// Sets the arrow style used by newly-created arrow shapes.
  void setArrowStyle({
    ArrowBodyKind? body,
    ArrowHeadStyle? startHead,
    ArrowHeadStyle? endHead,
    double? headScale,
  }) {
    arrowBody = body ?? arrowBody;
    arrowStartHead = startHead ?? arrowStartHead;
    arrowEndHead = endHead ?? arrowEndHead;
    arrowHeadScale = (headScale ?? arrowHeadScale).clamp(0.35, 2.5);
    _notifyToolState();
  }

  /// Sets the packed ARGB colour applied to new strokes.
  void setPenColor(int color) {
    if (penColor == color) {
      return;
    }
    penColor = color;
    final ToolWheelPreset preset = activeToolWheelPreset;
    if (preset.kind.isInk) {
      _toolWheelPresets[activeToolWheelIndex] = preset.copyWith(
        color: color | 0xFF000000,
        opacity: ((color >>> 24) & 0xFF) / 255,
      );
    }
    _saveToolSettings();
    _notifyToolState();
  }

  /// Changes only the RGB component, preserving this preset's opacity.
  void setPenRgbColor(int color) {
    final int nextColor = (penColor & 0xFF000000) | (color & 0x00FFFFFF);
    if (penColor == nextColor) {
      return;
    }
    penColor = nextColor;
    final ToolWheelPreset preset = activeToolWheelPreset;
    if (preset.kind.isInk) {
      _toolWheelPresets[activeToolWheelIndex] = preset.copyWith(
        color: color | 0xFF000000,
      );
    }
    _saveToolSettings();
    _notifyToolState();
  }

  /// Sets the active preset's opacity without changing its selected colour.
  void setPenOpacity(double opacity) {
    final double normalized = opacity.clamp(0, 1).toDouble();
    if (((penColor >>> 24) & 0xFF) == (normalized * 255).round()) {
      return;
    }
    penColor = _argbWithOpacity(penColor, normalized);
    final ToolWheelPreset preset = activeToolWheelPreset;
    if (preset.kind.isInk) {
      _toolWheelPresets[activeToolWheelIndex] = preset.copyWith(
        opacity: normalized,
      );
    }
    _saveToolSettings(debounce: true);
    _notifyToolState();
  }

  /// Sets the on-screen width applied to new strokes.
  void setPenWidth(double width) {
    final double normalized = width.clamp(0.5, 96).toDouble();
    if (penWidth == normalized) {
      return;
    }
    penWidth = normalized;
    final ToolWheelPreset preset = activeToolWheelPreset;
    if (preset.kind.isInk) {
      _toolWheelPresets[activeToolWheelIndex] = preset.copyWith(size: penWidth);
    }
    _saveToolSettings(debounce: true);
    _notifyToolState();
  }

  /// Sets whether new marks keep screen size or canvas size while zooming.
  void setPenWidthMode(PenWidthMode mode) {
    if (penWidthMode == mode) {
      return;
    }
    penWidthMode = mode;
    final ToolWheelPreset preset = activeToolWheelPreset;
    if (preset.kind.isInk) {
      _toolWheelPresets[activeToolWheelIndex] = preset.copyWith(
        widthMode: mode,
      );
    }
    _saveToolSettings();
    _notifyToolState();
  }

  /// Turns Adaptive pen on or off for the active ink-wheel preset.
  void setAdaptivePenEnabled({required bool enabled}) {
    setPenWidthMode(enabled ? PenWidthMode.screen : PenWidthMode.canvas);
  }

  /// Sets the ink tool kind applied to new strokes.
  void setPenKind(StrokeToolKind kind) {
    if (penKind == kind) {
      return;
    }
    penKind = kind;
    final ToolWheelPreset preset = activeToolWheelPreset;
    if (activeTool == CanvasTool.pen) {
      _toolWheelPresets[activeToolWheelIndex] = preset.copyWith(
        kind: ToolWheelSlotKind.fromStrokeKind(kind),
      );
    }
    _saveToolSettings();
    _notifyToolState();
  }

  /// Toggles whether captured pressure affects new strokes.
  void setPressureEnabled({required bool enabled}) {
    if (pressureEnabled == enabled) {
      return;
    }
    pressureEnabled = enabled;
    final ToolWheelPreset preset = activeToolWheelPreset;
    if (preset.kind.isInk) {
      _toolWheelPresets[activeToolWheelIndex] = preset.copyWith(
        pressureEnabled: enabled,
      );
    }
    _saveToolSettings();
    _notifyToolState();
  }

  /// Updates the capture profile for future strokes.
  void setPenProfile(PenProfile profile, {bool notify = true}) {
    if (penProfile == profile) {
      return;
    }
    penProfile = profile;
    if (notify) {
      _notifyToolState();
    }
  }

  /// Updates only smoothing for the active wheel preset.
  void setPenSmoothing(double smoothing) {
    final double normalized = smoothing.clamp(0, 1).toDouble();
    if (penProfile.smoothing == normalized) {
      return;
    }
    penProfile = penProfile.copyWith(smoothing: normalized);
    final ToolWheelPreset preset = activeToolWheelPreset;
    if (preset.kind.isInk) {
      _toolWheelPresets[activeToolWheelIndex] = preset.copyWith(
        smoothing: normalized,
      );
    }
    _saveToolSettings(debounce: true);
    _notifyToolState();
  }

  /// Updates the per-canvas paper style.
  void setPaperStyle(CanvasPaperStyle style) {
    if (paperStyle == style) {
      return;
    }
    paperStyle = style;
    final CanvasRepository? repo = _repository;
    final String? canvasId = _canvasId;
    if (repo != null && canvasId != null) {
      _track(() => repo.savePaperStyle(canvasId, style));
    }
    _notifyCanvasStyle();
  }

  /// Enables or disables snap-to-grid for precision placement.
  void setSnapToGridEnabled({required bool enabled}) {
    if (snapToGridEnabled == enabled) {
      return;
    }
    snapToGridEnabled = enabled;
    _notifyToolState();
  }

  /// Toggles snap-to-grid.
  void toggleSnapToGrid() {
    setSnapToGridEnabled(enabled: !snapToGridEnabled);
  }

  void _saveToolSettings({bool debounce = false}) {
    final CanvasRepository? repo = _repository;
    final String? canvasId = _canvasId;
    if (repo == null || canvasId == null) {
      return;
    }
    _toolSettingsDirty = true;
    if (debounce) {
      _toolSettingsSaveTimer?.cancel();
      _toolSettingsSaveTimer = Timer(
        _toolSettingsSaveDebounce,
        _saveToolSettingsNow,
      );
      return;
    }
    commitToolSettings();
  }

  /// Persists the exact final value after a continuous tool-setting gesture.
  void commitToolSettings() {
    _toolSettingsSaveTimer?.cancel();
    _toolSettingsSaveTimer = null;
    _saveToolSettingsNow();
  }

  void _saveToolSettingsNow() {
    final CanvasRepository? repo = _repository;
    final String? canvasId = _canvasId;
    if (!_toolSettingsDirty || repo == null || canvasId == null) {
      return;
    }
    _toolSettingsDirty = false;
    _track(
      () => repo.saveToolSettings(
        canvasId,
        CanvasToolSettings(
          penColor: penColor,
          penWidth: penWidth,
          penWidthMode: penWidthMode,
          penKind: penKind,
          pressureEnabled: pressureEnabled,
          toolWheelPresets: toolWheelPresets,
          activeToolWheelIndex: activeToolWheelIndex,
        ),
      ),
    );
  }

  /// Current pen width resolved to world units for a new committed mark.
  double resolvedPenWidthWorld() {
    return resolveStrokeWidthWorld(
      selectedWidth: penWidth,
      viewportScale: viewport.scale,
      mode: penWidthMode,
    );
  }

  /// Current pen hover radius in screen pixels.
  double resolvedPenHoverRadiusScreen() {
    final double screenDiameter = switch (penWidthMode) {
      PenWidthMode.screen => penWidth,
      PenWidthMode.canvas => penWidth * viewport.scale,
    };
    return (screenDiameter / 2).clamp(0.5, double.infinity).toDouble();
  }

  double _strokeSampleMinDistanceWorld(double strokeWidthWorld) {
    final double scale = viewport.scale;
    final double screenSample = scale.isFinite && scale > 0 ? 1.0 / scale : 1;
    final double widthSample = strokeWidthWorld / 3;
    return math.max(1e-6, math.min(screenSample, widthSample));
  }

  /// Sets the stylus hover indicator position, or clears it with `null`.
  void setHoverPoint(Offset? world) {
    if (hoverPointWorld == world) {
      return;
    }
    hoverPointWorld = world;
    _notifyOverlay();
  }

  // ---------------------------------------------------------------------------
  // Edits
  // ---------------------------------------------------------------------------

  /// Removes the given [elements] from the canvas as one undoable command.
  ///
  /// A no-op when [elements] is empty. Backs the object eraser / lasso-delete
  /// in later steps.
  void removeElements(Iterable<CanvasElement> elements) {
    final List<CanvasElement> list = elements
        .where(_isElementEditable)
        .toList(growable: false);
    if (list.isEmpty) {
      return;
    }
    _runCommand(RemoveElementsCommand(list));
  }

  /// Removes every committed element via an undoable [ClearCommand].
  ///
  /// Also discards any in-progress [liveStroke] and clears the selection. The
  /// clear can be reversed with [undo].
  void clear() {
    _liveStrokeBuilder = null;
    _liveStrokeRevision += 1;
    _clearSelectedIds();
    final List<CanvasElement> editable = _elements
        .where(_isElementEditable)
        .toList(growable: false);
    if (editable.isEmpty) {
      notifyListeners();
      return;
    }
    _runCommand(RemoveElementsCommand(editable));
  }

  // ---------------------------------------------------------------------------
  // Eraser tool
  // ---------------------------------------------------------------------------

  /// Starts an eraser drag at the [world] point.
  ///
  /// The drag accumulates a world-space path; nothing is erased until
  /// [endErase] commits the gesture, so an entire drag is one undoable unit.
  void beginErase(Offset world) {
    _eraserPath = <Offset>[world];
    _notifyOverlay();
  }

  /// Extends the in-progress eraser drag to the [world] point.
  ///
  /// A no-op when no eraser drag is active.
  void appendErase(Offset world) {
    final List<Offset>? path = _eraserPath;
    if (path == null) {
      return;
    }
    path.add(world);
    _notifyOverlay();
  }

  /// Finishes the eraser drag, applying the erase as one undoable command.
  ///
  /// Dispatches on [eraserMode]: [EraserMode.object] deletes whole crossed
  /// elements via a [RemoveElementsCommand]; [EraserMode.partial] splits
  /// crossed ink strokes into surviving vector fragments via a
  /// [ReplaceElementsCommand]. The eraser path is always cleared.
  void endErase() {
    final List<Offset>? path = _eraserPath;
    _eraserPath = null;
    if (path == null || path.isEmpty) {
      _notifyOverlay();
      return;
    }
    switch (eraserMode) {
      case EraserMode.object:
        _eraseWholeElements(path);
      case EraserMode.partial:
        _erasePartial(path);
    }
  }

  /// Cancels an in-progress eraser drag without erasing anything.
  void cancelErase() {
    _eraserPath = null;
    _notifyOverlay();
  }

  /// Deletes every element the eraser [path] crosses (object eraser).
  ///
  /// Broad phase: the spatial index is queried for the path's bounding area,
  /// inflated by the eraser radius. Narrow phase: each candidate ink element is
  /// precisely tested with [CanvasGeometry.circleHitsPolyline] against every
  /// eraser sample. All hits are removed as one [RemoveElementsCommand].
  void _eraseWholeElements(List<Offset> path) {
    final List<CanvasElement> hits = _elementsHitByEraser(path);
    if (hits.isEmpty) {
      _notifyOverlay();
      return;
    }
    _runCommand(RemoveElementsCommand(hits));
  }

  /// Splits every ink element the eraser [path] crosses (partial eraser).
  ///
  /// Each crossed [InkElement] is removed and replaced by 0..n fresh
  /// [InkElement] fragments — one per contiguous run of untouched stroke points
  /// (see [CanvasGeometry.splitStrokeByEraser]). Fragments keep the original
  /// stroke's colour, width and tool, and get fresh ids/z-indices so they slot
  /// cleanly into the store and the index. The whole operation is one undoable
  /// [ReplaceElementsCommand]; non-ink elements are left untouched.
  void _erasePartial(List<Offset> path) {
    final double worldRadius = eraserRadius / viewport.scale;
    final List<CanvasElement> removed = <CanvasElement>[];
    final List<CanvasElement> added = <CanvasElement>[];

    for (final CanvasElement element in _elementsHitByEraser(path)) {
      if (element is! InkElement) {
        // Only ink splits; a non-ink element the eraser merely grazes survives.
        continue;
      }
      if (element.stroke.tool == StrokeToolKind.fill) {
        // A fill is one closed region, not a centreline that can be split into
        // meaningful stroke fragments. Partial erase therefore removes the
        // region as a single object instead of corrupting its boundary.
        removed.add(element);
        continue;
      }
      final List<List<StrokePoint>> fragments =
          CanvasGeometry.splitStrokeByEraser(
            stroke: element.stroke,
            eraserPath: path,
            radius: worldRadius,
          );
      // Untouched: one fragment identical to the original — nothing to do.
      if (fragments.length == 1 &&
          fragments.single.length == element.stroke.points.length) {
        continue;
      }
      removed.add(element);
      for (final List<StrokePoint> run in fragments) {
        if (run.isEmpty) {
          continue;
        }
        added.add(
          InkElement.fromStroke(
            element.stroke.copyWith(id: newId(), points: run),
            zIndex: _nextZIndex++,
            layerId: element.layerId,
          ),
        );
      }
    }

    if (removed.isEmpty) {
      _notifyOverlay();
      return;
    }
    _runCommand(ReplaceElementsCommand(removed: removed, added: added));
  }

  /// Returns every committed element the eraser [path] crosses.
  ///
  /// Two-phase: the spatial index narrows to candidates whose bounds overlap
  /// the inflated path area, then each ink candidate is precisely tested
  /// against the eraser circle swept along the path. The eraser radius is
  /// converted from screen pixels to world units via the viewport scale so the
  /// footprint stays visually constant at any zoom.
  List<CanvasElement> _elementsHitByEraser(List<Offset> path) {
    if (path.isEmpty) {
      return const <CanvasElement>[];
    }
    final double worldRadius = eraserRadius / viewport.scale;
    final Rect area = CanvasGeometry.boundsOfPoints(path).inflate(worldRadius);
    final Set<String> candidateIds = _spatialIndex.query(area).toSet();
    if (candidateIds.isEmpty) {
      return const <CanvasElement>[];
    }

    final List<CanvasElement> hits = <CanvasElement>[];
    for (final CanvasElement element in _elements) {
      if (!_isElementEditable(element)) {
        continue;
      }
      if (!candidateIds.contains(element.id)) {
        continue;
      }
      if (_eraserPathHitsElement(element, path, worldRadius)) {
        hits.add(element);
      }
    }
    return hits;
  }

  /// Whether the eraser [path] (circle of [worldRadius]) crosses [element].
  ///
  /// Ink is tested precisely: the swept eraser polyline is checked for
  /// proximity to the stroke's centerline (symmetric, so a short eraser dab
  /// across a long stroke segment is caught too). This stays consistent with
  /// [CanvasGeometry.splitStrokeByEraser], which decides which points die.
  ///
  /// Image, PDF and link elements have no centerline — the eraser hits one when
  /// any swept sample falls within [worldRadius] of its placement rectangle.
  /// Such a hit can only ever object-erase the whole element (see [endErase]);
  /// the vector partial eraser applies to [InkElement] alone — a link chip is
  /// never split.
  bool _eraserPathHitsElement(
    CanvasElement element,
    List<Offset> path,
    double worldRadius,
  ) {
    switch (element) {
      case InkElement():
        if (element.stroke.tool == StrokeToolKind.fill) {
          if (path.any(element.outlinePath.contains)) {
            return true;
          }
          return CanvasGeometry.polylinesWithinDistance(
            path,
            _closedFillBoundary(element),
            worldRadius,
          );
        }
        final List<Offset> centerline = <Offset>[
          for (final StrokePoint p in element.stroke.points) p.offset,
        ];
        return CanvasGeometry.polylinesWithinDistance(
          path,
          centerline,
          worldRadius,
        );
      case ImageElement():
      case PdfElement():
      case LinkElement():
      case TextElement():
        return _pathReachesRotatedRect(
          path,
          _placementBoundsOf(element)!,
          element.rotation,
          worldRadius,
        );
      case ShapeElement():
        return _pathReachesShape(path, element, worldRadius);
    }
  }

  static bool _pathReachesShape(
    List<Offset> path,
    ShapeElement element,
    double radius,
  ) {
    for (final List<Offset> polygon in _shapeFilledPolygons(element)) {
      if (path.any(
        (Offset point) => CanvasGeometry.polygonContainsPoint(polygon, point),
      )) {
        return true;
      }
    }
    final double reach = radius + element.strokeWidth / 2;
    for (final List<Offset> polyline in _shapePolylines(element)) {
      if (CanvasGeometry.polylinesWithinDistance(path, polyline, reach)) {
        return true;
      }
    }
    return false;
  }

  static bool _pointHitsShape(Offset point, ShapeElement element, double slop) {
    for (final List<Offset> polygon in _shapeFilledPolygons(element)) {
      if (CanvasGeometry.polygonContainsPoint(polygon, point)) {
        return true;
      }
    }
    final double reach = slop + element.strokeWidth / 2;
    for (final List<Offset> polyline in _shapePolylines(element)) {
      if (CanvasGeometry.circleHitsPolyline(point, reach, polyline)) {
        return true;
      }
    }
    return false;
  }

  static List<List<Offset>> _shapePolylines(ShapeElement element) {
    switch (element.shapeKind) {
      case 0:
        return <List<Offset>>[
          CanvasGeometry.linePoints(element.start, element.end),
        ];
      case 1:
        return <List<Offset>>[
          CanvasGeometry.rectanglePoints(element.start, element.end),
        ];
      case 2:
        final Rect rect = Rect.fromPoints(element.start, element.end);
        final int segments = (math.pi * (rect.width + rect.height) / 8)
            .ceil()
            .clamp(32, 256);
        return <List<Offset>>[
          CanvasGeometry.ovalPoints(
            element.start,
            element.end,
            segments: segments,
          ),
        ];
      case 3:
        return _arrowPolylines(element);
      default:
        return <List<Offset>>[
          CanvasGeometry.linePoints(element.start, element.end),
        ];
    }
  }

  static List<List<Offset>> _arrowPolylines(ShapeElement element) {
    final Offset delta = element.end - element.start;
    final double length = delta.distance;
    if (length == 0) {
      return <List<Offset>>[
        <Offset>[element.start],
      ];
    }
    if (element.legacyArrow) {
      final double angle = math.atan2(delta.dy, delta.dx);
      final double headLength = ArrowGeometry.legacyHeadLength(
        element.start,
        element.end,
      );
      const double headAngle = math.pi / 7;
      final Offset left = Offset(
        element.end.dx - headLength * math.cos(angle - headAngle),
        element.end.dy - headLength * math.sin(angle - headAngle),
      );
      final Offset right = Offset(
        element.end.dx - headLength * math.cos(angle + headAngle),
        element.end.dy - headLength * math.sin(angle + headAngle),
      );
      return <List<Offset>>[
        <Offset>[element.start, element.end],
        <Offset>[element.end, left, right, element.end],
      ];
    }

    final List<List<Offset>> result = <List<Offset>>[
      _samplePath(
        ArrowGeometry.bodyPath(
          body: element.arrowBody,
          start: element.start,
          end: element.end,
          controls: element.controlPoints,
          strokeWidth: element.strokeWidth,
        ),
      ),
    ];
    final double headLength = ArrowGeometry.styledHeadLength(
      strokeWidth: element.strokeWidth,
      headScale: element.arrowHeadScale,
      maxLength: length,
    );
    result.addAll(
      _arrowHeadPolylines(
        tip: element.end,
        direction: ArrowGeometry.endTangent(
          body: element.arrowBody,
          start: element.start,
          end: element.end,
          controls: element.controlPoints,
          strokeWidth: element.strokeWidth,
        ),
        style: element.arrowEndHead,
        length: headLength,
      ),
    );
    result.addAll(
      _arrowHeadPolylines(
        tip: element.start,
        direction: -ArrowGeometry.startTangent(
          body: element.arrowBody,
          start: element.start,
          end: element.end,
          controls: element.controlPoints,
          strokeWidth: element.strokeWidth,
        ),
        style: element.arrowStartHead,
        length: headLength,
      ),
    );
    return result;
  }

  static List<Offset> _samplePath(ui.Path path) {
    final List<Offset> points = <Offset>[];
    for (final ui.PathMetric metric in path.computeMetrics()) {
      final int segments = (metric.length / 4).ceil().clamp(1, 256);
      for (var i = 0; i <= segments; i++) {
        final ui.Tangent? tangent = metric.getTangentForOffset(
          metric.length * i / segments,
        );
        if (tangent != null) {
          points.add(tangent.position);
        }
      }
    }
    return points;
  }

  static List<List<Offset>> _arrowHeadPolylines({
    required Offset tip,
    required Offset direction,
    required ArrowHeadStyle style,
    required double length,
  }) {
    if (style == ArrowHeadStyle.none ||
        length <= 0 ||
        direction.distance == 0) {
      return const <List<Offset>>[];
    }
    final Offset unit = direction / direction.distance;
    final Offset normal = Offset(-unit.dy, unit.dx);
    final double wing = length * 0.48;
    final Offset base = tip - unit * length;
    final Offset left = base + normal * wing;
    final Offset right = base - normal * wing;
    switch (style) {
      case ArrowHeadStyle.none:
        return const <List<Offset>>[];
      case ArrowHeadStyle.open:
        return <List<Offset>>[
          <Offset>[left, tip, right],
        ];
      case ArrowHeadStyle.filled:
        return <List<Offset>>[
          <Offset>[tip, left, right, tip],
        ];
      case ArrowHeadStyle.dot:
        final double radius = length * 0.28;
        return <List<Offset>>[
          CanvasGeometry.ovalPoints(
            tip - Offset(radius, radius),
            tip + Offset(radius, radius),
            segments: 32,
          ),
        ];
      case ArrowHeadStyle.diamond:
        final Offset center = tip - unit * (length * 0.48);
        final Offset tail = tip - unit * (length * 0.96);
        return <List<Offset>>[
          <Offset>[
            tip,
            center + normal * wing * 0.75,
            tail,
            center - normal * wing * 0.75,
            tip,
          ],
        ];
      case ArrowHeadStyle.bar:
        return <List<Offset>>[
          <Offset>[tip + normal * wing, tip - normal * wing],
        ];
    }
  }

  static List<List<Offset>> _shapeFilledPolygons(ShapeElement element) {
    if (element.shapeKind != ShapeKind.arrow.index) {
      return const <List<Offset>>[];
    }
    if (element.legacyArrow) {
      final List<List<Offset>> polylines = _arrowPolylines(element);
      return polylines.length < 2
          ? const <List<Offset>>[]
          : <List<Offset>>[polylines[1]];
    }
    final double arrowLength = (element.end - element.start).distance;
    if (arrowLength == 0) {
      return const <List<Offset>>[];
    }
    final double headLength = ArrowGeometry.styledHeadLength(
      strokeWidth: element.strokeWidth,
      headScale: element.arrowHeadScale,
      maxLength: arrowLength,
    );
    final List<List<Offset>> polygons = <List<Offset>>[];
    if (_arrowHeadIsFilled(element.arrowEndHead)) {
      polygons.addAll(
        _arrowHeadPolylines(
          tip: element.end,
          direction: ArrowGeometry.endTangent(
            body: element.arrowBody,
            start: element.start,
            end: element.end,
            controls: element.controlPoints,
            strokeWidth: element.strokeWidth,
          ),
          style: element.arrowEndHead,
          length: headLength,
        ),
      );
    }
    if (_arrowHeadIsFilled(element.arrowStartHead)) {
      polygons.addAll(
        _arrowHeadPolylines(
          tip: element.start,
          direction: -ArrowGeometry.startTangent(
            body: element.arrowBody,
            start: element.start,
            end: element.end,
            controls: element.controlPoints,
            strokeWidth: element.strokeWidth,
          ),
          style: element.arrowStartHead,
          length: headLength,
        ),
      );
    }
    return polygons;
  }

  static bool _arrowHeadIsFilled(ArrowHeadStyle style) {
    return style == ArrowHeadStyle.filled || style == ArrowHeadStyle.dot;
  }

  static List<Offset> _shapeCoverageSamples(ShapeElement element) {
    final List<(Offset, Offset, double)> segments =
        <(Offset, Offset, double)>[];
    var totalLength = 0.0;
    for (final List<Offset> polyline in _shapePolylines(element)) {
      for (var i = 0; i + 1 < polyline.length; i++) {
        final double length = (polyline[i + 1] - polyline[i]).distance;
        if (length == 0) {
          continue;
        }
        segments.add((polyline[i], polyline[i + 1], length));
        totalLength += length;
      }
    }
    if (segments.isEmpty || totalLength == 0) {
      return <Offset>[element.start];
    }
    const int targetSamples = 64;
    return <Offset>[
      for (final (Offset start, Offset end, double length) in segments)
        for (
          var i = 0;
          i < math.max(1, (targetSamples * length / totalLength).round());
          i++
        )
          Offset.lerp(
            start,
            end,
            (i + 0.5) /
                math.max(1, (targetSamples * length / totalLength).round()),
          )!,
    ];
  }

  /// Whether any sample of [path] lies within [radius] of [rect].
  ///
  /// Used to object-hit-test rectangular (image / PDF) elements against the
  /// swept eraser circle: a sample inside the rect, or within [radius] of its
  /// nearest edge, counts as a hit.
  static bool _pathReachesRect(List<Offset> path, Rect rect, double radius) {
    final double r2 = radius * radius;
    for (final Offset p in path) {
      final double cx = p.dx.clamp(rect.left, rect.right);
      final double cy = p.dy.clamp(rect.top, rect.bottom);
      final double dx = p.dx - cx;
      final double dy = p.dy - cy;
      if (dx * dx + dy * dy <= r2) {
        return true;
      }
    }
    return false;
  }

  /// Like [_pathReachesRect], but tests against the element's rotated visual
  /// rectangle rather than its broad axis-aligned culling bounds.
  static bool _pathReachesRotatedRect(
    List<Offset> path,
    Rect rect,
    double radians,
    double radius,
  ) {
    if (radians == 0) {
      return _pathReachesRect(path, rect, radius);
    }
    final Offset center = rect.center;
    return _pathReachesRect(
      <Offset>[
        for (final Offset point in path) _rotateAround(point, center, -radians),
      ],
      rect,
      radius,
    );
  }

  // ---------------------------------------------------------------------------
  // Lasso selection
  // ---------------------------------------------------------------------------

  /// Starts a freehand lasso loop at the [world] point.
  ///
  /// A replace loop snapshots the prior selection but keeps it visible while
  /// the loop is being traced. The snapshot is only replaced after a valid
  /// loop commits, and is restored if the gesture is cancelled.
  void beginLasso(Offset world) {
    _discardLasso(restoreSelection: true);
    _lassoPath = <Offset>[world];
    if (selectionMode == SelectionMode.replace) {
      _selectionBeforeReplaceLasso = Set<String>.of(_selectedIds);
    }
    _notifyOverlay();
  }

  /// Extends the in-progress lasso loop to the [world] point.
  ///
  /// A no-op when no lasso loop is active.
  void appendLasso(Offset world) {
    final List<Offset>? path = _lassoPath;
    if (path == null) {
      return;
    }
    path.add(world);
    _notifyOverlay();
  }

  /// Closes the lasso loop and selects the elements substantially inside it.
  ///
  /// The loop is auto-closed (its first vertex links back to its last). Broad
  /// phase: the spatial index is queried for the loop's bounding box. Narrow
  /// phase: each candidate is tested with an even-odd point-in-polygon rule —
  /// an ink element is selected when a majority of its centerline points fall
  /// inside the loop. A loop with too few points (an accidental tap) preserves
  /// the prior selection. Selection is held in the controller, not committed as
  /// a command.
  void endLasso() {
    final List<Offset>? path = _lassoPath;
    _lassoPath = null;
    if (path == null || path.length < 3) {
      _restoreSelectionBeforeReplaceLasso();
      _consumeSelectionMode();
      _notifySelection();
      return;
    }

    final Set<String> hits = <String>{};
    final Rect area = CanvasGeometry.boundsOfPoints(path);
    final Set<String> candidateIds = _spatialIndex.query(area).toSet();
    for (final CanvasElement element in _elements) {
      if (!_isElementEditable(element)) {
        continue;
      }
      if (!candidateIds.contains(element.id)) {
        continue;
      }
      if (_lassoSelects(element, path)) {
        hits.add(element.id);
      }
    }
    _applySelectionIds(hits, selectionMode);
    _selectionBeforeReplaceLasso = null;
    _consumeSelectionMode();
    _notifySelection();
  }

  /// Cancels an in-progress lasso loop without changing the selection.
  void cancelLasso() {
    _discardLasso(restoreSelection: true);
    _notifySelection();
  }

  void _discardLasso({required bool restoreSelection}) {
    _lassoPath = null;
    if (restoreSelection) {
      _restoreSelectionBeforeReplaceLasso();
    } else {
      _selectionBeforeReplaceLasso = null;
    }
  }

  void _restoreSelectionBeforeReplaceLasso() {
    final Set<String>? previous = _selectionBeforeReplaceLasso;
    _selectionBeforeReplaceLasso = null;
    if (previous == null) return;
    _applySelectionIds(<String>{
      for (final CanvasElement element in _elements)
        if (previous.contains(element.id) && _isElementEditable(element))
          element.id,
    }, SelectionMode.replace);
  }

  /// Whether the closed lasso [polygon] substantially encloses [element].
  ///
  /// For ink, "substantially" means a majority (> 50%) of the stroke's
  /// centerline points lie inside the polygon — so brushing the lasso past a
  /// stroke's tip does not grab it, but looping most of it does.
  ///
  /// For an image / PDF / link element the same majority rule is applied to a
  /// small fixed sample set of its placement rectangle (its four corners and
  /// its centre): the element is selected when most of those representative
  /// points fall inside the loop. This keeps mixed selections consistent — a
  /// lasso that loops a picture or a link chip grabs it just as it grabs ink.
  bool _lassoSelects(CanvasElement element, List<Offset> polygon) {
    switch (element) {
      case InkElement():
        final List<Offset> centerline = <Offset>[
          for (final StrokePoint p in element.stroke.points) p.offset,
        ];
        return CanvasGeometry.polygonCoverage(polygon, centerline) > 0.5;
      case ImageElement():
      case PdfElement():
      case LinkElement():
      case TextElement():
        return CanvasGeometry.polygonCoverage(
              polygon,
              _rotatedRectSamples(
                _placementBoundsOf(element)!,
                element.rotation,
              ),
            ) >
            0.5;
      case ShapeElement():
        return CanvasGeometry.polygonCoverage(
              polygon,
              _shapeCoverageSamples(element),
            ) >
            0.5;
    }
  }

  /// Selects the topmost editable element under [world].
  ///
  /// Returns whether an element was hit. With replace mode, tapping empty
  /// space clears the current selection; add/subtract modes leave it alone.
  bool selectElementAt(Offset world, {SelectionMode? mode}) {
    final SelectionMode effectiveMode = mode ?? selectionMode;
    final CanvasElement? hit = elementAt(
      world,
      requireEditable: true,
      requireVisible: true,
    );
    if (hit == null) {
      if (effectiveMode == SelectionMode.replace) {
        clearSelection();
      } else {
        _consumeSelectionMode();
        _notifyToolState();
      }
      return false;
    }
    _applySelectionIds(<String>{hit.id}, effectiveMode);
    _consumeSelectionMode();
    _notifySelection();
    return true;
  }

  bool _consumeSelectionMode() {
    if (selectionMode == SelectionMode.replace) {
      return false;
    }
    selectionMode = SelectionMode.replace;
    return true;
  }

  /// Returns the topmost element at [world], or `null` when none is hit.
  CanvasElement? elementAt(
    Offset world, {
    bool requireEditable = false,
    bool requireVisible = true,
  }) {
    final double slop = 10.0 / viewport.scale;
    final Set<String> candidateIds = _spatialIndex
        .query(Rect.fromCircle(center: world, radius: slop))
        .toSet();
    if (candidateIds.isEmpty) {
      return null;
    }
    for (final CanvasElement element in _elements.reversed) {
      if (!candidateIds.contains(element.id)) {
        continue;
      }
      if (requireVisible && !_isElementVisible(element)) {
        continue;
      }
      if (requireEditable && !_isElementEditable(element)) {
        continue;
      }
      if (_pointHitsElement(world, element, slop)) {
        return element;
      }
    }
    return null;
  }

  void _applySelectionIds(Set<String> ids, SelectionMode mode) {
    var changed = false;
    switch (mode) {
      case SelectionMode.replace:
        changed =
            _selectedIds.length != ids.length || !_selectedIds.containsAll(ids);
        if (changed) {
          _selectedIds
            ..clear()
            ..addAll(ids);
        }
      case SelectionMode.add:
        for (final String id in ids) {
          changed = _selectedIds.add(id) || changed;
        }
      case SelectionMode.subtract:
        for (final String id in ids) {
          changed = _selectedIds.remove(id) || changed;
        }
    }
    if (changed) {
      _markSelectionChanged();
    }
  }

  bool _pointHitsElement(Offset world, CanvasElement element, double slop) {
    switch (element) {
      case InkElement():
        if (element.stroke.tool == StrokeToolKind.fill) {
          return element.outlinePath.contains(world) ||
              CanvasGeometry.circleHitsPolyline(
                world,
                slop,
                _closedFillBoundary(element),
              );
        }
        final double reach = slop + element.stroke.width / 2;
        final List<Offset> centerline = <Offset>[
          for (final StrokePoint p in element.stroke.points) p.offset,
        ];
        return CanvasGeometry.circleHitsPolyline(world, reach, centerline);
      case ImageElement():
      case PdfElement():
      case LinkElement():
      case TextElement():
        return _pointHitsRotatedRect(
          world,
          _placementBoundsOf(element)!,
          element.rotation,
          slop,
        );
      case ShapeElement():
        return _pointHitsShape(world, element, slop);
    }
  }

  static bool _pointHitsRotatedRect(
    Offset world,
    Rect rect,
    double radians,
    double slop,
  ) {
    final Offset local = radians == 0
        ? world
        : _rotateAround(world, rect.center, -radians);
    return rect.inflate(slop).contains(local);
  }

  static Rect? _placementBoundsOf(CanvasElement element) {
    return switch (element) {
      ImageElement(:final placementBounds) => placementBounds,
      PdfElement(:final placementBounds) => placementBounds,
      LinkElement(:final placementBounds) => placementBounds,
      TextElement(:final placementBounds) => placementBounds,
      _ => null,
    };
  }

  static List<Offset> _closedFillBoundary(InkElement element) {
    final List<Offset> boundary = <Offset>[
      for (final StrokePoint point in element.stroke.points) point.offset,
    ];
    if (boundary.isNotEmpty) {
      boundary.add(boundary.first);
    }
    return boundary;
  }

  static List<Offset> _rotatedRectSamples(Rect rect, double radians) {
    final Offset center = rect.center;
    final List<Offset> corners = <Offset>[
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];
    return <Offset>[
      for (final Offset corner in corners)
        _rotateAround(corner, center, radians),
      center,
    ];
  }

  static Offset _rotateAround(Offset point, Offset origin, double radians) {
    if (radians == 0) {
      return point;
    }
    final double sin = math.sin(radians);
    final double cos = math.cos(radians);
    final double dx = point.dx - origin.dx;
    final double dy = point.dy - origin.dy;
    return Offset(
      origin.dx + dx * cos - dy * sin,
      origin.dy + dx * sin + dy * cos,
    );
  }

  /// Replaces the current selection with exactly [ids].
  ///
  /// Ids with no matching committed element are ignored. Used by the render
  /// layer for tap-to-select interactions.
  void setSelection(Iterable<String> ids) {
    final Set<String> next = <String>{
      for (final String id in ids)
        if (_elements.any(
          (CanvasElement e) => e.id == id && _isElementEditable(e),
        ))
          id,
    };
    final bool manipulationChanged = _cancelSelectionManipulation();
    if (_selectedIds.length == next.length && _selectedIds.containsAll(next)) {
      if (manipulationChanged) {
        _notifySelection();
      }
      return;
    }
    _selectedIds
      ..clear()
      ..addAll(next);
    _markSelectionChanged();
    _notifySelection();
  }

  /// Clears the current selection (e.g. on a tap in empty space).
  void clearSelection() {
    final bool modeChanged = _consumeSelectionMode();
    final bool manipulationChanged = _cancelSelectionManipulation();
    if (_selectedIds.isEmpty &&
        _lassoPath == null &&
        _selectionBeforeReplaceLasso == null &&
        !modeChanged &&
        !manipulationChanged) {
      return;
    }
    _clearSelectedIds();
    _lassoPath = null;
    _selectionBeforeReplaceLasso = null;
    _notifySelection();
  }

  /// Deletes every selected element as one undoable [RemoveElementsCommand].
  ///
  /// A no-op when nothing is selected. The selection is emptied — the deleted
  /// elements no longer exist to be selected — though an [undo] restores them
  /// (unselected).
  void deleteSelection() {
    final bool modeChanged = _consumeSelectionMode();
    final bool manipulationChanged = _cancelSelectionManipulation();
    final List<CanvasElement> selected = selectedElements;
    if (selected.isEmpty) {
      if (modeChanged || manipulationChanged) {
        _notifySelection();
      }
      return;
    }
    _runCommand(RemoveElementsCommand(selected));
    // RemoveElementsCommand.apply already pruned _selectedIds via
    // removeElementFromStore; this is just defensive.
    if (_clearSelectedIds()) {
      _notifySelection();
    }
  }

  /// Copies the current selection into the canvas-local clipboard.
  void copySelection() {
    final List<CanvasElement> selected = selectedElements;
    if (selected.isEmpty) {
      return;
    }
    _clipboardElements = List<CanvasElement>.unmodifiable(selected);
    _clipboardPasteCount = 0;
    _notifyToolState();
  }

  /// Pastes copied content as one undoable, newly selected group.
  void pasteSelection() {
    if (_clipboardElements.isEmpty) {
      return;
    }
    _clipboardPasteCount += 1;
    final Offset offset = Offset(
      24 * _clipboardPasteCount / viewport.scale,
      24 * _clipboardPasteCount / viewport.scale,
    );
    final List<CanvasElement> pasted = <CanvasElement>[
      for (var index = 0; index < _clipboardElements.length; index++)
        _copyElementForPaste(
          _clipboardElements[index],
          zIndex: _nextZIndex + index,
          offset: offset,
        ),
    ];
    _runCommand(
      ReplaceElementsCommand(removed: const <CanvasElement>[], added: pasted),
    );
    _selectedIds
      ..clear()
      ..addAll(pasted.map((CanvasElement element) => element.id));
    _markSelectionChanged();
    _notifySelection();
  }

  CanvasElement _copyElementForPaste(
    CanvasElement element, {
    required int zIndex,
    required Offset offset,
  }) {
    final String id = newId();
    final CanvasElement copy = switch (element) {
      InkElement() => element.copyWith(
        id: id,
        zIndex: zIndex,
        stroke: element.stroke.copyWith(id: id),
      ),
      ImageElement() => element.copyWith(id: id, zIndex: zIndex),
      PdfElement() => element.copyWith(id: id, zIndex: zIndex),
      LinkElement() => element.copyWith(id: id, zIndex: zIndex),
      TextElement() => element.copyWith(id: id, zIndex: zIndex),
      ShapeElement() => element.copyWith(id: id, zIndex: zIndex),
    };
    return copy.translated(offset);
  }

  /// Returns whether the [world] point lands on a currently selected element.
  ///
  /// The visible selection bounding box is draggable, including empty space
  /// between sparse selected elements. Backs the "press on the selection to
  /// drag it" interaction.
  ///
  /// Ink is hit against its centerline (a thin stroke stays grabbable via the
  /// slop); an image / PDF / link element — being a filled rectangle — is hit
  /// when the point lands inside its placement rect, grown by the same slop.
  bool selectionHitTest(Offset world) {
    if (_selectedIds.isEmpty || selectedElements.isEmpty) {
      return false;
    }
    // A small world-space slop keeps the grab area screen-constant. The whole
    // visible selection box is draggable, including empty space between sparse
    // elements in a group selection.
    final double slop = 12.0 / viewport.scale;
    final Rect? bounds = selectionBounds;
    if (bounds != null && bounds.inflate(slop).contains(world)) {
      return true;
    }
    for (final CanvasElement element in selectedElements) {
      switch (element) {
        case InkElement():
          if (element.stroke.tool == StrokeToolKind.fill) {
            if (element.outlinePath.contains(world) ||
                CanvasGeometry.circleHitsPolyline(
                  world,
                  slop,
                  _closedFillBoundary(element),
                )) {
              return true;
            }
            break;
          }
          final double reach = slop + element.stroke.width / 2;
          final List<Offset> centerline = <Offset>[
            for (final StrokePoint p in element.stroke.points) p.offset,
          ];
          if (CanvasGeometry.circleHitsPolyline(world, reach, centerline)) {
            return true;
          }
        case ImageElement():
        case PdfElement():
        case LinkElement():
        case TextElement():
          if (_pointHitsRotatedRect(
            world,
            _placementBoundsOf(element)!,
            element.rotation,
            slop,
          )) {
            return true;
          }
          break;
        case ShapeElement():
          if (_pointHitsShape(world, element, slop)) {
            return true;
          }
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Selection drag
  // ---------------------------------------------------------------------------

  /// Begins dragging the current selection.
  ///
  /// Starts a zero offset that [updateSelectionDrag] grows; the store is not
  /// touched until [endSelectionDrag] commits the move. A no-op when nothing is
  /// selected.
  void beginSelectionDrag() {
    if (_selectedIds.isEmpty) {
      return;
    }
    _clearSelectionTransformPreview();
    _selectionDragDelta = Offset.zero;
    _notifySelection();
  }

  /// Adds [worldDelta] to the in-progress selection drag.
  ///
  /// A no-op when no selection drag is active. Only the live preview offset
  /// moves — committed geometry is untouched until [endSelectionDrag].
  void updateSelectionDrag(Offset worldDelta) {
    final Offset? current = _selectionDragDelta;
    if (current == null) {
      return;
    }
    _selectionDragDelta = current + worldDelta;
    _notifySelection();
  }

  /// Finishes the selection drag, committing the move as one undoable command.
  ///
  /// A zero net move is dropped (no command, no history entry). Otherwise every
  /// selected element is translated by the accumulated delta via a
  /// [MoveElementsCommand]; the selection is preserved across the move (and its
  /// undo/redo) by [_reconcileSelectionFor].
  void endSelectionDrag() {
    final Offset? delta = _selectionDragDelta;
    _selectionDragDelta = null;
    if (delta == null || delta == Offset.zero) {
      _notifySelection();
      return;
    }
    final List<CanvasElement> originals = selectedElements;
    if (originals.isEmpty) {
      _notifySelection();
      return;
    }
    final List<CanvasElement> moved = <CanvasElement>[
      for (final CanvasElement element in originals) element.translated(delta),
    ];
    _runCommand(
      MoveElementsCommand(originals: originals, moved: moved, delta: delta),
    );
  }

  /// Cancels an in-progress selection drag, snapping it back with no command.
  void cancelSelectionDrag() {
    _selectionDragDelta = null;
    _notifySelection();
  }

  /// Begins a live scale/rotate/translate transform of the current selection.
  void beginSelectionTransform() {
    final List<CanvasElement> originals = selectedElements;
    if (originals.isEmpty) {
      return;
    }
    _selectionDragDelta = null;
    _selectionTransformOriginals = List<CanvasElement>.unmodifiable(originals);
    _selectionTransformPreview = SelectionTransformPreview(
      origin: _boundsForSelectedElements(originals)?.center ?? Offset.zero,
      translation: Offset.zero,
      scale: 1,
      rotation: 0,
    );
    _markSelectionPreviewChanged();
    _selectionTransformScale = 1;
    _selectionTransformRotation = 0;
    _selectionTransformTranslation = Offset.zero;
    _notifySelection();
  }

  /// Updates the live selection transform preview.
  void updateSelectionTransform({
    required Offset origin,
    required Offset translation,
    required double scale,
    required double rotation,
  }) {
    final List<CanvasElement>? originals = _selectionTransformOriginals;
    if (originals == null || originals.isEmpty) {
      return;
    }
    final double clampedScale = scale.clamp(0.05, 20.0).toDouble();
    _selectionTransformScale = clampedScale;
    _selectionTransformRotation = rotation;
    _selectionTransformTranslation = translation;
    _selectionTransformPreview = SelectionTransformPreview(
      origin: origin,
      translation: translation,
      scale: clampedScale,
      rotation: rotation,
    );
    _markSelectionPreviewChanged();
    _notifySelection();
  }

  /// Commits the live selection transform as one undoable command.
  void endSelectionTransform() {
    final List<CanvasElement>? captured = _selectionTransformOriginals;
    if (captured == null || captured.isEmpty) {
      _clearSelectionTransformPreview(notify: true);
      return;
    }
    final Set<String> capturedIds = <String>{
      for (final CanvasElement element in captured) element.id,
    };
    final List<CanvasElement> originals = <CanvasElement>[
      for (final CanvasElement element in _elements)
        if (capturedIds.contains(element.id) &&
            _selectedIds.contains(element.id) &&
            _isElementEditable(element))
          element,
    ];
    final SelectionTransformPreview preview = _selectionTransformPreview;
    final bool changed =
        (_selectionTransformScale - 1).abs() > 0.000001 ||
        _selectionTransformRotation.abs() > 0.000001 ||
        _selectionTransformTranslation.distance > 0.000001;
    _clearSelectionTransformPreview();
    if (!changed || originals.isEmpty) {
      _notifySelection();
      return;
    }
    final List<CanvasElement> transformed = <CanvasElement>[
      for (final CanvasElement original in originals)
        _transformElement(
          original,
          origin: preview.origin,
          translation: preview.translation,
          scale: preview.scale,
          rotation: preview.rotation,
        ),
    ];
    _runCommand(
      TransformElementsCommand(
        originals: originals,
        transformed: transformed,
        description: 'Transform',
      ),
    );
  }

  /// Cancels a live selection transform without writing geometry.
  void cancelSelectionTransform() {
    _clearSelectionTransformPreview(notify: true);
  }

  void _clearSelectionTransformPreview({bool notify = false}) {
    _selectionTransformOriginals = null;
    _selectionTransformPreview = const SelectionTransformPreview.identity();
    _markSelectionPreviewChanged();
    _selectionTransformScale = 1;
    _selectionTransformRotation = 0;
    _selectionTransformTranslation = Offset.zero;
    if (notify) {
      _notifySelection();
    }
  }

  /// Moves the current selection by a small world-space delta.
  void nudgeSelection(Offset worldDelta) {
    if (worldDelta == Offset.zero) {
      return;
    }
    final List<CanvasElement> originals = selectedElements;
    if (originals.isEmpty) {
      return;
    }
    final List<CanvasElement> moved = <CanvasElement>[
      for (final CanvasElement element in originals)
        element.translated(worldDelta),
    ];
    _runCommand(
      MoveElementsCommand(
        originals: originals,
        moved: moved,
        delta: worldDelta,
      ),
    );
  }

  /// Scales the current selection around [origin] as one undoable transform.
  ///
  /// [scaleX] and [scaleY] are clamped away from zero so a mistaken shortcut
  /// cannot collapse notes into unrecoverable geometry. When [origin] is
  /// omitted the current selection centre is used.
  void scaleSelection(double scaleX, double scaleY, {Offset? origin}) {
    final double sx = scaleX.clamp(0.05, 20.0).toDouble();
    final double sy = scaleY.clamp(0.05, 20.0).toDouble();
    if (sx == 1 && sy == 1) {
      return;
    }
    final Offset? transformOrigin = origin ?? selectionBounds?.center;
    if (transformOrigin == null) {
      return;
    }
    _transformSelection(
      description: 'Scale',
      transform: (CanvasElement element) =>
          _scaleElement(element, transformOrigin, sx, sy),
    );
  }

  /// Rotates the current selection around [origin] as one undoable transform.
  ///
  /// Rectangular content stores the rotation as element metadata. Ink and shape
  /// elements bake it into their point geometry so their existing renderers and
  /// eraser logic remain precise.
  void rotateSelection(double radians, {Offset? origin}) {
    if (radians == 0) {
      return;
    }
    final Offset? transformOrigin = origin ?? selectionBounds?.center;
    if (transformOrigin == null) {
      return;
    }
    _transformSelection(
      description: 'Rotate',
      transform: (CanvasElement element) =>
          _rotateElement(element, transformOrigin, radians),
    );
  }

  void _transformSelection({
    required String description,
    required CanvasElement Function(CanvasElement element) transform,
  }) {
    final List<CanvasElement> originals = selectedElements;
    if (originals.isEmpty) {
      return;
    }
    final List<CanvasElement> transformed = <CanvasElement>[
      for (final CanvasElement element in originals) transform(element),
    ];
    _runCommand(
      TransformElementsCommand(
        originals: originals,
        transformed: transformed,
        description: description,
      ),
    );
  }

  static CanvasElement _transformElement(
    CanvasElement element, {
    required Offset origin,
    required Offset translation,
    required double scale,
    required double rotation,
  }) {
    CanvasElement transformed = _scaleElement(element, origin, scale, scale);
    transformed = _rotateElement(transformed, origin, rotation);
    return transformed.translated(translation);
  }

  static CanvasElement _scaleElement(
    CanvasElement element,
    Offset origin,
    double scaleX,
    double scaleY,
  ) {
    final double widthScale = _averageScale(scaleX, scaleY);
    return switch (element) {
      InkElement() => element.copyWith(
        stroke: element.stroke.copyWith(
          points: <StrokePoint>[
            for (final StrokePoint point in element.stroke.points)
              _copyStrokePointAt(
                point,
                _scalePoint(point.offset, origin, scaleX, scaleY),
              ),
          ],
          width: element.stroke.width * widthScale,
        ),
      ),
      ShapeElement() => element.copyWith(
        start: _scalePoint(element.start, origin, scaleX, scaleY),
        end: _scalePoint(element.end, origin, scaleX, scaleY),
        controlPoints: <Offset>[
          for (final Offset point in element.controlPoints)
            _scalePoint(point, origin, scaleX, scaleY),
        ],
        strokeWidth: element.strokeWidth * widthScale,
      ),
      ImageElement() => element.copyWith(
        worldBounds: _scaleRect(
          element.placementBounds,
          origin,
          scaleX,
          scaleY,
        ),
      ),
      PdfElement() => element.copyWith(
        worldBounds: _scaleRect(
          element.placementBounds,
          origin,
          scaleX,
          scaleY,
        ),
      ),
      LinkElement() => element.copyWith(
        worldBounds: _scaleRect(
          element.placementBounds,
          origin,
          scaleX,
          scaleY,
        ),
      ),
      TextElement() => element.copyWith(
        worldBounds: _scaleRect(
          element.placementBounds,
          origin,
          scaleX,
          scaleY,
        ),
        fontSize: element.fontSize * widthScale,
      ),
    };
  }

  static CanvasElement _rotateElement(
    CanvasElement element,
    Offset origin,
    double radians,
  ) {
    return switch (element) {
      InkElement() => element.copyWith(
        stroke: element.stroke.copyWith(
          points: <StrokePoint>[
            for (final StrokePoint point in element.stroke.points)
              _copyStrokePointAt(
                point,
                _rotateAround(point.offset, origin, radians),
              ),
          ],
        ),
      ),
      ShapeElement() => element.copyWith(
        start: _rotateAround(element.start, origin, radians),
        end: _rotateAround(element.end, origin, radians),
        controlPoints: <Offset>[
          for (final Offset point in element.controlPoints)
            _rotateAround(point, origin, radians),
        ],
      ),
      ImageElement() => element.copyWith(
        worldBounds: _rotatePlacement(element.placementBounds, origin, radians),
        rotation: _normalizeRadians(element.rotation + radians),
      ),
      PdfElement() => element.copyWith(
        worldBounds: _rotatePlacement(element.placementBounds, origin, radians),
        rotation: _normalizeRadians(element.rotation + radians),
      ),
      LinkElement() => element.copyWith(
        worldBounds: _rotatePlacement(element.placementBounds, origin, radians),
        rotation: _normalizeRadians(element.rotation + radians),
      ),
      TextElement() => element.copyWith(
        worldBounds: _rotatePlacement(element.placementBounds, origin, radians),
        rotation: _normalizeRadians(element.rotation + radians),
      ),
    };
  }

  static Offset _scalePoint(
    Offset point,
    Offset origin,
    double scaleX,
    double scaleY,
  ) {
    return Offset(
      origin.dx + (point.dx - origin.dx) * scaleX,
      origin.dy + (point.dy - origin.dy) * scaleY,
    );
  }

  static Rect _scaleRect(
    Rect rect,
    Offset origin,
    double scaleX,
    double scaleY,
  ) {
    final Offset topLeft = _scalePoint(rect.topLeft, origin, scaleX, scaleY);
    final Offset bottomRight = _scalePoint(
      rect.bottomRight,
      origin,
      scaleX,
      scaleY,
    );
    return Rect.fromPoints(topLeft, bottomRight);
  }

  static Rect _rotatePlacement(Rect rect, Offset origin, double radians) {
    return Rect.fromCenter(
      center: _rotateAround(rect.center, origin, radians),
      width: rect.width,
      height: rect.height,
    );
  }

  static StrokePoint _copyStrokePointAt(StrokePoint point, Offset offset) {
    return StrokePoint(
      offset.dx,
      offset.dy,
      point.pressure,
      tiltX: point.tiltX,
      tiltY: point.tiltY,
      azimuth: point.azimuth,
      timestampMicros: point.timestampMicros,
      velocity: point.velocity,
    );
  }

  static double _averageScale(double scaleX, double scaleY) {
    return (scaleX.abs() + scaleY.abs()) / 2;
  }

  static double _normalizeRadians(double radians) {
    double value = radians;
    while (value <= -math.pi) {
      value += math.pi * 2;
    }
    while (value > math.pi) {
      value -= math.pi * 2;
    }
    return value;
  }

  Offset _snapWorld(Offset world) {
    if (!snapToGridEnabled || paperStyle.gridSpacing <= 0) {
      return world;
    }
    final double step = paperStyle.gridSpacing;
    return Offset(
      (world.dx / step).roundToDouble() * step,
      (world.dy / step).roundToDouble() * step,
    );
  }

  // ---------------------------------------------------------------------------
  // Shape tool
  // ---------------------------------------------------------------------------

  /// Begins a shape drag anchored at the [world] point.
  void beginShape(Offset world) {
    if (_editableActiveLayerId() == null) {
      _shapeStart = null;
      _shapeEnd = null;
      _notifyOverlay();
      return;
    }
    final Offset snapped = _snapWorld(world);
    _shapeStart = snapped;
    _shapeEnd = snapped;
    _notifyOverlay();
  }

  /// Updates the in-progress shape drag's free endpoint to [world].
  ///
  /// A no-op when no shape drag is active.
  void updateShape(Offset world) {
    if (_shapeStart == null) {
      return;
    }
    _shapeEnd = _snapWorld(world);
    _notifyOverlay();
  }

  /// Finishes the shape drag, committing the shape as an [InkElement].
  ///
  /// The shape's centerline is computed geometrically from the drag endpoints
  /// for the current [shapeKind], wrapped in a [Stroke] using the current pen
  /// colour and width, and added through an [AddElementCommand] — so the shape
  /// erases, lasso-selects, undoes and persists exactly like freehand ink. A
  /// zero-size drag (start == end) commits nothing.
  void endShape() {
    final Offset? start = _shapeStart;
    final Offset? end = _shapeEnd;
    final String? layerId = _editableActiveLayerId();
    _shapeStart = null;
    _shapeEnd = null;
    if (start == null || end == null || start == end || layerId == null) {
      _notifyOverlay();
      return;
    }

    _runCommand(
      AddElementCommand(
        ShapeElement(
          id: newId(),
          zIndex: _nextZIndex,
          layerId: layerId,
          shapeKind: shapeKind.index,
          start: start,
          end: end,
          color: penColor,
          strokeWidth: resolvedPenWidthWorld(),
          arrowBody: shapeKind == ShapeKind.arrow
              ? arrowBody
              : ArrowBodyKind.straight,
          arrowStartHead: shapeKind == ShapeKind.arrow
              ? arrowStartHead
              : ArrowHeadStyle.none,
          arrowEndHead: shapeKind == ShapeKind.arrow
              ? arrowEndHead
              : ArrowHeadStyle.none,
          arrowHeadScale: arrowHeadScale,
          legacyArrow: false,
        ),
      ),
    );
  }

  /// Cancels an in-progress shape drag without committing anything.
  void cancelShape() {
    _shapeStart = null;
    _shapeEnd = null;
    _notifyOverlay();
  }

  /// World-space centerline for [kind] spanning the drag [start]–[end].
  static List<Offset> _shapeGeometry(ShapeKind kind, Offset start, Offset end) {
    switch (kind) {
      case ShapeKind.line:
        return CanvasGeometry.linePoints(start, end);
      case ShapeKind.rectangle:
        return CanvasGeometry.rectanglePoints(start, end);
      case ShapeKind.oval:
        return CanvasGeometry.ovalPoints(start, end);
      case ShapeKind.arrow:
        return CanvasGeometry.arrowPoints(start, end);
    }
  }

  /// Builds the live preview [Stroke] for the in-progress shape drag, or
  /// `null` when no shape is being drawn.
  ///
  /// The render layer paints this on the live-stroke layer so the shape tracks
  /// the pointer before being committed. It mirrors what [endShape] will
  /// commit — same geometry, colour and width.
  Stroke? get liveShapeStroke {
    final Offset? start = _shapeStart;
    final Offset? end = _shapeEnd;
    if (start == null || end == null) {
      return null;
    }
    final List<Offset> geometry = _shapeGeometry(shapeKind, start, end);
    return Stroke(
      id: 'live-shape',
      points: <StrokePoint>[
        for (final Offset p in geometry) StrokePoint(p.dx, p.dy, 0.5),
      ],
      color: penColor,
      width: resolvedPenWidthWorld(),
      tool: StrokeToolKind.pen,
    );
  }

  /// Crisp live preview for the in-progress shape drag.
  ShapeElement? get liveShapeElement {
    final Offset? start = _shapeStart;
    final Offset? end = _shapeEnd;
    final String? layerId = _editableActiveLayerId();
    if (start == null || end == null || layerId == null) {
      return null;
    }
    return ShapeElement(
      id: 'live-shape',
      zIndex: _nextZIndex,
      layerId: layerId,
      shapeKind: shapeKind.index,
      start: start,
      end: end,
      color: penColor,
      strokeWidth: resolvedPenWidthWorld(),
      arrowBody: shapeKind == ShapeKind.arrow
          ? arrowBody
          : ArrowBodyKind.straight,
      arrowStartHead: shapeKind == ShapeKind.arrow
          ? arrowStartHead
          : ArrowHeadStyle.none,
      arrowEndHead: shapeKind == ShapeKind.arrow
          ? arrowEndHead
          : ArrowHeadStyle.none,
      arrowHeadScale: arrowHeadScale,
      legacyArrow: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Link tool
  // ---------------------------------------------------------------------------

  /// Places a new [LinkElement] chip on the canvas as one undoable command.
  ///
  /// [worldCenter] is where the user tapped (chip centre); [target] is the
  /// destination collected by the link dialog and [label] the chip text. The
  /// chip is sized so it stays visually constant at the current zoom — see
  /// [_linkPlacementRect]. Placement is one [AddElementCommand], so a link is
  /// undoable, erasable and selectable exactly like any other element.
  ///
  /// Returns the placed element so the view can, e.g., select it, or `null`
  /// when no visible, unlocked content layer can receive it.
  LinkElement? placeLink({
    required Offset worldCenter,
    required String label,
    required LinkTarget target,
  }) {
    final String? layerId = _editableActiveLayerId();
    if (layerId == null) {
      return null;
    }
    final Offset center = _snapWorld(worldCenter);
    final LinkElement element = LinkElement(
      id: newId(),
      zIndex: _nextZIndex,
      layerId: layerId,
      worldBounds: _linkPlacementRect(center),
      label: label,
      target: target,
    );
    _runCommand(AddElementCommand(element));
    return element;
  }

  /// Returns the [LinkElement] at the [world] point, or `null` if none.
  ///
  /// Used by the view to decide whether a pan-tool tap follows a link. The
  /// spatial index narrows the candidates; the topmost (highest z-index) link
  /// whose chip rectangle contains the point wins, so a link drawn over another
  /// is the one that is followed.
  LinkElement? linkAt(Offset world) {
    final Set<String> candidateIds = _spatialIndex
        .query(Rect.fromCenter(center: world, width: 1, height: 1))
        .toSet();
    if (candidateIds.isEmpty) {
      return null;
    }
    LinkElement? hit;
    // _elements is ascending z-index; the last match is the topmost link.
    for (final CanvasElement element in _elements) {
      if (!_isElementVisible(element)) {
        continue;
      }
      if (element is LinkElement &&
          candidateIds.contains(element.id) &&
          _pointHitsElement(world, element, 0)) {
        hit = element;
      }
    }
    return hit;
  }

  /// World-space placement rectangle for a link chip centred at [center].
  ///
  /// The chip uses [LinkElement.defaultChipSize] in screen pixels, converted to
  /// world units by the current viewport scale, so a freshly placed chip is the
  /// same on-screen size regardless of how far the canvas is zoomed.
  Rect _linkPlacementRect(Offset center) {
    final double s = viewport.scale;
    const Size chip = LinkElement.defaultChipSize;
    return Rect.fromCenter(
      center: center,
      width: chip.width / s,
      height: chip.height / s,
    );
  }

  // ---------------------------------------------------------------------------
  // Text tool
  // ---------------------------------------------------------------------------

  /// Places a new typed note on the canvas as one undoable command, returning
  /// `null` when no visible, unlocked content layer can receive it.
  TextElement? placeText({
    required Offset worldCenter,
    required String text,
    int? color,
    double fontSize = defaultTextFontSize,
  }) {
    final String body = text.trim();
    if (body.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Text note cannot be empty.');
    }
    final String? layerId = _editableActiveLayerId();
    if (layerId == null) {
      return null;
    }
    final Offset center = _snapWorld(worldCenter);
    final TextElement element = TextElement(
      id: newId(),
      zIndex: _nextZIndex,
      layerId: layerId,
      worldBounds: _textPlacementRect(center),
      text: body,
      color: color ?? penColor,
      fontSize: fontSize,
    );
    _runCommand(AddElementCommand(element));
    return element;
  }

  /// Replaces [element] with an updated text body as one undoable command.
  void updateTextElement(TextElement element, String text) {
    final String body = text.trim();
    if (body.isEmpty) {
      removeElements(<CanvasElement>[element]);
      return;
    }
    final TextElement updated = element.copyWith(text: body);
    _runCommand(
      ReplaceElementsCommand(
        removed: <CanvasElement>[element],
        added: <CanvasElement>[updated],
      ),
    );
  }

  /// Returns the topmost text note at [world], or `null` if none.
  TextElement? textAt(Offset world) {
    final Set<String> candidateIds = _spatialIndex
        .query(Rect.fromCenter(center: world, width: 1, height: 1))
        .toSet();
    TextElement? hit;
    for (final CanvasElement element in _elements) {
      if (!_isElementEditable(element)) {
        continue;
      }
      if (element is TextElement &&
          candidateIds.contains(element.id) &&
          _pointHitsElement(world, element, 0)) {
        hit = element;
      }
    }
    return hit;
  }

  Rect _textPlacementRect(Offset center) {
    final double s = viewport.scale;
    const Size note = TextElement.defaultNoteSize;
    return Rect.fromCenter(
      center: center,
      width: note.width / s,
      height: note.height / s,
    );
  }

  // ---------------------------------------------------------------------------
  // Viewport framing
  // ---------------------------------------------------------------------------

  /// Moves the camera so [worldRegion] is centred and comfortably framed.
  ///
  /// Used both by the bookmarks feature and by link navigation that targets a
  /// region: the viewport scale is chosen so [worldRegion] fills ~[fillFraction]
  /// of the shorter viewport edge (clamped to the engine's scale limits), and
  /// the translation is set so the region's centre lands at the viewport
  /// centre. Rotation is left at zero. A no-op for an empty region or before
  /// the view has reported its size.
  void frameRegion(Rect worldRegion, {double fillFraction = 0.8}) {
    final Size size = _viewportSize;
    if (worldRegion.isEmpty || size.isEmpty) {
      return;
    }
    final double regionEdge = worldRegion.longestSide;
    final double viewEdge = size.shortestSide * fillFraction;
    final double scale = regionEdge <= 0
        ? viewport.scale
        : CanvasTransform.clampScale(viewEdge / regionEdge);
    // With rotation 0 the screen position of a world point w is w*scale + t,
    // so to put the region centre at the viewport centre: t = c - centre*scale.
    final Offset translation =
        Offset(size.width / 2, size.height / 2) - worldRegion.center * scale;
    setViewport(ViewportState(translation: translation, scale: scale));
  }

  // ---------------------------------------------------------------------------
  // Bookmarks
  // ---------------------------------------------------------------------------

  /// The named viewport locations saved on this canvas, oldest first.
  List<Bookmark> get bookmarks => List<Bookmark>.unmodifiable(_bookmarks);

  /// Whether at least one bookmark has been saved.
  bool get hasBookmarks => _bookmarks.isNotEmpty;

  /// Saves the current [viewport] under [name] as a new [Bookmark].
  ///
  /// A blank [name] is ignored. Saving a name that already exists overwrites
  /// that bookmark's viewport rather than adding a duplicate, so re-saving "Top"
  /// just updates where "Top" points. Returns the stored [Bookmark], or `null`
  /// when [name] was blank.
  Bookmark? saveBookmark(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final Bookmark bookmark = Bookmark(name: trimmed, viewport: viewport);
    final int existing = _bookmarks.indexWhere(
      (Bookmark b) => b.name == trimmed,
    );
    if (existing >= 0) {
      _bookmarks[existing] = bookmark;
    } else {
      _bookmarks.add(bookmark);
    }
    final CanvasRepository? repo = _repository;
    final String? canvasId = _canvasId;
    if (repo != null && canvasId != null) {
      final int position = _bookmarks.indexOf(bookmark);
      _track(() => repo.upsertBookmark(canvasId, bookmark, position: position));
    }
    _notifyBookmarks();
    return bookmark;
  }

  /// Jumps the camera to [bookmark]'s saved viewport.
  void goToBookmark(Bookmark bookmark) {
    setViewport(bookmark.viewport);
  }

  /// Removes [bookmark] from the saved list. A no-op if it is not present.
  void removeBookmark(Bookmark bookmark) {
    if (_bookmarks.remove(bookmark)) {
      final CanvasRepository? repo = _repository;
      final String? canvasId = _canvasId;
      if (repo != null && canvasId != null) {
        _track(() => repo.deleteBookmark(canvasId, bookmark.name));
      }
      _notifyBookmarks();
    }
  }

  // ---------------------------------------------------------------------------
  // Image / PDF import
  // ---------------------------------------------------------------------------

  /// Whether an import (file pick + copy + decode/probe) is currently running.
  ///
  /// The toolbar disables the add-image / add-PDF actions while this is true so
  /// a second picker cannot open on top of the first.
  bool get isImporting => _isImporting;
  bool _isImporting = false;

  String? get importErrorMessage => _importErrorMessage;
  String? _importErrorMessage;

  void clearImportError() {
    if (_importErrorMessage == null) return;
    _importErrorMessage = null;
    _notifyEditorState();
  }

  /// Opens the system picker, imports a single image and places it on the
  /// canvas centred in the current viewport.
  ///
  /// The picked file is copied into the app documents directory (a stable path
  /// for persistence) and decoded; the resulting [ImageElement] carries that
  /// decoded bitmap so the picture is visible immediately. Placement is one
  /// undoable [AddElementCommand]. A cancelled picker is a silent no-op.
  Future<void> importImage() async {
    if (_disposed || _isImporting || !canCreateContent) {
      return;
    }
    _isImporting = true;
    _notifyToolState();
    ImportedImage? imported;
    var rasterTransferred = false;
    try {
      imported = await _importer.pickImage();
      if (imported == null || _disposed) {
        return;
      }
      final ImportedImage ready = imported;
      final String? layerId = _editableActiveLayerId();
      if (layerId == null) {
        return;
      }
      final Rect bounds = _placementRect(ready.intrinsicSize);
      final ImageElement element = ImageElement(
        id: newId(),
        zIndex: _nextZIndex,
        layerId: layerId,
        worldBounds: bounds,
        sourceFilePath: ready.storedPath,
        intrinsicSize: ready.intrinsicSize,
      );
      _runCommand(AddElementCommand(element));
      if (_disposed) {
        return;
      }
      var kept = true;
      _swapElement(element.id, (CanvasElement current) {
        if (current is! ImageElement) {
          kept = false;
          return current;
        }
        return current.copyWith(raster: ready.raster);
      });
      if (kept) {
        rasterTransferred = true;
        _trackRaster(ready.raster);
        _enforceRasterBudget();
      }
    } catch (error) {
      if (!_disposed) {
        debugPrint('Image import failed: $error');
        _importErrorMessage =
            'Could not import that image. Please try another file.';
      }
    } finally {
      if (imported != null && !rasterTransferred) {
        imported.raster.dispose();
      }
      if (!_disposed) {
        _isImporting = false;
        _editorStateSignal.emit();
        _notifyToolState();
      }
    }
  }

  /// Opens the system picker, imports a single PDF and places **one
  /// [PdfElement] per page** on the canvas.
  ///
  /// The PDF is copied into the app documents directory; every page becomes an
  /// element, laid out down a column from the viewport centre so a multi-page
  /// import does not stack on one spot. All pages are added as a single
  /// undoable command, so one undo removes the whole import. Each page's raster
  /// is rendered lazily afterwards (see [_scheduleVisibleRasters]); until then
  /// the painter shows a placeholder. A cancelled picker is a silent no-op.
  Future<void> importPdf() async {
    if (_disposed || _isImporting || !canCreateContent) {
      return;
    }
    _isImporting = true;
    _notifyToolState();
    try {
      final ImportedPdf? imported = await _importer.pickPdf();
      if (_disposed || imported == null || imported.pages.isEmpty) {
        return;
      }
      final String? layerId = _editableActiveLayerId();
      if (layerId == null) {
        return;
      }

      // Lay pages out top-to-bottom from the viewport centre, with a small gap.
      const double pageGap = 48.0;
      final Rect firstRect = _placementRect(imported.pages.first.size);
      double cursorTop = firstRect.top;
      final List<CanvasElement> pageElements = <CanvasElement>[];
      for (final PdfPageInfo page in imported.pages) {
        final Rect fitted = _fitRect(
          intrinsicSize: page.size,
          center: Offset.zero,
          maxEdge: firstRect.longestSide,
        );
        final Rect rect = Rect.fromLTWH(
          firstRect.center.dx - fitted.width / 2,
          cursorTop,
          fitted.width,
          fitted.height,
        );
        pageElements.add(
          PdfElement(
            id: newId(),
            zIndex: _nextZIndex + pageElements.length,
            layerId: layerId,
            worldBounds: rect,
            sourceFilePath: imported.storedPath,
            pageNumber: page.pageNumber,
            pageSize: page.size,
          ),
        );
        cursorTop += rect.height + pageGap;
      }

      _runCommand(
        ReplaceElementsCommand(
          removed: const <CanvasElement>[],
          added: pageElements,
        ),
      );
      // Kick off rasterising whatever pages landed on screen.
      _scheduleVisibleRasters();
    } catch (error) {
      if (!_disposed) {
        debugPrint('PDF import failed: $error');
        _importErrorMessage =
            'Could not import that PDF. Please try another file.';
      }
    } finally {
      if (!_disposed) {
        _isImporting = false;
        _editorStateSignal.emit();
        _notifyToolState();
      }
    }
  }

  /// World-space placement rectangle for an imported item of [intrinsicSize].
  ///
  /// Centred on the current viewport centre and sized so its longest edge is
  /// [_importDefaultWorldSize] — but never wider/taller than ~80% of the
  /// visible world rect, so a freshly imported item always fits on screen.
  /// Aspect ratio is preserved.
  Rect _placementRect(Size intrinsicSize) {
    final Rect visible = _visibleWorldRect;
    final double fitLimit =
        0.8 * (visible.width < visible.height ? visible.width : visible.height);
    final double maxEdge = fitLimit <= 0
        ? _importDefaultWorldSize
        : (_importDefaultWorldSize < fitLimit
              ? _importDefaultWorldSize
              : fitLimit);
    return _fitRect(
      intrinsicSize: intrinsicSize,
      center: visible.center,
      maxEdge: maxEdge,
    );
  }

  /// Builds a [center]-anchored rectangle whose longest edge is [maxEdge],
  /// preserving the aspect ratio of [intrinsicSize].
  static Rect _fitRect({
    required Size intrinsicSize,
    required Offset center,
    required double maxEdge,
  }) {
    final double w = intrinsicSize.width <= 0 ? 1.0 : intrinsicSize.width;
    final double h = intrinsicSize.height <= 0 ? 1.0 : intrinsicSize.height;
    final double scale = w >= h ? maxEdge / w : maxEdge / h;
    return Rect.fromCenter(center: center, width: w * scale, height: h * scale);
  }

  // ---------------------------------------------------------------------------
  // Raster cache management
  // ---------------------------------------------------------------------------

  /// Schedules raster loads for every image/PDF element currently on screen
  /// that lacks a (sharp enough) raster.
  ///
  /// The render layer calls this after a viewport change so a page scrolled
  /// into view starts rendering, and an element zoomed into gets re-rendered
  /// sharper. Only *visible* elements are scheduled — this is the mechanism
  /// that keeps PDF rasterisation viewport-bounded rather than count-bounded.
  void scheduleRasterWork() => _scheduleVisibleRasters();

  /// Internal: queues needed visible raster loads by viewport priority.
  void _scheduleVisibleRasters() {
    if (_disposed) {
      return;
    }
    final Rect visibleWorldRect = _visibleWorldRect;
    final Set<String> visibleIds = _spatialIndex
        .query(visibleWorldRect)
        .toSet();
    final int wantBucket = PdfRasterService.bucketForScale(viewport.scale);
    final Offset viewportCenter = visibleWorldRect.center;
    final List<_RasterJob> jobs = <_RasterJob>[];
    for (final CanvasElement element in _elements) {
      if (!_isElementVisible(element)) {
        continue;
      }
      if (!visibleIds.contains(element.id)) {
        continue;
      }
      final double priority = _distanceSquared(
        element.worldBounds.center,
        viewportCenter,
      );
      switch (element) {
        case InkElement():
        case LinkElement():
        case TextElement():
        case ShapeElement():
          // Vector ink and link chips have no raster — nothing to schedule.
          break;
        case ImageElement():
          if (element.raster == null) {
            jobs.add(
              _RasterJob(
                elementId: element.id,
                kind: _RasterJobKind.image,
                bucket: 0,
                priority: priority,
              ),
            );
          }
        case PdfElement():
          // (Re-)rasterise when no raster exists, or when the user has zoomed
          // into a higher resolution bucket than the cached page was rendered
          // for — a simple zoom-bucket comparison, no per-frame churn.
          final bool needsRaster =
              element.raster == null || element.rasterScaleBucket < wantBucket;
          if (needsRaster) {
            jobs.add(
              _RasterJob(
                elementId: element.id,
                kind: _RasterJobKind.pdf,
                bucket: wantBucket,
                priority: priority,
              ),
            );
          }
      }
    }
    jobs.sort((_RasterJob a, _RasterJob b) => a.priority.compareTo(b.priority));
    _rasterJobQueue
      ..clear()
      ..addAll(jobs.where((job) => !_rasterJobIsInFlight(job)));
    _drainRasterJobQueue();
  }

  /// Element ids with an image-raster decode in flight, so the same picture is
  /// not decoded twice concurrently.
  final Set<String> _imageRasterInFlight = <String>{};

  /// Element ids with a PDF page render in flight, mapped to the bucket being
  /// rendered, so stale queued work can wait for the current render to finish.
  final Map<String, int> _pdfRasterInFlight = <String, int>{};

  void _drainRasterJobQueue() {
    if (_disposed) {
      _rasterJobQueue.clear();
      return;
    }
    final Rect visibleWorldRect = _visibleWorldRect;
    var index = 0;
    while (index < _rasterJobQueue.length) {
      final _RasterJob job = _rasterJobQueue[index];
      final CanvasElement? element = _elementById(job.elementId);
      if (element == null ||
          !_isRasterJobStillNeeded(job, element, visibleWorldRect)) {
        _rasterJobQueue.removeAt(index);
        continue;
      }
      if (!_rasterJobHasCapacity(job) || _rasterJobIsInFlight(job)) {
        index += 1;
        continue;
      }
      _rasterJobQueue.removeAt(index);
      _startRasterJob(job, element);
    }
  }

  bool _rasterJobHasCapacity(_RasterJob job) {
    return switch (job.kind) {
      _RasterJobKind.image =>
        _activeImageRasterJobs < _maxConcurrentImageRasterJobs,
      _RasterJobKind.pdf => _activePdfRasterJobs < _maxConcurrentPdfRasterJobs,
    };
  }

  bool _rasterJobIsInFlight(_RasterJob job) {
    return switch (job.kind) {
      _RasterJobKind.image => _imageRasterInFlight.contains(job.elementId),
      _RasterJobKind.pdf => _pdfRasterInFlight.containsKey(job.elementId),
    };
  }

  bool _isRasterJobStillNeeded(
    _RasterJob job,
    CanvasElement element,
    Rect visibleWorldRect,
  ) {
    if (!_isElementVisible(element) ||
        !visibleWorldRect.overlaps(element.worldBounds)) {
      return false;
    }
    return switch (job.kind) {
      _RasterJobKind.image => element is ImageElement && element.raster == null,
      _RasterJobKind.pdf =>
        element is PdfElement &&
            (element.raster == null || element.rasterScaleBucket < job.bucket),
    };
  }

  void _startRasterJob(_RasterJob job, CanvasElement element) {
    switch (job.kind) {
      case _RasterJobKind.image:
        if (element is! ImageElement) {
          return;
        }
        _activeImageRasterJobs += 1;
        _imageRasterInFlight.add(job.elementId);
        unawaited(
          _loadImageRaster(element).whenComplete(() {
            if (_disposed) {
              return;
            }
            _activeImageRasterJobs = math.max(0, _activeImageRasterJobs - 1);
            _imageRasterInFlight.remove(job.elementId);
            _drainRasterJobQueue();
          }),
        );
      case _RasterJobKind.pdf:
        if (element is! PdfElement) {
          return;
        }
        _activePdfRasterJobs += 1;
        _pdfRasterInFlight[job.elementId] = job.bucket;
        unawaited(
          _loadPdfRaster(element, job.bucket).whenComplete(() {
            if (_disposed) {
              return;
            }
            _activePdfRasterJobs = math.max(0, _activePdfRasterJobs - 1);
            if (_pdfRasterInFlight[job.elementId] == job.bucket) {
              _pdfRasterInFlight.remove(job.elementId);
            }
            _drainRasterJobQueue();
          }),
        );
    }
  }

  CanvasElement? _elementById(String id) => _elementsById[id];

  static double _distanceSquared(Offset a, Offset b) {
    final double dx = a.dx - b.dx;
    final double dy = a.dy - b.dy;
    return dx * dx + dy * dy;
  }

  /// Asynchronously decodes [element]'s picture and swaps it into the store.
  ///
  /// The swap is **not** an undoable command — a raster is a runtime cache,
  /// not persistent state — so the element is replaced in place, preserving
  /// its id and bounds (and therefore its spatial-index entry, selection
  /// membership and undo history). A load that finishes after the element was
  /// removed or the canvas cleared is discarded.
  Future<void> _loadImageRaster(ImageElement element) async {
    final int epoch = _rasterEpoch;
    final ui.Image? image = await _decodeImageFile(element.sourceFilePath);
    if (image == null) {
      return;
    }
    if (epoch != _rasterEpoch || !_containsVisibleRasterElement(element.id)) {
      // The element was removed, cleared, or scrolled away while decoding. The
      // freshly-decoded image is referenced by nothing else, so disposing it
      // here is safe and reclaims its memory immediately.
      image.dispose();
      return;
    }
    var kept = true;
    _swapElement(element.id, (CanvasElement current) {
      if (current is! ImageElement || current.raster != null) {
        kept = false;
        return current;
      }
      return current.copyWith(raster: image);
    });
    if (kept) {
      _trackRaster(image);
      _enforceRasterBudget();
      _notifyElements(selectionMayChange: false, toolMayChange: false);
    } else {
      image.dispose();
    }
  }

  /// Decodes the image file at [path] into a `ui.Image`, or `null` on failure.
  static Future<ui.Image?> _decodeImageFile(String path) async {
    try {
      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromFilePath(
        path,
      );
      final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(
        buffer,
      );
      final ui.Codec codec = await descriptor.instantiateCodec();
      final ui.FrameInfo frame = await codec.getNextFrame();
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
      return frame.image;
    } on Object {
      // A missing or corrupt file just leaves the placeholder in place.
      return null;
    }
  }

  /// Asynchronously rasterises [element]'s PDF page at [bucket] and swaps the
  /// result into the store.
  ///
  /// Like [_loadImageRaster] this is an in-place, non-undoable swap. The new
  /// raster is only kept if it is at least as sharp as whatever the element
  /// already has (a slow low-res render can otherwise land after a fast
  /// high-res one). A render that finishes after a clear/removal is discarded.
  Future<void> _loadPdfRaster(PdfElement element, int bucket) async {
    final int epoch = _rasterEpoch;
    final PdfRasterResult? result;
    try {
      result = await _pdfRasterService.rasterizePage(
        filePath: element.sourceFilePath,
        pageNumber: element.pageNumber,
        scaleBucket: bucket,
      );
    } on Object {
      return;
    }
    if (result == null) {
      return;
    }
    final PdfRasterResult rendered = result;
    if (epoch != _rasterEpoch || !_containsVisibleRasterElement(element.id)) {
      rendered.image.dispose();
      return;
    }
    var kept = true;
    _swapElement(element.id, (CanvasElement current) {
      if (current is! PdfElement) {
        kept = false;
        return current;
      }
      // Reject a render that is not sharper than what is already cached.
      if (current.raster != null &&
          current.rasterScaleBucket >= rendered.scaleBucket) {
        kept = false;
        return current;
      }
      // Command history stores raster-free snapshots, so the superseded image
      // is owned only by the live store/painters and can be released now.
      final ui.Image? old = current.raster;
      if (old != null) {
        _untrackRaster(old);
        old.dispose();
      }
      return current.copyWith(
        raster: rendered.image,
        rasterScaleBucket: rendered.scaleBucket,
      );
    });
    if (kept) {
      _trackRaster(rendered.image);
      _enforceRasterBudget();
      _notifyElements(selectionMayChange: false, toolMayChange: false);
    } else {
      rendered.image.dispose();
    }
  }

  bool _containsVisibleRasterElement(String id) {
    final CanvasElement? element = _elementById(id);
    return element != null &&
        _isElementVisible(element) &&
        _visibleWorldRect.overlaps(element.worldBounds);
  }

  /// Replaces the element with [id] in place via [update], keeping z-order.
  ///
  /// Used only for runtime raster swaps: [update] must return an element with
  /// the same id and bounds, so the spatial-index entry stays valid and this
  /// never touches undo history. A no-op when [id] is absent.
  void _swapElement(
    String id,
    CanvasElement Function(CanvasElement current) update,
  ) {
    final int? index = paintOrderById[id];
    if (index == null) {
      return;
    }
    final CanvasElement current = _elements[index];
    final CanvasElement updated = update(current);
    _elements[index] = updated;
    _elementsById[id] = updated;
    _markElementsChanged(
      damageBounds: current.worldBounds.expandToInclude(updated.worldBounds),
    );
  }

  /// Adds [image]'s estimated byte size to the in-use raster total.
  void _trackRaster(ui.Image image) {
    _rasterBytesInUse += _rasterBytes(image);
  }

  static ui.Image? _elementRaster(CanvasElement element) {
    return switch (element) {
      ImageElement(:final raster) => raster,
      PdfElement(:final raster) => raster,
      _ => null,
    };
  }

  void _disposeElementRaster(CanvasElement element) {
    final ui.Image? raster = _elementRaster(element);
    if (raster == null) {
      return;
    }
    _untrackRaster(raster);
    raster.dispose();
  }

  /// Subtracts [image]'s estimated byte size from the in-use raster total.
  void _untrackRaster(ui.Image image) {
    _rasterBytesInUse -= _rasterBytes(image);
    if (_rasterBytesInUse < 0) {
      _rasterBytesInUse = 0;
    }
  }

  /// Estimated decoded size of [image] in bytes (4 bytes per pixel, RGBA).
  static int _rasterBytes(ui.Image image) => image.width * image.height * 4;

  /// Drops rasters from off-screen image/PDF elements until total raster
  /// memory is back under [_rasterBudgetBytes].
  ///
  /// On-screen elements are never evicted (their pixels are needed this
  /// frame); an evicted element keeps all of its persistent state and simply
  /// re-rasterises from its source file when it scrolls back into view.
  ///
  /// Command history stores raster-free snapshots, so evicted `ui.Image`s are
  /// disposed immediately and the element in the store is replaced with its
  /// durable metadata-only form.
  void _enforceRasterBudget() {
    if (_rasterBytesInUse <= _rasterBudgetBytes) {
      return;
    }
    final Set<String> visibleIds = _spatialIndex
        .query(_visibleWorldRect)
        .toSet();
    for (
      var i = 0;
      i < _elements.length && _rasterBytesInUse > _rasterBudgetBytes;
      i++
    ) {
      final CanvasElement element = _elements[i];
      if (visibleIds.contains(element.id)) {
        continue;
      }
      switch (element) {
        case InkElement():
        case LinkElement():
        case TextElement():
        case ShapeElement():
          // No raster to evict.
          break;
        case ImageElement():
          final ui.Image? raster = element.raster;
          if (raster != null) {
            _untrackRaster(raster);
            raster.dispose();
            final ImageElement cleared = element.copyWith(clearRaster: true);
            _elements[i] = cleared;
            _elementsById[element.id] = cleared;
            _markElementsChanged(damageBounds: element.worldBounds);
          }
        case PdfElement():
          final ui.Image? raster = element.raster;
          if (raster != null) {
            _untrackRaster(raster);
            raster.dispose();
            final PdfElement cleared = element.copyWith(clearRaster: true);
            _elements[i] = cleared;
            _elementsById[element.id] = cleared;
            _markElementsChanged(damageBounds: element.worldBounds);
          }
      }
    }
  }

  /// Disposes every decoded raster currently held by an element.
  ///
  /// Called from [dispose]; also bumps [_rasterEpoch] so any raster load still
  /// in flight discards its result instead of touching a dead controller.
  void _disposeAllRasters() {
    _rasterEpoch++;
    _rasterJobQueue.clear();
    _imageRasterInFlight.clear();
    _pdfRasterInFlight.clear();
    _activeImageRasterJobs = 0;
    _activePdfRasterJobs = 0;
    for (final CanvasElement element in _elements) {
      _disposeElementRaster(element);
    }
    _rasterBytesInUse = 0;
  }

  /// Releases the PDF service and every decoded raster, then tears down the
  /// listener list.
  ///
  /// [_disposeAllRasters] bumps [_rasterEpoch], so any raster load still in
  /// flight fails its post-await epoch check and discards its result rather
  /// than mutating the dead store or calling [notifyListeners].
  ///
  /// Persistence writes are **not** awaited here — the editor page calls
  /// [flush] before disposing so every pending write has already landed. The
  /// debounced viewport-save timer is cancelled so it cannot fire post-dispose;
  /// callers that skip [flush] simply lose an undebounced final viewport.
  @override
  void dispose() {
    _disposed = true;
    _viewportSaveTimer?.cancel();
    _viewportSaveTimer = null;
    _toolSettingsSaveTimer?.cancel();
    _toolSettingsSaveTimer = null;
    _disposeAllRasters();
    // Fire-and-forget: closing pooled PDFium handles need not block teardown.
    unawaited(_pdfRasterService.dispose());
    _editorStateSignal.dispose();
    _viewportSignal.dispose();
    _elementsSignal.dispose();
    _liveStrokeSignal.dispose();
    _selectionSignal.dispose();
    _overlaySignal.dispose();
    _toolStateSignal.dispose();
    _canvasStyleSignal.dispose();
    _bookmarksSignal.dispose();
    super.dispose();
  }
}
