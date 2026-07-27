import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart' hide StrokePoint;

import 'package:zenno/canvas/engine/stroke_builder.dart';
import 'package:zenno/canvas/engine/stroke_style.dart';
import 'package:zenno/canvas/model/stroke.dart';

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
  test('stroke outline uses continuous curves between outline samples', () {
    const points = <StrokePoint>[
      StrokePoint(0, 0, 0.35),
      StrokePoint(16, 6, 0.5),
      StrokePoint(28, 22, 0.75),
      StrokePoint(44, 15, 0.6),
      StrokePoint(60, 32, 0.45),
    ];
    final StrokeToolStyle style = strokeStyleFor(StrokeToolKind.pen);
    final options = StrokeOptions(
      size: 8,
      thinning: style.thinning,
      smoothing: style.smoothing,
      streamline: 0,
      simulatePressure: false,
      isComplete: true,
      start: StrokeEndOptions.start(
        cap: style.cap,
        taperEnabled: style.tapers,
        customTaper: style.taperLengthFactor * 8,
      ),
      end: StrokeEndOptions.end(
        cap: style.cap,
        taperEnabled: style.tapers,
        customTaper: style.taperLengthFactor * 8,
      ),
    );
    final List<Offset> outline = getStroke(<PointVector>[
      for (final point in points) PointVector(point.x, point.y, point.pressure),
    ], options: options);
    final Path path = buildStrokeOutline(
      points,
      size: options.size,
      isComplete: options.isComplete,
    );

    final PathMetric metric = path.computeMetrics().single;
    final Set<int> tangentAngles = <int>{};
    final int sampleCount = outline.length * 8;
    for (var i = 0; i < sampleCount; i += 1) {
      final Tangent? tangent = metric.getTangentForOffset(
        metric.length * i / sampleCount,
      );
      if (tangent != null) {
        tangentAngles.add((tangent.angle * 10000 / math.pi).round());
      }
    }

    expect(tangentAngles.length, greaterThan(outline.length));
  });

  test('a thin stroke stays inside its sampled centerline bounds', () {
    const points = <StrokePoint>[
      StrokePoint(0, 0, 0.5),
      StrokePoint(10, 0, 0.5),
      StrokePoint(20, 0, 0.5),
      StrokePoint(30, -40, 0.5),
    ];

    // The highlighter is the constant-width, untapered tool, so the outline
    // can only be as wide as `size` around the centerline.
    final Path path = buildStrokeOutline(
      points,
      size: 0.1,
      tool: StrokeToolKind.highlighter,
      isComplete: true,
    );

    expect(path.getBounds().bottom, lessThanOrEqualTo(0.1));
  });

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

  group('per-tool stroke styles', () {
    test('a highlighter ignores pressure and a pen does not', () {
      List<StrokePoint> atPressure(double pressure) => <StrokePoint>[
        for (int i = 0; i < 30; i++) StrokePoint(i * 6.0, 0, pressure),
      ];

      double widthOf(StrokeToolKind tool, double pressure) => buildStrokeOutline(
        atPressure(pressure),
        size: 12,
        tool: tool,
      ).getBounds().height;

      // A chisel tip lays the same band however hard it is pressed; a nib
      // responds to pressure. The tools used to share one thinning value.
      expect(
        widthOf(StrokeToolKind.highlighter, 0.15),
        closeTo(widthOf(StrokeToolKind.highlighter, 1), 0.01),
      );
      expect(
        widthOf(StrokeToolKind.pen, 1),
        greaterThan(widthOf(StrokeToolKind.pen, 0.15) + 1),
      );
    });

    test('only the tools that should taper do', () {
      expect(strokeStyleFor(StrokeToolKind.pen).tapers, isTrue);
      expect(strokeStyleFor(StrokeToolKind.highlighter).tapers, isFalse);
      expect(strokeStyleFor(StrokeToolKind.marker).tapers, isFalse);
    });

    test('a tapered pen stroke narrows at its ends', () {
      final List<StrokePoint> even = <StrokePoint>[
        for (int i = 0; i < 40; i++) StrokePoint(i * 6.0, 0, 1),
      ];
      final Path path = buildStrokeOutline(
        even,
        size: 14,
        tool: StrokeToolKind.pen,
        isComplete: true,
      );

      // Sample the outline near an end and near the middle: at constant
      // pressure any narrowing at the tip comes from the taper.
      final Rect bounds = path.getBounds();
      expect(path.contains(Offset(bounds.center.dx, 0)), isTrue);
      expect(path.contains(Offset(bounds.left + 0.5, 6)), isFalse);
    });
  });
}
