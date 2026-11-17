import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/albums/models/album_studio_models.dart';
import 'package:memodiary/features/albums/screens/album_book_overview_screen.dart';
import 'package:memodiary/features/albums/screens/album_flipbook_screen.dart';
import 'package:memodiary/features/albums/screens/album_page_editor_screen.dart';
import 'package:memodiary/features/albums/screens/album_workspace_screen.dart';
import 'package:memodiary/features/albums/services/album_studio_controller.dart';
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
    expect(find.text('第 1 / 1 页'), findsOneWidget);
    expect(find.byKey(const Key('spread_cover_title')), findsOneWidget);

    await tearDownAlbumScreen(tester);
  });

  testWidgets(
      'AlbumFlipbookScreen navigates across facing spreads and toggles fullscreen',
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

    // Prepare 3 photos for multi-photo collage photobook spreads:
    // Spread 1: Cover (left) + Page 1 (right)
    // Spread 2: Page 2 (left) + Page 3 (right)
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

    final studioDocument = AlbumStudioDocument(
      pages: [
        AlbumPageModel(
          id: 'p1_model',
          pageNumber: 1,
          layoutTemplateId: 'solo_full_bleed',
          photoSlots: const [
            PhotoSlotAssignment(slotIndex: 0, photoId: 'p1'),
          ],
          backgroundConfig: const PageBackgroundConfig(
            backgroundColorArgb: 0xFFFCF9F2,
          ),
        ),
        AlbumPageModel(
          id: 'p2_model',
          pageNumber: 2,
          layoutTemplateId: 'solo_full_bleed',
          photoSlots: const [
            PhotoSlotAssignment(slotIndex: 0, photoId: 'p2'),
          ],
          backgroundConfig: const PageBackgroundConfig(
            backgroundColorArgb: 0xFFFCF9F2,
          ),
        ),
        AlbumPageModel(
          id: 'p3_model',
          pageNumber: 3,
          layoutTemplateId: 'solo_full_bleed',
          photoSlots: const [
            PhotoSlotAssignment(slotIndex: 0, photoId: 'p3'),
          ],
          backgroundConfig: const PageBackgroundConfig(
            backgroundColorArgb: 0xFFFCF9F2,
          ),
        ),
      ],
    );

    await pumpAlbumScreen(
      tester,
      AlbumFlipbookScreen(
        collection: collection,
        photos: photos,
        studioDocument: studioDocument,
        repository: harness.repository,
        mediaService: harness.mediaService,
      ),
    );
    await tester.pumpAndSettle();

    // Verify Spread 1 (Cover on left, Page 1 on right)
    expect(find.text('第 1 / 2 页'), findsOneWidget);
    expect(find.byKey(const Key('spread_cover_title')), findsOneWidget);

    // Step to Spread 2 (Page 2 on left, Page 3 on right) via next button
    await tester.tap(find.byKey(const Key('flipbook_next_page_button')));
    await tester.pumpAndSettle();
    expect(find.text('第 2 / 2 页'), findsOneWidget);

    // Single tap viewport to toggle fullscreen chrome off
    expect(find.byKey(const Key('flipbook_bottom_bar')), findsOneWidget);
    await tester.tap(find.byKey(const Key('flipbook_fullscreen_toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('flipbook_bottom_bar')), findsNothing);

    // Single tap again to restore chrome
    await tester.tap(find.byKey(const Key('flipbook_fullscreen_toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('flipbook_bottom_bar')), findsOneWidget);

    // Tap on Edit Studio button in AppBar to open AlbumPageEditorScreen
    final editBtn = find.byKey(const Key('flipbook_edit_button'));
    expect(editBtn, findsOneWidget);
    await tester.tap(editBtn);
    await tester.pumpAndSettle();
    expect(find.byType(AlbumPageEditorScreen), findsOneWidget);

    // Close page editor to return
    await tester.tap(find.byKey(const Key('page_editor_confirm_button')));
    await tester.pumpAndSettle();
    expect(find.byType(AlbumFlipbookScreen), findsOneWidget);

    await tearDownAlbumScreen(tester);
  });

  testWidgets(
      'Overview -> Flipbook -> Page Editor shares one controller, opens active spread page, and propagates edits back',
      (tester) async {
    await harness.repository.createCollection(
      id: 'col-shared-roundtrip',
      title: '灵隐问道',
      destinationTag: '杭州',
    );
    final photoIds = <String>[];
    for (var i = 0; i < 3; i++) {
      final src = harness.createSourcePhoto('lingyin_$i.png');
      final photo = await harness.repository.ingestAndAddPhoto(
        collectionId: 'col-shared-roundtrip',
        sourceFile: src,
      );
      photoIds.add(photo.id);
    }

    final seedDoc = AlbumStudioDocument(
      pages: [
        for (var i = 0; i < 3; i++)
          AlbumPageModel(
            id: 'page_${i + 1}',
            pageNumber: i + 1,
            layoutTemplateId: 'solo_full_bleed',
            photoSlots: [
              PhotoSlotAssignment(slotIndex: 0, photoId: photoIds[i]),
            ],
          ),
      ],
    );
    await harness.repository.saveStudioDocument('col-shared-roundtrip', seedDoc);

    final collection =
        (await harness.repository.getCollectionById('col-shared-roundtrip'))!;
    final photos =
        await harness.repository.getPhotosForCollection('col-shared-roundtrip');

    await pumpAlbumScreen(
      tester,
      AlbumBookOverviewScreen(
        collection: collection,
        photos: photos,
        repository: harness.repository,
        mediaService: harness.mediaService,
      ),
      viewportSize: const Size(800, 1400),
    );
    await tester.pumpAndSettle();

    // Open Flipbook from Book Overview
    await tester.tap(find.byKey(const Key('book_overview_flipbook_button')));
    await tester.pumpAndSettle();
    expect(find.byType(AlbumFlipbookScreen), findsOneWidget);
    expect(find.text('第 1 / 2 页'), findsOneWidget);

    // Step to Spread 2 (Page 2 left, Page 3 right)
    await tester.tap(find.byKey(const Key('flipbook_next_page_button')));
    await tester.pumpAndSettle();
    expect(find.text('第 2 / 2 页'), findsOneWidget);

    // Tap Edit -> opens Page Editor at Spread 2's first editable page (Page 2 / 3)
    await tester.tap(find.byKey(const Key('flipbook_edit_button')));
    await tester.pumpAndSettle();
    expect(find.byType(AlbumPageEditorScreen), findsOneWidget);
    expect(find.text('第 2 / 3 页'), findsOneWidget);

    // Add a seal stamp overlay to Page 2 and set photo on Page 2 as collection cover
    await tester.tap(find.byKey(const Key('studio_tab_add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('studio_add_seal_stamp')));
    await tester.pumpAndSettle();

    // Return to Flipbook -> Page 2 displays the new overlay immediately
    await tester.tap(find.byKey(const Key('page_editor_confirm_button')));
    await tester.pumpAndSettle();
    expect(find.byType(AlbumFlipbookScreen), findsOneWidget);
    expect(find.text('拾光'), findsWidgets);

    // Pop Flipbook back to Book Overview -> Book Overview shares the same session
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AlbumBookOverviewScreen), findsOneWidget);
    expect(find.text('拾光'), findsWidgets);

    await tearDownAlbumScreen(tester);
  });

  testWidgets(
      'AlbumFlipbookScreen clamps spread index when spreads shrink and does not dispose external controller',
      (tester) async {
    await harness.repository.createCollection(
      id: 'col-flip-clamp',
      title: '飞来峰',
      destinationTag: '杭州',
    );
    final photoIds = <String>[];
    for (var i = 0; i < 3; i++) {
      final src = harness.createSourcePhoto('flf_$i.png');
      final photo = await harness.repository.ingestAndAddPhoto(
        collectionId: 'col-flip-clamp',
        sourceFile: src,
      );
      photoIds.add(photo.id);
    }

    final doc = AlbumStudioDocument(
      pages: [
        for (var i = 0; i < 3; i++)
          AlbumPageModel(
            id: 'clamp_page_${i + 1}',
            pageNumber: i + 1,
            layoutTemplateId: 'solo_full_bleed',
            photoSlots: [
              PhotoSlotAssignment(slotIndex: 0, photoId: photoIds[i]),
            ],
          ),
      ],
    );
    final collection =
        (await harness.repository.getCollectionById('col-flip-clamp'))!;
    final photos =
        await harness.repository.getPhotosForCollection('col-flip-clamp');
    final externalController = AlbumStudioController(
      collectionId: 'col-flip-clamp',
      initialDocument: doc,
      initialCollection: collection,
      initialPhotos: photos,
      repository: harness.repository,
    );

    await pumpAlbumScreen(
      tester,
      AlbumFlipbookScreen(
        controller: externalController,
        collection: collection,
        photos: const [],
        repository: harness.repository,
        mediaService: harness.mediaService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('flipbook_next_page_button')));
    await tester.pumpAndSettle();
    expect(find.text('第 2 / 2 页'), findsOneWidget);

    // Shrink document from 3 pages (2 spreads) down to 1 page (1 spread)
    externalController.removePage('clamp_page_3');
    externalController.removePage('clamp_page_2');
    await tester.pumpAndSettle();
    expect(find.text('第 1 / 1 页'), findsOneWidget);

    await tearDownAlbumScreen(tester);
    externalController.addBlankPage();
    expect(externalController.pages.length, 2);
    externalController.dispose();
    await tearDownAlbumScreen(tester);
  });
}

