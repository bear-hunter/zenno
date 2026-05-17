import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/features/revision/application/revision_providers.dart';
import 'package:zenno/features/revision/presentation/widgets/revision_card_detail_sheet.dart';
import 'package:zenno/features/revision/presentation/widgets/revision_card_tile.dart';
import 'package:zenno/shared/kanban/kanban_board_view.dart';
import 'package:zenno/shared/kanban/kanban_models.dart';

/// The Schedule Revision board.
///
/// Renders the seeded `revision` board through the generic [KanbanBoardView]
/// with a revision-specific card builder. Columns are retrospective retrieval
/// buckets (Studying / 1 Day / 1 Week / 1 Month — all editable); dragging a
/// card between them is the user's manual bucketing, never automatic.
///
/// Tapping a card opens [showRevisionCardDetailSheet] to edit it, set its
/// mastery flag, or mark it revised.
class RevisionBoardPage extends ConsumerWidget {
  /// Creates the revision board page.
  const RevisionBoardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(revisionBoardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Revision')),
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
    final controller = ref.watch(revisionBoardControllerProvider);
    return KanbanBoardView(
      board: board,
      controller: controller,
      cardBuilder: (card) => RevisionCardTile(card: card),
      onCardTap: (card) => showRevisionCardDetailSheet(context, card: card),
    );
  }
}

/// Shown when the revision board exists but has no columns.
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
            Icons.layers_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No columns yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add a column to start tracking revisions.',
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
            Icon(
              Icons.error_outline,
              size: 56,
              color: theme.colorScheme.error,
            ),
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
