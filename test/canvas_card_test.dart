import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:zenno/core/database/database.dart';
import 'package:zenno/features/library/application/library_providers.dart';
import 'package:zenno/features/library/data/library_repository.dart';
import 'package:zenno/features/library/presentation/widgets/canvas_card.dart';

void main() {
  testWidgets('rapid taps open once even when recency metadata fails', (
    tester,
  ) async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final baseRepository = LibraryRepository(db);
    final canvasId = await baseRepository.createCanvas(title: 'Open once');
    final canvas = await (db.select(
      db.canvases,
    )..where((row) => row.id.equals(canvasId))).getSingle();
    final touchGate = Completer<void>();
    final repository = _GatedTouchRepository(db, touchGate.future);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              Scaffold(body: CanvasCard(canvas: canvas)),
        ),
        GoRoute(
          path: '/canvas/:id',
          builder: (context, state) => const Scaffold(body: Text('Opened')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [libraryRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Open once'));
    await tester.tap(find.text('Open once'));
    expect(repository.touchCalls, 1);

    touchGate.completeError(StateError('metadata unavailable'));
    await tester.pumpAndSettle();

    expect(find.text('Opened'), findsOneWidget);
    expect(repository.touchCalls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _GatedTouchRepository extends LibraryRepository {
  _GatedTouchRepository(super.db, this._gate);

  final Future<void> _gate;
  int touchCalls = 0;

  @override
  Future<void> touchOpened(String id) async {
    touchCalls += 1;
    await _gate;
  }
}
