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
      await db.createEntry(
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

      await db.attachMediaToEntry(
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
    test('processes media attachments and album photos in FIFO order and persists results', () async {
      // 1. Setup media files on disk in tempDir
      final mediaDir = Directory('${tempDir.path}/media');
      await mediaDir.create(recursive: true);
      final file1 = File('${mediaDir.path}/att_cafe.webp');
      await file1.writeAsBytes([1, 2, 3]);
      final file2 = File('${mediaDir.path}/album_sign.webp');
      await file2.writeAsBytes([4, 5, 6]);

      // 2. Insert records into SQLite
      final now = DateTime(2026, 10, 20, 10, 0);
      await db.createEntry(
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
      await db.attachMediaToEntry(
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
      final attRow = await (db.select(db.mediaAttachments)
            ..where((tbl) => tbl.id.equals('att_cafe')))
          .getSingle();
      expect(attRow.ocrText, 'Flat White 32');
      expect(attRow.ocrBlocksJson, cafeResult.toBlocksJson());

      final albumRow = await (db.select(db.albumPhotos)
            ..where((tbl) => tbl.id.equals('album_sign')))
          .getSingle();
      expect(albumRow.ocrText, 'West Lake 100m');
      expect(albumRow.ocrBlocksJson, signResult.toBlocksJson());
    });
  });

  group('OcrQueueManager - Slice 3: Deduplication & Sentinel Assignment', () {
    test('deduplicates items by id when already queued', () async {
      final mediaDir = Directory('${tempDir.path}/media');
      await mediaDir.create(recursive: true);
      final file = File('${mediaDir.path}/att_dedupe.webp');
      await file.writeAsBytes([1, 2]);

      final now = DateTime(2026, 10, 20);
      await db.createEntry(
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
      await db.attachMediaToEntry(
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

    test('persists sentinel values on empty text, missing file, and OCR failure', () async {
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
      ocrService.setError(errorFile.path, Exception('Corrupted image buffer'));

      // 3. File missing entirely from disk
      const missingPath = 'media/att_missing.webp';

      final now = DateTime(2026, 10, 20);
      await db.createEntry(
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

      await db.attachMediaToEntry(
        id: 'att_empty',
        entryId: 'entry_sentinel',
        relativePath: 'media/att_empty.webp',
        thumbnailPath: 'media/att_empty_thumb.webp',
      );
      await db.attachMediaToEntry(
        id: 'att_error',
        entryId: 'entry_sentinel',
        relativePath: 'media/att_error.webp',
        thumbnailPath: 'media/att_error_thumb.webp',
      );
      await db.attachMediaToEntry(
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
      final emptyRow = await (db.select(db.mediaAttachments)
            ..where((tbl) => tbl.id.equals('att_empty')))
          .getSingle();
      expect(emptyRow.ocrText, '');
      expect(emptyRow.ocrBlocksJson, '[]');

      final errorRow = await (db.select(db.mediaAttachments)
            ..where((tbl) => tbl.id.equals('att_error')))
          .getSingle();
      expect(errorRow.ocrText, '');
      expect(errorRow.ocrBlocksJson, '[]');

      final missingRow = await (db.select(db.mediaAttachments)
            ..where((tbl) => tbl.id.equals('att_missing')))
          .getSingle();
      expect(missingRow.ocrText, '');
      expect(missingRow.ocrBlocksJson, '[]');

      // Because sentinels are now non-null, pending count should be 0
      expect(await queueManager.pendingBackfillCount(), 0);
    });
  });

  group('OcrQueueManager - Slice 4: Convenience Enqueue Methods', () {
    test('enqueueMediaAttachment fetches row and indexes image', () async {
      final mediaDir = Directory('${tempDir.path}/media');
      await mediaDir.create(recursive: true);
      final file = File('${mediaDir.path}/att_convenience.webp');
      await file.writeAsBytes([7, 8, 9]);

      final now = DateTime(2026, 10, 20);
      await db.createEntry(
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
      await db.attachMediaToEntry(
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

      final attRow = await (db.select(db.mediaAttachments)
            ..where((tbl) => tbl.id.equals('att_convenience')))
          .getSingle();
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

      final photoRow = await (db.select(db.albumPhotos)
            ..where((tbl) => tbl.id.equals('photo_convenience')))
          .getSingle();
      expect(photoRow.ocrText, 'Album Caption');
    });
  });

  group('OcrQueueManager - Slice 5: Reactive Session-Bound Monitoring', () {
    test('start() automatically processes images created >= launchTime, ignoring legacy images', () async {
      final launchTime = DateTime(2026, 10, 20, 12, 0);
      final preLaunchTime = DateTime(2026, 10, 20, 10, 0);
      final postLaunchTime = DateTime(2026, 10, 20, 12, 5);

      // Create a manager with fixed clock
      final clockedManager = OcrQueueManager(
        database: db,
        mediaSandboxService: mediaService,
        ocrService: ocrService,
        clock: () => launchTime,
      );

      // 1. Insert legacy image before launchTime
      final mediaDir = Directory('${tempDir.path}/media');
      await mediaDir.create(recursive: true);
      final legacyFile = File('${mediaDir.path}/legacy.webp');
      await legacyFile.writeAsBytes([1]);
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_legacy',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Legacy Entry'),
          contentDelta: '[{"insert":"Legacy\\n"}]',
          plainText: 'Legacy',
          entryDate: preLaunchTime,
          createdAt: Value(preLaunchTime),
        ),
      );
      await db.into(db.mediaAttachments).insert(
            MediaAttachmentsCompanion.insert(
              id: 'att_legacy',
              entryId: 'entry_legacy',
              mediaType: 'image',
              relativePath: 'media/legacy.webp',
              createdAt: Value(preLaunchTime),
            ),
          );

      // 2. Start the reactive watcher
      clockedManager.start();
      // Multiple calls are idempotent
      clockedManager.start();

      await pumpEventQueue();
      await clockedManager.waitUntilIdle();

      // Legacy item was NOT indexed
      final legacyRow = await (db.select(db.mediaAttachments)
            ..where((tbl) => tbl.id.equals('att_legacy')))
          .getSingle();
      expect(legacyRow.ocrText, isNull);

      // 3. Insert post-launch image
      final postFile = File('${mediaDir.path}/post_launch.webp');
      await postFile.writeAsBytes([2]);
      ocrService.setResult(
        postFile.path,
        const OcrResult(
          plainText: 'Fresh Session Photo',
          lines: [],
        ),
      );

      await db.into(db.mediaAttachments).insert(
            MediaAttachmentsCompanion.insert(
              id: 'att_post',
              entryId: 'entry_legacy',
              mediaType: 'image',
              relativePath: 'media/post_launch.webp',
              createdAt: Value(postLaunchTime),
            ),
          );

      // Allow Drift stream to emit
      await pumpEventQueue();

      // Wait until idle
      await clockedManager.waitUntilIdle();

      // Post-launch item was automatically indexed
      final postRow = await (db.select(db.mediaAttachments)
            ..where((tbl) => tbl.id.equals('att_post')))
          .getSingle();
      expect(postRow.ocrText, 'Fresh Session Photo');

      // 4. Dispose cancels watcher
      await clockedManager.dispose();

      // Insert another post-launch image after dispose
      final postDisposeFile = File('${mediaDir.path}/post_dispose.webp');
      await postDisposeFile.writeAsBytes([3]);
      await db.into(db.mediaAttachments).insert(
            MediaAttachmentsCompanion.insert(
              id: 'att_post_dispose',
              entryId: 'entry_legacy',
              mediaType: 'image',
              relativePath: 'media/post_dispose.webp',
              createdAt: Value(postLaunchTime.add(const Duration(minutes: 5))),
            ),
          );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final postDisposeRow = await (db.select(db.mediaAttachments)
            ..where((tbl) => tbl.id.equals('att_post_dispose')))
          .getSingle();
      expect(postDisposeRow.ocrText, isNull);
    });
  });

  group('OcrQueueManager - Slice 6: Historical Backfill & Cancellation', () {
    test('runBackfill processes all unindexed items sequentially and tracks progress', () async {
      final mediaDir = Directory('${tempDir.path}/media');
      await mediaDir.create(recursive: true);

      final file1 = File('${mediaDir.path}/bf_1.webp');
      await file1.writeAsBytes([1]);
      final file2 = File('${mediaDir.path}/bf_2.webp');
      await file2.writeAsBytes([2]);
      final file3 = File('${mediaDir.path}/bf_3.webp');
      await file3.writeAsBytes([3]);

      ocrService.setResult(file1.path, const OcrResult(plainText: 'Backfill 1', lines: []));
      ocrService.setResult(file2.path, const OcrResult(plainText: 'Backfill 2', lines: []));
      ocrService.setResult(file3.path, const OcrResult(plainText: 'Backfill 3', lines: []));

      final t1 = DateTime(2026, 10, 10, 10, 0);
      final t2 = DateTime(2026, 10, 10, 11, 0);
      final t3 = DateTime(2026, 10, 10, 12, 0);

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_bf',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Backfill Entry'),
          contentDelta: '[{"insert":"BF\\n"}]',
          plainText: 'BF',
          entryDate: t1,
          createdAt: Value(t1),
        ),
      );

      await db.into(db.mediaAttachments).insert(
            MediaAttachmentsCompanion.insert(
              id: 'bf_att_1',
              entryId: 'entry_bf',
              mediaType: 'image',
              relativePath: 'media/bf_1.webp',
              createdAt: Value(t1),
            ),
          );
      await db.into(db.mediaAttachments).insert(
            MediaAttachmentsCompanion.insert(
              id: 'bf_att_2',
              entryId: 'entry_bf',
              mediaType: 'image',
              relativePath: 'media/bf_2.webp',
              createdAt: Value(t2),
            ),
          );

      await db.into(db.albumCollections).insert(
            AlbumCollectionsCompanion.insert(
              id: 'bf_album',
              title: 'Backfill Collection',
              createdAt: Value(t3),
            ),
          );
      await db.into(db.albumPhotos).insert(
            AlbumPhotosCompanion.insert(
              id: 'bf_photo_3',
              collectionId: 'bf_album',
              relativeImagePath: 'media/bf_3.webp',
              relativeThumbnailPath: 'media/bf_3_thumb.webp',
              createdAt: Value(t3),
            ),
          );

      expect(await queueManager.pendingBackfillCount(), 3);

      final progress = <(int, int)>[];
      await queueManager.runBackfill(
        onProgress: (current, total) {
          progress.add((current, total));
        },
      );

      expect(progress, equals([(1, 3), (2, 3), (3, 3)]));
      expect(await queueManager.pendingBackfillCount(), 0);

      final row1 = await (db.select(db.mediaAttachments)
            ..where((tbl) => tbl.id.equals('bf_att_1')))
          .getSingle();
      expect(row1.ocrText, 'Backfill 1');

      final row3 = await (db.select(db.albumPhotos)
            ..where((tbl) => tbl.id.equals('bf_photo_3')))
          .getSingle();
      expect(row3.ocrText, 'Backfill 3');
    });

    test('runBackfill halts cleanly when cancelled via isCancelled', () async {
      final mediaDir = Directory('${tempDir.path}/media');
      await mediaDir.create(recursive: true);

      final file1 = File('${mediaDir.path}/cancel_1.webp');
      await file1.writeAsBytes([1]);
      final file2 = File('${mediaDir.path}/cancel_2.webp');
      await file2.writeAsBytes([2]);

      ocrService.setResult(file1.path, const OcrResult(plainText: 'Cancel 1', lines: []));
      ocrService.setResult(file2.path, const OcrResult(plainText: 'Cancel 2', lines: []));

      final now = DateTime(2026, 10, 10);
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_cancel',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Cancel Entry'),
          contentDelta: '[{"insert":"Cancel\\n"}]',
          plainText: 'Cancel',
          entryDate: now,
          createdAt: Value(now),
        ),
      );

      await db.into(db.mediaAttachments).insert(
            MediaAttachmentsCompanion.insert(
              id: 'cancel_att_1',
              entryId: 'entry_cancel',
              mediaType: 'image',
              relativePath: 'media/cancel_1.webp',
              createdAt: Value(now),
            ),
          );
      await db.into(db.mediaAttachments).insert(
            MediaAttachmentsCompanion.insert(
              id: 'cancel_att_2',
              entryId: 'entry_cancel',
              mediaType: 'image',
              relativePath: 'media/cancel_2.webp',
              createdAt: Value(now.add(const Duration(minutes: 1))),
            ),
          );

      var shouldCancel = false;
      final progress = <(int, int)>[];

      await queueManager.runBackfill(
        onProgress: (current, total) {
          progress.add((current, total));
          // Signal cancel after first item is processed
          if (current == 1) {
            shouldCancel = true;
          }
        },
        isCancelled: () => shouldCancel,
      );

      expect(progress, equals([(1, 2)]));

      // 1st item indexed, 2nd item still NULL
      final row1 = await (db.select(db.mediaAttachments)
            ..where((tbl) => tbl.id.equals('cancel_att_1')))
          .getSingle();
      expect(row1.ocrText, 'Cancel 1');

      final row2 = await (db.select(db.mediaAttachments)
            ..where((tbl) => tbl.id.equals('cancel_att_2')))
          .getSingle();
      expect(row2.ocrText, isNull);

      // 1 item remaining to backfill
      expect(await queueManager.pendingBackfillCount(), 1);
    });

    test('runBackfill pauses when isPaused returns true and resumes when false', () async {
      final mediaDir = Directory('${tempDir.path}/media');
      await mediaDir.create(recursive: true);

      final file1 = File('${mediaDir.path}/pause_1.webp');
      await file1.writeAsBytes([1]);
      final file2 = File('${mediaDir.path}/pause_2.webp');
      await file2.writeAsBytes([2]);

      ocrService.setResult(file1.path, const OcrResult(plainText: 'Pause 1', lines: []));
      ocrService.setResult(file2.path, const OcrResult(plainText: 'Pause 2', lines: []));

      final now = DateTime(2026, 10, 10);
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_pause',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Pause Entry'),
          contentDelta: '[{"insert":"Pause\\n"}]',
          plainText: 'Pause',
          entryDate: now,
          createdAt: Value(now),
        ),
      );

      await db.into(db.mediaAttachments).insert(
            MediaAttachmentsCompanion.insert(
              id: 'pause_att_1',
              entryId: 'entry_pause',
              mediaType: 'image',
              relativePath: 'media/pause_1.webp',
              createdAt: Value(now),
            ),
          );
      await db.into(db.mediaAttachments).insert(
            MediaAttachmentsCompanion.insert(
              id: 'pause_att_2',
              entryId: 'entry_pause',
              mediaType: 'image',
              relativePath: 'media/pause_2.webp',
              createdAt: Value(now.add(const Duration(minutes: 1))),
            ),
          );

      var isPaused = false;
      final progress = <(int, int)>[];

      // Start backfill in a future
      final backfillFuture = queueManager.runBackfill(
        onProgress: (current, total) {
          progress.add((current, total));
          if (current == 1) {
            isPaused = true;
          }
        },
        isPaused: () => isPaused,
      );

      // Wait a moment while paused
      await Future<void>.delayed(const Duration(milliseconds: 250));

      // Item 1 was processed, item 2 should be waiting while isPaused == true
      expect(progress, equals([(1, 2)]));
      final row2BeforeResume = await (db.select(db.mediaAttachments)
            ..where((tbl) => tbl.id.equals('pause_att_2')))
          .getSingle();
      expect(row2BeforeResume.ocrText, isNull);

      // Resume backfill
      isPaused = false;
      await backfillFuture;

      expect(progress, equals([(1, 2), (2, 2)]));
      final row2AfterResume = await (db.select(db.mediaAttachments)
            ..where((tbl) => tbl.id.equals('pause_att_2')))
          .getSingle();
      expect(row2AfterResume.ocrText, 'Pause 2');
    });
  });
}
