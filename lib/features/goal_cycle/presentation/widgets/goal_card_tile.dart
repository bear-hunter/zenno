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
    final statusNote = goal?.statusNote?.trim();
    final supportingText = statusNote != null && statusNote.isNotEmpty
        ? statusNote
        : card.subtitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.title,
          style: theme.textTheme.titleSmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (supportingText case final text? when text.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            text,
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
    final hasReflections = count > 0;
    final color = hasReflections
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.menu_book_outlined, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$count',
          semanticsLabel: '$count reflection${count == 1 ? '' : 's'}',
          style: theme.textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
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
    final local = date.toLocal();
    final today = DateTime.now();
    final day = DateTime(local.year, local.month, local.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    final days = day.difference(todayDay).inDays;
    final overdue = days < 0;
    final urgent = days <= 1;
    final label = switch (days) {
      < -1 => '${-days} days overdue',
      -1 => '1 day overdue',
      0 => 'Due today',
      1 => 'Due tomorrow',
      > 1 && <= 7 => 'Due in $days days',
      _ when local.year != today.year => DateFormat.yMMMd().format(local),
      _ => DateFormat.MMMd().format(local),
    };
    final color = overdue
        ? theme.colorScheme.error
        : urgent
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Tooltip(
      message: 'Target ${DateFormat.yMMMMd().format(local)}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            overdue ? Icons.warning_amber_rounded : Icons.flag_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
