import 'package:flutter/widgets.dart';

/// An immutable description of the canvas viewport — the camera through which
/// the infinite world is observed on screen.
///
/// The world-to-screen mapping is built from these three fields as
/// `Translate(translation) · RotateZ(rotation) · Scale(scale)`. A world point
/// `w` therefore lands on screen at `Rotate(rotation)·Scale(scale)·w +
/// translation`. See `CanvasTransform` for the concrete matrix math.
@immutable
class ViewportState {
  /// Creates a viewport from its [translation], [scale] and [rotation].
  const ViewportState({
    this.translation = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  /// Screen-space translation applied after rotation and scaling.
  final Offset translation;

  /// World-to-screen zoom factor (`1.0` = world units map 1:1 to logical px).
  final double scale;

  /// Rotation of the world about the origin, in radians.
  final double rotation;

  /// The identity viewport: no translation, unit scale, no rotation.
  static const ViewportState initial = ViewportState();

  /// Returns a copy of this viewport with the given fields replaced.
  ViewportState copyWith({
    Offset? translation,
    double? scale,
    double? rotation,
  }) {
    return ViewportState(
      translation: translation ?? this.translation,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ViewportState &&
        other.translation == translation &&
        other.scale == scale &&
        other.rotation == rotation;
  }

  @override
  int get hashCode => Object.hash(translation, scale, rotation);

  @override
  String toString() =>
      'ViewportState(translation: $translation, scale: $scale, '
      'rotation: $rotation)';
}
