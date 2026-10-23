# Milestone 3.5 — Phase 11 Task Checklist: Drift Schema v3 Migration, Media Pipeline & Album Repository

- [ ] **Task 11.1: Drift Schema v3 Migration (`lib/core/database/`)**
  - [ ] Create `lib/core/database/tables/album_collections.dart` defining `AlbumCollections` (`id`, `title`, `description`, `destinationTag`, `routeSummary`, `coverImagePath`, `startDate`, `endDate`, `layoutPreset`, `sortIndex`, `createdAt`, `updatedAt`).
  - [ ] Create `lib/core/database/tables/album_photos.dart` defining `AlbumPhotos` (`id`, `collectionId` with `KeyAction.cascade` reference to `AlbumCollections.id`, `relativeImagePath`, `relativeThumbnailPath`, `caption`, `locationTag`, `shotAt`, `sortOrder`, `aspectRatio`, `createdAt`).
  - [ ] Register `AlbumCollections` and `AlbumPhotos` in `@DriftDatabase` in `lib/core/database/app_database.dart` and update `lib/core/database/app_database.g.dart`.
  - [ ] Bump `schemaVersion` from `2` to `3` in `AppDatabase`, add `onCreate` and `onUpgrade (from < 3)` logic creating both tables and composite index `idx_album_photos_collection_order ON album_photos(collection_id, sort_order ASC)`, and ensure `PRAGMA foreign_keys = ON` is enabled in connection setup.

- [ ] **Task 11.2: Cascade File Deletion & Media Pipeline (`lib/core/services/`)**
  - [ ] Add `AlbumPhotoSandboxResult` and `copyAndProcessAlbumPhoto(File sourceFile)` to `MediaSandboxService` to generate the full-res (`media/{uuid}.webp`, max 1600px, 80% quality) and thumbnail (`media/{uuid}_thumb.webp`, 300px, 75% quality) WebP files along with cached `aspectRatio`.
  - [ ] Implement `deleteCollectionAndMedia({required String collectionId, required AppDatabase database})` and `deletePhotoAndMedia({required String photoId, required AppDatabase database})` on `MediaSandboxService` to purge deduplicated physical `.webp` full-res, thumbnail, and cover files from `media/` before deleting the SQLite rows.

- [ ] **Task 11.3: Full-Archive Backup Integration (`lib/features/import_export/`)**
  - [ ] Update `BackupDatabaseSnapshot` in `backup_manifest.dart` to include `albumCollections` and `albumPhotos` with backward-compatible deserialization (`?? const []`) for legacy v1/v2 `.mdbak` archives.
  - [ ] Bump `BackupManifest.maxSupportedSchemaVersion` from `2` to `3` and include collection/photo counts in manifest metadata and `BackupResult` / `RestoreResult`.
  - [ ] Update `AppDatabase.exportAllTablesSnapshot()` and `AppDatabase.replaceAllFromBackup()` to snapshot, delete (`albumPhotos` -> `albumCollections`), and restore (`albumCollections` -> `albumPhotos`) in strict foreign-key dependency order.
  - [ ] Update `BackupRestoreService.createBackup()` and `restoreBackup()` to discover, hash (SHA-256), and validate strictly relative paths for `coverImagePath`, `relativeImagePath`, and `relativeThumbnailPath`.

- [ ] **Task 11.4: AlbumRepository (`lib/features/albums/data/album_repository.dart`)**
  - [ ] Implement collection CRUD (`createCollection`, `updateCollection`, `getCollectionById`, `getAllCollections`, `watchAllCollections`, `reorderCollections`).
  - [ ] Implement photo CRUD (`addPhoto`, `addPhotosBatch`, `updatePhotoAnnotation`, `getPhotosForCollection`, `watchPhotosForCollection`, `reorderPhotos` batch transaction).
  - [ ] Implement automatic `routeSummary` synthesis helper (`synthesizeRouteSummary(String collectionId)`) from distinct chronological photo `locationTag`s (`"杭州 → 乌镇 → 苏州"`) when not manually overridden.
  - [ ] Delegate `deleteCollection(String collectionId)` and `deletePhoto(String photoId)` to `deleteCollectionAndMedia` / `deletePhotoAndMedia` so UI callers get atomic disk + DB cleanup through the repository seam.

- [ ] **Task 11.5: Automated Verification (`test/`)**
  - [ ] Create `test/core/database/schema_v3_migration_test.dart` verifying non-destructive v2 -> v3 upgrade, foreign-key cascade deletion, and index creation.
  - [ ] Create `test/features/albums/album_repository_test.dart` verifying collection/photo CRUD, reactive Drift watchers, batch `sortOrder` reordering, route trajectory synthesis, and cascade physical `.webp` file cleanup.
  - [ ] Update/extend `test/features/import_export/backup_manifest_test.dart` and `backup_restore_service_test.dart` to verify v3 round-trip backup/restore and legacy v2 archive backward compatibility.
  - [ ] Run `flutter analyze` (0 issues) and `test/hardening/network_quarantine_audit_test.dart`.
