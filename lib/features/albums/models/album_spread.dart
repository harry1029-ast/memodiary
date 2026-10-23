import '../../../core/database/app_database.dart';

/// Orientation for paired two-photo spreads ([DuoSpread]).
enum DuoLayoutOrientation {
  /// Two portrait or square photos placed side-by-side (`Row`).
  sideBySide,

  /// Two landscape or mixed-aspect photos stacked vertically (`Column`).
  stacked,
}

/// Sealed hierarchy representing a single synthesized page spread in a Travel Memory Album.
///
/// Compiled deterministically by `AlbumLayoutEngine.synthesize` from an
/// [AlbumCollection] and its ordered [AlbumPhoto] list.
sealed class AlbumSpread {
  /// 1-based page number of this spread within the compiled keepsake album.
  final int pageNumber;

  const AlbumSpread({required this.pageNumber});
}

/// Opening title & prologue spread of a Travel Memory Album.
final class CoverSpread extends AlbumSpread {
  final String title;
  final String? description;
  final String? destinationTag;
  final DateTime? startDate;
  final DateTime? endDate;
  final int photoCount;
  final String? coverImagePath;

  const CoverSpread({
    required super.pageNumber,
    required this.title,
    this.description,
    this.destinationTag,
    this.startDate,
    this.endDate,
    required this.photoCount,
    this.coverImagePath,
  });
}

/// Full-page feature spread showcasing a single high-impact [AlbumPhoto]
/// alongside its extended literati reflection (`写影札`), location badge, and capture date.
final class SingleHeroSpread extends AlbumSpread {
  final AlbumPhoto photo;

  const SingleHeroSpread({
    required super.pageNumber,
    required this.photo,
  });
}

/// Paired two-photo spread arranged either [DuoLayoutOrientation.sideBySide]
/// (for portrait/square pairs) or [DuoLayoutOrientation.stacked] (when landscape).
final class DuoSpread extends AlbumSpread {
  final AlbumPhoto firstPhoto;
  final AlbumPhoto secondPhoto;
  final DuoLayoutOrientation orientation;

  const DuoSpread({
    required super.pageNumber,
    required this.firstPhoto,
    required this.secondPhoto,
    required this.orientation,
  });
}

/// Compact 2x2 grid spread grouping 3 to 4 detail [AlbumPhoto] items
/// with concise metadata pills.
final class QuadSpread extends AlbumSpread {
  final List<AlbumPhoto> photos;

  const QuadSpread({
    required super.pageNumber,
    required this.photos,
  }) : assert(
          photos.length >= 3 && photos.length <= 4,
          'QuadSpread must contain 3 or 4 photos.',
        );
}

/// Concluding spread of the keepsake album displaying the complete travel
/// route trajectory (`"杭州 → 乌镇 → 苏州"`), trip summary counts, and Cinnabar seal imprint.
final class EpilogueSpread extends AlbumSpread {
  final String title;
  final String? routeSummary;
  final int totalPhotos;
  final int totalLocations;
  final String sealText;

  const EpilogueSpread({
    required super.pageNumber,
    required this.title,
    this.routeSummary,
    required this.totalPhotos,
    required this.totalLocations,
    required this.sealText,
  });
}

