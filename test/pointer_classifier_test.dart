import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/input/pointer_classifier.dart';

void main() {
  test('recognizes Android palm size reports', () {
    const PointerDownEvent event = PointerDownEvent(
      kind: PointerDeviceKind.touch,
      size: 0.3,
    );

    expect(isLikelyPalmContact(event), isTrue);
  });

  test('recognizes a broad contact ellipse when size is unavailable', () {
    const PointerDownEvent event = PointerDownEvent(
      kind: PointerDeviceKind.touch,
      radiusMajor: 52,
      radiusMinor: 20,
    );

    expect(isLikelyPalmContact(event), isTrue);
  });

  test('keeps normal fingertip contacts enabled', () {
    const PointerDownEvent event = PointerDownEvent(
      kind: PointerDeviceKind.touch,
      size: 0.1,
      radiusMajor: 18,
      radiusMinor: 14,
    );

    expect(isLikelyPalmContact(event), isFalse);
  });
}
