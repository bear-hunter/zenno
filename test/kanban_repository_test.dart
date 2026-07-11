import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/board_tables.dart';
import 'package:zenno/features/goal_cycle/data/goal_repository.dart';
import 'package:zenno/features/revision/data/revision_repository.dart';

void main() {
  for (final boardType in BoardType.values) {
    test('$boardType column reorder renormalizes dense positions', () async {
      final db = ZennoDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final board = await (db.select(
        db.boards,
      )..where((row) => row.boardType.equalsValue(boardType))).getSingle();
      final columns =
          await (db.select(db.boardColumns)
                ..where((row) => row.boardId.equals(board.id))
                ..orderBy([(row) => OrderingTerm.asc(row.position)]))
              .get();
      expect(columns.length, greaterThanOrEqualTo(2));
      await (db.update(db.boardColumns)
            ..where((row) => row.id.equals(columns.first.id)))
          .write(const BoardColumnsCompanion(position: Value(0)));
      await (db.update(db.boardColumns)
            ..where((row) => row.id.equals(columns[1].id)))
          .write(const BoardColumnsCompanion(position: Value(0.000000000001)));

      if (boardType == BoardType.revision) {
        await RevisionRepository(
          db,
        ).reorderColumn(columnId: columns[1].id, newPosition: 0.0000000000005);
      } else {
        await GoalRepository(
          db,
        ).reorderColumn(columnId: columns[1].id, newPosition: 0.0000000000005);
      }

      final reordered =
          await (db.select(db.boardColumns)
                ..where((row) => row.boardId.equals(board.id))
                ..orderBy([(row) => OrderingTerm.asc(row.position)]))
              .get();
      for (var index = 1; index < reordered.length; index += 1) {
        expect(
          reordered[index].position - reordered[index - 1].position,
          greaterThanOrEqualTo(1),
        );
      }
    });
  }

  test(
    'goal draft save rolls back card text when detail write fails',
    () async {
      final db = ZennoDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final board =
          await (db.select(
                db.boards,
              )..where((row) => row.boardType.equalsValue(BoardType.goalCycle)))
              .getSingle();
      final column =
          await (db.select(db.boardColumns)
                ..where((row) => row.boardId.equals(board.id))
                ..limit(1))
              .getSingle();
      final repository = GoalRepository(db);
      final cardId = await repository.addCard(
        columnId: column.id,
        title: 'Original',
        position: 0,
      );
      await db.customStatement('DROP TABLE goal_card_details');

      await expectLater(
        repository.saveCard(
          cardId: cardId,
          title: 'Partial write',
          subtitle: null,
          statusNote: 'Fails',
          targetDate: null,
        ),
        throwsA(anything),
      );

      final card = await (db.select(
        db.boardCards,
      )..where((row) => row.id.equals(cardId))).getSingle();
      expect(card.title, 'Original');
    },
  );
}
