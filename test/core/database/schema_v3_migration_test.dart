import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';

void main() {
  group('Schema v3 Migration & Travel Memory Album Relational Tests', () {
    test(
      'Fresh schema v3 database creates album_collections, album_photos, composite index, and enforces ON DELETE CASCADE',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(() => db.close());

        expect(db.schemaVersion, equals(3));

        final now = DateTime(2026, 10, 23, 12, 0);
        await db.into(db.albumCollections).insert(
              AlbumCollectionsCompanion.insert(
                id: 'col_jiangnan',
                title: '江南春行纪',
                description: const Value('山河沿路，笔底留痕'),
                destinationTag: const Value('江南'),
                routeSummary: const Value('杭州 → 乌镇 → 苏州'),
                coverImagePath: const Value('media/cover_1.webp'),
                startDate: Value(DateTime(2026, 4, 1)),
                endDate: Value(DateTime(2026, 4, 5)),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

        await db.into(db.albumPhotos).insert(
              AlbumPhotosCompanion.insert(
                id: 'photo_1',
                collectionId: 'col_jiangnan',
                relativeImagePath: 'media/photo_1.webp',
                relativeThumbnailPath: 'media/photo_1_thumb.webp',
                caption: const Value('断桥残雪初晴'),
                locationTag: const Value('杭州 · 西湖'),
                shotAt: Value(DateTime(2026, 4, 1, 9, 30)),
                sortOrder: const Value(0),
                aspectRatio: const Value(1.33),
                createdAt: Value(now),
              ),
            );

        // Verify composite index exists in sqlite_master
        final indexRows = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'idx_album_photos_collection_order'",
            )
            .get();
        expect(indexRows.length, equals(1));

        // Verify ON DELETE CASCADE removes linked photos when parent collection is deleted
        await (db.delete(db.albumCollections)
              ..where((tbl) => tbl.id.equals('col_jiangnan')))
            .go();

        final remainingPhotos = await db.select(db.albumPhotos).get();
        expect(remainingPhotos, isEmpty);
      },
    );

    test(
      'Simulated v2 -> v3 schema migration creates album tables without losing existing v2 entries or lock metadata',
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
            rawDb.execute('''
              INSERT INTO entries (
                id, notebook_id, template_id, title, content_delta, plain_text,
                entry_date, created_at, updated_at, is_locked, entry_pin_hash
              )
              VALUES (
                'v2_preserved_entry', 'notebook_default', 'template_minimalist_white',
                'V2 Locked Entry', '[{"insert":"Preserved across v3 upgrade\\n"}]',
                'Preserved across v3 upgrade', 1710000000, 1710000000, 1710000000,
                1, 'salt:hash123'
              );
            ''');
            rawDb.execute('PRAGMA user_version = 2;');
          },
        );

        final db = AppDatabase(executor);
        addTearDown(() => db.close());

        // 1. Verify legacy v2 entry is preserved intact after v2 -> v3 migration
        final entry = await db.getEntryById('v2_preserved_entry');
        expect(entry, isNotNull);
        expect(entry!.title, equals('V2 Locked Entry'));
        expect(entry.plainText, equals('Preserved across v3 upgrade'));
        expect(entry.isLocked, isTrue);
        expect(entry.entryPinHash, equals('salt:hash123'));

        // 2. Verify newly created v3 album_collections & album_photos tables work seamlessly
        await db.into(db.albumCollections).insert(
              AlbumCollectionsCompanion.insert(
                id: 'migrated_col_1',
                title: '京都红叶狩',
                destinationTag: const Value('关西'),
                routeSummary: const Value('京都 → 奈良 → 宇治'),
              ),
            );
        await db.into(db.albumPhotos).insert(
              AlbumPhotosCompanion.insert(
                id: 'migrated_photo_1',
                collectionId: 'migrated_col_1',
                relativeImagePath: 'media/kyoto_1.webp',
                relativeThumbnailPath: 'media/kyoto_1_thumb.webp',
                caption: const Value('清水寺晚秋'),
                locationTag: const Value('京都 · 清水寺'),
              ),
            );

        final collections = await db.select(db.albumCollections).get();
        expect(collections.length, equals(1));
        expect(collections.first.title, equals('京都红叶狩'));
        expect(collections.first.destinationTag, equals('关西'));
        expect(collections.first.routeSummary, equals('京都 → 奈良 → 宇治'));

        final photos = await db.select(db.albumPhotos).get();
        expect(photos.length, equals(1));
        expect(photos.first.caption, equals('清水寺晚秋'));
      },
    );
  });
}

