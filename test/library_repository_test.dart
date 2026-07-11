import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/persistence/canvas_repository.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/focus_tables.dart';
import 'package:zenno/features/focus/data/focus_repository.dart';
import 'package:zenno/features/library/data/library_repository.dart';

void main() {
  late ZennoDatabase db;
  late LibraryRepository repo;

  setUp(() {
    db = ZennoDatabase(NativeDatabase.memory());
    repo = LibraryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('creates folders and moves canvases into them', () async {
    final folderId = await repo.createFolder('Biology');
    final canvasId = await repo.createCanvas(
      title: 'Cells',
      folderId: folderId,
    );

    final canvas = await (db.select(
      db.canvases,
    )..where((c) => c.id.equals(canvasId))).getSingle();
    final folders = await repo.watchFolders().first;

    expect(folders.single.name, 'Biology');
    expect(canvas.folderId, folderId);
  });

  test('deleting a folder moves canvases to unfiled', () async {
    final folderId = await repo.createFolder('Chemistry');
    final canvasId = await repo.createCanvas(
      title: 'Reactions',
      folderId: folderId,
    );

    await repo.deleteFolder(folderId);

    final canvas = await (db.select(
      db.canvases,
    )..where((c) => c.id.equals(canvasId))).getSingle();
    final folders = await db.select(db.canvasFolders).get();

    expect(folders, isEmpty);
    expect(canvas.folderId, isNull);
  });

  test('deleting a canvas preserves linked focus-session history', () async {
    final canvasId = await repo.createCanvas(title: 'Working canvas');
    final focusRepo = FocusRepository(db);
    final sessionId = await focusRepo.createSession(
      startedAt: DateTime.utc(2026, 7, 10),
      goalText: 'Review physiology',
      preEnergy: 4,
      timerKind: TimerKind.pomodoro,
      plannedDurationSecs: 1500,
      pomodoroWorkSecs: 1500,
      pomodoroBreakSecs: 300,
      linkedCanvasId: canvasId,
    );

    await repo.deleteCanvas(canvasId);

    final session = await focusRepo.session(sessionId);
    expect(session, isNotNull);
    expect(session!.linkedCanvasId, isNull);
  });

  test('deleting a canvas cleans only unreferenced owned file paths', () async {
    final deletedPaths = <String>[];
    final deletingRepo = LibraryRepository(
      db,
      deleteOwnedFiles: (paths) async => deletedPaths.addAll(paths),
    );
    final canvasRepo = CanvasRepository(db);
    final first = await deletingRepo.createCanvas(title: 'First');
    final second = await deletingRepo.createCanvas(title: 'Second');
    const sharedPath = '/documents/canvas_media/shared.png';
    const uniquePath = '/documents/canvas_media/unique.png';
    const thumbnailPath = '/documents/thumbnails/first.png';
    await canvasRepo.upsertElement(
      first,
      const ImageElement(
        id: 'first-shared',
        zIndex: 0,
        worldBounds: Rect.fromLTWH(0, 0, 10, 10),
        sourceFilePath: sharedPath,
        intrinsicSize: Size(10, 10),
      ),
    );
    await canvasRepo.upsertElement(
      first,
      const ImageElement(
        id: 'first-unique',
        zIndex: 1,
        worldBounds: Rect.fromLTWH(10, 0, 10, 10),
        sourceFilePath: uniquePath,
        intrinsicSize: Size(10, 10),
      ),
    );
    await canvasRepo.upsertElement(
      second,
      const ImageElement(
        id: 'second-shared',
        zIndex: 0,
        worldBounds: Rect.fromLTWH(0, 0, 10, 10),
        sourceFilePath: sharedPath,
        intrinsicSize: Size(10, 10),
      ),
    );
    await deletingRepo.updateThumbnailPath(first, thumbnailPath);

    await deletingRepo.deleteCanvas(first);

    expect(deletedPaths, containsAll(<String>[uniquePath, thumbnailPath]));
    expect(deletedPaths, isNot(contains(sharedPath)));
  });
}
