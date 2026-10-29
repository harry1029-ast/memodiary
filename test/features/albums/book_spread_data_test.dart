import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/albums/models/album_studio_models.dart';

void main() {
  group('BookSpreadData Composite Model Tests (CODING_STANDARDS.md § 2)', () {
    test('instantiates with defaults and custom properties', () {
      const emptySpread = BookSpreadData();
      expect(emptySpread.isCoverLeft, isFalse);
      expect(emptySpread.leftPage, isNull);
      expect(emptySpread.leftPageIndex, isNull);
      expect(emptySpread.rightPage, isNull);
      expect(emptySpread.rightPageIndex, isNull);
      expect(emptySpread.expectedNextPageNumber, isNull);

      const coverSpread = BookSpreadData(isCoverLeft: true);
      expect(coverSpread.isCoverLeft, isTrue);

      final page = AlbumPageModel(
        id: 'p1',
        pageNumber: 1,
        layoutTemplateId: 'solo_full_bleed',
        photoSlots: const [],
        backgroundConfig: const PageBackgroundConfig(
          backgroundColorArgb: 0xFFFFFFFF,
        ),
      );

      final activeSpread = BookSpreadData(
        leftPage: page,
        leftPageIndex: 0,
        expectedNextPageNumber: 2,
      );
      expect(activeSpread.leftPage?.id, 'p1');
      expect(activeSpread.leftPageIndex, 0);
      expect(activeSpread.expectedNextPageNumber, 2);
    });

    test('AlbumStudioDocument.buildSpreads correctly partitions empty, odd, and even page sequences', () {
      final emptyDoc = AlbumStudioDocument(pages: const []);
      final emptySpreads = emptyDoc.buildSpreads(includeBlankTrailing: true);
      expect(emptySpreads.length, 1);
      expect(emptySpreads[0].isCoverLeft, isTrue);
      expect(emptySpreads[0].rightPage, isNull);

      final page1 = AlbumPageModel(
        id: 'p1',
        pageNumber: 1,
        layoutTemplateId: 'solo_full_bleed',
        photoSlots: const [],
        backgroundConfig: const PageBackgroundConfig(backgroundColorArgb: 0xFFFFFFFF),
      );
      final page2 = AlbumPageModel(
        id: 'p2',
        pageNumber: 2,
        layoutTemplateId: 'solo_full_bleed',
        photoSlots: const [],
        backgroundConfig: const PageBackgroundConfig(backgroundColorArgb: 0xFFFFFFFF),
      );
      final page3 = AlbumPageModel(
        id: 'p3',
        pageNumber: 3,
        layoutTemplateId: 'solo_full_bleed',
        photoSlots: const [],
        backgroundConfig: const PageBackgroundConfig(backgroundColorArgb: 0xFFFFFFFF),
      );

      // 1 page with includeBlankTrailing: true -> Spread 0 (Cover, Page 1), Spread 1 (Empty left slot)
      final doc1 = AlbumStudioDocument(pages: [page1]);
      final spreads1WithBlank = doc1.buildSpreads(includeBlankTrailing: true);
      expect(spreads1WithBlank.length, 2);
      expect(spreads1WithBlank[0].isCoverLeft, isTrue);
      expect(spreads1WithBlank[0].rightPage?.id, 'p1');
      expect(spreads1WithBlank[1].leftPage, isNull);
      expect(spreads1WithBlank[1].expectedNextPageNumber, 2);

      // 1 page with includeBlankTrailing: false -> Spread 0 only
      final spreads1WithoutBlank = doc1.buildSpreads(includeBlankTrailing: false);
      expect(spreads1WithoutBlank.length, 1);
      expect(spreads1WithoutBlank[0].isCoverLeft, isTrue);
      expect(spreads1WithoutBlank[0].rightPage?.id, 'p1');

      // 2 pages -> Spread 0 (Cover, Page 1), Spread 1 (Page 2, null)
      final doc2 = AlbumStudioDocument(pages: [page1, page2]);
      final spreads2 = doc2.buildSpreads(includeBlankTrailing: true);
      expect(spreads2.length, 2);
      expect(spreads2[0].isCoverLeft, isTrue);
      expect(spreads2[0].rightPage?.id, 'p1');
      expect(spreads2[1].leftPage?.id, 'p2');
      expect(spreads2[1].rightPage, isNull);

      // 3 pages with includeBlankTrailing: true -> Spread 0 (Cover, Page 1), Spread 1 (Page 2, Page 3), Spread 2 (Empty left slot)
      final doc3 = AlbumStudioDocument(pages: [page1, page2, page3]);
      final spreads3 = doc3.buildSpreads(includeBlankTrailing: true);
      expect(spreads3.length, 3);
      expect(spreads3[0].isCoverLeft, isTrue);
      expect(spreads3[0].rightPage?.id, 'p1');
      expect(spreads3[1].leftPage?.id, 'p2');
      expect(spreads3[1].rightPage?.id, 'p3');
      expect(spreads3[2].leftPage, isNull);
      expect(spreads3[2].expectedNextPageNumber, 4);
    });
  });
}
