import 'package:drift/drift.dart';
import 'package:zenno/core/database/tables/canvas_tables.dart';

/// Which feature a Kanban board belongs to.
enum BoardType { revision, goalCycle }

/// Retrospective mastery rating for a revision card.
enum MasteryFlag { green, yellow, red }

/// A Kanban board. v1 seeds one board per [BoardType].
class Boards extends Table {
  TextColumn get id => text()();
  IntColumn get boardType => intEnum<BoardType>()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A renameable, reorderable column within a [Boards] row.
@TableIndex(name: 'idx_board_columns_board_id', columns: {#boardId})
class BoardColumns extends Table {
  TextColumn get id => text()();
  TextColumn get boardId =>
      text().references(Boards, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();

  /// Fractional ordering position.
  RealColumn get position => real()();

  /// Optional ARGB colour for the column header.
  IntColumn get color => integer().nullable()();
  IntColumn get wipLimit => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A card on a Kanban board. [boardId] is denormalised for fast queries.
@TableIndex(
  name: 'idx_board_cards_column_id_position',
  columns: {#columnId, #position},
)
@TableIndex(name: 'idx_board_cards_board_id', columns: {#boardId})
class BoardCards extends Table {
  TextColumn get id => text()();
  TextColumn get columnId =>
      text().references(BoardColumns, #id, onDelete: KeyAction.cascade)();
  TextColumn get boardId =>
      text().references(Boards, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get subtitle => text().nullable()();

  /// Fractional ordering position within the column.
  RealColumn get position => real()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 1:1 detail for revision-board cards. The retrospective model: "Mark revised"
/// stamps [lastRevisedAt] and increments [revisionCount]; the column is a
/// user-chosen bucket — the app never computes due dates.
class RevisionCardDetails extends Table {
  TextColumn get cardId =>
      text().references(BoardCards, #id, onDelete: KeyAction.cascade)();
  IntColumn get masteryFlag => intEnum<MasteryFlag>()();
  DateTimeColumn get lastRevisedAt => dateTime().nullable()();
  IntColumn get revisionCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {cardId};
}

/// 1:1 detail for goal-cycle cards.
class GoalCardDetails extends Table {
  TextColumn get cardId =>
      text().references(BoardCards, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get statusNote => text().nullable()();

  @override
  Set<Column> get primaryKey => {cardId};
}

/// Soft ownership link between a study-system card and a normal library canvas.
///
/// Detaching deletes only this row. Deleting either the card or the canvas
/// cascades the attachment so stale rows never survive.
@TableIndex(
  name: 'idx_card_canvas_attachments_card_position',
  columns: {#cardId, #position},
)
@TableIndex(name: 'idx_card_canvas_attachments_canvas_id', columns: {#canvasId})
class CardCanvasAttachments extends Table {
  TextColumn get id => text()();
  TextColumn get cardId =>
      text().references(BoardCards, #id, onDelete: KeyAction.cascade)();
  TextColumn get canvasId =>
      text().references(Canvases, #id, onDelete: KeyAction.cascade)();
  TextColumn get label => text()();

  /// Fractional ordering position within the card's canvas list.
  RealColumn get position => real()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {cardId, canvasId},
  ];
}
