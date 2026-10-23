# Phase 12 Walkthrough: Collection Management, Batch Ingestion & Photo Annotation Workspace

## Overview

Phase 12 builds upon the Phase 11 relational schema and media sandbox foundation to implement the complete user-facing travel memory album management flow in **MemoDiary (拾光日记)**:
- **Albums Navigation & Collections Dashboard** (`AlbumCollectionsScreen`): literati Xuan-paper feed, responsive cards, destination vermilion seal, date & photo count pills, and route trajectory summary.
- **Batch Multi-Photo Ingestion Pipeline** (`AlbumIngestionService` & `ExifDateReader`): pure-Dart EXIF date extraction, dual-resolution WebP sandboxing (1600px + 300px thumb), progress dialog, and atomic batch SQLite inserts.
- **Collection Workspace & Reordering** (`AlbumWorkspaceScreen`): adaptive 300px thumbnail grid, header route banner, batch photo addition, and accessible drag-and-drop reordering with automatic route trajectory re-synthesis.
- **Photo Annotation Workspace (写影札)** (`PhotoAnnotationSheet`): high-resolution preview with pinch-zoom, location tag input (`"西湖断桥"`), multiline story/caption field, shot date override, cover designation, and atomic photo deletion.
- **Timeline Entry Point**: `timeline_albums_button` on `TimelineScreen` AppBar.

---

## Changes Made

### 1. Services & Utilities
- **[`ExifDateReader`](file:///home/harry1029/projects/memodiary/lib/features/albums/services/exif_date_reader.dart)**:
  - Pure-Dart reader extracting `DateTimeOriginal` (`0x9003`), `DateTimeDigitized` (`0x9004`), and `DateTime` (`0x0132`) from JPEG APP1/TIFF headers within the first 64 KB using synchronous `openSync`/`readSync`.
  - Zero external dependencies ($0 FOSS), fully isolated from network, falls back to `_clock()`.
- **[`AlbumIngestionService`](file:///home/harry1029/projects/memodiary/lib/features/albums/services/album_ingestion_service.dart)**:
  - Processes up to 50 photos per batch sequentially to prevent memory spikes on mobile devices.
  - Generates full-res (1600px, 80% quality) and preview thumbnails (300px, 75% quality).
  - Emits granular `IngestionProgress(processed, total, failed, isDone)`.
  - Atomically commits all processed items via `AlbumRepository.addPhotosBatch`.
  - Supports mid-batch cancellation preserving already-sandboxed items while purging half-written files.
- **[`AlbumRepository`](file:///home/harry1029/projects/memodiary/lib/features/albums/data/album_repository.dart)**:
  - Added `watchCollectionById`, `watchPhotoCounts`, `setCollectionCover`, and `updatePhotoAnnotationAndSyncRoute`.
- **[`MediaSandboxService`](file:///home/harry1029/projects/memodiary/lib/core/services/media_sandbox_service.dart)**:
  - Injected `aspectRatioExtractor` for test predictability.
  - Made sandbox file deletion and directory checks synchronous (`existsSync`, `deleteSync`) to eliminate isolate port stalls during `fakeAsync` test execution.

### 2. UI Widgets
- **[`SandboxedAlbumImage`](file:///home/harry1029/projects/memodiary/lib/features/albums/widgets/sandboxed_album_image.dart)**:
  - Resolves strictly relative sandboxed paths (`media/{uuid}.webp` or `media/{uuid}_thumb.webp`).
  - Limits in-memory decode via `cacheWidth` (300 for grid thumbnails, 720 for cards, 1200 for preview) so grids never exhaust device heap.
- **[`AlbumCollectionCard`](file:///home/harry1029/projects/memodiary/lib/features/albums/widgets/album_collection_card.dart)**:
  - Renders title, vermilion destination seal (`CinnabarSealBadge`), 16:9 cover frame, route trajectory (`📍 杭州 → 乌镇 → 苏州`), clamped metadata pills, and contextual `PopupMenuButton` (`edit`, `setCover`, `delete`).
- **[`CreateEditCollectionSheet`](file:///home/harry1029/projects/memodiary/lib/features/albums/widgets/create_edit_collection_sheet.dart)**:
  - Bottom sheet modal validating title (1–100 chars), destination seal ($\le$ 8 chars), optional route override, description prologue, and date range picker.
- **[`IngestionProgressDialog`](file:///home/harry1029/projects/memodiary/lib/features/albums/widgets/ingestion_progress_dialog.dart)**:
  - Modal sheet with `ValueListenableBuilder<IngestionProgress>`, `LinearProgressIndicator`, item count label, and cancellation button.
- **[`PhotoAnnotationSheet`](file:///home/harry1029/projects/memodiary/lib/features/albums/widgets/photo_annotation_sheet.dart)**:
  - Draggable scrollable sheet (写影札) featuring pinch-to-zoom preview (`InteractiveViewer`), location tag field (`"西湖断桥"`), multiline story field, capture date picker, "设为封面" toggle, and permanent photo deletion.

### 3. Screens & Navigation
- **[`AlbumCollectionsScreen`](file:///home/harry1029/projects/memodiary/lib/features/albums/screens/album_collections_screen.dart)**:
  - Main album dashboard reactively watching collections and photo counts.
  - Responsive layout (1 column on mobile, 2 columns on wide screens).
  - Empty state with decorative icon, literati poem, and creation CTA button.
- **[`AlbumWorkspaceScreen`](file:///home/harry1029/projects/memodiary/lib/features/albums/screens/album_workspace_screen.dart)**:
  - Dedicated workspace screen for browsing 300px thumbnails in an adaptive grid.
  - "排序" / "完成" mode toggle switching to an accessible `ReorderableListView` using `onReorderItem` that immediately persists sequence order and updates auto-synthesized route trajectory.
- **[`TimelineScreen`](file:///home/harry1029/projects/memodiary/lib/features/timeline/screens/timeline_screen.dart)**:
  - Added `timeline_albums_button` (`Icons.photo_album_outlined`, tooltip `'旅行影集'`) navigating to `AlbumCollectionsScreen`.

---

## Verification Results

| Suite / Verification Check | Scope | Result |
| :--- | :--- | :---: |
| **`test/features/albums/`** | EXIF date reader, batch ingestion service, repository, and all album screens/sheets (20 tests) | **Passed** (0 errors, 2s) |
| **`test/features/timeline/timeline_screen_test.dart`** | Entry points, capsule privacy, albums button navigation (6 tests) | **Passed** (0 errors, 1s) |
| **`flutter analyze`** | Entire codebase static analysis | **0 issues** (clean) |
| **Full Regression Suite (`flutter test`)** | 244 unit, widget, and integration tests across the entire project | **Passed** (244 / 244) |
| **Network Quarantine Audit** | Zero Internet permission in Android/iOS manifests, $0 FOSS dependency audit | **Passed** (10 / 10) |
