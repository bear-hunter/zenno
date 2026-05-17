/// Plain, immutable data classes the generic Kanban widget renders.
///
/// These are deliberately feature-agnostic: a board, its columns and cards
/// carry only the geometry and text the widget itself needs to lay out and
/// drag. Anything feature-specific (mastery flags, target dates, …) rides
/// along on a card's opaque [KanbanCardData.payload], which the generic widget
/// never reads — only the host feature's `cardBuilder` does.
library;

import 'package:flutter/foundation.dart';

/// A whole Kanban board: an ordered set of [columns].
@immutable
class KanbanBoardData {
  /// Creates a board snapshot.
  const KanbanBoardData({
    required this.id,
    required this.name,
    required this.columns,
  });

  /// Stable identifier of the underlying board.
  final String id;

  /// Human-readable board name.
  final String name;

  /// Columns in display order (already sorted by [KanbanColumnData.position]).
  final List<KanbanColumnData> columns;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KanbanBoardData &&
          other.id == id &&
          other.name == name &&
          listEquals(other.columns, columns);

  @override
  int get hashCode => Object.hash(id, name, Object.hashAll(columns));
}

/// A single column (lane) on a board, holding an ordered list of [cards].
@immutable
class KanbanColumnData {
  /// Creates a column snapshot.
  const KanbanColumnData({
    required this.id,
    required this.name,
    required this.position,
    required this.cards,
  });

  /// Stable identifier of the underlying column.
  final String id;

  /// Renameable column title.
  final String name;

  /// Fractional ordering position among sibling columns.
  final double position;

  /// Cards in display order (already sorted by [KanbanCardData.position]).
  final List<KanbanCardData> cards;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KanbanColumnData &&
          other.id == id &&
          other.name == name &&
          other.position == position &&
          listEquals(other.cards, cards);

  @override
  int get hashCode => Object.hash(id, name, position, Object.hashAll(cards));
}

/// A single card on a board.
///
/// [payload] is opaque, feature-specific data (e.g. a `RevisionCardExtra`).
/// The generic Kanban widget passes it straight through to the host's
/// `cardBuilder` and never inspects it.
@immutable
class KanbanCardData {
  /// Creates a card snapshot.
  const KanbanCardData({
    required this.id,
    required this.columnId,
    required this.position,
    required this.title,
    this.subtitle,
    this.payload,
  });

  /// Stable identifier of the underlying card.
  final String id;

  /// Identifier of the column this card currently belongs to.
  final String columnId;

  /// Fractional ordering position within [columnId].
  final double position;

  /// Primary card text.
  final String title;

  /// Optional secondary card text.
  final String? subtitle;

  /// Opaque, feature-specific extra data. Never read by the generic widget.
  final Object? payload;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KanbanCardData &&
          other.id == id &&
          other.columnId == columnId &&
          other.position == position &&
          other.title == title &&
          other.subtitle == subtitle &&
          other.payload == payload;

  @override
  int get hashCode =>
      Object.hash(id, columnId, position, title, subtitle, payload);
}
