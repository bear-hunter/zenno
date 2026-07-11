import 'dart:convert';
import 'dart:math' as math;

enum PressureCurveKind { light, normal, firm, custom }

class PenProfile {
  const PenProfile({
    this.stabilizer = 0.12,
    this.smoothing = 0.35,
    this.pressureCurve = PressureCurveKind.normal,
    this.customPressureExponent = 1.0,
    this.startTaper = 0.72,
    this.endTaper = 0.78,
  });

  final double stabilizer;
  final double smoothing;
  final PressureCurveKind pressureCurve;
  final double customPressureExponent;
  final double startTaper;
  final double endTaper;

  double mapPressure(double raw) {
    final double p = raw.clamp(0.0, 1.0);
    return switch (pressureCurve) {
      PressureCurveKind.light => math.sqrt(p),
      PressureCurveKind.normal => p,
      PressureCurveKind.firm => math.pow(p, 1.55).toDouble(),
      PressureCurveKind.custom =>
        math.pow(p, customPressureExponent.clamp(0.35, 2.5)).toDouble(),
    };
  }

  Map<String, Object> toJson() => <String, Object>{
    'stabilizer': stabilizer,
    'smoothing': smoothing,
    'pressureCurve': pressureCurve.name,
    'customPressureExponent': customPressureExponent,
    'startTaper': startTaper,
    'endTaper': endTaper,
  };

  String encode() => jsonEncode(toJson());

  static PenProfile fromJsonString(String json) {
    try {
      final Object? decoded = jsonDecode(json);
      if (decoded is Map<String, Object?>) {
        return PenProfile(
          stabilizer: _double(decoded['stabilizer'], 0.12),
          smoothing: _double(decoded['smoothing'], 0.35),
          pressureCurve: _curve(decoded['pressureCurve']),
          customPressureExponent: _double(
            decoded['customPressureExponent'],
            1.0,
          ),
          startTaper: _double(decoded['startTaper'], 0.72),
          endTaper: _double(decoded['endTaper'], 0.78),
        );
      }
    } catch (_) {
      // Fall through to defaults.
    }
    return const PenProfile();
  }

  PenProfile copyWith({
    double? stabilizer,
    double? smoothing,
    PressureCurveKind? pressureCurve,
    double? customPressureExponent,
    double? startTaper,
    double? endTaper,
  }) {
    return PenProfile(
      stabilizer: stabilizer ?? this.stabilizer,
      smoothing: smoothing ?? this.smoothing,
      pressureCurve: pressureCurve ?? this.pressureCurve,
      customPressureExponent:
          customPressureExponent ?? this.customPressureExponent,
      startTaper: startTaper ?? this.startTaper,
      endTaper: endTaper ?? this.endTaper,
    );
  }

  static double _double(Object? value, double fallback) {
    return value is num ? value.toDouble() : fallback;
  }

  static PressureCurveKind _curve(Object? value) {
    if (value is String) {
      for (final PressureCurveKind curve in PressureCurveKind.values) {
        if (curve.name == value) {
          return curve;
        }
      }
    }
    return PressureCurveKind.normal;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PenProfile &&
            other.stabilizer == stabilizer &&
            other.smoothing == smoothing &&
            other.pressureCurve == pressureCurve &&
            other.customPressureExponent == customPressureExponent &&
            other.startTaper == startTaper &&
            other.endTaper == endTaper;
  }

  @override
  int get hashCode => Object.hash(
    stabilizer,
    smoothing,
    pressureCurve,
    customPressureExponent,
    startTaper,
    endTaper,
  );
}
