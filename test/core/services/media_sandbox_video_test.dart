import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MediaSandboxService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('media_video_test_');
    service = MediaSandboxService(
      baseDirProvider: () async => tempDir,
      durationExtractor: (videoFile) async {
        // Fast mock extractor returning 30 seconds for normal test videos
        if (videoFile.path.contains('too_long')) {
          return const Duration(seconds: 75);
        }
        return const Duration(seconds: 30);
      },
      thumbnailGenerator: (videoFile, targetThumbnailPath, {durationSeconds}) async {
        // Mock thumbnail generator creating a mock poster file
        final thumbFile = File(targetThumbnailPath);
        await thumbFile.parent.create(recursive: true);
        await thumbFile.writeAsString('mock_poster_bytes');
        return thumbFile;
      },
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MediaSandboxService Video Tests', () {
    test('copyAndSandboxVideo copies video to media/{uuid}.mp4 and generates thumbnail', () async {
      final sourceFile = File(p.join(tempDir.path, 'source_video.mp4'));
      await sourceFile.writeAsString('dummy mp4 binary content');

      final result = await service.copyAndSandboxVideo(sourceFile);

      // Verify relative paths
      expect(MediaSandboxService.isStrictlyRelative(result.relativePath), isTrue);
      expect(result.relativePath.startsWith('media/'), isTrue);
      expect(result.relativePath.endsWith('.mp4'), isTrue);

      expect(MediaSandboxService.isStrictlyRelative(result.thumbnailPath), isTrue);
      expect(result.thumbnailPath.startsWith('media/'), isTrue);
      expect(result.thumbnailPath.endsWith('_thumb.webp'), isTrue);

      expect(result.durationSeconds, equals(30));

      // Verify files actually exist in sandbox
      final videoFile = await service.getFileFromRelativePath(result.relativePath);
      expect(await videoFile.exists(), isTrue);
      expect(await videoFile.readAsString(), 'dummy mp4 binary content');

      final thumbFile = await service.getFileFromRelativePath(result.thumbnailPath);
      expect(await thumbFile.exists(), isTrue);
    });

    test('copyAndSandboxVideo rejects videos exceeding 60s with VideoDurationExceededException', () async {
      final longVideoFile = File(p.join(tempDir.path, 'source_too_long_video.mp4'));
      await longVideoFile.writeAsString('long video content');

      expect(
        () => service.copyAndSandboxVideo(longVideoFile),
        throwsA(isA<VideoDurationExceededException>().having(
          (e) => e.durationSeconds,
          'durationSeconds',
          equals(75),
        )),
      );
    });

    test('generateProceduralVideoPoster produces non-empty poster image bytes', () async {
      final targetThumb = p.join(tempDir.path, 'media', 'procedural_thumb.webp');
      final resultFile = await MediaSandboxService.generateProceduralVideoPoster(
        targetThumbnailPath: targetThumb,
        durationSeconds: 45,
      );

      expect(await resultFile.exists(), isTrue);
      final bytes = await resultFile.readAsBytes();
      expect(bytes, isNotEmpty);
      // Valid PNG bytes start with \x89PNG
      expect(bytes[0], equals(0x89));
      expect(bytes[1], equals(0x50));
      expect(bytes[2], equals(0x4E));
      expect(bytes[3], equals(0x47));
    });
  });
}

