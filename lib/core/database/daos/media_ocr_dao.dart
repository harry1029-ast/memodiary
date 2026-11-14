import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/album_collections.dart';
import '../tables/album_photos.dart';
import '../tables/entries.dart';
import '../tables/media_attachments.dart';
import 'fts_query_utils.dart';
import 'media_reference_utils.dart';

export 'media_attachment_draft.dart';

part 'media_ocr_dao.g.dart';

/// Data access object for entry [MediaAttachments], canonical referenced-media
/// aggregation, on-device OCR indexing/backfill, and `media_fts` photo text search.
@DriftAccessor(tables: [MediaAttachments, Entries, AlbumCollections, AlbumPhotos])
class MediaOcrDao extends DatabaseAccessor<AppDatabase>
    with _$MediaOcrDaoMixin {
  MediaOcrDao(super.attachedDatabase);

  static final RegExp _alphaNumRegex = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// Records a media attachment linked to an entry with a strictly relative path.
  Future<int> attachMediaToEntry({
    required String id,
    required String entryId,
    required String relativePath,
    String mediaType = 'image',
    String? thumbnailPath,
  }) {
    return into(mediaAttachments).insert(
      MediaAttachmentsCompanion.insert(
        id: id,
        entryId: entryId,
        mediaType: mediaType,
        relativePath: relativePath,
        thumbnailPath: Value(thumbnailPath),
      ),
    );
  }

  /// Atomically inserts [attachments] for [entryId] inside a single transaction.
  Future<void> attachMediaBatch({
    required String entryId,
    required List<MediaAttachmentDraft> attachments,
  }) async {
    if (attachments.isEmpty) return;
    await attachedDatabase.transaction(() async {
      await batch((batchExecutor) {
        batchExecutor.insertAll(
          mediaAttachments,
          [
            for (final item in attachments)
              MediaAttachmentsCompanion.insert(
                id: item.id,
                entryId: entryId,
                mediaType: item.mediaType,
                relativePath: item.relativePath,
                thumbnailPath: Value(item.thumbnailPath),
              ),
          ],
        );
      });
    });
  }

  /// Retrieves all media attachments of [entryId] in collect order (oldest first).
  Future<List<MediaAttachment>> getMediaForEntry(String entryId) {
    return (select(mediaAttachments)
          ..where((attachment) => attachment.entryId.equals(entryId))
          ..orderBy([
            (attachment) => OrderingTerm.asc(attachment.createdAt),
            (attachment) => OrderingTerm.asc(const CustomExpression<int>('rowid')),
          ]))
        .get();
  }

  /// Deletes media attachment records matching both [entryId] and [relativePath].
  Future<int> deleteMediaForEntryByPath({
    required String entryId,
    required String relativePath,
  }) {
    return (delete(mediaAttachments)
          ..where(
            (attachment) =>
                attachment.entryId.equals(entryId) &
                attachment.relativePath.equals(relativePath),
          ))
        .go();
  }

  /// Retrieves all video media attachments associated with [entryId].
  Future<List<MediaAttachment>> getVideosForEntry(String entryId) {
    return (select(mediaAttachments)
          ..where((attachment) =>
              attachment.entryId.equals(entryId) &
              attachment.mediaType.equals('video')))
        .get();
  }

  /// Batch retrieves the primary (first) media attachment for each given entry ID.
  Future<Map<String, MediaAttachment>> getPrimaryMediaForEntries(
    List<String> entryIds,
  ) async {
    if (entryIds.isEmpty) return {};
    final records = await (select(mediaAttachments)
          ..where((attachment) => attachment.entryId.isIn(entryIds)))
        .get();
    final map = <String, MediaAttachment>{};
    for (final item in records) {
      map.putIfAbsent(item.entryId, () => item);
    }
    return map;
  }

  /// Retrieves a single [MediaAttachment] by its [id].
  Future<MediaAttachment?> getMediaAttachmentById(String id) {
    return (select(mediaAttachments)
          ..where((attachment) => attachment.id.equals(id)))
        .getSingleOrNull();
  }

  /// Retrieves a single [AlbumPhoto] by its [id].
  Future<AlbumPhoto?> getAlbumPhotoById(String id) {
    return (select(albumPhotos)..where((photo) => photo.id.equals(id)))
        .getSingleOrNull();
  }

  /// Returns all normalized non-empty relative media paths referenced across
  /// `mediaAttachments`, `albumCollections.coverImagePath`, and `albumPhotos`.
  Future<Set<String>> getAllReferencedMediaPaths() {
    return transaction(() async {
      final paths = <String>{};
      await _collectDistinctPaths(
        mediaAttachments,
        [mediaAttachments.relativePath, mediaAttachments.thumbnailPath],
        paths,
      );
      await _collectDistinctPaths(
        albumCollections,
        [albumCollections.coverImagePath],
        paths,
      );
      await _collectDistinctPaths(
        albumPhotos,
        [albumPhotos.relativeImagePath, albumPhotos.relativeThumbnailPath],
        paths,
      );
      return paths;
    });
  }

  Future<void> _collectDistinctPaths<T extends Table, D>(
    TableInfo<T, D> table,
    List<Expression<String>> columns,
    Set<String> target,
  ) async {
    final rows = await (selectOnly(table, distinct: true)..addColumns(columns)).get();
    for (final row in rows) {
      for (final column in columns) {
        addNormalizedMediaPath(target, row.read(column));
      }
    }
  }

  /// Updates cached OCR text and normalized line bounding boxes on an entry media attachment.
  Future<void> updateMediaOcr(
    String id, {
    required String ocrText,
    required String ocrBlocksJson,
  }) {
    return (update(mediaAttachments)..where((attachment) => attachment.id.equals(id)))
        .write(MediaAttachmentsCompanion(
      ocrText: Value(ocrText),
      ocrBlocksJson: Value(ocrBlocksJson),
    ));
  }

  /// Updates the diarist-authored caption of an entry media attachment,
  /// leaving OCR text (and therefore `media_fts`) untouched.
  Future<void> updateMediaCaption(String id, {required String caption}) {
    return (update(mediaAttachments)..where((attachment) => attachment.id.equals(id)))
        .write(MediaAttachmentsCompanion(caption: Value(caption)));
  }

  /// Updates cached OCR text and normalized line bounding boxes on an album photo.
  Future<void> updateAlbumPhotoOcr(
    String id, {
    required String ocrText,
    required String ocrBlocksJson,
  }) {
    return (update(albumPhotos)..where((photo) => photo.id.equals(id))).write(
      AlbumPhotosCompanion(
        ocrText: Value(ocrText),
        ocrBlocksJson: Value(ocrBlocksJson),
      ),
    );
  }

  /// Updates the normalized overlay coordinates of a media attachment.
  Future<void> updateMediaAttachmentOverlayPosition(
    String id, {
    double? xRatio,
    double? yRatio,
  }) {
    return (update(mediaAttachments)..where((attachment) => attachment.id.equals(id)))
        .write(MediaAttachmentsCompanion(
      overlayXRatio: Value(xRatio),
      overlayYRatio: Value(yRatio),
    ));
  }

  /// Searches OCR text across entry media attachments and album photos using
  /// dual-path FTS5 `MATCH` and CJK `LIKE` fallback, enforcing strict entry privacy.
  Future<List<PhotoTextMatch>> searchPhotoText(
    String query, {
    int limit = 50,
    DateTime? now,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || limit <= 0) return const [];

    final (entryMediaIds, albumPhotoIds) =
        await _findPhotoTextCandidateIds(trimmed);
    if (entryMediaIds.isEmpty && albumPhotoIds.isEmpty) {
      return const [];
    }

    final effectiveNow = now ?? DateTime.now();
    final matches = <PhotoTextMatch>[];
    final seenIds = <String>{};

    if (entryMediaIds.isNotEmpty) {
      await _collectEntryMediaMatches(
        entryMediaIds: entryMediaIds,
        effectiveNow: effectiveNow,
        seenIds: seenIds,
        matches: matches,
      );
    }

    if (albumPhotoIds.isNotEmpty) {
      await _collectAlbumPhotoMatches(
        albumPhotoIds: albumPhotoIds,
        seenIds: seenIds,
        matches: matches,
      );
    }

    matches.sort((left, right) {
      final leftEpoch = left.parentDate?.millisecondsSinceEpoch ?? 0;
      final rightEpoch = right.parentDate?.millisecondsSinceEpoch ?? 0;
      final dateCompare = rightEpoch.compareTo(leftEpoch);
      if (dateCompare != 0) return dateCompare;
      return left.id.compareTo(right.id);
    });

    return matches.length > limit ? matches.sublist(0, limit) : matches;
  }

  Future<(Set<String>, Set<String>)> _findPhotoTextCandidateIds(
    String trimmedQuery,
  ) async {
    final entryMediaIds = <String>{};
    final albumPhotoIds = <String>{};

    if (_alphaNumRegex.hasMatch(trimmedQuery)) {
      final ftsRows = await customSelect(
        'SELECT id, source_type FROM media_fts WHERE media_fts MATCH ?',
        variables: [Variable.withString(formatFts5PrefixQuery(trimmedQuery))],
        readsFrom: {mediaAttachments, albumPhotos},
      ).get();

      for (final row in ftsRows) {
        final id = row.read<String>('id');
        final sourceType = row.read<String>('source_type');
        if (sourceType == PhotoTextMatch.sourceEntryMedia) {
          entryMediaIds.add(id);
        } else if (sourceType == PhotoTextMatch.sourceAlbumPhoto) {
          albumPhotoIds.add(id);
        }
      }
    }

    if (containsCjkCharacters(trimmedQuery)) {
      final escapedLike = formatSqlLikeContainsPattern(trimmedQuery);
      final mediaLikeRows = await customSelect(
        r"SELECT id FROM media_attachments WHERE media_type = 'image' AND coalesce(ocr_text, '') LIKE ? ESCAPE '\'",
        variables: [Variable.withString(escapedLike)],
        readsFrom: {mediaAttachments},
      ).get();
      for (final row in mediaLikeRows) {
        entryMediaIds.add(row.read<String>('id'));
      }

      final albumLikeRows = await customSelect(
        r"SELECT id FROM album_photos WHERE coalesce(ocr_text, '') LIKE ? ESCAPE '\'",
        variables: [Variable.withString(escapedLike)],
        readsFrom: {albumPhotos},
      ).get();
      for (final row in albumLikeRows) {
        albumPhotoIds.add(row.read<String>('id'));
      }
    }

    return (entryMediaIds, albumPhotoIds);
  }

  Future<void> _collectEntryMediaMatches({
    required Set<String> entryMediaIds,
    required DateTime effectiveNow,
    required Set<String> seenIds,
    required List<PhotoTextMatch> matches,
  }) async {
    final joinedEntryRows = await (select(mediaAttachments).join([
      innerJoin(entries, entries.id.equalsExp(mediaAttachments.entryId)),
    ])
          ..where(
            mediaAttachments.id.isIn(entryMediaIds) &
                mediaAttachments.mediaType.equals('image') &
                mediaAttachments.ocrText.isNotNull() &
                mediaAttachments.ocrText.equals('').not() &
                entries.isDeleted.equals(false) &
                entries.isLocked.equals(false) &
                (entries.unlockAt.isNull() |
                    entries.unlockAt.isSmallerOrEqualValue(effectiveNow)),
          ))
        .get();

    for (final row in joinedEntryRows) {
      final attachment = row.readTable(mediaAttachments);
      final entry = row.readTable(entries);
      if (seenIds.add(attachment.id)) {
        matches.add(
          PhotoTextMatch(
            id: attachment.id,
            sourceType: PhotoTextMatch.sourceEntryMedia,
            parentId: attachment.entryId,
            relativePath: attachment.relativePath,
            thumbnailPath: attachment.thumbnailPath,
            ocrText: attachment.ocrText ?? '',
            ocrBlocksJson: attachment.ocrBlocksJson,
            parentTitle: entry.title,
            parentDate: entry.entryDate,
          ),
        );
      }
    }
  }

  Future<void> _collectAlbumPhotoMatches({
    required Set<String> albumPhotoIds,
    required Set<String> seenIds,
    required List<PhotoTextMatch> matches,
  }) async {
    final joinedAlbumRows = await (select(albumPhotos).join([
      innerJoin(
        albumCollections,
        albumCollections.id.equalsExp(albumPhotos.collectionId),
      ),
    ])
          ..where(
            albumPhotos.id.isIn(albumPhotoIds) &
                albumPhotos.ocrText.isNotNull() &
                albumPhotos.ocrText.equals('').not(),
          ))
        .get();

    for (final row in joinedAlbumRows) {
      final photo = row.readTable(albumPhotos);
      final collection = row.readTable(albumCollections);
      if (seenIds.add(photo.id)) {
        matches.add(
          PhotoTextMatch(
            id: photo.id,
            sourceType: PhotoTextMatch.sourceAlbumPhoto,
            parentId: photo.collectionId,
            relativePath: photo.relativeImagePath,
            thumbnailPath: photo.relativeThumbnailPath,
            ocrText: photo.ocrText ?? '',
            ocrBlocksJson: photo.ocrBlocksJson,
            parentTitle: collection.title,
            parentDate: photo.shotAt ?? photo.createdAt,
          ),
        );
      }
    }
  }

  UnindexedImageItem _mapUnindexedImageRow(QueryRow row) {
    return UnindexedImageItem(
      id: row.read<String>('id'),
      sourceType: row.read<String>('source_type'),
      relativePath: row.read<String>('relative_path'),
      createdAt: row.read<DateTime>('created_at'),
    );
  }

  /// Returns all images across active entries and album collections whose
  /// `ocr_text` is `NULL`, ordered chronologically (`created_at ASC`).
  Future<List<UnindexedImageItem>> getUnindexedImages() async {
    final rows = await customSelect(
      buildUnindexedImagesSql(sinceFilter: false),
      readsFrom: {mediaAttachments, entries, albumPhotos, albumCollections},
    ).get();

    return rows.map(_mapUnindexedImageRow).toList();
  }

  /// Counts all unindexed images (`ocr_text IS NULL`) across active entries and albums.
  Future<int> countUnindexedImages() async {
    final row = await customSelect(
      '''
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
      ''',
      readsFrom: {mediaAttachments, entries, albumPhotos, albumCollections},
    ).getSingle();

    return row.read<int>('cnt');
  }

  /// Reactively watches unindexed images across active entries and album collections
  /// created at or after [since], ordered chronologically (`created_at ASC`).
  Stream<List<UnindexedImageItem>> watchUnindexedImagesSince(DateTime since) {
    return customSelect(
      buildUnindexedImagesSql(sinceFilter: true),
      variables: [
        Variable.withDateTime(since),
        Variable.withDateTime(since),
      ],
      readsFrom: {mediaAttachments, entries, albumPhotos, albumCollections},
    ).watch().map((rows) => rows.map(_mapUnindexedImageRow).toList());
  }
}
