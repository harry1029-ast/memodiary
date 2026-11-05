import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/import_export/services/backup_restore_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late AppDatabase db;
  late Directory baseDir;
  late Directory tempDir;
  late BackupRestoreService backupService;

  const webpBytes = <int>[
    0x52, 0x49, 0x46, 0x46, 0x14, 0x00, 0x00, 0x00,
    0x57, 0x45, 0x42, 0x50, 0x56, 0x50, 0x38, 0x20,
    0x08, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04,
  ];

  setUp(() {
    db = AppDatabase.memory();
    baseDir = Directory.systemTemp.createTempSync('memodiary_mount_bak_base_');
    tempDir = Directory.systemTemp.createTempSync('memodiary_mount_bak_temp_');
    backupService = BackupRestoreService(
      database: db,
      mediaService: MediaSandboxService(baseDirProvider: () async => baseDir),
      tempDirProvider: () async => tempDir,
      baseDirProvider: () async => baseDir,
    );
  });

  tearDown(() async {
    await db.close();
    for (final dir in [baseDir, tempDir]) {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    }
  });

  test('backup → restore round-trips mount markers, staged items, captions and the legacy flag', () async {
    final mediaDir = Directory(p.join(baseDir.path, 'media'))..createSync(recursive: true);
    for (final name in ['mounted', 'staged', 'legacy']) {
      File(p.join(mediaDir.path, '$name.webp')).writeAsBytesSync(webpBytes);
    }
    final createdAt = DateTime(2026, 11, 5, 10);

    Future<void> insertEntry(String id, String delta, {bool legacyPending = false}) {
      return db.createEntry(EntriesCompanion.insert(
        id: id,
        notebookId: 'notebook_default',
        templateId: 'template_lined_paper',
        contentDelta: delta,
        plainText: '西湖泛舟',
        entryDate: createdAt,
        createdAt: Value(createdAt),
        updatedAt: Value(createdAt),
        legacyMountsPending: Value(legacyPending),
      ));
    }

    Future<void> insertMedia(String id, String entryId, {String? caption}) {
      return db.into(db.mediaAttachments).insert(MediaAttachmentsCompanion.insert(
            id: id,
            entryId: entryId,
            mediaType: 'image',
            relativePath: 'media/$id.webp',
            caption: Value(caption),
            createdAt: Value(createdAt),
          ));
    }

    await insertEntry(
      'entry_mounted',
      '[{"insert":"西湖泛舟"},{"insert":{"mount":"mounted"}},{"insert":"\\n"}]',
    );
    await insertMedia('mounted', 'entry_mounted', caption: '断桥残雪');
    await insertMedia('staged', 'entry_mounted', caption: '待贴一影');
    await insertEntry('entry_legacy', '[{"insert":"旧日\\n"}]', legacyPending: true);
    await insertMedia('legacy', 'entry_legacy');

    final before = await db.exportAllTablesSnapshot();
    final backupFile = File(p.join(tempDir.path, 'mounts.mdbak'));
    await backupService.createBackup(destination: backupFile);

    await db.delete(db.mediaAttachments).go();
    await db.delete(db.entries).go();

    await backupService.restoreBackup(source: backupFile);
    final after = await db.exportAllTablesSnapshot();

    expect(after.entries, equals(before.entries));
    expect(after.mediaAttachments, equals(before.mediaAttachments));
    final byId = {for (final entry in after.entries) entry.id: entry};
    expect(byId['entry_mounted']!.contentDelta, contains('{"mount":"mounted"}'));
    expect(byId['entry_mounted']!.legacyMountsPending, isFalse);
    expect(byId['entry_legacy']!.legacyMountsPending, isTrue);
    expect(
      {for (final media in after.mediaAttachments) media.id: media.caption},
      equals({'mounted': '断桥残雪', 'staged': '待贴一影', 'legacy': null}),
    );
  });
}
