import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/canvas_style.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';

void main() {
  test('default wheel exposes the requested eight direct favorites', () {
    final controller = CanvasController();
    addTearDown(controller.dispose);

    expect(
      controller.toolWheelPresets.map((preset) => preset.kind),
      const <ToolWheelSlotKind>[
        ToolWheelSlotKind.pen,
        ToolWheelSlotKind.pencil,
        ToolWheelSlotKind.highlighter,
        ToolWheelSlotKind.marker,
        ToolWheelSlotKind.airbrush,
        ToolWheelSlotKind.fill,
        ToolWheelSlotKind.eraser,
        ToolWheelSlotKind.lasso,
      ],
    );
  });

  test('switching favorites restores independent brush properties', () {
    final controller = CanvasController();
    addTearDown(controller.dispose);

    controller
      ..selectToolWheelPreset(2)
      ..setPenRgbColor(0xFF123456)
      ..setPenWidth(24)
      ..setPenOpacity(0.4)
      ..setPenSmoothing(0.8)
      ..selectToolWheelPreset(0);

    expect(controller.penKind, StrokeToolKind.pen);
    expect(controller.penWidth, 4);
    expect(controller.penOpacity, 1);

    controller.selectToolWheelPreset(2);

    expect(controller.penKind, StrokeToolKind.highlighter);
    expect(controller.penWidth, 24);
    expect(controller.penOpacity, closeTo(0.4, 1 / 255));
    expect(controller.penColor & 0x00FFFFFF, 0x00123456);
    expect(controller.penProfile.smoothing, 0.8);
  });

  test('Adaptive pen is remembered independently by each brush preset', () {
    final controller = CanvasController();
    addTearDown(controller.dispose);

    expect(controller.adaptivePenEnabled, isTrue);
    controller.setAdaptivePenEnabled(enabled: false);
    expect(controller.adaptivePenEnabled, isFalse);

    controller.selectToolWheelPreset(1);
    expect(controller.adaptivePenEnabled, isTrue);

    controller.selectToolWheelPreset(0);
    expect(controller.adaptivePenEnabled, isFalse);
  });

  test('changing Adaptive pen never rewrites existing stroke width', () {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    controller
      ..setPenWidth(10)
      ..setViewport(const ViewportState(translation: Offset.zero, scale: 2))
      ..beginStroke(const Offset(0, 0), 0.5)
      ..appendToStroke(const Offset(20, 20), 0.5)
      ..endStroke();
    final double committedWidth =
        (controller.elements.single as InkElement).stroke.width;

    controller
      ..setAdaptivePenEnabled(enabled: false)
      ..setViewport(const ViewportState(translation: Offset.zero, scale: 4));

    expect(
      (controller.elements.single as InkElement).stroke.width,
      committedWidth,
    );
    expect(committedWidth, 5);
  });

  test('a favorite can be replaced with a duplicate brush or utility', () {
    final controller = CanvasController();
    addTearDown(controller.dispose);

    controller.replaceToolWheelPreset(1, ToolWheelSlotKind.pen);

    expect(controller.toolWheelPresets[0].kind, ToolWheelSlotKind.pen);
    expect(controller.toolWheelPresets[1].kind, ToolWheelSlotKind.pen);
    expect(controller.activeToolWheelIndex, 1);
    expect(controller.activeTool, CanvasTool.pen);

    controller.replaceToolWheelPreset(1, ToolWheelSlotKind.pan);

    expect(controller.toolWheelPresets[1].kind, ToolWheelSlotKind.pan);
    expect(controller.activeTool, CanvasTool.pan);
  });
}
