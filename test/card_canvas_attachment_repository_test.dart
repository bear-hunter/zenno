import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/database/tables/board_tables.dart';
import 'package:zenno/features/library/data/library_repository.dart';
import 'package:zenno/shared/canvas_attachments/card_canvas_attachment_repository.dart';

void main() {
  late ZennoDatabase db;
  late LibraryRepository library;
  late CardCanvasAttachmentRepository repo;

  setUp(() async {
    db = ZennoDatabase(NativeDatabase.memory());
    library = LibraryRepository(db);
    repo = CardCanvasAttachmentRepository(db, library);
    await _insertCard(db, 'card-1');
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'create-and-attach creates a library canvas and ordered attachment',
    () async {
      final canvasId = await repo.createAndAttach(
        cardId: 'card-1',
        title: 'Renal map',
      );

      final canvases = await db.select(db.canvases).get();
      final attachments = await repo.watchForCard('card-1').first;

      expect(canvases.single.id, canvasId);
      expect(canvases.single.title, 'Renal map');
      expect(attachments.single.canvasId, canvasId);
      expect(attachments.single.label, 'Renal map');
      expect(attachments.single.position, 1000);
    },
  );

  test(
    'attach-existing, rename label, and detach without deleting canvas',
    () async {
      final canvasId = await library.createCanvas(title: 'Cardiology');
      await repo.attachExisting(cardId: 'card-1', canvasId: canvasId);
      var attachment = (await repo.watchForCard('card-1').first).single;

      await repo.renameLabel(
        attachmentId: attachment.id,
        label: 'Heart failure sketch',
      );
      attachment = (await repo.watchForCard('card-1').first).single;
      expect(attachment.label, 'Heart failure sketch');

      await repo.detach(attachment.id);

      expect(await repo.watchForCard('card-1').first, isEmpty);
      expect(await db.select(db.canvases).get(), hasLength(1));
    },
  );

  test('deleting canvas or card cascades attachment rows only', () async {
    final first = await library.createCanvas(title: 'First');
    final second = await library.createCanvas(title: 'Second');
    await repo.attachExisting(cardId: 'card-1', canvasId: first);
    await repo.attachExisting(cardId: 'card-1', canvasId: second);

    await (db.delete(db.canvases)..where((c) => c.id.equals(first))).go();

    var attachments = await repo.watchForCard('card-1').first;
    expect(attachments.map((a) => a.canvasId), [second]);

    await (db.delete(db.boardCards)..where((c) => c.id.equals('card-1'))).go();

    attachments = await repo.watchForCard('card-1').first;
    expect(attachments, isEmpty);
    expect(await db.select(db.canvases).get(), hasLength(1));
  });
}

Future<void> _insertCard(ZennoDatabase db, String cardId) async {
  await db
      .into(db.boards)
      .insert(
        BoardsCompanion.insert(
          id: 'board-1',
          boardType: BoardType.revision,
          name: 'Board',
          createdAt: DateTime.utc(2026),
        ),
      );
  await db
      .into(db.boardColumns)
      .insert(
        BoardColumnsCompanion.insert(
          id: 'column-1',
          boardId: 'board-1',
          name: 'Column',
          position: 1000,
        ),
      );
  await db
      .into(db.boardCards)
      .insert(
        BoardCardsCompanion.insert(
          id: cardId,
          columnId: 'column-1',
          boardId: 'board-1',
          title: 'Card',
          position: 1000,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
}
