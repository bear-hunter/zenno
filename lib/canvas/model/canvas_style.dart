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
  });

  final int penColor;
  final double penWidth;
  final PenWidthMode penWidthMode;
  final StrokeToolKind penKind;
  final bool pressureEnabled;
}
