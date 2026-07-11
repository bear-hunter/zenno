import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/tools/arrow_geometry.dart';

void main() {
  test('styled head size follows stroke width before arrow length', () {
    final thin = ArrowGeometry.styledHeadLength(
      strokeWidth: 1,
      headScale: 1,
      maxLength: 500,
    );
    final thick = ArrowGeometry.styledHeadLength(
      strokeWidth: 10,
      headScale: 1,
      maxLength: 500,
    );

    expect(thin, 8);
    expect(thick, greaterThan(thin));
    expect(thick, lessThanOrEqualTo(30));
  });

  test('styled head size is capped for very short arrows', () {
    final size = ArrowGeometry.styledHeadLength(
      strokeWidth: 20,
      headScale: 2,
      maxLength: 20,
    );

    expect(size, lessThanOrEqualTo(9.6));
  });

  test('legacy head length preserves previous length-based sizing', () {
    final size = ArrowGeometry.legacyHeadLength(
      Offset.zero,
      const Offset(100, 0),
    );

    expect(size, 22);
  });

  test('curved arrow tangent follows the control point at each end', () {
    const start = Offset(0, 0);
    const control = Offset(40, 80);
    const end = Offset(100, 10);

    final startTangent = ArrowGeometry.startTangent(
      body: ArrowBodyKind.curved,
      start: start,
      end: end,
      controls: const <Offset>[control],
      strokeWidth: 4,
    );
    final endTangent = ArrowGeometry.endTangent(
      body: ArrowBodyKind.curved,
      start: start,
      end: end,
      controls: const <Offset>[control],
      strokeWidth: 4,
    );

    expect(startTangent, control - start);
    expect(endTangent, end - control);
  });

  test('elbow path includes the configured bend point', () {
    const start = Offset(0, 0);
    const bend = Offset(100, 0);
    const end = Offset(100, 80);

    final path = ArrowGeometry.bodyPath(
      body: ArrowBodyKind.elbow,
      start: start,
      end: end,
      controls: const <Offset>[bend],
      strokeWidth: 4,
    );

    expect(path.getBounds(), const Rect.fromLTWH(0, 0, 100, 80));
  });
}
