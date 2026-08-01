import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/stroke.dart';

/// What a lasso commit costs when the loop is big enough to swallow a whole
/// mindmap — the case where the spatial-index broad phase stops filtering
/// anything and every element used to run the full narrow phase.
///
/// These numbers come from a debug-mode VM, so they are pessimistic next to an
/// AOT release build on the tablet. The assertions are deliberately loose; the
/// printed measurements are the real signal.
void main() {
  tearDown(() {
    CanvasController.debugDisableLassoRegionGrid = false;
  });

  test('a loop around 10,000 strokes commits in well under a second', () {
    final List<CanvasElement> scene = _mindmap(strokes: 10000);
    final List<Offset> loop = _loop();

    final _Commit commit = _measureCommit(scene, loop, useGrid: true);

    expect(
      commit.loopVertices,
      greaterThan(150),
      reason: 'a loop this coarse would not exercise the narrow phase',
    );
    expect(commit.selected, greaterThan(scene.length ~/ 5));
    expect(commit.selected, lessThan(scene.length * 4 ~/ 5));

    debugPrint(
      'lasso commit: ${scene.length} strokes, ${commit.loopVertices} loop '
      'vertices, ${commit.selected} selected in '
      '${commit.elapsed.inMilliseconds}ms',
    );
    expect(
      commit.elapsed.inMilliseconds,
      lessThan(600),
      reason: 'commit cost regressed — the grid fast paths are not engaging',
    );
  });

  test('the region grid beats the exact narrow phase by a wide margin', () {
    // A tenth of the scene above, so the pre-grid path finishes in seconds
    // rather than minutes while still showing the gap.
    final List<CanvasElement> scene = _mindmap(strokes: 1000);
    final List<Offset> loop = _loop();

    final _Commit withGrid = _measureCommit(scene, loop, useGrid: true);
    final _Commit exact = _measureCommit(scene, loop, useGrid: false);

    expect(withGrid.selected, exact.selected);
    debugPrint(
      'lasso commit over ${scene.length} strokes: '
      'grid ${withGrid.elapsed.inMicroseconds}us vs '
      'exact ${exact.elapsed.inMicroseconds}us',
    );
    expect(
      withGrid.elapsed.inMicroseconds * 4,
      lessThan(exact.elapsed.inMicroseconds),
      reason: 'the grid should be several times faster, not marginally',
    );
  });
}

class _Commit {
  const _Commit({
    required this.elapsed,
    required this.selected,
    required this.loopVertices,
  });

  final Duration elapsed;
  final int selected;
  final int loopVertices;
}

_Commit _measureCommit(
  List<CanvasElement> scene,
  List<Offset> loop, {
  required bool useGrid,
}) {
  final CanvasController controller = CanvasController();
  addTearDown(controller.dispose);
  for (final CanvasElement element in scene) {
    controller.addElementToStore(element);
  }
  controller.setTool(CanvasTool.lasso);
  CanvasController.debugDisableLassoRegionGrid = !useGrid;

  controller.beginLasso(loop.first);
  for (final Offset point in loop.skip(1)) {
    controller.appendLasso(point);
  }
  final int vertices = controller.lassoPath!.length;

  final Stopwatch stopwatch = Stopwatch()..start();
  controller.endLasso();
  stopwatch.stop();

  CanvasController.debugDisableLassoRegionGrid = false;
  return _Commit(
    elapsed: stopwatch.elapsed,
    selected: controller.selectedIds.length,
    loopVertices: vertices,
  );
}

/// Short strokes scattered over a wide extent, the way mindmap notes sit.
List<CanvasElement> _mindmap({
  required int strokes,
  double extent = 6000,
  int pointsPerStroke = 40,
}) {
  final math.Random random = math.Random(20260801);
  return <CanvasElement>[
    for (var i = 0; i < strokes; i++)
      () {
        final Offset origin = Offset(
          random.nextDouble() * extent - extent / 2,
          random.nextDouble() * extent - extent / 2,
        );
        return InkElement.fromStroke(
          Stroke(
            id: 'bench-$i',
            points: <StrokePoint>[
              for (var p = 0; p < pointsPerStroke; p++)
                StrokePoint(
                  origin.dx + p * 1.5,
                  origin.dy + math.sin(p / 4) * 8,
                  0.5,
                ),
            ],
            color: 0xFFFFFFFF,
            width: 3,
          ),
          zIndex: i,
        );
      }(),
  ];
}

/// A hand-drawn-looking loop: a big circle carrying enough high-frequency
/// wobble to survive the commit-time simplification, like real pen tracing.
List<Offset> _loop({double radius = 2200}) {
  return <Offset>[
    for (var i = 0; i < 900; i++)
      () {
        final double angle = 2 * math.pi * i / 900;
        final double wobble = radius + math.sin(angle * 47) * 9;
        return Offset(math.cos(angle) * wobble, math.sin(angle) * wobble);
      }(),
  ];
}
