import 'dart:convert' show utf8;
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/io/canvas_export.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/canvas_style.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/core/database/tables/canvas_tables.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CanvasController controllerWithLine() {
    final controller = CanvasController()
      ..setViewportSize(const Size(240, 180));
    controller
      ..beginShape(const Offset(10, 20))
      ..updateShape(const Offset(90, 70))
      ..endShape();
    return controller;
  }

  test('content scope resolves committed element bounds', () {
    final controller = controllerWithLine();
    addTearDown(controller.dispose);

    final region = CanvasExportService.resolveWorldRegion(
      controller: controller,
      scope: CanvasExportScope.content,
    );

    expect(region, isNotNull);
    expect(region!.left, lessThanOrEqualTo(10));
    expect(region.right, greaterThanOrEqualTo(90));
  });

  test('empty selection scope reports a useful export error', () async {
    final controller = controllerWithLine();
    addTearDown(controller.dispose);

    expect(
      () => CanvasExportService.renderToBytes(
        controller: controller,
        options: const CanvasExportOptions(scope: CanvasExportScope.selection),
      ),
      throwsA(isA<CanvasExportException>()),
    );
  });

  test('pixel budget rejects oversized exports before rendering', () async {
    final controller = CanvasController()
      ..setViewportSize(const Size(240, 180));
    addTearDown(controller.dispose);
    controller
      ..beginShape(Offset.zero)
      ..updateShape(const Offset(100000, 100000))
      ..endShape();

    expect(
      () => CanvasExportService.renderToBytes(
        controller: controller,
        options: const CanvasExportOptions(scale: 4),
      ),
      throwsA(isA<CanvasExportTooLargeException>()),
    );
  });

  test('renders content as PNG bytes', () async {
    final controller = controllerWithLine();
    addTearDown(controller.dispose);

    final Uint8List bytes = await CanvasExportService.renderToBytes(
      controller: controller,
      options: const CanvasExportOptions(
        scale: 0.5,
        padding: 4,
        transparentBackground: true,
        includeGrid: false,
      ),
    );

    expect(bytes.take(4).toList(), <int>[137, 80, 78, 71]);
  });

  test('renders content as JPG bytes', () async {
    final controller = controllerWithLine();
    addTearDown(controller.dispose);

    final Uint8List bytes = await CanvasExportService.renderToBytes(
      controller: controller,
      options: const CanvasExportOptions(
        format: CanvasExportFormat.jpg,
        scale: 0.5,
        padding: 4,
        includeGrid: false,
      ),
    );

    expect(bytes.take(2).toList(), <int>[255, 216]);
  });

  test('renders content as SVG vector markup', () async {
    final controller = controllerWithLine();
    addTearDown(controller.dispose);

    final Uint8List bytes = await CanvasExportService.renderToBytes(
      controller: controller,
      options: const CanvasExportOptions(
        format: CanvasExportFormat.svg,
        scale: 1,
        padding: 4,
        transparentBackground: true,
        includeGrid: false,
      ),
    );

    final String svg = utf8.decode(bytes);
    expect(svg, startsWith('<svg'));
    expect(svg, contains('<line'));
  });

  test('SVG writes pressure-sensitive ink as its filled outline', () async {
    final controller = CanvasController()
      ..setViewportSize(const Size(240, 180))
      ..addElementToStore(
        InkElement.fromStroke(
          const Stroke(
            id: 'pressure-ink',
            color: 0xFFFFFFFF,
            width: 18,
            points: [
              StrokePoint(10, 20, 0.15),
              StrokePoint(35, 24, 0.4),
              StrokePoint(65, 32, 0.95),
              StrokePoint(100, 45, 0.25),
            ],
          ),
          zIndex: 0,
        ),
      );
    addTearDown(controller.dispose);

    final String svg = utf8.decode(
      await CanvasExportService.renderToBytes(
        controller: controller,
        options: const CanvasExportOptions(
          format: CanvasExportFormat.svg,
          transparentBackground: true,
          includeGrid: false,
        ),
      ),
    );

    expect(svg, contains('<path data-ink-outline="true"'));
    expect(svg, contains(' Z" fill='));
    expect(svg, isNot(contains('<polyline')));
  });

  test('exports omit elements on hidden layers', () async {
    final controller = CanvasController()
      ..setViewportSize(const Size(240, 180));
    addTearDown(controller.dispose);
    controller.placeText(
      worldCenter: const Offset(20, 20),
      text: 'Visible note',
    );
    final hiddenLayer = controller.addLayer(name: 'Hidden');
    controller.placeText(
      worldCenter: const Offset(80, 80),
      text: 'Private hidden note',
    );
    controller.setLayerVisible(hiddenLayer.id, visible: false);

    final Uint8List bytes = await CanvasExportService.renderToBytes(
      controller: controller,
      options: const CanvasExportOptions(
        format: CanvasExportFormat.svg,
        scale: 1,
        padding: 4,
        transparentBackground: true,
        includeGrid: false,
      ),
    );

    final String svg = utf8.decode(bytes);
    expect(svg, contains('Visible note'));
    expect(svg, isNot(contains('Private hidden note')));
  });

  test('SVG includes the paper grid only when requested', () async {
    final controller = controllerWithLine();
    addTearDown(controller.dispose);
    controller.setPaperStyle(
      const CanvasPaperStyle(kind: BackgroundKind.lined),
    );

    final String withGrid = utf8.decode(
      await CanvasExportService.renderToBytes(
        controller: controller,
        options: const CanvasExportOptions(
          format: CanvasExportFormat.svg,
          includeGrid: true,
          transparentBackground: true,
        ),
      ),
    );
    final String withoutGrid = utf8.decode(
      await CanvasExportService.renderToBytes(
        controller: controller,
        options: const CanvasExportOptions(
          format: CanvasExportFormat.svg,
          includeGrid: false,
          transparentBackground: true,
        ),
      ),
    );

    expect(withGrid, contains('id="canvas-grid"'));
    expect(withGrid, contains('data-kind="lined"'));
    expect(withoutGrid, isNot(contains('id="canvas-grid"')));
  });

  test('SVG rectangle and ellipse use their true geometry', () async {
    final controller = CanvasController()
      ..setViewportSize(const Size(240, 180))
      ..addElementToStore(
        const ShapeElement(
          id: 'rect',
          zIndex: 0,
          shapeKind: 1,
          start: Offset(10, 20),
          end: Offset(90, 70),
          color: 0xFFFFFFFF,
          strokeWidth: 4,
        ),
      )
      ..addElementToStore(
        const ShapeElement(
          id: 'ellipse',
          zIndex: 1,
          shapeKind: 2,
          start: Offset(120, 30),
          end: Offset(200, 80),
          color: 0xFFFFFFFF,
          strokeWidth: 4,
        ),
      );
    addTearDown(controller.dispose);

    final String svg = utf8.decode(
      await CanvasExportService.renderToBytes(
        controller: controller,
        options: const CanvasExportOptions(
          format: CanvasExportFormat.svg,
          scale: 1,
          padding: 0,
          transparentBackground: true,
          includeGrid: false,
        ),
      ),
    );

    expect(svg, contains('width="80.00" height="50.00"'));
    expect(svg, contains('rx="40.00" ry="25.00"'));
  });

  test('SVG preserves styled arrow bodies and both head styles', () async {
    final controller = CanvasController()
      ..setViewportSize(const Size(240, 180))
      ..addElementToStore(
        const ShapeElement(
          id: 'arrow',
          zIndex: 0,
          shapeKind: 3,
          start: Offset(10, 20),
          end: Offset(180, 90),
          color: 0xFFFF0000,
          strokeWidth: 5,
          arrowBody: ArrowBodyKind.curved,
          arrowStartHead: ArrowHeadStyle.dot,
          arrowEndHead: ArrowHeadStyle.diamond,
          arrowHeadScale: 1.3,
          controlPoints: [Offset(90, 0)],
          legacyArrow: false,
        ),
      );
    addTearDown(controller.dispose);

    final String svg = utf8.decode(
      await CanvasExportService.renderToBytes(
        controller: controller,
        options: const CanvasExportOptions(
          format: CanvasExportFormat.svg,
          transparentBackground: true,
          includeGrid: false,
        ),
      ),
    );

    expect(svg, contains('data-arrow-body="curved"'));
    expect(svg, contains('data-arrow-head="dot"'));
    expect(svg, contains('data-arrow-head="diamond"'));
  });

  test('SVG embeds rotated image and PDF rasters', () async {
    final imageRaster = await _solidImage(const Color(0xFFFF0000));
    final pdfRaster = await _solidImage(const Color(0xFF00FF00));
    final controller = CanvasController()
      ..setViewportSize(const Size(240, 180))
      ..addElementToStore(
        ImageElement(
          id: 'image',
          zIndex: 0,
          rotation: math.pi / 4,
          worldBounds: const Rect.fromLTWH(10, 10, 40, 30),
          sourceFilePath: '/private/image.png',
          intrinsicSize: const Size(4, 4),
          raster: imageRaster,
        ),
      )
      ..addElementToStore(
        PdfElement(
          id: 'pdf',
          zIndex: 1,
          rotation: -math.pi / 6,
          worldBounds: const Rect.fromLTWH(80, 10, 40, 50),
          sourceFilePath: '/private/document.pdf',
          pageNumber: 2,
          pageSize: const Size(40, 50),
          raster: pdfRaster,
          rasterScaleBucket: 1,
        ),
      );
    addTearDown(controller.dispose);

    final String svg = utf8.decode(
      await CanvasExportService.renderToBytes(
        controller: controller,
        options: const CanvasExportOptions(
          format: CanvasExportFormat.svg,
          transparentBackground: true,
          includeGrid: false,
        ),
      ),
    );

    expect(svg, contains('data-source-kind="image"'));
    expect(svg, contains('data-source-kind="pdf-page"'));
    expect(svg, contains('href="data:image/png;base64,'));
    expect(svg, contains('transform="rotate(45.000'));
    expect(svg, contains('transform="rotate(-30.000'));
    expect(svg, isNot(contains('/private/image.png')));
    expect(svg, isNot(contains('/private/document.pdf')));
  });

  test('raster export loads a missing image raster from its source', () async {
    final Directory temp = await Directory.systemTemp.createTemp(
      'zenno_export_test_',
    );
    addTearDown(() => temp.delete(recursive: true));
    final Image source = await _solidImage(const Color(0xFFFF0000));
    final ByteData data = (await source.toByteData(
      format: ImageByteFormat.png,
    ))!;
    source.dispose();
    final File file = File('${temp.path}/red.png');
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    final controller = CanvasController()
      ..setViewportSize(const Size(20, 20))
      ..addElementToStore(
        ImageElement(
          id: 'image',
          zIndex: 0,
          worldBounds: const Rect.fromLTWH(0, 0, 10, 10),
          sourceFilePath: file.path,
          intrinsicSize: const Size(4, 4),
        ),
      );
    addTearDown(controller.dispose);

    final Uint8List bytes = await CanvasExportService.renderToBytes(
      controller: controller,
      options: const CanvasExportOptions(
        scale: 1,
        padding: 0,
        transparentBackground: true,
        includeGrid: false,
      ),
    );
    final Codec codec = await instantiateImageCodec(bytes);
    final FrameInfo frame = await codec.getNextFrame();
    codec.dispose();
    final ByteData rgba = (await frame.image.toByteData(
      format: ImageByteFormat.rawRgba,
    ))!;
    final int center = (5 * frame.image.width + 5) * 4;

    expect(rgba.getUint8(center), greaterThan(240));
    expect(rgba.getUint8(center + 1), lessThan(15));
    expect(rgba.getUint8(center + 2), lessThan(15));
    frame.image.dispose();
  });

  test(
    'raster export fails clearly instead of painting media placeholders',
    () {
      final controller = CanvasController()
        ..setViewportSize(const Size(20, 20))
        ..addElementToStore(
          const ImageElement(
            id: 'missing-image',
            zIndex: 0,
            worldBounds: Rect.fromLTWH(0, 0, 10, 10),
            sourceFilePath: '/does/not/exist.png',
            intrinsicSize: Size(10, 10),
          ),
        );
      addTearDown(controller.dispose);

      expect(
        () => CanvasExportService.renderToBytes(
          controller: controller,
          options: const CanvasExportOptions(includeGrid: false),
        ),
        throwsA(
          isA<CanvasExportException>().having(
            (error) => error.message,
            'message',
            contains('Could not load image'),
          ),
        ),
      );
    },
  );

  test('raster export reports an unavailable PDF page', () {
    final controller = CanvasController()
      ..setViewportSize(const Size(20, 20))
      ..addElementToStore(
        const PdfElement(
          id: 'missing-pdf',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(0, 0, 10, 10),
          sourceFilePath: '/does/not/exist.pdf',
          pageNumber: 1,
          pageSize: Size(10, 10),
        ),
      );
    addTearDown(controller.dispose);

    expect(
      () => CanvasExportService.renderToBytes(
        controller: controller,
        options: const CanvasExportOptions(includeGrid: false),
      ),
      throwsA(
        isA<CanvasExportException>().having(
          (error) => error.message,
          'message',
          contains('Could not load PDF'),
        ),
      ),
    );
  });
}

Future<Image> _solidImage(Color color) async {
  final PictureRecorder recorder = PictureRecorder();
  Canvas(
    recorder,
  ).drawRect(const Rect.fromLTWH(0, 0, 4, 4), Paint()..color = color);
  final Picture picture = recorder.endRecording();
  final Image image = await picture.toImage(4, 4);
  picture.dispose();
  return image;
}
