import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/services/recycle_bin_service.dart';

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

  group('Recycle Bin & 30-Day Auto-Purge Tests', () {
    test('softDeleteEntry sets isDeleted=true and restoreEntry restores it', () async {
      await db.createEntry(
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
      await db.softDeleteEntry('test_entry');
      var deletedList = await db.getDeletedEntries();
      expect(deletedList.length, equals(1));
      expect(deletedList.first.id, equals('test_entry'));

      // Restore
      await db.restoreEntry('test_entry');
      deletedList = await db.getDeletedEntries();
      expect(deletedList.isEmpty, isTrue);

      final active = await db.getEntryById('test_entry');
      expect(active, isNotNull);
      expect(active!.isDeleted, isFalse);
    });

    test('permanentDeleteEntry cleans up physical media files before SQLite records', () async {
      // 1. Create a dummy photo file in sandbox
      final sourceFile = File('${tempDir.path}/sample.jpg');
      await sourceFile.writeAsString('sample-image-bytes');
      final relPath = await mediaService.copyAndCompressImage(sourceFile);

      final physicalFile = await mediaService.getFileFromRelativePath(relPath);
      expect(await physicalFile.exists(), isTrue);

      // 2. Insert entry and link media
      await db.createEntry(
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
      await db.attachMediaToEntry(
        id: 'media_disk_1',
        entryId: 'entry_with_disk_media',
        relativePath: relPath,
      );

      // Verify records exist in SQLite
      final attachments = await db.getMediaForEntry('entry_with_disk_media');
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
      final entryAfter = await db.getEntryById('entry_with_disk_media');
      expect(entryAfter, isNull);
      final mediaAfter = await db.getMediaForEntry('entry_with_disk_media');
      expect(mediaAfter.isEmpty, isTrue);
    });

    test('purgeExpiredEntries deletes only entries older than retention threshold', () async {
      final now = DateTime.now();

      // Entry 1: Soft-deleted 35 days ago (should be purged)
      await db.createEntry(
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
      await db.createEntry(
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

      final remaining = await db.getDeletedEntries();
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('recent_deleted'));
      expect(await db.getEntryById('old_deleted'), isNull);
    });

    test('emptyRecycleBin removes all soft-deleted items', () async {
      final now = DateTime.now();

      for (int i = 0; i < 3; i++) {
        await db.createEntry(
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

      var deleted = await db.getDeletedEntries();
      expect(deleted.length, equals(3));

      final emptied = await RecycleBinService.emptyRecycleBin(
        database: db,
        mediaService: mediaService,
      );
      expect(emptied, equals(3));

      deleted = await db.getDeletedEntries();
      expect(deleted.isEmpty, isTrue);
    });
  });
}

