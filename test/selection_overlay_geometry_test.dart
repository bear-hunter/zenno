import 'dart:ui' show Rect, Size;

import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/render/selection_overlay_geometry.dart';

void main() {
  test(
    'compact edge layout keeps Done and rotation independently hittable',
    () {
      final SelectionOverlayGeometry geometry =
          SelectionOverlayGeometry.fromWorldBounds(
            bounds: const Rect.fromLTWH(280, -10, 20, 20),
            viewport: ViewportState.initial,
            canvasSize: const Size(320, 600),
          );

      expect(
        (geometry.doneCenter - geometry.rotationCenter).distance,
        greaterThanOrEqualTo(SelectionOverlayGeometry.handleHitSize),
      );
      expect(
        geometry.hitTest(geometry.doneCenter),
        SelectionOverlayTarget.done,
      );
      expect(
        geometry.hitTest(geometry.rotationCenter),
        SelectionOverlayTarget.rotation,
      );
    },
  );

  test('offscreen selections do not pin stray actions to a screen edge', () {
    final SelectionOverlayGeometry geometry =
        SelectionOverlayGeometry.fromWorldBounds(
          bounds: const Rect.fromLTWH(1000, 1000, 100, 100),
          viewport: ViewportState.initial,
          canvasSize: const Size(320, 600),
        );

    expect(geometry.rotationCenter.dx, greaterThan(320));
    expect(geometry.doneCenter.dx, greaterThan(320));
  });
}
