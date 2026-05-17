import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/render/canvas_view.dart';

Future<void> _pumpCanvas(
  WidgetTester tester,
  CanvasController controller, {
  void Function(Offset worldCenter)? onPlaceLink,
  void Function(LinkElement link)? onFollowLink,
  void Function(Offset worldCenter, TextElement? existing)? onEditText,
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
          ),
        ),
      ),
    ),
  );
}

void main() {
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
    );
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
    );
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
}
