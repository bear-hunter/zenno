import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/tables/board_tables.dart';
import 'package:zenno/core/util/relative_time.dart';
import 'package:zenno/features/revision/application/revision_providers.dart';
import 'package:zenno/features/revision/data/revision_repository.dart';
import 'package:zenno/features/revision/presentation/widgets/mastery_flag_chip.dart';
import 'package:zenno/shared/kanban/kanban_models.dart';

/// Opens the revision-card detail sheet for [card] as a modal bottom sheet.
///
/// The sheet edits the card's title/subtitle, sets its mastery flag, marks it
/// revised, and can delete it. Writes go through [RevisionBoardController];
/// the board behind the sheet updates reactively via its stream.
Future<void> showRevisionCardDetailSheet(
  BuildContext context, {
  required KanbanCardData card,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _RevisionCardDetailSheet(card: card),
  );
}

/// The body of the revision-card detail sheet.
class _RevisionCardDetailSheet extends ConsumerStatefulWidget {
  const _RevisionCardDetailSheet({required this.card});

  final KanbanCardData card;

  @override
  ConsumerState<_RevisionCardDetailSheet> createState() =>
      _RevisionCardDetailSheetState();
}

class _RevisionCardDetailSheetState
    extends ConsumerState<_RevisionCardDetailSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;

  /// Locally-tracked flag so the picker updates instantly; the write is sent
  /// in the background and the stream eventually confirms it.
  late MasteryFlag _flag;

  /// Whether the title/subtitle differ from what was last persisted.
  bool _textDirty = false;

  RevisionCardExtra get _extra {
    final payload = widget.card.payload;
    return payload is RevisionCardExtra
        ? payload
        : const RevisionCardExtra(
            flag: MasteryFlag.yellow,
            lastRevisedAt: null,
            revisionCount: 0,
          );
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card.title);
    _subtitleController = TextEditingController(
      text: widget.card.subtitle ?? '',
    );
    _flag = _extra.flag;
    _titleController.addListener(_onTextChanged);
    _subtitleController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final dirty =
        _titleController.text.trim() != widget.card.title ||
        _subtitleController.text.trim() != (widget.card.subtitle ?? '');
    if (dirty != _textDirty) {
      setState(() => _textDirty = dirty);
    }
  }

  RevisionBoardController get _controller =>
      ref.read(revisionBoardControllerProvider);

  Future<void> _saveText() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final subtitle = _subtitleController.text.trim();
    await _controller.updateCard(
      widget.card.id,
      title: title,
      subtitle: subtitle.isEmpty ? null : subtitle,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _setFlag(MasteryFlag flag) async {
    setState(() => _flag = flag);
    await _controller.setMasteryFlag(cardId: widget.card.id, flag: flag);
  }

  Future<void> _markRevised() async {
    await _controller.markRevised(widget.card.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete card?'),
        content: Text('Delete "${widget.card.title}"? This cannot be undone.'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Lift the sheet above the keyboard when a field is focused.
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl + bottomInset,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Revision card', style: theme.textTheme.titleLarge),
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
                labelText: 'Notes',
                hintText: 'Optional',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // --- Mastery flag picker -------------------------------------
            Text('Mastery', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final flag in MasteryFlag.values)
                  _FlagChoice(
                    flag: flag,
                    selected: flag == _flag,
                    onTap: () => _setFlag(flag),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // --- Revision history ----------------------------------------
            _RevisionStats(extra: _extra),

            const SizedBox(height: AppSpacing.xl),

            // --- Actions --------------------------------------------------
            FilledButton.icon(
              onPressed: _markRevised,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark revised'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
                  child: FilledButton.tonalIcon(
                    onPressed: _textDirty ? _saveText : null,
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
    );
  }
}

/// A selectable mastery-flag choice in the picker row.
class _FlagChoice extends StatelessWidget {
  const _FlagChoice({
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  final MasteryFlag flag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = masteryFlagColor(flag);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.md),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.24 : 0.10),
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.35),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(masteryFlagLabel(flag)),
            if (selected) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.check, size: 16, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small read-only summary of a card's revision history.
class _RevisionStats extends StatelessWidget {
  const _RevisionStats({required this.extra});

  final RevisionCardExtra extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastRevised = extra.lastRevisedAt;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lastRevised == null
                      ? 'Never revised'
                      : 'Last revised ${relativeTime(lastRevised)}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  extra.revisionCount == 1
                      ? '1 revision'
                      : '${extra.revisionCount} revisions',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
