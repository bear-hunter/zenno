import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/core/database/tables/board_tables.dart';
import 'package:zenno/features/goal_cycle/application/goal_providers.dart';
import 'package:zenno/features/goal_cycle/presentation/pages/goal_board_page.dart';
import 'package:zenno/features/revision/application/revision_providers.dart';
import 'package:zenno/features/revision/presentation/pages/revision_board_page.dart';
import 'package:zenno/shared/kanban/kanban_models.dart';

void main() {
  testWidgets('revision board shows add column when empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          revisionBoardProvider.overrideWith(
            (ref) => Stream.value(_emptyBoard('revision')),
          ),
          revisionBoardControllerProvider.overrideWithValue(
            const _NoopRevisionBoardController(),
          ),
        ],
        child: const MaterialApp(home: RevisionBoardPage()),
      ),
    );

    await tester.pump();

    expect(find.text('Add column'), findsOneWidget);
  });

  testWidgets('goal board shows add column when empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          goalBoardProvider.overrideWith(
            (ref) => Stream.value(_emptyBoard('goalCycle')),
          ),
          goalBoardControllerProvider.overrideWithValue(
            const _NoopGoalBoardController(),
          ),
        ],
        child: const MaterialApp(home: GoalBoardPage()),
      ),
    );

    await tester.pump();

    expect(find.text('Add column'), findsOneWidget);
  });
}

KanbanBoardData _emptyBoard(String id) {
  return KanbanBoardData(id: id, name: id, columns: const []);
}

class _NoopRevisionBoardController implements RevisionBoardController {
  const _NoopRevisionBoardController();

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
  Future<void> markRevised(String cardId) async {}

  @override
  Future<void> moveCard({
    required String cardId,
    required String toColumnId,
    required double newPosition,
  }) async {}

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
  }) async {}

  @override
  Future<void> updateCard(
    String cardId, {
    required String title,
    String? subtitle,
  }) async {}
}

class _NoopGoalBoardController implements GoalBoardController {
  const _NoopGoalBoardController();

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
  Future<void> moveCard({
    required String cardId,
    required String toColumnId,
    required double newPosition,
  }) async {}

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
  Future<void> setStatusNote({
    required String cardId,
    required String? note,
  }) async {}

  @override
  Future<void> setTargetDate({
    required String cardId,
    required DateTime? date,
  }) async {}

  @override
  Future<void> saveCard({
    required String cardId,
    required String title,
    required String? subtitle,
    required String? statusNote,
    required DateTime? targetDate,
  }) async {}

  @override
  Future<void> updateCard(
    String cardId, {
    required String title,
    String? subtitle,
  }) async {}
}
