import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/engine/spatial_index.dart';
import 'package:zenno/canvas/engine/stroke_builder.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/render/elements_painter.dart';

import 'canvas_performance_fixtures.dart';

const bool _runPerformanceBaseline = bool.fromEnvironment(
  'ZENNO_PERF_BASELINE',
);

void main() {
  test('large-canvas fixture is deterministic and spatially sparse', () {
    final List<CanvasElement> first = CanvasPerformanceFixtures.inkGrid();
    final List<CanvasElement> second = CanvasPerformanceFixtures.inkGrid();

    expect(first, hasLength(10000));
    expect(second, hasLength(first.length));
    expect(
      <String>[for (final CanvasElement element in first) element.id],
      <String>[for (final CanvasElement element in second) element.id],
    );
    expect(first.first.worldBounds, second.first.worldBounds);
    expect(first.last.worldBounds, second.last.worldBounds);

    final SpatialIndex index = _buildIndex(first);
    final List<String> visible = index
        .query(CanvasPerformanceFixtures.viewportRect())
        .toList(growable: false);

    expect(visible, isNotEmpty);
    expect(visible.length, lessThan(first.length ~/ 100));
  });

  test('long-stroke fixture preserves every deterministic input sample', () {
    final stroke = CanvasPerformanceFixtures.longStroke();

    expect(stroke.points, hasLength(8192));
    expect(stroke.points.first.timestampMicros, 0);
    expect(stroke.points.last.timestampMicros, 8191 * 8000);
  });

  group(
    'manual canvas performance baseline',
    () {
      test('records viewport paint work with 10,000 elements', () {
        final List<CanvasElement> elements =
            CanvasPerformanceFixtures.inkGrid();
        final SpatialIndex index = _buildIndex(elements);
        final List<int> samples = <int>[];

        for (var iteration = 0; iteration < 7; iteration += 1) {
          final ui.PictureRecorder recorder = ui.PictureRecorder();
          final Canvas canvas = Canvas(recorder);
          final Stopwatch stopwatch = Stopwatch()..start();
          ElementsPainter(
            elements: elements,
            spatialIndex: index,
            viewport: const ViewportState(scale: 16),
          ).paint(canvas, const Size(800, 600));
          stopwatch.stop();
          samples.add(stopwatch.elapsedMicroseconds);
          recorder.endRecording().dispose();
        }

        _recordSample(
          scenario: 'canvas-paint-10000-sparse',
          valuesMicros: samples,
          facts: <String, Object>{
            'totalElements': elements.length,
            'visibleSpatialHits': index
                .query(CanvasPerformanceFixtures.viewportRect())
                .length,
          },
        );
      });

      test('records ordered insertion cost for 2,000 elements', () {
        final List<CanvasElement> elements = CanvasPerformanceFixtures.inkGrid(
          count: 2000,
        );
        final CanvasController controller = CanvasController();
        addTearDown(controller.dispose);

        final Stopwatch stopwatch = Stopwatch()..start();
        for (final CanvasElement element in elements) {
          controller.addElementToStore(element);
        }
        stopwatch.stop();

        expect(controller.elements, hasLength(elements.length));
        _recordSample(
          scenario: 'canvas-store-insert-2000',
          valuesMicros: <int>[stopwatch.elapsedMicroseconds],
          facts: <String, Object>{'totalElements': elements.length},
        );
      });

      test('records long live-stroke outline construction', () {
        final stroke = CanvasPerformanceFixtures.longStroke();
        final List<int> samples = <int>[];

        for (var iteration = 0; iteration < 7; iteration += 1) {
          final Stopwatch stopwatch = Stopwatch()..start();
          final Path path = buildStrokeOutline(
            stroke.points,
            size: stroke.width,
            isComplete: false,
          );
          stopwatch.stop();
          expect(path.getBounds(), isNot(Rect.zero));
          samples.add(stopwatch.elapsedMicroseconds);
        }

        _recordSample(
          scenario: 'live-stroke-outline-8192',
          valuesMicros: samples,
          facts: <String, Object>{'pointCount': stroke.points.length},
        );
      });
    },
    skip: _runPerformanceBaseline
        ? false
        : 'Run with --dart-define=ZENNO_PERF_BASELINE=true.',
  );
}

SpatialIndex _buildIndex(List<CanvasElement> elements) {
  final SpatialIndex index = SpatialIndex();
  for (final CanvasElement element in elements) {
    index.insert(element.id, element.worldBounds);
  }
  return index;
}

void _recordSample({
  required String scenario,
  required List<int> valuesMicros,
  required Map<String, Object> facts,
}) {
  final List<int> sorted = List<int>.of(valuesMicros)..sort();
  final Map<String, Object> record = <String, Object>{
    'scenario': scenario,
    'buildMode': kReleaseMode
        ? 'release'
        : kProfileMode
        ? 'profile'
        : 'debug',
    'sampleCount': sorted.length,
    'minMicros': sorted.first,
    'medianMicros': sorted[sorted.length ~/ 2],
    'maxMicros': sorted.last,
    ...facts,
  };
  debugPrint('ZENNO_PERF ${jsonEncode(record)}');
}
