import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/import_export/services/image_format_transcoder.dart';

void main() {
  group('ImageFormatTranscoder Tests', () {
    test('isPdfNativeFormat recognizes JPEG and PNG signatures', () {
      final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x00, 0x00]);
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
      final randomBytes = Uint8List.fromList([0x00, 0x11, 0x22, 0x33]);

      expect(ImageFormatTranscoder.isPdfNativeFormat(pngBytes), isTrue);
      expect(ImageFormatTranscoder.isPdfNativeFormat(jpegBytes), isTrue);
      expect(ImageFormatTranscoder.isPdfNativeFormat(randomBytes), isFalse);
    });

    test('isWebp recognizes RIFF WEBP signature', () {
      final webpBytes = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, // RIFF
        0x00, 0x00, 0x00, 0x00,
        0x57, 0x45, 0x42, 0x50, // WEBP
      ]);
      final nonWebpBytes = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, // RIFF
        0x00, 0x00, 0x00, 0x00,
        0x41, 0x56, 0x49, 0x20, // AVI
      ]);

      expect(ImageFormatTranscoder.isWebp(webpBytes), isTrue);
      expect(ImageFormatTranscoder.isWebp(nonWebpBytes), isFalse);
    });

    test('ensurePdfCompatibleBytes passes through PNG bytes without alteration', () async {
      final png = ImageFormatTranscoder.transparent1x1Png;
      final result = await ImageFormatTranscoder.ensurePdfCompatibleBytes(png);

      expect(result, equals(png));
      expect(ImageFormatTranscoder.isPdfNativeFormat(result), isTrue);
    });

    test('ensurePdfCompatibleBytes converts unknown or WebP format via transcoder', () async {
      final fakeWebp = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46,
        0x00, 0x00, 0x00, 0x00,
        0x57, 0x45, 0x42, 0x50,
      ]);

      // Custom transcoder callback invoked for non-native format
      final converted = await ImageFormatTranscoder.ensurePdfCompatibleBytes(
        fakeWebp,
        customTranscoder: (bytes) async => ImageFormatTranscoder.transparent1x1Png,
      );

      expect(ImageFormatTranscoder.isPdfNativeFormat(converted), isTrue);
    });
  });
}

