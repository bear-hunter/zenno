import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zenno/config/router/routes.dart';
import 'package:zenno/config/theme/app_colors.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/core/util/relative_time.dart';
import 'package:zenno/features/library/application/library_providers.dart';

/// Actions available from a [CanvasCard]'s overflow menu.
enum _CanvasCardAction { rename, delete }

/// A single tile in the library grid representing one [Canvase].
///
/// Shows a placeholder thumbnail, the canvas title, and the time it was last
/// edited. Tapping opens the canvas editor; the overflow menu offers rename
/// and delete, each behind a dialog.
class CanvasCard extends ConsumerWidget {
  /// Creates a card for [canvas].
  const CanvasCard({required this.canvas, super.key});

  /// The canvas this card represents.
  final Canvase canvas;

  /// Records the open and navigates to the full-bleed canvas editor.
  Future<void> _open(BuildContext context, WidgetRef ref) async {
    await ref.read(libraryRepositoryProvider).touchOpened(canvas.id);
    if (context.mounted) {
      await context.push(Routes.canvasPath(canvas.id));
    }
  }

  /// Routes an overflow-menu [action] to its handler.
  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _CanvasCardAction action,
  ) async {
    switch (action) {
      case _CanvasCardAction.rename:
        await _rename(context, ref);
      case _CanvasCardAction.delete:
        await _confirmDelete(context, ref);
    }
  }

  /// Prompts for a new title and applies it.
  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: canvas.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename canvas'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Title'),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newTitle != null && newTitle.isNotEmpty && newTitle != canvas.title) {
      await ref.read(libraryRepositoryProvider).renameCanvas(
            canvas.id,
            newTitle,
          );
    }
  }

  /// Confirms, then permanently deletes the canvas.
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete canvas?'),
        content: Text(
          '"${canvas.title}" and everything on it will be permanently '
          'deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.flagRed,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(libraryRepositoryProvider).deleteCanvas(canvas.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _open(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Placeholder thumbnail area. A real preview lands once the canvas
            // engine writes a snapshot to `thumbnail_path` on close.
            Expanded(
              child: ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(
                    Icons.draw_outlined,
                    size: 40,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          canvas.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          relativeTime(canvas.updatedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_CanvasCardAction>(
                    tooltip: 'Canvas options',
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) => _onAction(context, ref, action),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _CanvasCardAction.rename,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Rename'),
                        ),
                      ),
                      PopupMenuItem(
                        value: _CanvasCardAction.delete,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete_outline),
                          title: Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
