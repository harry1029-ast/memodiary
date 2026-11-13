import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/services/recycle_bin_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late MediaSandboxService mediaService;

  setUp(() async {
    db = AppDatabase.memory();
    tempDir = await Directory.systemTemp.createTemp('memodiary_bin_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
      compressor: (src, dst, {int minWidth = 1600, int minHeight = 1600, int quality = 80}) async {
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

  File writeSandboxFile(String relativePath, String content) {
    final file = File(p.join(tempDir.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
    return file;
  }

  group('Recycle Bin & 30-Day Auto-Purge Tests', () {
    test('softDeleteEntry sets isDeleted=true and restoreEntry restores it', () async {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'test_entry',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('To Delete'),
          contentDelta: jsonEncode([{'insert': 'Bye\n'}]),
          plainText: 'Bye',
          entryDate: DateTime.now(),
        ),
      );

      // Soft delete
      await db.entriesDao.softDeleteEntry('test_entry');
      var deletedList = await db.entriesDao.getDeletedEntries();
      expect(deletedList.length, equals(1));
      expect(deletedList.first.id, equals('test_entry'));

      // Restore
      await db.entriesDao.restoreEntry('test_entry');
      deletedList = await db.entriesDao.getDeletedEntries();
      expect(deletedList.isEmpty, isTrue);

      final active = await db.entriesDao.getEntryById('test_entry');
      expect(active, isNotNull);
      expect(active!.isDeleted, isFalse);
    });

    test('permanentDeleteEntry commits SQLite deletion first and cleans up unreferenced physical media files afterward', () async {
      // 1. Create a dummy photo file in sandbox
      final sourceFile = File('${tempDir.path}/sample.jpg');
      await sourceFile.writeAsString('sample-image-bytes');
      final relPath = await mediaService.copyAndCompressImage(sourceFile);

      final physicalFile = await mediaService.getFileFromRelativePath(relPath);
      expect(await physicalFile.exists(), isTrue);

      // 2. Insert entry and link media
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_with_disk_media',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Media Entry'),
          contentDelta: jsonEncode([{'insert': 'Photo\n'}]),
          plainText: 'Photo',
          entryDate: DateTime.now(),
        ),
      );
      await db.mediaOcrDao.attachMediaToEntry(
        id: 'media_disk_1',
        entryId: 'entry_with_disk_media',
        relativePath: relPath,
      );

      // Verify records exist in SQLite
      final attachments = await db.mediaOcrDao.getMediaForEntry('entry_with_disk_media');
      expect(attachments.length, equals(1));

      // 3. Permanent delete via RecycleBinService
      await RecycleBinService.permanentDeleteEntry(
        entryId: 'entry_with_disk_media',
        database: db,
        mediaService: mediaService,
      );

      // Verify physical file was deleted from disk
      expect(await physicalFile.exists(), isFalse);

      // Verify SQLite records were removed
      final entryAfter = await db.entriesDao.getEntryById('entry_with_disk_media');
      expect(entryAfter, isNull);
      final mediaAfter = await db.mediaOcrDao.getMediaForEntry('entry_with_disk_media');
      expect(mediaAfter.isEmpty, isTrue);
    });

    test('permanentDeleteEntry preserves media files shared with another entry, album photo, or collection cover', () async {
      final uniqueFile = writeSandboxFile('media/unique_trash.webp', 'unique');
      final sharedEntryFile = writeSandboxFile('media/shared_entry.webp', 'entry');
      final sharedAlbumFile = writeSandboxFile('media/shared_album.webp', 'album');
      final sharedCoverFile = writeSandboxFile('media/shared_cover.webp', 'cover');

      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_trash',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: jsonEncode([{'insert': 'Trash\n'}]),
          plainText: 'Trash',
          entryDate: DateTime.now(),
          isDeleted: const Value(true),
        ),
      );
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_active_keeper',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: jsonEncode([{'insert': 'Keep\n'}]),
          plainText: 'Keep',
          entryDate: DateTime.now(),
        ),
      );

      await db.mediaOcrDao.attachMediaToEntry(
        id: 'att_unique',
        entryId: 'entry_trash',
        relativePath: 'media/unique_trash.webp',
      );
      await db.mediaOcrDao.attachMediaToEntry(
        id: 'att_shared_entry',
        entryId: 'entry_trash',
        relativePath: 'media/shared_entry.webp',
      );
      await db.mediaOcrDao.attachMediaToEntry(
        id: 'att_shared_album',
        entryId: 'entry_trash',
        relativePath: 'media/shared_album.webp',
      );
      await db.mediaOcrDao.attachMediaToEntry(
        id: 'att_shared_cover',
        entryId: 'entry_trash',
        relativePath: 'media/shared_cover.webp',
      );

      // External references that must keep shared files alive
      await db.mediaOcrDao.attachMediaToEntry(
        id: 'att_keeper',
        entryId: 'entry_active_keeper',
        relativePath: 'media/shared_entry.webp',
      );
      await db.albumsDao.insertCollection(
        AlbumCollectionsCompanion.insert(
          id: 'col_keeper',
          title: 'Keeper',
          coverImagePath: const Value('media/shared_cover.webp'),
        ),
      );
      await db.albumsDao.addPhoto(
        AlbumPhotosCompanion.insert(
          id: 'photo_keeper',
          collectionId: 'col_keeper',
          relativeImagePath: 'media/shared_album.webp',
          relativeThumbnailPath: 'media/keeper_thumb.webp',
        ),
      );

      await RecycleBinService.permanentDeleteEntry(
        entryId: 'entry_trash',
        database: db,
        mediaService: mediaService,
      );

      expect(await db.entriesDao.getEntryById('entry_trash'), isNull);
      expect(await db.mediaOcrDao.getMediaForEntry('entry_trash'), isEmpty);
      expect(uniqueFile.existsSync(), isFalse);
      expect(sharedEntryFile.existsSync(), isTrue);
      expect(sharedAlbumFile.existsSync(), isTrue);
      expect(sharedCoverFile.existsSync(), isTrue);
    });

    test('DB-first failure safety: permanentDeleteEntry leaves physical media untouched when SQLite delete fails', () async {
      final mediaFile = writeSandboxFile('media/protected_media.webp', 'keep-me');
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_fail_delete',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: jsonEncode([{'insert': 'Protected\n'}]),
          plainText: 'Protected',
          entryDate: DateTime.now(),
          isDeleted: const Value(true),
        ),
      );
      await db.mediaOcrDao.attachMediaToEntry(
        id: 'att_protected',
        entryId: 'entry_fail_delete',
        relativePath: 'media/protected_media.webp',
      );

      await db.customStatement(
        "CREATE TRIGGER block_entry_delete BEFORE DELETE ON entries BEGIN SELECT RAISE(ABORT, 'simulated sqlite entry delete failure'); END;",
      );

      await expectLater(
        () => RecycleBinService.permanentDeleteEntry(
          entryId: 'entry_fail_delete',
          database: db,
          mediaService: mediaService,
        ),
        throwsA(anything),
      );

      expect(mediaFile.existsSync(), isTrue);
      expect(await db.entriesDao.getEntryById('entry_fail_delete'), isNotNull);
      expect(
        await db.mediaOcrDao.getMediaForEntry('entry_fail_delete'),
        hasLength(1),
      );

      await db.customStatement('DROP TRIGGER block_entry_delete;');
      await RecycleBinService.permanentDeleteEntry(
        entryId: 'entry_fail_delete',
        database: db,
        mediaService: mediaService,
      );

      expect(mediaFile.existsSync(), isFalse);
      expect(await db.entriesDao.getEntryById('entry_fail_delete'), isNull);
    });

    test('purgeExpiredEntries deletes only entries older than retention threshold', () async {
      final now = DateTime.now();

      // Entry 1: Soft-deleted 35 days ago (should be purged)
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'old_deleted',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Old Trash'),
          contentDelta: jsonEncode([{'insert': 'Old\n'}]),
          plainText: 'Old',
          entryDate: now.subtract(const Duration(days: 40)),
          isDeleted: const Value(true),
          updatedAt: Value(now.subtract(const Duration(days: 35))),
        ),
      );

      // Entry 2: Soft-deleted 5 days ago (should be retained)
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'recent_deleted',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Recent Trash'),
          contentDelta: jsonEncode([{'insert': 'Recent\n'}]),
          plainText: 'Recent',
          entryDate: now.subtract(const Duration(days: 5)),
          isDeleted: const Value(true),
          updatedAt: Value(now.subtract(const Duration(days: 5))),
        ),
      );

      final purgedCount = await RecycleBinService.purgeExpiredEntries(
        database: db,
        mediaService: mediaService,
        retention: const Duration(days: 30),
      );

      expect(purgedCount, equals(1));

      final remaining = await db.entriesDao.getDeletedEntries();
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('recent_deleted'));
      expect(await db.entriesDao.getEntryById('old_deleted'), isNull);
    });

    test('emptyRecycleBin removes all soft-deleted items', () async {
      final now = DateTime.now();

      for (int i = 0; i < 3; i++) {
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'trash_$i',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: Value('Trash $i'),
            contentDelta: jsonEncode([{'insert': 'Data\n'}]),
            plainText: 'Data',
            entryDate: now,
            isDeleted: const Value(true),
          ),
        );
      }

      var deleted = await db.entriesDao.getDeletedEntries();
      expect(deleted.length, equals(3));

      final emptied = await RecycleBinService.emptyRecycleBin(
        database: db,
        mediaService: mediaService,
      );
      expect(emptied, equals(3));

      deleted = await db.entriesDao.getDeletedEntries();
      expect(deleted.isEmpty, isTrue);
    });
  });
}
