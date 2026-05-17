import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zenno/core/database/tables/board_tables.dart';
import 'package:zenno/core/providers/database_provider.dart';
import 'package:zenno/features/revision/data/revision_repository.dart';
import 'package:zenno/shared/kanban/kanban_controller.dart';
import 'package:zenno/shared/kanban/kanban_models.dart';

part 'revision_providers.g.dart';

/// The [RevisionRepository], bound to the app-wide [ZennoDatabase].
@riverpod
RevisionRepository revisionRepository(Ref ref) {
  return RevisionRepository(ref.watch(databaseProvider));
}

/// The Schedule Revision board as a reactive [KanbanBoardData] stream.
///
/// A thin wrapper over [RevisionRepository.watchRevisionBoard]; any write
/// through [RevisionBoardController] re-emits here and rebuilds every
/// watching widget.
@riverpod
Stream<KanbanBoardData> revisionBoard(Ref ref) {
  return ref.watch(revisionRepositoryProvider).watchRevisionBoard();
}

/// A [RevisionBoardController] bound to the repository.
///
/// Plain provider (not a `Notifier`): the controller is stateless — the UI's
/// state lives entirely in the [revisionBoardProvider] stream.
@riverpod
RevisionBoardController revisionBoardController(Ref ref) {
  return RevisionBoardController(ref.watch(revisionRepositoryProvider));
}

/// Adapts [RevisionRepository] to the generic [KanbanController] contract so
/// the shared `KanbanBoardView` can drive the revision board.
///
/// Pure delegation: it adds no behaviour, it only narrows the repository's
/// wide API down to the seven board-mutation methods the widget needs. The
/// revision-specific writes (`updateCard`, `setMasteryFlag`, `markRevised`)
/// stay on the repository and are called directly by the detail sheet.
class RevisionBoardController implements KanbanController {
  /// Creates a controller delegating to [_repository].
  const RevisionBoardController(this._repository);

  final RevisionRepository _repository;

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
  Future<void> renameColumn({required String columnId, required String name}) {
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

  // --- Revision-specific writes (not part of KanbanController) -------------

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

  /// Sets the mastery [flag] on card [cardId].
  Future<void> setMasteryFlag({
    required String cardId,
    required MasteryFlag flag,
  }) {
    return _repository.setMasteryFlag(cardId: cardId, flag: flag);
  }

  /// Records a retrospective revision of card [cardId].
  Future<void> markRevised(String cardId) {
    return _repository.markRevised(cardId);
  }
}
