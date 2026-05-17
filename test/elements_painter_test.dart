import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  ElementsPainter(
    elements: elements,
    spatialIndex: _index(elements),
    viewport: viewport,
    tileCache: cache,
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

    _paint(cache: cache, elements: elements, viewport: ViewportState.initial);
    expect(cache.tileCount, 1);

    _paint(
      cache: cache,
      elements: elements,
      viewport: const ViewportState(translation: Offset(-3000, 0)),
    );
    expect(cache.tileCount, 1);

    cache.dispose();
  });
}
