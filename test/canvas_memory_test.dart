import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/render/elements_painter.dart';

Future<ui.Image> _tinyRaster() async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(1, 1);
  picture.dispose();
  return image;
}

void _drawStroke(CanvasController controller, int i) {
  controller
    ..beginStroke(Offset(i * 10.0, 0), 0.5)
    ..appendToStroke(Offset(i * 10.0 + 30, 20), 0.5)
    ..endStroke();
}

void main() {
  group('bounded undo history', () {
    test('the undo stack never grows past its cap', () {
      final controller = CanvasController();
      addTearDown(controller.dispose);

      // A study session is hours of strokes; every command holds full element
      // snapshots, so an unbounded stack duplicated the whole canvas in RAM.
      for (int i = 0; i < 230; i++) {
        _drawStroke(controller, i);
      }

      var undoDepth = 0;
      while (controller.canUndo) {
        controller.undo();
        undoDepth++;
      }
      expect(undoDepth, 200);
      expect(
        controller.elementCount,
        30,
        reason:
            'commands dropped past the cap stay applied — only their '
            'undoability is released, never their content',
      );
    });
  });

  group('memory pressure response', () {
    test('sheds off-screen rasters and deep history, keeps everything else',
        () async {
      final ui.Image onScreen = await _tinyRaster();
      final ui.Image offScreen = await _tinyRaster();
      final controller = CanvasController()
        ..setViewportSize(const Size(200, 200));
      addTearDown(controller.dispose);

      controller
        ..addElementToStore(
          ImageElement(
            id: 'visible',
            zIndex: 0,
            worldBounds: const Rect.fromLTWH(10, 10, 50, 50),
            sourceFilePath: '/durable/visible.png',
            intrinsicSize: const Size(50, 50),
            raster: onScreen,
            rasterScaleBucket: 1,
          ),
        )
        ..addElementToStore(
          ImageElement(
            id: 'distant',
            zIndex: 1,
            worldBounds: const Rect.fromLTWH(5000, 0, 50, 50),
            sourceFilePath: '/durable/distant.png',
            intrinsicSize: const Size(50, 50),
            raster: offScreen,
            rasterScaleBucket: 1,
          ),
        );
      for (int i = 0; i < 80; i++) {
        _drawStroke(controller, i);
      }

      controller.onMemoryPressure();

      final Map<String, ImageElement> byId = <String, ImageElement>{
        for (final CanvasElement element in controller.elements)
          if (element is ImageElement) element.id: element,
      };
      expect(
        byId['visible']!.raster,
        same(onScreen),
        reason: 'on-screen pixels are needed this frame',
      );
      expect(byId['distant']!.raster, isNull);
      expect(offScreen.debugDisposed, isTrue);
      expect(
        byId['distant']!.sourceFilePath,
        '/durable/distant.png',
        reason: 'an evicted raster is a cache — the durable state survives',
      );

      var undoDepth = 0;
      while (controller.canUndo) {
        controller.undo();
        undoDepth++;
      }
      expect(undoDepth, 50, reason: 'history trims to the recent quarter');
    });
  });

  group('tile cache vs evicted rasters', () {
    test('evicting a raster invalidates the tiles that painted it', () async {
      // A recorded tile picture that blitted an image holds a reference to
      // that ui.Image; eviction disposes the image. If the damage path did
      // not drop the covering tile, the cache would either pin the "freed"
      // memory or replay a disposed image. This proves the full loop.
      final ui.Image raster = await _tinyRaster();
      final controller = CanvasController()
        ..setViewportSize(const Size(200, 200))
        ..addElementToStore(
          ImageElement(
            id: 'img',
            zIndex: 0,
            worldBounds: const Rect.fromLTWH(3000, 0, 50, 50),
            sourceFilePath: '/durable/img.png',
            intrinsicSize: const Size(50, 50),
            raster: raster,
            rasterScaleBucket: 1,
          ),
        );
      addTearDown(controller.dispose);

      final cache = ElementsTileCache();
      addTearDown(cache.dispose);
      void paintAt(ViewportState viewport, int sinceRevision) {
        final recorder = ui.PictureRecorder();
        ElementsPainter(
          elements: controller.viewportElements,
          spatialIndex: controller.spatialIndex,
          allElementsById: controller.elementsById,
          paintOrderById: controller.paintOrderById,
          viewport: viewport,
          elementsRevision: controller.elementsRevision,
          elementDamage: controller.elementDamageSince(sinceRevision),
          tileCache: cache,
        ).paint(Canvas(recorder), const Size(200, 200));
        recorder.endRecording().dispose();
      }

      // Frame the image and record its tile.
      controller.setViewport(const ViewportState(translation: Offset(-2950, 0)));
      paintAt(controller.viewport, cache.revision);
      final int buildsWithRaster = cache.pictureBuildCount;
      expect(buildsWithRaster, greaterThan(0));

      // Scroll away and evict everything off-screen.
      controller.setViewport(ViewportState.initial);
      controller.onMemoryPressure();
      expect(raster.debugDisposed, isTrue);

      // Scroll back: the covering tile must be re-recorded (placeholder now),
      // not replayed from the picture that references the disposed image.
      controller.setViewport(const ViewportState(translation: Offset(-2950, 0)));
      paintAt(controller.viewport, cache.revision);
      expect(cache.pictureBuildCount, greaterThan(buildsWithRaster));
    });
  });
}
