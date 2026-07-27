import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/input/pointer_classifier.dart';

PointerDownEvent _down({
  PointerDeviceKind kind = PointerDeviceKind.stylus,
  double pressure = 0.5,
  double pressureMin = 0,
  double pressureMax = 1,
}) => PointerDownEvent(
  kind: kind,
  pressure: pressure,
  pressureMin: pressureMin,
  pressureMax: pressureMax,
);

void main() {
  group('classifyPointer', () {
    test('both stylus orientations drive the active tool', () {
      // The eraser end of an S Pen arrives as invertedStylus and must still
      // be treated as a pen, not as an unhandled device.
      expect(
        classifyPointer(_down(kind: PointerDeviceKind.stylus)),
        CanvasInputKind.stylus,
      );
      expect(
        classifyPointer(_down(kind: PointerDeviceKind.invertedStylus)),
        CanvasInputKind.stylus,
      );
    });

    test('a finger is touch', () {
      expect(
        classifyPointer(_down(kind: PointerDeviceKind.touch)),
        CanvasInputKind.touch,
      );
    });

    test('mouse and trackpad share the tool-following path', () {
      expect(
        classifyPointer(_down(kind: PointerDeviceKind.mouse)),
        CanvasInputKind.mouse,
      );
      // Flutter forbids a trackpad PointerDownEvent, so classify a hover.
      expect(
        classifyPointer(
          const PointerHoverEvent(kind: PointerDeviceKind.trackpad),
        ),
        CanvasInputKind.mouse,
      );
    });

    test('an unrecognised device falls through rather than drawing', () {
      expect(
        classifyPointer(_down(kind: PointerDeviceKind.unknown)),
        CanvasInputKind.unknown,
      );
    });
  });

  group('normalizedPressure', () {
    test('rescales a device range onto 0..1', () {
      expect(
        normalizedPressure(
          _down(pressure: 0.5, pressureMin: 0, pressureMax: 1),
        ),
        closeTo(0.5, 1e-9),
      );
      expect(
        normalizedPressure(
          _down(pressure: 0.6, pressureMin: 0.4, pressureMax: 0.8),
        ),
        closeTo(0.5, 1e-9),
      );
    });

    test('clamps readings outside the reported range', () {
      expect(
        normalizedPressure(
          _down(pressure: 2, pressureMin: 0, pressureMax: 1),
        ),
        1,
      );
      expect(
        normalizedPressure(
          _down(pressure: -1, pressureMin: 0, pressureMax: 1),
        ),
        0,
      );
    });

    test('a device without pressure reports a neutral half', () {
      // pressureMin == pressureMax means no pressure sensor. Dividing by that
      // zero range would yield NaN and produce an invisible stroke.
      final double value = normalizedPressure(
        _down(pressure: 1, pressureMin: 1, pressureMax: 1),
      );
      expect(value, 0.5);
      expect(value.isNaN, isFalse);
    });
  });

  group('hasStylusButton', () {
    test('detects either side button', () {
      expect(hasStylusButton(kPrimaryStylusButton), isTrue);
      expect(hasStylusButton(kSecondaryStylusButton), isTrue);
      expect(
        hasStylusButton(kPrimaryStylusButton | kSecondaryStylusButton),
        isTrue,
      );
    });

    test('ignores buttons that are not the stylus barrel', () {
      expect(hasStylusButton(0), isFalse);
      expect(hasStylusButton(kPrimaryMouseButton), isFalse);
    });
  });
}
