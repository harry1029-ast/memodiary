import 'package:drift/drift.dart' show Value, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';

void main() {
  group('Schema v5 Migration & media_fts Initialization Tests', () {
    test(
      'Fresh schema v5 database sets schemaVersion 5, creates media_fts virtual table, 6 triggers, and new OCR columns',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(() => db.close());

        expect(db.schemaVersion, equals(5));

        // Trigger database creation
        await db.getAllTemplates();

        final ftsTableRows = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'media_fts'",
            )
            .get();
        expect(ftsTableRows.length, equals(1));

        final triggerRows = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'trigger' AND (name LIKE 'media_attachments_%' OR name LIKE 'album_photos_%')",
            )
            .get();
        final triggerNames =
            triggerRows.map((row) => row.read<String>('name')).toSet();
        expect(
          triggerNames,
          containsAll(<String>[
            'media_attachments_ai',
            'media_attachments_au',
            'media_attachments_ad',
            'album_photos_ai',
            'album_photos_au',
            'album_photos_ad',
          ]),
        );

        final now = DateTime(2026, 10, 31, 10, 0);
        await db.createEntry(
          EntriesCompanion.insert(
            id: 'entry_v5_1',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('West Lake Ticket'),
            contentDelta: '[{"insert":"Morning ferry.\\n"}]',
            plainText: 'Morning ferry.',
            entryDate: now,
          ),
        );

        const blocksJson =
            '[{"text":"西湖十景","box":[0.1,0.2,0.5,0.08]}]';
        await db.into(db.mediaAttachments).insert(
              MediaAttachmentsCompanion.insert(
                id: 'media_v5_1',
                entryId: 'entry_v5_1',
                mediaType: 'image',
                relativePath: 'media/ticket_1.webp',
                ocrText: const Value('西湖十景'),
                ocrBlocksJson: const Value(blocksJson),
                createdAt: Value(now),
              ),
            );

        await db.into(db.albumCollections).insert(
              AlbumCollectionsCompanion.insert(
                id: 'col_v5_1',
                title: '江南秋旅',
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

        await db.into(db.albumPhotos).insert(
              AlbumPhotosCompanion.insert(
                id: 'photo_v5_1',
                collectionId: 'col_v5_1',
                relativeImagePath: 'media/plaque_1.webp',
                relativeThumbnailPath: 'media/plaque_1_thumb.webp',
                ocrText: const Value('断桥残雪'),
                ocrBlocksJson: const Value(
                  '[{"text":"断桥残雪","box":[0.2,0.3,0.4,0.1]}]',
                ),
                createdAt: Value(now),
              ),
            );

        final savedMedia = (await db.getMediaForEntry('entry_v5_1')).single;
        expect(savedMedia.ocrText, equals('西湖十景'));
        expect(savedMedia.ocrBlocksJson, equals(blocksJson));

        final savedPhoto = await (db.select(db.albumPhotos)
              ..where((tbl) => tbl.id.equals('photo_v5_1')))
            .getSingle();
        expect(savedPhoto.ocrText, equals('断桥残雪'));
        expect(
          savedPhoto.ocrBlocksJson,
          equals('[{"text":"断桥残雪","box":[0.2,0.3,0.4,0.1]}]'),
        );
      },
    );

    test(
      'Real v4 -> v5 migration adds OCR columns and backfills existing non-empty image ocr_text into media_fts',
      () async {
        final executor = NativeDatabase.memory(
          setup: (rawDb) {
            rawDb.execute('''
              CREATE TABLE templates (
                id TEXT NOT NULL PRIMARY KEY,
                name TEXT NOT NULL,
                background_type TEXT NOT NULL,
                background_value TEXT NOT NULL,
                font_family TEXT,
                line_spacing REAL NOT NULL DEFAULT 1.5,
                margin_horizontal REAL NOT NULL DEFAULT 16.0,
                is_custom INTEGER NOT NULL DEFAULT 0
              );
            ''');
            rawDb.execute('''
              CREATE TABLE notebooks (
                id TEXT NOT NULL PRIMARY KEY,
                title TEXT NOT NULL,
                default_template_id TEXT NOT NULL REFERENCES templates (id),
                created_at INTEGER NOT NULL
              );
            ''');
            rawDb.execute('''
              CREATE TABLE entries (
                id TEXT NOT NULL PRIMARY KEY,
                notebook_id TEXT NOT NULL REFERENCES notebooks (id),
                template_id TEXT NOT NULL REFERENCES templates (id),
                title TEXT,
                content_delta TEXT NOT NULL,
                plain_text TEXT NOT NULL,
                entry_date INTEGER NOT NULL,
                mood INTEGER,
                weather TEXT,
                is_weekly_review INTEGER NOT NULL DEFAULT 0,
                week_number INTEGER,
                unlock_at INTEGER,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                is_deleted INTEGER NOT NULL DEFAULT 0,
                is_locked INTEGER NOT NULL DEFAULT 0,
                entry_pin_hash TEXT
              );
            ''');
            rawDb.execute('''
              CREATE TABLE media_attachments (
                id TEXT NOT NULL PRIMARY KEY,
                entry_id TEXT NOT NULL REFERENCES entries (id),
                media_type TEXT NOT NULL,
                relative_path TEXT NOT NULL,
                thumbnail_path TEXT,
                ocr_text TEXT,
                created_at INTEGER NOT NULL
              );
            ''');
            rawDb.execute('''
              CREATE TABLE album_collections (
                id TEXT NOT NULL PRIMARY KEY,
                title TEXT NOT NULL,
                description TEXT,
                destination_tag TEXT,
                route_summary TEXT,
                cover_image_path TEXT,
                start_date INTEGER,
                end_date INTEGER,
                layout_preset TEXT NOT NULL DEFAULT 'classic_photobook',
                studio_layout_json TEXT,
                theme_id TEXT NOT NULL DEFAULT 'shanshui_ink',
                sort_index INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
              );
            ''');
            rawDb.execute('''
              CREATE TABLE album_photos (
                id TEXT NOT NULL PRIMARY KEY,
                collection_id TEXT NOT NULL REFERENCES album_collections (id) ON DELETE CASCADE,
                relative_image_path TEXT NOT NULL,
                relative_thumbnail_path TEXT NOT NULL,
                caption TEXT,
                location_tag TEXT,
                shot_at INTEGER,
                sort_order INTEGER NOT NULL DEFAULT 0,
                aspect_ratio REAL NOT NULL DEFAULT 1.0,
                created_at INTEGER NOT NULL
              );
            ''');

            rawDb.execute('''
              INSERT INTO templates (id, name, background_type, background_value, font_family)
              VALUES ('template_minimalist_white', 'Minimalist White', 'color', '#FFFFFF', 'System');
            ''');
            rawDb.execute('''
              INSERT INTO notebooks (id, title, default_template_id, created_at)
              VALUES ('notebook_default', 'My Diary', 'template_minimalist_white', 1710000000);
            ''');
            rawDb.execute('''
              INSERT INTO entries (
                id, notebook_id, template_id, title, content_delta, plain_text,
                entry_date, created_at, updated_at
              )
              VALUES (
                'v4_entry_1', 'notebook_default', 'template_minimalist_white',
                'Legacy Trip', '[{"insert":"Hello\\n"}]', 'Hello',
                1710000000, 1710000000, 1710000000
              );
            ''');
            // Image with pre-existing ocr_text -> MUST be backfilled
            rawDb.execute('''
              INSERT INTO media_attachments (id, entry_id, media_type, relative_path, ocr_text, created_at)
              VALUES ('v4_img_with_ocr', 'v4_entry_1', 'image', 'media/ferry_ticket.webp', 'WestLake Ferry 2026', 1710000001);
            ''');
            // Image with NULL ocr_text -> MUST NOT be in media_fts
            rawDb.execute('''
              INSERT INTO media_attachments (id, entry_id, media_type, relative_path, ocr_text, created_at)
              VALUES ('v4_img_null_ocr', 'v4_entry_1', 'image', 'media/scenery.webp', NULL, 1710000002);
            ''');
            // Image with emptyocr_text -> MUST NOT be in media_fts
            rawDb.execute('''
              INSERT INTO media_attachments (id, entry_id, media_type, relative_path, ocr_text, created_at)
              VALUES ('v4_img_empty_ocr', 'v4_entry_1', 'image', 'media/blank.webp', '', 1710000003);
            ''');
            // Video attachment with ocr_text -> MUST NOT be in media_fts
            rawDb.execute('''
              INSERT INTO media_attachments (id, entry_id, media_type, relative_path, ocr_text, created_at)
              VALUES ('v4_vid_1', 'v4_entry_1', 'video', 'media/clip.mp4', 'Video Subtitle', 1710000004);
            ''');
            rawDb.execute('''
              INSERT INTO album_collections (id, title, created_at, updated_at)
              VALUES ('v4_col_1', '姑苏行', 1710000000, 1710000000);
            ''');
            rawDb.execute('''
              INSERT INTO album_photos (
                id, collection_id, relative_image_path, relative_thumbnail_path, created_at
              )
              VALUES ('v4_album_photo_1', 'v4_col_1', 'media/suzhou.webp', 'media/suzhou_thumb.webp', 1710000005);
            ''');

            rawDb.execute('PRAGMA user_version = 4;');
          },
        );

        final db = AppDatabase(executor);
        addTearDown(() => db.close());

        final attachments = await db.getMediaForEntry('v4_entry_1');
        expect(attachments.length, equals(4));
        final migratedTicket =
            attachments.firstWhere((item) => item.id == 'v4_img_with_ocr');
        expect(migratedTicket.ocrText, equals('WestLake Ferry 2026'));
        expect(migratedTicket.ocrBlocksJson, isNull);

        final migratedPhotos = await db.select(db.albumPhotos).get();
        expect(migratedPhotos.single.id, equals('v4_album_photo_1'));
        expect(migratedPhotos.single.ocrText, isNull);
        expect(migratedPhotos.single.ocrBlocksJson, isNull);

        // Verify media_fts backfilled ONLY the non-empty image attachment
        final ftsRows = await db
            .customSelect('SELECT id, source_type, ocr_text FROM media_fts')
            .get();
        expect(ftsRows.length, equals(1));
        expect(ftsRows.single.read<String>('id'), equals('v4_img_with_ocr'));
        expect(
          ftsRows.single.read<String>('source_type'),
          equals('entry_media'),
        );
        expect(
          ftsRows.single.read<String>('ocr_text'),
          equals('WestLake Ferry 2026'),
        );

        // Verify FTS5 MATCH works immediately against backfilled record
        final matchRows = await db
            .customSelect(
              'SELECT id FROM media_fts WHERE media_fts MATCH ?',
              variables: [Variable.withString('"Ferry"*')],
            )
            .get();
        expect(matchRows.length, equals(1));
        expect(matchRows.single.read<String>('id'), equals('v4_img_with_ocr'));
      },
    );

    test(
      'v2 -> v5 multi-step upgrade succeeds without duplicate column error on album_photos',
      () async {
        final executor = NativeDatabase.memory(
          setup: (rawDb) {
            rawDb.execute('''
              CREATE TABLE templates (
                id TEXT NOT NULL PRIMARY KEY,
                name TEXT NOT NULL,
                background_type TEXT NOT NULL,
                background_value TEXT NOT NULL,
                font_family TEXT,
                line_spacing REAL NOT NULL DEFAULT 1.5,
                margin_horizontal REAL NOT NULL DEFAULT 16.0,
                is_custom INTEGER NOT NULL DEFAULT 0
              );
            ''');
            rawDb.execute('''
              CREATE TABLE notebooks (
                id TEXT NOT NULL PRIMARY KEY,
                title TEXT NOT NULL,
                default_template_id TEXT NOT NULL REFERENCES templates (id),
                created_at INTEGER NOT NULL
              );
            ''');
            rawDb.execute('''
              CREATE TABLE entries (
                id TEXT NOT NULL PRIMARY KEY,
                notebook_id TEXT NOT NULL REFERENCES notebooks (id),
                template_id TEXT NOT NULL REFERENCES templates (id),
                title TEXT,
                content_delta TEXT NOT NULL,
                plain_text TEXT NOT NULL,
                entry_date INTEGER NOT NULL,
                mood INTEGER,
                weather TEXT,
                is_weekly_review INTEGER NOT NULL DEFAULT 0,
                week_number INTEGER,
                unlock_at INTEGER,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                is_deleted INTEGER NOT NULL DEFAULT 0,
                is_locked INTEGER NOT NULL DEFAULT 0,
                entry_pin_hash TEXT
              );
            ''');
            rawDb.execute('''
              CREATE TABLE media_attachments (
                id TEXT NOT NULL PRIMARY KEY,
                entry_id TEXT NOT NULL REFERENCES entries (id),
                media_type TEXT NOT NULL,
                relative_path TEXT NOT NULL,
                thumbnail_path TEXT,
                ocr_text TEXT,
                created_at INTEGER NOT NULL
              );
            ''');
            rawDb.execute('''
              INSERT INTO templates (id, name, background_type, background_value, font_family)
              VALUES ('template_minimalist_white', 'Minimalist White', 'color', '#FFFFFF', 'System');
            ''');
            rawDb.execute('''
              INSERT INTO notebooks (id, title, default_template_id, created_at)
              VALUES ('notebook_default', 'My Diary', 'template_minimalist_white', 1710000000);
            ''');
            rawDb.execute('PRAGMA user_version = 2;');
          },
        );

        final db = AppDatabase(executor);
        addTearDown(() => db.close());

        await db.into(db.albumCollections).insert(
              AlbumCollectionsCompanion.insert(
                id: 'v2_to_v5_col',
                title: '川西高原行',
              ),
            );
        await db.into(db.albumPhotos).insert(
              AlbumPhotosCompanion.insert(
                id: 'v2_to_v5_photo',
                collectionId: 'v2_to_v5_col',
                relativeImagePath: 'media/plateau.webp',
                relativeThumbnailPath: 'media/plateau_thumb.webp',
                ocrText: const Value('稻城亚丁海拔4600米'),
                ocrBlocksJson: const Value('[]'),
              ),
            );

        final photos = await db.select(db.albumPhotos).get();
        expect(photos.length, equals(1));
        expect(photos.single.ocrText, equals('稻城亚丁海拔4600米'));

        final ftsRows = await db
            .customSelect('SELECT id FROM media_fts')
            .get();
        expect(ftsRows.map((row) => row.read<String>('id')), contains('v2_to_v5_photo'));
      },
    );
  });
}
