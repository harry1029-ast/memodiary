---
id: SPEC-010
title: Staging Handscroll, Brush Reveal & Text-Anchored Sheet Mounting
status: ready-for-agent
created_at: 2026-11-05T00:00:00+08:00
adr: ADR-0009
---

# Specification: Staging Handscroll, Brush Reveal & Text-Anchored Sheet Mounting

## Problem Statement

When I attach a photo or video while writing, the editor drops it onto whichever Stationery Sheet I happen to be on, with no deliberate choice about where it belongs. Worse, that placement is not remembered: when I reopen the entry, my photos are redistributed first-come across the sheets, so a photo I attached beside the third page of my story reappears on the first. When I add or remove lines earlier in the entry, the text reflows across sheets but the photos do not follow the passage they illustrate. The Thread-Bound Folio and PDF export pair photos with leaves purely by order, so the preview can disagree with what I saw while writing.

The current media carousel also feels like a generic gallery rather than part of a scholar's desk. Attaching a keepsake has no sense of ceremony, and captions I type are stored alongside OCR-recognised text, so they leak into photo search results.

## Solution

The entry editor gains a **Staging Handscroll** (待贴画卷): one entry-wide handscroll resting on a dark walnut desk workstation below the Stationery Sheets. Every photo or video I **Collect** is painted into the handscroll by a one-time **Brush Reveal** (泼墨显影) — a bamboo brush sweeps splash-ink strokes that uncover the item in monochrome ink wash before it blooms into full colour.

From the handscroll, I deliberately **Mount** each item onto the sheet it belongs to, either by long-press dragging it onto the sheet or by tapping its 📌 贴至本页 button. Each sheet shows its mounted items (up to 3) in a **Sheet Mount Strip** (本页影札栏) just outside its Paper Heart, so mounting never changes the sheet's line capacity. A mounted item remembers the passage of text it was mounted beside and follows that passage through reflow, reloads, the Folio preview and PDF export. I can **Unmount** an item back to the handscroll, or erase it permanently from the handscroll with an ink-wash dissolve and an undo option.

When the handscroll is empty it rests closed as a brocade-wrapped scroll, inviting me to collect a keepsake. If I leave the entry with items still waiting in the handscroll, I am reminded and can keep them for later, discard them, or stay to finish mounting.

## User Stories

### Collecting into the Staging Handscroll

1. As a diarist, I want photos and videos I pick to land in a single entry-wide Staging Handscroll, so that I can gather keepsakes first and decide where they belong afterwards.
2. As a diarist, I want each newly collected item to be painted in by a brush with splash-ink strokes, so that adding a keepsake feels like a ceremonial act on a scholar's desk.
3. As a diarist, I want a collected item to first appear as monochrome ink wash and then bloom into full colour, so that the reveal echoes a painting coming to life.
4. As a diarist, I want a collected video to receive a cinnabar seal play stamp once its reveal finishes, so that I can tell videos from photos at a glance.
5. As a diarist, I want the Brush Reveal to play only once, at the moment I collect an item, so that reopening the entry, turning pages or unmounting never makes me sit through it again.
6. As a diarist who has enabled the system reduce-motion setting, I want collected items to appear directly in full colour without the brush animation, so that the editor respects my accessibility preference.
7. As a diarist, I want to pick several photos at once and see them painted in one after another, so that bulk collecting still feels orderly.
8. As a diarist, I want the handscroll to glide to a newly collected item before its reveal begins, so that I always see the item being painted.
9. As a diarist, I want the handscroll to scroll sideways with about three slots visible, so that it can hold many keepsakes without crowding the desk.
10. As a diarist, I want the handscroll to hold at most 15 items and tell me "画卷已满 15 影" when it is full, so that I understand why a new item was refused.
11. As a diarist, I want a multi-pick that exceeds the remaining room to collect as many as fit and tell me how many were left out, so that nothing is silently dropped.
12. As a diarist, I want collected items to read left to right in the order I collected them, so that the handscroll matches the direction of my writing.
13. As a diarist, I want collected items to be sandboxed, compressed and stored exactly as attachments are today, so that privacy and storage guarantees are unchanged.

### The closed scroll and the workstation

14. As a diarist, I want an empty handscroll to rest closed as a brocade-wrapped scroll on the desk, so that the workstation still looks inviting when I have no media.
15. As a diarist, I want tapping the closed scroll to start collecting, so that the empty state doubles as an obvious entry point.
16. As a diarist, I want the walnut desk and bamboo mat to frame only the workstation area while the rest of the editor keeps its light paper look, so that the editor's identity stays familiar.
17. As a diarist, I want to collapse and restore the workstation with the existing footer handle, so that I can give my writing the full screen when I choose.
18. As a diarist, I want the workstation and every Sheet Mount Strip to collapse automatically while the software keyboard is open and return when it closes, so that I can always see the lines I am typing.
19. As a diarist on a short phone, I want the workstation to start collapsed when there is not enough room for it, so that the Stationery Sheet is never squeezed.
20. As a diarist, I want the workstation to take the remaining vertical space (at least about 150dp when open, about 110dp when showing the closed scroll), so that it adapts to my device instead of overflowing.

### Mounting onto a sheet

21. As a diarist, I want to long-press a handscroll item and drag it onto the active Stationery Sheet to mount it, so that placing a keepsake feels physical.
22. As a diarist, I want the sheet to highlight as a drop target while I drag, so that I know where the item will land.
23. As a diarist, I want a 📌 贴至本页 button on each handscroll item that mounts it onto the active sheet, so that I can mount without dragging and so the action is reachable with a screen reader.
24. As a diarist, I want mounting to move the item out of the handscroll, so that each keepsake lives in exactly one place.
25. As a diarist, I want each sheet to hold at most three mounted items, so that photos never overwhelm my prose.
26. As a diarist, I want a mount onto a full sheet to be refused with a gentle shake and a message, so that I understand the limit and the item stays in the handscroll.
27. As a diarist, I want mounted items to appear in a Sheet Mount Strip outside the sheet's Paper Heart, so that mounting a photo never pushes my text onto the next sheet.
28. As a diarist, I want a sheet with no mounted items to show no strip at all, so that text-only sheets keep their calm, centred layout.
29. As a diarist, I want a sheet's mounted items to appear in the order I mounted them, so that the strip is predictable.
30. As a diarist, I want mounting onto an empty sheet to work, so that I can place a photo before writing its accompanying text.

### Unmounting and deleting

31. As a diarist, I want a ↩ button on each mounted item that returns it to the handscroll, so that I can change my mind about where it belongs.
32. As a diarist, I want the Sheet Mount Strip to offer no delete button, so that I cannot accidentally destroy a placed keepsake.
33. As a diarist, I want a ✕ button on each handscroll item that permanently erases it with an ink-wash dissolve, so that discarding feels in keeping with the desk.
34. As a diarist, I want an undo option in a snackbar right after erasing an item, so that a mistaken tap is recoverable without a confirmation dialog.
35. As a diarist, I want an erased item's attachment record and sandboxed file to be removed once the undo window passes, so that no ghost attachments resurface later.
36. As a diarist, I want erasing or unmounting an item to leave the rest of the handscroll in place without replaying the unroll animation, so that the desk feels stable.

### Following the text

37. As a diarist, I want a mounted item to stay with the passage of text it was mounted beside when I add or delete lines earlier in the entry, so that photos keep illustrating the right words.
38. As a diarist, I want my mounted items to stay on the same passage after I close and reopen the entry, so that my placement is truly remembered.
39. As a diarist, I want an item whose passage I delete to return to the handscroll rather than being deleted, so that editing text never destroys media.
40. As a diarist, I want undoing that text deletion to remount the item, so that undo restores exactly what I had.
41. As a diarist, I want copying and pasting text never to duplicate a mounted item, so that one keepsake is never shown twice.
42. As a diarist, I want reflow that brings a fourth item onto a sheet to show the extra on the following sheet, so that no sheet ever exceeds three items.
43. As a diarist, I want an extra item that would overflow the last sheet to return to the handscroll with a message, so that I am never given an empty photo-only sheet.
44. As a diarist, I want the hidden anchors that track my mounted items to be invisible and take no line space, so that my writing looks exactly as before.
45. As a diarist, I want those hidden anchors to never appear in search results or word counts, so that search reflects only what I wrote.

### Tapping, captions and accessibility

46. As a diarist, I want tapping any item in the handscroll or a Sheet Mount Strip to open it in the fullscreen lightbox, so that I can view it large.
47. As a diarist, I want to edit an item's caption in the lightbox, so that there is one obvious place for captions.
48. As a diarist, I want my captions stored separately from OCR-recognised text, so that captions do not pollute photo text search and OCR text does not overwrite captions.
49. As a diarist, I want my existing captions to survive the upgrade, so that nothing I typed is lost.
50. As a diarist using a screen reader, I want every handscroll and strip control (📌, ↩, ✕, the closed scroll, the drop target) to have a meaningful label, so that I can collect, mount and unmount without sight.
51. As a diarist, I want every control to be at least 44×44 and captions to be legible, so that the desk is comfortable to use on a phone.

### Leaving the editor

52. As a diarist, I want to be reminded when I leave the editor (via ← or ✓) with items still in the handscroll, so that I do not forget unmounted keepsakes.
53. As a diarist, I want that reminder to offer 留在画卷 (keep, the default), 舍弃待贴 (discard) and 继续装裱 (stay), so that I can choose without losing work by accident.
54. As a diarist, I want kept items to be waiting in the handscroll when I reopen the entry, already in full colour, so that I can finish mounting later.
55. As a diarist, I want leaving with an empty handscroll to show no reminder, so that the common case stays frictionless.

### Reading, export and existing entries

56. As a diarist, I want the Thread-Bound Folio to show each mounted item on the leaf whose text it was mounted beside, so that the preview matches the editor.
57. As a diarist, I want the Frontispiece showcase to use the items mounted on the first sheet, so that the cover reflects my deliberate choice.
58. As a diarist, I want content leaves' ephemera overlay cards to show that leaf's mounted items, so that existing overlay placement keeps working.
59. As a diarist, I want items still waiting in the handscroll to be left out of the Folio and PDF export, so that only placed keepsakes are published.
60. As a diarist, I want the PDF export to pair media with leaves exactly as the Folio does, so that exported diaries match what I previewed.
61. As a diarist with existing entries, I want my current attachments to be mounted automatically the first time I open each entry, using the same placement I see today, so that upgrading does not dump everything into the handscroll.
62. As a diarist with existing entries that contain inline photo or video embeds, I want them to keep rendering as before, so that old entries look unchanged.
63. As a diarist, I want the Staging Handscroll to be the only way to add new media in the editor, so that there is one clear way to place a keepsake.
64. As a diarist, I want backup and restore to preserve which sheet passage each item is mounted on and which items are still staged, so that a restored diary is identical.

## Implementation Decisions

### Domain model (per ADR-0009)

- **Mounting is anchored in the Delta.** Mounting inserts an invisible, zero-height custom embed (a "mount marker") into the entry's single continuous Quill Delta at the end of the active sheet's text (position 0 of the sheet if it is empty). The marker carries only the referenced `media_attachments` id.
- **The Delta is the single source of truth.** There is no `sheet_index`, `is_mounted` or similar column. An attachment is mounted if and only if a marker references it; an attachment with no marker is staged in the Staging Handscroll.
- **Order.** Items on a sheet render in marker order, which equals mount order because each mount appends at the end of the sheet's text.
- **Overflow.** When reflow places more than three markers on a sheet, the extras render on the following text sheet (cascading). Extras that would overflow the final sheet are unmounted: their markers are removed and the items return to the handscroll, with a snackbar. No sheet is ever allocated solely to host media.
- **Marker lifecycle.** Deleting text containing a marker unmounts the item (marker removed, attachment kept). Undo/redo restores or removes markers with the text. A mount is itself a document change, so undo right after a 📌 mount reverts the mount. Clipboard copy and paste strip markers. Markers are excluded from `plain_text`, word counts and FTS indexing. Markers referencing a missing attachment are stripped on save.
- **Mount semantics.** Mount moves an item from the handscroll to a sheet; an item is on at most one sheet. Unmount removes the marker and returns the item to the handscroll. Moving between sheets is Unmount → turn page → Mount; there is no direct sheet-to-sheet drag.
- **Delete semantics.** ✕ exists only on handscroll items. Deletion plays the ink-wash erase, shows an undo snackbar (hide the current snackbar first), and on expiry purges the `media_attachments` row and the sandboxed file, honouring Bidirectional Media Lifecycle Parity.

### Modules

- **Staging Handscroll widget (new).** Replaces `StationeryMediaTray` as the editor's media surface (Displacement over Coexistence: remove the old tray and migrate its tests). Hosts the walnut workstation, bamboo mat, open handscroll (cylinders, ebony weights, silk canvas, intro colophon) and closed brocade scroll states. Horizontally scrollable, ~3 slots visible, capacity 15 for new collects (returning items may exceed it). Exposes collect, mount (📌), delete (✕) and tap-to-lightbox callbacks; contains no database access.
- **Brush Reveal painter (new).** A `CustomPainter`-based reveal that erases an opaque silk-paper cover with five splash-ink sweeps (`BlendMode.dstOut` inside a saved layer, plus a wet-ink halo), animates a bamboo brush with kinematic lag and procedurally bent bristles, then fades the cover and animates a grayscale→colour filter. Static paper/handscroll geometry is recorded once into a `ui.Picture`; the brush and mask are a separate 60 FPS painter; each file stays under 450 lines. Driven by an `AnimationController` that is skipped when `MediaQuery.disableAnimations` is true and that only paints on-screen slots. Videos receive the cinnabar seal stamp after reveal.
- **Sheet Mount Strip widget (new).** Renders a sheet's mounted items outside its Double Outer Border, between the sheet and the workstation, with ↩ per item and a drag target highlight. Hidden when the sheet has no items, so SPEC-009's text-only centering still applies.
- **`EditorDeltaPartitioner` (modified).** Resolves mount markers to sheets during partitioning, applies cascading overflow and last-sheet unmount, strips orphan markers, and replaces the current first-fit attachment distribution. Reports staged (unanchored) attachments separately.
- **`EditorPaginationCoordinator` (modified).** `attachMediaToActiveSheet` is replaced by collect / mount / unmount / delete operations that edit the Delta (insert/remove markers) and notify listeners. Enforces the per-sheet cap of 3 and the handscroll cap of 15. The handscroll cap applies to Collect only: Unmount, erase-undo and reflow unmounts always return their items, even past 15, because refusing them would lose media.
- **Media pick actions (modified).** Image and video picks Collect into the handscroll rather than attaching to the active sheet. Multi-pick truncates to remaining capacity and reports the remainder. Inline embed insertion and dedicated photo-only sheets are removed as authoring paths; existing inline embed builders remain for rendering legacy content.
- **Legacy mounting pass (new, Dart).** On first open of an entry whose attachments have no markers, mount them using the current first-fit rule and write markers into the Delta. Idempotent; runs once per entry. Overflow on a legacy entry's last sheet is tolerated on open (`toleratedOverflowIds`) and unmounted only by later edits, so a legacy last sheet may show more than three items until edits make room.
- **Exit guard (modified editor screen).** On ← and ✓, when the handscroll is non-empty, show a dialog: 留在画卷 (default, leave and keep), 舍弃待贴 (erase staged items, then leave), 继续装裱 (stay).
- **Keyboard and space budget (modified editor canvas).** Workstation and Sheet Mount Strips collapse while the keyboard is open (extending SPEC-009). Workstation height = remaining space, minimum ~150dp open / ~110dp closed scroll; starts collapsed when the minimum does not fit. The existing footer handle toggles it.
- **`FolioPaginationEngine` and PDF export (modified).** Pair media with leaves via markers instead of order: Frontispiece showcase uses sheet 1's mounted items; content leaves' ephemera overlay cards use that leaf's mounted items; staged items are excluded. Existing `overlay_x_ratio` / `overlay_y_ratio` behaviour is unchanged. Pairing follows the editor's sheet partition computed without the measured sheet width, so it is approximate for long wrapped paragraphs. No Folio leaf or PDF page shows more than three items: sheet N rides on leaf N, sheets past the last leaf fold onto it, and items past a leaf's three move to the nearest earlier leaf with room, else the nearest later one (items with no room on any leaf are left out).
- **Lightbox (modified).** `FullscreenMediaLightbox` becomes the only caption editor, writing to the new `caption` column.

### Schema (schema version 6 → 7)

- Add nullable `caption` (TEXT) to `media_attachments`.
- Migration moves non-empty `ocr_text` into `caption` only for rows where `ocr_blocks_json IS NULL` or `'[]'` (the pre-v7 in-app caption editor wrote captions with empty blocks; real OCR text always carries blocks, and the OCR Sentinel has empty text); moved rows have `ocr_text` and `ocr_blocks_json` reset to NULL, so old captions leave photo search and the photos are queued for OCR backfill. Rows with OCR data keep `ocr_text` as OCR and get a null caption. Pre-v7 backups are restored with the same rule. `media_fts` continues to index `ocr_text` only.
- No column records mounting; anchoring lives in `entries.content_delta`.
- Backup manifest and restore carry the new column; mount markers travel inside the Delta.

### Interaction details

- Drag uses long-press-to-drag from a handscroll slot onto the active sheet; the 📌 button is the accessible equivalent with a semantic label naming the item and target sheet.
- All controls are at least 44×44 logical pixels with scoped `Semantics`; caption text is legible (no 8–10px text from the prototype); toolbars and ribbons clamp text scale per CODING_STANDARDS.
- Snackbars: full sheet ("本页已满三影"), full handscroll ("画卷已满 15 影"), multi-pick truncation, last-sheet overflow unmount, and erase-with-undo. Always hide the current snackbar before showing a new one.
- Unroll animation plays when the handscroll first opens from closed; mounting, unmounting, deleting and page turns update slots in place without replaying it.

## Testing Decisions

### What makes a good test

- Test observable behaviour only: what is rendered, which sheet shows which item, what the handscroll contains, what is persisted and what the Folio produces. Never assert on private controller fields or marker internals beyond the persisted Delta round-trip.
- Animations are pumped with bounded `tester.pump(duration)` steps; the Brush Reveal must also be verifiable with reduce-motion enabled (no animation, immediate full colour).
- Use synchronous `dart:io` fixtures and the shared doubles in the editor test harness (`SyncTestMediaSandboxService`, `StubEditorImagePicker`, `FakeEditorVideoPlatform`).
- Round-trip tests verify deep field parity (Delta content, attachment rows including `caption`) after save and reopen, not just counts.

### Seams

1. **Editor screen (`EntryEditorScreen` via the shared editor harness)** — primary seam:
   - Collecting one and several items shows them in the handscroll in order; reveal completes; reduce-motion skips it; video gets the seal stamp.
   - Handscroll cap of 15 refuses with a snackbar; multi-pick truncation reports the remainder.
   - Mount via 📌 and via long-press drag moves the item to the active sheet's Mount Strip; full sheet refuses with feedback and the item remains staged.
   - Unmount returns the item; erase removes it, undo restores it, expiry purges the attachment and file.
   - Typing above a mounted passage reflows text and the item stays with its passage on the new sheet; deleting the passage unmounts it; undo remounts it.
   - Reflow creating a fourth item cascades it to the next sheet; overflow at the last sheet unmounts it to the handscroll.
   - Save, leave and reopen preserves mounts and staged items (staged items appear without replaying the reveal).
   - Exit guard appears on ← and ✓ only when items are staged, and each choice behaves as specified.
   - Keyboard open collapses workstation and strips; closed scroll shows and starts collecting when tapped; short viewport starts collapsed.
2. **`EditorDeltaPartitioner`** (pure Dart) — marker-to-sheet resolution, cascading overflow, last-sheet unmount, orphan marker stripping, legacy first-fit mounting pass idempotency, and markers excluded from plain text.
3. **`FolioPaginationEngine`** — marker-based pairing for the Frontispiece and content leaves; staged items excluded; parity with the editor's sheet assignment.
4. **Schema v7 migration** — `caption` column added; captions copied only from rows without `ocr_blocks_json`; `media_fts` unaffected.

### Prior art

- Editor screen and media tray: `split_desk_media_tray_test`, `split_desk_centering_test`, `paginated_editor_stage_test`, `paper_heart_freeze_repro_test` (auto-spill and keyboard harness), `stationery_sheet_enter_spill_test`.
- Editor ↔ Folio parity: `paginated_editor_ephemera_and_folio_test`.
- Folio engine: `folio_pagination_engine_test`.
- Migrations: `schema_v3_migration_test` through `schema_v6_migration_test`.

## Out of Scope

- The other five prototype tray layouts (手卷展读, 藏影封套, 多宝阁, 立轴装裱, 经折展卷).
- The carved cinnabar lunar date seal, vertical weather/mood tags, curling page-corner navigation, silk bookmark pagination, paper ruling cycling, and the header "收起画案" toggle / restore pill — deferred to a later spec.
- Synthesized or bundled sound effects.
- Walnut desk extending beyond the workstation, or desk theming that follows the template.
- Brush Reveal replay controls (per-slot 🖌️ and toolbar 重演挥毫).
- Right-to-left handscroll reading order.
- Reordering items within a Sheet Mount Strip, or direct drag between sheets.
- Migrating legacy inline embeds into mounted items.
- Editing captions anywhere other than the lightbox.

## Further Notes

- Design reference: prototypes `memodiary_canvas_layout_benchmark_2.html` (Brush Reveal choreography, handscroll artefacts) and `memodiary_canvas_layout_benchmark_3.html` (entry-wide staging handscroll, mount/unmount, in-place erase). The prototypes' fixed 30px line stride, per-page titles, 3-item handscroll cap and silent drop-on-full behaviour are intentionally not carried over.
- The prototype's Brush Reveal parameters are a good starting point: five quadratic Bézier sweeps per slot (~175ms each, radii ~22–28 at slot scale), brush lag factor ~0.24, tilt clamped to ±28°, cover fade ~550ms, then a ~260ms delay before the video seal stamp.
- Vocabulary follows GLOSSARY.md: Staging Handscroll, Sheet Mount Strip, Collect, Mount / Unmount, Brush Reveal. Avoid "Media & Keepsake Tray" (SPEC-009's name for what is now the Sheet Mount Strip).
- `$0` FOSS invariant holds: Flutter painters, gestures and existing packages only.
