import 'package:flutter/material.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/shared/kanban/kanban_controller.dart';
import 'package:zenno/shared/kanban/kanban_models.dart';

/// A single Kanban lane: a header, a draggable list of cards, and an
/// "add card" affordance.
///
/// Cards are wrapped in [LongPressDraggable] so a long-press starts a drag
/// (a tap or a finger-scroll is left untouched). The column body and the gap
/// above each card are [DragTarget]s: dropping resolves a fractional position
/// from the neighbouring cards via [KanbanPositions.between] and calls
/// [KanbanController.moveCard].
class KanbanColumnView extends StatelessWidget {
  /// Creates a column view.
  const KanbanColumnView({
    required this.column,
    required this.boardColumns,
    required this.width,
    required this.controller,
    required this.cardBuilder,
    this.onCardTap,
    this.onCardAdded,
    this.onReorderColumnDragStarted,
    this.addCardLabel = 'Add card',
    super.key,
  });

  /// Narrowest lane width that still leaves card content readable.
  static const double minWidth = 240;

  /// Widest lane width before the board starts feeling sparse.
  static const double maxWidth = 300;

  /// The column to render.
  final KanbanColumnData column;

  /// Every lane on the board, used by the explicit accessible move menu.
  final List<KanbanColumnData> boardColumns;

  /// Resolved lane width supplied by [KanbanBoardView].
  final double width;

  /// Write surface for drops, renames, deletes and card creation.
  final KanbanController controller;

  /// Builds the visual tile for a card. The generic widget supplies only the
  /// drag/drop and tap behaviour around whatever this returns.
  final Widget Function(KanbanCardData card) cardBuilder;

  /// Optional tap callback for a card (typically opens a detail sheet).
  final void Function(KanbanCardData card)? onCardTap;

  /// Optional callback after a card is created.
  final void Function(KanbanCardData card)? onCardAdded;

  /// Invoked when the user begins dragging this column by its handle. The
  /// board view uses it to mark which column is in flight.
  final VoidCallback? onReorderColumnDragStarted;

  /// Copy for the creation affordance at the bottom of this lane.
  final String addCardLabel;

  /// Resolves the drop position for a card moved to [index] within this
  /// column, then performs the move. [index] is the slot the card lands in,
  /// counting only cards other than the one being dragged.
  Future<void> _dropCardAt(
    BuildContext context,
    int index,
    KanbanCardData dragged,
  ) {
    // Cards other than the one in flight, in display order.
    final others = [
      for (final c in column.cards)
        if (c.id != dragged.id) c,
    ];
    final draggedIndex = dragged.columnId == column.id
        ? column.cards.indexWhere((card) => card.id == dragged.id)
        : -1;
    final normalizedIndex = normalizeKanbanDropIndex(
      rawIndex: index,
      draggedIndex: draggedIndex,
      remainingItemCount: others.length,
    );
    final before = normalizedIndex > 0
        ? others[normalizedIndex - 1].position
        : null;
    final after = normalizedIndex < others.length
        ? others[normalizedIndex].position
        : null;

    final samePlace =
        dragged.columnId == column.id &&
        before == _positionBeforeDragged(dragged) &&
        after == _positionAfterDragged(dragged);
    if (samePlace) {
      // The card was dropped back exactly where it started — skip the write.
      return Future<void>.value();
    }

    return _runKanbanAction(
      context,
      () => controller.moveCard(
        cardId: dragged.id,
        toColumnId: column.id,
        newPosition: KanbanPositions.between(before, after),
      ),
      'Could not move card',
    );
  }

  Future<void> _moveCardToColumn(
    BuildContext context,
    KanbanCardData card,
    KanbanColumnData target,
  ) {
    if (target.id == card.columnId) return Future<void>.value();
    final last = target.cards.isEmpty ? null : target.cards.last.position;
    return _runKanbanAction(
      context,
      () => controller.moveCard(
        cardId: card.id,
        toColumnId: target.id,
        newPosition: KanbanPositions.between(last, null),
      ),
      'Could not move card',
    );
  }

  /// Position of the card immediately preceding [dragged] in its own column,
  /// or `null` if it is first / lives in another column.
  double? _positionBeforeDragged(KanbanCardData dragged) {
    if (dragged.columnId != column.id) return null;
    final i = column.cards.indexWhere((c) => c.id == dragged.id);
    return i > 0 ? column.cards[i - 1].position : null;
  }

  /// Position of the card immediately following [dragged] in its own column,
  /// or `null` if it is last / lives in another column.
  double? _positionAfterDragged(KanbanCardData dragged) {
    if (dragged.columnId != column.id) return null;
    final i = column.cards.indexWhere((c) => c.id == dragged.id);
    return i >= 0 && i < column.cards.length - 1
        ? column.cards[i + 1].position
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              column: column,
              controller: controller,
              onReorderDragStarted: onReorderColumnDragStarted,
            ),
            const Divider(),
            Expanded(child: _cardList(context, Theme.of(context))),
            _AddCardButton(
              column: column,
              controller: controller,
              onCardAdded: onCardAdded,
              label: addCardLabel,
            ),
          ],
        ),
      ),
    );
  }

  /// The scrollable card list. Each card sits below a thin drop zone so a
  /// card can be inserted at any index; a trailing zone catches drops at the
  /// end and an empty-state zone catches drops into an empty column.
  Widget _cardList(BuildContext context, ThemeData theme) {
    if (column.cards.isEmpty) {
      return _CardDropZone(
        onAccept: (card) => _dropCardAt(context, 0, card),
        expand: true,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('No cards yet', style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Add a card or drop one here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _CardDropZone(
      onAccept: (card) => _dropCardAt(context, column.cards.length, card),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        // One extra slot for a broad trailing append area.
        itemCount: column.cards.length + 1,
        itemBuilder: (context, index) {
          if (index == column.cards.length) {
            return _CardDropZone(
              onAccept: (card) =>
                  _dropCardAt(context, column.cards.length, card),
              child: const SizedBox(height: 160),
            );
          }
          final card = column.cards[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drop zone above this card → insert at `index`.
              _CardDropZone(
                onAccept: (dragged) => _dropCardAt(context, index, dragged),
                child: const SizedBox(height: AppSpacing.sm),
              ),
              _DraggableCard(
                card: card,
                width: width,
                onTap: onCardTap == null ? null : () => onCardTap!(card),
                moveTargets: [
                  for (final target in boardColumns)
                    if (target.id != card.columnId) target,
                ],
                onMoveTo: (target) => _moveCardToColumn(context, card, target),
                child: cardBuilder(card),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The column header: a drag handle, the (renameable) title, a card count and
/// an overflow menu (rename / delete).
class _Header extends StatelessWidget {
  const _Header({
    required this.column,
    required this.controller,
    this.onReorderDragStarted,
  });

  final KanbanColumnData column;
  final KanbanController controller;
  final VoidCallback? onReorderDragStarted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Drag handle — long-pressing it starts a column reorder.
          Tooltip(
            message: 'Hold and drag to reorder ${column.name}',
            child: Semantics(
              label: 'Reorder ${column.name}',
              button: true,
              child: LongPressDraggable<KanbanColumnDragData>(
                data: KanbanColumnDragData(column.id),
                onDragStarted: onReorderDragStarted,
                feedback: _ColumnHandleFeedback(name: column.name),
                child: SizedBox.square(
                  dimension: 44,
                  child: Icon(
                    Icons.drag_indicator,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              column.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${column.cards.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _ColumnMenu(column: column, controller: controller),
        ],
      ),
    );
  }
}

/// The per-column overflow menu: rename and delete.
class _ColumnMenu extends StatelessWidget {
  const _ColumnMenu({required this.column, required this.controller});

  final KanbanColumnData column;
  final KanbanController controller;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ColumnAction>(
      icon: const Icon(Icons.more_vert, size: 20),
      tooltip: 'Column actions',
      onSelected: (action) => switch (action) {
        _ColumnAction.rename => _rename(context),
        _ColumnAction.delete => _confirmDelete(context),
      },
      itemBuilder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return [
          const PopupMenuItem(
            value: _ColumnAction.rename,
            child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Rename'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: _ColumnAction.delete,
            child: ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: Text(
                'Delete column',
                style: TextStyle(color: colorScheme.error),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ];
      },
    );
  }

  Future<void> _rename(BuildContext context) async {
    final name = await showColumnNameDialog(
      context,
      title: 'Rename column',
      initialValue: column.name,
    );
    if (name != null && name != column.name) {
      if (!context.mounted) return;
      await _runKanbanAction(
        context,
        () => controller.renameColumn(columnId: column.id, name: name),
        'Could not rename column',
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete column?'),
        content: Text(
          column.cards.isEmpty
              ? 'Delete "${column.name}"?'
              : 'Delete "${column.name}" and its '
                    '${column.cards.length} card(s)? This cannot be undone.',
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
      await _runKanbanAction(
        context,
        () => controller.removeColumn(column.id),
        'Could not delete column',
      );
    }
  }
}

/// The "add card" button pinned to the bottom of a column.
class _AddCardButton extends StatelessWidget {
  const _AddCardButton({
    required this.column,
    required this.controller,
    required this.label,
    this.onCardAdded,
  });

  final KanbanColumnData column;
  final KanbanController controller;
  final String label;
  final void Function(KanbanCardData card)? onCardAdded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: TextButton.icon(
        onPressed: () => _addCard(context),
        icon: const Icon(Icons.add, size: 20),
        label: Text(label),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          minimumSize: const Size.fromHeight(44),
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Future<void> _addCard(BuildContext context) async {
    final draft = await _showCardDraftDialog(context, title: 'New card');
    if (draft != null) {
      if (!context.mounted) return;
      // New cards drop at the tail of the column.
      final last = column.cards.isEmpty ? null : column.cards.last.position;
      final position = KanbanPositions.between(last, null);
      final cardId = await _runKanbanAction(
        context,
        () => controller.addCard(
          columnId: column.id,
          title: draft.title,
          subtitle: draft.notes,
          position: position,
        ),
        'Could not add card',
      );
      if (cardId != null && context.mounted) {
        onCardAdded?.call(
          KanbanCardData(
            id: cardId,
            columnId: column.id,
            title: draft.title,
            subtitle: draft.notes,
            position: position,
          ),
        );
      }
    }
  }
}

/// Wraps a card body in a [LongPressDraggable]; the dragging card dims in
/// place and a slightly elevated copy follows the pointer.
class _DraggableCard extends StatelessWidget {
  const _DraggableCard({
    required this.card,
    required this.width,
    required this.child,
    required this.moveTargets,
    required this.onMoveTo,
    this.onTap,
  });

  final KanbanCardData card;
  final double width;
  final Widget child;
  final List<KanbanColumnData> moveTargets;
  final ValueChanged<KanbanColumnData> onMoveTo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardSurface = _KanbanCardSurface(
      card: card,
      onTap: onTap,
      moveTargets: moveTargets,
      onMoveTo: onMoveTo,
      child: child,
    );
    return LongPressDraggable<KanbanCardData>(
      data: card,
      // Cards can be wide; constrain the dragged copy to the column width.
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: width - AppSpacing.lg,
          child: Opacity(
            opacity: 0.9,
            child: _KanbanCardSurface(card: card, child: child),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: cardSurface),
      child: cardSurface,
    );
  }
}

class _KanbanCardSurface extends StatelessWidget {
  const _KanbanCardSurface({
    required this.card,
    required this.child,
    this.onTap,
    this.moveTargets = const [],
    this.onMoveTo,
  });

  final KanbanCardData card;
  final Widget child;
  final VoidCallback? onTap;
  final List<KanbanColumnData> moveTargets;
  final ValueChanged<KanbanColumnData>? onMoveTo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
    );
    return Semantics(
      key: ValueKey('kanban-card-${card.id}'),
      container: true,
      button: onTap != null,
      label: onTap == null ? null : 'Open ${card.title}',
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: child),
                const SizedBox(width: AppSpacing.xs),
                if (moveTargets.isEmpty)
                  Tooltip(
                    message: 'Hold and drag to move',
                    child: Icon(
                      Icons.drag_indicator,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  _CardMoveMenu(
                    card: card,
                    targets: moveTargets,
                    onMoveTo: onMoveTo!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardMoveMenu extends StatelessWidget {
  const _CardMoveMenu({
    required this.card,
    required this.targets,
    required this.onMoveTo,
  });

  final KanbanCardData card;
  final List<KanbanColumnData> targets;
  final ValueChanged<KanbanColumnData> onMoveTo;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Move ${card.title}',
      icon: const Icon(Icons.swap_horiz, size: 19),
      onSelected: (columnId) =>
          onMoveTo(targets.firstWhere((column) => column.id == columnId)),
      itemBuilder: (context) => [
        for (final target in targets)
          PopupMenuItem(
            value: target.id,
            child: Text('Move to ${target.name}'),
          ),
      ],
    );
  }
}

/// A thin [DragTarget] that highlights while a card hovers over it and runs
/// [onAccept] on drop.
class _CardDropZone extends StatelessWidget {
  const _CardDropZone({
    required this.onAccept,
    required this.child,
    this.expand = false,
  });

  /// Called with the dropped card. Returns the move future.
  final Future<void> Function(KanbanCardData card) onAccept;

  /// The collapsed (non-hovered) content — usually a small spacer.
  final Widget child;

  /// When true the zone fills available space (used for an empty column).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<KanbanCardData>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        final indicator = AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: hovering ? 56 : null,
          margin: hovering
              ? const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                  horizontal: AppSpacing.xs,
                )
              : EdgeInsets.zero,
          decoration: hovering
              ? BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: theme.colorScheme.primary),
                )
              : null,
          child: hovering ? null : child,
        );
        return expand ? SizedBox.expand(child: indicator) : indicator;
      },
    );
  }
}

/// Drag payload identifying a column being reordered.
///
/// Carried by the column header's [LongPressDraggable] and consumed by the
/// inter-column drop targets in [KanbanBoardView].
@immutable
class KanbanColumnDragData {
  /// Creates a column-reorder payload for the column [columnId].
  const KanbanColumnDragData(this.columnId);

  /// Identifier of the column being dragged.
  final String columnId;
}

/// The small pill shown under the pointer while dragging a column handle.
class _ColumnHandleFeedback extends StatelessWidget {
  const _ColumnHandleFeedback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(color: theme.colorScheme.primary),
        ),
        child: Text(name, style: theme.textTheme.titleSmall),
      ),
    );
  }
}

/// Actions offered by a column's overflow menu.
enum _ColumnAction { rename, delete }

/// Shows a single-text-field dialog and returns the trimmed entry, or `null`
/// if cancelled or left empty.
///
/// Shared by the rename, add-column and add-card flows. Public so the board
/// view (which owns the "add column" affordance) can reuse it.
Future<String?> showColumnNameDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String? hintText,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ColumnNameDialog(
      title: title,
      initialValue: initialValue,
      hintText: hintText,
    ),
  );
}

class _ColumnNameDialog extends StatefulWidget {
  const _ColumnNameDialog({
    required this.title,
    required this.initialValue,
    this.hintText,
  });

  final String title;
  final String initialValue;
  final String? hintText;

  @override
  State<_ColumnNameDialog> createState() => _ColumnNameDialogState();
}

class _ColumnNameDialogState extends State<_ColumnNameDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = 'Name is required');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: widget.hintText,
          errorText: _errorText,
        ),
        onChanged: (_) {
          if (_errorText != null) setState(() => _errorText = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _CardDraft {
  const _CardDraft({required this.title, this.notes});

  final String title;
  final String? notes;
}

Future<_CardDraft?> _showCardDraftDialog(
  BuildContext context, {
  required String title,
}) {
  return showDialog<_CardDraft>(
    context: context,
    builder: (context) => _CardDraftDialog(title: title),
  );
}

class _CardDraftDialog extends StatefulWidget {
  const _CardDraftDialog({required this.title});

  final String title;

  @override
  State<_CardDraftDialog> createState() => _CardDraftDialogState();
}

class _CardDraftDialogState extends State<_CardDraftDialog> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  String? _titleError;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Title is required');
      return;
    }
    final notes = _notesController.text.trim();
    Navigator.of(
      context,
    ).pop(_CardDraft(title: title, notes: notes.isEmpty ? null : notes));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Title',
                  errorText: _titleError,
                ),
                onChanged: (_) {
                  if (_titleError != null) setState(() => _titleError = null);
                },
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Optional',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

Future<T?> _runKanbanAction<T>(
  BuildContext context,
  Future<T> Function() action,
  String errorMessage,
) async {
  try {
    return await action();
  } catch (error) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$errorMessage: $error')));
    return null;
  }
}
