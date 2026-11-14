---
id: SPEC-017
title: "Deepen the Photobook Document Studio Session Seam"
status: ready-for-agent
created_at: 2026-11-14
adr: ADR-0002, ADR-0010
---

# Deepen the Photobook Document Studio Session Seam

## Problem Statement

When a diarist curates a travel album across the workspace, Book Overview, single-page canvas editor, and flipbook viewer, the **Photobook Document** session state is fractured across static widget snapshots and competing controllers:

1. **Stale Photo Imports Inside the Studio**: `AlbumStudioController` tracks only string photo IDs inside `AlbumStudioDocument`, while `AlbumBookOverviewScreen`, `AlbumPageEditorScreen`, and `AlbumFlipbookScreen` each hold static `AlbumCollection` and `List<AlbumPhoto>` widget fields and construct separate `photoById` lookup maps. When the diarist taps `+ Add → 导入更多照片 · Import Photos` inside `AlbumBookOverviewScreen`, new photos are ingested into SQLite, but `AlbumBookOverviewScreen`'s static photo list and `AlbumStudioController`'s `removedPhotoIds` tray remain completely unaware of the new photos until the studio is closed and reopened—and closing the studio overwrites `studio_layout_json` with the unreconciled document.
2. **Stale Annotations, Cover Seals & Dead Slots After Photo Deletion**: When the diarist opens `PhotoAnnotationSheet` (`写影札`) from `AlbumPageEditorScreen` and edits a photo's caption, location tag, or capture date, sets it as the collection cover, or deletes the photo, the open studio screens retain stale `AlbumPhoto` and `AlbumCollection` snapshots. Even worse, deleting a photo leaves its `photoId` dangling inside the page's `photoSlots` and the controller's 50-step Undo/Redo history, and `AlbumStudioDocument.reconcileWithPhotoIds` prunes slots without adapting the page's collage `layoutTemplateId` to `(N - 1)`.
3. **Competing, Undisposed Flipbook Controller**: Opening `AlbumFlipbookScreen` from `AlbumBookOverviewScreen` passes a static `AlbumStudioDocument` instead of the active `AlbumStudioController`. Tapping the edit action inside `AlbumFlipbookScreen` creates a second, undisposed `AlbumStudioController` instance whose saves race against the overview screen's controller upon navigating back.
4. **Leaked `AlbumsDao` Calls & Duplicated Route Synthesis**: `AlbumCollectionsScreen`, `AlbumWorkspaceScreen`, `PhotoAnnotationSheet`, and `AlbumIngestionService` bypass `AlbumRepository` to call `database.albumsDao` directly (violating ADR-0010's typed repository boundary). Furthermore, the rule that auto-updates `routeSummary` when it was previously empty or auto-synthesized is duplicated between `AlbumRepository.updatePhotoAnnotationAndSyncRoute` and `AlbumWorkspaceScreen`, and is omitted entirely when a photo with a location tag is deleted.

## Solution

Collapse **Photobook Document** session ownership into a deepened, reactive **`AlbumStudioController`** backed by a sealed **`AlbumRepository`**:

1. **Seal `AlbumsDao` Behind `AlbumRepository` with Unified Auto-Route Synthesis**:
   - Route all collection and photo streams, queries, metadata updates, cover assignments, batch photo insertions, and photo reorderings in the albums feature exclusively through `AlbumRepository`.
   - Centralize auto-route synthesis (`routeSummary`) into a single helper on `AlbumRepository` and invoke it consistently across photo annotation updates, photo reordering, and photo deletions.
   - Support an explicit `autoPopulate` parameter on `AlbumRepository.loadOrSynthesizeStudioDocument(collectionId, {bool autoPopulate = false})` so Studio Overview entry defaults to `autoPopulate: false` (blank starter page + Collection Box tray) while direct Flipbook entry defaults to `autoPopulate: true` (multi-photo collage spreads).
2. **Deepen `AlbumStudioController` into the Single Reactive Session Owner**:
   - `AlbumStudioController` owns the live `AlbumCollection?`, `List<AlbumPhoto>`, `Map<String, AlbumPhoto> photoById`, `overviewSpreads`, and `flipbookSpreads` projections for `collectionId`.
   - When constructed with an `AlbumRepository`, `AlbumStudioController` subscribes to `watchCollectionById` and `watchPhotosForCollection` (preserving initial in-memory seed data when `watchCollectionById` emits `null` for unpersisted test fixtures) and cancels subscriptions on `dispose()`.
   - When the live photo stream changes for a persisted collection, `AlbumStudioController` automatically reconciles `_document`, `_undoStack`, and `_redoStack` via `AlbumStudioDocument.reconcileWithPhotoIds` (deduplicating adjacent identical history states) and schedules persistence whenever the reconciled document differs from `_document`.
   - `AlbumStudioDocument.reconcileWithPhotoIds` automatically adapts any affected page's `layoutTemplateId` to `'solo_full_bleed'` (when 0 slots remain) or `PageLayoutCatalog.defaultTemplateForPhotoCount(validSlots.length).id` (when slots are pruned by deletion).
3. **Share One `AlbumStudioController` Across Overview, Page Editor, and Flipbook**:
   - `AlbumBookOverviewScreen` and `AlbumFlipbookScreen` accept an optional `AlbumStudioController? controller`, creating and disposing their own controller only when entered as the root studio/flipbook route and forwarding the shared instance to child routes (`AlbumPageEditorScreen`, `AlbumFlipbookScreen`).
   - All studio screens, `PhotoAnnotationSheet`, and `AlbumPdfPreviewSheet` consume live `controller.collection`, `controller.photos`, and `controller.photoById`.

## User Stories

1. As a diarist importing additional photos via `+ Add → 导入更多照片 · Import Photos` inside the Book Overview screen, I want the newly imported photos to appear immediately in the studio's Collection Box tray (`removedPhotoIds`) and photo lookup map without closing and reopening the studio, so that I can place them onto pages right away.
2. As a diarist closing the Book Overview screen after importing photos inside the studio, I want the persisted `studio_layout_json` to include the newly imported photo IDs in `removedPhotoIds`, so that my imported photos are not lost on save.
3. As a diarist editing a photo's caption, location tag, or capture date via `PhotoAnnotationSheet` (`写影札`) while inside `AlbumPageEditorScreen`, I want the updated photo metadata and any auto-synthesized collection `routeSummary` to reflect immediately across the page canvas, Book Overview, Flipbook, and PDF export without reopening the studio.
4. As a diarist setting a photo as the collection cover inside `PhotoAnnotationSheet` while in the studio, I want the Front Cover spread in Book Overview, Flipbook, and PDF export to reflect the new `coverImagePath` immediately, so that I see full WYSIWYG cover parity.
5. As a diarist permanently deleting a photo via `PhotoAnnotationSheet` while inside `AlbumPageEditorScreen`, I want the deleted photo to be automatically pruned from its page slot (or the Collection Box tray) and the page's collage layout template to adapt cleanly to `(N - 1)` photos, so that the page never renders a broken or empty slot frame.
6. As a diarist pressing Undo or Redo in the studio after deleting a photo from the collection, I want the deleted photo ID to be scrubbed from all Undo/Redo history snapshots, so that Undo never resurrects a dangling reference to a deleted sandbox file.
7. As a diarist deleting a photo that carried a location tag from a collection using an auto-synthesized `routeSummary`, I want the collection's `routeSummary` to automatically re-synthesize from the remaining photos' location tags (while preserving custom manual route summaries), so that the travel trajectory banner stays accurate.
8. As a diarist navigating from `AlbumBookOverviewScreen` to `AlbumFlipbookScreen` and tapping the edit button (`flipbook_edit_button`) to open `AlbumPageEditorScreen`, I want all three screens to share the exact same `AlbumStudioController` instance, so that edits made via the Flipbook are immediately visible in the Flipbook and Book Overview without leaked controllers or conflicting background saves.
9. As a diarist tapping the edit button in `AlbumFlipbookScreen` while viewing a specific **Photobook Spread**, I want `AlbumPageEditorScreen` to open at the first editable page of that spread (`leftPageIndex ?? rightPageIndex ?? 0`), so that I edit the spread I am currently inspecting.
10. As a diarist opening `AlbumFlipbookScreen` directly from `AlbumWorkspaceScreen` on a collection that has not yet saved a custom studio layout, I want the flipbook to compile a multi-photo collage layout (`autoPopulate: true`) for immediate reading and PDF export while leaving `AlbumBookOverviewScreen` to start with a creative blank starter page (`autoPopulate: false`) if opened without prior studio edits.
11. As a developer maintaining the albums module, I want all SQLite reads, reactive streams, and writes in `lib/features/albums/` to pass exclusively through `AlbumRepository` with zero direct `.albumsDao` references outside `AlbumRepository`, so that database and sandbox invariants remain sealed behind one repository seam.
12. As a developer writing tests for **Photobook Document** workflows, I want to drive imports, annotations, deletions, layout mutations, Undo/Redo, and spread generation headlessly through `AlbumStudioController` and `AlbumRepository` without mounting widget trees, so that tests are fast, deterministic, and decoupled from widget presentation.

## Implementation Decisions

### 1. Sealed `AlbumRepository` Interface & Auto-Route Synthesis
- `AlbumRepository` is the sole persistence and stream boundary for `lib/features/albums/`. No file under `lib/features/albums/` outside `album_repository.dart` may reference `.albumsDao` or `AlbumsDao`.
- Add the following methods to `AlbumRepository` (delegating to `database.albumsDao`):
  - Reactive streams:
    - `Stream<List<AlbumCollection>> watchAllCollections()`
    - `Stream<Map<String, int>> watchPhotoCounts()`
    - `Stream<AlbumCollection?> watchCollectionById(String collectionId)`
    - `Stream<List<AlbumPhoto>> watchPhotosForCollection(String collectionId)`
  - Queries:
    - `Future<AlbumCollection?> getCollectionById(String collectionId)`
    - `Future<List<AlbumPhoto>> getPhotosForCollection(String collectionId)`
    - `Future<AlbumPhoto?> getPhotoById(String photoId)`
  - Mutations:
    - `Future<void> updateCollectionMetadata({required String id, required String title, String? description, String? destinationTag, String? routeSummary, DateTime? startDate, DateTime? endDate})`
    - `Future<void> setCollectionCover(String collectionId, String photoId)`
    - `Future<void> reorderCollections(List<String> orderedCollectionIds)`
    - `Future<List<AlbumPhoto>> addPhotosBatch(String collectionId, List<AlbumPhotosCompanion> photos)`
    - `Future<void> reorderPhotosAndSyncRoute(String collectionId, List<String> orderedPhotoIds)`
- Extract a private helper on `AlbumRepository` that captures whether a collection's `routeSummary` was empty or matched `synthesizeRouteSummary(collectionId)` prior to a photo mutation, executes the mutation, and—if the route was auto-managed—calls `synthesizeRouteSummary(collectionId, persistToCollection: true)` afterward. Use this helper across:
  1. `updatePhotoAnnotationAndSyncRoute`
  2. `reorderPhotosAndSyncRoute`
  3. `deletePhoto`
- Update `AlbumRepository.loadOrSynthesizeStudioDocument(String collectionId, {bool autoPopulate = false})` to forward `autoPopulate` to `AlbumLayoutEngine.resolveOrCompileDocument`.
- Update `AlbumCollectionsScreen`, `AlbumWorkspaceScreen`, `PhotoAnnotationSheet`, and `AlbumIngestionService` to use `AlbumRepository` methods exclusively (and fix `AlbumWorkspaceScreen._handleOpenFlipbook` to pass `_repository` instead of `widget.repository`). Keep `AlbumCollectionsScreen` and `AlbumWorkspaceScreen` constructor signatures backward-compatible for external callers.

### 2. Adaptive Slot Reconciliation on `AlbumStudioDocument`
- In `AlbumStudioDocument.reconcileWithPhotoIds(Iterable<String> currentPhotoIds)`:
  - When pruning deleted photo IDs from a page's `photoSlots`, if `validSlots.length < page.photoSlots.length`, automatically adapt `layoutTemplateId` on that page:
    - If `validSlots.isEmpty`, set `layoutTemplateId` to `'solo_full_bleed'`.
    - Otherwise, set `layoutTemplateId` to `PageLayoutCatalog.defaultTemplateForPhotoCount(validSlots.length).id`.
  - If `validSlots.length == page.photoSlots.length`, preserve the page's existing `layoutTemplateId`.

### 3. Deepened Reactive `AlbumStudioController` Session
- Extend `AlbumStudioController` with optional session parameters while keeping existing synchronous unit-test construction (`AlbumStudioController(collectionId: ..., initialDocument: ...)`) working without change:
  ```dart
  AlbumStudioController({
    required this.collectionId,
    required AlbumStudioDocument initialDocument,
    AlbumCollection? initialCollection,
    List<AlbumPhoto> initialPhotos = const [],
    this.repository,
    Future<void> Function(AlbumStudioDocument)? onPersist,
    this.debounceDuration = const Duration(milliseconds: 600),
  })
  ```
- Expose reactive session state getters on `AlbumStudioController`:
  - `AlbumCollection? get collection`
  - `List<AlbumPhoto> get photos` (unmodifiable)
  - `Map<String, AlbumPhoto> get photoById` (unmodifiable map keyed by `photo.id`)
  - `List<BookSpreadData> get overviewSpreads => _document.buildSpreads(includeBlankTrailing: true)`
  - `List<BookSpreadData> get flipbookSpreads => _document.buildSpreads(includeBlankTrailing: false)`
- When `repository != null`, `AlbumStudioController` subscribes to `repository!.watchCollectionById(collectionId)` and `repository!.watchPhotosForCollection(collectionId)`:
  - Track `_hasPersistedCollection`: when `watchCollectionById` emits a non-null `AlbumCollection`, set `_hasPersistedCollection = true`, update `_collection`, and call `notifyListeners()`. If `watchCollectionById` emits `null` (e.g., an unpersisted in-memory widget test fixture), retain `_collection` and leave `_hasPersistedCollection = false`.
  - When `watchPhotosForCollection` emits `nextPhotos`: if `!_hasPersistedCollection && nextPhotos.isEmpty && _photos.isNotEmpty`, ignore the empty emission so unpersisted in-memory test fixtures keep their seeded `initialPhotos`. Otherwise, update `_photos` and `_photoById`, reconcile `_document` via `_document.reconcileWithPhotoIds(nextPhotos.map((p) => p.id))`, reconcile every snapshot in `_undoStack` and `_redoStack` with the same `reconcileWithPhotoIds` call (removing adjacent duplicate snapshots), and if `reconciledDoc != _document`, assign `_document = reconciledDoc` (clamping `_selectedPageIndex`), call `_schedulePersist()`, and call `notifyListeners()` (or call `notifyListeners()` whenever `photos` or `_document` changed).
- Cancel both stream subscriptions inside `AlbumStudioController.dispose()` before flushing any pending debounced persistence timer.

### 4. Shared Controller Lifecycle Across Studio & Flipbook Screens
- `AlbumBookOverviewScreen`:
  - If `widget.controller != null`, use it (`_ownsController = false`); otherwise (`_ownsController = true`), load the initial document via `widget.repository.loadOrSynthesizeStudioDocument(widget.collection.id, autoPopulate: false)` and construct `AlbumStudioController` seeded with `initialCollection: widget.collection`, `initialPhotos: widget.photos`, `initialDocument: doc`, and `repository: widget.repository`.
  - Read `final collection = ctrl.collection ?? widget.collection;`, `final photos = ctrl.photos;`, `final photoById = ctrl.photoById;`, and `final spreads = ctrl.overviewSpreads;` inside `ListenableBuilder(listenable: ctrl, ...)`.
  - Pass `controller: ctrl`, `collection: collection`, and `photos: photos` when pushing `AlbumPageEditorScreen` or `AlbumFlipbookScreen`, and pass `collection: collection`, `photos: photos`, `studioDocument: ctrl.document` when opening `AlbumPdfPreviewSheet`.
- `AlbumPageEditorScreen`:
  - Read `final collection = widget.controller.collection ?? widget.collection;`, `final photos = widget.controller.photos.isNotEmpty || widget.controller.collection != null ? widget.controller.photos : widget.photos;`, and `final photoById = widget.controller.photoById.isNotEmpty || widget.controller.collection != null ? widget.controller.photoById : _buildFallbackPhotoLookup();` inside `ListenableBuilder(listenable: widget.controller, ...)`.
  - Pass live `collection` to `PhotoAnnotationSheet.show(...)`.
- `AlbumFlipbookScreen`:
  - Accept optional `AlbumStudioController? controller`.
  - If `widget.controller != null`, reuse it (`_ownsController = false`). Otherwise (`_ownsController = true`), resolve initial document via `widget.document ?? AlbumLayoutEngine.resolveOrCompileDocument(collection: widget.collection, photos: widget.photos, autoPopulate: true)` and construct an owned `AlbumStudioController` seeded with `initialCollection: widget.collection`, `initialPhotos: widget.photos`, `initialDocument: initialDoc`, and `repository: widget.repository` (disposing it in `AlbumFlipbookScreen.dispose()`).
  - Wrap the screen body in `ListenableBuilder(listenable: _controller, ...)` and read live `collection`, `photos`, `photoById`, and `spreads = _controller.flipbookSpreads` (clamping `_currentIndex` safely when `spreads.length` changes).
  - When `_handleOpenStudioEditor` is triggered, compute the target page index from the current spread (`final currentSpread = spreads[_currentIndex.clamp(0, spreads.length - 1)]; final targetPageIndex = currentSpread.leftPageIndex ?? currentSpread.rightPageIndex ?? 0;`), call `_controller.selectPage(targetPageIndex)`, and push `AlbumPageEditorScreen` with `controller: _controller`—never creating a second `AlbumStudioController`.

## Testing Decisions

### What Makes a Good Test
- **Test external behavior at the session seam, not internal wiring**: Assert observable state transitions on `AlbumStudioController` (`collection`, `photos`, `photoById`, `pages`, `removedPhotoIds`, `overviewSpreads`, `flipbookSpreads`, `canUndo`, `canRedo`) and persisted SQLite state via `AlbumRepository` rather than inspecting private stream subscriptions or timers.
- **Real in-memory SQLite + temp file sandbox**: Exercise `AlbumRepository` and `AlbumStudioController` against a real in-memory `AppDatabase` and temporary `MediaSandboxService` directory (`AlbumTestHarness`).

### Modules to Be Tested
1. **`AlbumRepository` (`test/features/albums/album_repository_test.dart`)**:
   - Sealed stream and mutation methods (`watchAllCollections`, `watchPhotoCounts`, `watchCollectionById`, `watchPhotosForCollection`, `updateCollectionMetadata`, `setCollectionCover`, `reorderCollections`, `addPhotosBatch`, `reorderPhotosAndSyncRoute`).
   - Auto-route synthesis on `updatePhotoAnnotationAndSyncRoute`, `reorderPhotosAndSyncRoute`, and `deletePhoto` (updating auto-synthesized `routeSummary` when a waypoint photo is edited, reordered, or deleted, while preserving manual route overrides).
   - `loadOrSynthesizeStudioDocument` with `autoPopulate: false` vs `autoPopulate: true`.
2. **`AlbumStudioDocument` & `AlbumStudioController` (`test/features/albums/album_studio_controller_test.dart`)**:
   - `reconcileWithPhotoIds` adapting page `layoutTemplateId` to `(N - 1)` or `'solo_full_bleed'` when slots are pruned by photo deletion while preserving `layoutTemplateId` when no slots are lost.
   - Live SQLite stream reconciliation when backed by `AlbumRepository`:
     - Importing new photos appends them to `removedPhotoIds`, updates `photos` and `photoById`, preserves existing pages and undo history, and persists the reconciled document.
     - Editing photo annotations or setting cover updates `photos`, `photoById`, and `collection` reactively.
     - Deleting a photo prunes it from page slots and `removedPhotoIds`, adapts the affected page's `layoutTemplateId`, scrubs the deleted `photoId` from `_undoStack` and `_redoStack`, and persists the reconciled document.
3. **Studio & Flipbook Screen Integration (`test/features/albums/album_book_overview_screen_test.dart`, `test/features/albums/album_flipbook_screen_test.dart`, `test/features/albums/album_page_editor_screen_test.dart`)**:
   - Importing photos via `AlbumBookOverviewScreen`'s `+ Add → Import Photos` immediately updates the overview header's Collection Box count (`收集箱 N 张`) and makes the imported photos available in `AlbumPageEditorScreen`'s Removed tray.
   - Editing or deleting a photo via `PhotoAnnotationSheet` inside `AlbumPageEditorScreen` immediately updates the canvas and overview spreads.
   - Navigating `AlbumBookOverviewScreen` → `AlbumFlipbookScreen` → `AlbumPageEditorScreen` shares one `AlbumStudioController` so page edits made from Flipbook immediately reflect in both Flipbook and Book Overview.
4. **Architectural Guardrail (`test/hardening/code_style_audit_test.dart`)**:
   - Enforce that zero files under `lib/features/albums/` other than `album_repository.dart` contain `.albumsDao` or `AlbumsDao`.

### Prior Art
- `test/features/albums/album_test_harness.dart` for real in-memory `AppDatabase` + temp `MediaSandboxService` setup.
- `test/features/albums/album_studio_controller_test.dart` and `test/features/albums/album_repository_test.dart` for headless controller and repository unit tests.
- `test/hardening/code_style_audit_test.dart` for static architectural boundary assertions.

## Out of Scope

- Changing the visual design, layout template geometries (`PageLayoutCatalog`), or theme palettes (`AlbumThemeCatalog`) of the DIY Photobook Studio.
- Modifying the PDF vector rendering pipeline (`AlbumPdfExporter` / `AlbumStudioPdfRenderer`).
- Adding new SQLite tables or columns (schema version remains unchanged).

## Further Notes

- Aligns with **ADR-0002** (Collapse Dual-Model Photobook Pipeline onto Canonical Studio Document) and **ADR-0010** (Seal the AppDatabase & Media Sandbox Seam).
- Every file under `lib/features/albums/` touched by this spec must remain under the 450 LOC ceiling enforced by `test/hardening/code_style_audit_test.dart` (`CODING_STANDARDS.md` § 3). Note that `album_studio_controller.dart` (currently 640 LOC), `album_workspace_screen.dart` (currently 762 LOC), `album_book_overview_screen.dart` (currently 599 LOC), and `album_page_editor_screen.dart` (currently 602 LOC) are on the grandfathered ceiling list in `code_style_audit_test.dart`; when touching them, either decompose cohesive helpers so they drop below 450 LOC or ensure they never exceed their current line ceilings.
