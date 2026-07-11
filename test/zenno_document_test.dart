import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/io/zenno_document.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/canvas_style.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/core/database/tables/canvas_tables.dart';

void main() {
  test('encodes and decodes a versioned Zenno canvas document', () {
    final controller = CanvasController()
      ..setPaperStyle(
        const CanvasPaperStyle(
          kind: BackgroundKind.isometric,
          gridSpacing: 32,
          gridOpacity: 0.25,
        ),
      );
    addTearDown(controller.dispose);
    final layer = controller.addLayer(name: 'Sketch');
    controller.setActiveLayer(layer.id);
    controller.addElementToStore(
      InkElement.fromStroke(
        const Stroke(
          id: 'ink-doc',
          points: <StrokePoint>[
            StrokePoint(
              1,
              2,
              0.5,
              tiltX: 0.1,
              tiltY: 0.2,
              azimuth: 0.3,
              timestampMicros: 123,
              velocity: 45,
            ),
            StrokePoint(10, 20, 0.75),
          ],
          color: 0xFF112233,
          width: 4,
        ),
        zIndex: 0,
        layerId: layer.id,
      ),
    );
    controller.addElementToStore(
      const TextElement(
        id: 'text-doc',
        zIndex: 1,
        layerId: 'memory:content',
        rotation: 0.5,
        worldBounds: Rect.fromLTWH(10, 20, 100, 40),
        text: 'Native format',
        color: 0xFFFFFFFF,
        fontSize: 18,
      ),
    );

    final Uint8List bytes = ZennoDocumentCodec.encodeController(controller);
    final ZennoDocument document = ZennoDocumentCodec.decodeDocument(bytes);

    expect(document.version, ZennoDocumentCodec.currentVersion);
    expect(document.paperStyle.kind, BackgroundKind.isometric);
    expect(document.layers.map((layer) => layer.name), contains('Sketch'));
    expect(document.elements, hasLength(2));
    final InkElement ink = document.elements.whereType<InkElement>().single;
    expect(ink.layerId, layer.id);
    expect(ink.stroke.points.first.tiltX, 0.1);
    final TextElement text = document.elements.whereType<TextElement>().single;
    expect(text.rotation, 0.5);
    expect(text.placementBounds, const Rect.fromLTWH(10, 20, 100, 40));
  });

  test('rejects non-Zenno payloads', () {
    expect(
      () =>
          ZennoDocumentCodec.decodeDocument(Uint8List.fromList('{}'.codeUnits)),
      throwsFormatException,
    );
  });
}
