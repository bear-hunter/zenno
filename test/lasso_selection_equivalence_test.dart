import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/stroke.dart';

/// The region grid rewrote how a lasso commit decides what it caught, so what
/// it catches has to stay identical. Every scene here is selected twice — once
/// through the grid, once through the exact tests it replaced — and the two id
/// sets must match. A divergence is not a slow lasso, it is the wrong strokes
/// selected and one Delete away from lost notes.
void main() {
  tearDown(() {
    CanvasController.debugDisableLassoRegionGrid = false;
  });

  test('grid and exact commits select the same elements', () {
    var totalSelected = 0;
    var totalSkipped = 0;

    for (var seed = 0; seed < 24; seed++) {
      final math.Random random = math.Random(seed);
      final List<CanvasElement> scene = _scene(random);
      final List<Offset> loop = _loop(random, seed);

      final Set<String> viaGrid = _commitLasso(
        scene,
        loop,
        useGrid: true,
      );
      final Set<String> viaExact = _commitLasso(
        scene,
        loop,
        useGrid: false,
      );

      expect(
        viaGrid,
        viaExact,
        reason:
            'seed $seed: grid selected ${viaGrid.length} of ${scene.length}, '
            'exact selected ${viaExact.length}',
      );
      totalSelected += viaExact.length;
      totalSkipped += scene.length - viaExact.length;
    }

    // Guards against the comparison passing because every loop caught nothing
    // (or everything), which would make the agreement meaningless.
    expect(totalSelected, greaterThan(100));
    expect(totalSkipped, greaterThan(100));
  });

  test('a loop grazing stroke edges agrees element for element', () {
    // Contact selection is the delicate half of the rule: these strokes are not
    // enclosed, they are only clipped by the loop, so each one lands in the
    // grid's boundary band and runs the exact tests against local segments.
    final List<CanvasElement> scene = <CanvasElement>[
      for (var i = 0; i < 60; i++)
        _stroke(
          'graze-$i',
          i,
          <Offset>[Offset(-200, i * 7.0), Offset(200, i * 7.0)],
          width: 3,
        ),
    ];
    final List<Offset> loop = <Offset>[
      for (var i = 0; i <= 90; i++)
        Offset(
          math.cos(2 * math.pi * i / 90) * 150,
          210 + math.sin(2 * math.pi * i / 90) * 150,
        ),
    ];

    expect(
      _commitLasso(scene, loop, useGrid: true),
      _commitLasso(scene, loop, useGrid: false),
    );
  });

  test('a loop swallowing the whole scene agrees with the exact test', () {
    final math.Random random = math.Random(99);
    final List<CanvasElement> scene = _scene(random);
    const List<Offset> loop = <Offset>[
      Offset(-5000, -5000),
      Offset(5000, -5000),
      Offset(5000, 5000),
      Offset(-5000, 5000),
    ];

    final Set<String> viaGrid = _commitLasso(scene, loop, useGrid: true);
    expect(viaGrid, _commitLasso(scene, loop, useGrid: false));
    expect(viaGrid, hasLength(scene.length));
  });
}

/// Runs one lasso commit over [scene] and returns what it selected.
Set<String> _commitLasso(
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
  controller.endLasso();
  CanvasController.debugDisableLassoRegionGrid = false;

  return Set<String>.of(controller.selectedIds);
}

/// A mixed canvas: ink, fills, highlighter, shapes and placed elements.
List<CanvasElement> _scene(math.Random random) {
  final List<CanvasElement> elements = <CanvasElement>[];
  var z = 0;

  for (var i = 0; i < 45; i++) {
    final Offset origin = _spot(random);
    final int points = 2 + random.nextInt(30);
    elements.add(
      _stroke(
        'ink-$i',
        z++,
        <Offset>[
          for (var p = 0; p < points; p++)
            origin +
                Offset(
                  p * 6.0 + random.nextDouble() * 4,
                  math.sin(p / 3) * 18 + random.nextDouble() * 4,
                ),
        ],
        width: 1 + random.nextDouble() * 8,
        tool: random.nextInt(6) == 0
            ? StrokeToolKind.highlighter
            : StrokeToolKind.pen,
      ),
    );
  }

  for (var i = 0; i < 8; i++) {
    final Offset origin = _spot(random);
    elements.add(
      _stroke(
        'fill-$i',
        z++,
        <Offset>[
          for (var p = 0; p < 12; p++)
            origin +
                Offset(
                  math.cos(2 * math.pi * p / 12) * 40,
                  math.sin(2 * math.pi * p / 12) * 30,
                ),
        ],
        width: 2,
        tool: StrokeToolKind.fill,
      ),
    );
  }

  for (var i = 0; i < 12; i++) {
    final Offset origin = _spot(random);
    elements.add(
      ShapeElement(
        id: 'shape-$i',
        zIndex: z++,
        shapeKind: random.nextInt(4),
        start: origin,
        end: origin + Offset(20 + random.nextDouble() * 90, 20 + random.nextDouble() * 70),
        color: 0xFFFFFFFF,
        strokeWidth: 1 + random.nextDouble() * 5,
      ),
    );
  }

  for (var i = 0; i < 8; i++) {
    final Offset origin = _spot(random);
    elements.add(
      TextElement(
        id: 'text-$i',
        zIndex: z++,
        rotation: random.nextBool() ? 0 : random.nextDouble() * math.pi,
        worldBounds: Rect.fromLTWH(origin.dx, origin.dy, 120, 60),
        text: 'note $i',
        color: 0xFFFFFFFF,
        fontSize: 14,
      ),
    );
  }

  for (var i = 0; i < 5; i++) {
    final Offset origin = _spot(random);
    elements.add(
      LinkElement(
        id: 'link-$i',
        zIndex: z++,
        rotation: random.nextBool() ? 0 : random.nextDouble() * math.pi,
        worldBounds: Rect.fromLTWH(origin.dx, origin.dy, 90, 34),
        label: 'link $i',
        target: LinkTarget(targetCanvasId: 'canvas-$i'),
      ),
    );
  }

  return elements;
}

Offset _spot(math.Random random) {
  return Offset(
    -400 + random.nextDouble() * 800,
    -400 + random.nextDouble() * 800,
  );
}

InkElement _stroke(
  String id,
  int zIndex,
  List<Offset> points, {
  required double width,
  StrokeToolKind tool = StrokeToolKind.pen,
}) {
  return InkElement.fromStroke(
    Stroke(
      id: id,
      points: <StrokePoint>[
        for (final Offset point in points)
          StrokePoint(point.dx, point.dy, 0.5),
      ],
      color: 0xFFFFFFFF,
      width: width,
      tool: tool,
    ),
    zIndex: zIndex,
  );
}

/// A wobbling closed loop, big enough to cut through the scene rather than
/// cleanly contain or miss it.
List<Offset> _loop(math.Random random, int seed) {
  final Offset centre = Offset(
    -150 + random.nextDouble() * 300,
    -150 + random.nextDouble() * 300,
  );
  final double radius = 120 + random.nextDouble() * 320;
  final int lobes = 3 + seed % 5;
  return <Offset>[
    for (var i = 0; i < 160; i++)
      () {
        final double angle = 2 * math.pi * i / 160;
        final double wobble = 1 + 0.35 * math.sin(lobes * angle);
        return centre +
            Offset(
              math.cos(angle) * radius * wobble,
              math.sin(angle) * radius * wobble * 0.85,
            );
      }(),
  ];
}
