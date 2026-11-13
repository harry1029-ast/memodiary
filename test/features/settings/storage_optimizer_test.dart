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
      await db.entriesDao.createEntry(
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

      await db.mediaOcrDao.attachMediaToEntry(
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

    test(
      'preserves media_attachments, trashed attachments, album_photos, album_collections covers, and dotfiles while purging true orphans',
      () async {
        final now = DateTime.now();
        final mediaDir = Directory(p.join(tempDir.path, 'media'))
          ..createSync(recursive: true);

        File createMediaFile(String fileName, int byteCount) {
          final file = File(p.join(mediaDir.path, fileName))
            ..writeAsBytesSync(List.filled(byteCount, 7));
          return file;
        }

        // 1. Active diary entry with image + video + poster thumbnail
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'entry_active_refs',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Active Entry'),
            contentDelta: jsonEncode([{'insert': 'Notes\n'}]),
            plainText: 'Notes',
            entryDate: now,
          ),
        );
        final entryImgFile = createMediaFile('entry_photo.webp', 120);
        final entryVidFile = createMediaFile('entry_video.mp4', 450);
        final entryThumbFile = createMediaFile('entry_video_thumb.webp', 80);

        await db.mediaOcrDao.attachMediaToEntry(
          id: 'att_img',
          entryId: 'entry_active_refs',
          relativePath: 'media/entry_photo.webp',
        );
        await db.mediaOcrDao.attachMediaToEntry(
          id: 'att_vid',
          entryId: 'entry_active_refs',
          relativePath: 'media/entry_video.mp4',
          mediaType: 'video',
          thumbnailPath: 'media/entry_video_thumb.webp',
        );

        // 2. Soft-deleted entry in 30-day trash bin (attachment must remain protected)
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'entry_trashed_refs',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Trashed Entry'),
            contentDelta: jsonEncode([{'insert': 'Trash\n'}]),
            plainText: 'Trash',
            entryDate: now,
            isDeleted: const Value(true),
          ),
        );
        final trashedImgFile = createMediaFile('trashed_photo.webp', 110);
        await db.mediaOcrDao.attachMediaToEntry(
          id: 'att_trashed',
          entryId: 'entry_trashed_refs',
          relativePath: 'media/trashed_photo.webp',
        );

        // 3. Album collection with dedicated coverImagePath + separate album photo (full + thumb)
        final albumCoverFile = createMediaFile('album_cover_only.webp', 210);
        final albumPhotoFile = createMediaFile('album_photo_1.webp', 310);
        final albumThumbFile = createMediaFile('album_photo_1_thumb.webp', 90);

        await db.albumsDao.insertCollection(
          AlbumCollectionsCompanion.insert(
            id: 'album_col_refs',
            title: '江南春行纪',
            coverImagePath: const Value('media/album_cover_only.webp'),
          ),
        );
        await db.albumsDao.addPhoto(
          AlbumPhotosCompanion.insert(
            id: 'album_photo_refs',
            collectionId: 'album_col_refs',
            relativeImagePath: 'media/album_photo_1.webp',
            relativeThumbnailPath: 'media/album_photo_1_thumb.webp',
          ),
        );

        // 4. Hidden dotfile + unsupported scratch file + true unreferenced orphan
        final dotFile = createMediaFile('.DS_Store', 64);
        final scratchFile = createMediaFile('scratch.tmp', 50);
        final trueOrphanFile = createMediaFile('orphan_discarded_photo.webp', 500);

        final stats = await StorageOptimizerService.analyzeStorage(
          database: db,
          mediaService: mediaService,
        );

        // 7 referenced supported files + 1 true orphan = 8 (dotfile & .tmp ignored)
        expect(stats.activeEntriesCount, equals(1));
        expect(stats.deletedEntriesCount, equals(1));
        expect(stats.totalMediaFiles, equals(8));
        expect(
          stats.totalMediaBytes,
          equals(120 + 450 + 80 + 110 + 210 + 310 + 90 + 500),
        );
        expect(stats.orphanMediaFiles, equals(1));
        expect(stats.orphanMediaBytes, equals(500));

        final purgedCount = await StorageOptimizerService.purgeOrphanMedia(
          database: db,
          mediaService: mediaService,
        );
        expect(purgedCount, equals(1));

        // Only the true orphan is removed; all referenced files & ignored noise survive
        expect(trueOrphanFile.existsSync(), isFalse);
        expect(entryImgFile.existsSync(), isTrue);
        expect(entryVidFile.existsSync(), isTrue);
        expect(entryThumbFile.existsSync(), isTrue);
        expect(trashedImgFile.existsSync(), isTrue);
        expect(albumCoverFile.existsSync(), isTrue);
        expect(albumPhotoFile.existsSync(), isTrue);
        expect(albumThumbFile.existsSync(), isTrue);
        expect(dotFile.existsSync(), isTrue);
        expect(scratchFile.existsSync(), isTrue);

        final cleanStats = await StorageOptimizerService.analyzeStorage(
          database: db,
          mediaService: mediaService,
        );
        expect(cleanStats.totalMediaFiles, equals(7));
        expect(cleanStats.orphanMediaFiles, equals(0));
        expect(cleanStats.orphanMediaBytes, equals(0));
      },
    );
  });
}

