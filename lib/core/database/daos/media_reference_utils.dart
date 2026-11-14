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

/// Builds the SQL query selecting unindexed images (`ocr_text IS NULL`) across
/// active entries and album collections.
String buildUnindexedImagesSql({required bool sinceFilter}) {
  final mediaSince = sinceFilter ? 'AND ma.created_at >= ?' : '';
  final albumSince = sinceFilter ? 'AND ap.created_at >= ?' : '';
  return '''
    SELECT ma.id AS id,
           'entry_media' AS source_type,
           ma.relative_path AS relative_path,
           ma.created_at AS created_at
    FROM media_attachments ma
    INNER JOIN entries e ON e.id = ma.entry_id
    WHERE ma.media_type = 'image'
      AND ma.ocr_text IS NULL
      AND e.is_deleted = 0
      $mediaSince
    UNION ALL
    SELECT ap.id AS id,
           'album_photo' AS source_type,
           ap.relative_image_path AS relative_path,
           ap.created_at AS created_at
    FROM album_photos ap
    INNER JOIN album_collections ac ON ac.id = ap.collection_id
    WHERE ap.ocr_text IS NULL
      $albumSince
    ORDER BY created_at ASC, id ASC
  ''';
}

/// Builds the SQL query counting unindexed images (`ocr_text IS NULL`) across
/// active entries and album collections.
String buildCountUnindexedImagesSql() {
  return '''
    SELECT (
      SELECT COUNT(*)
      FROM media_attachments ma
      INNER JOIN entries e ON e.id = ma.entry_id
      WHERE ma.media_type = 'image' AND ma.ocr_text IS NULL AND e.is_deleted = 0
    ) + (
      SELECT COUNT(*)
      FROM album_photos ap
      INNER JOIN album_collections ac ON ac.id = ap.collection_id
      WHERE ap.ocr_text IS NULL
    ) AS cnt
  ''';
}
