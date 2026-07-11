import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenno/canvas/canvas_editor_navigation.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/shared/canvas_attachments/canvas_picker_dialog.dart';
import 'package:zenno/shared/canvas_attachments/card_canvas_attachment_providers.dart';
import 'package:zenno/shared/canvas_attachments/card_canvas_attachment_repository.dart';

/// Shared attachment list used by revision and goal card detail sheets.
class CardCanvasAttachmentsSection extends ConsumerStatefulWidget {
  /// Creates a card canvas attachment section.
  const CardCanvasAttachmentsSection({
    super.key,
    required this.cardId,
    required this.defaultCanvasTitle,
  });

  final String cardId;
  final String defaultCanvasTitle;

  @override
  ConsumerState<CardCanvasAttachmentsSection> createState() =>
      _CardCanvasAttachmentsSectionState();
}

class _CardCanvasAttachmentsSectionState
    extends ConsumerState<CardCanvasAttachmentsSection> {
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final attachments = ref.watch(cardCanvasAttachmentsProvider(widget.cardId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Canvases',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton.icon(
              onPressed: _adding ? null : _add,
              icon: _adding
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add, size: 20),
              label: Text(_adding ? 'Adding…' : 'Add canvas'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        attachments.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('Could not load canvases: $error'),
          data: (items) => _AttachmentList(items: items),
        ),
      ],
    );
  }

  Future<void> _add() async {
    if (_adding) return;
    final result = await showCanvasPickerDialog(
      context,
      defaultTitle: widget.defaultCanvasTitle,
    );
    if (result == null) return;
    setState(() => _adding = true);
    try {
      final repo = ref.read(cardCanvasAttachmentRepositoryProvider);
      switch (result) {
        case ExistingCanvasPicked(:final canvasId):
          await repo.attachExisting(cardId: widget.cardId, canvasId: canvasId);
        case NewCanvasPicked(:final title):
          await repo.createAndAttach(cardId: widget.cardId, title: title);
      }
    } catch (error) {
      debugPrint('Attach canvas failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not attach canvas. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }
}

class _AttachmentList extends ConsumerWidget {
  const _AttachmentList({required this.items});

  final List<CardCanvasAttachmentView> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Text(
        'No canvases attached yet.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Column(
      children: [
        for (final item in items)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              leading: const Icon(Icons.draw_outlined),
              title: Text(item.label),
              subtitle: item.label == item.canvasTitle
                  ? null
                  : Text(item.canvasTitle),
              onTap: () => openCanvasEditor(context, item.canvasId),
              trailing: Wrap(
                spacing: AppSpacing.xs,
                children: [
                  IconButton(
                    tooltip: 'Open canvas',
                    onPressed: () => openCanvasEditor(context, item.canvasId),
                    icon: const Icon(Icons.open_in_new),
                  ),
                  PopupMenuButton<_AttachmentAction>(
                    tooltip: 'Canvas actions',
                    onSelected: (action) =>
                        _handleAction(context, ref, item, action),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _AttachmentAction.rename,
                        child: Text('Rename label'),
                      ),
                      PopupMenuItem(
                        value: _AttachmentAction.detach,
                        child: Text('Detach'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    CardCanvasAttachmentView item,
    _AttachmentAction action,
  ) async {
    try {
      switch (action) {
        case _AttachmentAction.rename:
          await _rename(context, ref, item);
        case _AttachmentAction.detach:
          await ref
              .read(cardCanvasAttachmentRepositoryProvider)
              .detach(item.id);
      }
    } catch (error) {
      debugPrint('Update canvas attachment failed: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update the attachment. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    CardCanvasAttachmentView item,
  ) async {
    final controller = TextEditingController(text: item.label);
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename canvas label'),
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
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (label == null) return;
    await ref
        .read(cardCanvasAttachmentRepositoryProvider)
        .renameLabel(attachmentId: item.id, label: label);
  }
}

enum _AttachmentAction { rename, detach }
