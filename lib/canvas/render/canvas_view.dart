import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/engine/canvas_transform.dart';
import 'package:zenno/canvas/input/pointer_classifier.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/render/canvas_overlay_painter.dart';
import 'package:zenno/canvas/render/elements_painter.dart';
import 'package:zenno/canvas/render/grid_painter.dart';
import 'package:zenno/canvas/render/live_stroke_painter.dart';

/// A pointer currently in contact with (or hovering over) the canvas.
///
/// Tracks the pointer's [kind] so the input model can route it — a finger
/// transforms the viewport, a stylus and a mouse both follow the active tool —
/// and its latest [position] in surface-local coordinates so per-move deltas
/// can be computed.
class _ActivePointer {
  _ActivePointer({required this.kind, required this.position});

  /// The canvas-relevant category of this pointer.
  final CanvasInputKind kind;

  /// The pointer's most recent surface-local position.
  Offset position;
}

/// The interactive infinite-canvas surface.
///
/// Renders four stacked [CustomPaint] layers — grid, committed elements, live
/// stroke and overlay — and translates raw pointer events into [controller]
/// mutations. The committed-elements layer is viewport-culled via the
/// controller's spatial index. The input model is fixed: a **finger always
/// pans/pinches** (the palm-rejection guarantee), while a **stylus and a mouse
/// both follow [CanvasController.activeTool]** — drawing, erasing, lassoing,
/// drawing a shape or placing a link per the selected tool. Scroll-wheel
/// signals zoom around the cursor.
///
/// Two interactions are surfaced as callbacks rather than handled inline,
/// because they involve a dialog or route navigation that belongs to the host
/// page: [onPlaceLink] fires when the link tool is tapped (the host collects
/// the link's label/target and calls back into the controller), and
/// [onFollowLink] fires when the **pan** tool taps an existing link chip (the
/// host pushes the destination route).
class CanvasView extends StatefulWidget {
  /// Creates a canvas view driven by [controller].
  const CanvasView({
    required this.controller,
    this.onPlaceLink,
    this.onFollowLink,
    super.key,
  });

  /// The state and command surface for this canvas.
  final CanvasController controller;

  /// Called when the link tool is tapped, with the world-space tap point —
  /// the centre of the link chip to place. `null` disables link placement.
  final void Function(Offset worldCenter)? onPlaceLink;

  /// Called when the pan tool taps an existing [LinkElement] chip. `null`
  /// disables link following (the tap then does nothing).
  final void Function(LinkElement link)? onFollowLink;

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

/// What an active tool pointer (stylus / tool-following mouse) is doing for
/// the duration of one press-drag-release on the canvas.
///
/// The gesture is classified once on pointer-down from
/// [CanvasController.activeTool] and the press location, then every subsequent
/// move and the pointer-up route to the matching controller methods. Touch
/// pointers never take a [_ToolGesture] — they always transform the viewport.
enum _ToolGesture {
  /// Drawing a freehand ink stroke (pen tool).
  draw,

  /// Erasing — whole elements or vector fragments per the eraser mode.
  erase,

  /// Tracing a freehand lasso selection loop.
  lasso,

  /// Dragging the existing lasso selection to a new position.
  moveSelection,

  /// Defining a geometric shape by its two drag endpoints.
  shape,

  /// Panning the viewport (mouse / stylus pan tool). A pan gesture that ends
  /// as a tap on a link chip instead *follows* the link.
  pan,

  /// Placing a link chip — a tap with the link tool. Committed on pointer-up
  /// (when the press did not turn into a drag) via [CanvasView.onPlaceLink].
  placeLink,
}

class _CanvasViewState extends State<CanvasView> {
  /// All pointers currently down on (or hovering over) the surface.
  final Map<int, _ActivePointer> _pointers = <int, _ActivePointer>{};

  /// Viewport state at the last raster-scheduling pass.
  ///
  /// Used to detect a camera change between builds: when the viewport differs
  /// from this, image/PDF rasters are re-scheduled (a page scrolled into view
  /// starts rendering; an element zoomed into is re-rasterised sharper).
  ViewportState? _lastRasterViewport;

  /// Pointer id currently driving a tool gesture, or `null`.
  ///
  /// At most one tool gesture runs at a time: a second stylus/mouse press is
  /// ignored until the first lifts. The kind of gesture is in [_toolGesture].
  int? _toolPointerId;

  /// The gesture [_toolPointerId] is performing, or `null` when no tool
  /// gesture is active.
  _ToolGesture? _toolGesture;

  /// Whether [_toolPointerId] has moved since pressing down.
  ///
  /// A press-release with no movement is treated as a tap — used so a tap in
  /// empty space with the lasso tool clears the selection, the link tool
  /// places a chip, and the pan tool follows a link chip.
  bool _toolPointerMoved = false;

  /// Surface-local position where the active tool pointer pressed down.
  ///
  /// Held so a press-release with no movement (a tap) can be resolved to a
  /// world point on pointer-up for the link-place / link-follow gestures.
  Offset? _toolPointerDownPosition;

  /// Viewport captured when a two-finger pinch began.
  ViewportState? _pinchStartViewport;

  /// Gesture focal point captured when a two-finger pinch began.
  Offset? _pinchStartMidpoint;

  /// Distance between the two pinch fingers captured when the pinch began.
  double? _pinchStartDistance;

  /// Angle of the pinch finger vector captured when the pinch began.
  double? _pinchStartAngle;

  CanvasController get _controller => widget.controller;

  /// Surface-local positions of every touch pointer currently down.
  List<Offset> get _touchPositions => <Offset>[
    for (final pointer in _pointers.values)
      if (pointer.kind == CanvasInputKind.touch) pointer.position,
  ];

  /// Maps a surface-local [local] point into world space.
  Offset _toWorld(Offset local) =>
      CanvasTransform.toWorld(_controller.viewport, local);

  // ---------------------------------------------------------------------------
  // Pointer handlers
  // ---------------------------------------------------------------------------

  void _onPointerDown(PointerDownEvent event) {
    final kind = classifyPointer(event);
    _pointers[event.pointer] = _ActivePointer(
      kind: kind,
      position: event.localPosition,
    );

    // A finger always transforms the viewport — never draws or erases. This is
    // the palm-rejection guarantee: a resting palm reports as touch.
    if (kind == CanvasInputKind.touch) {
      _syncTouchGesture();
      return;
    }

    // A stylus always follows the active tool; a mouse follows it too.
    final bool followsTool =
        kind == CanvasInputKind.stylus || kind == CanvasInputKind.mouse;
    if (!followsTool || _toolPointerId != null) {
      return;
    }

    _toolPointerId = event.pointer;
    _toolPointerMoved = false;
    _toolPointerDownPosition = event.localPosition;
    _toolGesture = _beginToolGesture(event);
  }

  /// Classifies and starts the tool gesture for a fresh tool-pointer press.
  ///
  /// Dispatches on [CanvasController.activeTool]; the lasso tool additionally
  /// decides between dragging an existing selection (press lands on it) and
  /// tracing a new loop. Returns the [_ToolGesture] now in progress.
  _ToolGesture _beginToolGesture(PointerDownEvent event) {
    final Offset world = _toWorld(event.localPosition);
    switch (_controller.activeTool) {
      case CanvasTool.pan:
        // A pan press that ends without moving, on a link chip, follows the
        // link — see `_finishToolGesture`. Until then it is a normal pan.
        return _ToolGesture.pan;
      case CanvasTool.pen:
        _controller.beginStroke(world, normalizedPressure(event));
        return _ToolGesture.draw;
      case CanvasTool.eraser:
        _controller.beginErase(world);
        return _ToolGesture.erase;
      case CanvasTool.shape:
        _controller.beginShape(world);
        return _ToolGesture.shape;
      case CanvasTool.lasso:
        // Pressing on the current selection drags it; pressing elsewhere
        // starts a new loop (and a tap on empty space clears it on up).
        if (_controller.selectionHitTest(world)) {
          _controller.beginSelectionDrag();
          return _ToolGesture.moveSelection;
        }
        _controller.beginLasso(world);
        return _ToolGesture.lasso;
      case CanvasTool.link:
        // A link chip is placed on pointer-up (a tap); the press itself does
        // nothing so a drag with the link tool is harmless.
        return _ToolGesture.placeLink;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    final pointer = _pointers[event.pointer];
    if (pointer == null) {
      return;
    }
    final Offset previous = pointer.position;
    pointer.position = event.localPosition;

    if (event.pointer == _toolPointerId) {
      _toolPointerMoved = true;
      _routeToolMove(event, previous);
      return;
    }

    if (pointer.kind == CanvasInputKind.touch) {
      final touches = _touchPositions;
      if (touches.length == 1) {
        _controller.panBy(event.localPosition - previous);
      } else if (touches.length >= 2) {
        _applyPinch(touches[0], touches[1]);
      }
    }
  }

  /// Routes a move of the active tool pointer to the controller per
  /// [_toolGesture].
  void _routeToolMove(PointerMoveEvent event, Offset previous) {
    final Offset world = _toWorld(event.localPosition);
    switch (_toolGesture) {
      case _ToolGesture.draw:
        _controller.appendToStroke(world, normalizedPressure(event));
      case _ToolGesture.erase:
        _controller.appendErase(world);
      case _ToolGesture.lasso:
        _controller.appendLasso(world);
      case _ToolGesture.shape:
        _controller.updateShape(world);
      case _ToolGesture.moveSelection:
        // The drag delta is the world-space displacement of this move; it must
        // account for the current viewport (not just a screen delta).
        _controller.updateSelectionDrag(world - _toWorld(previous));
      case _ToolGesture.pan:
        _controller.panBy(event.localPosition - previous);
      case _ToolGesture.placeLink:
        // Placing a link is a tap; movement is ignored (the chip is committed
        // at the press point on pointer-up).
        break;
      case null:
        break;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _endPointer(event.pointer);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _endPointer(event.pointer, cancelled: true);
  }

  /// Tears down state for [pointerId] on pointer up or cancel.
  ///
  /// When [cancelled] the in-progress tool gesture is abandoned with no
  /// undoable command; otherwise it is committed.
  void _endPointer(int pointerId, {bool cancelled = false}) {
    final pointer = _pointers.remove(pointerId);

    if (pointerId == _toolPointerId) {
      _finishToolGesture(cancelled: cancelled);
      _toolPointerId = null;
      _toolGesture = null;
      _toolPointerDownPosition = null;
    }
    if (pointer?.kind == CanvasInputKind.touch) {
      _syncTouchGesture();
    }
  }

  /// Commits (or, when [cancelled], discards) the in-progress tool gesture.
  void _finishToolGesture({required bool cancelled}) {
    // A tap (no movement) with the lasso tool clears any selection — the loop
    // is too small for `endLasso` to select anything anyway, so treat the tap
    // on empty space as "deselect". A drag still goes through `endLasso`.
    if (_toolGesture == _ToolGesture.lasso && !cancelled && !_toolPointerMoved) {
      _controller.cancelLasso();
      _controller.clearSelection();
      return;
    }

    switch (_toolGesture) {
      case _ToolGesture.draw:
        if (cancelled) {
          _controller.cancelStroke();
        } else {
          _controller.endStroke();
        }
      case _ToolGesture.erase:
        if (cancelled) {
          _controller.cancelErase();
        } else {
          _controller.endErase();
        }
      case _ToolGesture.lasso:
        if (cancelled) {
          _controller.cancelLasso();
        } else {
          _controller.endLasso();
        }
      case _ToolGesture.shape:
        if (cancelled) {
          _controller.cancelShape();
        } else {
          _controller.endShape();
        }
      case _ToolGesture.moveSelection:
        if (cancelled) {
          _controller.cancelSelectionDrag();
        } else {
          _controller.endSelectionDrag();
        }
      case _ToolGesture.placeLink:
        // A genuine tap (no drag, not cancelled) places a link at the press
        // point; the host page collects the chip's label and target.
        if (!cancelled && !_toolPointerMoved) {
          _emitLinkPlacement();
        }
      case _ToolGesture.pan:
        // A pan that never moved is a tap: if it landed on a link chip, follow
        // the link. A real pan drag falls through and does nothing here.
        if (!cancelled && !_toolPointerMoved) {
          _maybeFollowLinkAtTap();
        }
      case null:
        break;
    }
  }

  /// Reports a link-placement tap to [CanvasView.onPlaceLink].
  void _emitLinkPlacement() {
    final Offset? down = _toolPointerDownPosition;
    final void Function(Offset)? callback = widget.onPlaceLink;
    if (down == null || callback == null) {
      return;
    }
    callback(_toWorld(down));
  }

  /// Follows a link chip when the pan tool tapped one, via
  /// [CanvasView.onFollowLink].
  void _maybeFollowLinkAtTap() {
    final Offset? down = _toolPointerDownPosition;
    final void Function(LinkElement)? callback = widget.onFollowLink;
    if (down == null || callback == null) {
      return;
    }
    final LinkElement? link = _controller.linkAt(_toWorld(down));
    if (link != null) {
      callback(link);
    }
  }

  void _onPointerHover(PointerHoverEvent event) {
    final kind = classifyPointer(event);
    if (kind == CanvasInputKind.stylus || kind == CanvasInputKind.mouse) {
      _controller.setHoverPoint(_toWorld(event.localPosition));
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }
    final double factor = event.scrollDelta.dy < 0 ? 1.15 : 1 / 1.15;
    _controller.setViewport(
      CanvasTransform.zoomAround(
        current: _controller.viewport,
        focusScreen: event.localPosition,
        scaleFactor: factor,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Gesture helpers
  // ---------------------------------------------------------------------------

  /// Snapshots the pinch baseline whenever two or more touches are down.
  ///
  /// Single-touch panning uses per-move deltas and needs no snapshot, so this
  /// only acts once a second finger lands (or re-baselines when one lifts).
  void _syncTouchGesture() {
    final touches = _touchPositions;
    if (touches.length < 2) {
      _pinchStartViewport = null;
      _pinchStartMidpoint = null;
      _pinchStartDistance = null;
      _pinchStartAngle = null;
      return;
    }
    final Offset a = touches[0];
    final Offset b = touches[1];
    _pinchStartViewport = _controller.viewport;
    _pinchStartMidpoint = (a + b) / 2;
    _pinchStartDistance = (b - a).distance;
    _pinchStartAngle = math.atan2(b.dy - a.dy, b.dx - a.dx);
  }

  /// Applies the live pinch defined by the first two touches [a] and [b].
  void _applyPinch(Offset a, Offset b) {
    final ViewportState? startViewport = _pinchStartViewport;
    final Offset? startMidpoint = _pinchStartMidpoint;
    final double? startDistance = _pinchStartDistance;
    final double? startAngle = _pinchStartAngle;
    if (startViewport == null ||
        startMidpoint == null ||
        startDistance == null ||
        startAngle == null ||
        startDistance == 0) {
      return;
    }

    final Offset currentMidpoint = (a + b) / 2;
    final double currentDistance = (b - a).distance;
    final double currentAngle = math.atan2(b.dy - a.dy, b.dx - a.dx);

    _controller.setViewport(
      CanvasTransform.interactiveUpdate(
        start: startViewport,
        anchorScreenAtStart: startMidpoint,
        currentFocusScreen: currentMidpoint,
        scaleFactor: currentDistance / startDistance,
        rotationDelta: currentAngle - startAngle,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  /// Keeps the controller's viewport size current and (re)schedules raster
  /// work whenever the camera or the viewport size has changed.
  ///
  /// Run from `build` via a post-frame callback so it never mutates the
  /// controller mid-build: a viewport change pulls newly-visible image/PDF
  /// elements into rasterisation, and a zoom-in re-rasterises PDF pages
  /// sharper. Image/PDF raster loads are the only viewport-driven async work;
  /// scheduling is cheap (a spatial-index query) and idempotent.
  void _syncRasterScheduling(Size size) {
    _controller.setViewportSize(size);
    final ViewportState viewport = _controller.viewport;
    if (_lastRasterViewport != viewport) {
      _lastRasterViewport = viewport;
      _controller.scheduleRasterWork();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: ClipRect(
        child: Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          onPointerHover: _onPointerHover,
          onPointerSignal: _onPointerSignal,
          child: MouseRegion(
            onExit: (_) => _controller.setHoverPoint(null),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final ViewportState viewport = _controller.viewport;
                final bool eraserActive =
                    _controller.activeTool == CanvasTool.eraser;
                // Defer raster scheduling to after this frame so the
                // controller is never mutated while building.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _syncRasterScheduling(context.size ?? Size.zero);
                  }
                });
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: GridPainter(viewport: viewport),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: ElementsPainter(
                          elements: _controller.elements,
                          spatialIndex: _controller.spatialIndex,
                          viewport: viewport,
                          selectedIds: _controller.selectedIds,
                          selectionDragDelta: _controller.selectionDragDelta,
                        ),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        // Freehand ink and the in-progress shape preview share
                        // the live layer — only one is ever non-null at once.
                        painter: LiveStrokePainter(
                          liveStroke: _controller.liveStroke ??
                              _controller.liveShapeStroke,
                          viewport: viewport,
                        ),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: CanvasOverlayPainter(
                          viewport: viewport,
                          hoverPointWorld: _controller.hoverPointWorld,
                          hoverRadius: eraserActive
                              ? _controller.eraserRadius
                              : _controller.penWidth,
                          isEraserHover: eraserActive,
                          eraserPath: _controller.eraserPath,
                          eraserRadius: _controller.eraserRadius,
                          lassoPath: _controller.lassoPath,
                          selectionBounds: _controller.selectionBounds,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
