import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'package:zenno/canvas/tools/canvas_geometry.dart';

/// Where a rectangle sits relative to a committed lasso loop.
enum LassoRegion {
  /// Every point of the rectangle is inside the loop.
  inside,

  /// Every point of the rectangle is outside the loop.
  outside,

  /// The loop's outline passes through the rectangle, so it holds both inside
  /// and outside points and only the exact tests can decide.
  boundary,
}

/// A throwaway uniform grid built over one committed lasso loop.
///
/// A loop drawn around a large mindmap makes the spatial-index broad phase
/// useless — its bounding box covers the whole canvas, so every element became
/// a candidate and ran the full narrow phase against every loop vertex. This
/// grid answers the two questions that narrow phase actually asks, in constant
/// time per element: which side of the loop a rectangle is on, and which loop
/// segments come near it. Elements that are cleanly inside or cleanly outside
/// never touch the geometry at all; the rest test against the handful of local
/// segments instead of the whole loop.
///
/// Results are exact, not approximate. A cell is classified inside/outside only
/// when no loop segment crosses it — and a cell no segment crosses is uniformly
/// one or the other, so its centre decides it. Points in a crossed cell fall
/// back to [CanvasGeometry.polygonContainsPoint], which is also the rule the
/// classification replicates, so the grid and the exact test never disagree.
///
/// Built once per commit and discarded; nothing here is retained between
/// gestures.
class LassoRegionGrid {
  LassoRegionGrid._({
    required List<Offset> polygon,
    required this.bounds,
    required double cellSize,
    required int columns,
    required int rows,
    required Uint8List cells,
    required Int32List boundaryPrefix,
    required Int32List cellSegmentStart,
    required Int32List cellSegmentIds,
  }) : _polygon = polygon,
       _cellSize = cellSize,
       _columns = columns,
       _rows = rows,
       _cells = cells,
       _boundaryPrefix = boundaryPrefix,
       _cellSegmentStart = cellSegmentStart,
       _cellSegmentIds = cellSegmentIds;

  /// Builds a grid over the closed loop through [polygon].
  ///
  /// The loop is implicitly closed: its last vertex links back to its first,
  /// matching [CanvasGeometry.polygonContainsPoint]. Returns `null` for a
  /// degenerate loop (fewer than three vertices, or no area to divide up), in
  /// which case callers should run the exact tests directly.
  static LassoRegionGrid? build(
    List<Offset> polygon, {
    int longAxisCells = _defaultLongAxisCells,
  }) {
    if (polygon.length < 3) {
      return null;
    }
    final Rect bounds = CanvasGeometry.boundsOfPoints(polygon);
    if (!bounds.left.isFinite ||
        !bounds.top.isFinite ||
        !bounds.right.isFinite ||
        !bounds.bottom.isFinite) {
      return null;
    }
    final double span = math.max(bounds.width, bounds.height);
    if (span <= 0) {
      return null;
    }

    final double cellSize = span / longAxisCells;
    final int columns = math.max(1, (bounds.width / cellSize).ceil());
    final int rows = math.max(1, (bounds.height / cellSize).ceil());
    final int cellCount = columns * rows;

    final Uint8List cells = Uint8List(cellCount);
    final Int32List cellSegmentStart = Int32List(cellCount + 1);

    // Pass 1 counts the segments crossing each cell so the crossing lists can
    // live in one flat array instead of a list-per-cell.
    _forEachSegmentCell(
      polygon: polygon,
      bounds: bounds,
      cellSize: cellSize,
      columns: columns,
      rows: rows,
      visit: (int cell, int segment) {
        cells[cell] = _boundaryCell;
        cellSegmentStart[cell + 1] += 1;
      },
    );
    for (var i = 0; i < cellCount; i++) {
      cellSegmentStart[i + 1] += cellSegmentStart[i];
    }
    final Int32List cellSegmentIds = Int32List(cellSegmentStart[cellCount]);
    final Int32List cursor = Int32List.fromList(cellSegmentStart);
    _forEachSegmentCell(
      polygon: polygon,
      bounds: bounds,
      cellSize: cellSize,
      columns: columns,
      rows: rows,
      visit: (int cell, int segment) {
        cellSegmentIds[cursor[cell]++] = segment;
      },
    );

    _classifyCells(
      polygon: polygon,
      bounds: bounds,
      cellSize: cellSize,
      columns: columns,
      rows: rows,
      cells: cells,
    );

    return LassoRegionGrid._(
      polygon: polygon,
      bounds: bounds,
      cellSize: cellSize,
      columns: columns,
      rows: rows,
      cells: cells,
      boundaryPrefix: _buildBoundaryPrefix(
        cells: cells,
        columns: columns,
        rows: rows,
      ),
      cellSegmentStart: cellSegmentStart,
      cellSegmentIds: cellSegmentIds,
    );
  }

  /// Cells along the loop's longer axis. 128 keeps a full grid's bookkeeping
  /// under a few hundred KB while making a typical stroke land in one cell.
  static const int _defaultLongAxisCells = 128;

  static const int _outsideCell = 0;
  static const int _insideCell = 1;
  static const int _boundaryCell = 2;

  /// The loop, implicitly closed. Segment `i` runs from vertex `i` to `i + 1`,
  /// and the last segment closes back to vertex `0`.
  final List<Offset> _polygon;

  /// World-space bounding box of the loop, and of the grid.
  final Rect bounds;

  final double _cellSize;
  final int _columns;
  final int _rows;

  /// One [_outsideCell] / [_insideCell] / [_boundaryCell] entry per cell.
  final Uint8List _cells;

  /// Summed-area table over boundary cells, so "does this rectangle touch the
  /// loop's outline?" is four array reads however large the rectangle is.
  final Int32List _boundaryPrefix;

  /// CSR offsets into [_cellSegmentIds], one entry per cell plus a terminator.
  final Int32List _cellSegmentStart;

  /// Indices of the loop segments crossing each cell, grouped by cell.
  final Int32List _cellSegmentIds;

  /// Whether [point] lies inside the loop, by the even-odd rule.
  ///
  /// Exactly agrees with `CanvasGeometry.polygonContainsPoint(polygon, point)`.
  bool containsPoint(Offset point) {
    if (point.dx < bounds.left ||
        point.dx > bounds.right ||
        point.dy < bounds.top ||
        point.dy > bounds.bottom) {
      // A closed loop encloses nothing outside its own bounding box.
      return false;
    }
    final int cell = _rowOf(point.dy) * _columns + _colOf(point.dx);
    return switch (_cells[cell]) {
      _insideCell => true,
      _outsideCell => false,
      _ => CanvasGeometry.polygonContainsPoint(_polygon, point),
    };
  }

  /// Which side of the loop [rect] is on, or [LassoRegion.boundary] when the
  /// loop's outline runs through it.
  LassoRegion classifyRect(Rect rect) {
    if (rect.right < bounds.left ||
        rect.left > bounds.right ||
        rect.bottom < bounds.top ||
        rect.top > bounds.bottom) {
      return LassoRegion.outside;
    }
    final int c0 = _colOf(math.max(rect.left, bounds.left));
    final int c1 = _colOf(math.min(rect.right, bounds.right));
    final int r0 = _rowOf(math.max(rect.top, bounds.top));
    final int r1 = _rowOf(math.min(rect.bottom, bounds.bottom));
    if (_boundaryCountIn(c0, r0, c1, r1) > 0) {
      return LassoRegion.boundary;
    }
    // No segment crosses any covered cell, so the whole covered area is one
    // connected region and any single cell speaks for all of them.
    if (_cells[r0 * _columns + c0] != _insideCell) {
      return LassoRegion.outside;
    }
    final bool reachesBeyondLoop =
        rect.left < bounds.left ||
        rect.right > bounds.right ||
        rect.top < bounds.top ||
        rect.bottom > bounds.bottom;
    return reachesBeyondLoop ? LassoRegion.boundary : LassoRegion.inside;
  }

  /// The stretches of the loop that pass through [rect], as open polylines.
  ///
  /// Any loop segment coming within reach of a shape inside [rect] is in one of
  /// these runs, so proximity tests against the returned polylines give the same
  /// answer as testing the whole loop — for a fraction of the segment pairs.
  /// Consecutive segments stay joined; separate passes come back as separate
  /// polylines so no phantom edge is created between them.
  List<List<Offset>> segmentRunsNear(Rect rect) {
    if (rect.right < bounds.left ||
        rect.left > bounds.right ||
        rect.bottom < bounds.top ||
        rect.top > bounds.bottom) {
      return const <List<Offset>>[];
    }
    final int c0 = _colOf(math.max(rect.left, bounds.left));
    final int c1 = _colOf(math.min(rect.right, bounds.right));
    final int r0 = _rowOf(math.max(rect.top, bounds.top));
    final int r1 = _rowOf(math.min(rect.bottom, bounds.bottom));

    final int count = _polygon.length;
    final Uint8List near = Uint8List(count);
    var found = 0;
    for (var r = r0; r <= r1; r++) {
      final int rowStart = r * _columns;
      for (var c = c0; c <= c1; c++) {
        final int cell = rowStart + c;
        for (
          var i = _cellSegmentStart[cell];
          i < _cellSegmentStart[cell + 1];
          i++
        ) {
          final int segment = _cellSegmentIds[i];
          if (near[segment] == 0) {
            near[segment] = 1;
            found += 1;
          }
        }
      }
    }
    if (found == 0) {
      return const <List<Offset>>[];
    }

    final List<List<Offset>> runs = <List<Offset>>[];
    var start = 0;
    while (start < count) {
      if (near[start] == 0) {
        start += 1;
        continue;
      }
      var end = start;
      while (end + 1 < count && near[end + 1] == 1) {
        end += 1;
      }
      runs.add(<Offset>[
        for (var i = start; i <= end + 1; i++) _polygon[i % count],
      ]);
      start = end + 1;
    }
    return runs;
  }

  int _boundaryCountIn(int c0, int r0, int c1, int r1) {
    final int stride = _columns + 1;
    return _boundaryPrefix[(r1 + 1) * stride + (c1 + 1)] -
        _boundaryPrefix[r0 * stride + (c1 + 1)] -
        _boundaryPrefix[(r1 + 1) * stride + c0] +
        _boundaryPrefix[r0 * stride + c0];
  }

  int _colOf(double x) {
    final int column = ((x - bounds.left) / _cellSize).floor();
    return column < 0
        ? 0
        : column > _columns - 1
        ? _columns - 1
        : column;
  }

  int _rowOf(double y) {
    final int row = ((y - bounds.top) / _cellSize).floor();
    return row < 0
        ? 0
        : row > _rows - 1
        ? _rows - 1
        : row;
  }

  /// Visits every (cell, segment) pair where the segment crosses the cell.
  ///
  /// Each segment is clipped to one row band at a time; within a band the
  /// segment's x range is contiguous, so the columns it spans are exactly the
  /// cells it passes through. Endpoints are nudged by a hair so a segment
  /// running precisely along a cell edge marks both neighbours — that keeps the
  /// invariant the classification relies on: an unmarked cell has no segment
  /// anywhere in it, edges included.
  static void _forEachSegmentCell({
    required List<Offset> polygon,
    required Rect bounds,
    required double cellSize,
    required int columns,
    required int rows,
    required void Function(int cell, int segment) visit,
  }) {
    final int count = polygon.length;
    final double slack = cellSize * 1e-9;
    for (var segment = 0; segment < count; segment++) {
      final Offset a = polygon[segment];
      final Offset b = polygon[(segment + 1) % count];
      final double minY = math.min(a.dy, b.dy);
      final double maxY = math.max(a.dy, b.dy);
      final int r0 = _indexOf(minY - slack, bounds.top, cellSize, rows);
      final int r1 = _indexOf(maxY + slack, bounds.top, cellSize, rows);
      for (var r = r0; r <= r1; r++) {
        final double bandTop = bounds.top + r * cellSize;
        final double bandBottom = bandTop + cellSize;
        double lowX;
        double highX;
        if (a.dy == b.dy) {
          lowX = math.min(a.dx, b.dx);
          highX = math.max(a.dx, b.dx);
        } else {
          final double span = b.dy - a.dy;
          final double tTop = ((bandTop - a.dy) / span).clamp(0.0, 1.0);
          final double tBottom = ((bandBottom - a.dy) / span).clamp(0.0, 1.0);
          final double xTop = a.dx + (b.dx - a.dx) * tTop;
          final double xBottom = a.dx + (b.dx - a.dx) * tBottom;
          lowX = math.min(xTop, xBottom);
          highX = math.max(xTop, xBottom);
        }
        final int c0 = _indexOf(lowX - slack, bounds.left, cellSize, columns);
        final int c1 = _indexOf(highX + slack, bounds.left, cellSize, columns);
        final int rowStart = r * columns;
        for (var c = c0; c <= c1; c++) {
          visit(rowStart + c, segment);
        }
      }
    }
  }

  /// Decides inside/outside for every cell no segment crosses.
  ///
  /// One even-odd scanline per row, at the row's centre. Only the segments that
  /// span the row contribute crossings, so the whole pass costs about what the
  /// rasterisation above does rather than rows x segments.
  static void _classifyCells({
    required List<Offset> polygon,
    required Rect bounds,
    required double cellSize,
    required int columns,
    required int rows,
    required Uint8List cells,
  }) {
    final int count = polygon.length;
    final List<List<int>> segmentsByRow = List<List<int>>.generate(
      rows,
      (_) => <int>[],
      growable: false,
    );
    for (var segment = 0; segment < count; segment++) {
      final Offset a = polygon[segment];
      final Offset b = polygon[(segment + 1) % count];
      final int r0 = _indexOf(
        math.min(a.dy, b.dy),
        bounds.top,
        cellSize,
        rows,
      );
      final int r1 = _indexOf(
        math.max(a.dy, b.dy),
        bounds.top,
        cellSize,
        rows,
      );
      for (var r = r0; r <= r1; r++) {
        segmentsByRow[r].add(segment);
      }
    }

    final List<double> crossings = <double>[];
    for (var r = 0; r < rows; r++) {
      final double y = bounds.top + (r + 0.5) * cellSize;
      crossings.clear();
      for (final int segment in segmentsByRow[r]) {
        // Same orientation as CanvasGeometry.polygonContainsPoint, which walks
        // edges as (previous, current) — so the crossing arithmetic, and any
        // floating-point tie it lands on, matches exactly.
        final Offset vi = polygon[(segment + 1) % count];
        final Offset vj = polygon[segment];
        if ((vi.dy > y) != (vj.dy > y)) {
          crossings.add(
            (vj.dx - vi.dx) * (y - vi.dy) / (vj.dy - vi.dy) + vi.dx,
          );
        }
      }
      crossings.sort();

      final int rowStart = r * columns;
      // Crossings and cell centres both advance left to right, so one shared
      // walk classifies the whole row.
      var next = 0;
      for (var c = 0; c < columns; c++) {
        final double x = bounds.left + (c + 0.5) * cellSize;
        while (next < crossings.length && crossings[next] <= x) {
          next += 1;
        }
        if (cells[rowStart + c] == _boundaryCell) {
          continue;
        }
        final bool inside = (crossings.length - next).isOdd;
        cells[rowStart + c] = inside ? _insideCell : _outsideCell;
      }
    }
  }

  static Int32List _buildBoundaryPrefix({
    required Uint8List cells,
    required int columns,
    required int rows,
  }) {
    final int stride = columns + 1;
    final Int32List prefix = Int32List(stride * (rows + 1));
    for (var r = 0; r < rows; r++) {
      var rowSum = 0;
      final int rowStart = r * columns;
      final int outRow = (r + 1) * stride;
      final int previousRow = r * stride;
      for (var c = 0; c < columns; c++) {
        if (cells[rowStart + c] == _boundaryCell) {
          rowSum += 1;
        }
        prefix[outRow + c + 1] = prefix[previousRow + c + 1] + rowSum;
      }
    }
    return prefix;
  }

  static int _indexOf(double value, double origin, double cellSize, int limit) {
    final int index = ((value - origin) / cellSize).floor();
    return index < 0
        ? 0
        : index > limit - 1
        ? limit - 1
        : index;
  }
}
