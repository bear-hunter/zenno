import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/canvas_layer.dart';
import 'package:zenno/canvas/model/canvas_style.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/persistence/canvas_repository.dart';
import 'package:zenno/core/database/database.dart'
    hide CanvasElement, CanvasLayer;
import 'package:zenno/core/database/tables/canvas_tables.dart'
    show BackgroundKind, PaperTexture;

const double _pointTolerance = 1e-6;

void main() {
  late ZennoDatabase db;
  late CanvasRepository repo;
  const String canvasId = 'canvas-under-test';

  setUp(() async {
    db = ZennoDatabase(NativeDatabase.memory());
    repo = CanvasRepository(db);
    // A parent canvas row must exist for the element/viewport foreign keys.
    await repo.ensureCanvasExists(canvasId, title: 'Test canvas');
  });

  tearDown(() async {
    await db.close();
  });

  group('ensureCanvasExists', () {
    test('creates a row once, then reports it already exists', () async {
      const String fresh = 'a-brand-new-canvas';
      expect(await repo.canvasExists(fresh), isFalse);
      expect(await repo.ensureCanvasExists(fresh), isTrue);
      expect(await repo.canvasExists(fresh), isTrue);
      expect(await repo.ensureCanvasExists(fresh), isFalse);
    });

    test('controller load does not recreate a deleted canvas', () async {
      const String deleted = 'deleted-canvas';
      final controller = CanvasController(repository: repo, canvasId: deleted);
      addTearDown(controller.dispose);

      await expectLater(
        controller.load(),
        throwsA(isA<CanvasNotFoundException>()),
      );

      expect(await repo.canvasExists(deleted), isFalse);
      expect(controller.isLoaded, isFalse);
    });
  });

  group('paper style', () {
    test('texture and intensity persist per canvas', () async {
      const style = CanvasPaperStyle(
        kind: BackgroundKind.lined,
        backgroundColor: 0xFFF7F1DE,
        gridColor: 0xFF6B7280,
        texture: PaperTexture.fibers,
        textureOpacity: 0.11,
      );

      await repo.savePaperStyle(canvasId, style);

      expect(await repo.loadPaperStyle(canvasId), style);
    });
  });

  group('layers', () {
    test('ensureCanvasExists creates a default content layer', () async {
      final layers = await repo.loadLayers(canvasId);

      expect(layers, hasLength(1));
      expect(layers.single.id, CanvasLayer.defaultContentLayerId(canvasId));
      expect(layers.single.name, 'Notes');
      expect(layers.single.visible, isTrue);
      expect(layers.single.locked, isFalse);
    });

    test('custom layer assignment round-trips on an element', () async {
      const layer = CanvasLayer(
        id: 'layer-sketch',
        canvasId: canvasId,
        name: 'Sketch',
        position: 1,
      );
      await repo.upsertLayer(layer);
      const original = ImageElement(
        id: 'layered-img',
        zIndex: 0,
        layerId: 'layer-sketch',
        worldBounds: Rect.fromLTWH(0, 0, 10, 10),
        sourceFilePath: '/m/layered.png',
        intrinsicSize: Size(10, 10),
      );

      await repo.upsertElement(canvasId, original);

      final loaded = await repo.loadElements(canvasId);
      expect(loaded.single.layerId, 'layer-sketch');
    });

    test('updating a layer preserves its element assignments', () async {
      const layer = CanvasLayer(
        id: 'layer-sketch',
        canvasId: canvasId,
        name: 'Sketch',
        position: 1,
      );
      await repo.upsertLayer(layer);
      await repo.upsertElement(
        canvasId,
        const ImageElement(
          id: 'layered-img',
          zIndex: 0,
          layerId: 'layer-sketch',
          worldBounds: Rect.fromLTWH(0, 0, 10, 10),
          sourceFilePath: '/m/layered.png',
          intrinsicSize: Size(10, 10),
        ),
      );

      await repo.upsertLayer(layer.copyWith(visible: false));

      final row = await (db.select(
        db.canvasElements,
      )..where((element) => element.id.equals('layered-img'))).getSingle();
      final loaded = await repo.loadElements(canvasId);
      expect(row.layerId, 'layer-sketch');
      expect(loaded.single.layerId, 'layer-sketch');
    });

    test('batch layer updates roll back together on failure', () async {
      const layer = CanvasLayer(
        id: 'layer-sketch',
        canvasId: canvasId,
        name: 'Sketch',
        position: 1,
      );
      await repo.upsertLayer(layer);

      await expectLater(
        repo.upsertLayers([
          layer.copyWith(visible: false),
          const CanvasLayer(
            id: 'invalid-layer',
            canvasId: 'missing-canvas',
            name: 'Invalid',
            position: 2,
          ),
        ]),
        throwsA(anything),
      );

      final stored = await (db.select(
        db.canvasLayers,
      )..where((candidate) => candidate.id.equals(layer.id))).getSingle();
      expect(stored.visible, isTrue);
    });
  });

  group('viewport round-trip', () {
    test('a never-saved canvas loads the identity viewport', () async {
      final ViewportState? vp = await repo.loadViewport(canvasId);
      expect(vp, ViewportState.initial);
    });

    test('save then load returns the same viewport', () async {
      const ViewportState saved = ViewportState(
        translation: Offset(-321.5, 88.25),
        scale: 2.5,
        rotation: 0.7853981633974483,
      );

      await repo.saveViewport(canvasId, saved);
      final ViewportState? loaded = await repo.loadViewport(canvasId);

      expect(loaded, saved);
    });

    test('loadViewport returns null for an unknown canvas', () async {
      expect(await repo.loadViewport('no-such-canvas'), isNull);
    });
  });

  test('bookmarks persist across controller reload and removal', () async {
    final first = CanvasController(repository: repo, canvasId: canvasId);
    await first.load();
    first.setViewport(
      const ViewportState(
        translation: Offset(120, -80),
        scale: 2.5,
        rotation: 0.25,
      ),
    );
    first.saveBookmark('Diagram');
    await first.flush();
    first.dispose();

    final second = CanvasController(repository: repo, canvasId: canvasId);
    await second.load();
    expect(second.bookmarks, hasLength(1));
    expect(second.bookmarks.single.name, 'Diagram');
    expect(
      second.bookmarks.single.viewport,
      const ViewportState(
        translation: Offset(120, -80),
        scale: 2.5,
        rotation: 0.25,
      ),
    );

    second.removeBookmark(second.bookmarks.single);
    await second.flush();
    second.dispose();

    expect(await repo.loadBookmarks(canvasId), isEmpty);
  });

  group('ink element round-trip', () {
    test('save then load reconstructs the InkElement', () async {
      const stroke = Stroke(
        id: 'ink-1',
        points: <StrokePoint>[
          StrokePoint(10, 20, 0.1),
          StrokePoint(
            11,
            22,
            0.4,
            tiltX: 0.12,
            tiltY: 0.25,
            azimuth: 1.2,
            timestampMicros: 1000,
            velocity: 42,
          ),
          StrokePoint(15.5, 30.25, 0.95),
        ],
        color: 0xFFAB12CD,
        width: 6.5,
        tool: StrokeToolKind.highlighter,
      );
      final original = InkElement.fromStroke(stroke, zIndex: 3);

      await repo.upsertElement(canvasId, original);
      final List<CanvasElement> loaded = await repo.loadElements(canvasId);

      expect(loaded, hasLength(1));
      final CanvasElement element = loaded.single;
      expect(element, isA<InkElement>());
      final InkElement ink = element as InkElement;
      expect(ink.id, 'ink-1');
      expect(ink.zIndex, 3);
      expect(ink.stroke.color, 0xFFAB12CD);
      expect(ink.stroke.width, closeTo(6.5, 1e-6));
      expect(ink.stroke.tool, StrokeToolKind.highlighter);
      expect(ink.stroke.points, hasLength(3));
      for (var i = 0; i < stroke.points.length; i++) {
        expect(
          ink.stroke.points[i].x,
          closeTo(stroke.points[i].x, _pointTolerance),
        );
        expect(
          ink.stroke.points[i].y,
          closeTo(stroke.points[i].y, _pointTolerance),
        );
        expect(
          ink.stroke.points[i].pressure,
          closeTo(stroke.points[i].pressure, _pointTolerance),
        );
        expect(
          ink.stroke.points[i].tiltX,
          closeTo(stroke.points[i].tiltX, _pointTolerance),
        );
        expect(
          ink.stroke.points[i].tiltY,
          closeTo(stroke.points[i].tiltY, _pointTolerance),
        );
        expect(
          ink.stroke.points[i].azimuth,
          closeTo(stroke.points[i].azimuth, _pointTolerance),
        );
        expect(
          ink.stroke.points[i].timestampMicros,
          stroke.points[i].timestampMicros,
        );
        expect(
          ink.stroke.points[i].velocity,
          closeTo(stroke.points[i].velocity, _pointTolerance),
        );
      }
    });

    test('new brush families persist through the stroke tool column', () async {
      final original = InkElement.fromStroke(
        const Stroke(
          id: 'ink-marker',
          points: <StrokePoint>[
            StrokePoint(0, 0, 0.5),
            StrokePoint(10, 10, 0.5),
          ],
          color: 0xFF112233,
          width: 8,
          tool: StrokeToolKind.marker,
        ),
        zIndex: 1,
      );

      await repo.upsertElement(canvasId, original);
      final loaded = (await repo.loadElements(canvasId)).single as InkElement;

      expect(loaded.stroke.tool, StrokeToolKind.marker);
    });

    test('freeform fill persists through the stroke tool column', () async {
      final original = InkElement.fromStroke(
        const Stroke(
          id: 'ink-fill',
          points: <StrokePoint>[
            StrokePoint(0, 0, 0.5),
            StrokePoint(30, 0, 0.5),
            StrokePoint(20, 20, 0.5),
            StrokePoint(0, 0, 0.5),
          ],
          color: 0x88F2C94C,
          width: 1,
          tool: StrokeToolKind.fill,
        ),
        zIndex: 1,
      );

      await repo.upsertElement(canvasId, original);
      final loaded = (await repo.loadElements(canvasId)).single as InkElement;

      expect(loaded.stroke.tool, StrokeToolKind.fill);
      expect(loaded.stroke.color, 0x88F2C94C);
      expect(loaded.stroke.points, original.stroke.points);
    });
  });

  group('image element round-trip', () {
    test('save then load reconstructs the ImageElement', () async {
      const original = ImageElement(
        id: 'img-1',
        zIndex: 5,
        worldBounds: Rect.fromLTWH(100, 200, 400, 300),
        sourceFilePath: '/docs/canvas_media/pic.png',
        intrinsicSize: Size(1600, 1200),
      );

      await repo.upsertElement(canvasId, original);
      final List<CanvasElement> loaded = await repo.loadElements(canvasId);

      expect(loaded, hasLength(1));
      final CanvasElement element = loaded.single;
      expect(element, isA<ImageElement>());
      final ImageElement image = element as ImageElement;
      expect(image.id, 'img-1');
      expect(image.zIndex, 5);
      expect(image.worldBounds, const Rect.fromLTWH(100, 200, 400, 300));
      expect(image.sourceFilePath, '/docs/canvas_media/pic.png');
      expect(image.intrinsicSize, const Size(1600, 1200));
      // The runtime raster is never persisted — it reloads as null.
      expect(image.raster, isNull);
    });
  });

  group('pdf element round-trip', () {
    test('save then load reconstructs the PdfElement', () async {
      const original = PdfElement(
        id: 'pdf-1',
        zIndex: 7,
        worldBounds: Rect.fromLTWH(0, 0, 595, 842),
        sourceFilePath: '/docs/canvas_media/notes.pdf',
        pageNumber: 4,
        pageSize: Size(595, 842),
      );

      await repo.upsertElement(canvasId, original);
      final List<CanvasElement> loaded = await repo.loadElements(canvasId);

      expect(loaded, hasLength(1));
      final CanvasElement element = loaded.single;
      expect(element, isA<PdfElement>());
      final PdfElement pdf = element as PdfElement;
      expect(pdf.id, 'pdf-1');
      expect(pdf.zIndex, 7);
      expect(pdf.worldBounds, const Rect.fromLTWH(0, 0, 595, 842));
      expect(pdf.sourceFilePath, '/docs/canvas_media/notes.pdf');
      expect(pdf.pageNumber, 4);
      expect(pdf.pageSize, const Size(595, 842));
      expect(pdf.raster, isNull);
    });
  });

  group('link element round-trip', () {
    test(
      'a plain canvas link round-trips with a null target viewport',
      () async {
        const original = LinkElement(
          id: 'link-1',
          zIndex: 2,
          worldBounds: Rect.fromLTWH(50, 60, 220, 56),
          label: 'See the diagram',
          target: LinkTarget(targetCanvasId: 'other-canvas'),
        );

        await repo.upsertElement(canvasId, original);
        final List<CanvasElement> loaded = await repo.loadElements(canvasId);

        expect(loaded, hasLength(1));
        final LinkElement link = loaded.single as LinkElement;
        expect(link.id, 'link-1');
        expect(link.zIndex, 2);
        expect(link.worldBounds, const Rect.fromLTWH(50, 60, 220, 56));
        expect(link.label, 'See the diagram');
        expect(link.target.targetCanvasId, 'other-canvas');
        expect(link.target.targetViewport, isNull);
      },
    );

    test(
      'a region link round-trips its full target viewport losslessly',
      () async {
        const ViewportState targetVp = ViewportState(
          translation: Offset(-12.5, 99.75),
          scale: 3.25,
          rotation: 1.5707963267948966,
        );
        const original = LinkElement(
          id: 'link-region',
          zIndex: 9,
          worldBounds: Rect.fromLTWH(0, 0, 220, 56),
          label: 'Jump to region',
          target: LinkTarget(
            targetCanvasId: 'canvas-under-test',
            targetViewport: targetVp,
          ),
        );

        await repo.upsertElement(canvasId, original);
        final List<CanvasElement> loaded = await repo.loadElements(canvasId);

        final LinkElement link = loaded.single as LinkElement;
        expect(link.target.targetCanvasId, 'canvas-under-test');
        expect(link.target.targetViewport, targetVp);
      },
    );
  });

  group('text element round-trip', () {
    test('save then load reconstructs the TextElement', () async {
      const original = TextElement(
        id: 'text-1',
        zIndex: 6,
        worldBounds: Rect.fromLTWH(40, 50, 320, 180),
        text: 'First line\nSecond line',
        color: 0xFFE8B84B,
        fontSize: 22,
      );

      await repo.upsertElement(canvasId, original);
      final List<CanvasElement> loaded = await repo.loadElements(canvasId);

      expect(loaded, hasLength(1));
      final TextElement note = loaded.single as TextElement;
      expect(note.id, 'text-1');
      expect(note.zIndex, 6);
      expect(note.worldBounds, const Rect.fromLTWH(40, 50, 320, 180));
      expect(note.text, 'First line\nSecond line');
      expect(note.color, 0xFFE8B84B);
      expect(note.fontSize, 22);
    });

    test('rotation round-trips without inflating placement bounds', () async {
      const original = TextElement(
        id: 'text-rotated',
        zIndex: 6,
        rotation: 0.7853981633974483,
        worldBounds: Rect.fromLTWH(-50, -10, 100, 20),
        text: 'Rotated',
        color: 0xFFE8B84B,
        fontSize: 22,
      );

      await repo.upsertElement(canvasId, original);
      final firstLoad =
          (await repo.loadElements(canvasId)).single as TextElement;
      await repo.upsertElement(canvasId, firstLoad);
      final secondLoad =
          (await repo.loadElements(canvasId)).single as TextElement;

      expect(firstLoad.rotation, closeTo(original.rotation, 1e-12));
      expect(firstLoad.placementBounds, original.placementBounds);
      expect(secondLoad.placementBounds, original.placementBounds);
      expect(secondLoad.worldBounds, original.worldBounds);
    });
  });

  group('tool settings', () {
    test('default pen width mode is Screen', () async {
      final settings = await repo.loadToolSettings(canvasId);

      expect(settings.penWidthMode, PenWidthMode.screen);
    });

    test('save then load preserves Canvas pen width mode', () async {
      await repo.saveToolSettings(
        canvasId,
        const CanvasToolSettings(
          penColor: 0xFFABCDEF,
          penWidth: 12,
          penWidthMode: PenWidthMode.canvas,
          penKind: StrokeToolKind.marker,
          pressureEnabled: false,
        ),
      );

      final settings = await repo.loadToolSettings(canvasId);

      expect(settings.penColor, 0xFFABCDEF);
      expect(settings.penWidth, 12);
      expect(settings.penWidthMode, PenWidthMode.canvas);
      expect(settings.penKind, StrokeToolKind.marker);
      expect(settings.pressureEnabled, isFalse);
    });

    test(
      'save then load preserves all eight independent wheel favorites',
      () async {
        final presets = List<ToolWheelPreset>.of(defaultToolWheelPresets);
        presets[0] = presets[0].copyWith(
          color: 0xFF123456,
          size: 7,
          opacity: 0.6,
          smoothing: 0.8,
        );
        presets[1] = defaultToolWheelPresetFor(
          ToolWheelSlotKind.pen,
        ).copyWith(size: 2);
        presets[7] = defaultToolWheelPresetFor(ToolWheelSlotKind.pan);

        await repo.saveToolSettings(
          canvasId,
          CanvasToolSettings(
            penColor: 0x99123456,
            penWidth: 7,
            toolWheelPresets: presets,
            activeToolWheelIndex: 7,
          ),
        );

        final settings = await repo.loadToolSettings(canvasId);

        expect(settings.activeToolWheelIndex, 7);
        expect(settings.toolWheelPresets, hasLength(8));
        expect(settings.toolWheelPresets[0], presets[0]);
        expect(settings.toolWheelPresets[1], presets[1]);
        expect(settings.toolWheelPresets[7].kind, ToolWheelSlotKind.pan);
      },
    );

    test(
      'continuous brush changes collapse to one final settings write',
      () async {
        final countingRepo = _CountingCanvasRepository(db);
        final controller = CanvasController(
          repository: countingRepo,
          canvasId: canvasId,
        );
        addTearDown(controller.dispose);
        await controller.load();

        controller
          ..setPenWidth(8)
          ..setPenWidth(12)
          ..setPenWidth(16)
          ..commitToolSettings();
        await controller.flush();

        expect(countingRepo.toolSettingsWriteCount, 1);
        expect((await repo.loadToolSettings(canvasId)).penWidth, 16);
      },
    );
  });

  group('mixed canvas', () {
    test('round-trips ink + image + pdf + text + link in z-order', () async {
      final ink = InkElement.fromStroke(
        const Stroke(
          id: 'e-ink',
          points: <StrokePoint>[StrokePoint(0, 0, 0.5), StrokePoint(5, 5, 0.5)],
          color: 0xFF112233,
          width: 3,
        ),
        zIndex: 0,
      );
      const image = ImageElement(
        id: 'e-img',
        zIndex: 1,
        worldBounds: Rect.fromLTWH(10, 10, 100, 80),
        sourceFilePath: '/m/a.jpg',
        intrinsicSize: Size(200, 160),
      );
      const pdf = PdfElement(
        id: 'e-pdf',
        zIndex: 2,
        worldBounds: Rect.fromLTWH(0, 200, 300, 400),
        sourceFilePath: '/m/b.pdf',
        pageNumber: 1,
        pageSize: Size(300, 400),
      );
      const link = LinkElement(
        id: 'e-link',
        zIndex: 4,
        worldBounds: Rect.fromLTWH(400, 0, 220, 56),
        label: 'Go',
        target: LinkTarget(targetCanvasId: 'dest'),
      );
      const text = TextElement(
        id: 'e-text',
        zIndex: 3,
        worldBounds: Rect.fromLTWH(100, 100, 320, 180),
        text: 'Remember this',
        color: 0xFFFFFFFF,
        fontSize: 22,
      );

      // Insert deliberately out of z-order.
      await repo.upsertElement(canvasId, link);
      await repo.upsertElement(canvasId, ink);
      await repo.upsertElement(canvasId, pdf);
      await repo.upsertElement(canvasId, image);
      await repo.upsertElement(canvasId, text);

      final List<CanvasElement> loaded = await repo.loadElements(canvasId);

      expect(loaded, hasLength(5));
      // Loaded ordered by z_index ascending.
      expect(loaded.map((e) => e.id).toList(), <String>[
        'e-ink',
        'e-img',
        'e-pdf',
        'e-text',
        'e-link',
      ]);
      expect(loaded[0], isA<InkElement>());
      expect(loaded[1], isA<ImageElement>());
      expect(loaded[2], isA<PdfElement>());
      expect(loaded[3], isA<TextElement>());
      expect(loaded[4], isA<LinkElement>());
    });

    test('a viewport and elements persist together on one canvas', () async {
      const ViewportState vp = ViewportState(
        translation: Offset(1, 2),
        scale: 1.5,
      );
      await repo.saveViewport(canvasId, vp);
      await repo.upsertElement(
        canvasId,
        const ImageElement(
          id: 'img-x',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(0, 0, 10, 10),
          sourceFilePath: '/m/x.png',
          intrinsicSize: Size(10, 10),
        ),
      );

      expect(await repo.loadViewport(canvasId), vp);
      expect(await repo.loadElements(canvasId), hasLength(1));
    });
  });

  group('upsertElement', () {
    test('re-upserting the same id updates rather than duplicates', () async {
      const first = ImageElement(
        id: 'img-update',
        zIndex: 0,
        worldBounds: Rect.fromLTWH(0, 0, 100, 100),
        sourceFilePath: '/m/before.png',
        intrinsicSize: Size(100, 100),
      );
      await repo.upsertElement(canvasId, first);

      // Same id, moved + different source.
      const second = ImageElement(
        id: 'img-update',
        zIndex: 0,
        worldBounds: Rect.fromLTWH(500, 500, 100, 100),
        sourceFilePath: '/m/after.png',
        intrinsicSize: Size(100, 100),
      );
      await repo.upsertElement(canvasId, second);

      final List<CanvasElement> loaded = await repo.loadElements(canvasId);
      expect(loaded, hasLength(1));
      final ImageElement image = loaded.single as ImageElement;
      expect(image.worldBounds, const Rect.fromLTWH(500, 500, 100, 100));
      expect(image.sourceFilePath, '/m/after.png');
    });
  });

  group('deleteElement', () {
    test('removes the element and (via cascade) its detail row', () async {
      final ink = InkElement.fromStroke(
        const Stroke(
          id: 'del-ink',
          points: <StrokePoint>[StrokePoint(0, 0, 0.5)],
          color: 0xFF000000,
          width: 2,
        ),
        zIndex: 0,
      );
      await repo.upsertElement(canvasId, ink);
      expect(await repo.loadElements(canvasId), hasLength(1));

      await repo.deleteElement('del-ink');

      expect(await repo.loadElements(canvasId), isEmpty);
      // The cascade should have removed the ink_strokes detail row too.
      final inkRows = await db.select(db.inkStrokes).get();
      expect(inkRows, isEmpty);
    });

    test('deleting an unknown id is a harmless no-op', () async {
      await repo.deleteElement('never-existed');
      expect(await repo.loadElements(canvasId), isEmpty);
    });
  });

  group('shape elements', () {
    test('round-trip save then load reconstructs the ShapeElement', () async {
      const shape = ShapeElement(
        id: 'shape-arrow',
        zIndex: 7,
        shapeKind: 3,
        start: Offset(10, 20),
        end: Offset(110, 80),
        color: 0xFF1E9BFF,
        strokeWidth: 6,
      );

      await repo.upsertElement(canvasId, shape);

      final loaded = await repo.loadElements(canvasId);
      expect(loaded, hasLength(1));
      final roundTripped = loaded.single as ShapeElement;
      expect(roundTripped.id, shape.id);
      expect(roundTripped.zIndex, shape.zIndex);
      expect(roundTripped.shapeKind, shape.shapeKind);
      expect(roundTripped.start, shape.start);
      expect(roundTripped.end, shape.end);
      expect(roundTripped.color, shape.color);
      expect(roundTripped.strokeWidth, shape.strokeWidth);
      expect(roundTripped.arrowEndHead, ArrowHeadStyle.filled);
      expect(roundTripped.legacyArrow, isTrue);
    });

    test('styled arrow fields round-trip without legacy rendering', () async {
      const shape = ShapeElement(
        id: 'shape-styled-arrow',
        zIndex: 8,
        shapeKind: 3,
        start: Offset(10, 20),
        end: Offset(110, 80),
        color: 0xFF1E9BFF,
        strokeWidth: 6,
        arrowBody: ArrowBodyKind.curved,
        arrowStartHead: ArrowHeadStyle.dot,
        arrowEndHead: ArrowHeadStyle.open,
        arrowHeadScale: 1.5,
        controlPoints: <Offset>[Offset(40, 100)],
        legacyArrow: false,
      );

      await repo.upsertElement(canvasId, shape);

      final loaded = await repo.loadElements(canvasId);
      expect(loaded, hasLength(1));
      final roundTripped = loaded.single as ShapeElement;
      expect(roundTripped.arrowBody, ArrowBodyKind.curved);
      expect(roundTripped.arrowStartHead, ArrowHeadStyle.dot);
      expect(roundTripped.arrowEndHead, ArrowHeadStyle.open);
      expect(roundTripped.arrowHeadScale, 1.5);
      expect(roundTripped.controlPoints, const <Offset>[Offset(40, 100)]);
      expect(roundTripped.legacyArrow, isFalse);
    });
  });

  group('loadElements', () {
    test('upsertElements and deleteElements handle mixed batches', () async {
      final ink = InkElement.fromStroke(
        const Stroke(
          id: 'batch-ink',
          points: <StrokePoint>[
            StrokePoint(0, 0, 0.5),
            StrokePoint(10, 10, 0.5),
          ],
          color: 0xFFFFFFFF,
          width: 4,
        ),
        zIndex: 0,
      );
      const image = ImageElement(
        id: 'batch-image',
        zIndex: 1,
        worldBounds: Rect.fromLTWH(10, 20, 30, 40),
        sourceFilePath: '/m/batch.png',
        intrinsicSize: Size(30, 40),
      );
      const note = TextElement(
        id: 'batch-note',
        zIndex: 2,
        worldBounds: Rect.fromLTWH(50, 60, 70, 80),
        text: 'Batched',
        color: 0xFFFFFFFF,
        fontSize: 18,
      );

      await repo.upsertElements(canvasId, <CanvasElement>[ink, image, note]);

      final loaded = await repo.loadElements(canvasId);
      expect(loaded.map((CanvasElement element) => element.id), <String>[
        'batch-ink',
        'batch-image',
        'batch-note',
      ]);

      await repo.deleteElements(<String>['batch-image', 'batch-note']);

      final remaining = await repo.loadElements(canvasId);
      expect(remaining.map((CanvasElement element) => element.id), <String>[
        'batch-ink',
      ]);
    });

    test('a failed replace batch restores the original elements', () async {
      const original = TextElement(
        id: 'original-note',
        zIndex: 0,
        worldBounds: Rect.fromLTWH(0, 0, 100, 80),
        text: 'Original',
        color: 0xFFFFFFFF,
        fontSize: 18,
      );
      await repo.upsertElement(canvasId, original);

      await expectLater(
        repo.applyElementBatch(
          canvasId,
          deletes: const ['original-note'],
          upserts: const [
            ImageElement(
              id: 'invalid-replacement',
              zIndex: 1,
              layerId: 'missing-layer',
              worldBounds: Rect.fromLTWH(0, 0, 10, 10),
              sourceFilePath: '/m/missing.png',
              intrinsicSize: Size(10, 10),
            ),
          ],
        ),
        throwsA(anything),
      );

      final loaded = await repo.loadElements(canvasId);
      expect(loaded, hasLength(1));
      expect(loaded.single.id, original.id);
      expect((loaded.single as TextElement).text, original.text);
    });

    test(
      'controller command persistence batches final moved geometry',
      () async {
        final CanvasController controller = CanvasController(
          repository: repo,
          canvasId: canvasId,
        );
        addTearDown(controller.dispose);
        await controller.load();
        const image = ImageElement(
          id: 'controller-batch-image',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(10, 20, 30, 40),
          sourceFilePath: '/m/controller-batch.png',
          intrinsicSize: Size(30, 40),
        );
        controller.addElementToStore(image);
        await controller.flush();

        controller
          ..setSelection(<String>{'controller-batch-image'})
          ..nudgeSelection(const Offset(5, -10));
        await controller.flush();

        final loaded = await repo.loadElements(canvasId);
        expect(loaded, hasLength(1));
        final moved = loaded.single as ImageElement;
        expect(moved.placementBounds, const Rect.fromLTWH(15, 10, 30, 40));
      },
    );

    test('dismissing a save banner does not hide unsaved writes', () async {
      final controller = CanvasController(repository: repo, canvasId: canvasId);
      addTearDown(controller.dispose);
      await controller.load();
      await db.close();

      controller.addElementToStore(
        const TextElement(
          id: 'unsaved-note',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(0, 0, 100, 80),
          text: 'Keep this note',
          color: 0xFFFFFFFF,
          fontSize: 18,
        ),
      );
      await controller.flush();
      expect(controller.hasSaveError, isTrue);
      expect(controller.hasUnsavedWrites, isTrue);

      controller.dismissSaveError();

      expect(controller.hasSaveError, isFalse);
      expect(controller.hasUnsavedWrites, isTrue);
    });

    test(
      'retry persists the newest state instead of a stale failed write',
      () async {
        final failOnceRepo = _FailOnceCanvasRepository(db);
        final controller = CanvasController(
          repository: failOnceRepo,
          canvasId: canvasId,
        );
        addTearDown(controller.dispose);
        await controller.load();
        const original = TextElement(
          id: 'retry-note',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(0, 0, 100, 80),
          text: 'Original',
          color: 0xFFFFFFFF,
          fontSize: 18,
        );

        controller.addElementToStore(original);
        await controller.flush();
        expect(controller.hasUnsavedWrites, isTrue);

        controller.updateTextElement(original, 'Newest');
        await controller.flush();
        await controller.retryFailedWrites();

        final loaded = await repo.loadElements(canvasId);
        expect((loaded.single as TextElement).text, 'Newest');
        expect(controller.hasUnsavedWrites, isFalse);
      },
    );

    test('does not return soft-deleted elements', () async {
      await repo.upsertElement(
        canvasId,
        const ImageElement(
          id: 'soft-del',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(0, 0, 10, 10),
          sourceFilePath: '/m/s.png',
          intrinsicSize: Size(10, 10),
        ),
      );
      // Flip is_deleted directly — loadElements filters these out.
      await db.customStatement(
        "UPDATE canvas_elements SET is_deleted = 1 WHERE id = 'soft-del'",
      );

      expect(await repo.loadElements(canvasId), isEmpty);
    });

    test('scopes results to the requested canvas', () async {
      const String otherCanvas = 'a-second-canvas';
      await repo.ensureCanvasExists(otherCanvas);
      await repo.upsertElement(
        otherCanvas,
        const ImageElement(
          id: 'other-img',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(0, 0, 10, 10),
          sourceFilePath: '/m/o.png',
          intrinsicSize: Size(10, 10),
        ),
      );

      expect(await repo.loadElements(canvasId), isEmpty);
      expect(await repo.loadElements(otherCanvas), hasLength(1));
    });
  });
}

class _FailOnceCanvasRepository extends CanvasRepository {
  _FailOnceCanvasRepository(super.db);

  bool _shouldFail = true;

  @override
  Future<void> upsertElement(String canvasId, CanvasElement element) {
    if (_shouldFail) {
      _shouldFail = false;
      return Future<void>.error(StateError('simulated write failure'));
    }
    return super.upsertElement(canvasId, element);
  }
}

class _CountingCanvasRepository extends CanvasRepository {
  _CountingCanvasRepository(super.db);

  int toolSettingsWriteCount = 0;

  @override
  Future<void> saveToolSettings(String canvasId, CanvasToolSettings settings) {
    toolSettingsWriteCount += 1;
    return super.saveToolSettings(canvasId, settings);
  }
}
