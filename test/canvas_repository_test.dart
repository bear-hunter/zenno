import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/persistence/canvas_repository.dart';
import 'package:zenno/core/database/database.dart' hide CanvasElement;

/// `float32` storage in the ink BLOB keeps ~7 significant digits; reloaded
/// stroke coordinates match only to this tolerance.
const double _f32Tolerance = 1e-3;

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
      expect(await repo.ensureCanvasExists(fresh), isTrue);
      expect(await repo.ensureCanvasExists(fresh), isFalse);
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

  group('ink element round-trip', () {
    test('save then load reconstructs the InkElement', () async {
      const stroke = Stroke(
        id: 'ink-1',
        points: <StrokePoint>[
          StrokePoint(10, 20, 0.1),
          StrokePoint(11, 22, 0.4),
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
        expect(ink.stroke.points[i].x,
            closeTo(stroke.points[i].x, _f32Tolerance));
        expect(ink.stroke.points[i].y,
            closeTo(stroke.points[i].y, _f32Tolerance));
        expect(ink.stroke.points[i].pressure,
            closeTo(stroke.points[i].pressure, _f32Tolerance));
      }
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
    test('a plain canvas link round-trips with a null target viewport',
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
    });

    test('a region link round-trips its full target viewport losslessly',
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
    });
  });

  group('mixed canvas', () {
    test('round-trips ink + image + pdf + link in z-order', () async {
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
        zIndex: 3,
        worldBounds: Rect.fromLTWH(400, 0, 220, 56),
        label: 'Go',
        target: LinkTarget(targetCanvasId: 'dest'),
      );

      // Insert deliberately out of z-order.
      await repo.upsertElement(canvasId, link);
      await repo.upsertElement(canvasId, ink);
      await repo.upsertElement(canvasId, pdf);
      await repo.upsertElement(canvasId, image);

      final List<CanvasElement> loaded = await repo.loadElements(canvasId);

      expect(loaded, hasLength(4));
      // Loaded ordered by z_index ascending.
      expect(loaded.map((e) => e.id).toList(),
          <String>['e-ink', 'e-img', 'e-pdf', 'e-link']);
      expect(loaded[0], isA<InkElement>());
      expect(loaded[1], isA<ImageElement>());
      expect(loaded[2], isA<PdfElement>());
      expect(loaded[3], isA<LinkElement>());
    });

    test('a viewport and elements persist together on one canvas', () async {
      const ViewportState vp =
          ViewportState(translation: Offset(1, 2), scale: 1.5);
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

  group('loadElements', () {
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
