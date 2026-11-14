import 'dart:math';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/import_export/models/backup_manifest.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('TemplatesDao', () {
    test('exposes canonical built-in templates matching initial seeds', () async {
      final templates = await db.templatesDao.getAllTemplates();
      expect(templates.map((item) => item.id).toSet(),
          equals(TemplatesDao.builtInTemplateIds.toSet()));

      final seedIds = TemplatesDao.buildDefaultTemplateCompanions()
          .map((companion) => companion.id.value)
          .toSet();
      expect(seedIds, equals(TemplatesDao.builtInTemplateIds.toSet()));
    });

    test('supports custom template CRUD and prevents modifying built-ins', () async {
      final custom = await db.templatesDao.createCustomTemplate(
        id: 'tpl_custom_1',
        name: 'Autumn Leaf',
        backgroundType: 'color',
        backgroundValue: '#FAF0E6',
      );
      expect(custom.isCustom, isTrue);

      await db.templatesDao.updateCustomTemplate('tpl_custom_1', name: 'Autumn Gold');
      final updated = await db.templatesDao.getTemplateById('tpl_custom_1');
      expect(updated?.name, 'Autumn Gold');

      await expectLater(
        () => db.templatesDao.updateCustomTemplate('template_minimalist_white', name: 'X'),
        throwsStateError,
      );

      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_tpl_1',
          notebookId: 'notebook_default',
          templateId: 'tpl_custom_1',
          contentDelta: '[{"insert":"Hi\\n"}]',
          plainText: 'Hi',
          entryDate: DateTime(2026, 5, 1),
        ),
      );

      await db.templatesDao.deleteCustomTemplate('tpl_custom_1');
      expect(await db.templatesDao.getTemplateById('tpl_custom_1'), isNull);
      final reassigned = await db.entriesDao.getEntryById('entry_tpl_1');
      expect(reassigned?.templateId, 'template_minimalist_white');
    });
  });

  group('EntriesDao', () {
    test('searchEntries and searchEntriesWithFilters share FTS5 and CJK LIKE resolution', () async {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'e_en',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Alpine Morning'),
          contentDelta: '[{"insert":"Coffee at sunrise\\n"}]',
          plainText: 'Coffee at sunrise',
          entryDate: DateTime(2026, 4, 10),
          mood: const Value(5),
          weather: const Value('sunny'),
        ),
      );
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'e_zh',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('西湖春游'),
          contentDelta: '[{"insert":"苏堤漫步听雨\\n"}]',
          plainText: '苏堤漫步听雨',
          entryDate: DateTime(2026, 4, 11),
          mood: const Value(4),
          weather: const Value('rainy'),
        ),
      );
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'e_sealed',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Future Coffee'),
          contentDelta: '[{"insert":"Secret coffee\\n"}]',
          plainText: 'Secret coffee',
          entryDate: DateTime(2026, 4, 12),
          unlockAt: Value(DateTime.now().add(const Duration(days: 30))),
        ),
      );

      final enHits = await db.entriesDao.searchEntries('Coffee');
      expect(enHits.map((entry) => entry.id).toSet(), equals({'e_en', 'e_sealed'}));

      final filteredEn = await db.entriesDao.searchEntriesWithFilters(
        query: 'Coffee',
        mood: 5,
        excludeSealedTimeCapsules: true,
      );
      expect(filteredEn.map((entry) => entry.id), equals(['e_en']));

      final cjkHits = await db.entriesDao.searchEntries('西湖');
      expect(cjkHits.map((entry) => entry.id), equals(['e_zh']));

      final filteredCjk = await db.entriesDao.searchEntriesWithFilters(
        query: '漫步',
        weather: 'rainy',
      );
      expect(filteredCjk.map((entry) => entry.id), equals(['e_zh']));
    });

    test('hardDeleteEntryAndCollectMediaPaths deletes entry and returns strictly unreferenced paths', () async {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_del_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: '[{"insert":"A\\n"}]',
          plainText: 'A',
          entryDate: DateTime(2026, 3, 1),
        ),
      );
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_keep_2',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: '[{"insert":"B\\n"}]',
          plainText: 'B',
          entryDate: DateTime(2026, 3, 2),
        ),
      );

      await db.mediaOcrDao.attachMediaToEntry(
        id: 'att_unique',
        entryId: 'entry_del_1',
        relativePath: 'media/unique_video.mp4',
        mediaType: 'video',
        thumbnailPath: 'media/unique_thumb.webp',
      );
      await db.mediaOcrDao.attachMediaToEntry(
        id: 'att_shared_entry',
        entryId: 'entry_del_1',
        relativePath: 'media/shared_entry.webp',
      );
      await db.mediaOcrDao.attachMediaToEntry(
        id: 'att_shared_album',
        entryId: 'entry_del_1',
        relativePath: 'media/shared_album.webp',
      );
      await db.mediaOcrDao.attachMediaToEntry(
        id: 'att_shared_cover',
        entryId: 'entry_del_1',
        relativePath: 'media/shared_cover.webp',
      );

      // Keep references in another entry, an album photo, and a collection cover
      await db.mediaOcrDao.attachMediaToEntry(
        id: 'att_keep',
        entryId: 'entry_keep_2',
        relativePath: 'media/shared_entry.webp',
      );
      await db.albumsDao.insertCollection(
        AlbumCollectionsCompanion.insert(
          id: 'col_keep',
          title: 'Keep Album',
          coverImagePath: const Value('media/shared_cover.webp'),
        ),
      );
      await db.albumsDao.addPhoto(
        AlbumPhotosCompanion.insert(
          id: 'photo_keep',
          collectionId: 'col_keep',
          relativeImagePath: 'media/shared_album.webp',
          relativeThumbnailPath: 'media/shared_album_thumb.webp',
        ),
      );

      final orphanPaths = await db.entriesDao.hardDeleteEntryAndCollectMediaPaths('entry_del_1');

      expect(await db.entriesDao.getEntryById('entry_del_1'), isNull);
      expect(await db.mediaOcrDao.getMediaForEntry('entry_del_1'), isEmpty);
      expect(
        orphanPaths.toSet(),
        equals({'media/unique_video.mp4', 'media/unique_thumb.webp'}),
      );
    });

    test('getEntriesOnThisDay handles leap day and getRandomOldEntry respects cutoff', () async {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'leap_2024',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: '[{"insert":"Leap\\n"}]',
          plainText: 'Leap',
          entryDate: DateTime(2024, 2, 29),
        ),
      );
      final onFeb28NonLeap = await db.entriesDao.getEntriesOnThisDay(DateTime(2025, 2, 28));
      expect(onFeb28NonLeap.map((entry) => entry.id), equals(['leap_2024']));

      final picked = await db.entriesDao.getRandomOldEntry(
        minDaysAgo: 90,
        referenceDate: DateTime(2026, 11, 1),
        random: Random(0),
      );
      expect(picked?.id, 'leap_2024');
    });
  });

  group('MediaOcrDao', () {
    test('getAllReferencedMediaPaths aggregates normalized paths across all media tables', () async {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'e_active',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: '[{"insert":"Hi\\n"}]',
          plainText: 'Hi',
          entryDate: DateTime(2026, 1, 1),
        ),
      );
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'e_trashed',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: '[{"insert":"Trash\\n"}]',
          plainText: 'Trash',
          entryDate: DateTime(2026, 1, 2),
          isDeleted: const Value(true),
        ),
      );

      await db.mediaOcrDao.attachMediaToEntry(
        id: 'm1',
        entryId: 'e_active',
        relativePath: r'media\entry_vid.mp4',
        mediaType: 'video',
        thumbnailPath: 'media/entry_vid_thumb.webp',
      );
      await db.mediaOcrDao.attachMediaToEntry(
        id: 'm2',
        entryId: 'e_trashed',
        relativePath: 'media/trashed_img.webp',
      );

      await db.albumsDao.insertCollection(
        AlbumCollectionsCompanion.insert(
          id: 'col_1',
          title: 'Trip',
          coverImagePath: const Value('media/cover_only.webp'),
        ),
      );
      await db.albumsDao.addPhoto(
        AlbumPhotosCompanion.insert(
          id: 'p1',
          collectionId: 'col_1',
          relativeImagePath: 'media/album_full.webp',
          relativeThumbnailPath: 'media/album_thumb.webp',
        ),
      );

      final referenced = await db.mediaOcrDao.getAllReferencedMediaPaths();
      expect(
        referenced,
        equals({
          'media/entry_vid.mp4',
          'media/entry_vid_thumb.webp',
          'media/trashed_img.webp',
          'media/cover_only.webp',
          'media/album_full.webp',
          'media/album_thumb.webp',
        }),
      );

      expect((await db.mediaOcrDao.getMediaAttachmentById('m1'))?.id, 'm1');
      expect((await db.mediaOcrDao.getMediaAttachmentById('missing')), isNull);
      expect((await db.mediaOcrDao.getAlbumPhotoById('p1'))?.id, 'p1');
      expect((await db.mediaOcrDao.getAlbumPhotoById('missing')), isNull);
    });

    test('attachMediaBatch inserts multiple rows atomically and rolls back on failure', () async {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'e_batch',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: '[{"insert":"Batch\\n"}]',
          plainText: 'Batch',
          entryDate: DateTime(2026, 11, 14),
        ),
      );

      await db.mediaOcrDao.attachMediaBatch(
        entryId: 'e_batch',
        attachments: const [
          MediaAttachmentDraft(
            id: 'batch_1',
            relativePath: 'media/batch_1.webp',
          ),
          MediaAttachmentDraft(
            id: 'batch_2',
            relativePath: 'media/batch_2.mp4',
            mediaType: 'video',
            thumbnailPath: 'media/batch_2_thumb.webp',
          ),
        ],
      );

      final inserted = await db.mediaOcrDao.getMediaForEntry('e_batch');
      expect(inserted.map((row) => row.id), equals(['batch_1', 'batch_2']));
      expect(inserted[1].thumbnailPath, equals('media/batch_2_thumb.webp'));

      await expectLater(
        () => db.mediaOcrDao.attachMediaBatch(
          entryId: 'e_batch',
          attachments: const [
            MediaAttachmentDraft(
              id: 'batch_3',
              relativePath: 'media/batch_3.webp',
            ),
            MediaAttachmentDraft(
              id: 'batch_1', // Duplicate PK triggers rollback of batch_3 too.
              relativePath: 'media/dup.webp',
            ),
          ],
        ),
        throwsException,
      );

      final afterRollback = await db.mediaOcrDao.getMediaForEntry('e_batch');
      expect(afterRollback.map((row) => row.id), equals(['batch_1', 'batch_2']));
    });
  });

  group('AlbumsDao', () {
    test('deletePhotoRecords reassigns cover atomically and protects shared paths', () async {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'e_ref',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: '[{"insert":"Ref\\n"}]',
          plainText: 'Ref',
          entryDate: DateTime(2026, 2, 1),
        ),
      );
      await db.mediaOcrDao.attachMediaToEntry(
        id: 'm_ref',
        entryId: 'e_ref',
        relativePath: 'media/shared_with_entry.webp',
      );

      await db.albumsDao.insertCollection(
        AlbumCollectionsCompanion.insert(
          id: 'col_a',
          title: 'Album A',
        ),
      );
      await db.albumsDao.addPhoto(
        AlbumPhotosCompanion.insert(
          id: 'p_cover',
          collectionId: 'col_a',
          relativeImagePath: 'media/shared_with_entry.webp',
          relativeThumbnailPath: 'media/p_cover_thumb.webp',
          sortOrder: const Value(0),
        ),
      );
      await db.albumsDao.addPhoto(
        AlbumPhotosCompanion.insert(
          id: 'p_next',
          collectionId: 'col_a',
          relativeImagePath: 'media/p_next.webp',
          relativeThumbnailPath: 'media/p_next_thumb.webp',
          sortOrder: const Value(1),
        ),
      );

      final collectionBefore = await db.albumsDao.getCollectionById('col_a');
      expect(collectionBefore?.coverImagePath, 'media/shared_with_entry.webp');

      final unreferenced = await db.albumsDao.deletePhotoRecords('p_cover');
      expect(await db.albumsDao.getPhotoById('p_cover'), isNull);

      final collectionAfter = await db.albumsDao.getCollectionById('col_a');
      expect(collectionAfter?.coverImagePath, 'media/p_next.webp');
      expect(unreferenced, equals(['media/p_cover_thumb.webp']));
    });

    test('deleteCollectionRecords deletes collection and photos and returns unreferenced paths', () async {
      await db.albumsDao.insertCollection(
        AlbumCollectionsCompanion.insert(
          id: 'col_shared_holder',
          title: 'Holder',
          coverImagePath: const Value('media/shared_cover.webp'),
        ),
      );
      await db.albumsDao.insertCollection(
        AlbumCollectionsCompanion.insert(
          id: 'col_target',
          title: 'Target',
          coverImagePath: const Value('media/shared_cover.webp'),
        ),
      );
      await db.albumsDao.addPhoto(
        AlbumPhotosCompanion.insert(
          id: 'p_target_1',
          collectionId: 'col_target',
          relativeImagePath: 'media/target_1.webp',
          relativeThumbnailPath: 'media/target_1_thumb.webp',
        ),
      );

      final orphans = await db.albumsDao.deleteCollectionRecords('col_target');
      expect(await db.albumsDao.getCollectionById('col_target'), isNull);
      expect(await db.albumsDao.getPhotosForCollection('col_target'), isEmpty);
      expect(
        orphans.toSet(),
        equals({'media/target_1.webp', 'media/target_1_thumb.webp'}),
      );
    });
  });

  group('BackupDao', () {
    test('exportAllTablesSnapshot and replaceAllFromBackup preserve canonical defaults', () async {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'e_bkp',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Backup Note'),
          contentDelta: '[{"insert":"Saved\\n"}]',
          plainText: 'Saved',
          entryDate: DateTime(2026, 6, 1),
        ),
      );

      final snapshot = await db.backupDao.exportAllTablesSnapshot();
      expect(snapshot.templates.length, 4);
      expect(snapshot.entries.length, 1);

      // Simulate restoring a snapshot where built-in templates and notebooks were omitted
      final strippedSnapshot = BackupDatabaseSnapshot(
        templates: const [],
        notebooks: const [],
        entries: snapshot.entries,
        mediaAttachments: const [],
        albumCollections: const [],
        albumPhotos: const [],
      );

      await db.backupDao.replaceAllFromBackup(strippedSnapshot);
      final restoredTemplates = await db.templatesDao.getAllTemplates();
      expect(
        restoredTemplates.map((item) => item.id).toSet(),
        equals(TemplatesDao.builtInTemplateIds.toSet()),
      );
      final searchHits = await db.entriesDao.searchEntries('Backup');
      expect(searchHits.map((entry) => entry.id), equals(['e_bkp']));
    });
  });
}
