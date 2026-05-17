import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/persistence/ink_codec.dart';

/// `float32` keeps ~7 significant digits; coordinates written and read back
/// match only to that precision, so equality checks use this tolerance.
const double _f32Tolerance = 1e-3;

void _expectPointsClose(
  List<StrokePoint> actual,
  List<StrokePoint> expected,
) {
  expect(actual, hasLength(expected.length));
  for (var i = 0; i < expected.length; i++) {
    expect(actual[i].x, closeTo(expected[i].x, _f32Tolerance), reason: 'x[$i]');
    expect(actual[i].y, closeTo(expected[i].y, _f32Tolerance), reason: 'y[$i]');
    expect(
      actual[i].pressure,
      closeTo(expected[i].pressure, _f32Tolerance),
      reason: 'pressure[$i]',
    );
  }
}

void main() {
  group('InkCodec round-trip', () {
    test('encodes then decodes a multi-point stroke', () {
      final points = <StrokePoint>[
        const StrokePoint(12.5, -40.25, 0.0),
        const StrokePoint(13.0, -39.5, 0.5),
        const StrokePoint(900.125, 1024.75, 1.0),
        const StrokePoint(-1234.5, 56.0, 0.33),
      ];

      final Uint8List blob = InkCodec.encodePoints(points);
      final List<StrokePoint> decoded = InkCodec.decodePoints(blob);

      _expectPointsClose(decoded, points);
    });

    test('round-trips an empty stroke as a header-only buffer', () {
      final Uint8List blob = InkCodec.encodePoints(const <StrokePoint>[]);

      expect(blob, hasLength(InkCodec.headerBytes));
      expect(blob[0], InkCodec.formatVersion);
      expect(InkCodec.decodePoints(blob), isEmpty);
    });

    test('round-trips a single-point stroke', () {
      final points = <StrokePoint>[const StrokePoint(7.0, 8.0, 0.9)];

      final List<StrokePoint> decoded =
          InkCodec.decodePoints(InkCodec.encodePoints(points));

      _expectPointsClose(decoded, points);
    });
  });

  group('InkCodec wire format', () {
    test('writes the format-version byte first', () {
      final Uint8List blob = InkCodec.encodePoints(
        <StrokePoint>[const StrokePoint(1, 2, 0.5)],
      );

      expect(blob[0], InkCodec.formatVersion);
    });

    test('buffer length is header + 12 bytes per point', () {
      for (final int count in <int>[0, 1, 5, 100]) {
        final points = <StrokePoint>[
          for (var i = 0; i < count; i++)
            StrokePoint(i.toDouble(), i.toDouble(), 0.5),
        ];
        final Uint8List blob = InkCodec.encodePoints(points);
        expect(
          blob.length,
          InkCodec.headerBytes + count * InkCodec.floatsPerPoint * 4,
          reason: '$count points',
        );
      }
    });

    test('float payload begins on a 4-byte boundary', () {
      // The payload must be readable as a Float32List view, which requires the
      // offset (== headerBytes) to be a multiple of 4.
      expect(InkCodec.headerBytes % 4, 0);
    });
  });

  group('InkCodec error handling', () {
    test('rejects a buffer too short for the header', () {
      expect(
        () => InkCodec.decodePoints(Uint8List.fromList(const <int>[1, 0])),
        throwsFormatException,
      );
    });

    test('rejects an unknown format version', () {
      final Uint8List blob = InkCodec.encodePoints(
        <StrokePoint>[const StrokePoint(1, 2, 0.5)],
      );
      blob[0] = 99; // Corrupt the version byte.

      expect(() => InkCodec.decodePoints(blob), throwsFormatException);
    });

    test('rejects a payload that is not a whole number of points', () {
      // Header (4 bytes) + 7 bytes is not a multiple of the 12-byte point size.
      final Uint8List blob = Uint8List(InkCodec.headerBytes + 7)
        ..[0] = InkCodec.formatVersion;

      expect(() => InkCodec.decodePoints(blob), throwsFormatException);
    });
  });
}
