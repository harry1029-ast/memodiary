import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/albums/widgets/photo_annotation_sheet.dart';
import 'album_test_harness.dart';

void main() {
  late AlbumTestHarness harness;

  setUp(() async {
    harness = await AlbumTestHarness.create();
  });

  tearDown(() async {
    await harness.dispose();
  });

  group('PhotoAnnotationSheet Widget Tests', () {
    testWidgets('saves caption and locationTag and auto-updates collection routeSummary', (tester) async {
      final collection = await harness.repository.createCollection(
        title: '西湖春游',
      );
      final src1 = harness.createSourcePhoto('westlake1.png');
      final src2 = harness.createSourcePhoto('westlake2.png');
      final p1 = await harness.repository.ingestAndAddPhoto(
        collectionId: collection.id,
        sourceFile: src1,
      );
      final p2 = await harness.repository.ingestAndAddPhoto(
        collectionId: collection.id,
        sourceFile: src2,
      );
      final photos = [p1, p2];

      final refreshedCollection =
          (await harness.repository.getCollectionById(collection.id))!;

      await pumpAlbumScreen(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                key: const Key('open_annotation_btn'),
                onPressed: () => PhotoAnnotationSheet.show(
                  context,
                  photo: photos[1],
                  collection: refreshedCollection,
                  repository: harness.repository,
                  mediaService: harness.mediaService,
                ),
                child: const Text('Annotate'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_annotation_btn')));
      await tester.pumpAndSettle();

      expect(find.text('写影札'), findsOneWidget);

      // Set photo[1] as collection cover
      await tester.tap(find.byKey(const Key('annotation_set_cover')));
      await tester.pumpAndSettle();
      expect(find.text('当前封面'), findsOneWidget);

      final afterCover =
          await harness.repository.getCollectionById(collection.id);
      expect(afterCover!.coverImagePath, photos[1].relativeImagePath);

      // Enter locationTag and caption
      await tester.enterText(
        find.byKey(const Key('annotation_location_field')),
        '西湖断桥',
      );
      await tester.enterText(
        find.byKey(const Key('annotation_caption_field')),
        '柳浪闻莺，微雨初晴。',
      );

      await tester.tap(find.byKey(const Key('annotation_save')));
      await tester.pumpAndSettle();

      final updatedPhotos =
          await harness.repository.getPhotosForCollection(collection.id);
      final updatedSecond =
          updatedPhotos.firstWhere((item) => item.id == photos[1].id);
      expect(updatedSecond.locationTag, '西湖断桥');
      expect(updatedSecond.caption, '柳浪闻莺，微雨初晴。');

      final afterRoute =
          await harness.repository.getCollectionById(collection.id);
      expect(afterRoute!.routeSummary, '西湖断桥');
    });

    testWidgets('deletes photo and removes physical files on confirmation', (tester) async {
      final collection = await harness.repository.createCollection(
        title: '姑苏行',
      );
      final src = harness.createSourcePhoto('suzhou.png');
      final photo = await harness.repository.ingestAndAddPhoto(
        collectionId: collection.id,
        sourceFile: src,
      );

      final fullResFile = await harness.mediaService.getFileFromRelativePath(
        photo.relativeImagePath,
      );
      final thumbFile = await harness.mediaService.getFileFromRelativePath(
        photo.relativeThumbnailPath,
      );
      expect(fullResFile.existsSync(), isTrue);
      expect(thumbFile.existsSync(), isTrue);

      final refreshedCollection =
          (await harness.repository.getCollectionById(collection.id))!;

      await pumpAlbumScreen(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                key: const Key('open_annotation_delete_btn'),
                onPressed: () => PhotoAnnotationSheet.show(
                  context,
                  photo: photo,
                  collection: refreshedCollection,
                  repository: harness.repository,
                  mediaService: harness.mediaService,
                ),
                child: const Text('Annotate'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_annotation_delete_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('annotation_delete')));
      await tester.pumpAndSettle();

      expect(find.text('删除这张照片？'), findsOneWidget);
      await tester.tap(find.byKey(const Key('annotation_delete_confirm')));
      await tester.pumpAndSettle();

      final remaining =
          await harness.repository.getPhotosForCollection(collection.id);
      expect(remaining, isEmpty);
      expect(fullResFile.existsSync(), isFalse);
      expect(thumbFile.existsSync(), isFalse);
    });
  });
}
