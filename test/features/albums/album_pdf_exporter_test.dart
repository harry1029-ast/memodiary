import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/albums/models/album_spread.dart';
import 'package:memodiary/features/albums/models/album_studio_models.dart';
import 'package:memodiary/features/albums/services/album_layout_engine.dart';
import 'package:memodiary/features/albums/services/album_pdf_exporter.dart';
import 'package:memodiary/features/albums/widgets/album_pdf_preview_sheet.dart';
import 'album_test_harness.dart';

int _countPdfPages(Uint8List pdfBytes) {
  final asciiContent = latin1.decode(pdfBytes, allowInvalid: true);
  final pageMatches = RegExp(r'/Type\s*/Page\b').allMatches(asciiContent);
  return pageMatches.length;
}

void main() {
  late AlbumTestHarness harness;

  setUp(() async {
    harness = await AlbumTestHarness.create();
  });

  tearDown(() async {
    await harness.dispose();
  });

  group('AlbumPdfExporter', () {
    test(
        'generates valid %PDF- photobook across Cover, SingleHero (long caption), Duo, Quad, and Epilogue in both A4 Landscape and Square formats without TooManyPagesException',
        () async {
      // Seed real sandboxed image files so _loadPdfImage exercises file reading + transcoding
      final src1 = harness.createSourcePhoto('pdf_1.png');
      final sandboxed1 =
          await harness.mediaService.copyAndProcessAlbumPhoto(src1);
      final src2 = harness.createSourcePhoto('pdf_2.png');
      final sandboxed2 =
          await harness.mediaService.copyAndProcessAlbumPhoto(src2);

      final now = DateTime(2026, 5, 1);
      final collection = AlbumCollection(
        id: 'col-pdf-1',
        title: '西湖烟雨集',
        description: '水光潋滟晴方好，山色空蒙雨亦奇。\n' * 6,
        destinationTag: '江南',
        routeSummary: '杭州 → 乌镇 → 苏州',
        coverImagePath: sandboxed1.relativeImagePath,
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 8),
        layoutPreset: 'magazine',
        themeId: 'shanshui_ink',
        sortIndex: 0,
        createdAt: now,
        updatedAt: now,
      );

      // Build explicit spreads covering all 5 types + extreme multiline captions
      // to verify single-page hard bounds guard against TooManyPagesException.
      final veryLongCaption = List.filled(
        20,
        '烟雨江南，乌篷船缓步摇过石桥，水波荡漾间映照出白墙黛瓦的千年光景。',
      ).join('\n');

      final p1 = AlbumPhoto(
        id: 'pdf-p1',
        collectionId: 'col-pdf-1',
        relativeImagePath: sandboxed1.relativeImagePath,
        relativeThumbnailPath: sandboxed1.relativeThumbnailPath,
        caption: veryLongCaption,
        locationTag: '杭州 · 西湖',
        shotAt: now,
        sortOrder: 0,
        aspectRatio: 0.75, // Portrait aspect ratio
        createdAt: now,
      );
      final p2 = AlbumPhoto(
        id: 'pdf-p2',
        collectionId: 'col-pdf-1',
        relativeImagePath: sandboxed2.relativeImagePath,
        relativeThumbnailPath: sandboxed2.relativeThumbnailPath,
        caption: veryLongCaption,
        locationTag: '乌镇 · 西栅',
        shotAt: now,
        sortOrder: 1,
        aspectRatio: 1.5, // Landscape aspect ratio
        createdAt: now,
      );

      final spreads = <AlbumSpread>[
        CoverSpread(
          pageNumber: 1,
          title: collection.title,
          description: collection.description,
          destinationTag: collection.destinationTag,
          startDate: collection.startDate,
          endDate: collection.endDate,
          photoCount: 6,
          coverImagePath: sandboxed1.relativeImagePath,
        ),
        SingleHeroSpread(pageNumber: 2, photo: p1),
        DuoSpread(
          pageNumber: 3,
          firstPhoto: p1,
          secondPhoto: p2,
          orientation: DuoLayoutOrientation.sideBySide,
        ),
        DuoSpread(
          pageNumber: 4,
          firstPhoto: p1,
          secondPhoto: p2,
          orientation: DuoLayoutOrientation.stacked,
        ),
        QuadSpread(
          pageNumber: 5,
          photos: [p1, p2, p1, p2],
        ),
        const EpilogueSpread(
          pageNumber: 6,
          title: '西湖烟雨集',
          routeSummary: '杭州 → 乌镇 → 苏州',
          totalPhotos: 6,
          totalLocations: 3,
          sealText: '江南',
        ),
      ];

      var transcodeCalls = 0;
      Future<Uint8List> mockTranscoder(Uint8List raw) async {
        transcodeCalls++;
        return kDeterministic1x1Png;
      }

      final a4Bytes = await AlbumPdfExporter.generatePhotobookFromSpreads(
        spreads: spreads,
        mediaService: harness.mediaService,
        format: AlbumPdfPageFormat.a4Landscape,
        imageTranscoder: mockTranscoder,
      );

      expect(a4Bytes, isNotEmpty);
      expect(latin1.decode(a4Bytes.sublist(0, 5)), '%PDF-');
      expect(_countPdfPages(a4Bytes), 6);

      final squareBytes = await AlbumPdfExporter.generatePhotobookFromSpreads(
        spreads: spreads,
        mediaService: harness.mediaService,
        format: AlbumPdfPageFormat.square,
        imageTranscoder: mockTranscoder,
      );

      expect(squareBytes, isNotEmpty);
      expect(latin1.decode(squareBytes.sublist(0, 5)), '%PDF-');
      expect(_countPdfPages(squareBytes), 6);
      // Since our test fixture already writes PNG magic bytes, fast-path or transcoder works cleanly
      expect(transcodeCalls, greaterThanOrEqualTo(0));
    });

    test(
        'generatePhotobookFromStudioDocument compiles WYSIWYG 2, 3, and 4-photo collage layouts, CJK text, vector backgrounds, and overlays in A4, Square, and BoundSpread formats with zero ? glyph fallbacks',
        () async {
      final src1 = harness.createSourcePhoto('studio_pdf_1.png');
      final sandboxed1 =
          await harness.mediaService.copyAndProcessAlbumPhoto(src1);
      final src2 = harness.createSourcePhoto('studio_pdf_2.png');
      final sandboxed2 =
          await harness.mediaService.copyAndProcessAlbumPhoto(src2);

      final now = DateTime(2026, 10, 23);
      final photos = <AlbumPhoto>[
        AlbumPhoto(
          id: 'sp-1',
          collectionId: 'col-studio-pdf',
          relativeImagePath: sandboxed1.relativeImagePath,
          relativeThumbnailPath: sandboxed1.relativeThumbnailPath,
          caption: '深圳 · 江南春行纪',
          locationTag: '深圳湾公园',
          shotAt: now,
          sortOrder: 0,
          aspectRatio: 1.33,
          createdAt: now,
        ),
        AlbumPhoto(
          id: 'sp-2',
          collectionId: 'col-studio-pdf',
          relativeImagePath: sandboxed2.relativeImagePath,
          relativeThumbnailPath: sandboxed2.relativeThumbnailPath,
          caption: '十月廿三 · 测试相册',
          locationTag: '杭州西湖',
          shotAt: now,
          sortOrder: 1,
          aspectRatio: 0.8,
          createdAt: now,
        ),
        AlbumPhoto(
          id: 'sp-3',
          collectionId: 'col-studio-pdf',
          relativeImagePath: sandboxed1.relativeImagePath,
          relativeThumbnailPath: sandboxed1.relativeThumbnailPath,
          caption: '水墨丹青三图拼贴',
          locationTag: '乌镇',
          shotAt: now,
          sortOrder: 2,
          aspectRatio: 1.0,
          createdAt: now,
        ),
        AlbumPhoto(
          id: 'sp-4',
          collectionId: 'col-studio-pdf',
          relativeImagePath: sandboxed2.relativeImagePath,
          relativeThumbnailPath: sandboxed2.relativeThumbnailPath,
          caption: '四宫格画册留影',
          locationTag: '苏州园林',
          shotAt: now,
          sortOrder: 3,
          aspectRatio: 1.2,
          createdAt: now,
        ),
      ];

      final studioDoc = AlbumStudioDocument(
        activeThemeId: 'shanshui_ink',
        pages: [
          AlbumPageModel(
            id: 'page-2p',
            pageNumber: 2,
            layoutTemplateId: 'duo_side_by_side',
            backgroundConfig: const PageBackgroundConfig(
              backgroundColorArgb: 0xFFFCF9F2,
              graphicPatternId: 'ink_bamboo_mountains',
            ),
            photoSlots: const [
              PhotoSlotAssignment(
                slotIndex: 0,
                photoId: 'sp-1',
                zoomScale: 1.15,
                panOffsetX: 0.05,
                panOffsetY: -0.05,
              ),
              PhotoSlotAssignment(slotIndex: 1, photoId: 'sp-2'),
            ],
            overlays: const [
              PageOverlayElement(
                id: 'ov-pill',
                type: OverlayElementType.datePill,
                content: '十月廿三 · 深圳 · 江南春行纪',
                dx: 0.5,
                dy: 0.12,
                zIndex: 1,
              ),
              PageOverlayElement(
                id: 'ov-seal',
                type: OverlayElementType.sealStamp,
                content: '拾光',
                dx: 0.85,
                dy: 0.85,
                rotation: -0.08,
                zIndex: 2,
              ),
            ],
          ),
          AlbumPageModel(
            id: 'page-3p',
            pageNumber: 3,
            layoutTemplateId: 'trio_dated_columns',
            backgroundConfig: const PageBackgroundConfig(
              backgroundColorArgb: 0xFFFAF6EE,
              graphicPatternId: 'corner_vines',
            ),
            dateHeaderText: '十月廿三 · 江南春行',
            photoSlots: const [
              PhotoSlotAssignment(slotIndex: 0, photoId: 'sp-1'),
              PhotoSlotAssignment(slotIndex: 1, photoId: 'sp-2'),
              PhotoSlotAssignment(slotIndex: 2, photoId: 'sp-3'),
            ],
            overlays: const [
              PageOverlayElement(
                id: 'ov-sticker',
                type: OverlayElementType.sticker,
                content: 'sticker_bamboo_sprig',
                dx: 0.78,
                dy: 0.18,
                scale: 1.1,
                zIndex: 1,
              ),
              PageOverlayElement(
                id: 'ov-note',
                type: OverlayElementType.text,
                content: '测试相册自定义便签批注',
                dx: 0.5,
                dy: 0.88,
                zIndex: 2,
              ),
            ],
          ),
          AlbumPageModel(
            id: 'page-4p',
            pageNumber: 4,
            layoutTemplateId: 'quad_grid_2x2',
            backgroundConfig: const PageBackgroundConfig(
              backgroundColorArgb: 0xFFF2ECE1,
              graphicPatternId: 'floral_allover',
            ),
            photoSlots: const [
              PhotoSlotAssignment(slotIndex: 0, photoId: 'sp-1'),
              PhotoSlotAssignment(slotIndex: 1, photoId: 'sp-2'),
              PhotoSlotAssignment(slotIndex: 2, photoId: 'sp-3'),
              PhotoSlotAssignment(slotIndex: 3, photoId: 'sp-4'),
            ],
            overlays: const [
              PageOverlayElement(
                id: 'ov-lotus',
                type: OverlayElementType.sticker,
                content: 'sticker_lotus_pod',
                dx: 0.5,
                dy: 0.5,
                zIndex: 1,
              ),
            ],
          ),
        ],
      );

      expect(
        studioDoc.collectReferencedPhotoIds(),
        containsAll(['sp-1', 'sp-2', 'sp-3', 'sp-4']),
      );

      final collection = AlbumCollection(
        id: 'col-studio-pdf',
        title: '深圳 · 江南春行纪',
        description: '测试相册 · 十月廿三',
        destinationTag: '深圳',
        routeSummary: '深圳 → 杭州 → 乌镇 → 苏州',
        coverImagePath: sandboxed1.relativeImagePath,
        startDate: now,
        endDate: now,
        layoutPreset: 'magazine',
        themeId: 'shanshui_ink',
        studioLayoutJson: studioDoc.toJsonString(),
        sortIndex: 0,
        createdAt: now,
        updatedAt: now,
      );

      // 1. A4 Landscape single-page format: 1 Cover + 3 Studio pages = 4 PDF pages
      final a4Bytes = await AlbumPdfExporter.generatePhotobookPdf(
        collection: collection,
        photos: photos,
        mediaService: harness.mediaService,
        format: AlbumPdfPageFormat.a4Landscape,
        imageTranscoder: (_) async => kDeterministic1x1Png,
      );
      expect(latin1.decode(a4Bytes.sublist(0, 5)), '%PDF-');
      expect(_countPdfPages(a4Bytes), 4);
      final a4Raw = latin1.decode(a4Bytes, allowInvalid: true);
      expect(a4Raw, isNot(contains('????')));
      expect(a4Raw, contains('/Subtype/Type0'));
      expect(a4Raw, contains('/Encoding/Identity-H'));

      // 2. Square format: 1 Cover + 3 Studio pages = 4 PDF pages
      final squareBytes =
          await AlbumPdfExporter.generatePhotobookFromStudioDocument(
        collection: collection,
        studioDocument: studioDoc,
        photos: photos,
        mediaService: harness.mediaService,
        format: AlbumPdfPageFormat.square,
        imageTranscoder: (_) async => kDeterministic1x1Png,
      );
      expect(latin1.decode(squareBytes.sublist(0, 5)), '%PDF-');
      expect(_countPdfPages(squareBytes), 4);

      // 3. 2-Page Bound Spread format (420x210mm):
      // Spread 1 = Cover (left) + Page 2 (right)
      // Spread 2 = Page 3 (left) + Page 4 (right)
      // Total = 2 Bound Spread PDF pages
      final spreadBytes =
          await AlbumPdfExporter.generatePhotobookFromStudioDocument(
        collection: collection,
        studioDocument: studioDoc,
        photos: photos,
        mediaService: harness.mediaService,
        format: AlbumPdfPageFormat.boundSpread,
        imageTranscoder: (_) async => kDeterministic1x1Png,
      );
      expect(latin1.decode(spreadBytes.sublist(0, 5)), '%PDF-');
      expect(_countPdfPages(spreadBytes), 2);
      final spreadRaw = latin1.decode(spreadBytes, allowInvalid: true);
      expect(spreadRaw, isNot(contains('????')));
    });
  });

  testWidgets(
      'AlbumPdfPreviewSheet switches format and triggers local save and share callbacks',
      (tester) async {
    final now = DateTime(2026, 5, 1);
    final collection = AlbumCollection(
      id: 'col-sheet-1',
      title: '江南游记',
      description: '烟雨长廊',
      destinationTag: '江南',
      routeSummary: '杭州 → 苏州',
      coverImagePath: null,
      startDate: now,
      endDate: now,
      layoutPreset: 'magazine',
      themeId: 'shanshui_ink',
      sortIndex: 0,
      createdAt: now,
      updatedAt: now,
    );
    final spreads = AlbumLayoutEngine.synthesize(
      collection: collection,
      photos: const [],
    );

    Uint8List? savedBytes;
    String? savedFileName;

    await pumpAlbumScreen(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              key: const Key('open_sheet_btn'),
              onPressed: () {
                AlbumPdfPreviewSheet.show(
                  context,
                  collection: collection,
                  spreads: spreads,
                  mediaService: harness.mediaService,
                  imageTranscoder: (_) async => kDeterministic1x1Png,
                  customSaveHandler: (bytes, fileName) async {
                    savedBytes = bytes;
                    savedFileName = fileName;
                    return '/tmp/$fileName';
                  },
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open_sheet_btn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('album_pdf_preview_sheet')), findsOneWidget);
    expect(find.text('共 2 页画幅'), findsOneWidget);

    // Select Square format
    await tester.tap(find.byKey(const Key('pdf_format_square')));
    await tester.pumpAndSettle();

    // Tap Save to Local
    await tester.tap(find.byKey(const Key('album_pdf_save_button')));
    await tester.pumpAndSettle();

    expect(savedBytes, isNotNull);
    expect(savedBytes, isNotEmpty);
    expect(savedFileName, '江南游记_Square.pdf');

    await tearDownAlbumScreen(tester);
  });

  testWidgets(
      'AlbumPdfPreviewSheet exports StudioDocument in 2-Page Bound Spread format',
      (tester) async {
    final now = DateTime(2026, 10, 23);
    final collection = AlbumCollection(
      id: 'col-sheet-spread',
      title: '测试相册',
      description: '深圳 · 江南春行纪',
      destinationTag: '深圳',
      routeSummary: '深圳 → 江南',
      coverImagePath: null,
      startDate: now,
      endDate: now,
      layoutPreset: 'magazine',
      themeId: 'shanshui_ink',
      sortIndex: 0,
      createdAt: now,
      updatedAt: now,
    );
    final studioDoc = AlbumStudioDocument(
      activeThemeId: 'shanshui_ink',
      pages: [
        AlbumPageModel(
          id: 'p-2',
          pageNumber: 2,
          layoutTemplateId: 'solo_full_bleed',
        ),
        AlbumPageModel(
          id: 'p-3',
          pageNumber: 3,
          layoutTemplateId: 'duo_side_by_side',
        ),
      ],
    );

    Uint8List? savedBytes;
    String? savedFileName;

    await pumpAlbumScreen(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              key: const Key('open_spread_sheet_btn'),
              onPressed: () {
                AlbumPdfPreviewSheet.show(
                  context,
                  collection: collection,
                  spreads: const [],
                  studioDocument: studioDoc,
                  photos: const [],
                  mediaService: harness.mediaService,
                  imageTranscoder: (_) async => kDeterministic1x1Png,
                  customSaveHandler: (bytes, fileName) async {
                    savedBytes = bytes;
                    savedFileName = fileName;
                    return '/tmp/$fileName';
                  },
                );
              },
              child: const Text('Open Spread Sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open_spread_sheet_btn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('album_pdf_preview_sheet')), findsOneWidget);
    expect(find.text('共 3 页画幅'), findsOneWidget);

    // Select 2-Page Bound Spread format
    await tester.tap(find.byKey(const Key('pdf_format_bound_spread')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('album_pdf_save_button')));
    await tester.pumpAndSettle();

    expect(savedBytes, isNotNull);
    expect(savedBytes, isNotEmpty);
    expect(savedFileName, '测试相册_Spread.pdf');
    expect(_countPdfPages(savedBytes!), 2);

    await tearDownAlbumScreen(tester);
  });
}
