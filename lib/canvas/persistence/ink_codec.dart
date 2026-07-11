import 'dart:typed_data';

import 'package:zenno/canvas/model/stroke.dart';

/// Packs a [StrokePoint] list to a compact [Uint8List] and back.
///
/// This is the codec for the `ink_strokes.points` BLOB — the only BLOB in the
/// Zenno schema. A stroke's centerline can run to thousands of samples, so it
/// is stored as a tightly packed binary buffer rather than as JSON or as
/// per-point rows: one tightly-packed little-endian point payload behind a
/// short header.
///
/// ## Wire format
///
/// ```text
/// byte 0        format version (currently 3)
/// bytes 1..3    zero padding — aligns the numeric payload
/// bytes 4..     repeated point records
/// ```
///
/// Version 1 point records are three `float32`s: x, y, pressure. Version 2
/// records keep those fields and add tiltX, tiltY, azimuth, timestampMicros
/// and cached velocity. Version 3 writes coordinates and velocity as
/// `float64`s so tiny deep-zoom writing survives persistence. The decoder keeps
/// v1/v2 support forever so old notes do not need to be rewritten.
///
/// Coordinates are world-space `double`s and v3 preserves them as `float64`.
abstract final class InkCodec {
  /// Current BLOB format version, written as byte 0 of every encoded buffer.
  static const int formatVersion = 3;

  static const int legacyFormatVersion = 1;
  static const int v2FormatVersion = 2;

  /// Size in bytes of the leading header (version byte + 3 padding bytes).
  static const int headerBytes = 4;

  static const int legacyFloatsPerPoint = 3;

  static const int legacyPointBytes = legacyFloatsPerPoint * 4;

  static const int v2PointBytes = 36;

  /// Size in bytes of the current v3 point record.
  static const int pointBytes = 48;

  /// Encodes [points] to the packed `ink_strokes.points` BLOB representation.
  ///
  /// The result is a fresh [Uint8List] containing the 4-byte header followed by
  /// the little-endian v3 point payload.
  /// An empty [points] list yields a 4-byte header-only buffer.
  static Uint8List encodePoints(List<StrokePoint> points) {
    final ByteData data = ByteData(headerBytes + points.length * pointBytes);
    data.setUint8(0, formatVersion);
    // Bytes 1..3 are left at their zero-initialised value (alignment padding).
    var offset = headerBytes;
    for (final StrokePoint p in points) {
      data.setFloat64(offset, p.x, Endian.little);
      data.setFloat64(offset + 8, p.y, Endian.little);
      data.setFloat32(offset + 16, p.pressure, Endian.little);
      data.setFloat32(offset + 20, p.tiltX, Endian.little);
      data.setFloat32(offset + 24, p.tiltY, Endian.little);
      data.setFloat32(offset + 28, p.azimuth, Endian.little);
      data.setFloat64(offset + 32, p.timestampMicros.toDouble(), Endian.little);
      data.setFloat64(offset + 40, p.velocity, Endian.little);
      offset += pointBytes;
    }
    return data.buffer.asUint8List();
  }

  /// Decodes a packed `ink_strokes.points` [blob] back into [StrokePoint]s.
  ///
  /// Throws a [FormatException] when [blob] is too short to hold the header,
  /// when its version byte is not [formatVersion], or when the payload length
  /// is not a whole number of points.
  static List<StrokePoint> decodePoints(Uint8List blob) {
    if (blob.length < headerBytes) {
      throw FormatException(
        'Ink BLOB too short: ${blob.length} bytes (need at least '
        '$headerBytes for the header).',
      );
    }
    final ByteData data = ByteData.sublistView(blob);
    final int version = data.getUint8(0);
    if (version == legacyFormatVersion) {
      return _decodeV1(data, blob.length);
    }
    if (version == v2FormatVersion) {
      return _decodeV2(data, blob.length);
    }
    if (version != formatVersion) {
      throw FormatException(
        'Unsupported ink BLOB format version $version '
        '(this build writes/reads version $formatVersion).',
      );
    }
    final int payloadBytes = blob.length - headerBytes;
    if (payloadBytes % pointBytes != 0) {
      throw FormatException(
        'Ink BLOB payload of $payloadBytes bytes is not a whole number of '
        '$pointBytes-byte points.',
      );
    }
    final int pointCount = payloadBytes ~/ pointBytes;
    final List<StrokePoint> points = <StrokePoint>[];
    var offset = headerBytes;
    for (var i = 0; i < pointCount; i++) {
      points.add(
        StrokePoint(
          data.getFloat64(offset, Endian.little),
          data.getFloat64(offset + 8, Endian.little),
          data.getFloat32(offset + 16, Endian.little),
          tiltX: data.getFloat32(offset + 20, Endian.little),
          tiltY: data.getFloat32(offset + 24, Endian.little),
          azimuth: data.getFloat32(offset + 28, Endian.little),
          timestampMicros: data.getFloat64(offset + 32, Endian.little).round(),
          velocity: data.getFloat64(offset + 40, Endian.little),
        ),
      );
      offset += pointBytes;
    }
    return points;
  }

  static List<StrokePoint> _decodeV2(ByteData data, int byteLength) {
    final int payloadBytes = byteLength - headerBytes;
    if (payloadBytes % v2PointBytes != 0) {
      throw FormatException(
        'Ink v2 BLOB payload of $payloadBytes bytes is not a whole number of '
        '$v2PointBytes-byte points.',
      );
    }
    final int pointCount = payloadBytes ~/ v2PointBytes;
    final List<StrokePoint> points = <StrokePoint>[];
    var offset = headerBytes;
    for (var i = 0; i < pointCount; i++) {
      points.add(
        StrokePoint(
          data.getFloat32(offset, Endian.little),
          data.getFloat32(offset + 4, Endian.little),
          data.getFloat32(offset + 8, Endian.little),
          tiltX: data.getFloat32(offset + 12, Endian.little),
          tiltY: data.getFloat32(offset + 16, Endian.little),
          azimuth: data.getFloat32(offset + 20, Endian.little),
          timestampMicros: data.getFloat64(offset + 24, Endian.little).round(),
          velocity: data.getFloat32(offset + 32, Endian.little),
        ),
      );
      offset += v2PointBytes;
    }
    return points;
  }

  static List<StrokePoint> _decodeV1(ByteData data, int byteLength) {
    final int payloadBytes = byteLength - headerBytes;
    if (payloadBytes % legacyPointBytes != 0) {
      throw FormatException(
        'Ink v1 BLOB payload of $payloadBytes bytes is not a whole number of '
        '$legacyPointBytes-byte points.',
      );
    }
    final int pointCount = payloadBytes ~/ legacyPointBytes;
    final List<StrokePoint> points = <StrokePoint>[];
    var offset = headerBytes;
    for (var i = 0; i < pointCount; i++) {
      points.add(
        StrokePoint(
          data.getFloat32(offset, Endian.little),
          data.getFloat32(offset + 4, Endian.little),
          data.getFloat32(offset + 8, Endian.little),
        ),
      );
      offset += legacyPointBytes;
    }
    return points;
  }
}
