import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'daos/albums_dao.dart';
import 'daos/backup_dao.dart';
import 'daos/entries_dao.dart';
import 'daos/media_ocr_dao.dart';
import 'daos/templates_dao.dart';
import 'tables/templates.dart';
import 'tables/notebooks.dart';
import 'tables/entries.dart';
import 'tables/media_attachments.dart';
import 'tables/album_collections.dart';
import 'tables/album_photos.dart';

export 'daos/albums_dao.dart';
export 'daos/backup_dao.dart';
export 'daos/entries_dao.dart';
export 'daos/media_ocr_dao.dart';
export 'daos/templates_dao.dart';
export 'models/photo_text_match.dart';

part 'app_database.g.dart';

/// Top-level isolate setup to ensure background isolates load SQLCipher on Android
@pragma('vm:entry-point')
void _isolateDatabaseSetup() {
  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }
}

/// MemoDiary core encrypted database with SQLCipher and FTS5 search.
@DriftDatabase(
  tables: [
    Templates,
    Notebooks,
    Entries,
    MediaAttachments,
    AlbumCollections,
    AlbumPhotos,
  ],
  daos: [
    EntriesDao,
    TemplatesDao,
    MediaOcrDao,
    AlbumsDao,
    BackupDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Testing constructor using an arbitrary executor (e.g. NativeDatabase.memory())
  AppDatabase.forTesting(super.e);

  /// Factory constructor for encrypted database file using SQLCipher
  factory AppDatabase.encrypted({
    required File dbFile,
    required String encryptionKey,
  }) {
    if (Platform.isAndroid) {
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    }

    final executor = NativeDatabase.createInBackground(
      dbFile,
      isolateSetup: _isolateDatabaseSetup,
      setup: (rawDb) {
        final escapedKey = encryptionKey.replaceAll("'", "''");
        rawDb.execute("PRAGMA key = '$escapedKey';");
      },
    );
    return AppDatabase(executor);
  }

  /// In-memory database factory for quick testing
  factory AppDatabase.memory() {
    return AppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 8;

  /// Creates the `media_fts` FTS5 virtual table and its 6 synchronization triggers.
  Future<void> _createMediaFts() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS media_fts USING fts5(
        id UNINDEXED,
        source_type UNINDEXED,
        parent_id UNINDEXED,
        relative_path UNINDEXED,
        ocr_text,
        tokenize='unicode61'
      );
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS media_attachments_ai AFTER INSERT ON media_attachments BEGIN
        INSERT INTO media_fts(id, source_type, parent_id, relative_path, ocr_text)
        SELECT new.id, 'entry_media', new.entry_id, new.relative_path, new.ocr_text
        WHERE new.media_type = 'image' AND coalesce(new.ocr_text, '') <> '';
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS media_attachments_au AFTER UPDATE ON media_attachments BEGIN
        DELETE FROM media_fts WHERE id = old.id AND source_type = 'entry_media';
        INSERT INTO media_fts(id, source_type, parent_id, relative_path, ocr_text)
        SELECT new.id, 'entry_media', new.entry_id, new.relative_path, new.ocr_text
        WHERE new.media_type = 'image' AND coalesce(new.ocr_text, '') <> '';
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS media_attachments_ad AFTER DELETE ON media_attachments BEGIN
        DELETE FROM media_fts WHERE id = old.id AND source_type = 'entry_media';
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS album_photos_ai AFTER INSERT ON album_photos BEGIN
        INSERT INTO media_fts(id, source_type, parent_id, relative_path, ocr_text)
        SELECT new.id, 'album_photo', new.collection_id, new.relative_image_path, new.ocr_text
        WHERE coalesce(new.ocr_text, '') <> '';
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS album_photos_au AFTER UPDATE ON album_photos BEGIN
        DELETE FROM media_fts WHERE id = old.id AND source_type = 'album_photo';
        INSERT INTO media_fts(id, source_type, parent_id, relative_path, ocr_text)
        SELECT new.id, 'album_photo', new.collection_id, new.relative_image_path, new.ocr_text
        WHERE coalesce(new.ocr_text, '') <> '';
      END;
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS album_photos_ad AFTER DELETE ON album_photos BEGIN
        DELETE FROM media_fts WHERE id = old.id AND source_type = 'album_photo';
      END;
    ''');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          // 1. Create standard Drift tables
          await m.createAll();

          // 2. Create SQLite FTS5 Virtual Table for full-text search
          await customStatement('''
            CREATE VIRTUAL TABLE IF NOT EXISTS entries_fts USING fts5(
              id UNINDEXED,
              title,
              plain_text,
              tokenize='unicode61'
            );
          ''');

          // 3. Create triggers to automatically keep FTS5 synchronized with entries table
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS entries_ai AFTER INSERT ON entries BEGIN
              INSERT INTO entries_fts(id, title, plain_text)
              VALUES (new.id, coalesce(new.title, ''), new.plain_text);
            END;
          ''');

          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS entries_au AFTER UPDATE ON entries BEGIN
              UPDATE entries_fts
              SET title = coalesce(new.title, ''),
                  plain_text = new.plain_text
              WHERE id = new.id;
            END;
          ''');

          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS entries_ad AFTER DELETE ON entries BEGIN
              DELETE FROM entries_fts WHERE id = old.id;
            END;
          ''');

          // 3b. Create media_fts FTS5 virtual table and synchronization triggers
          await _createMediaFts();

          // 4. Create index for ultra-fast reverse-chronological timeline pagination
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_entries_timeline ON entries(is_deleted, entry_date DESC);
          ''');

          // 4b. Create composite index for album photos ordered by narrative sequence
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_album_photos_collection_order
            ON album_photos(collection_id, sort_order ASC);
          ''');

          // 5. Seed the 4 canonical default templates and default notebook
          await batch((batchOp) {
            batchOp.insertAll(
              templates,
              TemplatesDao.buildDefaultTemplateCompanions(),
            );
            batchOp.insert(
              notebooks,
              TemplatesDao.buildDefaultNotebookCompanion(),
            );
          });
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(entries, entries.isLocked);
            await m.addColumn(entries, entries.entryPinHash);
          }
          if (from < 3) {
            await m.createTable(albumCollections);
            await m.createTable(albumPhotos);
            await customStatement('''
              CREATE INDEX IF NOT EXISTS idx_album_photos_collection_order
              ON album_photos(collection_id, sort_order ASC);
            ''');
          } else if (from < 4) {
            await m.addColumn(
              albumCollections,
              albumCollections.studioLayoutJson,
            );
            await m.addColumn(albumCollections, albumCollections.themeId);
          }
          if (from < 5) {
            await m.addColumn(
              mediaAttachments,
              mediaAttachments.ocrBlocksJson,
            );
            if (from >= 3) {
              await m.addColumn(albumPhotos, albumPhotos.ocrText);
              await m.addColumn(albumPhotos, albumPhotos.ocrBlocksJson);
            }
            await _createMediaFts();
            await customStatement('''
              INSERT INTO media_fts(id, source_type, parent_id, relative_path, ocr_text)
              SELECT id, 'entry_media', entry_id, relative_path, ocr_text
              FROM media_attachments
              WHERE media_type = 'image' AND coalesce(ocr_text, '') <> '';
            ''');
          }
          if (from < 6) {
            await m.addColumn(
              mediaAttachments,
              mediaAttachments.overlayXRatio,
            );
            await m.addColumn(
              mediaAttachments,
              mediaAttachments.overlayYRatio,
            );
          }
          if (from < 7) {
            await m.addColumn(mediaAttachments, mediaAttachments.caption);
            // Captions previously lived in `ocr_text`. Rows with real OCR
            // blocks keep it as OCR; rows never scanned (NULL blocks) or
            // captioned in-app (empty blocks with non-empty text) have the
            // text moved to `caption` and their OCR fields reset to unindexed
            // (NULL), so the caption leaves `media_fts` (via the update
            // trigger) and the photo is queued for OCR backfill.
            await customStatement('''
              UPDATE media_attachments
              SET caption = ocr_text, ocr_text = NULL, ocr_blocks_json = NULL
              WHERE coalesce(ocr_text, '') <> ''
                AND (ocr_blocks_json IS NULL OR ocr_blocks_json = '[]');
            ''');
          }
          if (from < 8) {
            await m.addColumn(entries, entries.legacyMountsPending);
            // Entries whose attachments predate mount markers are mounted
            // first-come by the editor on their next open. An entry already
            // holding a marker was written by the marker-aware editor.
            await customStatement('''
              UPDATE entries SET legacy_mounts_pending = 1
              WHERE content_delta NOT LIKE '%"mount":%'
                AND EXISTS (
                  SELECT 1 FROM media_attachments
                  WHERE media_attachments.entry_id = entries.id
                );
            ''');
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );
}
