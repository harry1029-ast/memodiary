---
id: SPEC-015
title: Seal the AppDatabase & Media Sandbox Seam
status: ready-for-agent
created_at: 2026-11-13T22:44:00+08:00
adr: ADR-0010
---

# Specification: Seal the AppDatabase & Media Sandbox Seam

## Problem Statement

Media storage management and persistence suffer from an inverted dependency seam, stale table awareness, and a monolithic database module:

- **Silent Travel Photobook & Cover Loss on Orphan Purge**: When a diarist runs Storage Optimization to reclaim orphaned media files, the optimizer only checks `mediaAttachments` for referenced paths. Valid travel Photobook photos and collection cover images stored in `albumPhotos` and `albumCollections` are misclassified as orphans and permanently deleted from disk.
- **Fragile Failure Ordering on Permanent Delete**: Both travel album deletion and recycle-bin permanent deletion remove physical image and video files from the sandbox before committing the SQLite delete transaction. If SQLite throws or rolls back, the user loses physical media files while SQLite retains broken dangling paths.
- **Inverted Media Seam & Duplicated Directory Scans**: The sandbox media module imports `AppDatabase` directly to run raw Drift queries against album tables and reassign covers, while both storage optimization and backup archive creation duplicate directory-walking logic (including a synthetic `'media/.probe'` parent lookup) and disagree on which hidden or temporary files belong in scans.
- **Monolithic Database Module (`1,447` LOC) & Raw Table Leakage**: `AppDatabase` mixes schema migrations, full-text search, template defaults (duplicated between `onCreate` and backup restore), OCR indexing, and backup serialization in one oversized file, while feature screens and background modules run raw `database.select(...)` queries directly instead of going through typed persistence interfaces.

## Solution

Reshape and deepen the seam between SQLite persistence (`AppDatabase` + typed Drift DAOs) and sandboxed filesystem operations (`MediaSandboxService`) in line with **ADR-0010**:

- **Pure Filesystem Media Sandbox**: Remove `AppDatabase` and all Drift queries from `MediaSandboxService`, leaving it purely responsible for image/video sandboxing, compression, path resolution/validation, listing media files cleanly, and batch-deleting relative paths.
- **Canonical Referenced Media & Unified Scanning**: Introduce a single referenced-media query aggregating `mediaAttachments`, `albumCollections.coverImagePath`, and `albumPhotos`, paired with a single sandbox directory listing operation filtering dotfiles and non-media extensions, shared by both `StorageOptimizerService` and `BackupRestoreService`.
- **SQLite-First Deletion Order & Deep `AlbumRepository`**: Move album persistence into `AlbumsDao`, keep `AlbumRepository` strictly for cross-module orchestration (ingestion, DB-first delete + cleanup, route synthesis, Photobook document persistence), and commit SQLite deletes before removing physical files across both `AlbumRepository` and `RecycleBinService`.
- **Cohesive Drift DAO Decomposition**: Split `AppDatabase` into `@DriftAccessor` DAOs (`EntriesDao`, `TemplatesDao`, `MediaOcrDao`, `AlbumsDao`, `BackupDao`), deduplicate built-in template defaults and FTS search helpers, migrate raw `select(...)` callers onto typed DAO interfaces, and remove shallow forwarding methods from `AppDatabase`.

## User Stories

### Orphan Protection & Storage Diagnostics

1. As a diarist using travel Photobooks, I want Storage Optimization's orphan analysis to recognize every photo in `albumPhotos` (both full-resolution images and thumbnails) as referenced, so that running cleanup never deletes my album memories.
2. As a diarist who assigns a collection cover image in `albumCollections`, I want that `coverImagePath` treated as a referenced media file even if referenced only as a cover, so that Storage Optimization never flags or purges cover art.
3. As a diarist with attachments on soft-deleted diary entries in the 30-day trash bin, I want Storage Optimization to treat those trashed entry attachments (`mediaAttachments`) as referenced until permanent deletion, so that restoring an entry from the bin always retains its media.
4. As a diarist running Storage Optimization, I want true orphan files left inside the sandbox `media/` directory (with zero references across diary attachments, album photos, and album covers) to be accurately counted in MB/KB and deleted upon confirmation, so that wasted space is reclaimed.
5. As a diarist with hidden OS/editor files (dotfiles) or unsupported scratch files inside the media directory, I want storage analytics, orphan purge, and encrypted backups to ignore hidden/non-media noise consistently, so that metrics and archives stay clean and predictable.

### Deletion Integrity & Photobook Workflows

6. As a diarist deleting a single album photo, I want SQLite to commit the deletion (and reassign `coverImagePath` atomically if needed) *before* deleting the underlying `.webp` and thumbnail files from disk, so that a failed database write can never destroy live image files.
7. As a diarist deleting an entire album collection, I want all SQLite collection/photo deletions to commit before deleting unreferenced sandbox files, while keeping any file still referenced by another collection, photo, cover, or diary attachment intact on disk.
8. As a diarist permanently deleting or emptying an entry from the Recycle Bin, I want SQLite records to commit deletion first and unreferenced physical media files to be removed afterward, so that failed transactions never leave dangling media references.
9. As a diarist whose device experiences an interrupted deletion after SQLite commit, I want any rare leftover disk file to stay invisible in the UI and be reclaimed cleanly on the next Storage Optimization pass, rather than corrupting gallery state.

### Encrypted Backup Consistency

10. As a diarist exporting an encrypted `.memodiary` backup archive, I want backup discovery to collect every referenced media path across `mediaAttachments`, `albumCollections`, and `albumPhotos` plus valid media files in `media/` using the same canonical interfaces as Storage Optimization, so backups never miss album covers or photos.
11. As a diarist restoring a `.memodiary` archive on a new device or clean install, I want the built-in system templates to be restored from the exact same canonical seed definitions used during initial database creation, so restored entries never diverge in default styling.

### Developer Ergonomics & Module Depth

12. As a developer working with `MediaSandboxService`, I want the module to have zero imports or dependencies on `AppDatabase` or Drift tables, so filesystem operations can be tested and evolved without constructing a database.
13. As a developer navigating database persistence, I want `AppDatabase` (and every split DAO module) to stay concise (< 450 LOC) with clear domain ownership—`EntriesDao`, `TemplatesDao`, `MediaOcrDao`, `AlbumsDao`, and `BackupDao`—instead of scrolling through one 1,447-line file.
14. As a developer querying templates, writing analytics, or resolving OCR queue items, I want typed DAO methods instead of writing raw `database.select(database.*)` queries in widget or background modules, so schema queries stay localized and easy to audit.
15. As a developer working in `AlbumRepository`, I want clear separation between pure SQL persistence (`AlbumsDao`) and multi-module workflows (`AlbumRepository` combining DB, media sandboxing, and layout synthesis), with zero shallow pass-through boilerplate.
16. As a developer maintaining FTS5 entry search and CJK substring fallback, I want the query normalization and SQL execution shared by a single helper inside `EntriesDao` rather than duplicated between plain search and filtered search.

## Implementation Decisions

### 1. Pure Filesystem `MediaSandboxService`

- **Drop Database Coupling**:
  - Remove the `AppDatabase` import and delete `deleteCollectionAndMedia` and `deletePhotoAndMedia` from `MediaSandboxService`.
  - Add a batch cleanup method `deleteMediaPaths(Iterable<String> relativePaths)` that validates each path with `isStrictlyRelative`, skips empty/unsafe paths, deletes existing files cleanly, and returns deleted count or paths without failing on missing files.
- **Unified Media Directory Scanner**:
  - Add `listMediaFiles({Set<String>? allowedExtensions})` (returning lightweight value records containing normalized `'media/<filename>'` relative path and `sizeBytes`) using `getBaseDirectory()` directly—eliminating the `'media/.probe'` workaround.
  - Default filter skips dotfiles (`.*`) and includes only supported sandbox media extensions: `.webp`, `.mp4`, `.png`, `.jpg`, `.jpeg` (case-insensitive).

### 2. Canonical Referenced-Media & Storage / Backup Unification

- **`MediaOcrDao.getAllReferencedMediaPaths()`**:
  - Replace the incomplete `AppDatabase.getAllMediaRelativePaths()` with `getAllReferencedMediaPaths()` returning normalized relative paths across all media-referencing tables:
    1. `mediaAttachments.relativePath` and `mediaAttachments.thumbnailPath`
    2. `albumCollections.coverImagePath`
    3. `albumPhotos.relativeImagePath` and `albumPhotos.relativeThumbnailPath`
  - Strip empty/null values and normalize directory separators (`\` → `/`) consistently.
- **`StorageOptimizerService` & `BackupRestoreService` Consolidation**:
  - Update `StorageOptimizerService.analyzeStorage` and `StorageOptimizerService.purgeOrphanMedia` to call `MediaSandboxService.listMediaFiles()` once per operation and compare against `database.mediaOcrDao.getAllReferencedMediaPaths()` (reading entry counts via `EntriesDao`). Remove the duplicated `mediaDir.listSync` and extension-checking loops and remove `'media/.probe'`.
  - Update `BackupRestoreService` backup discovery to obtain referenced paths via `database.mediaOcrDao.getAllReferencedMediaPaths()` and sandboxed media files via `mediaService.listMediaFiles()`, merging the sets before SHA-256 hashing and manifest assembly.

### 3. `AppDatabase` `@DriftAccessor` DAO Decomposition

- **Schema & Database Core (`AppDatabase`)**:
  - Retain `@DriftDatabase` table registration, `schemaVersion` (`8`), encryption factories, testing constructor, `onCreate` / `onUpgrade` migrations, and FTS5 table/trigger DDL setup in `AppDatabase`.
  - Register five `@DriftAccessor` DAOs (`EntriesDao`, `TemplatesDao`, `MediaOcrDao`, `AlbumsDao`, `BackupDao`) on `@DriftDatabase(daos: [...])` and regenerate Drift `.g.dart` bindings via `dart run build_runner build` without manually editing generated `.g.dart` files.
  - Remove legacy query and forwarding methods directly from `AppDatabase` so `AppDatabase` stays compact (< 350 LOC) and callers interact directly with the typed DAOs.
- **`EntriesDao`**:
  - Own entry CRUD, pagination (`getTimelineEntries`), metadata/template/lock updates, legacy mount-pass completion, soft-delete/restore/expired recycle-bin queries, `hardDeleteEntryRecords` (returning candidate media relative paths removed or queried inside the same transaction), `getAllActiveEntries`, weekly review queries, on-this-day / random serendipity queries (moving on-this-day month/day filtering into SQL or keeping SQL-bounded selection), and batch import.
  - Deduplicate FTS5 `entries_fts MATCH` + escaped CJK `LIKE` candidate-ID resolution into one internal helper shared by `searchEntries` and `searchEntriesWithFilters`.
- **`TemplatesDao`**:
  - Hold one canonical built-in template seed definition list (`template_minimalist_white`, `template_lined_paper`, `template_retro_kraft`, `template_weekly_review`) reused by both `AppDatabase.onCreate` (initial seeding) and `BackupDao.replaceAllFromBackup` (default preservation), plus notebook queries (`getAllNotebooks`, `createNotebook`) and template CRUD (`getAllTemplates`, `getTemplateById`, custom template create/update/delete/reassign).
- **`MediaOcrDao`**:
  - Own `attachMediaToEntry`, entry attachment reads/deletes, primary media batch map (`getPrimaryMediaForEntries`), `getAllReferencedMediaPaths()`, single-row lookup helpers (`getMediaAttachmentById`, `getAlbumPhotoById` for `OcrQueueManager`), caption/overlay/OCR updates, `searchPhotoText`, and unindexed OCR backfill queries/streams (`getUnindexedImages`, `countUnindexedImages`, `watchUnindexedImagesSince`).
- **`AlbumsDao`**:
  - Own pure SQL persistence for `albumCollections` and `albumPhotos`: collection/photo CRUD, reactive streams (`watchAllCollections`, `watchCollectionById`, `watchPhotosForCollection`, `watchPhotoCountForCollection`, `watchPhotoCounts`), ordering/reordering, cover assignment, and SQLite transactions for `deleteCollectionRecords(String collectionId)` and `deletePhotoRecords(String photoId)`.
  - Inside `deleteCollectionRecords` and `deletePhotoRecords`, collect the deleted record's candidate paths (`coverImagePath`, `relativeImagePath`, `relativeThumbnailPath`), delete the SQLite rows (and reassign `coverImagePath` to the next remaining ordered photo if needed), and check remaining references cleanly against candidate paths across `albumCollections`, `albumPhotos`, and `mediaAttachments`—returning strictly the unreferenced relative paths to clean up on disk. (Replace the existing O(N) Dart memory scan of all unrelated rows with targeted SQL `isIn` checks.)
- **`BackupDao`**:
  - Own `exportAllTablesSnapshot()` and transactional `replaceAllFromBackup(BackupDatabaseSnapshot)` (reusing `TemplatesDao`'s canonical default template list rather than duplicating companion literals).

### 4. Deep `AlbumRepository` & SQLite-First Deletion Ordering

- **`AlbumRepository` Coordination Scope**:
  - Refactor `AlbumRepository` (< 350 LOC) to delegate pure SQL reads/writes directly to `database.albumsDao` or focus strictly on multi-module operations uniting SQLite persistence with `MediaSandboxService` and layout synthesis (`createCollection` / `createPhotoFromFile` / `deleteCollection` / `deletePhoto` / `synthesizeRouteSummary` / `saveStudioDocument` / `loadOrSynthesizeStudioDocument`).
  - Migrate pure read/stream/sort callers that need no media sandbox (`watchAllCollections`, `watchPhotoCounts`, `watchPhotosForCollection`, etc.) to read from `database.albumsDao` rather than maintaining shallow pass-through wrappers on `AlbumRepository`.
  - In `AlbumRepository.deleteCollection` and `AlbumRepository.deletePhoto`, execute `database.albumsDao.deleteCollectionRecords(...)` / `deletePhotoRecords(...)` **first**, receive the unreferenced candidate paths after SQLite commit, and then call `mediaService.deleteMediaPaths(orphanPaths)`.
- **`RecycleBinService` Symmetry**:
  - Update `RecycleBinService.permanentDeleteEntry` to run `database.entriesDao.hardDeleteEntryAndCollectMediaPaths(entryId)` (inside SQLite transaction, computing any unreferenced `relativePath` / `thumbnailPath` not referenced by `albumCollections`, `albumPhotos`, or remaining `mediaAttachments`) **first**, then call `mediaService.deleteMediaPaths(...)` afterward.

### 5. Caller Migration & File-Size Compliance

- Replace all direct `database.select(database.*)` / raw table queries outside the database module with typed DAO methods across:
  - `AnalyticsService` → `database.entriesDao.getAllActiveEntries()`
  - `OcrQueueManager` → `database.mediaOcrDao.getMediaAttachmentById(...)` and `database.mediaOcrDao.getAlbumPhotoById(...)`
  - `EntryEditorScreen` → `database.templatesDao.getAllTemplates()`
  - Developer screenshot helper / fixture scripts and feature screens calling `AppDatabase` query methods → migrated to `entriesDao`, `templatesDao`, `mediaOcrDao`, `albumsDao`, `backupDao`.
- Ensure every modified and newly added Dart file stays under the project's `< 450` LOC ceiling.

## Testing Decisions

### Good Test Principles

- Test observable external behavior at the highest practical module seam using an in-memory SQLite database (`AppDatabase.memory()`) paired with an isolated temporary filesystem directory for `MediaSandboxService`—never assert private fields, SQL string formatting details, or internal mock call orderings where real in-memory SQLite + temp files can verify actual state.
- Update and retire obsolete direct `AppDatabase` test calls cleanly against the new DAO interfaces rather than keeping compatibility forwarding methods solely to preserve old test syntax.

### Seams & Modules Under Test

1. **Storage Optimization & Canonical Reference Seam (`StorageOptimizerService` + `MediaOcrDao`)**:
   - Expand `storage_optimizer_test` to seed referenced files simultaneously across `media_attachments` (image + video + poster thumbnail), `album_photos` (`relativeImagePath` + `relativeThumbnailPath`), and `album_collections` (`coverImagePath`), alongside a dotfile (e.g. `.DS_Store` or `.probe`) and a true unreferenced `.webp` orphan.
   - Verify `analyzeStorage` counts only supported media files (excluding dotfiles) and flags **only** the true orphan, and verify `purgeOrphanMedia` deletes the true orphan while keeping every diary attachment, album photo, album thumbnail, and album cover intact on disk.
2. **Media Sandbox Pure Filesystem Seam (`MediaSandboxService`)**:
   - Extend `media_sandbox_service_test` / `media_sandbox_video_test` to cover `listMediaFiles()` (extension filtering + dotfile exclusion + `'media/'` normalization + missing directory returns empty) and `deleteMediaPaths(...)` (ignores non-relative / traversal paths cleanly, deletes valid files, tolerates missing files).
3. **Album Deletion DB-First Seam (`AlbumRepository` + `AlbumsDao`)**:
   - Keep `album_repository_test` targeting `AlbumRepository.deletePhoto` and `AlbumRepository.deleteCollection`:
     - Verify single-photo delete commits SQLite removal + atomic cover reassignment before disk deletion, removes unreferenced full-res + thumb files, and preserves files shared by another collection cover or `media_attachments` row.
     - Verify failure ordering: when a database constraint/error prevents deletion (e.g. missing or failing transaction), physical files on disk remain completely untouched.
4. **Recycle Bin Permanent Delete Seam (`RecycleBinService` + `EntriesDao`)**:
   - Verify `RecycleBinService.permanentDeleteEntry` commits SQLite deletion first and removes unreferenced `media_attachments` files afterward while preserving paths still referenced elsewhere.
5. **Database DAO & Backup Restore Verification (`EntriesDao`, `TemplatesDao`, `MediaOcrDao`, `AlbumsDao`, `BackupDao`, `BackupRestoreService`)**:
   - Migrate existing database, template, FTS, analytics, OCR queue, and backup restore test suites (`app_database_test`, `custom_templates_test`, `media_attachments_video_test`, `media_fts_test`, `backup_restore_service_test`, `backup_restore_ocr_test`, `analytics_service_test`, OCR queue tests) directly onto the new DAO interfaces (`db.entriesDao`, `db.templatesDao`, `db.mediaOcrDao`, `db.albumsDao`, `db.backupDao`) without modifying schema migrations or breaking v1–v8 upgrade tests (`schema_v3`–`schema_v8_migration_test`).

## Out of Scope

- Bump or modification of `AppDatabase.schemaVersion` (`8`) or altering existing v1–v8 SQLite migration paths.
- Changing `.memodiary` backup archive encryption format, JSON manifest versioning, or `BackupCrypto` primitives.
- Modifying OCR recognition behavior (`Apple Vision` / ML Kit), OCR queue scheduling, or `media_fts` tokenization rules.
- Refactoring Candidate 4 (Editor Media Lifecycle / staging handscroll & caption parity) or Candidate 5 (Controller-free Delta partitioning & Folio/PDF decoding).
- Modifying `GLOSSARY.md` (no new user-facing domain terms are introduced).

## Further Notes

- Grounded in **ADR-0010** (*Seal the AppDatabase & Media Sandbox Seam*).
- Drift `.g.dart` part files must be regenerated exclusively via `dart run build_runner build` and never inspected or edited manually per project conventions.
- Full verification must run via `tool/test.sh` (plus static analysis) once implementation completes, ensuring zero regressions in schema v3–v8 migration tests and code-style line-length / file-size audits.
