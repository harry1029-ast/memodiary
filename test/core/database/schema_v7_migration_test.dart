import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Builds a raw schema v6 database (tables, `media_fts` and its entry-media
/// triggers) so the 6 → 7 upgrade runs against realistic legacy rows.
void _createSchemaV6(sqlite.Database rawDb) {
  rawDb.execute('PRAGMA user_version = 6;');
  rawDb.execute('''
    CREATE TABLE templates (
      id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL,
      background_type TEXT NOT NULL, background_value TEXT NOT NULL,
      font_family TEXT, line_spacing REAL, margin_horizontal REAL,
      is_custom INTEGER NOT NULL
    );
  ''');
  rawDb.execute('''
    CREATE TABLE notebooks (
      id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL,
      default_template_id TEXT NOT NULL, created_at INTEGER NOT NULL
    );
  ''');
  rawDb.execute('''
    CREATE TABLE entries (
      id TEXT NOT NULL PRIMARY KEY, notebook_id TEXT NOT NULL,
      template_id TEXT NOT NULL, title TEXT, content_delta TEXT NOT NULL,
      plain_text TEXT NOT NULL, entry_date INTEGER NOT NULL, mood INTEGER,
      weather TEXT, is_weekly_review INTEGER NOT NULL DEFAULT 0,
      week_number INTEGER, unlock_at INTEGER, created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL, is_deleted INTEGER NOT NULL DEFAULT 0,
      is_locked INTEGER NOT NULL DEFAULT 0, entry_pin_hash TEXT
    );
  ''');
  rawDb.execute('''
    CREATE TABLE media_attachments (
      id TEXT NOT NULL PRIMARY KEY, entry_id TEXT NOT NULL,
      media_type TEXT NOT NULL, relative_path TEXT NOT NULL,
      thumbnail_path TEXT, ocr_text TEXT, ocr_blocks_json TEXT,
      overlay_x_ratio REAL, overlay_y_ratio REAL, created_at INTEGER NOT NULL
    );
  ''');
  rawDb.execute('''
    CREATE TABLE album_collections (
      id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL,
      studio_layout_json TEXT, theme_id TEXT,
      created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
    );
  ''');
  rawDb.execute('''
    CREATE TABLE album_photos (
      id TEXT NOT NULL PRIMARY KEY, collection_id TEXT NOT NULL,
      relative_image_path TEXT NOT NULL, relative_thumbnail_path TEXT,
      ocr_text TEXT, ocr_blocks_json TEXT, created_at INTEGER NOT NULL
    );
  ''');
  rawDb.execute('''
    CREATE VIRTUAL TABLE media_fts USING fts5(
      id UNINDEXED, source_type UNINDEXED, parent_id UNINDEXED,
      relative_path UNINDEXED, ocr_text, tokenize='unicode61'
    );
  ''');
  rawDb.execute('''
    CREATE TRIGGER media_attachments_ai AFTER INSERT ON media_attachments BEGIN
      INSERT INTO media_fts(id, source_type, parent_id, relative_path, ocr_text)
      SELECT new.id, 'entry_media', new.entry_id, new.relative_path, new.ocr_text
      WHERE new.media_type = 'image' AND coalesce(new.ocr_text, '') <> '';
    END;
  ''');
  rawDb.execute('''
    CREATE TRIGGER media_attachments_au AFTER UPDATE ON media_attachments BEGIN
      DELETE FROM media_fts WHERE id = old.id AND source_type = 'entry_media';
      INSERT INTO media_fts(id, source_type, parent_id, relative_path, ocr_text)
      SELECT new.id, 'entry_media', new.entry_id, new.relative_path, new.ocr_text
      WHERE new.media_type = 'image' AND coalesce(new.ocr_text, '') <> '';
    END;
  ''');
}

void main() {
  group('Schema v7 migration: captions separated from OCR text', () {
    test('fresh schema v7 database persists a caption without touching OCR text', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      expect(db.schemaVersion, equals(7));
      await db.getAllTemplates();

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_v7_fresh',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: '[{"insert":"Fresh.\\n"}]',
          plainText: 'Fresh.',
          entryDate: DateTime(2026, 11, 5),
        ),
      );
      await db.into(db.mediaAttachments).insert(
        MediaAttachmentsCompanion.insert(
          id: 'media_v7_ticket',
          entryId: 'entry_v7_fresh',
          mediaType: 'image',
          relativePath: 'media/ticket.webp',
          ocrText: const Value('灵隐门票'),
          ocrBlocksJson: const Value('[{"text":"灵隐门票"}]'),
        ),
      );

      await db.updateMediaCaption('media_v7_ticket', caption: '秋日登山');

      final media = (await db.getMediaForEntry('entry_v7_fresh')).single;
      expect(media.caption, equals('秋日登山'));
      expect(media.ocrText, equals('灵隐门票'));
      expect((await db.searchPhotoText('灵隐')).map((match) => match.id), equals(['media_v7_ticket']));
      expect(await db.searchPhotoText('秋日'), isEmpty);
    });

    test('upgrade from v6 copies captions only from rows without OCR blocks', () async {
      final nowSec = DateTime(2026, 11, 5, 9).millisecondsSinceEpoch ~/ 1000;
      final executor = NativeDatabase.memory(
        setup: (rawDb) {
          _createSchemaV6(rawDb);
          rawDb.execute('''
            INSERT INTO entries (id, notebook_id, template_id, content_delta, plain_text, entry_date, created_at, updated_at)
            VALUES ('entry_legacy', 'nb1', 'tpl1', '[{"insert":"Legacy\\n"}]', 'Legacy', $nowSec, $nowSec, $nowSec);
          ''');
          void insertMedia(String id, String? ocrText, String? blocks) {
            rawDb.execute(
              'INSERT INTO media_attachments (id, entry_id, media_type, relative_path, ocr_text, ocr_blocks_json, created_at) '
              "VALUES (?, 'entry_legacy', 'image', ?, ?, ?, $nowSec)",
              [id, 'media/$id.webp', ocrText, blocks],
            );
          }

          insertMedia('legacy_caption', '湖畔品茶', null);
          insertMedia('in_app_caption', '雨后西湖', '[]');
          insertMedia('ocr_scanned', '狮峰龙井', '[{"text":"狮峰龙井"}]');
          insertMedia('ocr_sentinel', '', '[]');
          insertMedia('unscanned', null, null);
        },
      );
      final db = AppDatabase(executor);
      addTearDown(() => db.close());

      await db.getAllTemplates();
      final byId = {
        for (final media in await db.getMediaForEntry('entry_legacy')) media.id: media,
      };

      expect(byId['legacy_caption']!.caption, equals('湖畔品茶'));
      expect(byId['legacy_caption']!.ocrText, equals('湖畔品茶'));
      expect(byId['in_app_caption']!.caption, equals('雨后西湖'));
      expect(byId['ocr_scanned']!.caption, isNull);
      expect(byId['ocr_scanned']!.ocrText, equals('狮峰龙井'));
      expect(byId['ocr_scanned']!.ocrBlocksJson, equals('[{"text":"狮峰龙井"}]'));
      expect(byId['ocr_sentinel']!.caption, isNull);
      expect(byId['ocr_sentinel']!.ocrText, equals(''));
      expect(byId['unscanned']!.caption, isNull);
      expect(byId['unscanned']!.ocrText, isNull);

      expect((await db.searchPhotoText('狮峰')).map((match) => match.id), equals(['ocr_scanned']));

      await db.updateMediaCaption('ocr_scanned', caption: '明前新茶');
      expect((await db.searchPhotoText('狮峰')).map((match) => match.id), equals(['ocr_scanned']));
      expect(await db.searchPhotoText('明前'), isEmpty);
    });
  });
}
