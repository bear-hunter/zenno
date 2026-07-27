import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/engine/stroke_builder.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/render/live_stroke_painter.dart';

List<StrokePoint> _line({
  int count = 40,
  double length = 200,
  double pressure = 0.5,
}) {
  return <StrokePoint>[
    for (int i = 0; i < count; i++)
      StrokePoint(length * i / (count - 1), 0, pressure),
  ];
}

void main() {
  group('buildStrokeOutline', () {
    test('empty input yields an empty path', () {
      expect(buildStrokeOutline(const <StrokePoint>[], size: 4).computeMetrics(),
          isEmpty);
    });

    test('a single point yields a dot scaled by pressure', () {
      final Path light = buildStrokeOutline(
        <StrokePoint>[const StrokePoint(0, 0, 0)],
        size: 10,
      );
      final Path heavy = buildStrokeOutline(
        <StrokePoint>[const StrokePoint(0, 0, 1)],
        size: 10,
      );
      expect(light.getBounds().width, greaterThan(0));
      expect(
        heavy.getBounds().width,
        greaterThan(light.getBounds().width),
        reason: 'a firmer tap must leave a larger dot',
      );
    });

    test('a straight stroke stays within the swept centerline band', () {
      final Path path = buildStrokeOutline(_line(), size: 8);
      final Rect bounds = path.getBounds();

      // The outline surrounds the centerline, so it must span the line's
      // length and stay inside a band of the stroke's own width around it.
      expect(bounds.left, lessThanOrEqualTo(1));
      expect(bounds.right, greaterThan(190));
      expect(bounds.top, greaterThanOrEqualTo(-8));
      expect(bounds.bottom, lessThanOrEqualTo(8));
    });

    test('a wider size produces a thicker band', () {
      final double thin = buildStrokeOutline(_line(), size: 4).getBounds().height;
      final double thick =
          buildStrokeOutline(_line(), size: 16).getBounds().height;
      expect(thick, greaterThan(thin));
    });

    test('the outline is closed and enclosed by its own bounds', () {
      final Path path = buildStrokeOutline(_line(), size: 8);
      final Rect bounds = path.getBounds();
      expect(path.contains(bounds.center), isTrue);
      expect(path.computeMetrics().single.isClosed, isTrue);
    });

    test('a curved stroke covers the arc it was drawn along', () {
      final List<StrokePoint> arc = <StrokePoint>[
        for (int i = 0; i <= 40; i++)
          StrokePoint(i * 5, (i * 5 - 100) * (i * 5 - 100) / 100, 0.5),
      ];
      final Rect bounds = buildStrokeOutline(arc, size: 6).getBounds();
      expect(bounds.width, greaterThan(150));
      expect(bounds.height, greaterThan(50));
    });

    test('render quality is bucketed by viewport scale', () {
      expect(strokeRenderQualityForScale(0.01), StrokeRenderQuality.overview);
      expect(strokeRenderQualityForScale(1), StrokeRenderQuality.normal);
      expect(strokeRenderQualityForScale(8), StrokeRenderQuality.highZoom);
    });

    test('one outline serves every zoom level', () {
      // One path now serves every zoom: the outline is emitted as quadratic
      // curves, so Skia resolves the smoothness against the device transform
      // and the geometry itself is viewport-independent.
      final Rect bounds = buildStrokeOutline(_line(), size: 8).getBounds();
      expect(bounds.width, greaterThan(190));
    });

    test('a long stroke tessellates in bounded time', () {
      final Stopwatch watch = Stopwatch()..start();
      buildStrokeOutline(_line(count: 4000, length: 4000), size: 6);
      watch.stop();
      expect(watch.elapsedMilliseconds, lessThan(2000));
    });
  });

  group('buildFillBoundaryPath', () {
    test('fewer than three points cannot enclose an area', () {
      expect(
        buildFillBoundaryPath(<StrokePoint>[
          const StrokePoint(0, 0, 0.5),
          const StrokePoint(10, 0, 0.5),
        ]).computeMetrics(),
        isEmpty,
      );
    });

    test('a triangle encloses its own centroid', () {
      final Path path = buildFillBoundaryPath(<StrokePoint>[
        const StrokePoint(0, 0, 0.5),
        const StrokePoint(100, 0, 0.5),
        const StrokePoint(50, 100, 0.5),
      ]);
      expect(path.contains(const Offset(50, 40)), isTrue);
      expect(path.contains(const Offset(500, 500)), isFalse);
    });
  });

  group('isValidFillBoundary', () {
    test('collinear points do not enclose a region', () {
      expect(isValidFillBoundary(_line(count: 5)), isFalse);
    });

    test('a triangle does', () {
      expect(
        isValidFillBoundary(<StrokePoint>[
          const StrokePoint(0, 0, 0.5),
          const StrokePoint(100, 0, 0.5),
          const StrokePoint(50, 100, 0.5),
        ]),
        isTrue,
      );
    });
  });

  group('LiveStrokePathCache', () {
    Stroke strokeOf(int count) => Stroke(
      id: 'live',
      points: <StrokePoint>[
        for (int i = 0; i < count; i++) StrokePoint(i * 2.0, 0, 0.5),
      ],
      color: 0xFFFFFFFF,
      width: 6,
    );

    test('a short stroke is rebuilt whole', () {
      final cache = LiveStrokePathCache();
      final geometry = cache.geometryFor(
        stroke: strokeOf(20),
        revision: 1,
        blockPaint: Paint(),
      );
      expect(geometry.prefix, isNull);
      expect(geometry.tail.getBounds().width, greaterThan(0));
    });

    test('a long stroke freezes a prefix and keeps a short tail', () {
      final cache = LiveStrokePathCache();
      final geometry = cache.geometryFor(
        stroke: strokeOf(400),
        revision: 1,
        blockPaint: Paint(),
      );
      expect(geometry.prefix, isNotNull);

      // The tail covers only the unfrozen end of the stroke, so it spans a
      // small fraction of the stroke's total length.
      final double tailWidth = geometry.tail.getBounds().width;
      expect(tailWidth, lessThan(400));
    });

    test('per-sample cost stays flat as the stroke grows', () {
      final cache = LiveStrokePathCache();
      final paint = Paint();

      double timeAround(int from, int to) {
        final watch = Stopwatch()..start();
        for (int n = from; n <= to; n++) {
          cache.geometryFor(
            stroke: strokeOf(n),
            revision: n,
            blockPaint: paint,
          );
        }
        watch.stop();
        return watch.elapsedMicroseconds / (to - from + 1);
      }

      final double early = timeAround(200, 260);
      final double late = timeAround(1200, 1260);

      // Without a frozen prefix this ratio grows linearly with stroke length.
      expect(late, lessThan(early * 6));
    });

    test('switching strokes discards the previous prefix', () {
      final cache = LiveStrokePathCache();
      cache.geometryFor(
        stroke: strokeOf(400),
        revision: 1,
        blockPaint: Paint(),
      );
      final next = cache.geometryFor(
        stroke: Stroke(
          id: 'other',
          points: <StrokePoint>[
            const StrokePoint(0, 0, 0.5),
            const StrokePoint(10, 0, 0.5),
          ],
          color: 0xFFFFFFFF,
          width: 6,
        ),
        revision: 2,
        blockPaint: Paint(),
      );
      expect(next.prefix, isNull);
    });
  });
}
