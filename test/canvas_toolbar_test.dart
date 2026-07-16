import 'dart:async';
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
  Offset? toolWheelPosition,
  FutureOr<void> Function(Offset)? onToolWheelPositionChanged,
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
            toolWheelPosition: toolWheelPosition,
            onToolWheelPositionChanged: onToolWheelPositionChanged,
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

String _expectedWheelLabel(ToolWheelSlotKind kind) => switch (kind) {
  ToolWheelSlotKind.pen => 'Pen',
  ToolWheelSlotKind.pencil => 'Pencil',
  ToolWheelSlotKind.highlighter => 'Highlighter',
  ToolWheelSlotKind.marker => 'Marker',
  ToolWheelSlotKind.airbrush => 'Airbrush',
  ToolWheelSlotKind.fill => 'Freeform fill',
  ToolWheelSlotKind.eraser => 'Eraser',
  ToolWheelSlotKind.lasso => 'Select',
  _ => throw StateError('Unexpected default tool-wheel kind: $kind'),
};

void _expectOffsetsClose(Offset actual, Offset expected, {double epsilon = 1}) {
  expect(actual.dx, closeTo(expected.dx, epsilon));
  expect(actual.dy, closeTo(expected.dy, epsilon));
}

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

  testWidgets('tablet tool wheel is twenty percent larger', (tester) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    final Size wheelSize = tester.getSize(
      find.byKey(CanvasToolbar.compactDrawingPadKey),
    );
    expect(wheelSize, const Size.square(211.2));
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
      expect(
        find.descendant(
          of: _presetButton(index),
          matching: find.text(_expectedWheelLabel(kinds[index])),
        ),
        findsOneWidget,
      );
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

    final Rect palette = tester.getRect(
      find.byKey(CanvasToolbar.paletteDockKey),
    );
    expect(palette.left, greaterThanOrEqualTo(12));
    expect(palette.right, lessThanOrEqualTo(312));
    expect(palette.bottom, lessThanOrEqualTo(580));
    expect(wheel.overlaps(palette), isFalse);
    expect(palette.top - wheel.bottom, greaterThanOrEqualTo(8));
    expect(find.byKey(CanvasToolbar.minimalBackKey), findsOneWidget);
  });

  testWidgets('zoom percentage stays visible and resets the view to 100%', (
    tester,
  ) async {
    final controller = CanvasController();
    controller.setViewport(controller.viewport.copyWith(scale: 1.75));
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    const zoomKey = ValueKey<String>('canvas-zoom-percentage');
    expect(find.byKey(zoomKey), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(zoomKey), matching: find.text('175%')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(zoomKey));
    await tester.pump();

    expect(controller.viewport.scale, 1);
    expect(
      find.descendant(of: find.byKey(zoomKey), matching: find.text('100%')),
      findsOneWidget,
    );
  });

  testWidgets('orientation reset and rotation lock stay visible', (
    tester,
  ) async {
    final controller = CanvasController();
    controller.setViewport(
      controller.viewport.copyWith(scale: 1.75, rotation: math.pi / 4),
    );
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    expect(find.byKey(CanvasToolbar.resetOrientationKey), findsOneWidget);
    expect(find.byKey(CanvasToolbar.rotationLockKey), findsOneWidget);

    await tester.tap(find.byKey(CanvasToolbar.resetOrientationKey));
    await tester.pump();
    expect(controller.viewport.rotation, 0);
    expect(controller.viewport.scale, 1.75);

    await tester.tap(find.byKey(CanvasToolbar.rotationLockKey));
    await tester.pump();
    expect(controller.rotationLocked, isTrue);
    expect(find.byTooltip('Unlock rotation'), findsOneWidget);
  });

  testWidgets(
    'outer favorite drag moves and persists the complete wheel cluster',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = CanvasController();
      addTearDown(controller.dispose);
      final reportedPositions = <Offset>[];
      const mediaQuery = MediaQueryData(
        size: Size(1280, 800),
        padding: EdgeInsets.fromLTRB(24, 20, 16, 12),
      );
      await _pumpToolbar(
        tester,
        controller,
        mediaQuery: mediaQuery,
        onToolWheelPositionChanged: reportedPositions.add,
      );

      final Finder clusterFinder = find.byKey(CanvasToolbar.toolClusterKey);
      final Finder wheelFinder = find.byKey(CanvasToolbar.compactDrawingPadKey);
      final Finder sideControlsFinder = find.byKey(
        CanvasToolbar.canvasSettingsDockKey,
      );
      final Finder paletteFinder = find.byKey(CanvasToolbar.paletteDockKey);
      final Rect clusterBefore = tester.getRect(clusterFinder);
      final Rect wheelBefore = tester.getRect(wheelFinder);
      final Rect sideControlsBefore = tester.getRect(sideControlsFinder);
      final Rect paletteBefore = tester.getRect(paletteFinder);

      final TestGesture drag = await tester.startGesture(
        tester.getCenter(_presetButton(1)),
      );
      // Cross the pan slop first, then verify the accepted gesture translates
      // the cluster. Flutter does not guarantee that the slop-crossing delta
      // itself is delivered to onPanUpdate.
      await drag.moveBy(const Offset(20, 20));
      await tester.pump();
      await drag.moveBy(const Offset(200, 120));
      await tester.pump();
      expect(reportedPositions, isEmpty);
      await drag.up();
      await tester.pump();

      final Rect clusterAfter = tester.getRect(clusterFinder);
      final Offset translation = clusterAfter.topLeft - clusterBefore.topLeft;
      expect(translation.dx, greaterThan(150));
      expect(translation.dy, greaterThan(80));
      _expectOffsetsClose(
        tester.getRect(wheelFinder).topLeft - wheelBefore.topLeft,
        translation,
      );
      _expectOffsetsClose(
        tester.getRect(sideControlsFinder).topLeft - sideControlsBefore.topLeft,
        translation,
      );
      _expectOffsetsClose(
        tester.getRect(paletteFinder).topLeft - paletteBefore.topLeft,
        translation,
      );
      expect(controller.activeToolWheelIndex, 0);
      expect(find.text('Replace favorite 2'), findsNothing);
      expect(reportedPositions, hasLength(1));
      expect(reportedPositions.single.dx, inInclusiveRange(0, 1));
      expect(reportedPositions.single.dy, inInclusiveRange(0, 1));

      final Offset persistedPosition = reportedPositions.single;
      reportedPositions.clear();
      await _pumpToolbar(
        tester,
        controller,
        mediaQuery: mediaQuery,
        toolWheelPosition: persistedPosition,
        onToolWheelPositionChanged: reportedPositions.add,
      );
      final Rect restoredCluster = tester.getRect(clusterFinder);
      _expectOffsetsClose(restoredCluster.topLeft, clusterAfter.topLeft);
      expect(reportedPositions, isEmpty);

      await tester.tap(_presetButton(1));
      await tester.pump();
      expect(controller.activeToolWheelIndex, 1);
      expect(find.text('Replace favorite 2'), findsNothing);

      await tester.longPress(_presetButton(1));
      await tester.pumpAndSettle();
      expect(find.text('Replace favorite 2'), findsOneWidget);
      expect(reportedPositions, isEmpty);
    },
  );

  testWidgets('wheel cluster fits a short split-screen viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(
      tester,
      controller,
      mediaQuery: const MediaQueryData(size: Size(320, 200)),
    );

    final Rect cluster = tester.getRect(
      find.byKey(CanvasToolbar.toolClusterKey),
    );
    expect(cluster.left, greaterThanOrEqualTo(0));
    expect(cluster.top, greaterThanOrEqualTo(0));
    expect(cluster.right, lessThanOrEqualTo(320));
    expect(cluster.bottom, lessThanOrEqualTo(200));
  });

  testWidgets('canceled wheel drag persists the visible position', (
    tester,
  ) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    final reportedPositions = <Offset>[];
    await _pumpToolbar(
      tester,
      controller,
      onToolWheelPositionChanged: reportedPositions.add,
    );

    final TestGesture drag = await tester.startGesture(
      tester.getCenter(_presetButton(1)),
    );
    await drag.moveBy(const Offset(20, 20));
    await tester.pump();
    await drag.moveBy(const Offset(100, 80));
    await tester.pump();
    await drag.cancel();
    await tester.pump();

    expect(reportedPositions, hasLength(1));
  });

  testWidgets('wheel position save failure is visible', (tester) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(
      tester,
      controller,
      onToolWheelPositionChanged: (position) async {
        throw StateError('Write unavailable');
      },
    );

    final TestGesture drag = await tester.startGesture(
      tester.getCenter(_presetButton(1)),
    );
    await drag.moveBy(const Offset(20, 20));
    await tester.pump();
    await drag.moveBy(const Offset(100, 80));
    await drag.up();
    await tester.pumpAndSettle();

    expect(
      find.text('Could not save wheel position. Move it again to retry.'),
      findsOneWidget,
    );
  });

  testWidgets('huge wheel drags clamp the cluster inside safe insets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = CanvasController();
    addTearDown(controller.dispose);
    const padding = EdgeInsets.fromLTRB(12, 24, 8, 20);
    await _pumpToolbar(
      tester,
      controller,
      mediaQuery: const MediaQueryData(size: Size(320, 600), padding: padding),
      toolWheelPosition: const Offset(0.5, 0.5),
    );

    void expectClusterInsideSafeArea() {
      final Rect cluster = tester.getRect(
        find.byKey(CanvasToolbar.toolClusterKey),
      );
      expect(cluster.left, greaterThanOrEqualTo(padding.left));
      expect(cluster.top, greaterThanOrEqualTo(padding.top));
      expect(cluster.right, lessThanOrEqualTo(320 - padding.right));
      expect(cluster.bottom, lessThanOrEqualTo(600 - padding.bottom));
    }

    final Rect clusterBefore = tester.getRect(
      find.byKey(CanvasToolbar.toolClusterKey),
    );
    final TestGesture dragToTopLeft = await tester.startGesture(
      tester.getCenter(_presetButton(2)),
    );
    await dragToTopLeft.moveBy(const Offset(-20, -20));
    await tester.pump();
    await dragToTopLeft.moveBy(const Offset(-1980, -1980));
    await dragToTopLeft.up();
    await tester.pump();
    expectClusterInsideSafeArea();
    final Rect topLeftCluster = tester.getRect(
      find.byKey(CanvasToolbar.toolClusterKey),
    );
    expect(topLeftCluster.top, lessThan(clusterBefore.top));
    final Rect backButton = tester.getRect(
      find.byKey(CanvasToolbar.minimalBackKey),
    );
    expect(topLeftCluster.top, greaterThanOrEqualTo(backButton.bottom + 8));

    final TestGesture dragToBottomRight = await tester.startGesture(
      tester.getCenter(_presetButton(2)),
    );
    await dragToBottomRight.moveBy(const Offset(20, 20));
    await tester.pump();
    await dragToBottomRight.moveBy(const Offset(1980, 1980));
    await dragToBottomRight.up();
    await tester.pump();
    expectClusterInsideSafeArea();
    final Rect bottomRightCluster = tester.getRect(
      find.byKey(CanvasToolbar.toolClusterKey),
    );
    expect(bottomRightCluster.left, greaterThan(topLeftCluster.left));
    expect(bottomRightCluster.top, greaterThan(topLeftCluster.top));
    expect(controller.activeToolWheelIndex, 0);
    expect(find.text('Replace favorite 3'), findsNothing);
  });

  testWidgets('property drag changes its value without moving the cluster', (
    tester,
  ) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    final reportedPositions = <Offset>[];
    await _pumpToolbar(
      tester,
      controller,
      onToolWheelPositionChanged: reportedPositions.add,
    );
    final Finder clusterFinder = find.byKey(CanvasToolbar.toolClusterKey);
    final Rect clusterBefore = tester.getRect(clusterFinder);

    await tester.drag(find.byTooltip('Size: 4 pt'), const Offset(48, 0));
    await tester.pump();

    expect(controller.penWidth, greaterThan(4));
    _expectOffsetsClose(
      tester.getRect(clusterFinder).topLeft,
      clusterBefore.topLeft,
      epsilon: 0.1,
    );
    expect(reportedPositions, isEmpty);
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
    expect(find.byTooltip('Clear canvas'), findsNothing);
    expect(find.byTooltip('Show drawing tools'), findsOneWidget);
    expect(_swatch(0), findsOneWidget);

    await tester.tap(find.byTooltip('View and gestures'));
    await tester.pump();
    expect(find.byTooltip('Back to more actions'), findsOneWidget);
    expect(find.byTooltip('Enable snap to grid'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(CanvasToolbar.compactDrawingPadKey),
        matching: find.byTooltip('Lock rotation'),
      ),
      findsOneWidget,
    );
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

    final Finder rotation = find.descendant(
      of: find.byKey(CanvasToolbar.compactDrawingPadKey),
      matching: find.byTooltip('Lock rotation'),
    );
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
    final Finder paper = find.byTooltip('Paper');
    await tester.tap(paper);
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(CanvasToolbar.paperSettingsPanelKey)).left,
      closeTo(18, 0.1),
    );
    final Finder lined = find.byKey(
      const ValueKey<String>(
        '${CanvasToolbar.paperKindButtonKeyPrefix}-BackgroundKind.lined',
      ),
    );
    await tester.ensureVisible(lined);
    await tester.tap(lined);
    final Finder background = find.byKey(
      const ValueKey<String>(
        '${CanvasToolbar.paperBackgroundPresetButtonKeyPrefix}-5',
      ),
    );
    await tester.ensureVisible(background);
    await tester.tap(background);
    final Finder grid = find.byKey(
      const ValueKey<String>(
        '${CanvasToolbar.paperGridPresetButtonKeyPrefix}-1',
      ),
    );
    await tester.ensureVisible(grid);
    await tester.tap(grid);
    final Finder texture = find.byKey(
      const ValueKey<String>(
        '${CanvasToolbar.paperTextureButtonKeyPrefix}-PaperTexture.crosshatch',
      ),
    );
    await tester.ensureVisible(texture);
    await tester.tap(texture);
    await tester.pump();
    final Finder save = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(controller.paperStyle.kind, BackgroundKind.lined);
    expect(controller.paperStyle.backgroundColor, 0xFFF7F1DE);
    expect(controller.paperStyle.gridColor, 0xFF8EC5FF);
    expect(controller.paperStyle.texture, PaperTexture.crosshatch);
  });

  testWidgets('quick paper moods apply a complete canvas look', (tester) async {
    final controller = CanvasController();
    addTearDown(controller.dispose);
    await _pumpToolbar(tester, controller);

    await _openMore(tester);
    await tester.tap(find.byTooltip('Paper'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('${CanvasToolbar.paperMoodButtonKeyPrefix}-2'),
      ),
    );
    await tester.pump();
    final Finder save = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(controller.paperStyle.kind, BackgroundKind.grid);
    expect(controller.paperStyle.backgroundColor, 0xFF0B3A5B);
    expect(controller.paperStyle.gridColor, 0xFF8EC5FF);
    expect(controller.paperStyle.texture, PaperTexture.grain);
    expect(controller.paperStyle.textureOpacity, 0.05);
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
    await tester.tap(find.byKey(CanvasToolbar.wheelCenterKey));
    await tester.pump();
    expect(find.byTooltip('Copy selection'), findsOneWidget);
    expect(find.byTooltip('Paste selection'), findsOneWidget);

    await tester.tap(find.byTooltip('Copy selection'));
    await tester.pump();
    await tester.tap(find.byTooltip('Paste selection'));
    await tester.pump();

    expect(controller.elementCount, 2);
    expect(controller.selectedIds, hasLength(1));
    expect(controller.selectedIds.single, isNot('note'));
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
    expect(find.text('Freeform fill'), findsNWidgets(2));
    expect(find.text('Marker'), findsNWidgets(2));
    expect(find.text('Airbrush'), findsNWidgets(2));
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

  testWidgets('More never exposes a clear-canvas action', (tester) async {
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
    expect(find.byTooltip('Clear canvas'), findsNothing);
    expect(find.text('Clear canvas?'), findsNothing);
    expect(controller.elements, hasLength(1));
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
