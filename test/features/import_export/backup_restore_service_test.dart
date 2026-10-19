import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/import_export/models/backup_manifest.dart';
import 'package:memodiary/features/import_export/services/backup_crypto.dart';
import 'package:memodiary/features/import_export/services/backup_restore_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late AppDatabase db;
  late Directory baseDir;
  late Directory tempDir;
  late MediaSandboxService mediaService;
  late BackupRestoreService backupService;

  setUp(() {
    db = AppDatabase.memory();
    baseDir = Directory.systemTemp.createTempSync('memodiary_base_test_');
    tempDir = Directory.systemTemp.createTempSync('memodiary_temp_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => baseDir,
    );
    backupService = BackupRestoreService(
      database: db,
      mediaService: mediaService,
      tempDirProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    await db.close();
    if (baseDir.existsSync()) {
      baseDir.deleteSync(recursive: true);
    }
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<void> seedRichDatabaseAndMedia() async {
    // 1. Custom template
    await db.createCustomTemplate(
      id: 'template_custom_ocean',
      name: 'Ocean Breeze',
      backgroundType: 'lined',
      backgroundValue: '#EBF8FF',
      fontFamily: 'Serif',
      lineSpacing: 1.8,
      marginHorizontal: 24.0,
    );

    // 2. Second notebook
    await db.into(db.notebooks).insert(
          NotebooksCompanion.insert(
            id: 'notebook_travel',
            title: 'Travel Logs',
            defaultTemplateId: 'template_custom_ocean',
          ),
        );

    final d1 = DateTime(2026, 10, 1, 10, 0);
    final d2 = DateTime(2026, 10, 5, 20, 0);
    final futureUnlock = DateTime(2027, 10, 1);

    // 3. Entries: active, locked, time-capsule, soft-deleted
    await db.createEntry(
      EntriesCompanion.insert(
        id: 'entry_active_1',
        notebookId: 'notebook_travel',
        templateId: 'template_custom_ocean',
        title: const Value('National Day Trip'),
        contentDelta: '[{"insert":"Visited West Lake in Hangzhou.\\n"}]',
        plainText: 'Visited West Lake in Hangzhou.',
        entryDate: d1,
        mood: const Value(5),
        weather: const Value('sunny'),
        isWeeklyReview: const Value(true),
        weekNumber: const Value(40),
      ),
    );

    await db.createEntry(
      EntriesCompanion.insert(
        id: 'entry_locked_2',
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        title: const Value('Private Reflection'),
        contentDelta: '[{"insert":"Secret thoughts.\\n"}]',
        plainText: 'Secret thoughts.',
        entryDate: d2,
        isLocked: const Value(true),
        entryPinHash: const Value('salt_abc:hash_xyz'),
      ),
    );

    await db.createEntry(
      EntriesCompanion.insert(
        id: 'entry_capsule_3',
        notebookId: 'notebook_default',
        templateId: 'template_lined_paper',
        title: const Value('Letter to 2027'),
        contentDelta: '[{"insert":"Dear future me.\\n"}]',
        plainText: 'Dear future me.',
        entryDate: d2,
        unlockAt: Value(futureUnlock),
      ),
    );

    await db.createEntry(
      EntriesCompanion.insert(
        id: 'entry_deleted_4',
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        title: const Value('Trashed Note'),
        contentDelta: '[{"insert":"In recycle bin.\\n"}]',
        plainText: 'In recycle bin.',
        entryDate: d1,
        isDeleted: const Value(true),
      ),
    );

    // 4. Physical media files & attachments
    final mediaDir = Directory(p.join(baseDir.path, 'media'))
      ..createSync(recursive: true);

    File(p.join(mediaDir.path, 'photo_1.webp'))
        .writeAsBytesSync([0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4]);
    File(p.join(mediaDir.path, 'video_1.mp4'))
        .writeAsBytesSync([0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70]);
    File(p.join(mediaDir.path, 'video_1_thumb.webp'))
        .writeAsBytesSync([0x52, 0x49, 0x46, 0x46, 9, 9, 9]);

    await db.attachMediaToEntry(
      id: 'media_img_1',
      entryId: 'entry_active_1',
      relativePath: 'media/photo_1.webp',
      mediaType: 'image',
    );
    await db.attachMediaToEntry(
      id: 'media_vid_1',
      entryId: 'entry_active_1',
      relativePath: 'media/video_1.mp4',
      mediaType: 'video',
      thumbnailPath: 'media/video_1_thumb.webp',
    );
  }

  group('BackupRestoreService — Full Encrypted Round-Trip & Watchpoints', () {
    test('creates encrypted .mdbak and atomically restores all 4 tables, media files, and deduplicated FTS5 index', () async {
      await seedRichDatabaseAndMedia();
      final backupFile = File(p.join(tempDir.path, 'full_backup.mdbak'));

      final createRes = await backupService.createBackup(
        destination: backupFile,
        passphrase: 'strong-backup-passphrase',
        pbkdf2Iterations: 1000,
      );

      expect(createRes.isEncrypted, isTrue);
      expect(createRes.entriesCount, 4);
      expect(createRes.mediaFilesCount, 3);
      expect(backupFile.existsSync(), isTrue);

      final inspection = await backupService.inspectBackup(backupFile);
      expect(inspection.isEncrypted, isTrue);
      expect(inspection.pbkdf2Iterations, 1000);

      // Mutate live database & delete media to verify Replace Mode
      await db.delete(db.mediaAttachments).go();
      await db.delete(db.entries).go();
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'ephemeral_entry',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Should Be Replaced'),
          contentDelta: '[{"insert":"Temporary\\n"}]',
          plainText: 'Temporary',
          entryDate: DateTime(2026, 10, 18),
        ),
      );
      final mediaDir = Directory(p.join(baseDir.path, 'media'));
      if (mediaDir.existsSync()) {
        mediaDir.deleteSync(recursive: true);
      }

      // Restore from encrypted backup
      final restoreRes = await backupService.restoreBackup(
        source: backupFile,
        passphrase: 'strong-backup-passphrase',
      );

      expect(restoreRes.entriesRestored, 4);
      expect(restoreRes.mediaFilesRestored, 3);
      expect(restoreRes.notebooksRestored, 2);

      // Ephemeral post-backup entry should be gone (Replace mode)
      expect(await db.getEntryById('ephemeral_entry'), isNull);

      // Verify custom template, locked entry, capsule, and recycle bin entry
      final customTemplate = await db.getTemplateById('template_custom_ocean');
      expect(customTemplate, isNotNull);
      expect(customTemplate!.name, 'Ocean Breeze');
      expect(customTemplate.isCustom, isTrue);

      final lockedEntry = await db.getEntryById('entry_locked_2');
      expect(lockedEntry, isNotNull);
      expect(lockedEntry!.isLocked, isTrue);
      expect(lockedEntry.entryPinHash, 'salt_abc:hash_xyz');

      final capsuleEntry = await db.getEntryById('entry_capsule_3');
      expect(capsuleEntry, isNotNull);
      expect(capsuleEntry!.unlockAt, isNotNull);

      final deletedEntries = await db.getDeletedEntries();
      expect(deletedEntries.map((e) => e.id), contains('entry_deleted_4'));

      // Verify Watchpoint 1: No duplicate rows in entries_fts
      final ftsCountRow = await db
          .customSelect('SELECT COUNT(*) AS cnt FROM entries_fts')
          .getSingle();
      expect(ftsCountRow.read<int>('cnt'), 4);

      final searchHits = await db.searchEntries('Hangzhou');
      expect(searchHits.length, 1);
      expect(searchHits.single.id, 'entry_active_1');

      // Verify physical media files restored bit-for-bit
      final restoredPhoto = File(p.join(baseDir.path, 'media', 'photo_1.webp'));
      final restoredVideo = File(p.join(baseDir.path, 'media', 'video_1.mp4'));
      final restoredThumb =
          File(p.join(baseDir.path, 'media', 'video_1_thumb.webp'));

      expect(restoredPhoto.existsSync(), isTrue);
      expect(
        restoredPhoto.readAsBytesSync(),
        equals([0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4]),
      );
      expect(restoredVideo.existsSync(), isTrue);
      expect(restoredThumb.existsSync(), isTrue);
    });

    test('supports unencrypted backup and restore when passphrase is null', () async {
      await seedRichDatabaseAndMedia();
      final backupFile = File(p.join(tempDir.path, 'plain_backup.mdbak'));

      final createRes = await backupService.createBackup(
        destination: backupFile,
        passphrase: null,
      );
      expect(createRes.isEncrypted, isFalse);

      final inspection = await backupService.inspectBackup(backupFile);
      expect(inspection.isEncrypted, isFalse);

      await db.delete(db.mediaAttachments).go();
      await db.delete(db.entries).go();

      final restoreRes = await backupService.restoreBackup(
        source: backupFile,
        passphrase: null,
      );
      expect(restoreRes.entriesRestored, 4);
      expect(await db.getEntryById('entry_active_1'), isNotNull);
    });
  });

  group('BackupRestoreService — Atomic Rollback & Security Guards', () {
    test('wrong passphrase rejects before modifying live database or media', () async {
      await seedRichDatabaseAndMedia();
      final backupFile = File(p.join(tempDir.path, 'protected.mdbak'));

      await backupService.createBackup(
        destination: backupFile,
        passphrase: 'correct-password',
        pbkdf2Iterations: 1000,
      );

      // Add a post-backup entry that must survive a failed restore
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'must_survive_entry',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Do Not Lose Me'),
          contentDelta: '[{"insert":"Important local data\\n"}]',
          plainText: 'Important local data',
          entryDate: DateTime(2026, 10, 19),
        ),
      );

      await expectLater(
        () => backupService.restoreBackup(
          source: backupFile,
          passphrase: 'wrong-password',
        ),
        throwsA(isA<WrongPassphraseException>()),
      );

      // Verify live database & media were not touched
      expect(await db.getEntryById('must_survive_entry'), isNotNull);
      expect(
        File(p.join(baseDir.path, 'media', 'photo_1.webp')).existsSync(),
        isTrue,
      );
    });

    test('corrupted media SHA-256 in archive aborts before touching live database or media', () async {
      await seedRichDatabaseAndMedia();

      // Build a tampered unencrypted .mdbak where photo_1.webp bytes don't match manifest sha256
      final snapshot = await db.exportAllTablesSnapshot();
      final manifest = BackupManifest(
        appSchemaVersion: 2,
        createdAt: DateTime.now().toUtc(),
        snapshot: snapshot,
        mediaFiles: const [
          BackupMediaRecord(
            relativePath: 'media/photo_1.webp',
            sha256: '0000000000000000000000000000000000000000000000000000000000000000',
            sizeBytes: 8,
          ),
        ],
      );
      final manifestStr = manifest.toJsonString();
      final manifestSha =
          crypto.sha256.convert(utf8.encode(manifestStr)).toString();

      final badZip = File(p.join(tempDir.path, 'bad_media.zip'));
      final encoder = ZipFileEncoder();
      encoder.create(badZip.path);
      encoder.addArchiveFile(ArchiveFile.string('manifest.json', manifestStr));
      encoder.addArchiveFile(ArchiveFile.string('manifest.sha256', manifestSha));
      encoder.addArchiveFile(
        ArchiveFile.bytes('media/photo_1.webp', [1, 2, 3, 4, 5, 6, 7, 8]),
      );
      await encoder.close();

      final badMdbak = File(p.join(tempDir.path, 'bad_media.mdbak'));
      await BackupCrypto.wrapUnencryptedZip(
        sourceZip: badZip,
        destination: badMdbak,
      );

      await expectLater(
        () => backupService.restoreBackup(source: badMdbak),
        throwsA(isA<BackupCorruptedException>()),
      );

      // Live photo_1.webp still has its original bytes
      expect(
        File(p.join(baseDir.path, 'media', 'photo_1.webp')).readAsBytesSync(),
        equals([0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4]),
      );
    });

    test('mid-transaction SQLite failure (foreign key violation) rolls back cleanly leaving existing DB and media intact', () async {
      await seedRichDatabaseAndMedia();

      // Construct an archive with valid SHA-256 hashes but an entry referencing a non-existent notebook
      final invalidEntry = Entry(
        id: 'bad_fk_entry',
        notebookId: 'non_existent_notebook_id',
        templateId: 'template_minimalist_white',
        title: 'Broken FK',
        contentDelta: '[{"insert":"broken\\n"}]',
        plainText: 'broken',
        entryDate: DateTime.utc(2026, 10, 19),
        isWeeklyReview: false,
        createdAt: DateTime.utc(2026, 10, 19),
        updatedAt: DateTime.utc(2026, 10, 19),
        isDeleted: false,
        isLocked: false,
      );

      final badSnapshot = BackupDatabaseSnapshot(
        templates: const [],
        notebooks: const [],
        entries: [invalidEntry],
        mediaAttachments: const [],
      );
      final manifest = BackupManifest(
        appSchemaVersion: 2,
        createdAt: DateTime.now().toUtc(),
        snapshot: badSnapshot,
        mediaFiles: const [],
      );
      final manifestStr = manifest.toJsonString();
      final manifestSha =
          crypto.sha256.convert(utf8.encode(manifestStr)).toString();

      final zipFile = File(p.join(tempDir.path, 'bad_fk.zip'));
      final encoder = ZipFileEncoder();
      encoder.create(zipFile.path);
      encoder.addArchiveFile(ArchiveFile.string('manifest.json', manifestStr));
      encoder.addArchiveFile(ArchiveFile.string('manifest.sha256', manifestSha));
      await encoder.close();

      final mdbakFile = File(p.join(tempDir.path, 'bad_fk.mdbak'));
      await BackupCrypto.wrapUnencryptedZip(
        sourceZip: zipFile,
        destination: mdbakFile,
      );

      await expectLater(
        () => backupService.restoreBackup(source: mdbakFile),
        throwsA(isA<BackupCorruptedException>()),
      );

      // Pre-restore entries and media must remain completely intact!
      expect(await db.getEntryById('entry_active_1'), isNotNull);
      expect(await db.getEntryById('entry_locked_2'), isNotNull);
      expect(
        File(p.join(baseDir.path, 'media', 'photo_1.webp')).existsSync(),
        isTrue,
      );
    });

    test('rejects Zip-Slip path traversal entry (../evil.webp)', () async {
      final zipFile = File(p.join(tempDir.path, 'zip_slip.zip'));
      final encoder = ZipFileEncoder();
      encoder.create(zipFile.path);
      encoder.addArchiveFile(ArchiveFile.bytes('../evil.webp', [1, 2, 3]));
      await encoder.close();

      final mdbakFile = File(p.join(tempDir.path, 'zip_slip.mdbak'));
      await BackupCrypto.wrapUnencryptedZip(
        sourceZip: zipFile,
        destination: mdbakFile,
      );

      await expectLater(
        () => backupService.restoreBackup(source: mdbakFile),
        throwsA(isA<BackupCorruptedException>()),
      );
    });
  });
}

