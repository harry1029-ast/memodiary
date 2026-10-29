import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/albums/services/album_layout_engine.dart';
import 'package:memodiary/features/albums/services/album_theme_catalog.dart';

AlbumCollection _buildCollection({
  String id = 'col-1',
  String title = '江南春行',
  String? description = '烟雨入江南，山水如墨染。',
  String? destinationTag = '江南',
  String? routeSummary,
  String? coverImagePath,
  String themeId = 'shanshui_ink',
}) {
  final timestamp = DateTime(2026, 4, 10);
  return AlbumCollection(
    id: id,
    title: title,
    description: description,
    destinationTag: destinationTag,
    routeSummary: routeSummary,
    coverImagePath: coverImagePath,
    startDate: DateTime(2026, 4, 1),
    endDate: DateTime(2026, 4, 5),
    layoutPreset: 'magazine',
    themeId: themeId,
    sortIndex: 0,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

AlbumPhoto _buildPhoto({
  required String id,
  required int sortOrder,
  String? caption,
  String? locationTag,
  DateTime? shotAt,
  double aspectRatio = 1.0,
}) {
  return AlbumPhoto(
    id: id,
    collectionId: 'col-1',
    relativeImagePath: 'media/$id.webp',
    relativeThumbnailPath: 'media/${id}_thumb.webp',
    caption: caption,
    locationTag: locationTag,
    shotAt: shotAt ?? DateTime(2026, 4, 2, 10, sortOrder),
    sortOrder: sortOrder,
    aspectRatio: aspectRatio,
    createdAt: DateTime(2026, 4, 2, 10, sortOrder),
  );
}

void main() {
  group('AlbumLayoutEngine.compileStudioDocument', () {
    test('autoPopulate = false starts with 1 blank starter page and places photos in removedPhotoIds tray', () {
      final collection = _buildCollection();
      final photos = [
        _buildPhoto(id: 'p1', sortOrder: 0),
        _buildPhoto(id: 'p2', sortOrder: 1),
      ];

      final doc = AlbumLayoutEngine.compileStudioDocument(
        collection: collection,
        photos: photos,
        autoPopulate: false,
      );

      expect(doc.pages.length, 1);
      expect(doc.pages.first.pageNumber, 1);
      expect(doc.pages.first.layoutTemplateId, 'solo_full_bleed');
      expect(doc.pages.first.photoSlots, isEmpty);
      expect(doc.removedPhotoIds, ['p1', 'p2']);
      expect(doc.activeThemeId, 'shanshui_ink');
    });

    test('empty photos with autoPopulate = true returns 1 blank starter page with active theme background', () {
      final collection = _buildCollection(themeId: 'jardin');
      final doc = AlbumLayoutEngine.compileStudioDocument(
        collection: collection,
        photos: const [],
        autoPopulate: true,
      );

      expect(doc.pages.length, 1);
      expect(doc.pages.first.photoSlots, isEmpty);
      expect(doc.removedPhotoIds, isEmpty);
      expect(doc.activeThemeId, 'jardin');
      final jardinTheme = AlbumThemeCatalog.getThemeById('jardin');
      expect(
        doc.pages.first.backgroundConfig,
        jardinTheme.defaultBackgroundConfig,
      );
    });

    test('autoPopulate = true packs 1 photo into solo layout with formatted date header', () {
      final collection = _buildCollection();
      final photo = _buildPhoto(
        id: 'p1',
        sortOrder: 0,
        shotAt: DateTime(2026, 4, 3, 14, 30),
      );

      final doc = AlbumLayoutEngine.compileStudioDocument(
        collection: collection,
        photos: [photo],
        autoPopulate: true,
      );

      expect(doc.pages.length, 1);
      final page = doc.pages.first;
      expect(page.layoutTemplateId, 'solo_full_bleed');
      expect(page.photoSlots.length, 1);
      expect(page.photoSlots.first.photoId, 'p1');
      expect(page.dateHeaderText, '2026.04.03');
      expect(doc.removedPhotoIds, isEmpty);
    });

    test('autoPopulate = true partitions 2 photos into duo layout', () {
      final collection = _buildCollection();
      final photos = [
        _buildPhoto(id: 'p1', sortOrder: 0, aspectRatio: 0.8),
        _buildPhoto(id: 'p2', sortOrder: 1, aspectRatio: 0.9),
      ];

      final doc = AlbumLayoutEngine.compileStudioDocument(
        collection: collection,
        photos: photos,
        autoPopulate: true,
      );

      expect(doc.pages.length, 1);
      final page = doc.pages.first;
      expect(page.layoutTemplateId, 'duo_side_by_side');
      expect(page.photoSlots.length, 2);
      expect(page.photoSlots[0].photoId, 'p1');
      expect(page.photoSlots[1].photoId, 'p2');
    });

    test('autoPopulate = true partitions 5 photos into 3 + 2 without orphan single-photo pages', () {
      final collection = _buildCollection();
      final photos = [
        for (var i = 1; i <= 5; i++) _buildPhoto(id: 'p$i', sortOrder: i - 1),
      ];

      final doc = AlbumLayoutEngine.compileStudioDocument(
        collection: collection,
        photos: photos,
        autoPopulate: true,
      );

      expect(doc.pages.length, 2);
      expect(doc.pages[0].photoSlots.length, 3);
      expect(doc.pages[0].pageNumber, 1);
      expect(doc.pages[1].photoSlots.length, 2);
      expect(doc.pages[1].pageNumber, 2);
      expect(doc.removedPhotoIds, isEmpty);
    });

    test('autoPopulate = true partitions 7 photos into 4 + 3', () {
      final collection = _buildCollection();
      final photos = [
        for (var i = 1; i <= 7; i++) _buildPhoto(id: 'p$i', sortOrder: i - 1),
      ];

      final doc = AlbumLayoutEngine.compileStudioDocument(
        collection: collection,
        photos: photos,
        autoPopulate: true,
      );

      expect(doc.pages.length, 2);
      expect(doc.pages[0].photoSlots.length, 4);
      expect(doc.pages[1].photoSlots.length, 3);
    });

    test('sorts photos deterministically by sortOrder then createdAt before chunking', () {
      final collection = _buildCollection();
      final p1 = _buildPhoto(id: 'p1', sortOrder: 1, shotAt: DateTime(2026, 4, 2));
      final p2 = _buildPhoto(id: 'p2', sortOrder: 0, shotAt: DateTime(2026, 4, 1));

      final doc = AlbumLayoutEngine.compileStudioDocument(
        collection: collection,
        photos: [p1, p2],
        autoPopulate: true,
      );

      expect(doc.pages.first.photoSlots[0].photoId, 'p2');
      expect(doc.pages.first.photoSlots[1].photoId, 'p1');
    });
  });
}
