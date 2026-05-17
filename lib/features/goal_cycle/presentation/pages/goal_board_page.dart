import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/features/goal_cycle/application/goal_providers.dart';
import 'package:zenno/features/goal_cycle/presentation/pages/templates_page.dart';
import 'package:zenno/features/goal_cycle/presentation/widgets/goal_card_detail_sheet.dart';
import 'package:zenno/features/goal_cycle/presentation/widgets/goal_card_tile.dart';
import 'package:zenno/shared/kanban/kanban_board_view.dart';
import 'package:zenno/shared/kanban/kanban_models.dart';

/// The Goal Cycle board.
///
/// Renders the seeded `goalCycle` board through the same generic
/// [KanbanBoardView] that backs Schedule Revision, here with a goal-specific
/// card builder. Columns are reflective-cycle stages (Todo / In Cycle /
/// Monitoring / Out of Cycle — all editable); dragging a card between them is
/// the user's manual bucketing.
///
/// Tapping a card opens [showGoalCardDetailSheet] to edit it, set a target
/// date, and add or review reflection entries. The app-bar "Templates" action
/// opens the reflection-framework library.
class GoalBoardPage extends ConsumerWidget {
  /// Creates the Goal Cycle board page.
  const GoalBoardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(goalBoardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Cycle'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const TemplatesPage()),
            ),
            icon: const Icon(Icons.dashboard_customize_outlined),
            label: const Text('Templates'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: boardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _BoardError(error: error),
        data: (board) => _BoardBody(board: board),
      ),
    );
  }
}

/// The loaded board, or an empty-state when it has no columns.
class _BoardBody extends ConsumerWidget {
  const _BoardBody({required this.board});

  final KanbanBoardData board;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (board.columns.isEmpty) {
      return const _BoardEmpty();
    }
    final controller = ref.watch(goalBoardControllerProvider);
    return KanbanBoardView(
      board: board,
      controller: controller,
      cardBuilder: (card) => GoalCardTile(card: card),
      onCardTap: (card) => showGoalCardDetailSheet(context, card: card),
    );
  }
}

/// Shown when the Goal Cycle board exists but has no columns.
class _BoardEmpty extends StatelessWidget {
  const _BoardEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.track_changes_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No columns yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add a column to start tracking goals.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the board stream fails.
class _BoardError extends StatelessWidget {
  const _BoardError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Could not load the board',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
