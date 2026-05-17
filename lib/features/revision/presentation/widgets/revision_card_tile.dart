import 'package:flutter/material.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/util/relative_time.dart';
import 'package:zenno/features/revision/data/revision_repository.dart';
import 'package:zenno/features/revision/presentation/widgets/mastery_flag_chip.dart';
import 'package:zenno/shared/kanban/kanban_models.dart';

/// The visual tile for one revision card inside the Kanban board.
///
/// This is the `cardBuilder` output for `KanbanBoardView`: title, optional
/// subtitle, a [MasteryFlagChip], and a "13d ago" relative timestamp derived
/// live from the card's last revision. Drag/drop and tap handling are added
/// by the generic Kanban widget around this tile.
class RevisionCardTile extends StatelessWidget {
  /// Creates a tile for [card].
  const RevisionCardTile({required this.card, super.key});

  /// The card to render. Its [KanbanCardData.payload] is expected to be a
  /// [RevisionCardExtra].
  final KanbanCardData card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra = card.payload;
    // The revision board always supplies a RevisionCardExtra; fall back
    // defensively rather than throwing if a payload is ever missing.
    final revision = extra is RevisionCardExtra ? extra : null;

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.title,
              style: theme.textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (card.subtitle case final subtitle?
                when subtitle.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (revision != null)
                  MasteryFlagChip(flag: revision.flag, dense: true),
                const Spacer(),
                _RevisedAgo(lastRevisedAt: revision?.lastRevisedAt),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The compact "13d ago" / "Not revised" footer text.
class _RevisedAgo extends StatelessWidget {
  const _RevisedAgo({required this.lastRevisedAt});

  /// When the card was last marked revised, or `null` if never.
  final DateTime? lastRevisedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final at = lastRevisedAt;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.history,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          at == null ? 'Not revised' : relativeTime(at),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
