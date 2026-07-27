import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/engine/spatial_index.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/render/elements_painter.dart';

InkElement _ink(String id, Rect bounds, {int zIndex = 0}) {
  return InkElement.fromStroke(
    Stroke(
      id: id,
      points: <StrokePoint>[
        StrokePoint(bounds.left, bounds.top, 0.5),
        StrokePoint(bounds.right, bounds.bottom, 0.5),
      ],
      color: 0xFFFFFFFF,
      width: 4,
    ),
    zIndex: zIndex,
  );
}

SpatialIndex _index(List<CanvasElement> elements) {
  final index = SpatialIndex();
  for (final element in elements) {
    index.insert(element.id, element.worldBounds);
  }
  return index;
}

void _paint({
  required ElementsTileCache cache,
  required List<CanvasElement> elements,
  required ViewportState viewport,
  int? revision,
  CanvasElementDamage? damage,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final Map<String, CanvasElement> elementsById = <String, CanvasElement>{
    for (final CanvasElement element in elements) element.id: element,
  };
  ElementsPainter(
    elements: elements,
    spatialIndex: _index(elements),
    allElementsById: elementsById,
    paintOrderById: <String, int>{
      for (var index = 0; index < elements.length; index += 1)
        elements[index].id: index,
    },
    viewport: viewport,
    tileCache: cache,
    elementsRevision: revision,
    elementDamage: damage,
  ).paint(canvas, const Size(256, 256));
  recorder.endRecording().dispose();
}

void main() {
  test('tile cache reuses visible committed pictures across repaints', () {
    final cache = ElementsTileCache();
    final elements = <CanvasElement>[
      _ink('a', const Rect.fromLTWH(0, 0, 100, 100)),
    ];

    _paint(cache: cache, elements: elements, viewport: ViewportState.initial);
    final firstTileCount = cache.tileCount;
    expect(firstTileCount, greaterThan(0));

    _paint(cache: cache, elements: elements, viewport: ViewportState.initial);
    expect(cache.tileCount, firstTileCount);

    cache.dispose();
  });

  test('tile cache evicts least-recently-used tiles', () {
    final cache = ElementsTileCache(maxTiles: 1);
    final elements = <CanvasElement>[
      _ink('a', const Rect.fromLTWH(0, 0, 100, 100)),
      _ink('b', const Rect.fromLTWH(3000, 0, 100, 100), zIndex: 1),
    ];

    _paint(
      cache: cache,
      elements: elements,
      viewport: const ViewportState(translation: Offset(-20, -20)),
    );
    expect(cache.tileCount, 1);

    _paint(
      cache: cache,
      elements: elements,
      viewport: const ViewportState(translation: Offset(-3000, 0)),
    );
    expect(cache.tileCount, 1);

    cache.dispose();
  });

  test('local damage preserves cached pictures outside changed bounds', () {
    final cache = ElementsTileCache();
    final initial = <CanvasElement>[
      _ink('near', const Rect.fromLTWH(20, 20, 100, 100)),
      _ink('far', const Rect.fromLTWH(3000, 20, 100, 100), zIndex: 1),
    ];

    _paint(
      cache: cache,
      elements: initial,
      viewport: ViewportState.initial,
      revision: 1,
      damage: const CanvasElementDamage(
        fromRevision: 0,
        toRevision: 1,
        isFull: true,
      ),
    );
    _paint(
      cache: cache,
      elements: initial,
      viewport: const ViewportState(translation: Offset(-3000, 0)),
      revision: 1,
    );
    final int buildsBeforeEdit = cache.pictureBuildCount;

    final updated = <CanvasElement>[
      _ink('near', const Rect.fromLTWH(40, 20, 100, 100)),
      initial[1],
    ];
    const damage = CanvasElementDamage(
      fromRevision: 1,
      toRevision: 2,
      isFull: false,
      bounds: Rect.fromLTWH(20, 20, 120, 100),
    );
    _paint(
      cache: cache,
      elements: updated,
      viewport: ViewportState.initial,
      revision: 2,
      damage: damage,
    );
    final int buildsAfterLocalEdit = cache.pictureBuildCount;
    expect(buildsAfterLocalEdit, greaterThan(buildsBeforeEdit));

    _paint(
      cache: cache,
      elements: updated,
      viewport: const ViewportState(translation: Offset(-3000, 0)),
      revision: 2,
    );
    expect(cache.pictureBuildCount, buildsAfterLocalEdit);

    cache.dispose();
  });

  test('paints text notes in their bounds without throwing', () {
    final cache = ElementsTileCache();
    const elements = <CanvasElement>[
      TextElement(
        id: 'note',
        zIndex: 0,
        worldBounds: Rect.fromLTWH(20, 24, 180, 90),
        text: 'A multiline\ncanvas note',
        color: 0xFFFFFFFF,
        fontSize: 18,
      ),
    ];

    _paint(cache: cache, elements: elements, viewport: ViewportState.initial);

    expect(cache.tileCount, greaterThan(0));
    cache.dispose();
  });

  test('paints rotated text notes without throwing', () {
    final cache = ElementsTileCache();
    const elements = <CanvasElement>[
      TextElement(
        id: 'rotated-note',
        zIndex: 0,
        rotation: 0.7853981633974483,
        worldBounds: Rect.fromLTWH(20, 24, 180, 90),
        text: 'A rotated\ncanvas note',
        color: 0xFFFFFFFF,
        fontSize: 18,
      ),
    ];

    _paint(cache: cache, elements: elements, viewport: ViewportState.initial);

    expect(cache.tileCount, greaterThan(0));
    cache.dispose();
  });

  test('bypasses tile cache at very low zoom without throwing', () {
    final cache = ElementsTileCache();
    final elements = <CanvasElement>[
      _ink('overview', const Rect.fromLTWH(0, 0, 1000, 1000)),
    ];

    _paint(
      cache: cache,
      elements: elements,
      viewport: const ViewportState(scale: 0.01),
    );

    expect(cache.tileCount, 0);
    cache.dispose();
  });

  test('bypasses tile pictures at high zoom for quality-aware ink', () {
    final cache = ElementsTileCache();
    final elements = <CanvasElement>[
      _ink('deep', const Rect.fromLTWH(0, 0, 100, 100)),
    ];

    _paint(
      cache: cache,
      elements: elements,
      viewport: const ViewportState(scale: 16),
    );

    expect(cache.tileCount, 0);
    cache.dispose();
  });

  test('revision tokens keep equivalent committed inputs from repainting', () {
    final elements = <CanvasElement>[
      _ink('a', const Rect.fromLTWH(0, 0, 100, 100)),
    ];
    final oldPainter = ElementsPainter(
      elements: elements,
      spatialIndex: _index(elements),
      viewport: ViewportState.initial,
      elementsRevision: 1,
      selectionRevision: 0,
      selectionPreviewRevision: 0,
    );
    final newPainter = ElementsPainter(
      elements: List<CanvasElement>.of(elements),
      spatialIndex: oldPainter.spatialIndex,
      viewport: ViewportState.initial,
      elementsRevision: 1,
      selectionRevision: 0,
      selectionPreviewRevision: 0,
    );

    expect(newPainter.shouldRepaint(oldPainter), isFalse);
  });

  test('revision tokens repaint committed inputs when content changes', () {
    final elements = <CanvasElement>[
      _ink('a', const Rect.fromLTWH(0, 0, 100, 100)),
    ];
    final oldPainter = ElementsPainter(
      elements: elements,
      spatialIndex: _index(elements),
      viewport: ViewportState.initial,
      elementsRevision: 1,
    );
    final newPainter = ElementsPainter(
      elements: elements,
      spatialIndex: oldPainter.spatialIndex,
      viewport: ViewportState.initial,
      elementsRevision: 2,
    );

    expect(newPainter.shouldRepaint(oldPainter), isTrue);
  });
}
