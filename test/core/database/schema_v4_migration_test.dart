import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/albums/models/album_studio_models.dart';
import 'package:memodiary/features/import_export/models/backup_manifest.dart';

void main() {
  group('Schema v4 Migration & Studio Document Persistence Tests', () {
    test(
      'Fresh schema v4 database initializes album_collections with studioLayoutJson and default themeId shanshui_ink',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(() => db.close());

        expect(db.schemaVersion, equals(4));

        final now = DateTime(2026, 10, 24, 15, 0);
        await db.into(db.albumCollections).insert(
              AlbumCollectionsCompanion.insert(
                id: 'col_v4_default',
                title: '江南烟雨录',
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

        final created = await (db.select(db.albumCollections)
              ..where((tbl) => tbl.id.equals('col_v4_default')))
            .getSingle();

        expect(created.themeId, equals('shanshui_ink'));
        expect(created.studioLayoutJson, isNull);

        // Verify updating studioLayoutJson and themeId
        final doc = AlbumStudioDocument(
          activeThemeId: 'jardin',
          removedPhotoIds: const ['photo_removed_1'],
          recentBackgroundColors: const [0xFFC89D9C],
          pages: [
            AlbumPageModel(
              id: 'page_1',
              pageNumber: 1,
              layoutTemplateId: 'trio_left_hero_right_stack',
              photoSlots: const [
                PhotoSlotAssignment(slotIndex: 0, photoId: 'p1'),
                PhotoSlotAssignment(slotIndex: 1, photoId: 'p2'),
                PhotoSlotAssignment(slotIndex: 2, photoId: 'p3'),
              ],
            ),
          ],
        );

        await (db.update(db.albumCollections)
              ..where((tbl) => tbl.id.equals('col_v4_default')))
            .write(
          AlbumCollectionsCompanion(
            studioLayoutJson: Value(doc.toJsonString()),
            themeId: const Value('jardin'),
          ),
        );

        final updated = await (db.select(db.albumCollections)
              ..where((tbl) => tbl.id.equals('col_v4_default')))
            .getSingle();

        expect(updated.themeId, equals('jardin'));
        expect(updated.studioLayoutJson, isNotNull);
        final roundTripped =
            AlbumStudioDocument.fromJsonString(updated.studioLayoutJson!);
        expect(roundTripped, equals(doc));
      },
    );

    test(
      'Simulated v3 -> v4 schema migration adds studio_layout_json and theme_id non-destructively',
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
              INSERT INTO album_collections (
                id, title, description, destination_tag, route_summary,
                layout_preset, sort_index, created_at, updated_at
              )
              VALUES (
                'v3_collection', '姑苏秋行', '枫桥夜泊', '苏州', '寒山寺 → 拙政园',
                'classic_photobook', 0, 1710000000, 1710000000
              );
            ''');
            rawDb.execute('''
              INSERT INTO album_photos (
                id, collection_id, relative_image_path, relative_thumbnail_path,
                caption, location_tag, sort_order, aspect_ratio, created_at
              )
              VALUES (
                'v3_photo_1', 'v3_collection', 'media/suzhou_1.webp', 'media/suzhou_1_thumb.webp',
                '寒山寺钟声', '苏州 · 寒山寺', 0, 1.33, 1710000000
              );
            ''');
            rawDb.execute('PRAGMA user_version = 3;');
          },
        );

        final db = AppDatabase(executor);
        addTearDown(() => db.close());

        // Querying triggers v3 -> v4 migration
        final collections = await db.select(db.albumCollections).get();
        expect(collections.length, equals(1));
        final migrated = collections.single;
        expect(migrated.id, equals('v3_collection'));
        expect(migrated.title, equals('姑苏秋行'));
        expect(migrated.description, equals('枫桥夜泊'));
        expect(migrated.destinationTag, equals('苏州'));
        expect(migrated.routeSummary, equals('寒山寺 → 拙政园'));
        expect(migrated.themeId, equals('shanshui_ink'));
        expect(migrated.studioLayoutJson, isNull);

        final photos = await db.select(db.albumPhotos).get();
        expect(photos.length, equals(1));
        expect(photos.single.caption, equals('寒山寺钟声'));
      },
    );

    test(
      'BackupManifest supports schemaVersion 4 and backward-compatible v3 AlbumCollection deserialization',
      () {
        final now = DateTime.utc(2026, 10, 24, 12, 0);
        final snapshot = BackupDatabaseSnapshot(
          templates: const [],
          notebooks: const [],
          entries: const [],
          mediaAttachments: const [],
          albumCollections: [
            AlbumCollection(
              id: 'col_v4',
              title: '徽州古村行',
              layoutPreset: 'classic_photobook',
              studioLayoutJson: '{"activeThemeId":"abstract_blue","pages":[]}',
              themeId: 'abstract_blue',
              sortIndex: 0,
              createdAt: now,
              updatedAt: now,
            ),
          ],
        );

        final manifest = BackupManifest(
          appSchemaVersion: 4,
          createdAt: now,
          snapshot: snapshot,
          mediaFiles: const [],
        );

        final decoded = BackupManifest.fromJsonString(manifest.toJsonString());
        expect(decoded.appSchemaVersion, equals(4));
        final restoredCol = decoded.snapshot.albumCollections.single;
        expect(restoredCol.themeId, equals('abstract_blue'));
        expect(
          restoredCol.studioLayoutJson,
          equals('{"activeThemeId":"abstract_blue","pages":[]}'),
        );

        // Legacy v3 BackupManifest JSON without studioLayoutJson or themeId in snapshot
        final legacySnapshot = BackupDatabaseSnapshot.fromJson({
          'templates': [],
          'notebooks': [],
          'entries': [],
          'mediaAttachments': [],
          'albumCollections': [
            {
              'id': 'col_v3_legacy',
              'title': '旧版影集',
              'description': null,
              'destinationTag': null,
              'routeSummary': null,
              'coverImagePath': null,
              'startDate': null,
              'endDate': null,
              'layoutPreset': 'classic_photobook',
              'sortIndex': 0,
              'createdAt': now.millisecondsSinceEpoch,
              'updatedAt': now.millisecondsSinceEpoch,
            }
          ],
          'albumPhotos': [],
        });
        expect(
          legacySnapshot.albumCollections.single.themeId,
          equals('shanshui_ink'),
        );
        expect(legacySnapshot.albumCollections.single.studioLayoutJson, isNull);
      },
    );
  });
}

