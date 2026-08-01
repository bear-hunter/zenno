import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/stroke.dart';

void main() {
  testWidgets('live pen samples do not notify toolbar or committed elements', (
    tester,
  ) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    var liveNotifications = 0;
    var toolNotifications = 0;
    var elementNotifications = 0;
    controller.liveStrokeListenable.addListener(() => liveNotifications++);
    controller.toolStateListenable.addListener(() => toolNotifications++);
    controller.elementsListenable.addListener(() => elementNotifications++);

    controller.beginStroke(const Offset(0, 0), 0.5);
    controller.appendToStroke(const Offset(20, 20), 0.5);
    await tester.pump();

    expect(liveNotifications, greaterThanOrEqualTo(2));
    expect(toolNotifications, 0);
    expect(elementNotifications, 0);
  });

  test('hover changes only the hover channel', () {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    var hoverNotifications = 0;
    var overlayNotifications = 0;
    var elementNotifications = 0;
    controller.hoverListenable.addListener(() => hoverNotifications++);
    controller.overlayListenable.addListener(() => overlayNotifications++);
    controller.elementsListenable.addListener(() => elementNotifications++);

    controller.setHoverPoint(const Offset(10, 12));

    expect(hoverNotifications, 1);
    // Hover fires at the S Pen's report rate whenever the pen is near the
    // glass; routing it through the overlay channel repainted the whole
    // full-screen overlay layer per report just to move one small ring.
    expect(overlayNotifications, 0);
    expect(elementNotifications, 0);
  });

  test('dragging a selection does not wake the committed element layer', () {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    controller.addElementToStore(
      InkElement.fromStroke(
        const Stroke(
          id: 'a',
          points: <StrokePoint>[StrokePoint(0, 0, 0.5), StrokePoint(40, 40, 0.5)],
          color: 0xFFFFFFFF,
          width: 4,
        ),
        zIndex: 0,
      ),
    );
    controller.setSelection(<String>['a']);
    controller.beginSelectionDrag();

    var elementNotifications = 0;
    var selectionNotifications = 0;
    var previewNotifications = 0;
    var overlayNotifications = 0;
    controller.elementsListenable.addListener(() => elementNotifications++);
    controller.selectionListenable.addListener(() => selectionNotifications++);
    controller.selectionPreviewListenable.addListener(
      () => previewNotifications++,
    );
    controller.overlayListenable.addListener(() => overlayNotifications++);

    controller.updateSelectionDrag(const Offset(8, 0));
    controller.updateSelectionDrag(const Offset(8, 0));

    // The preview layer and the selection box follow the pointer; the committed
    // layer does not. Waking it here re-culled, re-sorted and re-painted every
    // visible element once per sample, which is what made dragging a big lasso
    // selection crawl.
    expect(previewNotifications, 2);
    expect(overlayNotifications, 2);
    expect(selectionNotifications, 0);
    expect(elementNotifications, 0);
  });

  test('starting and ending a drag does wake the committed layer', () {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    controller.addElementToStore(
      InkElement.fromStroke(
        const Stroke(
          id: 'a',
          points: <StrokePoint>[StrokePoint(0, 0, 0.5), StrokePoint(40, 40, 0.5)],
          color: 0xFFFFFFFF,
          width: 4,
        ),
        zIndex: 0,
      ),
    );
    controller.setSelection(<String>['a']);

    var selectionNotifications = 0;
    controller.selectionListenable.addListener(() => selectionNotifications++);

    // Both ends of the gesture change which layer owns the selection, so the
    // committed layer has to hear about them.
    controller.beginSelectionDrag();
    expect(controller.isFloatingSelection, isTrue);
    expect(selectionNotifications, 1);

    controller.updateSelectionDrag(const Offset(20, 0));
    controller.endSelectionDrag();
    expect(controller.isFloatingSelection, isFalse);
    expect(selectionNotifications, greaterThan(1));
  });

  test('tool changes do not notify grid or committed elements', () {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    var toolNotifications = 0;
    var styleNotifications = 0;
    var elementNotifications = 0;
    controller.toolStateListenable.addListener(() => toolNotifications++);
    controller.canvasStyleListenable.addListener(() => styleNotifications++);
    controller.elementsListenable.addListener(() => elementNotifications++);

    controller.setPenWidth(12);

    expect(toolNotifications, 1);
    expect(styleNotifications, 0);
    expect(elementNotifications, 0);
  });
}
