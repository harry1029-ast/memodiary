---
id: SPEC-025
title: Timeline Scrubber, Month Spine Dividers and Scroll Performance
status: ready-for-agent
created_at: 2026-11-26T17:58:23+08:00
adr: ADR-0015
---

# Specification: Timeline Scrubber, Month Spine Dividers and Scroll Performance

## Problem Statement

1. **Deep timeline browsing is tedious without mutating filters.** Long timelines paginate in batches of 20 entries. Jumping back several months or years currently requires either repeatedly scrolling page after page or narrowing the feed via the Date Index Tray, which hides surrounding entries.
2. **Calendar boundaries along the spine are easy to miss.** Each entry's left waist-tally badge shows its month and day (`M月` / `D日`), but not its year, so crossing from one month or year to another during fast scrolling lacks a clear visual anchor.
3. **Returning from reading or editing an entry loses the diarist's place.** Navigating to `EntryDetailScreen` from deep in the feed and coming back resets the timeline to the first 20 entries and drops the scroll position.
4. **Fast scrolling incurs avoidable decode and SQLite overhead.** Each timeline page reads full Quill Delta JSON (`content_delta`) blobs even though cards only display `plainText`, and Wet-Mounted Thumbnail resolves file paths via a fresh `FutureBuilder` + synchronous `existsSync()` on every build while decoding full-resolution WebP images into an `82×62` frame.

## Solution

1. **Timeline Scrubber**: An auto-hiding right-edge fast-scroll thumb paired with a floating `YYYY年M月` date plaque on the Chronicle Desk. It spans the entire filtered timeline using a lightweight ordered date index, previews `YYYY年M月` live while dragging, and jumps directly to the target position on release without altering Date Index Tray filters.
2. **Month Spine Divider**: An inline `YYYY年M月` section header integrated along the Chronicle Desk's vertical timeline spine at the top of a non-empty feed and wherever consecutive entries cross a calendar month or year boundary.
3. **Header Tap-to-Top**: Tapping the pinned Chronicle Desk title area (`日记 · 共 N 篇`) smoothly scrolls back to offset `0` to reveal the Shanshui Scenery Card and Window Sill Ledge without adding any floating chrome above the Tab Rail.
4. **Back-Navigation Scroll & Page Preservation**: Returning from `EntryDetailScreen` refreshes loaded pages in place (`keepLoadedPages: true`) so the diarist stays at their reading position, whereas creating a new entry via the Scroll Roller Button refreshes at the top.
5. **Lightweight Summary Projection & Wet-Mounted Thumbnail Optimization**: Project timeline rows without `content_delta` (carrying metadata and a short `plainText` snippet while `EntryDetailScreen` loads the full entry by `entryId`), and resolve Wet-Mounted Thumbnail paths synchronously with pixel-bounded `cacheWidth`/`cacheHeight` image decoding.

## User Stories

### Timeline Scrubber: visibility, dragging, and jumping

1. As a diarist with a short or non-scrollable timeline (fewer than 15 filtered entries), I want the Timeline Scrubber to stay hidden, so that the Chronicle Desk remains calm and uncluttered when fast-scrolling is unnecessary.
2. As a diarist with 15 or more filtered entries in a scrollable feed, I want the Timeline Scrubber to fade in when I scroll or touch its right-edge track and auto-fade out after about 1.5 seconds of inactivity, so that it stays out of the way while reading.
3. As a diarist dragging the Timeline Scrubber thumb, I want the scrubber and its floating `YYYY年M月` date plaque to remain visible for as long as I hold my finger down, so that it never disappears mid-gesture.
4. As a diarist scrolling through a multi-year diary, I want the Timeline Scrubber thumb position to reflect my reading progress across all matching entries (`totalFilteredCount`) rather than only loaded pages, so that the thumb never jumps backward whenever the next page loads.
5. As a diarist dragging the Timeline Scrubber vertically, I want the floating date plaque to update smoothly at 60 FPS showing the `YYYY年M月` of the target entry at that position, so that I know exactly where I will land before releasing.
6. As a diarist dragging across calendar month boundaries, I want a subtle selection haptic tick each time the previewed month changes, so that scrubbing has tactile precision without looking away from the plaque.
7. As a diarist releasing the Timeline Scrubber at an older month, I want the timeline to jump directly to that entry without altering my active Date Index Tray or charm filters, so that I keep full chronological context and can scroll freely both up and down from the landing spot.
8. As a diarist who jumped via the Timeline Scrubber and then scrolls further down, I want subsequent pagination batches to continue loading seamlessly below the landing point, so that I never hit an artificial dead end.
9. As a diarist switching between `最新 ↓` and `最早 ↑` sort orders or applying Year, Month, Ten-Day Period, Mood, Weather, Media, or Weekly Review filters, I want the Timeline Scrubber's date range and jumps to match the filtered and sorted result set, so that the scrubber is always consistent with the feed.
10. As an Android diarist using edge-swipe navigation, I want vertical drags on the Timeline Scrubber not to conflict with horizontal system Back gestures or the left-edge Diarist Panel drag, so that navigation gestures remain reliable.

### Month Spine Divider

11. As a diarist viewing a non-empty timeline, I want an inline `YYYY年M月` Month Spine Divider above the first entry and at every point where consecutive entries cross a calendar month or year boundary, so that both month groupings and year transitions are immediately scannable.
12. As a diarist sorting the timeline `最早 ↑` instead of `最新 ↓`, I want Month Spine Dividers to appear in ascending chronological order at each month transition, so that chronological orientation works in both directions.
13. As a diarist scrolling along the Chronicle Desk, I want each Month Spine Divider to integrate cleanly onto the continuous vertical silk-cord spine without breaking line alignment from the top grommet through the entry cards, so that the visual craft of the spine stays cohesive.
14. As a diarist switching between light and dark Atmosphere Themes or custom palettes, I want Month Spine Dividers to adapt using the active Atmosphere Palette colors, so that contrast and material harmony stay consistent.
15. As a diarist reading the timeline, I want Month Spine Dividers to use plain modern Chinese `YYYY年M月` formatting consistent with the plain Chinese UI diction policy, so that dates are effortless to scan.

### Header Tap-to-Top

16. As a diarist scrolled deep into the Chronicle Desk feed, I want tapping the pinned `日记 · 共 N 篇` title area to scroll back to the top of the screen, so that I can return to the Shanshui Scenery Card and Window Sill Ledge in one tap without needing a floating button.
17. As a diarist already at the top of the timeline, I want tapping the `日记 · 共 N 篇` title area to be a harmless no-op, so that accidental taps at rest do not jitter the screen.
18. As a diarist far down a long timeline, I want Tap-to-Top to reach the top briskly without an overly long scroll animation, so that returning to the top always feels responsive.
19. As a diarist tapping the `筛选` button or any chip inside the Date Index Tray, I want those taps never to trigger Tap-to-Top, so that filtering and sorting controls never scroll me away unexpectedly.

### Back-Navigation Scroll & Page Preservation

20. As a diarist who scrolled past page 1 and tapped an entry to read or edit it in `EntryDetailScreen`, I want returning to the timeline to keep my previously loaded pages and scroll position intact while reflecting any title, metadata, snippet, or deletion changes, so that I can continue browsing right where I left off.
21. As a diarist who scrolled down and opened a newly created entry via the Scroll Roller Button (`写日记`), I want returning from the editor to refresh the timeline at the top, so that my newly created entry is immediately visible.
22. As a diarist returning from a Diarist Panel screen (such as Recycle Bin or Import/Backup) that modified entries, I want the timeline to continue preserving loaded pages (`keepLoadedPages: true`) as before, so that external refreshes do not reset my position unnecessarily.

### Lightweight Summary Projection & Wet-Mounted Thumbnail Performance

23. As a diarist scrolling through a large diary, I want the timeline feed query to omit heavy `content_delta` Quill JSON blobs and fetch only display metadata plus a short `plainText` snippet, so that loading pages and scrubber jumps stay fast with low memory pressure.
24. As a diarist opening an entry card from the timeline into `EntryDetailScreen`, I want `EntryDetailScreen` to load the full `Entry` (including `content_delta`) by `entryId`, so that switching the timeline to a lightweight summary projection never drops rich text, formatting, or attachments when viewing or editing.
25. As a diarist viewing entries with photos or video posters, I want Wet-Mounted Thumbnail widgets to resolve sandboxed file paths synchronously once the sandbox directory is warm instead of flashing placeholders on every build, so that cards stay steady during fast flings.
26. As a diarist scrolling through photo-heavy timelines, I want Wet-Mounted Thumbnail images to decode at bounded thumbnail pixel dimensions (`cacheWidth`/`cacheHeight` scaled by device pixel ratio) without synchronous `existsSync()` checks during `build()`, so that frame times stay smooth and image memory stays bounded.
27. As a diarist jumping to an older page via the Timeline Scrubber, I want primary media attachments to be batch-loaded around the landing window, so that Wet-Mounted Thumbnails near the target entry appear promptly without decoding every earlier entry's media eagerly.

### Accessibility, Layout, and Reduced Motion

28. As a screen-reader user, I want the Tap-to-Top title region to announce a clear action label (such as `点击返回顶部`) when scrolled down and the Timeline Scrubber to expose plain modern Chinese semantics (`时间轴快速滚动条`), so that both controls are discoverable without sight.
29. As a diarist with system reduced-motion enabled, I want Tap-to-Top to jump immediately to offset `0` (`jumpTo(0)`) and the Timeline Scrubber fade to skip animated transitions, so that motion preferences are respected everywhere.
30. As a diarist using large text (`1.3×`) on a narrow phone (`320dp`), I want Month Spine Dividers, the pinned Chronicle Desk title bar, and the Timeline Scrubber's floating date plaque to render without text clipping or horizontal overflow, and interactive controls to satisfy minimum `44×44dp` touch targets.

## Implementation Decisions

- **Lightweight Timeline Summary Projection (`EntriesDao` & timeline models)**:
  - Introduce a dedicated timeline summary projection model in the timeline/DAO layer containing only the fields needed for timeline cards, Month Spine Dividers, and Shanshui Scenery Card inference: `id`, `title`, short `plainText` snippet (sufficient for the 3-line card preview and scenery mood/realm inference), `entryDate`, `mood`, `weather`, `isLocked`, `isWeeklyReview`, `weekNumber`, `unlockAt`, and `isDeleted`—strictly omitting `content_delta` per ADR 0015.
  - Update `TimelineEntryItem`, `EntrySummaryCard`, `TimeCapsuleCard`, and `TimelineScreen` to consume this summary model rather than full `Entry` rows.
  - Navigate from `TimelineScreen` to `EntryDetailScreen` using `entryId` so `EntryDetailScreen` loads the complete `Entry` row on open.
  - Add a lightweight ordered date-index query on `EntriesDao` that reads only filtered `(id, entry_date)` values in the active sort order for the Timeline Scrubber, reusing the existing timeline filter predicate so filtered counts and sort direction always match.

- **Timeline Scrubber & Single-Sliver Prefix Jump**:
  - Per ADR 0015, implement scrubber jumps using single-sliver prefix loading (`0 .. targetIndex + 20`) of lightweight summary rows into the existing `SliverList`, keeping `CustomScrollView`, `RefreshIndicator`, `UpperWindowAndSill`, and pinned `ChronicleDeskHeaderDelegate` intact.
  - Batch-fetch primary `MediaAttachment` rows around the jump target window (and merge incrementally as the user scrolls) so Wet-Mounted Thumbnails near the landing spot render promptly without querying media for every skipped prefix row upfront.
  - Drive the scrubber thumb position from the topmost visible entry index relative to `totalFilteredCount` (avoiding `scrollOffset / maxScrollExtent`, which jumps backward as `_loadMore()` appends pages).
  - Track the topmost visible item index reliably across variable-height entry cards and Month Spine Dividers (e.g., via lightweight item-key / render-box inspection or viewport offset estimation synchronized with visible item extents) so jumping and post-jump scrolling stay accurate.
  - During a drag, update the thumb and floating `YYYY年M月` plaque at 60 FPS from the ordered date index, trigger `HapticFeedback.selectionClick()` whenever the previewed `(year, month)` changes, and perform the prefix load + scroll jump upon finger release.
  - Hide the scrubber whenever `totalFilteredCount < 15` or the scroll view is not scrollable; fade it in on scroll or right-edge drag, and auto-fade out after ~1.5 seconds of inactivity (never fading while actively dragged).
  - Position the scrubber inside the Chronicle Desk's right margin with a vertical-drag gesture detector so horizontal Android edge-back swipes and the left-edge Diarist Panel drag remain undisturbed.

- **Month Spine Divider**:
  - Compute month transitions dynamically when building `ChronicleDeskFeedSliver` items (emitting a divider before index `0` and whenever `(entry.entryDate.year, entry.entryDate.month)` differs from the preceding entry's year/month).
  - Render each divider as an inline `YYYY年M月` marker aligned directly along the vertical spine line, styled with active Atmosphere Palette tokens (`deckleBorder`, `deskMat`, `textSecondary`/`accentSecondary`) and plain modern Chinese copy per ADR 0012.

- **Header Tap-to-Top**:
  - Wrap only the left title + count region (`日记 · 共 N 篇`) of the pinned Chronicle Desk header in a tap target with `44×44dp` minimum hit area, leaving the `筛选` Begonia plaque button and `Date Index Tray` completely separate.
  - On tap, if the timeline `ScrollController` offset is `> 0`, jump immediately when `MediaQuery.disableAnimationsOf(context)` is true; otherwise, if scrolled very far down, pre-jump closer to the top before animating smoothly to `0.0` so the return always completes briskly.

- **Back-Navigation Refresh Policy**:
  - In `TimelineScreen`, update the return callback from `EntryDetailScreen` to call `_loadInitial(keepLoadedPages: true)` without resetting the scroll controller, preserving loaded pages and reading position while refreshing modified/deleted items.
  - Keep `_loadInitial()` (resetting to page 1 and top) when returning from creating a new entry via the Scroll Roller Button (`写日记`).

- **Wet-Mounted Thumbnail Optimization**:
  - Warm `MediaSandboxService.getBaseDirectory()` once during `TimelineScreen` initialization so the cached base directory is ready before cards mount.
  - Update `WetMountedThumbnail` to resolve files synchronously via `MediaSandboxService.resolveFileSync` (falling back to async resolution only if the base directory is not yet cached), remove per-build `File.existsSync()` calls on the UI thread (relying on `Image.file`'s `errorBuilder` for missing/corrupt files), and pass device-pixel-ratio-scaled `cacheWidth` / `cacheHeight` matching the `82×62` display size to `Image.file`.

## Testing Decisions

- Good tests exercise external user-visible behavior and database query contracts through high-level seams, avoiding assertions on private widget state or internal helper signatures.
- **Primary seam — `TimelineScreen` widget test seam** *(prior art: existing timeline screen widget tests)*:
  - Test with a real in-memory `AppDatabase` and temporary-directory `MediaSandboxService`.
  - Verify Month Spine Dividers (`YYYY年M月`) at feed start and across month/year boundaries in both `newestFirst` and `oldestFirst` orders.
  - Verify Timeline Scrubber hidden state (`< 15` entries), scroll/drag visibility and auto-fade idle behavior, live `YYYY年M月` plaque preview during drag, release jump to an unloaded older month without altering Date Index Tray filters, subsequent scroll pagination below the jump point, and reduced-motion behavior.
  - Verify Header Tap-to-Top scrolling from deep in the feed back to offset `0`, no-op when already at top, instant `jumpTo(0)` under reduced motion, and non-interference with `筛选` and Date Index Tray taps.
  - Verify back-navigation page and scroll preservation after returning from `EntryDetailScreen`, contrasted with top refresh after creating a new entry via the Scroll Roller Button.
  - Verify Wet-Mounted Thumbnail synchronous rendering without placeholder flicker once the sandbox base directory is warm and bounded `cacheWidth` / `cacheHeight` image configuration.
- **Secondary seam — `EntriesDao` database seam** *(prior art: existing timeline repository DAO tests)*:
  - Test against a real in-memory `AppDatabase`.
  - Verify the lightweight timeline summary projection query returns accurate metadata and truncated/capped snippets across filters, sort orders, and pagination offsets without selecting `content_delta`.
  - Verify the ordered date-index query matches filtered active entries and respects `newestFirst` / `oldestFirst` ordering.

## Out of Scope

- Collapsing the `Date Index Tray` into a single-line header strip on scroll (remains pinned full-height in this spec).
- Adding a permanent horizontal timeline bar below the `Date Index Tray`.
- Paginating or refactoring eager list rendering on Search, Recycle Bin, Weekly Review, or Writing Analytics screens.
- Adding a user-facing lunar date toggle to Month Spine Dividers or the Timeline Scrubber (existing lunar helpers remain untouched).
- Any SQLite schema or migration changes (no new tables or columns required).

## Further Notes

- Architectural rationale and rejected alternatives (dual-sliver bidirectional windowing, filter-snap jumping, loaded-only scrollbars) are documented in `ADR-0015`.
- Canonical UI terminology (`Timeline Scrubber`, `Month Spine Divider`, `Chronicle Desk`, `Date Index Tray`, `Wet-Mounted Thumbnail`) is defined in `GLOSSARY.md`, and all user-facing copy follows `ADR-0012` (Plain Modern Chinese UI Diction Policy).
