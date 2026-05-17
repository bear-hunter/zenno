import 'package:flutter/material.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/util/relative_time.dart';
import 'package:zenno/features/goal_cycle/data/reflection_repository.dart';

/// A single saved reflection, shown on the goal-card detail sheet.
///
/// Collapsed it shows the framework name and how long ago it was written;
/// expanded it lists every prompt from the entry's *snapshot* schema with the
/// answer the user gave (prompts left blank read "—"). Because it renders from
/// the snapshot, an entry looks identical forever even after its source
/// template changes. An overflow menu offers edit / delete.
class ReflectionEntryTile extends StatelessWidget {
  /// Creates a tile for [entry].
  const ReflectionEntryTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  /// The reflection entry to render.
  final ReflectionEntryView entry;

  /// Invoked when the user chooses "Edit" from the overflow menu.
  final VoidCallback onEdit;

  /// Invoked when the user chooses "Delete" from the overflow menu.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Theme(
        // Drop the default expansion-tile divider lines for a cleaner card.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Icon(
            Icons.menu_book_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            entry.templateName,
            style: theme.textTheme.titleSmall,
          ),
          subtitle: Text(
            'Written ${relativeTime(entry.createdAt)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: _EntryMenu(onEdit: onEdit, onDelete: onDelete),
          children: [
            for (final prompt in entry.schema.prompts)
              _AnswerBlock(
                label: prompt.label,
                answer: entry.answers[prompt.key] ?? '',
              ),
          ],
        ),
      ),
    );
  }
}

/// One prompt label plus its answer inside an expanded entry.
class _AnswerBlock extends StatelessWidget {
  const _AnswerBlock({required this.label, required this.answer});

  final String label;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAnswer = answer.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasAnswer ? answer : '—',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: hasAnswer
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The per-entry overflow menu: edit and delete.
class _EntryMenu extends StatelessWidget {
  const _EntryMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_EntryAction>(
      icon: const Icon(Icons.more_vert, size: 20),
      tooltip: 'Reflection actions',
      onSelected: (action) => switch (action) {
        _EntryAction.edit => onEdit(),
        _EntryAction.delete => onDelete(),
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _EntryAction.edit,
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _EntryAction.delete,
          child: ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Delete'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

/// Actions offered by a reflection entry's overflow menu.
enum _EntryAction { edit, delete }
