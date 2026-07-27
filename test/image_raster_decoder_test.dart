import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/canvas/raster/image_raster_decoder.dart';

void main() {
  test('raster buckets include element size, zoom, and device pixels', () {
    const ui.Rect bounds = ui.Rect.fromLTWH(0, 0, 400, 200);

    expect(
      RasterScalePolicy.bucketForElement(
        worldBounds: bounds,
        viewportScale: 1,
        devicePixelRatio: 1,
      ),
      0,
    );
    expect(
      RasterScalePolicy.bucketForElement(
        worldBounds: bounds,
        viewportScale: 1,
        devicePixelRatio: 3,
      ),
      2,
    );
    expect(
      RasterScalePolicy.bucketForElement(
        worldBounds: bounds,
        viewportScale: 20,
        devicePixelRatio: 3,
      ),
      RasterScalePolicy.pixelSideLadder.length - 1,
    );
  });

  test('target dimensions preserve aspect ratio and obey the side cap', () {
    expect(
      RasterScalePolicy.targetSize(
        intrinsicSize: const ui.Size(8000, 4000),
        bucket: RasterScalePolicy.pixelSideLadder.length - 1,
        allowUpscaling: false,
      ),
      const ui.Size(4096, 2048),
    );
    expect(
      RasterScalePolicy.targetSize(
        intrinsicSize: const ui.Size(100, 50),
        bucket: RasterScalePolicy.pixelSideLadder.length - 1,
        allowUpscaling: false,
      ),
      const ui.Size(100, 50),
    );
  });

  test('file decode is bounded without modifying its durable source', () async {
    final Directory directory = await Directory.systemTemp.createTemp(
      'zenno-raster-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final File source = File('${directory.path}/source.png');
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawColor(const ui.Color(0xFF336699), ui.BlendMode.src);
    final ui.Picture picture = recorder.endRecording();
    final ui.Image original = await picture.toImage(1024, 512);
    picture.dispose();
    final ByteData data = (await original.toByteData(
      format: ui.ImageByteFormat.png,
    ))!;
    original.dispose();
    await source.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    final int sourceLength = await source.length();

    final DecodedImageRaster? decoded = await ImageRasterDecoder.decodeFile(
      source.path,
      scaleBucket: 0,
    );
    if (decoded != null) {
      addTearDown(decoded.image.dispose);
    }

    expect(decoded, isNotNull);
    expect(decoded!.intrinsicSize, const ui.Size(1024, 512));
    expect(decoded.image.width, 512);
    expect(decoded.image.height, 256);
    expect(await source.exists(), isTrue);
    expect(await source.length(), sourceLength);
  });
}
