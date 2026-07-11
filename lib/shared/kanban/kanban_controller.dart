/// The write surface the generic Kanban widget drives, plus the
/// fractional-index math used to compute drag-drop positions.
library;

/// Mutation contract for a Kanban board.
///
/// [KanbanBoardView] holds one of these and calls it on every user edit
/// (drag, rename, add, delete). Concrete implementations — one per feature —
/// delegate to that feature's repository, which owns all persistence. The
/// widget itself never touches a database.
///
/// Most methods are fire-and-forget `Future`s: the UI is driven by a separate
/// reactive read stream, so callers need completion for error handling. Card
/// creation may return the new card id so feature UIs can open post-add
/// options without coupling the shared widget to feature details.
abstract interface class KanbanController {
  /// Moves the card [cardId] into column [toColumnId] at fractional
  /// [newPosition]. Used both for cross-column moves and in-column reorders.
  Future<void> moveCard({
    required String cardId,
    required String toColumnId,
    required double newPosition,
  });

  /// Re-positions the column [columnId] to fractional [newPosition].
  Future<void> reorderColumn({
    required String columnId,
    required double newPosition,
  });

  /// Renames the column [columnId] to [name].
  Future<void> renameColumn({required String columnId, required String name});

  /// Appends a new column titled [name] at fractional [position].
  Future<void> addColumn({required String name, required double position});

  /// Deletes the column [columnId] and (by FK cascade) all of its cards.
  Future<void> removeColumn(String columnId);

  /// Adds a new card to column [columnId] at fractional [position].
  ///
  /// Returns the new card id when the backing implementation can provide it.
  Future<String?> addCard({
    required String columnId,
    required String title,
    String? subtitle,
    required double position,
  });

  /// Deletes the card [cardId].
  Future<void> deleteCard(String cardId);
}

/// Fractional-index arithmetic for ordering cards and columns.
///
/// A list whose items each hold a `double position` can be reordered with a
/// single-row write: to drop an item between two neighbours, store the
/// midpoint of their positions. At the ends there is no neighbour on one
/// side, so we step out by a fixed [gap]. Inserting into an empty list yields
/// a stable starting value of `0`.
///
/// Over many reorders in the *same* slot, repeated midpoints converge toward
/// the limit of `double` precision; the host repository is expected to run an
/// occasional renormalisation pass (rewrite positions as `0, 1, 2, …`). This
/// helper only does the per-drop math.
abstract final class KanbanPositions {
  const KanbanPositions._();

  /// The step taken when there is only one neighbour (an end insertion).
  static const double gap = 1024;

  /// Returns a position that sorts strictly between [before] and [after]
  /// where possible.
  ///
  /// If neighbours are equal, inverted, or too close for a useful midpoint,
  /// this returns a deterministic tail-side step instead of reusing a colliding
  /// value. Repositories should still renormalise dense lists, but this avoids
  /// the worst same-position drops.
  ///
  /// - both non-null  → their midpoint.
  /// - only [after]   → `after - gap` (insert at the head).
  /// - only [before]  → `before + gap` (insert at the tail).
  /// - both null      → `0` (the first item in an empty list).
  static double between(double? before, double? after) {
    if (before != null && after != null) {
      final delta = after - before;
      final midpoint = before + delta / 2;
      if (midpoint > before && midpoint < after) return midpoint;
      return before + gap;
    }
    if (after != null) {
      return after - gap;
    }
    if (before != null) {
      return before + gap;
    }
    return 0;
  }
}
