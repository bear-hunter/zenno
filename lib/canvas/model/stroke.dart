import 'package:flutter/widgets.dart';

/// The kind of ink tool that produced a [Stroke].
///
/// Mirrors the `tool` enum stored on the `ink_strokes` table. A
/// [StrokeToolKind.highlighter] is rendered semi-transparent and drawn beneath
/// pen ink.
enum StrokeToolKind {
  /// Opaque pressure-sensitive ink.
  pen,

  /// Translucent wide ink used to emphasise underlying content.
  highlighter,
}

/// A single sampled point along a [Stroke] centerline, in world coordinates.
@immutable
class StrokePoint {
  /// Creates a stroke point at world position ([x], [y]) with [pressure].
  const StrokePoint(this.x, this.y, this.pressure);

  /// World-space x coordinate.
  final double x;

  /// World-space y coordinate.
  final double y;

  /// Normalised stylus pressure in the range `0..1`.
  final double pressure;

  /// This point's world position as an [Offset].
  Offset get offset => Offset(x, y);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StrokePoint &&
        other.x == x &&
        other.y == y &&
        other.pressure == pressure;
  }

  @override
  int get hashCode => Object.hash(x, y, pressure);

  @override
  String toString() => 'StrokePoint($x, $y, pressure: $pressure)';
}

/// An immutable freehand ink stroke stored as a world-space centerline.
///
/// The geometry in [points] lives in world coordinates; [width] is the
/// intended on-screen thickness in logical pixels at `scale == 1.0` and is
/// therefore scaled by the viewport at render time. [color] is a packed ARGB
/// integer (`Color.toARGB32()`), matching the `ink_strokes.color` column.
@immutable
class Stroke {
  /// Creates a stroke. All fields except [tool] are required.
  const Stroke({
    required this.id,
    required this.points,
    required this.color,
    required this.width,
    this.tool = StrokeToolKind.pen,
  });

  /// Stable unique identifier (uuid v7).
  final String id;

  /// World-space centerline samples, in capture order.
  final List<StrokePoint> points;

  /// Stroke colour as a packed ARGB integer.
  final int color;

  /// Intended on-screen stroke width in logical pixels at `scale == 1.0`.
  final double width;

  /// The tool that produced this stroke.
  final StrokeToolKind tool;

  /// Returns a copy of this stroke with the given fields replaced.
  Stroke copyWith({
    String? id,
    List<StrokePoint>? points,
    int? color,
    double? width,
    StrokeToolKind? tool,
  }) {
    return Stroke(
      id: id ?? this.id,
      points: points ?? this.points,
      color: color ?? this.color,
      width: width ?? this.width,
      tool: tool ?? this.tool,
    );
  }

  @override
  String toString() =>
      'Stroke(id: $id, points: ${points.length}, color: $color, '
      'width: $width, tool: $tool)';
}
