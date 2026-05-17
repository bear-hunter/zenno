import 'package:flutter/gestures.dart';

/// The canvas-relevant category of a raw pointer.
///
/// The engine routes input by this kind: a [CanvasInputKind.stylus] drives the
/// active tool (draw / erase / lasso) while a [CanvasInputKind.touch] drives
/// viewport transforms (pan / zoom / rotate). This is the "stylus draws, finger
/// pans" model with no mode toggle.
enum CanvasInputKind {
  /// A pen / S Pen, including the eraser end held upside down.
  stylus,

  /// A finger (or a resting palm — hardware/software palm rejection aside, a
  /// palm reports as touch so it can only ever pan).
  touch,

  /// A mouse or trackpad pointer.
  mouse,

  /// Any device kind the engine does not specifically handle.
  unknown,
}

/// Classifies a raw [PointerEvent] by its physical device kind.
///
/// [PointerDeviceKind.stylus] and [PointerDeviceKind.invertedStylus] both map
/// to [CanvasInputKind.stylus]; [PointerDeviceKind.touch] to
/// [CanvasInputKind.touch]; [PointerDeviceKind.mouse] and
/// [PointerDeviceKind.trackpad] to [CanvasInputKind.mouse]. Anything else
/// (e.g. [PointerDeviceKind.unknown]) falls through to
/// [CanvasInputKind.unknown].
CanvasInputKind classifyPointer(PointerEvent event) {
  switch (event.kind) {
    case PointerDeviceKind.stylus:
    case PointerDeviceKind.invertedStylus:
      return CanvasInputKind.stylus;
    case PointerDeviceKind.touch:
      return CanvasInputKind.touch;
    case PointerDeviceKind.mouse:
    case PointerDeviceKind.trackpad:
      return CanvasInputKind.mouse;
    case PointerDeviceKind.unknown:
      return CanvasInputKind.unknown;
  }
}

/// Returns this [event]'s pressure normalised to the range `0..1`.
///
/// A stylus reports a real pressure bounded by [PointerEvent.pressureMin] and
/// [PointerEvent.pressureMax]; the raw value is rescaled into `0..1` and
/// clamped. Devices that do not support pressure report
/// `pressureMin == pressureMax`; for those a neutral constant of `0.5` is
/// returned so downstream ink keeps a sensible, even width.
double normalizedPressure(PointerEvent event) {
  final range = event.pressureMax - event.pressureMin;
  if (range == 0) {
    return 0.5;
  }
  return ((event.pressure - event.pressureMin) / range).clamp(0.0, 1.0);
}
