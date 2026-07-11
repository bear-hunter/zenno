import 'dart:convert';

enum StylusButtonAction {
  temporaryEraser,
  temporaryLasso,
  temporaryPan,
  straightLine,
  arrow,
  eyedropper,
  undo,
  redo,
  togglePreviousTool,
  radialMenu,
  exportSelection,
  disabled,
}

class StylusButtonMapping {
  const StylusButtonMapping({
    this.hold = StylusButtonAction.temporaryEraser,
    this.tap = StylusButtonAction.togglePreviousTool,
    this.drag = StylusButtonAction.temporaryEraser,
    this.penLongPress = StylusButtonAction.temporaryLasso,
  });

  final StylusButtonAction hold;
  final StylusButtonAction tap;
  final StylusButtonAction drag;
  final StylusButtonAction penLongPress;

  Map<String, String> toJson() => <String, String>{
    'hold': hold.name,
    'tap': tap.name,
    'drag': drag.name,
    'penLongPress': penLongPress.name,
  };

  static StylusButtonMapping fromJsonString(String json) {
    try {
      final Object? decoded = jsonDecode(json);
      if (decoded is Map<String, Object?>) {
        return StylusButtonMapping(
          hold: _actionFromName(
            decoded['hold'],
            StylusButtonAction.temporaryEraser,
          ),
          tap: _actionFromName(
            decoded['tap'],
            StylusButtonAction.togglePreviousTool,
          ),
          drag: _actionFromName(
            decoded['drag'],
            StylusButtonAction.temporaryEraser,
          ),
          penLongPress: _actionFromName(
            decoded['penLongPress'],
            StylusButtonAction.temporaryLasso,
          ),
        );
      }
    } catch (_) {
      // Fall through to the default mapping.
    }
    return const StylusButtonMapping();
  }

  String encode() => jsonEncode(toJson());

  static StylusButtonAction _actionFromName(
    Object? value,
    StylusButtonAction fallback,
  ) {
    if (value is String) {
      for (final StylusButtonAction action in StylusButtonAction.values) {
        if (action.name == value) {
          return action;
        }
      }
    }
    return fallback;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StylusButtonMapping &&
            other.hold == hold &&
            other.tap == tap &&
            other.drag == drag &&
            other.penLongPress == penLongPress;
  }

  @override
  int get hashCode => Object.hash(hold, tap, drag, penLongPress);
}
