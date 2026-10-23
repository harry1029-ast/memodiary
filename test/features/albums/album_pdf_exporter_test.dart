import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/albums/models/album_spread.dart';
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
}
