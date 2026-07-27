import 'package:zenno/canvas/model/stroke.dart';

/// How a given drawing tool shapes its outline.
///
/// Every tool used to share one hardcoded parameter set, which gave the
/// highlighter and marker the same pressure thinning as the pen — physically
/// wrong for a chisel tip, which lays down a constant band.
class StrokeToolStyle {
  const StrokeToolStyle({
    required this.thinning,
    required this.smoothing,
    required this.taperLengthFactor,
    required this.cap,
  });

  /// How strongly pressure modulates width. Zero is a constant-width band.
  final double thinning;

  /// How much the outline's corners are rounded off.
  final double smoothing;

  /// Taper length at each end, as a multiple of the stroke's own width.
  ///
  /// Zero disables tapering, which is what a chisel-tip marker or highlighter
  /// wants: it starts and stops at full width.
  final double taperLengthFactor;

  /// Whether an untapered end is rounded off.
  final bool cap;

  /// Whether this tool tapers at all.
  bool get tapers => taperLengthFactor > 0;
}

/// The outline style for [tool].
StrokeToolStyle strokeStyleFor(StrokeToolKind tool) {
  return switch (tool) {
    // A nib narrows with lighter pressure and lifts to a point.
    StrokeToolKind.pen => const StrokeToolStyle(
      thinning: 0.55,
      smoothing: 0.5,
      taperLengthFactor: 2,
      cap: true,
    ),
    // Graphite varies less than ink and leaves a blunter end.
    StrokeToolKind.pencil => const StrokeToolStyle(
      thinning: 0.35,
      smoothing: 0.4,
      taperLengthFactor: 0.75,
      cap: true,
    ),
    // A chisel tip lays a constant band and stops square.
    StrokeToolKind.highlighter => const StrokeToolStyle(
      thinning: 0,
      smoothing: 0.3,
      taperLengthFactor: 0,
      cap: false,
    ),
    StrokeToolKind.marker => const StrokeToolStyle(
      thinning: 0.1,
      smoothing: 0.45,
      taperLengthFactor: 0,
      cap: true,
    ),
    StrokeToolKind.airbrush => const StrokeToolStyle(
      thinning: 0.2,
      smoothing: 0.6,
      taperLengthFactor: 1.5,
      cap: true,
    ),
    // Fill uses its boundary polygon, not this outline path.
    StrokeToolKind.fill => const StrokeToolStyle(
      thinning: 0,
      smoothing: 0.5,
      taperLengthFactor: 0,
      cap: true,
    ),
  };
}
