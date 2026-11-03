---
id: SPEC-008
title: Paginated Entry Editor, Discrete Stationery Sheets & Auto-Spill
status: completed
created_at: 2026-11-03T22:31:00+08:00
---

# Specification: Paginated Entry Editor, Discrete Stationery Sheets & Auto-Spill

## Problem Statement

With Phase 1 of the **Thread-Bound Folio** complete, reading a saved diary entry presents discrete, integer-locked leaves (14 horizontal lines per content leaf and dedicated full-page **Tipped-In Ephemera Leaves** for photos and videos). However, composing or editing that same entry in the active authoring canvas still relies on a single infinite vertical scroll view:

1. **Infinite Scroll vs. Discrete Folio Disparity**: As a diarist writes a long entry, the **Journal Sheet** stretches downward indefinitely rather than turning onto fresh sheets. What looks like one continuous scroll during writing is unexpectedly sliced into separate pages only after returning to the **Thread-Bound Folio** preview.
2. **Inline Media Height Ambiguity**: Inserting photos or videos embeds variable-height cards inline inside the scrolling text stream during editing, whereas the **Thread-Bound Folio** elevates each attachment onto its own dedicated illustration leaf, breaking 1:1 WYSIWYG predictability.
3. **Misplaced & Border-Overlapping Cinnabar Signature Seal**: In the current editor, the **Cinnabar Signature Seal** floats persistently at fixed screen coordinates near the bottom-right corner on every draft regardless of page position, visibly overlapping and poking outside the **Double Outer Border** of the **Paper Heart** instead of resting cleanly inside the colophon of the final page.
4. **Lack of Tactile Sheet Navigation**: Diarists reviewing or revising multi-page entries while editing have no page indicator or quick page-turn controls, forcing tedious vertical scrolling back and forth past the on-screen keyboard.

## Solution

Refactor the authoring canvas from an unbounded vertical scroll view into a discrete, horizontally paginated **Stationery Sheet** (`信笺书页`) workspace powered by virtual Quill Delta partitioning and **Auto-Spill** (`溢行分叶`), achieving 1:1 WYSIWYG parity with the **Thread-Bound Folio**:

1. **Unified Storage with Virtual Sheet Partitioning**:
   - Preserve the single continuous Quill Delta JSON string (`content_delta`) and segmented `plain_text` invariant in SQLite with zero schema migrations.
   - Partition the unified document virtually at the editor presentation layer into an ordered sequence of discrete **Stationery Sheets** rendered inside a smooth horizontal `PageView` (~280ms ease-out cubic transitions) that protects 60 FPS mobile keyboard and IME stability.
2. **Integer-Locked Sheet Capacities (Sheet 1 vs. Sheet 2+)**:
   - **Sheet 1 (Opening Sheet)**: Reserves the top 4 integer rows inside the **Paper Heart** for the interactive **Journal Letterhead** (date, weather, mood, and title), followed by **10 lines** of horizontal body text.
   - **Sheet 2+ (Continuation Sheets)**: Display a concise running header colophon (`《题名》 · 第 X 页`) and provide the full **14 lines** of horizontal body text matching the **Thread-Bound Folio** content leaf grid.
3. **Seamless Auto-Spill & Deletion Spill-Back**:
   - **Auto-Spill**: Typing past line 10 on Sheet 1 (or line 14 on Sheet 2+) automatically allocates a continuation **Stationery Sheet**, smoothly slides the viewport forward, and places the caret at line 1 of the new sheet without dropping keyboard focus.
   - **Spill-Back**: Pressing backspace at line 1, column 0 of a continuation sheet moves the caret and merges content back onto the preceding text sheet; trailing continuation sheets that become empty (0 characters and no media) collapse automatically.
4. **WYSIWYG Full-Sheet Ephemera Mounts**:
   - Inserting a photo or short video from the **Writing Dock** allocates a dedicated full-sheet ephemera mount featuring paper-toned matte framing, classical silk corner mounts, an editable caption field, and a remove action—pushing subsequent prose onto the next **Stationery Sheet** in 1:1 alignment with **Tipped-In Ephemera Leaves**.
5. **Center-Border Navigation Chevrons & Bottom Page Badge**:
   - Anchor subtle floating chevron pill buttons (`‹` on the left border, `›` on the right border) at the vertical center of the **Journal Sheet** margins, hiding boundary buttons when at the first or final sheet, paired with a compact page counter badge (`第 1 / N 页`) docked at the bottom center.
6. **Final-Sheet Bounded Cinnabar Signature Seal**:
   - Render the **Cinnabar Signature Seal** exclusively on the **final Stationery Sheet**, anchored cleanly inside the bottom-right corner of the **Paper Heart** (`innerFrameRect`) so it never overlaps or protrudes outside the **Double Outer Border**.

## User Stories

1. As a diarist opening a new or existing entry in the editor, I want the **Journal Sheet** presented as discrete, non-scrolling **Stationery Sheets** rather than an infinite vertical scroll strip, so that composing feels like writing on real leaves of stationery that match the **Thread-Bound Folio** preview.
2. As a diarist composing on Sheet 1, I want the editable **Journal Letterhead** (date, weather, mood, and title) snapped cleanly to the top 4 rows of the **Paper Heart** with 10 integer-locked body lines beneath it, so that front-matter and opening prose sit harmoniously on ruled baselines without overflowing the **Earth Margin**.
3. As a diarist continuing my thoughts onto Sheet 2 and beyond, I want each continuation **Stationery Sheet** to display a subtle running header (`《题名》 · 第 X 页`) and provide 14 full ruled lines of body text, matching the 14-line geometry of **Thread-Bound Folio** content leaves.
4. As a diarist typing continuously past the bottom line of Sheet 1 (line 10) or any continuation sheet (line 14), I want **Auto-Spill** to automatically create the next **Stationery Sheet**, glide horizontally to it, and place my cursor at line 1 without dismissing my mobile keyboard or interrupting Pinyin IME composition.
5. As a diarist pasting a multi-paragraph passage into a **Stationery Sheet**, I want any overflow lines distributed deterministically across as many continuation **Stationery Sheets** as needed, with the viewport advancing to the sheet containing my ending cursor position.
6. As a diarist pressing backspace at the very start (line 1, offset 0) of a continuation **Stationery Sheet**, I want my cursor and remaining text to spill back seamlessly onto the bottom of the previous text sheet, so editing across page boundaries feels natural and uninterrupted.
7. As a diarist deleting all text from a trailing continuation **Stationery Sheet**, I want the empty sheet to collapse and disappear automatically, updating the total sheet count immediately without forcing me to delete blank pages manually.
8. As a diarist reviewing a multi-sheet draft, I want subtle floating left (`‹`) and right (`›`) chevron buttons vertically centered near the left and right borders of the **Journal Sheet**, so I can flip between sheets with a single thumb tap without reaching into toolbars.
9. As a diarist on Sheet 1, I want the left border chevron (`‹`) hidden, and when on the final **Stationery Sheet**, I want the right border chevron (`›`) hidden, so visual affordances accurately reflect available adjacent sheets.
10. As a diarist swiping horizontally across the **Journal Sheet** when not dragging text selection handles, I want the editor to slide smoothly (~280ms ease-out cubic) between adjacent **Stationery Sheets** at 60 FPS.
11. As a diarist writing a multi-page entry, I want a compact page indicator badge (`第 X / N 页`) docked cleanly near the bottom center of the **Journal Sheet**, so I always know my current sheet position and total sheet count.
12. As a diarist inserting a photo from camera or gallery via the **Writing Dock**, I want the photo mounted on its own dedicated full-sheet ephemera page with classical silk corner mounts, an editable caption input, and a remove button, pushing subsequent prose onto the following **Stationery Sheet** to match **Tipped-In Ephemera Leaves** 1:1.
13. As a diarist inserting a short sandboxed video ($\le 60\text{s}$) via the **Writing Dock**, I want the video presented on its own dedicated full-sheet ephemera page with inline playback controls, caption editing, and removal support, preserving clean text baselines on surrounding **Stationery Sheets**.
14. As a diarist removing a photo or video ephemera sheet in the editor, I want the ephemera sheet removed cleanly, adjacent text sheets re-indexed, and the unified Quill Delta updated and autosaved immediately.
15. As a diarist viewing my **Stationery Sheets** while writing, I want the **Cinnabar Signature Seal** displayed exclusively on the final sheet—migrating automatically whenever **Auto-Spill** adds a new final sheet or empty-sheet collapse removes one—matching the **Thread-Bound Folio** colophon behavior.
16. As a diarist inspecting the bottom-right corner of the final **Stationery Sheet** across any phone width or template, I want the **Cinnabar Signature Seal** positioned strictly inside the **Paper Heart** (`innerFrameRect`) with comfortable inset clearance from the **Double Outer Border**, never overlapping or bleeding outside the frame lines.
17. As a diarist formatting text (bold, italic, underline, strikethrough, headings, blockquotes, lists, checklists, ink colors, or `〘注〙` **Interlinear Sub-Notes**) from the **Writing Dock**, I want formatting actions to apply to whichever **Stationery Sheet** currently holds focus and persist losslessly into the unified Quill Delta.
18. As a diarist switching templates or adjusting font size / line spacing inside the **Scholar's Stationery Chest**, I want the **Paper Heart** metrics and **Stationery Sheet** line wrapping to recompute live across all sheets while keeping my underlying text and attachments 100% intact.
19. As a diarist using voice dictation or adopting a rotating **Thought Spark** prompt (`由此题落墨`), I want dictated or inserted text appended at my active sheet cursor and subject to the same seamless **Auto-Spill** pagination when crossing sheet line limits.
20. As a privacy-first user relying on offline FTS5 search, **Keepsake Scroll View**, PDF export, `.txt`/`.md` export, and encrypted `.memodiary` backups, I want all multi-sheet edits saved into the single canonical `entries.content_delta` and `entries.plain_text` columns so every downstream subsystem works with zero schema changes or regressions.

## Implementation Decisions

### 1. Virtual Delta Partitioning & Paginated Sheet Coordinator
- Retain the single canonical Quill Delta (`content_delta`) and segmented `plain_text` storage contract in SQLite with zero database schema changes, respecting ADR 0008.
- Introduce a dedicated pagination coordinator (`EditorPaginationCoordinator`) that bridges the unified Quill Delta document and an ordered list of presentation-layer sheet descriptors (`StationerySheetDescriptor`):
  - **Opening Text Sheet Descriptor (Sheet 1)**: Hosts the editable **Journal Letterhead** (snapped to 4 integer rows) followed by a horizontal rich-text editor slice capped at **10 integer rows** (`kOpeningSheetRowCapacity = 10`, accounting for `H1`/`H2` occupying 2 rows per line and `H3`/body/quote occupying 1 row per line).
  - **Continuation Text Sheet Descriptor (Sheet 2+)**: Hosts a compact 1-row running colophon header (`《<Title or 无题>》 · 第 <X> 页`) above the **Paper Heart** (or in the **Heaven Margin**) and a horizontal rich-text editor slice capped at **14 integer rows** (`kContinuationSheetRowCapacity = 14`).
  - **Ephemera Sheet Descriptor**: Represents an embedded image or video `BlockEmbed` (along with optional caption metadata via `MediaEmbedData`), occupying an entire dedicated sheet between preceding and succeeding text sheets.
- Whenever any text sheet controller mutates, an ephemera caption changes, or an attachment is inserted/removed, the coordinator deterministically re-synthesizes the unified canonical Quill Delta and plain text and notifies the existing autosave pipeline.
- Bind **Writing Dock**, voice dictation, and **Thought Spark** prompt insertion dynamically to the `QuillController` of the currently active text sheet (if the user invokes a text-insertion action while viewing an ephemera sheet, allocate or focus the immediately following text sheet and insert there).

### 2. Deterministic Line Measurement, Auto-Spill & Spill-Back Mechanics
- Measure wrapped visual line counts per paragraph inside each text sheet using deterministic `TextPainter` layout (matching the active `TypographySettings`, dynamic grid `letterSpacing`, `StrutStyle` line stride, and horizontal **Paper Heart** inner width) rather than brittle fixed character-count heuristics alone, while keeping a safe fallback character-per-row estimator when layout width is unconstrained.
- **IME Composition Guard**: Defer **Auto-Spill** redistribution while an active IME composing range (`value.composing.isValid && !value.composing.isCollapsed`, such as unfinished Pinyin syllables) is in flight; trigger **Auto-Spill** immediately once composition commits or a newline/character pushes committed visual rows past sheet capacity (`10` on Sheet 1, `14` on Sheet 2+).
- **Auto-Spill Transition**:
  - Split the overflowing trailing text/Delta operations at the exact line or paragraph boundary that exceeded sheet capacity and prepend them onto the next text **Stationery Sheet** (creating one if the current sheet was final or followed by an ephemera sheet).
  - Animate the horizontal `PageController` to the target sheet over `280ms` (`Curves.easeOutCubic`) and request focus on the destination `QuillController` with the caret positioned accurately relative to the spilled text.
- **Spill-Back & Auto-Collapse**:
  - Intercept backspace key/input deletion when the caret sits at offset `0` of a continuation text sheet: pull the caret (and any remaining lines that fit within the preceding text sheet's remaining row budget) back onto the end of the nearest preceding text sheet and slide the `PageController` backward.
  - Automatically prune trailing or intermediate empty continuation text sheets (`plainText.trim().isEmpty` and sheet index `> 0`) as long as at least one text sheet (Sheet 1) remains, keeping sheet numbering contiguous without manual page deletion.

### 3. Stationary Sheet Geometry, Ephemera Sheet & Bounded Cinnabar Seal
- Replace the unbounded `SingleChildScrollView` in the editor screen with a bounded single-viewport `PageView.builder` where each **Stationery Sheet** computes fixed single-page `StationeryLayoutMetrics` sized to the visible sheet viewport (`scrollOffset: 0.0`), eliminating scrolling phase drift.
- Constrain the **Paper Heart** (`innerFrameRect`) on each text sheet to match the sheet's exact row geometry (14 total rows inside the frame: 4 letterhead rows + 10 prose rows on Sheet 1; 14 prose rows on Sheet 2+) so horizontal baselines never overflow into the **Earth Margin**, including when the software keyboard insets the viewport (allowing compact internal scrolling only within the active sheet's clipped **Paper Heart** when the on-screen keyboard temporarily shrinks visible height below full sheet height, never scrolling infinitely across pages).
- Render full-sheet ephemera mounts inside the **Paper Heart** with paper-toned matte borders, classical silk corner mounts, inline video playback (for video embeds), an editable single/two-line caption input synchronized to `MediaEmbedData`, and a scoped accessible delete button.
- Render the **Cinnabar Signature Seal** (`CinnabarSignatureSeal`) exclusively when `sheetIndex == totalSheets - 1`, positioned strictly inside `metrics.innerFrameRect` (inset by `12px` from `innerFrameRect.right` and `12px` from `innerFrameRect.bottom`) so its bounding box never crosses or overlaps the **Double Outer Border**.

### 4. Center-Border Navigation Chevrons & Bottom Page Indicator
- Overlay two translucent, paper-adaptive floating chevron pill buttons vertically centered along the left and right canvas edges:
  - Left chevron (`‹`, `Key('editor_prev_sheet_btn')`, semantic label `'上一页 · Previous Sheet'`): visible and enabled only when `currentSheetIndex > 0`.
  - Right chevron (`›`, `Key('editor_next_sheet_btn')`, semantic label `'下一页 · Next Sheet'`): visible and enabled only when `currentSheetIndex < totalSheets - 1`.
- Dock a compact, non-intrusive page counter pill (`第 ${currentSheetIndex + 1} / $totalSheets 页`, `Key('editor_sheet_indicator')`) centered near the bottom **Earth Margin** with clamped text scaling (`<= 1.2`).
- Decompose all new and refactored editor modules cleanly so every production file—including the refactored `EntryEditorScreen`—resides strictly below the 450-line modularity ceiling.

## Testing Decisions

### What Makes a Good Test
- Test observable external behaviors, rendered geometry bounds, interactive navigation state, and persisted SQLite `content_delta` / `plain_text` round-trip fidelity rather than private controller fields or internal buffer state.
- Ensure every source file passes the `< 450` LOC modularity audit, uses descriptive domain identifiers (zero single-letter lambda parameters), clamps toolbar/badge text scaling, and guards animations so widget tests settle deterministically.

### Seams & Modules Tested
1. **Top-Level Interactive Editor Seam (`EntryEditorScreen` + In-Memory `AppDatabase`)**:
   - **Discrete Sheet Rendering**: Open an empty entry and verify Sheet 1 renders **Journal Letterhead**, `QuillEditor`, and `第 1 / 1 页` badge with both left and right border chevrons hidden and zero unbounded scroll views.
   - **Auto-Spill on Line Overflow**: Enter > 10 lines of text on Sheet 1; verify **Auto-Spill** allocates Sheet 2, advances the active page to `第 2 / 2 页`, displays the running colophon header (`《<Title>》 · 第 2 页`), shows the left border chevron (`‹`), and keeps overflowing text on Sheet 2. Enter > 14 lines on Sheet 2 and verify spill onto Sheet 3 (`第 3 / 3 页`).
   - **Spill-Back & Empty Sheet Collapse**: Delete text on a trailing continuation sheet and trigger backspace at offset `0`; verify the empty continuation sheet collapses automatically, returning total sheet count from 2 to 1 and hiding border chevrons.
   - **Center-Border Chevron Navigation**: Populate a 3-sheet entry, tap `editor_prev_sheet_btn` (`‹`) and `editor_next_sheet_btn` (`›`), and assert smooth sheet transitions, accurate visibility of boundary chevrons, and matching `editor_sheet_indicator` text.
   - **WYSIWYG Ephemera Sheet Lifecycle**: Insert a sandboxed image and video; verify dedicated ephemera sheets are allocated with editable captions and delete actions, pushing subsequent text onto continuation sheets, and verify deleting the ephemera sheet restores contiguous sheet indexing.
   - **Final-Sheet Cinnabar Seal Containment**: Across 1-sheet and multi-sheet entries on narrow (`360px`) and standard viewports, assert `CinnabarSignatureSeal` is absent on non-final sheets, present on the final sheet, and its rendered `Rect` is 100% contained within `metrics.innerFrameRect` (zero protrusion past the **Double Outer Border**).
   - **Unified SQLite & Folio Preview Round-Trip**: Trigger autosave / save-and-exit on a multi-sheet rich-text + media entry, verify SQLite `entries.content_delta` stores a single valid continuous Quill Delta JSON array, and re-open both `EntryEditorScreen` and `EntryDetailScreen` (**Thread-Bound Folio**) to verify 100% lossless content and formatting parity.
2. **Pure Virtual Delta Partitioner Seam (`EditorPaginationCoordinator` / Sheet Partitioner)**:
   - Unit-test lossless round-trip partitioning and re-merging across multi-sheet splits containing bold/italic/underline/color inline attributes, `H1`/`H2`/`H3` headings (verifying 2-row vs. 1-row weight accounting), `{夹注:...}` **Interlinear Sub-Notes**, emoji surrogate pairs, Pinyin IME composition deferral, and interleaved image/video `BlockEmbed` nodes.

### Prior Art
- Existing full-bleed `EntryEditorScreen` widget test suite exercising **Journal Letterhead**, **Writing Dock**, **Scholar's Stationery Chest**, and sandboxed media insertion against an in-memory Drift database.
- Existing **Paper Heart** layout geometry tests (`StationeryLayoutCalculator` and `IntegerSnappedLetterhead`) asserting pixel-exact `innerFrameRect` containment and integer stride multiples.
- Existing **Thread-Bound Folio** pagination unit and widget tests (`FolioPaginationEngine` and `EntryDetailScreen`) verifying 14-row horizontal leaves and **Tipped-In Ephemera Leaves**.

## Out of Scope

- Splitting diary entries into multiple relational rows or separate per-page JSON columns in SQLite (explicitly rejected per ADR 0008 to preserve zero-migration compatibility with FTS5 search, exports, and encrypted backups).
- Live vertical (`vertical-rl`) text input inside the active editor (authoring remains strictly horizontal `乌丝栏 · 横排` for native mobile keyboard/IME stability; vertical contemplation lives in **Thread-Bound Folio** **Reading Perspectives** and **Keepsake Scroll View**).
- 3D cylindrical `Matrix4` page-curl physics inside the active typing canvas (reserved for the read-only **Thread-Bound Folio** stage so active typing and on-screen keyboard layout remain jitter-free at 60 FPS).
- Cloud sync, remote telemetry, or paid third-party editor SDKs ($0 FOSS, 100% offline invariant).

## Further Notes

- Respects **ADR 0003** (Full-Bleed Journal Sheet & Minimalist Writing Dock), **ADR 0006** (Synchronized Paper Heart Geometry & Double Outer Border), **ADR 0007** (Thread-Bound Folio Preview & Reading Perspective), and **ADR 0008** (Virtual Delta Partitioning & Integer-Locked Pagination for Journal Sheets).
- Refactoring `EntryEditorScreen` during this phase also brings `entry_editor_screen.dart` cleanly under the strict `< 450` LOC file-size ceiling enforced by `code_style_audit_test.dart`.
