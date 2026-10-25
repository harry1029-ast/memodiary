import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/albums/screens/album_book_overview_screen.dart';
import 'package:memodiary/features/albums/screens/album_page_editor_screen.dart';
import 'package:memodiary/features/albums/screens/album_workspace_screen.dart';
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
        (await harness.repository.getCollectionById('col-studio-2'))!;
    final photos =
        await harness.repository.getPhotosForCollection('col-studio-2');

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
}
