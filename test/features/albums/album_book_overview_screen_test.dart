import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/albums/screens/album_book_overview_screen.dart';
import 'package:memodiary/features/albums/screens/album_page_editor_screen.dart';
import 'package:memodiary/features/albums/screens/album_workspace_screen.dart';
import 'package:memodiary/features/albums/services/album_studio_controller.dart';
import 'package:memodiary/features/albums/widgets/studio_drawers/themes_and_style_sheet.dart';
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
      'AlbumWorkspaceScreen opens AlbumBookOverviewScreen via "浏览画册 / 进入工作室" button',
      (tester) async {
    await harness.repository.createCollection(
      id: 'col-studio-1',
      title: '西湖寻秋手账',
      description: '秋水共长天一色',
      destinationTag: '杭州',
      routeSummary: '断桥 → 孤山 → 西泠印社',
    );

    for (var i = 0; i < 3; i++) {
      final src = harness.createSourcePhoto('hz_$i.png');
      await harness.repository.ingestAndAddPhoto(
        collectionId: 'col-studio-1',
        sourceFile: src,
      );
    }

    await pumpAlbumScreen(
      tester,
      AlbumWorkspaceScreen(
        collectionId: 'col-studio-1',
        database: harness.database,
        mediaService: harness.mediaService,
        repository: harness.repository,
      ),
    );
    await tester.pumpAndSettle();

    final openStudioBtn =
        find.byKey(const Key('workspace_open_studio_button'));
    expect(openStudioBtn, findsOneWidget);

    await tester.tap(openStudioBtn);
    await tester.pumpAndSettle();

    expect(find.byType(AlbumBookOverviewScreen), findsOneWidget);
    expect(find.byKey(const Key('book_spread_tile_0')), findsOneWidget);
    expect(find.byKey(const Key('spread_cover_leaf')), findsOneWidget);
    expect(find.byKey(const Key('spread_spine_crease_0')), findsOneWidget);
    expect(find.byKey(const Key('spread_page_tile_0')), findsOneWidget);

    await tearDownAlbumScreen(tester);
  });

  testWidgets(
      'AlbumBookOverviewScreen supports adding blank page, Undo/Redo, global theme switch, and opening AlbumPageEditorScreen',
      (tester) async {
    await harness.repository.createCollection(
      id: 'col-studio-2',
      title: '徽州古村行纪',
      description: '青砖小瓦马头墙',
      destinationTag: '徽州',
    );

    for (var i = 0; i < 2; i++) {
      final src = harness.createSourcePhoto('hz_village_$i.png');
      await harness.repository.ingestAndAddPhoto(
        collectionId: 'col-studio-2',
        sourceFile: src,
      );
    }

    final collection =
        (await harness.database.albumsDao.getCollectionById('col-studio-2'))!;
    final photos =
        await harness.database.albumsDao.getPhotosForCollection('col-studio-2');

    await pumpAlbumScreen(
      tester,
      AlbumBookOverviewScreen(
        collection: collection,
        photos: photos,
        repository: harness.repository,
        mediaService: harness.mediaService,
      ),
    );
    await tester.pumpAndSettle();

    // Initially 1 synthesized page for 2 photos (Cover + Page 1 on spread 0)
    expect(find.textContaining('共 1 页'), findsOneWidget);
    expect(find.byKey(const Key('spread_spine_crease_0')), findsOneWidget);

    // Undo and Redo buttons are initially disabled
    final undoBtn = tester.widget<IconButton>(
      find.byKey(const Key('book_overview_undo_button')),
    );
    expect(undoBtn.onPressed, isNull);

    // Tap '+ Add' -> '新增空白内页'
    await tester.tap(find.byKey(const Key('book_overview_add_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('overview_add_blank_page')));
    await tester.pumpAndSettle();

    expect(find.textContaining('共 2 页'), findsOneWidget);

    // Undo adding the blank page
    await tester.tap(find.byKey(const Key('book_overview_undo_button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('共 1 页'), findsOneWidget);

    // Redo adding the blank page
    await tester.tap(find.byKey(const Key('book_overview_redo_button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('共 2 页'), findsOneWidget);

    // Open 'Options' -> ThemesAndStyleSheet and apply 'Jardin' theme
    await tester.tap(find.byKey(const Key('book_overview_options_button')));
    await tester.pumpAndSettle();
    expect(find.byType(ThemesAndStyleSheet), findsOneWidget);

    await tester.tap(find.byKey(const Key('apply_theme_jardin')));
    await tester.pumpAndSettle();

    final persistedDoc =
        await harness.repository.loadOrSynthesizeStudioDocument('col-studio-2');
    expect(persistedDoc.activeThemeId, 'jardin');

    // Tap Page 1 leaf to open AlbumPageEditorScreen
    await tester.tap(find.byKey(const Key('spread_page_tile_0')));
    await tester.pumpAndSettle();

    expect(find.byType(AlbumPageEditorScreen), findsOneWidget);
    expect(find.text('Page 1 / 2'), findsOneWidget);

    await tearDownAlbumScreen(tester);
  });

  testWidgets(
      'AlbumBookOverviewScreen shows "+ 新增书页" on right when even pages and on left when odd pages',
      (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await harness.repository.createCollection(
      id: 'col-studio-3',
      title: '江南水乡手账',
      description: '烟雨江南',
      destinationTag: '乌镇',
    );

    // Ingest 2 photos -> 1 synthesized page
    for (var i = 0; i < 2; i++) {
      final src = harness.createSourcePhoto('wuzhen_$i.png');
      await harness.repository.ingestAndAddPhoto(
        collectionId: 'col-studio-3',
        sourceFile: src,
      );
    }

    final collection =
        (await harness.database.albumsDao.getCollectionById('col-studio-3'))!;
    final photos =
        await harness.database.albumsDao.getPhotosForCollection('col-studio-3');

    await pumpAlbumScreen(
      tester,
      AlbumBookOverviewScreen(
        collection: collection,
        photos: photos,
        repository: harness.repository,
        mediaService: harness.mediaService,
      ),
    );
    await tester.pumpAndSettle();

    // With 1 page (Spread 0: Cover + Page 1), Spread 1 is a trailing spread
    // with "+ 新增书页" on the LEFT side (Page 2).
    expect(find.textContaining('共 1 页'), findsOneWidget);
    expect(
      find.byKey(const Key('spread_1_add_left_page_button')),
      findsOneWidget,
    );
    expect(find.text('待添加 · Page 2'), findsOneWidget);

    // Tap the left-side button on Spread 1 to add Page 2
    await tester.tap(find.byKey(const Key('spread_1_add_left_page_button')));
    await tester.pumpAndSettle();

    // Now 2 pages: Spread 1 has Page 2 on left, and "+ 新增书页" on the RIGHT side (Image 1)
    expect(find.textContaining('共 2 页'), findsOneWidget);
    expect(
      find.byKey(const Key('spread_1_add_right_page_button')),
      findsOneWidget,
    );
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('卷尾留白 · Endpaper'), findsOneWidget);

    // Tap the right-side button on Spread 1 to add Page 3
    await tester.tap(find.byKey(const Key('spread_1_add_right_page_button')));
    await tester.pumpAndSettle();

    // Now 3 pages (Image 2): Spread 1 has Page 2 and Page 3.
    // Trailing Spread 2 is generated with "+ 新增书页" on the LEFT side!
    expect(find.textContaining('共 3 页'), findsOneWidget);
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Page 3'), findsOneWidget);
    expect(
      find.byKey(const Key('spread_2_add_left_page_button')),
      findsOneWidget,
    );
    expect(find.text('待添加 · Page 4'), findsOneWidget);

    // And the right side of Spread 2 is an inactive endpaper displaying '拾光印记'
    expect(
      find.byKey(const Key('spread_2_add_right_page_button')),
      findsNothing,
    );

    // Tap the left-side button on Spread 2 to add Page 4
    await tester.tap(find.byKey(const Key('spread_2_add_left_page_button')));
    await tester.pumpAndSettle();

    // Now 4 pages: Spread 2 has Page 4 on the left, and "+ 新增书页" activates on the RIGHT side
    expect(find.textContaining('共 4 页'), findsOneWidget);
    expect(find.text('Page 4'), findsOneWidget);
    expect(
      find.byKey(const Key('spread_2_add_right_page_button')),
      findsOneWidget,
    );

    await tearDownAlbumScreen(tester);
  });

  testWidgets(
      'AlbumBookOverviewScreen reacts to live photo imports, updates Page Editor tray, and preserves external controller on dispose',
      (tester) async {
    await harness.repository.createCollection(
      id: 'col-studio-live',
      title: '黄山云海集',
      destinationTag: '黄山',
    );
    for (var i = 0; i < 2; i++) {
      final src = harness.createSourcePhoto('huangshan_$i.png');
      await harness.repository.ingestAndAddPhoto(
        collectionId: 'col-studio-live',
        sourceFile: src,
      );
    }

    final collection =
        (await harness.repository.getCollectionById('col-studio-live'))!;
    final initialPhotos =
        await harness.repository.getPhotosForCollection('col-studio-live');
    late final String importedPhotoId;
    Future<void>? importFuture;

    await pumpAlbumScreen(
      tester,
      AlbumBookOverviewScreen(
        collection: collection,
        photos: initialPhotos,
        repository: harness.repository,
        mediaService: harness.mediaService,
        onImportMorePhotos: () {
          importFuture = () async {
            final extraSrc = harness.createSourcePhoto('huangshan_extra.png');
            final imported = await harness.repository.ingestAndAddPhoto(
              collectionId: 'col-studio-live',
              sourceFile: extraSrc,
            );
            importedPhotoId = imported.id;
          }();
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('收集箱 2 张'), findsOneWidget);

    // Trigger '+ Add -> Import Photos'
    await tester.tap(find.byKey(const Key('book_overview_add_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('overview_import_photos')));
    await tester.pumpAndSettle();
    await importFuture;
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Overview header immediately reflects the newly imported photo
    expect(find.textContaining('收集箱 3 张'), findsOneWidget);

    // Open Page 1 in AlbumPageEditorScreen; place the newly imported photo onto Page 1
    await tester.tap(find.byKey(const Key('spread_page_tile_0')));
    await tester.pumpAndSettle();
    expect(find.byType(AlbumPageEditorScreen), findsOneWidget);
    final importedTrayItem =
        find.byKey(Key('removed_tray_item_$importedPhotoId'));
    expect(importedTrayItem, findsOneWidget);
    await tester.tap(importedTrayItem);
    await tester.pumpAndSettle();

    // Verify Page 1 renders the newly imported photo (not missing-photo placeholder)
    expect(
      find.descendant(
        of: find.byKey(const Key('interactive_photo_slot_0')),
        matching: find.byIcon(Icons.add_photo_alternate_outlined),
      ),
      findsNothing,
    );

    // Confirm and exit Page Editor, then close Overview to persist layout
    await tester.tap(find.byKey(const Key('page_editor_confirm_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('book_overview_close_button')));
    await tester.pumpAndSettle();

    final persistedDoc = await harness.repository
        .loadOrSynthesizeStudioDocument('col-studio-live');
    expect(
      persistedDoc.pages.first.photoSlots.map((slot) => slot.photoId),
      contains(importedPhotoId),
    );

    await tearDownAlbumScreen(tester);

    // Passing an external controller must not dispose it when Overview unmounts,
    // and Overview must read live collection/photos from controller even if widget.photos is empty.
    final externalController = AlbumStudioController(
      collectionId: 'col-studio-live',
      initialDocument: persistedDoc,
      initialCollection: collection,
      initialPhotos:
          await harness.repository.getPhotosForCollection('col-studio-live'),
      repository: harness.repository,
    );
    await pumpAlbumScreen(
      tester,
      AlbumBookOverviewScreen(
        collection: collection,
        photos: const [],
        repository: harness.repository,
        mediaService: harness.mediaService,
        controller: externalController,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('收集箱 2 张'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('spread_page_tile_0')),
        matching: find.byIcon(Icons.add_photo_alternate_outlined),
      ),
      findsNothing,
    );

    await tearDownAlbumScreen(tester);
    externalController.addBlankPage();
    expect(externalController.pages.length, 2);
    externalController.dispose();
    await tearDownAlbumScreen(tester);
  });
}
