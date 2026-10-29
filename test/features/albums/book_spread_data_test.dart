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
  });
}
