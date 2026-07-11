import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/tools/arrow_geometry.dart';

/// Shared committed/live renderer for geometric canvas shapes.
void paintShapeElement(
  Canvas canvas,
  ShapeElement element, {
  required bool selected,
  Color selectionHalo = const Color(0x55E8B84B),
}) {
  final Paint paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = element.strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = Color(element.color);
  switch (element.shapeKind) {
    case 0:
      canvas.drawLine(element.start, element.end, paint);
    case 1:
      canvas.drawRect(Rect.fromPoints(element.start, element.end), paint);
    case 2:
      canvas.drawOval(Rect.fromPoints(element.start, element.end), paint);
    case 3:
      _paintArrow(canvas, element, paint);
    default:
      canvas.drawLine(element.start, element.end, paint);
  }
  if (selected) {
    canvas.drawRect(
      element.worldBounds,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = selectionHalo,
    );
  }
}

void _paintArrow(Canvas canvas, ShapeElement element, Paint paint) {
  final Offset delta = element.end - element.start;
  final double length = delta.distance;
  if (length == 0) {
    return;
  }

  if (element.legacyArrow) {
    _paintLegacyArrow(canvas, element, paint);
    return;
  }

  final Path body = ArrowGeometry.bodyPath(
    body: element.arrowBody,
    start: element.start,
    end: element.end,
    controls: element.controlPoints,
    strokeWidth: element.strokeWidth,
  );
  canvas.drawPath(body, paint);

  final double headLength = ArrowGeometry.styledHeadLength(
    strokeWidth: element.strokeWidth,
    headScale: element.arrowHeadScale,
    maxLength: length,
  );
  _paintHead(
    canvas,
    tip: element.end,
    direction: ArrowGeometry.endTangent(
      body: element.arrowBody,
      start: element.start,
      end: element.end,
      controls: element.controlPoints,
      strokeWidth: element.strokeWidth,
    ),
    style: element.arrowEndHead,
    length: headLength,
    paint: paint,
  );
  _paintHead(
    canvas,
    tip: element.start,
    direction: -ArrowGeometry.startTangent(
      body: element.arrowBody,
      start: element.start,
      end: element.end,
      controls: element.controlPoints,
      strokeWidth: element.strokeWidth,
    ),
    style: element.arrowStartHead,
    length: headLength,
    paint: paint,
  );
}

void _paintLegacyArrow(Canvas canvas, ShapeElement element, Paint paint) {
  final Offset delta = element.end - element.start;
  final double length = delta.distance;
  if (length == 0) {
    return;
  }
  final double angle = math.atan2(delta.dy, delta.dx);
  final double headLength = ArrowGeometry.legacyHeadLength(
    element.start,
    element.end,
  );
  const double headAngle = math.pi / 7;
  final Offset left = Offset(
    element.end.dx - headLength * math.cos(angle - headAngle),
    element.end.dy - headLength * math.sin(angle - headAngle),
  );
  final Offset right = Offset(
    element.end.dx - headLength * math.cos(angle + headAngle),
    element.end.dy - headLength * math.sin(angle + headAngle),
  );
  canvas.drawLine(element.start, element.end, paint);
  final Path head = Path()
    ..moveTo(element.end.dx, element.end.dy)
    ..lineTo(left.dx, left.dy)
    ..lineTo(right.dx, right.dy)
    ..close();
  canvas.drawPath(head, Paint()..color = Color(element.color));
}

void _paintHead(
  Canvas canvas, {
  required Offset tip,
  required Offset direction,
  required ArrowHeadStyle style,
  required double length,
  required Paint paint,
}) {
  if (style == ArrowHeadStyle.none || length <= 0) {
    return;
  }
  final double directionLength = direction.distance;
  if (directionLength == 0) {
    return;
  }
  final Offset unit = direction / directionLength;
  final Offset normal = Offset(-unit.dy, unit.dx);
  final double wing = length * 0.48;
  final Offset base = tip - unit * length;
  final Offset left = base + normal * wing;
  final Offset right = base - normal * wing;

  switch (style) {
    case ArrowHeadStyle.none:
      return;
    case ArrowHeadStyle.open:
      final Path path = Path()
        ..moveTo(left.dx, left.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(right.dx, right.dy);
      canvas.drawPath(path, paint);
    case ArrowHeadStyle.filled:
      final Path path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = paint.color);
    case ArrowHeadStyle.dot:
      canvas.drawCircle(tip, length * 0.28, Paint()..color = paint.color);
    case ArrowHeadStyle.diamond:
      final Offset center = tip - unit * (length * 0.48);
      final Offset tail = tip - unit * (length * 0.96);
      final Path path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(
          (center + normal * wing * 0.75).dx,
          (center + normal * wing * 0.75).dy,
        )
        ..lineTo(tail.dx, tail.dy)
        ..lineTo(
          (center - normal * wing * 0.75).dx,
          (center - normal * wing * 0.75).dy,
        )
        ..close();
      canvas.drawPath(path, paint);
    case ArrowHeadStyle.bar:
      canvas.drawLine(tip + normal * wing, tip - normal * wing, paint);
  }
}
