import 'package:flutter/widgets.dart';

import 'package:zenno/canvas/model/viewport_state.dart';

/// A named viewport location the user can jump back to within a canvas.
///
/// A bookmark is a lightweight "saved place" on the infinite canvas: it pairs a
/// human-readable [name] with the [viewport] camera (translation + scale +
/// rotation) that was active when it was saved. Jumping to a bookmark restores
/// that [viewport], so the user can flag a diagram or a section and return to
/// it without re-panning.
///
/// In Phase 1 bookmarks live in memory on the `CanvasController`. The type is
/// deliberately a plain immutable value — manual [==] / [hashCode], a
/// [copyWith], no codegen — so step 1.7 can persist it directly: it maps onto
/// the planned `bookmarks` table as `name` ← [name] and the four viewport
/// columns ← a serialised [viewport] (the same `vp_tx/vp_ty/vp_scale/vp_rotation`
/// shape the `canvases` table already uses for its last-viewport fields).
@immutable
class Bookmark {
  /// Creates a bookmark named [name] capturing [viewport].
  const Bookmark({required this.name, required this.viewport});

  /// Human-readable label for this saved location, shown in the bookmarks menu.
  final String name;

  /// The viewport camera restored when this bookmark is jumped to.
  final ViewportState viewport;

  /// Returns a copy with the given fields replaced.
  Bookmark copyWith({String? name, ViewportState? viewport}) {
    return Bookmark(
      name: name ?? this.name,
      viewport: viewport ?? this.viewport,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bookmark &&
        other.name == name &&
        other.viewport == viewport;
  }

  @override
  int get hashCode => Object.hash(name, viewport);

  @override
  String toString() => 'Bookmark(name: $name, viewport: $viewport)';
}
