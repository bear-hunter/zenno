import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/shared/kanban/kanban_board_view.dart';
import 'package:zenno/shared/kanban/kanban_controller.dart';
import 'package:zenno/shared/kanban/kanban_models.dart';

void main() {
  test('drop slots account for removing the dragged item', () {
    expect(
      normalizeKanbanDropIndex(
        rawIndex: 3,
        draggedIndex: 0,
        remainingItemCount: 2,
      ),
      2,
    );
    expect(
      normalizeKanbanDropIndex(
        rawIndex: 2,
        draggedIndex: 1,
        remainingItemCount: 2,
      ),
      1,
    );
    expect(
      normalizeKanbanDropIndex(
        rawIndex: 1,
        draggedIndex: -1,
        remainingItemCount: 3,
      ),
      1,
    );
  });

  test('dense but representable positions keep the requested midpoint', () {
    const before = 1.0;
    const after = 1.000000000001;

    final position = KanbanPositions.between(before, after);

    expect(position, greaterThan(before));
    expect(position, lessThan(after));
  });

  testWidgets('empty board shows useful copy and add column action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        board: const KanbanBoardData(id: 'board', name: 'Board', columns: []),
      ),
    );

    expect(find.text('No columns yet'), findsOneWidget);
    expect(
      find.text('Create a column to start organizing cards.'),
      findsOneWidget,
    );
    expect(find.text('Add column'), findsOneWidget);
  });

  testWidgets('empty column shows useful copy', (tester) async {
    await tester.pumpWidget(_host(board: _board(cards: const [])));

    expect(find.text('No cards yet'), findsOneWidget);
    expect(find.text('Add a card or drop one here.'), findsOneWidget);
  });

  testWidgets('add card dialog accepts title and notes', (tester) async {
    final controller = _RecordingKanbanController();
    await tester.pumpWidget(
      _host(
        board: _board(cards: const []),
        controller: controller,
      ),
    );

    await tester.tap(find.text('Add card'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Cell biology');
    await tester.enterText(find.byType(TextField).at(1), 'Chapter 3');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(controller.addedTitle, 'Cell biology');
    expect(controller.addedSubtitle, 'Chapter 3');
  });

  testWidgets('add and rename dialogs validate blank names', (tester) async {
    await tester.pumpWidget(_host(board: _board(cards: const [])));

    await tester.tap(find.text('Add card'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Title is required'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Column actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Name is required'), findsOneWidget);
  });

  testWidgets('card tap has button semantics and opens callback', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var tapped = false;

    await tester.pumpWidget(
      _host(
        board: _board(cards: [_card()]),
        onCardTap: (_) => tapped = true,
      ),
    );

    final node = tester.getSemantics(
      find.byKey(const ValueKey('kanban-card-card')),
    );
    expect(node.flagsCollection.isButton, isTrue);

    await tester.tap(find.text('Card A'));
    await tester.pump();

    expect(tapped, isTrue);
    semantics.dispose();
  });

  testWidgets('board exposes a visible horizontal scrollbar', (tester) async {
    await tester.pumpWidget(_host(board: _board(cards: [_card()])));

    expect(
      find.byKey(const ValueKey('kanban-horizontal-scrollbar')),
      findsOneWidget,
    );
    final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    expect(scrollbar.thumbVisibility, isTrue);
  });

  testWidgets('card move menu moves the card to another column', (
    tester,
  ) async {
    final controller = _RecordingKanbanController();
    await tester.pumpWidget(
      _host(board: _boardWithSecondColumn(), controller: controller),
    );

    await tester.tap(find.byTooltip('Move Card A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to Later'));
    await tester.pumpAndSettle();

    expect(controller.movedCardId, 'card');
    expect(controller.movedToColumnId, 'later');
  });

  testWidgets('column delete confirmation uses destructive copy', (
    tester,
  ) async {
    await tester.pumpWidget(_host(board: _board(cards: [_card()])));

    await tester.tap(find.byTooltip('Column actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete column'));
    await tester.pumpAndSettle();

    expect(find.text('Delete column?'), findsOneWidget);
    expect(
      find.text('Delete "Today" and its 1 card(s)? This cannot be undone.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Delete'), findsOneWidget);
  });
}

Widget _host({
  required KanbanBoardData board,
  _RecordingKanbanController? controller,
  void Function(KanbanCardData card)? onCardTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 1200,
        height: 800,
        child: KanbanBoardView(
          board: board,
          controller: controller ?? _RecordingKanbanController(),
          cardBuilder: (card) => Text(card.title),
          onCardTap: onCardTap,
        ),
      ),
    ),
  );
}

KanbanBoardData _board({required List<KanbanCardData> cards}) {
  return KanbanBoardData(
    id: 'board',
    name: 'Board',
    columns: [
      KanbanColumnData(id: 'column', name: 'Today', position: 0, cards: cards),
    ],
  );
}

KanbanCardData _card() {
  return const KanbanCardData(
    id: 'card',
    columnId: 'column',
    position: 0,
    title: 'Card A',
  );
}

KanbanBoardData _boardWithSecondColumn() {
  return KanbanBoardData(
    id: 'board',
    name: 'Board',
    columns: [
      KanbanColumnData(
        id: 'column',
        name: 'Today',
        position: 0,
        cards: [_card()],
      ),
      const KanbanColumnData(
        id: 'later',
        name: 'Later',
        position: 1,
        cards: [],
      ),
    ],
  );
}

class _RecordingKanbanController implements KanbanController {
  String? addedTitle;
  String? addedSubtitle;
  String? movedCardId;
  String? movedToColumnId;

  @override
  Future<String?> addCard({
    required String columnId,
    required String title,
    String? subtitle,
    required double position,
  }) async {
    addedTitle = title;
    addedSubtitle = subtitle;
    return 'added-card';
  }

  @override
  Future<void> addColumn({
    required String name,
    required double position,
  }) async {}

  @override
  Future<void> deleteCard(String cardId) async {}

  @override
  Future<void> moveCard({
    required String cardId,
    required String toColumnId,
    required double newPosition,
  }) async {
    movedCardId = cardId;
    movedToColumnId = toColumnId;
  }

  @override
  Future<void> removeColumn(String columnId) async {}

  @override
  Future<void> renameColumn({
    required String columnId,
    required String name,
  }) async {}

  @override
  Future<void> reorderColumn({
    required String columnId,
    required double newPosition,
  }) async {}
}
