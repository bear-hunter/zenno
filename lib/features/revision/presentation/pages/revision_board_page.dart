import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/widgets/aurora.dart';
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
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const AuroraTopBar(
            title: 'Schedule Revision',
            subtitle: 'Move topics through intervals as recall strengthens.',
          ),
          Expanded(
            child: boardAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _BoardError(error: error),
              data: (board) => _BoardBody(board: board),
            ),
          ),
        ],
      ),
    );
  }
}

/// The loaded board.
class _BoardBody extends ConsumerStatefulWidget {
  const _BoardBody({required this.board});

  final KanbanBoardData board;

  @override
  ConsumerState<_BoardBody> createState() => _BoardBodyState();
}

class _BoardBodyState extends ConsumerState<_BoardBody> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(revisionBoardControllerProvider);
    return KanbanBoardView(
      board: widget.board,
      controller: controller,
      cardBuilder: (card) => RevisionCardTile(card: card, now: _now),
      onCardTap: (card) => showRevisionCardDetailSheet(context, card: card),
      onCardAdded: (card) => showRevisionCardDetailSheet(context, card: card),
      addCardLabel: 'Add topic',
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
