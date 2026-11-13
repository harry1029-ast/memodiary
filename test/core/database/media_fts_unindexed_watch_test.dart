import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Unindexed Image Queries & Reactive Session Watch', () {
    test(
      'getUnindexedImages and countUnindexedImages return only NULL ocr_text images on non-deleted entries and albums ordered by createdAt ASC',
      () async {
        final t1 = DateTime(2026, 10, 1, 8, 0);
        final t2 = DateTime(2026, 10, 2, 9, 0);
        final t3 = DateTime(2026, 10, 3, 10, 0);

        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'entry_live',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Live'),
            contentDelta: '[{"insert":"Live\\n"}]',
            plainText: 'Live',
            entryDate: t1,
          ),
        );
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'entry_deleted',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Deleted'),
            contentDelta: '[{"insert":"Deleted\\n"}]',
            plainText: 'Deleted',
            entryDate: t1,
            isDeleted: const Value(true),
          ),
        );
        await db.into(db.albumCollections).insert(
              AlbumCollectionsCompanion.insert(
                id: 'col_live',
                title: 'Autumn Album',
                createdAt: Value(t1),
                updatedAt: Value(t1),
              ),
            );

        // 1. Unindexed album photo at t2
        await db.into(db.albumPhotos).insert(
              AlbumPhotosCompanion.insert(
                id: 'unindexed_album_t2',
                collectionId: 'col_live',
                relativeImagePath: 'media/album_t2.webp',
                relativeThumbnailPath: 'media/album_t2_thumb.webp',
                createdAt: Value(t2),
              ),
            );

        // 2. Unindexed entry image at t1 (earlier than t2 -> must sort first)
        await db.into(db.mediaAttachments).insert(
              MediaAttachmentsCompanion.insert(
                id: 'unindexed_entry_t1',
                entryId: 'entry_live',
                mediaType: 'image',
                relativePath: 'media/entry_t1.webp',
                createdAt: Value(t1),
              ),
            );

        // 3. Video attachment with NULL ocrText -> excluded
        await db.into(db.mediaAttachments).insert(
              MediaAttachmentsCompanion.insert(
                id: 'video_t3',
                entryId: 'entry_live',
                mediaType: 'video',
                relativePath: 'media/video_t3.mp4',
                createdAt: Value(t3),
              ),
            );

        // 4. Image on soft-deleted entry -> excluded
        await db.into(db.mediaAttachments).insert(
              MediaAttachmentsCompanion.insert(
                id: 'deleted_entry_img',
                entryId: 'entry_deleted',
                mediaType: 'image',
                relativePath: 'media/deleted.webp',
                createdAt: Value(t3),
              ),
            );

        // 5. Sentinel-scanned image (ocrText = '') -> excluded
        await db.into(db.mediaAttachments).insert(
              MediaAttachmentsCompanion.insert(
                id: 'sentinel_img',
                entryId: 'entry_live',
                mediaType: 'image',
                relativePath: 'media/scenery.webp',
                ocrText: const Value(''),
                ocrBlocksJson: const Value('[]'),
                createdAt: Value(t3),
              ),
            );

        expect(await db.mediaOcrDao.countUnindexedImages(), equals(2));
        final unindexed = await db.mediaOcrDao.getUnindexedImages();
        expect(
          unindexed.map((item) => item.id).toList(),
          equals(['unindexed_entry_t1', 'unindexed_album_t2']),
        );
        expect(unindexed.first.sourceType, equals('entry_media'));
        expect(unindexed.first.relativePath, equals('media/entry_t1.webp'));
        expect(unindexed.first.createdAt, equals(t1));
        expect(unindexed.last.sourceType, equals('album_photo'));
        expect(unindexed.last.relativePath, equals('media/album_t2.webp'));
        expect(unindexed.last.createdAt, equals(t2));
      },
    );

    test(
      'watchUnindexedImagesSince reactively emits only unindexed images created at or after since and drops them once scanned',
      () async {
        final legacyTime = DateTime(2026, 10, 1, 10, 0);
        final launchTime = DateTime(2026, 10, 31, 12, 0);
        final sessionTime = DateTime(2026, 10, 31, 12, 5);

        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'entry_session',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Session Entry'),
            contentDelta: '[{"insert":"Session\\n"}]',
            plainText: 'Session',
            entryDate: launchTime,
          ),
        );
        await db.into(db.albumCollections).insert(
              AlbumCollectionsCompanion.insert(
                id: 'col_session',
                title: 'Session Album',
                createdAt: Value(launchTime),
                updatedAt: Value(launchTime),
              ),
            );

        // Legacy unindexed image prior to launchTime -> must NOT appear in session watch
        await db.into(db.mediaAttachments).insert(
              MediaAttachmentsCompanion.insert(
                id: 'legacy_unindexed',
                entryId: 'entry_session',
                mediaType: 'image',
                relativePath: 'media/legacy.webp',
                createdAt: Value(legacyTime),
              ),
            );

        final emissions = <List<String>>[];
        final subscription = db.mediaOcrDao
            .watchUnindexedImagesSince(launchTime)
            .listen(
              (items) => emissions.add(items.map((item) => item.id).toList()),
            );
        addTearDown(subscription.cancel);

        await pumpEventQueue();
        expect(emissions.last, isEmpty);

        // Insert new entry image at launchTime and album photo at sessionTime
        await db.into(db.mediaAttachments).insert(
              MediaAttachmentsCompanion.insert(
                id: 'session_entry_img',
                entryId: 'entry_session',
                mediaType: 'image',
                relativePath: 'media/new_entry.webp',
                createdAt: Value(launchTime),
              ),
            );
        await pumpEventQueue();
        expect(emissions.last, equals(['session_entry_img']));

        await db.into(db.albumPhotos).insert(
              AlbumPhotosCompanion.insert(
                id: 'session_album_img',
                collectionId: 'col_session',
                relativeImagePath: 'media/new_album.webp',
                relativeThumbnailPath: 'media/new_album_thumb.webp',
                createdAt: Value(sessionTime),
              ),
            );
        await pumpEventQueue();
        expect(
          emissions.last,
          equals(['session_entry_img', 'session_album_img']),
        );

        // Mark session_entry_img with sentinel -> drops from stream
        await db.mediaOcrDao.updateMediaOcr(
          'session_entry_img',
          ocrText: '',
          ocrBlocksJson: '[]',
        );
        await pumpEventQueue();
        expect(emissions.last, equals(['session_album_img']));

        // Mark session_album_img with OCR text -> drops from stream
        await db.mediaOcrDao.updateAlbumPhotoOcr(
          'session_album_img',
          ocrText: 'Scanned Sign',
          ocrBlocksJson: '[{"text":"Scanned Sign","box":[0.1,0.1,0.5,0.1]}]',
        );
        await pumpEventQueue();
        expect(emissions.last, isEmpty);
      },
    );
  });
}
