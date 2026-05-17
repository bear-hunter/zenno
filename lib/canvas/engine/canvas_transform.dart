import 'dart:math' as math;

// `widgets.dart` provides `Offset`, `Matrix4` and `MatrixUtils`.
import 'package:flutter/widgets.dart';

import 'package:zenno/canvas/model/viewport_state.dart';

/// Pure static math for mapping between world space and screen space, and for
/// the pan / zoom / rotate operations that drive the infinite canvas.
///
/// The world-to-screen mapping is
/// `M = Translate(translation) · RotateZ(rotation) · Scale(scale)`, so a world
/// point `w` is placed on screen at `Rotate(rotation)·Scale(scale)·w +
/// translation`. Every method here is a pure function of its inputs — there is
/// no instance state — which keeps the engine trivially testable and lets the
/// render layer call into it freely.
abstract final class CanvasTransform {
  /// Smallest permitted viewport [ViewportState.scale].
  static const double minScale = 0.02;

  /// Largest permitted viewport [ViewportState.scale].
  static const double maxScale = 64.0;

  /// Discrete zoom stops that [snapScale] is allowed to snap to.
  static const List<double> _snapStops = <double>[
    0.125,
    0.25,
    0.5,
    1,
    2,
    4,
    8,
    16,
  ];

  /// Builds the world-to-screen [Matrix4] for [vp].
  ///
  /// Composed as translate → rotateZ → scale so that, read right-to-left, a
  /// world point is scaled, then rotated, then translated into screen space.
  static Matrix4 worldToScreenMatrix(ViewportState vp) {
    return Matrix4.identity()
      ..translateByDouble(vp.translation.dx, vp.translation.dy, 0, 1)
      ..rotateZ(vp.rotation)
      ..scaleByDouble(vp.scale, vp.scale, 1, 1);
  }

  /// Maps a [world] point into screen space under [vp].
  static Offset toScreen(ViewportState vp, Offset world) {
    return MatrixUtils.transformPoint(worldToScreenMatrix(vp), world);
  }

  /// Maps a [screen] point back into world space under [vp].
  ///
  /// Uses the inverse of [worldToScreenMatrix]; the transform is always
  /// invertible because [ViewportState.scale] is clamped strictly positive.
  static Offset toWorld(ViewportState vp, Offset screen) {
    final Matrix4 inverse = Matrix4.inverted(worldToScreenMatrix(vp));
    return MatrixUtils.transformPoint(inverse, screen);
  }

  /// Clamps [scale] to the `[minScale, maxScale]` range.
  static double clampScale(double scale) {
    return scale.clamp(minScale, maxScale);
  }

  /// Snaps [scale] to a nearby zoom stop if it is within [tolerancePercent].
  ///
  /// If [scale] lies within `tolerancePercent` (relative, default 6%) of one
  /// of the stops `{0.125, 0.25, 0.5, 1, 2, 4, 8, 16}` it is rounded to that
  /// stop; otherwise [scale] is returned unchanged. Used on gesture end so a
  /// pinch settles cleanly on a round zoom level.
  static double snapScale(double scale, {double tolerancePercent = 0.06}) {
    for (final double stop in _snapStops) {
      if ((scale - stop).abs() <= stop * tolerancePercent) {
        return stop;
      }
    }
    return scale;
  }

  /// Pans [current] by [screenDelta] (a translation in screen pixels).
  static ViewportState panBy(ViewportState current, Offset screenDelta) {
    return current.copyWith(
      translation: current.translation + screenDelta,
    );
  }

  /// Zooms [current] by [scaleFactor] while keeping the world point currently
  /// under [focusScreen] pinned to that same screen position.
  ///
  /// The new scale is clamped, so passing a [scaleFactor] that would exceed
  /// `[minScale, maxScale]` simply saturates without breaking the anchor.
  static ViewportState zoomAround({
    required ViewportState current,
    required Offset focusScreen,
    required double scaleFactor,
  }) {
    final Offset worldAnchor = toWorld(current, focusScreen);
    final double newScale = clampScale(current.scale * scaleFactor);
    final Offset newTranslation =
        focusScreen -
        _rotateThenScale(worldAnchor, current.rotation, newScale);
    return current.copyWith(scale: newScale, translation: newTranslation);
  }

  /// Applies a two-finger pinch/rotate gesture to the [start] viewport.
  ///
  /// [anchorScreenAtStart] is the gesture focal point measured against the
  /// viewport as it was when the gesture began; [currentFocusScreen] is the
  /// focal point now. [scaleFactor] and [rotationDelta] are cumulative since
  /// the gesture started. The world point under the original focal point is
  /// kept under the current focal point, giving stable pinch-to-zoom and twist.
  static ViewportState interactiveUpdate({
    required ViewportState start,
    required Offset anchorScreenAtStart,
    required Offset currentFocusScreen,
    required double scaleFactor,
    required double rotationDelta,
  }) {
    final Offset worldAnchor = toWorld(start, anchorScreenAtStart);
    final double newScale = clampScale(start.scale * scaleFactor);
    final double newRotation = start.rotation + rotationDelta;
    final Offset newTranslation =
        currentFocusScreen -
        _rotateThenScale(worldAnchor, newRotation, newScale);
    return ViewportState(
      translation: newTranslation,
      scale: newScale,
      rotation: newRotation,
    );
  }

  /// Applies "rotate by [rotation] then scale by [scale]" to world point [w].
  ///
  /// This is the linear (translation-free) part of the world-to-screen map:
  /// `Offset(s·(x·cos r − y·sin r), s·(x·sin r + y·cos r))`.
  static Offset _rotateThenScale(Offset w, double rotation, double scale) {
    final double cos = math.cos(rotation);
    final double sin = math.sin(rotation);
    return Offset(
      scale * (w.dx * cos - w.dy * sin),
      scale * (w.dx * sin + w.dy * cos),
    );
  }
}
