import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/canvas_editor_page.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/persistence/canvas_providers.dart';
import 'package:zenno/canvas/persistence/canvas_repository.dart';
import 'package:zenno/canvas/render/canvas_view.dart';
import 'package:zenno/canvas/widgets/canvas_toolbar.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/providers/database_provider.dart';

void main() {
  late ZennoDatabase db;
  late CanvasRepository repository;

  setUp(() {
    db = ZennoDatabase(NativeDatabase.memory());
    repository = CanvasRepository(db);
  });

  tearDown(() => db.close());

  testWidgets('system back saves an inline title draft', (tester) async {
    const String canvasId = 'title-canvas';
    await repository.ensureCanvasExists(canvasId, title: 'Original');
    final container = await _pumpEditor(tester, db, canvasId: canvasId);

    await tester.tap(find.text('Original'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey<String>('canvas-title-field')),
      'Renamed before back',
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    final row = await (db.select(
      db.canvases,
    )..where((canvas) => canvas.id.equals(canvasId))).getSingle();
    expect(row.title, 'Renamed before back');
    await _disposeEditor(tester, container);
  });

  testWidgets('canvas shortcuts are disabled while editing the title', (
    tester,
  ) async {
    const String canvasId = 'shortcut-canvas';
    await repository.ensureCanvasExists(canvasId, title: 'Original');
    final container = await _pumpEditor(tester, db, canvasId: canvasId);

    expect(
      tester.widget<CallbackShortcuts>(find.byType(CallbackShortcuts)).bindings,
      isNotEmpty,
    );

    await tester.tap(find.text('Original'));
    await tester.pump();

    expect(
      tester.widget<CallbackShortcuts>(find.byType(CallbackShortcuts)).bindings,
      isEmpty,
    );
    await _disposeEditor(tester, container);
  });

  testWidgets('a stale route does not recreate a deleted canvas', (
    tester,
  ) async {
    const String canvasId = 'already-deleted';
    final container = await _pumpEditor(tester, db, canvasId: canvasId);

    expect(find.text('This canvas no longer exists.'), findsOneWidget);
    expect(await repository.canvasExists(canvasId), isFalse);
    await _disposeEditor(tester, container);
  });

  testWidgets('arrival viewport wins after slow persisted hydration', (
    tester,
  ) async {
    const String canvasId = 'slow-canvas';
    const ViewportState persisted = ViewportState(
      translation: Offset(10, 20),
      scale: 1.2,
      rotation: 0.1,
    );
    const ViewportState arrival = ViewportState(
      translation: Offset(-300, 75),
      scale: 2.4,
      rotation: 0.4,
    );
    await repository.ensureCanvasExists(canvasId, title: 'Slow');
    await repository.saveViewport(canvasId, persisted);
    final gate = Completer<void>();
    final slowRepository = _SlowViewportRepository(db, gate.future);

    final container = await _pumpEditor(
      tester,
      db,
      canvasId: canvasId,
      repositoryOverride: slowRepository,
      initialViewport: arrival,
      settle: false,
    );
    expect(find.text('Loading canvas…'), findsOneWidget);

    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(await repository.loadViewport(canvasId), arrival);
    await _disposeEditor(tester, container);
  });

  testWidgets('stylus radial wheel opens once at the editor surface', (
    tester,
  ) async {
    const String canvasId = 'quick-tools-canvas';
    await repository.ensureCanvasExists(canvasId, title: 'Quick tools');
    final container = await _pumpEditor(tester, db, canvasId: canvasId);

    final CanvasView view = tester.widget<CanvasView>(find.byType(CanvasView));
    view.onShowQuickTools?.call(const Offset(320, 240));
    view.onShowQuickTools?.call(const Offset(320, 240));
    await tester.pumpAndSettle();

    final Finder radialCenter = find.byKey(CanvasToolbar.showFullControlsKey);
    expect(radialCenter, findsOneWidget);
    expect(tester.getSize(radialCenter), const Size(80, 80));
    expect(find.byTooltip('Eraser'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Eraser').last);
    await tester.pumpAndSettle();

    expect(view.controller.activeTool, CanvasTool.eraser);
    expect(radialCenter, findsNothing);
    await _disposeEditor(tester, container);
  });

  testWidgets('Escape clears the selection without changing the active tool', (
    tester,
  ) async {
    const String canvasId = 'escape-selection-canvas';
    await repository.ensureCanvasExists(canvasId, title: 'Escape selection');
    final container = await _pumpEditor(tester, db, canvasId: canvasId);

    final CanvasController controller = tester
        .widget<CanvasView>(find.byType(CanvasView))
        .controller;
    controller
      ..setTool(CanvasTool.pen)
      ..addElementToStore(
        const TextElement(
          id: 'selected-note',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(80, 80, 80, 40),
          text: 'Selected',
          color: 0xFFFFFFFF,
          fontSize: 18,
        ),
      )
      ..setSelection(<String>{'selected-note'});
    await tester.pump();

    expect(controller.hasSelection, isTrue);
    expect(find.text('1 selected'), findsOneWidget);
    final CallbackShortcuts shortcuts = tester.widget<CallbackShortcuts>(
      find.byType(CallbackShortcuts),
    );
    final VoidCallback? escape =
        shortcuts.bindings[const SingleActivator(LogicalKeyboardKey.escape)];
    expect(escape, isNotNull);
    escape!();
    await tester.pump();

    expect(controller.hasSelection, isFalse);
    expect(controller.activeTool, CanvasTool.pen);
    expect(find.byType(CanvasEditorPage), findsOneWidget);
    expect(find.byTooltip('Draw settings'), findsOneWidget);
    await _disposeEditor(tester, container);
  });

  testWidgets('top Back clears selection before leaving the editor', (
    tester,
  ) async {
    const String canvasId = 'back-selection-canvas';
    await repository.ensureCanvasExists(canvasId, title: 'Back selection');
    final container = await _pumpEditor(tester, db, canvasId: canvasId);

    final CanvasController controller = tester
        .widget<CanvasView>(find.byType(CanvasView))
        .controller;
    controller
      ..addElementToStore(
        const TextElement(
          id: 'selected-note',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(80, 80, 80, 40),
          text: 'Selected',
          color: 0xFFFFFFFF,
          fontSize: 18,
        ),
      )
      ..setSelection(<String>{'selected-note'});
    await tester.pump();

    await tester.tap(find.byKey(CanvasToolbar.minimalBackKey));
    await tester.pump();
    expect(controller.hasSelection, isFalse);
    expect(find.byType(CanvasEditorPage), findsOneWidget);
    await _disposeEditor(tester, container);
  });
}

Future<ProviderContainer> _pumpEditor(
  WidgetTester tester,
  ZennoDatabase db, {
  required String canvasId,
  CanvasRepository? repositoryOverride,
  ViewportState initialViewport = ViewportState.initial,
  bool settle = true,
}) async {
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      if (repositoryOverride != null)
        canvasRepositoryProvider.overrideWithValue(repositoryOverride),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: CanvasEditorPage(
          canvasId: canvasId,
          initialViewport: initialViewport,
        ),
      ),
    ),
  );
  await tester.pump();
  if (settle) await tester.pump(const Duration(milliseconds: 100));
  return container;
}

Future<void> _disposeEditor(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  container.dispose();
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}

class _SlowViewportRepository extends CanvasRepository {
  _SlowViewportRepository(super.db, this._gate);

  final Future<void> _gate;

  @override
  Future<ViewportState?> loadViewport(String canvasId) async {
    await _gate;
    return super.loadViewport(canvasId);
  }
}
