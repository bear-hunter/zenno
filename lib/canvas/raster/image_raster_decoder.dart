import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Shared, capped resolution ladder for canvas image and PDF rasters.
abstract final class RasterScalePolicy {
  static const List<int> pixelSideLadder = <int>[512, 1024, 2048, 4096];
  static const int importBucket = 1;

  static int get maxPixelSide => pixelSideLadder.last;

  static int bucketForElement({
    required Rect worldBounds,
    required double viewportScale,
    required double devicePixelRatio,
  }) {
    final double desiredPixelSide =
        worldBounds.longestSide *
        viewportScale.clamp(0.01, 64) *
        devicePixelRatio.clamp(1, 4);
    for (var index = 0; index < pixelSideLadder.length; index += 1) {
      if (desiredPixelSide <= pixelSideLadder[index]) {
        return index;
      }
    }
    return pixelSideLadder.length - 1;
  }

  static Size targetSize({
    required Size intrinsicSize,
    required int bucket,
    required bool allowUpscaling,
  }) {
    final double width = intrinsicSize.width <= 0 ? 1 : intrinsicSize.width;
    final double height = intrinsicSize.height <= 0 ? 1 : intrinsicSize.height;
    final double sourceLongest = width > height ? width : height;
    final double bucketSide =
        pixelSideLadder[bucket.clamp(0, pixelSideLadder.length - 1)].toDouble();
    final double targetLongest = allowUpscaling
        ? bucketSide
        : bucketSide.clamp(1, sourceLongest);
    final double scale = targetLongest / sourceLongest;
    return Size(
      (width * scale).round().clamp(1, maxPixelSide).toDouble(),
      (height * scale).round().clamp(1, maxPixelSide).toDouble(),
    );
  }
}

class DecodedImageRaster {
  const DecodedImageRaster({
    required this.image,
    required this.intrinsicSize,
    required this.scaleBucket,
  });

  final ui.Image image;
  final Size intrinsicSize;
  final int scaleBucket;
}

/// Decodes a durable image source directly from its encoded file buffer.
abstract final class ImageRasterDecoder {
  static Future<DecodedImageRaster?> decodeFile(
    String path, {
    required int scaleBucket,
  }) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      buffer = await ui.ImmutableBuffer.fromFilePath(path);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final Size intrinsicSize = Size(
        descriptor.width.toDouble(),
        descriptor.height.toDouble(),
      );
      final Size target = RasterScalePolicy.targetSize(
        intrinsicSize: intrinsicSize,
        bucket: scaleBucket,
        allowUpscaling: false,
      );
      codec = await descriptor.instantiateCodec(
        targetWidth: target.width.round(),
        targetHeight: target.height.round(),
      );
      final ui.FrameInfo frame = await codec.getNextFrame();
      return DecodedImageRaster(
        image: frame.image,
        intrinsicSize: intrinsicSize,
        scaleBucket: scaleBucket,
      );
    } on Object {
      return null;
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }
}
