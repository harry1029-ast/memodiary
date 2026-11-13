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
    tempDir = await Directory.systemTemp.createTemp('ocr_queue_backfill_test_');
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

  group('OcrQueueManager - Slice 5: Reactive Session-Bound Monitoring', () {
    test(
      'start() automatically processes images created >= launchTime, ignoring legacy images',
      () async {
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
        await db.entriesDao.createEntry(
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
        final legacyRow =
            (await db.mediaOcrDao.getMediaAttachmentById('att_legacy'))!;
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
        final postRow =
            (await db.mediaOcrDao.getMediaAttachmentById('att_post'))!;
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
                createdAt:
                    Value(postLaunchTime.add(const Duration(minutes: 5))),
              ),
            );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final postDisposeRow =
            (await db.mediaOcrDao.getMediaAttachmentById('att_post_dispose'))!;
        expect(postDisposeRow.ocrText, isNull);
      },
    );
  });

  group('OcrQueueManager - Slice 6: Historical Backfill & Cancellation', () {
    test(
      'runBackfill processes all unindexed items sequentially and tracks progress',
      () async {
        final mediaDir = Directory('${tempDir.path}/media');
        await mediaDir.create(recursive: true);

        final file1 = File('${mediaDir.path}/bf_1.webp');
        await file1.writeAsBytes([1]);
        final file2 = File('${mediaDir.path}/bf_2.webp');
        await file2.writeAsBytes([2]);
        final file3 = File('${mediaDir.path}/bf_3.webp');
        await file3.writeAsBytes([3]);

        ocrService.setResult(
          file1.path,
          const OcrResult(plainText: 'Backfill 1', lines: []),
        );
        ocrService.setResult(
          file2.path,
          const OcrResult(plainText: 'Backfill 2', lines: []),
        );
        ocrService.setResult(
          file3.path,
          const OcrResult(plainText: 'Backfill 3', lines: []),
        );

        final t1 = DateTime(2026, 10, 10, 10, 0);
        final t2 = DateTime(2026, 10, 10, 11, 0);
        final t3 = DateTime(2026, 10, 10, 12, 0);

        await db.entriesDao.createEntry(
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

        final row1 = (await db.mediaOcrDao.getMediaAttachmentById('bf_att_1'))!;
        expect(row1.ocrText, 'Backfill 1');

        final row3 = (await db.mediaOcrDao.getAlbumPhotoById('bf_photo_3'))!;
        expect(row3.ocrText, 'Backfill 3');
      },
    );

    test(
      'runBackfill halts cleanly when cancelled via isCancelled',
      () async {
        final mediaDir = Directory('${tempDir.path}/media');
        await mediaDir.create(recursive: true);

        final file1 = File('${mediaDir.path}/cancel_1.webp');
        await file1.writeAsBytes([1]);
        final file2 = File('${mediaDir.path}/cancel_2.webp');
        await file2.writeAsBytes([2]);

        ocrService.setResult(
          file1.path,
          const OcrResult(plainText: 'Cancel 1', lines: []),
        );
        ocrService.setResult(
          file2.path,
          const OcrResult(plainText: 'Cancel 2', lines: []),
        );

        final now = DateTime(2026, 10, 10);
        await db.entriesDao.createEntry(
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
        final row1 =
            (await db.mediaOcrDao.getMediaAttachmentById('cancel_att_1'))!;
        expect(row1.ocrText, 'Cancel 1');

        final row2 =
            (await db.mediaOcrDao.getMediaAttachmentById('cancel_att_2'))!;
        expect(row2.ocrText, isNull);

        // 1 item remaining to backfill
        expect(await queueManager.pendingBackfillCount(), 1);
      },
    );

    test(
      'runBackfill pauses when isPaused returns true and resumes when false',
      () async {
        final mediaDir = Directory('${tempDir.path}/media');
        await mediaDir.create(recursive: true);

        final file1 = File('${mediaDir.path}/pause_1.webp');
        await file1.writeAsBytes([1]);
        final file2 = File('${mediaDir.path}/pause_2.webp');
        await file2.writeAsBytes([2]);

        ocrService.setResult(
          file1.path,
          const OcrResult(plainText: 'Pause 1', lines: []),
        );
        ocrService.setResult(
          file2.path,
          const OcrResult(plainText: 'Pause 2', lines: []),
        );

        final now = DateTime(2026, 10, 10);
        await db.entriesDao.createEntry(
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
        final row2BeforeResume =
            (await db.mediaOcrDao.getMediaAttachmentById('pause_att_2'))!;
        expect(row2BeforeResume.ocrText, isNull);

        // Resume backfill
        isPaused = false;
        await backfillFuture;

        expect(progress, equals([(1, 2), (2, 2)]));
        final row2AfterResume =
            (await db.mediaOcrDao.getMediaAttachmentById('pause_att_2'))!;
        expect(row2AfterResume.ocrText, 'Pause 2');
      },
    );
  });
}
