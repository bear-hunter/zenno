import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/engine/canvas_commands.dart';
import 'package:zenno/canvas/io/canvas_import.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/canvas_style.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/pdf/pdf_raster_service.dart';
import 'package:zenno/canvas/render/live_stroke_painter.dart';

/// Builds a trivial two-point [InkElement] for command tests.
///
/// The geometry is irrelevant to undo/redo correctness; only the [id] and
/// [zIndex] matter, so a fixed short stroke is used.
InkElement inkElement(String id, {required int zIndex}) {
  return InkElement.fromStroke(
    Stroke(
      id: id,
      points: const <StrokePoint>[
        StrokePoint(0, 0, 0.5),
        StrokePoint(10, 10, 0.5),
      ],
      color: 0xFFFFFFFF,
      width: 4,
    ),
    zIndex: zIndex,
  );
}

Future<Image> tinyRaster() async {
  final PictureRecorder recorder = PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  canvas.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
  final Picture picture = recorder.endRecording();
  final Image image = await picture.toImage(1, 1);
  picture.dispose();
  return image;
}

class _NoopPdfRasterService extends PdfRasterService {
  @override
  Future<PdfRasterResult?> rasterizePage({
    required String filePath,
    required int pageNumber,
    required int scaleBucket,
  }) async => null;

  @override
  Future<void> dispose() async {}
}

class _RecordingPdfRasterService extends PdfRasterService {
  final List<int> requestedBuckets = <int>[];
  final List<Completer<PdfRasterResult?>> pending =
      <Completer<PdfRasterResult?>>[];

  @override
  Future<PdfRasterResult?> rasterizePage({
    required String filePath,
    required int pageNumber,
    required int scaleBucket,
  }) {
    requestedBuckets.add(scaleBucket);
    final Completer<PdfRasterResult?> completer = Completer<PdfRasterResult?>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<void> dispose() async {}
}

class _ControlledCanvasImporter extends CanvasImporter {
  _ControlledCanvasImporter(PdfRasterService pdfRasterService)
    : super(pdfRasterService: pdfRasterService);

  final Completer<ImportedImage?> image = Completer<ImportedImage?>();
  final Completer<ImportedPdf?> pdf = Completer<ImportedPdf?>();

  @override
  Future<ImportedImage?> pickImage() => image.future;

  @override
  Future<ImportedPdf?> pickPdf() => pdf.future;
}

CanvasElement rasterElement({
  required bool pdf,
  required Image raster,
  String id = 'raster',
}) {
  if (pdf) {
    return PdfElement(
      id: id,
      zIndex: 0,
      worldBounds: const Rect.fromLTWH(0, 0, 100, 100),
      sourceFilePath: '/missing.pdf',
      pageNumber: 1,
      pageSize: const Size(100, 100),
      raster: raster,
      rasterScaleBucket: 1,
    );
  }
  return ImageElement(
    id: id,
    zIndex: 0,
    worldBounds: const Rect.fromLTWH(0, 0, 100, 100),
    sourceFilePath: '/missing.png',
    intrinsicSize: const Size(100, 100),
    raster: raster,
  );
}

Image? elementRaster(CanvasElement element) {
  return switch (element) {
    ImageElement(:final raster) => raster,
    PdfElement(:final raster) => raster,
    _ => null,
  };
}

/// An in-memory [ElementStore] for exercising commands without a controller.
///
/// Mirrors `CanvasController`'s store contract: keeps the element list sorted
/// ascending by [CanvasElement.zIndex] and treats a duplicate id as a no-op
/// add, so command [CanvasCommand.apply] / [CanvasCommand.revert] can be
/// asserted against a minimal, predictable backing.
class _FakeStore implements ElementStore {
  final List<CanvasElement> _elements = <CanvasElement>[];

  @override
  List<CanvasElement> get currentElements =>
      List<CanvasElement>.unmodifiable(_elements);

  /// The ids currently in the store, in paint order.
  List<String> get ids => <String>[for (final e in _elements) e.id];

  @override
  void addElementToStore(CanvasElement element) {
    if (_elements.any((CanvasElement e) => e.id == element.id)) {
      return;
    }
    var insertAt = _elements.length;
    for (var i = 0; i < _elements.length; i++) {
      if (_elements[i].zIndex > element.zIndex) {
        insertAt = i;
        break;
      }
    }
    _elements.insert(insertAt, element);
  }

  @override
  void removeElementFromStore(String id) {
    _elements.removeWhere((CanvasElement e) => e.id == id);
  }
}

void main() {
  group('AddElementCommand', () {
    test('apply inserts the element, revert removes it', () {
      final _FakeStore store = _FakeStore();
      final AddElementCommand command = AddElementCommand(
        inkElement('a', zIndex: 0),
      );

      command.apply(store);
      expect(store.ids, <String>['a']);

      command.revert(store);
      expect(store.ids, isEmpty);
    });

    test('apply is idempotent — a replay never duplicates the element', () {
      final _FakeStore store = _FakeStore();
      final AddElementCommand command = AddElementCommand(
        inkElement('a', zIndex: 0),
      );

      command.apply(store);
      command.apply(store);
      expect(store.ids, <String>['a']);
    });

    test('snapshots imported images without runtime rasters', () async {
      final Image raster = await tinyRaster();
      addTearDown(raster.dispose);
      final AddElementCommand command = AddElementCommand(
        ImageElement(
          id: 'img',
          zIndex: 0,
          worldBounds: const Rect.fromLTWH(0, 0, 10, 10),
          sourceFilePath: '/m/img.png',
          intrinsicSize: const Size(10, 10),
          raster: raster,
        ),
      );

      expect((command.element as ImageElement).raster, isNull);
    });
  });

  group('RemoveElementsCommand', () {
    test('apply removes every element, revert restores them in z-order', () {
      final _FakeStore store = _FakeStore()
        ..addElementToStore(inkElement('a', zIndex: 0))
        ..addElementToStore(inkElement('b', zIndex: 1))
        ..addElementToStore(inkElement('c', zIndex: 2));

      final RemoveElementsCommand command = RemoveElementsCommand(
        <CanvasElement>[inkElement('a', zIndex: 0), inkElement('c', zIndex: 2)],
      );

      command.apply(store);
      expect(store.ids, <String>['b']);

      command.revert(store);
      // The store re-sorts by zIndex, so order is restored regardless of the
      // order the command re-inserts in.
      expect(store.ids, <String>['a', 'b', 'c']);
    });

    test('snapshots its element list defensively', () {
      final List<CanvasElement> source = <CanvasElement>[
        inkElement('a', zIndex: 0),
      ];
      final RemoveElementsCommand command = RemoveElementsCommand(source);
      // Mutating the caller's list must not affect the command's undo data.
      source.add(inkElement('b', zIndex: 1));
      expect(command.elements.map((CanvasElement e) => e.id), <String>['a']);
    });
  });

  group('ClearCommand', () {
    test('apply empties the store, revert restores the snapshot', () {
      final _FakeStore store = _FakeStore()
        ..addElementToStore(inkElement('a', zIndex: 0))
        ..addElementToStore(inkElement('b', zIndex: 1));

      final ClearCommand command = ClearCommand();
      command.apply(store);
      expect(store.ids, isEmpty);

      command.revert(store);
      expect(store.ids, <String>['a', 'b']);
    });
  });

  group('ReplaceElementsCommand', () {
    test('apply swaps removed for added, revert swaps back', () {
      final _FakeStore store = _FakeStore()
        ..addElementToStore(inkElement('orig', zIndex: 0));

      final ReplaceElementsCommand command = ReplaceElementsCommand(
        removed: <CanvasElement>[inkElement('orig', zIndex: 0)],
        added: <CanvasElement>[
          inkElement('frag-a', zIndex: 1),
          inkElement('frag-b', zIndex: 2),
        ],
      );

      command.apply(store);
      expect(store.ids, <String>['frag-a', 'frag-b']);

      command.revert(store);
      expect(store.ids, <String>['orig']);
    });

    test('snapshots both lists defensively', () {
      final List<CanvasElement> removed = <CanvasElement>[
        inkElement('a', zIndex: 0),
      ];
      final List<CanvasElement> added = <CanvasElement>[
        inkElement('b', zIndex: 1),
      ];
      final ReplaceElementsCommand command = ReplaceElementsCommand(
        removed: removed,
        added: added,
      );
      removed.add(inkElement('x', zIndex: 9));
      added.add(inkElement('y', zIndex: 9));
      expect(command.removed.map((CanvasElement e) => e.id), <String>['a']);
      expect(command.added.map((CanvasElement e) => e.id), <String>['b']);
    });
  });

  group('MoveElementsCommand', () {
    test('apply installs the moved copies, revert restores the originals', () {
      final InkElement original = inkElement('a', zIndex: 0);
      final InkElement moved = original.translated(const Offset(50, 25));
      final _FakeStore store = _FakeStore()..addElementToStore(original);

      final MoveElementsCommand command = MoveElementsCommand(
        originals: <CanvasElement>[original],
        moved: <CanvasElement>[moved],
        delta: const Offset(50, 25),
      );

      command.apply(store);
      expect(store.ids, <String>['a']);
      // The id is preserved; only the geometry shifted.
      final InkElement afterMove = store.currentElements.single as InkElement;
      expect(afterMove.stroke.points.first.x, moreOrLessEquals(50));

      command.revert(store);
      final InkElement afterRevert = store.currentElements.single as InkElement;
      expect(afterRevert.stroke.points.first.x, moreOrLessEquals(0));
    });
  });

  group('TransformElementsCommand', () {
    test('apply installs transformed copies, revert restores originals', () {
      const TextElement original = TextElement(
        id: 'note',
        zIndex: 0,
        worldBounds: Rect.fromLTWH(-50, -10, 100, 20),
        text: 'Rotate me',
        color: 0xFFFFFFFF,
        fontSize: 18,
      );
      final TextElement rotated = original.copyWith(rotation: 0.5);
      final _FakeStore store = _FakeStore()..addElementToStore(original);

      final TransformElementsCommand command = TransformElementsCommand(
        originals: <CanvasElement>[original],
        transformed: <CanvasElement>[rotated],
        description: 'Rotate',
      );

      command.apply(store);
      expect((store.currentElements.single as TextElement).rotation, 0.5);

      command.revert(store);
      expect((store.currentElements.single as TextElement).rotation, 0);
    });
  });

  group('InkElement.translated', () {
    test('shifts every point and the bounds by the delta', () {
      final InkElement element = inkElement('a', zIndex: 3);
      final InkElement moved = element.translated(const Offset(10, -5));

      expect(moved.id, 'a');
      expect(moved.zIndex, 3);
      expect(moved.stroke.points.first.x, moreOrLessEquals(10));
      expect(moved.stroke.points.first.y, moreOrLessEquals(-5));
      expect(
        moved.worldBounds,
        element.worldBounds.shift(const Offset(10, -5)),
      );
    });
  });

  group('TextElement', () {
    test('translates its bounds without changing content', () {
      const TextElement element = TextElement(
        id: 'note-1',
        zIndex: 4,
        worldBounds: Rect.fromLTWH(10, 20, 200, 100),
        text: 'Hello\ncanvas',
        color: 0xFFFFFFFF,
        fontSize: 22,
      );

      final TextElement moved = element.translated(const Offset(30, -10));

      expect(moved.id, 'note-1');
      expect(moved.zIndex, 4);
      expect(moved.text, 'Hello\ncanvas');
      expect(moved.color, 0xFFFFFFFF);
      expect(moved.fontSize, 22);
      expect(moved.worldBounds, const Rect.fromLTWH(40, 10, 200, 100));
    });
  });

  group('committed element damage', () {
    test('remove then add includes both old and new bounds', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);
      const TextElement original = TextElement(
        id: 'moving-note',
        zIndex: 0,
        worldBounds: Rect.fromLTWH(10, 20, 100, 60),
        text: 'Move me',
        color: 0xFFFFFFFF,
        fontSize: 18,
      );
      final TextElement moved = original.translated(const Offset(3000, 40));

      controller.addElementToStore(original);
      final int beforeMove = controller.elementsRevision;
      controller.removeElementFromStore(original.id);
      controller.addElementToStore(moved);

      final CanvasElementDamage damage = controller.elementDamageSince(
        beforeMove,
      );
      expect(damage.isFull, isFalse);
      expect(
        damage.bounds,
        original.worldBounds.expandToInclude(moved.worldBounds),
      );
    });

    test('falls back to a full clear when bounded history is exhausted', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);
      final int oldRevision = controller.elementsRevision;

      for (var i = 0; i < 65; i += 1) {
        controller.addElementToStore(
          TextElement(
            id: 'note-$i',
            zIndex: i,
            worldBounds: Rect.fromLTWH(i * 10, 0, 8, 8),
            text: '$i',
            color: 0xFFFFFFFF,
            fontSize: 12,
          ),
        );
      }

      expect(controller.elementDamageSince(oldRevision).isFull, isTrue);
    });
  });

  group('live stroke repaint', () {
    test('appendToStroke replaces liveStroke identity before commit', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      controller.beginStroke(const Offset(0, 0), 0.5);
      final Stroke first = controller.liveStroke!;

      controller.appendToStroke(const Offset(10, 0), 0.5);
      final Stroke second = controller.liveStroke!;

      expect(identical(first, second), isFalse);
      expect(second.points, hasLength(2));
    });

    test('LiveStrokePainter repaints after an appended stroke sample', () {
      const Stroke before = Stroke(
        id: 'live',
        points: <StrokePoint>[StrokePoint(0, 0, 0.5)],
        color: 0xFFFFFFFF,
        width: 4,
      );
      const Stroke after = Stroke(
        id: 'live',
        points: <StrokePoint>[StrokePoint(0, 0, 0.5), StrokePoint(10, 0, 0.5)],
        color: 0xFFFFFFFF,
        width: 4,
      );

      const oldPainter = LiveStrokePainter(
        liveStroke: before,
        liveStrokeRevision: 1,
        viewport: ViewportState.initial,
      );
      const newPainter = LiveStrokePainter(
        liveStroke: after,
        liveStrokeRevision: 2,
        viewport: ViewportState.initial,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });

    testWidgets('appendToStroke coalesces listener notifications per frame', (
      tester,
    ) async {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() {
        notifications += 1;
      });

      controller.beginStroke(const Offset(0, 0), 0.5);
      controller.appendToStroke(const Offset(10, 0), 0.5);
      controller.appendToStroke(const Offset(20, 0), 0.5);

      expect(notifications, 1);
      expect(controller.liveStroke?.points, hasLength(3));

      await tester.pump();

      expect(notifications, 2);
    });
  });

  group('pen width modes', () {
    test('screen mode resolves selected width through current zoom', () {
      expect(
        resolveStrokeWidthWorld(
          selectedWidth: 4,
          viewportScale: 4,
          mode: PenWidthMode.screen,
        ),
        1,
      );
    });

    test('canvas mode keeps selected width in world units', () {
      expect(
        resolveStrokeWidthWorld(
          selectedWidth: 4,
          viewportScale: 4,
          mode: PenWidthMode.canvas,
        ),
        4,
      );
    });

    test('controller snapshots screen-mode stroke width at stroke start', () {
      final CanvasController controller = CanvasController()
        ..setViewport(const ViewportState(scale: 4))
        ..setPenWidth(4);
      addTearDown(controller.dispose);

      controller.beginStroke(const Offset(0, 0), 0.5);

      expect(controller.liveStroke!.width, 1);
    });

    test('controller snapshots canvas-mode stroke width at stroke start', () {
      final CanvasController controller = CanvasController()
        ..setViewport(const ViewportState(scale: 4))
        ..setPenWidth(4)
        ..setPenWidthMode(PenWidthMode.canvas);
      addTearDown(controller.dispose);

      controller.beginStroke(const Offset(0, 0), 0.5);

      expect(controller.liveStroke!.width, 4);
    });
  });

  group('CanvasController — command-backed undo/redo', () {
    /// Commits a stroke through the controller's normal begin/append/end path.
    void drawStroke(CanvasController controller) {
      controller
        ..beginStroke(const Offset(0, 0), 0.5)
        ..appendToStroke(const Offset(20, 20), 0.5)
        ..endStroke();
    }

    test('a committed stroke becomes an element and is undoable', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      expect(controller.canUndo, isFalse);
      expect(controller.elementCount, 0);

      drawStroke(controller);
      expect(controller.elementCount, 1);
      expect(controller.elements.single, isA<InkElement>());
      expect(controller.spatialIndex.length, 1);
      expect(controller.canUndo, isTrue);
      expect(controller.canRedo, isFalse);

      controller.undo();
      expect(controller.elementCount, 0);
      expect(controller.spatialIndex.isEmpty, isTrue);
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isTrue);

      controller.redo();
      expect(controller.elementCount, 1);
      expect(controller.spatialIndex.length, 1);
      expect(controller.canRedo, isFalse);
    });

    test('an empty stroke commits nothing and is not undoable', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      controller
        ..beginStroke(const Offset(0, 0), 0.5)
        ..cancelStroke();
      expect(controller.elementCount, 0);
      expect(controller.canUndo, isFalse);
    });

    test('a fresh edit forks history — the redo stack is dropped', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      drawStroke(controller);
      controller.undo();
      expect(controller.canRedo, isTrue);

      // Drawing again must invalidate the pending redo.
      drawStroke(controller);
      expect(controller.canRedo, isFalse);
      expect(controller.elementCount, 1);
    });

    test('clear is undoable and restores every element', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      drawStroke(controller);
      drawStroke(controller);
      expect(controller.elementCount, 2);

      controller.clear();
      expect(controller.elementCount, 0);
      expect(controller.spatialIndex.isEmpty, isTrue);
      expect(controller.canUndo, isTrue);

      controller.undo();
      expect(controller.elementCount, 2);
      expect(controller.spatialIndex.length, 2);
    });

    test('clearing an empty canvas records no undoable command', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      controller.clear();
      expect(controller.canUndo, isFalse);
    });

    test('z-index keeps advancing after an undo so new ink paints on top', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      drawStroke(controller);
      final int firstZ = controller.elements.single.zIndex;

      controller.undo();
      drawStroke(controller);
      final int secondZ = controller.elements.single.zIndex;

      // The allocator is re-derived from the (now empty) list on undo, so the
      // re-drawn stroke does not collide with the reverted one.
      expect(secondZ, greaterThanOrEqualTo(firstZ));
    });

    test('removeElements deletes via an undoable command', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      drawStroke(controller);
      drawStroke(controller);
      final List<CanvasElement> snapshot = controller.elements;

      controller.removeElements(<CanvasElement>[snapshot.first]);
      expect(controller.elementCount, 1);
      expect(controller.spatialIndex.length, 1);

      controller.undo();
      expect(controller.elementCount, 2);
      expect(controller.spatialIndex.length, 2);
    });
  });

  group('CanvasController — raster integrity and imports', () {
    for (final bool isPdf in <bool>[false, true]) {
      final String kind = isPdf ? 'PDF' : 'image';
      final String article = isPdf ? 'a' : 'an';

      test(
        'removing $article $kind disposes and untracks its raster',
        () async {
          final Image raster = await tinyRaster();
          final CanvasController controller = CanvasController(
            pdfRasterService: _NoopPdfRasterService(),
          )..addElementToStore(rasterElement(pdf: isPdf, raster: raster));
          addTearDown(() {
            controller.dispose();
            if (!raster.debugDisposed) {
              raster.dispose();
            }
          });

          expect(controller.debugRasterBytesInUse, 4);
          controller.removeElements(controller.elements);

          expect(controller.elementCount, 0);
          expect(controller.debugRasterBytesInUse, 0);
          expect(raster.debugDisposed, isTrue);

          controller.undo();
          expect(controller.elements, hasLength(1));
          expect(elementRaster(controller.elements.single), isNull);

          controller.redo();
          expect(controller.elements, isEmpty);
          expect(controller.debugRasterBytesInUse, 0);
        },
      );

      test(
        'moving $article $kind releases its old raster across undo and redo',
        () async {
          final Image raster = await tinyRaster();
          final CanvasController controller = CanvasController(
            pdfRasterService: _NoopPdfRasterService(),
          )..addElementToStore(rasterElement(pdf: isPdf, raster: raster));
          addTearDown(() {
            controller.dispose();
            if (!raster.debugDisposed) {
              raster.dispose();
            }
          });

          controller
            ..setSelection(<String>{'raster'})
            ..nudgeSelection(const Offset(25, 10));

          expect(raster.debugDisposed, isTrue);
          expect(controller.debugRasterBytesInUse, 0);
          expect(elementRaster(controller.elements.single), isNull);
          expect(
            controller.elements.single.worldBounds.topLeft,
            const Offset(25, 10),
          );

          controller.undo();
          expect(elementRaster(controller.elements.single), isNull);
          expect(controller.elements.single.worldBounds.topLeft, Offset.zero);

          controller.redo();
          expect(elementRaster(controller.elements.single), isNull);
          expect(
            controller.elements.single.worldBounds.topLeft,
            const Offset(25, 10),
          );
        },
      );
    }

    test(
      'raster budget evicts the least-recently-used off-screen item',
      () async {
        final Image bRaster = await tinyRaster();
        final Image aRaster = await tinyRaster();
        final Image cRaster = await tinyRaster();
        final CanvasController controller = CanvasController(
          pdfRasterService: _NoopPdfRasterService(),
          rasterBudgetBytes: 8,
        )..setViewportSize(const Size(100, 100));
        addTearDown(() {
          controller.dispose();
          for (final Image image in <Image>[bRaster, aRaster, cRaster]) {
            if (!image.debugDisposed) {
              image.dispose();
            }
          }
        });

        controller
          ..addElementToStore(
            ImageElement(
              id: 'b',
              zIndex: 0,
              worldBounds: const Rect.fromLTWH(10, 10, 20, 20),
              sourceFilePath: '/durable/b.png',
              intrinsicSize: const Size(20, 20),
              raster: bRaster,
              rasterScaleBucket: 3,
            ),
          )
          ..addElementToStore(
            ImageElement(
              id: 'a',
              zIndex: 1,
              worldBounds: const Rect.fromLTWH(1000, 0, 20, 20),
              sourceFilePath: '/durable/a.png',
              intrinsicSize: const Size(20, 20),
              raster: aRaster,
              rasterScaleBucket: 3,
            ),
          )
          ..addElementToStore(
            ImageElement(
              id: 'c',
              zIndex: 2,
              worldBounds: const Rect.fromLTWH(2000, 0, 20, 20),
              sourceFilePath: '/durable/c.png',
              intrinsicSize: const Size(20, 20),
              raster: cRaster,
              rasterScaleBucket: 3,
            ),
          )
          ..scheduleRasterWork()
          ..setViewport(const ViewportState(translation: Offset(-3000, 0)))
          ..debugEnforceRasterBudget();

        final Map<String, ImageElement> byId = <String, ImageElement>{
          for (final CanvasElement element in controller.elements)
            element.id: element as ImageElement,
        };
        expect(byId['a']!.raster, isNull);
        expect(byId['a']!.sourceFilePath, '/durable/a.png');
        expect(byId['b']!.raster, same(bRaster));
        expect(byId['c']!.raster, same(cRaster));
        expect(aRaster.debugDisposed, isTrue);
        expect(controller.debugRasterBytesInUse, 8);
      },
    );

    test(
      'zoom buckets sharpen once without decode churn inside a bucket',
      () async {
        final _RecordingPdfRasterService rasterService =
            _RecordingPdfRasterService();
        final Image initial = await tinyRaster();
        final CanvasController controller = CanvasController(
          pdfRasterService: rasterService,
        )..setViewportSize(const Size(100, 100));
        addTearDown(() {
          controller.dispose();
          if (!initial.debugDisposed) {
            initial.dispose();
          }
        });
        controller.addElementToStore(
          PdfElement(
            id: 'page',
            zIndex: 0,
            worldBounds: const Rect.fromLTWH(0, 0, 100, 100),
            sourceFilePath: '/durable/document.pdf',
            pageNumber: 1,
            pageSize: const Size(100, 100),
            raster: initial,
            rasterScaleBucket: 0,
          ),
        );

        controller
          ..setViewport(const ViewportState(scale: 6))
          ..scheduleRasterWork()
          ..scheduleRasterWork();
        await pumpEventQueue();

        expect(rasterService.requestedBuckets, <int>[1]);

        controller
          ..setViewport(const ViewportState(scale: 25))
          ..scheduleRasterWork();
        await pumpEventQueue();
        expect(rasterService.requestedBuckets, <int>[1]);

        final Image sharper = await tinyRaster();
        rasterService.pending.single.complete(
          PdfRasterResult(image: sharper, scaleBucket: 1),
        );
        await pumpEventQueue();
        expect(rasterService.requestedBuckets, <int>[1, 3]);
        expect((controller.elements.single as PdfElement).rasterScaleBucket, 1);

        final Image sharpest = await tinyRaster();
        rasterService.pending.last.complete(
          PdfRasterResult(image: sharpest, scaleBucket: 3),
        );
        await pumpEventQueue();
        expect((controller.elements.single as PdfElement).rasterScaleBucket, 3);

        controller
          ..setViewport(const ViewportState(scale: 30))
          ..scheduleRasterWork();
        await pumpEventQueue();
        expect(rasterService.requestedBuckets, <int>[1, 3]);
      },
    );

    test(
      'a completed image import is discarded after controller disposal',
      () async {
        final _NoopPdfRasterService rasterService = _NoopPdfRasterService();
        final _ControlledCanvasImporter importer = _ControlledCanvasImporter(
          rasterService,
        );
        final CanvasController controller = CanvasController(
          pdfRasterService: rasterService,
          importer: importer,
        );
        final Future<void> importing = controller.importImage();
        controller.dispose();

        final Image raster = await tinyRaster();
        addTearDown(() {
          if (!raster.debugDisposed) {
            raster.dispose();
          }
        });
        importer.image.complete(
          ImportedImage(
            storedPath: '/stale.png',
            intrinsicSize: const Size(1, 1),
            raster: raster,
          ),
        );

        await importing;
        expect(controller.elements, isEmpty);
        expect(raster.debugDisposed, isTrue);
      },
    );

    test(
      'a completed PDF import is ignored after controller disposal',
      () async {
        final _NoopPdfRasterService rasterService = _NoopPdfRasterService();
        final _ControlledCanvasImporter importer = _ControlledCanvasImporter(
          rasterService,
        );
        final CanvasController controller = CanvasController(
          pdfRasterService: rasterService,
          importer: importer,
        );
        final Future<void> importing = controller.importPdf();
        controller.dispose();
        importer.pdf.complete(
          const ImportedPdf(
            storedPath: '/stale.pdf',
            originalFileName: 'stale.pdf',
            pages: <PdfPageInfo>[
              PdfPageInfo(pageNumber: 1, size: Size(600, 800)),
            ],
          ),
        );

        await importing;
        expect(controller.elements, isEmpty);
      },
    );

    test('mixed-size PDF pages keep an exact vertical gap', () async {
      final _NoopPdfRasterService rasterService = _NoopPdfRasterService();
      final _ControlledCanvasImporter importer = _ControlledCanvasImporter(
        rasterService,
      );
      final CanvasController controller = CanvasController(
        pdfRasterService: rasterService,
        importer: importer,
      )..setViewportSize(const Size(1200, 1200));
      addTearDown(controller.dispose);

      final Future<void> importing = controller.importPdf();
      importer.pdf.complete(
        const ImportedPdf(
          storedPath: '/mixed.pdf',
          originalFileName: 'mixed.pdf',
          pages: <PdfPageInfo>[
            PdfPageInfo(pageNumber: 1, size: Size(600, 800)),
            PdfPageInfo(pageNumber: 2, size: Size(1000, 400)),
            PdfPageInfo(pageNumber: 3, size: Size(300, 900)),
          ],
        ),
      );
      await importing;

      final List<PdfElement> pages = controller.elements.cast<PdfElement>();
      expect(pages, hasLength(3));
      expect(
        pages[1].placementBounds.top,
        moreOrLessEquals(pages[0].placementBounds.bottom + 48),
      );
      expect(
        pages[2].placementBounds.top,
        moreOrLessEquals(pages[1].placementBounds.bottom + 48),
      );
      expect(
        pages.map((PdfElement page) => page.placementBounds.center.dx),
        everyElement(pages.first.placementBounds.center.dx),
      );
    });
  });

  group('CanvasController — editing tools', () {
    /// Commits a straight stroke from [from] to [to] through the controller.
    void drawLine(CanvasController controller, Offset from, Offset to) {
      controller
        ..beginStroke(from, 0.5)
        ..appendToStroke(to, 0.5)
        ..endStroke();
    }

    test('object eraser deletes a crossed stroke as one undoable command', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.eraser)
        ..setEraserMode(EraserMode.object);
      addTearDown(controller.dispose);

      drawLine(controller, const Offset(0, 0), const Offset(100, 0));
      expect(controller.elementCount, 1);

      // Drag the eraser straight across the stroke's centerline.
      controller
        ..beginErase(const Offset(50, 0))
        ..appendErase(const Offset(50, 0))
        ..endErase();
      expect(controller.elementCount, 0);
      expect(controller.canUndo, isTrue);

      controller.undo();
      expect(controller.elementCount, 1);
    });

    test('object eraser that misses records no command', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.eraser);
      addTearDown(controller.dispose);

      drawLine(controller, const Offset(0, 0), const Offset(100, 0));
      // Erase far from the stroke.
      controller
        ..beginErase(const Offset(50, 500))
        ..endErase();
      expect(controller.elementCount, 1);
      expect(controller.canUndo, isTrue, reason: 'only the draw is undoable');

      controller.undo();
      expect(controller.canUndo, isFalse);
    });

    test('partial eraser splits a stroke into surviving fragments', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.eraser)
        ..setEraserMode(EraserMode.partial)
        ..setEraserRadius(8);
      addTearDown(controller.dispose);

      // A long stroke sampled densely so a mid erase leaves points each side.
      controller.beginStroke(const Offset(0, 0), 0.5);
      for (double x = 5; x <= 200; x += 5) {
        controller.appendToStroke(Offset(x, 0), 0.5);
      }
      controller.endStroke();
      expect(controller.elementCount, 1);

      // Erase a dab in the middle — the stroke should split in two.
      controller
        ..beginErase(const Offset(100, 0))
        ..endErase();
      expect(controller.elementCount, 2);
      expect(controller.canUndo, isTrue);

      // Undo restores the single original stroke.
      controller.undo();
      expect(controller.elementCount, 1);
    });

    test('partial eraser splits a sparse two-point stroke at a crossing', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.eraser)
        ..setEraserMode(EraserMode.partial)
        ..setEraserRadius(6);
      addTearDown(controller.dispose);

      drawLine(controller, const Offset(0, 0), const Offset(100, 0));

      controller
        ..beginErase(const Offset(50, -20))
        ..appendErase(const Offset(50, 20))
        ..endErase();

      expect(controller.elementCount, 2);
      final fragments = controller.elements.cast<InkElement>().toList();
      expect(fragments.first.stroke.points.last.x, closeTo(50, 0.01));
      expect(fragments.last.stroke.points.first.x, closeTo(50, 0.01));
    });

    test('lasso selects an enclosed stroke and survives tool switch', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.lasso);
      addTearDown(controller.dispose);

      // A small stroke near the origin.
      drawLine(controller, const Offset(10, 10), const Offset(20, 20));

      // Loop a generous square around it.
      controller
        ..beginLasso(const Offset(-50, -50))
        ..appendLasso(const Offset(80, -50))
        ..appendLasso(const Offset(80, 80))
        ..appendLasso(const Offset(-50, 80))
        ..endLasso();
      expect(controller.hasSelection, isTrue);
      expect(controller.selectedElements, hasLength(1));

      // Switching tools keeps the selection available for direct manipulation.
      controller.setTool(CanvasTool.pen);
      expect(controller.hasSelection, isTrue);
    });

    test('lasso selects only the stroke touched by a small crossing loop', () {
      final CanvasController controller = CanvasController()
        ..addElementToStore(
          InkElement.fromStroke(
            const Stroke(
              id: 'touched',
              points: <StrokePoint>[
                StrokePoint(0, 0, 0.5),
                StrokePoint(100, 0, 0.5),
              ],
              color: 0xFFFFFFFF,
              width: 4,
            ),
            zIndex: 0,
          ),
        )
        ..addElementToStore(
          InkElement.fromStroke(
            const Stroke(
              id: 'nearby',
              points: <StrokePoint>[
                StrokePoint(0, 24, 0.5),
                StrokePoint(100, 24, 0.5),
              ],
              color: 0xFFFFFFFF,
              width: 4,
            ),
            zIndex: 1,
          ),
        )
        ..setTool(CanvasTool.lasso)
        ..beginLasso(const Offset(45, -10))
        ..appendLasso(const Offset(55, -10))
        ..appendLasso(const Offset(55, 10))
        ..appendLasso(const Offset(45, 10))
        ..endLasso();
      addTearDown(controller.dispose);

      expect(controller.selectedIds, <String>{'touched'});
    });

    test('lasso contact selection also follows a geometric line', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.shape)
        ..setShapeKind(ShapeKind.line)
        ..beginShape(Offset.zero)
        ..updateShape(const Offset(100, 0))
        ..endShape()
        ..setTool(CanvasTool.lasso)
        ..beginLasso(const Offset(45, -10))
        ..appendLasso(const Offset(55, -10))
        ..appendLasso(const Offset(55, 10))
        ..appendLasso(const Offset(45, 10))
        ..endLasso();
      addTearDown(controller.dispose);

      expect(controller.selectedElements, hasLength(1));
      expect(controller.selectedElements.single, isA<ShapeElement>());
    });

    test('lasso that encloses nothing leaves the selection empty', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.lasso);
      addTearDown(controller.dispose);

      drawLine(controller, const Offset(500, 500), const Offset(520, 520));
      controller
        ..beginLasso(const Offset(-10, -10))
        ..appendLasso(const Offset(10, -10))
        ..appendLasso(const Offset(10, 10))
        ..appendLasso(const Offset(-10, 10))
        ..endLasso();
      expect(controller.hasSelection, isFalse);
    });

    test('replace lasso keeps the prior selection visible until commit', () {
      final CanvasController controller = CanvasController()
        ..addElementToStore(inkElement('selected', zIndex: 0))
        ..addElementToStore(
          inkElement('next', zIndex: 1).translated(const Offset(100, 0)),
        )
        ..setSelection(<String>{'selected'})
        ..setSelectionMode(SelectionMode.replace);
      addTearDown(controller.dispose);

      controller
        ..beginLasso(const Offset(80, -20))
        ..appendLasso(const Offset(130, -20))
        ..appendLasso(const Offset(130, 30));
      expect(controller.selectedIds, <String>{'selected'});

      controller
        ..appendLasso(const Offset(80, 30))
        ..endLasso();

      expect(controller.selectedIds, <String>{'next'});
    });

    test('cancelled and invalid replace lassos preserve prior selection', () {
      final CanvasController controller = CanvasController()
        ..addElementToStore(inkElement('selected', zIndex: 0))
        ..setSelection(<String>{'selected'});
      addTearDown(controller.dispose);

      controller.beginLasso(const Offset(100, 100));
      expect(controller.selectedIds, <String>{'selected'});

      controller
        ..appendLasso(const Offset(140, 100))
        ..cancelLasso();
      expect(controller.selectedIds, <String>{'selected'});

      controller
        ..beginLasso(const Offset(100, 100))
        ..endLasso();

      expect(controller.selectedIds, <String>{'selected'});

      controller
        ..setSelectionMode(SelectionMode.add)
        ..beginLasso(const Offset(100, 100))
        ..endLasso();
      expect(controller.selectedIds, <String>{'selected'});
      expect(controller.selectionMode, SelectionMode.replace);
    });

    test('add and subtract lasso modes are consumed after one attempt', () {
      final CanvasController controller = CanvasController()
        ..addElementToStore(inkElement('a', zIndex: 0))
        ..addElementToStore(
          inkElement('b', zIndex: 1).translated(const Offset(100, 0)),
        )
        ..setSelection(<String>{'a'})
        ..setSelectionMode(SelectionMode.add);
      addTearDown(controller.dispose);

      controller
        ..beginLasso(const Offset(80, -20))
        ..appendLasso(const Offset(130, -20))
        ..appendLasso(const Offset(130, 30))
        ..appendLasso(const Offset(80, 30))
        ..endLasso();
      expect(controller.selectedIds, <String>{'a', 'b'});
      expect(controller.selectionMode, SelectionMode.replace);

      controller
        ..setSelectionMode(SelectionMode.subtract)
        ..beginLasso(const Offset(-20, -20))
        ..appendLasso(const Offset(30, -20))
        ..appendLasso(const Offset(30, 30))
        ..appendLasso(const Offset(-20, 30))
        ..endLasso();
      expect(controller.selectedIds, <String>{'b'});
      expect(controller.selectionMode, SelectionMode.replace);
    });

    test('deleteSelection removes the selection via an undoable command', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.lasso);
      addTearDown(controller.dispose);

      drawLine(controller, const Offset(10, 10), const Offset(20, 20));
      controller
        ..beginLasso(const Offset(-50, -50))
        ..appendLasso(const Offset(80, -50))
        ..appendLasso(const Offset(80, 80))
        ..appendLasso(const Offset(-50, 80))
        ..endLasso();
      expect(controller.hasSelection, isTrue);

      controller.deleteSelection();
      expect(controller.elementCount, 0);
      expect(controller.hasSelection, isFalse);

      controller.undo();
      expect(controller.elementCount, 1);
    });

    test('copy and paste duplicates the selection as one undoable group', () {
      final controller = CanvasController()
        ..addElementToStore(
          const TextElement(
            id: 'note',
            zIndex: 0,
            worldBounds: Rect.fromLTWH(10, 20, 80, 40),
            text: 'Copy me',
            color: 0xFFFFFFFF,
            fontSize: 18,
          ),
        )
        ..setSelection(<String>{'note'});

      controller.copySelection();
      expect(controller.hasClipboardContent, isTrue);

      controller.pasteSelection();

      expect(controller.elementCount, 2);
      expect(controller.selectedIds, hasLength(1));
      expect(controller.selectedIds, isNot(contains('note')));
      final TextElement pasted =
          controller.selectedElements.single as TextElement;
      expect(pasted.text, 'Copy me');
      expect(pasted.placementBounds, const Rect.fromLTWH(34, 44, 80, 40));

      controller.undo();
      expect(controller.elements.map((element) => element.id), <String>[
        'note',
      ]);
    });

    test('dragging a selection moves it and survives undo/redo', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.lasso);
      addTearDown(controller.dispose);

      drawLine(controller, const Offset(10, 10), const Offset(20, 20));
      controller
        ..beginLasso(const Offset(-50, -50))
        ..appendLasso(const Offset(80, -50))
        ..appendLasso(const Offset(80, 80))
        ..appendLasso(const Offset(-50, 80))
        ..endLasso();
      final InkElement before = controller.elements.single as InkElement;
      final double startX = before.stroke.points.first.x;

      controller
        ..beginSelectionDrag()
        ..updateSelectionDrag(const Offset(100, 0))
        ..endSelectionDrag();

      final InkElement after = controller.elements.single as InkElement;
      expect(after.stroke.points.first.x, moreOrLessEquals(startX + 100));
      // The selection still tracks the moved element.
      expect(controller.hasSelection, isTrue);

      controller.undo();
      final InkElement reverted = controller.elements.single as InkElement;
      expect(reverted.stroke.points.first.x, moreOrLessEquals(startX));
      expect(controller.hasSelection, isTrue);
    });

    test(
      'selection transform previews without mutating committed elements',
      () {
        final CanvasController controller = CanvasController();
        addTearDown(controller.dispose);

        const TextElement note = TextElement(
          id: 'preview-note',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(10, 20, 30, 40),
          text: 'Preview',
          color: 0xFFFFFFFF,
          fontSize: 12,
        );
        controller
          ..addElementToStore(note)
          ..setSelection(<String>{'preview-note'})
          ..beginSelectionTransform();

        final TextElement before = controller.elements.single as TextElement;

        controller.updateSelectionTransform(
          origin: Offset.zero,
          translation: const Offset(5, 10),
          scale: 2,
          rotation: 0,
        );

        expect(controller.elements.single, before);
        expect(controller.canUndo, isFalse);
        expect(
          controller.selectionTransformPreview?.translation,
          const Offset(5, 10),
        );
        expect(controller.selectionBounds, const Rect.fromLTWH(25, 50, 60, 80));

        controller.endSelectionTransform();

        final TextElement after = controller.elements.single as TextElement;
        expect(after.placementBounds, const Rect.fromLTWH(25, 50, 60, 80));
        expect(after.fontSize, 24);
        expect(controller.selectionTransformPreview, isNull);
        expect(controller.canUndo, isTrue);

        controller.undo();
        final TextElement reverted = controller.elements.single as TextElement;
        expect(reverted.placementBounds, before.placementBounds);
        expect(reverted.fontSize, before.fontSize);
        expect(controller.hasSelection, isTrue);
      },
    );

    test('selection changes cancel live drag and transform previews', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);
      const TextElement note = TextElement(
        id: 'cancel-preview',
        zIndex: 0,
        worldBounds: Rect.fromLTWH(10, 20, 30, 40),
        text: 'Keep me',
        color: 0xFFFFFFFF,
        fontSize: 12,
      );
      controller
        ..addElementToStore(note)
        ..setSelection(<String>{note.id})
        ..beginSelectionDrag()
        ..updateSelectionDrag(const Offset(50, 20))
        ..clearSelection();

      expect(controller.isDraggingSelection, isFalse);
      controller.endSelectionDrag();
      expect(controller.elements.single.worldBounds, note.worldBounds);

      controller
        ..setSelection(<String>{note.id})
        ..beginSelectionTransform()
        ..updateSelectionTransform(
          origin: note.worldBounds.center,
          translation: const Offset(30, 10),
          scale: 2,
          rotation: 0.5,
        )
        // Reapplying even the same membership is an explicit cancellation.
        ..setSelection(<String>{note.id});

      expect(controller.isTransformingSelection, isFalse);
      controller.endSelectionTransform();
      expect(controller.elements.single.worldBounds, note.worldBounds);
      expect(controller.canUndo, isFalse);
    });

    test('delete during a live transform cannot resurrect stale content', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);
      const TextElement note = TextElement(
        id: 'delete-preview',
        zIndex: 0,
        worldBounds: Rect.fromLTWH(10, 20, 30, 40),
        text: 'Delete me',
        color: 0xFFFFFFFF,
        fontSize: 12,
      );
      controller
        ..addElementToStore(note)
        ..setSelection(<String>{note.id})
        ..beginSelectionTransform()
        ..updateSelectionTransform(
          origin: note.worldBounds.center,
          translation: const Offset(80, 0),
          scale: 1.5,
          rotation: 0.25,
        )
        ..deleteSelection()
        ..endSelectionTransform();

      expect(controller.elementCount, 0);
      expect(controller.isTransformingSelection, isFalse);

      controller.undo();
      expect(controller.elements.single.worldBounds, note.worldBounds);
    });

    test('transform commit revalidates selected editable element ids', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);
      const TextElement note = TextElement(
        id: 'stale-preview',
        zIndex: 0,
        worldBounds: Rect.fromLTWH(10, 20, 30, 40),
        text: 'Do not restore',
        color: 0xFFFFFFFF,
        fontSize: 12,
      );
      controller
        ..addElementToStore(note)
        ..setSelection(<String>{note.id})
        ..beginSelectionTransform()
        ..updateSelectionTransform(
          origin: note.worldBounds.center,
          translation: const Offset(80, 0),
          scale: 1.5,
          rotation: 0.25,
        )
        ..removeElementFromStore(note.id)
        ..endSelectionTransform();

      expect(controller.elementCount, 0);
      expect(controller.isTransformingSelection, isFalse);
      expect(controller.canUndo, isFalse);
    });

    test('locking a selected layer cancels its live transform', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);
      const TextElement note = TextElement(
        id: 'locked-preview',
        zIndex: 0,
        worldBounds: Rect.fromLTWH(10, 20, 30, 40),
        text: 'Locked',
        color: 0xFFFFFFFF,
        fontSize: 12,
      );
      controller
        ..addElementToStore(note)
        ..setSelection(<String>{note.id})
        ..beginSelectionTransform()
        ..updateSelectionTransform(
          origin: note.worldBounds.center,
          translation: const Offset(80, 0),
          scale: 1.5,
          rotation: 0.25,
        )
        ..setLayerLocked(controller.activeLayerId, locked: true)
        ..endSelectionTransform();

      expect(controller.elements.single.worldBounds, note.worldBounds);
      expect(controller.hasSelection, isFalse);
      expect(controller.isTransformingSelection, isFalse);
      expect(controller.canUndo, isFalse);
    });

    test('text notes lasso-select, move, delete, undo and redo', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.text);
      addTearDown(controller.dispose);

      final TextElement note = controller.placeText(
        worldCenter: const Offset(100, 100),
        text: 'Line one\nLine two',
      )!;
      expect(controller.elements.single, isA<TextElement>());

      controller
        ..setTool(CanvasTool.lasso)
        ..beginLasso(const Offset(-100, -100))
        ..appendLasso(const Offset(300, -100))
        ..appendLasso(const Offset(300, 300))
        ..appendLasso(const Offset(-100, 300))
        ..endLasso();
      expect(controller.selectedElements, hasLength(1));

      controller
        ..beginSelectionDrag()
        ..updateSelectionDrag(const Offset(25, 10))
        ..endSelectionDrag();
      final moved = controller.elements.single as TextElement;
      expect(moved.worldBounds, note.worldBounds.shift(const Offset(25, 10)));

      controller.deleteSelection();
      expect(controller.elementCount, 0);
      controller.undo();
      expect(controller.elementCount, 1);
      controller.redo();
      expect(controller.elementCount, 0);
    });

    test('a zero-distance selection drag records no command', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.lasso);
      addTearDown(controller.dispose);

      drawLine(controller, const Offset(10, 10), const Offset(20, 20));
      controller
        ..beginLasso(const Offset(-50, -50))
        ..appendLasso(const Offset(80, -50))
        ..appendLasso(const Offset(80, 80))
        ..appendLasso(const Offset(-50, 80))
        ..endLasso();

      controller
        ..beginSelectionDrag()
        ..endSelectionDrag();
      // Only the draw is on the undo stack.
      controller.undo();
      expect(controller.canUndo, isFalse);
    });

    test('active layer is stamped on new elements', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      final layer = controller.addLayer(name: 'Sketch');
      controller
        ..setActiveLayer(layer.id)
        ..beginStroke(const Offset(0, 0), 0.5)
        ..appendToStroke(const Offset(10, 0), 0.5)
        ..endStroke();

      expect(controller.elements.single.layerId, layer.id);
      expect(controller.activeLayerId, layer.id);
    });

    test('viewport elements contain only ordered spatial hits', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);
      controller
        ..setViewportSize(const Size(100, 100))
        ..addElementToStore(inkElement('near', zIndex: 0))
        ..addElementToStore(
          inkElement('far', zIndex: 1).translated(const Offset(1000, 0)),
        );

      expect(
        controller.viewportElements.map((CanvasElement element) => element.id),
        <String>['near'],
      );

      controller.setViewport(
        const ViewportState(translation: Offset(-1000, 0)),
      );

      expect(
        controller.viewportElements.map((CanvasElement element) => element.id),
        <String>['far'],
      );
    });

    test(
      'hidden and locked layers are protected from selection and erasing',
      () {
        final CanvasController controller = CanvasController();
        addTearDown(controller.dispose);

        final layer = controller.addLayer(name: 'Protected');
        controller
          ..setActiveLayer(layer.id)
          ..addElementToStore(inkElement('protected', zIndex: 0));

        controller.setLayerVisible(layer.id, visible: false);
        expect(controller.visibleElements, isEmpty);
        expect(controller.selectElementAt(const Offset(5, 5)), isFalse);
        expect(controller.hasSelection, isFalse);

        controller.setLayerVisible(layer.id, visible: true);
        controller.setLayerLocked(layer.id, locked: true);
        expect(controller.selectElementAt(const Offset(5, 5)), isFalse);
        controller
          ..setEraserMode(EraserMode.object)
          ..beginErase(const Offset(5, 5))
          ..endErase();
        expect(controller.elementCount, 1);
      },
    );

    test('all hidden or locked layers block new content', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);
      final String layerId = controller.activeLayerId;

      controller.setLayerVisible(layerId, visible: false);
      expect(controller.canCreateContent, isFalse);
      expect(
        controller.placeText(
          worldCenter: const Offset(5, 5),
          text: 'Hidden note',
        ),
        isNull,
      );
      expect(
        controller.placeLink(
          worldCenter: const Offset(5, 5),
          label: 'Hidden link',
          target: const LinkTarget(targetCanvasId: 'target'),
        ),
        isNull,
      );
      controller
        ..beginStroke(const Offset(0, 0), 0.5)
        ..appendToStroke(const Offset(10, 0), 0.5)
        ..endStroke()
        ..beginShape(const Offset(0, 0))
        ..updateShape(const Offset(10, 10))
        ..endShape();

      expect(controller.elementCount, 0);
      expect(controller.liveStroke, isNull);
      expect(controller.liveShapeElement, isNull);

      controller
        ..setLayerVisible(layerId, visible: true)
        ..setLayerLocked(layerId, locked: true);
      expect(controller.canCreateContent, isFalse);
      expect(
        controller.placeText(
          worldCenter: const Offset(5, 5),
          text: 'Locked note',
        ),
        isNull,
      );
      expect(
        controller.placeLink(
          worldCenter: const Offset(5, 5),
          label: 'Locked link',
          target: const LinkTarget(targetCanvasId: 'target'),
        ),
        isNull,
      );
      controller
        ..beginStroke(const Offset(0, 0), 0.5)
        ..appendToStroke(const Offset(10, 0), 0.5)
        ..endStroke()
        ..beginShape(const Offset(0, 0))
        ..updateShape(const Offset(10, 10))
        ..endShape();

      expect(controller.elementCount, 0);
      expect(controller.liveStroke, isNull);
      expect(controller.liveShapeElement, isNull);
    });

    test('tap item picker supports replace add and subtract modes', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      controller
        ..addElementToStore(inkElement('a', zIndex: 0))
        ..addElementToStore(
          inkElement('b', zIndex: 1).translated(const Offset(100, 0)),
        );

      expect(controller.selectElementAt(const Offset(5, 5)), isTrue);
      expect(controller.selectedIds, <String>{'a'});

      controller
        ..setSelectionMode(SelectionMode.add)
        ..selectElementAt(const Offset(105, 5));
      expect(controller.selectedIds, <String>{'a', 'b'});
      expect(controller.selectionMode, SelectionMode.replace);

      controller
        ..setSelectionMode(SelectionMode.subtract)
        ..selectElementAt(const Offset(5, 5));
      expect(controller.selectedIds, <String>{'b'});
      expect(controller.selectionMode, SelectionMode.replace);

      controller.setSelectionMode(SelectionMode.add);
      expect(controller.selectElementAt(const Offset(500, 500)), isFalse);
      expect(controller.selectedIds, <String>{'b'});
      expect(controller.selectionMode, SelectionMode.replace);
    });

    test('clear and delete reset a pending one-shot selection mode', () {
      final CanvasController controller = CanvasController()
        ..addElementToStore(inkElement('a', zIndex: 0))
        ..setSelection(<String>{'a'})
        ..setSelectionMode(SelectionMode.add);
      addTearDown(controller.dispose);

      controller.clearSelection();
      expect(controller.hasSelection, isFalse);
      expect(controller.selectionMode, SelectionMode.replace);

      controller
        ..setSelection(<String>{'a'})
        ..setSelectionMode(SelectionMode.subtract)
        ..deleteSelection();
      expect(controller.elementCount, 0);
      expect(controller.selectionMode, SelectionMode.replace);
    });

    test('selection bounds are draggable with screen-constant padding', () {
      final CanvasController controller = CanvasController()
        ..addElementToStore(
          const TextElement(
            id: 'left',
            zIndex: 0,
            worldBounds: Rect.fromLTWH(0, 0, 10, 10),
            text: 'Left',
            color: 0xFFFFFFFF,
            fontSize: 12,
          ),
        )
        ..addElementToStore(
          const TextElement(
            id: 'right',
            zIndex: 1,
            worldBounds: Rect.fromLTWH(100, 0, 10, 10),
            text: 'Right',
            color: 0xFFFFFFFF,
            fontSize: 12,
          ),
        )
        ..setSelection(<String>{'left', 'right'});
      addTearDown(controller.dispose);

      // Empty space between sparse selected elements belongs to the draggable
      // group bounds.
      expect(controller.selectionHitTest(const Offset(55, 5)), isTrue);
      expect(controller.selectionHitTest(const Offset(121, 5)), isTrue);
      expect(controller.selectionHitTest(const Offset(123, 5)), isFalse);

      controller.setViewport(const ViewportState(scale: 2));
      expect(controller.selectionHitTest(const Offset(115, 5)), isTrue);
      expect(controller.selectionHitTest(const Offset(117, 5)), isFalse);

      final String layerId = controller.activeLayerId;
      controller.setLayerLocked(layerId, locked: true);
      expect(controller.selectionHitTest(const Offset(55, 5)), isFalse);
    });

    test('nudgeSelection moves selected elements and remains undoable', () {
      final CanvasController controller = CanvasController();
      addTearDown(controller.dispose);

      controller.addElementToStore(inkElement('a', zIndex: 0));
      controller.setSelection(<String>{'a'});

      controller.nudgeSelection(const Offset(8, -4));
      final InkElement moved = controller.elements.single as InkElement;
      expect(moved.stroke.points.first.offset, const Offset(8, -4));
      expect(controller.hasSelection, isTrue);

      controller.undo();
      final InkElement reverted = controller.elements.single as InkElement;
      expect(reverted.stroke.points.first.offset, Offset.zero);
      expect(controller.hasSelection, isTrue);
    });

    test(
      'scaleSelection scales selected ink and text and remains undoable',
      () {
        final CanvasController controller = CanvasController();
        addTearDown(controller.dispose);

        final InkElement ink = inkElement('ink-scale', zIndex: 0);
        const TextElement note = TextElement(
          id: 'note-scale',
          zIndex: 1,
          worldBounds: Rect.fromLTWH(10, 10, 100, 50),
          text: 'Scale',
          color: 0xFFFFFFFF,
          fontSize: 20,
        );
        controller
          ..addElementToStore(ink)
          ..addElementToStore(note)
          ..setSelection(<String>{'ink-scale', 'note-scale'})
          ..scaleSelection(2, 3, origin: Offset.zero);

        final InkElement scaledInk = controller.elements
            .whereType<InkElement>()
            .single;
        final TextElement scaledNote = controller.elements
            .whereType<TextElement>()
            .single;
        expect(scaledInk.stroke.points.last.offset, const Offset(20, 30));
        expect(scaledInk.stroke.width, 10);
        expect(
          scaledNote.placementBounds,
          const Rect.fromLTWH(20, 30, 200, 150),
        );
        expect(scaledNote.fontSize, 50);
        expect(controller.hasSelection, isTrue);

        controller.undo();
        final TextElement revertedNote = controller.elements
            .whereType<TextElement>()
            .single;
        expect(revertedNote.placementBounds, note.placementBounds);
        expect(controller.hasSelection, isTrue);
      },
    );

    test(
      'rotateSelection rotates rectangular content with precise hit testing',
      () {
        final CanvasController controller = CanvasController();
        addTearDown(controller.dispose);
        controller.viewport = const ViewportState(scale: 100);

        const TextElement note = TextElement(
          id: 'note-rotate',
          zIndex: 0,
          worldBounds: Rect.fromLTWH(-50, -10, 100, 20),
          text: 'Rotate',
          color: 0xFFFFFFFF,
          fontSize: 20,
        );
        controller
          ..addElementToStore(note)
          ..setSelection(<String>{'note-rotate'})
          ..rotateSelection(0.7853981633974483, origin: Offset.zero);

        final TextElement rotated = controller.elements.single as TextElement;
        expect(rotated.placementBounds, note.placementBounds);
        expect(rotated.rotation, closeTo(0.7853981633974483, 1e-12));
        expect(controller.elementAt(Offset.zero), isA<TextElement>());
        expect(
          controller.elementAt(
            rotated.worldBounds.topLeft + const Offset(1, 1),
          ),
          isNull,
        );

        controller.undo();
        final TextElement reverted = controller.elements.single as TextElement;
        expect(reverted.rotation, 0);
        expect(controller.hasSelection, isTrue);
      },
    );

    test('shape tool commits a geometric ShapeElement', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.shape)
        ..setShapeKind(ShapeKind.rectangle);
      addTearDown(controller.dispose);

      controller
        ..beginShape(const Offset(0, 0))
        ..updateShape(const Offset(100, 60))
        ..endShape();
      expect(controller.elementCount, 1);
      final ShapeElement shape = controller.elements.single as ShapeElement;
      expect(shape.shapeKind, ShapeKind.rectangle.index);
      expect(shape.start, const Offset(0, 0));
      expect(shape.end, const Offset(100, 60));
      expect(controller.canUndo, isTrue);

      controller.undo();
      expect(controller.elementCount, 0);
    });

    test('snap-to-grid snaps new precision objects to grid intersections', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.shape)
        ..setShapeKind(ShapeKind.rectangle)
        ..setPaperStyle(const CanvasPaperStyle(gridSpacing: 10))
        ..setSnapToGridEnabled(enabled: true);
      addTearDown(controller.dispose);

      controller
        ..beginShape(const Offset(3, 7))
        ..updateShape(const Offset(16, 23))
        ..endShape();

      final ShapeElement shape = controller.elements.single as ShapeElement;
      expect(shape.start, const Offset(0, 10));
      expect(shape.end, const Offset(20, 20));

      final TextElement text = controller.placeText(
        worldCenter: const Offset(14, 26),
        text: 'Snapped',
      )!;
      expect(text.placementBounds.center, const Offset(10, 30));
    });

    test('a zero-size shape drag commits nothing', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.shape);
      addTearDown(controller.dispose);

      controller
        ..beginShape(const Offset(5, 5))
        ..endShape();
      expect(controller.elementCount, 0);
      expect(controller.canUndo, isFalse);
    });

    const List<(ShapeKind kind, Offset end, Offset hit, Offset miss)>
    shapeHitCases = <(ShapeKind, Offset, Offset, Offset)>[
      (ShapeKind.line, Offset(100, 100), Offset(50, 50), Offset(0, 100)),
      (ShapeKind.rectangle, Offset(100, 100), Offset(50, 0), Offset(50, 50)),
      (ShapeKind.oval, Offset(100, 100), Offset(50, 0), Offset(50, 50)),
      (ShapeKind.arrow, Offset(100, 0), Offset(50, 0), Offset(50, 40)),
    ];

    for (final (ShapeKind kind, Offset end, Offset hit, Offset miss)
        in shapeHitCases) {
      test('${kind.name} hit-testing follows its painted geometry', () {
        final CanvasController controller = CanvasController()
          ..setTool(CanvasTool.shape)
          ..setShapeKind(kind)
          ..beginShape(Offset.zero)
          ..updateShape(end)
          ..endShape();
        addTearDown(controller.dispose);

        expect(controller.elementAt(hit), isA<ShapeElement>());
        expect(controller.elementAt(miss), isNull);
      });

      test('${kind.name} eraser ignores empty space inside its bounds', () {
        final CanvasController controller = CanvasController()
          ..setTool(CanvasTool.shape)
          ..setShapeKind(kind)
          ..beginShape(Offset.zero)
          ..updateShape(end)
          ..endShape()
          ..setEraserMode(EraserMode.object)
          ..beginErase(miss)
          ..endErase();
        addTearDown(controller.dispose);

        expect(controller.elementCount, 1);
        controller
          ..beginErase(hit)
          ..endErase();
        expect(controller.elementCount, 0);
      });

      test('${kind.name} lasso measures the painted geometry', () {
        final CanvasController controller = CanvasController()
          ..setTool(CanvasTool.shape)
          ..setShapeKind(kind)
          ..beginShape(Offset.zero)
          ..updateShape(end)
          ..endShape()
          ..setTool(CanvasTool.lasso)
          ..beginLasso(const Offset(-20, -20))
          ..appendLasso(const Offset(120, -20))
          ..appendLasso(const Offset(120, 120))
          ..appendLasso(const Offset(-20, 120))
          ..endLasso();
        addTearDown(controller.dispose);

        expect(controller.selectedElements, hasLength(1));
      });
    }

    test(
      'filled arrowhead interiors participate in hit-testing and erasing',
      () {
        final CanvasController controller = CanvasController()
          ..setTool(CanvasTool.shape)
          ..setShapeKind(ShapeKind.arrow)
          ..setArrowStyle(endHead: ArrowHeadStyle.filled, headScale: 2.5)
          ..beginShape(Offset.zero)
          ..updateShape(const Offset(200, 0))
          ..endShape()
          ..setViewport(const ViewportState(scale: 20));
        addTearDown(controller.dispose);

        const Offset insideHead = Offset(180, 5);
        expect(controller.elementAt(insideHead), isA<ShapeElement>());

        controller
          ..setEraserMode(EraserMode.object)
          ..beginErase(insideHead)
          ..endErase();
        expect(controller.elementCount, 0);
      },
    );

    test('a committed shape can itself be lasso-selected and erased', () {
      final CanvasController controller = CanvasController()
        ..setTool(CanvasTool.shape)
        ..setShapeKind(ShapeKind.line);
      addTearDown(controller.dispose);

      controller
        ..beginShape(const Offset(10, 10))
        ..updateShape(const Offset(40, 10))
        ..endShape();
      expect(controller.elementCount, 1);

      // The shape erases through the same pipeline as freehand ink.
      controller
        ..setTool(CanvasTool.eraser)
        ..setEraserMode(EraserMode.object)
        ..beginErase(const Offset(25, 10))
        ..endErase();
      expect(controller.elementCount, 0);
    });
  });
}
