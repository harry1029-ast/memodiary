import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Builds a raw schema v7 database (only the tables the 7 → 8 upgrade reads).
void _createSchemaV7(sqlite.Database rawDb) {
  rawDb.execute('PRAGMA user_version = 7;');
  rawDb.execute('''
    CREATE TABLE templates (
      id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL,
      background_type TEXT NOT NULL, background_value TEXT NOT NULL,
      font_family TEXT, line_spacing REAL, margin_horizontal REAL,
      is_custom INTEGER NOT NULL
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
      overlay_x_ratio REAL, overlay_y_ratio REAL, caption TEXT,
      created_at INTEGER NOT NULL
    );
  ''');
}

void main() {
  group('Schema v8 migration: legacy mounting pass flag', () {
    test('fresh entries are never pending the legacy mounting pass', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      expect(db.schemaVersion, equals(8));
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'entry_fresh',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: '[{"insert":"Fresh.\\n"}]',
          plainText: 'Fresh.',
          entryDate: DateTime(2026, 11, 5),
        ),
      );

      expect((await db.entriesDao.getEntryById('entry_fresh'))!.legacyMountsPending, isFalse);
    });

    test('upgrade from v7 flags only entries with attachments and no mount markers', () async {
      final nowSec = DateTime(2026, 11, 5, 9).millisecondsSinceEpoch ~/ 1000;
      final executor = NativeDatabase.memory(
        setup: (rawDb) {
          _createSchemaV7(rawDb);
          void insertEntry(String id, String delta) {
            rawDb.execute(
              'INSERT INTO entries (id, notebook_id, template_id, content_delta, plain_text, entry_date, created_at, updated_at) '
              "VALUES (?, 'nb1', 'tpl1', ?, '', $nowSec, $nowSec, $nowSec)",
              [id, delta],
            );
          }

          void insertMedia(String id, String entryId) {
            rawDb.execute(
              'INSERT INTO media_attachments (id, entry_id, media_type, relative_path, created_at) '
              "VALUES (?, ?, 'image', ?, $nowSec)",
              [id, entryId, 'media/$id.webp'],
            );
          }

          // Pre-SPEC-010 sheet-paired keepsakes: attachments, no markers.
          insertEntry('sheet_paired', '[{"insert":"游湖\\n"}]');
          insertMedia('lake', 'sheet_paired');
          // Pre-SPEC-010 inline embed: its attachment backs the embed.
          insertEntry('inline_embed', '[{"insert":{"image":"media/inline.webp"}},{"insert":"\\n"}]');
          insertMedia('inline', 'inline_embed');
          // Written by the marker-aware editor: already anchored.
          insertEntry('anchored', '[{"insert":"登山"},{"insert":{"mount":"peak"}},{"insert":"\\n"}]');
          insertMedia('peak', 'anchored');
          // Marker-aware editor, one item mounted and one left staged.
          insertEntry('partly_staged', '[{"insert":"观潮"},{"insert":{"mount":"tide"}},{"insert":"\\n"}]');
          insertMedia('tide', 'partly_staged');
          insertMedia('waiting', 'partly_staged');
          // Text only.
          insertEntry('text_only', '[{"insert":"无图\\n"}]');
        },
      );
      final db = AppDatabase(executor);
      addTearDown(() => db.close());

      Future<bool> pending(String id) async => (await db.entriesDao.getEntryById(id))!.legacyMountsPending;

      expect(await pending('sheet_paired'), isTrue);
      expect(await pending('inline_embed'), isTrue);
      expect(await pending('anchored'), isFalse);
      expect(await pending('partly_staged'), isFalse);
      expect(await pending('text_only'), isFalse);
    });
  });
}
