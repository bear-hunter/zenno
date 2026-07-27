import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/model/canvas_style.dart';
import 'package:zenno/canvas/persistence/canvas_repository.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/features/library/data/library_repository.dart';

void main() {
  late ZennoDatabase db;

  setUp(() => db = ZennoDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('tool settings write debounce', () {
    test('a drag of many width changes collapses to one write', () async {
      final repository = _CountingCanvasRepository(db);
      await repository.ensureCanvasExists('c1', title: 'Debounce');
      final controller = CanvasController(
        repository: repository,
        canvasId: 'c1',
      );
      await controller.load();
      repository.toolSettingsWrites = 0;

      // Simulate a width slider drag: 50 setter calls inside one frame budget.
      for (int i = 0; i < 50; i++) {
        controller.setPenWidth(2.0 + i * 0.1);
      }
      expect(
        repository.toolSettingsWrites,
        0,
        reason: 'nothing should be written while the drag is still in flight',
      );

      await controller.flush();
      expect(repository.toolSettingsWrites, 1);

      controller.dispose();
    });

    test('paper style changes are debounced the same way', () async {
      final repository = _CountingCanvasRepository(db);
      await repository.ensureCanvasExists('c2', title: 'Paper');
      final controller = CanvasController(
        repository: repository,
        canvasId: 'c2',
      );
      await controller.load();
      repository.paperStyleWrites = 0;

      for (int i = 0; i < 20; i++) {
        controller.setPaperStyle(
          controller.paperStyle.copyWith(backgroundColor: 0xFF000000 + i),
        );
      }
      expect(repository.paperStyleWrites, 0);

      await controller.flush();
      expect(repository.paperStyleWrites, 1);

      controller.dispose();
    });

    test('the debounced write still lands without an explicit flush', () async {
      final repository = _CountingCanvasRepository(db);
      await repository.ensureCanvasExists('c3', title: 'Timer');
      final controller = CanvasController(
        repository: repository,
        canvasId: 'c3',
      );
      await controller.load();
      repository.toolSettingsWrites = 0;

      controller.setPenWidth(9);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(repository.toolSettingsWrites, 1);

      controller.dispose();
    });
  });

  group('orphaned library file cleanup', () {
    test('never deletes a file younger than the grace window', () async {
      final Directory temp = await Directory.systemTemp.createTemp('zenno');
      addTearDown(() => temp.delete(recursive: true));
      final File midImport = File('${temp.path}/just-imported.png')
        ..writeAsStringSync('bytes');

      // Mirrors the real race: the media file exists but the element row that
      // references it has not been written yet, so it is not in `referenced`.
      final deleted = await _sweep(
        root: temp,
        referenced: const <String>{},
        graceWindow: const Duration(minutes: 10),
      );

      expect(deleted, isEmpty);
      expect(midImport.existsSync(), isTrue);
    });

    test('deletes an unreferenced file older than the grace window', () async {
      final Directory temp = await Directory.systemTemp.createTemp('zenno');
      addTearDown(() => temp.delete(recursive: true));
      File('${temp.path}/orphan.png').writeAsStringSync('bytes');

      final deleted = await _sweep(
        root: temp,
        referenced: const <String>{},
        graceWindow: Duration.zero,
      );

      expect(deleted, <String>['orphan.png']);
    });

    test('never deletes a referenced file', () async {
      final Directory temp = await Directory.systemTemp.createTemp('zenno');
      addTearDown(() => temp.delete(recursive: true));
      final File kept = File('${temp.path}/kept.png')
        ..writeAsStringSync('bytes');

      final deleted = await _sweep(
        root: temp,
        referenced: <String>{kept.resolveSymbolicLinksSync()},
        graceWindow: Duration.zero,
      );

      expect(deleted, isEmpty);
      expect(kept.existsSync(), isTrue);
    });
  });

  test('library repository no longer sweeps files on construction', () async {
    int sweeps = 0;
    LibraryRepository(
      db,
      cleanupOwnedFiles: (_) async => sweeps++,
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      sweeps,
      0,
      reason: 'cleanup is a startup task, not a construction side effect',
    );
  });
}

/// Runs the orphan sweep over [root] and returns the names it deleted.
///
/// Reimplements the io helper's decision rule against an injectable root so the
/// test never touches the real application documents directory.
Future<List<String>> _sweep({
  required Directory root,
  required Set<String> referenced,
  required Duration graceWindow,
}) async {
  final DateTime cutoff = DateTime.now().subtract(graceWindow);
  final List<String> deleted = <String>[];
  await for (final entity in root.list(followLinks: false)) {
    if (entity is! File) continue;
    final String resolved = entity.resolveSymbolicLinksSync();
    if (referenced.contains(resolved)) continue;
    if (entity.statSync().modified.isAfter(cutoff)) continue;
    deleted.add(entity.uri.pathSegments.last);
    await entity.delete();
  }
  return deleted;
}

class _CountingCanvasRepository extends CanvasRepository {
  _CountingCanvasRepository(super.db);

  int toolSettingsWrites = 0;
  int paperStyleWrites = 0;

  @override
  Future<void> saveToolSettings(String canvasId, CanvasToolSettings settings) {
    toolSettingsWrites++;
    return super.saveToolSettings(canvasId, settings);
  }

  @override
  Future<void> savePaperStyle(String canvasId, CanvasPaperStyle style) {
    paperStyleWrites++;
    return super.savePaperStyle(canvasId, style);
  }
}
