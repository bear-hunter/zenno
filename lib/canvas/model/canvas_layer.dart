import 'package:flutter/foundation.dart';

import 'package:zenno/core/database/tables/canvas_tables.dart';

@immutable
class CanvasLayer {
  const CanvasLayer({
    required this.id,
    required this.canvasId,
    required this.name,
    required this.position,
    this.visible = true,
    this.locked = false,
    this.opacity = 1.0,
    this.blendMode = 'srcOver',
    this.kind = CanvasLayerKind.content,
  });

  final String id;
  final String canvasId;
  final String name;
  final double position;
  final bool visible;
  final bool locked;
  final double opacity;
  final String blendMode;
  final CanvasLayerKind kind;

  bool get isEditable => visible && !locked && kind == CanvasLayerKind.content;

  CanvasLayer copyWith({
    String? id,
    String? canvasId,
    String? name,
    double? position,
    bool? visible,
    bool? locked,
    double? opacity,
    String? blendMode,
    CanvasLayerKind? kind,
  }) {
    return CanvasLayer(
      id: id ?? this.id,
      canvasId: canvasId ?? this.canvasId,
      name: name ?? this.name,
      position: position ?? this.position,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      opacity: (opacity ?? this.opacity).clamp(0.0, 1.0),
      blendMode: blendMode ?? this.blendMode,
      kind: kind ?? this.kind,
    );
  }

  static String defaultContentLayerId(String canvasId) => '$canvasId:content';

  static CanvasLayer defaultContent(String canvasId) {
    return CanvasLayer(
      id: defaultContentLayerId(canvasId),
      canvasId: canvasId,
      name: 'Notes',
      position: 0,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CanvasLayer &&
            other.id == id &&
            other.canvasId == canvasId &&
            other.name == name &&
            other.position == position &&
            other.visible == visible &&
            other.locked == locked &&
            other.opacity == opacity &&
            other.blendMode == blendMode &&
            other.kind == kind;
  }

  @override
  int get hashCode => Object.hash(
    id,
    canvasId,
    name,
    position,
    visible,
    locked,
    opacity,
    blendMode,
    kind,
  );
}
