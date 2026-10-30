import 'dart:io';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../models/album_studio_models.dart';
import '../services/album_layout_engine.dart';

/// Repository encapsulating travel memory album (`AlbumCollections` & `AlbumPhotos`)
/// relational queries, reactive Drift streams, batch reordering, route trajectory
/// synthesis, and physical sandboxed WebP media cleanup.
class AlbumRepository {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final Uuid _uuid;

  AlbumRepository({
    required this.database,
    required this.mediaService,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  // ===========================================================================
  // Album Collection Operations
  // ===========================================================================

  /// Creates and persists a new travel album collection.
  Future<AlbumCollection> createCollection({
    String? id,
    required String title,
    String? description,
    String? destinationTag,
    String? routeSummary,
    String? coverImagePath,
    DateTime? startDate,
    DateTime? endDate,
    String layoutPreset = 'classic_photobook',
    String? studioLayoutJson,
    String themeId = 'shanshui_ink',
    int? sortIndex,
  }) async {
    final collectionId = id ?? _uuid.v4();
    final now = DateTime.now();

    final resolvedSortIndex = sortIndex ?? await _nextCollectionSortIndex();

    final companion = AlbumCollectionsCompanion.insert(
      id: collectionId,
      title: title.trim(),
      description: Value(description),
      destinationTag: Value(destinationTag),
      routeSummary: Value(routeSummary),
      coverImagePath: Value(coverImagePath),
      startDate: Value(startDate),
      endDate: Value(endDate),
      layoutPreset: Value(layoutPreset),
      studioLayoutJson: Value(studioLayoutJson),
      themeId: Value(themeId),
      sortIndex: Value(resolvedSortIndex),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    await database.into(database.albumCollections).insert(companion);
    return (await getCollectionById(collectionId))!;
  }

  Future<int> _nextCollectionSortIndex() async {
    final existing = await (database.select(database.albumCollections)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.sortIndex)])
          ..limit(1))
        .getSingleOrNull();
    return existing != null ? existing.sortIndex + 1 : 0;
  }

  /// Updates an existing collection's metadata.
  Future<void> updateCollection(AlbumCollectionsCompanion companion) async {
    if (!companion.id.present) {
      throw ArgumentError('Collection ID must be present when updating.');
    }
    final updatedCompanion = companion.copyWith(
      updatedAt: Value(DateTime.now()),
    );
    await (database.update(database.albumCollections)
          ..where((tbl) => tbl.id.equals(companion.id.value)))
        .write(updatedCompanion);
  }

  /// Retrieves a single collection by its [id], or null if not found.
  Future<AlbumCollection?> getCollectionById(String id) {
    return (database.select(database.albumCollections)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Reactive stream of a single collection by its [id].
  Stream<AlbumCollection?> watchCollectionById(String id) {
    return (database.select(database.albumCollections)
          ..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Retrieves all travel album collections ordered by `sortIndex ASC, createdAt DESC`.
  Future<List<AlbumCollection>> getAllCollections() {
    return (database.select(database.albumCollections)
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.sortIndex),
            (tbl) => OrderingTerm.desc(tbl.createdAt),
          ]))
        .get();
  }

  /// Retrieves the most recently created travel album collection, or null if none exist.
  Future<AlbumCollection?> getLatestCollection() {
    return (database.select(database.albumCollections)
          ..orderBy([(table) => OrderingTerm.desc(table.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Reactive stream of all travel album collections ordered by `sortIndex ASC, createdAt DESC`.
  Stream<List<AlbumCollection>> watchAllCollections() {
    return (database.select(database.albumCollections)
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.sortIndex),
            (tbl) => OrderingTerm.desc(tbl.createdAt),
          ]))
        .watch();
  }

  /// Reactive stream emitting the total photo count for [collectionId].
  Stream<int> watchPhotoCountForCollection(String collectionId) {
    final countExp = database.albumPhotos.id.count();
    final query = database.selectOnly(database.albumPhotos)
      ..addColumns([countExp])
      ..where(database.albumPhotos.collectionId.equals(collectionId));
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  /// Reactive stream emitting a map of `collectionId -> photoCount` across all collections
  /// using a single `GROUP BY` query.
  Stream<Map<String, int>> watchPhotoCounts() {
    final collectionIdCol = database.albumPhotos.collectionId;
    final countExp = database.albumPhotos.id.count();
    final query = database.selectOnly(database.albumPhotos)
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
    await database.transaction(() async {
      for (var index = 0; index < orderedCollectionIds.length; index++) {
        final collectionId = orderedCollectionIds[index];
        await (database.update(database.albumCollections)
              ..where((tbl) => tbl.id.equals(collectionId)))
            .write(
          AlbumCollectionsCompanion(
            sortIndex: Value(index),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  /// Deletes [collectionId] after purging all associated physical `.webp` full-res,
  /// thumbnail, and cover files from the `media/` sandbox directory.
  Future<void> deleteCollection(String collectionId) {
    return mediaService.deleteCollectionAndMedia(
      collectionId: collectionId,
      database: database,
    );
  }

  // ===========================================================================
  // Album Photo Operations
  // ===========================================================================

  /// Sandboxes [sourceFile] (generating 1600px full-res WebP + 300px thumbnail WebP)
  /// and inserts the resulting `AlbumPhoto` into [collectionId].
  Future<AlbumPhoto> ingestAndAddPhoto({
    required String collectionId,
    required File sourceFile,
    String? id,
    String? caption,
    String? locationTag,
    DateTime? shotAt,
    int? sortOrder,
  }) async {
    final sandboxed = await mediaService.copyAndProcessAlbumPhoto(sourceFile);
    return addPhoto(
      id: id,
      collectionId: collectionId,
      relativeImagePath: sandboxed.relativeImagePath,
      relativeThumbnailPath: sandboxed.relativeThumbnailPath,
      aspectRatio: sandboxed.aspectRatio,
      caption: caption,
      locationTag: locationTag,
      shotAt: shotAt,
      sortOrder: sortOrder,
    );
  }

  /// Inserts a pre-sandboxed photo record into [collectionId].
  /// Automatically assigns `coverImagePath` on the parent collection if it has none.
  Future<AlbumPhoto> addPhoto({
    String? id,
    required String collectionId,
    required String relativeImagePath,
    required String relativeThumbnailPath,
    String? caption,
    String? locationTag,
    DateTime? shotAt,
    int? sortOrder,
    double aspectRatio = 1.0,
  }) async {
    final photoId = id ?? _uuid.v4();
    final now = DateTime.now();
    final resolvedSortOrder =
        sortOrder ?? await _nextPhotoSortOrder(collectionId);

    await database.transaction(() async {
      await database.into(database.albumPhotos).insert(
            AlbumPhotosCompanion.insert(
              id: photoId,
              collectionId: collectionId,
              relativeImagePath: relativeImagePath,
              relativeThumbnailPath: relativeThumbnailPath,
              caption: Value(caption),
              locationTag: Value(locationTag),
              shotAt: Value(shotAt),
              sortOrder: Value(resolvedSortOrder),
              aspectRatio: Value(aspectRatio),
              createdAt: Value(now),
            ),
          );

      final collection = await getCollectionById(collectionId);
      if (collection != null &&
          (collection.coverImagePath == null ||
              collection.coverImagePath!.isEmpty)) {
        await (database.update(database.albumCollections)
              ..where((tbl) => tbl.id.equals(collectionId)))
            .write(
          AlbumCollectionsCompanion(
            coverImagePath: Value(relativeImagePath),
            updatedAt: Value(now),
          ),
        );
      } else {
        await (database.update(database.albumCollections)
              ..where((tbl) => tbl.id.equals(collectionId)))
            .write(
          AlbumCollectionsCompanion(
            updatedAt: Value(now),
          ),
        );
      }
    });

    return (await getPhotoById(photoId))!;
  }

  /// Inserts multiple photo companions into [collectionId] in a single atomic batch.
  /// Automatically assigns `coverImagePath` on the parent collection if it has none.
  Future<List<AlbumPhoto>> addPhotosBatch(
    String collectionId,
    List<AlbumPhotosCompanion> photos,
  ) async {
    if (photos.isEmpty) return const [];
    final now = DateTime.now();

    await database.transaction(() async {
      await database.batch((batch) {
        batch.insertAll(database.albumPhotos, photos);
      });

      final collection = await getCollectionById(collectionId);
      if (collection != null) {
        final needsCover = collection.coverImagePath == null ||
            collection.coverImagePath!.isEmpty;
        final firstCover =
            needsCover ? photos.first.relativeImagePath.value : null;
        await (database.update(database.albumCollections)
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

  Future<int> _nextPhotoSortOrder(String collectionId) async {
    final existing = await (database.select(database.albumPhotos)
          ..where((tbl) => tbl.collectionId.equals(collectionId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.sortOrder)])
          ..limit(1))
        .getSingleOrNull();
    return existing != null ? existing.sortOrder + 1 : 0;
  }

  /// Retrieves a single photo by its [id], or null if not found.
  Future<AlbumPhoto?> getPhotoById(String id) {
    return (database.select(database.albumPhotos)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Retrieves all photos in [collectionId] ordered by `sortOrder ASC, createdAt ASC`.
  Future<List<AlbumPhoto>> getPhotosForCollection(String collectionId) {
    return (database.select(database.albumPhotos)
          ..where((tbl) => tbl.collectionId.equals(collectionId))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.sortOrder),
            (tbl) => OrderingTerm.asc(tbl.createdAt),
          ]))
        .get();
  }

  /// Reactive stream of all photos in [collectionId] ordered by `sortOrder ASC, createdAt ASC`.
  Stream<List<AlbumPhoto>> watchPhotosForCollection(String collectionId) {
    return (database.select(database.albumPhotos)
          ..where((tbl) => tbl.collectionId.equals(collectionId))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.sortOrder),
            (tbl) => OrderingTerm.asc(tbl.createdAt),
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

    await database.transaction(() async {
      await (database.update(database.albumPhotos)
            ..where((tbl) => tbl.id.equals(photoId)))
          .write(
        AlbumPhotosCompanion(
          caption: caption,
          locationTag: locationTag,
          shotAt: shotAt,
        ),
      );

      await (database.update(database.albumCollections)
            ..where((tbl) => tbl.id.equals(photo.collectionId)))
          .write(
        AlbumCollectionsCompanion(
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// Updates a photo's annotation (`caption`, `locationTag`, `shotAt`) and automatically
  /// regenerates the parent collection's `routeSummary` if the route was previously empty
  /// or auto-synthesized (preserving manual user overrides).
  Future<void> updatePhotoAnnotationAndSyncRoute({
    required String photoId,
    Value<String?> caption = const Value.absent(),
    Value<String?> locationTag = const Value.absent(),
    Value<DateTime?> shotAt = const Value.absent(),
  }) async {
    final photo = await getPhotoById(photoId);
    if (photo == null) return;

    final collection = await getCollectionById(photo.collectionId);
    final preEditSynthesized = await synthesizeRouteSummary(photo.collectionId);

    final currentRoute = collection?.routeSummary?.trim();
    final isAutoRoute = currentRoute == null ||
        currentRoute.isEmpty ||
        currentRoute == preEditSynthesized;

    await updatePhotoAnnotation(
      photoId: photoId,
      caption: caption,
      locationTag: locationTag,
      shotAt: shotAt,
    );

    if (isAutoRoute) {
      await synthesizeRouteSummary(
        photo.collectionId,
        persistToCollection: true,
      );
    }
  }

  /// Batch-updates `sortOrder` (`0..N-1`) for photos in [collectionId] inside a transaction.
  Future<void> reorderPhotos(
    String collectionId,
    List<String> orderedPhotoIds,
  ) async {
    final now = DateTime.now();
    await database.transaction(() async {
      for (var index = 0; index < orderedPhotoIds.length; index++) {
        final photoId = orderedPhotoIds[index];
        await (database.update(database.albumPhotos)
              ..where((tbl) =>
                  tbl.id.equals(photoId) &
                  tbl.collectionId.equals(collectionId)))
            .write(
          AlbumPhotosCompanion(
            sortOrder: Value(index),
          ),
        );
      }

      await (database.update(database.albumCollections)
            ..where((tbl) => tbl.id.equals(collectionId)))
          .write(
        AlbumCollectionsCompanion(
          updatedAt: Value(now),
        ),
      );
    });
  }

  /// Deletes a single [photoId] and removes its physical `.webp` full-res and thumbnail
  /// files from the `media/` sandbox directory.
  Future<void> deletePhoto(String photoId) {
    return mediaService.deletePhotoAndMedia(
      photoId: photoId,
      database: database,
    );
  }

  /// Synthesizes a waypoint trajectory string (e.g. `"杭州 → 乌镇 → 苏州"`) from
  /// distinct non-empty `locationTag` values across the collection's ordered photos.
  /// Returns null if no photos have a location tag.
  Future<String?> synthesizeRouteSummary(
    String collectionId, {
    bool persistToCollection = false,
  }) async {
    final photos = await getPhotosForCollection(collectionId);
    final waypoints = <String>[];

    for (final photo in photos) {
      final rawTag = photo.locationTag?.trim();
      if (rawTag == null || rawTag.isEmpty) continue;
      if (!waypoints.contains(rawTag)) {
        waypoints.add(rawTag);
      }
    }

    final summary = waypoints.isEmpty ? null : waypoints.join(' → ');

    if (persistToCollection) {
      await updateCollection(
        AlbumCollectionsCompanion(
          id: Value(collectionId),
          routeSummary: Value(summary),
        ),
      );
    }

    return summary;
  }

  // ===========================================================================
  // Studio Document Persistence
  // ===========================================================================

  /// Persists [document] as `studio_layout_json` and syncs `theme_id` on [collectionId].
  Future<void> saveStudioDocument(
    String collectionId,
    AlbumStudioDocument document,
  ) async {
    await updateCollection(
      AlbumCollectionsCompanion(
        id: Value(collectionId),
        studioLayoutJson: Value(document.toJsonString()),
        themeId: Value(document.activeThemeId),
      ),
    );
  }

  /// Loads the persisted [AlbumStudioDocument] for [collectionId], or synthesizes
  /// a fresh multi-photo collage document if none is saved yet.
  Future<AlbumStudioDocument> loadOrSynthesizeStudioDocument(
    String collectionId,
  ) async {
    final collection = await getCollectionById(collectionId);
    if (collection == null) {
      throw StateError('Collection $collectionId not found.');
    }

    final photos = await getPhotosForCollection(collectionId);
    return AlbumLayoutEngine.resolveOrCompileDocument(
      collection: collection,
      photos: photos,
      themeId: collection.themeId,
      autoPopulate: false,
    );
  }
}

