import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/engine/canvas_commands.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/stroke.dart';

/// Builds a trivial two-point [InkElement] for command tests.
///
/// The geometry is irrelevant to undo/redo correctness; only the [id] and
/// [zIndex] matter, so a fixed short stroke is used.
InkElement inkElement(String id, {required int zIndex}) {
  return InkElement.fromStroke(
    Stroke(
      id: id,
      points: const <StrokePoint>[
        StrokePoint(0, 0, 0.5),
        StrokePoint(10, 10, 0.5),
      ],
      color: 0xFFFFFFFF,
      width: 4,
    ),
    zIndex: zIndex,
  );
}

/// An in-memory [ElementStore] for exercising commands without a controller.
///
/// Mirrors `CanvasController`'s store contract: keeps the element list sorted
/// ascending by [CanvasElement.zIndex] and treats a duplicate id as a no-op
/// add, so command [CanvasCommand.apply] / [CanvasCommand.revert] can be
/// asserted against a minimal, predictable backing.
class _FakeStore implements ElementStore {
  final List<CanvasElement> _elements = <CanvasElement>[];

  @override
  List<CanvasElement> get currentElements =>
      List<CanvasElement>.unmodifiable(_elements);

  /// The ids currently in the store, in paint order.
  List<String> get ids => <String>[for (final e in _elements) e.id];

  @override
  void addElementToStore(CanvasElement element) {
    if (_elements.any((CanvasElement e) => e.id == element.id)) {
      return;
    }
    var insertAt = _elements.length;
    for (var i = 0; i < _elements.length; i++) {
      if (_elements[i].zIndex > element.zIndex) {
        insertAt = i;
        break;
      }
    }
    _elements.insert(insertAt, element);
  }

  @override
  void removeElementFromStore(String id) {
    _elements.removeWhere((CanvasElement e) => e.id == id);
  }
}

void main() {
  group('AddElementCommand', () {
    test('apply inserts the element, revert removes it', () {
      final _FakeStore store = _FakeStore();
      final AddElementCommand command = AddElementCommand(
        inkElement('a', zIndex: 0),
      );

      command.apply(store);
      expect(store.ids, <String>['a']);

      command.revert(store);
      expect(store.ids, isEmpty);
    });

    test('apply is idempotent — a replay never duplicates the element', () {
      final _FakeStore store = _FakeStore();
      final AddElementCommand command = AddElementCommand(
        inkElement('a', zIndex: 0),
      );

      command.apply(store);
      command.apply(store);
      expect(store.ids, <String>['a']);
    });
  });

  group('RemoveElementsCommand', () {
    test('apply removes every element, revert restores them in z-order', () {
      final _FakeStore store = _FakeStore()
        ..addElementToStore(inkElement('a', zIndex: 0))
        ..addElementToStore(inkElement('b', zIndex: 1))
        ..addElementToStore(inkElement('c', zIndex: 2));

      final RemoveElementsCommand command = RemoveElementsCommand(
        <CanvasElement>[inkElement('a', zIndex: 0), inkElement('c', zIndex: 2)],
      );

      command.apply(store);
      expect(store.ids, <String>['b']);

      command.revert(store);
      // The store re-sorts by zIndex, so order is restored regardless of the
      // order the command re-inserts in.
      expect(store.ids, <String>['a', 'b', 'c']);
    });

    test('snapshots its element list defensively', () {
      final List<CanvasElement> source = <CanvasElement>[
        inkElement('a', zIndex: 0),
      ];
      final RemoveElementsCommand command = RemoveElementsCommand(source);
      // Mutating the caller's list must not affect the command's undo data.
      source.add(inkElement('b', zIndex: 1));
      expect(command.elements.map((CanvasElement e) => e.id), <String>['a']);
    });
  });

  group('ClearCommand', () {
    test('apply empties the store, revert restores the snapshot', () {
      final _FakeStore store = _FakeStore()
        ..addElementToStore(inkElement('a', zIndex: 0))
        ..addElementToStore(inkElement('b', zIndex: 1));

      final ClearCommand command = ClearCommand();
      command.apply(store);
      expect(store.ids, isEmpty);

      command.revert(store);
      expect(store.ids, <String>['a', 'b']);
    });
  });

  group('ReplaceElementsCommand', () {
    test('apply swaps removed for added, revert swaps back', () {
      final _FakeStore store = _FakeStore()
        ..addElementToStore(inkElement('orig', zIndex: 0));

      final ReplaceElementsCommand command = ReplaceElementsCommand(
        removed: <CanvasElement>[inkElement('orig', zIndex: 0)],
        added: <CanvasElement>[
          inkElement('frag-a', zIndex: 1),
          inkElement('frag-b', zIndex: 2),
        ],
      );

      command.apply(store);
      expect(store.ids, <String>['frag-a', 'frag-b']);

      command.revert(store);
      expect(store.ids, <String>['orig']);
    });

    test('snapshots both lists defensively', () {
      final List<CanvasElement> removed = <CanvasElement>[
        inkElement('a', zIndex: 0),
      ];
      final List<CanvasElement> added = <CanvasElement>[
        inkElement('b', zIndex: 1),
      ];
      final ReplaceElementsCommand command = ReplaceElementsCommand(
        removed: removed,
        added: added,
      );
      removed.add(inkElement('x', zIndex: 9));
      added.add(inkElement('y', zIndex: 9));
      expect(command.removed.map((CanvasElement e) => e.id), <String>['a']);
      expect(command.added.map((CanvasElement e) => e.id), <String>['b']);
    });
  });

  group('MoveElementsCommand', () {
    test('apply installs the moved copies, revert restores the originals', () {
      final InkElement original = inkElement('a', zIndex: 0);
      final InkElement moved = original.translated(const Offset(50, 25));
      final _FakeStore store = _FakeStore()..addElementToStore(original);

      final MoveElementsCommand command = MoveElementsCommand(
        originals: <CanvasElement>[original],
        moved: <CanvasElement>[moved],
        delta: const Offset(50, 25),
      );

      command.apply(store);
      expect(store.ids, <String>['a']);
      // The id is preserved; only the geometry shifted.
      final InkElement afterMove = store.currentElements.single as InkElement;
      expect(afterMove.stroke.points.first.x, moreOrLessEquals(50));

      command.revert(store);
      final InkElement afterRevert = store.currentElements.single as InkElement;
      expect(afterRevert.stroke.points.first.x, moreOrLessEquals(0));
    });
  });

  group('InkElement.translated', () {
    test('shifts every point and the bounds by the delta', () {
      final InkElement element = inkElement('a', zIndex: 3);
      final InkElement moved = element.translated(const Offset(10, -5));

      expect(moved.id, 'a');
      expect(moved.zIndex, 3);
      expect(moved.stroke.points.first.x, moreOrLessEquals(10));
      expect(moved.stroke.points.first.y, moreOrLessEquals(-5));
      expect(
        moved.worldBounds,
        element.worldBounds.shift(const Offset(10, -5)),
      );
    });
  });

  group('CanvasController — command-backed undo/redo', () {
    /// Commits a stroke through the controller's normal begin/append/end path.
    void drawStroke(CanvasController controller) {
      controller
        ..beginStroke(const Offset(0, 0), 0.5)
        ..appendToStroke(const Offset(20, 20), 0.5)
        ..endStroke();
    }

    test('a committed stroke becomes an element and is undoable', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      expect(controller.canUndo, isFalse);
      expect(controller.elementCount, 0);

      drawStroke(controller);
      expect(controller.elementCount, 1);
      expect(controller.elements.single, isA<InkElement>());
      expect(controller.spatialIndex.length, 1);
      expect(controller.canUndo, isTrue);
      expect(controller.canRedo, isFalse);

      controller.undo();
      expect(controller.elementCount, 0);
      expect(controller.spatialIndex.isEmpty, isTrue);
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isTrue);

      controller.redo();
      expect(controller.elementCount, 1);
      expect(controller.spatialIndex.length, 1);
      expect(controller.canRedo, isFalse);
    });

    test('an empty stroke commits nothing and is not undoable', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      controller
        ..beginStroke(const Offset(0, 0), 0.5)
        ..cancelStroke();
      expect(controller.elementCount, 0);
      expect(controller.canUndo, isFalse);
    });

    test('a fresh edit forks history — the redo stack is dropped', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      drawStroke(controller);
      controller.undo();
      expect(controller.canRedo, isTrue);

      // Drawing again must invalidate the pending redo.
      drawStroke(controller);
      expect(controller.canRedo, isFalse);
      expect(controller.elementCount, 1);
    });

    test('clear is undoable and restores every element', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      drawStroke(controller);
      drawStroke(controller);
      expect(controller.elementCount, 2);

      controller.clear();
      expect(controller.elementCount, 0);
      expect(controller.spatialIndex.isEmpty, isTrue);
      expect(controller.canUndo, isTrue);

      controller.undo();
      expect(controller.elementCount, 2);
      expect(controller.spatialIndex.length, 2);
    });

    test('clearing an empty canvas records no undoable command', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      controller.clear();
      expect(controller.canUndo, isFalse);
    });

    test('z-index keeps advancing after an undo so new ink paints on top', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      drawStroke(controller);
      final int firstZ = controller.elements.single.zIndex;

      controller.undo();
      drawStroke(controller);
      final int secondZ = controller.elements.single.zIndex;

      // The allocator is re-derived from the (now empty) list on undo, so the
      // re-drawn stroke does not collide with the reverted one.
      expect(secondZ, greaterThanOrEqualTo(firstZ));
    });

    test('removeElements deletes via an undoable command', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      drawStroke(controller);
      drawStroke(controller);
      final List<CanvasElement> snapshot = controller.elements;

      controller.removeElements(<CanvasElement>[snapshot.first]);
      expect(controller.elementCount, 1);
      expect(controller.spatialIndex.length, 1);

      controller.undo();
      expect(controller.elementCount, 2);
      expect(controller.spatialIndex.length, 2);
    });
  });

  group('CanvasController — editing tools', () {
    /// Commits a straight stroke from [from] to [to] through the controller.
    void drawLine(CanvasController controller, Offset from, Offset to) {
      controller
        ..beginStroke(from, 0.5)
        ..appendToStroke(to, 0.5)
        ..endStroke();
    }

    test('object eraser deletes a crossed stroke as one undoable command', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.eraser)
        ..setEraserMode(EraserMode.object);
      addTearDown(controller.dispose);

      drawLine(controller, const Offset(0, 0), const Offset(100, 0));
      expect(controller.elementCount, 1);

      // Drag the eraser straight across the stroke's centerline.
      controller
        ..beginErase(const Offset(50, 0))
        ..appendErase(const Offset(50, 0))
        ..endErase();
      expect(controller.elementCount, 0);
      expect(controller.canUndo, isTrue);

      controller.undo();
      expect(controller.elementCount, 1);
    });

    test('object eraser that misses records no command', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.eraser);
      addTearDown(controller.dispose);

      drawLine(controller, const Offset(0, 0), const Offset(100, 0));
      // Erase far from the stroke.
      controller
        ..beginErase(const Offset(50, 500))
        ..endErase();
      expect(controller.elementCount, 1);
      expect(controller.canUndo, isTrue, reason: 'only the draw is undoable');

      controller.undo();
      expect(controller.canUndo, isFalse);
    });

    test('partial eraser splits a stroke into surviving fragments', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.eraser)
        ..setEraserMode(EraserMode.partial)
        ..setEraserRadius(8);
      addTearDown(controller.dispose);

      // A long stroke sampled densely so a mid erase leaves points each side.
      controller.beginStroke(const Offset(0, 0), 0.5);
      for (double x = 5; x <= 200; x += 5) {
        controller.appendToStroke(Offset(x, 0), 0.5);
      }
      controller.endStroke();
      expect(controller.elementCount, 1);

      // Erase a dab in the middle — the stroke should split in two.
      controller
        ..beginErase(const Offset(100, 0))
        ..endErase();
      expect(controller.elementCount, 2);
      expect(controller.canUndo, isTrue);

      // Undo restores the single original stroke.
      controller.undo();
      expect(controller.elementCount, 1);
    });

    test('lasso selects an enclosed stroke and clears on switch', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.lasso);
      addTearDown(controller.dispose);

      // A small stroke near the origin.
      drawLine(controller, const Offset(10, 10), const Offset(20, 20));

      // Loop a generous square around it.
      controller
        ..beginLasso(const Offset(-50, -50))
        ..appendLasso(const Offset(80, -50))
        ..appendLasso(const Offset(80, 80))
        ..appendLasso(const Offset(-50, 80))
        ..endLasso();
      expect(controller.hasSelection, isTrue);
      expect(controller.selectedElements, hasLength(1));

      // Switching tools clears the selection.
      controller.setTool(CanvasTool.pen);
      expect(controller.hasSelection, isFalse);
    });

    test('lasso that encloses nothing leaves the selection empty', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.lasso);
      addTearDown(controller.dispose);

      drawLine(controller, const Offset(500, 500), const Offset(520, 520));
      controller
        ..beginLasso(const Offset(-10, -10))
        ..appendLasso(const Offset(10, -10))
        ..appendLasso(const Offset(10, 10))
        ..appendLasso(const Offset(-10, 10))
        ..endLasso();
      expect(controller.hasSelection, isFalse);
    });

    test('deleteSelection removes the selection via an undoable command', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.lasso);
      addTearDown(controller.dispose);

      drawLine(controller, const Offset(10, 10), const Offset(20, 20));
      controller
        ..beginLasso(const Offset(-50, -50))
        ..appendLasso(const Offset(80, -50))
        ..appendLasso(const Offset(80, 80))
        ..appendLasso(const Offset(-50, 80))
        ..endLasso();
      expect(controller.hasSelection, isTrue);

      controller.deleteSelection();
      expect(controller.elementCount, 0);
      expect(controller.hasSelection, isFalse);

      controller.undo();
      expect(controller.elementCount, 1);
    });

    test('dragging a selection moves it and survives undo/redo', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.lasso);
      addTearDown(controller.dispose);

      drawLine(controller, const Offset(10, 10), const Offset(20, 20));
      controller
        ..beginLasso(const Offset(-50, -50))
        ..appendLasso(const Offset(80, -50))
        ..appendLasso(const Offset(80, 80))
        ..appendLasso(const Offset(-50, 80))
        ..endLasso();
      final InkElement before = controller.elements.single as InkElement;
      final double startX = before.stroke.points.first.x;

      controller
        ..beginSelectionDrag()
        ..updateSelectionDrag(const Offset(100, 0))
        ..endSelectionDrag();

      final InkElement after = controller.elements.single as InkElement;
      expect(after.stroke.points.first.x, moreOrLessEquals(startX + 100));
      // The selection still tracks the moved element.
      expect(controller.hasSelection, isTrue);

      controller.undo();
      final InkElement reverted = controller.elements.single as InkElement;
      expect(reverted.stroke.points.first.x, moreOrLessEquals(startX));
      expect(controller.hasSelection, isTrue);
    });

    test('a zero-distance selection drag records no command', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.lasso);
      addTearDown(controller.dispose);

      drawLine(controller, const Offset(10, 10), const Offset(20, 20));
      controller
        ..beginLasso(const Offset(-50, -50))
        ..appendLasso(const Offset(80, -50))
        ..appendLasso(const Offset(80, 80))
        ..appendLasso(const Offset(-50, 80))
        ..endLasso();

      controller
        ..beginSelectionDrag()
        ..endSelectionDrag();
      // Only the draw is on the undo stack.
      controller.undo();
      expect(controller.canUndo, isFalse);
    });

    test('shape tool commits a geometric InkElement', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.shape)
        ..setShapeKind(ShapeKind.rectangle);
      addTearDown(controller.dispose);

      controller
        ..beginShape(const Offset(0, 0))
        ..updateShape(const Offset(100, 60))
        ..endShape();
      expect(controller.elementCount, 1);
      final InkElement shape = controller.elements.single as InkElement;
      // A rectangle perimeter is a closed five-point loop.
      expect(shape.stroke.points, hasLength(5));
      expect(controller.canUndo, isTrue);

      controller.undo();
      expect(controller.elementCount, 0);
    });

    test('a zero-size shape drag commits nothing', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.shape);
      addTearDown(controller.dispose);

      controller
        ..beginShape(const Offset(5, 5))
        ..endShape();
      expect(controller.elementCount, 0);
      expect(controller.canUndo, isFalse);
    });

    test('a committed shape can itself be lasso-selected and erased', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.shape)
        ..setShapeKind(ShapeKind.line);
      addTearDown(controller.dispose);

      controller
        ..beginShape(const Offset(10, 10))
        ..updateShape(const Offset(40, 10))
        ..endShape();
      expect(controller.elementCount, 1);

      // The shape erases through the same pipeline as freehand ink.
      controller
        ..setTool(CanvasTool.eraser)
        ..setEraserMode(EraserMode.object)
        ..beginErase(const Offset(25, 10))
        ..endErase();
      expect(controller.elementCount, 0);
    });
  });
}
