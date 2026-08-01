import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/tools/canvas_geometry.dart';
import 'package:zenno/canvas/tools/lasso_region_grid.dart';

/// The grid is only allowed to be faster than the exact tests, never different.
/// Everything here pins that: containment must agree point for point, a
/// rectangle may only be called inside/outside when every point in it really is,
/// and no loop segment that reaches a rectangle may be left out of its runs.
void main() {
  group('LassoRegionGrid.containsPoint', () {
    test('agrees with the exact even-odd test on every loop shape', () {
      final math.Random random = math.Random(20260801);
      for (final (String name, List<Offset> polygon) in _polygons(random)) {
        final LassoRegionGrid? grid = LassoRegionGrid.build(polygon);
        expect(grid, isNotNull, reason: '$name should build a grid');

        final Rect bounds = CanvasGeometry.boundsOfPoints(polygon);
        // Probe wider than the loop so points beyond its bounding box are
        // covered too, and include the vertices themselves.
        final Rect probe = bounds.inflate(
          math.max(bounds.width, bounds.height) * 0.2,
        );
        final List<Offset> points = <Offset>[
          ...polygon,
          for (var i = 0; i < 4000; i++)
            Offset(
              probe.left + random.nextDouble() * probe.width,
              probe.top + random.nextDouble() * probe.height,
            ),
        ];

        for (final Offset point in points) {
          expect(
            grid!.containsPoint(point),
            CanvasGeometry.polygonContainsPoint(polygon, point),
            reason: '$name disagreed at $point',
          );
        }
      }
    });

    test('agrees on a loop whose edges land exactly on cell lines', () {
      // An axis-aligned loop whose bounding box divides evenly into cells puts
      // whole edges on cell borders — the case where a cell could be called
      // decided when the outline actually runs through it.
      const List<Offset> square = <Offset>[
        Offset.zero,
        Offset(128, 0),
        Offset(128, 128),
        Offset(0, 128),
      ];
      final LassoRegionGrid grid = LassoRegionGrid.build(
        square,
        longAxisCells: 128,
      )!;

      for (var x = -2; x <= 130; x++) {
        for (var y = -2; y <= 130; y++) {
          final Offset point = Offset(x.toDouble(), y.toDouble());
          expect(
            grid.containsPoint(point),
            CanvasGeometry.polygonContainsPoint(square, point),
            reason: 'disagreed at $point',
          );
        }
      }
    });
  });

  group('LassoRegionGrid.classifyRect', () {
    test('only claims inside or outside when every point agrees', () {
      final math.Random random = math.Random(5150);
      for (final (String name, List<Offset> polygon) in _polygons(random)) {
        final LassoRegionGrid grid = LassoRegionGrid.build(polygon)!;
        final Rect bounds = CanvasGeometry.boundsOfPoints(polygon);
        final double span = math.max(bounds.width, bounds.height);

        var decided = 0;
        for (var i = 0; i < 1500; i++) {
          final double width = random.nextDouble() * span * 0.3;
          final double height = random.nextDouble() * span * 0.3;
          final Rect rect = Rect.fromLTWH(
            bounds.left - span * 0.1 + random.nextDouble() * span * 1.2,
            bounds.top - span * 0.1 + random.nextDouble() * span * 1.2,
            width,
            height,
          );
          final LassoRegion region = grid.classifyRect(rect);
          if (region == LassoRegion.boundary) {
            continue;
          }
          decided += 1;
          final bool expected = region == LassoRegion.inside;

          // A decided rectangle must not have the outline running through it —
          // that is exactly what lets an element skip the contact tests.
          for (var s = 0; s < polygon.length; s++) {
            expect(
              _segmentReachesRect(
                polygon[s],
                polygon[(s + 1) % polygon.length],
                rect,
              ),
              isFalse,
              reason: '$name called $rect $region with segment $s crossing it',
            );
          }

          for (final Offset point in _sampleRect(rect)) {
            expect(
              CanvasGeometry.polygonContainsPoint(polygon, point),
              expected,
              reason: '$name called $rect $region but $point disagrees',
            );
          }
        }
        expect(
          decided,
          greaterThan(200),
          reason: '$name decided too few rectangles to be worth the grid',
        );
      }
    });

    test('a rectangle clear of the loop is outside', () {
      final LassoRegionGrid grid = LassoRegionGrid.build(const <Offset>[
        Offset.zero,
        Offset(100, 0),
        Offset(100, 100),
        Offset(0, 100),
      ])!;
      expect(
        grid.classifyRect(const Rect.fromLTWH(500, 500, 10, 10)),
        LassoRegion.outside,
      );
      expect(
        grid.classifyRect(const Rect.fromLTWH(40, 40, 10, 10)),
        LassoRegion.inside,
      );
      expect(
        grid.classifyRect(const Rect.fromLTWH(-10, 40, 30, 10)),
        LassoRegion.boundary,
      );
    });
  });

  group('LassoRegionGrid.segmentRunsNear', () {
    test('keeps every segment that reaches the rectangle', () {
      final math.Random random = math.Random(90210);
      for (final (String name, List<Offset> polygon) in _polygons(random)) {
        final LassoRegionGrid grid = LassoRegionGrid.build(polygon)!;
        final Rect bounds = CanvasGeometry.boundsOfPoints(polygon);
        final double span = math.max(bounds.width, bounds.height);

        for (var i = 0; i < 400; i++) {
          final Rect rect = Rect.fromLTWH(
            bounds.left + random.nextDouble() * bounds.width,
            bounds.top + random.nextDouble() * bounds.height,
            random.nextDouble() * span * 0.25,
            random.nextDouble() * span * 0.25,
          );
          final List<List<Offset>> runs = grid.segmentRunsNear(rect);
          final Set<String> kept = <String>{
            for (final List<Offset> run in runs)
              for (var i = 0; i + 1 < run.length; i++)
                '${run[i]}->${run[i + 1]}',
          };

          for (var s = 0; s < polygon.length; s++) {
            final Offset a = polygon[s];
            final Offset b = polygon[(s + 1) % polygon.length];
            if (!_segmentReachesRect(a, b, rect)) {
              continue;
            }
            expect(
              kept,
              contains('$a->$b'),
              reason: '$name dropped segment $s reaching $rect',
            );
          }
        }
      }
    });

    test('runs are unbroken stretches of the loop, never joined ends', () {
      final math.Random random = math.Random(4242);
      final List<Offset> polygon = _blob(random, vertices: 60);
      final LassoRegionGrid grid = LassoRegionGrid.build(polygon)!;
      final Rect bounds = CanvasGeometry.boundsOfPoints(polygon);

      final List<List<Offset>> runs = grid.segmentRunsNear(
        Rect.fromLTWH(bounds.left, bounds.top, bounds.width, bounds.height / 8),
      );
      expect(runs, isNotEmpty);
      for (final List<Offset> run in runs) {
        expect(run.length, greaterThanOrEqualTo(2));
        for (var i = 0; i + 1 < run.length; i++) {
          final int index = polygon.indexOf(run[i]);
          expect(index, isNonNegative);
          expect(run[i + 1], polygon[(index + 1) % polygon.length]);
        }
      }
    });
  });

  group('LassoRegionGrid.build', () {
    test('declines loops with no area to divide up', () {
      expect(
        LassoRegionGrid.build(const <Offset>[Offset.zero, Offset(10, 10)]),
        isNull,
      );
      expect(
        LassoRegionGrid.build(const <Offset>[
          Offset.zero,
          Offset.zero,
          Offset.zero,
        ]),
        isNull,
      );
      expect(
        LassoRegionGrid.build(const <Offset>[
          Offset(double.nan, 0),
          Offset(10, 0),
          Offset(10, 10),
        ]),
        isNull,
      );
    });

    test('a loop far from the origin still classifies correctly', () {
      // World coordinates drift a long way from zero on a big canvas; the grid
      // must index off its own bounds, not off absolute position.
      const Offset origin = Offset(1250000, -874000);
      final List<Offset> polygon = <Offset>[
        for (final Offset point in _blob(math.Random(7), vertices: 40))
          point + origin,
      ];
      final LassoRegionGrid grid = LassoRegionGrid.build(polygon)!;
      final math.Random random = math.Random(8);
      final Rect bounds = CanvasGeometry.boundsOfPoints(polygon);
      for (var i = 0; i < 2000; i++) {
        final Offset point = Offset(
          bounds.left + random.nextDouble() * bounds.width,
          bounds.top + random.nextDouble() * bounds.height,
        );
        expect(
          grid.containsPoint(point),
          CanvasGeometry.polygonContainsPoint(polygon, point),
          reason: 'disagreed at $point',
        );
      }
    });
  });
}

/// A spread of loop shapes: smooth, spiky, self-crossing and axis-aligned.
List<(String, List<Offset>)> _polygons(math.Random random) {
  return <(String, List<Offset>)>[
    ('blob', _blob(random, vertices: 40)),
    ('spiky blob', _blob(random, vertices: 120, jitter: 0.75)),
    ('self-intersecting scribble', _scribble(random, vertices: 30)),
    ('star', _star(points: 9)),
    (
      'axis-aligned rectangle',
      const <Offset>[
        Offset(-40, -20),
        Offset(260, -20),
        Offset(260, 180),
        Offset(-40, 180),
      ],
    ),
    (
      'comb with horizontal edges',
      <Offset>[
        for (var i = 0; i < 12; i++) ...<Offset>[
          Offset(i * 20.0, 0),
          Offset(i * 20.0, i.isEven ? 120 : 40),
          Offset(i * 20.0 + 10, i.isEven ? 120 : 40),
          Offset(i * 20.0 + 10, 0),
        ],
        const Offset(240, -60),
        const Offset(0, -60),
      ],
    ),
  ];
}

List<Offset> _blob(math.Random random, {required int vertices, double jitter = 0.35}) {
  return <Offset>[
    for (var i = 0; i < vertices; i++)
      () {
        final double angle = 2 * math.pi * i / vertices;
        final double radius = 200 * (1 - jitter + random.nextDouble() * jitter);
        return Offset(
          300 + radius * math.cos(angle),
          250 + radius * math.sin(angle) * 0.8,
        );
      }(),
  ];
}

List<Offset> _scribble(math.Random random, {required int vertices}) {
  return <Offset>[
    for (var i = 0; i < vertices; i++)
      Offset(random.nextDouble() * 400, random.nextDouble() * 300),
  ];
}

List<Offset> _star({required int points}) {
  return <Offset>[
    for (var i = 0; i < points * 2; i++)
      () {
        final double angle = math.pi * i / points;
        final double radius = i.isEven ? 180.0 : 70.0;
        return Offset(200 + radius * math.cos(angle), 200 + radius * math.sin(angle));
      }(),
  ];
}

/// Points across [rect] including its corners, edges and interior.
List<Offset> _sampleRect(Rect rect) {
  const int steps = 4;
  return <Offset>[
    for (var i = 0; i <= steps; i++)
      for (var j = 0; j <= steps; j++)
        Offset(
          rect.left + rect.width * i / steps,
          rect.top + rect.height * j / steps,
        ),
  ];
}

/// Whether segment [a]–[b] touches [rect] at all (endpoints inside count).
bool _segmentReachesRect(Offset a, Offset b, Rect rect) {
  if (_rectContains(rect, a) || _rectContains(rect, b)) {
    return true;
  }
  final List<Offset> corners = <Offset>[
    rect.topLeft,
    rect.topRight,
    rect.bottomRight,
    rect.bottomLeft,
  ];
  for (var i = 0; i < 4; i++) {
    if (_segmentsCross(a, b, corners[i], corners[(i + 1) % 4])) {
      return true;
    }
  }
  return false;
}

bool _rectContains(Rect rect, Offset point) {
  return point.dx >= rect.left &&
      point.dx <= rect.right &&
      point.dy >= rect.top &&
      point.dy <= rect.bottom;
}

bool _segmentsCross(Offset a, Offset b, Offset c, Offset d) {
  double cross(Offset p, Offset q) => p.dx * q.dy - p.dy * q.dx;
  final Offset r = b - a;
  final Offset s = d - c;
  final double denominator = cross(r, s);
  if (denominator == 0) {
    return false;
  }
  final Offset ca = c - a;
  final double t = cross(ca, s) / denominator;
  final double u = cross(ca, r) / denominator;
  return t >= 0 && t <= 1 && u >= 0 && u <= 1;
}
