import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';

/// Lightweight description of one page inside a PDF, gathered at import time.
@immutable
class PdfPageInfo {
  /// Creates page info for the 1-based [pageNumber] of size [size] points.
  const PdfPageInfo({required this.pageNumber, required this.size});

  /// 1-based page index within the source document.
  final int pageNumber;

  /// Intrinsic page size in PDF points (1/72").
  final ui.Size size;
}

/// The result of a rasterise request: the decoded page bitmap plus the bucket
/// it was rendered for, so the caller can record what resolution it cached.
@immutable
class PdfRasterResult {
  /// Creates a raster result for [image] rendered at [scaleBucket].
  const PdfRasterResult({required this.image, required this.scaleBucket});

  /// The decoded PDF-page bitmap. The caller owns it and must dispose it when
  /// it is evicted or replaced.
  final ui.Image image;

  /// The zoom bucket this raster was rendered for (see
  /// [PdfRasterService.bucketForScale]).
  final int scaleBucket;
}

/// Renders pages of imported PDFs to `ui.Image`s, off the synchronous UI path.
///
/// This is the engine's single touch-point for the `pdfrx` package. It knows
/// how to:
/// - lazily initialise `pdfrx` exactly once (`pdfrx` needs a one-time setup
///   call before any document is opened);
/// - probe a PDF file for its page count and per-page sizes at import time
///   (see [probe]);
/// - rasterise a specific page to a `ui.Image` at a zoom-appropriate
///   resolution (see [rasterizePage]).
///
/// **Why this is safe for ink latency.** `pdfrx` performs the heavy native
/// PDFium work — `FPDF_RenderPageBitmap` — on its *own* dedicated background
/// isolate (its internal `BackgroundWorker`); every method here is `async` and
/// `await`s that worker, so the calling isolate is never blocked on native
/// rasterisation. The only calling-isolate cost is allocating the pixel buffer
/// and the final `ui.decodeImageFromPixels`, which is itself asynchronous and
/// handed to the engine's raster thread. The controller still shows a
/// placeholder until the future completes, so a slow page never stalls a
/// frame.
///
/// Open [PdfDocument]s are pooled by file path and reused across page renders
/// of the same PDF (a multi-page import renders every page from one open
/// handle). The pool is capped: [dispose] tears everything down.
class PdfRasterService {
  /// Creates a raster service. `pdfrx` is initialised lazily on first use.
  PdfRasterService();

  /// Discrete render-resolution ladder, as world-pixels-per-point multipliers.
  ///
  /// A PDF page is rendered at `pageSizePoints * _scaleLadder[bucket]` pixels.
  /// Bucket 0 is a low-DPI raster good enough at fit-to-screen zoom; higher
  /// buckets are used as the user zooms in so the page stays crisp. The ladder
  /// is coarse on purpose — re-rasterising on every zoom delta would thrash.
  static const List<double> _scaleLadder = <double>[1.0, 2.0, 3.5, 5.0];

  /// Hard ceiling on a rendered page's longest pixel side.
  ///
  /// Bounds the worst-case raster (a huge page at the top zoom bucket) so a
  /// single PDF page can never blow the in-memory raster budget on its own.
  static const int _maxRasterPixelSide = 4096;

  /// Whether [pdfrxFlutterInitialize] has completed.
  bool _initialized = false;

  /// In-flight `pdfrx` initialisation, so concurrent callers share one init.
  Future<void>? _initializing;

  /// Open documents pooled by absolute file path, reused across page renders.
  final Map<String, Future<PdfDocument>> _openDocuments =
      <String, Future<PdfDocument>>{};

  /// Whether [dispose] has been called; further work is rejected after that.
  bool _disposed = false;

  /// Lazily initialises `pdfrx`, exactly once, before the first document opens.
  ///
  /// `pdfrx` requires a one-time `pdfrxFlutterInitialize` (it wires asset
  /// loading and the PDFium cache directory). Doing it lazily here keeps the
  /// whole PDF feature self-contained in `lib/canvas/` — no bootstrap code has
  /// to know about it. Concurrent callers await the same future.
  Future<void> _ensureInitialized() {
    if (_initialized) {
      return Future<void>.value();
    }
    return _initializing ??= () async {
      await pdfrxFlutterInitialize();
      _initialized = true;
      _initializing = null;
    }();
  }

  /// Opens (or returns the pooled handle for) the PDF at [filePath].
  Future<PdfDocument> _document(String filePath) {
    return _openDocuments[filePath] ??= () async {
      await _ensureInitialized();
      return PdfDocument.openFile(filePath);
    }();
  }

  /// Probes the PDF at [filePath] for its page count and per-page sizes.
  ///
  /// Used by the importer to decide how many [PdfElement]s to create and at
  /// what aspect ratio. The returned list is in document order (page 1 first).
  /// Throws if the file is not a readable PDF.
  Future<List<PdfPageInfo>> probe(String filePath) async {
    if (_disposed) {
      throw StateError('PdfRasterService used after dispose().');
    }
    final PdfDocument document = await _document(filePath);
    return <PdfPageInfo>[
      for (final PdfPage page in document.pages)
        PdfPageInfo(
          pageNumber: page.pageNumber,
          size: ui.Size(page.width, page.height),
        ),
    ];
  }

  /// Maps a viewport [scale] to a discrete render-resolution bucket.
  ///
  /// The result indexes [_scaleLadder]; a higher bucket means a sharper (and
  /// larger) raster. Bucketing means a PDF page is only re-rendered when zoom
  /// crosses a ladder threshold, not on every pinch frame.
  static int bucketForScale(double scale) {
    // Pick the smallest ladder entry that still covers the current scale.
    for (var i = 0; i < _scaleLadder.length; i++) {
      if (scale <= _scaleLadder[i]) {
        return i;
      }
    }
    return _scaleLadder.length - 1;
  }

  /// Rasterises [pageNumber] of the PDF at [filePath] for the given zoom
  /// [scaleBucket].
  ///
  /// The page is rendered at `pageSizePoints * ladder[scaleBucket]` pixels
  /// (clamped to [_maxRasterPixelSide]) and decoded into a `ui.Image`. The
  /// native render runs on `pdfrx`'s background isolate; this method only
  /// allocates and decodes on the caller's isolate, both asynchronously.
  ///
  /// Returns `null` if the page cannot be rendered (e.g. the file went away).
  Future<PdfRasterResult?> rasterizePage({
    required String filePath,
    required int pageNumber,
    required int scaleBucket,
  }) async {
    if (_disposed) {
      return null;
    }
    final int bucket = scaleBucket.clamp(0, _scaleLadder.length - 1);
    final PdfDocument document = await _document(filePath);
    if (pageNumber < 1 || pageNumber > document.pages.length) {
      return null;
    }
    final PdfPage page = document.pages[pageNumber - 1];

    // Target pixel size for this zoom bucket, capped so one page can't blow
    // the memory budget.
    final double ladder = _scaleLadder[bucket];
    int targetWidth = (page.width * ladder).round().clamp(1, 1 << 20);
    int targetHeight = (page.height * ladder).round().clamp(1, 1 << 20);
    final int longest =
        targetWidth > targetHeight ? targetWidth : targetHeight;
    if (longest > _maxRasterPixelSide) {
      final double shrink = _maxRasterPixelSide / longest;
      targetWidth = (targetWidth * shrink).round().clamp(1, 1 << 20);
      targetHeight = (targetHeight * shrink).round().clamp(1, 1 << 20);
    }

    // Native PDFium rasterisation — runs on pdfrx's own background isolate.
    final PdfImage? rendered = await page.render(
      fullWidth: targetWidth.toDouble(),
      fullHeight: targetHeight.toDouble(),
      width: targetWidth,
      height: targetHeight,
    );
    if (rendered == null || _disposed) {
      rendered?.dispose();
      return null;
    }

    try {
      final ui.Image image = await _decodeBgra(
        rendered.pixels,
        rendered.width,
        rendered.height,
      );
      return PdfRasterResult(image: image, scaleBucket: bucket);
    } finally {
      // The PdfImage's native pixel buffer is no longer needed once decoded.
      rendered.dispose();
    }
  }

  /// Decodes raw BGRA8888 [pixels] into a `ui.Image`.
  ///
  /// `pdfrx` hands back pixels in `bgra8888`; [ui.decodeImageFromPixels] takes
  /// that format directly and decodes asynchronously on the engine side, so no
  /// codec round-trip is needed.
  static Future<ui.Image> _decodeBgra(
    Uint8List pixels,
    int width,
    int height,
  ) {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.bgra8888,
      completer.complete,
    );
    return completer.future;
  }

  /// Closes every pooled document and rejects further work.
  ///
  /// The controller calls this from its own `dispose`. Decoded `ui.Image`s
  /// handed out by [rasterizePage] are owned by the caller and are *not*
  /// disposed here — the controller's raster cache disposes those.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    final List<Future<PdfDocument>> pending = _openDocuments.values.toList();
    _openDocuments.clear();
    for (final Future<PdfDocument> docFuture in pending) {
      try {
        final PdfDocument document = await docFuture;
        await document.dispose();
      } on Object {
        // A document that never finished opening has nothing to release.
      }
    }
  }
}
