import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/albums/screens/album_page_editor_screen.dart';
import 'package:memodiary/features/albums/services/album_studio_controller.dart';
import 'package:memodiary/features/albums/widgets/studio_drawers/add_elements_drawer.dart';
import 'package:memodiary/features/albums/widgets/studio_drawers/background_style_drawer.dart';
import 'package:memodiary/features/albums/widgets/studio_drawers/layout_picker_drawer.dart';
import 'package:memodiary/features/albums/widgets/studio_drawers/removed_photos_drawer.dart';
import 'album_test_harness.dart';

void main() {
  late AlbumTestHarness harness;

  setUp(() async {
    harness = await AlbumTestHarness.create();
  });

  tearDown(() async {
    await harness.dispose();
  });

  Future<(AlbumStudioController, List<String>)> createControllerWithPhotos(
    int count,
  ) async {
    await harness.repository.createCollection(
      id: 'col-editor-test',
      title: '姑苏园林手账',
      destinationTag: '苏州',
    );
    final photoIds = <String>[];
    for (var i = 0; i < count; i++) {
      final src = harness.createSourcePhoto('sz_editor_$i.png');
      final photo = await harness.repository.ingestAndAddPhoto(
        collectionId: 'col-editor-test',
        sourceFile: src,
      );
      photoIds.add(photo.id);
    }

    final doc = await harness.repository
        .loadOrSynthesizeStudioDocument('col-editor-test');
    final controller = AlbumStudioController(
      collectionId: 'col-editor-test',
      initialDocument: doc,
      repository: harness.repository,
    );
    return (controller, photoIds);
  }

  testWidgets(
      'AlbumPageEditorScreen supports removing a photo to Removed tray and restoring it back to auto-upgrade layout',
      (tester) async {
    final (controller, photoIds) = await createControllerWithPhotos(2);
    final collection =
        (await harness.repository.getCollectionById('col-editor-test'))!;
    final photos =
        await harness.repository.getPhotosForCollection('col-editor-test');

    await pumpAlbumScreen(
      tester,
      AlbumPageEditorScreen(
        controller: controller,
        collection: collection,
        photos: photos,
        repository: harness.repository,
        mediaService: harness.mediaService,
        initialPageIndex: 0,
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.selectedPage!.photoSlots.length, 2);
    expect(controller.removedPhotoIds, isEmpty);

    // Tap slot 0 to open inline contextual menu
    await tester.tap(find.byKey(const Key('interactive_photo_slot_0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('slot_context_menu_0')), findsOneWidget);

    // Tap 'Remove to Tray' button on slot 0
    await tester.tap(find.byKey(const Key('slot_remove_to_tray_0')));
    await tester.pumpAndSettle();

    // Page auto-downgraded from 2-photo layout to 1-photo layout; 1 photo in tray
    expect(controller.selectedPage!.photoSlots.length, 1);
    expect(controller.removedPhotoIds, [photoIds[0]]);

    // Open 'Removed (1)' drawer
    await tester.tap(find.byKey(const Key('studio_tab_removed')));
    await tester.pumpAndSettle();
    expect(find.byType(RemovedPhotosDrawer), findsOneWidget);

    final trayItem = find.byKey(Key('removed_tray_item_${photoIds[0]}'));
    expect(trayItem, findsOneWidget);

    // Tap the photo in the Removed tray to restore it onto the page
    await tester.tap(trayItem);
    await tester.pumpAndSettle();

    expect(controller.removedPhotoIds, isEmpty);
    expect(controller.selectedPage!.photoSlots.length, 2);

    await tearDownAlbumScreen(tester);
  });

  testWidgets(
      'AlbumPageEditorScreen switches layout via LayoutPickerDrawer and updates background color & graphic via BackgroundStyleDrawer',
      (tester) async {
    final (controller, _) = await createControllerWithPhotos(2);
    final collection =
        (await harness.repository.getCollectionById('col-editor-test'))!;
    final photos =
        await harness.repository.getPhotosForCollection('col-editor-test');

    await pumpAlbumScreen(
      tester,
      AlbumPageEditorScreen(
        controller: controller,
        collection: collection,
        photos: photos,
        repository: harness.repository,
        mediaService: harness.mediaService,
        initialPageIndex: 0,
      ),
    );
    await tester.pumpAndSettle();

    // Open Layout drawer
    await tester.tap(find.byKey(const Key('studio_tab_layout')));
    await tester.pumpAndSettle();
    expect(find.byType(LayoutPickerDrawer), findsOneWidget);

    // Select 'duo_stacked' layout
    final stackedOption =
        find.byKey(const Key('layout_option_duo_stacked'));
    await tester.tap(stackedOption);
    await tester.pumpAndSettle();

    expect(controller.selectedPage!.layoutTemplateId, 'duo_stacked');

    // Open Background drawer
    await tester.tap(find.byKey(const Key('studio_tab_background')));
    await tester.pumpAndSettle();
    expect(find.byType(BackgroundStyleDrawer), findsOneWidget);

    // Select 'corner_vines' graphic motif
    final cornerVinesGraphic = find.byKey(const Key('bg_graphic_corner_vines'));
    await tester.ensureVisible(cornerVinesGraphic);
    await tester.tap(cornerVinesGraphic);
    await tester.pumpAndSettle();

    expect(
      controller.selectedPage!.backgroundConfig.graphicPatternId,
      'corner_vines',
    );

    // Select a contrasting color swatch ('天青冰瓷' 0xffeaf6f6)
    final swatch = find.byKey(const Key('bg_swatch_ffeaf6f6'));
    await tester.ensureVisible(swatch);
    await tester.tap(swatch);
    await tester.pumpAndSettle();

    expect(
      controller.selectedPage!.backgroundConfig.backgroundColorArgb,
      0xFFEAF6F6,
    );

    await tearDownAlbumScreen(tester);
  });

  testWidgets(
      'AlbumPageEditorScreen inserts and deletes overlays via AddElementsDrawer',
      (tester) async {
    final (controller, _) = await createControllerWithPhotos(1);
    final collection =
        (await harness.repository.getCollectionById('col-editor-test'))!;
    final photos =
        await harness.repository.getPhotosForCollection('col-editor-test');

    await pumpAlbumScreen(
      tester,
      AlbumPageEditorScreen(
        controller: controller,
        collection: collection,
        photos: photos,
        repository: harness.repository,
        mediaService: harness.mediaService,
        initialPageIndex: 0,
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.selectedPage!.overlays, isEmpty);

    // Open Add drawer
    await tester.tap(find.byKey(const Key('studio_tab_add')));
    await tester.pumpAndSettle();
    expect(find.byType(AddElementsDrawer), findsOneWidget);

    // Tap '朱印闲章' quick action
    await tester.tap(find.byKey(const Key('studio_add_seal_stamp')));
    await tester.pumpAndSettle();

    expect(controller.selectedPage!.overlays.length, 1);
    final addedOverlay = controller.selectedPage!.overlays.first;

    // Close the drawer so the canvas overlay has full room
    await tester.tap(find.byKey(const Key('studio_tab_add')));
    await tester.pumpAndSettle();

    // Tap the overlay item on canvas to select it and reveal its delete button
    final overlayFinder = find.byKey(Key('overlay_item_${addedOverlay.id}'));
    expect(overlayFinder, findsOneWidget);
    await tester.tap(overlayFinder);
    await tester.pumpAndSettle();

    final deleteBtn = find.byKey(Key('delete_overlay_${addedOverlay.id}'));
    expect(deleteBtn, findsOneWidget);
    await tester.tap(deleteBtn);
    await tester.pumpAndSettle();

    expect(controller.selectedPage!.overlays, isEmpty);

    await tearDownAlbumScreen(tester);
  });

  testWidgets(
      'AlbumPageEditorScreen swaps two photo slots via LongPressDraggable and DragTarget',
      (tester) async {
    final (controller, photoIds) = await createControllerWithPhotos(2);
    final collection =
        (await harness.repository.getCollectionById('col-editor-test'))!;
    final photos =
        await harness.repository.getPhotosForCollection('col-editor-test');

    await pumpAlbumScreen(
      tester,
      AlbumPageEditorScreen(
        controller: controller,
        collection: collection,
        photos: photos,
        repository: harness.repository,
        mediaService: harness.mediaService,
        initialPageIndex: 0,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      controller.selectedPage!.photoSlots.map((s) => s.photoId).toList(),
      [photoIds[0], photoIds[1]],
    );

    final slot0 = find.byKey(const Key('interactive_photo_slot_0'));
    final slot1 = find.byKey(const Key('interactive_photo_slot_1'));
    expect(slot0, findsOneWidget);
    expect(slot1, findsOneWidget);

    final center0 = tester.getCenter(slot0);
    final center1 = tester.getCenter(slot1);

    // Long-press slot 0 to activate LongPressDraggable and drag onto slot 1
    final gesture = await tester.startGesture(center0);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(center1);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      controller.selectedPage!.photoSlots.map((s) => s.photoId).toList(),
      [photoIds[1], photoIds[0]],
    );

    await tearDownAlbumScreen(tester);
  });
}
