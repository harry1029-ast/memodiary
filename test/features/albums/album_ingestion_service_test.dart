import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/albums/services/album_ingestion_service.dart';
import 'package:path/path.dart' as p;
import 'album_test_harness.dart';

void main() {
  late AlbumTestHarness harness;
  final fallbackTime = DateTime(2026, 10, 23, 18, 0);
  final exifTime = DateTime(2026, 4, 2, 9, 15);

  setUp(() async {
    harness = await AlbumTestHarness.create(
      captureDateReader: (file) async {
        if (file.path.endsWith('with_exif.jpg')) {
          return exifTime;
        }
        return null;
      },
      clock: () => fallbackTime,
    );
  });

  tearDown(() async {
    await harness.dispose();
  });

  group('AlbumIngestionService — Sequential Batch Ingestion, Progress & Error Resilience', () {
    test('ingests 3 photos sequentially, preserves EXIF vs clock fallback, and auto-assigns cover', () async {
      await harness.repository.createCollection(
        id: 'col_batch',
        title: '江南春行纪',
      );

      final f1 = harness.createSourcePhoto('photo_1_with_exif.jpg');
      final f2 = harness.createSourcePhoto('photo_2.jpg');
      final f3 = harness.createSourcePhoto('photo_3.jpg');

      final progressEvents = <IngestionProgress>[];
      final result = await harness.ingestionService.ingest(
        collectionId: 'col_batch',
        sources: [f1, f2, f3],
        onProgress: progressEvents.add,
      );

      expect(result.imported, equals(3));
      expect(result.failed, equals(0));
      expect(result.wasCancelled, isFalse);
      expect(progressEvents.last.isDone, isTrue);
      expect(progressEvents.last.processed, equals(3));

      final photos = await harness.repository.getPhotosForCollection('col_batch');
      expect(photos.length, equals(3));
      expect(photos[0].sortOrder, equals(0));
      expect(photos[1].sortOrder, equals(1));
      expect(photos[2].sortOrder, equals(2));
      expect(photos[0].shotAt, equals(exifTime));
      expect(photos[1].shotAt, equals(fallbackTime));

      final updatedCol = await harness.repository.getCollectionById('col_batch');
      expect(updatedCol!.coverImagePath, equals(photos[0].relativeImagePath));
    });

    test('skips missing/corrupted source file while committing valid files in the batch', () async {
      await harness.repository.createCollection(
        id: 'col_partial',
        title: '部分导入测试',
      );

      final valid1 = harness.createSourcePhoto('valid_1.jpg');
      final missing = File(p.join(harness.tempDir.path, 'does_not_exist.jpg'));
      final valid2 = harness.createSourcePhoto('valid_2.jpg');

      final result = await harness.ingestionService.ingest(
        collectionId: 'col_partial',
        sources: [valid1, missing, valid2],
      );

      expect(result.imported, equals(2));
      expect(result.failed, equals(1));

      final photos = await harness.repository.getPhotosForCollection('col_partial');
      expect(photos.length, equals(2));
    });

    test('commits already-processed photos when cancelled mid-batch', () async {
      await harness.repository.createCollection(
        id: 'col_cancel',
        title: '中断导入测试',
      );

      final files = List.generate(
        5,
        (index) => harness.createSourcePhoto('cancel_$index.jpg'),
      );

      var processedSoFar = 0;
      final result = await harness.ingestionService.ingest(
        collectionId: 'col_cancel',
        sources: files,
        onProgress: (progress) {
          processedSoFar = progress.processed;
        },
        isCancelled: () => processedSoFar >= 2,
      );

      expect(result.wasCancelled, isTrue);
      expect(result.imported, equals(2));

      final savedPhotos = await harness.repository.getPhotosForCollection('col_cancel');
      expect(savedPhotos.length, equals(2));
    });

    test('caps batch size at 50 photos when more than 50 are passed', () async {
      await harness.repository.createCollection(
        id: 'col_cap',
        title: '上限测试',
      );

      final files = List.generate(
        55,
        (index) => harness.createSourcePhoto('cap_$index.jpg'),
      );

      final result = await harness.ingestionService.ingest(
        collectionId: 'col_cap',
        sources: files,
      );

      expect(result.wasTruncatedToMax, isTrue);
      expect(result.imported, equals(50));
      final savedPhotos = await harness.repository.getPhotosForCollection('col_cap');
      expect(savedPhotos.length, equals(50));
    });
  });
}

