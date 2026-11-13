import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/services/ocr/ocr_models.dart';
import 'package:memodiary/core/services/ocr/ocr_queue_manager.dart';
import '../../../helpers/fake_ocr_service.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late MediaSandboxService mediaService;
  late FakeOcrService ocrService;
  late OcrQueueManager queueManager;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('ocr_queue_test_');
    mediaService = MediaSandboxService(baseDirProvider: () async => tempDir);
    ocrService = FakeOcrService();
    queueManager = OcrQueueManager(
      database: db,
      mediaSandboxService: mediaService,
      ocrService: ocrService,
    );
  });

  tearDown(() async {
    await queueManager.dispose();
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('OcrQueueManager - Slice 1: Initialization & pendingBackfillCount', () {
    test('pendingBackfillCount reflects unindexed image count', () async {
      expect(await queueManager.pendingBackfillCount(), 0);

      // Create an entry with an image attachment
      final entryDate = DateTime(2026, 10, 20);
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Test Entry'),
          contentDelta: '[{"insert":"Hello\\n"}]',
          plainText: 'Hello',
          entryDate: entryDate,
        ),
      );

      await db.mediaOcrDao.attachMediaToEntry(
        id: 'att_1',
        entryId: 'entry_1',
        relativePath: 'media/att_1.webp',
        thumbnailPath: 'media/att_1_thumb.webp',
      );

      expect(await queueManager.pendingBackfillCount(), 1);

      // Add an unindexed album photo
      await db.into(db.albumCollections).insert(
            AlbumCollectionsCompanion.insert(
              id: 'album_1',
              title: 'Album 1',
            ),
          );
      await db.into(db.albumPhotos).insert(
            AlbumPhotosCompanion.insert(
              id: 'photo_1',
              collectionId: 'album_1',
              relativeImagePath: 'media/photo_1.webp',
              relativeThumbnailPath: 'media/photo_1_thumb.webp',
            ),
          );

      expect(await queueManager.pendingBackfillCount(), 2);
    });

    test('can dispose multiple times cleanly', () async {
      await queueManager.dispose();
      await queueManager.dispose();
      expect(queueManager.isDisposed, isTrue);
    });
  });

  group('OcrQueueManager - Slice 2: FIFO Processing & Persistence', () {
    test(
      'processes media attachments and album photos in FIFO order and persists results',
      () async {
        // 1. Setup media files on disk in tempDir
        final mediaDir = Directory('${tempDir.path}/media');
        await mediaDir.create(recursive: true);
        final file1 = File('${mediaDir.path}/att_cafe.webp');
        await file1.writeAsBytes([1, 2, 3]);
        final file2 = File('${mediaDir.path}/album_sign.webp');
        await file2.writeAsBytes([4, 5, 6]);

        // 2. Insert records into SQLite
        final now = DateTime(2026, 10, 20, 10, 0);
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'entry_1',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Cafe visit'),
            contentDelta: '[{"insert":"Coffee\\n"}]',
            plainText: 'Coffee',
            entryDate: now,
          ),
        );
        await db.mediaOcrDao.attachMediaToEntry(
          id: 'att_cafe',
          entryId: 'entry_1',
          relativePath: 'media/att_cafe.webp',
          thumbnailPath: 'media/att_cafe_thumb.webp',
        );

        await db.into(db.albumCollections).insert(
              AlbumCollectionsCompanion.insert(
                id: 'album_1',
                title: 'City Walk',
              ),
            );
        await db.into(db.albumPhotos).insert(
              AlbumPhotosCompanion.insert(
                id: 'album_sign',
                collectionId: 'album_1',
                relativeImagePath: 'media/album_sign.webp',
                relativeThumbnailPath: 'media/album_sign_thumb.webp',
              ),
            );

        // 3. Configure FakeOcrService results
        const cafeResult = OcrResult(
          plainText: 'Flat White 32',
          lines: [
            OcrLineBlock(text: 'Flat White 32', box: [0.1, 0.2, 0.5, 0.1]),
          ],
        );
        const signResult = OcrResult(
          plainText: 'West Lake 100m',
          lines: [
            OcrLineBlock(text: 'West Lake 100m', box: [0.2, 0.3, 0.6, 0.2]),
          ],
        );
        ocrService.setResult(file1.path, cafeResult);
        ocrService.setResult(file2.path, signResult);

        // 4. Enqueue both items
        queueManager.enqueueItem(
          UnindexedImageItem(
            id: 'att_cafe',
            sourceType: 'entry_media',
            relativePath: 'media/att_cafe.webp',
            createdAt: now,
          ),
        );
        queueManager.enqueueItem(
          UnindexedImageItem(
            id: 'album_sign',
            sourceType: 'album_photo',
            relativePath: 'media/album_sign.webp',
            createdAt: now,
          ),
        );

        // 5. Wait until idle
        await queueManager.waitUntilIdle();

        // 6. Verify FakeOcrService was called in FIFO order
        expect(ocrService.recognizedPaths, equals([file1.path, file2.path]));

        // 7. Verify SQLite row updates
        final attRow =
            (await db.mediaOcrDao.getMediaAttachmentById('att_cafe'))!;
        expect(attRow.ocrText, 'Flat White 32');
        expect(attRow.ocrBlocksJson, cafeResult.toBlocksJson());

        final albumRow =
            (await db.mediaOcrDao.getAlbumPhotoById('album_sign'))!;
        expect(albumRow.ocrText, 'West Lake 100m');
        expect(albumRow.ocrBlocksJson, signResult.toBlocksJson());
      },
    );
  });

  group('OcrQueueManager - Slice 3: Deduplication & Sentinel Assignment', () {
    test('deduplicates items by id when already queued', () async {
      final mediaDir = Directory('${tempDir.path}/media');
      await mediaDir.create(recursive: true);
      final file = File('${mediaDir.path}/att_dedupe.webp');
      await file.writeAsBytes([1, 2]);

      final now = DateTime(2026, 10, 20);
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_dedupe',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Dedupe test'),
          contentDelta: '[{"insert":"Text\\n"}]',
          plainText: 'Text',
          entryDate: now,
        ),
      );
      await db.mediaOcrDao.attachMediaToEntry(
        id: 'att_dedupe',
        entryId: 'entry_dedupe',
        relativePath: 'media/att_dedupe.webp',
        thumbnailPath: 'media/att_dedupe_thumb.webp',
      );

      ocrService.setResult(
        file.path,
        const OcrResult(plainText: 'Single Run', lines: []),
      );

      final item = UnindexedImageItem(
        id: 'att_dedupe',
        sourceType: 'entry_media',
        relativePath: 'media/att_dedupe.webp',
        createdAt: now,
      );

      // Enqueue multiple times rapidly
      queueManager.enqueueItem(item);
      queueManager.enqueueItem(item);
      queueManager.enqueueItem(item);

      await queueManager.waitUntilIdle();

      // FakeOcrService was only called once
      expect(ocrService.recognizedPaths, equals([file.path]));
    });

    test(
      'persists sentinel values on empty text, missing file, and OCR failure',
      () async {
        final mediaDir = Directory('${tempDir.path}/media');
        await mediaDir.create(recursive: true);

        // 1. File exists but has no text (whitespace only)
        final emptyFile = File('${mediaDir.path}/att_empty.webp');
        await emptyFile.writeAsBytes([1]);
        ocrService.setResult(
          emptyFile.path,
          const OcrResult(plainText: '   \n  ', lines: []),
        );

        // 2. File exists but OCR throws exception
        final errorFile = File('${mediaDir.path}/att_error.webp');
        await errorFile.writeAsBytes([2]);
        ocrService.setError(
          errorFile.path,
          Exception('Corrupted image buffer'),
        );

        // 3. File missing entirely from disk
        const missingPath = 'media/att_missing.webp';

        final now = DateTime(2026, 10, 20);
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'entry_sentinel',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Sentinel test'),
            contentDelta: '[{"insert":"Sentinel\\n"}]',
            plainText: 'Sentinel',
            entryDate: now,
          ),
        );

        await db.mediaOcrDao.attachMediaToEntry(
          id: 'att_empty',
          entryId: 'entry_sentinel',
          relativePath: 'media/att_empty.webp',
          thumbnailPath: 'media/att_empty_thumb.webp',
        );
        await db.mediaOcrDao.attachMediaToEntry(
          id: 'att_error',
          entryId: 'entry_sentinel',
          relativePath: 'media/att_error.webp',
          thumbnailPath: 'media/att_error_thumb.webp',
        );
        await db.mediaOcrDao.attachMediaToEntry(
          id: 'att_missing',
          entryId: 'entry_sentinel',
          relativePath: missingPath,
          thumbnailPath: 'media/att_missing_thumb.webp',
        );

        queueManager.enqueueItem(
          UnindexedImageItem(
            id: 'att_empty',
            sourceType: 'entry_media',
            relativePath: 'media/att_empty.webp',
            createdAt: now,
          ),
        );
        queueManager.enqueueItem(
          UnindexedImageItem(
            id: 'att_error',
            sourceType: 'entry_media',
            relativePath: 'media/att_error.webp',
            createdAt: now,
          ),
        );
        queueManager.enqueueItem(
          UnindexedImageItem(
            id: 'att_missing',
            sourceType: 'entry_media',
            relativePath: missingPath,
            createdAt: now,
          ),
        );

        await queueManager.waitUntilIdle();

        // Check all 3 records in DB have sentinel values '' and '[]'
        final emptyRow =
            (await db.mediaOcrDao.getMediaAttachmentById('att_empty'))!;
        expect(emptyRow.ocrText, '');
        expect(emptyRow.ocrBlocksJson, '[]');

        final errorRow =
            (await db.mediaOcrDao.getMediaAttachmentById('att_error'))!;
        expect(errorRow.ocrText, '');
        expect(errorRow.ocrBlocksJson, '[]');

        final missingRow =
            (await db.mediaOcrDao.getMediaAttachmentById('att_missing'))!;
        expect(missingRow.ocrText, '');
        expect(missingRow.ocrBlocksJson, '[]');

        // Because sentinels are now non-null, pending count should be 0
        expect(await queueManager.pendingBackfillCount(), 0);
      },
    );
  });

  group('OcrQueueManager - Slice 4: Convenience Enqueue Methods', () {
    test('enqueueMediaAttachment fetches row and indexes image', () async {
      final mediaDir = Directory('${tempDir.path}/media');
      await mediaDir.create(recursive: true);
      final file = File('${mediaDir.path}/att_convenience.webp');
      await file.writeAsBytes([7, 8, 9]);

      final now = DateTime(2026, 10, 20);
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_convenience',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Convenience test'),
          contentDelta: '[{"insert":"Test\\n"}]',
          plainText: 'Test',
          entryDate: now,
        ),
      );
      await db.mediaOcrDao.attachMediaToEntry(
        id: 'att_convenience',
        entryId: 'entry_convenience',
        relativePath: 'media/att_convenience.webp',
        thumbnailPath: 'media/att_convenience_thumb.webp',
      );

      ocrService.setResult(
        file.path,
        const OcrResult(
          plainText: 'Convenient Text',
          lines: [
            OcrLineBlock(text: 'Convenient Text', box: [0.1, 0.1, 0.8, 0.1]),
          ],
        ),
      );

      queueManager.enqueueMediaAttachment('att_convenience');
      await queueManager.waitUntilIdle();

      final attRow =
          (await db.mediaOcrDao.getMediaAttachmentById('att_convenience'))!;
      expect(attRow.ocrText, 'Convenient Text');
    });

    test('enqueueAlbumPhoto fetches row and indexes photo', () async {
      final mediaDir = Directory('${tempDir.path}/media');
      await mediaDir.create(recursive: true);
      final file = File('${mediaDir.path}/photo_convenience.webp');
      await file.writeAsBytes([10, 11, 12]);

      await db.into(db.albumCollections).insert(
            AlbumCollectionsCompanion.insert(
              id: 'album_convenience',
              title: 'Collection',
            ),
          );
      await db.into(db.albumPhotos).insert(
            AlbumPhotosCompanion.insert(
              id: 'photo_convenience',
              collectionId: 'album_convenience',
              relativeImagePath: 'media/photo_convenience.webp',
              relativeThumbnailPath: 'media/photo_convenience_thumb.webp',
            ),
          );

      ocrService.setResult(
        file.path,
        const OcrResult(
          plainText: 'Album Caption',
          lines: [
            OcrLineBlock(text: 'Album Caption', box: [0.2, 0.2, 0.6, 0.2]),
          ],
        ),
      );

      queueManager.enqueueAlbumPhoto('photo_convenience');
      await queueManager.waitUntilIdle();

      final photoRow =
          (await db.mediaOcrDao.getAlbumPhotoById('photo_convenience'))!;
      expect(photoRow.ocrText, 'Album Caption');
    });
  });
}
