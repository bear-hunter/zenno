import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/canvas_editor_navigation.dart';
import 'package:zenno/canvas/canvas_editor_page.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/persistence/canvas_repository.dart';
import 'package:zenno/canvas/render/canvas_view.dart';
import 'package:zenno/config/router/routes.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/providers/database_provider.dart';

void main() {
  testWidgets(
    'linked navigation reuses an existing editor and coalesces rapid opens',
    (WidgetTester tester) async {
      final ZennoDatabase db = ZennoDatabase(NativeDatabase.memory());
      final CanvasRepository repository = CanvasRepository(db);
      await repository.ensureCanvasExists('a', title: 'Canvas A');
      await repository.ensureCanvasExists('b', title: 'Canvas B');

      final ProviderContainer container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      final GoRouter router = GoRouter(
        initialLocation: '/',
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) => Scaffold(
              body: Center(
                child: FilledButton(
                  key: const ValueKey<String>('open-a'),
                  onPressed: () => unawaited(openCanvasEditor(context, 'a')),
                  child: const Text('Open A'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: Routes.canvas,
            builder: (BuildContext context, GoRouterState state) =>
                CanvasEditorPage(canvasId: state.pathParameters['id']!),
          ),
        ],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        router.dispose();
        container.dispose();
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 1));
        await db.close();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.byKey(const ValueKey<String>('open-a')));
      await tester.pumpAndSettle();

      expect(_currentCanvasId(tester), 'a');
      final CanvasController controllerA = tester
          .widget<CanvasView>(find.byType(CanvasView))
          .controller;

      final BuildContext contextA = tester.element(
        find.byType(CanvasEditorPage),
      );
      unawaited(openCanvasEditor(contextA, 'b'));
      unawaited(openCanvasEditor(contextA, 'b'));
      await tester.pumpAndSettle();

      expect(_allEditors('a'), findsOneWidget);
      expect(_allEditors('b'), findsOneWidget);
      expect(_currentCanvasId(tester), 'b');

      router.pop();
      await tester.pumpAndSettle();

      expect(_currentCanvasId(tester), 'a');
      expect(
        tester.widget<CanvasView>(find.byType(CanvasView)).controller,
        same(controllerA),
      );

      final BuildContext returnedA = tester.element(
        find.byType(CanvasEditorPage),
      );
      unawaited(openCanvasEditor(returnedA, 'b'));
      await tester.pumpAndSettle();
      expect(_currentCanvasId(tester), 'b');

      const ViewportState arrival = ViewportState(
        translation: Offset(-240, 80),
        scale: 2.5,
        rotation: 0.25,
      );
      final BuildContext contextB = tester.element(
        find.byType(CanvasEditorPage),
      );
      final Future<void> reused = openCanvasEditor<void>(
        contextB,
        'a',
        targetViewport: arrival,
      );
      await tester.runAsync(() => reused);
      await tester.pumpAndSettle();

      expect(_allEditors('a'), findsOneWidget);
      expect(_allEditors('b'), findsNothing);
      expect(_currentCanvasId(tester), 'a');
      final CanvasController reusedA = tester
          .widget<CanvasView>(find.byType(CanvasView))
          .controller;
      expect(reusedA, same(controllerA));
      expect(reusedA.viewport, arrival);
    },
  );
}

Finder _allEditors(String canvasId) {
  return find.byWidgetPredicate(
    (Widget widget) =>
        widget is CanvasEditorPage && widget.canvasId == canvasId,
    skipOffstage: false,
  );
}

String _currentCanvasId(WidgetTester tester) {
  return tester
      .widget<CanvasEditorPage>(find.byType(CanvasEditorPage))
      .canvasId;
}
