---
id: SPEC-011
title: Scholar's Desk Chrome, Lunar Letterhead & Tucked Prints
status: ready-for-agent
created_at: 2026-11-10T00:00:00+08:00
adr: ADR-0009
---

# Specification: Scholar's Desk Chrome, Lunar Letterhead & Tucked Prints

## Problem Statement

Since SPEC-010 the entry editor rests on a walnut Scholar's Desk, but several parts of it still feel like a generic app rather than a scholar's stationery:

- When a sheet has mounted photos, its Sheet Mount Strip squeezes the Desk Workstation down to its 110px minimum. The Staging Handscroll's thumbnails become too small to recognise, and their 📌 / ✕ controls cover them.
- While I type, the software keyboard and the Writing Dock together still hide about two rows at the bottom of the Stationery Sheet (confirmed on a phone).
- The Journal Letterhead's date line ("2026年11月6日 星期…") is cut off, its lunar wording is not a real lunar date, and its weather and mood chips look like form controls.
- Page turns use plain side chevrons that sit over the sheet.
- The footer handle above the Writing Dock collapses the *workstation*, not the dock it sits on, and there is no way to put the Writing Dock away.
- The desk has a single walnut look that ignores the app's dark appearance.

## Solution

The editor becomes a calmer, more tactile scholar's desk:

- **Tucked Prints** (夹页影札) replace the Sheet Mount Strip. A sheet's mounted photos and videos are slipped behind its top-right edge, with only their tops peeking out above it. Tapping them fans them out to view, open, or unmount. The band below the sheet disappears, so the Desk Workstation gets its full height back.
- **Page Corners** (折角) at the foot of each sheet turn pages, replacing the side chevrons.
- The **Journal Letterhead** is redrawn as classical front-matter:
  - a carved **Lunar Date Seal** (岁时印) showing the true lunar stem-branch year and seasonal month;
  - a two-line date that is never cut off;
  - the title;
  - vertical **Weather and Mood Charms**.
- **Each panel carries its own collapse control.** A brass pull tab on the workstation puts it away and leaves a **Restore Pill** behind. A tab on the Writing Dock hides the dock. The footer handle is removed.
- **While I type**, the app bar slides away, the Writing Dock becomes a slim accessory row, and the desk keeps the caret at least two rows above the dock, so the whole sheet stays usable. The sheet's geometry never changes.
- **The Scholar's Desk** is walnut in light mode and ebony in dark mode.

## User Stories

### Turning pages with Page Corners

1. As a diarist, I want a curled Page Corner at the bottom-right of a sheet that turns to the next sheet, so that turning a page feels like lifting paper.
2. As a diarist, I want a curled Page Corner at the bottom-left that turns to the previous sheet, so that I can go back the same way.
3. As a diarist, I want the previous corner hidden on the first sheet and the next corner hidden on the last sheet, so that the corners never offer a page that does not exist.
4. As a diarist, I want the drawn fold to stay inside the sheet's margin and border, so that it never covers the end of my last line of text.
5. As a diarist, I want each corner's touch target to be at least 44×44, reaching onto the desk below the sheet, so that a small fold is still easy to tap.
6. As a diarist using a screen reader, I want the corners announced as "上卷" and "下卷" with the target sheet number, so that I can turn pages without sight.
7. As a diarist, I want swiping between sheets to keep working, so that I can turn pages either way.
8. As a diarist writing with the keyboard open, I want tapping a corner to carry my writing focus to the new sheet without the keyboard dropping, so that turning pages stays as smooth as it is today.
9. As a diarist, I want the side chevrons gone, so that nothing floats over my writing.

### The page indicator

10. As a diarist, I want "第 N / M 页" shown at the left of the header band above the sheet, so that I always know where I am.
11. As a diarist, I want the header band's "文房书案" engraving removed, so that the band stays uncluttered for the page indicator and my Tucked Prints.

### The Journal Letterhead

12. As a diarist, I want a carved cinnabar Lunar Date Seal at the left of the first sheet's letterhead showing the lunar year's stem-branch and the seasonal month (e.g. 丙午 · 孟冬), so that my entry is dated like classical stationery.
13. As a diarist, I want the lunar date to be calculated correctly, including leap months, so that the seal never shows a wrong date.
14. As a diarist, I want a leap month to use its base month's seasonal name, so that the seal always reads naturally.
15. As a diarist, I want the seal to update when I change the entry's date, so that it always matches the entry.
16. As a diarist, I want tapping the seal to open the date and time picker, so that the seal also works as the date control.
17. As a diarist, I want the first date line to read like "2026年11月6日 周五", so that the solar date is short enough to show in full.
18. As a diarist, I want a second, muted date line with the lunar day and solar term (e.g. "九月廿九 · 立冬"), so that I see the classical calendar without crowding the solar date.
19. As a diarist, I want the date lines to be at least 13sp and never cut off with an ellipsis, so that the date is always legible.
20. As a diarist on a narrow phone or with large text, I want the solar term dropped first when space runs out, so that the date itself is always shown.
21. As a diarist, I want the title below the date lines to use the full width up to the charms, so that long titles wrap less.
22. As a diarist, I want a vertical Weather Charm and a vertical Mood Charm hanging at the right of the letterhead, so that weather and mood read like calligraphy tags rather than form chips.
23. As a diarist, I want tapping a charm to open its weather or mood picker, so that I can still change them in one tap.
24. As a diarist, I want charm text to be at least 12px and each charm to have a 44×44 target, so that the charms are legible and easy to tap.
25. As a diarist, I want the new letterhead to occupy exactly the same four rows as today, only on the first sheet, so that no sheet's line capacity changes and existing entries paginate exactly as before.
26. As a diarist using a screen reader, I want the seal, the date lines and each charm to have meaningful labels (e.g. "岁次丙午 孟冬初五，轻触修改日期"), so that the letterhead is usable without sight.
27. As a diarist, I want the Thread-Bound Folio and the intro screen to show the same correct lunar dates, so that every lunar date in the app agrees.
28. As a diarist writing an entry dated outside the supported lunar range, I want the seal to show only the stem-branch year and the lunar day to be omitted, so that nothing wrong is displayed.

### Tucked Prints

29. As a diarist, I want a sheet's mounted photos and videos tucked behind its top-right edge, with only a tilted sliver of each peeking out, so that my keepsakes are present without distracting from my writing.
30. As a diarist, I want each print to carry a small washi-tape strip and a slight tilt, so that it looks like a real photo slipped between pages.
31. As a diarist, I want a video's print to carry a small cinnabar ▶ stamp, so that I can tell videos from photos.
32. As a diarist, I want the prints to appear in the order I mounted them, so that the fan is predictable.
33. As a diarist, I want Tucked Prints to take no rows and leave no band below the sheet, so that mounting a photo never changes my sheet or squeezes the workstation.
34. As a diarist, I want tapping the Tucked Prints to fan them out in an overlay over the desk at a recognisable size, so that I can see what is mounted on this sheet.
35. As a diarist, I want tapping a print in the fanned overlay to open it in the fullscreen lightbox, so that I can view it large and edit its caption.
36. As a diarist, I want a ↩ 揭回 control on each fanned print that returns it to the Staging Handscroll, so that I can unmount from the new presentation.
37. As a diarist, I want to dismiss the fanned overlay by tapping outside it or with the back gesture, so that I return to writing easily.
38. As a diarist, I want a sheet without mounted items to show no Tucked Prints at all, so that text-only sheets stay calm.
39. As a diarist, I want dragging a handscroll item onto the sheet, or tapping 📌, to mount it as a new Tucked Print that slides down into the sheet's edge, so that mounting still feels physical.
40. As a diarist, I want a mount onto a full sheet to make the Tucked Prints shake and show "本页已满三影", so that I understand the limit.
41. As a diarist with a legacy entry whose sheet holds more than three items, I want the resting fan to show the first three with a "+N" mark and the overlay to show them all, so that nothing is hidden.
42. As a diarist, I want Tucked Prints to follow their passage through reflow, reloads, the Folio and PDF export exactly as mounted items do today, so that nothing about placement changes.
43. As a diarist using a screen reader, I want the Tucked Prints announced as "本页夹页影札 N 枚，轻触展开", and each fanned print and ↩ control to be labelled, so that I can manage mounted items without sight.
44. As a diarist typing with the keyboard open, I want the Tucked Prints to move up out of view with the header band, so that they never cover the lines I am writing.

### The Staging Handscroll's slot controls

45. As a diarist, I want each handscroll slot's 📌 贴至本页 and ✕ controls moved off the thumbnail into its caption bar, so that I can always recognise the photo.
46. As a diarist, I want those controls to keep 44×44 targets and their existing labels, so that they stay accessible.

### Collapsing the workstation

47. As a diarist, I want a brass pull tab centred on the workstation's top edge that puts the workstation away, so that the control sits on the thing it hides.
48. As a diarist, I want a Restore Pill resting at the foot of the desk while the workstation is put away, so that I can bring it back from where it was.
49. As a diarist, I want the Restore Pill to say how many items wait in the Staging Handscroll ("待贴画卷已收起 · 待贴 N 影", or "锦袱合卷" when empty), so that I do not forget staged keepsakes.
50. As a diarist, I want collecting a new photo or video while the workstation is put away to bring it back automatically, so that I see the Brush Reveal.
51. As a diarist, I want the workstation to fill all the space left below the sheet, at least about 150dp when open and about 110dp for the closed scroll, so that the handscroll is always recognisable.
52. As a diarist on a short phone, I want the workstation to start put away when its minimum does not fit, so that the sheet is never squeezed.
53. As a diarist, I want the workstation's put-away state to last only for this visit to the entry, so that reopening an entry shows me my staged keepsakes again.
54. As a diarist, I want the footer handle above the Writing Dock removed, so that the dock no longer carries a control for something else.

### Hiding the Writing Dock

55. As a diarist, I want a small tab on the Writing Dock's top edge, at the right, that hides the dock, so that I can give the desk more room when I am reading or arranging media.
56. As a diarist, I want a small tab left at the bottom-right of the screen while the dock is hidden, so that I can bring it back.
57. As a diarist, I want the space freed by hiding the dock to go to the desk without moving or resizing the sheet, so that my ruling and text stay put.
58. As a diarist, I want my choice to hide the dock remembered across entries and app restarts, so that I set it once.

### Typing with the keyboard open

59. As a diarist, I want the app bar to slide away while the keyboard is open and return when it closes, so that I gain space for writing.
60. As a diarist, I want a small save-state dot in the header band while the app bar is away, so that I still know my writing is saved.
61. As a diarist, I want the system back gesture to keep working while the app bar is away, so that I can always leave the editor.
62. As a diarist, I want the Writing Dock to become a slim accessory row while the keyboard is open, with only Tt formatting, 🎙 dictation and 收起键盘, so that it takes as little space as possible.
63. As a diarist who has hidden the Writing Dock, I want the accessory row to appear anyway when the keyboard opens, so that formatting and dictation are always at hand while typing.
64. As a diarist, I want the dock-hide tab hidden while the keyboard is open, so that the accessory row is the only bar above the keyboard.
65. As a diarist, I want the desk to keep my caret at least two rows above the accessory row, so that I see my line and the context around it.
66. As a diarist writing on the last row of a sheet on a 360×780 phone, I want that row to stay fully visible above the accessory row, so that the keyboard never hides what I am typing.
67. As a diarist, I want opening the keyboard to keep moving the desk rather than resizing or reflowing the sheet, so that text stays aligned with the ruling and Folio pagination is unaffected.
68. As a diarist, I want all of these keyboard behaviours to avoid summoning or dropping the keyboard unexpectedly, so that the SPEC-010 keyboard fixes stay intact.

### The Scholar's Desk appearance

69. As a diarist using the light appearance, I want the desk to stay walnut, so that the editor keeps its familiar look.
70. As a diarist using the dark appearance, I want the desk to become a deeper ebony with fainter grain, matching mat and brass, so that the paper sheets do not glare at night.
71. As a diarist, I want the desk's colouring to never depend on the entry's stationery template, so that changing a template only changes the paper.

## Implementation Decisions

### Page Corners (replaces side chevrons)

- The side chevrons are removed (Displacement over Coexistence), and their tests migrate to the Page Corners.
- Each sheet shows a previous corner (bottom-left) and a next corner (bottom-right), hidden on the first and last sheet respectively.
- The editor sheets use compact margins: the Heaven and Earth margins are at least 16px. So the drawn fold (about 20px, folded-paper gradient after the prototype's `.page-corner-curl`) stays within the Earth margin and border. The 44×44 hit target extends outward and down onto the desk; the desk always has at least the sheet gap below the sheet.
- Tapping a corner goes through the existing page-turn path: focus is carried across without remounting editors and without dropping the keyboard, as the chevrons do today.
- Static fold geometry is recorded once into a `ui.Picture`.

### Header band

- It stays 30px and is resolved against the resting desk height, as today.
- "第 N / M 页" moves to the left, and the "文房书案" engraving is removed.
- The right side of the band hosts the tops of the Tucked Prints.
- While the app bar is away (keyboard open), the band also carries a small save-state dot mirroring the autosave status.

### Lunar calendar (replaces the old calendar helper)

- New pure-Dart lunar calendar converter: hand-written offline lunar data for 1900–2100, with no package and no network.
- It returns:
  - the lunar year's stem-branch (e.g. 丙午);
  - the lunar month, with a leap flag;
  - the lunar day (e.g. 初五);
  - the seasonal month name (孟/仲/季 + 春/夏/秋/冬; a leap month takes its base month's name).
- Outside the supported range it returns only the stem-branch year: the seal shows that and the lunar day is omitted.
- The existing helper maps solar months and days to lunar-style numerals, so it shows wrong lunar dates. It is removed, and every user moves to the new converter: the Folio content parser, the book intro screen and the editor letterhead. Its tests migrate.
- The solar-term calculation already used by the letterhead stays.

### Journal Letterhead (Sheet 1 only)

- The letterhead keeps its integer-snapped four rows on the opening sheet. Continuation sheets have no front-matter, and no sheet's row capacity changes.
- Layout, left to right:
  - the **Lunar Date Seal**;
  - a column with date line 1, date line 2 and the title;
  - the **Weather Charm** and **Mood Charm**.
- **Lunar Date Seal**, from the prototype's `.cinnabar-date-seal`: about 38×38; a 2×2 character grid read in the classical right-column-first order (stem-branch year on the right, seasonal month on the left); a 2px cinnabar `#B83B2E` border; a faint cinnabar wash fill; the bundled brush font; rotated -3°. Tapping it opens the existing date and time picker.
- **Date line 1** is `yyyy年M月d日 周X`. **Date line 2** is `<lunar day> · <solar term>` in muted ink.
  - Both lines are at least 13sp, and neither uses ellipsis truncation.
  - When the width is insufficient, the solar term is dropped first, then the lines wrap or scale down; the solar date is never cut.
  - Text scale is clamped per CODING_STANDARDS.
- **The title field** spans the full width between the date column's start and the charms.
- **Weather Charm and Mood Charm**, from the prototype's `.vertical-tag`:
  - vertical calligraphy tags, emoji plus two characters set vertically;
  - a thin cinnabar border and a paper fill;
  - text of at least 12px;
  - each one a 44×44 target opening the existing weather or mood picker.
- Scoped `Semantics` on the seal, each charm, and the date block.

### Tucked Prints (replaces the Sheet Mount Strip)

- The Sheet Mount Strip widget and its band below the sheet are removed (Displacement over Coexistence), and their tests migrate to Tucked Prints.
- The mount-marker model of ADR-0009 is unchanged: Tucked Prints are only the editor's presentation of a sheet's mounted items. ADR-0009's wording was amended to name Tucked Prints.
- **Resting fan:**
  - Up to three prints, about 40px wide, each showing its top ~22px above the sheet's top-right edge in the header band. They are stacked behind the sheet, so the sheet paints over their lower parts.
  - Tilts come from the prototype's `-1.8deg / 1.4deg / -1.2deg`, each print with a washi strip (`rgba(212,175,55,0.52)`, about 28×8).
  - A video's print gets a small cinnabar ▶ stamp.
  - More than three items (tolerated legacy overflow) shows a "+N" mark.
  - The whole fan is one target of at least 44×44 with the label "本页夹页影札 N 枚，轻触展开".
- **Fanned overlay:**
  - It opens over the desk, showing every mounted item of the active sheet at about 96px.
  - Tapping a print opens the fullscreen lightbox, which remains the only caption editor.
  - Each print has a ↩ 揭回 control (44×44, labelled) that unmounts it to the Staging Handscroll.
  - Tapping outside, or the back gesture, dismisses it.
  - It is a modal route that keeps its own state (Modal Route State Encapsulation).
- **Mounting:**
  - Drag onto the sheet and 📌 still mount through the existing operations.
  - A newly mounted print slides down into the sheet edge, adapted from the prototype's `mountSnapIn` (0.36s, `cubic-bezier(0.22,1,0.36,1)`).
  - A refused mount onto a full sheet plays the prototype's `rejectShake` on the fan (0.38s, ±6px) and shows "本页已满三影", hiding the current snackbar first.
  - The drop-target highlight stays on the sheet.
- **Keyboard:** while the keyboard is open, the prints move with the header band under the existing desk lift; they are not separately hidden.
- **Keyboard safety:** opening the overlay, unmounting and mounting release writing focus first and make their document edits without requesting the keyboard, as SPEC-010's fixes do.

### Desk space budget (modified)

- The strip band is removed from the budget.
- While docked, the sheet sits under the header band, and the workstation takes all remaining height, minimum ~150dp open and ~110dp for the closed scroll. On the last sheet the Cinnabar Signature Seal band still applies.
- When collapsed, the sheet centres on the desk, with the Restore Pill at the desk's foot.
- Whether the workstation fits stays an entry-wide start-up decision (start collapsed when the minimum does not fit).
- The budget is still resolved against the resting desk height, so neither the keyboard nor any chrome moves or resizes the sheet.

### Staging Handscroll slot controls (modified)

- Each slot's 📌 贴至本页 and ✕ move from the thumbnail corners into the slot's caption bar.
- They keep their 44×44 targets and labels, and the thumbnail is left unobstructed.

### Collapse controls

- The footer handle above the Writing Dock is removed, and its tests migrate.
- **Workstation:**
  - A brass pull tab is centred on its top edge (44×44, labelled 收起画案 / 展开画案).
  - While the workstation is put away, a **Restore Pill** rests at the desk's foot, styled after the prototype's `#workstation-restore-pill` (dark walnut fill, amber border, amber text). It reads "待贴画卷已收起 · 待贴 N 影" or, when empty, "锦袱合卷", and tapping it restores the workstation.
  - Collecting media while it is put away restores it automatically.
  - The collapsed state stays session-only (per visit to the editor), as today.
- **Writing Dock:**
  - A small tab sits on the dock's top edge at the right (44×44, labelled 收起文房 / 展开文房), and stays at the bottom-right while the dock is hidden.
  - The hidden state is an app-wide preference, stored with the existing local settings and never in the entry.
  - Hiding or showing the dock changes only the space below the desk; the sheet's resting geometry is unaffected.

### Keyboard chrome

- While the keyboard is open:
  - The app bar animates out and returns when the keyboard closes. The system back gesture and the exit guard are unaffected.
  - The Writing Dock is replaced by an accessory row of about 40dp holding Tt formatting, 🎙 dictation and 收起键盘 (which releases writing focus). Photo, video and ambiance actions are not shown; collecting closes the keyboard anyway.
  - The accessory row appears whether or not the dock is hidden, and the dock-hide tab is not shown.
- **Typewriter-style lift:** the desk lift keeps the caret at least two rows above the accessory row's top edge, clamped as today so the sheet's bottom edge can always be brought into view.
- **Space gained** (measured on the reference phone): about 25dp from the removed footer handle and about 56dp from the app bar, plus the slimmer dock row. Real-device testing shows about two rows hidden today; together these must keep the sheet's last row fully visible.
- All of this changes only chrome and the desk's translation. The sheet's size, ruling and row capacity never change with the keyboard, so Paper Heart and Folio formatting are unaffected.
- Every new control follows SPEC-010's focus rules:
  - Tapping a chrome control while writing does not summon or drop the keyboard unexpectedly.
  - Page turns keep focus.
  - Programmatic edits ignore focus.

### Scholar's Desk appearance

- The desk painter takes a fixed palette chosen by the app's brightness:
  - **light:** the current walnut, after the prototype's `#211A14` base with a radial highlight;
  - **dark:** an ebony palette after the prototype's `#2B231B → #120F0C`, with fainter grain.
- Bamboo mat and brass tones are adjusted to match.
- The palette never depends on the stationery template.
- Static geometry stays recorded once into a `ui.Picture`.

### Code shape

- Every new or modified file stays under 450 lines.
- The entry editor screen is already near the limit, so new behaviour goes into separate widgets and controllers, not the screen.
- Composite letterhead data (solar date, lunar date, solar term, weather, mood) travels as a typed value object.

## Testing Decisions

### What makes a good test

- Test observable behaviour only: what is rendered and where, which sheet is shown, what the overlay contains, what a tap does, what is persisted, and whether the keyboard was requested or hidden. Do not assert on private state or painter internals.
- Keyboard tests use the phone viewport (360×780) with a simulated keyboard inset, and assert positions with rectangle comparisons, as the existing desk keyboard tests do.
- Remember that widget tests treat the software keyboard as always shown. Assert on the text-input log and focus state, and keep real-device validation in the release checklist.
- Animations are pumped with bounded steps, never by settling ambient loops.
- Use the shared editor harness and test doubles (synchronous media sandbox, stub image picker, fake video platform).

### Seams (agreed)

1. **The editor screen through the shared editor harness** (primary):
   - Page Corners: visibility on first, middle and last sheet; turning pages; 44×44 targets; labels; focus carried without dropping the keyboard; no chevrons.
   - Header band: indicator on the left, no engraving.
   - Letterhead on Sheet 1 only, occupying exactly the four rows (opening sheet still holds 10 body rows): the seal shows the correct stem-branch year and seasonal month; tapping it opens the date picker; the date lines are not truncated at 360dp; the solar term drops first under large text scale; the charms open their pickers.
   - Tucked Prints: absent with no mounts; up to three shown above the sheet's top edge; "+N" for legacy overflow; tap opens the overlay; overlay print opens the lightbox; ↩ unmounts back to the handscroll; mounting via 📌 and via drag adds a print; a full sheet shakes and shows the snackbar; no band below the sheet; none of these summon the keyboard.
   - Workstation: pull tab collapses and leaves the Restore Pill with the staged count; the pill restores it; collecting while collapsed restores it; the footer handle is gone; reopening the entry shows it docked again.
   - Writing Dock: the tab hides it and the preference survives a new editor session; the sheet does not move.
   - Keyboard open: the app bar is away and the save dot shows; the accessory row shows its three controls, even when the dock is hidden; the last row of a full opening sheet and of a full continuation sheet is fully visible above the accessory row; the caret stays two rows clear; the sheet's size and ruling are unchanged.
   - Dark appearance: the desk renders with the dark palette regardless of template.
2. **The lunar calendar converter** (pure Dart):
   - known solar-to-lunar conversions across several years, including dates either side of the lunar new year;
   - leap months and their seasonal names;
   - stem-branch years;
   - the 1900 and 2100 bounds and the out-of-range fallback.
   - It replaces the old calendar helper's tests.
3. **The desk space budget** (pure Dart):
   - workstation height with no strip band;
   - minimums;
   - centring when collapsed;
   - the sheet never moves with the keyboard;
   - the start-collapsed decision on short desks.

### Prior art

- Desk and keyboard: `desk_keyboard_layout_test`, `desk_actions_keyboard_test`, `desk_space_budget_test`, `desk_workstation_test`, `split_desk_centering_test`.
- Mounting flows (migrate from the strip to Tucked Prints): `split_desk_mount_strip_test`, `staging_handscroll_mount_test`, `staging_handscroll_drag_mount_test`, `staging_handscroll_unmount_erase_test`, `mounted_items_follow_text_test`, `legacy_entry_mounting_test`.
- Letterhead: `journal_letterhead_test`, `integer_snapped_letterhead_test`.
- Writing Dock and handle (migrate): `writing_dock_test`, `writing_dock_workstation_handle_test`, `editor_top_app_bar_test`.
- Paging: `paginated_editor_stage_test`, `enter_mid_sheet_spill_test`.
- Lunar: `chinese_calendar_helper_test` (replaced).

## Out of Scope

- Paper ruling cycling (the prototype's "TT" button and "纸格" indicator). It belongs to the planned template work in the Scholar's Stationery Chest.
- The silk bookmark pagination ribbon.
- Desk colouring that follows the stationery template, or per-template desk materials.
- Synthesized or bundled sound effects.
- Brush Reveal replay controls (per-slot 🖌️ and 重演挥毫).
- Right-to-left handscroll reading order.
- Reordering Tucked Prints, or moving items directly between sheets.
- Editing captions anywhere other than the lightbox.
- Remembering the workstation's collapsed state across visits.
- Front-matter on continuation sheets, or per-sheet titles.
- Any change to the Folio or PDF media pairing (only their lunar dates are corrected).

## Further Notes

- **Design reference:** the prototypes `memodiary_canvas_layout_benchmark_3.html` (and `_2.html`, which shares the same markup for these features). They are not tracked in git. They live on the developer's machine at `/mnt/c/Users/ASUS/Desktop/私人日记/prototypes/`. Read them as HTML/CSS visual references, not code to port. Exact values above are quoted from them. Their 10px and smaller text, hover-only sizes, fixed 30px stride, per-page front-matter and in-frame media strip are intentionally not carried over.
- **Vocabulary** follows GLOSSARY.md: Scholar's Desk, Page Corner, Lunar Date Seal, Weather Charm / Mood Charm, Tucked Prints, Restore Pill, Staging Handscroll, Collect, Mount / Unmount, Writing Dock. Avoid "Sheet Mount Strip" (SPEC-010's name, now replaced by Tucked Prints), "chevron" and "page counter".
- **ADR-0009** governs mounting and was amended only in wording. No new ADR was needed: none of these decisions is both hard to reverse and the result of a contested trade-off.
- The `$0` FOSS invariant holds: Flutter painters, gestures, existing packages and hand-written lunar data only.
- After implementation, validate the keyboard behaviour on a real phone. Widget tests cannot observe Quill's behaviour while the keyboard is hidden.
