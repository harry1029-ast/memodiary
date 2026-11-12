---
id: SPEC-012
title: Deepen Stationery Sheet Pagination Coordinator & Listener Seam
status: ready-for-agent
created_at: 2026-11-12T00:13:05+08:00
adr: ADR-0008, ADR-0009
---

# Specification: Deepen Stationery Sheet Pagination Coordinator & Listener Seam

## Problem Statement

While authoring a diary entry across discrete **Stationery Sheets**, the pagination, listener binding, media staging, and Delta splitting logic is fragmented across ten shallow modules with leaked invariants and temporal coupling:

- **Broken Document Stream Subscriptions & External Rebinding**: Replacing a **Stationery Sheet**'s underlying Quill document in place during **Auto-Spill**, **Spill-Back**, or layout re-balancing silently invalidates active document change stream subscriptions. Because the pagination coordinator does not observe its own sheets, both the pagination handler and the autosave manager independently duplicate a ~45-line listener-binding loop that polls for document identity swaps. External callers (including template and typography pickers in the **Scholar's Stationery Chest**) must manually invoke listener rebinding after mutations, or live typing stops triggering **Auto-Spill** and autosave.
- **Split Leading-Backspace / Spill-Back Interception**: Pressing Backspace at the leading edge of a continuation **Stationery Sheet** (or immediately after a leading invisible mount marker) is intercepted in two separate places: inside the custom Quill controller's text replacement hook and inside a widget-level keyboard focus handler that prop-drills a callback from the top-level editor screen through the paper canvas into the text sheet view. Both sites duplicate the mount-marker offset inspection.
- **Exposed Mutable Lists & Temporal Coupling Across Collaborators**: The coordinator exposes a sub-object for **Staging Handscroll** and **Tucked Prints** operations that holds raw mutable references to the coordinator's internal sheet and staged-item lists. Similarly, **Spill-Back** requires the coordinator to manually snapshot mounted **Tucked Prints** before calling the spill mutator and manually trigger mount reflow afterward, or keepsakes on a collapsed sheet are lost.
- **Duplicated Paragraph Tokenization & Line-Budget Splitting**: Cold-load Delta partitioning and live **Auto-Spill** overflow extraction maintain separate loops to tokenize newline-delimited paragraphs, attach zero-height mount markers, measure wrapped rows inside the **Paper Heart**, and split Delta operations at safe UTF-16 code-point boundaries.

## Solution

Deepen the **Stationery Sheet** pagination cluster into a self-contained pagination coordinator module with a narrow, complete public interface and high internal locality:

- **Self-Contained Per-Sheet Change Observation**: The pagination coordinator owns all per-sheet document change streams, controller listeners, and ephemera **Caption** listeners internally. Whenever sheets are initialized, partitioned, split, merged, or re-Balanced, the coordinator manages subscription lifecycles and document identity transitions behind its own seam. Live edits on any sheet's controller automatically trigger **Auto-Spill**, empty continuation sheet collapse, **Tucked Prints** mount reflow, and content revision increments without external callers ever rebinding listeners.
- **Simplified Autosave & Viewport Adapters**:
  - The autosave manager drops all direct sheet and document stream subscriptions, observing only the coordinator's content revision notifier and the entry title controller.
  - The pagination handler drops all listener-management plumbing and acts strictly as a viewport and focus adapter that animates page turns and transfers keyboard focus in response to coordinator forward (`onAutoSpill`) and reverse (`onSpillBack`) transition signals.
- **Unified Leading-Backspace Locality**: The **Stationery Sheet** descriptor and its custom Quill controller own leading-Backspace detection in one place. The coordinator wires each continuation sheet's leading-Backspace callback to **Spill-Back** automatically whenever sheets are indexed, and the text sheet widget delegates hardware Backspace key events directly to its sheet descriptor, eliminating callback prop-drilling through the canvas.
- **Cohesive Coordinator Interface for Media & Sheet Mutations**: **Collect**, **Mount / Unmount**, staged erasure and undo restoration, **Caption** updates, and legacy ephemera sheet removal become direct methods on the pagination coordinator's interface, hiding internal list and mount-tracker invariants behind the module seam.
- **Single Paragraph Tokenization & Line-Budget Splitting Implementation**: Cold-load Delta partitioning and live **Auto-Spill** overflow extraction share one internal paragraph tokenizer and line-budget splitter that preserves inline attributes, UTF-16 surrogate pairs, and zero-height mount markers.

## User Stories

### Self-Contained Live Editing & Autosave

1. As a diarist typing continuously past the ruled **Paper Heart** capacity of an opening or continuation **Stationery Sheet**, I want the coordinator to automatically detect the overflow and perform **Auto-Spill** onto the next sheet without requiring external listener rebinding, so that my writing flows across sheets without dropped keystrokes or stale listeners.
2. As a diarist pasting a multi-paragraph passage onto a **Stationery Sheet**, I want the coordinator to cascade the overflow across as many continuation sheets as needed and emit a single forward transition signal to the final destination sheet, so that the viewport glides smoothly to my caret's new resting place.
3. As a diarist composing text with a Pinyin or CJK Input Method Editor (IME), I want **Auto-Spill**, **Spill-Back**, layout re-balancing, and **Tucked Prints** mount reflow to defer while the IME composing range is active and run automatically as soon as composition commits, so that active IME candidate selection is never interrupted.
4. As a diarist deleting the last remaining character on a continuation **Stationery Sheet**, I want the coordinator to automatically collapse trailing empty continuation sheets, clamp the active sheet index, and emit a reverse transition signal (`onSpillBack`), so that the viewport returns to the preceding sheet with my caret placed at the end of its text.
5. As a diarist switching stationery templates or adjusting typography (font family, size, or line spacing) inside the **Scholar's Stationery Chest**, I want the coordinator to re-balance all **Stationery Sheets** and keep all sheet change listeners active automatically, so that typing immediately after a template or font change continues to trigger **Auto-Spill** and autosave without manual listener re-attachment by the screen.
6. As a diarist editing body text, editing a legacy ephemera **Caption**, or mutating **Tucked Prints**, I want every content mutation to increment the coordinator's content revision notifier, so that the autosave manager schedules a debounced SQLite save solely by observing that notifier and the title controller.

### Leading Backspace & Spill-Back Locality

7. As a diarist pressing Backspace at offset 0 of a continuation **Stationery Sheet** (via either the software keyboard or a hardware keyboard), I want the sheet to invoke its leading-Backspace handler and trigger **Spill-Back** on the coordinator, so that content merges back onto the preceding sheet up to its **Paper Heart** row capacity without prop-drilling callbacks through the canvas widget tree.
8. As a diarist pressing Backspace immediately after a leading invisible mount marker on a continuation **Stationery Sheet** where no visible text precedes the marker, I want the controller to recognize that the cursor is at the leading text edge and trigger **Spill-Back** rather than deleting the invisible mount marker, so that my **Tucked Prints** remain mounted while the sheet merges backward.
9. As a diarist pressing Backspace immediately after a leading invisible mount marker on the opening **Stationery Sheet** (Sheet 1), I want the controller to treat the operation as a no-op without unmounting the keepsake, so that **Tucked Prints** on the opening sheet are protected from accidental Backspace deletion.
10. As a diarist triggering **Spill-Back** on a continuation **Stationery Sheet** that holds mounted **Tucked Prints**, I want the coordinator to remember and reflow those mounts automatically inside the **Spill-Back** operation, so that keepsakes transfer cleanly to the preceding sheet (or cascade) without being lost when the continuation sheet collapses.

### Staging Handscroll & Tucked Prints Cohesion

11. As a diarist collecting a photo or video into the **Staging Handscroll**, I want to invoke **Collect** directly on the pagination coordinator (`collectMedia`), checking remaining handscroll capacity (`handscrollRoom`) through the same interface, so that collect-order tracking and revision notifications are encapsulated inside the coordinator.
12. As a diarist mounting a staged photo or video from the **Staging Handscroll** onto the active **Stationery Sheet** (`mountOnActiveSheet`), I want the coordinator to insert the invisible mount marker at the end of the sheet's text without summoning the software keyboard and attach the item to the sheet's **Tucked Prints** (up to the 3-item capacity), so that mounting works through a single coordinator method.
13. As a diarist unmounting a keepsake from a **Stationery Sheet**'s **Tucked Prints** (`unmountMedia`), I want the coordinator to strip its mount marker from whichever sheet holds it and return the item to the **Staging Handscroll** in its original **Collect** order, so that unmounted keepsakes always rejoin the handscroll predictably.
14. As a diarist erasing a staged keepsake from the **Staging Handscroll** (`removeStaged`) and optionally tapping Undo (`restoreStaged`), I want the coordinator to remove and restore the item at its original **Collect** rank while bumping content revision, so that undo restoration preserves handscroll ordering.
15. As a diarist editing a photo or video **Caption** in the fullscreen lightbox (`updateCaption`), I want the coordinator to update the in-memory item whether it is currently mounted in **Tucked Prints** or waiting in the **Staging Handscroll**, so that lightbox **Caption** edits reflect immediately in memory.

### Unified Paragraph Tokenization & Delta Splitting

16. As a diarist opening an existing entry or typing new paragraphs with bold, italic, color, header, or list formatting, I want cold-load Delta partitioning and live **Auto-Spill** overflow extraction to use the same paragraph tokenizer and line-budget splitter, so that sheet breaks are 1:1 identical between initial load and live editing.
17. As a diarist writing text containing multi-byte UTF-16 surrogate pairs (such as emoji or rare CJK ideographs) across a line or sheet wrap boundary, I want the shared splitter to snap split offsets to safe code-point boundaries, so that characters are never corrupted across **Stationery Sheets**.
18. As a diarist pressing Enter repeatedly on a **Stationery Sheet** that has mounted **Tucked Prints**, I want empty trailing newlines that spill onto the next sheet without accompanying text to leave the sheet's mount markers anchored on the source sheet, so that pressing Enter on an empty line does not push **Tucked Prints** onto the next sheet.
19. As a diarist whose draft is saved to SQLite (`reSynthesize`), I want orphan or duplicate mount markers stripped and structural emptiness (`document.length <= 1` with no mount markers or ephemera sheets) evaluated consistently, so that whitespace and intentional blank lines are preserved while truly empty drafts serialize cleanly.

## Implementation Decisions

- **Deepened Coordinator Module (`EditorPaginationCoordinator`)**:
  - Owns per-sheet listener subscriptions for all active `TextStationerySheet` and `EphemeraSheet` instances. Whenever the sheet list is populated, re-partitioned, split, merged, or re-indexed, the coordinator synchronizes its internal subscriptions and assigns each continuation sheet's `onBackspaceAtStart` callback to trigger `handleSpillBack(sheet.sheetIndex)`.
  - Handles in-place `controller.document` replacement internally: when a `TextStationerySheet` swaps its `Document` via `setDelta`, the coordinator's listener rebinds its `Document.changes` subscription to the new `Document` instance without treating the programmatic swap as a user typing event.
  - Guards internal sheet mutations with a re-entrancy flag so programmatic Delta updates during **Auto-Spill**, **Spill-Back**, trailing-sheet collapse, and mount reflow do not recursively trigger listener callbacks.
  - Exposes two directional viewport transition callbacks:
    - `ValueChanged<AutoSpillResult>? onAutoSpill` for forward overflow transitions.
    - `ValueChanged<SpillBackResult>? onSpillBack` for reverse sheet transitions (triggered both by leading-Backspace **Spill-Back** and by deleting the last character on an active continuation sheet so that it collapses).
  - Promotes media and sheet operations directly onto `EditorPaginationCoordinator`'s public interface:
    - `int get handscrollRoom`
    - `bool collectMedia(SheetMediaItem item)`
    - `bool mountOnActiveSheet(String mediaId)`
    - `bool unmountMedia(String mediaId)`
    - `SheetMediaItem? removeStaged(String mediaId)`
    - `void restoreStaged(SheetMediaItem item)`
    - `bool updateCaption(String mediaId, String newCaption)`
    - `void removeEphemeraSheet(int sheetIndex)`
    - Retires the public `coordinator.media` getter; internal media state helpers remain private to the coordinator module (split via `part` files or package-internal helpers to keep every source file under the 450-line limit).
- **Autosave Module Simplification (`EditorAutosaveManager`)**:
  - Removes all per-sheet `Document.changes` subscriptions, `QuillController` listeners, `EphemeraSheet.captionController` listeners, and `_rebindSheetListeners()` logic.
  - Subscribes exclusively to `coordinator.contentRevision` and `titleController`, scheduling debounced saves whenever either notifies.
- **Viewport & Focus Adapter Simplification (`EditorPaginationHandler`)**:
  - Removes `attachSheetListeners()`, `_subscriptions`, `_listenerRemovers`, and `_onSheetDocumentChanged`.
  - Listens to `coordinator` state changes, `coordinator.onAutoSpill`, and `coordinator.onSpillBack` to update `currentSheetIndex`, mark/save drafts on `autosaveManager`, invoke `onStateChanged`, and schedule post-frame `PageController.animateToPage` and `FocusNode` / caret selection handoff.
  - Retains user-initiated page turn methods (`goToSheet`, `handlePageChanged`, `ensureActiveTextSheet`, `activeTextController`, `handleDeleteEphemera`).
- **Leading-Backspace Encapsulation (`TextStationerySheet` & `StationeryQuillController`)**:
  - `StationeryQuillController` exposes `bool handleLeadingBackspace()`, which checks whether the selection is collapsed and `MountMarker.prevNonMarkerOffset(document.toDelta(), selection.baseOffset) == null`, invoking `onBackspaceAtStart` and returning `true` when handled.
  - `TextStationerySheet` delegates `bool handleLeadingBackspace()` to its controller (returning `false` on `OpeningSheet` where `sheetIndex == 0`).
  - `EditorTextSheetView`'s `Focus.onKeyEvent` handler for `LogicalKeyboardKey.backspace` calls `sheet.handleLeadingBackspace()` directly.
  - The `onSpillBack` callback parameter is removed from `EditorTextSheetView` and `EditorPaperCanvas`, and `EntryEditorScreen` no longer passes `onSpillBack` or calls `attachSheetListeners()`.
- **Unified Paragraph Tokenization & Line-Budget Splitting**:
  - Consolidates paragraph extraction (`extractContentBlocks` and `extractParagraphsFromDelta`) so newline-terminated text blocks with attached zero-height `MountMarker` embeds and block attributes are tokenized by one shared implementation.
  - Consolidates single-paragraph line measurement and safe UTF-16 code-point offset splitting so `EditorDeltaPartitioner.partition` and `StationeryDeltaSplitter.extractOverflow` share the same line-break cut calculation instead of duplicating loop bodies.

## Testing Decisions

- **What Makes a Good Test**:
  - Tests exercise the public interface of the deepened modules (`EditorPaginationCoordinator`, `EditorDeltaPartitioner`, `EditorAutosaveManager`, and `EntryEditorScreen`) and assert on observable outcomes (sheet count, per-sheet plain text and Delta attributes, active sheet index, caret offset, mounted **Tucked Prints**, **Staging Handscroll** contents, emitted `AutoSpillResult` / `SpillBackResult` events, and persisted SQLite entry rows), never internal private helper state.
- **Modules Under Test**:
  - `EditorPaginationCoordinator` & `EditorDeltaPartitioner`: Tested directly in unit tests for cold-load partitioning, live `QuillController` typing/deletion triggering automatic **Auto-Spill** and empty-sheet collapse without external listener calls, leading-Backspace **Spill-Back** with mounted **Tucked Prints** preservation, emoji surrogate-pair splitting, inline attribute preservation, empty-row mount marker retention, orphan marker stripping, and direct media methods (`collectMedia`, `mountOnActiveSheet`, `unmountMedia`, `removeStaged`, `restoreStaged`, `updateCaption`, `removeEphemeraSheet`).
  - `EditorAutosaveManager`: Tested with an in-memory `AppDatabase` and `EditorPaginationCoordinator` to verify that live sheet text edits, **Caption** edits, and media mutations trigger debounced and forced SQLite persistence solely via `coordinator.contentRevision`.
  - `EntryEditorScreen` & Paginated Stage Widget Tests: Tested through `WidgetTester` to verify end-to-end page turns, **Auto-Spill**, hardware and IME Backspace **Spill-Back**, template/typography switching in the **Scholar's Stationery Chest** followed by continued typing, and **Staging Handscroll** / **Tucked Prints** interactions.
- **Test Surface Cleanup (Replace, Don't Layer)**:
  - Migrate the behavioral test cases from the standalone `StationeryDeltaSplitter` unit test file and direct `SheetMountResolver` test calls into the coordinator and partitioner test suites, and delete the standalone shallow splitter test file.

## Out of Scope

- Changing the visual appearance or layout math of the **Paper Heart**, **Heaven and Earth Margins**, **Double Outer Border**, or **Journal Letterhead** (covered by ADR-0006 and SPEC-011).
- Changing the 3-item per-sheet **Tucked Prints** capacity or the 15-item **Staging Handscroll** capacity (covered by ADR-0009 and SPEC-010).
- Refactoring `EditorChromeController`, `DeskSpaceBudget`, or `WritingFocusGuard` (separate deepening candidate).
- Refactoring `ThreadBoundFolioScreen` or PDF export rendering pipelines outside of any shared `EditorDeltaPartitioner` calls.

## Further Notes

- Every source file in the deepened module must remain strictly under the 450-line repository limit (`GEMINI.md` / `CODING_STANDARDS.md`) by organizing internal helpers behind `EditorPaginationCoordinator` and `EditorDeltaPartitioner`.
- All rich-text emptiness checks must continue to honor the **Rich-Text Document Structural Emptiness Invariant** (`document.length <= 1` rather than `.trim().isEmpty`), and controller disposal must honor **Active IME Controller Disposal Safety**.
