import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/import_export/models/backup_manifest.dart';

void main() {
  group('BackupManifest & BackupDatabaseSnapshot Serialization', () {
    test('round-trips all 4 SQLite table types and media records accurately', () {
      final now = DateTime.utc(2026, 10, 19, 12, 30);
      final unlockAt = DateTime.utc(2027, 1, 1);

      final snapshot = BackupDatabaseSnapshot(
        templates: const [
          Template(
            id: 'template_custom_1',
            name: 'Warm Grid',
            backgroundType: 'grid',
            backgroundValue: '#FAF6F0',
            fontFamily: 'Serif',
            lineSpacing: 1.7,
            marginHorizontal: 22.0,
            isCustom: true,
          ),
        ],
        notebooks: [
          Notebook(
            id: 'notebook_default',
            title: 'My Diary',
            defaultTemplateId: 'template_custom_1',
            createdAt: now,
          ),
        ],
        entries: [
          Entry(
            id: 'entry_1',
            notebookId: 'notebook_default',
            templateId: 'template_custom_1',
            title: 'Autumn Trip',
            contentDelta: '[{"insert":"Hello world\\n"}]',
            plainText: 'Hello world',
            entryDate: now,
            mood: 5,
            weather: 'sunny',
            isWeeklyReview: true,
            weekNumber: 42,
            unlockAt: unlockAt,
            createdAt: now,
            updatedAt: now,
            isDeleted: false,
            isLocked: true,
            entryPinHash: 'salt123:hash456',
          ),
        ],
        mediaAttachments: [
          MediaAttachment(
            id: 'media_1',
            entryId: 'entry_1',
            mediaType: 'video',
            relativePath: 'media/clip.mp4',
            thumbnailPath: 'media/clip_thumb.webp',
            ocrText: 'mountain sign',
            createdAt: now,
          ),
        ],
      );

      final manifest = BackupManifest(
        appSchemaVersion: 2,
        createdAt: now,
        snapshot: snapshot,
        mediaFiles: const [
          BackupMediaRecord(
            relativePath: 'media/clip.mp4',
            sha256: 'abc123def456',
            sizeBytes: 1048576,
          ),
          BackupMediaRecord(
            relativePath: 'media/clip_thumb.webp',
            sha256: '789fed654cba',
            sizeBytes: 16384,
          ),
        ],
      );

      final jsonStr = manifest.toJsonString();
      final decoded = BackupManifest.fromJsonString(jsonStr);

      expect(decoded.format, BackupManifest.expectedFormat);
      expect(decoded.formatVersion, 1);
      expect(decoded.appSchemaVersion, 2);
      expect(decoded.mediaFiles.length, 2);
      expect(decoded.mediaFiles.first.relativePath, 'media/clip.mp4');
      expect(decoded.mediaFiles.first.sha256, 'abc123def456');
      expect(decoded.mediaFiles.first.sizeBytes, 1048576);

      expect(decoded.snapshot.templates.single.id, 'template_custom_1');
      expect(decoded.snapshot.templates.single.isCustom, isTrue);
      expect(decoded.snapshot.notebooks.single.title, 'My Diary');

      final restoredEntry = decoded.snapshot.entries.single;
      expect(restoredEntry.id, 'entry_1');
      expect(restoredEntry.title, 'Autumn Trip');
      expect(restoredEntry.mood, 5);
      expect(restoredEntry.weather, 'sunny');
      expect(restoredEntry.isWeeklyReview, isTrue);
      expect(restoredEntry.weekNumber, 42);
      expect(restoredEntry.isLocked, isTrue);
      expect(restoredEntry.entryPinHash, 'salt123:hash456');
      expect(
        restoredEntry.unlockAt?.millisecondsSinceEpoch,
        unlockAt.millisecondsSinceEpoch,
      );

      final restoredMedia = decoded.snapshot.mediaAttachments.single;
      expect(restoredMedia.mediaType, 'video');
      expect(restoredMedia.relativePath, 'media/clip.mp4');
      expect(restoredMedia.thumbnailPath, 'media/clip_thumb.webp');
      expect(restoredMedia.ocrText, 'mountain sign');
      expect(decoded.snapshot.albumCollections, isEmpty);
      expect(decoded.snapshot.albumPhotos, isEmpty);
    });

    test('round-trips schema v3 albumCollections and albumPhotos and supports legacy v2 manifests missing album keys', () {
      final now = DateTime.utc(2026, 10, 23, 15, 0);

      final snapshot = BackupDatabaseSnapshot(
        templates: const [],
        notebooks: const [],
        entries: const [],
        mediaAttachments: const [],
        albumCollections: [
          AlbumCollection(
            id: 'col_1',
            title: '江南春行纪',
            description: '山河沿路，笔底留痕',
            destinationTag: '江南',
            routeSummary: '杭州 → 乌镇 → 苏州',
            coverImagePath: 'media/album_1.webp',
            startDate: now,
            endDate: now,
            layoutPreset: 'classic_photobook',
            themeId: 'shanshui_ink',
            sortIndex: 0,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        albumPhotos: [
          AlbumPhoto(
            id: 'photo_1',
            collectionId: 'col_1',
            relativeImagePath: 'media/album_1.webp',
            relativeThumbnailPath: 'media/album_1_thumb.webp',
            caption: '西湖春晓',
            locationTag: '杭州 · 西湖',
            shotAt: now,
            sortOrder: 0,
            aspectRatio: 1.5,
            createdAt: now,
          ),
        ],
      );

      final manifest = BackupManifest(
        appSchemaVersion: 3,
        createdAt: now,
        snapshot: snapshot,
        mediaFiles: const [],
      );

      final decoded = BackupManifest.fromJsonString(manifest.toJsonString());
      expect(decoded.appSchemaVersion, equals(3));
      expect(decoded.snapshot.albumCollections.single.title, equals('江南春行纪'));
      expect(decoded.snapshot.albumCollections.single.destinationTag, equals('江南'));
      expect(decoded.snapshot.albumCollections.single.routeSummary, equals('杭州 → 乌镇 → 苏州'));
      expect(decoded.snapshot.albumPhotos.single.caption, equals('西湖春晓'));
      expect(decoded.snapshot.albumPhotos.single.aspectRatio, equals(1.5));

      // Verify legacy v2 manifest JSON with no albumCollections / albumPhotos keys deserializes cleanly
      final legacyV2 = BackupManifest.fromJson({
        'format': 'memodiary-backup',
        'formatVersion': 1,
        'appSchemaVersion': 2,
        'tables': {
          'templates': [],
          'notebooks': [],
          'entries': [],
          'mediaAttachments': [],
        },
        'mediaFiles': [],
      });
      expect(legacyV2.snapshot.albumCollections, isEmpty);
      expect(legacyV2.snapshot.albumPhotos, isEmpty);
    });

    test('rejects unsupported future formatVersion or appSchemaVersion', () {
      expect(
        () => BackupManifest.fromJson({
          'format': 'memodiary-backup',
          'formatVersion': 99,
          'appSchemaVersion': 2,
          'tables': {},
          'mediaFiles': [],
        }),
        throwsA(isA<BackupVersionException>()),
      );

      expect(
        () => BackupManifest.fromJson({
          'format': 'memodiary-backup',
          'formatVersion': 1,
          'appSchemaVersion': 99,
          'tables': {},
          'mediaFiles': [],
        }),
        throwsA(isA<BackupVersionException>()),
      );
    });
  });
}

