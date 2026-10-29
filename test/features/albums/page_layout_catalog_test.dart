import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/albums/services/album_layout_engine.dart';
import 'package:memodiary/features/albums/services/page_layout_catalog.dart';

AlbumCollection _buildCollection({
  String id = 'col_studio',
  String title = '西湖春游手账',
  String themeId = 'jardin',
}) {
  final now = DateTime(2026, 5, 1);
  return AlbumCollection(
    id: id,
    title: title,
    layoutPreset: 'classic_photobook',
    themeId: themeId,
    sortIndex: 0,
    createdAt: now,
    updatedAt: now,
  );
}

AlbumPhoto _buildPhoto({
  required String id,
  required int sortOrder,
  double aspectRatio = 1.0,
  DateTime? shotAt,
}) {
  return AlbumPhoto(
    id: id,
    collectionId: 'col_studio',
    relativeImagePath: 'media/$id.webp',
    relativeThumbnailPath: 'media/${id}_thumb.webp',
    shotAt: shotAt ?? DateTime(2026, 5, 1, 10, sortOrder),
    sortOrder: sortOrder,
    aspectRatio: aspectRatio,
    createdAt: DateTime(2026, 5, 1, 10, sortOrder),
  );
}

void main() {
  group('PageLayoutCatalog Geometry & Bounds Verification', () {
    test(
      'defines 18+ templates covering 1, 2, 3, 4, 5, and 6 photos per page',
      () {
        expect(
          PageLayoutCatalog.allTemplates.length,
          greaterThanOrEqualTo(18),
        );

        for (var count = 1; count <= 6; count++) {
          final templates = PageLayoutCatalog.templatesForPhotoCount(count);
          expect(
            templates,
            isNotEmpty,
            reason: 'Expected at least 2 templates for photoCount=$count',
          );
          expect(templates.length, greaterThanOrEqualTo(2));
        }
      },
    );

    test(
      'all template photo slots and dateHeaderSlots are strictly within normalized 0.0..1.0 bounds and non-overlapping',
      () {
        const epsilon = 1e-6;

        for (final template in PageLayoutCatalog.allTemplates) {
          expect(
            template.slots.length,
            equals(template.photoCount),
            reason: 'Template ${template.id} slot count mismatch',
          );

          if (template.dateHeaderSlot != null) {
            final header = template.dateHeaderSlot!;
            expect(header.left, greaterThanOrEqualTo(-epsilon));
            expect(header.top, greaterThanOrEqualTo(-epsilon));
            expect(header.right, lessThanOrEqualTo(1.0 + epsilon));
            expect(header.bottom, lessThanOrEqualTo(1.0 + epsilon));
            expect(header.width, greaterThan(0));
            expect(header.height, greaterThan(0));
          }

          for (var i = 0; i < template.slots.length; i++) {
            final slot = template.slots[i];
            expect(
              slot.left,
              greaterThanOrEqualTo(-epsilon),
              reason: '${template.id} slot $i left out of bounds',
            );
            expect(
              slot.top,
              greaterThanOrEqualTo(-epsilon),
              reason: '${template.id} slot $i top out of bounds',
            );
            expect(
              slot.right,
              lessThanOrEqualTo(1.0 + epsilon),
              reason: '${template.id} slot $i right out of bounds',
            );
            expect(
              slot.bottom,
              lessThanOrEqualTo(1.0 + epsilon),
              reason: '${template.id} slot $i bottom out of bounds',
            );
            expect(slot.width, greaterThan(0));
            expect(slot.height, greaterThan(0));

            if (template.dateHeaderSlot != null) {
              final overlapHeader =
                  slot.intersect(template.dateHeaderSlot!);
              expect(
                overlapHeader.width <= epsilon ||
                    overlapHeader.height <= epsilon,
                isTrue,
                reason:
                    '${template.id} slot $i overlaps with dateHeaderSlot',
              );
            }

            for (var j = i + 1; j < template.slots.length; j++) {
              final other = template.slots[j];
              final intersection = slot.intersect(other);
              expect(
                intersection.width <= epsilon ||
                    intersection.height <= epsilon,
                isTrue,
                reason: '${template.id} slots $i and $j overlap',
              );
            }
          }
        }
      },
    );
  });

  group('AlbumLayoutEngine.compileStudioDocument Multi-Photo Auto-Packing', () {
    test('empty collection compiles 1 starter page with active theme', () {
      final collection = _buildCollection(themeId: 'jardin');
      final doc = AlbumLayoutEngine.compileStudioDocument(
        collection: collection,
        photos: const [],
      );

      expect(doc.activeThemeId, equals('jardin'));
      expect(doc.pages.length, equals(1));
      expect(doc.pages.first.photoSlots, isEmpty);
      expect(doc.removedPhotoIds, isEmpty);
    });

    test(
      'compiles clean-slate studio document with 1 blank starter page and all photos in Collection Box by default',
      () {
        final collection = _buildCollection(themeId: 'shanshui_ink');
        final fourPhotos = [
          for (var i = 0; i < 4; i++) _buildPhoto(id: 'clean_$i', sortOrder: i),
        ];

        final doc = AlbumLayoutEngine.compileStudioDocument(
          collection: collection,
          photos: fourPhotos,
        );

        expect(doc.pages.length, equals(1));
        expect(doc.pages.first.photoSlots, isEmpty);
        expect(doc.removedPhotoIds.length, equals(4));
        expect(doc.removedPhotoIds, equals(['clean_0', 'clean_1', 'clean_2', 'clean_3']));
      },
    );

    test(
      'packs 2 to 4 photos per page when autoPopulate is true',
      () {
        final collection = _buildCollection(themeId: 'shanshui_ink');

        // 6 photos -> packed into 2 pages of 3 photos each (not 6 pages of 1!)
        final sixPhotos = [
          for (var i = 0; i < 6; i++) _buildPhoto(id: 'p_$i', sortOrder: i),
        ];

        final doc6 = AlbumLayoutEngine.compileStudioDocument(
          collection: collection,
          photos: sixPhotos,
          autoPopulate: true,
        );

        expect(doc6.pages.length, equals(2));
        expect(doc6.pages[0].photoSlots.length, equals(3));
        expect(doc6.pages[1].photoSlots.length, equals(3));
        expect(doc6.pages[0].dateHeaderText, equals('2026.05.01'));

        // 5 photos -> packed into 2 pages of 3 + 2 photos
        final fivePhotos = sixPhotos.sublist(0, 5);
        final doc5 = AlbumLayoutEngine.compileStudioDocument(
          collection: collection,
          photos: fivePhotos,
          autoPopulate: true,
        );
        expect(doc5.pages.length, equals(2));
        expect(doc5.pages[0].photoSlots.length, equals(3));
        expect(doc5.pages[1].photoSlots.length, equals(2));

        // 10 photos -> every page has between 2 and 4 photos
        final tenPhotos = [
          for (var i = 0; i < 10; i++) _buildPhoto(id: 'p10_$i', sortOrder: i),
        ];
        final doc10 = AlbumLayoutEngine.compileStudioDocument(
          collection: collection,
          photos: tenPhotos,
          autoPopulate: true,
        );
        expect(doc10.pages.length, lessThanOrEqualTo(4));
        for (final page in doc10.pages) {
          expect(page.photoSlots.length, inInclusiveRange(2, 4));
        }
      },
    );
  });
}

