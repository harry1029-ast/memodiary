# Implementation Plan — Phase 7: Sandboxed Short Video Ingestion & Inline Playback

MemoDiary is an offline-first, multimodal personal journal. Phase 7 implements **sandboxed short video ingestion (capped at 60s)**, **procedural poster thumbnailing**, **inline video playback** in the rich-text editor and timeline reader, and **storage optimizer & recycle bin lifecycle management** adhering strictly to the **$0 FOSS**, **Zero-Cloud**, and **Sandboxed Media Isolation** invariants from [GEMINI.md](file:///home/harry1029/projects/memodiary/GEMINI.md).

---

## User Review Required

> [!IMPORTANT]
> - **Dependency Selection**: We are adding `video_player: ^2.9.2` (the official Flutter first-party package under the BSD-3-Clause license, 100% free open-source, zero cloud telemetry).
> - **60-Second Video Constraint**: Videos exceeding 60 seconds will be rejected during sandboxing with `VideoDurationExceededException`, preserving user device storage and keeping diary entries focused.
> - **Static PDF Fallback**: PDF print documents cannot stream video; `PdfEntrySerializer` will render the poster frame with a play overlay badge and `Video: Local playback only` note.

---

## 3 Critical Technical Watchpoints & Safeguards

1. **Poster Frame Generation on Physical Devices**:
   - **The Risk**: Without adding a heavy native C/FFmpeg plugin, extracting a raster frame from raw video bytes on Android/iOS can be finicky.
   - **The Safeguard**: `VideoThumbnailGenerator` has a robust fallback: if on-device video frame extraction cannot decode a frame, it renders and saves a procedural vector placeholder (dark slate canvas with film reel / play icon, video badge, and duration label) using `dart:ui.PictureRecorder` -> `toImage` -> `.webp`/`.png`, so the app never crashes or blocks saving when a video frame cannot be rasterized.

2. **Audio Focus & Pause on Offscreen / Navigation**:
   - **The Risk**: If a user starts video playback inside `EntryDetailScreen` and taps "Back" or "Edit", video audio might continue playing in the background.
   - **The Safeguard**: `SandboxedVideoPlayer` implements `WidgetsBindingObserver` to pause playback on app lifecycle transitions (`AppLifecycleState.paused` / `inactive`), and ensures `controller.pause()` and `controller.dispose()` are always executed inside `dispose()`, completely cutting audio and releasing hardware decoders before navigation pop or route transition.

3. **Storage Optimizer Multi-Extension Scanning**:
   - **The Risk**: In Phase 3, `StorageOptimizerService` was initially tailored around scanning `.webp` images.
   - **The Safeguard**: The directory scanner in `StorageOptimizerService` will be explicitly updated to match both `.webp` and `.mp4` files (and any sandbox media), ensuring both video files and their companion poster thumbnails are accurately tallied in storage metrics and cleanly purged when orphaned.

---

## Proposed Changes

```
┌────────────────────────────────────────────────────────────────────────┐
│                          EntryEditorScreen                             │
│                     (Record / Pick Short Video)                        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        MediaSandboxService                             │
│  1. Check duration <= 60s (VideoDurationExceededException if > 60s)    │
│  2. Copy to sandbox: media/{uuid}.mp4                                  │
│  3. Generate poster: media/{uuid}_thumb.webp                           │
│  4. Return VideoSandboxResult(relativePath, thumbnailPath, duration)   │
└───────────────────┬────────────────────────────────┬───────────────────┘
                    │                                │
                    ▼                                ▼
┌──────────────────────────────────────┐  ┌──────────────────────────────┐
│        Drift Database (SQLite)       │  │      Quill Delta JSON        │
│  media_attachments:                  │  │  {"insert": {                │
│    media_type: 'video'               │  │    "video": "media/uuid.mp4" │
│    relative_path: 'media/uuid.mp4'   │  │  }}                          │
│    thumbnail_path: 'media/uuid_...   │  └──────────────┬───────────────┘
└───────────────────┬──────────────────┘                 │
                    │                                    │
                    ▼                                    ▼
┌──────────────────────────────────────┐  ┌──────────────────────────────┐
│ StorageOptimizer & RecycleBinService │  │  SandboxedVideoEmbedBuilder  │
│  - Storage breakdown: video bytes    │  │    & SandboxedVideoPlayer    │
│  - Purge orphan .mp4 & _thumb.webp   │  │  (Poster, scrub bar, play)   │
│  - Hard delete removes both files    │  │  (PDF: Poster + Local note)  │
└──────────────────────────────────────┘  └──────────────────────────────┘
```

---

### Component 1: Dependencies & Foundation

#### [MODIFY] [pubspec.yaml](file:///home/harry1029/projects/memodiary/pubspec.yaml)
- Add `video_player: ^2.9.2` under dependencies.
- Run `flutter pub get`.

---

### Component 2: Sandboxed Video Service

#### [MODIFY] [media_sandbox_service.dart](file:///home/harry1029/projects/memodiary/lib/core/services/media_sandbox_service.dart)
- Define `VideoSandboxResult`:
  ```dart
  class VideoSandboxResult {
    final String relativePath;
    final String thumbnailPath;
    final int durationSeconds;
    const VideoSandboxResult({
      required this.relativePath,
      required this.thumbnailPath,
      required this.durationSeconds,
    });
  }
  ```
- Define `VideoDurationExtractor` and `VideoThumbnailGenerator` typedefs for constructor injection (enabling hermetic testing).
- Implement `copyAndSandboxVideo(File sourceFile, {Duration maxDuration = const Duration(seconds: 60)})`:
  - Validates source existence.
  - Checks duration; throws `VideoDurationExceededException` if $>60\text{s}$.
  - Copies to `media/{uuid}.mp4`.
  - Generates poster frame at `media/{uuid}_thumb.webp`.
  - Returns `VideoSandboxResult`.

---

### Component 3: Database Layer Updates

#### [MODIFY] [app_database.dart](file:///home/harry1029/projects/memodiary/lib/core/database/app_database.dart)
- Update `getAllMediaRelativePaths()` to include both `relativePath` and `thumbnailPath`:
  ```dart
  final rows = await (selectOnly(mediaAttachments, distinct: true)
        ..addColumns([mediaAttachments.relativePath, mediaAttachments.thumbnailPath]))
      .get();
  ```
- Add helper method `getVideosForEntry(String entryId)` to retrieve all `mediaType == 'video'` attachments for an entry.

---

### Component 4: Quill Video Embed & Inline Player Widget

#### [NEW] [sandboxed_video_player.dart](file:///home/harry1029/projects/memodiary/lib/features/editor/widgets/sandboxed_video_player.dart)
- Stateful widget managing video playback lifecycle:
  - Initial State: Displays poster frame (`_thumb.webp`) with play button overlay and duration badge (`00:45`).
  - Loading State: Shows centered loading indicator while initializing `VideoPlayerController`.
  - Playback State:
    - Tap-to-play/pause.
    - Floating bottom bar with play/pause button, time elapsed / total (`00:15 / 00:45`), and scrubbable progress bar.
    - Gracefully pauses when off-screen or disposed.
  - Error State: Shows clear error card with retry button.

#### [NEW] [sandboxed_video_embed_builder.dart](file:///home/harry1029/projects/memodiary/lib/features/editor/widgets/sandboxed_video_embed_builder.dart)
- Custom `EmbedBuilder` for `flutter_quill` matching `BlockEmbed.videoType`:
  - Resolves sandboxed video path and companion poster thumbnail.
  - Renders `SandboxedVideoPlayer`.
  - Includes deletion badge in edit mode (`!embedContext.readOnly`).

#### [MODIFY] [editor_toolbar.dart](file:///home/harry1029/projects/memodiary/lib/features/editor/widgets/editor_toolbar.dart)
- Add optional `onPickVideo` callback and video camera button (`Icons.videocam_outlined`).

#### [MODIFY] [entry_editor_screen.dart](file:///home/harry1029/projects/memodiary/lib/features/editor/screens/entry_editor_screen.dart)
- Register `SandboxedVideoEmbedBuilder` in `embedBuilders`.
- Add `_handleVideoPick()`:
  - Bottom sheet option: "Record Video (≤60s)" and "Choose from Gallery (≤60s)".
  - Calls `MediaSandboxService.copyAndSandboxVideo()`.
  - Inserts `BlockEmbed.video(result.relativePath)`.
  - Calls `database.attachMediaToEntry(..., mediaType: 'video', thumbnailPath: result.thumbnailPath)`.

#### [MODIFY] [entry_detail_screen.dart](file:///home/harry1029/projects/memodiary/lib/features/timeline/screens/entry_detail_screen.dart)
- Register `SandboxedVideoEmbedBuilder` in read-only `embedBuilders`.

#### [MODIFY] [pdf_entry_serializer.dart](file:///home/harry1029/projects/memodiary/lib/features/import_export/services/pdf_entry_serializer.dart)
- Add handler for `insert is Map && insert.containsKey('video')`:
  - Locates `_thumb.webp` poster.
  - Renders image with `Video: Local playback only` badge and duration label.

---

### Component 5: Storage Optimizer & Recycle Bin Lifecycle

#### [MODIFY] [storage_optimizer_service.dart](file:///home/harry1029/projects/memodiary/lib/features/settings/services/storage_optimizer_service.dart)
- Add `totalVideoFiles` and `totalVideoBytes` to `StorageStats`.
- Differentiate video and image files in `mediaDir.listSync()`.
- Ensure orphan `.mp4` and `_thumb.webp` files are correctly counted and purged.

#### [MODIFY] [recycle_bin_service.dart](file:///home/harry1029/projects/memodiary/lib/core/services/recycle_bin_service.dart)
- Verify `permanentDeleteEntry()` removes both `attachment.relativePath` (`.mp4`) and `attachment.thumbnailPath` (`_thumb.webp`).

---

## Verification Plan

### Automated Tests
1. **Sandboxed Video Service Tests**:
   - `test/core/services/media_sandbox_video_test.dart`:
     - Test `copyAndSandboxVideo` creates `.mp4` and `_thumb.webp` files.
     - Test validation rejects videos $>60\text{s}$ with `VideoDurationExceededException`.
     - Test relative path normalization and strictly relative verification.
2. **Database Video Attachment Tests**:
   - `test/core/database/media_attachments_video_test.dart`:
     - Test attaching video records `mediaType = 'video'`, `relativePath`, and `thumbnailPath`.
     - Test `getAllMediaRelativePaths()` includes both video and thumbnail paths.
3. **Quill Video Embed & Player Widget Tests**:
   - `test/features/editor/sandboxed_video_embed_test.dart`:
     - Test inline video player with mocked video player platform channels.
     - Verify poster frame, play/pause toggle, duration badge, and edit mode delete action.
4. **Storage Optimizer & Recycle Bin Video Tests**:
   - `test/features/settings/video_storage_optimizer_test.dart`:
     - Test storage metrics for videos and orphan `.mp4` detection and purge.
   - `test/features/recycle_bin/video_recycle_bin_purge_test.dart`:
     - Test permanent deletion and 30-day auto-purge removes physical `.mp4` and `_thumb.webp` files.
5. **PDF Video Fallback Tests**:
   - `test/features/import_export/pdf_video_fallback_test.dart`:
     - Verify Delta containing video renders graceful PDF poster card with "Local playback only".
6. **Full Regression Suite**:
   - `flutter analyze` (0 errors/warnings).
   - `flutter test` (all tests passing).
