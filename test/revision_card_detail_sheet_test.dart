import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/core/database/tables/board_tables.dart';
import 'package:zenno/features/revision/application/revision_providers.dart';
import 'package:zenno/features/revision/data/revision_repository.dart';
import 'package:zenno/features/revision/presentation/widgets/revision_card_detail_sheet.dart';
import 'package:zenno/shared/canvas_attachments/card_canvas_attachment_providers.dart';
import 'package:zenno/shared/kanban/kanban_models.dart';

void main() {
  testWidgets('dirty dismiss shows discard confirmation', (tester) async {
    await _openSheet(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Changed title');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
  });

  testWidgets('empty title shows validation error', (tester) async {
    await _openSheet(tester);

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.pumpAndSettle();

    expect(find.text('Title is required'), findsOneWidget);
  });

  testWidgets('save persists title and notes without closing sheet', (
    tester,
  ) async {
    final controller = _RecordingRevisionBoardController();
    await _openSheet(tester, controller: controller);

    await tester.enterText(find.byType(TextFormField).at(0), 'Cardiology');
    await tester.enterText(find.byType(TextFormField).at(1), 'Valve notes');
    final saveButton = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(controller.updatedTitle, 'Cardiology');
    expect(controller.updatedSubtitle, 'Valve notes');
    expect(find.text('Revision card'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('dirty mark revised offers save and discard choices', (
    tester,
  ) async {
    await _openSheet(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Changed title');
    await tester.tap(find.text('Mark revised'));
    await tester.pumpAndSettle();

    expect(find.text('Unsaved edits'), findsOneWidget);
    expect(find.text('Save & mark'), findsOneWidget);
    expect(find.text('Mark without saving'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('mark revised records revision only and shows feedback', (
    tester,
  ) async {
    final controller = _RecordingRevisionBoardController();
    await _openSheet(tester, controller: controller);

    await tester.tap(find.text('Mark revised'));
    await tester.pumpAndSettle();

    expect(controller.markRevisedCount, 1);
    expect(controller.moveCardCount, 0);
    expect(find.text('Marked revised'), findsOneWidget);
  });

  testWidgets('failed mastery write reverts the selected flag', (tester) async {
    final controller = _RecordingRevisionBoardController(throwOnFlag: true);
    await _openSheet(tester, controller: controller);

    expect(
      find.byKey(const ValueKey('revision-mastery-yellow-selected')),
      findsOneWidget,
    );

    await tester.tap(find.text('Confident'));
    await tester.pumpAndSettle();

    expect(controller.setFlagCount, 1);
    expect(
      find.byKey(const ValueKey('revision-mastery-yellow-selected')),
      findsOneWidget,
    );
    expect(find.textContaining('Could not update mastery'), findsOneWidget);
  });
}

Future<_RecordingRevisionBoardController> _openSheet(
  WidgetTester tester, {
  _RecordingRevisionBoardController? controller,
  KanbanCardData? card,
}) async {
  final testCard = card ?? _card();
  final testController = controller ?? _RecordingRevisionBoardController();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        revisionBoardControllerProvider.overrideWithValue(testController),
        cardCanvasAttachmentsProvider(
          testCard.id,
        ).overrideWith((ref) => Stream.value(const [])),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showRevisionCardDetailSheet(context, card: testCard),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return testController;
}

KanbanCardData _card() {
  return const KanbanCardData(
    id: 'card',
    columnId: 'column',
    position: 0,
    title: 'Biology',
    subtitle: 'Chapter 1',
    payload: RevisionCardExtra(
      flag: MasteryFlag.yellow,
      lastRevisedAt: null,
      revisionCount: 0,
    ),
  );
}

class _RecordingRevisionBoardController implements RevisionBoardController {
  _RecordingRevisionBoardController({this.throwOnFlag = false});

  final bool throwOnFlag;
  String? updatedTitle;
  String? updatedSubtitle;
  int markRevisedCount = 0;
  int moveCardCount = 0;
  int setFlagCount = 0;

  @override
  Future<String?> addCard({
    required String columnId,
    required String title,
    String? subtitle,
    required double position,
  }) async => 'added-card';

  @override
  Future<void> addColumn({
    required String name,
    required double position,
  }) async {}

  @override
  Future<void> deleteCard(String cardId) async {}

  @override
  Future<void> markRevised(String cardId) async {
    markRevisedCount++;
  }

  @override
  Future<void> moveCard({
    required String cardId,
    required String toColumnId,
    required double newPosition,
  }) async {
    moveCardCount++;
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

  @override
  Future<void> setMasteryFlag({
    required String cardId,
    required MasteryFlag flag,
  }) async {
    setFlagCount++;
    if (throwOnFlag) throw StateError('nope');
  }

  @override
  Future<void> updateCard(
    String cardId, {
    required String title,
    String? subtitle,
  }) async {
    updatedTitle = title;
    updatedSubtitle = subtitle;
  }
}
