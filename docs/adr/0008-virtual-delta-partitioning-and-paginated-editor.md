# Virtual Delta Partitioning & Integer-Locked Pagination for Journal Sheets

## Context
Following the completion of the Thread-Bound Folio reading stage (ADR 0007), diary preview displays content in discrete, integer-locked paper leaves (14 horizontal lines or dedicated tipped-in photo leaves). However, the authoring canvas (`EntryEditorScreen`) previously wrapped the Quill rich-text editor in an unconstrained `SingleChildScrollView`.

This disparity created a significant WYSIWYG breakdown:
1. **Infinite Scroll vs. Discrete Leaves**: The diarist could scroll indefinitely downwards during writing, but upon tapping preview or saving, the content was partitioned into discrete, integer-snapped folio pages.
2. **Visual Inconsistency**: The Cinnabar Signature Seal was fixed at the bottom of the scroll view on every draft, often floating awkwardly outside or across outer borders.
3. **Media Insertion Ambiguity**: Inline media embeds had variable vertical heights in the editor, whereas the preview tipped them onto dedicated full-page leaves.

## Decision
We refactor `EntryEditorScreen` into a paginated authoring surface with **Virtual Delta Partitioning** and **Integer-Locked Stationery Sheets (`StationerySheet`)**:

1. **Unified Storage Invariant (Zero SQLite Schema Disruption)**:
   - Diary entries continue to be stored in SQLite as a single, continuous Quill Delta JSON string (`entries.content_delta`).
   - We reject splitting entries into multiple per-page database rows. Instead, the document is partitioned algorithmically and visually into discrete `StationerySheet` viewports based on line capacity and layout boundaries.
   - Preserves 100% compatibility with full-text search (`entries_fts`), offline backup/restore, autosave transactions, and undo/redo history.

2. **Integer Line Capacities (Sheet 1 vs. Sheet 2+)**:
   - **Sheet 1 (Opening Sheet)**: Hosts the interactive `JournalLetterhead` (Date, Mood, Weather, Title) at the top, occupying 4 rows within the Paper Heart, followed by **10 lines** of body text.
   - **Sheet 2+ (Continuation Sheets)**: Render a subtle running header colophon (`《题名》 · 第 X 页`) and host the full **14 lines** of body text, strictly matching the Folio preview's horizontal ruling grid.

3. **Auto-Spill & Deletion Spill-Back Flow**:
   - **Auto-Spill**: When typing crosses the bottom rule of the active sheet, a new sheet is automatically allocated, the viewport smoothly slides forward (~280ms ease-out cubic), and the cursor lands at line 1.
   - **Spill-Back**: Pressing backspace at line 1, column 0 of a continuation sheet merges content back into the previous sheet. If a continuation sheet becomes empty (0 characters and zero media), it auto-collapses without requiring manual deletion.

4. **WYSIWYG Tipped-In Ephemera Sheets**:
   - Inserting an image or video in the editor allocates a dedicated full-sheet ephemera mount (with photo preview, caption field, and delete button), pushing subsequent text to the next sheet, aligning 1:1 with `FolioTippedInEphemeraLeaf`.

5. **Center-Border Navigation Arrows & Page Badge**:
   - Subtle floating chevron buttons (`‹` on the left border, `›` on the right border) are positioned at the vertical center of the Journal Sheet.
   - A minimalist page counter badge (`第 1 / 3 页`) is docked at the bottom center of the canvas.

6. **Final-Sheet Cinnabar Seal Invariant**:
   - The animated Cinnabar Signature Seal lands strictly at the bottom-right colophon of the **final sheet**, and is repositioned to remain completely **within the page margins**, preventing any bleed past the outer frame border.

7. **Horizontal Authoring Invariant**:
   - The editor writes horizontally (`乌丝栏 · 横排`) to ensure 100% compatibility with native mobile IME keyboards (Pinyin, English) and selection handles, reserving classical vertical column formats (`朱丝竖排` / `原稿墨格`) for non-destructive contemplation in the preview stage.

## Consequences
- **True WYSIWYG Parity**: What the diarist drafts on page $N$ appears identically on page $N$ of the Thread-Bound Folio.
- **Zero Schema Migrations**: All pagination is calculated at the presentation layer; existing database tables remain unchanged.
- **60 FPS Performance**: Horizontal page sliding (`PageView`) avoids 3D transform recalculations during active keystrokes, protecting mobile keyboard responsiveness and IME stability.

