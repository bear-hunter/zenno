import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';

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
