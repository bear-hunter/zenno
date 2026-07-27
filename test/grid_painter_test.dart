import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/model/canvas_style.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/render/grid_painter.dart';
import 'package:zenno/core/database/tables/canvas_tables.dart';

void _paintGrid(BackgroundKind kind) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  GridPainter(
    viewport: ViewportState.initial,
    style: CanvasPaperStyle(kind: kind),
  ).paint(canvas, const Size(320, 240));
  recorder.endRecording().dispose();
}

void main() {
  test('isometric and triangle grids paint without throwing', () {
    _paintGrid(BackgroundKind.isometric);
    _paintGrid(BackgroundKind.triangle);
  });

  test('paper textures paint without throwing', () {
    for (final PaperTexture texture in PaperTexture.values) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      PaperTexturePainter(
        viewport: ViewportState.initial,
        style: CanvasPaperStyle(texture: texture),
      ).paint(canvas, const Size(320, 240));
      recorder.endRecording().dispose();
    }
  });
}
