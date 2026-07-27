import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/model/canvas_element.dart';

CanvasController _controllerWithHorizontalStroke() {
  final controller = CanvasController()
    ..beginStroke(const Offset(0, 0), 0.5);
  for (int i = 1; i <= 40; i++) {
    controller.appendToStroke(Offset(i * 10.0, 0), 0.5);
  }
  return controller..endStroke();
}

void main() {
  group('incremental eraser', () {
    test('elements are marked pending as the drag crosses them', () {
      final controller = _controllerWithHorizontalStroke()
        ..setTool(CanvasTool.eraser);
      addTearDown(controller.dispose);
      final String strokeId = controller.elements.single.id;

      // Start well clear of the stroke, then scrub across it.
      controller.beginErase(const Offset(200, 400));
      expect(controller.pendingEraseIds, isEmpty);

      controller.appendErase(const Offset(200, 200));
      expect(
        controller.pendingEraseIds,
        isEmpty,
        reason: 'still nowhere near the stroke',
      );

      controller.appendErase(const Offset(200, 0));
      expect(
        controller.pendingEraseIds,
        contains(strokeId),
        reason: 'the preview must show the hit before the pen lifts',
      );

      controller.endErase();
      expect(controller.pendingEraseIds, isEmpty);
    });

    test('a crossing drag erases, and cancelling does not', () {
      final controller = _controllerWithHorizontalStroke()
        ..setTool(CanvasTool.eraser)
        ..setEraserMode(EraserMode.object);
      addTearDown(controller.dispose);

      controller.beginErase(const Offset(200, 40));
      controller.appendErase(const Offset(200, -40));
      controller.cancelErase();
      expect(controller.elementCount, 1);
      expect(controller.pendingEraseIds, isEmpty);

      controller.beginErase(const Offset(200, 40));
      controller.appendErase(const Offset(200, -40));
      controller.endErase();
      expect(controller.elementCount, 0);
    });

    test('a drag that misses everything erases nothing', () {
      final controller = _controllerWithHorizontalStroke()
        ..setTool(CanvasTool.eraser)
        ..setEraserMode(EraserMode.object);
      addTearDown(controller.dispose);

      controller.beginErase(const Offset(200, 500));
      controller.appendErase(const Offset(260, 500));
      controller.endErase();

      expect(controller.elementCount, 1);
    });

    test('samples closer than the eraser footprint are dropped', () {
      final controller = _controllerWithHorizontalStroke()
        ..setTool(CanvasTool.eraser);
      addTearDown(controller.dispose);

      controller.beginErase(const Offset(0, 300));
      for (int i = 1; i <= 200; i++) {
        controller.appendErase(Offset(i * 0.05, 300));
      }

      // A scrub used to keep every move event; the path is now thinned to the
      // eraser's own radius, which is what bounded the pointer-up hit test.
      expect(controller.eraserPath!.length, lessThan(50));
    });

    test('the exposed path view is stable between reads', () {
      final controller = _controllerWithHorizontalStroke()
        ..setTool(CanvasTool.eraser);
      addTearDown(controller.dispose);

      controller.beginErase(const Offset(0, 300));
      controller.appendErase(const Offset(80, 300));

      // The overlay painter compares by identity, so rebuilding this per read
      // made it repaint unconditionally during a drag.
      expect(identical(controller.eraserPath, controller.eraserPath), isTrue);
    });

    test('partial erase still splits a crossed stroke', () {
      final controller = _controllerWithHorizontalStroke()
        ..setTool(CanvasTool.eraser)
        ..setEraserMode(EraserMode.partial);
      addTearDown(controller.dispose);

      controller.beginErase(const Offset(200, 40));
      controller.appendErase(const Offset(200, -40));
      controller.endErase();

      // The stroke is cut in two where the eraser crossed it.
      expect(controller.elements.whereType<InkElement>().length, 2);
    });
  });
}
