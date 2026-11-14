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

  File writeSandboxMediaFile(String relativePath, List<int> bytes) {
    final file = File(p.join(tempDir.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    return file;
  }

  group('AlbumRepository — CRUD, Watchers, Reordering & DB-First Deletion', () {
    test('creates, updates, reorders, and reactively watches collections', () async {
      final emittedCounts = <int>[];
      final sub = db.albumsDao.watchAllCollections().listen((list) {
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
      await db.albumsDao.reorderCollections(['col_2', 'col_1']);
      final all = await db.albumsDao.getAllCollections();
      expect(
        all.map((collection) => collection.id).toList(),
        equals(['col_2', 'col_1']),
      );
      expect(all[0].sortIndex, equals(0));
      expect(all[1].sortIndex, equals(1));

      // Update collection metadata
      await db.albumsDao.updateCollection(
        const AlbumCollectionsCompanion(
          id: Value('col_1'),
          title: Value('江南烟雨集'),
        ),
      );
      final updated = await db.albumsDao.getCollectionById('col_1');
      expect(updated!.title, equals('江南烟雨集'));

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(emittedCounts, contains(2));
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
        expect(
          MediaSandboxService.isStrictlyRelative(photo1.relativeImagePath),
          isTrue,
        );
        expect(
          MediaSandboxService.isStrictlyRelative(photo1.relativeThumbnailPath),
          isTrue,
        );
        expect(photo1.relativeThumbnailPath, endsWith('_thumb.webp'));

        // Verify physical files exist in media/ sandbox
        final file1Full =
            await mediaService.getFileFromRelativePath(photo1.relativeImagePath);
        final file1Thumb = await mediaService
            .getFileFromRelativePath(photo1.relativeThumbnailPath);
        expect(file1Full.existsSync(), isTrue);
        expect(file1Thumb.existsSync(), isTrue);

        // Verify first photo automatically became the collection's coverImagePath
        final refreshedCol = await db.albumsDao.getCollectionById('col_trip');
        expect(refreshedCol!.coverImagePath, equals(photo1.relativeImagePath));

        // Verify synthesizeRouteSummary aggregates distinct locationTags in sortOrder
        final route = await repository.synthesizeRouteSummary(
          'col_trip',
          persistToCollection: true,
        );
        expect(route, equals('杭州 → 乌镇 → 苏州'));
        expect(
          (await db.albumsDao.getCollectionById('col_trip'))!.routeSummary,
          equals('杭州 → 乌镇 → 苏州'),
        );

        // Reorder photos: photo_3 -> photo_1 -> photo_2
        await db.albumsDao
            .reorderPhotos('col_trip', ['photo_3', 'photo_1', 'photo_2']);
        final ordered = await db.albumsDao.getPhotosForCollection('col_trip');
        expect(
          ordered.map((photo) => photo.id).toList(),
          equals(['photo_3', 'photo_1', 'photo_2']),
        );
        expect(ordered[0].sortOrder, equals(0));
        expect(ordered[1].sortOrder, equals(1));
        expect(ordered[2].sortOrder, equals(2));

        // Re-synthesizing route reflects the new narrative order
        final reorderedRoute =
            await repository.synthesizeRouteSummary('col_trip');
        expect(reorderedRoute, equals('苏州 → 杭州 → 乌镇'));

        // Update annotation on photo2
        await db.albumsDao.updatePhotoAnnotation(
          photoId: photo2.id,
          caption: const Value('乌镇摇橹船灯火'),
          locationTag: const Value('嘉兴 · 乌镇'),
        );
        final updatedPhoto2 = await db.albumsDao.getPhotoById(photo2.id);
        expect(updatedPhoto2!.caption, equals('乌镇摇橹船灯火'));
        expect(updatedPhoto2.locationTag, equals('嘉兴 · 乌镇'));
      },
    );

    test(
      'deletePhoto reassigns or clears coverImagePath and deleteCollection reclaims unreferenced physical files',
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

        final p1ImgFile =
            await mediaService.getFileFromRelativePath(p1.relativeImagePath);
        final p1ThumbFile = await mediaService
            .getFileFromRelativePath(p1.relativeThumbnailPath);
        final p2ImgFile =
            await mediaService.getFileFromRelativePath(p2.relativeImagePath);
        final p2ThumbFile = await mediaService
            .getFileFromRelativePath(p2.relativeThumbnailPath);

        expect(p1ImgFile.existsSync(), isTrue);
        expect(p1ThumbFile.existsSync(), isTrue);
        expect(p2ImgFile.existsSync(), isTrue);
        expect(p2ThumbFile.existsSync(), isTrue);

        // 1. Delete cover photo p_1 -> cover advances atomically to p_2
        await repository.deletePhoto('p_1');
        expect(p1ImgFile.existsSync(), isFalse);
        expect(p1ThumbFile.existsSync(), isFalse);
        expect(await db.albumsDao.getPhotoById('p_1'), isNull);

        final colAfterP1Delete =
            await db.albumsDao.getCollectionById('col_cleanup');
        expect(colAfterP1Delete!.coverImagePath, equals(p2.relativeImagePath));

        // 2. Delete last remaining cover photo p_2 -> cover clears to null
        await repository.deletePhoto('p_2');
        expect(p2ImgFile.existsSync(), isFalse);
        expect(p2ThumbFile.existsSync(), isFalse);
        expect(await db.albumsDao.getPhotoById('p_2'), isNull);
        final colAfterP2Delete =
            await db.albumsDao.getCollectionById('col_cleanup');
        expect(colAfterP2Delete!.coverImagePath, isNull);

        // 3. Re-add photo and delete entire collection -> physical files and DB rows purged
        final p3 = await repository.ingestAndAddPhoto(
          id: 'p_3',
          collectionId: 'col_cleanup',
          sourceFile: createSourcePhotoFile('island_3.jpg'),
        );
        final p3ImgFile =
            await mediaService.getFileFromRelativePath(p3.relativeImagePath);
        final p3ThumbFile = await mediaService
            .getFileFromRelativePath(p3.relativeThumbnailPath);

        await repository.deleteCollection('col_cleanup');
        expect(p3ImgFile.existsSync(), isFalse);
        expect(p3ThumbFile.existsSync(), isFalse);
        expect(await db.albumsDao.getCollectionById('col_cleanup'), isNull);
        expect(
          await db.albumsDao.getPhotosForCollection('col_cleanup'),
          isEmpty,
        );
      },
    );

    test(
      'deletePhoto and deleteCollection preserve paths shared with other collections, album photos, or diary mediaAttachments',
      () async {
        final sharedWithEntryFile =
            writeSandboxMediaFile('media/shared_entry.webp', [1, 2, 3]);
        final sharedWithOtherAlbumFile =
            writeSandboxMediaFile('media/shared_album.webp', [4, 5, 6]);
        final sharedWithCoverFile =
            writeSandboxMediaFile('media/shared_cover.webp', [7, 8, 9]);
        final uniqueThumb1 =
            writeSandboxMediaFile('media/unique_thumb_1.webp', [10]);
        final uniqueFull2 =
            writeSandboxMediaFile('media/unique_full_2.webp', [11]);
        final uniqueThumb2 =
            writeSandboxMediaFile('media/unique_thumb_2.webp', [12]);

        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'entry_holder',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            contentDelta: '[{"insert":"Shared\\n"}]',
            plainText: 'Shared',
            entryDate: DateTime(2026, 6, 1),
          ),
        );
        await db.mediaOcrDao.attachMediaToEntry(
          id: 'att_shared',
          entryId: 'entry_holder',
          relativePath: 'media/shared_entry.webp',
        );

        await repository.createCollection(
          id: 'col_holder',
          title: 'Holder Collection',
          coverImagePath: 'media/shared_cover.webp',
        );
        await repository.addPhoto(
          id: 'photo_holder',
          collectionId: 'col_holder',
          relativeImagePath: 'media/shared_album.webp',
          relativeThumbnailPath: 'media/holder_thumb.webp',
        );

        await repository.createCollection(
          id: 'col_target',
          title: 'Target Collection',
          coverImagePath: 'media/shared_cover.webp',
        );
        await repository.addPhoto(
          id: 'photo_shared_entry',
          collectionId: 'col_target',
          relativeImagePath: 'media/shared_entry.webp',
          relativeThumbnailPath: 'media/unique_thumb_1.webp',
          sortOrder: 0,
        );
        await repository.addPhoto(
          id: 'photo_shared_album',
          collectionId: 'col_target',
          relativeImagePath: 'media/shared_album.webp',
          relativeThumbnailPath: 'media/unique_thumb_2.webp',
          sortOrder: 1,
        );
        await repository.addPhoto(
          id: 'photo_unique',
          collectionId: 'col_target',
          relativeImagePath: 'media/unique_full_2.webp',
          relativeThumbnailPath: 'media/unique_thumb_2.webp',
          sortOrder: 2,
        );

        // Delete photo_shared_entry: unique thumb deleted, shared entry image preserved
        await repository.deletePhoto('photo_shared_entry');
        expect(await db.albumsDao.getPhotoById('photo_shared_entry'), isNull);
        expect(uniqueThumb1.existsSync(), isFalse);
        expect(sharedWithEntryFile.existsSync(), isTrue);

        // Delete col_target: unique full & thumb deleted; shared album photo and shared cover preserved
        await repository.deleteCollection('col_target');
        expect(await db.albumsDao.getCollectionById('col_target'), isNull);
        expect(uniqueFull2.existsSync(), isFalse);
        expect(uniqueThumb2.existsSync(), isFalse);
        expect(sharedWithOtherAlbumFile.existsSync(), isTrue);
        expect(sharedWithCoverFile.existsSync(), isTrue);
        expect(sharedWithEntryFile.existsSync(), isTrue);
      },
    );

    test(
      'DB-first failure safety: physical files stay untouched when SQLite delete fails',
      () async {
        await repository.createCollection(
          id: 'col_fail_guard',
          title: 'Failure Safety Album',
        );
        final photo = await repository.ingestAndAddPhoto(
          id: 'photo_fail_guard',
          collectionId: 'col_fail_guard',
          sourceFile: createSourcePhotoFile('fail_guard.jpg'),
        );

        final fullFile =
            await mediaService.getFileFromRelativePath(photo.relativeImagePath);
        final thumbFile = await mediaService
            .getFileFromRelativePath(photo.relativeThumbnailPath);
        expect(fullFile.existsSync(), isTrue);
        expect(thumbFile.existsSync(), isTrue);

        // Block album_photos deletion inside SQLite
        await db.customStatement(
          "CREATE TRIGGER block_album_photo_delete BEFORE DELETE ON album_photos BEGIN SELECT RAISE(ABORT, 'simulated sqlite photo delete failure'); END;",
        );

        await expectLater(
          () => repository.deletePhoto('photo_fail_guard'),
          throwsA(anything),
        );
        expect(fullFile.existsSync(), isTrue);
        expect(thumbFile.existsSync(), isTrue);
        expect(await db.albumsDao.getPhotoById('photo_fail_guard'), isNotNull);

        await expectLater(
          () => repository.deleteCollection('col_fail_guard'),
          throwsA(anything),
        );
        expect(fullFile.existsSync(), isTrue);
        expect(thumbFile.existsSync(), isTrue);
        expect(
          await db.albumsDao.getCollectionById('col_fail_guard'),
          isNotNull,
        );

        // Remove failure trigger and confirm normal DB-first delete succeeds cleanly
        await db.customStatement('DROP TRIGGER block_album_photo_delete;');
        await repository.deleteCollection('col_fail_guard');
        expect(fullFile.existsSync(), isFalse);
        expect(thumbFile.existsSync(), isFalse);
        expect(await db.albumsDao.getCollectionById('col_fail_guard'), isNull);
      },
    );

    test(
      'setCollectionCover, watchPhotoCounts, and updatePhotoAnnotationAndSyncRoute auto-syncs route while preserving manual route override',
      () async {
        await repository.createCollection(
          id: 'col_sync',
          title: '路线同步测试',
        );

        final p1 = await repository.ingestAndAddPhoto(
          id: 'sync_p1',
          collectionId: 'col_sync',
          sourceFile: createSourcePhotoFile('sync_1.jpg'),
          locationTag: '杭州',
        );
        final p2 = await repository.ingestAndAddPhoto(
          id: 'sync_p2',
          collectionId: 'col_sync',
          sourceFile: createSourcePhotoFile('sync_2.jpg'),
          locationTag: '乌镇',
        );

        final countsMap = await db.albumsDao.watchPhotoCounts().first;
        expect(countsMap['col_sync'], equals(2));

        // 1. Auto-route sync: collection initially has null routeSummary -> editing p2 location auto-synthesizes route
        await repository.updatePhotoAnnotationAndSyncRoute(
          photoId: p2.id,
          locationTag: const Value('乌镇 · 西栅'),
        );
        var col = await db.albumsDao.getCollectionById('col_sync');
        expect(col!.routeSummary, equals('杭州 → 乌镇 · 西栅'));

        // 2. Subsequent edit while route is still equal to synthesized route updates it again
        await repository.updatePhotoAnnotationAndSyncRoute(
          photoId: p1.id,
          locationTag: const Value('杭州 · 西湖'),
        );
        col = await db.albumsDao.getCollectionById('col_sync');
        expect(col!.routeSummary, equals('杭州 · 西湖 → 乌镇 · 西栅'));

        // 3. Manual override: user sets custom routeSummary -> subsequent photo location edit preserves manual route
        await db.albumsDao.updateCollection(
          const AlbumCollectionsCompanion(
            id: Value('col_sync'),
            routeSummary: Value('自定义江南环线'),
          ),
        );
        await repository.updatePhotoAnnotationAndSyncRoute(
          photoId: p2.id,
          locationTag: const Value('苏州 · 拙政园'),
        );
        col = await db.albumsDao.getCollectionById('col_sync');
        expect(col!.routeSummary, equals('自定义江南环线'));

        // 4. setCollectionCover switches cover to p2
        await db.albumsDao.setCollectionCover('col_sync', p2.id);
        col = await db.albumsDao.getCollectionById('col_sync');
        expect(col!.coverImagePath, equals(p2.relativeImagePath));
      },
    );

    test(
      'exposes sealed streams, queries, metadata updates, cover assignment, collection reordering, and batch photo inserts',
      () async {
        final allCollectionsFuture = repository.watchAllCollections().firstWhere(
              (list) => list.length == 2 && list.first.id == 'col_sealed_b',
            );
        final countsFuture = repository
            .watchPhotoCounts()
            .firstWhere((counts) => counts['col_sealed_a'] == 2);

        await repository.createCollection(
          id: 'col_sealed_a',
          title: 'Initial A',
        );
        await repository.createCollection(
          id: 'col_sealed_b',
          title: 'Initial B',
        );

        final watchedColFuture = repository
            .watchCollectionById('col_sealed_a')
            .firstWhere((col) => col?.title == 'Updated A');
        final watchedPhotosFuture = repository
            .watchPhotosForCollection('col_sealed_a')
            .firstWhere((photos) => photos.length == 2);

        await repository.reorderCollections(['col_sealed_b', 'col_sealed_a']);
        final reorderedCollections = await allCollectionsFuture;
        expect(
          reorderedCollections.map((col) => col.id).toList(),
          equals(['col_sealed_b', 'col_sealed_a']),
        );

        await repository.updateCollectionMetadata(
          id: 'col_sealed_a',
          title: 'Updated A',
          description: 'Lakeside notes',
          destinationTag: 'Hangzhou',
          routeSummary: 'Manual Route',
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 3),
        );
        final updatedCol = await watchedColFuture;
        expect(updatedCol!.description, equals('Lakeside notes'));
        expect(updatedCol.destinationTag, equals('Hangzhou'));
        expect(updatedCol.routeSummary, equals('Manual Route'));

        final fetchedCol = await repository.getCollectionById('col_sealed_a');
        expect(fetchedCol?.title, equals('Updated A'));

        final batchResult = await repository.addPhotosBatch('col_sealed_a', [
          AlbumPhotosCompanion.insert(
            id: 'batch_p1',
            collectionId: 'col_sealed_a',
            relativeImagePath: 'media/batch_p1.webp',
            relativeThumbnailPath: 'media/batch_p1_thumb.webp',
            sortOrder: const Value(0),
          ),
          AlbumPhotosCompanion.insert(
            id: 'batch_p2',
            collectionId: 'col_sealed_a',
            relativeImagePath: 'media/batch_p2.webp',
            relativeThumbnailPath: 'media/batch_p2_thumb.webp',
            sortOrder: const Value(1),
          ),
        ]);
        expect(batchResult.map((photo) => photo.id), equals(['batch_p1', 'batch_p2']));

        final counts = await countsFuture;
        expect(counts['col_sealed_a'], equals(2));

        final watchedPhotos = await watchedPhotosFuture;
        expect(watchedPhotos.length, equals(2));

        final queriedPhotos =
            await repository.getPhotosForCollection('col_sealed_a');
        expect(queriedPhotos.map((photo) => photo.id), equals(['batch_p1', 'batch_p2']));

        final queriedPhoto2 = await repository.getPhotoById('batch_p2');
        expect(queriedPhoto2?.relativeImagePath, equals('media/batch_p2.webp'));

        await repository.setCollectionCover('col_sealed_a', 'batch_p2');
        final colAfterCover = await repository.getCollectionById('col_sealed_a');
        expect(colAfterCover!.coverImagePath, equals('media/batch_p2.webp'));
      },
    );

    test(
      'reorderPhotosAndSyncRoute and deletePhoto auto-sync routeSummary while preserving manual overrides',
      () async {
        await repository.createCollection(
          id: 'col_auto_route',
          title: 'Auto Route Sync',
        );
        final p1 = await repository.ingestAndAddPhoto(
          id: 'route_p1',
          collectionId: 'col_auto_route',
          sourceFile: createSourcePhotoFile('route_1.jpg'),
          locationTag: '杭州',
        );
        final p2 = await repository.ingestAndAddPhoto(
          id: 'route_p2',
          collectionId: 'col_auto_route',
          sourceFile: createSourcePhotoFile('route_2.jpg'),
          locationTag: '乌镇',
        );
        final p3 = await repository.ingestAndAddPhoto(
          id: 'route_p3',
          collectionId: 'col_auto_route',
          sourceFile: createSourcePhotoFile('route_3.jpg'),
          locationTag: '苏州',
        );

        // 1. Reorder while routeSummary is still empty -> auto-synthesizes new order
        await repository.reorderPhotosAndSyncRoute(
          'col_auto_route',
          [p3.id, p1.id, p2.id],
        );
        var col = await repository.getCollectionById('col_auto_route');
        expect(col!.routeSummary, equals('苏州 → 杭州 → 乌镇'));

        // 2. Delete middle waypoint photo -> re-synthesizes remaining waypoints
        await repository.deletePhoto(p1.id);
        col = await repository.getCollectionById('col_auto_route');
        expect(col!.routeSummary, equals('苏州 → 乌镇'));

        // 3. Delete remaining waypoint photos -> clears auto-route to null
        await repository.deletePhoto(p3.id);
        col = await repository.getCollectionById('col_auto_route');
        expect(col!.routeSummary, equals('乌镇'));
        await repository.deletePhoto(p2.id);
        col = await repository.getCollectionById('col_auto_route');
        expect(col!.routeSummary, isNull);

        // 4. Manual route override is preserved across reorder and delete
        final p4 = await repository.ingestAndAddPhoto(
          id: 'route_p4',
          collectionId: 'col_auto_route',
          sourceFile: createSourcePhotoFile('route_4.jpg'),
          locationTag: '南京',
        );
        final p5 = await repository.ingestAndAddPhoto(
          id: 'route_p5',
          collectionId: 'col_auto_route',
          sourceFile: createSourcePhotoFile('route_5.jpg'),
          locationTag: '扬州',
        );
        await repository.updateCollectionMetadata(
          id: 'col_auto_route',
          title: 'Auto Route Sync',
          routeSummary: '江南私家线路',
        );

        await repository.reorderPhotosAndSyncRoute(
          'col_auto_route',
          [p5.id, p4.id],
        );
        col = await repository.getCollectionById('col_auto_route');
        expect(col!.routeSummary, equals('江南私家线路'));

        await repository.deletePhoto(p4.id);
        col = await repository.getCollectionById('col_auto_route');
        expect(col!.routeSummary, equals('江南私家线路'));
      },
    );

    test(
      'loadOrSynthesizeStudioDocument defaults to autoPopulate: false and supports autoPopulate: true',
      () async {
        await repository.createCollection(
          id: 'col_studio_opts',
          title: 'Studio Options',
        );
        await repository.addPhoto(
          id: 'opt_p1',
          collectionId: 'col_studio_opts',
          relativeImagePath: 'media/opt_1.webp',
          relativeThumbnailPath: 'media/opt_1_thumb.webp',
          sortOrder: 0,
        );
        await repository.addPhoto(
          id: 'opt_p2',
          collectionId: 'col_studio_opts',
          relativeImagePath: 'media/opt_2.webp',
          relativeThumbnailPath: 'media/opt_2_thumb.webp',
          sortOrder: 1,
        );

        final blankDoc = await repository.loadOrSynthesizeStudioDocument(
          'col_studio_opts',
        );
        expect(blankDoc.pages.length, equals(1));
        expect(blankDoc.pages.first.photoSlots, isEmpty);
        expect(blankDoc.removedPhotoIds, equals(['opt_p1', 'opt_p2']));

        final populatedDoc = await repository.loadOrSynthesizeStudioDocument(
          'col_studio_opts',
          autoPopulate: true,
        );
        expect(populatedDoc.pages.first.photoSlots.length, equals(2));
        expect(populatedDoc.removedPhotoIds, isEmpty);
      },
    );
  });
}
