import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/auth_service.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/import_export/models/backup_manifest.dart';
import 'package:memodiary/features/import_export/services/backup_restore_service.dart';
import 'package:memodiary/features/search/services/natural_language_search_parser.dart';
import 'package:path/path.dart' as p;

void main() {
  late AppDatabase db;
  late Directory baseDir;
  late Directory tempDir;
  late MediaSandboxService mediaService;
  late BackupRestoreService backupService;
  late AuthService authService;

  late Uint8List photoBytes;
  late Uint8List videoBytes;
  late Uint8List thumbBytes;

  late String photoSha;
  late String videoSha;
  late String thumbSha;

  String computeSha256(List<int> bytes) =>
      crypto.sha256.convert(bytes).toString();

  Uint8List generateDeterministicMp4Payload(int totalBytes) {
    // 32-byte standard MP4 ftyp box header (Watchpoint 2)
    const ftypHeader = <int>[
      0x00, 0x00, 0x00, 0x20, // size = 32
      0x66, 0x74, 0x79, 0x70, // 'ftyp'
      0x69, 0x73, 0x6f, 0x6d, // major_brand = 'isom'
      0x00, 0x00, 0x02, 0x00, // minor_version = 512
      0x69, 0x73, 0x6f, 0x6d, // compatible_brands: 'isom'
      0x69, 0x73, 0x6f, 0x32, // 'iso2'
      0x61, 0x76, 0x63, 0x31, // 'avc1'
      0x6d, 0x70, 0x34, 0x31, // 'mp41'
    ];
    assert(ftypHeader.length == 32);

    final bytes = Uint8List(totalBytes);
    bytes.setRange(0, 32, ftypHeader);

    final rand = Random(2026);
    for (var i = 32; i < totalBytes; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return bytes;
  }

  Uint8List generateDeterministicWebpPayload(int totalBytes, int seed) {
    final bytes = Uint8List(totalBytes);
    // RIFF / WEBP container header
    bytes[0] = 0x52; // R
    bytes[1] = 0x49; // I
    bytes[2] = 0x46; // F
    bytes[3] = 0x46; // F
    final fileSizeMinus8 = totalBytes - 8;
    bytes[4] = fileSizeMinus8 & 0xFF;
    bytes[5] = (fileSizeMinus8 >> 8) & 0xFF;
    bytes[6] = (fileSizeMinus8 >> 16) & 0xFF;
    bytes[7] = (fileSizeMinus8 >> 24) & 0xFF;
    bytes[8] = 0x57; // W
    bytes[9] = 0x45; // E
    bytes[10] = 0x42; // B
    bytes[11] = 0x50; // P
    final rand = Random(seed);
    for (var i = 12; i < totalBytes; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return bytes;
  }

  setUp(() {
    db = AppDatabase.memory();
    baseDir = Directory.systemTemp.createTempSync('memodiary_e2e_base_');
    tempDir = Directory.systemTemp.createTempSync('memodiary_e2e_temp_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => baseDir,
    );
    backupService = BackupRestoreService(
      database: db,
      mediaService: mediaService,
      tempDirProvider: () async => tempDir,
    );
    authService = AuthService();

    // Generate physical media payloads
    // 200 KiB WebP photo
    photoBytes = generateDeterministicWebpPayload(200 * 1024, 101);
    // 2.5 MiB MP4 video crossing 1 MiB chunk boundaries
    videoBytes = generateDeterministicMp4Payload((2.5 * 1024 * 1024).round());
    // 10 KiB WebP video poster thumbnail
    thumbBytes = generateDeterministicWebpPayload(10 * 1024, 102);

    photoSha = computeSha256(photoBytes);
    videoSha = computeSha256(videoBytes);
    thumbSha = computeSha256(thumbBytes);
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

  Future<void> seedAllProductionInvariants() async {
    // 1. Custom Template
    await db.createCustomTemplate(
      id: 'template_custom_rc_grid',
      name: 'RC Vintage Grid',
      backgroundType: 'grid',
      backgroundValue: '#FAF6F0',
      fontFamily: 'Serif',
      lineSpacing: 1.6,
      marginHorizontal: 24.0,
    );

    // 2. Custom Notebook
    await db.into(db.notebooks).insert(
          NotebooksCompanion.insert(
            id: 'notebook_rc_2026',
            title: '2026 拾光纪事',
            defaultTemplateId: 'template_custom_rc_grid',
          ),
        );

    // 3. Entry 1 (Active Multimodal + NL Target)
    await db.createEntry(
      EntriesCompanion.insert(
        id: 'entry_rc_01',
        notebookId: 'notebook_rc_2026',
        templateId: 'template_custom_rc_grid',
        title: const Value('京都秋日旅行'),
        contentDelta: '[{"insert":"去年国庆在京都旅行，晴天拍了枫叶照片和短视频。\\n"}]',
        plainText: '去年国庆在京都旅行，晴天拍了枫叶照片和短视频。',
        entryDate: DateTime(2025, 10, 3, 14, 30),
        mood: const Value(5),
        weather: const Value('sunny'),
        isWeeklyReview: const Value(false),
        isDeleted: const Value(false),
      ),
    );

    // 4. Entry 2 (Soft-Deleted Recycle Bin)
    await db.createEntry(
      EntriesCompanion.insert(
        id: 'entry_rc_02',
        notebookId: 'notebook_rc_2026',
        templateId: 'template_custom_rc_grid',
        title: const Value('已删除的草稿'),
        contentDelta: '[{"insert":"回收站保留三十天测试内容\\n"}]',
        plainText: '回收站保留三十天测试内容',
        entryDate: DateTime(2026, 9, 15, 10, 0),
        isDeleted: const Value(true),
      ),
    );

    // 5. Entry 3 (Single-Entry PIN-Locked)
    final pinHash = authService.hashEntryPin('8426');
    await db.createEntry(
      EntriesCompanion.insert(
        id: 'entry_rc_03',
        notebookId: 'notebook_rc_2026',
        templateId: 'template_custom_rc_grid',
        title: const Value('加密私密日记'),
        contentDelta: '[{"insert":"只有独立密码才能查看的正文\\n"}]',
        plainText: '只有独立密码才能查看的正文',
        entryDate: DateTime(2026, 10, 1, 21, 0),
        isLocked: const Value(true),
        entryPinHash: Value(pinHash),
      ),
    );

    // 6. Entry 4 (Sealed Time Capsule)
    await db.createEntry(
      EntriesCompanion.insert(
        id: 'entry_rc_04',
        notebookId: 'notebook_rc_2026',
        templateId: 'template_custom_rc_grid',
        title: const Value('给未来的信'),
        contentDelta: '[{"insert":"时间胶囊未解锁绝对机密令牌\\n"}]',
        plainText: '时间胶囊未解锁绝对机密令牌',
        entryDate: DateTime(2026, 10, 5, 18, 0),
        unlockAt: Value(DateTime(2027, 10, 19, 0, 0)),
      ),
    );

    // 7. Entry 5 (Weekly Review)
    await db.createEntry(
      EntriesCompanion.insert(
        id: 'entry_rc_05',
        notebookId: 'notebook_rc_2026',
        templateId: 'template_custom_rc_grid',
        title: const Value('十月第二周复盘'),
        contentDelta: '[{"insert":"本周工作与运动复盘总结\\n"}]',
        plainText: '本周工作与运动复盘总结',
        entryDate: DateTime(2026, 10, 11, 20, 0),
        isWeeklyReview: const Value(true),
        weekNumber: const Value(41),
      ),
    );

    // 8. Entry 6 (Event-Tagged Active Entry)
    await db.createEntry(
      EntriesCompanion.insert(
        id: 'entry_rc_06',
        notebookId: 'notebook_rc_2026',
        templateId: 'template_custom_rc_grid',
        title: const Value('京都咖啡小馆'),
        contentDelta: '[{"insert":"在京都品尝手冲咖啡。\\n"}]',
        plainText: '在京都品尝手冲咖啡。',
        entryDate: DateTime(2026, 10, 12, 15, 0),
        mood: const Value(4),
        weather: const Value('cloudy'),
      ),
    );

    // 9. Write Physical Media Files to Sandbox
    final mediaDir = Directory(p.join(baseDir.path, 'media'))
      ..createSync(recursive: true);

    File(p.join(mediaDir.path, 'rc_photo_01.webp')).writeAsBytesSync(photoBytes);
    File(p.join(mediaDir.path, 'rc_video_01.mp4')).writeAsBytesSync(videoBytes);
    File(p.join(mediaDir.path, 'rc_video_01_thumb.webp'))
        .writeAsBytesSync(thumbBytes);

    // 10. Relational Media Attachments
    await db.attachMediaToEntry(
      id: 'media_rc_photo_1',
      entryId: 'entry_rc_01',
      relativePath: 'media/rc_photo_01.webp',
      mediaType: 'image',
    );
    await db.attachMediaToEntry(
      id: 'media_rc_video_1',
      entryId: 'entry_rc_01',
      relativePath: 'media/rc_video_01.mp4',
      mediaType: 'video',
      thumbnailPath: 'media/rc_video_01_thumb.webp',
    );
  }

  group('Phase 10 — End-to-End Disaster Recovery Hardening Suite', () {
    test('Scenario A: In-Place Total Wipe & Encrypted Restore (2.5 MiB payload, 100% parity)',
        () async {
      await seedAllProductionInvariants();
      final backupFile =
          File(p.join(tempDir.path, 'full_disaster_recovery.mdbak'));
      const passphrase = 'ReleaseCandidatePassphrase2026!';

      // 1. Capture snapshot before backup
      final preBackupSnapshot = await db.exportAllTablesSnapshot();
      expect(preBackupSnapshot.entries.length, 6);
      expect(preBackupSnapshot.templates.length, 5); // 4 default + 1 custom
      expect(preBackupSnapshot.notebooks.length, 2); // 1 default + 1 custom
      expect(preBackupSnapshot.mediaAttachments.length, 2);

      // 2. Create encrypted backup bundle
      final backupResult = await backupService.createBackup(
        destination: backupFile,
        passphrase: passphrase,
        pbkdf2Iterations: 2000,
      );
      expect(backupFile.existsSync(), isTrue);
      expect(backupResult.mediaFilesCount, 3); // 1 photo, 1 video, 1 poster thumb
      expect(backupResult.isEncrypted, isTrue);
      // Backup size must exceed 2.5 MiB
      expect(backupResult.totalBytes, greaterThan(2.5 * 1024 * 1024));

      // 3. Simulate Catastrophic Device Wipe
      await (db.delete(db.mediaAttachments)).go();
      await (db.delete(db.entries)).go();
      await db.customStatement('DELETE FROM entries_fts;');
      await (db.delete(db.notebooks)).go();
      await (db.delete(db.templates)).go();

      final mediaDir = Directory(p.join(baseDir.path, 'media'));
      if (mediaDir.existsSync()) {
        mediaDir.deleteSync(recursive: true);
      }

      // Assert database and media sandbox are completely empty
      final emptySnapshot = await db.exportAllTablesSnapshot();
      expect(emptySnapshot.entries, isEmpty);
      expect(emptySnapshot.templates, isEmpty);
      expect(emptySnapshot.notebooks, isEmpty);
      expect(emptySnapshot.mediaAttachments, isEmpty);
      final emptyMediaFiles = mediaDir.existsSync()
          ? mediaDir.listSync(recursive: true).whereType<File>().toList()
          : <File>[];
      expect(emptyMediaFiles, isEmpty);

      // 4. Execute Atomic Restore from Encrypted Backup
      final restoreResult = await backupService.restoreBackup(
        source: backupFile,
        passphrase: passphrase,
      );

      expect(restoreResult.entriesRestored, 6);
      expect(restoreResult.templatesRestored, 5);
      expect(restoreResult.notebooksRestored, 2);
      expect(restoreResult.mediaFilesRestored, 3);

      // 5. Assert 100% Relational Field Parity
      final restoredSnapshot = await db.exportAllTablesSnapshot();
      expect(restoredSnapshot.entries.length, 6);
      expect(restoredSnapshot.templates.length, 5);
      expect(restoredSnapshot.notebooks.length, 2);
      expect(restoredSnapshot.mediaAttachments.length, 2);

      // Verify all 6 entries have 100% field parity against preBackupSnapshot
      for (final preEntry in preBackupSnapshot.entries) {
        final restoredEntry = restoredSnapshot.entries
            .firstWhere((e) => e.id == preEntry.id);
        expect(restoredEntry.notebookId, preEntry.notebookId);
        expect(restoredEntry.templateId, preEntry.templateId);
        expect(restoredEntry.title, preEntry.title);
        expect(restoredEntry.contentDelta, preEntry.contentDelta);
        expect(restoredEntry.plainText, preEntry.plainText);
        expect(restoredEntry.entryDate.millisecondsSinceEpoch,
            preEntry.entryDate.millisecondsSinceEpoch);
        expect(restoredEntry.mood, preEntry.mood);
        expect(restoredEntry.weather, preEntry.weather);
        expect(restoredEntry.isWeeklyReview, preEntry.isWeeklyReview);
        expect(restoredEntry.weekNumber, preEntry.weekNumber);
        expect(restoredEntry.isDeleted, preEntry.isDeleted);
        expect(restoredEntry.isLocked, preEntry.isLocked);
        expect(restoredEntry.entryPinHash, preEntry.entryPinHash);
        expect(
          restoredEntry.unlockAt?.millisecondsSinceEpoch,
          preEntry.unlockAt?.millisecondsSinceEpoch,
        );
      }

      // Verify all media attachments have 100% field parity against preBackupSnapshot
      for (final preMedia in preBackupSnapshot.mediaAttachments) {
        final restoredMedia = restoredSnapshot.mediaAttachments
            .firstWhere((m) => m.id == preMedia.id);
        expect(restoredMedia.entryId, preMedia.entryId);
        expect(restoredMedia.mediaType, preMedia.mediaType);
        expect(restoredMedia.relativePath, preMedia.relativePath);
        expect(restoredMedia.thumbnailPath, preMedia.thumbnailPath);
        expect(restoredMedia.ocrText, preMedia.ocrText);
      }

      // Verify custom template
      final customTpl =
          await db.getTemplateById('template_custom_rc_grid');
      expect(customTpl, isNotNull);
      expect(customTpl!.name, 'RC Vintage Grid');
      expect(customTpl.backgroundType, 'grid');
      expect(customTpl.backgroundValue, '#FAF6F0');
      expect(customTpl.fontFamily, 'Serif');
      expect(customTpl.lineSpacing, 1.6);
      expect(customTpl.marginHorizontal, 24.0);
      expect(customTpl.isCustom, isTrue);

      // Verify custom notebook
      final customNb = await (db.select(db.notebooks)
            ..where((tbl) => tbl.id.equals('notebook_rc_2026')))
          .getSingleOrNull();
      expect(customNb, isNotNull);
      expect(customNb!.title, '2026 拾光纪事');
      expect(customNb.defaultTemplateId, 'template_custom_rc_grid');

      // 6. Assert 100% Physical Byte-Digest Parity
      final restoredPhoto =
          File(p.join(baseDir.path, 'media', 'rc_photo_01.webp'));
      final restoredVideo =
          File(p.join(baseDir.path, 'media', 'rc_video_01.mp4'));
      final restoredThumb =
          File(p.join(baseDir.path, 'media', 'rc_video_01_thumb.webp'));

      expect(restoredPhoto.existsSync(), isTrue);
      expect(restoredVideo.existsSync(), isTrue);
      expect(restoredThumb.existsSync(), isTrue);

      expect(computeSha256(restoredPhoto.readAsBytesSync()), photoSha);
      expect(computeSha256(restoredVideo.readAsBytesSync()), videoSha);
      expect(computeSha256(restoredThumb.readAsBytesSync()), thumbSha);

      // 7. Assert Non-Duplicate FTS5 Row Count
      final ftsRows = await db
          .customSelect('SELECT count(*) as cnt FROM entries_fts')
          .getSingle();
      final ftsCount = ftsRows.data['cnt'] as int;
      expect(ftsCount, 6,
          reason: 'FTS5 index must have exactly 1 row per entry with zero duplicates');

      // 8. Assert SQLite FTS5 Keyword Search Parity
      final searchKyoto =
          await db.searchEntriesWithFilters(query: '京都');
      final kyotoIds = searchKyoto.map((e) => e.id).toSet();
      expect(kyotoIds, containsAll(['entry_rc_01', 'entry_rc_06']));

      // 9. Assert CJK LIKE Substring Fallback
      final searchTravel =
          await db.searchEntriesWithFilters(query: '旅行');
      final travelIds = searchTravel.map((e) => e.id).toList();
      expect(travelIds, contains('entry_rc_01'));

      // 10. Assert Natural Language Multi-Constraint Search
      final nlRefDate = DateTime(2026, 10, 19);
      const nlParser = NaturalLanguageSearchParser();
      final parsedNlQuery = nlParser.parse(
        '去年国庆 晴天 带图',
        now: nlRefDate,
      );
      final nlResults = await db.searchEntriesWithFilters(
        query: parsedNlQuery.keywords,
        startDate: parsedNlQuery.startDate,
        endDate: parsedNlQuery.endDate,
        mood: null,
        weather: parsedNlQuery.weather,
        hasImage: parsedNlQuery.hasImage,
        weeklyReviewOnly: parsedNlQuery.weeklyReviewOnly,
        excludeSealedTimeCapsules: true,
      );
      expect(nlResults.length, 1);
      expect(nlResults.first.id, 'entry_rc_01');

      // Weekly review NL query
      final parsedWeekly = nlParser.parse(
        '10月所有周记',
        now: nlRefDate,
      );
      final weeklyResults = await db.searchEntriesWithFilters(
        query: parsedWeekly.keywords,
        startDate: parsedWeekly.startDate,
        endDate: parsedWeekly.endDate,
        weeklyReviewOnly: parsedWeekly.weeklyReviewOnly,
        excludeSealedTimeCapsules: true,
      );
      expect(weeklyResults.length, 1);
      expect(weeklyResults.first.id, 'entry_rc_05');

      // 11. Assert Privacy Invariants (Sealed Capsules & Recycle Bin Excluded)
      final secretSearchResults = await db.searchEntriesWithFilters(
        query: '绝对机密令牌',
        excludeSealedTimeCapsules: true,
      );
      expect(secretSearchResults, isEmpty,
          reason: 'Sealed time capsules must never leak into search results');

      final trashSearchResults = await db.searchEntriesWithFilters(
        query: '回收站保留',
      );
      expect(trashSearchResults, isEmpty,
          reason: 'Soft-deleted recycle bin entries must never appear in active search');

      // 12. Assert Single-Entry PIN Authentication
      final restoredLockedEntry = await (db.select(db.entries)
            ..where((tbl) => tbl.id.equals('entry_rc_03')))
          .getSingle();
      expect(restoredLockedEntry.isLocked, isTrue);
      expect(restoredLockedEntry.entryPinHash, isNotNull);
      expect(
        authService.verifyEntryPin('8426', restoredLockedEntry.entryPinHash!),
        isTrue,
        reason: 'Restored entry PIN hash must verify with the correct PIN',
      );
      expect(
        authService.verifyEntryPin('0000', restoredLockedEntry.entryPinHash!),
        isFalse,
        reason: 'Restored entry PIN hash must reject incorrect PIN',
      );
    });

    test('Scenario B: Fresh-Device Restore with Default Schema Pre-Seeding',
        () async {
      await seedAllProductionInvariants();
      final backupFile =
          File(p.join(tempDir.path, 'fresh_device_backup.mdbak'));
      const passphrase = 'ReleaseCandidatePassphrase2026!';

      await backupService.createBackup(
        destination: backupFile,
        passphrase: passphrase,
        pbkdf2Iterations: 2000,
      );

      // Create a brand new database and new sandbox directory (simulating new install)
      final freshDb = AppDatabase.memory();
      final freshBaseDir =
          Directory.systemTemp.createTempSync('memodiary_fresh_base_');
      final freshMediaService = MediaSandboxService(
        baseDirProvider: () async => freshBaseDir,
      );
      final freshBackupService = BackupRestoreService(
        database: freshDb,
        mediaService: freshMediaService,
        tempDirProvider: () async => tempDir,
      );

      addTearDown(() async {
        await freshDb.close();
        if (freshBaseDir.existsSync()) {
          freshBaseDir.deleteSync(recursive: true);
        }
      });

      // Fresh database starts with 4 default templates and 1 default notebook
      final initialTemplates = await freshDb.getAllTemplates();
      expect(initialTemplates.length, 4);
      final initialNotebooks = await freshDb.select(freshDb.notebooks).get();
      expect(initialNotebooks.length, 1);

      // Restore into fresh install
      final res = await freshBackupService.restoreBackup(
        source: backupFile,
        passphrase: passphrase,
      );
      expect(res.entriesRestored, 6);
      expect(res.mediaFilesRestored, 3);

      final freshCustomTpl =
          await freshDb.getTemplateById('template_custom_rc_grid');
      expect(freshCustomTpl, isNotNull);
      expect(freshCustomTpl!.name, 'RC Vintage Grid');

      final freshTemplates = await freshDb.getAllTemplates();
      expect(freshTemplates.length, 5,
          reason: 'Must contain 4 default templates and 1 restored custom template without duplicates');

      // Assert restored notebooks count and custom notebook parity
      final freshNotebooks = await freshDb.select(freshDb.notebooks).get();
      expect(freshNotebooks.length, 2,
          reason: 'Must contain both default notebook and restored custom notebook');
      final customNotebook =
          freshNotebooks.firstWhere((nb) => nb.id == 'notebook_rc_2026');
      expect(customNotebook.title, '2026 拾光纪事');
      expect(customNotebook.defaultTemplateId, 'template_custom_rc_grid');

      final freshEntries = await freshDb.select(freshDb.entries).get();
      expect(freshEntries.length, 6);

      // Media files exist in fresh sandbox
      final freshVideo =
          File(p.join(freshBaseDir.path, 'media', 'rc_video_01.mp4'));
      expect(freshVideo.existsSync(), isTrue);
      expect(computeSha256(freshVideo.readAsBytesSync()), videoSha);
    });

    test('Scenario C: Wrong Passphrase Defense Leaves Target Data Untouched',
        () async {
      await seedAllProductionInvariants();
      final backupFile =
          File(p.join(tempDir.path, 'wrong_passphrase_test.mdbak'));
      const correctPassphrase = 'ReleaseCandidatePassphrase2026!';

      await backupService.createBackup(
        destination: backupFile,
        passphrase: correctPassphrase,
        pbkdf2Iterations: 2000,
      );

      final preWipeEntries = await db.select(db.entries).get();
      expect(preWipeEntries.length, 6);

      // Attempt restore with wrong password
      expect(
        () => backupService.restoreBackup(
          source: backupFile,
          passphrase: 'WrongPassphrase2026!',
        ),
        throwsA(isA<WrongPassphraseException>()),
      );

      // Target database and media must remain 100% intact
      final postAttemptEntries = await db.select(db.entries).get();
      expect(postAttemptEntries.length, 6);

      final photo = File(p.join(baseDir.path, 'media', 'rc_photo_01.webp'));
      expect(photo.existsSync(), isTrue);
      expect(computeSha256(photo.readAsBytesSync()), photoSha);
    });
  });
}
