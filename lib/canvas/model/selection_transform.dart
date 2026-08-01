import 'dart:math' as math;

import 'package:flutter/widgets.dart';

@immutable
class SelectionTransformPreview {
  const SelectionTransformPreview({
    required this.origin,
    required this.translation,
    required this.scale,
    required this.rotation,
  });

  const SelectionTransformPreview.identity()
    : origin = Offset.zero,
      translation = Offset.zero,
      scale = 1,
      rotation = 0;

  final Offset origin;
  final Offset translation;
  final double scale;
  final double rotation;

  bool get isChanged =>
      (scale - 1).abs() > 0.000001 ||
      rotation.abs() > 0.000001 ||
      translation.distance > 0.000001;

  Offset transformPoint(Offset point) {
    final double scaledX = (point.dx - origin.dx) * scale;
    final double scaledY = (point.dy - origin.dy) * scale;
    if (rotation == 0) {
      return Offset(
        origin.dx + scaledX + translation.dx,
        origin.dy + scaledY + translation.dy,
      );
    }
    final double sin = math.sin(rotation);
    final double cos = math.cos(rotation);
    return Offset(
      origin.dx + scaledX * cos - scaledY * sin + translation.dx,
      origin.dy + scaledX * sin + scaledY * cos + translation.dy,
    );
  }

  Rect transformRect(Rect rect) {
    final List<Offset> corners = <Offset>[
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ].map(transformPoint).toList(growable: false);

    double left = corners.first.dx;
    double right = corners.first.dx;
    double top = corners.first.dy;
    double bottom = corners.first.dy;
    for (final Offset corner in corners.skip(1)) {
      if (corner.dx < left) left = corner.dx;
      if (corner.dx > right) right = corner.dx;
      if (corner.dy < top) top = corner.dy;
      if (corner.dy > bottom) bottom = corner.dy;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  void applyToCanvas(Canvas canvas) {
    canvas.transform(toMatrix().storage);
  }

  /// This preview as a world-space matrix.
  ///
  /// The same transform [applyToCanvas] applies, in a form the render layer can
  /// re-express in screen space — which is how a selection is moved by shifting
  /// an already-painted layer instead of repainting it.
  Matrix4 toMatrix() {
    return Matrix4.identity()
      ..translateByDouble(
        origin.dx + translation.dx,
        origin.dy + translation.dy,
        0,
        1,
      )
      ..rotateZ(rotation)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-origin.dx, -origin.dy, 0, 1);
  }

  @override
  bool operator ==(Object other) {
    return other is SelectionTransformPreview &&
        other.origin == origin &&
        other.translation == translation &&
        other.scale == scale &&
        other.rotation == rotation;
  }

  @override
  int get hashCode => Object.hash(origin, translation, scale, rotation);
}
