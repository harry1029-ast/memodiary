import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/albums/services/exif_date_reader.dart';

/// Builds a synthetic JPEG byte array containing an APP1 Exif segment with
/// configurable endianness, IFD0 `DateTime` (`0x0132`), and ExifSubIFD
/// `DateTimeOriginal` (`0x9003`).
Uint8List buildSyntheticExifJpeg({
  required Endian endian,
  String? dateTime0,
  String? dateTimeOriginal,
}) {
  // Layout inside TIFF buffer:
  // [0..7]   : TIFF header (8 bytes)
  // [8..49]  : IFD0 (2 bytes count + up to 2 entries * 12 bytes + 4 bytes nextIFD = 30 bytes)
  // [50..79] : IFD0 string value ("YYYY:MM:DD HH:MM:SS\x00" = 20 bytes)
  // [80..109]: ExifSubIFD (2 bytes count + 1 entry * 12 bytes + 4 bytes nextIFD = 18 bytes)
  // [110..139]: ExifSubIFD string value (20 bytes)
  final tiff = Uint8List(160);
  final data = ByteData.sublistView(tiff);

  if (endian == Endian.little) {
    tiff[0] = 0x49; // 'I'
    tiff[1] = 0x49; // 'I'
  } else {
    tiff[0] = 0x4D; // 'M'
    tiff[1] = 0x4D; // 'M'
  }
  data.setUint16(2, 0x002A, endian);
  data.setUint32(4, 8, endian); // IFD0 starts at offset 8

  var ifd0Count = 0;
  var cursor = 10;

  if (dateTime0 != null) {
    ifd0Count++;
    final strBytes = [...dateTime0.codeUnits, 0];
    tiff.setRange(50, 50 + strBytes.length, strBytes);
    data.setUint16(cursor, 0x0132, endian); // DateTime
    data.setUint16(cursor + 2, 2, endian); // ASCII
    data.setUint32(cursor + 4, strBytes.length, endian);
    data.setUint32(cursor + 8, 50, endian);
    cursor += 12;
  }

  if (dateTimeOriginal != null) {
    ifd0Count++;
    data.setUint16(cursor, 0x8769, endian); // ExifIFDPointer
    data.setUint16(cursor + 2, 4, endian); // LONG
    data.setUint32(cursor + 4, 1, endian);
    data.setUint32(cursor + 8, 80, endian); // SubIFD at offset 80
    cursor += 12;

    final origBytes = [...dateTimeOriginal.codeUnits, 0];
    tiff.setRange(110, 110 + origBytes.length, origBytes);
    data.setUint16(80, 1, endian); // 1 entry in ExifSubIFD
    data.setUint16(82, 0x9003, endian); // DateTimeOriginal
    data.setUint16(84, 2, endian); // ASCII
    data.setUint32(86, origBytes.length, endian);
    data.setUint32(90, 110, endian);
  }

  data.setUint16(8, ifd0Count, endian);

  final segmentLength = 2 + 6 + tiff.length;
  final out = BytesBuilder();
  out.add([0xFF, 0xD8]); // SOI
  out.add([0xFF, 0xE1]); // APP1
  out.add([(segmentLength >> 8) & 0xFF, segmentLength & 0xFF]);
  out.add([0x45, 0x78, 0x69, 0x66, 0x00, 0x00]); // "Exif\x00\x00"
  out.add(tiff);
  out.add([0xFF, 0xD9]); // EOI
  return out.toBytes();
}

void main() {
  group('ExifDateReader — Pure-Dart JPEG EXIF Capture Date Extraction', () {
    test('extracts DateTimeOriginal from Little-Endian (II) JPEG APP1 header', () {
      final jpeg = buildSyntheticExifJpeg(
        endian: Endian.little,
        dateTime0: '2026:04:01 10:00:00',
        dateTimeOriginal: '2026:03:28 16:45:12',
      );

      final parsed = ExifDateReader.readCaptureDateFromBytes(jpeg);
      expect(parsed, equals(DateTime(2026, 3, 28, 16, 45, 12)));
    });

    test('extracts DateTimeOriginal from Big-Endian (MM) JPEG APP1 header', () {
      final jpeg = buildSyntheticExifJpeg(
        endian: Endian.big,
        dateTimeOriginal: '2025:11:15 08:20:30',
      );

      final parsed = ExifDateReader.readCaptureDateFromBytes(jpeg);
      expect(parsed, equals(DateTime(2025, 11, 15, 8, 20, 30)));
    });

    test('falls back to IFD0 DateTime (0x0132) when DateTimeOriginal is absent', () {
      final jpeg = buildSyntheticExifJpeg(
        endian: Endian.little,
        dateTime0: '2024:07:09 19:05:00',
      );

      final parsed = ExifDateReader.readCaptureDateFromBytes(jpeg);
      expect(parsed, equals(DateTime(2024, 7, 9, 19, 5, 0)));
    });

    test('reads capture date from File on disk and returns null for non-JPEG or truncated files', () async {
      final dir = await Directory.systemTemp.createTemp('exif_reader_test_');
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });

      final jpegFile = File('${dir.path}/photo.jpg')
        ..writeAsBytesSync(
          buildSyntheticExifJpeg(
            endian: Endian.little,
            dateTimeOriginal: '2026:05:02 14:30:00',
          ),
        );
      expect(
        await ExifDateReader.readCaptureDate(jpegFile),
        equals(DateTime(2026, 5, 2, 14, 30, 0)),
      );

      final pngFile = File('${dir.path}/not_jpeg.png')
        ..writeAsBytesSync([0x89, 0x50, 0x4E, 0x47, 1, 2, 3, 4]);
      expect(await ExifDateReader.readCaptureDate(pngFile), isNull);

      final truncated = File('${dir.path}/truncated.jpg')
        ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE1, 0x00]);
      expect(await ExifDateReader.readCaptureDate(truncated), isNull);
    });
  });
}

