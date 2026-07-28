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
  double? _lastPressure;

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
    final double pressure = profile.mapPressure(rawPressure);
    _lastPressure = pressure;
    return PenSample(
      point: point,
      pressure: pressure,
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
    final double pressure = _smoothPressure(
      profile.mapPressure(rawPressure),
      previousMicros: previousMicros,
      currentMicros: timestampMicros,
    );
    _lastPoint = smoothed;
    _lastTimestampMicros = timestampMicros;
    _lastPressure = pressure;
    return PenSample(
      point: smoothed,
      pressure: pressure,
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
    _lastPressure = null;
  }

  /// Damps digitiser noise out of [pressure] without touching the geometry.
  ///
  /// The S Pen's reported pressure jitters by a few hundredths sample to
  /// sample, and `thinning` turns that straight into a rippling stroke edge.
  /// Pressure is a scalar with no shape, so filtering it costs nothing visible:
  /// a slightly late width is imperceptible where a slightly late *position*
  /// would read as lag.
  double _smoothPressure(
    double pressure, {
    required int? previousMicros,
    required int currentMicros,
  }) {
    final double? previous = _lastPressure;
    if (previous == null) {
      return pressure;
    }
    final double dt = previousMicros == null
        ? _nominalFrameSeconds
        : ((currentMicros - previousMicros) / 1e6).clamp(1e-4, 0.05);
    final double alpha = (1 - math.exp(-dt / _pressureTauSeconds)).clamp(
      0.0,
      1.0,
    );
    return previous + (pressure - previous) * alpha;
  }

  /// How far this sample moves the filtered point toward the raw one.
  ///
  /// This filter is now deliberately **small**, and it is not what gives a
  /// stroke its shape. Shape smoothing is `perfect_freehand`'s `streamline`,
  /// applied over the centreline in [buildStrokeOutline] — see [streamlineFor].
  ///
  /// The division of labour matters. A *temporal* filter's output depends on
  /// how fast the stroke was drawn and on the digitiser's report rate, so the
  /// same letter written quickly and slowly comes out as two different shapes.
  /// That instability is what made handwriting look wrong when this filter was
  /// carrying all the smoothing. A *spatial* filter has no such dependence.
  ///
  /// What survives here is tremor rejection, which spatial smoothing cannot do:
  /// a hand shaking in place produces real displacement that `streamline` would
  /// faithfully reproduce. So the time constant is short and shrinks quickly
  /// with speed — at writing speed this is very nearly a pass-through, and only
  /// a nearly-stationary nib is damped at all.
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
  ///
  /// Small on purpose: this filter only rejects tremor. Anything larger starts
  /// bending the geometry, which is [streamlineFor]'s job.
  static const double _maxTauSeconds = 0.012;

  /// Speed (world units/second) at which the time constant halves.
  ///
  /// Well below handwriting speed, so ordinary writing is barely filtered here.
  static const double _speedRelaxation = 250.0;

  /// Time constant of the pressure filter.
  static const double _pressureTauSeconds = 0.025;

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
