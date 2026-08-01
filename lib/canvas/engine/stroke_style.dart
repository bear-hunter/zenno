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
    required this.startTaperFactor,
    required this.endTaperFactor,
    required this.cap,
  });

  /// How strongly pressure modulates width. Zero is a constant-width band.
  final double thinning;

  /// How much the outline's corners are rounded off.
  final double smoothing;

  /// Entry taper length, as a multiple of the stroke's own width.
  ///
  /// Short: a real nib is set down deliberately and reaches full width almost
  /// at once. A long entry taper is what makes ink look tentative.
  final double startTaperFactor;

  /// Exit taper length, as a multiple of the stroke's own width.
  ///
  /// Longer than the entry: the pen is lifted while still moving, so the line
  /// thins out over some distance. Zero disables tapering, which is what a
  /// chisel-tip marker or highlighter wants — it stops at full width.
  final double endTaperFactor;

  /// Whether an untapered end is rounded off.
  final bool cap;

  /// Whether this tool tapers at either end.
  bool get tapersStart => startTaperFactor > 0;

  /// Whether this tool tapers at its finish.
  bool get tapersEnd => endTaperFactor > 0;
}

/// The outline style for [tool].
StrokeToolStyle strokeStyleFor(StrokeToolKind tool) {
  return switch (tool) {
    // A nib sets down almost at full width and lifts to a point. `thinning` is
    // deliberately moderate: heavier coupling turns the S Pen's own pressure
    // noise into a visible ripple along the edge of a slow stroke.
    StrokeToolKind.pen => const StrokeToolStyle(
      thinning: 0.42,
      smoothing: 0.5,
      startTaperFactor: 0.35,
      endTaperFactor: 1.6,
      cap: true,
    ),
    // Graphite varies less than ink and leaves a blunter end.
    StrokeToolKind.pencil => const StrokeToolStyle(
      thinning: 0.3,
      smoothing: 0.4,
      startTaperFactor: 0.2,
      endTaperFactor: 0.7,
      cap: true,
    ),
    // A chisel tip lays a constant band and stops square.
    StrokeToolKind.highlighter => const StrokeToolStyle(
      thinning: 0,
      smoothing: 0.3,
      startTaperFactor: 0,
      endTaperFactor: 0,
      cap: false,
    ),
    StrokeToolKind.marker => const StrokeToolStyle(
      thinning: 0.1,
      smoothing: 0.45,
      startTaperFactor: 0,
      endTaperFactor: 0,
      cap: true,
    ),
    StrokeToolKind.airbrush => const StrokeToolStyle(
      thinning: 0.2,
      smoothing: 0.6,
      startTaperFactor: 0.5,
      endTaperFactor: 1.2,
      cap: true,
    ),
    // Fill uses its boundary polygon, not this outline path.
    StrokeToolKind.fill => const StrokeToolStyle(
      thinning: 0,
      smoothing: 0.5,
      startTaperFactor: 0,
      endTaperFactor: 0,
      cap: true,
    ),
  };
}

/// Lowest fraction of nominal width a pressure-sensitive tool may thin to.
///
/// Light pressure must thin the line, never erase it. Without a floor the
/// lightest touch approaches zero width and simply fails to mark.
const double minPressureFraction = 0.45;

/// Spatial smoothing strength for a given profile [smoothing] knob.
///
/// This is `perfect_freehand`'s `streamline` — a low-pass on the *centreline*,
/// so its output depends only on the shape drawn, never on how fast it was
/// drawn or on the digitiser's report rate. That speed-invariance is what makes
/// handwriting look consistent, and it is why the shape filtering lives here
/// rather than in a time-based filter over the incoming samples.
double streamlineFor(double smoothing) =>
    (smoothing.clamp(0.0, 1.0) * 0.62).clamp(0.0, 0.62);
