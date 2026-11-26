import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/import_export/services/image_format_transcoder.dart';
import 'package:memodiary/features/import_export/services/pdf_sandboxed_image_loader.dart';

void main() {
  group('PdfSandboxedImageLoader Tests', () {
    late Directory tempDir;
    late MediaSandboxService mediaService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pdf_loader_test_');
      mediaService = MediaSandboxService(
        baseDirProvider: () async => tempDir,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('rejects empty, absolute, traversal, and remote URL paths', () async {
      const invalidPaths = [
        '',
        '   ',
        '/etc/passwd',
        '../secret.png',
        'photos/../../secret.png',
        'http://example.com/image.png',
        'https://example.com/image.png',
      ];

      for (final path in invalidPaths) {
        final image = await PdfSandboxedImageLoader.load(
          relativePath: path,
          mediaService: mediaService,
        );
        expect(image, isNull, reason: 'Expected null for unsafe path: "$path"');
      }
    });

    test('returns null when file is missing or empty', () async {
      final missing = await PdfSandboxedImageLoader.load(
        relativePath: 'missing.png',
        mediaService: mediaService,
      );
      expect(missing, isNull);

      final emptyFile = File('${tempDir.path}/empty.png');
      await emptyFile.writeAsBytes(const <int>[]);
      final emptyResult = await PdfSandboxedImageLoader.load(
        relativePath: 'empty.png',
        mediaService: mediaService,
      );
      expect(emptyResult, isNull);
    });

    test('loads valid sandboxed PNG and invokes customTranscoder for non-native bytes', () async {
      final pngFile = File('${tempDir.path}/sample.png');
      await pngFile.writeAsBytes(ImageFormatTranscoder.transparent1x1Png);

      final pngImage = await PdfSandboxedImageLoader.load(
        relativePath: '  sample.png  ',
        mediaService: mediaService,
      );
      expect(pngImage, isNotNull);
      expect(pngImage!.bytes, equals(ImageFormatTranscoder.transparent1x1Png));

      final fakeWebp = File('${tempDir.path}/sample.webp');
      await fakeWebp.writeAsBytes(Uint8List.fromList(const [
        0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50,
      ]));

      var transcoderCalled = false;
      final transcodedImage = await PdfSandboxedImageLoader.load(
        relativePath: 'sample.webp',
        mediaService: mediaService,
        customTranscoder: (_) async {
          transcoderCalled = true;
          return ImageFormatTranscoder.transparent1x1Png;
        },
      );
      expect(transcoderCalled, isTrue);
      expect(transcodedImage, isNotNull);
      expect(transcodedImage!.bytes, equals(ImageFormatTranscoder.transparent1x1Png));
    });
  });
}
