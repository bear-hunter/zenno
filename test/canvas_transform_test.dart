import 'dart:math' as math;

// `painting.dart` is imported for `MatrixUtils`, which `widgets.dart` omits;
// it also supplies `Offset`.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/engine/canvas_transform.dart';
import 'package:zenno/canvas/model/viewport_state.dart';

/// Asserts that two [Offset]s are equal within [epsilon] on both axes.
void expectOffsetClose(
  Offset actual,
  Offset expected, {
  double epsilon = 1e-6,
}) {
  expect(
    actual.dx,
    closeTo(expected.dx, epsilon),
    reason: 'dx of $actual vs $expected',
  );
  expect(
    actual.dy,
    closeTo(expected.dy, epsilon),
    reason: 'dy of $actual vs $expected',
  );
}

void main() {
  // A spread of viewports: identity, panned, zoomed in/out, rotated, and a
  // combined pan + zoom + rotation. These exercise every term of the matrix.
  const List<ViewportState> viewports = <ViewportState>[
    ViewportState.initial,
    ViewportState(translation: Offset(120, -75)),
    ViewportState(scale: 3.5),
    ViewportState(scale: 0.1),
    ViewportState(rotation: math.pi / 6),
    ViewportState(translation: Offset(-340, 512), scale: 2.25, rotation: -1.1),
    ViewportState(translation: Offset(64, 64), scale: 0.37, rotation: 2.7),
  ];

  // Sample world points, including the origin, negatives, and large values.
  const List<Offset> worldPoints = <Offset>[
    Offset.zero,
    Offset(10, 20),
    Offset(-150, 87),
    Offset(2048, -2048),
    Offset(-9999.5, 12345.25),
  ];

  group('toWorld / toScreen round-trip', () {
    test('toWorld(toScreen(p)) ~= p for every viewport and point', () {
      for (final ViewportState vp in viewports) {
        for (final Offset world in worldPoints) {
          final Offset screen = CanvasTransform.toScreen(vp, world);
          final Offset back = CanvasTransform.toWorld(vp, screen);
          // Large coordinates lose absolute precision; use a relative-ish
          // epsilon generous enough for the ~12k-magnitude sample.
          expectOffsetClose(back, world, epsilon: 1e-3);
        }
      }
    });

    test('toScreen(toWorld(p)) ~= p for every viewport and point', () {
      for (final ViewportState vp in viewports) {
        for (final Offset screen in worldPoints) {
          final Offset world = CanvasTransform.toWorld(vp, screen);
          final Offset back = CanvasTransform.toScreen(vp, world);
          expectOffsetClose(back, screen, epsilon: 1e-3);
        }
      }
    });

    test('identity viewport maps world to the same screen point', () {
      const Offset p = Offset(42, -17);
      expectOffsetClose(CanvasTransform.toScreen(ViewportState.initial, p), p);
    });

    test('pure translation offsets the point by the translation', () {
      const ViewportState vp = ViewportState(translation: Offset(100, 50));
      expectOffsetClose(
        CanvasTransform.toScreen(vp, const Offset(10, 10)),
        const Offset(110, 60),
      );
    });

    test('pure scale multiplies world coordinates', () {
      const ViewportState vp = ViewportState(scale: 4);
      expectOffsetClose(
        CanvasTransform.toScreen(vp, const Offset(10, -5)),
        const Offset(40, -20),
      );
    });
  });

  group('worldToScreenMatrix', () {
    test('is consistent with toScreen', () {
      const ViewportState vp = ViewportState(
        translation: Offset(33, 44),
        scale: 1.8,
        rotation: 0.6,
      );
      const Offset world = Offset(70, -25);
      final Offset viaMatrix = MatrixUtils.transformPoint(
        CanvasTransform.worldToScreenMatrix(vp),
        world,
      );
      expectOffsetClose(viaMatrix, CanvasTransform.toScreen(vp, world));
    });
  });

  group('zoomAround', () {
    test('keeps the world anchor pinned under the focus point', () {
      const Offset focus = Offset(400, 300);
      for (final ViewportState vp in viewports) {
        for (final double factor in <double>[0.5, 1.0, 1.7, 5.0]) {
          // World point under the focus before zooming.
          final Offset worldAnchorBefore = CanvasTransform.toWorld(vp, focus);
          final ViewportState result = CanvasTransform.zoomAround(
            current: vp,
            focusScreen: focus,
            scaleFactor: factor,
          );
          // That same world point must still land on the focus afterwards.
          final Offset focusAfter = CanvasTransform.toScreen(
            result,
            worldAnchorBefore,
          );
          expectOffsetClose(focusAfter, focus, epsilon: 1e-3);
        }
      }
    });

    test('applies the scale factor when within bounds', () {
      const ViewportState vp = ViewportState(scale: 2);
      final ViewportState result = CanvasTransform.zoomAround(
        current: vp,
        focusScreen: const Offset(10, 10),
        scaleFactor: 3,
      );
      expect(result.scale, closeTo(6, 1e-9));
    });

    test('clamps scale at the maximum and still pins the anchor', () {
      const Offset focus = Offset(123, 456);
      const ViewportState vp = ViewportState(scale: 32);
      final Offset worldAnchorBefore = CanvasTransform.toWorld(vp, focus);
      final ViewportState result = CanvasTransform.zoomAround(
        current: vp,
        focusScreen: focus,
        scaleFactor: 100, // 32 * 100 would be 3200, well past maxScale.
      );
      expect(result.scale, CanvasTransform.maxScale);
      expectOffsetClose(
        CanvasTransform.toScreen(result, worldAnchorBefore),
        focus,
        epsilon: 1e-3,
      );
    });

    test('does not change rotation', () {
      const ViewportState vp = ViewportState(rotation: 0.9);
      final ViewportState result = CanvasTransform.zoomAround(
        current: vp,
        focusScreen: Offset.zero,
        scaleFactor: 2,
      );
      expect(result.rotation, vp.rotation);
    });
  });

  group('interactiveUpdate', () {
    test('keeps the start anchor under the current focus point', () {
      const ViewportState start = ViewportState(
        translation: Offset(50, -30),
        scale: 1.5,
        rotation: 0.3,
      );
      const Offset anchorAtStart = Offset(200, 150);
      const Offset currentFocus = Offset(260, 110);
      final Offset worldAnchor = CanvasTransform.toWorld(start, anchorAtStart);

      final ViewportState result = CanvasTransform.interactiveUpdate(
        start: start,
        anchorScreenAtStart: anchorAtStart,
        currentFocusScreen: currentFocus,
        scaleFactor: 1.4,
        rotationDelta: 0.5,
      );

      expect(result.scale, closeTo(start.scale * 1.4, 1e-9));
      expect(result.rotation, closeTo(start.rotation + 0.5, 1e-9));
      expectOffsetClose(
        CanvasTransform.toScreen(result, worldAnchor),
        currentFocus,
        epsilon: 1e-3,
      );
    });

    test('clamps scale and still pins the anchor', () {
      const ViewportState start = ViewportState(scale: 0.05);
      const Offset anchorAtStart = Offset(80, 80);
      const Offset currentFocus = Offset(80, 80);
      final Offset worldAnchor = CanvasTransform.toWorld(start, anchorAtStart);

      final ViewportState result = CanvasTransform.interactiveUpdate(
        start: start,
        anchorScreenAtStart: anchorAtStart,
        currentFocusScreen: currentFocus,
        scaleFactor: 0.1, // 0.05 * 0.1 = 0.005, below minScale.
        rotationDelta: 0,
      );

      expect(result.scale, CanvasTransform.minScale);
      expectOffsetClose(
        CanvasTransform.toScreen(result, worldAnchor),
        currentFocus,
        epsilon: 1e-3,
      );
    });
  });

  group('panBy', () {
    test('adds the screen delta to translation', () {
      const ViewportState vp = ViewportState(translation: Offset(10, 20));
      final ViewportState result = CanvasTransform.panBy(
        vp,
        const Offset(5, -8),
      );
      expect(result.translation, const Offset(15, 12));
    });

    test('leaves scale and rotation untouched', () {
      const ViewportState vp = ViewportState(scale: 2.5, rotation: 1.2);
      final ViewportState result = CanvasTransform.panBy(
        vp,
        const Offset(100, 100),
      );
      expect(result.scale, vp.scale);
      expect(result.rotation, vp.rotation);
    });
  });

  group('clampScale', () {
    test('clamps below the minimum', () {
      expect(CanvasTransform.clampScale(0.0001), CanvasTransform.minScale);
    });

    test('clamps above the maximum', () {
      expect(CanvasTransform.clampScale(1000), CanvasTransform.maxScale);
    });

    test('leaves an in-range value unchanged', () {
      expect(CanvasTransform.clampScale(1.5), 1.5);
    });

    test('passes the exact bounds through', () {
      expect(
        CanvasTransform.clampScale(CanvasTransform.minScale),
        CanvasTransform.minScale,
      );
      expect(
        CanvasTransform.clampScale(CanvasTransform.maxScale),
        CanvasTransform.maxScale,
      );
    });
  });

  group('snapScale', () {
    test('snaps a value just below a stop', () {
      // 0.98 is within 6% of the stop 1.0.
      expect(CanvasTransform.snapScale(0.98), 1.0);
    });

    test('snaps a value just above a stop', () {
      // 2.05 is within 6% of the stop 2.0.
      expect(CanvasTransform.snapScale(2.05), 2.0);
    });

    test('snaps near a fractional stop', () {
      // 0.255 is within 6% of the stop 0.25.
      expect(CanvasTransform.snapScale(0.255), 0.25);
    });

    test('leaves a far value alone', () {
      // 1.5 is exactly between stops 1 and 2 — outside 6% of either.
      expect(CanvasTransform.snapScale(1.5), 1.5);
    });

    test('leaves a value just outside tolerance alone', () {
      // 1.07 is > 6% from stop 1.0 and far from stop 2.0.
      expect(CanvasTransform.snapScale(1.07), 1.07);
    });

    test('returns an exact stop unchanged', () {
      expect(CanvasTransform.snapScale(4.0), 4.0);
    });

    test('respects a custom tolerance', () {
      // 1.15 is outside the default 6% but inside a 20% tolerance.
      expect(CanvasTransform.snapScale(1.15), 1.15);
      expect(CanvasTransform.snapScale(1.15, tolerancePercent: 0.2), 1.0);
    });
  });

  group('ViewportState', () {
    test('copyWith replaces only the given fields', () {
      const ViewportState vp = ViewportState(
        translation: Offset(1, 2),
        scale: 3,
        rotation: 0.4,
      );
      final ViewportState scaled = vp.copyWith(scale: 9);
      expect(scaled.scale, 9);
      expect(scaled.translation, vp.translation);
      expect(scaled.rotation, vp.rotation);
    });

    test('value equality and hashCode', () {
      const ViewportState a = ViewportState(
        translation: Offset(5, 6),
        scale: 2,
        rotation: 1,
      );
      const ViewportState b = ViewportState(
        translation: Offset(5, 6),
        scale: 2,
        rotation: 1,
      );
      const ViewportState c = ViewportState(
        translation: Offset(5, 6),
        scale: 2,
        rotation: 1.5,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('initial is the identity viewport', () {
      expect(ViewportState.initial.translation, Offset.zero);
      expect(ViewportState.initial.scale, 1.0);
      expect(ViewportState.initial.rotation, 0.0);
    });
  });
}
