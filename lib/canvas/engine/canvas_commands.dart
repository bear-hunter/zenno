import 'package:flutter/widgets.dart';

import 'package:zenno/canvas/model/canvas_element.dart';

/// The mutation surface a [CanvasCommand] acts on.
///
/// `CanvasController` implements this so commands can add and remove elements
/// without depending on the controller's full API (viewport, tools, hover).
/// Both methods keep the element list z-ordered and the spatial index in
/// sync — a command never has to think about either.
abstract interface class ElementStore {
  /// Inserts [element] into the canvas, keeping z-order and the index synced.
  ///
  /// Re-adding an element with an id already present is treated as a no-op so
  /// command replays stay idempotent.
  void addElementToStore(CanvasElement element);

  /// Removes the element with [id] from the canvas, syncing the index.
  ///
  /// A no-op when no element has that id.
  void removeElementFromStore(String id);

  /// Returns the current canvas elements in paint order (back to front).
  List<CanvasElement> get currentElements;
}

/// A reversible canvas mutation, the unit of undo/redo.
///
/// Every structural change to the canvas — committing a stroke, erasing,
/// clearing — is expressed as a [CanvasCommand]. The controller keeps an undo
/// stack and a redo stack of these: [apply] runs the change forward, [revert]
/// runs it back. Because each command carries the full data it needs to
/// reverse itself, undo/redo stays correct no matter how the element list is
/// otherwise mutated between steps.
abstract class CanvasCommand {
  /// Const base constructor for subclasses.
  const CanvasCommand();

  /// A short human-readable label, handy for debugging and future UI.
  String get label;

  /// Applies this command's change to [store] (the forward / redo direction).
  void apply(ElementStore store);

  /// Reverses this command's change on [store] (the undo direction).
  ///
  /// Must restore [store] to exactly the state it had before [apply] ran.
  void revert(ElementStore store);
}

/// Adds a single [element] to the canvas.
///
/// The forward action inserts the element; reverting removes it by id. This is
/// the command produced when the user finishes drawing an ink stroke.
class AddElementCommand extends CanvasCommand {
  /// Creates a command that adds [element].
  const AddElementCommand(this.element);

  /// The element this command inserts.
  final CanvasElement element;

  @override
  String get label => 'Add element';

  @override
  void apply(ElementStore store) {
    store.addElementToStore(element);
  }

  @override
  void revert(ElementStore store) {
    store.removeElementFromStore(element.id);
  }
}

/// Removes one or more elements from the canvas.
///
/// Snapshots the removed [elements] so reverting can re-insert them at their
/// original z-index. Backs the object eraser and lasso-delete in later steps;
/// also reused by [ClearCommand].
class RemoveElementsCommand extends CanvasCommand {
  /// Creates a command that removes every element in [elements].
  ///
  /// The list is copied defensively so later mutation of the caller's list
  /// cannot corrupt this command's undo data.
  RemoveElementsCommand(Iterable<CanvasElement> elements)
      : elements = List<CanvasElement>.unmodifiable(elements);

  /// The elements this command removes, in their original order.
  final List<CanvasElement> elements;

  @override
  String get label =>
      elements.length == 1 ? 'Remove element' : 'Remove ${elements.length} elements';

  @override
  void apply(ElementStore store) {
    for (final CanvasElement element in elements) {
      store.removeElementFromStore(element.id);
    }
  }

  @override
  void revert(ElementStore store) {
    for (final CanvasElement element in elements) {
      store.addElementToStore(element);
    }
  }
}

/// Swaps one set of elements for another as a single undoable unit.
///
/// The forward action removes every element in [removed] and inserts every
/// element in [added]; reverting does the exact opposite. This is the command
/// behind the **vector (partial) eraser**: the originals an eraser stroke
/// crossed go in [removed], and the surviving stroke fragments — fresh
/// [CanvasElement]s — go in [added], so a partial erase splits an ink stroke
/// into sub-strokes in one step that undo/redo treats atomically.
///
/// It is deliberately general: any "replace A with B" edit (e.g. a future
/// shape-recognition or merge tool) can reuse it. With an empty [added] it
/// degenerates to a multi-element delete; with an empty [removed], to a
/// multi-element add.
class ReplaceElementsCommand extends CanvasCommand {
  /// Creates a command that removes [removed] and inserts [added].
  ///
  /// Both lists are copied defensively so later mutation of the caller's lists
  /// cannot corrupt this command's undo data.
  ReplaceElementsCommand({
    required Iterable<CanvasElement> removed,
    required Iterable<CanvasElement> added,
  })  : removed = List<CanvasElement>.unmodifiable(removed),
        added = List<CanvasElement>.unmodifiable(added);

  /// The elements this command removes (and a [revert] re-inserts).
  final List<CanvasElement> removed;

  /// The elements this command inserts (and a [revert] removes).
  final List<CanvasElement> added;

  @override
  String get label => 'Replace elements';

  @override
  void apply(ElementStore store) {
    for (final CanvasElement element in removed) {
      store.removeElementFromStore(element.id);
    }
    for (final CanvasElement element in added) {
      store.addElementToStore(element);
    }
  }

  @override
  void revert(ElementStore store) {
    for (final CanvasElement element in added) {
      store.removeElementFromStore(element.id);
    }
    for (final CanvasElement element in removed) {
      store.addElementToStore(element);
    }
  }
}

/// Translates a set of elements by a fixed world-space [delta].
///
/// Backs dragging a lasso selection: every selected element is replaced by a
/// copy whose geometry is offset by [delta]. The command keeps the *original*
/// elements and their already-translated counterparts (built once by the
/// controller, which knows how to offset each concrete [CanvasElement] kind),
/// so [apply] swaps originals → moved and [revert] swaps back — the moved id is
/// preserved, only the geometry changes.
///
/// One drag produces exactly one [MoveElementsCommand]; live drag feedback is
/// rendered without mutating the store until the gesture ends.
class MoveElementsCommand extends CanvasCommand {
  /// Creates a move of [originals] to [moved] by [delta].
  ///
  /// [originals] and [moved] must line up by index — `moved[i]` is `originals[i]`
  /// shifted by [delta] — and share ids. Both lists are copied defensively.
  MoveElementsCommand({
    required Iterable<CanvasElement> originals,
    required Iterable<CanvasElement> moved,
    required this.delta,
  })  : originals = List<CanvasElement>.unmodifiable(originals),
        moved = List<CanvasElement>.unmodifiable(moved);

  /// The elements as they were before the move.
  final List<CanvasElement> originals;

  /// The elements after the move — each `originals[i]` shifted by [delta].
  final List<CanvasElement> moved;

  /// The world-space translation applied by the move.
  final Offset delta;

  @override
  String get label => moved.length == 1
      ? 'Move element'
      : 'Move ${moved.length} elements';

  @override
  void apply(ElementStore store) {
    for (final CanvasElement element in originals) {
      store.removeElementFromStore(element.id);
    }
    for (final CanvasElement element in moved) {
      store.addElementToStore(element);
    }
  }

  @override
  void revert(ElementStore store) {
    for (final CanvasElement element in moved) {
      store.removeElementFromStore(element.id);
    }
    for (final CanvasElement element in originals) {
      store.addElementToStore(element);
    }
  }
}

/// Removes every element from the canvas.
///
/// Snapshots the whole element list on first [apply] so a later [revert]
/// restores the canvas exactly. Backs the toolbar's "clear canvas" action.
class ClearCommand extends CanvasCommand {
  /// Creates an empty clear command; the snapshot is taken when [apply] runs.
  ClearCommand();

  /// Elements present when [apply] last ran, restored verbatim by [revert].
  List<CanvasElement> _removed = const <CanvasElement>[];

  @override
  String get label => 'Clear canvas';

  @override
  void apply(ElementStore store) {
    _removed = List<CanvasElement>.unmodifiable(store.currentElements);
    for (final CanvasElement element in _removed) {
      store.removeElementFromStore(element.id);
    }
  }

  @override
  void revert(ElementStore store) {
    for (final CanvasElement element in _removed) {
      store.addElementToStore(element);
    }
  }
}
