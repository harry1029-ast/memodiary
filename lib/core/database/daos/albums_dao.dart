import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/album_collections.dart';
import '../tables/album_photos.dart';
import 'media_reference_utils.dart';

part 'albums_dao.g.dart';

/// Data access object for pure SQL persistence of [AlbumCollections] and
/// [AlbumPhotos], including atomic deletion and cover reassignment.
@DriftAccessor(tables: [AlbumCollections, AlbumPhotos])
class AlbumsDao extends DatabaseAccessor<AppDatabase> with _$AlbumsDaoMixin {
  AlbumsDao(super.attachedDatabase);

  /// Computes the next `sortIndex` for a newly created collection.
  Future<int> nextCollectionSortIndex() async {
    final existing = await (select(albumCollections)
          ..orderBy([(collection) => OrderingTerm.desc(collection.sortIndex)])
          ..limit(1))
        .getSingleOrNull();
    return existing != null ? existing.sortIndex + 1 : 0;
  }

  /// Inserts a new collection record and returns the persisted row.
  Future<AlbumCollection> insertCollection(
    AlbumCollectionsCompanion companion,
  ) async {
    await into(albumCollections).insert(companion);
    return (await getCollectionById(companion.id.value))!;
  }

  /// Updates an existing collection's metadata.
  Future<void> updateCollection(AlbumCollectionsCompanion companion) async {
    if (!companion.id.present) {
      throw ArgumentError('Collection ID must be present when updating.');
    }
    final updatedCompanion = companion.copyWith(
      updatedAt: Value(DateTime.now()),
    );
    await (update(albumCollections)
          ..where((collection) => collection.id.equals(companion.id.value)))
        .write(updatedCompanion);
  }

  /// Retrieves a single collection by its [id], or null if not found.
  Future<AlbumCollection?> getCollectionById(String id) {
    return (select(albumCollections)
          ..where((collection) => collection.id.equals(id)))
        .getSingleOrNull();
  }

  /// Reactive stream of a single collection by its [id].
  Stream<AlbumCollection?> watchCollectionById(String id) {
    return (select(albumCollections)
          ..where((collection) => collection.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Retrieves all travel album collections ordered by `sortIndex ASC, createdAt DESC`.
  Future<List<AlbumCollection>> getAllCollections() {
    return (select(albumCollections)
          ..orderBy([
            (collection) => OrderingTerm.asc(collection.sortIndex),
            (collection) => OrderingTerm.desc(collection.createdAt),
          ]))
        .get();
  }

  /// Retrieves the most recently created travel album collection, or null if none exist.
  Future<AlbumCollection?> getLatestCollection() {
    return (select(albumCollections)
          ..orderBy([(collection) => OrderingTerm.desc(collection.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Reactive stream of all travel album collections ordered by `sortIndex ASC, createdAt DESC`.
  Stream<List<AlbumCollection>> watchAllCollections() {
    return (select(albumCollections)
          ..orderBy([
            (collection) => OrderingTerm.asc(collection.sortIndex),
            (collection) => OrderingTerm.desc(collection.createdAt),
          ]))
        .watch();
  }

  /// Reactive stream emitting the total photo count for [collectionId].
  Stream<int> watchPhotoCountForCollection(String collectionId) {
    final countExp = albumPhotos.id.count();
    final query = selectOnly(albumPhotos)
      ..addColumns([countExp])
      ..where(albumPhotos.collectionId.equals(collectionId));
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  /// Reactive stream emitting a map of `collectionId -> photoCount` across all collections.
  Stream<Map<String, int>> watchPhotoCounts() {
    final collectionIdCol = albumPhotos.collectionId;
    final countExp = albumPhotos.id.count();
    final query = selectOnly(albumPhotos)
      ..addColumns([collectionIdCol, countExp])
      ..groupBy([collectionIdCol]);

    return query.watch().map((rows) {
      final counts = <String, int>{};
      for (final row in rows) {
        final colId = row.read(collectionIdCol);
        final count = row.read(countExp) ?? 0;
        if (colId != null) {
          counts[colId] = count;
        }
      }
      return counts;
    });
  }

  /// Sets [photoId]'s `relativeImagePath` as the `coverImagePath` of [collectionId].
  Future<void> setCollectionCover(String collectionId, String photoId) async {
    final photo = await getPhotoById(photoId);
    if (photo == null || photo.collectionId != collectionId) {
      throw StateError(
        'Photo $photoId does not belong to collection $collectionId.',
      );
    }
    await updateCollection(
      AlbumCollectionsCompanion(
        id: Value(collectionId),
        coverImagePath: Value(photo.relativeImagePath),
      ),
    );
  }

  /// Batch-updates `sortIndex` across collections inside a single transaction.
  Future<void> reorderCollections(List<String> orderedCollectionIds) async {
    final now = DateTime.now();
    await transaction(() async {
      for (var index = 0; index < orderedCollectionIds.length; index++) {
        final collectionId = orderedCollectionIds[index];
        await (update(albumCollections)
              ..where((collection) => collection.id.equals(collectionId)))
            .write(
          AlbumCollectionsCompanion(
            sortIndex: Value(index),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  /// Computes the next `sortOrder` for a photo added to [collectionId].
  Future<int> nextPhotoSortOrder(String collectionId) async {
    final existing = await (select(albumPhotos)
          ..where((photo) => photo.collectionId.equals(collectionId))
          ..orderBy([(photo) => OrderingTerm.desc(photo.sortOrder)])
          ..limit(1))
        .getSingleOrNull();
    return existing != null ? existing.sortOrder + 1 : 0;
  }

  /// Inserts a photo record into its collection inside a transaction and
  /// automatically sets `coverImagePath` if the parent collection has none.
  Future<AlbumPhoto> addPhoto(AlbumPhotosCompanion companion) async {
    final now = DateTime.now();
    final collectionId = companion.collectionId.value;

    await transaction(() async {
      await into(albumPhotos).insert(companion);

      final collection = await getCollectionById(collectionId);
      if (collection != null &&
          (collection.coverImagePath == null ||
              collection.coverImagePath!.isEmpty)) {
        await (update(albumCollections)
              ..where((tbl) => tbl.id.equals(collectionId)))
            .write(
          AlbumCollectionsCompanion(
            coverImagePath: Value(companion.relativeImagePath.value),
            updatedAt: Value(now),
          ),
        );
      } else {
        await (update(albumCollections)
              ..where((tbl) => tbl.id.equals(collectionId)))
            .write(
          AlbumCollectionsCompanion(
            updatedAt: Value(now),
          ),
        );
      }
    });

    return (await getPhotoById(companion.id.value))!;
  }

  /// Inserts multiple photo companions into [collectionId] in a single atomic batch.
  Future<List<AlbumPhoto>> addPhotosBatch(
    String collectionId,
    List<AlbumPhotosCompanion> photos,
  ) async {
    if (photos.isEmpty) return const [];
    final now = DateTime.now();

    await transaction(() async {
      await batch((batchOp) {
        batchOp.insertAll(albumPhotos, photos);
      });

      final collection = await getCollectionById(collectionId);
      if (collection != null) {
        final needsCover = collection.coverImagePath == null ||
            collection.coverImagePath!.isEmpty;
        final firstCover =
            needsCover ? photos.first.relativeImagePath.value : null;
        await (update(albumCollections)
              ..where((tbl) => tbl.id.equals(collectionId)))
            .write(
          AlbumCollectionsCompanion(
            coverImagePath: needsCover
                ? Value(firstCover)
                : const Value.absent(),
            updatedAt: Value(now),
          ),
        );
      }
    });

    return getPhotosForCollection(collectionId);
  }

  /// Retrieves a single photo by its [id], or null if not found.
  Future<AlbumPhoto?> getPhotoById(String id) {
    return (select(albumPhotos)..where((photo) => photo.id.equals(id)))
        .getSingleOrNull();
  }

  /// Retrieves all photos in [collectionId] ordered by `sortOrder ASC, createdAt ASC`.
  Future<List<AlbumPhoto>> getPhotosForCollection(String collectionId) {
    return (select(albumPhotos)
          ..where((photo) => photo.collectionId.equals(collectionId))
          ..orderBy([
            (photo) => OrderingTerm.asc(photo.sortOrder),
            (photo) => OrderingTerm.asc(photo.createdAt),
          ]))
        .get();
  }

  /// Reactive stream of all photos in [collectionId] ordered by `sortOrder ASC, createdAt ASC`.
  Stream<List<AlbumPhoto>> watchPhotosForCollection(String collectionId) {
    return (select(albumPhotos)
          ..where((photo) => photo.collectionId.equals(collectionId))
          ..orderBy([
            (photo) => OrderingTerm.asc(photo.sortOrder),
            (photo) => OrderingTerm.asc(photo.createdAt),
          ]))
        .watch();
  }

  /// Updates per-photo notation fields (`caption`, `locationTag`, `shotAt`).
  Future<void> updatePhotoAnnotation({
    required String photoId,
    Value<String?> caption = const Value.absent(),
    Value<String?> locationTag = const Value.absent(),
    Value<DateTime?> shotAt = const Value.absent(),
  }) async {
    final photo = await getPhotoById(photoId);
    if (photo == null) return;

    await transaction(() async {
      await (update(albumPhotos)..where((row) => row.id.equals(photoId))).write(
        AlbumPhotosCompanion(
          caption: caption,
          locationTag: locationTag,
          shotAt: shotAt,
        ),
      );

      await (update(albumCollections)
            ..where((collection) => collection.id.equals(photo.collectionId)))
          .write(
        AlbumCollectionsCompanion(
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// Batch-updates `sortOrder` (`0..N-1`) for photos in [collectionId] inside a transaction.
  Future<void> reorderPhotos(
    String collectionId,
    List<String> orderedPhotoIds,
  ) async {
    final now = DateTime.now();
    await transaction(() async {
      for (var index = 0; index < orderedPhotoIds.length; index++) {
        final photoId = orderedPhotoIds[index];
        await (update(albumPhotos)
              ..where((photo) =>
                  photo.id.equals(photoId) &
                  photo.collectionId.equals(collectionId)))
            .write(
          AlbumPhotosCompanion(
            sortOrder: Value(index),
          ),
        );
      }

      await (update(albumCollections)
            ..where((collection) => collection.id.equals(collectionId)))
          .write(
        AlbumCollectionsCompanion(
          updatedAt: Value(now),
        ),
      );
    });
  }

  /// Transactionally deletes [collectionId] and all its photos, returning
  /// strictly the candidate sandbox paths that are no longer referenced in
  /// `albumCollections`, `albumPhotos`, or `mediaAttachments`.
  Future<List<String>> deleteCollectionRecords(String collectionId) async {
    return transaction(() async {
      final collection = await getCollectionById(collectionId);
      final photos = await getPhotosForCollection(collectionId);

      final candidatePaths = <String>{};
      addNormalizedMediaPath(candidatePaths, collection?.coverImagePath);
      for (final photo in photos) {
        addNormalizedMediaPath(candidatePaths, photo.relativeImagePath);
        addNormalizedMediaPath(candidatePaths, photo.relativeThumbnailPath);
      }

      await (delete(albumPhotos)
            ..where((photo) => photo.collectionId.equals(collectionId)))
          .go();
      await (delete(albumCollections)
            ..where((collectionRow) => collectionRow.id.equals(collectionId)))
          .go();

      return filterUnreferencedMediaPaths(attachedDatabase, candidatePaths);
    });
  }

  /// Transactionally deletes [photoId], atomically reassigns the parent
  /// collection's `coverImagePath` if it pointed to this photo, and returns
  /// strictly the candidate paths no longer referenced in SQLite.
  Future<List<String>> deletePhotoRecords(String photoId) async {
    return transaction(() async {
      final photo = await getPhotoById(photoId);
      if (photo == null) return const [];

      final candidatePaths = <String>{};
      addNormalizedMediaPath(candidatePaths, photo.relativeImagePath);
      addNormalizedMediaPath(candidatePaths, photo.relativeThumbnailPath);

      final parentCollection = await getCollectionById(photo.collectionId);

      await (delete(albumPhotos)..where((row) => row.id.equals(photoId))).go();

      final normalizedCover = parentCollection?.coverImagePath != null
          ? normalizeRelativeMediaPath(parentCollection!.coverImagePath!)
          : null;
      if (normalizedCover != null && candidatePaths.contains(normalizedCover)) {
        final remainingPhotos = await getPhotosForCollection(photo.collectionId);
        final nextCover = remainingPhotos.isNotEmpty
            ? remainingPhotos.first.relativeImagePath
            : null;
        await (update(albumCollections)
              ..where((collection) => collection.id.equals(photo.collectionId)))
            .write(
          AlbumCollectionsCompanion(
            coverImagePath: Value(nextCover),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      return filterUnreferencedMediaPaths(attachedDatabase, candidatePaths);
    });
  }
}
