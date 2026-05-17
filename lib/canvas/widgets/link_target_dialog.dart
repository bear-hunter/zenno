import 'package:flutter/material.dart';

import 'package:zenno/canvas/model/canvas_element.dart';

/// One canvas the user can link to: its [id] and display [title].
///
/// Supplied by `CanvasEditorPage`'s injected `canvasChooser`. A record alias
/// keeps `lib/canvas/` decoupled from the library feature — the engine never
/// imports a library model, it just receives `(id, title)` pairs.
typedef LinkCanvasOption = ({String id, String title});

/// The result of the link dialog: the chip [label] and its [target].
///
/// Returned from [showLinkTargetDialog]; `null` when the user cancels.
@immutable
class LinkDialogResult {
  /// Creates a dialog result carrying [label] and [target].
  const LinkDialogResult({required this.label, required this.target});

  /// Text to show on the placed link chip.
  final String label;

  /// Where the placed link navigates.
  final LinkTarget target;
}

/// Shows the modal that collects a link chip's label and destination canvas.
///
/// When [canvasChooser] is supplied it is awaited to list the canvases the user
/// can link to and the dialog shows a picker; when it is `null` (the engine is
/// running standalone, with no library wired) the dialog degrades to a plain
/// text field for a destination canvas id. Either way the user also types the
/// chip label. Returns a [LinkDialogResult], or `null` if cancelled.
///
/// This keeps `lib/canvas/` self-contained: the dialog never reaches into the
/// library feature — it only consumes the injected chooser callback.
Future<LinkDialogResult?> showLinkTargetDialog(
  BuildContext context, {
  Future<List<LinkCanvasOption>> Function()? canvasChooser,
}) {
  return showDialog<LinkDialogResult>(
    context: context,
    builder: (context) => _LinkTargetDialog(canvasChooser: canvasChooser),
  );
}

/// The stateful body of the link dialog.
class _LinkTargetDialog extends StatefulWidget {
  const _LinkTargetDialog({required this.canvasChooser});

  /// Lists the canvases available as link targets, or `null` to fall back to a
  /// free-text canvas-id field.
  final Future<List<LinkCanvasOption>> Function()? canvasChooser;

  @override
  State<_LinkTargetDialog> createState() => _LinkTargetDialogState();
}

class _LinkTargetDialogState extends State<_LinkTargetDialog> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _canvasIdController = TextEditingController();

  /// Loaded canvas options when a chooser was supplied; `null` until loaded or
  /// when running in free-text fallback mode.
  Future<List<LinkCanvasOption>>? _optionsFuture;

  /// The canvas option the user has picked, when using the chooser.
  LinkCanvasOption? _selected;

  @override
  void initState() {
    super.initState();
    _optionsFuture = widget.canvasChooser?.call();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _canvasIdController.dispose();
    super.dispose();
  }

  /// Whether the dialog has enough input to create a link.
  bool get _canSubmit {
    if (widget.canvasChooser != null) {
      return _selected != null;
    }
    return _canvasIdController.text.trim().isNotEmpty;
  }

  /// Builds the result and closes the dialog.
  void _submit() {
    final String targetId = widget.canvasChooser != null
        ? (_selected?.id ?? '')
        : _canvasIdController.text.trim();
    if (targetId.isEmpty) {
      return;
    }
    // Default the chip label to the destination's title when the user left it
    // blank and a titled option was picked.
    final String typedLabel = _labelController.text.trim();
    final String label = typedLabel.isNotEmpty
        ? typedLabel
        : (_selected?.title.trim().isNotEmpty ?? false
            ? _selected!.title.trim()
            : 'Link');
    Navigator.of(context).pop(
      LinkDialogResult(
        label: label,
        target: LinkTarget(targetCanvasId: targetId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New link'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _labelController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'Shown on the link chip',
              ),
            ),
            const SizedBox(height: 16),
            if (widget.canvasChooser != null)
              _canvasPicker()
            else
              _canvasIdField(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: const Text('Add link'),
        ),
      ],
    );
  }

  /// A dropdown of the canvases returned by the injected chooser.
  Widget _canvasPicker() {
    return FutureBuilder<List<LinkCanvasOption>>(
      future: _optionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final List<LinkCanvasOption> options =
            snapshot.data ?? const <LinkCanvasOption>[];
        if (options.isEmpty) {
          return const Text('No other canvases to link to.');
        }
        return DropdownButtonFormField<String>(
          initialValue: _selected?.id,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Target canvas'),
          items: [
            for (final LinkCanvasOption option in options)
              DropdownMenuItem<String>(
                value: option.id,
                child: Text(
                  option.title.trim().isEmpty
                      ? 'Untitled canvas'
                      : option.title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (id) => setState(() {
            _selected = id == null
                ? null
                : options.firstWhere((LinkCanvasOption o) => o.id == id);
          }),
        );
      },
    );
  }

  /// Free-text canvas-id field used when no chooser is wired.
  Widget _canvasIdField() {
    return TextField(
      controller: _canvasIdController,
      textInputAction: TextInputAction.done,
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) {
        if (_canSubmit) {
          _submit();
        }
      },
      decoration: const InputDecoration(
        labelText: 'Target canvas id',
        hintText: 'Paste the destination canvas id',
      ),
    );
  }
}
