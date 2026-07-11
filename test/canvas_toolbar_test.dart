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

Finder _toolButton(CanvasTool tool) =>
    find.byKey(ValueKey<String>('${CanvasToolbar.toolButtonKeyPrefix}-$tool'));

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

  testWidgets('eight wheel sectors map to seven tools and More', (
    tester,
  ) async {
    final controller = CanvasController()..setTool(CanvasTool.pan);
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    const tools = <CanvasTool>[
      CanvasTool.pen,
      CanvasTool.eraser,
      CanvasTool.lasso,
      CanvasTool.shape,
      CanvasTool.text,
      CanvasTool.link,
      CanvasTool.pan,
    ];
    for (final tool in tools) {
      expect(_toolButton(tool), findsOneWidget);
    }
    expect(find.byKey(CanvasToolbar.canvasSettingsDockKey), findsOneWidget);

    final Rect wheel = tester.getRect(
      find.byKey(CanvasToolbar.minimalToolMenuKey),
    );
    final double innerRadius = wheel.width * 40 / 176;
    final double radius = (wheel.width / 2 + innerRadius) / 2;
    const double sweep = math.pi * 2 / 8;
    for (var index = 0; index < tools.length; index++) {
      final double angle = -math.pi / 2 + index * sweep;
      await tester.tapAt(
        wheel.center +
            Offset(math.cos(angle) * radius, math.sin(angle) * radius),
      );
      await tester.pump();
      expect(controller.activeTool, tools[index]);
    }

    const double moreAngle = -math.pi / 2 + 7 * sweep;
    await tester.tapAt(
      wheel.center +
          Offset(math.cos(moreAngle) * radius, math.sin(moreAngle) * radius),
    );
    await tester.pump();
    expect(find.byTooltip('Undo'), findsOneWidget);
    expect(find.byTooltip('Insert'), findsOneWidget);
    expect(find.byTooltip('Appearance'), findsOneWidget);
    expect(find.byTooltip('View and gestures'), findsOneWidget);
    expect(_swatch(0), findsOneWidget);
  });

  testWidgets('center swaps to pen context ring without hiding palette', (
    tester,
  ) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    await tester.tap(find.byTooltip('Draw settings'));
    await tester.pump();

    expect(find.byTooltip('Show drawing tools'), findsOneWidget);
    expect(find.byTooltip('Pencil'), findsOneWidget);
    expect(find.byTooltip('Thicker'), findsOneWidget);
    expect(find.byTooltip('Screen width'), findsOneWidget);
    expect(_swatch(0), findsOneWidget);

    await tester.tap(find.byTooltip('Pencil'));
    await tester.pump();
    expect(controller.penKind, StrokeToolKind.pencil);

    await tester.tap(find.byTooltip('Thicker'));
    await tester.pump();
    expect(controller.penWidth, 8);

    await tester.tap(find.byTooltip('Screen width'));
    await tester.pump();
    expect(controller.penWidthMode, PenWidthMode.canvas);

    await tester.tap(find.byTooltip('Show drawing tools'));
    await tester.pump();
    expect(_toolButton(CanvasTool.eraser), findsOneWidget);
    expect(_swatch(0), findsOneWidget);
  });

  testWidgets('eraser and pan settings are available in context rings', (
    tester,
  ) async {
    final controller = CanvasController()..setTool(CanvasTool.eraser);
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    await tester.tap(find.byTooltip('Eraser settings'));
    await tester.pump();
    await tester.tap(find.byTooltip('Split strokes'));
    await tester.tap(find.byTooltip('Eraser 32'));
    await tester.pump();
    expect(controller.eraserMode, EraserMode.partial);
    expect(controller.eraserRadius, 32);
    expect(_swatch(0), findsOneWidget);

    await tester.tap(find.byTooltip('Show drawing tools'));
    controller.setTool(CanvasTool.pan);
    await tester.pump();
    await tester.tap(find.byTooltip('Pan settings'));
    await tester.pump();
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    expect(controller.viewport.scale, greaterThan(1));
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

      final double innerRadius = wheel.width * 40 / 176;
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

  testWidgets(
    'selection count replaces every tool summary and opens eight actions',
    (tester) async {
      final controller = CanvasController()..setTool(CanvasTool.pen);
      addTearDown(controller.dispose);
      controller
        ..addElementToStore(
          const TextElement(
            id: 'first-note',
            zIndex: 0,
            worldBounds: Rect.fromLTWH(-50, -10, 100, 20),
            text: 'First',
            color: 0xFFFFFFFF,
            fontSize: 18,
          ),
        )
        ..addElementToStore(
          const TextElement(
            id: 'second-note',
            zIndex: 1,
            worldBounds: Rect.fromLTWH(80, -10, 100, 20),
            text: 'Second',
            color: 0xFFFFFFFF,
            fontSize: 18,
          ),
        )
        ..setSelection(<String>{'first-note', 'second-note'});
      await _pumpToolbar(tester, controller);

      for (final CanvasTool tool in CanvasTool.values) {
        controller.setTool(tool);
        await tester.pump();
        expect(
          find.descendant(
            of: find.byKey(CanvasToolbar.wheelCenterKey),
            matching: find.text('2 selected'),
          ),
          findsOneWidget,
          reason: 'selection count hidden behind $tool summary',
        );
        expect(find.byTooltip('Selection actions'), findsOneWidget);
      }

      await tester.tap(find.byKey(CanvasToolbar.wheelCenterKey));
      await tester.pumpAndSettle();

      const actions = <String>[
        'Done selecting',
        'Delete selection',
        'Add to selection once',
        'Remove from selection once',
        'Rotate selection left',
        'Rotate selection right',
        'Scale selection down',
        'Scale selection up',
      ];
      for (final action in actions) {
        expect(find.byTooltip(action), findsAtLeastNWidgets(1));
      }
      expect(find.byTooltip('Show drawing tools'), findsOneWidget);
    },
  );

  testWidgets('selection modes preserve Pen and Done restores its center', (
    tester,
  ) async {
    final controller = CanvasController()..setTool(CanvasTool.pen);
    addTearDown(controller.dispose);
    controller
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
    await _pumpToolbar(tester, controller);

    await tester.tap(find.byKey(CanvasToolbar.wheelCenterKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to selection once').last);
    await tester.pumpAndSettle();
    expect(controller.selectionMode, SelectionMode.add);
    expect(controller.activeTool, CanvasTool.pen);

    await tester.tap(find.byTooltip('Remove from selection once').last);
    await tester.pumpAndSettle();
    expect(controller.selectionMode, SelectionMode.subtract);
    expect(controller.activeTool, CanvasTool.pen);

    await tester.tap(find.byTooltip('Done selecting').last);
    await tester.pumpAndSettle();
    expect(controller.hasSelection, isFalse);
    expect(controller.activeTool, CanvasTool.pen);
    expect(find.byTooltip('Draw settings'), findsOneWidget);
    expect(find.byTooltip('Selection actions'), findsNothing);
  });

  testWidgets('selection ring rotates and scales without changing tools', (
    tester,
  ) async {
    final controller = CanvasController()..setTool(CanvasTool.pen);
    addTearDown(controller.dispose);
    controller
      ..addElementToStore(
        const TextElement(
          id: 'note',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(-50, -10, 100, 20),
          text: 'Transform',
          color: 0xFFFFFFFF,
          fontSize: 18,
        ),
      )
      ..setSelection(<String>{'note'});
    await _pumpToolbar(tester, controller);

    await tester.tap(find.byKey(CanvasToolbar.wheelCenterKey));
    await tester.pump();
    await tester.tap(find.byTooltip('Rotate selection right'));
    await tester.pump();

    var note = controller.elements.single as TextElement;
    expect(note.rotation, greaterThan(0));
    final double widthBefore = note.placementBounds.width;
    await tester.tap(find.byTooltip('Scale selection up'));
    await tester.pump();
    note = controller.elements.single as TextElement;
    expect(note.placementBounds.width, greaterThan(widthBefore));
    expect(controller.activeTool, CanvasTool.pen);
    expect(controller.hasSelection, isTrue);
  });

  testWidgets('long-press selection center keeps fine-adjustment fallback', (
    tester,
  ) async {
    final controller = CanvasController()..setTool(CanvasTool.pen);
    addTearDown(controller.dispose);
    controller
      ..addElementToStore(
        const TextElement(
          id: 'note',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(-50, -10, 100, 20),
          text: 'Transform',
          color: 0xFFFFFFFF,
          fontSize: 18,
        ),
      )
      ..setSelection(<String>{'note'});
    await _pumpToolbar(tester, controller);

    await tester.longPress(find.byKey(CanvasToolbar.wheelCenterKey));
    await tester.pumpAndSettle();
    final Finder rotate = find.byTooltip('Rotate selection right');
    final Finder scale = find.byTooltip('Scale selection up');
    expect(rotate, findsOneWidget);
    expect(scale, findsOneWidget);
    await tester.ensureVisible(rotate);
    await tester.tap(rotate);
    await tester.pump();

    final note = controller.elements.single as TextElement;
    expect(note.rotation, greaterThan(0));
    expect(controller.activeTool, CanvasTool.pen);
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
