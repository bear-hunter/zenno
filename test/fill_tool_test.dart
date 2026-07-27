import 'dart:convert' show utf8;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/engine/spatial_index.dart';
import 'package:zenno/canvas/engine/stroke_builder.dart';
import 'package:zenno/canvas/input/pen_profile.dart';
import 'package:zenno/canvas/io/canvas_export.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/render/canvas_view.dart';
import 'package:zenno/canvas/render/elements_painter.dart';
import 'package:zenno/canvas/render/live_stroke_painter.dart';

const List<StrokePoint> _squarePoints = <StrokePoint>[
  StrokePoint(20, 20, 0.8),
  StrokePoint(120, 20, 0.8),
  StrokePoint(120, 120, 0.8),
  StrokePoint(20, 120, 0.8),
];

Stroke _fillStroke({String id = 'fill'}) => Stroke(
  id: id,
  points: _squarePoints,
  color: 0xFFFF0000,
  width: 16,
  tool: StrokeToolKind.fill,
);

InkElement _fillElement({String id = 'fill'}) =>
    InkElement.fromStroke(_fillStroke(id: id), zIndex: 0);

SpatialIndex _indexFor(CanvasElement element) =>
    SpatialIndex()..insert(element.id, element.worldBounds);

Future<ui.Color> _paintedPixel(
  CustomPainter painter,
  Offset point, {
  Size size = const Size(160, 160),
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  painter.paint(canvas, size);
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(
    size.width.toInt(),
    size.height.toInt(),
  );
  picture.dispose();
  final ByteData data = (await image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  ))!;
  image.dispose();
  final int offset =
      (point.dy.toInt() * size.width.toInt() + point.dx.toInt()) * 4;
  return ui.Color.fromARGB(
    data.getUint8(offset + 3),
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('freeform fill geometry', () {
    test('builds a closed region and rejects degenerate boundaries', () {
      final Path path = buildFillBoundaryPath(_squarePoints);

      expect(path.contains(const Offset(70, 70)), isTrue);
      expect(path.contains(const Offset(150, 70)), isFalse);
      expect(isValidFillBoundary(_squarePoints), isTrue);
      expect(
        isValidFillBoundary(const <StrokePoint>[
          StrokePoint(0, 0, 1),
          StrokePoint(20, 20, 1),
          StrokePoint(40, 40, 1),
        ]),
        isFalse,
      );
    });

    test('InkElement uses the fill region for its path and exact bounds', () {
      final InkElement element = _fillElement();

      expect(element.outlinePath.contains(const Offset(70, 70)), isTrue);
      expect(element.outlinePath.contains(const Offset(140, 70)), isFalse);
      expect(element.worldBounds, const Rect.fromLTRB(20, 20, 120, 120));
    });
  });

  group('fill controller lifecycle', () {
    test('commits one undoable fill and hit-tests its interior', () {
      final CanvasController controller = CanvasController()
        ..setPenKind(StrokeToolKind.fill);
      addTearDown(controller.dispose);

      controller.beginStroke(const Offset(20, 20), 0.8);
      for (final StrokePoint point in _squarePoints.skip(1)) {
        controller.appendToStroke(point.offset, point.pressure);
      }
      controller.endStroke();

      expect(controller.elements, hasLength(1));
      final InkElement element = controller.elements.single as InkElement;
      expect(element.stroke.tool, StrokeToolKind.fill);
      expect(element.stroke.points.first.pressure, 0.8);
      expect(controller.elementAt(const Offset(70, 70)), same(element));
      expect(controller.elementAt(const Offset(150, 70)), isNull);

      controller.undo();
      expect(controller.elements, isEmpty);
      controller.redo();
      expect(controller.elements, hasLength(1));
    });

    test('does not commit a tap or a collinear fill gesture', () {
      final CanvasController controller = CanvasController()
        ..setPenKind(StrokeToolKind.fill);
      addTearDown(controller.dispose);

      controller
        ..beginStroke(const Offset(10, 10), 0.5)
        ..endStroke()
        ..beginStroke(const Offset(10, 10), 0.5)
        ..appendToStroke(const Offset(40, 40), 0.5)
        ..appendToStroke(const Offset(80, 80), 0.5)
        ..endStroke();

      expect(controller.elements, isEmpty);
      expect(controller.canUndo, isFalse);
    });

    test('partial eraser removes a fill atomically and undo restores it', () {
      final CanvasController controller = CanvasController()
        ..addElementToStore(_fillElement())
        ..setEraserMode(EraserMode.partial)
        ..beginErase(const Offset(70, 70))
        ..endErase();
      addTearDown(controller.dispose);

      expect(controller.elements, isEmpty);
      controller.undo();
      expect(controller.elements.single, isA<InkElement>());
      expect(
        (controller.elements.single as InkElement).stroke.tool,
        StrokeToolKind.fill,
      );
    });
  });

  testWidgets('stylus traces and commits fill through the pen input route', (
    WidgetTester tester,
  ) async {
    final CanvasController controller = CanvasController()
      ..setPenKind(StrokeToolKind.fill)
      ..setPenProfile(const PenProfile(stabilizer: 0, smoothing: 0));
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 200,
          height: 200,
          child: CanvasView(controller: controller),
        ),
      ),
    );

    final Offset origin = tester.getTopLeft(find.byType(CanvasView));
    final TestGesture stylus = await tester.createGesture(
      kind: PointerDeviceKind.stylus,
    );
    await stylus.down(origin + const Offset(20, 20));
    await stylus.moveTo(origin + const Offset(120, 20));
    await stylus.moveTo(origin + const Offset(120, 120));
    await stylus.moveTo(origin + const Offset(20, 120));
    await stylus.up();
    await tester.pump();

    expect(controller.elements, hasLength(1));
    final InkElement fill = controller.elements.single as InkElement;
    expect(fill.stroke.tool, StrokeToolKind.fill);
    expect(fill.outlinePath.contains(const Offset(70, 70)), isTrue);
  });

  group('fill rendering and export', () {
    test('live painter fills the traced interior', () async {
      final ui.Color inside = await _paintedPixel(
        LiveStrokePainter(
          liveStroke: _fillStroke(),
          liveStrokeRevision: 1,
          viewport: ViewportState.initial,
        ),
        const Offset(70, 70),
      );
      final ui.Color outside = await _paintedPixel(
        LiveStrokePainter(
          liveStroke: _fillStroke(),
          liveStrokeRevision: 1,
          viewport: ViewportState.initial,
        ),
        const Offset(150, 70),
      );

      expect(inside.a, 1);
      expect(inside.r, 1);
      expect(outside.a, 0);
    });

    test('committed painter fills the traced interior', () async {
      final InkElement element = _fillElement();
      final ElementsPainter painter = ElementsPainter(
        elements: <CanvasElement>[element],
        spatialIndex: _indexFor(element),
        viewport: ViewportState.initial,
      );

      final ui.Color inside = await _paintedPixel(
        painter,
        const Offset(70, 70),
      );
      final ui.Color outside = await _paintedPixel(
        painter,
        const Offset(150, 70),
      );

      expect(inside.a, 1);
      expect(inside.r, 1);
      expect(outside.a, 0);
    });

    test('SVG export retains the closed fill polygon and colour', () async {
      final CanvasController controller = CanvasController()
        ..setViewportSize(const Size(160, 160))
        ..addElementToStore(_fillElement());
      addTearDown(controller.dispose);

      final String svg = utf8.decode(
        await CanvasExportService.renderToBytes(
          controller: controller,
          options: const CanvasExportOptions(
            format: CanvasExportFormat.svg,
            padding: 0,
            transparentBackground: true,
            includeGrid: false,
          ),
        ),
      );

      expect(svg, contains('<path data-ink-outline="true"'));
      expect(svg, contains(' Z" fill="#FF0000"'));
      expect(svg, contains('opacity="1.00"'));
      expect(svg, contains('fill-rule="evenodd"'));
    });
  });
}
