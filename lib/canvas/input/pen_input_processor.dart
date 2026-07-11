import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:zenno/canvas/input/pen_profile.dart';
import 'package:zenno/canvas/model/stroke.dart';

class PenSample {
  const PenSample({
    required this.point,
    required this.pressure,
    this.tiltX = 0,
    this.tiltY = 0,
    this.azimuth = 0,
    this.timestampMicros = 0,
    this.velocity = 0,
  });

  final Offset point;
  final double pressure;
  final double tiltX;
  final double tiltY;
  final double azimuth;
  final int timestampMicros;
  final double velocity;
}

class PenInputProcessor {
  PenInputProcessor(this.profile);

  final PenProfile profile;
  Offset? _lastPoint;
  int? _lastTimestampMicros;

  PenSample begin(
    Offset point,
    double rawPressure, {
    double tiltX = 0,
    double tiltY = 0,
    double azimuth = 0,
    int timestampMicros = 0,
  }) {
    _lastPoint = point;
    _lastTimestampMicros = timestampMicros;
    return PenSample(
      point: point,
      pressure: profile.mapPressure(rawPressure),
      tiltX: tiltX,
      tiltY: tiltY,
      azimuth: azimuth,
      timestampMicros: timestampMicros,
    );
  }

  PenSample next(
    Offset point,
    double rawPressure, {
    double tiltX = 0,
    double tiltY = 0,
    double azimuth = 0,
    int timestampMicros = 0,
  }) {
    final Offset? previous = _lastPoint;
    if (previous == null) {
      return begin(
        point,
        rawPressure,
        tiltX: tiltX,
        tiltY: tiltY,
        azimuth: azimuth,
        timestampMicros: timestampMicros,
      );
    }
    final double distance = (point - previous).distance;
    final double adaptiveSmoothing =
        profile.smoothing.clamp(0.0, 0.95) * (distance / (distance + 24.0));
    final double damping = math.max(
      profile.stabilizer.clamp(0.0, 0.9),
      adaptiveSmoothing,
    );
    final double follow = (1.0 - damping).clamp(0.12, 1.0);
    final Offset smoothed = previous + (point - previous) * follow;
    final int? previousMicros = _lastTimestampMicros;
    final double velocity = _velocity(
      previous,
      smoothed,
      previousMicros,
      timestampMicros,
    );
    _lastPoint = smoothed;
    _lastTimestampMicros = timestampMicros;
    return PenSample(
      point: smoothed,
      pressure: profile.mapPressure(rawPressure),
      tiltX: tiltX,
      tiltY: tiltY,
      azimuth: azimuth,
      timestampMicros: timestampMicros,
      velocity: velocity,
    );
  }

  void reset() {
    _lastPoint = null;
    _lastTimestampMicros = null;
  }

  static List<StrokePoint> applyTaper(
    List<StrokePoint> points,
    PenProfile profile,
  ) {
    if (points.length < 2) {
      return points;
    }
    final List<StrokePoint> tapered = List<StrokePoint>.of(points);
    tapered[0] = _scalePressure(tapered[0], profile.startTaper);
    tapered[tapered.length - 1] = _scalePressure(
      tapered.last,
      profile.endTaper,
    );
    if (tapered.length > 3) {
      tapered[1] = _scalePressure(tapered[1], (1 + profile.startTaper) / 2);
      tapered[tapered.length - 2] = _scalePressure(
        tapered[tapered.length - 2],
        (1 + profile.endTaper) / 2,
      );
    }
    return tapered;
  }

  static StrokePoint _scalePressure(StrokePoint point, double factor) {
    return StrokePoint(
      point.x,
      point.y,
      (point.pressure * factor.clamp(0.1, 1.0)).clamp(0.0, 1.0),
      tiltX: point.tiltX,
      tiltY: point.tiltY,
      azimuth: point.azimuth,
      timestampMicros: point.timestampMicros,
      velocity: point.velocity,
    );
  }

  static double _velocity(
    Offset previous,
    Offset current,
    int? previousMicros,
    int currentMicros,
  ) {
    if (previousMicros == null || currentMicros <= previousMicros) {
      return 0;
    }
    final double seconds = (currentMicros - previousMicros) / 1000000.0;
    if (seconds <= 0) {
      return 0;
    }
    return (current - previous).distance / seconds;
  }
}
