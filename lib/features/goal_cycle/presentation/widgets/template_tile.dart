import 'package:flutter/material.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/features/goal_cycle/data/reflection_repository.dart';

/// A list tile for one reflection template on the Templates page.
///
/// Shows the framework name, its description (or a prompt-count fallback), and
/// a "Builtin" / "Custom" badge. Tapping it opens the template — builtins
/// view-only, customs editable. The trailing overflow menu offers
/// "Duplicate & edit" for every template and, for customs only, "Delete".
class TemplateTile extends StatelessWidget {
  /// Creates a tile for [template].
  const TemplateTile({
    required this.template,
    required this.onOpen,
    required this.onDuplicate,
    this.onDelete,
    super.key,
  });

  /// The template to render.
  final ReflectionTemplateView template;

  /// Invoked when the tile is tapped (open / view / edit).
  final VoidCallback onOpen;

  /// Invoked for "Duplicate & edit" — forks an editable copy.
  final VoidCallback onDuplicate;

  /// Invoked for "Delete". `null` for builtins (which are not deletable), so
  /// the menu item is hidden.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promptCount = template.schema.prompts.length;
    final description = template.description;
    final subtitle = (description != null && description.isNotEmpty)
        ? description
        : '$promptCount prompt${promptCount == 1 ? '' : 's'}';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        leading: Icon(
          template.isBuiltin
              ? Icons.auto_stories_outlined
              : Icons.edit_note_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                template.name,
                style: theme.textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _KindBadge(isBuiltin: template.isBuiltin),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        trailing: _TemplateMenu(onDuplicate: onDuplicate, onDelete: onDelete),
        onTap: onOpen,
      ),
    );
  }
}

/// A small "Builtin" / "Custom" pill.
class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.isBuiltin});

  final bool isBuiltin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isBuiltin
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        isBuiltin ? 'Builtin' : 'Custom',
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// The per-template overflow menu: duplicate (always) and delete (customs).
class _TemplateMenu extends StatelessWidget {
  const _TemplateMenu({required this.onDuplicate, this.onDelete});

  final VoidCallback onDuplicate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_TemplateAction>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Template actions',
      onSelected: (action) => switch (action) {
        _TemplateAction.duplicate => onDuplicate(),
        _TemplateAction.delete => onDelete?.call(),
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _TemplateAction.duplicate,
          child: ListTile(
            leading: Icon(Icons.copy_all_outlined),
            title: Text('Duplicate & edit'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (onDelete != null)
          const PopupMenuItem(
            value: _TemplateAction.delete,
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

/// Actions offered by a template's overflow menu.
enum _TemplateAction { duplicate, delete }
