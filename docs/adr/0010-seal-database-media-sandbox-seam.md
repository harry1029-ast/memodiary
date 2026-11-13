---
status: accepted
---

# Seal the AppDatabase & Media Sandbox Seam

`MediaSandboxService` is strictly a pure filesystem module with zero dependency on `AppDatabase` or Drift tables. `AppDatabase` is decomposed into cohesive `@DriftAccessor` DAOs (`EntriesDao`, `TemplatesDao`, `MediaOcrDao`, `AlbumsDao`, `BackupDao`) exposing typed interfaces directly, without preserving shallow forwarding wrappers on `AppDatabase`.

Both `StorageOptimizerService` and `BackupRestoreService` consume a single canonical media-reference interface (`MediaOcrDao.getAllReferencedMediaPaths()`, uniting `mediaAttachments.{relativePath, thumbnailPath}`, `albumCollections.coverImagePath`, and `albumPhotos.{relativeImagePath, relativeThumbnailPath}`) alongside `MediaSandboxService.listMediaFiles()` (which excludes dotfiles and restricts default scans to `.webp`, `.mp4`, `.png`, `.jpg`, and `.jpeg`). Across album and recycle-bin permanent deletions (`AlbumRepository` and `RecycleBinService`), the SQLite transaction commits first—calculating unreferenced candidate paths inside SQLite—and `MediaSandboxService.deleteMediaPaths(...)` deletes physical files afterward.

## Considered Options

- **Delete files before SQLite commit**: Rejected because any SQLite exception or rollback permanently destroys user photos while leaving broken dangling paths in the database.
- **Cross-module deletion coordinator owning both `AppDatabase` and `MediaSandboxService`**: Rejected for album operations because `AlbumRepository` already owns album workflows and would otherwise become a shallow pass-through.
- **Keep forwarding methods on `AppDatabase`**: Rejected because maintaining ~40 forwarding methods keeps `AppDatabase` shallow, oversized (> 450 LOC), and encourages raw table queries outside the database module.

## Consequences

- **Rare post-commit orphan files**: If the process crashes or filesystem deletion fails after SQLite commits, unreferenced files remain harmlessly in `media/` and are reclaimed automatically on the next `StorageOptimizerService.purgeOrphanMedia()` run, rather than breaking SQLite integrity.
- **Single source of media truth**: Any future table column storing sandbox relative paths must be added to `MediaOcrDao.getAllReferencedMediaPaths()` so storage purge and `.memodiary` backup archives stay synchronized.
- **No raw Drift selects in callers**: Feature screens and background coordinators consume typed DAO methods instead of `database.select(database.*)` directly.
