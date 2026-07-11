import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/database_exceptions.dart';
import 'package:zenno/core/database/tables/settings_tables.dart';
import 'package:zenno/features/library/application/library_providers.dart';
import 'package:zenno/features/library/data/library_repository.dart';
import 'package:zenno/features/library/presentation/pages/library_page.dart';

void main() {
  testWidgets('explains when another web tab owns the database', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySortProvider.overrideWithValue(LibrarySort.recent),
          canvasListProvider.overrideWith(
            (ref) => Stream<List<Canvase>>.error(
              StateError(databaseAlreadyOpenMessage),
            ),
          ),
          canvasFolderListProvider.overrideWith(
            (ref) => Stream<List<CanvasFolder>>.value(const []),
          ),
        ],
        child: const MaterialApp(home: LibraryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Zenno is open in another tab'), findsOneWidget);
    expect(
      find.text('Close the other tab, then reload this page.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('folder toggle hides cards and search reveals matches', (
    tester,
  ) async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = LibraryRepository(db);
    final folderId = await repository.createFolder('Biology');
    await repository.createCanvas(title: 'Cell membrane', folderId: folderId);
    await _pumpLibrary(tester, repository);

    expect(find.text('Cell membrane'), findsOneWidget);

    await tester.tap(find.byKey(LibraryPage.folderToggleKey(folderId)));
    await tester.pumpAndSettle();

    expect(find.text('Biology'), findsOneWidget);
    expect(find.text('1 canvas'), findsOneWidget);
    expect(find.text('Cell membrane'), findsNothing);
    expect(find.byKey(LibraryPage.folderContentsKey(folderId)), findsNothing);

    await tester.enterText(find.byType(TextField), 'membrane');
    await tester.pumpAndSettle();

    expect(find.text('Cell membrane'), findsOneWidget);
    expect(find.byKey(LibraryPage.folderContentsKey(folderId)), findsOneWidget);
    final searchToggle = tester.widget<IconButton>(
      find.byKey(LibraryPage.folderToggleKey(folderId)),
    );
    expect(searchToggle.onPressed, isNull);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Cell membrane'), findsNothing);

    await tester.tap(find.byKey(LibraryPage.folderToggleKey(folderId)));
    await tester.pumpAndSettle();
    expect(find.text('Cell membrane'), findsOneWidget);
    await _disposeLibrary(tester);
  });

  testWidgets('dragging a canvas moves it once and expands its destination', (
    tester,
  ) async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _RecordingLibraryRepository(db);
    final sourceId = await repository.createFolder('Source');
    final targetId = await repository.createFolder('Target');
    final canvasId = await repository.createCanvas(
      title: 'Move me',
      folderId: sourceId,
    );
    await _pumpLibrary(tester, repository);

    await tester.tap(find.byKey(LibraryPage.folderToggleKey(targetId)));
    await tester.pumpAndSettle();

    await _dragCanvasToFolder(tester, canvasId, targetId);
    await tester.pumpAndSettle();

    final moved = await (db.select(
      db.canvases,
    )..where((row) => row.id.equals(canvasId))).getSingle();
    expect(repository.moveCalls, 1);
    expect(moved.folderId, targetId);
    expect(
      find.descendant(
        of: find.byKey(LibraryPage.folderContentsKey(targetId)),
        matching: find.text('Move me'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(LibraryPage.folderToggleKey(targetId)))
          .tooltip,
      'Collapse Target',
    );
    await _disposeLibrary(tester);
  });

  testWidgets('a failed drag leaves the canvas in its source folder', (
    tester,
  ) async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _RecordingLibraryRepository(db, failMoves: true);
    final sourceId = await repository.createFolder('Source');
    final targetId = await repository.createFolder('Target');
    final canvasId = await repository.createCanvas(
      title: 'Stay here',
      folderId: sourceId,
    );
    await _pumpLibrary(tester, repository);

    await _dragCanvasToFolder(tester, canvasId, targetId);
    await tester.pump(const Duration(milliseconds: 300));

    final canvas = await (db.select(
      db.canvases,
    )..where((row) => row.id.equals(canvasId))).getSingle();
    expect(repository.moveCalls, 1);
    expect(canvas.folderId, sourceId);
    expect(
      find.descendant(
        of: find.byKey(LibraryPage.folderContentsKey(sourceId)),
        matching: find.text('Stay here'),
      ),
      findsOneWidget,
    );
    expect(
      find.text('Could not move canvas. Please try again.'),
      findsOneWidget,
    );
    await _disposeLibrary(tester);
  });

  testWidgets('dropping onto the current folder is rejected', (tester) async {
    final db = ZennoDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = _RecordingLibraryRepository(db);
    final folderId = await repository.createFolder('Source');
    final canvasId = await repository.createCanvas(
      title: 'Already here',
      folderId: folderId,
    );
    await _pumpLibrary(tester, repository);

    await _dragCanvasToFolder(tester, canvasId, folderId);
    await tester.pump(const Duration(milliseconds: 200));

    expect(repository.moveCalls, 0);
    await _disposeLibrary(tester);
  });
}

Future<void> _pumpLibrary(
  WidgetTester tester,
  LibraryRepository repository,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 1200);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(repository),
        librarySortProvider.overrideWithValue(LibrarySort.recent),
      ],
      child: const MaterialApp(home: LibraryPage()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _disposeLibrary(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
}

Future<void> _dragCanvasToFolder(
  WidgetTester tester,
  String canvasId,
  String? folderId,
) async {
  final draggable = find.byKey(LibraryPage.canvasDragKey(canvasId));
  final target = find.byKey(LibraryPage.folderDropTargetKey(folderId));
  expect(draggable, findsOneWidget);
  expect(target, findsOneWidget);

  final gesture = await tester.startGesture(
    tester.getCenter(draggable),
    kind: PointerDeviceKind.touch,
  );
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
  await gesture.moveTo(tester.getCenter(target));
  await tester.pump(const Duration(milliseconds: 150));
  await gesture.up();
  await tester.pump();
}

class _RecordingLibraryRepository extends LibraryRepository {
  _RecordingLibraryRepository(super.db, {this.failMoves = false});

  final bool failMoves;
  int moveCalls = 0;

  @override
  Future<void> moveCanvasToFolder(String canvasId, String? folderId) async {
    moveCalls += 1;
    if (failMoves) throw StateError('Move unavailable');
    await super.moveCanvasToFolder(canvasId, folderId);
  }
}
