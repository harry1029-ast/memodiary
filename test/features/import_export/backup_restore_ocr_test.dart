import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart' show Value;
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

  // Deterministic WebP RIFF header fixture
  const webpBytes = <int>[
    0x52, 0x49, 0x46, 0x46, 0x14, 0x00, 0x00, 0x00,
    0x57, 0x45, 0x42, 0x50, 0x56, 0x50, 0x38, 0x20,
    0x08, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04,
  ];

  setUp(() {
    db = AppDatabase.memory();
    baseDir = Directory.systemTemp.createTempSync('memodiary_ocr_bak_base_');
    tempDir = Directory.systemTemp.createTempSync('memodiary_ocr_bak_temp_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => baseDir,
    );
    backupService = BackupRestoreService(
      database: db,
      mediaService: mediaService,
      tempDirProvider: () async => tempDir,
      baseDirProvider: () async => baseDir,
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

  group('Backup & Restore OCR Field Parity & Backward Compatibility (v5)', () {
    test(
      'encrypted round-trip preserves 100% deep field parity for OCR columns and rebuilds deduplicated media_fts',
      () async {
        final mediaDir = Directory(p.join(baseDir.path, 'media'))
          ..createSync(recursive: true);
        for (final fileName in [
          'entry_ticket.webp',
          'entry_ticket_thumb.webp',
          'entry_scenery.webp',
          'album_menu.webp',
          'album_menu_thumb.webp',
        ]) {
          File(p.join(mediaDir.path, fileName)).writeAsBytesSync(webpBytes);
        }

        final entryDate = DateTime(2026, 10, 20, 14, 30);
        final createdAt = DateTime(2026, 10, 20, 14, 35);
        final shotAt = DateTime(2026, 10, 20, 12, 15);

        await db.createEntry(
          EntriesCompanion.insert(
            id: 'entry_ocr_1',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Lingyin Temple Visit'),
            contentDelta: '[{"insert":"Temple ticket and mountain view.\\n"}]',
            plainText: 'Temple ticket and mountain view.',
            entryDate: entryDate,
            mood: const Value(5),
            weather: const Value('sunny'),
            createdAt: Value(createdAt),
            updatedAt: Value(createdAt),
          ),
        );

        const ticketBlocksJson =
            '[{"text":"灵隐飞来峰门票 45元","box":[0.11,0.22,0.75,0.09]}]';
        await db.into(db.mediaAttachments).insert(
              MediaAttachmentsCompanion.insert(
                id: 'att_ticket_1',
                entryId: 'entry_ocr_1',
                mediaType: 'image',
                relativePath: 'media/entry_ticket.webp',
                thumbnailPath: const Value('media/entry_ticket_thumb.webp'),
                ocrText: const Value('灵隐飞来峰门票 45元'),
                ocrBlocksJson: const Value(ticketBlocksJson),
                createdAt: Value(createdAt),
              ),
            );

        // Sentinel attachment (scanned with zero words)
        await db.into(db.mediaAttachments).insert(
              MediaAttachmentsCompanion.insert(
                id: 'att_scenery_sentinel',
                entryId: 'entry_ocr_1',
                mediaType: 'image',
                relativePath: 'media/entry_scenery.webp',
                ocrText: const Value(''),
                ocrBlocksJson: const Value('[]'),
                createdAt: Value(createdAt),
              ),
            );

        await db.into(db.albumCollections).insert(
              AlbumCollectionsCompanion.insert(
                id: 'col_ocr_1',
                title: '杭州寻味录',
                description: const Value('茶馆与老街'),
                destinationTag: const Value('杭州'),
                routeSummary: const Value('灵隐 → 龙井'),
                coverImagePath: const Value('media/album_menu.webp'),
                createdAt: Value(createdAt),
                updatedAt: Value(createdAt),
              ),
            );

        const menuBlocksJson =
            '[{"text":"狮峰龙井明前特级","box":[0.15,0.3,0.6,0.08]}]';
        await db.into(db.albumPhotos).insert(
              AlbumPhotosCompanion.insert(
                id: 'photo_menu_1',
                collectionId: 'col_ocr_1',
                relativeImagePath: 'media/album_menu.webp',
                relativeThumbnailPath: 'media/album_menu_thumb.webp',
                caption: const Value('山中茶席'),
                locationTag: const Value('龙井村'),
                shotAt: Value(shotAt),
                sortOrder: const Value(2),
                aspectRatio: const Value(1.33),
                ocrText: const Value('狮峰龙井明前特级'),
                ocrBlocksJson: const Value(menuBlocksJson),
                createdAt: Value(createdAt),
              ),
            );

        final preBackupSnapshot = await db.exportAllTablesSnapshot();
        final backupFile = File(p.join(tempDir.path, 'v5_ocr_roundtrip.mdbak'));

        await backupService.createBackup(
          destination: backupFile,
          passphrase: 'ocr-vault-passphrase',
          pbkdf2Iterations: 1000,
        );

        // Inject a stale phantom row directly into media_fts before restore to prove replaceAllFromBackup clears media_fts
        await db.customStatement('''
          INSERT INTO media_fts(id, source_type, parent_id, relative_path, ocr_text)
          VALUES ('stale_phantom_id', 'entry_media', 'missing_entry', 'media/ghost.webp', 'PhantomStaleToken');
        ''');

        await backupService.restoreBackup(
          source: backupFile,
          passphrase: 'ocr-vault-passphrase',
        );

        final postRestoreSnapshot = await db.exportAllTablesSnapshot();

        // Deep field parity on Entry
        expect(
          postRestoreSnapshot.entries.single,
          equals(preBackupSnapshot.entries.single),
        );

        // Deep field parity on MediaAttachments (both populated OCR & empty sentinel)
        expect(
          postRestoreSnapshot.mediaAttachments,
          equals(preBackupSnapshot.mediaAttachments),
        );

        // Deep field parity on AlbumCollection & AlbumPhoto
        expect(
          postRestoreSnapshot.albumCollections.single,
          equals(preBackupSnapshot.albumCollections.single),
        );
        expect(
          postRestoreSnapshot.albumPhotos.single,
          equals(preBackupSnapshot.albumPhotos.single),
        );

        // Verify media_fts has exact count (2 non-empty OCR images; phantom & sentinel excluded)
        final ftsCountRow = await db
            .customSelect('SELECT COUNT(*) AS cnt FROM media_fts')
            .getSingle();
        expect(ftsCountRow.read<int>('cnt'), equals(2));

        // Verify immediate searchability without re-running OCR
        final ticketMatches = await db.searchPhotoText('飞来峰');
        expect(ticketMatches.length, equals(1));
        expect(ticketMatches.single.id, equals('att_ticket_1'));
        expect(ticketMatches.single.ocrBlocksJson, equals(ticketBlocksJson));

        final menuMatches = await db.searchPhotoText('狮峰龙井');
        expect(menuMatches.length, equals(1));
        expect(menuMatches.single.id, equals('photo_menu_1'));
        expect(menuMatches.single.ocrBlocksJson, equals(menuBlocksJson));

        // Sentinel image is NOT considered unindexed after restore
        expect(await db.countUnindexedImages(), equals(0));
      },
    );

    test(
      'restores legacy schema v4 backup archive missing ocrBlocksJson and album ocrText fields with null defaults',
      () async {
        final nowEpochMs = DateTime.utc(2026, 10, 24, 12, 0).millisecondsSinceEpoch;
        final legacyManifestMap = <String, dynamic>{
          'format': BackupManifest.expectedFormat,
          'formatVersion': 1,
          'appSchemaVersion': 4,
          'createdAt': '2026-10-24T12:00:00.000Z',
          'tables': {
            'templates': <Map<String, dynamic>>[],
            'notebooks': <Map<String, dynamic>>[
              {
                'id': 'notebook_default',
                'title': 'My Diary',
                'defaultTemplateId': 'template_minimalist_white',
                'createdAt': nowEpochMs,
              },
            ],
            'entries': <Map<String, dynamic>>[
              {
                'id': 'v4_entry_1',
                'notebookId': 'notebook_default',
                'templateId': 'template_minimalist_white',
                'title': 'Legacy V4 Entry',
                'contentDelta': '[{"insert":"V4 body\\n"}]',
                'plainText': 'V4 body',
                'entryDate': nowEpochMs,
                'mood': 4,
                'weather': 'cloudy',
                'isWeeklyReview': false,
                'weekNumber': null,
                'unlockAt': null,
                'createdAt': nowEpochMs,
                'updatedAt': nowEpochMs,
                'isDeleted': false,
                'isLocked': false,
                'entryPinHash': null,
              },
            ],
            // v4 MediaAttachment JSON: has ocrText, NO ocrBlocksJson key
            'mediaAttachments': <Map<String, dynamic>>[
              {
                'id': 'v4_att_1',
                'entryId': 'v4_entry_1',
                'mediaType': 'image',
                'relativePath': 'media/v4_photo.webp',
                'thumbnailPath': null,
                'ocrText': 'Legacy V4 Signpost',
                'createdAt': nowEpochMs,
              },
            ],
            'albumCollections': <Map<String, dynamic>>[
              {
                'id': 'v4_col_1',
                'title': 'V4 Travel Album',
                'description': null,
                'destinationTag': null,
                'routeSummary': null,
                'coverImagePath': 'media/v4_album.webp',
                'startDate': null,
                'endDate': null,
                'layoutPreset': 'classic_photobook',
                'studioLayoutJson': null,
                'themeId': 'shanshui_ink',
                'sortIndex': 0,
                'createdAt': nowEpochMs,
                'updatedAt': nowEpochMs,
              },
            ],
            // v4 AlbumPhoto JSON: NO ocrText or ocrBlocksJson keys at all
            'albumPhotos': <Map<String, dynamic>>[
              {
                'id': 'v4_album_photo_1',
                'collectionId': 'v4_col_1',
                'relativeImagePath': 'media/v4_album.webp',
                'relativeThumbnailPath': 'media/v4_album_thumb.webp',
                'caption': 'Old Bridge',
                'locationTag': 'Suzhou',
                'shotAt': null,
                'sortOrder': 0,
                'aspectRatio': 1.5,
                'createdAt': nowEpochMs,
              },
            ],
          },
          'mediaFiles': <Map<String, dynamic>>[
            {
              'relativePath': 'media/v4_photo.webp',
              'sha256': crypto.sha256.convert(webpBytes).toString(),
              'sizeBytes': webpBytes.length,
            },
            {
              'relativePath': 'media/v4_album.webp',
              'sha256': crypto.sha256.convert(webpBytes).toString(),
              'sizeBytes': webpBytes.length,
            },
            {
              'relativePath': 'media/v4_album_thumb.webp',
              'sha256': crypto.sha256.convert(webpBytes).toString(),
              'sizeBytes': webpBytes.length,
            },
          ],
        };

        final manifestStr = jsonEncode(legacyManifestMap);
        final manifestSha =
            crypto.sha256.convert(utf8.encode(manifestStr)).toString();

        final zipFile = File(p.join(tempDir.path, 'legacy_v4.zip'));
        final encoder = ZipFileEncoder();
        encoder.create(zipFile.path);
        encoder.addArchiveFile(ArchiveFile.string('manifest.json', manifestStr));
        encoder.addArchiveFile(
          ArchiveFile.string('manifest.sha256', manifestSha),
        );
        encoder.addArchiveFile(
          ArchiveFile.bytes('media/v4_photo.webp', webpBytes),
        );
        encoder.addArchiveFile(
          ArchiveFile.bytes('media/v4_album.webp', webpBytes),
        );
        encoder.addArchiveFile(
          ArchiveFile.bytes('media/v4_album_thumb.webp', webpBytes),
        );
        await encoder.close();

        final mdbakFile = File(p.join(tempDir.path, 'legacy_v4.mdbak'));
        await BackupCrypto.wrapUnencryptedZip(
          sourceZip: zipFile,
          destination: mdbakFile,
        );

        final restoreRes = await backupService.restoreBackup(source: mdbakFile);
        expect(restoreRes.entriesRestored, equals(1));
        expect(restoreRes.albumPhotosRestored, equals(1));

        final restoredMedia = (await db.getMediaForEntry('v4_entry_1')).single;
        expect(restoredMedia.ocrText, equals('Legacy V4 Signpost'));
        expect(restoredMedia.ocrBlocksJson, isNull);

        final restoredAlbumPhoto = (await db.select(db.albumPhotos).get()).single;
        expect(restoredAlbumPhoto.ocrText, isNull);
        expect(restoredAlbumPhoto.ocrBlocksJson, isNull);

        // Legacy entry attachment with ocrText is searchable immediately, while legacy album photo is queued for backfill
        final searchHits = await db.searchPhotoText('Signpost');
        expect(searchHits.map((item) => item.id).toList(), equals(['v4_att_1']));
        expect(await db.countUnindexedImages(), equals(1));
      },
    );
  });
}
