import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'package:zenno/canvas/engine/canvas_transform.dart';
import 'package:zenno/canvas/model/viewport_state.dart';

/// Interactive regions exposed by the committed-selection overlay.
enum SelectionOverlayTarget {
  outside,
  body,
  scaleTopLeft,
  scaleTopRight,
  scaleBottomRight,
  scaleBottomLeft,
  rotation,
  done,
}

/// Screen-space geometry shared by selection painting and pointer hit testing.
///
/// The visible handles stay small, while every handle receives a 44 logical-px
/// target so it remains comfortable to acquire with a stylus or mouse.
class SelectionOverlayGeometry {
  const SelectionOverlayGeometry._({
    required this.frameRect,
    required this.rotationCenter,
    required this.doneCenter,
  });

  static const double framePadding = 6;
  static const double handleHitSize = 44;
  static const double cornerVisualRadius = 6;
  static const double actionVisualRadius = 11;
  static const double _actionOffset = 32;

  final Rect frameRect;
  final Offset rotationCenter;
  final Offset doneCenter;

  static SelectionOverlayGeometry fromWorldBounds({
    required Rect bounds,
    required ViewportState viewport,
    required Size canvasSize,
  }) {
    final List<Offset> corners = <Offset>[
      CanvasTransform.toScreen(viewport, bounds.topLeft),
      CanvasTransform.toScreen(viewport, bounds.topRight),
      CanvasTransform.toScreen(viewport, bounds.bottomRight),
      CanvasTransform.toScreen(viewport, bounds.bottomLeft),
    ];
    double minX = corners.first.dx;
    double maxX = corners.first.dx;
    double minY = corners.first.dy;
    double maxY = corners.first.dy;
    for (final Offset corner in corners.skip(1)) {
      minX = math.min(minX, corner.dx);
      maxX = math.max(maxX, corner.dx);
      minY = math.min(minY, corner.dy);
      maxY = math.max(maxY, corner.dy);
    }
    final Rect frame = Rect.fromLTRB(
      minX,
      minY,
      maxX,
      maxY,
    ).inflate(framePadding);
    final Rect canvasRect = Offset.zero & canvasSize;
    final bool frameVisible = !canvasSize.isEmpty && frame.overlaps(canvasRect);
    final Offset desiredRotation = Offset(
      frame.center.dx,
      frame.top - _actionOffset,
    );
    final Offset desiredDone = Offset(
      frame.right + _actionOffset,
      frame.top - _actionOffset,
    );
    final Offset rotationCenter = frameVisible
        ? _keepActionOnCanvas(desiredRotation, canvasSize)
        : desiredRotation;
    Offset doneCenter = frameVisible
        ? _keepActionOnCanvas(desiredDone, canvasSize)
        : desiredDone;
    if (frameVisible &&
        (doneCenter - rotationCenter).distance < handleHitSize) {
      for (final Offset candidate in <Offset>[
        Offset(frame.right + _actionOffset, frame.center.dy),
        Offset(frame.right + _actionOffset, frame.bottom + _actionOffset),
        Offset(frame.center.dx, frame.bottom + _actionOffset),
        Offset(frame.left - _actionOffset, frame.center.dy),
      ]) {
        final Offset next = _keepActionOnCanvas(candidate, canvasSize);
        if ((next - rotationCenter).distance >= handleHitSize) {
          doneCenter = next;
          break;
        }
      }
    }
    return SelectionOverlayGeometry._(
      frameRect: frame,
      rotationCenter: rotationCenter,
      doneCenter: doneCenter,
    );
  }

  static Offset _keepActionOnCanvas(Offset desired, Size size) {
    if (size.isEmpty) {
      return desired;
    }
    const double inset = handleHitSize / 2;
    final double maxX = math.max(inset, size.width - inset);
    final double maxY = math.max(inset, size.height - inset);
    return Offset(
      desired.dx.clamp(inset, maxX).toDouble(),
      desired.dy.clamp(inset, maxY).toDouble(),
    );
  }

  List<SelectionOverlayTarget> get scaleTargets =>
      const <SelectionOverlayTarget>[
        SelectionOverlayTarget.scaleTopLeft,
        SelectionOverlayTarget.scaleTopRight,
        SelectionOverlayTarget.scaleBottomRight,
        SelectionOverlayTarget.scaleBottomLeft,
      ];

  Offset centerFor(SelectionOverlayTarget target) => switch (target) {
    SelectionOverlayTarget.scaleTopLeft => frameRect.topLeft,
    SelectionOverlayTarget.scaleTopRight => frameRect.topRight,
    SelectionOverlayTarget.scaleBottomRight => frameRect.bottomRight,
    SelectionOverlayTarget.scaleBottomLeft => frameRect.bottomLeft,
    SelectionOverlayTarget.rotation => rotationCenter,
    SelectionOverlayTarget.done => doneCenter,
    SelectionOverlayTarget.body => frameRect.center,
    SelectionOverlayTarget.outside => frameRect.center,
  };

  Offset oppositeCornerFor(SelectionOverlayTarget target) => switch (target) {
    SelectionOverlayTarget.scaleTopLeft => frameRect.bottomRight,
    SelectionOverlayTarget.scaleTopRight => frameRect.bottomLeft,
    SelectionOverlayTarget.scaleBottomRight => frameRect.topLeft,
    SelectionOverlayTarget.scaleBottomLeft => frameRect.topRight,
    _ => frameRect.center,
  };

  bool isScaleTarget(SelectionOverlayTarget target) =>
      target == SelectionOverlayTarget.scaleTopLeft ||
      target == SelectionOverlayTarget.scaleTopRight ||
      target == SelectionOverlayTarget.scaleBottomRight ||
      target == SelectionOverlayTarget.scaleBottomLeft;

  /// Returns the nearest 44px handle target, then the frame body, or outside.
  SelectionOverlayTarget hitTest(Offset position) {
    final List<SelectionOverlayTarget> handles = <SelectionOverlayTarget>[
      SelectionOverlayTarget.done,
      SelectionOverlayTarget.rotation,
      ...scaleTargets,
    ];
    SelectionOverlayTarget? nearest;
    double nearestDistance = double.infinity;
    for (final SelectionOverlayTarget target in handles) {
      final Offset center = centerFor(target);
      final Rect targetRect = Rect.fromCenter(
        center: center,
        width: handleHitSize,
        height: handleHitSize,
      );
      if (!targetRect.contains(position)) {
        continue;
      }
      final double distance = (position - center).distanceSquared;
      if (distance < nearestDistance) {
        nearest = target;
        nearestDistance = distance;
      }
    }
    if (nearest != null) {
      return nearest;
    }
    return frameRect.contains(position)
        ? SelectionOverlayTarget.body
        : SelectionOverlayTarget.outside;
  }
}
