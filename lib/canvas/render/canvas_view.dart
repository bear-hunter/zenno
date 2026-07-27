import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/engine/canvas_transform.dart';
import 'package:zenno/canvas/input/pen_input_processor.dart';
import 'package:zenno/canvas/input/pen_profile.dart';
import 'package:zenno/canvas/input/pointer_classifier.dart';
import 'package:zenno/canvas/input/stylus_button_mapping.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/render/canvas_overlay_painter.dart';
import 'package:zenno/canvas/render/elements_painter.dart';
import 'package:zenno/canvas/render/grid_painter.dart';
import 'package:zenno/canvas/render/live_stroke_painter.dart';
import 'package:zenno/canvas/render/selection_overlay_geometry.dart';

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
/// controller's spatial index. The input model is fixed around flow: a finger
/// normally pans/pinches the viewport, but when content is selected fingers can
/// directly move, scale, and rotate that selection. A stylus and mouse follow
/// [CanvasController.activeTool] — drawing, erasing, lassoing, drawing a shape
/// or placing a link per the selected tool. Scroll-wheel signals zoom around
/// the cursor.
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
    this.onEditText,
    this.onShowQuickTools,
    this.stylusButtonMapping = const StylusButtonMapping(),
    this.penProfile = const PenProfile(),
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

  /// Called when the text tool is tapped, with an existing note when the tap
  /// hit one or `null` plus the world-space tap point for creating a new note.
  final void Function(Offset worldCenter, TextElement? existing)? onEditText;

  /// Called at a surface-local point when a stylus side-button tap is mapped
  /// to [StylusButtonAction.radialMenu].
  final ValueChanged<Offset>? onShowQuickTools;

  /// User-configured stylus-button behavior.
  final StylusButtonMapping stylusButtonMapping;

  /// User-configured capture profile for new pen strokes.
  final PenProfile penProfile;

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

  /// Creating or editing a typed text note.
  editText,
}

/// Deferred one-pointer manipulation of an existing selection.
///
/// A session begins on pointer-down, but does not start an undoable controller
/// preview until movement crosses [CanvasController.tapSlop].
class _SelectionPointerSession {
  _SelectionPointerSession({
    required this.target,
    required this.downLocal,
    required this.geometry,
  }) : previousLocal = downLocal;

  final SelectionOverlayTarget target;
  final Offset downLocal;
  final SelectionOverlayGeometry geometry;
  Offset previousLocal;
  bool activated = false;
  Offset? transformOriginWorld;
  double? scaleStartDistance;
  Offset? rotationCenterLocal;
  double? rotationStartAngle;
}

class _CanvasViewState extends State<CanvasView> {
  final ElementsTileCache _elementsTileCache = ElementsTileCache();
  final LiveStrokePathCache _liveStrokePathCache = LiveStrokePathCache();

  /// All pointers currently down on (or hovering over) the surface.
  final Map<int, _ActivePointer> _pointers = <int, _ActivePointer>{};
  final Map<int, Offset> _touchDownPositions = <int, Offset>{};
  final Set<int> _movedTouchPointers = <int>{};
  int _touchShortcutPointerCount = 0;
  bool _touchShortcutDisqualified = false;
  Timer? _longPressTimer;
  Timer? _stylusLongPressTimer;
  Timer? _stylusButtonHoldTimer;
  int? _longPressLassoPointerId;
  final Set<int> _selectionTransformTouchPointers = <int>{};
  Offset? _selectionTransformStartMidpoint;
  double? _selectionTransformStartDistance;
  double? _selectionTransformStartAngle;
  Offset? _selectionTransformOriginWorld;

  /// Viewport state at the last raster-scheduling pass.
  ///
  /// Used to detect a camera change between builds: when the viewport differs
  /// from this, image/PDF rasters are re-scheduled (a page scrolled into view
  /// starts rendering; an element zoomed into is re-rasterised sharper).
  ViewportState? _lastRasterViewport;
  Size? _lastRasterSize;
  Size? _pendingRasterSyncSize;
  bool _rasterSyncScheduled = false;

  /// Pointer id currently driving a tool gesture, or `null`.
  ///
  /// At most one tool gesture runs at a time: a second stylus/mouse press is
  /// ignored until the first lifts. The kind of gesture is in [_toolGesture].
  int? _toolPointerId;

  /// The gesture [_toolPointerId] is performing, or `null` when no tool
  /// gesture is active.
  _ToolGesture? _toolGesture;
  StylusButtonAction? _stylusButtonDragAction;
  bool _toolGestureUsesTemporaryTool = false;
  bool _stylusLongPressToolActive = false;
  _SelectionPointerSession? _selectionPointerSession;
  Set<String>? _selectionBeforeBackgroundGesture;

  /// Whether [_toolPointerId] has moved since pressing down.
  ///
  /// A press-release with no movement is treated as a tap — used so a tap in
  /// empty space with the lasso tool clears the selection, the link tool
  /// places a chip, and the pan tool follows a link chip.
  bool _toolPointerMoved = false;
  PenInputProcessor? _penInputProcessor;

  /// Surface-local position where the active tool pointer pressed down.
  ///
  /// Held so a press-release with no movement (a tap) can be resolved to a
  /// world point on pointer-up for the link-place / link-follow gestures.
  Offset? _toolPointerDownPosition;

  /// Latest surface-local position of the active tool pointer.
  Offset? _toolPointerUpPosition;

  /// Viewport captured when a two-finger pinch began.
  ViewportState? _pinchStartViewport;

  /// Gesture focal point captured when a two-finger pinch began.
  Offset? _pinchStartMidpoint;

  /// Distance between the two pinch fingers captured when the pinch began.
  double? _pinchStartDistance;

  /// Angle of the pinch finger vector captured when the pinch began.
  double? _pinchStartAngle;

  CanvasController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.setPenProfile(widget.penProfile, notify: false);
  }

  @override
  void didUpdateWidget(covariant CanvasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.penProfile != widget.penProfile) {
      _controller.setPenProfile(widget.penProfile, notify: false);
      _penInputProcessor = PenInputProcessor(widget.penProfile);
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _stylusLongPressTimer?.cancel();
    _stylusButtonHoldTimer?.cancel();
    if (_selectionTransformTouchPointers.isNotEmpty) {
      _controller.cancelSelectionTransform();
    }
    if (_toolPointerId != null) {
      _finishToolGesture(cancelled: true);
    } else if (_toolGestureUsesTemporaryTool) {
      _restoreTemporaryTool();
    }
    if (_longPressLassoPointerId != null) {
      _controller.cancelLasso();
    }
    _elementsTileCache.dispose();
    _liveStrokePathCache.clear();
    super.dispose();
  }

  /// Surface-local positions of every touch pointer currently down.
  List<Offset> get _touchPositions => <Offset>[
    for (final pointer in _pointers.values)
      if (pointer.kind == CanvasInputKind.touch) pointer.position,
  ];

  /// Maps a surface-local [local] point into world space.
  Offset _toWorld(Offset local) =>
      CanvasTransform.toWorld(_controller.viewport, local);

  SelectionOverlayGeometry? get _selectionOverlayGeometry {
    final Rect? bounds = _controller.selectionBounds;
    final RenderObject? renderObject = context.findRenderObject();
    if (bounds == null ||
        bounds.isEmpty ||
        renderObject is! RenderBox ||
        !renderObject.hasSize) {
      return null;
    }
    return SelectionOverlayGeometry.fromWorldBounds(
      bounds: bounds,
      viewport: _controller.viewport,
      canvasSize: renderObject.size,
    );
  }

  // ---------------------------------------------------------------------------
  // Pointer handlers
  // ---------------------------------------------------------------------------

  void _onPointerDown(PointerDownEvent event) {
    final kind = classifyPointer(event);
    _pointers[event.pointer] = _ActivePointer(
      kind: kind,
      position: event.localPosition,
    );

    // A finger normally transforms the viewport — never draws or erases. When
    // it starts on a selected element, however, it manipulates that selection
    // directly.
    if (kind == CanvasInputKind.touch) {
      if (_toolPointerId != null) {
        if (_toolGesture == _ToolGesture.moveSelection &&
            _pointers[_toolPointerId]?.kind == CanvasInputKind.touch) {
          _beginSelectionTouchTransform();
        }
        return;
      }
      if (_tryBeginTouchSelectionDrag(event)) {
        return;
      }
      if (_touchDownPositions.isEmpty) {
        _touchShortcutPointerCount = 0;
        _touchShortcutDisqualified = false;
      }
      _touchDownPositions[event.pointer] = event.localPosition;
      _touchShortcutPointerCount = math.max(
        _touchShortcutPointerCount,
        _touchDownPositions.length,
      );
      _scheduleLongPressLasso(event.pointer, event.localPosition);
      _syncTouchGesture();
      return;
    }

    // Secondary and middle mouse clicks are platform/context actions, not
    // canvas tool presses.
    if (kind == CanvasInputKind.mouse && event.buttons != kPrimaryMouseButton) {
      return;
    }

    // A stylus always follows the active tool; a primary mouse press does too.
    final bool followsTool =
        kind == CanvasInputKind.stylus || kind == CanvasInputKind.mouse;
    if (!followsTool || _toolPointerId != null) {
      return;
    }

    _toolPointerId = event.pointer;
    _toolPointerMoved = false;
    _toolPointerDownPosition = event.localPosition;
    _toolPointerUpPosition = event.localPosition;
    if (kind == CanvasInputKind.stylus && hasStylusButton(event.buttons)) {
      _stylusButtonDragAction = widget.stylusButtonMapping.drag;
      _toolGestureUsesTemporaryTool = _pushTemporaryToolFor(
        _stylusButtonDragAction!,
      );
      if (_toolGestureUsesTemporaryTool) {
        _toolGesture = _beginToolGesture(event);
      } else {
        _toolGesture = null;
      }
      _scheduleStylusButtonHold(event.pointer);
      return;
    }
    if (_tryBeginPrimarySelectionSession(event)) {
      return;
    }
    _toolGesture = _beginToolGesture(event);
    if (kind == CanvasInputKind.stylus && !hasStylusButton(event.buttons)) {
      _scheduleStylusLongPress(event.pointer, event.localPosition);
    }
  }

  bool _tryBeginPrimarySelectionSession(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.invertedStylus ||
        !_controller.hasSelection) {
      return false;
    }
    final SelectionOverlayGeometry? geometry = _selectionOverlayGeometry;
    if (geometry == null) {
      return false;
    }
    final SelectionOverlayTarget target = geometry.hitTest(event.localPosition);

    // Add/subtract are explicit selection-modification modes. They must keep
    // tracing even when the press begins over the current selection body.
    if (_controller.selectionMode != SelectionMode.replace &&
        (target == SelectionOverlayTarget.body ||
            target == SelectionOverlayTarget.outside)) {
      _controller.beginLasso(_toWorld(event.localPosition));
      _toolGesture = _ToolGesture.lasso;
      return true;
    }

    _selectionPointerSession = _SelectionPointerSession(
      target: target,
      downLocal: event.localPosition,
      geometry: geometry,
    );
    _toolGesture = null;
    return true;
  }

  bool _tryBeginTouchSelectionDrag(PointerDownEvent event) {
    if (_selectionTransformTouchPointers.isNotEmpty ||
        !_controller.selectionHitTest(_toWorld(event.localPosition))) {
      return false;
    }
    _toolPointerId = event.pointer;
    _toolPointerMoved = false;
    _toolPointerDownPosition = event.localPosition;
    _toolPointerUpPosition = event.localPosition;
    _toolGesture = _ToolGesture.moveSelection;
    _controller.beginSelectionDrag();
    return true;
  }

  /// Classifies and starts the tool gesture for a fresh tool-pointer press.
  ///
  /// Dispatches on [CanvasController.activeTool]; the lasso tool additionally
  /// decides between dragging an existing selection (press lands on it) and
  /// tracing a new loop. Returns the [_ToolGesture] now in progress.
  _ToolGesture? _beginToolGesture(PointerDownEvent event) {
    return _beginToolGestureFor(
      localPosition: event.localPosition,
      pointerKind: event.kind,
      event: event,
    );
  }

  _ToolGesture? _beginToolGestureAt(
    Offset localPosition,
    PointerDeviceKind pointerKind,
  ) {
    return _beginToolGestureFor(
      localPosition: localPosition,
      pointerKind: pointerKind,
    );
  }

  _ToolGesture? _beginToolGestureFor({
    required Offset localPosition,
    required PointerDeviceKind pointerKind,
    PointerEvent? event,
  }) {
    final Offset world = _toWorld(localPosition);
    if (pointerKind == PointerDeviceKind.invertedStylus) {
      _controller.beginErase(world);
      return _ToolGesture.erase;
    }
    switch (_controller.activeTool) {
      case CanvasTool.pan:
        // A pan press that ends without moving, on a link chip, follows the
        // link — see `_finishToolGesture`. Until then it is a normal pan.
        return _ToolGesture.pan;
      case CanvasTool.pen:
        if (!_controller.canCreateContent) {
          return null;
        }
        if (event == null) {
          return _ToolGesture.pan;
        }
        final PenSample sample = _beginPenSample(world, event);
        _controller.beginStroke(
          sample.point,
          sample.pressure,
          tiltX: sample.tiltX,
          tiltY: sample.tiltY,
          azimuth: sample.azimuth,
          timestampMicros: sample.timestampMicros,
          velocity: sample.velocity,
        );
        return _ToolGesture.draw;
      case CanvasTool.eraser:
        _controller.beginErase(world);
        return _ToolGesture.erase;
      case CanvasTool.shape:
        if (!_controller.canCreateContent) {
          return null;
        }
        _controller.beginShape(world);
        return _ToolGesture.shape;
      case CanvasTool.lasso:
        // Add/subtract always trace, even when a temporary stylus lasso begins
        // over selected content. Replace mode keeps direct body dragging.
        if (_controller.selectionMode == SelectionMode.replace &&
            _controller.selectionHitTest(world)) {
          _controller.beginSelectionDrag();
          return _ToolGesture.moveSelection;
        }
        _controller.beginLasso(world);
        return _ToolGesture.lasso;
      case CanvasTool.link:
        if (!_controller.canCreateContent) {
          return null;
        }
        // A link chip is placed on pointer-up (a tap); the press itself does
        // nothing so a drag with the link tool is harmless.
        return _ToolGesture.placeLink;
      case CanvasTool.text:
        if (!_controller.canCreateContent) {
          return null;
        }
        return _ToolGesture.editText;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    final pointer = _pointers[event.pointer];
    if (pointer == null) {
      return;
    }
    final Offset previous = pointer.position;
    pointer.position = event.localPosition;
    final Offset? touchDown = _touchDownPositions[event.pointer];
    if (touchDown != null &&
        (event.localPosition - touchDown).distance > CanvasController.tapSlop) {
      _movedTouchPointers.add(event.pointer);
      _touchShortcutDisqualified = true;
      _longPressTimer?.cancel();
    }

    if (_selectionTransformTouchPointers.contains(event.pointer)) {
      _updateSelectionTouchTransform();
      return;
    }

    if (event.pointer == _longPressLassoPointerId) {
      _controller.appendLasso(_toWorld(event.localPosition));
      return;
    }

    if (event.pointer == _toolPointerId) {
      _toolPointerUpPosition = event.localPosition;
      final Offset? down = _toolPointerDownPosition;
      final bool wasMoved = _toolPointerMoved;
      if (down == null ||
          (event.localPosition - down).distance > CanvasController.tapSlop) {
        _toolPointerMoved = true;
        _stylusLongPressTimer?.cancel();
        _stylusButtonHoldTimer?.cancel();
      }
      if (_selectionPointerSession != null) {
        _routeSelectionPointerMove(event);
        return;
      }
      if (!wasMoved && _toolPointerMoved && _dispatchStylusDragOneShot()) {
        _stylusLongPressToolActive = true;
      }
      _routeToolMove(event, previous);
      return;
    }

    if (pointer.kind == CanvasInputKind.touch) {
      if (_toolPointerId != null) {
        return;
      }
      final touches = _touchPositions;
      if (touches.length == 1) {
        _controller.panBy(event.localPosition - previous);
      } else if (touches.length >= 2) {
        _applyPinch(touches[0], touches[1]);
      }
    }
  }

  void _routeSelectionPointerMove(PointerMoveEvent event) {
    final _SelectionPointerSession? session = _selectionPointerSession;
    if (session == null ||
        (!session.activated &&
            (event.localPosition - session.downLocal).distance <=
                CanvasController.tapSlop)) {
      return;
    }

    switch (session.target) {
      case SelectionOverlayTarget.body:
        if (!session.activated) {
          _controller.beginSelectionDrag();
          session.activated = true;
          _controller.updateSelectionDrag(
            _toWorld(event.localPosition) - _toWorld(session.downLocal),
          );
        } else {
          _controller.updateSelectionDrag(
            _toWorld(event.localPosition) - _toWorld(session.previousLocal),
          );
        }
      case SelectionOverlayTarget.scaleTopLeft:
      case SelectionOverlayTarget.scaleTopRight:
      case SelectionOverlayTarget.scaleBottomRight:
      case SelectionOverlayTarget.scaleBottomLeft:
        _updateSinglePointerScale(session, event.localPosition);
      case SelectionOverlayTarget.rotation:
        _updateSinglePointerRotation(session, event.localPosition);
      case SelectionOverlayTarget.done:
        // Done is deliberately tap-only; dragging away leaves the selection.
        break;
      case SelectionOverlayTarget.outside:
        _resumeBackgroundToolFromSelection(session, event);
        return;
    }
    session.previousLocal = event.localPosition;
  }

  void _updateSinglePointerScale(
    _SelectionPointerSession session,
    Offset currentLocal,
  ) {
    if (!session.activated) {
      final Offset origin = _toWorld(
        session.geometry.oppositeCornerFor(session.target),
      );
      final double startDistance =
          (_toWorld(session.geometry.centerFor(session.target)) - origin)
              .distance;
      if (startDistance <= 0.000001) {
        return;
      }
      session
        ..transformOriginWorld = origin
        ..scaleStartDistance = startDistance
        ..activated = true;
      _controller.beginSelectionTransform();
    }
    final Offset? origin = session.transformOriginWorld;
    final double? startDistance = session.scaleStartDistance;
    if (origin == null || startDistance == null) {
      return;
    }
    final double scale =
        (_toWorld(currentLocal) - origin).distance / startDistance;
    _controller.updateSelectionTransform(
      origin: origin,
      translation: Offset.zero,
      scale: scale,
      rotation: 0,
    );
  }

  void _updateSinglePointerRotation(
    _SelectionPointerSession session,
    Offset currentLocal,
  ) {
    if (!session.activated) {
      final Offset center = session.geometry.frameRect.center;
      session
        ..transformOriginWorld = _toWorld(center)
        ..rotationCenterLocal = center
        ..rotationStartAngle = math.atan2(
          session.geometry.rotationCenter.dy - center.dy,
          session.geometry.rotationCenter.dx - center.dx,
        )
        ..activated = true;
      _controller.beginSelectionTransform();
    }
    final Offset? center = session.rotationCenterLocal;
    final double? startAngle = session.rotationStartAngle;
    final Offset? origin = session.transformOriginWorld;
    if (center == null || startAngle == null || origin == null) {
      return;
    }
    final double currentAngle = math.atan2(
      currentLocal.dy - center.dy,
      currentLocal.dx - center.dx,
    );
    _controller.updateSelectionTransform(
      origin: origin,
      translation: Offset.zero,
      scale: 1,
      rotation: _normaliseAngle(currentAngle - startAngle),
    );
  }

  double _normaliseAngle(double radians) {
    var result = radians;
    while (result > math.pi) {
      result -= math.pi * 2;
    }
    while (result < -math.pi) {
      result += math.pi * 2;
    }
    return result;
  }

  void _resumeBackgroundToolFromSelection(
    _SelectionPointerSession session,
    PointerMoveEvent event,
  ) {
    _selectionBeforeBackgroundGesture = Set<String>.of(_controller.selectedIds);
    _controller.clearSelection();
    _selectionPointerSession = null;
    _toolGesture = _beginToolGestureFor(
      localPosition: session.downLocal,
      pointerKind: event.kind,
      event: event,
    );
    _routeToolMove(event, session.downLocal);
  }

  /// Routes a move of the active tool pointer to the controller per
  /// [_toolGesture].
  void _routeToolMove(PointerMoveEvent event, Offset previous) {
    final Offset world = _toWorld(event.localPosition);
    switch (_toolGesture) {
      case _ToolGesture.draw:
        final PenSample sample = _nextPenSample(world, event);
        _controller.appendToStroke(
          sample.point,
          sample.pressure,
          tiltX: sample.tiltX,
          tiltY: sample.tiltY,
          azimuth: sample.azimuth,
          timestampMicros: sample.timestampMicros,
          velocity: sample.velocity,
        );
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
        final bool provisionalSideButtonPan =
            _stylusButtonDragAction != null &&
            !_stylusLongPressToolActive &&
            !_toolPointerMoved;
        if (!provisionalSideButtonPan) {
          _controller.panBy(event.localPosition - previous);
        }
      case _ToolGesture.placeLink:
        // Placing a link is a tap; movement is ignored (the chip is committed
        // at the press point on pointer-up).
        break;
      case _ToolGesture.editText:
        break;
      case null:
        break;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer == _toolPointerId) {
      _toolPointerUpPosition = event.localPosition;
      _appendPenUpSample(event);
    }
    _endPointer(event.pointer);
  }

  /// Appends the pointer-up position as the stroke's final sample.
  ///
  /// The smoothing filter always trails the true nib position, so ending a
  /// stroke at the last *smoothed* move leaves it visibly short of where the
  /// user lifted — worst on short ticks and fast flicks. This pushes the raw
  /// up-event position, bypassing both the filter and the thinning threshold.
  void _appendPenUpSample(PointerUpEvent event) {
    if (_toolGesture != _ToolGesture.draw) {
      return;
    }
    _controller.appendToStroke(
      _toWorld(event.localPosition),
      _controller.liveStrokeLastPressure ?? _pressure(event),
      tiltX: _tiltX(event),
      tiltY: _tiltY(event),
      azimuth: event.orientation,
      timestampMicros: event.timeStamp.inMicroseconds,
      force: true,
    );
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _endPointer(event.pointer, cancelled: true);
  }

  /// Tears down state for [pointerId] on pointer up or cancel.
  ///
  /// When [cancelled] the in-progress tool gesture is abandoned with no
  /// undoable command; otherwise it is committed.
  void _endPointer(int pointerId, {bool cancelled = false}) {
    final bool wasSelectionTransformPointer = _selectionTransformTouchPointers
        .contains(pointerId);
    final pointer = _pointers.remove(pointerId);

    if (wasSelectionTransformPointer) {
      if (cancelled) {
        _controller.cancelSelectionTransform();
      } else {
        _controller.endSelectionTransform();
      }
      _clearSelectionTouchTransform();
    }

    if (pointerId == _toolPointerId) {
      _stylusLongPressTimer?.cancel();
      _stylusButtonHoldTimer?.cancel();
      _finishToolGesture(cancelled: cancelled);
      _toolPointerId = null;
      _toolGesture = null;
      _toolPointerDownPosition = null;
      _toolPointerUpPosition = null;
    }
    if (pointer?.kind == CanvasInputKind.touch) {
      if (cancelled) {
        _touchShortcutDisqualified = true;
      }
      if (pointerId == _longPressLassoPointerId) {
        _touchShortcutDisqualified = true;
        if (cancelled) {
          _controller.cancelLasso();
        } else {
          _controller.endLasso();
        }
        _longPressLassoPointerId = null;
      }
      _touchDownPositions.remove(pointerId);
      _movedTouchPointers.remove(pointerId);
      _maybeApplyTouchTapShortcut();
      _syncTouchGesture();
    }
  }

  void _scheduleLongPressLasso(int pointerId, Offset localPosition) {
    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(milliseconds: 520), () {
      if (!mounted || _toolPointerId != null || _pointers.length != 1) {
        return;
      }
      final pointer = _pointers[pointerId];
      if (pointer == null ||
          pointer.kind != CanvasInputKind.touch ||
          _movedTouchPointers.contains(pointerId)) {
        return;
      }
      _touchShortcutDisqualified = true;
      _longPressLassoPointerId = pointerId;
      _controller.beginLasso(_toWorld(localPosition));
    });
  }

  void _scheduleStylusLongPress(int pointerId, Offset localPosition) {
    final StylusButtonAction action = widget.stylusButtonMapping.penLongPress;
    if (action == StylusButtonAction.disabled) {
      return;
    }
    _stylusLongPressTimer?.cancel();
    _stylusLongPressTimer = Timer(const Duration(milliseconds: 520), () {
      if (!mounted ||
          pointerId != _toolPointerId ||
          _toolPointerMoved ||
          _selectionTransformTouchPointers.isNotEmpty) {
        return;
      }
      final pointer = _pointers[pointerId];
      if (pointer == null || pointer.kind != CanvasInputKind.stylus) {
        return;
      }
      // A hold outside the current frame intentionally becomes the configured
      // long-press action instead of completing the pending deselect tap.
      _selectionPointerSession = null;
      _cancelToolGesture();
      _stylusButtonDragAction = action;
      _stylusLongPressToolActive = true;
      if (action == StylusButtonAction.radialMenu) {
        _toolGesture = null;
        widget.onShowQuickTools?.call(localPosition);
        return;
      }
      _toolGestureUsesTemporaryTool = _pushTemporaryToolFor(action);
      if (!_toolGestureUsesTemporaryTool) {
        _toolGesture = null;
        return;
      }
      _toolPointerMoved = false;
      _toolPointerDownPosition = localPosition;
      _toolPointerUpPosition = localPosition;
      _toolGesture = _beginToolGestureAt(
        localPosition,
        PointerDeviceKind.stylus,
      );
    });
  }

  void _scheduleStylusButtonHold(int pointerId) {
    final StylusButtonAction action = widget.stylusButtonMapping.hold;
    if (action == StylusButtonAction.disabled) {
      return;
    }
    _stylusButtonHoldTimer?.cancel();
    _stylusButtonHoldTimer = Timer(const Duration(milliseconds: 520), () {
      if (!mounted ||
          pointerId != _toolPointerId ||
          _toolPointerMoved ||
          _selectionTransformTouchPointers.isNotEmpty) {
        return;
      }
      final _ActivePointer? pointer = _pointers[pointerId];
      if (pointer == null || pointer.kind != CanvasInputKind.stylus) {
        return;
      }

      // The drag mapping is provisional until movement crosses tap slop.
      // Cancel its preview without committing before dispatching the distinct
      // stationary-hold action.
      _cancelToolGesture();
      if (_toolGestureUsesTemporaryTool) {
        _controller.popTemporaryTool();
      }
      _toolGestureUsesTemporaryTool = false;
      _toolGesture = null;
      _stylusButtonDragAction = null;
      _stylusLongPressToolActive = true;
      _toolPointerMoved = false;
      _toolPointerDownPosition = pointer.position;
      _toolPointerUpPosition = pointer.position;

      _toolGestureUsesTemporaryTool = _pushTemporaryToolFor(action);
      if (_toolGestureUsesTemporaryTool) {
        _toolGesture = _beginToolGestureAt(
          pointer.position,
          PointerDeviceKind.stylus,
        );
      } else {
        _performStylusTapAction(action);
      }
    });
  }

  void _beginSelectionTouchTransform() {
    final touchEntries = _pointers.entries
        .where((entry) => entry.value.kind == CanvasInputKind.touch)
        .take(2)
        .toList();
    if (touchEntries.length < 2) {
      return;
    }

    if (_toolGesture == _ToolGesture.moveSelection) {
      _controller.endSelectionDrag();
      _toolPointerId = null;
      _toolGesture = null;
      _toolPointerDownPosition = null;
      _toolPointerUpPosition = null;
    }

    final Offset a = touchEntries[0].value.position;
    final Offset b = touchEntries[1].value.position;
    _selectionTransformTouchPointers
      ..clear()
      ..add(touchEntries[0].key)
      ..add(touchEntries[1].key);
    _selectionTransformStartMidpoint = (a + b) / 2;
    _selectionTransformStartDistance = (b - a).distance;
    _selectionTransformStartAngle = math.atan2(b.dy - a.dy, b.dx - a.dx);
    _selectionTransformOriginWorld =
        _controller.selectionBounds?.center ?? _toWorld((a + b) / 2);
    _controller.beginSelectionTransform();
    _updateSelectionTouchTransform();
  }

  void _updateSelectionTouchTransform() {
    if (_selectionTransformTouchPointers.length < 2) {
      return;
    }
    final ids = _selectionTransformTouchPointers.toList();
    final _ActivePointer? first = _pointers[ids[0]];
    final _ActivePointer? second = _pointers[ids[1]];
    final Offset? startMidpoint = _selectionTransformStartMidpoint;
    final double? startDistance = _selectionTransformStartDistance;
    final double? startAngle = _selectionTransformStartAngle;
    final Offset? origin = _selectionTransformOriginWorld;
    if (first == null ||
        second == null ||
        startMidpoint == null ||
        startDistance == null ||
        startAngle == null ||
        origin == null ||
        startDistance == 0) {
      return;
    }
    final Offset a = first.position;
    final Offset b = second.position;
    final Offset currentMidpoint = (a + b) / 2;
    final double currentDistance = (b - a).distance;
    final double currentAngle = math.atan2(b.dy - a.dy, b.dx - a.dx);
    _controller.updateSelectionTransform(
      origin: origin,
      translation: _toWorld(currentMidpoint) - _toWorld(startMidpoint),
      scale: currentDistance / startDistance,
      rotation: currentAngle - startAngle,
    );
  }

  void _clearSelectionTouchTransform() {
    _selectionTransformTouchPointers.clear();
    _selectionTransformStartMidpoint = null;
    _selectionTransformStartDistance = null;
    _selectionTransformStartAngle = null;
    _selectionTransformOriginWorld = null;
    _syncTouchGesture();
  }

  void _maybeApplyTouchTapShortcut() {
    // Resolve a touch chord once, after its final tracked finger lifts. This
    // also retains cancellation/movement from fingers that lifted earlier.
    if (_touchDownPositions.isNotEmpty) {
      return;
    }
    final int tapCount = _touchShortcutPointerCount;
    final bool disqualified = _touchShortcutDisqualified;
    _touchShortcutPointerCount = 0;
    _touchShortcutDisqualified = false;
    if (disqualified) {
      return;
    }
    if (tapCount == 2) {
      _controller.undo();
    } else if (tapCount == 3) {
      _controller.redo();
    }
  }

  /// Commits (or, when [cancelled], discards) the in-progress tool gesture.
  void _finishToolGesture({required bool cancelled}) {
    if (_finishSelectionPointerGesture(cancelled: cancelled)) {
      _restoreTemporaryTool();
      return;
    }
    if (_stylusButtonDragAction != null &&
        !_stylusLongPressToolActive &&
        !cancelled &&
        !_toolPointerMoved) {
      _cancelToolGesture();
      _restoreTemporaryTool();
      _performStylusTapAction(widget.stylusButtonMapping.tap);
      return;
    }

    // A tap (no movement) with the lasso tool clears any selection — the loop
    // is too small for `endLasso` to select anything anyway, so treat the tap
    // on empty space as "deselect". A drag still goes through `endLasso`.
    if (_toolGesture == _ToolGesture.lasso &&
        !cancelled &&
        !_toolPointerMoved) {
      _controller.cancelLasso();
      final Offset? down = _toolPointerUpPosition ?? _toolPointerDownPosition;
      if (down == null) {
        _controller.clearSelection();
      } else {
        _controller.selectElementAt(_toWorld(down));
      }
      _restoreTemporaryTool();
      return;
    }

    switch (_toolGesture) {
      case _ToolGesture.draw:
        if (cancelled) {
          _controller.cancelStroke();
        } else {
          _controller.endStroke();
        }
        _penInputProcessor?.reset();
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
      case _ToolGesture.editText:
        if (!cancelled && !_toolPointerMoved) {
          _emitTextEdit();
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
    final Set<String>? selectionBeforeBackground =
        _selectionBeforeBackgroundGesture;
    _selectionBeforeBackgroundGesture = null;
    if (cancelled && selectionBeforeBackground != null) {
      _controller.setSelection(selectionBeforeBackground);
    }
    _restoreTemporaryTool();
  }

  bool _finishSelectionPointerGesture({required bool cancelled}) {
    final _SelectionPointerSession? session = _selectionPointerSession;
    if (session == null) {
      return false;
    }
    _selectionPointerSession = null;
    switch (session.target) {
      case SelectionOverlayTarget.body:
        if (session.activated) {
          if (cancelled) {
            _controller.cancelSelectionDrag();
          } else {
            _controller.endSelectionDrag();
          }
        }
      case SelectionOverlayTarget.scaleTopLeft:
      case SelectionOverlayTarget.scaleTopRight:
      case SelectionOverlayTarget.scaleBottomRight:
      case SelectionOverlayTarget.scaleBottomLeft:
      case SelectionOverlayTarget.rotation:
        if (session.activated) {
          if (cancelled) {
            _controller.cancelSelectionTransform();
          } else {
            _controller.endSelectionTransform();
          }
        }
      case SelectionOverlayTarget.done:
        if (!cancelled && !_toolPointerMoved) {
          _controller.clearSelection();
        }
      case SelectionOverlayTarget.outside:
        if (!cancelled) {
          if (_controller.activeTool == CanvasTool.lasso) {
            _controller.selectElementAt(
              _toWorld(session.downLocal),
              mode: SelectionMode.replace,
            );
          } else {
            _controller.clearSelection();
          }
        }
    }
    return true;
  }

  void _cancelToolGesture() {
    switch (_toolGesture) {
      case _ToolGesture.draw:
        _controller.cancelStroke();
        _penInputProcessor?.reset();
      case _ToolGesture.erase:
        _controller.cancelErase();
      case _ToolGesture.lasso:
        _controller.cancelLasso();
      case _ToolGesture.shape:
        _controller.cancelShape();
      case _ToolGesture.moveSelection:
        _controller.cancelSelectionDrag();
      case _ToolGesture.pan:
      case _ToolGesture.placeLink:
      case _ToolGesture.editText:
      case null:
        break;
    }
  }

  bool _pushTemporaryToolFor(StylusButtonAction action) {
    switch (action) {
      case StylusButtonAction.temporaryEraser:
        _controller.pushTemporaryTool(CanvasTool.eraser);
        return true;
      case StylusButtonAction.temporaryLasso:
        _controller.pushTemporaryTool(CanvasTool.lasso);
        return true;
      case StylusButtonAction.temporaryPan:
        _controller.pushTemporaryTool(CanvasTool.pan);
        return true;
      case StylusButtonAction.straightLine:
        _controller.pushTemporaryTool(
          CanvasTool.shape,
          shapeKindOverride: ShapeKind.line,
        );
        return true;
      case StylusButtonAction.arrow:
        _controller.pushTemporaryTool(
          CanvasTool.shape,
          shapeKindOverride: ShapeKind.arrow,
        );
        return true;
      case StylusButtonAction.eyedropper:
      case StylusButtonAction.undo:
      case StylusButtonAction.redo:
      case StylusButtonAction.togglePreviousTool:
      case StylusButtonAction.radialMenu:
      case StylusButtonAction.exportSelection:
      case StylusButtonAction.disabled:
        return false;
    }
  }

  void _performStylusTapAction(StylusButtonAction action) {
    switch (action) {
      case StylusButtonAction.undo:
        _controller.undo();
      case StylusButtonAction.redo:
        _controller.redo();
      case StylusButtonAction.togglePreviousTool:
        _controller.togglePreviousTool();
      case StylusButtonAction.straightLine:
        _controller
          ..setShapeKind(ShapeKind.line)
          ..setTool(CanvasTool.shape);
      case StylusButtonAction.arrow:
        _controller
          ..setShapeKind(ShapeKind.arrow)
          ..setTool(CanvasTool.shape);
      case StylusButtonAction.temporaryEraser:
        _controller.setTool(CanvasTool.eraser);
      case StylusButtonAction.temporaryLasso:
        _controller.setTool(CanvasTool.lasso);
      case StylusButtonAction.temporaryPan:
        _controller.setTool(CanvasTool.pan);
      case StylusButtonAction.radialMenu:
        final Offset? position =
            _toolPointerUpPosition ?? _toolPointerDownPosition;
        if (position != null) {
          widget.onShowQuickTools?.call(position);
        }
      case StylusButtonAction.eyedropper:
      case StylusButtonAction.exportSelection:
      case StylusButtonAction.disabled:
        break;
    }
  }

  bool _dispatchStylusDragOneShot() {
    final StylusButtonAction? action = _stylusButtonDragAction;
    switch (action) {
      case StylusButtonAction.undo:
      case StylusButtonAction.redo:
      case StylusButtonAction.togglePreviousTool:
      case StylusButtonAction.radialMenu:
        _performStylusTapAction(action!);
        return true;
      case StylusButtonAction.temporaryEraser:
      case StylusButtonAction.temporaryLasso:
      case StylusButtonAction.temporaryPan:
      case StylusButtonAction.straightLine:
      case StylusButtonAction.arrow:
      case StylusButtonAction.eyedropper:
      case StylusButtonAction.exportSelection:
      case StylusButtonAction.disabled:
      case null:
        return false;
    }
  }

  void _restoreTemporaryTool() {
    _stylusButtonHoldTimer?.cancel();
    if (_toolGestureUsesTemporaryTool) {
      _controller.popTemporaryTool();
    }
    _toolGestureUsesTemporaryTool = false;
    _stylusLongPressToolActive = false;
    _stylusButtonDragAction = null;
  }

  /// Reports a link-placement tap to [CanvasView.onPlaceLink].
  void _emitLinkPlacement() {
    final Offset? down = _toolPointerUpPosition ?? _toolPointerDownPosition;
    final void Function(Offset)? callback = widget.onPlaceLink;
    if (down == null || callback == null) {
      return;
    }
    callback(_toWorld(down));
  }

  /// Follows a link chip when the pan tool tapped one, via
  /// [CanvasView.onFollowLink].
  void _maybeFollowLinkAtTap() {
    final Offset? down = _toolPointerUpPosition ?? _toolPointerDownPosition;
    final void Function(LinkElement)? callback = widget.onFollowLink;
    if (down == null || callback == null) {
      return;
    }
    final LinkElement? link = _controller.linkAt(_toWorld(down));
    if (link != null) {
      callback(link);
    }
  }

  void _emitTextEdit() {
    final Offset? up = _toolPointerUpPosition ?? _toolPointerDownPosition;
    final callback = widget.onEditText;
    if (up == null || callback == null) {
      return;
    }
    final Offset world = _toWorld(up);
    callback(world, _controller.textAt(world));
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

  double _pressure(PointerEvent event) {
    return _controller.pressureEnabled ? normalizedPressure(event) : 0.5;
  }

  PenSample _beginPenSample(Offset world, PointerEvent event) {
    final PenInputProcessor processor = PenInputProcessor(
      _controller.penProfile,
    );
    _penInputProcessor = processor;
    return processor.begin(
      world,
      _pressure(event),
      tiltX: _tiltX(event),
      tiltY: _tiltY(event),
      azimuth: event.orientation,
      timestampMicros: event.timeStamp.inMicroseconds,
    );
  }

  PenSample _nextPenSample(Offset world, PointerEvent event) {
    final PenInputProcessor processor =
        _penInputProcessor ?? PenInputProcessor(_controller.penProfile);
    _penInputProcessor = processor;
    return processor.next(
      world,
      _pressure(event),
      tiltX: _tiltX(event),
      tiltY: _tiltY(event),
      azimuth: event.orientation,
      timestampMicros: event.timeStamp.inMicroseconds,
    );
  }

  double _tiltX(PointerEvent event) {
    return event.tilt * math.cos(event.orientation);
  }

  double _tiltY(PointerEvent event) {
    return event.tilt * math.sin(event.orientation);
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
        rotationDelta: _controller.rotationLocked
            ? 0
            : currentAngle - startAngle,
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
    final bool sizeChanged = _lastRasterSize != size;
    _lastRasterSize = size;
    _controller.setViewportSize(size);
    final ViewportState viewport = _controller.viewport;
    if (_lastRasterViewport != viewport || sizeChanged) {
      _lastRasterViewport = viewport;
      _controller.scheduleRasterWork();
    }
  }

  void _queueRasterScheduling(Size size) {
    if (_lastRasterSize == size &&
        _lastRasterViewport == _controller.viewport &&
        !_rasterSyncScheduled) {
      return;
    }
    _pendingRasterSyncSize = size;
    if (_rasterSyncScheduled) {
      return;
    }
    _rasterSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rasterSyncScheduled = false;
      if (mounted) {
        _syncRasterScheduling(_pendingRasterSyncSize ?? Size.zero);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Color(_controller.paperStyle.backgroundColor),
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
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final Size size = constraints.biggest;
                    final bool hasFiniteSize =
                        size.width.isFinite && size.height.isFinite;
                    _queueRasterScheduling(hasFiniteSize ? size : Size.zero);
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        RepaintBoundary(
                          child: CustomPaint(
                            painter: GridPainter(
                              viewport: viewport,
                              style: _controller.paperStyle,
                            ),
                          ),
                        ),
                        RepaintBoundary(
                          child: CustomPaint(
                            painter: ElementsPainter(
                              elements: _controller.visibleElements,
                              spatialIndex: _controller.spatialIndex,
                              viewport: viewport,
                              elementsRevision: _controller.elementsRevision,
                              selectionRevision: _controller.selectionRevision,
                              selectionPreviewRevision:
                                  _controller.selectionPreviewRevision,
                              tileCache: _elementsTileCache,
                              selectedIds: _controller.selectedIds,
                              selectionDragDelta:
                                  _controller.selectionDragDelta,
                              selectionTransformPreview:
                                  _controller.selectionTransformPreview,
                            ),
                          ),
                        ),
                        // The live and overlay layers redraw at pen report
                        // rate. They subscribe to the controller's live-layer
                        // channel so a stroke sample rebuilds these two
                        // painters only, never the surrounding editor.
                        RepaintBoundary(
                          child: ListenableBuilder(
                            listenable: _controller.liveLayerListenable,
                            builder: (context, _) => CustomPaint(
                              // Freehand ink and the in-progress shape preview
                              // share the live layer — only one is ever
                              // non-null at once.
                              painter: LiveStrokePainter(
                                liveStroke: _controller.liveStroke,
                                liveStrokeRevision:
                                    _controller.liveStrokeRevision,
                                liveShape: _controller.liveShapeElement,
                                viewport: _controller.viewport,
                                pathCache: _liveStrokePathCache,
                              ),
                            ),
                          ),
                        ),
                        RepaintBoundary(
                          child: ListenableBuilder(
                            listenable: _controller.liveLayerListenable,
                            builder: (context, _) {
                              final bool erasing =
                                  _controller.activeTool == CanvasTool.eraser;
                              return CustomPaint(
                                painter: CanvasOverlayPainter(
                                  viewport: _controller.viewport,
                                  hoverPointWorld: _controller.hoverPointWorld,
                                  hoverRadius: erasing
                                      ? _controller.eraserRadius
                                      : _controller
                                            .resolvedPenHoverRadiusScreen(),
                                  isEraserHover: erasing,
                                  eraserPath: _controller.eraserPath,
                                  eraserRadius: _controller.eraserRadius,
                                  lassoPath: _controller.lassoPath,
                                  selectionBounds: _controller.selectionBounds,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
