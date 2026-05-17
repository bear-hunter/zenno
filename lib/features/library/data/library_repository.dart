import 'package:drift/drift.dart';

import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/util/id.dart';

/// Ordering applied to the canvas library grid.
///
/// Persisted (in a later phase) to `app_settings.library_sort`; for now it is
/// held in memory by the library's sort provider.
enum LibrarySort {
  /// Most recently edited first — ordered by `updated_at` descending.
  recent,

  /// Most recently created first — ordered by `created_at` descending.
  created,

  /// Alphabetical — ordered by `title` ascending.
  title,
}

/// Data layer for the canvas library.
///
/// The only code in the feature that touches Drift: it exposes reactive
/// `Stream` reads over the `canvases` table and `Future` writes, returning the
/// Drift-generated [Canvase] row class to the layers above.
class LibraryRepository {
  /// Creates a repository backed by [db].
  const LibraryRepository(this._db);

  final ZennoDatabase _db;

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

    return query.watch();
  }

  /// Inserts a new, empty canvas and returns its generated id.
  ///
  /// [title] defaults to `Untitled`. Timestamps are set to now; every other
  /// non-null column falls back to its schema default (blank background,
  /// identity viewport, not archived).
  Future<String> createCanvas({String title = 'Untitled'}) async {
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
          ),
        );
    return id;
  }

  /// Renames the canvas [id] to [title] and bumps its `updated_at`.
  Future<void> renameCanvas(String id, String title) {
    return (_db.update(_db.canvases)..where((c) => c.id.equals(id))).write(
      CanvasesCompanion(
        title: Value(title),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Archives the canvas [id], hiding it from the library grid.
  Future<void> archiveCanvas(String id) {
    return (_db.update(_db.canvases)..where((c) => c.id.equals(id))).write(
      const CanvasesCompanion(isArchived: Value(true)),
    );
  }

  /// Permanently deletes the canvas [id]. Foreign-key cascades remove its
  /// elements and detail rows.
  Future<void> deleteCanvas(String id) {
    return (_db.delete(_db.canvases)..where((c) => c.id.equals(id))).go();
  }

  /// Records that the canvas [id] was just opened by setting `last_opened_at`.
  Future<void> touchOpened(String id) {
    return (_db.update(_db.canvases)..where((c) => c.id.equals(id))).write(
      CanvasesCompanion(lastOpenedAt: Value(DateTime.now())),
    );
  }
}
