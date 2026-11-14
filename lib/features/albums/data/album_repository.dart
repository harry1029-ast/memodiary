import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/media_sandbox_service.dart';
import '../models/album_studio_models.dart';
import '../services/album_layout_engine.dart';

/// Repository orchestrating cross-module travel memory album workflows across
/// [AppDatabase.albumsDao], [MediaSandboxService], and [AlbumLayoutEngine]:
/// reactive streams, queries, metadata updates, photo sandboxing, DB-first
/// cascade deletion, route trajectory synthesis, and Photobook studio
/// document persistence.
class AlbumRepository {
  final AppDatabase database;
  final MediaSandboxService mediaService;
  final Uuid _uuid;

  AlbumRepository({
    required this.database,
    required this.mediaService,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  /// Reactive stream of all travel album collections ordered by `sortIndex ASC, createdAt DESC`.
  Stream<List<AlbumCollection>> watchAllCollections() {
    return database.albumsDao.watchAllCollections();
  }

  /// Reactive stream emitting a map of `collectionId -> photoCount`.
  Stream<Map<String, int>> watchPhotoCounts() {
    return database.albumsDao.watchPhotoCounts();
  }

  /// Reactive stream of a single collection by [collectionId].
  Stream<AlbumCollection?> watchCollectionById(String collectionId) {
    return database.albumsDao.watchCollectionById(collectionId);
  }

  /// Reactive stream of ordered photos belonging to [collectionId].
  Stream<List<AlbumPhoto>> watchPhotosForCollection(String collectionId) {
    return database.albumsDao.watchPhotosForCollection(collectionId);
  }

  /// Retrieves a single collection by [collectionId], or null if not found.
  Future<AlbumCollection?> getCollectionById(String collectionId) {
    return database.albumsDao.getCollectionById(collectionId);
  }

  /// Retrieves all photos in [collectionId] ordered by `sortOrder ASC, createdAt ASC`.
  Future<List<AlbumPhoto>> getPhotosForCollection(String collectionId) {
    return database.albumsDao.getPhotosForCollection(collectionId);
  }

  /// Retrieves a single photo by [photoId], or null if not found.
  Future<AlbumPhoto?> getPhotoById(String photoId) {
    return database.albumsDao.getPhotoById(photoId);
  }

  /// Updates an existing collection's editable metadata fields.
  Future<void> updateCollectionMetadata({
    required String id,
    required String title,
    String? description,
    String? destinationTag,
    String? routeSummary,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return database.albumsDao.updateCollection(
      AlbumCollectionsCompanion(
        id: Value(id),
        title: Value(title),
        description: Value(description),
        destinationTag: Value(destinationTag),
        routeSummary: Value(routeSummary),
        startDate: Value(startDate),
        endDate: Value(endDate),
      ),
    );
  }

  /// Assigns [photoId] as the cover image of [collectionId].
  Future<void> setCollectionCover(String collectionId, String photoId) {
    return database.albumsDao.setCollectionCover(collectionId, photoId);
  }

  /// Persists a new ordering of collections across [orderedCollectionIds].
  Future<void> reorderCollections(List<String> orderedCollectionIds) {
    return database.albumsDao.reorderCollections(orderedCollectionIds);
  }

  /// Inserts a batch of pre-sandboxed photo companions into [collectionId].
  Future<List<AlbumPhoto>> addPhotosBatch(
    String collectionId,
    List<AlbumPhotosCompanion> photos,
  ) {
    return database.albumsDao.addPhotosBatch(collectionId, photos);
  }

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
    final resolvedSortIndex =
        sortIndex ?? await database.albumsDao.nextCollectionSortIndex();

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

    return database.albumsDao.insertCollection(companion);
  }

  /// Commits SQLite deletion of [collectionId] and all its photos first, then
  /// removes unreferenced physical `.webp` files from the `media/` sandbox.
  Future<void> deleteCollection(String collectionId) async {
    final orphanPaths =
        await database.albumsDao.deleteCollectionRecords(collectionId);
    await mediaService.deleteMediaPaths(orphanPaths);
  }

  /// Sandboxes [sourceFile] (generating 1600px full-res WebP + 300px thumbnail WebP)
  /// and inserts the resulting [AlbumPhoto] into [collectionId].
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

  /// Inserts a pre-sandboxed photo record into [collectionId], assigning
  /// `coverImagePath` on the parent collection if it currently has none.
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
        sortOrder ?? await database.albumsDao.nextPhotoSortOrder(collectionId);

    return database.albumsDao.addPhoto(
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
  }

  Future<T> _runWithAutoRouteSync<T>(
    String collectionId,
    Future<T> Function() mutation,
  ) async {
    final collection = await database.albumsDao.getCollectionById(collectionId);
    final preEditSynthesized = await synthesizeRouteSummary(collectionId);
    final currentRoute = collection?.routeSummary?.trim();
    final isAutoRoute = currentRoute == null ||
        currentRoute.isEmpty ||
        currentRoute == preEditSynthesized;

    final result = await mutation();

    if (isAutoRoute) {
      await synthesizeRouteSummary(
        collectionId,
        persistToCollection: true,
      );
    }
    return result;
  }

  /// Updates a photo's annotation (`caption`, `locationTag`, `shotAt`) and
  /// automatically regenerates the parent collection's `routeSummary` if the
  /// route was previously empty or auto-synthesized (preserving manual overrides).
  Future<void> updatePhotoAnnotationAndSyncRoute({
    required String photoId,
    Value<String?> caption = const Value.absent(),
    Value<String?> locationTag = const Value.absent(),
    Value<DateTime?> shotAt = const Value.absent(),
  }) async {
    final photo = await database.albumsDao.getPhotoById(photoId);
    if (photo == null) return;

    await _runWithAutoRouteSync(
      photo.collectionId,
      () => database.albumsDao.updatePhotoAnnotation(
        photoId: photoId,
        caption: caption,
        locationTag: locationTag,
        shotAt: shotAt,
      ),
    );
  }

  /// Reorders photos in [collectionId] and automatically regenerates
  /// `routeSummary` if the route was previously empty or auto-synthesized.
  Future<void> reorderPhotosAndSyncRoute(
    String collectionId,
    List<String> orderedPhotoIds,
  ) async {
    await _runWithAutoRouteSync(
      collectionId,
      () => database.albumsDao.reorderPhotos(collectionId, orderedPhotoIds),
    );
  }

  /// Commits SQLite deletion of [photoId] (with atomic cover reassignment and
  /// auto-route re-synthesis) first, then removes unreferenced physical `.webp`
  /// files from disk.
  Future<void> deletePhoto(String photoId) async {
    final photo = await database.albumsDao.getPhotoById(photoId);
    if (photo == null) return;

    final orphanPaths = await _runWithAutoRouteSync(
      photo.collectionId,
      () => database.albumsDao.deletePhotoRecords(photoId),
    );
    await mediaService.deleteMediaPaths(orphanPaths);
  }

  /// Synthesizes a waypoint trajectory string (e.g. `"杭州 → 乌镇 → 苏州"`) from
  /// distinct non-empty `locationTag` values across the collection's ordered photos.
  /// Returns null if no photos have a location tag.
  Future<String?> synthesizeRouteSummary(
    String collectionId, {
    bool persistToCollection = false,
  }) async {
    final photos =
        await database.albumsDao.getPhotosForCollection(collectionId);
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
      await database.albumsDao.updateCollection(
        AlbumCollectionsCompanion(
          id: Value(collectionId),
          routeSummary: Value(summary),
        ),
      );
    }

    return summary;
  }

  /// Persists [document] as `studio_layout_json` and syncs `theme_id` on [collectionId].
  Future<void> saveStudioDocument(
    String collectionId,
    AlbumStudioDocument document,
  ) async {
    await database.albumsDao.updateCollection(
      AlbumCollectionsCompanion(
        id: Value(collectionId),
        studioLayoutJson: Value(document.toJsonString()),
        themeId: Value(document.activeThemeId),
      ),
    );
  }

  /// Loads the persisted [AlbumStudioDocument] for [collectionId], or synthesizes
  /// a fresh document if none is saved yet.
  Future<AlbumStudioDocument> loadOrSynthesizeStudioDocument(
    String collectionId, {
    bool autoPopulate = false,
  }) async {
    final collection = await database.albumsDao.getCollectionById(collectionId);
    if (collection == null) {
      throw StateError('Collection $collectionId not found.');
    }

    final photos =
        await database.albumsDao.getPhotosForCollection(collectionId);
    return AlbumLayoutEngine.resolveOrCompileDocument(
      collection: collection,
      photos: photos,
      themeId: collection.themeId,
      autoPopulate: autoPopulate,
    );
  }
}
