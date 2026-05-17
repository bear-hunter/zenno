import 'dart:typed_data';

import 'package:zenno/canvas/model/stroke.dart';

/// Packs a [StrokePoint] list to a compact [Uint8List] and back.
///
/// This is the codec for the `ink_strokes.points` BLOB — the only BLOB in the
/// Zenno schema. A stroke's centerline can run to thousands of samples, so it
/// is stored as a tightly packed binary buffer rather than as JSON or as
/// per-point rows: one `Float32List` of `[x, y, pressure, …]` triples behind a
/// short header.
///
/// ## Wire format
///
/// ```text
/// byte 0        format version (currently 1)
/// bytes 1..3    zero padding — aligns the float payload to a 4-byte boundary
/// bytes 4..     little-endian Float32 payload: x0,y0,p0, x1,y1,p1, …
/// ```
///
/// The 4-byte header is deliberate: a `Float32List.view` onto the BLOB needs
/// its byte offset to be a multiple of 4, so the version byte plus three
/// padding bytes let the payload be read as a typed-data view with no copy.
/// The payload length is always a multiple of `3 × 4 = 12` bytes; the point
/// count is therefore `(buffer.length − 4) ~/ 12` and is not stored in the
/// BLOB itself (the `ink_strokes.point_count` column holds it for queries).
///
/// Coordinates are world-space `double`s narrowed to `float32`. `float32` has
/// ~7 significant decimal digits, which comfortably covers on-canvas ink
/// geometry; the small precision loss is invisible at any sane zoom and halves
/// the stored size versus `float64`.
abstract final class InkCodec {
  /// Current BLOB format version, written as byte 0 of every encoded buffer.
  static const int formatVersion = 1;

  /// Size in bytes of the leading header (version byte + 3 padding bytes).
  static const int headerBytes = 4;

  /// Number of `float32` values stored per point: x, y, pressure.
  static const int floatsPerPoint = 3;

  /// Encodes [points] to the packed `ink_strokes.points` BLOB representation.
  ///
  /// The result is a fresh [Uint8List] of `headerBytes + points.length × 12`
  /// bytes — the 4-byte header followed by the little-endian `float32` payload.
  /// An empty [points] list yields a 4-byte header-only buffer.
  static Uint8List encodePoints(List<StrokePoint> points) {
    final ByteData data = ByteData(
      headerBytes + points.length * floatsPerPoint * 4,
    );
    data.setUint8(0, formatVersion);
    // Bytes 1..3 are left at their zero-initialised value (alignment padding).
    var offset = headerBytes;
    for (final StrokePoint p in points) {
      data.setFloat32(offset, p.x, Endian.little);
      data.setFloat32(offset + 4, p.y, Endian.little);
      data.setFloat32(offset + 8, p.pressure, Endian.little);
      offset += floatsPerPoint * 4;
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
    if (version != formatVersion) {
      throw FormatException(
        'Unsupported ink BLOB format version $version '
        '(this build writes/reads version $formatVersion).',
      );
    }
    final int payloadBytes = blob.length - headerBytes;
    const int pointBytes = floatsPerPoint * 4;
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
          data.getFloat32(offset, Endian.little),
          data.getFloat32(offset + 4, Endian.little),
          data.getFloat32(offset + 8, Endian.little),
        ),
      );
      offset += pointBytes;
    }
    return points;
  }
}
