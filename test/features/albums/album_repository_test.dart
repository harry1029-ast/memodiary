import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/albums/data/album_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late MediaSandboxService mediaService;
  late AlbumRepository repository;

  /// Deterministic 1x1 PNG fixture bytes for sandboxed image ingestion tests
  final sampleImageBytes = MediaSandboxService.generateProceduralVideoPoster;

  setUp(() {
    db = AppDatabase.memory();
    tempDir = Directory.systemTemp.createTempSync('memodiary_album_repo_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
      compressor: (
        sourcePath,
        targetPath, {
        int minWidth = 1600,
        int minHeight = 1600,
        int quality = 80,
      }) async {
        final target = File(targetPath);
        await target.parent.create(recursive: true);
        // Write deterministic RIFF WEBP header + payload
        await target.writeAsBytes([
          0x52, 0x49, 0x46, 0x46, 0x10, 0x00, 0x00, 0x00,
          0x57, 0x45, 0x42, 0x50, minWidth & 0xFF, quality & 0xFF,
        ]);
        return target;
      },
    );
    repository = AlbumRepository(
      database: db,
      mediaService: mediaService,
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  File createSourcePhotoFile(String filename) {
    final file = File(p.join(tempDir.path, filename));
    file.writeAsBytesSync([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      1, 2, 3, 4,
    ]);
    return file;
  }

  group('AlbumRepository — CRUD, Watchers, Reordering & Cascade File Cleanup', () {
    test('creates, updates, reorders, and reactively watches collections', () async {
      final emittedCounts = <int>[];
      final sub = repository.watchAllCollections().listen((list) {
        emittedCounts.add(list.length);
      });
      addTearDown(() => sub.cancel());

      final col1 = await repository.createCollection(
        id: 'col_1',
        title: '江南春行纪',
        description: '雨窗独坐，山河留痕',
        destinationTag: '江南',
        routeSummary: '杭州 → 乌镇 → 苏州',
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 6),
      );
      final col2 = await repository.createCollection(
        id: 'col_2',
        title: '川西雪山行',
        destinationTag: '川西',
        routeSummary: '康定 → 新都桥 → 稻城',
      );

      expect(col1.title, equals('江南春行纪'));
      expect(col1.destinationTag, equals('江南'));
      expect(col1.routeSummary, equals('杭州 → 乌镇 → 苏州'));
      expect(col1.sortIndex, equals(0));
      expect(col2.sortIndex, equals(1));

      // Reorder col_2 before col_1
      await repository.reorderCollections(['col_2', 'col_1']);
      final all = await repository.getAllCollections();
      expect(all.map((collection) => collection.id).toList(), equals(['col_2', 'col_1']));
      expect(all[0].sortIndex, equals(0));
      expect(all[1].sortIndex, equals(1));

      // Update collection metadata
      await repository.updateCollection(
        const AlbumCollectionsCompanion(
          id: Value('col_1'),
          title: Value('江南烟雨集'),
        ),
      );
      final updated = await repository.getCollectionById('col_1');
      expect(updated!.title, equals('江南烟雨集'));

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(emittedCounts, contains(2));
      expect(sampleImageBytes, isNotNull);
    });

    test(
      'ingests dual-resolution WebP photos, auto-assigns coverImagePath, updates annotations, reorders, and synthesizes route trajectory',
      () async {
        final col = await repository.createCollection(
          id: 'col_trip',
          title: '江南水乡行',
          destinationTag: '江南',
        );
        expect(col.coverImagePath, isNull);

        final src1 = createSourcePhotoFile('raw_1.jpg');
        final src2 = createSourcePhotoFile('raw_2.jpg');
        final src3 = createSourcePhotoFile('raw_3.jpg');

        final photo1 = await repository.ingestAndAddPhoto(
          id: 'photo_1',
          collectionId: 'col_trip',
          sourceFile: src1,
          caption: '西湖晨雾',
          locationTag: '杭州',
          shotAt: DateTime(2026, 5, 1, 7, 0),
        );
        final photo2 = await repository.ingestAndAddPhoto(
          id: 'photo_2',
          collectionId: 'col_trip',
          sourceFile: src2,
          caption: '西栅夜航',
          locationTag: '乌镇',
          shotAt: DateTime(2026, 5, 2, 20, 0),
        );
        final photo3 = await repository.ingestAndAddPhoto(
          id: 'photo_3',
          collectionId: 'col_trip',
          sourceFile: src3,
          caption: '拙政园听雨',
          locationTag: '苏州',
          shotAt: DateTime(2026, 5, 3, 14, 0),
        );
        expect(photo3.id, equals('photo_3'));

        // Verify strictly relative WebP and _thumb.webp paths
        expect(MediaSandboxService.isStrictlyRelative(photo1.relativeImagePath), isTrue);
        expect(MediaSandboxService.isStrictlyRelative(photo1.relativeThumbnailPath), isTrue);
        expect(photo1.relativeThumbnailPath, endsWith('_thumb.webp'));

        // Verify physical files exist in media/ sandbox
        final file1Full = await mediaService.getFileFromRelativePath(photo1.relativeImagePath);
        final file1Thumb = await mediaService.getFileFromRelativePath(photo1.relativeThumbnailPath);
        expect(file1Full.existsSync(), isTrue);
        expect(file1Thumb.existsSync(), isTrue);

        // Verify first photo automatically became the collection's coverImagePath
        final refreshedCol = await repository.getCollectionById('col_trip');
        expect(refreshedCol!.coverImagePath, equals(photo1.relativeImagePath));

        // Verify synthesizeRouteSummary aggregates distinct locationTags in sortOrder
        final route = await repository.synthesizeRouteSummary(
          'col_trip',
          persistToCollection: true,
        );
        expect(route, equals('杭州 → 乌镇 → 苏州'));
        expect(
          (await repository.getCollectionById('col_trip'))!.routeSummary,
          equals('杭州 → 乌镇 → 苏州'),
        );

        // Reorder photos: photo_3 -> photo_1 -> photo_2
        await repository.reorderPhotos('col_trip', ['photo_3', 'photo_1', 'photo_2']);
        final ordered = await repository.getPhotosForCollection('col_trip');
        expect(
          ordered.map((photo) => photo.id).toList(),
          equals(['photo_3', 'photo_1', 'photo_2']),
        );
        expect(ordered[0].sortOrder, equals(0));
        expect(ordered[1].sortOrder, equals(1));
        expect(ordered[2].sortOrder, equals(2));

        // Re-synthesizing route reflects the new narrative order
        final reorderedRoute = await repository.synthesizeRouteSummary('col_trip');
        expect(reorderedRoute, equals('苏州 → 杭州 → 乌镇'));

        // Update annotation on photo2
        await repository.updatePhotoAnnotation(
          photoId: photo2.id,
          caption: const Value('乌镇摇橹船灯火'),
          locationTag: const Value('嘉兴 · 乌镇'),
        );
        final updatedPhoto2 = await repository.getPhotoById(photo2.id);
        expect(updatedPhoto2!.caption, equals('乌镇摇橹船灯火'));
        expect(updatedPhoto2.locationTag, equals('嘉兴 · 乌镇'));
      },
    );

    test(
      'deletePhoto and deleteCollection reclaim physical .webp and _thumb.webp files from disk without leaving orphans',
      () async {
        await repository.createCollection(
          id: 'col_cleanup',
          title: '海岛拾光',
        );

        final p1 = await repository.ingestAndAddPhoto(
          id: 'p_1',
          collectionId: 'col_cleanup',
          sourceFile: createSourcePhotoFile('island_1.jpg'),
        );
        final p2 = await repository.ingestAndAddPhoto(
          id: 'p_2',
          collectionId: 'col_cleanup',
          sourceFile: createSourcePhotoFile('island_2.jpg'),
        );

        final p1ImgFile = await mediaService.getFileFromRelativePath(p1.relativeImagePath);
        final p1ThumbFile = await mediaService.getFileFromRelativePath(p1.relativeThumbnailPath);
        final p2ImgFile = await mediaService.getFileFromRelativePath(p2.relativeImagePath);
        final p2ThumbFile = await mediaService.getFileFromRelativePath(p2.relativeThumbnailPath);

        expect(p1ImgFile.existsSync(), isTrue);
        expect(p1ThumbFile.existsSync(), isTrue);
        expect(p2ImgFile.existsSync(), isTrue);
        expect(p2ThumbFile.existsSync(), isTrue);

        // 1. Delete single photo p_1 (which was also the auto-assigned cover photo)
        await repository.deletePhoto('p_1');
        expect(p1ImgFile.existsSync(), isFalse);
        expect(p1ThumbFile.existsSync(), isFalse);
        expect(await repository.getPhotoById('p_1'), isNull);

        // Cover photo should automatically advance to p_2
        final colAfterP1Delete = await repository.getCollectionById('col_cleanup');
        expect(colAfterP1Delete!.coverImagePath, equals(p2.relativeImagePath));

        // 2. Delete entire collection -> p_2 physical files and DB rows must be purged
        await repository.deleteCollection('col_cleanup');
        expect(p2ImgFile.existsSync(), isFalse);
        expect(p2ThumbFile.existsSync(), isFalse);
        expect(await repository.getCollectionById('col_cleanup'), isNull);
        expect(await repository.getPhotosForCollection('col_cleanup'), isEmpty);
      },
    );
  });
}
