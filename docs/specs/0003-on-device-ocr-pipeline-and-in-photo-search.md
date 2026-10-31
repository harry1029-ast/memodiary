---
id: SPEC-003
title: On-Device OCR Pipeline, Media FTS5 Indexing & In-Photo Search
status: ready-for-agent
created_at: 2026-10-31T16:55:00+08:00
---

# Specification: On-Device OCR Pipeline, Media FTS5 Indexing & In-Photo Search

## Problem Statement

Diarists capture and import rich visual memories—transit tickets, museum plaques, café menus, handwritten postcards, street markers, and book excerpts—into their diary entries and travel photobook collections. However, once stored inside MemoDiary, these images become silent visual black boxes:

1. **Unsearchable Visual Content**: The existing full-text search engine (`entries_fts`) indexes only manually typed titles and Quill Delta plain text. A diarist searching for "西湖十景", "特快列车", or a coffee shop name cannot locate the entry or photo containing those words unless they manually transcribed the text by hand.
2. **Disconnected Photo Archives**: Photos in `MediaAttachments` and `AlbumPhotos` possess no spatial text index. Tapping into an image collection requires manual visual scanning across dozens of photos to locate a specific receipt, quotation, or train ticket.
3. **Absence of Visual Highlighting**: When reviewing past photos, diarists have no way to quickly identify where a searched keyword appears within the photograph, causing cognitive fatigue on text-dense documents and tickets.
4. **Cloud Privacy Violation**: Commercial diary applications offload image OCR to cloud endpoints, violating MemoDiary's non-negotiable architectural invariants: **100% Local-First**, **Zero Backend**, and **$0 Runtime Cost**.

## Solution

An entirely local, on-device vision extraction, SQLite FTS5 reverse-indexing, and interactive visual search pipeline (**Phase 17**):

1. **100% Offline Vision Engine (`OcrService`)**:
   - Encapsulates text recognition behind an abstract `OcrService` interface (`PlatformOcrService` over `memodiary/ocr` channel) with zero runtime cloud requests.
   - Uses built-in Apple Vision (`VNRecognizeTextRequest` targeting iOS 15.0+) on iOS, and bundled `com.google.mlkit:text-recognition-chinese:16.0.1` on Android with `android.permission.INTERNET` stripped via `tools:node="remove"` (recorded in ADR 0004).
   - Provides a deterministic `StubOcrService` / `FakeOcrService` for headless desktop environments and CI unit test harnesses.
2. **Drift Schema v5 & Dedicated `media_fts` Virtual Table**:
   - Upgrades `AppDatabase` to `schemaVersion => 5`.
   - Adds `ocr_blocks_json` (compact JSON string of normalized 0.0–1.0 line bounding boxes) to `MediaAttachments`.
   - Adds `ocr_text` (plain text) and `ocr_blocks_json` to `AlbumPhotos`.
   - Introduces a dedicated SQLite FTS5 table `media_fts` (`id UNINDEXED, source_type UNINDEXED, parent_id UNINDEXED, relative_path UNINDEXED, ocr_text, tokenize='unicode61'`).
   - Automatically maintains `media_fts` via SQLite triggers (`AFTER INSERT`, `AFTER UPDATE`, `AFTER DELETE`) on `media_attachments` and `album_photos`.
   - Implements MemoDiary's dual-path search strategy: FTS5 `MATCH` combined with parameterized SQL `LIKE %term%` fallback for CJK ideographs, strictly filtering out soft-deleted entries (`entries.is_deleted = 0`), locked entries (`entries.is_locked = 0`), sealed Time Capsules (`unlock_at IS NULL OR unlock_at <= now`), and deleted album collections.
3. **Asynchronous Rate-Limited Ingestion Queue (`OcrQueueManager`)**:
   - Decouples media attachment from OCR extraction. Images are immediately compressed and saved to SQLite/sandbox so the diarist experiences zero UI latency; `OcrQueueManager.start()` reactively watches unindexed images created since launch (`watchUnindexedImagesSince`).
   - An asynchronous background FIFO queue extracts text one image at a time, releasing native memory buffers between frames to maintain 60 FPS and prevent thermal throttling.
   - Employs an explicit sentinel value (`ocr_text = ''` and `ocr_blocks_json = '[]'`) for images containing zero recognizable text or unreadable files, preventing infinite re-indexing loops on subsequent launches.
4. **Segmented Visual Search UI & Animated Bounding Box Overlays**:
   - Extends `SearchScreen` to present segmented search results: "全部" (All), "日记" (Diary Entries), and "图中文字" (Photo Text Matches).
   - Photo result cards display image thumbnails, matching OCR text snippets with search terms highlighted, and an "图中文字匹配" cinnabar badge.
   - Tapping any photo match opens `OcrPhotoViewerScreen` showing the image with highlighted lines inside `InteractiveViewer`, plus a secondary action to open the parent diary entry (`EntryDetailScreen`) or album (`AlbumWorkspaceScreen`).
   - `OcrHighlightOverlay`: Renders a pulsing cinnabar accent frame (`tokens.cinnabar`) around matched text lines, accompanied by an accessible floating "隐藏高亮 / 显示高亮" toggle pill.
5. **Non-Blocking Backfill Indexer & Backup Preservation**:
   - Provides an on-demand "Index Existing Photos" (重建离线识图索引) action in Settings and a non-intrusive prompt in the Search screen for existing historical photos.
   - Extends `BackupDatabaseSnapshot` and `BackupManifest` to serialize cached OCR text and normalized boxes, allowing instant restoration of photo searchability across devices without re-running OCR.

## User Stories

1. As a diarist, I want words on photographed tickets, menus, and street signs to be automatically recognized in the background, so that my photos become searchable without manual typing.
2. As a diarist, I want text recognition to execute 100% on-device with zero network connectivity, so that my personal photos and private documents are never uploaded to any remote server.
3. As a diarist, I want the app to support both Chinese (Simplified and Traditional) and Latin characters, so that bilingual receipts, travel signs, and book quotes are recognized accurately.
4. As a diarist attaching photos to a diary entry, I want the photo to be added immediately without a loading spinner, so that my writing flow is not interrupted by OCR processing.
5. As a diarist importing a batch of travel photos into an album collection, I want the photos to save instantly while OCR runs quietly in the background, so that the album workspace remains smooth and responsive.
6. As a searcher, I want to type keywords into the existing search bar and see matching photos in a dedicated "图中文字" (Photo Text Matches) tab or section, so that I can easily distinguish diary text from photo text.
7. As a searcher, I want search result cards for photos to display a clear thumbnail and a highlighted snippet of the recognized text, so that I understand why the image matched my query.
8. As a searcher tapping an entry photo match, I want the app to open the photo in full-screen view with matched lines highlighted and an action to open the parent diary entry, so that I can inspect the image and jump to the entry context.
9. As a searcher tapping an album photo match, I want the app to open the photo in full-screen view with the matched text highlighted, so that I can immediately spot the relevant words.
10. As a reader viewing a matched photo, I want the recognized text line to be outlined in a glowing cinnabar accent box, so that my eye is drawn directly to the text without obscuring the photograph.
11. As a reader viewing a highlighted photo, I want an unobtrusive "Hide Highlights" pill, so that I can dismiss the bounding box and admire the original image unobstructed.
12. As a diarist who soft-deleted an entry into the 30-day Recycle Bin, I want photos belonging to that trashed entry to be excluded from search results, so that private deleted memories remain hidden.
13. As a diarist who restored an entry from the Recycle Bin, I want its photos to immediately reappear in search results, so that my search index stays consistent with my library.
14. As a diarist deleting an album collection, I want all associated photo OCR search records to be automatically purged from the search index via database cascade triggers, so that phantom search results never linger.
15. As an existing user updating to v1.3.0, I want to see an unobtrusive prompt in the Search screen informing me of unindexed historical photos, so that I can choose when to run an index backfill.
16. As a user initiating historical photo indexing from Settings, I want a clear progress bar with item counts (e.g., "正在索引: 14/85 张照片") and a cancel button, so that I remain in full control of device battery and CPU usage.
17. As a user whose phone is low on battery, I want the backfill indexing process to be pauseable and resumable, so that I do not exhaust my battery during urgent travel.
18. As a diarist taking photos of landscape scenery or abstract art containing zero words, I want the system to mark the photo as scanned with an empty sentinel, so that the queue does not waste CPU repeatedly re-scanning textless photos on every launch.
19. As a diarist importing an image with corrupted headers, I want the OCR worker to log the failure gracefully and mark it with a sentinel value, so that an invalid file never crashes the app or halts the queue.
20. As a user creating an encrypted `.memo` backup archive, I want the backup file to preserve all extracted OCR text and normalized bounding boxes, so that restoring my diary on a new phone avoids hours of redundant OCR re-computation.
21. As a user restoring an older backup archive created before v1.3.0, I want the restoration to succeed smoothly with backward-compatible defaults, so that my historical data is never rejected.
22. As a diarist searching with Chinese ideographs (e.g., "咖啡"), I want instant search results regardless of Chinese word segmentation boundaries, so that compound terms are always recalled accurately.
23. As a developer running unit and integration tests on Linux workstations and CI, I want the OCR pipeline to use an injectable mock service, so that tests run deterministically without native mobile platform channel crashes.
24. As a diarist using Dark Mode, I want the bounding box overlays and search badges to adopt warm amber/cinnabar tones harmonious with the classical scholar aesthetic, so that the visual experience feels natural and elegant.
25. As a diarist using Airplane Mode, I want full search and OCR capabilities to operate identically to online mode, so that travel journaling without cellular service is completely supported.

## Implementation Decisions

### 1. Architectural Seams & Abstraction Boundaries
- **`OcrService` (Primary Vision Seam)**:
  - Abstract interface defining:
    - `Future<OcrResult> recognizeText(String absoluteFilePath)`
    - `Future<void> dispose()`
  - Implementations:
    - `PlatformOcrService`: Invokes native `memodiary/ocr` method channel (Android Kotlin bundled `com.google.mlkit:text-recognition-chinese:16.0.1` with `INTERNET` stripped via `tools:node="remove"`; iOS Swift Apple Vision `VNRecognizeTextRequest` targeting iOS 15.0+), normalizing pixel coordinates in pure Dart via `OcrResultNormalizer` and falling back to `StubOcrService` on `MissingPluginException` or desktop platforms (ADR 0004).
    - `StubOcrService`: Pure Dart fallback for Linux/macOS/Windows desktop and automated test runners.
  - Injected via service locator / constructor into `OcrQueueManager`.
- **`AppDatabase` (Persistence & FTS Seam)**:
  - Existing database boundary handling schema evolution, SQLite FTS5 table lifecycle, triggers, and query methods.

### 2. Data Contract & Coordinate Normalization
- **`OcrResult` Model**:
  - `plainText`: Concatenated raw plain text with line breaks, sanitized of control characters.
  - `lines`: List of `OcrLineBlock` objects, each containing:
    - `text`: Line text string.
    - `box`: Bounding box `[left, top, width, height]` scaled to `0.0 .. 1.0` relative to image dimensions, rounded to 4 decimal places.
- **SQLite Columns (Drift Schema v5)**:
  - `MediaAttachments.ocrBlocksJson`: Nullable `TEXT`.
  - `AlbumPhotos.ocrText`: Nullable `TEXT`.
  - `AlbumPhotos.ocrBlocksJson`: Nullable `TEXT`.
  - Sentinel representation: `ocr_text = ''` and `ocr_blocks_json = '[]'` for processed images with zero text or unreadable formats.

### 3. Dedicated `media_fts` Virtual Table & Triggers
- **Virtual Table Schema**:
  ```sql
  CREATE VIRTUAL TABLE IF NOT EXISTS media_fts USING fts5(
    id UNINDEXED,              -- media_attachment.id OR album_photo.id
    source_type UNINDEXED,     -- 'entry_media' | 'album_photo'
    parent_id UNINDEXED,       -- entry_id OR collection_id
    relative_path UNINDEXED,   -- sandboxed relative WebP path
    ocr_text,                  -- pure plain text for tokenization
    tokenize='unicode61'
  );
  ```
- **Automated Triggers**:
  - `media_attachments_ai`: After insert on `media_attachments`, inserts into `media_fts` when `ocr_text` is non-empty.
  - `media_attachments_au`: After update on `media_attachments`, deletes old row and reinserts into `media_fts` when `ocr_text` is non-empty.
  - `media_attachments_ad`: After delete on `media_attachments`, deletes matching row from `media_fts`.
  - `album_photos_ai`: After insert on `album_photos`, inserts into `media_fts` when `ocr_text` is non-empty.
  - `album_photos_au`: After update on `album_photos`, deletes old row and reinserts into `media_fts` when `ocr_text` is non-empty.
  - `album_photos_ad`: After delete on `album_photos`, deletes matching row from `media_fts`.

### 4. Search Query Mechanics & Privacy Enforcement
- **Dual-Path CJK Strategy**:
  - Replicates `app_database.searchEntries(...)`: Queries `media_fts` using `MATCH '"$escaped"*'`.
  - If query string matches `[\u4e00-\u9fff]`, executes parameterized SQL `LIKE '%$escapedLike%'` on `media_attachments` and `album_photos` to ensure Chinese compound words match reliably without relying on whitespace tokenization.
- **Privacy & Soft-Delete Filtering**:
  - For `source_type = 'entry_media'`, joins `entries` on `media_attachments.entry_id` and filters `entries.is_deleted = 0 AND entries.is_locked = 0 AND (entries.unlock_at IS NULL OR entries.unlock_at <= now)`.
  - For `source_type = 'album_photo'`, joins `album_collections` on `album_photos.collection_id`. Trashed or deleted records are strictly excluded from search results.

### 5. Asynchronous Worker Queue (`OcrQueueManager`)
- **Queue Lifecycle**:
  - Exposes `enqueueMediaAttachment(String attachmentId)`, `enqueueAlbumPhoto(String photoId)`, `start()` (subscribing to `watchUnindexedImagesSince` for session-bound reactive indexing), `runBackfill({onProgress, isCancelled})`, and `pendingBackfillCount()`.
  - Processes items sequentially via an internal FIFO queue with deduplication by ID.
  - Resolves sandboxed absolute file path via `MediaSandboxService`.
  - Updates SQLite row atomically upon completion with `ocr_text` and `ocr_blocks_json` (or sentinel `''` / `'[]'`).
  - Triggers SQLite trigger to update `media_fts`.

### 6. Interactive Visual Highlighting & UI
- **`SearchScreen` Presentation**:
  - Adds a segmented filter bar: "全部" (All), "日记" (Entries), "图中文字" (Photos), plus an unobtrusive backfill prompt banner when `pendingBackfillCount() > 0`.
  - Photo search tiles (`PhotoTextMatchCard`) display an image preview, parent title/date, an inline text snippet highlighting matched terms in bold `tokens.cinnabar` ink, and an "图中文字匹配" badge.
- **`OcrPhotoViewerScreen` & `OcrHighlightOverlay`**:
  - Tapping a photo match opens `OcrPhotoViewerScreen`, wrapping the photo and `OcrHighlightOverlay` inside `InteractiveViewer` with a secondary action to open the parent entry (`EntryDetailScreen`) or album (`AlbumWorkspaceScreen`).
  - `OcrHighlightOverlay` parses `ocr_blocks_json` and scales normalized coordinates `[l, t, w, h]` to the letterboxed `BoxFit.contain` rendered image dimensions.
  - Filters lines matching the search term (or whitespace tokens) and paints an animated pulsing cinnabar rectangle (`tokens.cinnabar.withValues(alpha: 0.18)` fill, 2px solid border, guarded by `enableAnimation`).
  - Accessible floating pill button (`Key('ocr_highlight_toggle')`) allows toggling overlay visibility.

### 7. Backup & Restore Preservation
- `BackupManifest` and `BackupDatabaseSnapshot` models updated to include `ocr_blocks_json` on media attachments, and both `ocr_text` and `ocr_blocks_json` on album photos.
- Deserialization handles missing fields gracefully, defaulting to `null` to ensure older `.memo` backup archives restore flawlessly.

## Testing Decisions

### What Makes a Good Test
- Tests must assert external observable behavior at defined architectural seams rather than inspecting private internal loop state.
- Database tests must assert that `media_fts` reflects additions, edits, and deletions via triggers, and that soft-deleted entries never leak into search results.
- Queue tests must assert that enqueuing IDs updates database records with expected plain text and normalized coordinate JSON, and that invalid files set the sentinel value without crashing.
- UI tests must verify that `SearchScreen` renders the "图中文字" section and navigating to a result displays the target media with highlight overlay.
- All tests must run cleanly on Linux workstations and CI via `StubOcrService` / `FakeOcrService` with zero native plugin dependencies.

### Modules Tested
1. **`AppDatabase` (Migration & Search Unit Tests)**:
   - Migration from schema v4 to schema v5.
   - Trigger synchronization on `media_attachments` and `album_photos`.
   - Dual-path search query execution (FTS5 + CJK `LIKE`).
   - Soft-delete filtering for trashed entries.
2. **`OcrQueueManager` (Service Unit Tests)**:
   - FIFO sequential processing.
   - Sentinel assignment for textless and corrupt files.
   - Backfill scanning and cancellation.
3. **`SearchScreen` (Widget Tests)**:
   - Rendering "图中文字" search results.
   - Deep-linking to entry/album photo views.
4. **`OcrHighlightOverlay` (Widget Tests)**:
   - Canvas bounding box projection and painting.
   - Toggle visibility button interaction.
5. **`BackupRestoreService` (Integration Tests)**:
   - Round-trip backup export and import preserving OCR columns.
   - Backward compatibility with v1–v4 backup archives.

### Prior Art
- `test/core/database/app_database_test.dart`
- `test/features/search/search_screen_test.dart`
- `test/features/import_export/backup_restore_service_test.dart`

## Out of Scope
- Cloud-based OCR services or remote API fallbacks (strictly prohibited by zero-backend invariant).
- Image-to-image feature embeddings and vector similarity search (deferred to future milestones).
- Automatic document-to-entry drafting and heuristic smart topic classification (scheduled for Phase 18).
- Freehand handwriting drawing engine (strictly prohibited; native OS handwriting input is reused).

## Further Notes
- Adheres 100% to MemoDiary's $0 FOSS and sandboxed media isolation standards: all processed images reside in the app's sandboxed private directory as compressed WebPs (≤1600px).
- Memory safety: Bitmaps and native recognition instances are disposed immediately after each frame is recognized to avoid OOM crashes on low-end devices.

