import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:zenno/canvas/input/pen_profile.dart';

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
    final int? previousMicros = _lastTimestampMicros;
    final Offset smoothed =
        previous +
        (point - previous) *
            _followFactor(
              distance: (point - previous).distance,
              previousMicros: previousMicros,
              currentMicros: timestampMicros,
            );
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

  /// How far this sample moves the filtered point toward the raw one.
  ///
  /// An exponential filter expressed as a time constant rather than a
  /// per-sample weight. Two properties matter:
  ///
  /// * **Time-normalised.** Flutter delivers every historical MotionEvent as
  ///   its own move, so an S Pen writing fast produces several samples per
  ///   frame. Applying a fixed weight per *sample* made effective lag depend on
  ///   report rate and stroke speed instead of on the profile.
  /// * **Relaxes with speed.** Jitter lives in slow, deliberate strokes;
  ///   fast strokes need to track the nib. The time constant therefore shrinks
  ///   as speed rises, which is the opposite of damping harder when fast.
  ///
  /// `perfect_freehand`'s own `streamline` is left at zero: filtering happens
  /// here, once, rather than being applied twice with compounding lag.
  double _followFactor({
    required double distance,
    required int? previousMicros,
    required int currentMicros,
  }) {
    final double stabilizer = profile.stabilizer.clamp(0.0, 0.9);
    final double smoothing = profile.smoothing.clamp(0.0, 0.95);
    // The profile's two knobs set the filter's maximum time constant, in
    // seconds — roughly "how long the ink takes to catch up with the nib".
    final double baseTau = math.max(stabilizer, smoothing) * _maxTauSeconds;
    if (baseTau <= 0) {
      return 1;
    }

    final double dt = previousMicros == null
        ? _nominalFrameSeconds
        : ((currentMicros - previousMicros) / 1e6).clamp(1e-4, 0.05);
    final double speed = distance / dt;
    final double tau = baseTau / (1 + speed / _speedRelaxation);
    return (1 - math.exp(-dt / math.max(tau, 1e-4))).clamp(0.0, 1.0);
  }

  /// Time constant at full stabilizer and zero speed.
  static const double _maxTauSeconds = 0.045;

  /// Speed (world units/second) at which the time constant halves.
  static const double _speedRelaxation = 900.0;

  /// Assumed interval for the first move, before two timestamps exist.
  static const double _nominalFrameSeconds = 1 / 120;

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
