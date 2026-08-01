import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/tools/canvas_geometry.dart';

/// Builds a straight horizontal [Stroke] of `count` evenly-spaced points.
///
/// Points run from `(0, 0)` to `(count - 1, 0)` at unit spacing, so the
/// index of a point equals its x coordinate — which makes the stroke-splitting
/// assertions easy to read.
Stroke horizontalStroke(int count) {
  return Stroke(
    id: 'h',
    points: <StrokePoint>[
      for (int i = 0; i < count; i++) StrokePoint(i.toDouble(), 0, 0.5),
    ],
    color: 0xFFFFFFFF,
    width: 4,
  );
}

/// The x coordinates of one stroke fragment, for compact assertions.
List<double> xs(List<StrokePoint> fragment) => <double>[
  for (final StrokePoint p in fragment) p.x,
];

void main() {
  group('CanvasGeometry.distanceToSegment', () {
    test('point on the segment has zero distance', () {
      expect(
        CanvasGeometry.distanceToSegment(
          const Offset(5, 0),
          Offset.zero,
          const Offset(10, 0),
        ),
        moreOrLessEquals(0),
      );
    });

    test('perpendicular distance is the offset from the line', () {
      expect(
        CanvasGeometry.distanceToSegment(
          const Offset(5, 3),
          Offset.zero,
          const Offset(10, 0),
        ),
        moreOrLessEquals(3),
      );
    });

    test('beyond an endpoint the nearest point is that endpoint', () {
      // x = 20 is past the (10, 0) end, so the nearest point is (10, 0).
      expect(
        CanvasGeometry.distanceToSegment(
          const Offset(20, 0),
          Offset.zero,
          const Offset(10, 0),
        ),
        moreOrLessEquals(10),
      );
    });

    test('a degenerate segment reduces to point distance', () {
      expect(
        CanvasGeometry.distanceToSegment(
          const Offset(3, 4),
          const Offset(0, 0),
          const Offset(0, 0),
        ),
        moreOrLessEquals(5),
      );
    });
  });

  group('CanvasGeometry.polygonContainsPoint', () {
    final List<Offset> square = <Offset>[
      const Offset(0, 0),
      const Offset(10, 0),
      const Offset(10, 10),
      const Offset(0, 10),
    ];

    test('a point inside the polygon is contained', () {
      expect(
        CanvasGeometry.polygonContainsPoint(square, const Offset(5, 5)),
        isTrue,
      );
    });

    test('a point outside the polygon is not contained', () {
      expect(
        CanvasGeometry.polygonContainsPoint(square, const Offset(15, 5)),
        isFalse,
      );
    });

    test('a degenerate polygon (< 3 vertices) contains nothing', () {
      expect(
        CanvasGeometry.polygonContainsPoint(<Offset>[
          const Offset(0, 0),
          const Offset(10, 0),
        ], const Offset(5, 0)),
        isFalse,
      );
    });

    test('coverage is the inside fraction of a point list', () {
      // Three of four points lie inside the square.
      final List<Offset> points = <Offset>[
        const Offset(2, 2),
        const Offset(5, 5),
        const Offset(8, 8),
        const Offset(50, 50),
      ];
      expect(
        CanvasGeometry.polygonCoverage(square, points),
        moreOrLessEquals(0.75),
      );
    });
  });

  group('CanvasGeometry.simplifyPolyline', () {
    test('short inputs are returned unchanged', () {
      expect(CanvasGeometry.simplifyPolyline(const <Offset>[], 2), isEmpty);
      expect(
        CanvasGeometry.simplifyPolyline(const <Offset>[Offset(1, 2)], 2),
        const <Offset>[Offset(1, 2)],
      );
      expect(
        CanvasGeometry.simplifyPolyline(const <Offset>[
          Offset(1, 2),
          Offset(3, 4),
        ], 2),
        const <Offset>[Offset(1, 2), Offset(3, 4)],
      );
    });

    test('collinear points collapse while endpoints are retained', () {
      final List<Offset> simplified = CanvasGeometry.simplifyPolyline(
        const <Offset>[Offset(0, 0), Offset(2, 0), Offset(4, 0), Offset(6, 0)],
        0.1,
      );

      expect(simplified, const <Offset>[Offset(0, 0), Offset(6, 0)]);
    });

    test('corners outside the tolerance are preserved', () {
      final List<Offset> simplified = CanvasGeometry.simplifyPolyline(
        const <Offset>[
          Offset(0, 0),
          Offset(5, 0),
          Offset(10, 0),
          Offset(10, 5),
          Offset(10, 10),
        ],
        0.1,
      );

      expect(simplified, const <Offset>[
        Offset(0, 0),
        Offset(10, 0),
        Offset(10, 10),
      ]);
    });

    test('a simplified loop preserves representative selection results', () {
      final List<Offset> rawLoop = <Offset>[
        for (var x = 0; x <= 100; x++) Offset(x.toDouble(), 0),
        for (var y = 1; y <= 100; y++) Offset(100, y.toDouble()),
        for (var x = 99; x >= 0; x--) Offset(x.toDouble(), 100),
        for (var y = 99; y >= 1; y--) Offset(0, y.toDouble()),
      ];
      final List<Offset> simplified = CanvasGeometry.simplifyPolyline(
        rawLoop,
        2,
      );
      final List<List<Offset>> elementCenterlines = <List<Offset>>[
        <Offset>[for (var x = 20; x <= 80; x += 5) Offset(x.toDouble(), 50)],
        <Offset>[for (var x = 120; x <= 180; x += 5) Offset(x.toDouble(), 50)],
        <Offset>[for (var y = 20; y <= 80; y += 5) Offset(50, y.toDouble())],
      ];

      expect(simplified.length, lessThan(rawLoop.length));
      for (final List<Offset> centerline in elementCenterlines) {
        expect(
          CanvasGeometry.polygonMajorityInside(simplified, centerline),
          CanvasGeometry.polygonMajorityInside(rawLoop, centerline),
        );
      }
    });
  });

  group('CanvasGeometry.polygonMajorityInside', () {
    test('matches polygonCoverage across randomized polygons and points', () {
      final math.Random random = math.Random(4729);

      for (var iteration = 0; iteration < 100; iteration++) {
        final int vertexCount = 3 + random.nextInt(14);
        final List<Offset> polygon = <Offset>[
          for (var i = 0; i < vertexCount; i++)
            Offset.fromDirection(
              i * 2 * math.pi / vertexCount,
              20 + random.nextDouble() * 80,
            ),
        ];
        final List<Offset> points = <Offset>[
          for (var i = 0; i < random.nextInt(100); i++)
            Offset(
              random.nextDouble() * 240 - 120,
              random.nextDouble() * 240 - 120,
            ),
        ];

        expect(
          CanvasGeometry.polygonMajorityInside(polygon, points),
          CanvasGeometry.polygonCoverage(polygon, points) > 0.5,
          reason: 'mismatch in randomized iteration $iteration',
        );
      }
    });

    test('large-loop hit testing stays within a desktop frame budget', () {
      final List<Offset> rawLoop = <Offset>[
        for (var i = 0; i < 4000; i++)
          Offset.fromDirection(
            i * 2 * math.pi / 4000,
            1000 + math.sin(i * 0.17),
          ),
      ];
      final List<List<Offset>> strokes = <List<Offset>>[
        for (var stroke = 0; stroke < 500; stroke++)
          <Offset>[
            for (var point = 0; point < 200; point++)
              Offset(-400 + point * 4, -400 + (stroke % 200) * 4),
          ],
      ];
      final List<Offset> simplified = CanvasGeometry.simplifyPolyline(
        rawLoop,
        2,
      );

      final Stopwatch baselineWatch = Stopwatch()..start();
      for (final List<Offset> stroke in strokes.take(5)) {
        CanvasGeometry.polygonCoverage(rawLoop, stroke);
      }
      baselineWatch.stop();

      final Stopwatch optimizedWatch = Stopwatch()..start();
      for (final List<Offset> stroke in strokes) {
        final int stride = math.max(1, stroke.length ~/ 32);
        final List<Offset> samples = <Offset>[
          for (var i = 0; i < stroke.length; i += stride) stroke[i],
        ];
        CanvasGeometry.polygonMajorityInside(simplified, samples);
      }
      optimizedWatch.stop();

      final Duration estimatedBaseline = baselineWatch.elapsed * 100;
      debugPrint(
        'Lasso perf: 4000 -> ${simplified.length} vertices; '
        'estimated baseline ${estimatedBaseline.inMilliseconds} ms; '
        'optimized ${optimizedWatch.elapsedMicroseconds / 1000} ms',
      );
      expect(
        optimizedWatch.elapsed,
        lessThan(const Duration(milliseconds: 16)),
      );
    });
  });

  group('CanvasGeometry.splitStrokeByEraser', () {
    test('an eraser that misses the stroke leaves it whole', () {
      final Stroke stroke = horizontalStroke(10);
      final List<List<StrokePoint>> fragments =
          CanvasGeometry.splitStrokeByEraser(
            stroke: stroke,
            // Far below the stroke, well outside the radius.
            eraserPath: const <Offset>[Offset(5, 100)],
            radius: 1,
          );
      expect(fragments, hasLength(1));
      expect(fragments.single, hasLength(10));
      expect(xs(fragments.single), xs(stroke.points));
    });

    test('an eraser through the middle splits the stroke in two', () {
      final Stroke stroke = horizontalStroke(11); // x: 0..10
      // A point eraser at x = 5 with radius 1.5 removes points x = 4, 5, 6.
      final List<List<StrokePoint>> fragments =
          CanvasGeometry.splitStrokeByEraser(
            stroke: stroke,
            eraserPath: const <Offset>[Offset(5, 0)],
            radius: 1.5,
          );
      expect(fragments, hasLength(2));
      expect(xs(fragments[0]), <double>[0, 1, 2, 3, 3.5]);
      expect(xs(fragments[1]), <double>[6.5, 7, 8, 9, 10]);
    });

    test('an eraser covering everything fully erases the stroke', () {
      final Stroke stroke = horizontalStroke(6); // x: 0..5
      // A swept eraser path running the whole length, generous radius.
      final List<List<StrokePoint>> fragments =
          CanvasGeometry.splitStrokeByEraser(
            stroke: stroke,
            eraserPath: const <Offset>[Offset(0, 0), Offset(5, 0)],
            radius: 2,
          );
      expect(fragments, isEmpty);
    });

    test('an eraser swept along the stroke erases the whole covered span', () {
      final Stroke stroke = horizontalStroke(21); // x: 0..20
      // A 2-sample eraser path from x=5 to x=15: the swept segment runs along
      // the stroke, so the entire span 4..16 (radius 1) is erased in one cut.
      final List<List<StrokePoint>> fragments =
          CanvasGeometry.splitStrokeByEraser(
            stroke: stroke,
            eraserPath: const <Offset>[Offset(5, 0), Offset(15, 0)],
            radius: 1,
          );
      expect(fragments, hasLength(2));
      expect(xs(fragments[0]), <double>[0, 1, 2, 3, 4]);
      expect(xs(fragments[1]), <double>[16, 17, 18, 19, 20]);
    });

    test('two disjoint point erasers cut the stroke into three pieces', () {
      // Erase one stroke twice, feeding the survivors of the first erase into
      // the second — the contiguous-run model of the engine's partial eraser.
      final Stroke stroke = horizontalStroke(21); // x: 0..20
      final List<List<StrokePoint>> firstCut =
          CanvasGeometry.splitStrokeByEraser(
            stroke: stroke,
            eraserPath: const <Offset>[Offset(5, 0)],
            radius: 1,
          );
      // A point eraser at x=5 removes x=4,5,6 → survivors [0..3] and [7..20].
      expect(firstCut, hasLength(2));
      expect(xs(firstCut[0]), <double>[0, 1, 2, 3, 4]);

      // Erase the far survivor run again at x = 15 (removes x=14,15,16).
      final List<List<StrokePoint>> secondCut =
          CanvasGeometry.splitStrokeByEraser(
            stroke: stroke.copyWith(points: firstCut[1]),
            eraserPath: const <Offset>[Offset(15, 0)],
            radius: 1,
          );
      expect(secondCut, hasLength(2)); // [7..13] and [17..20]

      // Net: three contiguous surviving runs, with cut boundary points
      // inserted to keep sparse strokes visually continuous.
      final List<List<StrokePoint>> allRuns = <List<StrokePoint>>[
        firstCut[0],
        ...secondCut,
      ];
      expect(allRuns, hasLength(3));
      final int survivingPoints = allRuns.fold<int>(
        0,
        (int sum, List<StrokePoint> run) => sum + run.length,
      );
      expect(survivingPoints, 19);
    });

    test('an isolated surviving point is kept as a single-point fragment', () {
      final Stroke stroke = horizontalStroke(5); // x: 0..4
      // A 2-sample eraser path covering x=1..3 with radius 0.9 erases exactly
      // x=1,2,3, leaving x=0 and x=4 as two lone surviving points.
      final List<List<StrokePoint>> fragments =
          CanvasGeometry.splitStrokeByEraser(
            stroke: stroke,
            eraserPath: const <Offset>[Offset(1, 0), Offset(3, 0)],
            radius: 0.9,
          );
      expect(fragments, hasLength(2));
      expect(xs(fragments[0]), <double>[0, 1]);
      expect(xs(fragments[1]), <double>[3, 4]);
    });

    test('an empty eraser path leaves the stroke whole', () {
      final Stroke stroke = horizontalStroke(4);
      final List<List<StrokePoint>> fragments =
          CanvasGeometry.splitStrokeByEraser(
            stroke: stroke,
            eraserPath: const <Offset>[],
            radius: 5,
          );
      expect(fragments, hasLength(1));
      expect(xs(fragments.single), xs(stroke.points));
    });

    test('an empty stroke yields no fragments', () {
      final List<List<StrokePoint>> fragments =
          CanvasGeometry.splitStrokeByEraser(
            stroke: const Stroke(
              id: 'e',
              points: <StrokePoint>[],
              color: 0xFFFFFFFF,
              width: 4,
            ),
            eraserPath: const <Offset>[Offset(0, 0)],
            radius: 5,
          );
      expect(fragments, isEmpty);
    });

    test('fragments preserve original point order and pressure', () {
      const Stroke stroke = Stroke(
        id: 'p',
        points: <StrokePoint>[
          StrokePoint(0, 0, 0.1),
          StrokePoint(1, 0, 0.2),
          StrokePoint(2, 0, 0.3),
          StrokePoint(3, 0, 0.4),
        ],
        color: 0xFFFFFFFF,
        width: 4,
      );
      // Erase the middle two points.
      final List<List<StrokePoint>> fragments =
          CanvasGeometry.splitStrokeByEraser(
            stroke: stroke,
            eraserPath: const <Offset>[Offset(1.5, 0)],
            radius: 0.9,
          );
      expect(fragments, hasLength(2));
      expect(fragments[0].first.pressure, moreOrLessEquals(0.1));
      expect(fragments[0].last.pressure, moreOrLessEquals(0.16));
      expect(fragments[1].first.pressure, moreOrLessEquals(0.34));
      expect(fragments[1].last.pressure, moreOrLessEquals(0.4));
    });
  });

  group('CanvasGeometry shape generators', () {
    test('linePoints is the two endpoints', () {
      expect(
        CanvasGeometry.linePoints(const Offset(1, 2), const Offset(9, 4)),
        <Offset>[const Offset(1, 2), const Offset(9, 4)],
      );
    });

    test('rectanglePoints is a closed four-corner loop', () {
      final List<Offset> rect = CanvasGeometry.rectanglePoints(
        const Offset(0, 0),
        const Offset(10, 6),
      );
      expect(rect, hasLength(5));
      expect(rect.first, rect.last); // closed
      expect(rect.first, const Offset(0, 0));
      expect(rect[2], const Offset(10, 6)); // opposite corner
    });

    test('ovalPoints traces a closed loop within the bounding box', () {
      final List<Offset> oval = CanvasGeometry.ovalPoints(
        const Offset(0, 0),
        const Offset(20, 10),
        segments: 32,
      );
      expect((oval.first - oval.last).distance, lessThan(1e-9)); // closed
      final Rect bounds = CanvasGeometry.boundsOfPoints(oval);
      // The ellipse fits its bounding box (allow a hair of float slack).
      expect(bounds.left, moreOrLessEquals(0, epsilon: 1e-6));
      expect(bounds.right, moreOrLessEquals(20, epsilon: 1e-6));
      expect(bounds.top, moreOrLessEquals(0, epsilon: 1e-6));
      expect(bounds.bottom, moreOrLessEquals(10, epsilon: 1e-6));
    });

    test('arrowPoints draws a shaft plus two head barbs', () {
      final List<Offset> arrow = CanvasGeometry.arrowPoints(
        const Offset(0, 0),
        const Offset(100, 0),
      );
      // start, end, barbLeft, end, barbRight — one continuous polyline.
      expect(arrow, hasLength(5));
      expect(arrow[0], const Offset(0, 0));
      expect(arrow[1], const Offset(100, 0));
      expect(arrow[3], const Offset(100, 0));
      // Barbs sit behind the tip (smaller x) and off the shaft axis.
      expect(arrow[2].dx, lessThan(100));
      expect(arrow[2].dy, isNot(moreOrLessEquals(0)));
      expect(arrow[4].dy, isNot(moreOrLessEquals(0)));
    });

    test('a zero-length arrow drag yields coincident points', () {
      final List<Offset> arrow = CanvasGeometry.arrowPoints(
        const Offset(5, 5),
        const Offset(5, 5),
      );
      expect(arrow, <Offset>[const Offset(5, 5), const Offset(5, 5)]);
    });
  });
}
