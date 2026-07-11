import 'package:drift/drift.dart';

import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/settings_tables.dart';
import 'package:zenno/core/util/id.dart';
import 'package:zenno/features/library/data/library_file_cleanup.dart';

/// Data layer for the canvas library.
///
/// The only code in the feature that touches Drift: it exposes reactive
/// `Stream` reads over the `canvases` table and `Future` writes, returning the
/// Drift-generated [Canvase] row class to the layers above.
class LibraryRepository {
  /// Creates a repository backed by [db].
  const LibraryRepository(
    this._db, {
    Future<void> Function(Iterable<String> paths) deleteOwnedFiles =
        deleteOwnedLibraryFiles,
    Future<void> Function(Set<String> referencedPaths) cleanupOwnedFiles =
        deleteOrphanedOwnedLibraryFiles,
  }) : _deleteOwnedFiles = deleteOwnedFiles,
       _cleanupOwnedFiles = cleanupOwnedFiles;

  final ZennoDatabase _db;
  final Future<void> Function(Iterable<String> paths) _deleteOwnedFiles;
  final Future<void> Function(Set<String> referencedPaths) _cleanupOwnedFiles;

  /// Deletes old media/thumbnail files left behind by element erases or
  /// interrupted versions of the app, after comparing them with every live DB
  /// reference. Safe to call at startup, when in-memory undo history is empty.
  Future<void> cleanupOrphanedFiles() async {
    final Set<String> referenced = <String>{};
    referenced.addAll(
      (await _db.select(_db.images).get()).map((row) => row.filePath),
    );
    referenced.addAll(
      (await _db.select(_db.pdfDocuments).get()).map((row) => row.filePath),
    );
    referenced.addAll(
      (await _db.select(_db.canvases).get())
          .map((row) => row.thumbnailPath)
          .whereType<String>(),
    );
    await _cleanupOwnedFiles(referenced);
  }

  /// Watches every non-archived canvas, ordered according to [sort].
  ///
  /// Emits a fresh list whenever the underlying rows change, so any screen
  /// listening updates automatically after a create/rename/delete.
  Stream<List<Canvase>> watchCanvases(LibrarySort sort) {
    final query = _db.select(_db.canvases)
      ..where((c) => c.isArchived.equals(false));

    switch (sort) {
      case LibrarySort.recent:
        query.orderBy([
          (c) => OrderingTerm(expression: c.updatedAt, mode: OrderingMode.desc),
        ]);
      case LibrarySort.created:
        query.orderBy([
          (c) => OrderingTerm(expression: c.createdAt, mode: OrderingMode.desc),
        ]);
      case LibrarySort.title:
        query.orderBy([
          (c) => OrderingTerm(expression: c.title, mode: OrderingMode.asc),
        ]);
    }

    return _watchWithInitialRead(query);
  }

  /// Watches just one canvas title for editor chrome.
  Stream<String?> watchCanvasTitle(String id) {
    final query = _db.select(_db.canvases)..where((c) => c.id.equals(id));
    return query.watchSingleOrNull().map((canvas) => canvas?.title);
  }

  /// Inserts a new, empty canvas and returns its generated id.
  ///
  /// [title] defaults to `Untitled`. Timestamps are set to now; every other
  /// non-null column falls back to its schema default (blank background,
  /// identity viewport, not archived).
  Future<String> createCanvas({
    String title = 'Untitled',
    String? folderId,
  }) async {
    final id = newId();
    final now = DateTime.now();
    await _db
        .into(_db.canvases)
        .insert(
          CanvasesCompanion.insert(
            id: id,
            title: title,
            createdAt: now,
            updatedAt: now,
            folderId: Value(folderId),
          ),
        );
    return id;
  }

  /// Watches folders in their explicit display order.
  Stream<List<CanvasFolder>> watchFolders() {
    final query = _db.select(_db.canvasFolders)
      ..orderBy([(f) => OrderingTerm(expression: f.position)]);
    return _watchWithInitialRead(query);
  }

  /// Creates a new one-level folder.
  Future<String> createFolder(String name) async {
    final id = newId();
    final now = DateTime.now();
    final maxPositionRow = await _db
        .customSelect(
          'SELECT MAX(position) AS max_position FROM canvas_folders',
        )
        .getSingle();
    final maxPosition =
        maxPositionRow.readNullable<double>('max_position') ?? 0;
    await _db
        .into(_db.canvasFolders)
        .insert(
          CanvasFoldersCompanion.insert(
            id: id,
            name: name,
            position: maxPosition + 1,
            createdAt: now,
          ),
        );
    return id;
  }

  /// Renames a folder.
  Future<void> renameFolder(String id, String name) {
    return (_db.update(_db.canvasFolders)..where((f) => f.id.equals(id))).write(
      CanvasFoldersCompanion(name: Value(name)),
    );
  }

  /// Moves a canvas into [folderId], or to unfiled when [folderId] is null.
  Future<void> moveCanvasToFolder(String canvasId, String? folderId) async {
    final updatedRows =
        await (_db.update(
          _db.canvases,
        )..where((c) => c.id.equals(canvasId))).write(
          CanvasesCompanion(
            folderId: Value(folderId),
            updatedAt: Value(DateTime.now()),
          ),
        );
    if (updatedRows != 1) {
      throw StateError('Canvas $canvasId no longer exists.');
    }
  }

  /// Deletes a folder without deleting its canvases.
  Future<void> deleteFolder(String id) async {
    await _db.transaction(() async {
      await (_db.update(
        _db.canvases,
      )..where((c) => c.folderId.equals(id))).write(
        CanvasesCompanion(
          folderId: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await (_db.delete(_db.canvasFolders)..where((f) => f.id.equals(id))).go();
    });
  }

  /// Renames the canvas [id] to [title] and bumps its `updated_at`.
  Future<void> renameCanvas(String id, String title) {
    return (_db.update(_db.canvases)..where((c) => c.id.equals(id))).write(
      CanvasesCompanion(title: Value(title), updatedAt: Value(DateTime.now())),
    );
  }

  /// Archives the canvas [id], hiding it from the library grid.
  Future<void> archiveCanvas(String id) {
    return (_db.update(_db.canvases)..where((c) => c.id.equals(id))).write(
      const CanvasesCompanion(isArchived: Value(true)),
    );
  }

  /// Permanently deletes the canvas [id]. Foreign-key cascades remove its
  /// elements and detail rows. Focus-session history is detached first so the
  /// canvas foreign key cannot cascade-delete past study records.
  Future<void> deleteCanvas(String id) async {
    final Set<String> fileCandidates = await _ownedFilePathsForCanvas(id);
    await _db.transaction(() async {
      await (_db.update(_db.focusSessions)
            ..where((session) => session.linkedCanvasId.equals(id)))
          .write(const FocusSessionsCompanion(linkedCanvasId: Value(null)));
      await (_db.delete(
        _db.canvases,
      )..where((canvas) => canvas.id.equals(id))).go();
    });
    final List<String> orphaned = <String>[];
    for (final path in fileCandidates) {
      if (!await _isFilePathReferenced(path)) orphaned.add(path);
    }
    await _deleteOwnedFiles(orphaned);
  }

  Future<Set<String>> _ownedFilePathsForCanvas(String canvasId) async {
    final Set<String> paths = <String>{};
    final canvas = await (_db.select(
      _db.canvases,
    )..where((row) => row.id.equals(canvasId))).getSingleOrNull();
    if (canvas?.thumbnailPath case final String thumbnailPath) {
      paths.add(thumbnailPath);
    }
    final elementIds =
        await (_db.selectOnly(_db.canvasElements)
              ..addColumns([_db.canvasElements.id])
              ..where(_db.canvasElements.canvasId.equals(canvasId)))
            .map((row) => row.read(_db.canvasElements.id)!)
            .get();
    if (elementIds.isEmpty) return paths;
    final images = await (_db.select(
      _db.images,
    )..where((image) => image.elementId.isIn(elementIds))).get();
    final pdfs = await (_db.select(
      _db.pdfDocuments,
    )..where((pdf) => pdf.elementId.isIn(elementIds))).get();
    paths
      ..addAll(images.map((image) => image.filePath))
      ..addAll(pdfs.map((pdf) => pdf.filePath));
    return paths;
  }

  Future<bool> _isFilePathReferenced(String path) async {
    final image =
        await (_db.select(_db.images)
              ..where((row) => row.filePath.equals(path))
              ..limit(1))
            .getSingleOrNull();
    if (image != null) return true;
    final pdf =
        await (_db.select(_db.pdfDocuments)
              ..where((row) => row.filePath.equals(path))
              ..limit(1))
            .getSingleOrNull();
    if (pdf != null) return true;
    return await (_db.select(_db.canvases)
              ..where((row) => row.thumbnailPath.equals(path))
              ..limit(1))
            .getSingleOrNull() !=
        null;
  }

  /// Records that the canvas [id] was just opened by setting `last_opened_at`.
  Future<void> touchOpened(String id) {
    return (_db.update(_db.canvases)..where((c) => c.id.equals(id))).write(
      CanvasesCompanion(lastOpenedAt: Value(DateTime.now())),
    );
  }

  /// Updates the generated thumbnail path for [id].
  Future<void> updateThumbnailPath(String id, String thumbnailPath) {
    return (_db.update(_db.canvases)..where((c) => c.id.equals(id))).write(
      CanvasesCompanion(
        thumbnailPath: Value(thumbnailPath),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

Stream<List<T>> _watchWithInitialRead<T>(Selectable<T> query) async* {
  yield await query.get();
  yield* query.watch();
}
