import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/albums/screens/album_workspace_screen.dart';
import 'album_test_harness.dart';

void main() {
  late AlbumTestHarness harness;

  setUp(() async {
    harness = await AlbumTestHarness.create();
  });

  tearDown(() async {
    await harness.dispose();
  });

  group('AlbumWorkspaceScreen Widget Tests', () {
    testWidgets('renders photos in sortOrder and toggles into ReorderableListView to persist reorder', (tester) async {
      final collection = await harness.repository.createCollection(
        title: '江南水乡行',
        destinationTag: '江南',
      );

      final src1 = harness.createSourcePhoto('p1.png');
      final src2 = harness.createSourcePhoto('p2.png');
      final src3 = harness.createSourcePhoto('p3.png');
      final p1 = await harness.repository.ingestAndAddPhoto(
        collectionId: collection.id,
        sourceFile: src1,
      );
      final p2 = await harness.repository.ingestAndAddPhoto(
        collectionId: collection.id,
        sourceFile: src2,
      );
      final p3 = await harness.repository.ingestAndAddPhoto(
        collectionId: collection.id,
        sourceFile: src3,
      );
      final photos = [p1, p2, p3];

      await harness.repository.updatePhotoAnnotationAndSyncRoute(
        photoId: photos[0].id,
        caption: const Value('第一站：西湖'),
        locationTag: const Value('杭州'),
      );
      await harness.repository.updatePhotoAnnotationAndSyncRoute(
        photoId: photos[1].id,
        caption: const Value('第二站：西栅'),
        locationTag: const Value('乌镇'),
      );
      await harness.repository.updatePhotoAnnotationAndSyncRoute(
        photoId: photos[2].id,
        caption: const Value('第三站：平江路'),
        locationTag: const Value('苏州'),
      );

      await pumpAlbumScreen(
        tester,
        AlbumWorkspaceScreen(
          collectionId: collection.id,
          database: harness.database,
          mediaService: harness.mediaService,
          repository: harness.repository,
          ingestionService: harness.ingestionService,
        ),
      );
      await tester.pumpAndSettle();

      // Verify header & auto-synthesized route banner
      expect(find.text('江南水乡行'), findsOneWidget);
      expect(find.text('3 张影像'), findsOneWidget);
      expect(find.byKey(const Key('workspace_route_banner')), findsOneWidget);
      expect(find.text('杭州 → 乌镇 → 苏州'), findsOneWidget);

      // Verify browse grid tiles exist
      expect(
        find.byKey(Key('workspace_photo_tile_${photos[0].id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('workspace_photo_tile_${photos[1].id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('workspace_photo_tile_${photos[2].id}')),
        findsOneWidget,
      );

      // Toggle into reorder mode
      final reorderToggle = find.byKey(const Key('workspace_reorder_toggle'));
      expect(reorderToggle, findsOneWidget);
      await tester.tap(reorderToggle);
      await tester.pumpAndSettle();

      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(find.byKey(Key('reorder_tile_${photos[0].id}')), findsOneWidget);
      expect(find.byKey(Key('reorder_tile_${photos[2].id}')), findsOneWidget);

      // Invoke onReorderItem callback on ReorderableListView to move index 2 to 0
      final reorderList = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      reorderList.onReorderItem!(2, 0);
      await tester.pumpAndSettle();

      final updatedPhotos = await harness.repository.getPhotosForCollection(
        collection.id,
      );
      expect(
        updatedPhotos.map((photo) => photo.id).toList(),
        [photos[2].id, photos[0].id, photos[1].id],
      );

      // Route summary should auto-update to reflect the new order
      final updatedCollection = await harness.repository.getCollectionById(
        collection.id,
      );
      expect(updatedCollection!.routeSummary, '苏州 → 杭州 → 乌镇');

      await tearDownAlbumScreen(tester);
    });

    testWidgets('imports batch photos via workspace_add_photos and updates grid', (tester) async {
      final collection = await harness.repository.createCollection(
        title: '海岛假日',
      );
      final pickFile1 = harness.createSourcePhoto('beach1.png');
      final pickFile2 = harness.createSourcePhoto('beach2.png');

      await pumpAlbumScreen(
        tester,
        AlbumWorkspaceScreen(
          collectionId: collection.id,
          database: harness.database,
          mediaService: harness.mediaService,
          repository: harness.repository,
          ingestionService: harness.ingestionService,
          customFilesPicker: () async => [pickFile1, pickFile2],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 张影像'), findsOneWidget);
      expect(find.byKey(const Key('workspace_empty_add_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('workspace_add_photos')));
      await tester.pumpAndSettle();

      expect(find.text('2 张影像'), findsOneWidget);
      expect(find.textContaining('已导入 2 张照片'), findsOneWidget);

      await tearDownAlbumScreen(tester);
    });
  });
}
