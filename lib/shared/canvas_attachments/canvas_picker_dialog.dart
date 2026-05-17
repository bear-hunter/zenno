import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/database.dart';
import 'package:zenno/features/library/application/library_providers.dart';

/// Opens a dialog that returns either an existing canvas id or a new canvas
/// title to create.
Future<CanvasPickerResult?> showCanvasPickerDialog(
  BuildContext context, {
  required String defaultTitle,
}) {
  return showDialog<CanvasPickerResult>(
    context: context,
    builder: (_) => _CanvasPickerDialog(defaultTitle: defaultTitle),
  );
}

/// Result of the shared canvas picker/create flow.
sealed class CanvasPickerResult {
  const CanvasPickerResult();
}

/// User selected an existing canvas.
class ExistingCanvasPicked extends CanvasPickerResult {
  const ExistingCanvasPicked(this.canvasId);

  final String canvasId;
}

/// User asked to create a new canvas.
class NewCanvasPicked extends CanvasPickerResult {
  const NewCanvasPicked(this.title);

  final String title;
}

class _CanvasPickerDialog extends ConsumerStatefulWidget {
  const _CanvasPickerDialog({required this.defaultTitle});

  final String defaultTitle;

  @override
  ConsumerState<_CanvasPickerDialog> createState() =>
      _CanvasPickerDialogState();
}

class _CanvasPickerDialogState extends ConsumerState<_CanvasPickerDialog> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.defaultTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvases = ref.watch(canvasListProvider);

    return AlertDialog(
      title: const Text('Choose canvas'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'New canvas title',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Create new canvas'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Existing canvases',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            canvases.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text('Could not load canvases: $error'),
              data: (items) => _ExistingCanvasList(items: items),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _create() {
    final title = _titleController.text.trim();
    Navigator.of(
      context,
    ).pop(NewCanvasPicked(title.isEmpty ? widget.defaultTitle : title));
  }
}

class _ExistingCanvasList extends StatelessWidget {
  const _ExistingCanvasList({required this.items});

  final List<Canvase> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text('No canvases yet.'),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final canvas = items[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.draw_outlined),
            title: Text(canvas.title),
            subtitle: canvas.lastOpenedAt == null
                ? null
                : Text('Opened ${canvas.lastOpenedAt}'),
            onTap: () =>
                Navigator.of(context).pop(ExistingCanvasPicked(canvas.id)),
          );
        },
      ),
    );
  }
}
