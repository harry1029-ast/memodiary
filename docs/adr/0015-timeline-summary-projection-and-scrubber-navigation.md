---
status: accepted
---

# Timeline Summary Projection and Single-Sliver Scrubber Navigation

To keep Chronicle Desk scrolling smooth across large diaries and support direct right-edge Timeline Scrubber jumps without dual-sliver complexity, we decouple the timeline feed from full `Entry` rows via a lightweight summary projection omitting `content_delta` (carrying only display metadata and a short `plainText` snippet, while `EntryDetailScreen` reloads the full `Entry` by `entryId`), and back Timeline Scrubber jumps with single-sliver prefix loading of lightweight summary rows (`0 .. targetIndex + 20`) plus batched primary-media lookup around the target window while keeping `Date Index Tray` filters intact.

## Considered Options

- **Bidirectional windowed dual-sliver (`CustomScrollView.center`)**: Avoids loading prefix summaries before the jump target, but conflicts with `RefreshIndicator`, `UpperWindowAndSill`, and the pinned `ChronicleDeskHeaderDelegate`, and complicates upward scroll offset stability.
- **Filter-snap jump (applying Year + Month to Date Index Tray)**: Reuses existing date filtering, but unexpectedly narrows the user's active feed and loses surrounding chronological context.
- **Loaded-only scrollbar**: Simpler to implement, but cannot reach older entries without paging through every intermediate batch first and causes the thumb position to jump backward as `_loadMore()` appends pages.

## Consequences

- Timeline scrolling, scrubbing, and `Month Spine Divider` rendering operate on lightweight summary rows without pulling Quill Delta JSON blobs from SQLite.
- `Timeline Scrubber` previews `YYYY年M月` live at 60 FPS from a lightweight ordered date index (with month-crossing haptic feedback) and jumps on finger release; it stays hidden on short lists (`< 15` entries or non-scrollable) and auto-fades after ~1.5s of idle.
- Returning from `EntryDetailScreen` calls `_loadInitial(keepLoadedPages: true)` to preserve loaded pages and scroll offset, whereas creating a new entry via the Scroll Roller Button refreshes at the top.
- `Wet-Mounted Thumbnail` resolves sandbox paths synchronously via `MediaSandboxService.resolveFileSync` (after warming the base directory) and decodes with `cacheWidth`/`cacheHeight`.
- Tapping the pinned Chronicle Desk title area (`日记 · 共 N 篇`) scrolls back to offset `0` (respecting reduced motion), avoiding any extra floating button above the Tab Rail.
