import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenno/canvas/model/stroke.dart';
import 'package:zenno/canvas/persistence/ink_codec.dart';

const double _coordTolerance = 1e-10;
const double _f32Tolerance = 1e-6;

void _expectPointsClose(List<StrokePoint> actual, List<StrokePoint> expected) {
  expect(actual, hasLength(expected.length));
  for (var i = 0; i < expected.length; i++) {
    expect(
      actual[i].x,
      closeTo(expected[i].x, _coordTolerance),
      reason: 'x[$i]',
    );
    expect(
      actual[i].y,
      closeTo(expected[i].y, _coordTolerance),
      reason: 'y[$i]',
    );
    expect(
      actual[i].pressure,
      closeTo(expected[i].pressure, _f32Tolerance),
      reason: 'pressure[$i]',
    );
    expect(
      actual[i].tiltX,
      closeTo(expected[i].tiltX, _f32Tolerance),
      reason: 'tiltX[$i]',
    );
    expect(
      actual[i].tiltY,
      closeTo(expected[i].tiltY, _f32Tolerance),
      reason: 'tiltY[$i]',
    );
    expect(
      actual[i].azimuth,
      closeTo(expected[i].azimuth, _f32Tolerance),
      reason: 'azimuth[$i]',
    );
    expect(
      actual[i].timestampMicros,
      expected[i].timestampMicros,
      reason: 'timestampMicros[$i]',
    );
    expect(
      actual[i].velocity,
      closeTo(expected[i].velocity, _f32Tolerance),
      reason: 'velocity[$i]',
    );
  }
}

void main() {
  group('InkCodec round-trip', () {
    test('encodes then decodes a multi-point stroke', () {
      final points = <StrokePoint>[
        const StrokePoint(
          123456789.123456,
          -98765432.654321,
          0.0,
          tiltX: 0.1,
          tiltY: 0.2,
          azimuth: 0.3,
          timestampMicros: 123456789,
          velocity: 12,
        ),
        const StrokePoint(
          13.0,
          -39.5,
          0.5,
          tiltX: 0.4,
          tiltY: 0.5,
          azimuth: 0.6,
          timestampMicros: 123456999,
          velocity: 20,
        ),
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

      final List<StrokePoint> decoded = InkCodec.decodePoints(
        InkCodec.encodePoints(points),
      );

      _expectPointsClose(decoded, points);
    });
  });

  group('InkCodec wire format', () {
    test('writes the format-version byte first', () {
      final Uint8List blob = InkCodec.encodePoints(<StrokePoint>[
        const StrokePoint(1, 2, 0.5),
      ]);

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
          InkCodec.headerBytes + count * InkCodec.pointBytes,
          reason: '$count points',
        );
      }
    });

    test('decodes legacy v1 buffers with metadata defaults', () {
      final ByteData data = ByteData(
        InkCodec.headerBytes + 2 * InkCodec.legacyPointBytes,
      )..setUint8(0, InkCodec.legacyFormatVersion);
      data
        ..setFloat32(InkCodec.headerBytes, 1, Endian.little)
        ..setFloat32(InkCodec.headerBytes + 4, 2, Endian.little)
        ..setFloat32(InkCodec.headerBytes + 8, 0.5, Endian.little)
        ..setFloat32(
          InkCodec.headerBytes + InkCodec.legacyPointBytes,
          3,
          Endian.little,
        )
        ..setFloat32(
          InkCodec.headerBytes + InkCodec.legacyPointBytes + 4,
          4,
          Endian.little,
        )
        ..setFloat32(
          InkCodec.headerBytes + InkCodec.legacyPointBytes + 8,
          0.75,
          Endian.little,
        );

      final decoded = InkCodec.decodePoints(data.buffer.asUint8List());

      _expectPointsClose(decoded, const <StrokePoint>[
        StrokePoint(1, 2, 0.5),
        StrokePoint(3, 4, 0.75),
      ]);
      expect(decoded.every((point) => point.timestampMicros == 0), isTrue);
      expect(decoded.every((point) => point.velocity == 0), isTrue);
    });

    test('decodes legacy v2 buffers with stylus metadata', () {
      final ByteData data = ByteData(
        InkCodec.headerBytes + InkCodec.v2PointBytes,
      )..setUint8(0, InkCodec.v2FormatVersion);
      data
        ..setFloat32(InkCodec.headerBytes, 1.25, Endian.little)
        ..setFloat32(InkCodec.headerBytes + 4, 2.5, Endian.little)
        ..setFloat32(InkCodec.headerBytes + 8, 0.5, Endian.little)
        ..setFloat32(InkCodec.headerBytes + 12, 0.1, Endian.little)
        ..setFloat32(InkCodec.headerBytes + 16, 0.2, Endian.little)
        ..setFloat32(InkCodec.headerBytes + 20, 0.3, Endian.little)
        ..setFloat64(InkCodec.headerBytes + 24, 42000, Endian.little)
        ..setFloat32(InkCodec.headerBytes + 32, 12.5, Endian.little);

      final decoded = InkCodec.decodePoints(data.buffer.asUint8List());

      _expectPointsClose(decoded, const <StrokePoint>[
        StrokePoint(
          1.25,
          2.5,
          0.5,
          tiltX: 0.1,
          tiltY: 0.2,
          azimuth: 0.3,
          timestampMicros: 42000,
          velocity: 12.5,
        ),
      ]);
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
      final Uint8List blob = InkCodec.encodePoints(<StrokePoint>[
        const StrokePoint(1, 2, 0.5),
      ]);
      blob[0] = 99; // Corrupt the version byte.

      expect(() => InkCodec.decodePoints(blob), throwsFormatException);
    });

    test('rejects a payload that is not a whole number of points', () {
      // Header (4 bytes) + 7 bytes is not a multiple of the point record size.
      final Uint8List blob = Uint8List(InkCodec.headerBytes + 7)
        ..[0] = InkCodec.formatVersion;

      expect(() => InkCodec.decodePoints(blob), throwsFormatException);
    });
  });
}
