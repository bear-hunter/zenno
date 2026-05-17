import 'package:flutter/material.dart';
import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/tables/focus_tables.dart';

/// The result of a distraction-capture bottom sheet.
class DistractionCapture {
  /// Creates a capture result.
  const DistractionCapture({required this.kind, required this.note});

  /// Whether the distraction came from the user (internal) or the environment
  /// (external).
  final DistractionKind kind;

  /// The user's short note describing the distraction. May be empty.
  final String note;
}

/// A sub-five-second distraction-capture bottom sheet.
///
/// The interaction is intentionally tiny: pick internal / external, optionally
/// type a one-line note, tap Capture. Designed so logging a distraction barely
/// interrupts the study session.
///
/// Show it with [DistractionSheet.show], which returns the [DistractionCapture]
/// or `null` if dismissed.
class DistractionSheet extends StatefulWidget {
  const DistractionSheet._();

  /// Presents the sheet and resolves to the captured distraction, or `null`
  /// if the user dismissed it.
  static Future<DistractionCapture?> show(BuildContext context) {
    return showModalBottomSheet<DistractionCapture>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const DistractionSheet._(),
    );
  }

  @override
  State<DistractionSheet> createState() => _DistractionSheetState();
}

class _DistractionSheetState extends State<DistractionSheet> {
  final TextEditingController _noteController = TextEditingController();
  DistractionKind _kind = DistractionKind.internal;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _capture() {
    Navigator.of(
      context,
    ).pop(DistractionCapture(kind: _kind, note: _noteController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Lift the sheet above the on-screen keyboard.
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Capture a distraction', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Note it and get back to work.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SegmentedButton<DistractionKind>(
            segments: const [
              ButtonSegment(
                value: DistractionKind.internal,
                icon: Icon(Icons.psychology_outlined),
                label: Text('Internal'),
              ),
              ButtonSegment(
                value: DistractionKind.external,
                icon: Icon(Icons.notifications_active_outlined),
                label: Text('External'),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (selection) =>
                setState(() => _kind = selection.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _noteController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'e.g. checked phone, mind wandered',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _capture(),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _capture,
            icon: const Icon(Icons.bolt),
            label: const Text('Capture'),
          ),
        ],
      ),
    );
  }
}
