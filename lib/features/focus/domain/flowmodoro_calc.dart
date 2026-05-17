/// Flowmodoro break-length math.
///
/// Pure Dart — no Flutter, no Drift. Unit-tested in
/// `test/flowmodoro_calc_test.dart`.
library;

/// Computes the rest a Flowmodoro break should last after a [focusStretch] of
/// open-ended focus work.
///
/// The Flowmodoro technique scales the break to the work just done:
/// `break = focusStretch * ratio`. The raw result is then clamped to
/// `[min, max]` so a very short stretch still earns a usable pause and a
/// marathon stretch does not produce an unreasonably long break.
///
/// [ratio] is typically `0.2` (the seeded `default_flow_break_ratio`). A
/// non-positive [focusStretch] yields [min]. The clamp bounds default to
/// `[2 min, 30 min]`, matching the design in the implementation plan.
Duration flowmodoroBreak(
  Duration focusStretch,
  double ratio, {
  Duration min = const Duration(minutes: 2),
  Duration max = const Duration(minutes: 30),
}) {
  assert(ratio >= 0, 'ratio must be non-negative');
  assert(min <= max, 'min must not exceed max');

  // Work in microseconds so a fractional ratio does not lose sub-second
  // precision before the clamp.
  final scaledMicros = (focusStretch.inMicroseconds * ratio).round();
  final scaled = Duration(microseconds: scaledMicros);

  if (scaled < min) return min;
  if (scaled > max) return max;
  return scaled;
}
