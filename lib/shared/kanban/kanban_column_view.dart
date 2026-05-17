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
    required this.controller,
    required this.cardBuilder,
    this.onCardTap,
    this.onReorderColumnDragStarted,
    super.key,
  });

  /// Fixed lane width — sized for a tablet landscape board.
  static const double width = 300;

  /// The column to render.
  final KanbanColumnData column;

  /// Write surface for drops, renames, deletes and card creation.
  final KanbanController controller;

  /// Builds the visual tile for a card. The generic widget supplies only the
  /// drag/drop and tap behaviour around whatever this returns.
  final Widget Function(KanbanCardData card) cardBuilder;

  /// Optional tap callback for a card (typically opens a detail sheet).
  final void Function(KanbanCardData card)? onCardTap;

  /// Invoked when the user begins dragging this column by its handle. The
  /// board view uses it to mark which column is in flight.
  final VoidCallback? onReorderColumnDragStarted;

  /// Resolves the drop position for a card moved to [index] within this
  /// column, then performs the move. [index] is the slot the card lands in,
  /// counting only cards other than the one being dragged.
  Future<void> _dropCardAt(int index, KanbanCardData dragged) {
    // Cards other than the one in flight, in display order.
    final others = [
      for (final c in column.cards)
        if (c.id != dragged.id) c,
    ];
    final before = index > 0 ? others[index - 1].position : null;
    final after = index < others.length ? others[index].position : null;

    final samePlace =
        dragged.columnId == column.id &&
        before == _positionBeforeDragged(dragged) &&
        after == _positionAfterDragged(dragged);
    if (samePlace) {
      // The card was dropped back exactly where it started — skip the write.
      return Future<void>.value();
    }

    return controller.moveCard(
      cardId: dragged.id,
      toColumnId: column.id,
      newPosition: KanbanPositions.between(before, after),
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
    final theme = Theme.of(context);
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            column: column,
            controller: controller,
            onReorderDragStarted: onReorderColumnDragStarted,
          ),
          Expanded(child: _cardList(theme)),
          _AddCardButton(column: column, controller: controller),
        ],
      ),
    );
  }

  /// The scrollable card list. Each card sits below a thin drop zone so a
  /// card can be inserted at any index; a trailing zone catches drops at the
  /// end and an empty-state zone catches drops into an empty column.
  Widget _cardList(ThemeData theme) {
    if (column.cards.isEmpty) {
      return _CardDropZone(
        onAccept: (card) => _dropCardAt(0, card),
        expand: true,
        child: Center(
          child: Text(
            'No cards',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      // One extra slot for the trailing drop zone.
      itemCount: column.cards.length + 1,
      itemBuilder: (context, index) {
        if (index == column.cards.length) {
          // Trailing zone: drop after the last card.
          return _CardDropZone(
            onAccept: (card) => _dropCardAt(column.cards.length, card),
            child: const SizedBox(height: AppSpacing.xl),
          );
        }
        final card = column.cards[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drop zone above this card → insert at `index`.
            _CardDropZone(
              onAccept: (dragged) => _dropCardAt(index, dragged),
              child: const SizedBox(height: AppSpacing.sm),
            ),
            _DraggableCard(
              card: card,
              child: GestureDetector(
                onTap: onCardTap == null ? null : () => onCardTap!(card),
                child: cardBuilder(card),
              ),
            ),
          ],
        );
      },
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
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          // Drag handle — long-pressing it starts a column reorder.
          LongPressDraggable<KanbanColumnDragData>(
            data: KanbanColumnDragData(column.id),
            onDragStarted: onReorderDragStarted,
            feedback: _ColumnHandleFeedback(name: column.name),
            child: Icon(
              Icons.drag_indicator,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              column.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          ),
          Text(
            '${column.cards.length}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
      itemBuilder: (context) => const [
        PopupMenuItem(
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
            leading: Icon(Icons.delete_outline),
            title: Text('Delete column'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Future<void> _rename(BuildContext context) async {
    final name = await showColumnNameDialog(
      context,
      title: 'Rename column',
      initialValue: column.name,
    );
    if (name != null && name != column.name) {
      await controller.renameColumn(columnId: column.id, name: name);
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
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await controller.removeColumn(column.id);
    }
  }
}

/// The "add card" button pinned to the bottom of a column.
class _AddCardButton extends StatelessWidget {
  const _AddCardButton({required this.column, required this.controller});

  final KanbanColumnData column;
  final KanbanController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: TextButton.icon(
        onPressed: () => _addCard(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add card'),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          minimumSize: const Size.fromHeight(44),
        ),
      ),
    );
  }

  Future<void> _addCard(BuildContext context) async {
    final title = await showColumnNameDialog(
      context,
      title: 'New card',
      hintText: 'Card title',
    );
    if (title != null) {
      // New cards drop at the tail of the column.
      final last = column.cards.isEmpty ? null : column.cards.last.position;
      await controller.addCard(
        columnId: column.id,
        title: title,
        position: KanbanPositions.between(last, null),
      );
    }
  }
}

/// Wraps a card body in a [LongPressDraggable]; the dragging card dims in
/// place and a slightly elevated copy follows the pointer.
class _DraggableCard extends StatelessWidget {
  const _DraggableCard({required this.card, required this.child});

  final KanbanCardData card;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<KanbanCardData>(
      data: card,
      // Cards can be wide; constrain the dragged copy to the column width.
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: KanbanColumnView.width - AppSpacing.lg,
          child: Opacity(opacity: 0.9, child: child),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: child),
      child: child,
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
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
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
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: hintText),
          onSubmitted: (_) => _submitNameDialog(context, controller),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _submitNameDialog(context, controller),
            child: const Text('Save'),
          ),
        ],
      );
    },
  ).whenComplete(controller.dispose);
}

/// Pops the name dialog with the trimmed text, or with `null` when empty.
void _submitNameDialog(BuildContext context, TextEditingController controller) {
  final text = controller.text.trim();
  Navigator.of(context).pop(text.isEmpty ? null : text);
}
