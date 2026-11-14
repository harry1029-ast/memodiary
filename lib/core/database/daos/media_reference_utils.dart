import 'package:drift/drift.dart';
import '../app_database.dart';

/// Normalizes a sandboxed relative media path to forward-slash form.
String normalizeRelativeMediaPath(String rawPath) {
  return rawPath.trim().replaceAll('\\', '/');
}

/// Adds [rawPath] to [target] if non-null and non-empty after normalization.
void addNormalizedMediaPath(Set<String> target, String? rawPath) {
  if (rawPath == null) return;
  final normalized = normalizeRelativeMediaPath(rawPath);
  if (normalized.isNotEmpty) {
    target.add(normalized);
  }
}

/// Filters [candidatePaths] down to those with zero remaining references across
/// `albumCollections.coverImagePath`, `albumPhotos`, and `mediaAttachments`.
Future<List<String>> filterUnreferencedMediaPaths(
  AppDatabase database,
  Set<String> candidatePaths,
) async {
  final normalizedCandidates = <String>{};
  for (final rawPath in candidatePaths) {
    addNormalizedMediaPath(normalizedCandidates, rawPath);
  }
  if (normalizedCandidates.isEmpty) return const [];

  final lookupPool = <String>{
    ...candidatePaths.where((path) => path.isNotEmpty),
    ...normalizedCandidates,
  }.toList();

  final stillReferenced = <String>{};

  final matchingCovers = await (database.selectOnly(database.albumCollections)
        ..addColumns([database.albumCollections.coverImagePath])
        ..where(database.albumCollections.coverImagePath.isIn(lookupPool)))
      .get();
  for (final row in matchingCovers) {
    addNormalizedMediaPath(
      stillReferenced,
      row.read(database.albumCollections.coverImagePath),
    );
  }

  final matchingAlbumPhotos = await (database.selectOnly(database.albumPhotos)
        ..addColumns([
          database.albumPhotos.relativeImagePath,
          database.albumPhotos.relativeThumbnailPath,
        ])
        ..where(
          database.albumPhotos.relativeImagePath.isIn(lookupPool) |
              database.albumPhotos.relativeThumbnailPath.isIn(lookupPool),
        ))
      .get();
  for (final row in matchingAlbumPhotos) {
    addNormalizedMediaPath(
      stillReferenced,
      row.read(database.albumPhotos.relativeImagePath),
    );
    addNormalizedMediaPath(
      stillReferenced,
      row.read(database.albumPhotos.relativeThumbnailPath),
    );
  }

  final matchingMedia = await (database.selectOnly(database.mediaAttachments)
        ..addColumns([
          database.mediaAttachments.relativePath,
          database.mediaAttachments.thumbnailPath,
        ])
        ..where(
          database.mediaAttachments.relativePath.isIn(lookupPool) |
              database.mediaAttachments.thumbnailPath.isIn(lookupPool),
        ))
      .get();
  for (final row in matchingMedia) {
    addNormalizedMediaPath(
      stillReferenced,
      row.read(database.mediaAttachments.relativePath),
    );
    addNormalizedMediaPath(
      stillReferenced,
      row.read(database.mediaAttachments.thumbnailPath),
    );
  }

  return normalizedCandidates
      .where((path) => !stillReferenced.contains(path))
      .toList();
}
