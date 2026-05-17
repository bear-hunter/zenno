import 'package:flutter/material.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/database.dart';

/// The pre-study ritual checklist, rendered as a list of toggleable rows.
///
/// Each row is one active `ritual_checklist_items` entry. Tapping a row toggles
/// its checked state via [onToggle]; the trailing menu (shown when [editable])
/// surfaces rename / retire actions. The widget is purely presentational —
/// every mutation is delegated to a callback.
class RitualChecklist extends StatelessWidget {
  /// Creates a ritual checklist.
  const RitualChecklist({
    required this.items,
    required this.checkedItemIds,
    required this.onToggle,
    this.onEdit,
    this.onRetire,
    this.editable = true,
    super.key,
  });

  /// The active ritual items, already ordered by `position`.
  final List<RitualChecklistItem> items;

  /// Ids of the items currently ticked.
  final Set<String> checkedItemIds;

  /// Called with an item's id when its row is tapped.
  final ValueChanged<String> onToggle;

  /// Called with `(itemId, newLabel)` when an item is renamed. The widget
  /// shows the rename dialog itself; pass a handler to persist the result.
  final void Function(String itemId, String label)? onEdit;

  /// Called with an item's id when it is retired.
  final ValueChanged<String>? onRetire;

  /// Whether the per-item rename / retire menu is shown.
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          'No ritual items yet.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final item in items)
          _RitualRow(
            item: item,
            checked: checkedItemIds.contains(item.id),
            editable: editable,
            onToggle: () => onToggle(item.id),
            onEdit: onEdit == null
                ? null
                : () => _promptRename(context, item),
            onRetire: onRetire == null ? null : () => onRetire!(item.id),
          ),
      ],
    );
  }

  /// Shows a rename dialog for [item] and forwards a non-empty result.
  Future<void> _promptRename(
    BuildContext context,
    RitualChecklistItem item,
  ) async {
    final controller = TextEditingController(text: item.label);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename ritual item'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Label'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = result?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      onEdit?.call(item.id, trimmed);
    }
  }
}

/// One tappable ritual row.
class _RitualRow extends StatelessWidget {
  const _RitualRow({
    required this.item,
    required this.checked,
    required this.editable,
    required this.onToggle,
    required this.onEdit,
    required this.onRetire,
  });

  final RitualChecklistItem item;
  final bool checked;
  final bool editable;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onRetire;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Icon(
                checked
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                color: checked ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: checked
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
              if (editable && (onEdit != null || onRetire != null))
                PopupMenuButton<_RitualAction>(
                  tooltip: 'Edit ritual item',
                  icon: Icon(
                    Icons.more_vert,
                    color: colors.onSurfaceVariant,
                  ),
                  onSelected: (action) {
                    switch (action) {
                      case _RitualAction.rename:
                        onEdit?.call();
                      case _RitualAction.retire:
                        onRetire?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: _RitualAction.rename,
                        child: Text('Rename'),
                      ),
                    if (onRetire != null)
                      const PopupMenuItem(
                        value: _RitualAction.retire,
                        child: Text('Retire'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Actions available from a ritual row's overflow menu.
enum _RitualAction { rename, retire }
