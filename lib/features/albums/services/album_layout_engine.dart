import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../models/album_spread.dart';
import '../models/album_studio_models.dart';
import 'album_theme_catalog.dart';
import 'page_layout_catalog.dart';

/// Pure Dart layout synthesis compiler that transforms an [AlbumCollection]
/// and its ordered [AlbumPhoto] sequence into a list of [AlbumSpread] pages.
///
/// The compiled sequence is guaranteed to start with a [CoverSpread] (`pageNumber = 1`),
/// contain zero or more body spreads ([SingleHeroSpread], [DuoSpread], [QuadSpread]),
/// and conclude with an [EpilogueSpread].
class AlbumLayoutEngine {
  const AlbumLayoutEngine._();

  /// Minimum trimmed caption character length that promotes a photo to a standalone
  /// [SingleHeroSpread] so the extended reflection has ample reading room.
  static const int heroCaptionMinLength = 60;

  /// Maximum trimmed caption character length eligible for compact [QuadSpread] cells.
  static const int quadCaptionMaxLength = 25;

  /// Aspect ratio threshold at or above which a photo is treated as wide panoramic.
  static const double panoramicWideAspectThreshold = 1.6;

  /// Aspect ratio threshold at or below which a photo is treated as tall panoramic.
  static const double panoramicTallAspectThreshold = 0.6;

  /// Aspect ratio threshold at or below which two photos can be placed side-by-side
  /// in a [DuoSpread] without horizontal cramping.
  static const double sideBySideMaxAspect = 1.15;

  /// Synthesizes an ordered list of [AlbumSpread] models from [collection] and [photos].
  static List<AlbumSpread> synthesize({
    required AlbumCollection collection,
    required List<AlbumPhoto> photos,
  }) {
    final orderedPhotos = List<AlbumPhoto>.from(photos)
      ..sort((first, second) {
        final orderComparison = first.sortOrder.compareTo(second.sortOrder);
        if (orderComparison != 0) return orderComparison;
        return first.createdAt.compareTo(second.createdAt);
      });

    final spreads = <AlbumSpread>[];
    var currentPage = 1;

    // 1. Cover Spread (Page 1)
    final explicitCover = collection.coverImagePath?.trim();
    final resolvedCoverPath =
        (explicitCover != null && explicitCover.isNotEmpty)
            ? explicitCover
            : (orderedPhotos.isNotEmpty
                ? orderedPhotos.first.relativeImagePath
                : null);

    spreads.add(
      CoverSpread(
        pageNumber: currentPage++,
        title: collection.title,
        description: _normalizeOptionalText(collection.description),
        destinationTag: _normalizeOptionalText(collection.destinationTag),
        startDate: collection.startDate,
        endDate: collection.endDate,
        photoCount: orderedPhotos.length,
        coverImagePath: resolvedCoverPath,
      ),
    );

    // 2. Body Spreads
    final isEditorialPreset =
        collection.layoutPreset.trim().toLowerCase() == 'editorial';
    var cursor = 0;

    while (cursor < orderedPhotos.length) {
      final remaining = orderedPhotos.length - cursor;
      final currentPhoto = orderedPhotos[cursor];

      // Rule A: Promote to SingleHeroSpread if:
      // - Editorial preset opening photo (cursor == 0)
      // - Extended caption (>= 60 chars) or panoramic aspect ratio
      // - Only 1 photo remains
      final isOpeningEditorialHero = isEditorialPreset && cursor == 0;
      if (remaining == 1 ||
          isOpeningEditorialHero ||
          _requiresHeroSpread(currentPhoto)) {
        spreads.add(
          SingleHeroSpread(
            pageNumber: currentPage++,
            photo: currentPhoto,
          ),
        );
        cursor += 1;
        continue;
      }

      // Rule B: QuadSpread clustering when 4 (or exactly 3 remaining) consecutive
      // photos all have short captions (< 25 chars) and standard aspect ratios.
      if (remaining >= 4 &&
          _canFormQuadSpread(orderedPhotos.sublist(cursor, cursor + 4))) {
        spreads.add(
          QuadSpread(
            pageNumber: currentPage++,
            photos: orderedPhotos.sublist(cursor, cursor + 4),
          ),
        );
        cursor += 4;
        continue;
      }

      if (remaining == 3 &&
          _canFormQuadSpread(orderedPhotos.sublist(cursor, cursor + 3))) {
        spreads.add(
          QuadSpread(
            pageNumber: currentPage++,
            photos: orderedPhotos.sublist(cursor, cursor + 3),
          ),
        );
        cursor += 3;
        continue;
      }

      // Rule C: DuoSpread pairing if the next photo does not demand a standalone Hero.
      final nextPhoto = orderedPhotos[cursor + 1];
      if (!_requiresHeroSpread(nextPhoto)) {
        final orientation = (currentPhoto.aspectRatio <= sideBySideMaxAspect &&
                nextPhoto.aspectRatio <= sideBySideMaxAspect)
            ? DuoLayoutOrientation.sideBySide
            : DuoLayoutOrientation.stacked;

        spreads.add(
          DuoSpread(
            pageNumber: currentPage++,
            firstPhoto: currentPhoto,
            secondPhoto: nextPhoto,
            orientation: orientation,
          ),
        );
        cursor += 2;
        continue;
      }

      // Fallback: current photo becomes SingleHeroSpread so nextPhoto can be evaluated cleanly.
      spreads.add(
        SingleHeroSpread(
          pageNumber: currentPage++,
          photo: currentPhoto,
        ),
      );
      cursor += 1;
    }

    // 3. Epilogue Spread
    final distinctLocations = _extractOrderedDistinctLocations(orderedPhotos);
    final explicitRoute = _normalizeOptionalText(collection.routeSummary);
    final synthesizedRoute = explicitRoute ??
        (distinctLocations.isNotEmpty ? distinctLocations.join(' → ') : null);

    final destinationTag = _normalizeOptionalText(collection.destinationTag);
    final sealText = destinationTag != null && destinationTag.isNotEmpty
        ? (destinationTag.length > 4
            ? destinationTag.substring(0, 4)
            : destinationTag)
        : '拾光';

    spreads.add(
      EpilogueSpread(
        pageNumber: currentPage,
        title: collection.title,
        routeSummary: synthesizedRoute,
        totalPhotos: orderedPhotos.length,
        totalLocations: distinctLocations.length,
        sealText: sealText,
      ),
    );

    return spreads;
  }

  static bool _requiresHeroSpread(AlbumPhoto photo) {
    final captionLength = photo.caption?.trim().length ?? 0;
    if (captionLength >= heroCaptionMinLength) {
      return true;
    }
    if (photo.aspectRatio >= panoramicWideAspectThreshold ||
        photo.aspectRatio <= panoramicTallAspectThreshold) {
      return true;
    }
    return false;
  }

  static bool _canFormQuadSpread(List<AlbumPhoto> candidatePhotos) {
    for (final candidate in candidatePhotos) {
      final captionLength = candidate.caption?.trim().length ?? 0;
      if (captionLength >= quadCaptionMaxLength) {
        return false;
      }
      if (candidate.aspectRatio < 0.75 || candidate.aspectRatio > 1.45) {
        return false;
      }
    }
    return true;
  }

  static List<String> _extractOrderedDistinctLocations(
    List<AlbumPhoto> orderedPhotos,
  ) {
    final stops = <String>[];
    final seen = <String>{};
    for (final photo in orderedPhotos) {
      final tag = photo.locationTag?.trim();
      if (tag == null || tag.isEmpty) continue;
      if (seen.add(tag)) {
        stops.add(tag);
      }
    }
    return stops;
  }

  static String? _normalizeOptionalText(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Compiles an initial [AlbumStudioDocument] for the DIY Photobook Studio,
  /// packing 2 to 4 photos per page into rich multi-photo collage layouts by default
  /// instead of placing 1 photo per page.
  static AlbumStudioDocument compileStudioDocument({
    required AlbumCollection collection,
    required List<AlbumPhoto> photos,
    String? themeId,
  }) {
    final resolvedTheme =
        AlbumThemeCatalog.getThemeById(themeId ?? collection.themeId);

    final orderedPhotos = List<AlbumPhoto>.from(photos)
      ..sort((first, second) {
        final orderComparison = first.sortOrder.compareTo(second.sortOrder);
        if (orderComparison != 0) return orderComparison;
        return first.createdAt.compareTo(second.createdAt);
      });

    if (orderedPhotos.isEmpty) {
      return AlbumStudioDocument(
        activeThemeId: resolvedTheme.id,
        recentBackgroundColors: [
          resolvedTheme.defaultBackgroundConfig.backgroundColorArgb,
        ],
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

