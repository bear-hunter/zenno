import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart'
    show kPrimaryStylusButton, kSecondaryMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/input/stylus_button_mapping.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/render/canvas_view.dart';
import 'package:zenno/canvas/render/selection_overlay_geometry.dart';

Future<void> _pumpCanvas(
  WidgetTester tester,
  CanvasController controller, {
  void Function(Offset worldCenter)? onPlaceLink,
  void Function(LinkElement link)? onFollowLink,
  void Function(Offset worldCenter, TextElement? existing)? onEditText,
  ValueChanged<Offset>? onShowQuickTools,
  StylusButtonMapping stylusButtonMapping = const StylusButtonMapping(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 400,
          child: CanvasView(
            controller: controller,
            onPlaceLink: onPlaceLink,
            onFollowLink: onFollowLink,
            onEditText: onEditText,
            onShowQuickTools: onShowQuickTools,
            stylusButtonMapping: stylusButtonMapping,
          ),
        ),
      ),
    ),
  );
}

TextElement _textNote(String id, Rect bounds, {int zIndex = 0}) => TextElement(
  id: id,
  zIndex: zIndex,
  worldBounds: bounds,
  text: id,
  color: 0xFFFFFFFF,
  fontSize: 18,
);

SelectionOverlayGeometry _selectionGeometry(
  WidgetTester tester,
  CanvasController controller,
) => SelectionOverlayGeometry.fromWorldBounds(
  bounds: controller.selectionBounds!,
  viewport: controller.viewport,
  canvasSize: tester.getSize(find.byType(CanvasView)),
);

Offset _canvasGlobal(WidgetTester tester, Offset local) =>
    tester.getTopLeft(find.byType(CanvasView)) + local;

Future<void> _tapStylus(WidgetTester tester, Offset local) async {
  final TestGesture stylus = await tester.createGesture(
    kind: PointerDeviceKind.stylus,
  );
  await stylus.down(_canvasGlobal(tester, local));
  await stylus.up();
  await tester.pump();
}

Future<void> _dragStylus(WidgetTester tester, Offset start, Offset end) async {
  final TestGesture stylus = await tester.createGesture(
    kind: PointerDeviceKind.stylus,
  );
  await stylus.down(_canvasGlobal(tester, start));
  await stylus.moveTo(_canvasGlobal(tester, end));
  await stylus.up();
  await tester.pump();
}

void main() {
  testWidgets('three-finger redo fires once without a follow-up undo', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..beginStroke(const Offset(40, 40), 0.5)
      ..appendToStroke(const Offset(160, 40), 0.5)
      ..endStroke()
      ..undo();
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);

    final TestGesture first = await tester.createGesture(
      kind: PointerDeviceKind.touch,
    );
    final TestGesture second = await tester.createGesture(
      kind: PointerDeviceKind.touch,
    );
    final TestGesture third = await tester.createGesture(
      kind: PointerDeviceKind.touch,
    );
    await first.down(const Offset(80, 80));
    await second.down(const Offset(120, 80));
    await third.down(const Offset(160, 80));
    await first.up();
    await second.up();
    await third.up();
    await tester.pump();

    expect(controller.elementCount, 1);
    expect(controller.canRedo, isFalse);
    expect(controller.canUndo, isTrue);
  });

  testWidgets('cancelled two-finger shortcut does not undo', (tester) async {
    final CanvasController controller = CanvasController()
      ..beginStroke(const Offset(40, 40), 0.5)
      ..appendToStroke(const Offset(160, 40), 0.5)
      ..endStroke();
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);

    final TestGesture first = await tester.createGesture(
      kind: PointerDeviceKind.touch,
    );
    final TestGesture second = await tester.createGesture(
      kind: PointerDeviceKind.touch,
    );
    await first.down(const Offset(80, 80));
    await second.down(const Offset(120, 80));
    await first.cancel();
    await second.up();
    await tester.pump();

    expect(controller.elementCount, 1);
    expect(controller.canUndo, isTrue);
  });

  testWidgets('moved three-finger shortcut does not undo or redo', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..beginStroke(const Offset(40, 40), 0.5)
      ..appendToStroke(const Offset(160, 40), 0.5)
      ..endStroke();
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);

    final TestGesture first = await tester.createGesture(
      kind: PointerDeviceKind.touch,
    );
    final TestGesture second = await tester.createGesture(
      kind: PointerDeviceKind.touch,
    );
    final TestGesture third = await tester.createGesture(
      kind: PointerDeviceKind.touch,
    );
    await first.down(const Offset(80, 80));
    await second.down(const Offset(120, 80));
    await third.down(const Offset(160, 80));
    await first.moveBy(const Offset(40, 0));
    await first.up();
    await second.up();
    await third.up();
    await tester.pump();

    expect(controller.elementCount, 1);
    expect(controller.canUndo, isTrue);
    expect(controller.canRedo, isFalse);
  });

  testWidgets('secondary mouse button does not draw', (tester) async {
    final CanvasController controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);

    final TestGesture mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await mouse.down(const Offset(80, 80));
    await mouse.moveTo(const Offset(160, 80));
    await mouse.up();
    await tester.pump();

    expect(controller.liveStroke, isNull);
    expect(controller.elementCount, 0);
  });

  testWidgets('secondary mouse button does not erase', (tester) async {
    final CanvasController controller = CanvasController()
      ..beginStroke(const Offset(40, 80), 0.5)
      ..appendToStroke(const Offset(160, 80), 0.5)
      ..endStroke()
      ..setTool(CanvasTool.eraser);
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);

    final TestGesture mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await mouse.down(const Offset(80, 80));
    await mouse.moveTo(const Offset(120, 80));
    await mouse.up();
    await tester.pump();

    expect(controller.eraserPath, isNull);
    expect(controller.elementCount, 1);
  });

  testWidgets('secondary mouse button does not create a shape', (tester) async {
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.shape);
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);

    final TestGesture mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await mouse.down(const Offset(80, 80));
    await mouse.moveTo(const Offset(160, 160));
    await mouse.up();
    await tester.pump();

    expect(controller.liveShapeElement, isNull);
    expect(controller.elementCount, 0);
  });

  testWidgets('touch pan is ignored while stylus drawing is active', (
    tester,
  ) async {
    final CanvasController controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
    );
    await stylus.down(const Offset(100, 100));
    await tester.pump();

    final TestGesture touch = await tester.createGesture(
      kind: PointerDeviceKind.touch,
    );
    await touch.down(const Offset(200, 200));
    await touch.moveBy(const Offset(80, 0));
    await tester.pump();

    expect(controller.viewport, ViewportState.initial);
    expect(controller.liveStroke?.points, hasLength(1));

    await touch.up();
    await stylus.up();
  });

  testWidgets('link placement uses final tap position within tap slop', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.link);
    addTearDown(controller.dispose);
    Offset? placedAt;
    await _pumpCanvas(
      tester,
      controller,
      onPlaceLink: (worldCenter) => placedAt = worldCenter,
    );

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
    );
    await stylus.down(const Offset(100, 100));
    await stylus.moveBy(const Offset(6, 0));
    await stylus.up();
    await tester.pump();

    expect(placedAt, const Offset(106, 100));
  });

  testWidgets('drag beyond tap slop does not place a link', (tester) async {
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.link);
    addTearDown(controller.dispose);
    var placements = 0;
    await _pumpCanvas(tester, controller, onPlaceLink: (_) => placements++);

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
    );
    await stylus.down(const Offset(100, 100));
    await stylus.moveBy(const Offset(20, 0));
    await stylus.up();
    await tester.pump();

    expect(placements, 0);
  });

  testWidgets('pan-tool link follow uses final tap position within tap slop', (
    tester,
  ) async {
    final CanvasController controller = CanvasController();
    addTearDown(controller.dispose);
    final LinkElement link = controller.placeLink(
      worldCenter: const Offset(100, 100),
      label: 'Target',
      target: const LinkTarget(targetCanvasId: 'target-canvas'),
    )!;
    controller.setTool(CanvasTool.pan);
    LinkElement? followed;
    await _pumpCanvas(
      tester,
      controller,
      onFollowLink: (link) => followed = link,
    );

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
    );
    await stylus.down(const Offset(96, 100));
    await stylus.moveBy(const Offset(6, 0));
    await stylus.up();
    await tester.pump();

    expect(followed, link);
  });

  testWidgets('text tool tap reports existing text note', (tester) async {
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.text);
    addTearDown(controller.dispose);
    final TextElement note = controller.placeText(
      worldCenter: const Offset(100, 100),
      text: 'Existing note',
    )!;
    Offset? editAt;
    TextElement? edited;
    await _pumpCanvas(
      tester,
      controller,
      onEditText: (worldCenter, existing) {
        editAt = worldCenter;
        edited = existing;
      },
    );

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
    );
    await stylus.down(const Offset(100, 100));
    await stylus.up();
    await tester.pump();

    expect(editAt, const Offset(100, 100));
    expect(edited, note);
  });

  testWidgets('rotation lock preserves pinch zoom but blocks twist', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..toggleRotationLock();
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);
    await tester.pump();

    final TestGesture first = await tester.createGesture(
      kind: PointerDeviceKind.touch,
    );
    final TestGesture second = await tester.createGesture(
      kind: PointerDeviceKind.touch,
    );

    await first.down(const Offset(100, 100));
    await second.down(const Offset(200, 100));
    await tester.pump();
    await second.moveTo(const Offset(260, 160));
    await tester.pump();

    expect(controller.viewport.scale, greaterThan(1));
    expect(controller.viewport.rotation, 0);

    await second.up();
    await first.up();
  });

  testWidgets('finger drag on selected content moves it directly', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.pen)
      ..addElementToStore(
        const TextElement(
          id: 'note',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(80, 80, 40, 40),
          text: 'Move me',
          color: 0xFFFFFFFF,
          fontSize: 18,
        ),
      )
      ..setSelection(<String>{'note'});
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);

    final TestGesture touch = await tester.createGesture(
      kind: PointerDeviceKind.touch,
    );
    await touch.down(const Offset(100, 100));
    await touch.moveBy(const Offset(40, 10));
    await touch.up();
    await tester.pump();

    final TextElement moved = controller.elements.single as TextElement;
    expect(moved.placementBounds, const Rect.fromLTWH(120, 90, 40, 40));
    expect(controller.activeTool, CanvasTool.pen);
    expect(controller.hasSelection, isTrue);
    expect(controller.viewport, ViewportState.initial);
  });

  testWidgets('two fingers on selected content scale it directly', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..addElementToStore(
        const TextElement(
          id: 'note',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(80, 80, 40, 40),
          text: 'Scale me',
          color: 0xFFFFFFFF,
          fontSize: 18,
        ),
      )
      ..setSelection(<String>{'note'});
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);

    final TestGesture first = await tester.createGesture(
      kind: PointerDeviceKind.touch,
    );
    final TestGesture second = await tester.createGesture(
      kind: PointerDeviceKind.touch,
    );
    await first.down(const Offset(90, 100));
    await second.down(const Offset(110, 100));
    await tester.pump();
    await first.moveTo(const Offset(80, 100));
    await second.moveTo(const Offset(120, 100));
    await tester.pump();
    await second.up();
    await first.up();
    await tester.pump();

    final TextElement scaled = controller.elements.single as TextElement;
    expect(scaled.placementBounds, const Rect.fromLTWH(60, 60, 80, 80));
    expect(scaled.fontSize, 36);
    expect(controller.hasSelection, isTrue);
    expect(controller.canUndo, isTrue);
  });

  testWidgets('stylus moves a sparse selection from its blank frame interior', (
    tester,
  ) async {
    const Rect firstBounds = Rect.fromLTWH(60, 120, 40, 40);
    const Rect secondBounds = Rect.fromLTWH(260, 120, 40, 40);
    const Offset delta = Offset(30, 20);
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.pen)
      ..addElementToStore(_textNote('first', firstBounds))
      ..addElementToStore(_textNote('second', secondBounds, zIndex: 1))
      ..setSelection(<String>{'first', 'second'});
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);

    final SelectionOverlayGeometry geometry = _selectionGeometry(
      tester,
      controller,
    );
    final Offset blankInterior = geometry.centerFor(
      SelectionOverlayTarget.body,
    );
    expect(controller.elementAt(blankInterior), isNull);

    await _dragStylus(tester, blankInterior, blankInterior + delta);

    final Map<String, TextElement> moved = <String, TextElement>{
      for (final TextElement element
          in controller.elements.whereType<TextElement>())
        element.id: element,
    };
    expect(moved['first']!.placementBounds, firstBounds.shift(delta));
    expect(moved['second']!.placementBounds, secondBounds.shift(delta));
    expect(controller.activeTool, CanvasTool.pen);
    expect(controller.selectedIds, <String>{'first', 'second'});
    expect(controller.canUndo, isTrue);
  });

  testWidgets('selection body tap and sub-slop jitter create no history', (
    tester,
  ) async {
    const Rect originalBounds = Rect.fromLTWH(100, 100, 100, 60);
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.pen)
      ..addElementToStore(_textNote('note', originalBounds))
      ..setSelection(<String>{'note'});
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);

    final Offset body = _selectionGeometry(
      tester,
      controller,
    ).centerFor(SelectionOverlayTarget.body);
    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
    );
    await stylus.down(_canvasGlobal(tester, body));
    await stylus.moveTo(_canvasGlobal(tester, body + const Offset(7, 0)));
    await stylus.up();
    await tester.pump();

    final TextElement note = controller.elements.single as TextElement;
    expect(note.placementBounds, originalBounds);
    expect(controller.selectedIds, <String>{'note'});
    expect(controller.isDraggingSelection, isFalse);
    expect(controller.canUndo, isFalse);
  });

  testWidgets('corner handle uniformly scales the selection', (tester) async {
    const Rect originalBounds = Rect.fromLTWH(100, 120, 80, 40);
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.pen)
      ..addElementToStore(_textNote('note', originalBounds))
      ..setSelection(<String>{'note'});
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);

    final SelectionOverlayGeometry geometry = _selectionGeometry(
      tester,
      controller,
    );
    final Offset handle = geometry.centerFor(
      SelectionOverlayTarget.scaleBottomRight,
    );
    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
    );
    await stylus.down(_canvasGlobal(tester, handle));
    await stylus.moveTo(_canvasGlobal(tester, handle + const Offset(40, 30)));
    await tester.pump();
    expect(controller.isTransformingSelection, isTrue);
    expect(controller.selectionTransformPreview!.scale, greaterThan(1));
    await stylus.up();
    await tester.pump();

    final Rect scaled =
        (controller.elements.single as TextElement).placementBounds;
    final double widthScale = scaled.width / originalBounds.width;
    final double heightScale = scaled.height / originalBounds.height;
    expect(widthScale, greaterThan(1));
    expect(heightScale, closeTo(widthScale, 0.000001));
    expect(controller.hasSelection, isTrue);
    expect(controller.activeTool, CanvasTool.pen);
    expect(controller.canUndo, isTrue);
  });

  testWidgets('top rotation handle rotates the selection', (tester) async {
    const Rect originalBounds = Rect.fromLTWH(100, 120, 80, 40);
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.pen)
      ..addElementToStore(_textNote('note', originalBounds))
      ..setSelection(<String>{'note'});
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);

    final SelectionOverlayGeometry geometry = _selectionGeometry(
      tester,
      controller,
    );
    final Offset handle = geometry.centerFor(SelectionOverlayTarget.rotation);
    final double radius = (handle - geometry.frameRect.center).distance;
    final Offset quarterTurn = geometry.frameRect.center + Offset(radius, 0);
    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
    );
    await stylus.down(_canvasGlobal(tester, handle));
    await stylus.moveTo(_canvasGlobal(tester, quarterTurn));
    await tester.pump();
    expect(controller.isTransformingSelection, isTrue);
    expect(
      controller.selectionTransformPreview!.rotation,
      closeTo(math.pi / 2, 0.001),
    );
    await stylus.up();
    await tester.pump();

    final TextElement rotated = controller.elements.single as TextElement;
    expect(rotated.rotation, closeTo(math.pi / 2, 0.001));
    expect(controller.hasSelection, isTrue);
    expect(controller.activeTool, CanvasTool.pen);
    expect(controller.canUndo, isTrue);
  });

  testWidgets('Done handle clears selection without deleting content', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.pen)
      ..addElementToStore(
        _textNote('note', const Rect.fromLTWH(100, 120, 80, 40)),
      )
      ..setSelection(<String>{'note'});
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);

    final Offset done = _selectionGeometry(
      tester,
      controller,
    ).centerFor(SelectionOverlayTarget.done);
    await _tapStylus(tester, done);

    expect(controller.hasSelection, isFalse);
    expect(controller.elementCount, 1);
    expect(controller.elements.single.id, 'note');
    expect(controller.activeTool, CanvasTool.pen);
    expect(controller.canUndo, isFalse);
  });

  testWidgets('outside Pen tap clears without a dot and drag resumes drawing', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.pen)
      ..addElementToStore(
        _textNote('note', const Rect.fromLTWH(100, 120, 80, 40)),
      )
      ..setSelection(<String>{'note'});
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);

    const Offset outsideTap = Offset(340, 340);
    expect(
      _selectionGeometry(tester, controller).hitTest(outsideTap),
      SelectionOverlayTarget.outside,
    );
    await _tapStylus(tester, outsideTap);
    expect(controller.hasSelection, isFalse);
    expect(controller.elementCount, 1);
    expect(controller.liveStroke, isNull);
    expect(controller.canUndo, isFalse);

    controller.setSelection(<String>{'note'});
    await tester.pump();
    const Offset dragStart = Offset(300, 300);
    const Offset dragEnd = Offset(360, 350);
    expect(
      _selectionGeometry(tester, controller).hitTest(dragStart),
      SelectionOverlayTarget.outside,
    );
    await _dragStylus(tester, dragStart, dragEnd);

    expect(controller.hasSelection, isFalse);
    expect(controller.elementCount, 2);
    expect(controller.elements.whereType<InkElement>(), hasLength(1));
    expect(controller.activeTool, CanvasTool.pen);
    expect(controller.canUndo, isTrue);
  });

  testWidgets(
    'cancel restores body scale rotate and background selection sessions',
    (tester) async {
      const Rect originalBounds = Rect.fromLTWH(100, 120, 80, 40);
      const targets = <SelectionOverlayTarget>[
        SelectionOverlayTarget.body,
        SelectionOverlayTarget.scaleBottomRight,
        SelectionOverlayTarget.rotation,
        SelectionOverlayTarget.outside,
      ];

      for (final SelectionOverlayTarget target in targets) {
        final CanvasController controller = CanvasController()
          ..setTool(CanvasTool.pen)
          ..addElementToStore(_textNote('note', originalBounds))
          ..setSelection(<String>{'note'});
        addTearDown(controller.dispose);
        await _pumpCanvas(tester, controller);

        final SelectionOverlayGeometry geometry = _selectionGeometry(
          tester,
          controller,
        );
        final Offset start = switch (target) {
          SelectionOverlayTarget.outside => const Offset(320, 320),
          _ => geometry.centerFor(target),
        };
        final Offset end = switch (target) {
          SelectionOverlayTarget.body => start + const Offset(30, 20),
          SelectionOverlayTarget.scaleBottomRight =>
            start + const Offset(40, 30),
          SelectionOverlayTarget.rotation =>
            geometry.frameRect.center +
                Offset((start - geometry.frameRect.center).distance, 0),
          SelectionOverlayTarget.outside => start + const Offset(40, 30),
          _ => throw StateError('Unexpected cancellation target'),
        };

        final TestGesture stylus = await tester.createGesture(
          kind: PointerDeviceKind.stylus,
        );
        await stylus.down(_canvasGlobal(tester, start));
        await stylus.moveTo(_canvasGlobal(tester, end));
        await tester.pump();
        if (target == SelectionOverlayTarget.body) {
          expect(controller.isDraggingSelection, isTrue);
        } else if (target == SelectionOverlayTarget.outside) {
          expect(controller.hasSelection, isFalse);
          expect(controller.liveStroke, isNotNull);
        } else {
          expect(controller.isTransformingSelection, isTrue);
        }

        await stylus.cancel();
        await tester.pump();

        final TextElement note = controller.elements.single as TextElement;
        expect(
          note.placementBounds,
          originalBounds,
          reason: '$target cancellation changed geometry',
        );
        expect(
          note.rotation,
          0,
          reason: '$target cancellation rotated content',
        );
        expect(controller.selectedIds, <String>{'note'});
        expect(controller.elementCount, 1);
        expect(controller.liveStroke, isNull);
        expect(controller.isDraggingSelection, isFalse);
        expect(controller.isTransformingSelection, isFalse);
        expect(controller.canUndo, isFalse);
      }
    },
  );

  testWidgets('Add and Remove taps are one-shot while Pen stays active', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.pen)
      ..addElementToStore(
        _textNote('first', const Rect.fromLTWH(80, 100, 60, 40)),
      )
      ..addElementToStore(
        _textNote('second', const Rect.fromLTWH(260, 100, 60, 40), zIndex: 1),
      )
      ..setSelection(<String>{'first'})
      ..setSelectionMode(SelectionMode.add);
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);

    await _tapStylus(tester, const Offset(290, 120));
    expect(controller.selectedIds, <String>{'first', 'second'});
    expect(controller.selectionMode, SelectionMode.replace);
    expect(controller.activeTool, CanvasTool.pen);

    controller.setSelectionMode(SelectionMode.subtract);
    await tester.pump();
    await _tapStylus(tester, const Offset(110, 120));
    expect(controller.selectedIds, <String>{'second'});
    expect(controller.selectionMode, SelectionMode.replace);
    expect(controller.activeTool, CanvasTool.pen);
  });

  testWidgets('Add and Remove loops are one-shot while Pen stays active', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.pen)
      ..addElementToStore(
        _textNote('first', const Rect.fromLTWH(80, 100, 60, 40)),
      )
      ..addElementToStore(
        _textNote('second', const Rect.fromLTWH(260, 100, 60, 40), zIndex: 1),
      )
      ..setSelection(<String>{'first'})
      ..setSelectionMode(SelectionMode.add);
    addTearDown(controller.dispose);
    await _pumpCanvas(tester, controller);

    final TestGesture add = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
    );
    await add.down(_canvasGlobal(tester, const Offset(230, 70)));
    await add.moveTo(_canvasGlobal(tester, const Offset(350, 70)));
    await add.moveTo(_canvasGlobal(tester, const Offset(350, 180)));
    await add.moveTo(_canvasGlobal(tester, const Offset(230, 180)));
    await add.up();
    await tester.pump();
    expect(controller.selectedIds, <String>{'first', 'second'});
    expect(controller.selectionMode, SelectionMode.replace);
    expect(controller.activeTool, CanvasTool.pen);

    controller.setSelectionMode(SelectionMode.subtract);
    await tester.pump();
    final TestGesture remove = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
    );
    await remove.down(_canvasGlobal(tester, const Offset(50, 70)));
    await remove.moveTo(_canvasGlobal(tester, const Offset(180, 70)));
    await remove.moveTo(_canvasGlobal(tester, const Offset(180, 180)));
    await remove.moveTo(_canvasGlobal(tester, const Offset(50, 180)));
    await remove.up();
    await tester.pump();
    expect(controller.selectedIds, <String>{'second'});
    expect(controller.selectionMode, SelectionMode.replace);
    expect(controller.activeTool, CanvasTool.pen);
  });

  testWidgets('temporary lasso restores Pen and its selection still moves', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.pen);
    addTearDown(controller.dispose);
    controller.addElementToStore(
      const TextElement(
        id: 'note',
        zIndex: 0,
        worldBounds: Rect.fromLTWH(90, 90, 40, 40),
        text: 'Pick me',
        color: 0xFFFFFFFF,
        fontSize: 18,
      ),
    );
    await _pumpCanvas(
      tester,
      controller,
      stylusButtonMapping: const StylusButtonMapping(
        penLongPress: StylusButtonAction.temporaryLasso,
      ),
    );

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
    );
    await stylus.down(const Offset(60, 60));
    await tester.pump(const Duration(milliseconds: 600));
    await stylus.moveTo(const Offset(160, 60));
    await stylus.moveTo(const Offset(160, 160));
    await stylus.moveTo(const Offset(60, 160));
    await stylus.up();
    await tester.pump();

    expect(controller.selectedIds, <String>{'note'});
    expect(controller.activeTool, CanvasTool.pen);
    expect(controller.liveStroke, isNull);
    expect(controller.elementCount, 1);

    const Offset delta = Offset(30, 10);
    final Offset body = _selectionGeometry(
      tester,
      controller,
    ).centerFor(SelectionOverlayTarget.body);
    await _dragStylus(tester, body, body + delta);

    final TextElement moved = controller.elements.single as TextElement;
    expect(moved.placementBounds, const Rect.fromLTWH(120, 100, 40, 40));
    expect(controller.selectedIds, <String>{'note'});
    expect(controller.activeTool, CanvasTool.pen);
  });

  testWidgets('temporary side-button lasso honors subtract over selection', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.pen)
      ..addElementToStore(
        _textNote('note', const Rect.fromLTWH(80, 100, 60, 40)),
      )
      ..setSelection(<String>{'note'})
      ..setSelectionMode(SelectionMode.subtract);
    addTearDown(controller.dispose);
    await _pumpCanvas(
      tester,
      controller,
      stylusButtonMapping: const StylusButtonMapping(
        drag: StylusButtonAction.temporaryLasso,
        tap: StylusButtonAction.disabled,
        hold: StylusButtonAction.disabled,
        penLongPress: StylusButtonAction.disabled,
      ),
    );

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await stylus.down(_canvasGlobal(tester, const Offset(110, 120)));
    await tester.pump();

    expect(controller.activeTool, CanvasTool.lasso);
    expect(controller.lassoPath, isNotNull);
    expect(controller.isDraggingSelection, isFalse);

    await stylus.cancel();
    await tester.pump();
    expect(controller.activeTool, CanvasTool.pen);
    expect(controller.selectedIds, <String>{'note'});
    expect(controller.selectionMode, SelectionMode.subtract);
  });

  testWidgets('stylus button drag temporarily erases then restores tool', (
    tester,
  ) async {
    final CanvasController controller = CanvasController();
    addTearDown(controller.dispose);
    controller
      ..beginStroke(const Offset(40, 40), 0.5)
      ..appendToStroke(const Offset(160, 40), 0.5)
      ..endStroke()
      ..setTool(CanvasTool.pen);
    await _pumpCanvas(
      tester,
      controller,
      stylusButtonMapping: const StylusButtonMapping(
        tap: StylusButtonAction.disabled,
        drag: StylusButtonAction.temporaryEraser,
      ),
    );

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await stylus.down(const Offset(100, 40));
    await stylus.moveBy(const Offset(20, 0));
    await stylus.up();
    await tester.pump();

    expect(controller.elementCount, 0);
    expect(controller.activeTool, CanvasTool.pen);
  });

  testWidgets('stylus button tap can undo without drawing', (tester) async {
    final CanvasController controller = CanvasController();
    addTearDown(controller.dispose);
    controller
      ..beginStroke(const Offset(40, 40), 0.5)
      ..appendToStroke(const Offset(160, 40), 0.5)
      ..endStroke()
      ..setTool(CanvasTool.pen);
    await _pumpCanvas(
      tester,
      controller,
      stylusButtonMapping: const StylusButtonMapping(
        tap: StylusButtonAction.undo,
        drag: StylusButtonAction.disabled,
      ),
    );

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await stylus.down(const Offset(120, 80));
    await stylus.up();
    await tester.pump();

    expect(controller.elementCount, 0);
    expect(controller.liveStroke, isNull);
  });

  testWidgets('stylus button radial action reports its local tap position', (
    tester,
  ) async {
    final CanvasController controller = CanvasController();
    addTearDown(controller.dispose);
    Offset? quickToolsPosition;
    await _pumpCanvas(
      tester,
      controller,
      onShowQuickTools: (position) => quickToolsPosition = position,
      stylusButtonMapping: const StylusButtonMapping(
        hold: StylusButtonAction.disabled,
        tap: StylusButtonAction.radialMenu,
        drag: StylusButtonAction.disabled,
        penLongPress: StylusButtonAction.disabled,
      ),
    );

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await stylus.down(const Offset(123, 145));
    await stylus.up();
    await tester.pump();

    expect(quickToolsPosition, const Offset(123, 145));
    expect(controller.elementCount, 0);
  });

  testWidgets('stylus button radial drag mapping opens once after movement', (
    tester,
  ) async {
    final CanvasController controller = CanvasController();
    addTearDown(controller.dispose);
    final List<Offset> quickToolsPositions = <Offset>[];
    await _pumpCanvas(
      tester,
      controller,
      onShowQuickTools: quickToolsPositions.add,
      stylusButtonMapping: const StylusButtonMapping(
        tap: StylusButtonAction.disabled,
        drag: StylusButtonAction.radialMenu,
        penLongPress: StylusButtonAction.disabled,
      ),
    );

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await stylus.down(const Offset(90, 110));
    expect(quickToolsPositions, isEmpty);
    await stylus.moveTo(const Offset(140, 150));
    expect(quickToolsPositions, const <Offset>[Offset(140, 150)]);
    await stylus.up();
    await tester.pump();

    expect(quickToolsPositions, const <Offset>[Offset(140, 150)]);
    expect(controller.elementCount, 0);
  });

  testWidgets('an unmoved radial drag mapping still performs its tap action', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.eraser)
      ..setTool(CanvasTool.pen);
    addTearDown(controller.dispose);
    final List<Offset> quickToolsPositions = <Offset>[];
    await _pumpCanvas(
      tester,
      controller,
      onShowQuickTools: quickToolsPositions.add,
      stylusButtonMapping: const StylusButtonMapping(
        tap: StylusButtonAction.togglePreviousTool,
        drag: StylusButtonAction.radialMenu,
        penLongPress: StylusButtonAction.disabled,
      ),
    );

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await stylus.down(const Offset(90, 110));
    await stylus.up();
    await tester.pump();

    expect(quickToolsPositions, isEmpty);
    expect(controller.activeTool, CanvasTool.eraser);
  });

  testWidgets('stationary side-button hold opens radial tools exactly once', (
    tester,
  ) async {
    final CanvasController controller = CanvasController();
    addTearDown(controller.dispose);
    final List<Offset> quickToolsPositions = <Offset>[];
    await _pumpCanvas(
      tester,
      controller,
      onShowQuickTools: quickToolsPositions.add,
      stylusButtonMapping: const StylusButtonMapping(
        hold: StylusButtonAction.radialMenu,
        tap: StylusButtonAction.disabled,
        drag: StylusButtonAction.disabled,
        penLongPress: StylusButtonAction.disabled,
      ),
    );

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await stylus.down(const Offset(150, 170));
    await tester.pump(const Duration(milliseconds: 600));
    expect(quickToolsPositions, const <Offset>[Offset(150, 170)]);
    await tester.pump(const Duration(milliseconds: 600));
    await stylus.up();
    await tester.pump();

    expect(quickToolsPositions, const <Offset>[Offset(150, 170)]);
    expect(controller.elementCount, 0);
  });

  testWidgets('side-button hold temporarily lassos then restores pen', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.pen)
      ..addElementToStore(
        const TextElement(
          id: 'hold-lasso-note',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(90, 90, 20, 20),
          text: 'Pick me',
          color: 0xFFFFFFFF,
          fontSize: 18,
        ),
      );
    addTearDown(controller.dispose);
    await _pumpCanvas(
      tester,
      controller,
      stylusButtonMapping: const StylusButtonMapping(
        hold: StylusButtonAction.temporaryLasso,
        tap: StylusButtonAction.disabled,
        drag: StylusButtonAction.disabled,
        penLongPress: StylusButtonAction.disabled,
      ),
    );

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await stylus.down(const Offset(60, 60));
    await tester.pump(const Duration(milliseconds: 600));
    await stylus.moveTo(const Offset(140, 60));
    await stylus.moveTo(const Offset(140, 140));
    await stylus.moveTo(const Offset(60, 140));
    await stylus.up();
    await tester.pump();

    expect(controller.selectedIds, <String>{'hold-lasso-note'});
    expect(controller.activeTool, CanvasTool.pen);
  });

  testWidgets('side-button hold temporarily erases then restores pen', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..beginStroke(const Offset(40, 40), 0.5)
      ..appendToStroke(const Offset(160, 40), 0.5)
      ..endStroke()
      ..setTool(CanvasTool.pen);
    addTearDown(controller.dispose);
    await _pumpCanvas(
      tester,
      controller,
      stylusButtonMapping: const StylusButtonMapping(
        hold: StylusButtonAction.temporaryEraser,
        tap: StylusButtonAction.disabled,
        drag: StylusButtonAction.disabled,
        penLongPress: StylusButtonAction.disabled,
      ),
    );

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await stylus.down(const Offset(80, 40));
    await tester.pump(const Duration(milliseconds: 600));
    await stylus.moveTo(const Offset(120, 40));
    await stylus.up();
    await tester.pump();

    expect(controller.elementCount, 0);
    expect(controller.activeTool, CanvasTool.pen);
  });

  testWidgets('release before hold timeout cancels preview and performs tap', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..beginStroke(const Offset(40, 40), 0.5)
      ..appendToStroke(const Offset(160, 40), 0.5)
      ..endStroke()
      ..setTool(CanvasTool.eraser)
      ..setTool(CanvasTool.pen);
    addTearDown(controller.dispose);
    final List<Offset> quickToolsPositions = <Offset>[];
    await _pumpCanvas(
      tester,
      controller,
      onShowQuickTools: quickToolsPositions.add,
      stylusButtonMapping: const StylusButtonMapping(
        hold: StylusButtonAction.radialMenu,
        tap: StylusButtonAction.togglePreviousTool,
        drag: StylusButtonAction.temporaryEraser,
        penLongPress: StylusButtonAction.disabled,
      ),
    );

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await stylus.down(const Offset(80, 40));
    await tester.pump(const Duration(milliseconds: 200));
    await stylus.up();
    await tester.pump(const Duration(milliseconds: 500));

    expect(quickToolsPositions, isEmpty);
    expect(controller.elementCount, 1);
    expect(controller.activeTool, CanvasTool.eraser);
  });

  testWidgets('movement uses drag action and cancels pending hold', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..beginStroke(const Offset(40, 40), 0.5)
      ..appendToStroke(const Offset(160, 40), 0.5)
      ..endStroke()
      ..setTool(CanvasTool.pen);
    addTearDown(controller.dispose);
    final List<Offset> quickToolsPositions = <Offset>[];
    await _pumpCanvas(
      tester,
      controller,
      onShowQuickTools: quickToolsPositions.add,
      stylusButtonMapping: const StylusButtonMapping(
        hold: StylusButtonAction.radialMenu,
        tap: StylusButtonAction.disabled,
        drag: StylusButtonAction.temporaryEraser,
        penLongPress: StylusButtonAction.disabled,
      ),
    );

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await stylus.down(const Offset(80, 40));
    await stylus.moveTo(const Offset(120, 40));
    await tester.pump(const Duration(milliseconds: 600));
    await stylus.up();
    await tester.pump();

    expect(quickToolsPositions, isEmpty);
    expect(controller.elementCount, 0);
    expect(controller.activeTool, CanvasTool.pen);
  });

  testWidgets('provisional side-button pan ignores sub-slop jitter', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..setTool(CanvasTool.pen);
    addTearDown(controller.dispose);
    await _pumpCanvas(
      tester,
      controller,
      stylusButtonMapping: const StylusButtonMapping(
        hold: StylusButtonAction.temporaryPan,
        tap: StylusButtonAction.disabled,
        drag: StylusButtonAction.temporaryPan,
        penLongPress: StylusButtonAction.disabled,
      ),
    );

    final TestGesture tap = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await tap.down(const Offset(100, 100));
    await tap.moveTo(const Offset(102, 102));
    await tester.pump(const Duration(milliseconds: 200));
    await tap.up();
    await tester.pump();
    expect(controller.viewport, ViewportState.initial);

    final TestGesture hold = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await hold.down(const Offset(140, 140));
    await hold.moveTo(const Offset(142, 142));
    await tester.pump(const Duration(milliseconds: 600));
    await hold.up();
    await tester.pump();

    expect(controller.viewport, ViewportState.initial);
    expect(controller.activeTool, CanvasTool.pen);
  });

  testWidgets('supported one-shot drag actions dispatch exactly once', (
    tester,
  ) async {
    Future<void> runDrag(
      CanvasController controller,
      StylusButtonAction action, {
      ValueChanged<Offset>? onShowQuickTools,
    }) async {
      await _pumpCanvas(
        tester,
        controller,
        onShowQuickTools: onShowQuickTools,
        stylusButtonMapping: StylusButtonMapping(
          hold: StylusButtonAction.disabled,
          tap: StylusButtonAction.disabled,
          drag: action,
          penLongPress: StylusButtonAction.disabled,
        ),
      );
      final TestGesture stylus = await tester.createGesture(
        kind: PointerDeviceKind.stylus,
        buttons: kPrimaryStylusButton,
      );
      await stylus.down(const Offset(80, 80));
      await stylus.moveTo(const Offset(120, 80));
      await stylus.moveTo(const Offset(160, 80));
      await stylus.up();
      await tester.pump();
    }

    final CanvasController undoController = CanvasController()
      ..beginStroke(const Offset(10, 10), 0.5)
      ..endStroke()
      ..beginStroke(const Offset(20, 20), 0.5)
      ..endStroke();
    final CanvasController redoController = CanvasController()
      ..beginStroke(const Offset(10, 10), 0.5)
      ..endStroke()
      ..beginStroke(const Offset(20, 20), 0.5)
      ..endStroke()
      ..undo()
      ..undo();
    final CanvasController toggleController = CanvasController()
      ..setTool(CanvasTool.eraser)
      ..setTool(CanvasTool.pen);
    final CanvasController radialController = CanvasController();
    addTearDown(undoController.dispose);
    addTearDown(redoController.dispose);
    addTearDown(toggleController.dispose);
    addTearDown(radialController.dispose);

    await runDrag(undoController, StylusButtonAction.undo);
    expect(undoController.elementCount, 1);

    await runDrag(redoController, StylusButtonAction.redo);
    expect(redoController.elementCount, 1);

    await runDrag(toggleController, StylusButtonAction.togglePreviousTool);
    expect(toggleController.activeTool, CanvasTool.eraser);

    final List<Offset> radialPositions = <Offset>[];
    await runDrag(
      radialController,
      StylusButtonAction.radialMenu,
      onShowQuickTools: radialPositions.add,
    );
    expect(radialPositions, const <Offset>[Offset(120, 80)]);
  });

  testWidgets('hold action fires once and suppresses release tap', (
    tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..beginStroke(const Offset(40, 40), 0.5)
      ..appendToStroke(const Offset(160, 40), 0.5)
      ..endStroke();
    addTearDown(controller.dispose);
    await _pumpCanvas(
      tester,
      controller,
      stylusButtonMapping: const StylusButtonMapping(
        hold: StylusButtonAction.undo,
        tap: StylusButtonAction.redo,
        drag: StylusButtonAction.disabled,
        penLongPress: StylusButtonAction.disabled,
      ),
    );

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await stylus.down(const Offset(120, 80));
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.elementCount, 0);
    await tester.pump(const Duration(milliseconds: 600));
    await stylus.up();
    await tester.pump();

    expect(controller.elementCount, 0);
    expect(controller.canRedo, isTrue);
  });

  testWidgets('cancel and dispose prevent pending hold callbacks', (
    tester,
  ) async {
    final CanvasController firstController = CanvasController();
    final CanvasController secondController = CanvasController();
    addTearDown(firstController.dispose);
    addTearDown(secondController.dispose);
    final List<Offset> quickToolsPositions = <Offset>[];
    const StylusButtonMapping mapping = StylusButtonMapping(
      hold: StylusButtonAction.radialMenu,
      tap: StylusButtonAction.disabled,
      drag: StylusButtonAction.disabled,
      penLongPress: StylusButtonAction.disabled,
    );
    await _pumpCanvas(
      tester,
      firstController,
      onShowQuickTools: quickToolsPositions.add,
      stylusButtonMapping: mapping,
    );

    final TestGesture cancelled = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await cancelled.down(const Offset(100, 120));
    await tester.pump(const Duration(milliseconds: 200));
    await cancelled.cancel();
    await tester.pump(const Duration(milliseconds: 500));
    expect(quickToolsPositions, isEmpty);

    await _pumpCanvas(
      tester,
      secondController,
      onShowQuickTools: quickToolsPositions.add,
      stylusButtonMapping: mapping,
    );
    final TestGesture disposed = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await disposed.down(const Offset(160, 180));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
    await disposed.cancel();

    expect(quickToolsPositions, isEmpty);
  });

  testWidgets('cancel and dispose clean up activated temporary holds', (
    tester,
  ) async {
    final CanvasController cancelController = CanvasController()
      ..setTool(CanvasTool.pen);
    final CanvasController disposeController = CanvasController()
      ..setTool(CanvasTool.pen);
    final CanvasController touchController = CanvasController();
    addTearDown(cancelController.dispose);
    addTearDown(disposeController.dispose);
    addTearDown(touchController.dispose);
    const StylusButtonMapping lassoHold = StylusButtonMapping(
      hold: StylusButtonAction.temporaryLasso,
      tap: StylusButtonAction.disabled,
      drag: StylusButtonAction.disabled,
      penLongPress: StylusButtonAction.disabled,
    );

    await _pumpCanvas(tester, cancelController, stylusButtonMapping: lassoHold);
    final TestGesture cancelled = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await cancelled.down(const Offset(100, 100));
    await tester.pump(const Duration(milliseconds: 600));
    expect(cancelController.activeTool, CanvasTool.lasso);
    expect(cancelController.lassoPath, isNotNull);
    await cancelled.cancel();
    await tester.pump();
    expect(cancelController.activeTool, CanvasTool.pen);
    expect(cancelController.lassoPath, isNull);

    await _pumpCanvas(
      tester,
      disposeController,
      stylusButtonMapping: const StylusButtonMapping(
        hold: StylusButtonAction.temporaryEraser,
        tap: StylusButtonAction.disabled,
        drag: StylusButtonAction.disabled,
        penLongPress: StylusButtonAction.disabled,
      ),
    );
    final TestGesture disposed = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
      buttons: kPrimaryStylusButton,
    );
    await disposed.down(const Offset(120, 120));
    await tester.pump(const Duration(milliseconds: 600));
    expect(disposeController.activeTool, CanvasTool.eraser);
    expect(disposeController.eraserPath, isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(disposeController.activeTool, CanvasTool.pen);
    expect(disposeController.eraserPath, isNull);
    await disposed.cancel();

    await _pumpCanvas(tester, touchController);
    final TestGesture touch = await tester.createGesture(
      kind: PointerDeviceKind.touch,
    );
    await touch.down(const Offset(180, 180));
    await tester.pump(const Duration(milliseconds: 600));
    expect(touchController.lassoPath, isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(touchController.lassoPath, isNull);
    await touch.cancel();
  });

  testWidgets('pen long-press radial action opens once without drawing', (
    tester,
  ) async {
    final CanvasController controller = CanvasController();
    addTearDown(controller.dispose);
    final List<Offset> quickToolsPositions = <Offset>[];
    await _pumpCanvas(
      tester,
      controller,
      onShowQuickTools: quickToolsPositions.add,
      stylusButtonMapping: const StylusButtonMapping(
        penLongPress: StylusButtonAction.radialMenu,
      ),
    );

    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
    );
    await stylus.down(const Offset(180, 210));
    await tester.pump(const Duration(milliseconds: 600));
    await stylus.up();
    await tester.pump();

    expect(quickToolsPositions, const <Offset>[Offset(180, 210)]);
    expect(controller.liveStroke, isNull);
    expect(controller.elementCount, 0);
  });
}
