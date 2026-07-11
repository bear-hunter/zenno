import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenno/canvas/canvas_editor_navigation.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/database.dart' hide Image;
import 'package:zenno/core/util/relative_time.dart';
import 'package:zenno/core/widgets/aurora.dart';
import 'package:zenno/features/library/application/library_providers.dart';

/// Actions available from a [CanvasCard]'s overflow menu.
enum _CanvasCardAction { rename, move, delete }

/// A single tile in the library grid representing one [Canvase].
///
/// Shows a placeholder thumbnail, the canvas title, and the time it was last
/// edited. Tapping opens the canvas editor; the overflow menu offers rename
/// and delete, each behind a dialog.
class CanvasCard extends ConsumerWidget {
  /// Creates a card for [canvas].
  const CanvasCard({required this.canvas, this.folders = const [], super.key});

  /// The canvas this card represents.
  final Canvase canvas;

  /// One-level library folders available as move targets.
  final List<CanvasFolder> folders;

  /// Records the open and navigates to the full-bleed canvas editor.
  Future<void> _open(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(libraryRepositoryProvider).touchOpened(canvas.id);
    } catch (error) {
      // Opening the note is more important than best-effort recency metadata.
      debugPrint('Touch opened canvas failed: $error');
    }
    if (!context.mounted) return;
    try {
      await openCanvasEditor(context, canvas.id);
    } catch (error) {
      debugPrint('Open canvas failed: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open canvas. Please try again.'),
          ),
        );
      }
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
      case _CanvasCardAction.move:
        await _move(context, ref);
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
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newTitle != null && newTitle.isNotEmpty && newTitle != canvas.title) {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref
            .read(libraryRepositoryProvider)
            .renameCanvas(canvas.id, newTitle);
        messenger.showSnackBar(const SnackBar(content: Text('Canvas renamed')));
      } catch (error) {
        debugPrint('Rename canvas failed: $error');
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not rename canvas. Please try again.'),
          ),
        );
      }
    }
  }

  /// Prompts for a target folder and moves the canvas.
  Future<void> _move(BuildContext context, WidgetRef ref) async {
    const unfiledValue = '__unfiled__';
    final target = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Move canvas'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(unfiledValue),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.inbox_outlined),
              title: Text('Unfiled'),
            ),
          ),
          for (final folder in folders)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(folder.id),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_outlined),
                title: Text(folder.name),
              ),
            ),
        ],
      ),
    );
    if (!context.mounted || target == null) return;
    final String? targetFolderId = target == unfiledValue ? null : target;
    if (targetFolderId == canvas.folderId) return;
    try {
      await ref
          .read(libraryRepositoryProvider)
          .moveCanvasToFolder(canvas.id, targetFolderId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Canvas moved')));
      }
    } catch (error) {
      debugPrint('Move canvas failed: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not move canvas. Please try again.'),
          ),
        );
      }
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
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(libraryRepositoryProvider).deleteCanvas(canvas.id);
        messenger.showSnackBar(const SnackBar(content: Text('Canvas deleted')));
      } catch (error) {
        debugPrint('Delete canvas failed: $error');
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not delete canvas. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AuroraPanel(
      padding: EdgeInsets.zero,
      radius: AppRadii.lg,
      clip: true,
      showShadow: false,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Semantics(
              button: true,
              label: 'Open canvas ${canvas.title}',
              excludeSemantics: true,
              child: _OpenOnceInkWell(
                onOpen: () => _open(context, ref),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _CanvasThumbnail(path: canvas.thumbnailPath),
                    ),
                    Divider(color: theme.colorScheme.outlineVariant),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        56,
                        AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            canvas.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Edited ${relativeTime(canvas.updatedAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: AppSpacing.xs,
              bottom: AppSpacing.xs,
              child: PopupMenuButton<_CanvasCardAction>(
                tooltip: 'Canvas options',
                icon: const Icon(Icons.more_horiz),
                onSelected: (action) => _onAction(context, ref, action),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _CanvasCardAction.rename,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Rename'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: _CanvasCardAction.move,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.drive_file_move_outline),
                      title: Text('Move'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _CanvasCardAction.delete,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
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

class _OpenOnceInkWell extends StatefulWidget {
  const _OpenOnceInkWell({required this.onOpen, required this.child});

  final Future<void> Function() onOpen;
  final Widget child;

  @override
  State<_OpenOnceInkWell> createState() => _OpenOnceInkWellState();
}

class _OpenOnceInkWellState extends State<_OpenOnceInkWell> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await widget.onOpen();
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _opening ? null : () => unawaited(_open()),
      child: widget.child,
    );
  }
}

class _CanvasThumbnail extends StatelessWidget {
  const _CanvasThumbnail({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filePath = path;
    if (filePath == null || kIsWeb) return _placeholder(theme);
    return LayoutBuilder(
      builder: (context, constraints) {
        final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
        final int? cacheWidth = _decodeDimension(
          constraints.maxWidth,
          devicePixelRatio,
        );
        final int? cacheHeight = _decodeDimension(
          constraints.maxHeight,
          devicePixelRatio,
        );
        return Image.file(
          File(filePath),
          fit: BoxFit.cover,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          errorBuilder: (context, error, stackTrace) => _placeholder(theme),
        );
      },
    );
  }

  int? _decodeDimension(double logicalPixels, double devicePixelRatio) {
    if (!logicalPixels.isFinite || logicalPixels <= 0) {
      return null;
    }
    return (logicalPixels * devicePixelRatio).ceil().clamp(1, 4096).toInt();
  }

  Widget _placeholder(ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ThumbnailGridPainter(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.draw_outlined,
              size: 36,
              color: theme.colorScheme.primary.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailGridPainter extends CustomPainter {
  const _ThumbnailGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 22.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ThumbnailGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
