import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/engine/spatial_index.dart';

/// Returns the [SpatialIndex.query] result for [viewport] as a sorted list, so
/// assertions are order-independent (the index does not promise an order).
List<String> sortedQuery(SpatialIndex index, Rect viewport) {
  final List<String> ids = index.query(viewport).toList()..sort();
  return ids;
}

void main() {
  group('SpatialIndex — basic insert / query', () {
    test('query returns exactly the ids intersecting the viewport', () {
      final SpatialIndex index = SpatialIndex();
      // A scatter of well-separated rectangles.
      index.insert('a', const Rect.fromLTWH(0, 0, 10, 10));
      index.insert('b', const Rect.fromLTWH(100, 100, 20, 20));
      index.insert('c', const Rect.fromLTWH(-50, -50, 10, 10));
      index.insert('d', const Rect.fromLTWH(500, 500, 40, 40));

      // A viewport that overlaps only 'a' and 'b'.
      expect(sortedQuery(index, const Rect.fromLTWH(5, 5, 110, 110)), <String>[
        'a',
        'b',
      ]);

      // A viewport around 'c' only.
      expect(
        sortedQuery(index, const Rect.fromLTWH(-60, -60, 30, 30)),
        <String>['c'],
      );

      // A viewport covering everything.
      expect(
        sortedQuery(index, const Rect.fromLTWH(-1000, -1000, 4000, 4000)),
        <String>['a', 'b', 'c', 'd'],
      );

      // A viewport in empty space hits nothing.
      expect(
        sortedQuery(index, const Rect.fromLTWH(2000, 2000, 50, 50)),
        isEmpty,
      );
    });

    test('edge-touching rectangles count as intersecting', () {
      final SpatialIndex index = SpatialIndex();
      index.insert('touch', const Rect.fromLTWH(0, 0, 10, 10));
      // A viewport whose left edge exactly meets the element's right edge.
      expect(sortedQuery(index, const Rect.fromLTWH(10, 0, 10, 10)), <String>[
        'touch',
      ]);
    });

    test('query reports length, isEmpty and boundsOf', () {
      final SpatialIndex index = SpatialIndex();
      expect(index.isEmpty, isTrue);
      expect(index.isNotEmpty, isFalse);
      expect(index.length, 0);

      const Rect bounds = Rect.fromLTWH(3, 4, 5, 6);
      index.insert('x', bounds);
      expect(index.isEmpty, isFalse);
      expect(index.length, 1);
      expect(index.boundsOf('x'), bounds);
      expect(index.boundsOf('missing'), isNull);
    });
  });

  group('SpatialIndex — remove', () {
    test('removed ids no longer appear in query results', () {
      final SpatialIndex index = SpatialIndex();
      index.insert('a', const Rect.fromLTWH(0, 0, 10, 10));
      index.insert('b', const Rect.fromLTWH(20, 0, 10, 10));
      index.insert('c', const Rect.fromLTWH(40, 0, 10, 10));

      const Rect wide = Rect.fromLTWH(-10, -10, 100, 100);
      expect(sortedQuery(index, wide), <String>['a', 'b', 'c']);

      index.remove('b');
      expect(sortedQuery(index, wide), <String>['a', 'c']);
      expect(index.length, 2);
      expect(index.boundsOf('b'), isNull);

      index.remove('a');
      index.remove('c');
      expect(sortedQuery(index, wide), isEmpty);
      expect(index.isEmpty, isTrue);
    });

    test('removing an unknown id is a harmless no-op', () {
      final SpatialIndex index = SpatialIndex();
      index.insert('a', const Rect.fromLTWH(0, 0, 10, 10));
      index.remove('does-not-exist');
      expect(index.length, 1);
      expect(sortedQuery(index, const Rect.fromLTWH(-5, -5, 50, 50)), <String>[
        'a',
      ]);
    });
  });

  group('SpatialIndex — clear and rebuild', () {
    test('clear empties the index', () {
      final SpatialIndex index = SpatialIndex();
      index.insert('a', const Rect.fromLTWH(0, 0, 10, 10));
      index.insert('b', const Rect.fromLTWH(50, 50, 10, 10));
      index.clear();
      expect(index.isEmpty, isTrue);
      expect(index.length, 0);
      expect(index.query(const Rect.fromLTWH(-100, -100, 1000, 1000)), isEmpty);
    });

    test('rebuild replaces all entries', () {
      final SpatialIndex index = SpatialIndex();
      index.insert('old', const Rect.fromLTWH(0, 0, 10, 10));
      index.rebuild(<MapEntry<String, Rect>>[
        const MapEntry<String, Rect>('p', Rect.fromLTWH(0, 0, 5, 5)),
        const MapEntry<String, Rect>('q', Rect.fromLTWH(200, 200, 5, 5)),
      ]);
      expect(index.length, 2);
      const Rect all = Rect.fromLTWH(-50, -50, 500, 500);
      expect(sortedQuery(index, all), <String>['p', 'q']);
    });
  });

  group('SpatialIndex — upsert and growth', () {
    test('re-inserting an id replaces its bounds', () {
      final SpatialIndex index = SpatialIndex();
      index.insert('m', const Rect.fromLTWH(0, 0, 10, 10));
      // Move it far away by re-inserting under the same id.
      index.insert('m', const Rect.fromLTWH(1000, 1000, 10, 10));

      expect(index.length, 1);
      // No longer at the old location.
      expect(index.query(const Rect.fromLTWH(-5, -5, 30, 30)), isEmpty);
      // Found at the new location.
      expect(
        sortedQuery(index, const Rect.fromLTWH(990, 990, 50, 50)),
        <String>['m'],
      );
    });

    test('grows the root region to hold far-flung inserts', () {
      final SpatialIndex index = SpatialIndex();
      // First insert seeds a root around the origin; later inserts land far
      // outside it, forcing the root to grow in every direction.
      index.insert('origin', const Rect.fromLTWH(0, 0, 10, 10));
      index.insert('far-pos', const Rect.fromLTWH(100000, 100000, 10, 10));
      index.insert('far-neg', const Rect.fromLTWH(-80000, -90000, 10, 10));

      expect(index.length, 3);
      expect(
        sortedQuery(
          index,
          const Rect.fromLTWH(-200000, -200000, 500000, 500000),
        ),
        <String>['far-neg', 'far-pos', 'origin'],
      );
      // A tight viewport still isolates a single far entry.
      expect(
        sortedQuery(index, const Rect.fromLTWH(99990, 99990, 50, 50)),
        <String>['far-pos'],
      );
    });

    test('handles many entries that force node subdivision', () {
      final SpatialIndex index = SpatialIndex();
      // A 12x12 grid of small rectangles, far more than a node's capacity,
      // so the quadtree must subdivide repeatedly.
      for (var row = 0; row < 12; row++) {
        for (var col = 0; col < 12; col++) {
          index.insert(
            'r${row}c$col',
            Rect.fromLTWH(col * 100.0, row * 100.0, 20, 20),
          );
        }
      }
      expect(index.length, 144);

      // A viewport covering exactly the 2x2 block of cells (0,0)-(1,1).
      final List<String> hits = sortedQuery(
        index,
        const Rect.fromLTWH(0, 0, 120, 120),
      );
      expect(hits, <String>['r0c0', 'r0c1', 'r1c0', 'r1c1']);

      // A whole-grid viewport returns every entry.
      expect(
        index.query(const Rect.fromLTWH(-50, -50, 2000, 2000)).length,
        144,
      );

      // Remove one cell and confirm it drops out.
      index.remove('r0c0');
      expect(sortedQuery(index, const Rect.fromLTWH(0, 0, 120, 120)), <String>[
        'r0c1',
        'r1c0',
        'r1c1',
      ]);
    });
  });
}
