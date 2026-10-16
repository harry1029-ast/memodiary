import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/settings/services/storage_optimizer_service.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late MediaSandboxService mediaService;

  setUp(() async {
    db = AppDatabase.memory();
    tempDir = await Directory.systemTemp.createTemp('storage_optimizer_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
      compressor: (src, dst, {minWidth = 1600, minHeight = 1600, quality = 80}) async {
        final dstFile = File(dst);
        await dstFile.parent.create(recursive: true);
        return File(src).copy(dst);
      },
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('StorageOptimizerService Tests', () {
    test('analyzeStorage and purgeOrphanMedia accurately identify and clean orphan files', () async {
      final now = DateTime.now();

      // 1. Create an active entry
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'active_entry_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Active Diary'),
          contentDelta: jsonEncode([{'insert': 'Hello\n'}]),
          plainText: 'Hello',
          entryDate: now,
        ),
      );

      // 2. Create referenced media file in sandbox
      final activeImg = File('${tempDir.path}/active.jpg');
      await activeImg.writeAsString('referenced-image-data');
      final activeRelPath = await mediaService.copyAndCompressImage(activeImg);

      await db.attachMediaToEntry(
        id: 'media_active_1',
        entryId: 'active_entry_1',
        relativePath: activeRelPath,
      );

      // 3. Create unreferenced (orphan) file in sandbox media directory
      final mediaDir = Directory('${tempDir.path}/media');
      await mediaDir.create(recursive: true);
      final orphanFile = File('${mediaDir.path}/orphan_discarded_photo.webp');
      await orphanFile.writeAsString('orphan-unreferenced-image-data');

      // 4. Analyze storage metrics
      final stats = await StorageOptimizerService.analyzeStorage(
        database: db,
        mediaService: mediaService,
      );

      expect(stats.activeEntriesCount, equals(1));
      expect(stats.totalMediaFiles, equals(2)); // 1 referenced + 1 orphan
      expect(stats.orphanMediaFiles, equals(1));
      expect(stats.orphanMediaBytes, greaterThan(0));

      // 5. Purge orphan media
      final purgedCount = await StorageOptimizerService.purgeOrphanMedia(
        database: db,
        mediaService: mediaService,
      );

      expect(purgedCount, equals(1));

      // 6. Verify orphan file is gone from disk
      expect(await orphanFile.exists(), isFalse);

      // 7. Verify referenced file is still intact on disk
      final activeFile = await mediaService.getFileFromRelativePath(activeRelPath);
      expect(await activeFile.exists(), isTrue);

      // Re-run analysis to verify clean state
      final cleanStats = await StorageOptimizerService.analyzeStorage(
        database: db,
        mediaService: mediaService,
      );
      expect(cleanStats.orphanMediaFiles, equals(0));
      expect(cleanStats.orphanMediaBytes, equals(0));
    });
  });
}

