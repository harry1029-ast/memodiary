# Milestone 4 — Task Checklist

## Phase 17: On-Device OCR Pipeline, Media FTS5 Indexing & In-Photo Search (Completed)

- [x] **Task 17.1: Native OCR Channel & Dart Vision Seam (`memodiary/ocr`)**
  - [x] Abstract `OcrService` interface in `lib/core/services/ocr/ocr_service.dart` with `recognizeText(String absolutePath)` and `dispose()`.
  - [x] `OcrResult` and `OcrLineBlock` value objects with `toBlocksJson()` and `parseBlocksJson(...)` in `lib/core/services/ocr/ocr_models.dart`.
  - [x] Pure Dart `OcrResultNormalizer` in `lib/core/services/ocr/ocr_result_normalizer.dart` clamping pixel boxes to 4 decimal places (`0.0..1.0`), stripping control characters, and discarding zero-area boxes.
  - [x] `PlatformOcrService` over `MethodChannel('memodiary/ocr')` with fallback to `StubOcrService` on desktop/Linux and test environments.
  - [x] Android native handler (`OcrChannelHandler.kt`) integrating bundled `com.google.mlkit:text-recognition-chinese:16.0.1` stripped of `INTERNET` and `ACCESS_NETWORK_STATE` permissions via `tools:node="remove"`.
  - [x] iOS native handler (`OcrChannelHandler.swift`) implementing `VNRecognizeTextRequest` (iOS 15.0+) with bottom-left to top-left coordinate conversion.
  - [x] Architectural Decision Record [ADR 0004](file:///home/harry1029/projects/memodiary/docs/adr/0004-on-device-ocr-engine.md) documenting native engine choice, license exception, and manifest quarantine defense.
  - [x] Shared test double `FakeOcrService` in `test/helpers/fake_ocr_service.dart` and unit tests in `test/core/services/ocr/ocr_result_normalizer_test.dart`.

---

- [x] **Task 17.2: Drift Schema v5, `media_fts` Virtual Table & Privacy Search**
  - [x] Upgraded `AppDatabase.schemaVersion` to `5`, adding nullable `ocrBlocksJson` to `MediaAttachments` and `ocrText` + `ocrBlocksJson` to `AlbumPhotos`.
  - [x] SQLite virtual table `media_fts` (`id UNINDEXED, source_type UNINDEXED, parent_id UNINDEXED, relative_path UNINDEXED, ocr_text, tokenize='unicode61'`).
  - [x] 6 automated SQLite triggers (`media_attachments_ai/au/ad` and `album_photos_ai/au/ad`) maintaining `media_fts` with delete-then-reinsert mechanics, ignoring empty sentinels.
  - [x] `AppDatabase.searchPhotoText` executing dual-path FTS5 `MATCH` + parameterized CJK SQL `LIKE %query%` fallback, deduplicating by ID.
  - [x] Strict privacy filtering: masks soft-deleted entries (`is_deleted = 1`), locked entries (`is_locked = 1`), and sealed Time Capsules (`unlock_at > now`).
  - [x] Helper queries: `updateMediaOcr`, `updateAlbumPhotoOcr`, `getUnindexedImages`, `countUnindexedImages`, and reactive `watchUnindexedImagesSince`.
  - [x] Backward-compatible backup serialization/deserialization with `BackupManifest.maxSupportedSchemaVersion = 5` in `lib/features/import_export/models/backup_manifest.dart`.
  - [x] Migration and search unit tests in `test/core/database/schema_v5_migration_test.dart`, `media_fts_test.dart`, and `backup_restore_ocr_test.dart`.

---

- [x] **Task 17.3: Asynchronous Rate-Limited Queue (`OcrQueueManager`)**
  - [x] FIFO sequential background processing in `lib/core/services/ocr/ocr_queue_manager.dart` with inter-job yielding to maintain 60 FPS.
  - [x] Persistent sentinel values (`ocr_text = ''`, `ocr_blocks_json = '[]'`) for textless, missing, or corrupt image files to eliminate re-scan loops.
  - [x] Reactive session monitoring: `start()` subscribes to `watchUnindexedImagesSince(launchTime)` to automatically index newly captured photos without touching editor call sites.
  - [x] Cancelable & pauseable historical backfill: `runBackfill({onProgress, isPaused, isCancelled})` and `pendingBackfillCount()`.
  - [x] Unit tests in `test/core/services/ocr/ocr_queue_manager_test.dart` verifying FIFO ordering, deduplication, sentinel assignment, and cancel/pause/resume.

---

- [x] **Task 17.4: Visual Search Results & Segmented Search UI**
  - [x] `SearchScreen` segmented filter bar (**全部 / 日记 / 图中文字**) with `Key('search_segment_<kind>')` and text-scale clamping $\le 1.3$.
  - [x] Concurrent query execution running `searchEntriesWithFilters` and `searchPhotoText` in parallel.
  - [x] `PhotoTextMatchCard` (`Key('search_photo_match_card_<id>')`) with sandboxed thumbnail preview, parent date/title, matched snippet with keywords bolded in `tokens.cinnabar`, and "图中文字匹配" badge.
  - [x] Poetic empty search state under "图中文字".
  - [x] Unobtrusive backfill prompt banner (`Key('search_ocr_backfill_banner')`) displayed when `pendingBackfillCount > 0`.
  - [x] Widget tests in `test/features/search/search_screen_ocr_test.dart`.

---

- [x] **Task 17.5: Interactive Photo Viewer & Bounding Box Highlighting**
  - [x] `OcrHighlightOverlay` in `lib/features/search/widgets/ocr_highlight_overlay.dart` using `CustomPainter` to project normalized `[l, t, w, h]` boxes onto letterboxed `BoxFit.contain` image bounds.
  - [x] Case-insensitive query matching with whitespace fallback; pulsing cinnabar accent box (`tokens.cinnabar.withValues(alpha: 0.18)` fill, 2px border) enabled by default in production.
  - [x] `OcrPhotoViewerScreen` in `lib/features/search/screens/ocr_photo_viewer_screen.dart` wrapping image and overlay in `InteractiveViewer` for unified pan/zoom.
  - [x] Accessible floating "隐藏高亮 / 显示高亮" toggle pill (`Key('search_ocr_highlight_toggle')`) with screen reader semantics.
  - [x] Secondary navigation action (`Key('search_ocr_viewer_view_parent_button')`) opening parent diary entry in `EntryDetailScreen` or album in `AlbumWorkspaceScreen`.
  - [x] Widget tests in `test/features/search/ocr_highlight_overlay_test.dart` and `ocr_photo_viewer_screen_test.dart`.

---

- [x] **Task 17.6: Historical Backfill Maintenance & Main Wiring**
  - [x] `OcrBackfillDialog` in `lib/features/settings/widgets/ocr_backfill_dialog.dart` showing live progress ("正在索引: $current/$total 张照片"), linear progress indicator, pause/resume toggle (`Key('settings_ocr_backfill_pause_button')`), and non-destructive cancellation ("取消").
  - [x] Settings maintenance tile (`Key('settings_ocr_backfill_tile')`) showing indexed status and opening `OcrBackfillDialog`.
  - [x] Search backfill banner (`Key('search_ocr_backfill_banner')`) directly launching the backfill dialog.
  - [x] Application lifecycle wiring in `lib/main.dart`: instantiates `PlatformOcrService`, starts `OcrQueueManager`, and passes dependencies across screens.
  - [x] Widget tests in `test/features/settings/ocr_backfill_dialog_test.dart`.

---

- [x] **Task 17.7: Two-Axis Code Review Refinements & Hardening**
  - [x] Standards Review: Standardized all search keys (`search_ocr_highlight_toggle`, `search_ocr_viewer_view_parent_button`, `search_photo_match_card_*`) per `CODING_STANDARDS.md` §1; eliminated silent in-memory fallback databases in production screens; loaded `EntryDetailScreen` asynchronously by ID with loading spinner.
  - [x] Spec Review: Activated pulsing highlight animation by default in production; forwarded segmented keywords (`parsed.keywords`) for natural language query matching; added pause/resume control to backfill dialog.
  - [x] Full automated verification: 140/140 tests passing across all test suites, zero issues in `flutter analyze`, and clean merged manifest quarantine audit.
