import 'package:drift/drift.dart';

import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/board_tables.dart';
import 'package:zenno/core/util/id.dart';
import 'package:zenno/shared/kanban/kanban_models.dart';

/// Feature-specific data riding on a revision card's opaque
/// [KanbanCardData.payload].
///
/// The generic Kanban widget never reads this — only the revision feature's
/// card builder and detail sheet do.
class RevisionCardExtra {
  /// Creates the extra data for a revision card.
  const RevisionCardExtra({
    required this.flag,
    required this.lastRevisedAt,
    required this.revisionCount,
  });

  /// Retrospective mastery rating.
  final MasteryFlag flag;

  /// When "Mark revised" was last pressed, or `null` if never.
  final DateTime? lastRevisedAt;

  /// How many times the card has been marked revised.
  final int revisionCount;
}

/// The only code that touches Drift for the Schedule Revision board.
///
/// Exposes the board as a single reactive [Stream] (a write to any joined
/// table re-emits) and a set of `Future` writes. Drift types never leak past
/// this class — reads come out as [KanbanBoardData], writes take plain values.
///
/// Ordering uses the fractional `position` columns: a move is a single-row
/// UPDATE. Callers compute the target position; this repository just stores
/// it. It also runs a renormalisation pass when neighbouring card positions
/// converge too closely to remain distinct.
class RevisionRepository {
  /// Creates a repository over the given [_db].
  RevisionRepository(this._db);

  final ZennoDatabase _db;

  /// Below this gap between two neighbouring positions, a fresh midpoint can
  /// no longer be represented distinctly — the column is renormalised.
  static const double _minPositionGap = 1e-6;

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Watches the seeded `revision` board as a [KanbanBoardData].
  ///
  /// A single joined query over `boards` → `board_columns` → `board_cards` →
  /// `revision_card_details` backs the stream, so it re-emits on any change
  /// to any of those tables. Columns and cards are returned sorted by
  /// `position`; each card's `payload` is a [RevisionCardExtra].
  ///
  /// While the board itself has no cards the join still yields its columns
  /// (an outer join from columns to cards). If — defensively — no revision
  /// board has been seeded, the stream emits an empty board.
  Stream<KanbanBoardData> watchRevisionBoard() {
    // boards ⟕ board_columns ⟕ board_cards ⟕ revision_card_details.
    // Outer joins so a column with no cards, and a card with no detail row,
    // both still surface.
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
            _db.revisionCardDetails,
            _db.revisionCardDetails.cardId.equalsExp(_db.boardCards.id),
          ),
        ])
          ..where(_db.boards.boardType.equalsValue(BoardType.revision))
          ..orderBy([
            OrderingTerm.asc(_db.boardColumns.position),
            OrderingTerm.asc(_db.boardCards.position),
          ]);

    return query.watch().map(_rowsToBoard);
  }

  /// Assembles the flat joined [rows] into a single [KanbanBoardData].
  ///
  /// Because the join fans out, the board and each column appear on multiple
  /// rows; columns are de-duplicated by id while preserving first-seen
  /// (position-sorted) order, and cards are appended under their column.
  KanbanBoardData _rowsToBoard(List<TypedResult> rows) {
    if (rows.isEmpty) {
      return const KanbanBoardData(
        id: '',
        name: 'Schedule Revision',
        columns: [],
      );
    }

    final board = rows.first.readTable(_db.boards);

    // Column id → its accumulating card list, in insertion (= sorted) order.
    final columnOrder = <String>[];
    final columnById = <String, BoardColumn>{};
    final cardsByColumn = <String, List<KanbanCardData>>{};

    for (final row in rows) {
      final column = row.readTableOrNull(_db.boardColumns);
      if (column == null) continue; // Board exists but has no columns.

      if (!columnById.containsKey(column.id)) {
        columnById[column.id] = column;
        columnOrder.add(column.id);
        cardsByColumn[column.id] = <KanbanCardData>[];
      }

      final card = row.readTableOrNull(_db.boardCards);
      if (card == null) continue; // Column with no cards.
      final detail = row.readTableOrNull(_db.revisionCardDetails);
      cardsByColumn[column.id]!.add(_toCardData(card, detail));
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
            cards: cardsByColumn[id]!,
          ),
      ],
    );
  }

  /// Maps a Drift [card] row plus its optional [detail] row into the generic
  /// [KanbanCardData], stashing a [RevisionCardExtra] as the payload.
  KanbanCardData _toCardData(BoardCard card, RevisionCardDetail? detail) {
    return KanbanCardData(
      id: card.id,
      columnId: card.columnId,
      position: card.position,
      title: card.title,
      subtitle: card.subtitle,
      payload: RevisionCardExtra(
        // Defensive default: a detail row should always exist (addCard
        // creates it), but a card without one is treated as freshly added.
        flag: detail?.masteryFlag ?? MasteryFlag.yellow,
        lastRevisedAt: detail?.lastRevisedAt,
        revisionCount: detail?.revisionCount ?? 0,
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
  /// 1:1 `revision_card_details` row in one transaction. Returns the new id.
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
          .into(_db.revisionCardDetails)
          .insert(
            RevisionCardDetailsCompanion.insert(
              cardId: cardId,
              // A new card starts "shaky" until it has been revised.
              masteryFlag: MasteryFlag.yellow,
            ),
          );
    });
    return cardId;
  }

  /// Deletes card [cardId]. The `revision_card_details` row goes with it via
  /// the FK cascade.
  Future<void> deleteCard(String cardId) async {
    await (_db.delete(_db.boardCards)..where((c) => c.id.equals(cardId))).go();
  }

  /// Sets the mastery [flag] on card [cardId].
  Future<void> setMasteryFlag({
    required String cardId,
    required MasteryFlag flag,
  }) async {
    await (_db.update(_db.revisionCardDetails)
          ..where((d) => d.cardId.equals(cardId)))
        .write(RevisionCardDetailsCompanion(masteryFlag: Value(flag)));
  }

  /// Records a retrospective revision of card [cardId]: stamps
  /// `last_revised_at` to now and increments `revision_count`.
  ///
  /// Reads the current count first (a small single-row query) so it is
  /// portable regardless of in-place SQL increment support.
  Future<void> markRevised(String cardId) async {
    final detailQuery = _db.select(_db.revisionCardDetails)
      ..where((d) => d.cardId.equals(cardId));
    final detail = await detailQuery.getSingleOrNull();
    final nextCount = (detail?.revisionCount ?? 0) + 1;

    await (_db.update(_db.revisionCardDetails)
          ..where((d) => d.cardId.equals(cardId)))
        .write(
          RevisionCardDetailsCompanion(
            lastRevisedAt: Value(DateTime.now().toUtc()),
            revisionCount: Value(nextCount),
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

  /// Appends a column titled [name] at fractional [position] on the revision
  /// board.
  Future<void> addColumn({
    required String name,
    required double position,
  }) async {
    final boardId = await _revisionBoardId();
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

  /// Deletes column [columnId]; its cards (and their details) cascade.
  Future<void> removeColumn(String columnId) async {
    await (_db.delete(_db.boardColumns)..where((c) => c.id.equals(columnId)))
        .go();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Returns the id of the seeded `revision` board, or `null` if unseeded.
  Future<String?> _revisionBoardId() async {
    final query = _db.select(_db.boards)
      ..where((b) => b.boardType.equalsValue(BoardType.revision))
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
