import 'dart:io';
import 'dart:typed_data';

/// Pure-Dart reader extracting EXIF capture timestamps (`DateTimeOriginal` `0x9003`,
/// `DateTimeDigitized` `0x9004`, or `DateTime` `0x0132`) from JPEG APP1/TIFF headers.
///
/// Designed for $0 FOSS offline execution with zero native dependencies:
/// - Reads at most the first 128 KB of a source file before WebP compression strips EXIF.
/// - Supports both Little-Endian (`II`, `0x4949`) and Big-Endian (`MM`, `0x4D4D`) TIFF headers.
/// - Never throws on non-JPEG, truncated, or malformed inputs (returns `null`).
class ExifDateReader {
  static const int _maxHeaderBytes = 131072; // 128 KB

  static const int _tagDateTime = 0x0132;
  static const int _tagExifIfdPointer = 0x8769;
  static const int _tagDateTimeOriginal = 0x9003;
  static const int _tagDateTimeDigitized = 0x9004;

  const ExifDateReader._();

  /// Reads the EXIF capture timestamp from [source], or returns `null` if unavailable.
  static Future<DateTime?> readCaptureDate(File source) async {
    try {
      if (!source.existsSync()) return null;
      final raf = source.openSync(mode: FileMode.read);
      try {
        final length = raf.lengthSync();
        final bytesToRead =
            length < _maxHeaderBytes ? length : _maxHeaderBytes;
        final bytes = raf.readSync(bytesToRead);
        return readCaptureDateFromBytes(bytes);
      } finally {
        raf.closeSync();
      }
    } catch (_) {
      return null;
    }
  }

  /// Parses the EXIF capture timestamp from raw file [bytes], or returns `null`.
  static DateTime? readCaptureDateFromBytes(Uint8List bytes) {
    try {
      if (bytes.length < 14) return null;
      // Verify JPEG SOI marker (0xFF, 0xD8)
      if (bytes[0] != 0xFF || bytes[1] != 0xD8) return null;

      var offset = 2;
      while (offset + 4 <= bytes.length) {
        if (bytes[offset] != 0xFF) return null;
        var marker = bytes[offset + 1];
        // Skip padding 0xFF bytes
        while (marker == 0xFF && offset + 2 < bytes.length) {
          offset++;
          marker = bytes[offset + 1];
        }

        // SOS (0xDA) or EOI (0xD9) ends metadata segments
        if (marker == 0xDA || marker == 0xD9) break;

        if (offset + 4 > bytes.length) break;
        final segmentLength = (bytes[offset + 2] << 8) | bytes[offset + 3];
        if (segmentLength < 2 || offset + 2 + segmentLength > bytes.length) {
          break;
        }

        // APP1 marker (0xE1) with "Exif\x00\x00" signature
        if (marker == 0xE1 && segmentLength >= 8) {
          final sigStart = offset + 4;
          if (sigStart + 6 <= bytes.length &&
              bytes[sigStart] == 0x45 && // 'E'
              bytes[sigStart + 1] == 0x78 && // 'x'
              bytes[sigStart + 2] == 0x69 && // 'i'
              bytes[sigStart + 3] == 0x66 && // 'f'
              bytes[sigStart + 4] == 0x00 &&
              bytes[sigStart + 5] == 0x00) {
            final tiffStart = sigStart + 6;
            final tiffLength = segmentLength - 8;
            if (tiffStart + tiffLength <= bytes.length) {
              final tiffView = Uint8List.sublistView(
                bytes,
                tiffStart,
                tiffStart + tiffLength,
              );
              final parsed = _parseTiff(tiffView);
              if (parsed != null) return parsed;
            }
          }
        }

        offset += 2 + segmentLength;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static DateTime? _parseTiff(Uint8List tiff) {
    if (tiff.length < 8) return null;
    final byte0 = tiff[0];
    final byte1 = tiff[1];
    final Endian endian;
    if (byte0 == 0x49 && byte1 == 0x49) {
      endian = Endian.little;
    } else if (byte0 == 0x4D && byte1 == 0x4D) {
      endian = Endian.big;
    } else {
      return null;
    }

    final data = ByteData.sublistView(tiff);
    final magic = data.getUint16(2, endian);
    if (magic != 0x002A) return null;

    final ifd0Offset = data.getUint32(4, endian);
    String? dateTime0;
    String? dateTimeOriginal;
    String? dateTimeDigitized;
    int? exifIfdOffset;

    void scanIfd(int ifdOffset, {required bool isSubIfd}) {
      if (ifdOffset < 0 || ifdOffset + 2 > tiff.length) return;
      final entryCount = data.getUint16(ifdOffset, endian);
      var cursor = ifdOffset + 2;

      for (var index = 0; index < entryCount; index++) {
        if (cursor + 12 > tiff.length) break;
        final tag = data.getUint16(cursor, endian);
        final fieldType = data.getUint16(cursor + 2, endian);
        final count = data.getUint32(cursor + 4, endian);

        if (!isSubIfd && tag == _tagExifIfdPointer && count == 1) {
          // LONG (4) or SHORT (3)
          if (fieldType == 4) {
            exifIfdOffset = data.getUint32(cursor + 8, endian);
          } else if (fieldType == 3) {
            exifIfdOffset = data.getUint16(cursor + 8, endian);
          }
        } else if (fieldType == 2 &&
            (tag == _tagDateTime ||
                tag == _tagDateTimeOriginal ||
                tag == _tagDateTimeDigitized)) {
          // ASCII string (type = 2)
          final valueOffset =
              count <= 4 ? (cursor + 8) : data.getUint32(cursor + 8, endian);
          if (valueOffset >= 0 &&
              count > 0 &&
              valueOffset + count <= tiff.length) {
            final rawBytes = tiff.sublist(
              valueOffset,
              valueOffset + count,
            );
            final nonNullBytes =
                rawBytes.takeWhile((byte) => byte != 0).toList();
            final str = String.fromCharCodes(nonNullBytes).trim();
            if (tag == _tagDateTimeOriginal) {
              dateTimeOriginal = str;
            } else if (tag == _tagDateTimeDigitized) {
              dateTimeDigitized = str;
            } else if (tag == _tagDateTime) {
              dateTime0 = str;
            }
          }
        }
        cursor += 12;
      }
    }

    scanIfd(ifd0Offset, isSubIfd: false);
    if (exifIfdOffset != null) {
      scanIfd(exifIfdOffset!, isSubIfd: true);
    }

    final candidate = dateTimeOriginal ?? dateTimeDigitized ?? dateTime0;
    if (candidate == null) return null;
    return parseExifDateString(candidate);
  }

  /// Parses standard EXIF date string `"YYYY:MM:DD HH:MM:SS"` into a local [DateTime].
  static DateTime? parseExifDateString(String raw) {
    final match = RegExp(
      r'^(\d{4})[:\-](\d{2})[:\-](\d{2})\s+(\d{2}):(\d{2}):(\d{2})',
    ).firstMatch(raw.trim());
    if (match == null) return null;

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    final hour = int.tryParse(match.group(4)!);
    final minute = int.tryParse(match.group(5)!);
    final second = int.tryParse(match.group(6)!);

    if (year == null ||
        month == null ||
        day == null ||
        hour == null ||
        minute == null ||
        second == null) {
      return null;
    }
    if (year < 1970 || month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    return DateTime(year, month, day, hour, minute, second);
  }
}

