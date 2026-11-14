---
id: SPEC-016
title: Deepen the Staging Handscroll & Tucked Prints Media Lifecycle Seam
status: completed
created_at: 2026-11-14T18:46:00+08:00
adr: ADR-0009, ADR-0010
---

# Specification: Deepen the Staging Handscroll & Tucked Prints Media Lifecycle Seam

## Problem Statement

While collecting, mounting, captioning, and erasing media inside the diary editor, media lifecycle state and cleanup invariants leak across shallow UI and pagination modules, causing orphaned files, brittle timer lifetimes, and duplicated state synchronization:

- **Pass-Through Media Collection Coupled to UI**: `EditorMediaBinding.pickMedia` currently accepts a `BuildContext` and `ImagePicker` and forwards nine dependencies into static `EditorMediaActions` helpers that mix modal source bottom sheets, OS picking, sandbox compression, SQLite transaction writes, **Staging Handscroll** staging, **Brush Reveal** queuing, and draft autosave—preventing headless verification of the **Collect** pipeline and leaving compressed sandbox files stranded on disk if SQLite persistence throws.
- **Erase-Undo Purge Coupled to SnackBar Dismissal & Orphaned Video Thumbnails**: `EditorMediaBinding` declares `kEraseUndoWindow` (4 seconds) and `_pendingErasures`, yet owns no internal `Timer`; instead `EditorMediaFeedback` drives `purgeErased` via `SnackBar.closed.then(...)`. Without an active `ScaffoldMessenger` (or when snackbars are replaced), the undo window never expires on its own. Moreover, `_purge` deletes only `relativePath` and skips the companion `thumbnailPath` created for sandboxed short videos.
- **Split Caption Invariant Across Paper Canvas and Media Binding**: `EditorMediaBinding.updateCaption` updates only SQLite (`MediaOcrDao.updateMediaCaption`), forcing `EditorPaperCanvas` to coordinate both `coordinator.updateCaption` and `onMediaCaptionChanged` manually and carry a parallel `onMediaCaptionChanged` callback alongside `DeskMediaHandlers`.
- **Misplaced Legacy Ephemera Deletion & Orphaned Sandbox Files**: `EditorPaginationHandler` (the viewport scroll and focus adapter) injects `MediaOcrDao` solely for `handleDeleteEphemera`, which removes the legacy `EphemeraSheet` from `EditorPaginationCoordinator` and deletes the SQLite row, **but forgets to delete the underlying sandbox media file (and any companion video thumbnail) from `MediaSandboxService`**, leaking orphaned files on disk in violation of **ADR-0009** and **ADR-0010**.
- **Mixed Responsibilities in `EditorMediaActions`**: `EditorMediaActions` mixes sandbox media ingestion with unrelated **Ghost Prompt** Thought Spark rotation and blockquote insertion (`handleShuffleSpark` and `handleInsertPrompt`).

## Solution

Deepen `EditorMediaBinding` into a cohesive, UI-free media lifecycle module sitting at the `MediaOcrDao` and `MediaSandboxService` seam, while reducing surrounding UI and viewport classes to thin adapters:

- **UI-Free Deep `EditorMediaBinding` over `MediaOcrDao`**: Remove `BuildContext`, `ImagePicker`, and `AppDatabase` from `EditorMediaBinding`; inject `MediaOcrDao` directly. Own the full media lifecycle behind one module interface: headless **Collect** for picked image/video files (enforcing `kHandscrollCapacity`, atomic batch SQLite persistence, best-effort sandbox file rollback on SQLite failure, **Brush Reveal** queuing, draft autosave, and a typed collect outcome), **Mount** / **Unmount**, internal 4-second `Timer`-driven erase-with-undo and SQLite-first file + video thumbnail purge, atomic **Caption** updates across both `EditorPaginationCoordinator` and `MediaOcrDao`, and legacy `EphemeraSheet` deletion across coordinator, SQLite, and sandbox storage.
- **Pure Viewport `EditorPaginationHandler`**: Remove `MediaOcrDao` and `handleDeleteEphemera` from `EditorPaginationHandler`, keeping post-frame `PageController` sheet synchronization in `EditorPaginationHandler` so `EditorMediaBinding` remains free of scroll or widget controllers.
- **Thin UI Adapters**: Consolidate `onCaptionChanged` onto `DeskMediaHandlers` (eliminating the separate `onMediaCaptionChanged` prop on `EditorPaperCanvas` and `EditorDeskMediaArea`), narrow `EditorMediaActions` strictly to camera/gallery bottom-sheet presentation and `ImagePicker` invocation feeding `EditorMediaBinding`, relocate Thought Spark helpers (`handleShuffleSpark`, `handleInsertPrompt`) out of `EditorMediaActions`, and simplify `EditorMediaFeedback` to pure SnackBar presentation and `undoErase` tap wiring.

## User Stories

### Collecting Media into the Staging Handscroll

1. As a diarist tapping photo **Collect** in the **Writing Dock** or **Desk Workstation**, I want picked photos compressed into the sandbox, persisted atomically to SQLite, and added to the **Staging Handscroll** in pick order with queued **Brush Reveals**, so that newly collected items survive an immediate draft reopen.
2. As a diarist recording or picking a short video, I want the video and its companion poster thumbnail persisted cleanly in the sandbox and **Staging Handscroll**, so that playback works offline without leaking temporary files.
3. As a diarist collecting more photos than the remaining **Staging Handscroll** room (capacity 15), I want the editor to **Collect** what fits in order and report cleanly how many photos were left out, so that the handscroll capacity invariant holds reliably.
4. As a diarist collecting photos when SQLite fails to commit the attachment batch, I want newly compressed sandbox files cleaned up immediately, so that failed saves do not leave hidden unreferenced files on disk.

### Erase-with-Undo & Clean File Deletion

5. As a diarist erasing a staged photo or short video from the **Staging Handscroll**, I want a 4-second undo window to restore the item back to its original collect order if I tap Undo in time, so that accidental removals are painless.
6. As a diarist whose 4-second erase undo window elapses (or who confirms discarding staged items on exit), I want both the SQLite `mediaAttachments` row and **all** sandbox files for that item (including any companion video `thumbnailPath`) deleted permanently, with zero leftover thumbnails on disk.
7. As a diarist removing a legacy full-sheet **Tipped-In Ephemera Leaf** (`EphemeraSheet`) from an older entry, I want its sheet removed, its draft re-saved, its SQLite attachment deleted first, and its sandboxed image/video file (and companion thumbnail) removed from disk, so that storage usage stays clean.

### Caption Continuity & Desk Adapters

8. As a diarist editing a **Caption** on a staged item or **Tucked Print** inside the fullscreen lightbox, I want the updated **Caption** reflected immediately across both in-memory sheet state and SQLite through one atomic operation, so UI displays and reopened drafts never disagree.
9. As a diarist deleting a legacy `EphemeraSheet`, I want the editor viewport to smoothly settle onto the surviving active **Stationery Sheet**, so navigation stays seamless.
10. As a diarist triggering **Ghost Prompt** shuffle or insertion from the **Writing Dock**, I want prompt actions cleanly separated from media picking, so prompt behavior remains unaffected by media refactors.

### Developer Ergonomics & Testability

11. As a developer reading editor media logic, I want all media lifecycle state transitions (**Collect**, **Mount**, **Unmount**, erase timer + purge, **Caption**, and legacy ephemera delete) localized inside `EditorMediaBinding`, instead of tracing six shallow modules and UI SnackBar callbacks.
12. As a developer modifying `EditorPaginationHandler`, I want the viewport/focus adapter to hold zero `MediaOcrDao` or SQLite deletion dependencies, keeping navigation and pagination concerns cleanly separated.
13. As a developer inspecting `EditorPaperCanvas` and `EditorDeskMediaArea`, I want **Caption** updates carried inside `DeskMediaHandlers` alongside the other desk media callbacks rather than passed as a duplicate sibling property.
14. As a developer testing media lifecycle invariants, I want to verify **Collect** rollback, capacity cutoffs, 4-second erase-undo expiry via `fakeAsync`, atomic **Caption** updates, and legacy `EphemeraSheet` cleanup directly against `EditorMediaBinding` with an in-memory `AppDatabase` and temp sandbox directory without pumping a `Scaffold` or mocking `ImagePicker`.

## Implementation Decisions

### 1. Database Persistence Seam on `MediaOcrDao`

- **Transactional Batch Attachment**: Add an atomic batch attach operation on `MediaOcrDao` running inside `attachedDatabase.transaction` so multi-image **Collect** inserts all rows in a single SQLite write without `EditorMediaBinding` importing or depending on `AppDatabase`.
- **Entry Media Deletion with Thumbnail Discovery**: Ensure `MediaOcrDao` exposes or returns companion `thumbnailPath` values when deleting entry media records matching `(entryId, relativePath)` (or via a dedicated query/delete helper inside the transaction) so both staged video erasures and legacy video `EphemeraSheet` deletions know every sandbox file path that must be cleaned up after SQLite commits.

### 2. Deep `EditorMediaBinding` Interface & Lifecycle

- **Dependencies & Seam Narrowing**:
  - Replace `AppDatabase` with `MediaOcrDao` and remove `BuildContext` and `ImagePicker` from `EditorMediaBinding` so the module is 100% UI-free (`flutter/material.dart`-free).
  - Retain `MediaSandboxService`, `entryId`, `EditorPaginationCoordinator`, `EditorAutosaveManager`, and `VoidCallback onStateChanged`.
- **Headless Collect (`collectImages`, `collectVideo`)**:
  - Inspect `coordinator.handscrollRoom`; when zero, return an immutable collect outcome indicating full handscroll (`collectedCount: 0`, `rejectedByCapacity: inputs.length`) without touching disk or SQLite.
  - Sandbox up to `handscrollRoom` image files (`copyAndCompressImage`) or one video (`copyAndSandboxVideo`). Track every newly created sandbox relative path (and companion video thumbnail path).
  - Persist attachment rows atomically via `MediaOcrDao`. If SQLite insertion throws, execute best-effort cleanup of newly created sandbox paths via `MediaSandboxService.deleteMediaPaths` before rethrowing so failed collects leave zero orphan files on disk.
  - On SQLite commit, collect each item into `coordinator` in input order, enqueue collected IDs into `brushReveals`, invoke `onStateChanged()`, await `autosaveManager.saveDraft()`, and return the immutable collect outcome (`collectedCount`, `rejectedByCapacity`).
- **Internal Erase-Undo Timer & Complete Purge (`eraseStagedMedia`, `undoErase`, `purgeErased`, `discardAllStaged`, `dispose`)**:
  - Maintain a per-attachment active `Timer` map (`_eraseTimers`) alongside `_pendingErasures`.
  - When `eraseStagedMedia(mediaId)` removes an item from `coordinator`, complete any pending **Brush Reveal**, store the item in `_pendingErasures`, schedule `Timer(kEraseUndoWindow, () => purgeErased(mediaId))`, and call `onStateChanged()`.
  - When `undoErase(mediaId)` runs before expiry, cancel and remove its active timer, remove the item from `_pendingErasures`, restore it to `coordinator` in collect order, and notify `onStateChanged()`.
  - Inside `_purge(mediaId)`, cancel and remove any active timer, remove the item from `_pendingErasures`, delete the SQLite row via `MediaOcrDao.deleteMediaForEntryByPath` **first** (**ADR-0010** SQLite-first ordering), and then delete `[item.relativePath, if (item.thumbnailPath != null) item.thumbnailPath!]` via `MediaSandboxService.deleteMediaPaths`.
  - Ensure `discardAllStaged()` and `dispose()` cancel all active timers and purge every pending erasure cleanly.
- **Atomic Caption Sync (`updateCaption`)**:
  - Update in-memory coordinator state (`coordinator.updateCaption(mediaId, newCaption)`), trigger `onStateChanged()` when updated, and await `mediaOcrDao.updateMediaCaption(mediaId, caption: newCaption)` in one place.
- **Legacy Ephemera Sheet Deletion (`deleteLegacyEphemera`)**:
  - Remove legacy `EphemeraSheet` deletion from `EditorPaginationHandler` and expose `deleteLegacyEphemera(int sheetIndex)` on `EditorMediaBinding`.
  - Validate `sheetIndex` points to an `EphemeraSheet`, capture its `sandboxedRelativePath`, call `coordinator.removeEphemeraSheet(sheetIndex)`, notify `onStateChanged()`, delete matching SQLite attachment rows via `MediaOcrDao` first (collecting any companion `thumbnailPath`), delete primary + thumbnail sandbox paths via `MediaSandboxService.deleteMediaPaths`, and await `autosaveManager.saveDraft(force: true)`.

### 3. Pure Viewport `EditorPaginationHandler`

- **Strip DAO Coupling**: Remove `MediaOcrDao` and `handleDeleteEphemera` from `EditorPaginationHandler`.
- **Post-Delete PageController Sync**: Keep `PageController` sheet navigation inside `EditorPaginationHandler` (`_handleCoordinatorNotification` or a lightweight viewport alignment helper invoked after legacy ephemera deletion) so deleting an `EphemeraSheet` smoothly animates to the clamped `coordinator.activeSheetIndex` without `EditorMediaBinding` holding Flutter widget/scroll controllers.

### 4. Thin UI & Prompt Adapters

- **Unify `DeskMediaHandlers` Seam**:
  - Move `onCaptionChanged` onto `DeskMediaHandlers` and remove the redundant `onMediaCaptionChanged` parameter from `EditorPaperCanvas` and `EditorDeskMediaArea`.
  - Inside `EditorPaperCanvas`, wire `onCaptionChanged: deskMedia.onCaptionChanged` into `EditorDeskMediaArea` directly without duplicating `coordinator.updateCaption` at the widget level.
  - Inside `EditorDeskMediaArea`, forward `handlers.onCaptionChanged` to `FullscreenMediaLightbox` and `TuckedPrintsOverlay`.
- **Narrow `EditorMediaActions` & Relocate Thought Spark**:
  - Restrict `EditorMediaActions` strictly to presenting camera/gallery modal choices, invoking `ImagePicker`, forwarding picked files into `EditorMediaBinding`, and rendering capacity/error SnackBars from the returned collect outcome (or thrown `VideoDurationExceededException`).
  - Move `handleShuffleSpark` and `handleInsertPrompt` out of `EditorMediaActions` into `EditorOverlayActions` (or a dedicated prompt helper) so media actions and Thought Spark prompt actions remain cleanly separated.
- **Simplify `EditorMediaFeedback`**:
  - Update `EditorMediaFeedback.handlersFor` to bind `onCaptionChanged: binding.updateCaption` onto `DeskMediaHandlers` and display the 4-second erase-undo SnackBar wiring `SnackBarAction` solely to `binding.undoErase(mediaId)`, removing `.closed.then((reason) => binding.purgeErased(mediaId))`.
- **Screen Wiring (`EntryEditorScreen`)**:
  - Construct `EditorMediaBinding` with `widget.database.mediaOcrDao`, `widget.mediaSandboxService`, `widget.entryId`, `_coordinator`, `autosave`, and `_rebuild`; construct `EditorPaginationHandler` without `MediaOcrDao`.
  - Route legacy `EphemeraSheet` deletion cleanly through `_mediaBinding!.deleteLegacyEphemera` plus `_paginationHandler` viewport sync.

## Testing Decisions

### Good Test Principles

- Test observable external behavior—in-memory coordinator items, collect outcomes, SQLite `mediaAttachments` rows, physical sandbox files on disk, listener notifications, and rendered UI elements—never private maps or timer implementation details.
- Exercise the deepened `EditorMediaBinding` directly at its headless seam using a real in-memory `AppDatabase`, an isolated temporary directory `MediaSandboxService`, and `fakeAsync` for deterministic 4-second timer control.

### Modules & Seams Under Test

1. **`EditorMediaBinding` Direct Unit Suite**:
   - **Image & Video Collect + Rollback**: Verify single/multi-image `collectImages` and `collectVideo` compress files into the sandbox temp dir, insert `mediaAttachments` rows atomically via `MediaOcrDao`, stage items into `EditorPaginationCoordinator` in collect order, enqueue `BrushRevealQueue` IDs, trigger `autosaveManager`, respect `kHandscrollCapacity` (returning accurate `collectedCount` and `rejectedByCapacity`), and delete newly created sandbox files if SQLite persistence throws.
   - **Mount / Unmount**: Verify `mountMedia` and `unmountMedia` update `TuckedPrints` capacity (3 per sheet), increment `mountRefusals` on a full sheet without unstaging, and restore to collect order on unmount.
   - **Erase-with-Undo Internal Timer (`fakeAsync`)**: Verify `eraseStagedMedia` keeps the SQLite row and sandbox files alive throughout the 4-second `kEraseUndoWindow`, `undoErase` before 4 seconds cancels purge and restores collect order, elapsing 4 seconds purges SQLite + primary `.webp`/`.mp4` + companion `_thumb.webp` files automatically with no `Scaffold` mounted, and `discardAllStaged` / `dispose` cancel timers and purge all pending erasures immediately.
   - **Atomic Caption Sync**: Verify `updateCaption` updates both `coordinator` in-memory `SheetMediaItem.caption` (whether staged or mounted) and SQLite `mediaAttachments.caption`.
   - **Legacy Ephemera Deletion**: Verify `deleteLegacyEphemera` removes the target `EphemeraSheet`, preserves neighboring sheets with contiguous indices, deletes the `mediaAttachments` row, and deletes the sandbox file (and companion video thumbnail) from disk.
2. **`EditorPaginationHandler` Seam**:
   - Verify `EditorPaginationHandler` operates without `MediaOcrDao` and keeps `currentSheetIndex` / `PageController` synchronized when sheets shrink.
3. **Existing Editor Widget & Code-Style Regression Suites**:
   - Re-run existing staging handscroll, brush reveal, caption lightbox, exit reminder, legacy ephemera sheet, desk media area, and code-style audit tests (`tool/test.sh`) to verify full end-to-end UI parity and zero audit regressions.

## Out of Scope

- Changing the `kHandscrollCapacity` (15) or per-sheet `kMountCapacity` (3) domain limits or `kEraseUndoWindow` (4 seconds) duration.
- Modifying `GLOSSARY.md` (all terms—**Staging Handscroll**, **Tucked Prints**, **Collect**, **Mount**, **Unmount**, **Brush Reveal**, **Caption**, **Ghost Prompt**—already exist with exact definitions) or SQLite schema version (`8`).
- Refactoring other architecture review candidates (`AlbumStudioController`, Quill Delta IR / vertical pagination, `SearchScreen`, or `SceneryController`).

## Further Notes

- Reinforces **ADR-0009** (*Staging Handscroll & Text-Anchored Sheet Mounting*, Bidirectional Media Lifecycle Parity) and **ADR-0010** (*Seal the AppDatabase & Media Sandbox Seam*, typed DAO encapsulation and SQLite-first deletion ordering).
- Every touched Dart file must comply with the repository `< 450` LOC standard enforced by static audits.
