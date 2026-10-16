import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late MediaSandboxService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('media_sandbox_test_');
    service = MediaSandboxService(
      baseDirProvider: () async => tempDir,
      compressor: (sourcePath, targetPath, {minWidth = 1600, minHeight = 1600, quality = 80}) async {
        // Fast mock compressor copying file to target for headless test
        final src = File(sourcePath);
        return src.copy(targetPath);
      },
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MediaSandboxService Tests', () {
    test('copyAndCompressImage generates relative path with media/{uuid}.webp format', () async {
      // Create dummy source image
      final sourceFile = File(p.join(tempDir.path, 'source_photo.png'));
      await sourceFile.writeAsString('test image content binary simulation');

      final relativePath = await service.copyAndCompressImage(sourceFile);

      // Verify strictly relative path format
      expect(MediaSandboxService.isStrictlyRelative(relativePath), isTrue);
      expect(relativePath.startsWith('media/'), isTrue);
      expect(relativePath.endsWith('.webp'), isTrue);

      // Verify UUID pattern inside path
      final filename = p.basename(relativePath);
      expect(
        RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\.webp$')
            .hasMatch(filename),
        isTrue,
      );

      // Verify target file actually exists in sandbox
      final targetFile = await service.getFileFromRelativePath(relativePath);
      expect(await targetFile.exists(), isTrue);
      expect(await targetFile.readAsString(), 'test image content binary simulation');
    });

    test('isStrictlyRelative rejects absolute paths', () {
      expect(MediaSandboxService.isStrictlyRelative('/storage/emulated/0/DCIM/photo.jpg'), isFalse);
      expect(MediaSandboxService.isStrictlyRelative('/var/mobile/Containers/Data/photo.jpg'), isFalse);
      expect(MediaSandboxService.isStrictlyRelative(r'C:\Users\User\Pictures\photo.jpg'), isFalse);
      expect(MediaSandboxService.isStrictlyRelative('media/550e8400-e29b-41d4-a716-446655440000.webp'), isTrue);
    });

    test('deleteMedia removes sandboxed file from disk', () async {
      final sourceFile = File(p.join(tempDir.path, 'source_photo2.png'));
      await sourceFile.writeAsString('content to delete');

      final relativePath = await service.copyAndCompressImage(sourceFile);
      final file = await service.getFileFromRelativePath(relativePath);
      expect(await file.exists(), isTrue);

      final deleted = await service.deleteMedia(relativePath);
      expect(deleted, isTrue);
      expect(await file.exists(), isFalse);

      // Calling delete again returns false
      final deletedAgain = await service.deleteMedia(relativePath);
      expect(deletedAgain, isFalse);
    });

    test('copyAndCompressImage throws exception if source does not exist', () async {
      final nonExistent = File(p.join(tempDir.path, 'ghost.jpg'));
      expect(
        () => service.copyAndCompressImage(nonExistent),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}

