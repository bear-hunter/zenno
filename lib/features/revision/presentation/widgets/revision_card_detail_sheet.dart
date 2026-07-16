import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/core/database/tables/board_tables.dart';
import 'package:zenno/core/util/foreground_minute_clock.dart';
import 'package:zenno/core/util/relative_time.dart';
import 'package:zenno/features/revision/application/revision_providers.dart';
import 'package:zenno/features/revision/data/revision_repository.dart';
import 'package:zenno/features/revision/presentation/widgets/mastery_flag_chip.dart';
import 'package:zenno/shared/canvas_attachments/card_canvas_attachments_section.dart';
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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late String _persistedTitle;
  late String _persistedSubtitle;
  late DateTime _now;
  late final ForegroundMinuteClock _clock;

  /// Locally-tracked flag so the picker updates instantly; the write is sent
  /// in the background and the stream eventually confirms it.
  late MasteryFlag _flag;

  /// Whether the title/subtitle differ from what was last persisted.
  bool _textDirty = false;
  bool _saving = false;
  bool _marking = false;
  bool _deleting = false;
  bool _flagSaving = false;
  bool _allowPop = false;
  bool _discardDialogOpen = false;

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
    _persistedTitle = widget.card.title;
    _persistedSubtitle = widget.card.subtitle ?? '';
    _titleController = TextEditingController(text: _persistedTitle);
    _subtitleController = TextEditingController(text: _persistedSubtitle);
    _flag = _extra.flag;
    _clock = ForegroundMinuteClock()..addListener(_onMinuteChanged);
    _now = _clock.now;
    _titleController.addListener(_onTextChanged);
    _subtitleController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _clock
      ..removeListener(_onMinuteChanged)
      ..dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  void _onMinuteChanged() {
    if (mounted) setState(() => _now = _clock.now);
  }

  void _onTextChanged() {
    final dirty =
        _titleController.text.trim() != _persistedTitle ||
        _subtitleController.text.trim() != _persistedSubtitle;
    if (dirty != _textDirty) {
      setState(() => _textDirty = dirty);
    }
  }

  RevisionBoardController get _controller =>
      ref.read(revisionBoardControllerProvider);

  bool get _busy => _saving || _marking || _deleting || _flagSaving;

  bool get _shouldGuardPop => !_allowPop && (_textDirty || _busy);

  String? _validateTitle(String? value) {
    return (value ?? '').trim().isEmpty ? 'Title is required' : null;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _saveText({bool showFeedback = true}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    final title = _titleController.text.trim();
    final subtitle = _subtitleController.text.trim();
    setState(() => _saving = true);
    try {
      await _controller.updateCard(
        widget.card.id,
        title: title,
        subtitle: subtitle.isEmpty ? null : subtitle,
      );
      if (!mounted) return true;
      setState(() {
        _persistedTitle = title;
        _persistedSubtitle = subtitle;
        _textDirty = false;
      });
      if (showFeedback) _showSnack('Saved');
      return true;
    } catch (error) {
      if (mounted) _showSnack('Could not save: $error');
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setFlag(MasteryFlag flag) async {
    if (_busy || flag == _flag) return;
    final previous = _flag;
    setState(() {
      _flag = flag;
      _flagSaving = true;
    });
    try {
      await _controller.setMasteryFlag(cardId: widget.card.id, flag: flag);
    } catch (error) {
      if (!mounted) return;
      setState(() => _flag = previous);
      _showSnack('Could not update mastery: $error');
    } finally {
      if (mounted) setState(() => _flagSaving = false);
    }
  }

  Future<void> _markRevised() async {
    if (_busy) return;
    if (_textDirty) {
      final choice = await _confirmDirtyMark();
      if (choice == null) return;
      if (choice == _DirtyMarkChoice.saveAndMark) {
        final saved = await _saveText(showFeedback: false);
        if (!saved) return;
      }
    }

    if (!mounted) return;
    setState(() => _marking = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _controller.markRevised(widget.card.id);
      if (!mounted) return;
      _allowPop = true;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Marked revised')));
    } catch (error) {
      if (mounted) _showSnack('Could not mark revised: $error');
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  Future<void> _delete() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Delete card?'),
          content: Text(
            _textDirty
                ? 'Delete "${widget.card.title}" and discard unsaved edits? '
                      'This cannot be undone.'
                : 'Delete "${widget.card.title}"? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (!(confirmed ?? false)) return;
    setState(() => _deleting = true);
    try {
      await _controller.deleteCard(widget.card.id);
      if (!mounted) return;
      _allowPop = true;
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) _showSnack('Could not delete: $error');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<_DirtyMarkChoice?> _confirmDirtyMark() {
    return showDialog<_DirtyMarkChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved edits'),
        content: const Text(
          'Save your title and notes before marking this card revised?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_DirtyMarkChoice.markWithoutSaving),
            child: const Text('Mark without saving'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(_DirtyMarkChoice.saveAndMark),
            child: const Text('Save & mark'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePopAttempt() async {
    if (_allowPop || _discardDialogOpen) return;
    if (_busy) {
      _showSnack('Finish the current action first');
      return;
    }
    if (!_textDirty) return;

    _discardDialogOpen = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved title and notes edits will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    _discardDialogOpen = false;
    if (!(discard ?? false) || !mounted) return;
    setState(() => _allowPop = true);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Lift the sheet above the keyboard when a field is focused.
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope<void>(
      canPop: !_shouldGuardPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handlePopAttempt();
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl + bottomInset,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.contentMaxWidth,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Revision card', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.lg),

                  // --- Editable fields ---------------------------------------
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    style: theme.textTheme.titleMedium,
                    validator: _validateTitle,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
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

                  // --- Mastery flag picker -----------------------------------
                  Text('Mastery', style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final flag in MasteryFlag.values)
                        _FlagChoice(
                          flag: flag,
                          selected: flag == _flag,
                          onTap: _busy ? null : () => _setFlag(flag),
                        ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // --- Revision history --------------------------------------
                  _RevisionStats(extra: _extra, now: _now),

                  const SizedBox(height: AppSpacing.xl),

                  CardCanvasAttachmentsSection(
                    cardId: widget.card.id,
                    defaultCanvasTitle: _persistedTitle,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // --- Actions ------------------------------------------------
                  FilledButton.icon(
                    onPressed: _busy ? null : _markRevised,
                    icon: _marking
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_marking ? 'Marking...' : 'Mark revised'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _delete,
                          icon: _deleting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.delete_outline),
                          label: Text(_deleting ? 'Deleting...' : 'Delete'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            foregroundColor: theme.colorScheme.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _textDirty && !_busy
                              ? () => _saveText()
                              : null,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(_saving ? 'Saving...' : 'Save'),
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
        ),
      ),
    );
  }
}

enum _DirtyMarkChoice { saveAndMark, markWithoutSaving }

/// A selectable mastery-flag choice in the picker row.
class _FlagChoice extends StatelessWidget {
  const _FlagChoice({
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  final MasteryFlag flag;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = masteryFlagColor(flag);
    return InkWell(
      key: ValueKey(
        'revision-mastery-${flag.name}-${selected ? 'selected' : 'option'}',
      ),
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
  const _RevisionStats({required this.extra, required this.now});

  final RevisionCardExtra extra;
  final DateTime now;

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
                      : 'Last revised ${relativeTime(lastRevised, now: now)}',
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
