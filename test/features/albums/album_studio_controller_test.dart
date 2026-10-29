import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/albums/models/album_studio_models.dart';
import 'package:memodiary/features/albums/services/album_studio_controller.dart';
import 'package:memodiary/features/albums/services/album_theme_catalog.dart';
import 'package:memodiary/features/albums/services/page_layout_catalog.dart';
import 'package:memodiary/features/albums/widgets/page_background_painter.dart';
import 'album_test_harness.dart';

void main() {
  group('AlbumStudioController Undo/Redo, Tray, Themes & Persistence', () {
    late AlbumStudioDocument initialDoc;
    late AlbumStudioController controller;

    setUp(() {
      initialDoc = AlbumStudioDocument(
        activeThemeId: 'shanshui_ink',
        recentBackgroundColors: const [0xFFFCF9F2],
        pages: [
          AlbumPageModel(
            id: 'page_1',
            pageNumber: 1,
            layoutTemplateId: 'trio_left_hero_right_stack',
            photoSlots: const [
              PhotoSlotAssignment(slotIndex: 0, photoId: 'photo_a'),
              PhotoSlotAssignment(slotIndex: 1, photoId: 'photo_b'),
              PhotoSlotAssignment(slotIndex: 2, photoId: 'photo_c'),
            ],
          ),
          AlbumPageModel(
            id: 'page_2',
            pageNumber: 2,
            layoutTemplateId: 'duo_side_by_side',
            photoSlots: const [
              PhotoSlotAssignment(slotIndex: 0, photoId: 'photo_d'),
              PhotoSlotAssignment(slotIndex: 1, photoId: 'photo_e'),
            ],
          ),
        ],
      );

      controller = AlbumStudioController(
        collectionId: 'col_1',
        initialDocument: initialDoc,
      );
    });

    test('swaps photo slots and supports undo/redo', () {
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);

      controller.swapPhotoSlots(
        pageId: 'page_1',
        firstSlotIndex: 0,
        secondSlotIndex: 2,
      );

      expect(controller.canUndo, isTrue);
      final slotsAfterSwap = controller.pages.first.photoSlots;
      expect(slotsAfterSwap[0].photoId, equals('photo_c'));
      expect(slotsAfterSwap[0].slotIndex, equals(0));
      expect(slotsAfterSwap[2].photoId, equals('photo_a'));
      expect(slotsAfterSwap[2].slotIndex, equals(2));

      controller.undo();
      expect(controller.document, equals(initialDoc));
      expect(controller.canRedo, isTrue);

      controller.redo();
      expect(controller.pages.first.photoSlots[0].photoId, equals('photo_c'));
      expect(controller.pages.first.photoSlots[2].photoId, equals('photo_a'));
    });

    test('auto-persists mutations with debouncing and flushes on dispose', () async {
      final savedDocs = <AlbumStudioDocument>[];
      final autoSaveController = AlbumStudioController(
        collectionId: 'col_1',
        initialDocument: initialDoc,
        debounceDuration: const Duration(milliseconds: 50),
        onPersist: (doc) async {
          savedDocs.add(doc);
        },
      );

      // Perform 3 rapid mutations
      autoSaveController.swapPhotoSlots(pageId: 'page_1', firstSlotIndex: 0, secondSlotIndex: 1);
      autoSaveController.swapPhotoSlots(pageId: 'page_1', firstSlotIndex: 1, secondSlotIndex: 2);
      autoSaveController.swapPhotoSlots(pageId: 'page_1', firstSlotIndex: 0, secondSlotIndex: 2);

      // Immediately before debounce fires: savedDocs should be empty
      expect(savedDocs, isEmpty);

      // Wait for debounce timer to fire
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(savedDocs.length, 1);
      expect(savedDocs.first, autoSaveController.document);

      // Perform another mutation and dispose immediately -> should flush
      autoSaveController.swapPhotoSlots(pageId: 'page_1', firstSlotIndex: 0, secondSlotIndex: 1);
      autoSaveController.dispose();
      expect(savedDocs.length, 2);
      expect(savedDocs.last, autoSaveController.document);
    });

    test(
      'removePhotoToTray and restorePhotoFromTray auto-transition between N and N+1 layouts',
      () {
        // Remove photo_b from 3-photo page -> transitions to 2-photo layout
        controller.removePhotoToTray(pageId: 'page_1', slotIndex: 1);

        final pageAfterRemove = controller.pages.first;
        expect(pageAfterRemove.photoSlots.length, equals(2));
        expect(pageAfterRemove.photoSlots[0].photoId, equals('photo_a'));
        expect(pageAfterRemove.photoSlots[0].slotIndex, equals(0));
        expect(pageAfterRemove.photoSlots[1].photoId, equals('photo_c'));
        expect(pageAfterRemove.photoSlots[1].slotIndex, equals(1));

        final twoPhotoTemplate =
            PageLayoutCatalog.getById(pageAfterRemove.layoutTemplateId);
        expect(twoPhotoTemplate.photoCount, equals(2));
        expect(controller.removedPhotoIds, contains('photo_b'));

        // Restore photo_b onto page_2 (which had 2 photos -> transitions to 3-photo layout!)
        controller.restorePhotoFromTray(
          photoId: 'photo_b',
          targetPageId: 'page_2',
        );

        expect(controller.removedPhotoIds, isEmpty);
        final page2AfterRestore = controller.pages[1];
        expect(page2AfterRestore.photoSlots.length, equals(3));
        expect(page2AfterRestore.photoSlots[2].photoId, equals('photo_b'));
        final threePhotoTemplate =
            PageLayoutCatalog.getById(page2AfterRestore.layoutTemplateId);
        expect(threePhotoTemplate.photoCount, equals(3));
      },
    );

    test(
      'caps Undo/Redo stack at 50 steps and clears Redo stack on new mutation',
      () {
        for (var step = 1; step <= 60; step++) {
          controller.updatePageBackground(
            pageId: 'page_1',
            backgroundConfig: PageBackgroundConfig(
              backgroundColorArgb: 0xFF000000 + step,
              textColorArgb: 0xFFFFFFFF,
            ),
          );
        }

        expect(
          controller.undoCount,
          equals(AlbumStudioController.maxHistorySteps),
        );

        controller.undo();
        expect(controller.canRedo, isTrue);

        // New mutation clears redo stack
        controller.changePageLayout(
          pageId: 'page_1',
          layoutTemplateId: 'trio_dated_columns',
        );
        expect(controller.canRedo, isFalse);
      },
    );

    test(
      'applies all 5 global book themes and updates page backgrounds & overlays',
      () {
        for (final theme in AlbumThemeCatalog.allThemes) {
          controller.applyGlobalTheme(theme.id);
          expect(controller.document.activeThemeId, equals(theme.id));
          for (final page in controller.pages) {
            expect(
              theme.graphicPatternIds
                  .contains(page.backgroundConfig.graphicPatternId),
              isTrue,
            );
          }
        }

        const stickerOverlay = PageOverlayElement(
          id: 'ov_1',
          type: OverlayElementType.sticker,
          content: 'sticker_flora_blossom',
          dx: 0.3,
          dy: 0.4,
          scale: 1.2,
          rotation: 0.25,
        );

        controller.addOverlay(pageId: 'page_1', overlay: stickerOverlay);
        expect(controller.pages.first.overlays.single, equals(stickerOverlay));

        final movedOverlay = stickerOverlay.copyWith(dx: 0.75, dy: 0.80);
        controller.updateOverlay(pageId: 'page_1', overlay: movedOverlay);
        expect(controller.pages.first.overlays.single.dx, equals(0.75));

        controller.removeOverlay(pageId: 'page_1', overlayId: 'ov_1');
        expect(controller.pages.first.overlays, isEmpty);
      },
    );

    test('renders PageBackgroundPainter and StickerElementPainter without error',
        () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(400, 400);

      for (final pattern in AlbumThemeCatalog.allGraphicPatterns) {
        final painter = PageBackgroundPainter(
          config: PageBackgroundConfig(
            backgroundColorArgb: 0xFFFCF9F2,
            textColorArgb: 0xFF1E1E1E,
            graphicPatternId: pattern.id,
          ),
        );
        painter.paint(canvas, size);
      }

      for (final sticker in StickerCatalog.allStickers) {
        final stickerPainter = StickerElementPainter(stickerId: sticker.id);
        stickerPainter.paint(canvas, const Size(80, 80));
      }

      final picture = recorder.endRecording();
      addTearDown(picture.dispose);
    });

    test(
      'persists and reloads AlbumStudioDocument through AlbumRepository with 100% parity',
      () async {
        final harness = await AlbumTestHarness.create();
        addTearDown(() => harness.dispose());

        final collection = await harness.repository.createCollection(
          id: 'col_persist',
          title: '京都枫叶手账',
          themeId: 'jardin',
        );

        for (var i = 0; i < 5; i++) {
          await harness.repository.addPhoto(
            id: 'kyoto_$i',
            collectionId: collection.id,
            relativeImagePath: 'media/kyoto_$i.webp',
            relativeThumbnailPath: 'media/kyoto_${i}_thumb.webp',
            sortOrder: i,
          );
        }

        // First load synthesizes clean-slate studio document with all photos in Collection Box
        final synthesized = await harness.repository
            .loadOrSynthesizeStudioDocument(collection.id);
        expect(synthesized.pages.length, equals(1));
        expect(synthesized.pages[0].photoSlots, isEmpty);
        expect(synthesized.removedPhotoIds.length, equals(5));

        final repoController = AlbumStudioController(
          collectionId: collection.id,
          initialDocument: synthesized,
          repository: harness.repository,
        );

        repoController.applyGlobalTheme('abstract_blue');
        // Place one photo from Collection Box onto page 1
        repoController.restorePhotoFromTray(
          photoId: 'kyoto_0',
          targetPageId: repoController.pages.first.id,
        );
        expect(repoController.pages.first.photoSlots.length, equals(1));
        expect(repoController.removedPhotoIds, isNot(contains('kyoto_0')));
        await repoController.saveToRepository();

        final reloaded = await harness.repository
            .loadOrSynthesizeStudioDocument(collection.id);
        expect(reloaded, equals(repoController.document));
        expect(reloaded.activeThemeId, equals('abstract_blue'));
        expect(reloaded.pages.first.photoSlots.length, equals(1));
      },
    );

    test('movePhotoBetweenPages moves photo and adapts layouts for both pages', () {
      // page_1 has 3 photos (a, b, c), page_2 has 2 photos (d, e)
      controller.movePhotoBetweenPages(
        sourcePageId: 'page_1',
        sourceSlotIndex: 0,
        targetPageId: 'page_2',
      );

      expect(controller.canUndo, isTrue);
      // page_1 should now have 2 photos (b, c) and a 2-photo layout
      expect(controller.pages[0].photoSlots.length, equals(2));
      expect(controller.pages[0].photoSlots[0].photoId, equals('photo_b'));
      expect(controller.pages[0].photoSlots[1].photoId, equals('photo_c'));
      final p1Layout = PageLayoutCatalog.getById(controller.pages[0].layoutTemplateId);
      expect(p1Layout.photoCount, equals(2));

      // page_2 should now have 3 photos (d, e, a) and a 3-photo layout
      expect(controller.pages[1].photoSlots.length, equals(3));
      expect(controller.pages[1].photoSlots[0].photoId, equals('photo_d'));
      expect(controller.pages[1].photoSlots[1].photoId, equals('photo_e'));
      expect(controller.pages[1].photoSlots[2].photoId, equals('photo_a'));
      final p2Layout = PageLayoutCatalog.getById(controller.pages[1].layoutTemplateId);
      expect(p2Layout.photoCount, equals(3));

      // Undo restores original state
      controller.undo();
      expect(controller.pages[0].photoSlots.length, equals(3));
      expect(controller.pages[1].photoSlots.length, equals(2));
    });

    test('changePageLayout stashes surplus photos to removedPhotoIds when downscaling', () {
      // page_1 currently has 3 photos (a, b, c)
      expect(controller.pages[0].photoSlots.length, equals(3));
      expect(controller.removedPhotoIds, isEmpty);

      // Change to a 2-slot template (duo_side_by_side)
      controller.changePageLayout(
        pageId: 'page_1',
        layoutTemplateId: 'duo_side_by_side',
      );

      expect(controller.pages[0].photoSlots.length, equals(2));
      expect(controller.pages[0].photoSlots[0].photoId, equals('photo_a'));
      expect(controller.pages[0].photoSlots[1].photoId, equals('photo_b'));
      expect(controller.removedPhotoIds, equals(['photo_c']));

      // Undo reverts the downscaling and restores photo_c to page_1
      controller.undo();
      expect(controller.pages[0].photoSlots.length, equals(3));
      expect(controller.pages[0].photoSlots[2].photoId, equals('photo_c'));
      expect(controller.removedPhotoIds, isEmpty);
    });

    test('reconcileWithPhotoIds prunes deleted photos and routes new photos to removedPhotoIds', () {
      final doc = AlbumStudioDocument(
        activeThemeId: 'shanshui_ink',
        pages: [
          AlbumPageModel(
            id: 'p1',
            pageNumber: 1,
            layoutTemplateId: 'duo_side_by_side',
            photoSlots: const [
              PhotoSlotAssignment(slotIndex: 0, photoId: 'photo_existing'),
              PhotoSlotAssignment(slotIndex: 1, photoId: 'photo_deleted'),
            ],
          ),
        ],
        removedPhotoIds: const ['tray_deleted', 'tray_kept'],
      );

      // Current DB has 'photo_existing', 'tray_kept', and newly ingested 'photo_new'
      final reconciled = doc.reconcileWithPhotoIds([
        'photo_existing',
        'tray_kept',
        'photo_new',
      ]);

      // 'photo_deleted' pruned from p1 slots
      expect(reconciled.pages[0].photoSlots.length, equals(1));
      expect(reconciled.pages[0].photoSlots[0].photoId, equals('photo_existing'));
      expect(reconciled.pages[0].photoSlots[0].slotIndex, equals(0));

      // 'tray_deleted' pruned from tray, 'photo_new' added to tray
      expect(reconciled.removedPhotoIds, contains('tray_kept'));
      expect(reconciled.removedPhotoIds, contains('photo_new'));
      expect(reconciled.removedPhotoIds, isNot(contains('tray_deleted')));
      expect(reconciled.removedPhotoIds, isNot(contains('photo_deleted')));
    });

    test('StickerCatalog includes datePill category and paints correctly', () {
      final datePills = StickerCatalog.byCategory(StickerCategory.datePill);
      expect(datePills.length, greaterThanOrEqualTo(2));
      expect(datePills.first.category.displayLabel, equals('日期胶囊'));

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const painter = StickerElementPainter(
        stickerId: 'sticker_date_pill_ribbon',
      );
      painter.paint(canvas, const Size(120, 60));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}
