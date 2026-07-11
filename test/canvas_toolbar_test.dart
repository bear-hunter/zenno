import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/canvas_style.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/render/canvas_view.dart';
import 'package:zenno/canvas/widgets/canvas_toolbar.dart';
import 'package:zenno/core/database/tables/canvas_tables.dart';

Future<void> _pumpToolbar(
  WidgetTester tester,
  CanvasController controller, {
  ValueChanged<List<int>>? onPaletteChanged,
  Widget? title,
  List<int> palette = const <int>[],
  bool includeCanvas = false,
  MediaQueryData? mediaQuery,
}) async {
  Widget home = Scaffold(
    body: Stack(
      children: [
        if (includeCanvas)
          Positioned.fill(child: CanvasView(controller: controller)),
        Positioned.fill(
          child: CanvasToolbar(
            controller: controller,
            onBack: () {},
            title: title,
            palette: palette,
            onPaletteChanged: onPaletteChanged,
          ),
        ),
      ],
    ),
  );
  if (mediaQuery != null) {
    home = MediaQuery(data: mediaQuery, child: home);
  }
  await tester.pumpWidget(MaterialApp(home: home));
}

Finder _presetButton(int index) => find.byKey(
  ValueKey<String>('${CanvasToolbar.toolButtonKeyPrefix}-preset-$index'),
);

Finder _swatch(int index) => find.byKey(
  ValueKey<String>('${CanvasToolbar.swatchButtonKeyPrefix}-$index'),
);

Future<void> _openMore(WidgetTester tester) async {
  await tester.tap(find.byKey(CanvasToolbar.canvasSettingsDockKey));
  await tester.pumpAndSettle();
}

Future<void> _drawStylusStroke(
  WidgetTester tester,
  Offset start,
  Offset end,
) async {
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.stylus,
  );
  await gesture.down(start);
  await gesture.moveTo(end);
  await gesture.up();
}

void main() {
  testWidgets('wheel and attached palette stay visible after drawing', (
    tester,
  ) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    expect(find.byKey(CanvasToolbar.minimalToolMenuKey), findsOneWidget);
    expect(find.byKey(CanvasToolbar.compactDrawingPadKey), findsOneWidget);
    expect(_swatch(0), findsOneWidget);
    expect(_swatch(5), findsOneWidget);
    expect(find.byKey(CanvasToolbar.pinControlsKey), findsNothing);
    expect(find.byKey(CanvasToolbar.hideControlsKey), findsNothing);

    controller
      ..beginStroke(const Offset(20, 20), 0.5)
      ..appendToStroke(const Offset(80, 80), 0.5)
      ..endStroke();
    await tester.pump();

    expect(find.byKey(CanvasToolbar.minimalToolMenuKey), findsOneWidget);
    expect(_swatch(0), findsOneWidget);
    expect(_swatch(5), findsOneWidget);
  });

  testWidgets('eight wheel sectors are stable remembered favorites', (
    tester,
  ) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    const kinds = <ToolWheelSlotKind>[
      ToolWheelSlotKind.pen,
      ToolWheelSlotKind.pencil,
      ToolWheelSlotKind.highlighter,
      ToolWheelSlotKind.marker,
      ToolWheelSlotKind.airbrush,
      ToolWheelSlotKind.fill,
      ToolWheelSlotKind.eraser,
      ToolWheelSlotKind.lasso,
    ];
    for (var index = 0; index < kinds.length; index++) {
      expect(_presetButton(index), findsOneWidget);
      expect(controller.toolWheelPresets[index].kind, kinds[index]);
    }
    expect(find.byKey(CanvasToolbar.canvasSettingsDockKey), findsOneWidget);

    for (var index = 1; index < kinds.length; index++) {
      await tester.tap(_presetButton(index));
      await tester.pump();
      expect(controller.activeToolWheelIndex, index);
    }
    await tester.tap(_presetButton(0));
    await tester.pump();
    expect(controller.activeToolWheelIndex, 0);
  });

  testWidgets('center edits color and inner ring edits remembered properties', (
    tester,
  ) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    expect(find.byTooltip('Size: 4 pt'), findsOneWidget);
    expect(find.byTooltip('Opacity: 100%'), findsOneWidget);
    expect(find.byTooltip('Smoothing: 35%'), findsOneWidget);

    await tester.tap(find.byKey(CanvasToolbar.wheelCenterKey));
    await tester.pumpAndSettle();
    expect(find.text('Tool colour'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Size: 4 pt'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '8 pt'));
    await tester.pump();
    expect(controller.penWidth, 8);
    await tester.tapAt(const Offset(760, 30));
    await tester.pumpAndSettle();

    await tester.tap(_presetButton(0));
    await tester.pumpAndSettle();
    expect(find.text('Replace favorite 1'), findsOneWidget);
    await tester.tap(find.text('Airbrush').last);
    await tester.pumpAndSettle();
    expect(controller.activeToolWheelPreset.kind, ToolWheelSlotKind.airbrush);
    expect(controller.penKind, StrokeToolKind.airbrush);
    expect(_swatch(0), findsOneWidget);
  });

  testWidgets('utility favorites open context settings and can be replaced', (
    tester,
  ) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    await tester.tap(_presetButton(6));
    await tester.pump();
    await tester.tap(find.byTooltip('Eraser settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Split strokes'));
    await tester.pump();
    expect(controller.eraserMode, EraserMode.partial);
    expect(_swatch(0), findsOneWidget);
    await tester.tapAt(const Offset(760, 30));
    await tester.pumpAndSettle();

    controller.replaceToolWheelPreset(7, ToolWheelSlotKind.pan);
    await tester.pump();
    expect(controller.activeTool, CanvasTool.pan);
    await tester.tap(find.byTooltip('Pan settings'));
    await tester.pumpAndSettle();
    expect(find.text('Drag to move the canvas'), findsOneWidget);
    expect(_swatch(0), findsOneWidget);
  });

  testWidgets('palette remains available for every tool and preserves it', (
    tester,
  ) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    for (final CanvasTool tool in CanvasTool.values) {
      controller.setTool(tool);
      await tester.pump();
      expect(_swatch(0), findsOneWidget, reason: 'palette missing for $tool');
    }

    controller.setTool(CanvasTool.lasso);
    await tester.pump();
    await tester.tap(_swatch(0));
    await tester.pump();

    expect(controller.penColor, 0xFFFF4F91);
    expect(controller.activeTool, CanvasTool.lasso);
  });

  testWidgets('long custom palettes scroll and keep the selected tool', (
    tester,
  ) async {
    final colors = <int>[
      for (var index = 0; index < 12; index++)
        0xFF000000 | (index * 0x00111111),
    ];
    final controller = CanvasController()..setTool(CanvasTool.eraser);
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller, palette: colors);

    final Finder last = _swatch(colors.length - 1);
    expect(last, findsOneWidget);
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    await tester.tap(last);
    await tester.pump();

    expect(controller.penColor, colors.last);
    expect(controller.activeTool, CanvasTool.eraser);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'former bars plus transparent wheel corners and gaps draw through',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = CanvasController();
      addTearDown(controller.dispose);
      await _pumpToolbar(tester, controller, includeCanvas: true);

      await _drawStylusStroke(
        tester,
        const Offset(170, 28),
        const Offset(220, 28),
      );
      await _drawStylusStroke(
        tester,
        const Offset(300, 575),
        const Offset(360, 575),
      );
      await _drawStylusStroke(
        tester,
        const Offset(28, 350),
        const Offset(28, 410),
      );

      final Rect wheel = tester.getRect(
        find.byKey(CanvasToolbar.minimalToolMenuKey),
      );
      await _drawStylusStroke(
        tester,
        wheel.topLeft + const Offset(3, 3),
        wheel.topLeft + const Offset(13, 3),
      );

      final double innerRadius = wheel.width * 58 / 176;
      final double radius = (wheel.width / 2 + innerRadius) / 2;
      const double firstGapAngle = -math.pi * 3 / 8;
      await _drawStylusStroke(
        tester,
        wheel.center + Offset.fromDirection(firstGapAngle, radius),
        wheel.center + Offset.fromDirection(firstGapAngle, radius + 10),
      );
      await tester.pump();

      expect(controller.elementCount, 5);
    },
  );

  testWidgets('wheel and palette respect 320x600 safe insets', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(
      tester,
      controller,
      mediaQuery: const MediaQueryData(
        size: Size(320, 600),
        padding: EdgeInsets.fromLTRB(12, 24, 8, 20),
      ),
    );

    expect(tester.takeException(), isNull);
    final Rect wheel = tester.getRect(
      find.byKey(CanvasToolbar.compactDrawingPadKey),
    );
    expect(wheel.left, greaterThanOrEqualTo(12));
    expect(wheel.top, greaterThanOrEqualTo(24));
    expect(wheel.right, lessThanOrEqualTo(312));
    expect(wheel.bottom, lessThanOrEqualTo(580));

    Rect palette = tester.getRect(_swatch(0));
    for (var index = 1; index < 6; index++) {
      palette = palette.expandToInclude(tester.getRect(_swatch(index)));
    }
    expect(palette.left, greaterThanOrEqualTo(12));
    expect(palette.right, lessThanOrEqualTo(312));
    expect(palette.bottom, lessThanOrEqualTo(580));
    expect((palette.top - wheel.bottom).abs(), lessThanOrEqualTo(8));
    expect(find.byKey(CanvasToolbar.minimalBackKey), findsOneWidget);
  });

  testWidgets('save failures remain actionable beside wheel and palette', (
    tester,
  ) async {
    final controller = _UnsavedCanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    final Finder warning = find.byKey(CanvasToolbar.minimalSaveErrorKey);
    expect(warning, findsOneWidget);
    expect(tester.getSize(warning).shortestSide, greaterThanOrEqualTo(44));
    expect(find.byKey(CanvasToolbar.minimalToolMenuKey), findsOneWidget);
    expect(_swatch(0), findsOneWidget);

    await tester.tap(warning);
    await tester.pumpAndSettle();
    expect(find.text('Canvas not saved'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
  });

  testWidgets('nested More wheels expose document actions at 320px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller, onPaletteChanged: (_) {});

    await _openMore(tester);
    expect(find.byTooltip('Insert'), findsOneWidget);
    expect(find.byTooltip('Layers'), findsOneWidget);
    expect(find.byTooltip('Export'), findsOneWidget);
    expect(find.byTooltip('Appearance'), findsOneWidget);
    expect(find.byTooltip('View and gestures'), findsOneWidget);
    expect(find.byTooltip('Clear canvas'), findsOneWidget);
    expect(find.byTooltip('Show drawing tools'), findsOneWidget);
    expect(_swatch(0), findsOneWidget);

    await tester.tap(find.byTooltip('View and gestures'));
    await tester.pump();
    expect(find.byTooltip('Back to more actions'), findsOneWidget);
    expect(find.byTooltip('Enable snap to grid'), findsOneWidget);
    expect(find.byTooltip('Lock rotation'), findsOneWidget);
    expect(find.byTooltip('Reset view'), findsOneWidget);
    expect(_swatch(0), findsOneWidget);

    final Finder guide = find.byKey(CanvasToolbar.gestureGuideKey);
    await tester.tap(guide);
    await tester.pumpAndSettle();

    expect(find.text('Finger drag or pinch'), findsOneWidget);
    expect(find.text('Two-finger tap'), findsOneWidget);
    expect(find.text('Three-finger tap'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('More toggles snap and rotation lock', (tester) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    await _openMore(tester);
    await tester.tap(find.byTooltip('View and gestures'));
    await tester.pump();
    final Finder snap = find.byTooltip('Enable snap to grid');
    await tester.tap(snap);
    await tester.pump();
    expect(controller.snapToGridEnabled, isTrue);

    final Finder rotation = find.byTooltip('Lock rotation');
    await tester.tap(rotation);
    await tester.pump();
    expect(controller.rotationLocked, isTrue);
  });

  testWidgets('palette editor applies presets from More', (tester) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    var savedPalette = <int>[];
    await _pumpToolbar(
      tester,
      controller,
      onPaletteChanged: (next) => savedPalette = next,
    );

    await _openMore(tester);
    await tester.tap(find.byTooltip('Appearance'));
    await tester.pump();
    final Finder edit = find.byTooltip('Edit palette');
    await tester.tap(edit);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          '${CanvasToolbar.palettePresetButtonKeyPrefix}-2',
        ),
      ),
    );
    await tester.pump();
    final Finder save = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(savedPalette, isNotEmpty);
    expect(savedPalette.first, 0xFFF2C94C);
  });

  testWidgets('paper action still applies background and grid presets', (
    tester,
  ) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    await _openMore(tester);
    await tester.tap(find.byTooltip('Appearance'));
    await tester.pump();
    final Finder paper = find.byTooltip('Paper');
    await tester.tap(paper);
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(CanvasToolbar.paperSettingsPanelKey)).left,
      closeTo(18, 0.1),
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          '${CanvasToolbar.paperKindButtonKeyPrefix}-BackgroundKind.lined',
        ),
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          '${CanvasToolbar.paperBackgroundPresetButtonKeyPrefix}-5',
        ),
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          '${CanvasToolbar.paperGridPresetButtonKeyPrefix}-1',
        ),
      ),
    );
    await tester.pump();
    final Finder save = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(controller.paperStyle.kind, BackgroundKind.lined);
    expect(controller.paperStyle.backgroundColor, 0xFFF7F1DE);
    expect(controller.paperStyle.gridColor, 0xFF8EC5FF);
  });

  testWidgets('selection does not replace the eight favorite slots', (
    tester,
  ) async {
    final controller = CanvasController()
      ..addElementToStore(
        const TextElement(
          id: 'note',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(-50, -10, 100, 20),
          text: 'Select',
          color: 0xFFFFFFFF,
          fontSize: 18,
        ),
      )
      ..setSelection(<String>{'note'});
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    for (var index = 0; index < 8; index++) {
      expect(_presetButton(index), findsOneWidget);
    }
    expect(
      find.descendant(
        of: find.byKey(CanvasToolbar.wheelCenterKey),
        matching: find.text('Pen'),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Done selecting'), findsOneWidget);
  });

  testWidgets('selection modes remain available from the Select favorite', (
    tester,
  ) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    await tester.tap(_presetButton(7));
    await tester.pump();
    await tester.tap(find.byTooltip('Select settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to selection once'));
    await tester.pump();
    expect(controller.selectionMode, SelectionMode.add);

    await tester.tap(find.byTooltip('Remove from selection once'));
    await tester.pump();
    expect(controller.selectionMode, SelectionMode.subtract);
    expect(controller.activeTool, CanvasTool.lasso);
  });

  testWidgets('favorites remember independent color and size', (tester) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(
      tester,
      controller,
      palette: const <int>[0xFFFF4F91, 0xFFFFFFFF],
    );

    await tester.tap(_presetButton(2));
    await tester.pump();
    await tester.tap(_swatch(0));
    controller.setPenWidth(24);
    await tester.pump();

    await tester.tap(_presetButton(0));
    await tester.pump();
    expect(controller.penWidth, 4);
    expect(controller.penColor & 0x00FFFFFF, 0x00FFFFFF);

    await tester.tap(_presetButton(2));
    await tester.pump();
    expect(controller.penWidth, 24);
    expect(controller.penColor & 0x00FFFFFF, 0x00FF4F91);
  });

  testWidgets('long-press favorite opens the replacement library', (
    tester,
  ) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    await tester.longPress(_presetButton(1));
    await tester.pumpAndSettle();
    expect(find.text('Replace favorite 2'), findsOneWidget);
    expect(find.text('Freeform fill'), findsOneWidget);
    expect(find.text('Marker'), findsOneWidget);
    expect(find.text('Airbrush'), findsOneWidget);
    await tester.tap(find.text('Pen').last);
    await tester.pumpAndSettle();

    expect(controller.toolWheelPresets[0].kind, ToolWheelSlotKind.pen);
    expect(controller.toolWheelPresets[1].kind, ToolWheelSlotKind.pen);
  });

  testWidgets('More exposes enabled image and PDF actions', (tester) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    await _openMore(tester);
    await tester.tap(find.byTooltip('Insert'));
    await tester.pump();
    final Finder image = find.byKey(CanvasToolbar.importImageKey);
    final Finder pdf = find.byKey(CanvasToolbar.importPdfKey);
    expect(image, findsOneWidget);
    expect(pdf, findsOneWidget);
    expect(find.byTooltip('Insert image'), findsOneWidget);
    expect(find.byTooltip('Insert PDF'), findsOneWidget);
  });

  testWidgets('More disables image and PDF actions while importing', (
    tester,
  ) async {
    final controller = _ImportingCanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    await _openMore(tester);
    expect(find.byTooltip('Importing'), findsOneWidget);
    expect(find.byKey(CanvasToolbar.importImageKey), findsNothing);
    expect(find.byKey(CanvasToolbar.importPdfKey), findsNothing);
    expect(find.byTooltip('Back to more actions'), findsNothing);
  });

  testWidgets('clear canvas remains confirmed through More', (tester) async {
    final controller = CanvasController()
      ..addElementToStore(
        const TextElement(
          id: 'keep-until-confirmed',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(0, 0, 100, 50),
          text: 'Keep me',
          color: 0xFFFFFFFF,
          fontSize: 18,
        ),
      );
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    await _openMore(tester);
    final Finder clear = find.byTooltip('Clear canvas');
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(find.text('Clear canvas?'), findsOneWidget);
    expect(controller.elements, hasLength(1));

    await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
    await tester.pumpAndSettle();
    expect(controller.elements, isEmpty);
  });
}

class _ImportingCanvasController extends CanvasController {
  @override
  bool get isImporting => true;
}

class _UnsavedCanvasController extends CanvasController {
  @override
  bool get hasSaveError => true;

  @override
  bool get hasUnsavedWrites => true;
}
