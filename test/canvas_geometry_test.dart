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
      expect(xs(fragments[0]), <double>[0, 1, 2, 3]);
      expect(xs(fragments[1]), <double>[7, 8, 9, 10]);
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
      expect(xs(fragments[0]), <double>[0, 1, 2, 3]);
      expect(xs(fragments[1]), <double>[17, 18, 19, 20]);
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
      expect(xs(firstCut[0]), <double>[0, 1, 2, 3]);

      // Erase the far survivor run again at x = 15 (removes x=14,15,16).
      final List<List<StrokePoint>> secondCut =
          CanvasGeometry.splitStrokeByEraser(
            stroke: stroke.copyWith(points: firstCut[1]),
            eraserPath: const <Offset>[Offset(15, 0)],
            radius: 1,
          );
      expect(secondCut, hasLength(2)); // [7..13] and [17..20]

      // Net: three contiguous surviving runs; 6 of 21 points erased.
      final List<List<StrokePoint>> allRuns = <List<StrokePoint>>[
        firstCut[0],
        ...secondCut,
      ];
      expect(allRuns, hasLength(3));
      final int survivingPoints = allRuns.fold<int>(
        0,
        (int sum, List<StrokePoint> run) => sum + run.length,
      );
      expect(survivingPoints, 15);
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
      expect(xs(fragments[0]), <double>[0]);
      expect(xs(fragments[1]), <double>[4]);
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
      expect(fragments[0].single.pressure, moreOrLessEquals(0.1));
      expect(fragments[1].single.pressure, moreOrLessEquals(0.4));
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
