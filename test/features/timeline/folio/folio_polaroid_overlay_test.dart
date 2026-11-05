import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/widgets/fullscreen_media_lightbox.dart';
import 'package:memodiary/features/import_export/services/pdf_polaroid_overlay_builder.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_content_leaf_page.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_ephemera_overlay_layer.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_leaf_model.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_polaroid_card_painter.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_polaroid_mini_card.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_reading_perspective.dart';
import 'package:memodiary/features/timeline/widgets/folio/thread_bound_folio_screen.dart';

void main() {
  final testDate = DateTime(2026, 11, 4, 21, 30);

  FolioPhotoAttachment createTestPhoto({
    String id = 'photo-1',
    String relativePath = 'media/test_polaroid_1.webp',
    String title = '竹窗听雨图',
    String caption = '竹窗听雨 · 小泥炉温陈年普洱',
    int pageNumber = 1,
    int targetLeafIndex = 1,
    double? overlayXRatio,
    double? overlayYRatio,
  }) {
    return FolioPhotoAttachment(
      id: id,
      relativePath: relativePath,
      mediaType: EphemeraMediaType.image,
      title: title,
      caption: caption,
      date: testDate.toIso8601String(),
      pageNumber: pageNumber,
      targetLeafIndex: targetLeafIndex,
      overlayXRatio: overlayXRatio,
      overlayYRatio: overlayYRatio,
    );
  }

  FolioContentBodyLeaf createTestBodyLeaf({
    required FolioRulingLayout layout,
    List<FolioPhotoAttachment> photos = const [],
    int leafIndex = 1,
    int totalLeaves = 2,
    bool isConcludingLeaf = true,
  }) {
    return FolioContentBodyLeaf(
      leafIndex: leafIndex,
      totalLeaves: totalLeaves,
      pageIndexInContent: 1,
      totalContentPages: 1,
      layout: layout,
      title: '暮秋听雨小记',
      lunarDate: '岁次丙午 · 孟冬廿三',
      horizontalRows: [
        FolioHorizontalRow(segments: [
          FolioHorizontalSegment(text: '暮秋听雨小记，窗外细雨蒙蒙。'),
        ]),
      ],
      photos: photos,
      isConcludingLeaf: isConcludingLeaf,
    );
  }

  Widget buildTestHarness(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390,
            height: 844,
            child: child,
          ),
        ),
      ),
    );
  }

  group('FolioPolaroidMiniCard Visual Styling & Multi-Photo Stack', () {
    testWidgets('renders single Polaroid mini-card with brass paperclip and gold washi tape', (tester) async {
      final photo = createTestPhoto();

      await tester.pumpWidget(
        buildTestHarness(
          FolioPolaroidMiniCard(
            photos: [photo],
            atmosphereRealm: ShanshuiRealm.nature,
          ),
        ),
      );

      // Verify title & helper text
      expect(find.text('竹窗听雨图'), findsOneWidget);
      expect(find.text('✥ 拖拽 / 点展读'), findsOneWidget);
      expect(find.text('P1'), findsOneWidget);

      // Verify brass paperclip and gold washi tape widgets
      expect(find.byKey(const Key('folio_polaroid_paperclip')), findsOneWidget);
      expect(find.byType(GoldWashiTapeWidget), findsOneWidget);

      // Verify hide button is present, reset button is hidden for default position
      expect(find.byKey(const Key('folio_polaroid_hide_button')), findsOneWidget);
      expect(find.byKey(const Key('folio_polaroid_reset_button')), findsNothing);

      // Verify single card has no multi-photo counter badge
      expect(find.byKey(const Key('folio_polaroid_counter_badge')), findsNothing);
    });

    testWidgets('renders overlapping fanned stack with counter badge for 2 and 3 photos', (tester) async {
      final photos3 = [
        createTestPhoto(id: 'p1', title: '画心一', pageNumber: 1),
        createTestPhoto(id: 'p2', title: '画心二', pageNumber: 2),
        createTestPhoto(id: 'p3', title: '画心三', pageNumber: 3),
      ];

      await tester.pumpWidget(
        buildTestHarness(
          FolioPolaroidMiniCard(
            photos: photos3,
            atmosphereRealm: ShanshuiRealm.nature,
          ),
        ),
      );

      // Top card shows active photo title
      expect(find.text('画心一'), findsOneWidget);

      // Shows counter badge for N=3
      final badgeFinder = find.byKey(const Key('folio_polaroid_counter_badge'));
      expect(badgeFinder, findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('shows snap-back reset button when hasCustomPosition is true', (tester) async {
      bool resetCalled = false;
      final photo = createTestPhoto();

      await tester.pumpWidget(
        buildTestHarness(
          FolioPolaroidMiniCard(
            photos: [photo],
            hasCustomPosition: true,
            onReset: () => resetCalled = true,
          ),
        ),
      );

      final resetBtn = find.byKey(const Key('folio_polaroid_reset_button'));
      expect(resetBtn, findsOneWidget);
      expect(find.text('↺'), findsOneWidget);

      await tester.tap(resetBtn);
      await tester.pumpAndSettle();
      expect(resetCalled, isTrue);
    });
  });

  group('Smart Default Placement & FolioRulingLayout Anchoring', () {
    testWidgets('vertical ruling anchors default position to Top-Left corner', (tester) async {
      final photo = createTestPhoto();
      final bodyLeaf = createTestBodyLeaf(
        layout: FolioRulingLayout.vermilionVertical,
        photos: [photo],
      );

      await tester.pumpWidget(
        buildTestHarness(
          FolioContentLeafPage(
            leaf: bodyLeaf,
            theme: ReadingPerspective.vermilionVertical.resolveTheme(),
          ),
        ),
      );

      final cardFinder = find.byType(FolioPolaroidMiniCard);
      expect(cardFinder, findsOneWidget);

      final cardTopLeft = tester.getTopLeft(cardFinder);
      final leafCenter = tester.getTopLeft(find.byType(FolioContentLeafPage));

      // In Top-Left corner, dx and dy relative to leaf should be near top-left
      expect(cardTopLeft.dy - leafCenter.dy, lessThan(200.0));
      expect(find.byKey(const Key('folio_polaroid_reset_button')), findsNothing);
    });

    testWidgets('horizontal ruling anchors default position to Bottom-Left corner', (tester) async {
      final photo = createTestPhoto();
      final bodyLeaf = createTestBodyLeaf(
        layout: FolioRulingLayout.faithfulHorizontal,
        photos: [photo],
      );

      await tester.pumpWidget(
        buildTestHarness(
          FolioContentLeafPage(
            leaf: bodyLeaf,
            theme: ReadingPerspective.faithfulOriginal.resolveTheme(),
            mediaService: MediaSandboxService(),
          ),
        ),
      );

      final cardFinder = find.byType(FolioPolaroidMiniCard);
      expect(cardFinder, findsOneWidget);

      final cardTopLeft = tester.getTopLeft(cardFinder);
      final leafCenter = tester.getTopLeft(find.byType(FolioContentLeafPage));

      // In Bottom-Left corner, dy relative to leaf should be near bottom (> 300px)
      expect(cardTopLeft.dy - leafCenter.dy, greaterThan(300.0));
    });
  });

  group('Drag Gestures, Snap Reset & Hide/Restore Toggles', () {
    testWidgets('dragging mini-card updates position and reveals snap-back reset button', (tester) async {
      double? reportedX;
      double? reportedY;
      final photo = createTestPhoto();

      await tester.pumpWidget(
        buildTestHarness(
          SizedBox(
            width: 320,
            height: 448,
            child: Stack(
              children: [
                FolioEphemeraOverlayLayer(
                  photos: [photo],
                  layout: FolioRulingLayout.vermilionVertical,
                  onPositionChanged: (id, x, y) {
                    reportedX = x;
                    reportedY = y;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      final cardFinder = find.byType(FolioPolaroidMiniCard);
      expect(find.byKey(const Key('folio_polaroid_reset_button')), findsNothing);

      // Drag card down-right by (100, 150)
      await tester.drag(cardFinder, const Offset(100.0, 150.0));
      await tester.pumpAndSettle();

      // Reset button should now be visible
      expect(find.byKey(const Key('folio_polaroid_reset_button')), findsOneWidget);

      // Verify reported normalized coordinates are between 0.0 and 1.0
      expect(reportedX, isNotNull);
      expect(reportedY, isNotNull);
      expect(reportedX!, inInclusiveRange(0.0, 1.0));
      expect(reportedY!, inInclusiveRange(0.0, 1.0));

      // Tap snap-back reset button
      await tester.tap(find.byKey(const Key('folio_polaroid_reset_button')));
      await tester.pumpAndSettle();

      // Reset button disappears after snap reset
      expect(find.byKey(const Key('folio_polaroid_reset_button')), findsNothing);
      expect(reportedX, isNull);
      expect(reportedY, isNull);
    });

    testWidgets('dragging multi-photo stack updates coordinates for all photos in the stack', (tester) async {
      final updatedPhotoIds = <String>[];
      final photo1 = createTestPhoto(id: 'photo_stack_1');
      final photo2 = createTestPhoto(id: 'photo_stack_2');

      await tester.pumpWidget(
        buildTestHarness(
          SizedBox(
            width: 320,
            height: 448,
            child: Stack(
              children: [
                FolioEphemeraOverlayLayer(
                  photos: [photo1, photo2],
                  layout: FolioRulingLayout.vermilionVertical,
                  onPositionChanged: (id, x, y) {
                    updatedPhotoIds.add(id);
                  },
                ),
              ],
            ),
          ),
        ),
      );

      final cardFinder = find.byType(FolioPolaroidMiniCard);
      await tester.drag(cardFinder, const Offset(50.0, 70.0));
      await tester.pumpAndSettle();

      expect(updatedPhotoIds, containsAll(['photo_stack_1', 'photo_stack_2']));
    });

    testWidgets('tapping ✕ hides card and reveals restore pill in header', (tester) async {
      final photo = createTestPhoto();
      final bodyLeaf = createTestBodyLeaf(
        layout: FolioRulingLayout.faithfulHorizontal,
        photos: [photo],
      );

      await tester.pumpWidget(
        buildTestHarness(
          FolioContentLeafPage(
            leaf: bodyLeaf,
            theme: ReadingPerspective.faithfulOriginal.resolveTheme(),
            mediaService: MediaSandboxService(),
          ),
        ),
      );

      // Initially visible
      expect(find.byType(FolioPolaroidMiniCard), findsOneWidget);
      expect(find.text('👁️ 隐藏微笺'), findsOneWidget);

      // Tap hide button on card
      await tester.tap(find.byKey(const Key('folio_polaroid_hide_button')));
      await tester.pumpAndSettle();

      // Card is hidden, pill switches to restore mode
      expect(find.byType(FolioPolaroidMiniCard), findsNothing);
      expect(find.text('📌 展开微笺'), findsOneWidget);

      // Tap restore pill to expand
      await tester.tap(find.byKey(const Key('folio_ephemera_restore_pill')));
      await tester.pumpAndSettle();

      // Card is visible again
      expect(find.byType(FolioPolaroidMiniCard), findsOneWidget);
      expect(find.text('👁️ 隐藏微笺'), findsOneWidget);
    });

    testWidgets('tapping card opens FullscreenMediaLightbox', (tester) async {
      final photo = createTestPhoto();
      final bodyLeaf = createTestBodyLeaf(
        layout: FolioRulingLayout.faithfulHorizontal,
        photos: [photo],
      );

      await tester.pumpWidget(
        buildTestHarness(
          FolioContentLeafPage(
            leaf: bodyLeaf,
            theme: ReadingPerspective.faithfulOriginal.resolveTheme(),
            mediaService: MediaSandboxService(),
          ),
        ),
      );

      expect(find.byType(FullscreenMediaLightbox), findsNothing);

      // Tap mini-card
      await tester.tap(find.byType(FolioPolaroidMiniCard));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Lightbox opened
      expect(find.byType(FullscreenMediaLightbox), findsOneWidget);
    });

    testWidgets('ThreadBoundFolioScreen persists custom coordinates to SQLite database on drag', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(() => db.close());
      await db.getAllTemplates();

      final now = DateTime(2026, 11, 4, 21, 30);
      final entry = Entry(
        id: 'entry_persist_1',
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        title: '西湖记事',
        contentDelta: jsonEncode([
          {'insert': '西湖断桥初雪。'},
          {
            'insert': {'mount': 'media_persist_1'},
          },
          {'insert': '\n'},
        ]),
        plainText: '西湖断桥初雪。',
        entryDate: now,
        createdAt: now,
        updatedAt: now,
        isWeeklyReview: false,
        isDeleted: false,
        isLocked: false,
        legacyMountsPending: false,
      );
      await db.createEntry(entry.toCompanion(false));

      final attachment = MediaAttachment(
        id: 'media_persist_1',
        entryId: entry.id,
        mediaType: 'image',
        relativePath: 'media/persist_test.webp',
        createdAt: now,
      );
      await db.into(db.mediaAttachments).insert(attachment.toCompanion(false));

      await tester.pumpWidget(
        buildTestHarness(
          ThreadBoundFolioScreen(
            entry: entry,
            attachments: [attachment],
            onOverlayPositionChanged: (photoId, xRatio, yRatio) =>
                db.updateMediaAttachmentOverlayPosition(photoId, xRatio: xRatio, yRatio: yRatio),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to content page (Page 2)
      await tester.tap(find.text('轻翻展读正文 ⇢'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final cardFinder = find.byType(FolioPolaroidMiniCard);
      expect(cardFinder, findsOneWidget);

      // Drag mini-card
      await tester.drag(cardFinder, const Offset(60.0, 80.0));
      await tester.pumpAndSettle();

      // Verify row in SQLite has updated overlay ratios
      final savedMedia = (await db.getMediaForEntry(entry.id)).single;
      expect(savedMedia.overlayXRatio, isNotNull);
      expect(savedMedia.overlayYRatio, isNotNull);

      // Tap reset
      await tester.tap(find.byKey(const Key('folio_polaroid_reset_button')));
      await tester.pumpAndSettle();

      final resetMedia = (await db.getMediaForEntry(entry.id)).single;
      expect(resetMedia.overlayXRatio, isNull);
      expect(resetMedia.overlayYRatio, isNull);
    });
  });

  group('Vector PDF Parity & Coordinate Resolution', () {
    test('PdfPolaroidOverlayBuilder resolves custom ratios and defaults identically', () {
      // 1. Custom coordinates
      final (customDx, customDy) = PdfPolaroidOverlayBuilder.resolvePlacement(
        xRatio: 0.5,
        yRatio: 0.25,
        availableWidth: 320.0,
        availableHeight: 448.0,
        isVertical: true,
      );
      // maxDx = 320 - 72 = 248 -> 0.5 * 248 = 124.0
      // maxDy = 448 - 94 = 354 -> 0.25 * 354 = 88.5
      expect(customDx, equals(124.0));
      expect(customDy, equals(88.5));

      // 2. Default vertical script: Top-Left (8, 8)
      final (vertDx, vertDy) = PdfPolaroidOverlayBuilder.resolvePlacement(
        xRatio: null,
        yRatio: null,
        availableWidth: 320.0,
        availableHeight: 448.0,
        isVertical: true,
      );
      expect(vertDx, equals(8.0));
      expect(vertDy, equals(8.0));

      // 3. Default horizontal script: Bottom-Left (8, maxDy - 8)
      final (horizDx, horizDy) = PdfPolaroidOverlayBuilder.resolvePlacement(
        xRatio: null,
        yRatio: null,
        availableWidth: 320.0,
        availableHeight: 448.0,
        isVertical: false,
      );
      expect(horizDx, equals(8.0));
      expect(horizDy, equals(344.0));
    });
  });
}
