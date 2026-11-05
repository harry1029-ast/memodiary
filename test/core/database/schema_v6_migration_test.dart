import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';

void main() {
  group('Schema v6 Migration & Ephemera Overlay Persistence Tests', () {
    test('Fresh schema v6 database sets schemaVersion 6 and has overlay ratio columns', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      expect(db.schemaVersion, equals(7));

      // Trigger schema creation
      await db.getAllTemplates();

      final now = DateTime(2026, 11, 4, 20, 0);
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_v6_fresh',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Ephemera Overlay Test'),
          contentDelta: '[{"insert":"Fresh test.\\n"}]',
          plainText: 'Fresh test.',
          entryDate: now,
        ),
      );

      await db.into(db.mediaAttachments).insert(
        MediaAttachmentsCompanion.insert(
          id: 'media_v6_fresh',
          entryId: 'entry_v6_fresh',
          mediaType: 'image',
          relativePath: 'media/polaroid_fresh.webp',
          overlayXRatio: const Value(0.25),
          overlayYRatio: const Value(0.75),
          createdAt: Value(now),
        ),
      );

      final media = (await db.getMediaForEntry('entry_v6_fresh')).single;
      expect(media.overlayXRatio, equals(0.25));
      expect(media.overlayYRatio, equals(0.75));
    });

    test('Migration from schema v5 adds overlay_x_ratio and overlay_y_ratio', () async {
      final nowSec = DateTime(2026, 11, 4, 12, 0).millisecondsSinceEpoch ~/ 1000;
      final executor = NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('PRAGMA user_version = 5;');
          rawDb.execute('''
            CREATE TABLE templates (
              id TEXT NOT NULL PRIMARY KEY,
              name TEXT NOT NULL,
              background_type TEXT NOT NULL,
              background_value TEXT NOT NULL,
              font_family TEXT,
              line_spacing REAL,
              margin_horizontal REAL,
              is_custom INTEGER NOT NULL
            );
          ''');
          rawDb.execute('''
            CREATE TABLE notebooks (
              id TEXT NOT NULL PRIMARY KEY,
              title TEXT NOT NULL,
              default_template_id TEXT NOT NULL,
              created_at INTEGER NOT NULL
            );
          ''');
          rawDb.execute('''
            CREATE TABLE entries (
              id TEXT NOT NULL PRIMARY KEY,
              notebook_id TEXT NOT NULL,
              template_id TEXT NOT NULL,
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
              entry_id TEXT NOT NULL,
              media_type TEXT NOT NULL,
              relative_path TEXT NOT NULL,
              thumbnail_path TEXT,
              ocr_text TEXT,
              ocr_blocks_json TEXT,
              created_at INTEGER NOT NULL
            );
          ''');
          rawDb.execute('''
            CREATE TABLE album_collections (
              id TEXT NOT NULL PRIMARY KEY,
              title TEXT NOT NULL,
              studio_layout_json TEXT,
              theme_id TEXT,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            );
          ''');
          rawDb.execute('''
            CREATE TABLE album_photos (
              id TEXT NOT NULL PRIMARY KEY,
              collection_id TEXT NOT NULL,
              relative_image_path TEXT NOT NULL,
              relative_thumbnail_path TEXT,
              ocr_text TEXT,
              ocr_blocks_json TEXT,
              created_at INTEGER NOT NULL
            );
          ''');
          rawDb.execute('''
            INSERT INTO entries (id, notebook_id, template_id, title, content_delta, plain_text, entry_date, created_at, updated_at)
            VALUES ('entry_legacy', 'nb1', 'tpl1', 'Legacy', '[{"insert":"Test\\n"}]', 'Test', $nowSec, $nowSec, $nowSec);
          ''');
          rawDb.execute('''
            INSERT INTO media_attachments (id, entry_id, media_type, relative_path, created_at)
            VALUES ('media_legacy', 'entry_legacy', 'image', 'media/legacy.webp', $nowSec);
          ''');
        },
      );

      final migratedDb = AppDatabase(executor);
      addTearDown(() => migratedDb.close());

      // Trigger database initialization / migration
      await migratedDb.getAllTemplates();

      expect(migratedDb.schemaVersion, equals(7));

      // Verify legacy record has null overlay coordinates
      final legacyMedia = (await migratedDb.getMediaForEntry('entry_legacy')).single;
      expect(legacyMedia.overlayXRatio, isNull);
      expect(legacyMedia.overlayYRatio, isNull);

      // Update overlay position using database method
      await migratedDb.updateMediaAttachmentOverlayPosition(
        'media_legacy',
        xRatio: 0.15,
        yRatio: 0.85,
      );

      final updatedMedia = (await migratedDb.getMediaForEntry('entry_legacy')).single;
      expect(updatedMedia.overlayXRatio, equals(0.15));
      expect(updatedMedia.overlayYRatio, equals(0.85));

      // Reset to null (snap-back reset)
      await migratedDb.updateMediaAttachmentOverlayPosition(
        'media_legacy',
        xRatio: null,
        yRatio: null,
      );

      final resetMedia = (await migratedDb.getMediaForEntry('entry_legacy')).single;
      expect(resetMedia.overlayXRatio, isNull);
      expect(resetMedia.overlayYRatio, isNull);
    });
  });
}
