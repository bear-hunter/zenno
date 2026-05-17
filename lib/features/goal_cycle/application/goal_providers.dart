import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zenno/core/providers/database_provider.dart';
import 'package:zenno/features/goal_cycle/data/goal_repository.dart';
import 'package:zenno/shared/kanban/kanban_controller.dart';
import 'package:zenno/shared/kanban/kanban_models.dart';

part 'goal_providers.g.dart';

/// The [GoalRepository], bound to the app-wide [ZennoDatabase].
@riverpod
GoalRepository goalRepository(Ref ref) {
  return GoalRepository(ref.watch(databaseProvider));
}

/// The Goal Cycle board as a reactive [KanbanBoardData] stream.
///
/// A thin wrapper over [GoalRepository.watchGoalBoard]; any write through
/// [GoalBoardController] (or a reflection add/delete) re-emits here and
/// rebuilds every watching widget.
///
/// `@riverpod`-safe: [KanbanBoardData] is a hand-written model, not a Drift
/// row type, so it can legally appear in a codegen provider's signature.
@riverpod
Stream<KanbanBoardData> goalBoard(Ref ref) {
  return ref.watch(goalRepositoryProvider).watchGoalBoard();
}

/// A [GoalBoardController] bound to the repository.
///
/// Plain provider (not a `Notifier`): the controller is stateless — the UI's
/// state lives entirely in the [goalBoardProvider] stream.
@riverpod
GoalBoardController goalBoardController(Ref ref) {
  return GoalBoardController(ref.watch(goalRepositoryProvider));
}

/// Adapts [GoalRepository] to the generic [KanbanController] contract so the
/// shared `KanbanBoardView` can drive the Goal Cycle board.
///
/// Pure delegation: it adds no behaviour, it only narrows the repository's
/// wide API down to the seven board-mutation methods the widget needs. The
/// goal-specific writes (`updateCard`, `setTargetDate`, `setStatusNote`) stay
/// on the repository and are called directly by the detail sheet.
class GoalBoardController implements KanbanController {
  /// Creates a controller delegating to [_repository].
  const GoalBoardController(this._repository);

  final GoalRepository _repository;

  @override
  Future<void> moveCard({
    required String cardId,
    required String toColumnId,
    required double newPosition,
  }) {
    return _repository.moveCard(
      cardId: cardId,
      toColumnId: toColumnId,
      newPosition: newPosition,
    );
  }

  @override
  Future<void> reorderColumn({
    required String columnId,
    required double newPosition,
  }) {
    return _repository.reorderColumn(
      columnId: columnId,
      newPosition: newPosition,
    );
  }

  @override
  Future<void> renameColumn({
    required String columnId,
    required String name,
  }) {
    return _repository.renameColumn(columnId: columnId, name: name);
  }

  @override
  Future<void> addColumn({required String name, required double position}) {
    return _repository.addColumn(name: name, position: position);
  }

  @override
  Future<void> removeColumn(String columnId) {
    return _repository.removeColumn(columnId);
  }

  @override
  Future<void> addCard({
    required String columnId,
    required String title,
    String? subtitle,
    required double position,
  }) {
    return _repository.addCard(
      columnId: columnId,
      title: title,
      subtitle: subtitle,
      position: position,
    );
  }

  @override
  Future<void> deleteCard(String cardId) {
    return _repository.deleteCard(cardId);
  }

  // --- Goal-specific writes (not part of KanbanController) -----------------

  /// Updates the title and subtitle of card [cardId]. A `null` [subtitle]
  /// clears it.
  Future<void> updateCard(
    String cardId, {
    required String title,
    String? subtitle,
  }) {
    return _repository.updateCard(
      cardId,
      title: title,
      subtitle: Value(subtitle),
    );
  }

  /// Sets (or, with a `null` [date], clears) the goal's target date.
  Future<void> setTargetDate({
    required String cardId,
    required DateTime? date,
  }) {
    return _repository.setTargetDate(cardId: cardId, date: date);
  }

  /// Sets (or, with a `null` [note], clears) the goal's status note.
  Future<void> setStatusNote({
    required String cardId,
    required String? note,
  }) {
    return _repository.setStatusNote(cardId: cardId, note: note);
  }
}
