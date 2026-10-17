import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/settings/services/storage_optimizer_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late MediaSandboxService mediaService;

  setUp(() async {
    db = AppDatabase.memory();
    tempDir = await Directory.systemTemp.createTemp('video_storage_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Video Storage Optimizer Tests', () {
    test('accurately accounts for .mp4 files and purges orphan videos and thumbnails', () async {
      final mediaDir = Directory(p.join(tempDir.path, 'media'))..createSync(recursive: true);

      // 1. Create an active entry
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'active_video_entry',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Active Video Entry'),
          contentDelta: jsonEncode([{'insert': 'Video diary\n'}]),
          plainText: 'Video diary',
          entryDate: DateTime.now(),
        ),
      );

      // 2. Create active sandboxed video and thumbnail
      final activeVideoFile = File(p.join(mediaDir.path, 'active_video.mp4'))
        ..writeAsBytesSync(List.filled(2000, 1));
      final activeThumbFile = File(p.join(mediaDir.path, 'active_video_thumb.webp'))
        ..writeAsBytesSync(List.filled(500, 2));

      await db.attachMediaToEntry(
        id: 'media_active_vid_1',
        entryId: 'active_video_entry',
        relativePath: 'media/active_video.mp4',
        thumbnailPath: 'media/active_video_thumb.webp',
        mediaType: 'video',
      );

      // 3. Create orphan video and orphan thumbnail (unreferenced)
      final orphanVideoFile = File(p.join(mediaDir.path, 'orphan_video.mp4'))
        ..writeAsBytesSync(List.filled(3000, 3));
      final orphanThumbFile = File(p.join(mediaDir.path, 'orphan_video_thumb.webp'))
        ..writeAsBytesSync(List.filled(600, 4));

      // 4. Analyze storage metrics
      final statsBefore = await StorageOptimizerService.analyzeStorage(
        database: db,
        mediaService: mediaService,
      );

      expect(statsBefore.activeEntriesCount, 1);
      expect(statsBefore.totalMediaFiles, 4); // active video + thumb + orphan video + thumb
      expect(statsBefore.totalMediaBytes, 2000 + 500 + 3000 + 600);
      expect(statsBefore.orphanMediaFiles, 2); // orphan video + orphan thumb
      expect(statsBefore.orphanMediaBytes, 3000 + 600);

      // 5. Purge orphan media files
      final purgedCount = await StorageOptimizerService.purgeOrphanMedia(
        database: db,
        mediaService: mediaService,
      );

      expect(purgedCount, 2);
      expect(orphanVideoFile.existsSync(), isFalse);
      expect(orphanThumbFile.existsSync(), isFalse);

      // Verify active media files were NOT deleted
      expect(activeVideoFile.existsSync(), isTrue);
      expect(activeThumbFile.existsSync(), isTrue);

      // 6. Post-purge storage analysis
      final statsAfter = await StorageOptimizerService.analyzeStorage(
        database: db,
        mediaService: mediaService,
      );

      expect(statsAfter.totalMediaFiles, 2);
      expect(statsAfter.totalMediaBytes, 2500);
      expect(statsAfter.orphanMediaFiles, 0);
      expect(statsAfter.orphanMediaBytes, 0);
    });
  });
}

