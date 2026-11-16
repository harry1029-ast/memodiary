---
id: SPEC-019
title: Window Above, Chronicle Desk Below — Timeline Front Screen Redesign
status: completed
created_at: 2026-11-16T19:15:00+08:00
---

# Specification: Window Above, Chronicle Desk Below — Timeline Front Screen Redesign

## Problem Statement

On the Personal Diary front screen (`TimelineScreen`), the Shanshui Scenery Card, the `OnThisDayBanner` ("岁时忆昔"), and the diary entry cards all sit as disconnected blocks on a flat background:

1. **Obstructed Landscape**: The frosted `ThoughtSparkDock` covers the lower third of the 16:9 `ShanshuiSceneryCard`, hiding the lake, ferryboat, and waterside pavilions while duplicating the inspirational Ghost Prompt experience already present inside the entry editor.
2. **Header Clutter & Non-Functional Filter**: The `岁时忆昔` retrospection banner pushes diary entries far down the viewport, while the `[My Diary ▾]` notebook selector sits above the scenery and updates only a label without filtering the timeline feed.
3. **Lack of Chronological Browsing & Spatial Depth**: Diarists cannot filter or reverse-sort entries directly on the timeline by year, month, or ten-day period (`上旬 / 中旬 / 下旬`), and the flat list lacks the tactile transition between looking out a study window and tending notes on a desk below.

## Solution

Redesign `TimelineScreen` around the classical literati spatial metaphor **「抬头观山，低头抚卷」** (*Raise your head to gaze at the scenery; lower your head to tend your scrolls*):

1. **Unobstructed Upper Window & `Bamboo Blind Pull-Cord` (`竹帘流苏拉绳`)**: Remove `ThoughtSparkDock` and the poetic header row above the scenery so the `ShanshuiSceneryCard` renders as a full 16:9 recessed Jiangnan wooden window (`轩窗`). Replace the generic collapse chevron with a draggable and tappable **Bamboo Blind Pull-Cord** on the top-left that unrolls a slatted **Xiangfei Bamboo Blind (`湘妃竹帘`)** before folding the window into a `44dp` bamboo-slat bar.
2. **Merged `Window Sill Ledge` (`窗台案沿`)**: Separate the distant window above from the workspace below with a single carved wooden sill and brass-bracketed ledge bearing the four decorative study ornaments (**`案沿清供`**: welcoming pine bonsai, calligraphy brush stand, interactive brass candlestick toggling warm desk glow, and celadon incense burner), removing the `OnThisDayBanner` / `SerendipityRouletteCard` retrospection feature completely.
3. **Lower `Chronicle Desk` (`案头卷匣`) with Sticky Scroll Physics**: Unify everything below the sill into an elevated desk mat surface. Scrolling down gently fades out the upper window and sill while pinning the Desk Header and filter tray at the top of the viewport.
4. **3-Row `Date Index Tray` (`案头岁时检目`) & Charm/Tag Filter**: Dock a chronological filter and sorter tray inside the pinned Desk Header—filtering by **Year (`纪年`)** + sort order (`最新 ↓` / `最早 ↑`), **Month (`月令`)** with entry-presence cinnabar dots, and progressively disclosed **Ten-Day Period (`三旬`: `上旬 / 中旬 / 下旬`)**—and replace the timeline `[My Diary ▾]` stub with a functional **Charm & Tag Filter** (`[🏷️ 全部笺签 ▾]`) across Mood, Weather, Media, and Weekly Review traits.
5. **Two-Tier `EntrySummaryCard` & `Wet-Mounted Thumbnail` (`册页平裱`)**: Restyle entry cards into folded Xuan-paper slips with faint vertical vermilion ruling, a full-width title and metadata header above a hairline divider (without the old cinnabar dot), and a silk-brocade framed `Wet-Mounted Thumbnail` with 45° mitered corner seams (without any overlapping red seal).

## User Stories

### Unobstructed Window & Bamboo Blind Collapse

1. As a diarist opening the timeline, I want the `ShanshuiSceneryCard` to be completely free of the Thought Spark overlay and poetic text banner above it, so that the full 16:9 landscape—lake, ferryboat, and waterside pavilions—is unobstructed.
2. As a diarist, I want the `ShanshuiSceneryCard` framed inside a slim wooden window perimeter (top bamboo valance, subtle side wood molding, light beams, and bottom balustrade) without heavy octagonal corner masks or hanging lanterns, so that the room framing feels authentic without hiding the procedural painting.
3. As a diarist, I want to tap the landscape painting to open `ContemplationViewScreen` and tap the realm badge to open the Scenery Realm switcher, so that all existing scenery controls stay accessible.
4. As a diarist, I want a hanging braided silk **Bamboo Blind Pull-Cord** (`竹帘流苏拉绳`) with a jade bead and crimson tassel at the top-left of the window, so that collapsing the scenery feels like pulling a real curtain cord.
5. As a diarist, I want dragging the pull-cord downward to extend the cord and smoothly unroll the slatted **Xiangfei Bamboo Blind (`湘妃竹帘`)** proportionally across the window, with a micro-label indicating when the pull passes the release threshold (`松手收窗 ✓`), so that the gesture feels tactile and responsive.
6. As a diarist, I want releasing the pull-cord before the threshold (after dragging) to spring both the cord and blind gently back up, so that accidental short drags do not collapse my window.
7. As a diarist, I want either tapping the pull-cord or dragging it past the threshold to drop the bamboo blind down to the sill and then shrink the window smoothly into a `44dp` slatted bamboo bar (`竹帘低垂`), so that my `Chronicle Desk` rises to give me more reading space.
8. As a diarist with the blind lowered (`44dp` bar), I want tapping the bar (`拽绳卷帘 ↑`) to expand the window frame back to 16:9 first and then roll the bamboo blind back up, so that revealing the scenery mirrors closing it.
9. As a diarist returning to the app, I want my window collapsed/expanded preference to remain persisted via `ScenerySettingsService`, so that my preferred viewing posture is remembered.

### Merged Window Sill Ledge & Desk Ornaments

10. As a diarist, I want a single compact carved wooden **Window Sill Ledge** (`窗台案沿`) with brass corner brackets separating the upper window from the lower `Chronicle Desk`, so that the boundary between distant view and foreground desk is unmistakable without wasting vertical space.
11. As a diarist, I want the four study ornaments (**`案沿清供`**)—welcoming pine bonsai and calligraphy brush stand on the left, brass candlestick and celadon incense burner on the right—resting gracefully on the ledge without duplicate modals or `忆昔` badges, so that the study feels inhabited and calm.
12. As a diarist reading at night or in dark mode, I want tapping the **Brass Candlestick** to toggle its flickering flame and cast a subtle warm radial amber candlelight glow across the top of the `Chronicle Desk`, so that the desk atmosphere responds to my touch.

### Chronicle Desk, Sticky Scroll Physics & Removals

13. As a diarist, I want `OnThisDayBanner` and `SerendipityRouletteCard` (`岁时忆昔`) completely removed from the timeline, while keeping the three AppBar octagonal medallions (`周志复盘`, `检索墨痕`, `设置与私隐`) intact, so that entries sit higher on the screen and existing navigation stays reliable.
14. As a diarist ready to write, I want the existing `ScrollRollerFab` (`挥毫落墨 Write Diary`) preserved without redesign and opening `EntryEditorScreen` directly (with no intermediate quick-write or Thought Spark modal), so that starting a new entry remains one tap.
15. As a diarist scrolling down into older entries ("lowering my head"), I want the upper window and `Window Sill Ledge` to scroll up and softly fade out while the Desk Header and `Date Index Tray` pin cleanly at the top of the viewport, so that filtering and reading remain unobstructed.
16. As a diarist scrolling back to the top ("raising my head"), I want the window and `Window Sill Ledge` to glide smoothly back into view, so that I effortlessly return to contemplating the landscape.
17. As a diarist using either light (`宣纸胡桃`) or dark (`碑拓乌木`) appearance, I want the `Chronicle Desk` surround, inlaid felt/linen desk mat, wood sill, and brass accents to harmonize with `InkDiaryTokens`, so that both themes feel cohesive.

### Charm & Tag Filter (Replacing Timeline Notebook Selector)

18. As a diarist, I want the confusing `[My Diary ▾]` notebook selector removed from the timeline and replaced on the top-right of the `Chronicle Desk` header by a Begonia-framed **`[🏷️ 全部笺签 ▾]`** Charm & Tag Filter button, so that filtering entries reflects real entry attributes rather than an unused notebook label.
19. As a diarist, I want tapping the Charm & Tag Filter button to open a sheet letting me filter the timeline by **Mood (`心绪`: 欢欣 / 怡然 / 静穆 / 倦怠 / 沉郁)**, **Weather (`天时`: 晴明 / 阴翳 / 润雨 / 朔风 / 凝雪)**, **With Media (`含图影`)**, and **Weekly Review (`周志复盘`)**, plus a one-tap clear option, so that I can find entries by mood, weather, or content type.
20. As a diarist with an active Charm or Tag filter, I want the Begonia button label and the left-side `案头卷宗 · 共 N 卷` count badge to reflect the active filter and live total count, so that I always know what subset is displayed.

### 3-Row Date Index Tray (`案头岁时检目`)

21. As a diarist, I want the **Date Index Tray** docked at the top of the `Chronicle Desk` with a Year row (`纪年`) and a right-aligned sort toggle (`最新 ↓` / `最早 ↑`), so that I can jump to any year or reverse chronological order in one tap.
22. As a diarist, I want Row 1 to display `[全部]` followed by every year present in my entries (plus the current year) with its lunar stem-branch label (e.g. `2026 丙午`), so that the selector adapts to my real diary history.
23. As a diarist, I want Row 2 to display a horizontally scrollable strip of months (`1月`–`12月`), with a small cinnabar ink dot (`•`) beneath every month that contains at least one entry matching the active Year and Charm filters, so that I never tap blindly into empty months.
24. As a diarist tapping a Month chip while Year is set to `全部`, I want the tray to automatically select the most recent year that has entries (or the current year) and scroll the selected month chip into view, so that month filtering is immediately meaningful.
25. As a diarist, I want Row 3—the Ten-Day Period selector (**`三旬`**: `上旬 初一–初十`, `中旬 十一–二十`, `下旬 廿一–晦日`)—to remain collapsed by default and smoothly expand only when a specific month is selected, so that vertical space is conserved until I drill into a month.
26. As a diarist, I want tapping an active `旬` segment to toggle it off back to the full month, and tapping `全部` on Row 1 or tapping the active Month chip again to clear the month and smoothly collapse Row 3, so that stepping back out is effortless.
27. As a diarist launching the app, I want the `Date Index Tray` to default to `全部` (All Years, no month selected, `三旬` collapsed, sorted `最新 ↓`), so that my latest entries always appear immediately even on the first day of a new month.
28. As a diarist whose active date or charm filters match zero entries (while entries exist in the database), I want to see a compact `"此岁时检目下暂无案头卷宗"` empty card with a 1-tap `[清除筛选]` reset button instead of the first-run `"素宣待书"` onboarding screen, so that I can recover immediately.
29. As a diarist browsing the timeline, I want a sculpted brass grommet (`黄铜绳扣`) at the bottom-left spine axis of the `Date Index Tray` directly anchoring the vertical timeline cord of `TimelineDateSpineItem`, so that the date badges look physically strung beneath the index tray.

### Two-Tier Entry Card & Wet-Mounted Thumbnail

30. As a diarist scanning my timeline, I want `EntrySummaryCard` styled as a folded Xuan-paper slip with a subtle stacked bottom edge and faint vertical vermilion ruling lines, so that cards feel like real stationery leaves resting on the desk mat.
31. As a diarist, I want `EntrySummaryCard` to use a two-tier layout: a full-width top header showing the entry title (without any leading cinnabar dot) on the left and the timestamp (`yyyy-MM-dd HH:mm`) plus Mood, Weather, Weekly Review (`W#`), or Lock indicators on the right above a hairline divider, so that long titles are never squished by photo thumbnails.
32. As a diarist, I want the lower tier of `EntrySummaryCard` to show up to 3 lines of body snippet on the left paired with a **Wet-Mounted Thumbnail** (`册页平裱`) on the right—framed in a warm silk-brocade border with 45° corner miter seams and **no** overlapping collector's red seal stamp—so that keepsake photos look clean and classical without distracting overlays.
33. As a diarist with sealed Time Capsules, I want `TimeCapsuleCard` to adopt the matching folded Xuan-paper slip container and two-tier header alignment while keeping its privacy invariant (never exposing sealed `plainText`), so that the feed remains visually unified and secure.

## Implementation Decisions

### 1. Palette & Surface Tokens (`碑拓乌木` Dark / `宣纸胡桃` Light)

Adapted from the prototype's CSS variables to pair seamlessly with `InkDiaryTokens` without touching stationery templates:

- **Dark Mode (`碑拓乌木`)**:
  - Wood window frame & sill bevel: `#1C140F` → `#2D2018` (`light` highlight `#473325`)
  - `Window Sill Ledge` gradient: `#2C1E16` → `#19110C`, brass accents `#C8A96E` (dim `#7E6840`)
  - `Chronicle Desk` surround: `#1D150F` → `#120D09`
  - Desk mat / tray / card stack: mat `#181816`, tray `#211F1C`, folded slip `#242320` (hover `#2C2A26`), stack lip `#36332D`, deckle border `#3D3A34`
  - Ambient candlelight radial tint: `rgba(255, 184, 77, 0.16)`
- **Light Mode (`宣纸胡桃`)**:
  - Wood window frame & sill bevel: `#3D2719` → `#593A26` (`light` highlight `#785036`)
  - `Window Sill Ledge` gradient: `#68442C` → `#4A2F1D`, brass accents `#9A7432` (dim `#B5955B`)
  - `Chronicle Desk` surround: `#DFD3C0`
  - Desk mat / tray / card stack: mat `#EAE2D3`, tray `#E2D8C5`, folded slip `#FAF6EE`, stack lip `#D4C7B0`, deckle border `#C9B99E`
  - Ambient candlelight radial tint: `rgba(255, 195, 95, 0.22)`
- **Wet-Mounted Thumbnail (`册页平裱`)**: Silk brocade frame `#E8DFCE`, outer border `#B8A689`, inner painting rule `#9A7B48`, mitered seam lines `#9C8B70` (`0.7px`).

### 2. Window & Bamboo Blind Choreography (`ShanshuiSceneryCard`)

- **Retire `ThoughtSparkDock`**: Remove `activePrompt`, `onRefreshPrompt`, `onWritePrompt`, `ThoughtSparkDock`, and the mini reveal tab from `ShanshuiSceneryCard` and `TimelineScreen`. Remove the unused `memodiary_thought_spark_hidden` preference helper (or leave persisted key untouched while deleting UI wiring).
- **Window Frame Painter / Overlay**: Render a slim perimeter wooden window casing, faint diagonal volumetric light rays (`sunbeam`), top rolled bamboo valance, and bottom exterior wooden balustrade directly around `ShanshuiSceneryPainting` without obstructing the central 16:9 canvas.
- **Bamboo Blind Pull-Cord & Slatted Blind**:
  - Positioned at top-left (`left: 10`), shifting the top-left Time/Weather and Realm overlay badges right (`left: ~60`) so nothing overlaps.
  - Cord resting length `36dp`; drag downward clamps at `92dp`, threshold `36dp`, micro-tap displacement `< 5dp`.
  - Idle sway: gentle `±1.5°` oscillation (`4200ms` period), gated off when `enableAmbientAnimation == false` or scrolled out of view.
  - **Closing choreography**: (1) Cord tugs to `76dp`; (2) Slatted bamboo blind (`湘妃竹帘`, horizontal bamboo slats + vertical crimson-gold braided silk cords + centered `竹帘垂落 · 静心抚卷` emblem + bottom rosewood/brass bar) translates vertically from `-102%` to `0%` over `440ms` (`Cubic(0.22, 1.0, 0.36, 1.0)`); (3) After `~380ms`, card height animates smoothly over `460ms` (`Cubic(0.22, 1.0, 0.36, 1.0)`) down to the `44dp` slatted bar (`拽绳卷帘 ↑` + `竹帘低垂 · <title>` + badges).
  - **Opening choreography**: (1) Card height expands smoothly back to 16:9 with blind closed; (2) After `~320ms`, blind translates upward from `0%` to `-102%` over `440ms` (`Cubic(0.22, 1.0, 0.36, 1.0)`).
  - For deterministic widget testing and reduced-motion accessibility, tapping when animations are disabled completes the collapsed/expanded transition cleanly within a standard pump cycle.

### 3. Merged `Window Sill Ledge` (`窗台案沿`)

- Implemented as a single compact custom-painted / composed widget (`~36–40dp` total height, including the carved wooden bevel lip and brass corner brackets) directly beneath `ShanshuiSceneryCard`.
- Displays four compact custom-drawn study ornaments along the ledge: Pine Bonsai (`迎客松`) and Brush Stand (`笔架`) on the left; Brass Candlestick (`黄铜烛台`) and Celadon Incense Burner (`青瓷香炉`, with rising smoke wisps gated by `enableAmbientAnimation`) on the right.
- Only the Brass Candlestick exposes a `44×44` semantic tap target (`点亮红烛 / 熄灭红烛`), toggling the flickering flame and radial amber glow overlay on the `Chronicle Desk` below.

### 4. Timeline Filter State, DAO Queries & Sticky `Chronicle Desk`

- **Filter Value Object (`TimelineFilterState`)** adapted from the prototype's state model:

```dart
enum TimelineXun { shang, zhong, xia } // 上旬 1..10, 中旬 11..20, 下旬 21..31
enum TimelineSortOrder { newestFirst, oldestFirst }

class TimelineFilterState {
  final int? year; // null == 全部
  final int? month; // 1..12, null == all months in year
  final TimelineXun? xun; // only non-null when month != null
  final TimelineSortOrder sortOrder;
  final int? mood; // 1..5
  final String? weather; // 'sunny' | 'cloudy' | 'rainy' | 'windy' | 'snowy'
  final bool hasMediaOnly;
  final bool weeklyReviewOnly;
}
```

- **State Transition Rules**:
  - `selectYear(null)` clears both `month` and `xun`.
  - `selectMonth(m)` toggles `month` off (and clears `xun`) if `month == m`; otherwise sets `month = m`, clears `xun`, and if `year == null`, promotes `year` to the latest year in `availableYears` (falling back to `DateTime.now().year`).
  - `selectXun(x)` toggles `xun` off if `xun == x`; otherwise sets `xun = x`.
  - `resetAll()` restores defaults (`year: null, month: null, xun: null, mood: null, weather: null, hasMediaOnly: false, weeklyReviewOnly: false`, preserving or optionally resetting sort order—reset button clears filters cleanly).
- **Database Queries (`EntriesDao`)**:
  - Extend `EntriesDao` with filtered timeline pagination and metadata summary queries (pure Drift SQLite predicates, no schema migration required):
    - `getFilteredTimelineEntries({TimelineFilterState filters, int limit, int offset})`: filters `isDeleted == false`, optional Gregorian `[startDate, endDate)` bounds derived from `year`, `month`, and `xun` (`1..10`, `11..20`, `21..lastDayOfMonth`), optional `mood`, `weather`, `isWeeklyReview`, optional `EXISTS` / join on `mediaAttachments` for `hasMediaOnly`, and `ORDER BY entryDate DESC/ASC`.
    - `countFilteredTimelineEntries({TimelineFilterState filters})`: powers the live `共 N 卷` count badge accurately across pagination.
    - `getTimelineDateFacetSummary({int? year, int? mood, String? weather, bool hasMediaOnly, bool weeklyReviewOnly})`: returns distinct years across all active entries (for Row 1) and the set of months `1..12` that have matching entries for the active year + charm filters (for the Row 2 cinnabar presence dots `•`).
- **Sticky Sliver Layout (`TimelineScreen`)**:
  - Replace the single `ListView.builder` with a `CustomScrollView` containing:
    1. `SliverToBoxAdapter`: `ShanshuiSceneryCard` + merged `Window Sill Ledge` (fading slightly with scroll progress via scroll offset listener).
    2. `SliverPersistentHeader(pinned: true)`: `Chronicle Desk` Header (`案头卷宗 · 共 N 卷` + `[🏷️ 全部笺签 ▾]` Begonia filter button) + 3-row `Date Index Tray` (`案头岁时检目`) + bottom brass cord grommet (`黄铜绳扣`). Dynamically updates `maxExtent`/`minExtent` as Row 3 (`三旬`) expands/collapses (`AnimatedSize` / animated sliver header height over `320ms`).
    3. `SliverList`: Filtered empty state card (if `totalInDb > 0 && entries.isEmpty`), onboarding empty state (if `totalInDb == 0`), or `TimelineDateSpineItem` wrapping `EntrySummaryCard` / `TimeCapsuleCard` + bottom pagination spinner.
- **Notebook Selector Removal from Timeline**: Remove `NotebookSelectorSheet` import/wiring from `TimelineScreen` and replace it with the new Charm & Tag Filter sheet (`ChronicleCharmFilterSheet`). `TimelineScreen` still uses the default notebook (`notebook_default` or first notebook) and its default template when creating a new entry via `ScrollRollerFab`.

### 5. Two-Tier `EntrySummaryCard` & `TimeCapsuleCard`

- **Card Geometry**: Folded Xuan-paper slip surface with subtle vertical vermilion ruling lines (`vermilionSubtle` every `28dp`), stacked-paper bottom edge (`3dp` solid bottom lip shadow), and subtle inner hairline border.
- **Tier 1 (Full-width Header)**:
  - Left: Entry title (`15.5sp`, serif bold, max 2 lines, **no cinnabar dot**).
  - Right: Timestamp (`yyyy-MM-dd HH:mm`) + Mood emoji, Weather icon, Weekly Review seal (`W#`), or Lock icon.
- **Tier 2 (Body + Thumbnail)**:
  - Left: Snippet (`maxLines: 3`, ellipsis).
  - Right (when `!isLocked && item.primaryMedia != null`): **`Wet-Mounted Thumbnail`** framed in silk brocade with 45° corner miter lines (`74×50` / `82×62` aspect framing), **no overlapping red collector's seal**.
- **Accessibility & File Size**: Clamp text scaling per `CODING_STANDARDS.md`, assign clear `Semantics` labels and `44×44` minimum tap targets to the pull-cord, candlestick, filter chips, sort button, and Charm Filter button, and keep every modified/new widget file under 450 lines by decomposing the Desk Header, `Date Index Tray`, Charm Filter Sheet, `Window Sill Ledge`, and Window Blind overlay into focused widgets.

## Testing Decisions

### What Makes a Good Test

- Tests assert **user-observable behavior only**: rendered labels, visibility/absence of removed features, filter counts and filtered list results, chronological sort order, progressive disclosure of `三旬`, persisted window collapse state, and screen navigation—never private widget state fields or `CustomPainter` coordinate internals.
- Ambient animations (cord sway, candle flicker, incense smoke) are disabled or stepped deterministically with bounded `pump(Duration)` calls rather than calling `pumpAndSettle()` on infinite tickers.
- All timeline/DAO tests run against an in-memory `AppDatabase.memory()` and `MediaSandboxService` without mocks that obscure real SQLite query filtering.

### Seams

1. **`TimelineScreen` Widget Integration Seam** (Primary — tests the full UI + `EntriesDao` filter pipeline end-to-end):
   - Verifies `ThoughtSparkDock`, `OnThisDayBanner`, `SerendipityRouletteCard`, poetic header (`岁月微澜`), and `[My Diary ▾]` notebook selector are absent from the timeline.
   - Verifies `ScrollRollerFab` (`Write Diary`) remains intact and navigates directly to `EntryEditorScreen`.
   - Verifies `Window Sill Ledge` ornaments render and tapping the Brass Candlestick toggles candlelight state cleanly.
   - Verifies **Date Index Tray** default state (`全部`, `最新 ↓`, `三旬` hidden), Year filtering, Month selection auto-promoting Year + expanding `三旬` (`上旬` / `中旬` / `下旬`), Month presence dots (`•`), toggling sort order (`最新 ↓` / `最早 ↑`), and filtered empty state with `[清除筛选]` recovery (distinct from zero-entry `"素宣待书"` empty state).
   - Verifies **Charm & Tag Filter** (`[🏷️ 全部笺签 ▾]`) filters entries by Mood, Weather, With Media, and Weekly Review.
   - Verifies two-tier `EntrySummaryCard` renders title without cinnabar dot, 3-line snippet, `Wet-Mounted Thumbnail` without seal overlay, and `TimeCapsuleCard` preserves privacy (`plainText` hidden).
2. **`ShanshuiSceneryCard` Widget Seam** (Unit/widget seam for window frame & bamboo blind choreography):
   - Verifies `ThoughtSparkDock` and prompt callbacks/widgets are gone while Realm badge switcher and `ContemplationViewScreen` tap target continue working.
   - Verifies tapping or dragging the **Bamboo Blind Pull-Cord** (`竹帘流苏拉绳`) past threshold drops the slatted bamboo blind and folds into the `44dp` bamboo-slat bar (`拽绳卷帘 ↑`), short drags spring back without collapsing, and tapping the `44dp` bar restores the expanded 16:9 window while persisting state via `ScenerySettingsService`.

### Prior Art

- `test/features/timeline/timeline_screen_test.dart` (migrate Thought Spark, OnThisDay, and NotebookSelector assertions; keep Sealed Time Capsule privacy, AppBar 3 medallions, and Write Diary FAB tests; add Date Index Tray & Charm Filter tests)
- `test/features/timeline/timeline_repository_test.dart` (add `EntriesDao` tests for Gregorian date bounds, `上旬/中旬/下旬` day ranges, sort direction, facet counts, and charm/media predicates)
- `test/features/scenery/shanshui_scenery_card_test.dart` (migrate collapse/expand tests to `Bamboo Blind Pull-Cord` tap/drag and `44dp` bamboo-slat bar)

## Out of Scope

- **Single-Page Portrait Thread-Bound Book Reader Modal (`单页线装册展读台`)** from the prototype — MemoDiary already has its dedicated `EntryDetailScreen` / `ThreadBoundFolioStage` (`SPEC-007`), which remains unchanged when tapping an entry card.
- **Quick Desk Note + Relocated Thought Spark Modal** — tapping `挥毫落墨` continues going straight to `EntryEditorScreen` (which already contains `Ghost Prompt`).
- **Synthesized Web Audio Sound Effects** — bamboo slat ticks, water drops, and seal thump audio effects are not part of the timeline scope.
- **Octagonal Moon Window (`八角月洞窗`) Toggle & Hanging Palace Lanterns** — excluded so the 16:9 `ShanshuiCanvas` stays unobstructed.
- **Removing the `Notebooks` SQLite Table or Backup Schema** — `notebooks` remains in SQLite (`entries.notebookId`) and `.mdbak` backup manifests so existing entries and backups stay 100% compatible; only the timeline UI selector is retired.
- **Deleting `OnThisDay` / `Serendipity` DAO or Retrospection files** if referenced elsewhere outside `TimelineScreen` — only their Timeline integration is removed unless confirmed unused during implementation.

## Further Notes

- **Visual Reference**: The HTML/Tailwind/SVG prototype provided in the design session (`「抬头观山，低头抚卷」江南书斋原型`) serves as the exact aesthetic, color, animation curve (`Cubic(0.22, 1.0, 0.36, 1.0)`), and structural reference.
- **Glossary Alignment**: Uses canonical terms defined in `GLOSSARY.md`: `Shanshui Scenery Card`, `Bamboo Blind Pull-Cord`, `Contemplation View`, `Scenery Realm`, `Window Sill Ledge`, `Chronicle Desk`, `Date Index Tray`, and `Wet-Mounted Thumbnail`.
- **Cost & Privacy Invariant**: 100% native Flutter `CustomPainter`, widgets, and local Drift SQLite queries (`$0` runtime/build cost, strictly offline).
