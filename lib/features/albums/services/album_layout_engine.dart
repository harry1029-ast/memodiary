import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../models/album_studio_models.dart';
import 'album_theme_catalog.dart';
import 'page_layout_catalog.dart';

/// Pure Dart layout synthesis compiler for the DIY Photobook Studio.
///
/// Transforms an [AlbumCollection] and its ordered [AlbumPhoto] sequence
/// into a canonical [AlbumStudioDocument].
class AlbumLayoutEngine {
  const AlbumLayoutEngine._();

  /// Resolves the persisted [AlbumStudioDocument] from [collection.studioLayoutJson],
  /// reconciling it with [photos], or compiles a fresh multi-photo collage document
  /// if none is saved or if JSON parsing fails.
  static AlbumStudioDocument resolveOrCompileDocument({
    required AlbumCollection collection,
    required List<AlbumPhoto> photos,
    String? themeId,
  }) {
    final rawJson = collection.studioLayoutJson?.trim();
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        return AlbumStudioDocument.fromJsonString(rawJson)
            .reconcileWithPhotoIds(photos.map((photo) => photo.id));
      } catch (_) {
        // Fall through to compile fresh layout on corrupted or legacy payload
      }
    }

    return compileStudioDocument(
      collection: collection,
      photos: photos,
      themeId: themeId,
      autoPopulate: true,
    );
  }

  /// Compiles an initial [AlbumStudioDocument] for the DIY Photobook Studio.
  ///
  /// By default ([autoPopulate] = false), gives users full creative autonomy by starting
  /// with a single blank starter page styled with the active theme background, placing all
  /// ingested photos directly into the Collection Box tray ([AlbumStudioDocument.removedPhotoIds]).
  ///
  /// When [autoPopulate] is true, automatically packs 2 to 4 photos per page into multi-photo
  /// collage layouts.
  static AlbumStudioDocument compileStudioDocument({
    required AlbumCollection collection,
    required List<AlbumPhoto> photos,
    String? themeId,
    bool autoPopulate = false,
  }) {
    final resolvedTheme =
        AlbumThemeCatalog.getThemeById(themeId ?? collection.themeId);

    final orderedPhotos = List<AlbumPhoto>.from(photos)
      ..sort((first, second) {
        final orderComparison = first.sortOrder.compareTo(second.sortOrder);
        if (orderComparison != 0) return orderComparison;
        return first.createdAt.compareTo(second.createdAt);
      });

    if (!autoPopulate || orderedPhotos.isEmpty) {
      return AlbumStudioDocument(
        activeThemeId: resolvedTheme.id,
        recentBackgroundColors: [
          resolvedTheme.defaultBackgroundConfig.backgroundColorArgb,
        ],
        removedPhotoIds: orderedPhotos.map((photo) => photo.id).toList(),
        pages: [
          AlbumPageModel(
            id: 'page_1',
            pageNumber: 1,
            layoutTemplateId: 'solo_full_bleed',
            photoSlots: const [],
            backgroundConfig: resolvedTheme.defaultBackgroundConfig,
          ),
        ],
      );
    }

    final chunks = _partitionIntoMultiPhotoChunks(orderedPhotos);
    final pages = <AlbumPageModel>[];
    final dateFormat = DateFormat('yyyy.MM.dd');

    for (var pageIdx = 0; pageIdx < chunks.length; pageIdx++) {
      final chunk = chunks[pageIdx];
      final aspectRatios =
          chunk.map((photo) => photo.aspectRatio).toList(growable: false);
      final template = PageLayoutCatalog.defaultTemplateForPhotoCount(
        chunk.length,
        aspectRatios: aspectRatios,
        pageVariationIndex: pageIdx,
      );

      final slots = <PhotoSlotAssignment>[
        for (var slotIdx = 0; slotIdx < chunk.length; slotIdx++)
          PhotoSlotAssignment(
            slotIndex: slotIdx,
            photoId: chunk[slotIdx].id,
          ),
      ];

      DateTime? earliestShot;
      for (final photo in chunk) {
        if (photo.shotAt != null) {
          if (earliestShot == null || photo.shotAt!.isBefore(earliestShot)) {
            earliestShot = photo.shotAt;
          }
        }
      }
      earliestShot ??= collection.startDate;

      final bgConfig = resolvedTheme.backgroundConfigForIndex(pageIdx);

      pages.add(
        AlbumPageModel(
          id: 'page_${pageIdx + 1}',
          pageNumber: pageIdx + 1,
          layoutTemplateId: template.id,
          photoSlots: slots,
          backgroundConfig: bgConfig,
          dateHeaderText:
              earliestShot != null ? dateFormat.format(earliestShot) : null,
        ),
      );
    }

    return AlbumStudioDocument(
      pages: pages,
      removedPhotoIds: const [],
      recentBackgroundColors: [
        resolvedTheme.defaultBackgroundConfig.backgroundColorArgb,
      ],
      activeThemeId: resolvedTheme.id,
    );
  }

  /// Partitions [orderedPhotos] into chunks of 2 to 4 photos per page so that
  /// any collection with >= 2 photos uses multi-photo collage layouts without
  /// leaving single-photo orphan pages.
  static List<List<AlbumPhoto>> _partitionIntoMultiPhotoChunks(
    List<AlbumPhoto> orderedPhotos,
  ) {
    final chunks = <List<AlbumPhoto>>[];
    var cursor = 0;
    var step = 0;

    while (cursor < orderedPhotos.length) {
      final remaining = orderedPhotos.length - cursor;
      int takeCount;

      if (remaining == 1) {
        takeCount = 1;
      } else if (remaining == 2) {
        takeCount = 2;
      } else if (remaining == 3) {
        takeCount = 3;
      } else if (remaining == 4) {
        takeCount = 4;
      } else if (remaining == 5) {
        // Split 5 into 3 + 2 so both pages are multi-photo collages
        takeCount = 3;
      } else if (remaining == 6) {
        // Split 6 into 3 + 3
        takeCount = 3;
      } else if (remaining == 7) {
        // Split 7 into 4 + 3
        takeCount = 4;
      } else {
        // Alternate 3 and 4 photos per page for visual rhythm
        takeCount = step.isEven ? 3 : 4;
        if (remaining - takeCount == 1) {
          takeCount = 3;
        }
      }

      chunks.add(orderedPhotos.sublist(cursor, cursor + takeCount));
      cursor += takeCount;
      step += 1;
    }

    return chunks;
  }
}
