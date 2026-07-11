import 'package:flutter/widgets.dart';

import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/core/database/tables/canvas_tables.dart';

/// How the selected pen width is interpreted when a mark is created.
enum PenWidthMode {
  /// Keep the pen the same visual size under the hand at every zoom level.
  screen,

  /// Keep the mark the same size in world/canvas units.
  canvas,
}

/// The behavior assigned to one of the eight persistent tool-wheel slots.
///
/// Ink families share the normal pen gesture but retain independent colour,
/// size, opacity and smoothing settings. Utility kinds keep their stable slot
/// position while routing the next gesture to the corresponding canvas tool.
enum ToolWheelSlotKind {
  pen,
  pencil,
  highlighter,
  marker,
  airbrush,
  fill,
  eraser,
  lasso,
  shape,
  text,
  link,
  pan;

  /// Whether this slot creates an ink/fill stroke.
  bool get isInk => switch (this) {
    pen || pencil || highlighter || marker || airbrush || fill => true,
    eraser || lasso || shape || text || link || pan => false,
  };

  /// Stroke family used by an ink slot, or `null` for a utility slot.
  StrokeToolKind? get strokeKind => switch (this) {
    pen => StrokeToolKind.pen,
    pencil => StrokeToolKind.pencil,
    highlighter => StrokeToolKind.highlighter,
    marker => StrokeToolKind.marker,
    airbrush => StrokeToolKind.airbrush,
    fill => StrokeToolKind.fill,
    eraser || lasso || shape || text || link || pan => null,
  };

  /// Maps a stored stroke family back to its wheel kind.
  static ToolWheelSlotKind fromStrokeKind(StrokeToolKind kind) =>
      switch (kind) {
        StrokeToolKind.pen => pen,
        StrokeToolKind.pencil => pencil,
        StrokeToolKind.highlighter => highlighter,
        StrokeToolKind.marker => marker,
        StrokeToolKind.airbrush => airbrush,
        StrokeToolKind.fill => fill,
      };
}

/// One remembered favorite on the persistent canvas tool wheel.
@immutable
class ToolWheelPreset {
  const ToolWheelPreset({
    required this.kind,
    required this.color,
    required this.size,
    this.opacity = 1,
    this.smoothing = 0.35,
    this.widthMode = PenWidthMode.screen,
    this.pressureEnabled = true,
  });

  final ToolWheelSlotKind kind;

  /// Opaque RGB color. [opacity] is stored separately per preset.
  final int color;

  /// Pen width for ink slots and footprint radius for the eraser slot.
  final double size;
  final double opacity;
  final double smoothing;
  final PenWidthMode widthMode;
  final bool pressureEnabled;

  ToolWheelPreset copyWith({
    ToolWheelSlotKind? kind,
    int? color,
    double? size,
    double? opacity,
    double? smoothing,
    PenWidthMode? widthMode,
    bool? pressureEnabled,
  }) {
    return ToolWheelPreset(
      kind: kind ?? this.kind,
      color: color ?? this.color,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      smoothing: smoothing ?? this.smoothing,
      widthMode: widthMode ?? this.widthMode,
      pressureEnabled: pressureEnabled ?? this.pressureEnabled,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'kind': kind.name,
    'color': color & 0xFFFFFFFF,
    'size': size,
    'opacity': opacity,
    'smoothing': smoothing,
    'widthMode': widthMode.name,
    'pressureEnabled': pressureEnabled,
  };

  static ToolWheelPreset? fromJson(Object? value) {
    if (value is! Map) return null;
    final Object? rawKind = value['kind'];
    final ToolWheelSlotKind? kind = ToolWheelSlotKind.values
        .where((candidate) => candidate.name == rawKind)
        .firstOrNull;
    if (kind == null) return null;
    final ToolWheelPreset fallback = defaultToolWheelPresetFor(kind);
    final Object? rawWidthMode = value['widthMode'];
    final PenWidthMode widthMode = PenWidthMode.values.firstWhere(
      (candidate) => candidate.name == rawWidthMode,
      orElse: () => fallback.widthMode,
    );
    return ToolWheelPreset(
      kind: kind,
      color: ((value['color'] as num?)?.toInt() ?? fallback.color) | 0xFF000000,
      size: ((value['size'] as num?)?.toDouble() ?? fallback.size)
          .clamp(0.5, 96)
          .toDouble(),
      opacity: ((value['opacity'] as num?)?.toDouble() ?? fallback.opacity)
          .clamp(0, 1)
          .toDouble(),
      smoothing:
          ((value['smoothing'] as num?)?.toDouble() ?? fallback.smoothing)
              .clamp(0, 1)
              .toDouble(),
      widthMode: widthMode,
      pressureEnabled:
          value['pressureEnabled'] as bool? ?? fallback.pressureEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ToolWheelPreset &&
            other.kind == kind &&
            other.color == color &&
            other.size == size &&
            other.opacity == opacity &&
            other.smoothing == smoothing &&
            other.widthMode == widthMode &&
            other.pressureEnabled == pressureEnabled;
  }

  @override
  int get hashCode => Object.hash(
    kind,
    color,
    size,
    opacity,
    smoothing,
    widthMode,
    pressureEnabled,
  );
}

/// Concepts-style defaults: six directly reachable marks plus Eraser and
/// Select. Every slot can later be replaced from the brush/tool picker.
const List<ToolWheelPreset> defaultToolWheelPresets = <ToolWheelPreset>[
  ToolWheelPreset(kind: ToolWheelSlotKind.pen, color: 0xFFFFFFFF, size: 4),
  ToolWheelPreset(
    kind: ToolWheelSlotKind.pencil,
    color: 0xFFD9D9D9,
    size: 2,
    smoothing: 0.15,
  ),
  ToolWheelPreset(
    kind: ToolWheelSlotKind.highlighter,
    color: 0xFFFFD54F,
    size: 18,
    smoothing: 0.6,
    pressureEnabled: false,
  ),
  ToolWheelPreset(
    kind: ToolWheelSlotKind.marker,
    color: 0xFFFF4F91,
    size: 12,
    smoothing: 0.55,
    pressureEnabled: false,
  ),
  ToolWheelPreset(
    kind: ToolWheelSlotKind.airbrush,
    color: 0xFF1E9BFF,
    size: 28,
    smoothing: 0.7,
  ),
  ToolWheelPreset(
    kind: ToolWheelSlotKind.fill,
    color: 0xFFF2C94C,
    size: 1,
    opacity: 0.55,
    smoothing: 0.45,
    pressureEnabled: false,
  ),
  ToolWheelPreset(
    kind: ToolWheelSlotKind.eraser,
    color: 0xFFFFFFFF,
    size: 16,
    pressureEnabled: false,
  ),
  ToolWheelPreset(
    kind: ToolWheelSlotKind.lasso,
    color: 0xFFFFFFFF,
    size: 4,
    pressureEnabled: false,
  ),
];

ToolWheelPreset defaultToolWheelPresetFor(ToolWheelSlotKind kind) {
  for (final ToolWheelPreset preset in defaultToolWheelPresets) {
    if (preset.kind == kind) return preset;
  }
  return switch (kind) {
    ToolWheelSlotKind.shape => const ToolWheelPreset(
      kind: ToolWheelSlotKind.shape,
      color: 0xFFFFFFFF,
      size: 4,
    ),
    ToolWheelSlotKind.text => const ToolWheelPreset(
      kind: ToolWheelSlotKind.text,
      color: 0xFFFFFFFF,
      size: 4,
    ),
    ToolWheelSlotKind.link => const ToolWheelPreset(
      kind: ToolWheelSlotKind.link,
      color: 0xFFFFFFFF,
      size: 4,
    ),
    ToolWheelSlotKind.pan => const ToolWheelPreset(
      kind: ToolWheelSlotKind.pan,
      color: 0xFFFFFFFF,
      size: 4,
    ),
    _ => defaultToolWheelPresets.first,
  };
}

/// Resolves the stored world-space stroke width for a new mark.
double resolveStrokeWidthWorld({
  required double selectedWidth,
  required double viewportScale,
  required PenWidthMode mode,
}) {
  return switch (mode) {
    PenWidthMode.screen =>
      viewportScale.isFinite && viewportScale > 0
          ? selectedWidth / viewportScale
          : selectedWidth,
    PenWidthMode.canvas => selectedWidth,
  };
}

@immutable
class CanvasPaperStyle {
  const CanvasPaperStyle({
    this.kind = BackgroundKind.grid,
    this.backgroundColor = 0xFF172331,
    this.gridColor = 0xFFFFFFFF,
    this.gridSpacing = 48,
    this.gridOpacity = 0.14,
    this.graphMajorInterval = 4,
  });

  final BackgroundKind kind;
  final int backgroundColor;
  final int gridColor;
  final double gridSpacing;
  final double gridOpacity;
  final int graphMajorInterval;

  CanvasPaperStyle copyWith({
    BackgroundKind? kind,
    int? backgroundColor,
    int? gridColor,
    double? gridSpacing,
    double? gridOpacity,
    int? graphMajorInterval,
  }) {
    return CanvasPaperStyle(
      kind: kind ?? this.kind,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gridColor: gridColor ?? this.gridColor,
      gridSpacing: gridSpacing ?? this.gridSpacing,
      gridOpacity: gridOpacity ?? this.gridOpacity,
      graphMajorInterval: graphMajorInterval ?? this.graphMajorInterval,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CanvasPaperStyle &&
            other.kind == kind &&
            other.backgroundColor == backgroundColor &&
            other.gridColor == gridColor &&
            other.gridSpacing == gridSpacing &&
            other.gridOpacity == gridOpacity &&
            other.graphMajorInterval == graphMajorInterval;
  }

  @override
  int get hashCode => Object.hash(
    kind,
    backgroundColor,
    gridColor,
    gridSpacing,
    gridOpacity,
    graphMajorInterval,
  );
}

@immutable
class CanvasToolSettings {
  const CanvasToolSettings({
    this.penColor = 0xFFFFFFFF,
    this.penWidth = 4,
    this.penWidthMode = PenWidthMode.screen,
    this.penKind = StrokeToolKind.pen,
    this.pressureEnabled = true,
    this.toolWheelPresets = defaultToolWheelPresets,
    this.activeToolWheelIndex = 0,
  });

  final int penColor;
  final double penWidth;
  final PenWidthMode penWidthMode;
  final StrokeToolKind penKind;
  final bool pressureEnabled;
  final List<ToolWheelPreset> toolWheelPresets;
  final int activeToolWheelIndex;
}
