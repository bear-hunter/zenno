import 'dart:ui' show Rect, Size;

import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/render/selection_overlay_geometry.dart';

void main() {
  test(
    'compact edge layout keeps every selection action independently hittable',
    () {
      final SelectionOverlayGeometry geometry =
          SelectionOverlayGeometry.fromWorldBounds(
            bounds: const Rect.fromLTWH(280, -10, 20, 20),
            viewport: ViewportState.initial,
            canvasSize: const Size(320, 600),
          );

      final List<SelectionOverlayTarget> actions = <SelectionOverlayTarget>[
        SelectionOverlayTarget.rotation,
        SelectionOverlayTarget.done,
        SelectionOverlayTarget.copy,
        SelectionOverlayTarget.paste,
        SelectionOverlayTarget.delete,
      ];
      for (final SelectionOverlayTarget action in actions) {
        expect(geometry.hitTest(geometry.centerFor(action)), action);
      }
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
    expect(geometry.copyCenter.dx, greaterThan(320));
    expect(geometry.pasteCenter.dx, greaterThan(320));
    expect(geometry.deleteCenter.dx, greaterThan(320));
  });
}
