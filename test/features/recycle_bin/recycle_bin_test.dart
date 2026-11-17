import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/services/recycle_bin_service.dart';
import 'package:memodiary/features/recycle_bin/screens/recycle_bin_screen.dart';
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

  group('RecycleBinScreen Widget Tests', () {
    Future<void> pumpRecycleBin(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RecycleBinScreen(
            database: db,
            mediaService: mediaService,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('displays plain Chinese title and empty state when no deleted entries', (tester) async {
      await pumpRecycleBin(tester);

      expect(find.text('回收站'), findsOneWidget);
      expect(find.text('RECYCLE BIN'), findsNothing);
      expect(find.text('岁暮拾遗'), findsNothing);
      expect(find.text('回收站为空'), findsOneWidget);
      expect(find.text('清空回收站'), findsNothing);
    });

    testWidgets('displays deleted entries with plain countdown, timestamp, and tooltips', (tester) async {
      final deletedAt = DateTime(2026, 11, 10, 14, 30);
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'bin_entry_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('秋日笔记'),
          contentDelta: jsonEncode([{'insert': '内容\n'}]),
          plainText: '内容',
          entryDate: deletedAt,
          isDeleted: const Value(true),
          updatedAt: Value(deletedAt),
        ),
      );
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'bin_entry_2',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value(''),
          contentDelta: jsonEncode([{'insert': '无题内容\n'}]),
          plainText: '无题内容',
          entryDate: deletedAt,
          isDeleted: const Value(true),
          updatedAt: Value(deletedAt),
        ),
      );

      await pumpRecycleBin(tester);

      expect(find.text('清空回收站'), findsOneWidget);
      expect(find.text('秋日笔记'), findsOneWidget);
      expect(find.text('无题'), findsOneWidget);
      expect(find.textContaining('天后自动清除'), findsNWidgets(2));
      final formattedTime = DateFormat('yyyy年M月d日 · HH:mm').format(deletedAt);
      expect(find.text('删除于 $formattedTime'), findsNWidgets(2));
      expect(find.byTooltip('恢复'), findsNWidgets(2));
      expect(find.byTooltip('彻底删除'), findsNWidgets(2));
    });

    testWidgets('restoring entry shows plain snackbar and removes it from bin', (tester) async {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'bin_restore_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('待恢复日记'),
          contentDelta: jsonEncode([{'insert': '内容\n'}]),
          plainText: '内容',
          entryDate: DateTime(2026, 11, 10, 9, 0),
          isDeleted: const Value(true),
        ),
      );

      await pumpRecycleBin(tester);
      await tester.tap(find.byTooltip('恢复'));
      await tester.pumpAndSettle();

      expect(find.text('已恢复：待恢复日记'), findsOneWidget);
      expect(find.text('回收站为空'), findsOneWidget);
      final restored = await db.entriesDao.getEntryById('bin_restore_1');
      expect(restored?.isDeleted, isFalse);
    });

    testWidgets('permanent delete and empty bin show unmistakable confirmation dialogs', (tester) async {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'bin_del_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('日记一'),
          contentDelta: jsonEncode([{'insert': '一\n'}]),
          plainText: '一',
          entryDate: DateTime(2026, 11, 10, 9, 0),
          isDeleted: const Value(true),
        ),
      );
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'bin_del_2',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('日记二'),
          contentDelta: jsonEncode([{'insert': '二\n'}]),
          plainText: '二',
          entryDate: DateTime(2026, 11, 11, 9, 0),
          isDeleted: const Value(true),
        ),
      );

      await pumpRecycleBin(tester);

      // Single permanent delete dialog
      await tester.tap(find.byTooltip('彻底删除').first);
      await tester.pumpAndSettle();
      expect(find.text('彻底删除日记？'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '彻底删除'));
      await tester.pumpAndSettle();

      expect(find.text('已彻底删除'), findsOneWidget);
      expect(await db.entriesDao.getDeletedEntries(), hasLength(1));

      // Empty bin dialog with exact confirmation text
      await tester.tap(find.text('清空回收站'));
      await tester.pumpAndSettle();
      expect(find.text('确定彻底删除全部 1 篇日记？删除后无法恢复。'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '清空回收站'));
      await tester.pumpAndSettle();

      expect(find.text('回收站为空'), findsOneWidget);
      expect(await db.entriesDao.getDeletedEntries(), isEmpty);
    });
  });
}
