import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/canvas_style.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/render/canvas_overlay_painter.dart';

InkElement _ink(String id, double y, {int zIndex = 0}) => InkElement.fromStroke(
  Stroke(
    id: id,
    points: <StrokePoint>[
      StrokePoint(0, y, 0.5),
      StrokePoint(40, y, 0.5),
    ],
    color: 0xFFFFFFFF,
    width: 4,
  ),
  zIndex: zIndex,
);

void main() {
  group('element store indexing', () {
    test('hydrating pre-sorted elements stays linear', () {
      final controller = CanvasController();
      addTearDown(controller.dispose);

      final Stopwatch watch = Stopwatch()..start();
      for (int i = 0; i < 4000; i++) {
        controller.addElementToStore(_ink('e$i', i.toDouble(), zIndex: i));
      }
      watch.stop();

      expect(controller.elementCount, 4000);
      // The old insert scanned the whole list per element, twice. Quadratic
      // growth here is what made opening a dense canvas slow.
      expect(watch.elapsedMilliseconds, lessThan(3000));
    });

    test('removal keeps later elements addressable', () {
      final controller = CanvasController();
      addTearDown(controller.dispose);
      for (int i = 0; i < 20; i++) {
        controller.addElementToStore(_ink('e$i', i.toDouble(), zIndex: i));
      }

      controller.removeElementFromStore('e5');
      controller.removeElementFromStore('e0');

      expect(controller.elementCount, 18);
      // Every surviving id must still resolve after the list shifted under it.
      for (final CanvasElement element in controller.elements) {
        expect(
          controller.elements.where((e) => e.id == element.id).length,
          1,
        );
      }
      controller.removeElementFromStore('e19');
      expect(controller.elements.any((e) => e.id == 'e19'), isFalse);
    });

    test('adding a duplicate id is still a no-op', () {
      final controller = CanvasController();
      addTearDown(controller.dispose);
      controller.addElementToStore(_ink('dup', 0));
      controller.addElementToStore(_ink('dup', 40));
      expect(controller.elementCount, 1);
    });
  });

  group('selection bounds', () {
    test('an empty selection short-circuits before scanning', () {
      final controller = CanvasController();
      addTearDown(controller.dispose);
      for (int i = 0; i < 500; i++) {
        controller.addElementToStore(_ink('e$i', i.toDouble(), zIndex: i));
      }

      expect(controller.selectionBounds, isNull);
    });

    test('a real selection still reports its bounds', () {
      final controller = CanvasController();
      addTearDown(controller.dispose);
      controller.addElementToStore(_ink('a', 0));
      controller.setSelection(<String>{'a'});

      expect(controller.selectionBounds, isNotNull);
    });
  });

  group('overlay theming', () {
    test('chrome contrast follows the paper, not a hardcoded white', () {
      const ViewportState viewport = ViewportState();
      const onLight = CanvasOverlayPainter(
        viewport: viewport,
        paperIsLight: true,
        accentColor: Color(0xFFD8946C),
      );
      const onDark = CanvasOverlayPainter(
        viewport: viewport,
        accentColor: Color(0xFFD8946C),
      );

      // A white hover ring on a white paper preset was simply invisible.
      expect(onLight.paperIsLight, isTrue);
      expect(onDark.paperIsLight, isFalse);
      expect(
        onLight.shouldRepaint(onDark),
        isTrue,
        reason: 'a paper change must repaint the overlay',
      );
    });

    test('the accent comes from the theme', () {
      const ViewportState viewport = ViewportState();
      const a = CanvasOverlayPainter(
        viewport: viewport,
        accentColor: Color(0xFFD8946C),
      );
      const b = CanvasOverlayPainter(
        viewport: viewport,
        accentColor: Color(0xFF3366FF),
      );
      expect(a.shouldRepaint(b), isTrue);
    });
  });

  test('paper style exposes a luminance the overlay can read', () {
    const CanvasPaperStyle white = CanvasPaperStyle(
      backgroundColor: 0xFFFFFFFF,
    );
    expect(Color(white.backgroundColor).computeLuminance(), greaterThan(0.5));
  });

  group('lasso input thinning', () {
    test('a dense drag retains only the vertices that shape the loop', () {
      final controller = CanvasController();
      addTearDown(controller.dispose);

      // 2000 raw moves around a 200-unit loop, the rate an S Pen actually
      // reports at once Flutter expands its historical samples. Every one of
      // them used to be retained, repaint the overlay, and be re-projected.
      controller.beginLasso(Offset.zero);
      for (int i = 0; i < 2000; i++) {
        final double t = i / 2000;
        controller.appendLasso(Offset(200 * t, 40 * (t - t * t)));
      }

      expect(controller.lassoPath!.length, lessThan(400));
      expect(
        controller.lassoPath!.length,
        greaterThan(60),
        reason: 'thinning must not flatten the loop into a few segments',
      );
    });

    test('reading the lasso path twice does not copy it twice', () {
      final controller = CanvasController();
      addTearDown(controller.dispose);

      controller.beginLasso(Offset.zero);
      controller.appendLasso(const Offset(50, 0));
      final List<Offset>? first = controller.lassoPath;

      // The overlay reads this on every repaint, and appending repaints. A
      // fresh copy per read made tracing a loop quadratic in its length.
      expect(identical(controller.lassoPath, first), isTrue);

      controller.appendLasso(const Offset(100, 0));
      expect(identical(controller.lassoPath, first), isFalse);
    });

    test('the retained loop is bounded however long the drag runs', () {
      final controller = CanvasController();
      addTearDown(controller.dispose);

      controller.beginLasso(Offset.zero);
      for (int i = 0; i < 20000; i++) {
        controller.appendLasso(Offset(i * 3.0, (i % 2) * 3.0));
      }

      expect(controller.lassoPath!.length, lessThanOrEqualTo(4000));
    });
  });

  group('selection preview cost', () {
    CanvasController seeded({int elements = 40}) {
      final controller = CanvasController();
      for (var i = 0; i < elements; i++) {
        controller.addElementToStore(_ink('ink-$i', i * 10.0, zIndex: i));
      }
      return controller;
    }

    test('a drag reuses the culled element list instead of rebuilding it', () {
      final CanvasController controller = seeded();
      addTearDown(controller.dispose);
      controller.setSelection(<String>['ink-0', 'ink-1']);
      controller.beginSelectionDrag();

      // Every pointer sample used to drop this list, so each drag frame
      // re-queried the spatial index and re-sorted everything on screen.
      final List<CanvasElement> culled = controller.viewportElements;
      controller.updateSelectionDrag(const Offset(6, 0));
      controller.updateSelectionDrag(const Offset(6, 0));

      expect(identical(controller.viewportElements, culled), isTrue);
    });

    test('cached selection bounds still track drags and edits', () {
      final CanvasController controller = seeded();
      addTearDown(controller.dispose);
      controller.setSelection(<String>['ink-0']);

      final Rect? initial = controller.selectionBounds;
      expect(initial, isNotNull);

      controller.beginSelectionDrag();
      controller.updateSelectionDrag(const Offset(25, 12));
      expect(controller.selectionBounds, initial!.shift(const Offset(25, 12)));

      controller.endSelectionDrag();
      expect(controller.selectionBounds, initial.shift(const Offset(25, 12)));

      // Growing the selection has to widen the cached box, not keep serving
      // the old one.
      controller.setSelection(<String>['ink-0', 'ink-39']);
      expect(
        controller.selectionBounds!.height,
        greaterThan(initial.height * 2),
      );

      controller.clearSelection();
      expect(controller.selectionBounds, isNull);
    });

    test('deleting a selected element reshapes the cached bounds', () {
      final CanvasController controller = seeded();
      addTearDown(controller.dispose);
      controller.setSelection(<String>['ink-0', 'ink-39']);
      final Rect wide = controller.selectionBounds!;

      controller.deleteSelection();

      expect(controller.selectionBounds, isNull);
      controller.setSelection(<String>['ink-1']);
      expect(controller.selectionBounds!.height, lessThan(wide.height));
    });
  });
}
