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
