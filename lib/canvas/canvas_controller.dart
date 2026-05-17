import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:zenno/canvas/engine/canvas_commands.dart';
import 'package:zenno/canvas/engine/canvas_transform.dart';
import 'package:zenno/canvas/engine/spatial_index.dart';
import 'package:zenno/canvas/io/canvas_import.dart';
import 'package:zenno/canvas/model/canvas_bookmark.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/pdf/pdf_raster_service.dart';
import 'package:zenno/canvas/persistence/canvas_repository.dart';
import 'package:zenno/canvas/tools/canvas_geometry.dart';
import 'package:zenno/core/util/id.dart';

/// The active canvas interaction tool.
///
/// The setting decides what a stylus (and a mouse) do on press-drag: a finger
/// always transforms the viewport (pan / pinch / rotate) regardless — see
/// `CanvasView` for the routing.
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
}

/// How the eraser tool removes ink.
enum EraserMode {
  /// Deletes every whole element the eraser path crosses.
  object,

  /// Splits crossed ink strokes, keeping the untouched sub-strokes as vector
  /// fragments. Never rasterises.
  partial,
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
class CanvasController extends ChangeNotifier implements ElementStore {
  /// Creates a canvas controller.
  ///
  /// With both [repository] and [canvasId] supplied the controller persists to
  /// SQLite — call [load] once after construction to hydrate it. Omitting
  /// either keeps the controller fully in-memory (the Phase-1-and-earlier
  /// behaviour); the two are an all-or-nothing pair.
  CanvasController({CanvasRepository? repository, String? canvasId})
    : assert(
        (repository == null) == (canvasId == null),
        'repository and canvasId must be supplied together, or neither.',
      ),
      _repository = repository,
      _canvasId = canvasId;

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

  /// Pending debounced viewport-save timer, or `null` when none is scheduled.
  Timer? _viewportSaveTimer;

  /// In-flight persistence futures, awaited by [flush] so the editor page can
  /// guarantee every write has hit SQLite before it disposes.
  final Set<Future<void>> _pendingWrites = <Future<void>>{};

  final List<Future<void> Function()> _failedWrites =
      <Future<void> Function()>[];
  Object? _saveError;

  /// Latest persistence error, if a canvas write failed.
  Object? get saveError => _saveError;

  /// Whether there are failed writes the user can retry.
  bool get hasSaveError => _saveError != null;

  /// The camera through which the world is observed.
  ViewportState viewport = ViewportState.initial;

  /// Committed elements, kept sorted ascending by [CanvasElement.zIndex]
  /// (back to front). Mutated only via [addElementToStore] /
  /// [removeElementFromStore], which keep [_spatialIndex] in sync.
  final List<CanvasElement> _elements = <CanvasElement>[];

  /// Viewport-culling index over [_elements], keyed by element id.
  final SpatialIndex _spatialIndex = SpatialIndex();

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
      List<CanvasElement>.unmodifiable(_elements);

  /// The spatial index over the committed elements, for viewport culling.
  ///
  /// Exposed read-only for the render layer; callers must not mutate it
  /// directly — the controller keeps it consistent with [elements].
  SpatialIndex get spatialIndex => _spatialIndex;

  /// The stroke currently being drawn, or `null` when nothing is in progress.
  ///
  /// The live stroke is not yet a [CanvasElement]; it becomes an [InkElement]
  /// only when [endStroke] commits it.
  Stroke? liveStroke;

  /// The active interaction tool. Drawing always starts as [CanvasTool.pen].
  CanvasTool activeTool = CanvasTool.pen;

  /// Packed ARGB colour applied to new strokes. Defaults to opaque white.
  int penColor = 0xFFFFFFFF;

  /// On-screen width (logical px at `scale == 1`) applied to new strokes.
  double penWidth = 4.0;

  /// The ink tool kind applied to new strokes.
  StrokeToolKind penKind = StrokeToolKind.pen;

  /// Whether the eraser deletes whole elements or splits strokes into vector
  /// fragments. See [EraserMode].
  EraserMode eraserMode = EraserMode.object;

  /// On-screen radius (logical px at `scale == 1`) of the eraser footprint.
  double eraserRadius = 14.0;

  /// The shape primitive [CanvasTool.shape] currently produces.
  ShapeKind shapeKind = ShapeKind.line;

  /// World-space position of the stylus hover indicator, or `null`.
  Offset? hoverPointWorld;

  /// Renders imported PDF pages to `ui.Image`s on a background path.
  ///
  /// Created lazily on the first import and disposed with the controller; the
  /// importer and the PDF raster scheduler both borrow it.
  final PdfRasterService _pdfRasterService = PdfRasterService();

  /// Picks media files (image / PDF) and stages them for the canvas.
  late final CanvasImporter _importer = CanvasImporter(
    pdfRasterService: _pdfRasterService,
  );

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

  /// Soft ceiling on total decoded raster memory across all elements.
  ///
  /// ~96 MB of `ui.Image` pixels. Past this, off-screen image/PDF rasters are
  /// dropped (and their `ui.Image`s disposed) oldest-first; they re-rasterise
  /// from the source file when scrolled back into view. Keeps the canvas
  /// inside a sane memory envelope on a mid-range tablet.
  static const int _rasterBudgetBytes = 96 * 1024 * 1024;

  /// Default longest-edge world size for a freshly imported element.
  ///
  /// The imported picture / PDF page is placed at this size (preserving aspect
  /// ratio) unless the viewport is small, in which case it is scaled to fit.
  static const double _importDefaultWorldSize = 720.0;

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

  /// World-space anchor of an in-progress shape drag, or `null`.
  Offset? _shapeStart;

  /// World-space current point of an in-progress shape drag, or `null`.
  Offset? _shapeEnd;

  /// World-space accumulated offset of an in-progress selection drag, or
  /// `null` when the selection is not being dragged. Live drag feedback only —
  /// the store is mutated once, on pointer-up, via [MoveElementsCommand].
  Offset? _selectionDragDelta;

  /// Named viewport locations saved on this canvas, newest last.
  ///
  /// In-memory in Phase 1 — step 1.7 persists these to the `bookmarks` table.
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
  Set<String> get selectedIds => Set<String>.unmodifiable(_selectedIds);

  /// Whether at least one element is currently selected.
  bool get hasSelection => _selectedIds.isNotEmpty;

  /// Live world-space offset of an in-progress selection drag, or [Offset.zero]
  /// when the selection is not being dragged.
  Offset get selectionDragDelta => _selectionDragDelta ?? Offset.zero;

  /// Whether a selection is currently being dragged.
  bool get isDraggingSelection => _selectionDragDelta != null;

  /// The committed elements that are currently selected, in paint order.
  List<CanvasElement> get selectedElements => <CanvasElement>[
    for (final CanvasElement e in _elements)
      if (_selectedIds.contains(e.id)) e,
  ];

  /// World-space bounding box enclosing every selected element, or `null` when
  /// nothing is selected. Reflects any in-progress [selectionDragDelta].
  Rect? get selectionBounds {
    Rect? bounds;
    for (final CanvasElement element in _elements) {
      if (!_selectedIds.contains(element.id)) {
        continue;
      }
      bounds = bounds == null
          ? element.worldBounds
          : bounds.expandToInclude(element.worldBounds);
    }
    if (bounds == null) {
      return null;
    }
    return bounds.shift(selectionDragDelta);
  }

  // ---------------------------------------------------------------------------
  // ElementStore — the mutation surface used by CanvasCommands.
  // ---------------------------------------------------------------------------

  @override
  List<CanvasElement> get currentElements =>
      List<CanvasElement>.unmodifiable(_elements);

  @override
  void addElementToStore(CanvasElement element) {
    // Idempotent: a command replay must not duplicate an element.
    for (final CanvasElement existing in _elements) {
      if (existing.id == element.id) {
        return;
      }
    }
    // Insert keeping the list sorted ascending by zIndex.
    var insertAt = _elements.length;
    for (var i = 0; i < _elements.length; i++) {
      if (_elements[i].zIndex > element.zIndex) {
        insertAt = i;
        break;
      }
    }
    _elements.insert(insertAt, element);
    _spatialIndex.insert(element.id, element.worldBounds);

    // Keep the z-index allocator ahead of every committed element.
    if (element.zIndex >= _nextZIndex) {
      _nextZIndex = element.zIndex + 1;
    }

    // Write-through: an add (including a redo, or the re-add half of a move)
    // upserts the element. Skipped while [load] is hydrating the store.
    _persistUpsert(element);
  }

  @override
  void removeElementFromStore(String id) {
    final int index = _elements.indexWhere((CanvasElement e) => e.id == id);
    if (index < 0) {
      return;
    }
    _elements.removeAt(index);
    _spatialIndex.remove(id);
    // Keep the selection consistent: a removed element can no longer be
    // selected. (A MoveElementsCommand removes-then-re-adds with the same id,
    // so it re-selects itself below via _reconcileSelection.)
    _selectedIds.remove(id);

    // Write-through: a remove (including an undo, or the remove half of a
    // move) deletes the element row. A move's immediately-following re-add
    // re-inserts it; the net effect is a position update. Skipped during load.
    _persistDelete(id);
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

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
    // The library normally creates the canvas row first; make the editor
    // self-sufficient when reached directly so element/viewport FKs hold.
    await repo.ensureCanvasExists(canvasId);

    final List<CanvasElement> loaded = await repo.loadElements(canvasId);
    final ViewportState? savedViewport = await repo.loadViewport(canvasId);
    if (_disposed) {
      return;
    }

    _hydrating = true;
    try {
      for (final CanvasElement element in loaded) {
        addElementToStore(element);
      }
    } finally {
      _hydrating = false;
    }
    if (savedViewport != null) {
      viewport = savedViewport;
    }
    _isLoaded = true;
    notifyListeners();
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
    _track(() => repo.upsertElement(canvasId, element));
  }

  /// Deletes the element [id] via the repository, if persistence is enabled.
  ///
  /// A no-op while hydrating or for an in-memory controller. A move removes
  /// then immediately re-adds an id — the re-add's upsert lands after this
  /// delete, so the row survives the move with updated geometry.
  void _persistDelete(String id) {
    final CanvasRepository? repo = _repository;
    if (_hydrating || repo == null) {
      return;
    }
    _track(() => repo.deleteElement(id));
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
    final retries = List<Future<void> Function()>.of(_failedWrites);
    _failedWrites.clear();
    _saveError = null;
    notifyListeners();
    for (final retry in retries) {
      _track(retry);
    }
    await flush();
  }

  /// Dismisses the visible save error without dropping retry information.
  void dismissSaveError() {
    _saveError = null;
    notifyListeners();
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
            notifyListeners();
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
    command.apply(this);
    _undoStack.add(command);
    _redoStack.clear();
    _reconcileSelectionFor(command);
    notifyListeners();
  }

  /// Reverses the most recently applied command, moving it onto the redo stack.
  ///
  /// A no-op when [canUndo] is false.
  void undo() {
    if (_undoStack.isEmpty) {
      return;
    }
    final CanvasCommand command = _undoStack.removeLast();
    command.revert(this);
    _redoStack.add(command);
    _recomputeNextZIndex();
    _reconcileSelectionFor(command);
    notifyListeners();
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
    command.apply(this);
    _undoStack.add(command);
    _reconcileSelectionFor(command);
    notifyListeners();
  }

  /// Repairs the selection after [command] ran (forward or reverse).
  ///
  /// [removeElementFromStore] drops removed ids from [_selectedIds] as it goes,
  /// so after a `MoveElementsCommand` — which removes then re-adds elements
  /// under the same ids — the moved elements would be left unselected. Here the
  /// moved ids are re-selected (only those still present in [_elements]) so a
  /// selection survives undo/redo of its own move and stays draggable.
  void _reconcileSelectionFor(CanvasCommand command) {
    if (command is! MoveElementsCommand) {
      return;
    }
    for (final CanvasElement element in command.moved) {
      if (_elements.any((CanvasElement e) => e.id == element.id)) {
        _selectedIds.add(element.id);
      }
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
  void beginStroke(Offset world, double pressure) {
    liveStroke = Stroke(
      id: newId(),
      points: <StrokePoint>[StrokePoint(world.dx, world.dy, pressure)],
      color: penColor,
      width: penWidth,
      tool: penKind,
    );
    notifyListeners();
  }

  /// Appends a sample at the [world] point with [pressure] to [liveStroke].
  ///
  /// A no-op when no stroke is in progress.
  void appendToStroke(Offset world, double pressure) {
    final Stroke? stroke = liveStroke;
    if (stroke == null) {
      return;
    }
    stroke.points.add(StrokePoint(world.dx, world.dy, pressure));
    notifyListeners();
  }

  /// Commits the in-progress [liveStroke] to the canvas as an [InkElement].
  ///
  /// A stroke with at least one point is wrapped in an [InkElement] and added
  /// through an [AddElementCommand], so the commit is undoable. The
  /// [liveStroke] is always cleared.
  void endStroke() {
    final Stroke? stroke = liveStroke;
    liveStroke = null;
    if (stroke != null && stroke.points.isNotEmpty) {
      final InkElement element = InkElement.fromStroke(
        stroke,
        zIndex: _nextZIndex,
      );
      _runCommand(AddElementCommand(element));
      return;
    }
    notifyListeners();
  }

  /// Discards the in-progress [liveStroke] without committing it.
  void cancelStroke() {
    liveStroke = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Viewport
  // ---------------------------------------------------------------------------

  /// Replaces the viewport with [next].
  ///
  /// Schedules a debounced persist of the new camera (a no-op in memory-only
  /// mode) — so the canvas reopens framed where it was left.
  void setViewport(ViewportState next) {
    viewport = next;
    _scheduleViewportSave();
    notifyListeners();
  }

  /// Pans the viewport by [screenDelta] screen pixels.
  void panBy(Offset screenDelta) {
    viewport = CanvasTransform.panBy(viewport, screenDelta);
    _scheduleViewportSave();
    notifyListeners();
  }

  /// Resets the viewport to [ViewportState.initial].
  void resetView() {
    viewport = ViewportState.initial;
    _scheduleViewportSave();
    notifyListeners();
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

  // ---------------------------------------------------------------------------
  // Tools
  // ---------------------------------------------------------------------------

  /// Sets the active interaction tool.
  ///
  /// Switching away from the lasso clears any active selection and discards an
  /// in-progress lasso loop, so a stale selection box never lingers under an
  /// unrelated tool.
  void setTool(CanvasTool tool) {
    activeTool = tool;
    if (tool != CanvasTool.lasso) {
      _selectedIds.clear();
      _lassoPath = null;
    }
    notifyListeners();
  }

  /// Sets how the eraser removes ink (whole elements vs. vector fragments).
  void setEraserMode(EraserMode mode) {
    eraserMode = mode;
    notifyListeners();
  }

  /// Sets the on-screen radius of the eraser footprint.
  void setEraserRadius(double radius) {
    eraserRadius = radius;
    notifyListeners();
  }

  /// Sets the shape primitive the shape tool produces.
  void setShapeKind(ShapeKind kind) {
    shapeKind = kind;
    notifyListeners();
  }

  /// Sets the packed ARGB colour applied to new strokes.
  void setPenColor(int color) {
    penColor = color;
    notifyListeners();
  }

  /// Sets the on-screen width applied to new strokes.
  void setPenWidth(double width) {
    penWidth = width;
    notifyListeners();
  }

  /// Sets the ink tool kind applied to new strokes.
  void setPenKind(StrokeToolKind kind) {
    penKind = kind;
    notifyListeners();
  }

  /// Sets the stylus hover indicator position, or clears it with `null`.
  void setHoverPoint(Offset? world) {
    hoverPointWorld = world;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Edits
  // ---------------------------------------------------------------------------

  /// Removes the given [elements] from the canvas as one undoable command.
  ///
  /// A no-op when [elements] is empty. Backs the object eraser / lasso-delete
  /// in later steps.
  void removeElements(Iterable<CanvasElement> elements) {
    final List<CanvasElement> list = elements.toList(growable: false);
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
    liveStroke = null;
    _selectedIds.clear();
    if (_elements.isEmpty) {
      notifyListeners();
      return;
    }
    _runCommand(ClearCommand());
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
    notifyListeners();
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
    notifyListeners();
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
      notifyListeners();
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
    notifyListeners();
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
      notifyListeners();
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
          ),
        );
      }
    }

    if (removed.isEmpty) {
      notifyListeners();
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
        return _pathReachesRect(path, element.worldBounds, worldRadius);
    }
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

  // ---------------------------------------------------------------------------
  // Lasso selection
  // ---------------------------------------------------------------------------

  /// Starts a freehand lasso loop at the [world] point.
  ///
  /// Beginning a new loop clears any prior selection so the gesture starts
  /// fresh.
  void beginLasso(Offset world) {
    _lassoPath = <Offset>[world];
    _selectedIds.clear();
    notifyListeners();
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
    notifyListeners();
  }

  /// Closes the lasso loop and selects the elements substantially inside it.
  ///
  /// The loop is auto-closed (its first vertex links back to its last). Broad
  /// phase: the spatial index is queried for the loop's bounding box. Narrow
  /// phase: each candidate is tested with an even-odd point-in-polygon rule —
  /// an ink element is selected when a majority of its centerline points fall
  /// inside the loop. A loop with too few points (an accidental tap) selects
  /// nothing. Selection is held in the controller, not committed as a command.
  void endLasso() {
    final List<Offset>? path = _lassoPath;
    _lassoPath = null;
    if (path == null || path.length < 3) {
      notifyListeners();
      return;
    }

    _selectedIds.clear();
    final Rect area = CanvasGeometry.boundsOfPoints(path);
    final Set<String> candidateIds = _spatialIndex.query(area).toSet();
    for (final CanvasElement element in _elements) {
      if (!candidateIds.contains(element.id)) {
        continue;
      }
      if (_lassoSelects(element, path)) {
        _selectedIds.add(element.id);
      }
    }
    notifyListeners();
  }

  /// Cancels an in-progress lasso loop without changing the selection.
  void cancelLasso() {
    _lassoPath = null;
    notifyListeners();
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
        final Rect r = element.worldBounds;
        final List<Offset> samples = <Offset>[
          r.topLeft,
          r.topRight,
          r.bottomLeft,
          r.bottomRight,
          r.center,
        ];
        return CanvasGeometry.polygonCoverage(polygon, samples) > 0.5;
    }
  }

  /// Replaces the current selection with exactly [ids].
  ///
  /// Ids with no matching committed element are ignored. Used by the render
  /// layer for tap-to-select interactions.
  void setSelection(Iterable<String> ids) {
    _selectedIds
      ..clear()
      ..addAll(
        ids.where(
          (String id) => _elements.any((CanvasElement e) => e.id == id),
        ),
      );
    notifyListeners();
  }

  /// Clears the current selection (e.g. on a tap in empty space).
  void clearSelection() {
    if (_selectedIds.isEmpty && _lassoPath == null) {
      return;
    }
    _selectedIds.clear();
    _lassoPath = null;
    notifyListeners();
  }

  /// Deletes every selected element as one undoable [RemoveElementsCommand].
  ///
  /// A no-op when nothing is selected. The selection is emptied — the deleted
  /// elements no longer exist to be selected — though an [undo] restores them
  /// (unselected).
  void deleteSelection() {
    final List<CanvasElement> selected = selectedElements;
    if (selected.isEmpty) {
      return;
    }
    _runCommand(RemoveElementsCommand(selected));
    // RemoveElementsCommand.apply already pruned _selectedIds via
    // removeElementFromStore; this is just defensive.
    _selectedIds.clear();
    notifyListeners();
  }

  /// Returns whether the [world] point lands on a currently selected element.
  ///
  /// A precise hit so a drag started inside the selection bounding box but off
  /// every stroke still falls through to (e.g.) a fresh lasso. Backs the
  /// "press on the selection to drag it" interaction.
  ///
  /// Ink is hit against its centerline (a thin stroke stays grabbable via the
  /// slop); an image / PDF / link element — being a filled rectangle — is hit
  /// when the point lands inside its placement rect, grown by the same slop.
  bool selectionHitTest(Offset world) {
    if (_selectedIds.isEmpty) {
      return false;
    }
    // A small world-space slop so thin strokes remain easy to grab.
    final double slop = 12.0 / viewport.scale;
    for (final CanvasElement element in selectedElements) {
      switch (element) {
        case InkElement():
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
          if (element.worldBounds.inflate(slop).contains(world)) {
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
    _selectionDragDelta = Offset.zero;
    notifyListeners();
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
    notifyListeners();
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
      notifyListeners();
      return;
    }
    final List<CanvasElement> originals = selectedElements;
    if (originals.isEmpty) {
      notifyListeners();
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
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Shape tool
  // ---------------------------------------------------------------------------

  /// Begins a shape drag anchored at the [world] point.
  void beginShape(Offset world) {
    _shapeStart = world;
    _shapeEnd = world;
    notifyListeners();
  }

  /// Updates the in-progress shape drag's free endpoint to [world].
  ///
  /// A no-op when no shape drag is active.
  void updateShape(Offset world) {
    if (_shapeStart == null) {
      return;
    }
    _shapeEnd = world;
    notifyListeners();
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
    _shapeStart = null;
    _shapeEnd = null;
    if (start == null || end == null || start == end) {
      notifyListeners();
      return;
    }

    final List<Offset> geometry = _shapeGeometry(shapeKind, start, end);
    final Stroke stroke = Stroke(
      id: newId(),
      points: <StrokePoint>[
        for (final Offset p in geometry) StrokePoint(p.dx, p.dy, 0.5),
      ],
      color: penColor,
      width: penWidth,
      tool: StrokeToolKind.pen,
    );
    _runCommand(
      AddElementCommand(InkElement.fromStroke(stroke, zIndex: _nextZIndex)),
    );
  }

  /// Cancels an in-progress shape drag without committing anything.
  void cancelShape() {
    _shapeStart = null;
    _shapeEnd = null;
    notifyListeners();
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
      width: penWidth,
      tool: StrokeToolKind.pen,
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
  /// Returns the placed element so the view can, e.g., select it.
  LinkElement placeLink({
    required Offset worldCenter,
    required String label,
    required LinkTarget target,
  }) {
    final LinkElement element = LinkElement(
      id: newId(),
      zIndex: _nextZIndex,
      worldBounds: _linkPlacementRect(worldCenter),
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
      if (element is LinkElement &&
          candidateIds.contains(element.id) &&
          element.worldBounds.contains(world)) {
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
    notifyListeners();
    return bookmark;
  }

  /// Jumps the camera to [bookmark]'s saved viewport.
  void goToBookmark(Bookmark bookmark) {
    setViewport(bookmark.viewport);
  }

  /// Removes [bookmark] from the saved list. A no-op if it is not present.
  void removeBookmark(Bookmark bookmark) {
    if (_bookmarks.remove(bookmark)) {
      notifyListeners();
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

  /// Opens the system picker, imports a single image and places it on the
  /// canvas centred in the current viewport.
  ///
  /// The picked file is copied into the app documents directory (a stable path
  /// for persistence) and decoded; the resulting [ImageElement] carries that
  /// decoded bitmap so the picture is visible immediately. Placement is one
  /// undoable [AddElementCommand]. A cancelled picker is a silent no-op.
  Future<void> importImage() async {
    if (_isImporting) {
      return;
    }
    _isImporting = true;
    notifyListeners();
    try {
      final ImportedImage? imported = await _importer.pickImage();
      if (imported == null) {
        return;
      }
      final Rect bounds = _placementRect(imported.intrinsicSize);
      _trackRaster(imported.raster);
      _runCommand(
        AddElementCommand(
          ImageElement(
            id: newId(),
            zIndex: _nextZIndex,
            worldBounds: bounds,
            sourceFilePath: imported.storedPath,
            intrinsicSize: imported.intrinsicSize,
            raster: imported.raster,
          ),
        ),
      );
      _enforceRasterBudget();
    } finally {
      _isImporting = false;
      notifyListeners();
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
    if (_isImporting) {
      return;
    }
    _isImporting = true;
    notifyListeners();
    try {
      final ImportedPdf? imported = await _importer.pickPdf();
      if (imported == null || imported.pages.isEmpty) {
        return;
      }

      // Lay pages out top-to-bottom from the viewport centre, with a small gap.
      const double pageGap = 48.0;
      final Rect firstRect = _placementRect(imported.pages.first.size);
      double cursorTop = firstRect.top;
      final List<CanvasElement> pageElements = <CanvasElement>[];
      for (final PdfPageInfo page in imported.pages) {
        final Rect rect = _fitRect(
          intrinsicSize: page.size,
          center: Offset(firstRect.center.dx, cursorTop + firstRect.height / 2),
          maxEdge: firstRect.longestSide,
        );
        pageElements.add(
          PdfElement(
            id: newId(),
            zIndex: _nextZIndex + pageElements.length,
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
    } finally {
      _isImporting = false;
      notifyListeners();
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

  /// Internal: walks the visible elements and starts any needed raster load.
  void _scheduleVisibleRasters() {
    if (_disposed) {
      return;
    }
    final Set<String> visibleIds = _spatialIndex
        .query(_visibleWorldRect)
        .toSet();
    final int wantBucket = PdfRasterService.bucketForScale(viewport.scale);
    for (final CanvasElement element in _elements) {
      if (!visibleIds.contains(element.id)) {
        continue;
      }
      switch (element) {
        case InkElement():
        case LinkElement():
          // Vector ink and link chips have no raster — nothing to schedule.
          break;
        case ImageElement():
          if (element.raster == null) {
            _loadImageRaster(element);
          }
        case PdfElement():
          // (Re-)rasterise when no raster exists, or when the user has zoomed
          // into a higher resolution bucket than the cached page was rendered
          // for — a simple zoom-bucket comparison, no per-frame churn.
          final bool needsRaster =
              element.raster == null || element.rasterScaleBucket < wantBucket;
          if (needsRaster) {
            _loadPdfRaster(element, wantBucket);
          }
      }
    }
  }

  /// Element ids with an image-raster decode in flight, so the same picture is
  /// not decoded twice concurrently.
  final Set<String> _imageRasterInFlight = <String>{};

  /// Asynchronously decodes [element]'s picture and swaps it into the store.
  ///
  /// The swap is **not** an undoable command — a raster is a runtime cache,
  /// not persistent state — so the element is replaced in place, preserving
  /// its id and bounds (and therefore its spatial-index entry, selection
  /// membership and undo history). A load that finishes after the element was
  /// removed or the canvas cleared is discarded.
  Future<void> _loadImageRaster(ImageElement element) async {
    if (_imageRasterInFlight.contains(element.id)) {
      return;
    }
    _imageRasterInFlight.add(element.id);
    final int epoch = _rasterEpoch;
    try {
      final ui.Image? image = await _decodeImageFile(element.sourceFilePath);
      if (image == null) {
        return;
      }
      if (epoch != _rasterEpoch || !_containsId(element.id)) {
        // The element was removed, or the canvas cleared, while decoding. The
        // freshly-decoded image is referenced by nothing else, so disposing it
        // here is safe and reclaims its memory immediately.
        image.dispose();
        return;
      }
      var kept = true;
      _swapElement(element.id, (CanvasElement current) {
        if (current is! ImageElement) {
          kept = false;
          return current;
        }
        return current.copyWith(raster: image);
      });
      if (kept) {
        _trackRaster(image);
        _enforceRasterBudget();
        notifyListeners();
      } else {
        image.dispose();
      }
    } finally {
      _imageRasterInFlight.remove(element.id);
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

  /// Element ids with a PDF page render in flight, mapped to the bucket being
  /// rendered, so a higher-resolution request can still supersede a lower one.
  final Map<String, int> _pdfRasterInFlight = <String, int>{};

  /// Asynchronously rasterises [element]'s PDF page at [bucket] and swaps the
  /// result into the store.
  ///
  /// Like [_loadImageRaster] this is an in-place, non-undoable swap. The new
  /// raster is only kept if it is at least as sharp as whatever the element
  /// already has (a slow low-res render can otherwise land after a fast
  /// high-res one). A render that finishes after a clear/removal is discarded.
  Future<void> _loadPdfRaster(PdfElement element, int bucket) async {
    final int? inFlight = _pdfRasterInFlight[element.id];
    if (inFlight != null && inFlight >= bucket) {
      return;
    }
    _pdfRasterInFlight[element.id] = bucket;
    final int epoch = _rasterEpoch;
    try {
      final PdfRasterResult? result = await _pdfRasterService.rasterizePage(
        filePath: element.sourceFilePath,
        pageNumber: element.pageNumber,
        scaleBucket: bucket,
      );
      if (result == null) {
        return;
      }
      if (epoch != _rasterEpoch || !_containsId(element.id)) {
        result.image.dispose();
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
            current.rasterScaleBucket >= result.scaleBucket) {
          kept = false;
          return current;
        }
        // Drop the superseded raster's byte count but do NOT dispose it: an
        // older element instance still carrying that `ui.Image` may be held
        // by a command on the undo stack (e.g. a MoveElementsCommand snapshot
        // taken while it was current). Disposing it here would leave that
        // command pointing at a freed image. The Flutter engine GC-finalises
        // an unreferenced `ui.Image`, so the native memory is still reclaimed.
        final ui.Image? old = current.raster;
        if (old != null) {
          _untrackRaster(old);
        }
        return current.copyWith(
          raster: result.image,
          rasterScaleBucket: result.scaleBucket,
        );
      });
      if (kept) {
        _trackRaster(result.image);
        _enforceRasterBudget();
        notifyListeners();
      } else {
        result.image.dispose();
      }
    } finally {
      if (_pdfRasterInFlight[element.id] == bucket) {
        _pdfRasterInFlight.remove(element.id);
      }
    }
  }

  /// Whether an element with [id] is still present in the store.
  bool _containsId(String id) => _elements.any((CanvasElement e) => e.id == id);

  /// Replaces the element with [id] in place via [update], keeping z-order.
  ///
  /// Used only for runtime raster swaps: [update] must return an element with
  /// the same id and bounds, so the spatial-index entry stays valid and this
  /// never touches undo history. A no-op when [id] is absent.
  void _swapElement(
    String id,
    CanvasElement Function(CanvasElement current) update,
  ) {
    final int index = _elements.indexWhere((CanvasElement e) => e.id == id);
    if (index < 0) {
      return;
    }
    _elements[index] = update(_elements[index]);
  }

  /// Adds [image]'s estimated byte size to the in-use raster total.
  void _trackRaster(ui.Image image) {
    _rasterBytesInUse += _rasterBytes(image);
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
  /// The evicted `ui.Image` is **not** explicitly disposed: the same off-screen
  /// element instance may still be referenced by a command on the undo stack,
  /// so freeing the image here would leave that command holding a dead handle.
  /// The element in the store is replaced with a raster-free copy, dropping the
  /// *store's* reference; once no command references the old instance either,
  /// the Flutter engine GC-finalises the `ui.Image` and reclaims its memory.
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
          // No raster to evict.
          break;
        case ImageElement():
          final ui.Image? raster = element.raster;
          if (raster != null) {
            _untrackRaster(raster);
            _elements[i] = element.copyWith(clearRaster: true);
          }
        case PdfElement():
          final ui.Image? raster = element.raster;
          if (raster != null) {
            _untrackRaster(raster);
            _elements[i] = element.copyWith(clearRaster: true);
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
    for (final CanvasElement element in _elements) {
      switch (element) {
        case InkElement():
        case LinkElement():
          // No raster to dispose.
          break;
        case ImageElement():
          element.raster?.dispose();
        case PdfElement():
          element.raster?.dispose();
      }
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
    _disposeAllRasters();
    // Fire-and-forget: closing pooled PDFium handles need not block teardown.
    unawaited(_pdfRasterService.dispose());
    super.dispose();
  }
}
