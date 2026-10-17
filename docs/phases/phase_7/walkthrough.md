# Phase 7 Walkthrough: Sandboxed Short Video Ingestion & Inline Playback

Milestone 2 (Beta) Phase 7 has been successfully implemented and verified across all layers, adhering strictly to the **$0 FOSS**, **Zero-Cloud / Offline-First**, and **Sandboxed Media Isolation** invariants defined in [GEMINI.md](file:///home/harry1029/projects/memodiary/GEMINI.md).

---

## 1. Architecture & Component Summary

### A. Dependencies & Video Sandbox Foundation
- **Dependency**: Added [`video_player: ^2.9.2`](file:///home/harry1029/projects/memodiary/pubspec.yaml) (100% free open-source MIT/BSD-3-Clause, local-first hardware-accelerated playback with zero third-party telemetry).
- [`MediaSandboxService`](file:///home/harry1029/projects/memodiary/lib/core/services/media_sandbox_service.dart):
  - **Watchpoint 1 (Poster Frame Generation & Fallback)**:
    - Added `copyAndSandboxVideo` enforcing a **60-second duration cap** via `VideoDurationExceededException`.
    - Generates companion first-frame poster thumbnails at `media/{uuid}_thumb.webp`.
    - Implemented `generateProceduralVideoPoster` using `dart:ui.PictureRecorder` and vector canvas primitives (640×360 cinematic dark slate frame with play triangle and film reel border guides). If native on-device video frame decoding fails or is unavailable, this guaranteed fallback ensures the app never crashes or blocks saving.
    - Resolves and saves strictly relative sandbox paths (`media/{uuid}.mp4`, `media/{uuid}_thumb.webp`).

### B. Database Layer Updates
- [`AppDatabase`](file:///home/harry1029/projects/memodiary/lib/core/database/app_database.dart):
  - Updated `getAllMediaRelativePaths()` to index **both** `relativePath` and `thumbnailPath` for all attachments. This guarantees companion thumbnails are recognized as active references by storage optimizers.
  - Added query helper `getVideosForEntry(String entryId)` filtering `media_type = 'video'`.

### C. Quill Video Embed & Inline Player Widget
- [`SandboxedVideoPlayer`](file:///home/harry1029/projects/memodiary/lib/features/editor/widgets/sandboxed_video_player.dart):
  - **Watchpoint 2 (Audio Focus & Navigation Lifecycle Disposal)**:
    - Implements `WidgetsBindingObserver` to pause audio and video when app transitions to `paused` or `inactive`.
    - In `dispose()`, first removes controller update listeners to prevent unmounted `setState` exceptions, immediately calls `_controller.pause()`, and releases native hardware decoders via `_controller.dispose()`.
    - Implements lazy play-tap initialization: initially displays the static poster thumbnail with duration badge and centered play icon; initializes `VideoPlayerController` only when tapped.
    - Features duration formatting, interactive progress bar scrubbing, and fullscreen/aspect ratio preservation.
- [`SandboxedVideoEmbedBuilder`](file:///home/harry1029/projects/memodiary/lib/features/editor/widgets/sandboxed_video_embed_builder.dart):
  - Registered for `BlockEmbed.videoType` in Flutter Quill.
  - Resolves sandboxed relative video and companion thumbnail files asynchronously.
  - Displays top-right delete button in edit mode with `onVideoRemoved` auto-save callback.
- [`EntryEditorScreen`](file:///home/harry1029/projects/memodiary/lib/features/editor/screens/entry_editor_screen.dart):
  - Registered `SandboxedVideoEmbedBuilder` in editor `embedBuilders`.
  - Added video capture/gallery picking action in `EditorToolbar` with 60s duration capping, sandbox copying, and Quill delta insertion.
- [`EntryDetailScreen`](file:///home/harry1029/projects/memodiary/lib/features/timeline/screens/entry_detail_screen.dart):
  - Registered `SandboxedVideoEmbedBuilder` in read-only `embedBuilders`.
- [`PdfEntrySerializer`](file:///home/harry1029/projects/memodiary/lib/features/import_export/services/pdf_entry_serializer.dart):
  - Handled `insert['video']`: renders static poster frame with `[Video: Local playback only]` banner in generated PDF documents.

### D. Storage Optimizer & Recycle Bin Multi-Extension Purge
- [`StorageOptimizerService`](file:///home/harry1029/projects/memodiary/lib/features/settings/services/storage_optimizer_service.dart):
  - **Watchpoint 3 (Multi-Extension Scanning)**:
    - Updated directory scanner to detect both `.webp` and `.mp4` files while ignoring hidden/probe files.
    - `purgeOrphanMedia` safely reclaims unreferenced `.mp4` and unreferenced `_thumb.webp` files while preserving active referenced media.
- [`RecycleBinService`](file:///home/harry1029/projects/memodiary/lib/core/services/recycle_bin_service.dart):
  - `permanentDeleteEntry` physically deletes both `attachment.relativePath` (`.mp4`) and `attachment.thumbnailPath` (`_thumb.webp`) before purging SQLite rows.

---

## 2. Automated Verification Results

### Test Execution Matrix
| Test Suite | Purpose | Tests | Status |
| :--- | :--- | :---: | :---: |
| [`media_sandbox_video_test.dart`](file:///home/harry1029/projects/memodiary/test/core/services/media_sandbox_video_test.dart) | Sandboxing, 60s duration capping, procedural poster generation | 3 | ✅ Passed |
| [`media_attachments_video_test.dart`](file:///home/harry1029/projects/memodiary/test/core/database/media_attachments_video_test.dart) | Database recording, thumbnail indexing, `getVideosForEntry` | 1 | ✅ Passed |
| [`sandboxed_video_embed_test.dart`](file:///home/harry1029/projects/memodiary/test/features/editor/sandboxed_video_embed_test.dart) | Quill embed, poster display, tap play, lifecycle pause & disposal | 3 | ✅ Passed |
| [`pdf_video_fallback_test.dart`](file:///home/harry1029/projects/memodiary/test/features/import_export/pdf_video_fallback_test.dart) | PDF generation with video poster and fallback container | 2 | ✅ Passed |
| [`video_storage_optimizer_test.dart`](file:///home/harry1029/projects/memodiary/test/features/settings/video_storage_optimizer_test.dart) | Multi-extension tallying (.webp, .mp4) & orphan video purge | 1 | ✅ Passed |
| [`video_recycle_bin_purge_test.dart`](file:///home/harry1029/projects/memodiary/test/features/recycle_bin/video_recycle_bin_purge_test.dart) | Physical .mp4 and _thumb.webp disk removal on permanent delete | 2 | ✅ Passed |
| **Complete Regression Suite** | Full project regression (`flutter test`) | **146** | **✅ 146/146 Passed** |
| **Static Analysis** | `analyze_files` across all project files | - | **✅ 0 Errors / 0 Warnings** |

---

## 3. Technical Watchpoints Addressed

1. **Poster Frame Generation on Physical Devices**: Implemented `generateProceduralVideoPoster` using `dart:ui.PictureRecorder` as a fallback, ensuring reliable poster creation without requiring native FFmpeg binaries.
2. **Audio Focus & Navigation Disposal**: `SandboxedVideoPlayer` detaches controller listeners and invokes `pause()` and `dispose()` within `dispose()`, as well as monitoring `AppLifecycleState.paused`/`inactive` via `WidgetsBindingObserver`.
3. **Storage Optimizer Multi-Extension Scanning**: `StorageOptimizerService` filters `.webp` and `.mp4` media files explicitly, and `AppDatabase.getAllMediaRelativePaths()` tracks both `relativePath` and `thumbnailPath`, preventing active thumbnails from being flagged as orphans.
