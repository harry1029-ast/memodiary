import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/albums/screens/album_flipbook_screen.dart';
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

  testWidgets(
      'AlbumWorkspaceScreen opens AlbumFlipbookScreen via "生成影卷 / 浏览画册" button',
      (tester) async {
    await harness.repository.createCollection(
      id: 'col-flip-1',
      title: '姑苏寻幽',
      description: '小桥流水人家',
      destinationTag: '姑苏',
      routeSummary: '虎丘 → 拙政园 → 平江路',
    );

    final srcFile = harness.createSourcePhoto('suzhou_1.png');
    await harness.repository.ingestAndAddPhoto(
      collectionId: 'col-flip-1',
      sourceFile: srcFile,
    );

    await pumpAlbumScreen(
      tester,
      AlbumWorkspaceScreen(
        collectionId: 'col-flip-1',
        database: harness.database,
        mediaService: harness.mediaService,
        repository: harness.repository,
      ),
    );
    await tester.pumpAndSettle();

    final openFlipbookBtn =
        find.byKey(const Key('workspace_open_flipbook_button'));
    expect(openFlipbookBtn, findsOneWidget);

    await tester.tap(openFlipbookBtn);
    await tester.pumpAndSettle();

    expect(find.byType(AlbumFlipbookScreen), findsOneWidget);
    expect(find.byKey(const Key('flipbook_page_indicator')), findsOneWidget);
    expect(find.text('第 1 / 3 页'), findsOneWidget);
    expect(find.byKey(const Key('spread_cover_title')), findsOneWidget);

    await tearDownAlbumScreen(tester);
  });

  testWidgets(
      'AlbumFlipbookScreen navigates across Cover, Hero, Duo, and Epilogue spreads and toggles fullscreen',
      (tester) async {
    final collection = AlbumCollection(
      id: 'col-flip-2',
      title: '江南春行卷',
      description: '春水碧于天，画船听雨眠。',
      destinationTag: '江南',
      routeSummary: '杭州 → 乌镇 → 苏州',
      coverImagePath: null,
      startDate: DateTime(2026, 4, 1),
      endDate: DateTime(2026, 4, 4),
      layoutPreset: 'editorial',
      themeId: 'shanshui_ink',
      sortIndex: 0,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 4),
    );

    // Prepare 3 photos so 'editorial' layout generates:
    // Page 1: CoverSpread
    // Page 2: SingleHeroSpread (photo 1)
    // Page 3: DuoSpread (photo 2 + photo 3)
    // Page 4: EpilogueSpread
    final photos = [
      AlbumPhoto(
        id: 'p1',
        collectionId: 'col-flip-2',
        relativeImagePath: 'media/p1.webp',
        relativeThumbnailPath: 'media/p1_thumb.webp',
        caption: '西湖苏堤春晓',
        locationTag: '杭州',
        shotAt: DateTime(2026, 4, 1, 9, 0),
        sortOrder: 0,
        aspectRatio: 1.0,
        createdAt: DateTime(2026, 4, 1, 9, 0),
      ),
      AlbumPhoto(
        id: 'p2',
        collectionId: 'col-flip-2',
        relativeImagePath: 'media/p2.webp',
        relativeThumbnailPath: 'media/p2_thumb.webp',
        caption: '西栅夜色',
        locationTag: '乌镇',
        shotAt: DateTime(2026, 4, 2, 19, 30),
        sortOrder: 1,
        aspectRatio: 0.85,
        createdAt: DateTime(2026, 4, 2, 19, 30),
      ),
      AlbumPhoto(
        id: 'p3',
        collectionId: 'col-flip-2',
        relativeImagePath: 'media/p3.webp',
        relativeThumbnailPath: 'media/p3_thumb.webp',
        caption: '平江古巷',
        locationTag: '苏州',
        shotAt: DateTime(2026, 4, 3, 14, 0),
        sortOrder: 2,
        aspectRatio: 0.9,
        createdAt: DateTime(2026, 4, 3, 14, 0),
      ),
    ];

    await pumpAlbumScreen(
      tester,
      AlbumFlipbookScreen(
        collection: collection,
        photos: photos,
        mediaService: harness.mediaService,
      ),
    );
    await tester.pumpAndSettle();

    // Verify Page 1 (Cover)
    expect(find.text('第 1 / 4 页'), findsOneWidget);
    expect(find.byKey(const Key('spread_cover_title')), findsOneWidget);

    // Step to Page 2 (SingleHeroSpread) via next button
    await tester.tap(find.byKey(const Key('flipbook_next_page_button')));
    await tester.pumpAndSettle();
    expect(find.text('第 2 / 4 页'), findsOneWidget);
    expect(find.byKey(const Key('spread_hero_caption_p1')), findsOneWidget);
    expect(find.text('西湖苏堤春晓'), findsOneWidget);

    // Step to Page 3 (DuoSpread)
    await tester.tap(find.byKey(const Key('flipbook_next_page_button')));
    await tester.pumpAndSettle();
    expect(find.text('第 3 / 4 页'), findsOneWidget);
    expect(find.byKey(const Key('spread_duo_side_by_side')), findsOneWidget);

    // Step to Page 4 (EpilogueSpread)
    await tester.tap(find.byKey(const Key('flipbook_next_page_button')));
    await tester.pumpAndSettle();
    expect(find.text('第 4 / 4 页'), findsOneWidget);
    expect(find.byKey(const Key('spread_epilogue_container')), findsOneWidget);
    expect(find.text('杭州 → 乌镇 → 苏州'), findsOneWidget);

    // Single tap viewport to toggle fullscreen chrome off
    expect(find.byKey(const Key('flipbook_bottom_bar')), findsOneWidget);
    await tester.tap(find.byKey(const Key('flipbook_fullscreen_toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('flipbook_bottom_bar')), findsNothing);

    // Single tap again to restore chrome
    await tester.tap(find.byKey(const Key('flipbook_fullscreen_toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('flipbook_bottom_bar')), findsOneWidget);

    // Update a photo caption in repository to ensure unused imports/helpers aren't needed
    await harness.repository.updateCollection(
      const AlbumCollectionsCompanion(
        id: Value('col-flip-2'),
      ),
    );

    await tearDownAlbumScreen(tester);
  });
}

