# Phase 7 Task Checklist: Sandboxed Short Video Ingestion & Inline Playback

- [x] **Step 1: Dependencies & Foundation**
  - [x] Add `video_player: ^2.9.2` to `pubspec.yaml`.
  - [x] Run `flutter pub get` and verify dependency resolution.

- [x] **Step 2: Sandboxed Video Service**
  - [x] Define `VideoSandboxResult` and custom exceptions in `lib/core/services/media_sandbox_service.dart`.
  - [x] Implement duration validation (capped at 60s) with injectable `VideoDurationExtractor`.
  - [x] Implement video sandboxing to `media/{uuid}.mp4` and poster thumbnail generation to `media/{uuid}_thumb.webp` with procedural vector fallback for physical devices (Watchpoint 1).
  - [x] Write unit tests in `test/core/services/media_sandbox_video_test.dart`.

- [x] **Step 3: Database Layer Updates**
  - [x] Update `getAllMediaRelativePaths()` in `lib/core/database/app_database.dart` to return both `relativePath` and `thumbnailPath`.
  - [x] Add `getVideosForEntry(String entryId)` query helper.
  - [x] Write database tests in `test/core/database/media_attachments_video_test.dart`.

- [x] **Step 4: Quill Video Embed & Inline Player Widget**
  - [x] Implement `SandboxedVideoPlayer` with `WidgetsBindingObserver` audio pause and controller disposal on navigation/offscreen (Watchpoint 2).
  - [x] Implement `SandboxedVideoEmbedBuilder` in `lib/features/editor/widgets/sandboxed_video_embed_builder.dart`.
  - [x] Update `EditorToolbar` with video capture action.
  - [x] Update `EntryEditorScreen` with video picker workflow.
  - [x] Update `EntryDetailScreen` with video embed support.
  - [x] Update `PdfEntrySerializer` with graceful video poster placeholder.
  - [x] Write widget tests with mocked platform channels in `test/features/editor/sandboxed_video_embed_test.dart` and `test/features/import_export/pdf_video_fallback_test.dart`.

- [x] **Step 5: Storage Optimizer & Recycle Bin Integration**
  - [x] Update `StorageOptimizerService` multi-extension scanner (`.webp` and `.mp4`) and orphan purge (Watchpoint 3).
  - [x] Update `RecycleBinService` to ensure physical `.mp4` and `_thumb.webp` files are removed upon permanent delete.
  - [x] Write integration tests in `test/features/settings/video_storage_optimizer_test.dart` and `test/features/recycle_bin/video_recycle_bin_purge_test.dart`.

- [x] **Step 6: Static Analysis & Full Regression Suite**
  - [x] Run `analyze_files` across the entire project (0 errors, 0 warnings).
  - [x] Run full `flutter test` test suite (146/146 tests passed).
