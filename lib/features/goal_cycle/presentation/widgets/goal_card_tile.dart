import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/features/goal_cycle/data/goal_repository.dart';
import 'package:zenno/shared/kanban/kanban_models.dart';

/// The visual tile for one goal card inside the Kanban board.
///
/// This is the `cardBuilder` output for `KanbanBoardView`: title, optional
/// subtitle, a reflection-count badge, and — when set — the goal's target
/// date. Drag/drop and tap handling are added by the generic Kanban widget
/// around this tile.
class GoalCardTile extends StatelessWidget {
  /// Creates a tile for [card].
  const GoalCardTile({required this.card, super.key});

  /// The card to render. Its [KanbanCardData.payload] is expected to be a
  /// [GoalCardExtra].
  final KanbanCardData card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payload = card.payload;
    // The goal board always supplies a GoalCardExtra; fall back defensively
    // rather than throwing if a payload is ever missing.
    final goal = payload is GoalCardExtra ? payload : null;
    final reflectionCount = goal?.reflectionCount ?? 0;
    final targetDate = goal?.targetDate;

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
                _ReflectionBadge(count: reflectionCount),
                const Spacer(),
                if (targetDate != null) _TargetDateLabel(date: targetDate),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A small pill showing how many reflections a goal card has.
class _ReflectionBadge extends StatelessWidget {
  const _ReflectionBadge({required this.count});

  /// The number of reflection entries on the card.
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // No reflections yet → a muted prompt rather than a "0" badge.
    final hasReflections = count > 0;
    final color = hasReflections
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: hasReflections ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            hasReflections
                ? '$count reflection${count == 1 ? '' : 's'}'
                : 'No reflections',
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// The compact target-date footer, e.g. "17 May".
class _TargetDateLabel extends StatelessWidget {
  const _TargetDateLabel({required this.date});

  /// The goal's target date.
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.flag_outlined,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          DateFormat.MMMd().format(date.toLocal()),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
