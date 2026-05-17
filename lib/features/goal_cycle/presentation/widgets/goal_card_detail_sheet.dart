import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/features/goal_cycle/application/goal_providers.dart';
import 'package:zenno/features/goal_cycle/application/reflection_providers.dart';
import 'package:zenno/features/goal_cycle/data/goal_repository.dart';
import 'package:zenno/features/goal_cycle/data/reflection_repository.dart';
import 'package:zenno/features/goal_cycle/presentation/pages/reflection_editor_page.dart';
import 'package:zenno/features/goal_cycle/presentation/widgets/reflection_entry_tile.dart';
import 'package:zenno/shared/canvas_attachments/card_canvas_attachments_section.dart';
import 'package:zenno/shared/kanban/kanban_models.dart';

/// Opens the goal-card detail sheet for [card] as a modal bottom sheet.
///
/// The sheet edits the card's title/subtitle/status note, sets or clears its
/// target date, lists every reflection on the goal, and adds new ones. Writes
/// go through [GoalBoardController] and [ReflectionRepository]; the board and
/// the reflection list behind the sheet update reactively via their streams.
Future<void> showGoalCardDetailSheet(
  BuildContext context, {
  required KanbanCardData card,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _GoalCardDetailSheet(card: card),
  );
}

/// The body of the goal-card detail sheet.
class _GoalCardDetailSheet extends ConsumerStatefulWidget {
  const _GoalCardDetailSheet({required this.card});

  final KanbanCardData card;

  @override
  ConsumerState<_GoalCardDetailSheet> createState() =>
      _GoalCardDetailSheetState();
}

class _GoalCardDetailSheetState extends ConsumerState<_GoalCardDetailSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _statusController;

  /// Locally-tracked target date so the picker updates instantly; the write is
  /// sent in the background and the board stream eventually confirms it.
  DateTime? _targetDate;

  /// Whether any editable field differs from what was last persisted.
  bool _dirty = false;

  GoalCardExtra get _extra {
    final payload = widget.card.payload;
    return payload is GoalCardExtra
        ? payload
        : const GoalCardExtra(
            targetDate: null,
            statusNote: null,
            reflectionCount: 0,
          );
  }

  GoalBoardController get _controller => ref.read(goalBoardControllerProvider);

  @override
  void initState() {
    super.initState();
    final extra = _extra;
    _titleController = TextEditingController(text: widget.card.title);
    _subtitleController = TextEditingController(
      text: widget.card.subtitle ?? '',
    );
    _statusController = TextEditingController(text: extra.statusNote ?? '');
    _targetDate = extra.targetDate;
    _titleController.addListener(_onFieldChanged);
    _subtitleController.addListener(_onFieldChanged);
    _statusController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final extra = _extra;
    final dirty =
        _titleController.text.trim() != widget.card.title ||
        _subtitleController.text.trim() != (widget.card.subtitle ?? '') ||
        _statusController.text.trim() != (extra.statusNote ?? '');
    if (dirty != _dirty) {
      setState(() => _dirty = dirty);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final subtitle = _subtitleController.text.trim();
    final note = _statusController.text.trim();

    await _controller.updateCard(
      widget.card.id,
      title: title,
      subtitle: subtitle.isEmpty ? null : subtitle,
    );
    await _controller.setStatusNote(
      cardId: widget.card.id,
      note: note.isEmpty ? null : note,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() => _targetDate = picked);
    await _controller.setTargetDate(cardId: widget.card.id, date: picked);
  }

  Future<void> _clearTargetDate() async {
    setState(() => _targetDate = null);
    await _controller.setTargetDate(cardId: widget.card.id, date: null);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text(
          'Delete "${widget.card.title}" and all its reflections? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    await _controller.deleteCard(widget.card.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addReflection() async {
    await openReflectionEditor(context, cardId: widget.card.id);
  }

  Future<void> _editReflection(ReflectionEntryView entry) async {
    await openReflectionEditor(
      context,
      cardId: widget.card.id,
      existingEntry: entry,
    );
  }

  Future<void> _deleteReflection(ReflectionEntryView entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reflection?'),
        content: Text(
          'Delete this "${entry.templateName}" reflection? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    await ref.read(reflectionRepositoryProvider).deleteEntry(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Lift the sheet above the keyboard when a field is focused.
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final reflectionsAsync = ref.watch(cardReflectionsProvider(widget.card.id));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl + bottomInset,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Goal', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),

              // --- Editable fields -----------------------------------------
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.titleMedium,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _subtitleController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Summary',
                  hintText: 'Optional',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _statusController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Status note',
                  hintText: 'Where this goal stands right now',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // --- Target date ---------------------------------------------
              _TargetDateRow(
                date: _targetDate,
                onPick: _pickTargetDate,
                onClear: _clearTargetDate,
              ),

              const SizedBox(height: AppSpacing.xl),

              // --- Reflections ---------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reflections',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addReflection,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add reflection'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              reflectionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Could not load reflections: $error',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                data: (entries) => _ReflectionList(
                  entries: entries,
                  onEdit: _editReflection,
                  onDelete: _deleteReflection,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              CardCanvasAttachmentsSection(
                cardId: widget.card.id,
                defaultCanvasTitle: widget.card.title,
              ),

              const SizedBox(height: AppSpacing.xl),

              // --- Actions --------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _dirty ? _save : null,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
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

/// The target-date control: a labelled value with set / clear affordances.
class _TargetDateRow extends StatelessWidget {
  const _TargetDateRow({
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDate = date != null;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              hasDate
                  ? 'Target: ${DateFormat.yMMMMd().format(date!.toLocal())}'
                  : 'No target date',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (hasDate)
            IconButton(
              tooltip: 'Clear target date',
              icon: const Icon(Icons.close, size: 20),
              onPressed: onClear,
            ),
          TextButton(
            onPressed: onPick,
            child: Text(hasDate ? 'Change' : 'Set'),
          ),
        ],
      ),
    );
  }
}

/// The list of saved reflections, or an empty-state line.
class _ReflectionList extends StatelessWidget {
  const _ReflectionList({
    required this.entries,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ReflectionEntryView> entries;
  final void Function(ReflectionEntryView entry) onEdit;
  final void Function(ReflectionEntryView entry) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        alignment: Alignment.centerLeft,
        child: Text(
          'No reflections yet. Add one to capture what you learned.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries)
          ReflectionEntryTile(
            entry: entry,
            onEdit: () => onEdit(entry),
            onDelete: () => onDelete(entry),
          ),
      ],
    );
  }
}
