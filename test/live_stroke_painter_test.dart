import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/render/live_stroke_painter.dart';

void main() {
  test('long live strokes rebuild only a bounded tail', () {
    final LiveStrokePathCache cache = LiveStrokePathCache();
    final List<StrokePoint> points = List<StrokePoint>.generate(
      1000,
      (int index) => StrokePoint(
        index.toDouble(),
        (index % 17).toDouble(),
        0.25 + (index % 50) / 100,
        tiltX: index / 1000,
        tiltY: -index / 2000,
        azimuth: index / 500,
        timestampMicros: index * 1000,
        velocity: index / 10,
      ),
    );
    final Stroke stroke = Stroke(
      id: 'long-live-stroke',
      points: points,
      color: 0xFFFFFFFF,
      width: 4,
    );

    final path = cache.pathFor(stroke: stroke, revision: 1, viewportScale: 1);

    expect(cache.lastRebuiltPointCount, lessThan(256));
    expect(stroke.points, same(points));
    for (var index = 64; index < points.length - 64; index += 64) {
      expect(path.contains(points[index].offset), isTrue);
    }

    final List<StrokePoint> appended = <StrokePoint>[
      ...points,
      const StrokePoint(
        1000,
        14,
        0.75,
        tiltX: 1,
        tiltY: -0.5,
        azimuth: 2,
        timestampMicros: 1000000,
        velocity: 100,
      ),
    ];
    cache.pathFor(
      stroke: stroke.copyWith(points: appended),
      revision: 2,
      viewportScale: 1,
    );

    expect(cache.lastRebuiltPointCount, lessThan(256));
    expect(points, hasLength(1000));
    expect(points.last.timestampMicros, 999000);
    expect(appended.last.tiltX, 1);
    expect(appended.last.velocity, 100);
  });

  test('fill preview keeps its exact source boundary', () {
    final LiveStrokePathCache cache = LiveStrokePathCache();
    final List<StrokePoint> points = <StrokePoint>[
      const StrokePoint(0, 0, 0.1, timestampMicros: 1),
      const StrokePoint(100, 0, 0.2, timestampMicros: 2),
      const StrokePoint(100, 100, 0.3, timestampMicros: 3),
      const StrokePoint(0, 100, 0.4, timestampMicros: 4),
    ];
    final List<StrokePoint> before = List<StrokePoint>.of(points);

    cache.pathFor(
      stroke: Stroke(
        id: 'fill',
        points: points,
        color: 0xFFFFFFFF,
        width: 4,
        tool: StrokeToolKind.fill,
      ),
      revision: 1,
      viewportScale: 1,
    );

    expect(points, before);
    expect(cache.lastRebuiltPointCount, points.length);
  });
}
