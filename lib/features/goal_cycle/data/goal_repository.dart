import 'package:drift/drift.dart';

import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/board_tables.dart';
import 'package:zenno/core/util/id.dart';
import 'package:zenno/shared/kanban/kanban_models.dart';

/// Feature-specific data riding on a goal card's opaque
/// [KanbanCardData.payload].
///
/// The generic Kanban widget never reads this — only the Goal Cycle feature's
/// card builder and detail sheet do.
class GoalCardExtra {
  /// Creates the extra data for a goal card.
  const GoalCardExtra({
    required this.targetDate,
    required this.statusNote,
    required this.reflectionCount,
  });

  /// Optional target / deadline date for the goal.
  final DateTime? targetDate;

  /// Optional free-text status note from `goal_card_details`.
  final String? statusNote;

  /// How many `reflection_entries` rows reference this card.
  final int reflectionCount;
}

/// The only code that touches Drift for the Goal Cycle board.
///
/// Exposes the board as a single reactive [Stream] (a write to any joined
/// table re-emits) and a set of `Future` writes. Drift types never leak past
/// this class — reads come out as [KanbanBoardData], writes take plain values.
///
/// Ordering uses the fractional `position` columns: a move is a single-row
/// UPDATE. Callers compute the target position; this repository just stores
/// it. It also runs a renormalisation pass when neighbouring card positions
/// converge too closely to remain distinct.
class GoalRepository {
  /// Creates a repository over the given [_db].
  GoalRepository(this._db);

  final ZennoDatabase _db;

  /// Below this gap between two neighbouring positions, a fresh midpoint can
  /// no longer be represented distinctly — the column is renormalised.
  static const double _minPositionGap = 1e-6;

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Watches the seeded `goalCycle` board as a [KanbanBoardData].
  ///
  /// A single joined query over `boards` → `board_columns` → `board_cards` →
  /// `goal_card_details` → `reflection_entries` backs the stream, so it
  /// re-emits on any change to any of those tables (including adding or
  /// deleting a reflection — card badges stay live). Columns and cards are
  /// returned sorted by `position`; each card's `payload` is a [GoalCardExtra].
  ///
  /// The join to `reflection_entries` fans out one row per card × reflection,
  /// so reflection ids are collected into a per-card [Set] and counted —
  /// double-counting is impossible.
  ///
  /// While the board itself has no cards the join still yields its columns
  /// (an outer join from columns to cards). If — defensively — no goal-cycle
  /// board has been seeded, the stream emits an empty board.
  Stream<KanbanBoardData> watchGoalBoard() {
    // boards ⟕ board_columns ⟕ board_cards ⟕ goal_card_details
    //        ⟕ reflection_entries.
    // Outer joins so a column with no cards, a card with no detail row, and a
    // card with no reflections all still surface.
    final query =
        _db.select(_db.boards).join([
            leftOuterJoin(
              _db.boardColumns,
              _db.boardColumns.boardId.equalsExp(_db.boards.id),
            ),
            leftOuterJoin(
              _db.boardCards,
              _db.boardCards.columnId.equalsExp(_db.boardColumns.id),
            ),
            leftOuterJoin(
              _db.goalCardDetails,
              _db.goalCardDetails.cardId.equalsExp(_db.boardCards.id),
            ),
            leftOuterJoin(
              _db.reflectionEntries,
              _db.reflectionEntries.cardId.equalsExp(_db.boardCards.id),
            ),
          ])
          ..where(_db.boards.boardType.equalsValue(BoardType.goalCycle))
          ..orderBy([
            OrderingTerm.asc(_db.boardColumns.position),
            OrderingTerm.asc(_db.boardCards.position),
          ]);

    return query.watch().map(_rowsToBoard);
  }

  /// Assembles the flat joined [rows] into a single [KanbanBoardData].
  ///
  /// Because the joins fan out, the board, each column and each card appear on
  /// multiple rows; columns and cards are de-duplicated by id while preserving
  /// first-seen (position-sorted) order. Reflection ids are collected per card
  /// into a [Set] so the resulting [GoalCardExtra.reflectionCount] is exact.
  KanbanBoardData _rowsToBoard(List<TypedResult> rows) {
    if (rows.isEmpty) {
      return const KanbanBoardData(id: '', name: 'Goal Cycle', columns: []);
    }

    final board = rows.first.readTable(_db.boards);

    // Column id → its accumulating card list, in insertion (= sorted) order.
    final columnOrder = <String>[];
    final columnById = <String, BoardColumn>{};
    final cardsByColumn = <String, List<BoardCard>>{};

    // Card id → its detail row and the set of distinct reflection ids seen.
    final detailByCard = <String, GoalCardDetail?>{};
    final reflectionIdsByCard = <String, Set<String>>{};

    for (final row in rows) {
      final column = row.readTableOrNull(_db.boardColumns);
      if (column == null) continue; // Board exists but has no columns.

      if (!columnById.containsKey(column.id)) {
        columnById[column.id] = column;
        columnOrder.add(column.id);
        cardsByColumn[column.id] = <BoardCard>[];
      }

      final card = row.readTableOrNull(_db.boardCards);
      if (card == null) continue; // Column with no cards.

      if (!reflectionIdsByCard.containsKey(card.id)) {
        cardsByColumn[column.id]!.add(card);
        detailByCard[card.id] = row.readTableOrNull(_db.goalCardDetails);
        reflectionIdsByCard[card.id] = <String>{};
      }

      final reflection = row.readTableOrNull(_db.reflectionEntries);
      if (reflection != null) {
        reflectionIdsByCard[card.id]!.add(reflection.id);
      }
    }

    return KanbanBoardData(
      id: board.id,
      name: board.name,
      columns: [
        for (final id in columnOrder)
          KanbanColumnData(
            id: id,
            name: columnById[id]!.name,
            position: columnById[id]!.position,
            cards: [
              for (final card in cardsByColumn[id]!)
                _toCardData(
                  card,
                  detailByCard[card.id],
                  reflectionIdsByCard[card.id]!.length,
                ),
            ],
          ),
      ],
    );
  }

  /// Maps a Drift [card] row plus its optional [detail] row and reflection
  /// [reflectionCount] into the generic [KanbanCardData], stashing a
  /// [GoalCardExtra] as the payload.
  KanbanCardData _toCardData(
    BoardCard card,
    GoalCardDetail? detail,
    int reflectionCount,
  ) {
    return KanbanCardData(
      id: card.id,
      columnId: card.columnId,
      position: card.position,
      title: card.title,
      subtitle: card.subtitle,
      payload: GoalCardExtra(
        targetDate: detail?.targetDate,
        statusNote: detail?.statusNote,
        reflectionCount: reflectionCount,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card writes
  // ---------------------------------------------------------------------------

  /// Moves card [cardId] into [toColumnId] at fractional [newPosition].
  Future<void> moveCard({
    required String cardId,
    required String toColumnId,
    required double newPosition,
  }) async {
    await (_db.update(_db.boardCards)..where((c) => c.id.equals(cardId))).write(
      BoardCardsCompanion(
        columnId: Value(toColumnId),
        position: Value(newPosition),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    await _renormaliseColumnIfNeeded(toColumnId);
  }

  /// Updates the editable text of card [cardId].
  ///
  /// Passing an absent [subtitle] leaves it unchanged; passing `Value(null)`
  /// clears it.
  Future<void> updateCard(
    String cardId, {
    required String title,
    Value<String?> subtitle = const Value.absent(),
  }) async {
    await (_db.update(_db.boardCards)..where((c) => c.id.equals(cardId))).write(
      BoardCardsCompanion(
        title: Value(title),
        subtitle: subtitle,
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Adds a card to [columnId], creating both the `board_cards` row and its
  /// 1:1 `goal_card_details` row in one transaction. Returns the new id.
  Future<String> addCard({
    required String columnId,
    required String title,
    String? subtitle,
    required double position,
  }) async {
    final cardId = newId();
    final now = DateTime.now().toUtc();
    final boardId = await _boardIdForColumn(columnId);

    await _db.transaction(() async {
      await _db
          .into(_db.boardCards)
          .insert(
            BoardCardsCompanion.insert(
              id: cardId,
              columnId: columnId,
              boardId: boardId,
              title: title,
              subtitle: Value(subtitle),
              position: position,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _db
          .into(_db.goalCardDetails)
          .insert(GoalCardDetailsCompanion.insert(cardId: cardId));
    });
    return cardId;
  }

  /// Deletes card [cardId]. Its `goal_card_details` row and any
  /// `reflection_entries` go with it via the FK cascade.
  Future<void> deleteCard(String cardId) async {
    await (_db.delete(_db.boardCards)..where((c) => c.id.equals(cardId))).go();
  }

  /// Sets (or, with a `null` [date], clears) the target date of card [cardId].
  ///
  /// The `goal_card_details` row is created on demand if it is somehow
  /// missing — `addCard` always makes one, but this keeps the write safe.
  Future<void> setTargetDate({
    required String cardId,
    required DateTime? date,
  }) async {
    await _db
        .into(_db.goalCardDetails)
        .insertOnConflictUpdate(
          GoalCardDetailsCompanion(
            cardId: Value(cardId),
            targetDate: Value(date),
          ),
        );
  }

  /// Sets (or, with a `null` [note], clears) the status note of card [cardId].
  Future<void> setStatusNote({
    required String cardId,
    required String? note,
  }) async {
    await _db
        .into(_db.goalCardDetails)
        .insertOnConflictUpdate(
          GoalCardDetailsCompanion(
            cardId: Value(cardId),
            statusNote: Value(note),
          ),
        );
  }

  // ---------------------------------------------------------------------------
  // Column writes
  // ---------------------------------------------------------------------------

  /// Re-positions column [columnId] to fractional [newPosition].
  Future<void> reorderColumn({
    required String columnId,
    required double newPosition,
  }) async {
    await (_db.update(_db.boardColumns)..where((c) => c.id.equals(columnId)))
        .write(BoardColumnsCompanion(position: Value(newPosition)));
  }

  /// Renames column [columnId] to [name].
  Future<void> renameColumn({
    required String columnId,
    required String name,
  }) async {
    await (_db.update(_db.boardColumns)..where((c) => c.id.equals(columnId)))
        .write(BoardColumnsCompanion(name: Value(name)));
  }

  /// Appends a column titled [name] at fractional [position] on the goal-cycle
  /// board.
  Future<void> addColumn({
    required String name,
    required double position,
  }) async {
    final boardId = await _goalBoardId();
    if (boardId == null) return;
    await _db
        .into(_db.boardColumns)
        .insert(
          BoardColumnsCompanion.insert(
            id: newId(),
            boardId: boardId,
            name: name,
            position: position,
          ),
        );
  }

  /// Deletes column [columnId]; its cards (details + reflections) cascade.
  Future<void> removeColumn(String columnId) async {
    await (_db.delete(
      _db.boardColumns,
    )..where((c) => c.id.equals(columnId))).go();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Returns the id of the seeded `goalCycle` board, or `null` if unseeded.
  Future<String?> _goalBoardId() async {
    final query = _db.select(_db.boards)
      ..where((b) => b.boardType.equalsValue(BoardType.goalCycle))
      ..orderBy([(b) => OrderingTerm.asc(b.createdAt)])
      ..limit(1);
    final board = await query.getSingleOrNull();
    return board?.id;
  }

  /// Looks up the `board_id` that owns [columnId].
  Future<String> _boardIdForColumn(String columnId) async {
    final query = _db.select(_db.boardColumns)
      ..where((c) => c.id.equals(columnId));
    final column = await query.getSingle();
    return column.boardId;
  }

  /// Rewrites every position in [columnId] as `0, 1, 2, …` when two adjacent
  /// cards have drifted too close to host a future midpoint.
  ///
  /// Cheap and rare — a column holds few cards and only converges after many
  /// drops into the same slot.
  Future<void> _renormaliseColumnIfNeeded(String columnId) async {
    final query = _db.select(_db.boardCards)
      ..where((c) => c.columnId.equals(columnId))
      ..orderBy([(c) => OrderingTerm.asc(c.position)]);
    final cards = await query.get();

    var needsRenormalise = false;
    for (var i = 1; i < cards.length; i++) {
      if (cards[i].position - cards[i - 1].position < _minPositionGap) {
        needsRenormalise = true;
        break;
      }
    }
    if (!needsRenormalise) return;

    await _db.transaction(() async {
      for (var i = 0; i < cards.length; i++) {
        await (_db.update(_db.boardCards)
              ..where((c) => c.id.equals(cards[i].id)))
            .write(BoardCardsCompanion(position: Value(i.toDouble())));
      }
    });
  }
}
