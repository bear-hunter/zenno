import 'package:flutter/material.dart';

import 'package:zenno/config/theme/app_spacing.dart';
import 'package:zenno/shared/kanban/kanban_column_view.dart';
import 'package:zenno/shared/kanban/kanban_controller.dart';
import 'package:zenno/shared/kanban/kanban_models.dart';

/// A generic, feature-agnostic Kanban board.
///
/// Renders [board] as a horizontally-scrolling row of [KanbanColumnView]s,
/// each a vertical list of cards drawn by [cardBuilder]. All mutations (card
/// moves, column reorders, renames, adds, deletes) are routed through
/// [controller]; the widget only owns horizontal scroll position and re-renders
/// whenever the host feeds it a fresh [board] snapshot.
///
/// The same widget backs Schedule Revision and Goal Cycle — the only
/// difference is the [cardBuilder] and the `payload` each card carries.
class KanbanBoardView extends StatefulWidget {
  /// Creates a board view.
  const KanbanBoardView({
    required this.board,
    required this.controller,
    required this.cardBuilder,
    this.onCardTap,
    this.onCardAdded,
    this.addCardLabel = 'Add card',
    super.key,
  });

  /// The board snapshot to render.
  final KanbanBoardData board;

  /// Write surface for every board mutation.
  final KanbanController controller;

  /// Builds the visual tile for a card.
  final Widget Function(KanbanCardData card) cardBuilder;

  /// Optional tap callback for a card (typically opens a detail sheet).
  final void Function(KanbanCardData card)? onCardTap;

  /// Optional callback after a card is created.
  final void Function(KanbanCardData card)? onCardAdded;

  /// Copy for the per-lane creation affordance (for example, "Add topic").
  final String addCardLabel;

  @override
  State<KanbanBoardView> createState() => _KanbanBoardViewState();
}

class _KanbanBoardViewState extends State<KanbanBoardView> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  /// Resolves the drop position for the column dragged onto slot [index],
  /// then performs the reorder. [index] counts only columns other than the
  /// one in flight.
  Future<void> _dropColumnAt(
    BuildContext context,
    int index,
    String draggedColumnId,
  ) {
    final others = [
      for (final c in widget.board.columns)
        if (c.id != draggedColumnId) c,
    ];
    final currentIndex = widget.board.columns.indexWhere(
      (c) => c.id == draggedColumnId,
    );
    final normalizedIndex = normalizeKanbanDropIndex(
      rawIndex: index,
      draggedIndex: currentIndex,
      remainingItemCount: others.length,
    );
    final before = normalizedIndex > 0
        ? others[normalizedIndex - 1].position
        : null;
    final after = normalizedIndex < others.length
        ? others[normalizedIndex].position
        : null;

    final beforeNow = currentIndex > 0
        ? widget.board.columns[currentIndex - 1].position
        : null;
    final afterNow =
        currentIndex >= 0 && currentIndex < widget.board.columns.length - 1
        ? widget.board.columns[currentIndex + 1].position
        : null;
    if (before == beforeNow && after == afterNow) {
      // Dropped back into its own slot — no write needed.
      return Future<void>.value();
    }

    return _runKanbanAction(
      context,
      () => widget.controller.reorderColumn(
        columnId: draggedColumnId,
        newPosition: KanbanPositions.between(before, after),
      ),
      'Could not move column',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.board.columns.isEmpty) {
      return _EmptyBoardState(
        board: widget.board,
        controller: widget.controller,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = _columnWidthFor(
          maxWidth: constraints.maxWidth,
          columnCount: widget.board.columns.length,
        );
        final viewportHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : null;
        return Scrollbar(
          key: const ValueKey('kanban-horizontal-scrollbar'),
          controller: _horizontalController,
          thumbVisibility: true,
          interactive: true,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: SizedBox(
              height: viewportHeight == null
                  ? null
                  : (viewportHeight - AppSpacing.lg - AppSpacing.xl).clamp(
                      0,
                      double.infinity,
                    ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < widget.board.columns.length; i++) ...[
                    // Drop zone before column `i` — reorders a dragged column here.
                    _ColumnDropZone(
                      onAccept: (id) => _dropColumnAt(context, i, id),
                    ),
                    KanbanColumnView(
                      key: ValueKey(widget.board.columns[i].id),
                      column: widget.board.columns[i],
                      boardColumns: widget.board.columns,
                      width: columnWidth,
                      controller: widget.controller,
                      cardBuilder: widget.cardBuilder,
                      onCardTap: widget.onCardTap,
                      onCardAdded: widget.onCardAdded,
                      addCardLabel: widget.addCardLabel,
                    ),
                  ],
                  // Trailing drop zone — reorders a dragged column to the end.
                  _ColumnDropZone(
                    onAccept: (id) =>
                        _dropColumnAt(context, widget.board.columns.length, id),
                  ),
                  _AddColumnButton(
                    board: widget.board,
                    controller: widget.controller,
                    compact: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _columnWidthFor({required double maxWidth, required int columnCount}) {
    if (columnCount <= 0 || !maxWidth.isFinite) {
      return KanbanColumnView.maxWidth;
    }

    const boardPadding = AppSpacing.lg * 2;
    const compactAddWidth = _AddColumnButton.compactWidth;
    final columnMargins = columnCount * AppSpacing.md;
    final dropZones = (columnCount + 1) * AppSpacing.sm;
    final available =
        maxWidth - boardPadding - compactAddWidth - columnMargins - dropZones;
    if (available <= 0) return KanbanColumnView.minWidth;

    return (available / columnCount)
        .clamp(KanbanColumnView.minWidth, KanbanColumnView.maxWidth)
        .toDouble();
  }
}

/// A narrow vertical [DragTarget] sitting between columns. It accepts a
/// column-handle drag and widens to signal a valid drop slot.
class _ColumnDropZone extends StatelessWidget {
  const _ColumnDropZone({required this.onAccept});

  /// Called with the dragged column's id on drop.
  final Future<void> Function(String columnId) onAccept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<KanbanColumnDragData>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onAccept(details.data.columnId),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: hovering ? AppSpacing.sm : AppSpacing.xs,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
          decoration: BoxDecoration(
            color: hovering
                ? theme.colorScheme.primary.withValues(alpha: 0.75)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.xs),
          ),
        );
      },
    );
  }
}

/// The "add column" affordance at the end of the board.
class _AddColumnButton extends StatelessWidget {
  const _AddColumnButton({
    required this.board,
    required this.controller,
    this.compact = false,
  });

  static const double fullWidth = 220;
  static const double compactWidth = 64;

  final KanbanBoardData board;
  final KanbanController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (compact) {
      return SizedBox(
        width: compactWidth,
        child: Align(
          alignment: Alignment.topCenter,
          child: Tooltip(
            message: 'Add column',
            child: IconButton.outlined(
              onPressed: () => _addColumn(context),
              icon: const Icon(Icons.add),
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return Container(
      width: fullWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () => _addColumn(context),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Add column',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addColumn(BuildContext context) async {
    final name = await showColumnNameDialog(
      context,
      title: 'New column',
      hintText: 'Column name',
    );
    if (name != null) {
      if (!context.mounted) return;
      // New columns land at the end of the board.
      final last = board.columns.isEmpty ? null : board.columns.last.position;
      await _runKanbanAction(
        context,
        () => controller.addColumn(
          name: name,
          position: KanbanPositions.between(last, null),
        ),
        'Could not add column',
      );
    }
  }
}

class _EmptyBoardState extends StatelessWidget {
  const _EmptyBoardState({required this.board, required this.controller});

  final KanbanBoardData board;
  final KanbanController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.view_kanban_outlined,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('No columns yet', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Create a column to start organizing cards.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () async {
                  final name = await showColumnNameDialog(
                    context,
                    title: 'New column',
                    hintText: 'Column name',
                  );
                  if (name == null) return;
                  if (!context.mounted) return;
                  await _runKanbanAction(
                    context,
                    () => controller.addColumn(
                      name: name,
                      position: KanbanPositions.between(null, null),
                    ),
                    'Could not add column',
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add column'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _runKanbanAction(
  BuildContext context,
  Future<void> Function() action,
  String errorMessage,
) async {
  try {
    await action();
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$errorMessage: $error')));
  }
}
