import 'package:flutter/material.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/shared/kanban/kanban_column_view.dart';
import 'package:zenno/shared/kanban/kanban_controller.dart';
import 'package:zenno/shared/kanban/kanban_models.dart';

/// A generic, feature-agnostic Kanban board.
///
/// Renders [board] as a horizontally-scrolling row of [KanbanColumnView]s,
/// each a vertical list of cards drawn by [cardBuilder]. All mutations (card
/// moves, column reorders, renames, adds, deletes) are routed through
/// [controller]; the widget keeps no state of its own and re-renders whenever
/// the host feeds it a fresh [board] snapshot.
///
/// The same widget backs Schedule Revision and Goal Cycle — the only
/// difference is the [cardBuilder] and the `payload` each card carries.
class KanbanBoardView extends StatelessWidget {
  /// Creates a board view.
  const KanbanBoardView({
    required this.board,
    required this.controller,
    required this.cardBuilder,
    this.onCardTap,
    super.key,
  });

  /// The board snapshot to render.
  final KanbanBoardData board;

  /// Write surface for every board mutation.
  final KanbanController controller;

  /// Builds the visual tile for a card.
  final Widget Function(KanbanCardData card) cardBuilder;

  /// Optional tap callback for a card (typically opens a detail sheet).
  final void Function(KanbanCardData card)? onCardTap;

  /// Resolves the drop position for the column dragged onto slot [index],
  /// then performs the reorder. [index] counts only columns other than the
  /// one in flight.
  Future<void> _dropColumnAt(int index, String draggedColumnId) {
    final others = [
      for (final c in board.columns)
        if (c.id != draggedColumnId) c,
    ];
    final before = index > 0 ? others[index - 1].position : null;
    final after = index < others.length ? others[index].position : null;

    final currentIndex = board.columns.indexWhere(
      (c) => c.id == draggedColumnId,
    );
    final beforeNow = currentIndex > 0
        ? board.columns[currentIndex - 1].position
        : null;
    final afterNow =
        currentIndex >= 0 && currentIndex < board.columns.length - 1
        ? board.columns[currentIndex + 1].position
        : null;
    if (before == beforeNow && after == afterNow) {
      // Dropped back into its own slot — no write needed.
      return Future<void>.value();
    }

    return controller.reorderColumn(
      columnId: draggedColumnId,
      newPosition: KanbanPositions.between(before, after),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < board.columns.length; i++) ...[
              // Drop zone before column `i` — reorders a dragged column here.
              _ColumnDropZone(onAccept: (id) => _dropColumnAt(i, id)),
              KanbanColumnView(
                key: ValueKey(board.columns[i].id),
                column: board.columns[i],
                controller: controller,
                cardBuilder: cardBuilder,
                onCardTap: onCardTap,
              ),
            ],
            // Trailing drop zone — reorders a dragged column to the end.
            _ColumnDropZone(
              onAccept: (id) => _dropColumnAt(board.columns.length, id),
            ),
            _AddColumnButton(board: board, controller: controller),
          ],
        ),
      ),
    );
  }
}

/// A narrow vertical [DragTarget] sitting between columns. It accepts a
/// column-handle drag and widens to signal a valid drop slot.
class _ColumnDropZone extends StatelessWidget {
  const _ColumnDropZone({required this.onAccept});

  /// Called with the dragged column's id on drop.
  final Future<void> Function(String columnId) onAccept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<KanbanColumnDragData>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onAccept(details.data.columnId),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: hovering ? AppSpacing.sm : AppSpacing.xs,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
          decoration: BoxDecoration(
            color: hovering ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.xs),
          ),
        );
      },
    );
  }
}

/// The "add column" affordance at the end of the board.
class _AddColumnButton extends StatelessWidget {
  const _AddColumnButton({required this.board, required this.controller});

  final KanbanBoardData board;
  final KanbanController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        onTap: () => _addColumn(context),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Add column',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addColumn(BuildContext context) async {
    final name = await showColumnNameDialog(
      context,
      title: 'New column',
      hintText: 'Column name',
    );
    if (name != null) {
      // New columns land at the end of the board.
      final last = board.columns.isEmpty ? null : board.columns.last.position;
      await controller.addColumn(
        name: name,
        position: KanbanPositions.between(last, null),
      );
    }
  }
}
