import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show PointMode;

import 'package:flutter/rendering.dart';
import 'package:zenno/canvas/engine/canvas_transform.dart';
import 'package:zenno/canvas/model/canvas_style.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/core/database/tables/canvas_tables.dart';

/// Cached world-space pattern tiles for the paper background.
///
/// The paper texture and the dot grid are deterministic, periodic patterns —
/// yet they used to be regenerated point by point on every frame of every pan:
/// per cell a hash, trigonometry, and a world→screen projection, five figures
/// of operations per frame for a background that never changes. Instead the
/// pattern is recorded once into a [ui.Picture] tile in world space and
/// stamped across the visible rect under the canvas transform, so a pan costs
/// the GPU a handful of picture replays and the CPU nothing.
///
/// Owned by the view (like the elements tile cache) so pictures survive
/// painter instances; each slot re-records only when its key — pattern kind,
/// step, colour, opacity — changes, which happens on zoom-bucket crossings and
/// style edits, never during a pan.
class BackgroundPatternCache {
  ui.Picture? _texturePicture;
  Object? _textureKey;
  ui.Picture? _gridPicture;
  Object? _gridKey;

  ui.Picture _texture(Object key, ui.Picture Function() record) {
    if (_textureKey != key) {
      _texturePicture?.dispose();
      _texturePicture = record();
      _textureKey = key;
    }
    return _texturePicture!;
  }

  ui.Picture _grid(Object key, ui.Picture Function() record) {
    if (_gridKey != key) {
      _gridPicture?.dispose();
      _gridPicture = record();
      _gridKey = key;
    }
    return _gridPicture!;
  }

  /// Releases native picture resources.
  void dispose() {
    _texturePicture?.dispose();
    _texturePicture = null;
    _textureKey = null;
    _gridPicture?.dispose();
    _gridPicture = null;
    _gridKey = null;
  }
}

/// Stamps [picture] (a `tileWorld`-sized world-space tile) across the visible
/// world rect of [viewport].
///
/// The canvas gets the world→screen transform once; each tile is a translate
/// and a picture replay. Tile size tracks the pattern step, which the painters
/// keep proportional to the screen, so the stamp count is bounded by the
/// screen and never explodes at overview zoom.
void _stampTiles({
  required Canvas canvas,
  required Size size,
  required ViewportState viewport,
  required double tileWorld,
  required ui.Picture picture,
}) {
  final Rect world = _visibleWorldBounds(viewport, size);
  final int minTx = (world.left / tileWorld).floor();
  final int maxTx = (world.right / tileWorld).floor();
  final int minTy = (world.top / tileWorld).floor();
  final int maxTy = (world.bottom / tileWorld).floor();

  canvas.save();
  canvas.transform(CanvasTransform.worldToScreenMatrix(viewport).storage);
  for (int ty = minTy; ty <= maxTy; ty += 1) {
    for (int tx = minTx; tx <= maxTx; tx += 1) {
      canvas.save();
      canvas.translate(tx * tileWorld, ty * tileWorld);
      canvas.drawPicture(picture);
      canvas.restore();
    }
  }
  canvas.restore();
}

/// Paints a deterministic, world-anchored paper surface beneath the guide grid.
class PaperTexturePainter extends CustomPainter {
  const PaperTexturePainter({
    required this.viewport,
    required this.style,
    this.cache,
  });

  final ViewportState viewport;
  final CanvasPaperStyle style;

  /// Optional pattern-tile cache owned by the view; without one the tile is
  /// re-recorded per paint (still correct, just not reused across frames).
  final BackgroundPatternCache? cache;

  /// Cells per recorded tile; also the period of the (wrapped) cell hash.
  ///
  /// A power of two so `& (_cellsPerTile - 1)` wraps negative cell indices
  /// correctly. The texture repeats every 32 cells — at ≤0.3 alpha and
  /// dash-sized marks the repetition is imperceptible, and it is what lets one
  /// recorded tile cover the whole plane.
  static const int _cellsPerTile = 32;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty ||
        viewport.scale <= 0 ||
        style.texture == PaperTexture.clean ||
        style.textureOpacity <= 0) {
      return;
    }

    final double step = _textureStep(viewport.scale);
    final Object key = Object.hash(
      style.texture,
      step,
      style.gridColor,
      style.textureOpacity,
    );
    final ui.Picture picture = cache == null
        ? _recordTile(step)
        : cache!._texture(key, () => _recordTile(step));
    _stampTiles(
      canvas: canvas,
      size: size,
      viewport: viewport,
      tileWorld: step * _cellsPerTile,
      picture: picture,
    );
    if (cache == null) {
      picture.dispose();
    }
  }

  /// Records one tile of the texture in tile-local world coordinates.
  ///
  /// Cells in a one-cell margin around the tile are drawn too (clipped to the
  /// tile), so a mark that straddles a tile border is completed by the
  /// neighbouring stamp — the wrapped hash guarantees both tiles agree on it.
  ui.Picture _recordTile(double step) {
    final recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double tileWorld = step * _cellsPerTile;
    canvas.clipRect(Rect.fromLTWH(0, 0, tileWorld, tileWorld));

    final Paint paint = Paint()
      ..color = Color(
        style.gridColor,
      ).withValues(alpha: style.textureOpacity.clamp(0.0, 0.3))
      // World-space width: the mark scales with the paper like real grain,
      // ~1 screen px at the spacing the step search maintains.
      ..strokeWidth = step / 20
      ..strokeCap = StrokeCap.round;

    if (style.texture == PaperTexture.grain) {
      final List<Offset> points = <Offset>[];
      for (int x = -1; x <= _cellsPerTile; x++) {
        for (int y = -1; y <= _cellsPerTile; y++) {
          final int hash = _paperHash(
            x & (_cellsPerTile - 1),
            y & (_cellsPerTile - 1),
          );
          points.add(
            Offset(
              (x + 0.12 + _hashUnit(hash, 0) * 0.76) * step,
              (y + 0.12 + _hashUnit(hash, 8) * 0.76) * step,
            ),
          );
        }
      }
      canvas.drawPoints(PointMode.points, points, paint..strokeWidth = step / 14);
      return recorder.endRecording();
    }

    for (int x = -1; x <= _cellsPerTile; x++) {
      for (int y = -1; y <= _cellsPerTile; y++) {
        final int hash = _paperHash(
          x & (_cellsPerTile - 1),
          y & (_cellsPerTile - 1),
        );
        final Offset anchor = Offset(
          (x + 0.18 + _hashUnit(hash, 0) * 0.64) * step,
          (y + 0.18 + _hashUnit(hash, 8) * 0.64) * step,
        );
        final double angle = switch (style.texture) {
          PaperTexture.fibers => (_hashUnit(hash, 16) - 0.5) * 0.18,
          PaperTexture.crosshatch =>
            (hash & 1) == 0 ? math.pi / 4 : -math.pi / 4,
          PaperTexture.clean || PaperTexture.grain => 0,
        };
        final double length = step * (0.24 + _hashUnit(hash, 20) * 0.3);
        final Offset direction = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(
          anchor - direction * (length / 2),
          anchor + direction * (length / 2),
          paint,
        );
      }
    }
    return recorder.endRecording();
  }

  double _textureStep(double scale) {
    double step = 16;
    while (step * scale < 14) {
      step *= 2;
    }
    while (step * scale > 28 && step > 1) {
      step /= 2;
    }
    return step;
  }

  static int _paperHash(int x, int y) {
    int value = (x * 374761393) ^ (y * 668265263);
    value = (value ^ (value >> 13)) * 1274126177;
    return (value ^ (value >> 16)) & 0x7FFFFFFF;
  }

  static double _hashUnit(int hash, int shift) =>
      ((hash >> shift) & 0xFF) / 255;

  @override
  bool shouldRepaint(PaperTexturePainter oldDelegate) =>
      oldDelegate.viewport != viewport || oldDelegate.style != style;
}

/// Paints an infinite dotted grid that stays fixed in world space.
///
/// The grid step is chosen from powers of two so the on-screen dot spacing
/// (`step * viewport.scale`) stays roughly within a comfortable 32–96 logical
/// pixel band regardless of zoom. The dot lattice is stamped from a cached
/// world-space picture tile (see [BackgroundPatternCache]); the line variants
/// draw a bounded number of lines per frame and stay direct.
class GridPainter extends CustomPainter {
  /// Creates a grid painter for the given [viewport].
  const GridPainter({required this.viewport, required this.style, this.cache});

  /// The camera through which the world grid is observed.
  final ViewportState viewport;
  final CanvasPaperStyle style;

  /// Optional pattern-tile cache owned by the view.
  final BackgroundPatternCache? cache;

  /// Lower bound of the desired on-screen dot spacing, in logical pixels.
  static const double _minSpacing = 32;

  /// Upper bound of the desired on-screen dot spacing, in logical pixels.
  static const double _maxSpacing = 96;

  /// Smallest world-space grid step considered when searching for a fit.
  static const double _minStep = 1;

  /// Largest world-space grid step considered when searching for a fit.
  static const double _maxStep = 1048576.0;

  /// Dots per recorded lattice tile.
  static const int _dotsPerTile = 16;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || viewport.scale <= 0) {
      return;
    }

    final Rect world = _visibleWorldBounds(viewport, size);
    final double minX = world.left;
    final double maxX = world.right;
    final double minY = world.top;
    final double maxY = world.bottom;

    if (style.kind == BackgroundKind.blank) {
      return;
    }

    final step = _gridStep(viewport.scale, style.gridSpacing);

    // Snap the world rect outwards to the grid so the first/last lines of dots
    // are still drawn when they sit just off the visible edge.
    final startX = (minX / step).floorToDouble() * step;
    final startY = (minY / step).floorToDouble() * step;

    final Color color = Color(
      style.gridColor,
    ).withValues(alpha: style.gridOpacity.clamp(0.0, 1.0));
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    if (style.kind == BackgroundKind.lined) {
      for (var y = startY; y <= maxY; y += step) {
        canvas.drawLine(
          CanvasTransform.toScreen(viewport, Offset(minX, y)),
          CanvasTransform.toScreen(viewport, Offset(maxX, y)),
          paint,
        );
      }
      return;
    }

    if (style.kind == BackgroundKind.grid) {
      final majorEvery = style.graphMajorInterval <= 1
          ? 0
          : style.graphMajorInterval;
      for (var x = startX; x <= maxX; x += step) {
        final major = majorEvery > 0 && ((x / step).round() % majorEvery == 0);
        canvas.drawLine(
          CanvasTransform.toScreen(viewport, Offset(x, minY)),
          CanvasTransform.toScreen(viewport, Offset(x, maxY)),
          paint..strokeWidth = major ? 1.5 : 1,
        );
      }
      for (var y = startY; y <= maxY; y += step) {
        final major = majorEvery > 0 && ((y / step).round() % majorEvery == 0);
        canvas.drawLine(
          CanvasTransform.toScreen(viewport, Offset(minX, y)),
          CanvasTransform.toScreen(viewport, Offset(maxX, y)),
          paint..strokeWidth = major ? 1.5 : 1,
        );
      }
      return;
    }

    if (style.kind == BackgroundKind.isometric) {
      _drawLineFamily(canvas, minX, maxX, minY, maxY, step, math.pi / 2, paint);
      _drawLineFamily(canvas, minX, maxX, minY, maxY, step, math.pi / 6, paint);
      _drawLineFamily(
        canvas,
        minX,
        maxX,
        minY,
        maxY,
        step,
        -math.pi / 6,
        paint,
      );
      return;
    }

    if (style.kind == BackgroundKind.triangle) {
      _drawLineFamily(canvas, minX, maxX, minY, maxY, step, 0, paint);
      _drawLineFamily(canvas, minX, maxX, minY, maxY, step, math.pi / 3, paint);
      _drawLineFamily(
        canvas,
        minX,
        maxX,
        minY,
        maxY,
        step,
        -math.pi / 3,
        paint,
      );
      return;
    }

    // Dot lattice: strictly periodic, so one recorded tile covers the plane.
    // Building thousands of projected offsets per pan frame is what this
    // replaces.
    final Object key = Object.hash('dots', step, color.toARGB32());
    final ui.Picture picture = cache == null
        ? _recordDotTile(step, color)
        : cache!._grid(key, () => _recordDotTile(step, color));
    _stampTiles(
      canvas: canvas,
      size: size,
      viewport: viewport,
      tileWorld: step * _dotsPerTile,
      picture: picture,
    );
    if (cache == null) {
      picture.dispose();
    }
  }

  ui.Picture _recordDotTile(double step, Color color) {
    final recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double tileWorld = step * _dotsPerTile;
    canvas.clipRect(Rect.fromLTWH(0, 0, tileWorld, tileWorld));
    final List<Offset> points = <Offset>[
      for (int x = 0; x < _dotsPerTile; x++)
        for (int y = 0; y < _dotsPerTile; y++) Offset(x * step, y * step),
    ];
    canvas.drawPoints(
      PointMode.points,
      points,
      Paint()
        ..color = color
        // World-space dot size, ~2 px at mid-band spacing — the dots breathe
        // slightly with zoom inside a step bucket, like printed graph paper.
        ..strokeWidth = step / 24
        ..strokeCap = StrokeCap.round,
    );
    return recorder.endRecording();
  }

  /// Picks a power-of-two world step whose on-screen spacing falls within the
  /// `[_minSpacing, _maxSpacing]` band for the given [scale].
  ///
  /// Starts at the smallest candidate step and doubles until the projected
  /// spacing reaches `_minSpacing`; the search is clamped to `[_minStep,
  /// _maxStep]` so extreme zoom levels still yield a sane step.
  double _gridStep(double scale, double preferredStep) {
    var step = preferredStep.clamp(_minStep, _maxStep).toDouble();
    while (step * scale < _minSpacing && step < _maxStep) {
      step *= 2;
    }
    while (step * scale > _maxSpacing && step > _minStep) {
      step /= 2;
    }
    return step;
  }

  void _drawLineFamily(
    Canvas canvas,
    double minX,
    double maxX,
    double minY,
    double maxY,
    double step,
    double angle,
    Paint paint,
  ) {
    final Offset direction = Offset(math.cos(angle), math.sin(angle));
    final Offset normal = Offset(-direction.dy, direction.dx);
    final List<Offset> corners = <Offset>[
      Offset(minX, minY),
      Offset(maxX, minY),
      Offset(maxX, maxY),
      Offset(minX, maxY),
    ];
    double minProjection = _dot(corners.first, normal);
    double maxProjection = minProjection;
    for (final Offset corner in corners.skip(1)) {
      final double projection = _dot(corner, normal);
      minProjection = math.min(minProjection, projection);
      maxProjection = math.max(maxProjection, projection);
    }

    final double extent =
        math.sqrt(math.pow(maxX - minX, 2) + math.pow(maxY - minY, 2)) + step;
    final double start = (minProjection / step).floorToDouble() * step;
    for (
      double projection = start;
      projection <= maxProjection;
      projection += step
    ) {
      final Offset anchor = normal * projection;
      canvas.drawLine(
        CanvasTransform.toScreen(viewport, anchor - direction * extent),
        CanvasTransform.toScreen(viewport, anchor + direction * extent),
        paint,
      );
    }
  }

  static double _dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

  @override
  bool shouldRepaint(GridPainter oldDelegate) =>
      oldDelegate.viewport != viewport || oldDelegate.style != style;
}

Rect _visibleWorldBounds(ViewportState viewport, Size size) {
  final List<Offset> corners = <Offset>[
    CanvasTransform.toWorld(viewport, Offset.zero),
    CanvasTransform.toWorld(viewport, Offset(size.width, 0)),
    CanvasTransform.toWorld(viewport, Offset(0, size.height)),
    CanvasTransform.toWorld(viewport, Offset(size.width, size.height)),
  ];
  double minX = corners.first.dx;
  double maxX = corners.first.dx;
  double minY = corners.first.dy;
  double maxY = corners.first.dy;
  for (final Offset corner in corners.skip(1)) {
    minX = math.min(minX, corner.dx);
    maxX = math.max(maxX, corner.dx);
    minY = math.min(minY, corner.dy);
    maxY = math.max(maxY, corner.dy);
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}
