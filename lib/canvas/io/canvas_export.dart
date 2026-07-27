import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as image_codec;
import 'package:path_provider/path_provider.dart';

import 'package:zenno/canvas/canvas_controller.dart';
import 'package:zenno/canvas/engine/spatial_index.dart';
import 'package:zenno/canvas/model/canvas_element.dart';
import 'package:zenno/canvas/model/canvas_style.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/model/viewport_state.dart';
import 'package:zenno/canvas/pdf/pdf_raster_service.dart';
import 'package:zenno/canvas/raster/image_raster_decoder.dart';
import 'package:zenno/canvas/render/elements_painter.dart';
import 'package:zenno/canvas/render/grid_painter.dart';
import 'package:zenno/canvas/tools/arrow_geometry.dart';
import 'package:zenno/core/database/tables/canvas_tables.dart';

class _JpgEncodeRequest {
  const _JpgEncodeRequest({
    required this.width,
    required this.height,
    required this.rgba,
    required this.quality,
  });

  final int width;
  final int height;
  final Uint8List rgba;
  final int quality;
}

Uint8List _encodeJpgOnWorker(_JpgEncodeRequest request) {
  final image_codec.Image rgba = image_codec.Image.fromBytes(
    width: request.width,
    height: request.height,
    bytes: request.rgba.buffer,
    bytesOffset: request.rgba.offsetInBytes,
    order: image_codec.ChannelOrder.rgba,
  );
  return Uint8List.fromList(
    image_codec.encodeJpg(rgba, quality: request.quality.clamp(1, 100)),
  );
}

class _PreparedExportElements {
  const _PreparedExportElements({required this.elements, required this.owned});

  final List<CanvasElement> elements;
  final List<ui.Image> owned;

  void dispose() {
    for (final ui.Image image in owned) {
      image.dispose();
    }
  }
}

enum CanvasExportScope { content, viewport, selection }

enum CanvasExportFormat {
  png('png'),
  jpg('jpg'),
  svg('svg');

  const CanvasExportFormat(this.extension);

  final String extension;
}

class CanvasExportOptions {
  const CanvasExportOptions({
    this.scope = CanvasExportScope.content,
    this.format = CanvasExportFormat.png,
    this.scale = 1.5,
    this.jpgQuality = 92,
    this.padding = 32,
    this.transparentBackground = false,
    this.includeGrid = true,
  });

  final CanvasExportScope scope;
  final CanvasExportFormat format;
  final double scale;
  final int jpgQuality;
  final double padding;
  final bool transparentBackground;
  final bool includeGrid;

  bool get paintsBackground =>
      format == CanvasExportFormat.jpg || !transparentBackground;
}

class CanvasExportResult {
  const CanvasExportResult({
    required this.filePath,
    required this.bytes,
    required this.pixelSize,
    required this.worldRegion,
    required this.options,
  });

  final String filePath;
  final Uint8List bytes;
  final Size pixelSize;
  final Rect worldRegion;
  final CanvasExportOptions options;
}

class CanvasExportException implements Exception {
  const CanvasExportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CanvasExportTooLargeException extends CanvasExportException {
  const CanvasExportTooLargeException(super.message);
}

abstract final class CanvasExportService {
  static const int maxPixels = 32 * 1024 * 1024;

  static Future<CanvasExportResult> exportToFile({
    required CanvasController controller,
    required CanvasExportOptions options,
  }) async {
    final Uint8List bytes = await renderToBytes(
      controller: controller,
      options: options,
    );
    final Rect region = resolveWorldRegion(
      controller: controller,
      scope: options.scope,
    )!;
    final Size pixelSize = estimatePixelSize(region: region, options: options);
    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${docs.path}/canvas_exports');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final String stamp = DateTime.now().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
    final File file = File(
      '${dir.path}/zenno_canvas_$stamp.${options.format.extension}',
    );
    await file.writeAsBytes(bytes, flush: true);
    return CanvasExportResult(
      filePath: file.path,
      bytes: bytes,
      pixelSize: pixelSize,
      worldRegion: region,
      options: options,
    );
  }

  static Future<Uint8List> renderToBytes({
    required CanvasController controller,
    required CanvasExportOptions options,
  }) async {
    final Rect region =
        resolveWorldRegion(controller: controller, scope: options.scope) ??
        (throw _emptyScopeError(options.scope));
    final Size pixelSize = estimatePixelSize(region: region, options: options);
    final int width = pixelSize.width.toInt();
    final int height = pixelSize.height.toInt();
    final int pixels = width * height;
    if (pixels > maxPixels) {
      throw CanvasExportTooLargeException(
        'Export is ${_megapixels(pixels)}MP. Lower the scale or export a smaller region.',
      );
    }
    final double scale = options.scale.clamp(0.25, 4.0);
    final double padding = math.max(0, options.padding);
    final List<CanvasElement> scopedElements = _elementsForScope(
      controller,
      options.scope,
    );
    final _PreparedExportElements prepared = await _prepareElements(
      scopedElements,
      scale: scale,
    );
    try {
      if (options.format == CanvasExportFormat.svg) {
        return Uint8List.fromList(
          utf8.encode(
            await _renderSvg(
              controller: controller,
              options: options,
              elements: prepared.elements,
            ),
          ),
        );
      }

      final ViewportState exportViewport = ViewportState(
        translation: Offset(
          (padding - region.left) * scale,
          (padding - region.top) * scale,
        ),
        scale: scale,
      );
      final SpatialIndex spatialIndex = _indexFor(prepared.elements);
      final Size outputSize = Size(width.toDouble(), height.toDouble());

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      if (options.paintsBackground) {
        canvas.drawRect(
          Offset.zero & outputSize,
          Paint()..color = Color(controller.paperStyle.backgroundColor),
        );
        PaperTexturePainter(
          viewport: exportViewport,
          style: controller.paperStyle,
        ).paint(canvas, outputSize);
      }
      if (options.includeGrid) {
        GridPainter(
          viewport: exportViewport,
          style: controller.paperStyle,
        ).paint(canvas, outputSize);
      }
      ElementsPainter(
        elements: prepared.elements,
        spatialIndex: spatialIndex,
        viewport: exportViewport,
      ).paint(canvas, outputSize);
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(width, height);
      picture.dispose();
      try {
        return switch (options.format) {
          CanvasExportFormat.png => _encodePng(image),
          CanvasExportFormat.jpg => _encodeJpg(image, options.jpgQuality),
          CanvasExportFormat.svg => throw StateError('SVG handled earlier.'),
        };
      } finally {
        image.dispose();
      }
    } finally {
      prepared.dispose();
    }
  }

  static Rect? resolveWorldRegion({
    required CanvasController controller,
    required CanvasExportScope scope,
  }) {
    return switch (scope) {
      CanvasExportScope.content => controller.contentBounds,
      CanvasExportScope.viewport => controller.visibleWorldRect,
      CanvasExportScope.selection => controller.selectionBounds,
    };
  }

  static Size estimatePixelSize({
    required Rect region,
    required CanvasExportOptions options,
  }) {
    final double scale = options.scale.clamp(0.25, 4.0);
    final double padding = math.max(0, options.padding);
    final int width = math.max(
      1,
      ((region.width + padding * 2) * scale).ceil(),
    );
    final int height = math.max(
      1,
      ((region.height + padding * 2) * scale).ceil(),
    );
    return Size(width.toDouble(), height.toDouble());
  }

  static List<CanvasElement> _elementsForScope(
    CanvasController controller,
    CanvasExportScope scope,
  ) {
    return switch (scope) {
      CanvasExportScope.selection => controller.selectedElements,
      CanvasExportScope.viewport => <CanvasElement>[
        for (final CanvasElement element in controller.visibleElements)
          if (element.worldBounds.overlaps(controller.visibleWorldRect))
            element,
      ],
      CanvasExportScope.content => controller.visibleElements,
    };
  }

  static SpatialIndex _indexFor(List<CanvasElement> elements) {
    final SpatialIndex index = SpatialIndex();
    for (final CanvasElement element in elements) {
      index.insert(element.id, element.worldBounds);
    }
    return index;
  }

  static CanvasExportException _emptyScopeError(CanvasExportScope scope) {
    return switch (scope) {
      CanvasExportScope.content => const CanvasExportException(
        'There is nothing on this canvas to export yet.',
      ),
      CanvasExportScope.viewport => const CanvasExportException(
        'The viewport is not ready to export yet.',
      ),
      CanvasExportScope.selection => const CanvasExportException(
        'Select something before exporting a selection.',
      ),
    };
  }

  static Future<_PreparedExportElements> _prepareElements(
    List<CanvasElement> elements, {
    required double scale,
  }) async {
    final List<CanvasElement> prepared = <CanvasElement>[];
    final List<ui.Image> owned = <ui.Image>[];
    PdfRasterService? pdfService;
    try {
      for (final CanvasElement element in elements) {
        final int rasterBucket = RasterScalePolicy.bucketForElement(
          worldBounds: element.worldBounds,
          viewportScale: scale,
          devicePixelRatio: 1,
        );
        switch (element) {
          case ImageElement(raster: ui.Image(), :final rasterScaleBucket)
              when rasterScaleBucket >= rasterBucket:
            prepared.add(element);
          case ImageElement():
            final DecodedImageRaster? decoded =
                await ImageRasterDecoder.decodeFile(
                  element.sourceFilePath,
                  scaleBucket: rasterBucket,
                );
            if (decoded == null) {
              throw CanvasExportException(
                'Could not load image "${element.sourceFilePath}" for export.',
              );
            }
            owned.add(decoded.image);
            prepared.add(
              element.copyWith(
                raster: decoded.image,
                rasterScaleBucket: decoded.scaleBucket,
              ),
            );
          case PdfElement(raster: ui.Image(), :final rasterScaleBucket)
              when rasterScaleBucket >= rasterBucket:
            prepared.add(element);
          case PdfElement():
            if (!await File(element.sourceFilePath).exists()) {
              throw CanvasExportException(
                'Could not load PDF "${element.sourceFilePath}" page ${element.pageNumber} for export.',
              );
            }
            pdfService ??= PdfRasterService();
            final PdfRasterResult? rendered;
            try {
              rendered = await pdfService.rasterizePage(
                filePath: element.sourceFilePath,
                pageNumber: element.pageNumber,
                scaleBucket: rasterBucket,
              );
            } on Object catch (error) {
              throw CanvasExportException(
                'Could not render PDF page ${element.pageNumber} for export: $error',
              );
            }
            if (rendered == null) {
              throw CanvasExportException(
                'Could not render PDF page ${element.pageNumber} for export.',
              );
            }
            owned.add(rendered.image);
            prepared.add(
              element.copyWith(
                raster: rendered.image,
                rasterScaleBucket: rendered.scaleBucket,
              ),
            );
          case InkElement():
          case LinkElement():
          case TextElement():
          case ShapeElement():
            prepared.add(element);
        }
      }
      return _PreparedExportElements(elements: prepared, owned: owned);
    } on Object {
      for (final ui.Image image in owned) {
        image.dispose();
      }
      rethrow;
    } finally {
      if (pdfService != null) {
        await pdfService.dispose();
      }
    }
  }

  static Future<Uint8List> _encodePng(ui.Image image) async {
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      throw const CanvasExportException('Could not encode PNG export.');
    }
    return byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
  }

  static Future<Uint8List> _encodeJpg(ui.Image image, int quality) async {
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (byteData == null) {
      throw const CanvasExportException('Could not encode JPG export.');
    }
    final Uint8List rgba = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    return compute(
      _encodeJpgOnWorker,
      _JpgEncodeRequest(
        width: image.width,
        height: image.height,
        rgba: Uint8List.fromList(rgba),
        quality: quality.clamp(1, 100).toInt(),
      ),
    );
  }

  static String _megapixels(int pixels) {
    return (pixels / 1000000).toStringAsFixed(1);
  }

  static Future<String> _renderSvg({
    required CanvasController controller,
    required CanvasExportOptions options,
    required List<CanvasElement> elements,
  }) async {
    final Rect region =
        resolveWorldRegion(controller: controller, scope: options.scope) ??
        (throw _emptyScopeError(options.scope));
    final Size pixelSize = estimatePixelSize(region: region, options: options);
    final double scale = options.scale.clamp(0.25, 4.0);
    final double padding = math.max(0, options.padding);
    final StringBuffer out = StringBuffer()
      ..writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" width="${pixelSize.width.toStringAsFixed(0)}" height="${pixelSize.height.toStringAsFixed(0)}" viewBox="0 0 ${pixelSize.width.toStringAsFixed(0)} ${pixelSize.height.toStringAsFixed(0)}">',
      );
    if (options.paintsBackground) {
      out.writeln(
        '<rect width="100%" height="100%" fill="${_svgColor(controller.paperStyle.backgroundColor)}"/>',
      );
    }
    if (options.includeGrid) {
      _writeSvgGrid(
        out,
        style: controller.paperStyle,
        region: region,
        padding: padding,
        scale: scale,
      );
    }
    for (final CanvasElement element in elements) {
      switch (element) {
        case InkElement():
          _writeSvgInk(out, element, region, padding, scale);
        case ShapeElement():
          _writeSvgShape(out, element, region, padding, scale);
        case TextElement():
          _writeSvgText(out, element, region, padding, scale);
        case ImageElement():
          await _writeSvgImage(out, element, region, padding, scale);
        case PdfElement():
          await _writeSvgPdf(out, element, region, padding, scale);
        case LinkElement():
          _writeSvgLink(out, element, region, padding, scale);
      }
    }
    out.writeln('</svg>');
    return out.toString();
  }

  static void _writeSvgGrid(
    StringBuffer out, {
    required CanvasPaperStyle style,
    required Rect region,
    required double padding,
    required double scale,
  }) {
    if (style.kind == BackgroundKind.blank) {
      return;
    }
    final Rect world = Rect.fromLTRB(
      region.left - padding,
      region.top - padding,
      region.right + padding,
      region.bottom + padding,
    );
    final double step = _svgGridStep(scale, style.gridSpacing);
    final double startX = (world.left / step).floorToDouble() * step;
    final double startY = (world.top / step).floorToDouble() * step;
    final String color = _svgColor(style.gridColor);
    final String opacity = style.gridOpacity.clamp(0.0, 1.0).toStringAsFixed(3);
    out.writeln(
      '<g id="canvas-grid" data-kind="${style.kind.name}" stroke="$color" fill="$color" opacity="$opacity" stroke-linecap="round">',
    );
    switch (style.kind) {
      case BackgroundKind.blank:
        break;
      case BackgroundKind.lined:
        for (var y = startY; y <= world.bottom; y += step) {
          _writeSvgGridLine(
            out,
            Offset(world.left, y),
            Offset(world.right, y),
            region,
            padding,
            scale,
          );
        }
      case BackgroundKind.grid:
        final int majorEvery = style.graphMajorInterval <= 1
            ? 0
            : style.graphMajorInterval;
        for (var x = startX; x <= world.right; x += step) {
          final bool major =
              majorEvery > 0 && ((x / step).round() % majorEvery == 0);
          _writeSvgGridLine(
            out,
            Offset(x, world.top),
            Offset(x, world.bottom),
            region,
            padding,
            scale,
            strokeWidth: major ? 1.5 : 1,
          );
        }
        for (var y = startY; y <= world.bottom; y += step) {
          final bool major =
              majorEvery > 0 && ((y / step).round() % majorEvery == 0);
          _writeSvgGridLine(
            out,
            Offset(world.left, y),
            Offset(world.right, y),
            region,
            padding,
            scale,
            strokeWidth: major ? 1.5 : 1,
          );
        }
      case BackgroundKind.isometric:
        _writeSvgGridLineFamily(
          out,
          world,
          step,
          math.pi / 2,
          region,
          padding,
          scale,
        );
        _writeSvgGridLineFamily(
          out,
          world,
          step,
          math.pi / 6,
          region,
          padding,
          scale,
        );
        _writeSvgGridLineFamily(
          out,
          world,
          step,
          -math.pi / 6,
          region,
          padding,
          scale,
        );
      case BackgroundKind.triangle:
        _writeSvgGridLineFamily(out, world, step, 0, region, padding, scale);
        _writeSvgGridLineFamily(
          out,
          world,
          step,
          math.pi / 3,
          region,
          padding,
          scale,
        );
        _writeSvgGridLineFamily(
          out,
          world,
          step,
          -math.pi / 3,
          region,
          padding,
          scale,
        );
      case BackgroundKind.dotted:
        for (var x = startX; x <= world.right; x += step) {
          for (var y = startY; y <= world.bottom; y += step) {
            final Offset point = _svgOffset(
              Offset(x, y),
              region,
              padding,
              scale,
            );
            out.writeln(
              '<circle cx="${point.dx.toStringAsFixed(2)}" cy="${point.dy.toStringAsFixed(2)}" r="1" stroke="none"/>',
            );
          }
        }
    }
    out.writeln('</g>');
  }

  static double _svgGridStep(double scale, double preferredStep) {
    var step = preferredStep.clamp(1.0, 1048576.0).toDouble();
    while (step * scale < 32 && step < 1048576.0) {
      step *= 2;
    }
    while (step * scale > 96 && step > 1) {
      step /= 2;
    }
    return step;
  }

  static void _writeSvgGridLine(
    StringBuffer out,
    Offset start,
    Offset end,
    Rect region,
    double padding,
    double scale, {
    double strokeWidth = 1,
  }) {
    final Offset a = _svgOffset(start, region, padding, scale);
    final Offset b = _svgOffset(end, region, padding, scale);
    out.writeln(
      '<line x1="${a.dx.toStringAsFixed(2)}" y1="${a.dy.toStringAsFixed(2)}" x2="${b.dx.toStringAsFixed(2)}" y2="${b.dy.toStringAsFixed(2)}" stroke-width="${strokeWidth.toStringAsFixed(2)}"/>',
    );
  }

  static void _writeSvgGridLineFamily(
    StringBuffer out,
    Rect world,
    double step,
    double angle,
    Rect region,
    double padding,
    double scale,
  ) {
    final Offset direction = Offset(math.cos(angle), math.sin(angle));
    final Offset normal = Offset(-direction.dy, direction.dx);
    final List<Offset> corners = <Offset>[
      world.topLeft,
      world.topRight,
      world.bottomRight,
      world.bottomLeft,
    ];
    double minProjection = _dot(corners.first, normal);
    double maxProjection = minProjection;
    for (final Offset corner in corners.skip(1)) {
      final double projection = _dot(corner, normal);
      minProjection = math.min(minProjection, projection);
      maxProjection = math.max(maxProjection, projection);
    }
    final double extent =
        math.sqrt(
          math.pow(world.width, 2).toDouble() +
              math.pow(world.height, 2).toDouble(),
        ) +
        step;
    final double first = (minProjection / step).floorToDouble() * step;
    for (
      var projection = first;
      projection <= maxProjection;
      projection += step
    ) {
      final Offset anchor = normal * projection;
      _writeSvgGridLine(
        out,
        anchor - direction * extent,
        anchor + direction * extent,
        region,
        padding,
        scale,
      );
    }
  }

  static double _dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

  static void _writeSvgInk(
    StringBuffer out,
    InkElement element,
    Rect region,
    double padding,
    double scale,
  ) {
    if (element.stroke.points.isEmpty) {
      return;
    }
    final double baseOpacity = switch (element.stroke.tool) {
      StrokeToolKind.highlighter => 0.35,
      StrokeToolKind.pencil => 0.72,
      StrokeToolKind.marker => 0.78,
      StrokeToolKind.airbrush => 0.42,
      StrokeToolKind.fill => 1,
      StrokeToolKind.pen => 1,
    };
    final double opacity =
        baseOpacity * (((element.stroke.color >>> 24) & 0xFF) / 255);
    final String blend = element.stroke.tool == StrokeToolKind.highlighter
        ? ' style="mix-blend-mode:multiply"'
        : '';
    final String fillRule = element.stroke.tool == StrokeToolKind.fill
        ? ' fill-rule="evenodd"'
        : '';
    out.writeln(
      '<path data-ink-outline="true" d="${_svgPathData(element.outlinePath, region, padding, scale)}" fill="${_svgColor(element.stroke.color)}" stroke="none" opacity="${opacity.toStringAsFixed(2)}"$fillRule$blend/>',
    );
  }

  static void _writeSvgShape(
    StringBuffer out,
    ShapeElement element,
    Rect region,
    double padding,
    double scale,
  ) {
    final Rect bounds = _svgRectFromWorld(
      Rect.fromPoints(element.start, element.end),
      region,
      padding,
      scale,
    );
    final double width = math.max(0.5, element.strokeWidth * scale);
    final String stroke = _svgColor(element.color);
    final String transform = _svgRotationTransform(bounds, element.rotation);
    out.writeln('<g data-shape-kind="${element.shapeKind}"$transform>');
    switch (element.shapeKind) {
      case 1:
        out.writeln(
          '<rect x="${bounds.left.toStringAsFixed(2)}" y="${bounds.top.toStringAsFixed(2)}" width="${bounds.width.toStringAsFixed(2)}" height="${bounds.height.toStringAsFixed(2)}" fill="none" stroke="$stroke" stroke-width="${width.toStringAsFixed(2)}"/>',
        );
      case 2:
        out.writeln(
          '<ellipse cx="${bounds.center.dx.toStringAsFixed(2)}" cy="${bounds.center.dy.toStringAsFixed(2)}" rx="${(bounds.width / 2).toStringAsFixed(2)}" ry="${(bounds.height / 2).toStringAsFixed(2)}" fill="none" stroke="$stroke" stroke-width="${width.toStringAsFixed(2)}"/>',
        );
      case 0:
        final Offset start = _svgOffset(element.start, region, padding, scale);
        final Offset end = _svgOffset(element.end, region, padding, scale);
        out.writeln(
          '<line x1="${start.dx.toStringAsFixed(2)}" y1="${start.dy.toStringAsFixed(2)}" x2="${end.dx.toStringAsFixed(2)}" y2="${end.dy.toStringAsFixed(2)}" stroke="$stroke" stroke-width="${width.toStringAsFixed(2)}" stroke-linecap="round"/>',
        );
      case 3:
        _writeSvgArrow(out, element, region, padding, scale, stroke, width);
      default:
        final Offset start = _svgOffset(element.start, region, padding, scale);
        final Offset end = _svgOffset(element.end, region, padding, scale);
        out.writeln(
          '<line x1="${start.dx.toStringAsFixed(2)}" y1="${start.dy.toStringAsFixed(2)}" x2="${end.dx.toStringAsFixed(2)}" y2="${end.dy.toStringAsFixed(2)}" stroke="$stroke" stroke-width="${width.toStringAsFixed(2)}" stroke-linecap="round"/>',
        );
    }
    out.writeln('</g>');
  }

  static void _writeSvgArrow(
    StringBuffer out,
    ShapeElement element,
    Rect region,
    double padding,
    double scale,
    String stroke,
    double width,
  ) {
    final Offset delta = element.end - element.start;
    final double length = delta.distance;
    if (length == 0) {
      return;
    }
    if (element.legacyArrow) {
      final Offset start = _svgOffset(element.start, region, padding, scale);
      final Offset end = _svgOffset(element.end, region, padding, scale);
      final double angle = math.atan2(delta.dy, delta.dx);
      final double headLength = ArrowGeometry.legacyHeadLength(
        element.start,
        element.end,
      );
      const double headAngle = math.pi / 7;
      final Offset leftWorld = Offset(
        element.end.dx - headLength * math.cos(angle - headAngle),
        element.end.dy - headLength * math.sin(angle - headAngle),
      );
      final Offset rightWorld = Offset(
        element.end.dx - headLength * math.cos(angle + headAngle),
        element.end.dy - headLength * math.sin(angle + headAngle),
      );
      final Offset left = _svgOffset(leftWorld, region, padding, scale);
      final Offset right = _svgOffset(rightWorld, region, padding, scale);
      out
        ..writeln(
          '<line data-arrow-body="legacy" x1="${start.dx.toStringAsFixed(2)}" y1="${start.dy.toStringAsFixed(2)}" x2="${end.dx.toStringAsFixed(2)}" y2="${end.dy.toStringAsFixed(2)}" stroke="$stroke" stroke-width="${width.toStringAsFixed(2)}" stroke-linecap="round"/>',
        )
        ..writeln(
          '<path data-arrow-head="filled" d="M ${end.dx.toStringAsFixed(2)} ${end.dy.toStringAsFixed(2)} L ${left.dx.toStringAsFixed(2)} ${left.dy.toStringAsFixed(2)} L ${right.dx.toStringAsFixed(2)} ${right.dy.toStringAsFixed(2)} Z" fill="$stroke" stroke="none"/>',
        );
      return;
    }

    final ui.Path body = ArrowGeometry.bodyPath(
      body: element.arrowBody,
      start: element.start,
      end: element.end,
      controls: element.controlPoints,
      strokeWidth: element.strokeWidth,
    );
    out.writeln(
      '<path data-arrow-body="${element.arrowBody.name}" d="${_svgPathData(body, region, padding, scale)}" fill="none" stroke="$stroke" stroke-width="${width.toStringAsFixed(2)}" stroke-linecap="round" stroke-linejoin="round"/>',
    );
    final double headLength = ArrowGeometry.styledHeadLength(
      strokeWidth: element.strokeWidth,
      headScale: element.arrowHeadScale,
      maxLength: length,
    );
    _writeSvgArrowHead(
      out,
      tip: element.end,
      direction: ArrowGeometry.endTangent(
        body: element.arrowBody,
        start: element.start,
        end: element.end,
        controls: element.controlPoints,
        strokeWidth: element.strokeWidth,
      ),
      style: element.arrowEndHead,
      length: headLength,
      region: region,
      padding: padding,
      scale: scale,
      stroke: stroke,
      width: width,
    );
    _writeSvgArrowHead(
      out,
      tip: element.start,
      direction: -ArrowGeometry.startTangent(
        body: element.arrowBody,
        start: element.start,
        end: element.end,
        controls: element.controlPoints,
        strokeWidth: element.strokeWidth,
      ),
      style: element.arrowStartHead,
      length: headLength,
      region: region,
      padding: padding,
      scale: scale,
      stroke: stroke,
      width: width,
    );
  }

  static String _svgPathData(
    ui.Path path,
    Rect region,
    double padding,
    double scale,
  ) {
    final StringBuffer data = StringBuffer();
    for (final ui.PathMetric metric in path.computeMetrics()) {
      final int segments = (metric.length / 4).ceil().clamp(1, 256);
      for (var i = 0; i <= segments; i++) {
        final ui.Tangent? tangent = metric.getTangentForOffset(
          metric.length * i / segments,
        );
        if (tangent == null) continue;
        final Offset point = _svgOffset(
          tangent.position,
          region,
          padding,
          scale,
        );
        data.write(
          '${i == 0 ? 'M' : 'L'} ${point.dx.toStringAsFixed(2)} ${point.dy.toStringAsFixed(2)} ',
        );
      }
      if (metric.isClosed) {
        data.write('Z ');
      }
    }
    return data.toString().trim();
  }

  static void _writeSvgArrowHead(
    StringBuffer out, {
    required Offset tip,
    required Offset direction,
    required ArrowHeadStyle style,
    required double length,
    required Rect region,
    required double padding,
    required double scale,
    required String stroke,
    required double width,
  }) {
    if (style == ArrowHeadStyle.none ||
        length <= 0 ||
        direction.distance == 0) {
      return;
    }
    final Offset unit = direction / direction.distance;
    final Offset normal = Offset(-unit.dy, unit.dx);
    final double wing = length * 0.48;
    final Offset base = tip - unit * length;
    final Offset left = base + normal * wing;
    final Offset right = base - normal * wing;
    final Offset svgTip = _svgOffset(tip, region, padding, scale);
    final Offset svgLeft = _svgOffset(left, region, padding, scale);
    final Offset svgRight = _svgOffset(right, region, padding, scale);
    switch (style) {
      case ArrowHeadStyle.none:
        return;
      case ArrowHeadStyle.open:
        out.writeln(
          '<path data-arrow-head="open" d="M ${svgLeft.dx.toStringAsFixed(2)} ${svgLeft.dy.toStringAsFixed(2)} L ${svgTip.dx.toStringAsFixed(2)} ${svgTip.dy.toStringAsFixed(2)} L ${svgRight.dx.toStringAsFixed(2)} ${svgRight.dy.toStringAsFixed(2)}" fill="none" stroke="$stroke" stroke-width="${width.toStringAsFixed(2)}" stroke-linecap="round" stroke-linejoin="round"/>',
        );
      case ArrowHeadStyle.filled:
        out.writeln(
          '<path data-arrow-head="filled" d="M ${svgTip.dx.toStringAsFixed(2)} ${svgTip.dy.toStringAsFixed(2)} L ${svgLeft.dx.toStringAsFixed(2)} ${svgLeft.dy.toStringAsFixed(2)} L ${svgRight.dx.toStringAsFixed(2)} ${svgRight.dy.toStringAsFixed(2)} Z" fill="$stroke" stroke="none"/>',
        );
      case ArrowHeadStyle.dot:
        out.writeln(
          '<circle data-arrow-head="dot" cx="${svgTip.dx.toStringAsFixed(2)}" cy="${svgTip.dy.toStringAsFixed(2)}" r="${(length * 0.28 * scale).toStringAsFixed(2)}" fill="$stroke" stroke="none"/>',
        );
      case ArrowHeadStyle.diamond:
        final Offset center = tip - unit * (length * 0.48);
        final Offset tail = tip - unit * (length * 0.96);
        final Offset upper = center + normal * wing * 0.75;
        final Offset lower = center - normal * wing * 0.75;
        final Offset svgUpper = _svgOffset(upper, region, padding, scale);
        final Offset svgTail = _svgOffset(tail, region, padding, scale);
        final Offset svgLower = _svgOffset(lower, region, padding, scale);
        out.writeln(
          '<path data-arrow-head="diamond" d="M ${svgTip.dx.toStringAsFixed(2)} ${svgTip.dy.toStringAsFixed(2)} L ${svgUpper.dx.toStringAsFixed(2)} ${svgUpper.dy.toStringAsFixed(2)} L ${svgTail.dx.toStringAsFixed(2)} ${svgTail.dy.toStringAsFixed(2)} L ${svgLower.dx.toStringAsFixed(2)} ${svgLower.dy.toStringAsFixed(2)} Z" fill="none" stroke="$stroke" stroke-width="${width.toStringAsFixed(2)}" stroke-linejoin="round"/>',
        );
      case ArrowHeadStyle.bar:
        final Offset a = _svgOffset(
          tip + normal * wing,
          region,
          padding,
          scale,
        );
        final Offset b = _svgOffset(
          tip - normal * wing,
          region,
          padding,
          scale,
        );
        out.writeln(
          '<line data-arrow-head="bar" x1="${a.dx.toStringAsFixed(2)}" y1="${a.dy.toStringAsFixed(2)}" x2="${b.dx.toStringAsFixed(2)}" y2="${b.dy.toStringAsFixed(2)}" stroke="$stroke" stroke-width="${width.toStringAsFixed(2)}" stroke-linecap="round"/>',
        );
    }
  }

  static void _writeSvgText(
    StringBuffer out,
    TextElement element,
    Rect region,
    double padding,
    double scale,
  ) {
    final Rect rect = _svgRectFromWorld(
      element.placementBounds,
      region,
      padding,
      scale,
    );
    final String transform = _svgRotationTransform(rect, element.rotation);
    final List<String> lines = element.text.split('\n');
    final double fontSize = element.fontSize * scale;
    out.writeln(
      '<text x="${rect.left.toStringAsFixed(2)}" y="${(rect.top + fontSize).toStringAsFixed(2)}" fill="${_svgColor(element.color)}" font-size="${fontSize.toStringAsFixed(2)}"$transform>',
    );
    for (var i = 0; i < lines.length; i += 1) {
      final String y = i == 0 ? '0' : (fontSize * 1.25).toStringAsFixed(2);
      out.writeln(
        '<tspan x="${rect.left.toStringAsFixed(2)}" dy="$y">${_xmlEscape(lines[i])}</tspan>',
      );
    }
    out.writeln('</text>');
  }

  static Future<void> _writeSvgImage(
    StringBuffer out,
    ImageElement element,
    Rect region,
    double padding,
    double scale,
  ) async {
    final Rect rect = _svgRectFromWorld(
      element.placementBounds,
      region,
      padding,
      scale,
    );
    final ui.Image? raster = element.raster;
    if (raster == null) {
      throw CanvasExportException(
        'Image "${element.sourceFilePath}" is not ready for SVG export.',
      );
    }
    final String data = base64Encode(await _encodePng(raster));
    final String transform = _svgRotationTransform(rect, element.rotation);
    out.writeln(
      '<image data-source-kind="image" href="data:image/png;base64,$data" x="${rect.left.toStringAsFixed(2)}" y="${rect.top.toStringAsFixed(2)}" width="${rect.width.toStringAsFixed(2)}" height="${rect.height.toStringAsFixed(2)}"$transform/>',
    );
  }

  static Future<void> _writeSvgPdf(
    StringBuffer out,
    PdfElement element,
    Rect region,
    double padding,
    double scale,
  ) async {
    final Rect rect = _svgRectFromWorld(
      element.placementBounds,
      region,
      padding,
      scale,
    );
    final ui.Image? raster = element.raster;
    if (raster == null) {
      throw CanvasExportException(
        'PDF page ${element.pageNumber} is not ready for SVG export.',
      );
    }
    final String data = base64Encode(await _encodePng(raster));
    final String transform = _svgRotationTransform(rect, element.rotation);
    out
      ..writeln('<g$transform>')
      ..writeln(
        '<rect x="${rect.left.toStringAsFixed(2)}" y="${rect.top.toStringAsFixed(2)}" width="${rect.width.toStringAsFixed(2)}" height="${rect.height.toStringAsFixed(2)}" fill="#FFFFFF"/>',
      )
      ..writeln(
        '<image data-source-kind="pdf-page" data-page="${element.pageNumber}" href="data:image/png;base64,$data" x="${rect.left.toStringAsFixed(2)}" y="${rect.top.toStringAsFixed(2)}" width="${rect.width.toStringAsFixed(2)}" height="${rect.height.toStringAsFixed(2)}"/>',
      )
      ..writeln('</g>');
  }

  static void _writeSvgLink(
    StringBuffer out,
    LinkElement element,
    Rect region,
    double padding,
    double scale,
  ) {
    final Rect rect = _svgRectFromWorld(
      element.placementBounds,
      region,
      padding,
      scale,
    );
    final String transform = _svgRotationTransform(rect, element.rotation);
    out
      ..writeln('<g$transform>')
      ..writeln(
        '<rect x="${rect.left.toStringAsFixed(2)}" y="${rect.top.toStringAsFixed(2)}" width="${rect.width.toStringAsFixed(2)}" height="${rect.height.toStringAsFixed(2)}" rx="${(rect.height * 0.28).toStringAsFixed(2)}" fill="#e8b84b" fill-opacity="0.12" stroke="#e8b84b"/>',
      )
      ..writeln(
        '<text x="${(rect.left + rect.height * 0.35).toStringAsFixed(2)}" y="${(rect.center.dy + rect.height * 0.12).toStringAsFixed(2)}" fill="#e8b84b" font-size="${(rect.height * 0.34).toStringAsFixed(2)}">${_xmlEscape(element.label.isEmpty ? 'Link' : element.label)}</text>',
      )
      ..writeln('</g>');
  }

  static Rect _svgRectFromWorld(
    Rect rect,
    Rect region,
    double padding,
    double scale,
  ) {
    return Rect.fromLTWH(
      (rect.left - region.left + padding) * scale,
      (rect.top - region.top + padding) * scale,
      rect.width * scale,
      rect.height * scale,
    );
  }

  static String _svgRotationTransform(Rect rect, double radians) {
    if (radians == 0) {
      return '';
    }
    final double degrees = radians * 180 / math.pi;
    return ' transform="rotate(${degrees.toStringAsFixed(3)} ${rect.center.dx.toStringAsFixed(2)} ${rect.center.dy.toStringAsFixed(2)})"';
  }

  static Offset _svgOffset(
    Offset point,
    Rect region,
    double padding,
    double scale,
  ) {
    return Offset(
      (point.dx - region.left + padding) * scale,
      (point.dy - region.top + padding) * scale,
    );
  }

  static String _svgColor(int argb) {
    final int rgb = argb & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static String _xmlEscape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}
