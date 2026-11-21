---
id: SPEC-023
title: Home Shell, Tab Rail and Diarist Panel
status: ready-for-agent
created_at: 2026-11-22T10:00:00+08:00
adr: ADR-0014
---

# Specification: Home Shell, Tab Rail and Diarist Panel

## Problem Statement

1. **Diary and albums live in separate worlds.** The 3D book cover (`BookIntroScreen`) is the only place to choose between the diary (`个人日记`) and the photobooks (`旅行相册`). Once inside the timeline, reaching the albums means going back to the cover and through its other door, and the album screen sits behind a back arrow as if it were a sub-page.
2. **Occasional tools are buried in Settings.** Writing Analytics (`写作统计`), the Recycle Bin (`回收站`) and the import, export and backup tools sit inside a 1,559-line Settings screen among appearance and permission options, so things the diarist opens now and then are mixed with things they configure once.
3. **No personal space.** There is no place that feels like "mine": no summary of how much has been written or collected, and no natural home for the cover shortcut, which currently takes the header's top-left spot.
4. **The app has no real icon or consistent name.** The launcher shows the default Flutter logo on both platforms, and the app name reads `MemoDiary` on iOS and on Android phones not set to Chinese, while everything inside the app says **云皓日记**.

## Solution

1. **Home Shell.** After the optional cover, the diarist lands in one Home Shell holding two tabs, **日记** (the timeline) and **相册** (the album collections). The cover stays as an opening scene only. Entering replaces it, and each cover door chooses the starting tab.
2. **Tab Rail.** A woodwork bottom bar in the active Atmosphere Palette reads **日记 · [Scroll Roller Button] · 相册**. The centre button sits raised in a notch and follows the tab: `写日记` on 日记, `新建相册` on 相册. The whole rail slides away when scrolling down and returns when scrolling up.
3. **Diarist Panel (`我的`).** A woodwork side panel slides out from the left. It opens from a cloud-avatar button at the header's top-left, or by dragging from the left edge within an upper band of the screen. It shows a placeholder profile, a stats strip (`日记` · `相册` · `收藏`), and rows for `写作统计`, `回收站`, `导入与备份` and `返回封面`. The first three move out of Settings.
4. **App icon and name.** The launcher icon becomes the night moon, ruyi clouds and open book painting supplied by the diarist, reframed for platform masks and paired with an Android 13 themed silhouette. The app is named **云皓日记** on both platforms.

## User Stories

### Cover and entering the Home Shell

1. As a diarist who keeps the opening cover on, I want the cover to play as before when I launch the app, so that the opening scene I like is unchanged.
2. As a diarist on the cover, I want no Tab Rail on screen, so that the cover stays a clean, full-screen scene.
3. As a diarist tapping `个人日记` on the cover, I want to land in the Home Shell on the 日记 tab, so that the door I picked is respected.
4. As a diarist tapping `旅行相册` on the cover, I want to land in the Home Shell on the 相册 tab, so that I reach my albums in one step.
5. As a diarist who entered from the cover, I want the cover to be replaced rather than kept underneath, so that an edge swipe or Back never drops me onto it by accident.
6. As a diarist who turned the cover off, I want the app to open straight into the Home Shell on the 日记 tab, so that I start writing without a detour.
7. As a diarist who wants to see the cover again, I want a `返回封面` row in the Diarist Panel, so that the cover is one deliberate tap away.
8. As a diarist tapping `返回封面`, I want the Home Shell replaced by the cover, so that routes never pile up when I go back and forth.
9. As a diarist returning to the cover and entering again, I want to land on the tab matching the door I tap, so that the cover keeps working as a two-door entrance.

### Tab Rail

10. As a diarist on the Home Shell, I want a bottom bar reading 日记 · [centre button] · 相册, so that I can switch between my diary and my albums with one tap.
11. As a diarist, I want the selected tab marked clearly by colour and weight, so that I always know where I am.
12. As a diarist, I want the Tab Rail drawn as woodwork in my active Atmosphere Palette, matching the header's casement frame, so that the screen reads as one framed window, top and bottom.
13. As a diarist switching theme style or light/dark mode, I want the Tab Rail to recolour immediately, so that it never looks out of place.
14. As a diarist switching tabs, I want each tab to keep its state (the timeline's scroll position, date filters, charm filter and open or closed scenery window), so that I can glance at albums and come back to exactly where I was.
15. As a diarist opening 相册 for the first time in a session, I want it to load only then, so that launching the app stays fast.
16. As a diarist, I want to switch tabs only by tapping, so that sideways swipes never fight the Diarist Panel drag or the scenery window.
17. As a diarist on the 相册 tab, I want no back arrow in its header, so that it reads as a peer of the diary rather than a sub-page.
18. As a diarist scrolling down the timeline or album list, I want the whole Tab Rail, centre button included, to slide away, so that I get the full screen for reading.
19. As a diarist scrolling back up, I want the Tab Rail to slide back in, so that switching and writing are always close at hand.
20. As a diarist switching tabs while the rail is hidden, I want the rail to reappear, so that I can see where I landed.
21. As a diarist whose list is too short to scroll, I want the Tab Rail always visible, so that it never gets stuck hidden.
22. As a diarist opening an entry, the editor, weekly review, search, settings or any album sub-screen, I want those screens to cover the Tab Rail, so that focused screens stay uncluttered, as they are today.

### Scroll Roller Button

23. As a diarist on the 日记 tab, I want the raised centre button to read `写日记` and open a new entry, so that writing is one tap away as before.
24. As a diarist on the 相册 tab, I want the centre button to read `新建相册` and open the create-album sheet, so that starting a photobook is just as close.
25. As a diarist switching tabs, I want the centre label to cross-fade between `写日记` and `新建相册`, so that the change is visible but calm.
26. As a diarist who creates an entry or album from the centre button, I want the current tab's list to refresh afterwards, so that my new item appears immediately.
27. As a diarist on the 相册 tab, I want the album screen's own `新建相册` buttons (the floating button and the empty-state button) gone, so that there is exactly one way to create an album.
28. As a diarist with an empty album list, I want the empty state to point me at the centre `新建相册` button, so that I know how to start.

### Diarist Panel: opening and closing

29. As a diarist, I want a small cloud-avatar button at the header's top-left on both tabs, so that I can open my panel with one obvious tap.
30. As a diarist, I want to drag the panel out from the left edge in the upper part of the screen (around the header and scenery window), so that opening it feels natural.
31. As an Android diarist using gesture navigation, I want left-edge swipes in that upper band to open the panel, and left-edge swipes lower down to remain the system Back gesture, so that I keep Back where I expect it.
32. As a diarist with the panel open, I want the page behind it dimmed and shifted slightly with a strip still visible, so that I know where I will return.
33. As a diarist, I want to close the panel by tapping the visible strip or swiping it back to the left, so that dismissing it is effortless.
34. As an Android diarist with the panel open, I want Back to close the panel first, so that Back behaves predictably.
35. As a diarist, I want the panel drawn as a casement-woodwork screen in my active Atmosphere Palette, so that it belongs to the same window as the header and Tab Rail.
36. As a diarist, I want the panel about 85% of the screen wide, so that it feels like a page of its own while the app behind stays in view.

### Diarist Panel: contents

37. As a diarist opening the panel, I want a profile block at the top with a round cloud avatar, the name `云皓主人` and the line `记录今日，也收藏远方`, so that the panel feels personal even before real profiles exist.
38. As a diarist, I want that profile block to be display-only for now, so that nothing pretends to be editable before profile features arrive.
39. As a diarist, I want a stats strip showing `日记`, `相册` and `收藏` with counts, so that I see at a glance how much I have kept.
40. As a diarist, I want `日记` to count every entry not in the Recycle Bin, including weekly reviews and time capsules, so that it matches `总篇数` in Writing Analytics.
41. As a diarist, I want `相册` to count my album collections, so that my photobook collection is visible.
42. As a diarist, I want `收藏` shown as a dimmed dash, so that it reads as "not available yet" rather than a broken zero.
43. As a diarist, I want the counts refreshed every time I open the panel, so that they reflect entries or albums I just added or deleted.
44. As a diarist, I want tapping `日记` or `相册` in the strip to close the panel and switch to that tab, so that the numbers double as shortcuts.
45. As a diarist, I want tapping `收藏` to do nothing, so that it does not lead to an empty screen.
46. As a diarist, I want a `写作统计` row that opens the Writing Analytics screen, so that my writing metrics are one tap from my personal space.
47. As a diarist, I want a `回收站` row that opens the Recycle Bin, so that recovering a deleted entry is easy to find.
48. As a diarist, I want an `导入与备份` row that opens a screen holding `导入文本`, `导出日记`, the last-backup time, `导出加密备份` and `从备份恢复`, so that all my data-moving tools live together.
49. As a diarist, I want a `返回封面` row as the last item, so that revisiting the cover is deliberate and out of the way.
50. As a diarist returning from any screen opened from the panel, I want to come back to the Home Shell with my tab state intact, so that the panel never costs me my place.

### Settings after the move

51. As a diarist opening Settings, I want `写作统计`, `回收站` and the import/export section gone, so that Settings holds only things I configure.
52. As a diarist, I want the rest of Settings (opening cover, appearance theme, signature seal, storage cleanup, reminders, permissions, privacy) unchanged, so that nothing I rely on moves unexpectedly.
53. As a diarist, I want 每周复盘, 搜索 and 设置 to stay in the timeline header, so that my daily tools stay where they are.

### Android Back on the Home Shell

54. As an Android diarist on the 相册 tab, I want Back to switch to the 日记 tab, so that Back walks me home before leaving.
55. As an Android diarist on the 日记 tab, I want Back to exit the app, so that it behaves like any root screen.
56. As an Android diarist, I want Back on the Home Shell never to reopen the cover, so that the cover only appears when I ask for it.

### App icon and name

57. As a diarist looking at my home screen, I want the 云皓日记 icon (glowing moon, ruyi clouds, open book on a night sky) instead of the Flutter logo, so that the app looks finished and recognisable.
58. As an Android diarist, I want the icon to keep its moon, clouds and book inside any launcher mask (circle, squircle, rounded square), so that nothing important is cropped.
59. As an iOS diarist, I want a correct full-bleed icon without transparency, so that it passes App Store checks and looks right on the home screen.
60. As an Android 13+ diarist using themed icons, I want a single-colour silhouette of the moon, clouds and book, so that the icon follows my wallpaper colours like other apps.
61. As a diarist whose phone is set to English or another language, I want the app named 云皓日记 under its icon and in the app switcher, so that the name matches the app everywhere.

### Accessibility

62. As a screen-reader user, I want the cloud-avatar button announced as `我的` with button semantics, so that I can find the panel without seeing it.
63. As a screen-reader user, I want the panel announced when it opens and its stats read as label plus count (e.g. `日记 128`), and `收藏` announced as unavailable, so that the strip makes sense spoken aloud.
64. As a screen-reader user, I want the Tab Rail tabs announced as tabs with their selected state, and the centre button announced with its current label, so that I always know what each control does.
65. As a diarist with large text (1.3×) on a narrow phone (320dp), I want the Tab Rail, stats strip and panel rows to fit without overflow, and every control to have at least a 44×44dp tap target, so that the new structure works for me.
66. As a diarist with system animations reduced, I want the panel, rail hide and label cross-fade to respect reduced motion, so that movement never bothers me.

## Implementation Decisions

### 1. Navigation topology

- A new **Home Shell** screen becomes the app's root once the cover is passed. It takes the same dependencies the timeline takes today (database, media sandbox service, OCR queue manager) plus an initial tab (`日记` or `相册`).
- The app's home is the cover when `showIntroOnLaunch` is on, otherwise the Home Shell on 日记.
- The cover's two doors **replace** the cover with the Home Shell (initial tab 日记 or 相册) instead of pushing on top of it. The cover's "reset sky on return" behaviour is no longer needed, because the cover is rebuilt fresh whenever it is shown.
- `返回封面` (in the Diarist Panel) replaces the Home Shell with the cover, passing the same dependencies. This retires SPEC-022's pop-or-replace rule on the timeline header.
- There is one Navigator. Every screen opened from a tab or from the panel is pushed on the root Navigator, so it covers the Home Shell, Tab Rail and panel. No nested navigators.
- Android Back on the Home Shell, handled by the shell's pop interception: panel open → close panel; else 相册 tab → switch to 日记; else let the system pop (exit app). Never reopens the cover.

### 2. Home Shell and tabs

- Tabs are held in an indexed stack, so both stay alive and keep their state. The 相册 tab is built lazily the first time it is selected.
- Switching is tap-only on the Tab Rail. No horizontal paging between tabs.
- **Primary action contract:** each tab exposes its primary action (create entry, create album) to the shell, so the centre button triggers the tab's existing create flow and the tab refreshes its own list afterwards. Create flows stay inside their tabs; the shell knows nothing about entries or albums.
- `TimelineScreen` drops its own floating `ScrollRollerFab` and its roll-up state. Its header's top-left `返回封面` emblem is replaced by the cloud-avatar button that opens the Diarist Panel. The three right-hand medallions (每周复盘, 搜索, 设置) are unchanged.
- `AlbumCollectionsScreen` drops its back arrow, its floating `新建相册` button and its empty-state `新建相册` button (displacement, per `CODING_STANDARDS.md` § 3). Its header gains the same cloud-avatar button. Its empty-state copy points at the centre button.

### 3. Tab Rail

- A bottom bar with three slots: `日记` tab, raised **Scroll Roller Button** in a centre notch, `相册` tab. It sits above the system bottom inset.
- Colours come from the active `AtmospherePalette`: rail surface from the woodwork tokens (`woodFrameDark` / `woodFrameMid` / `woodFrameHighlight`) with a light hairline, selected tab in `headerTitleText` plus an `accentPrimary` mark, unselected tabs muted. The centre button keeps the existing `fabGradient` / `fabBorder` / `fabText` tokens.
- **Hide on scroll:** the shell listens for vertical user-scroll notifications bubbling up from the active tab. Scrolling forward (down the list) hides the whole rail including the centre button, and scrolling back reveals it. The rail is revealed on tab switch, when the list is not scrollable, and whenever reduced motion is on (shown, not animated).
- The centre label cross-fades between `写日记` and `新建相册` on tab switch.
- The existing `ScrollRollerFab` widget is reused for the centre button, and its standalone roll-up mode is removed if nothing else uses it.

### 4. Diarist Panel

- A custom side panel (not the stock `Scaffold` drawer, whose edge drag covers the full screen height) about 85% of the screen wide, drawn as a casement-woodwork screen in the active Atmosphere Palette. It opens over the whole Home Shell, header and Tab Rail included. The content behind dims and shifts slightly. Tap-scrim or swipe-left closes it.
- **Opening:**
  - The cloud-avatar header button on either tab.
  - A left-edge drag (≈20dp wide) limited to an upper band starting at the top of the safe area, at most 200dp tall, covering the header and scenery window.
- **Android Back-gesture exclusion:** Flutter has no public API to reserve edge regions from Android's system Back gesture. Add a small native method channel (alongside the existing `memodiary/ocr` channel) through which the Home Shell reports the left-edge band rectangle to the Activity, which applies it as a system gesture exclusion rect. Android honours at most 200dp of exclusion per edge, which is why the band is capped there. The shell sets the band while it is the visible route and clears it when another route covers it. iOS needs no exclusion, because the Home Shell is a root route with no swipe-back.
- **Placeholder profile:** a drawn round cloud avatar (reusing the Cloud-Moon emblem drawing style), the fixed name `云皓主人` and the fixed line `记录今日，也收藏远方`. Display-only, nothing persisted, no profile model. These are constants to be replaced by a future profile spec.
- **Stats strip:** a small read model supplies two counts from the repository layer: active entries (not soft-deleted, including weekly reviews and time capsules, the same rule as Writing Analytics' `总篇数`) and album collections. The counts are fetched each time the panel opens. `收藏` renders a dimmed `—` with no tap action. Tapping `日记` or `相册` closes the panel and selects that tab.
- **Rows (in order):** `写作统计` (opens `AnalyticsDashboardScreen`), `回收站` (opens `RecycleBinScreen`), `导入与备份` (opens a new Import & Backup screen), `返回封面`.
- The panel's own status-bar styling uses light icons over the woodwork, as the timeline header does.

### 5. Settings extraction

- Remove the `写作统计` tile and the whole `导入与导出` section from `SettingsScreen`, and the `回收站` tile from its storage card. The Recycle Bin count shown on that tile moves out of Settings with it.
- The import/export section's contents (`导入文本`, `导出日记`, last-backup time, `导出加密备份`, `从备份恢复`) move unchanged in behaviour into a new **Import & Backup** screen titled `导入与备份`. The import, backup and restore logic moves with them, so Settings no longer owns it. This is a move, not a copy.
- The remaining Settings sections are untouched. This extraction is expected to bring `SettingsScreen` substantially closer to the `< 450` LOC standard. Any further decomposition is welcome but not required by this spec.

### 6. App icon and name

- **Source artwork:** the diarist-supplied 1024×1024 night-moon painting (navy sky, glowing moon, outlined ruyi clouds with a smoke wisp into an open book, side clouds, landscape page, red seal, ribbon). The diarist holds the rights to it (provenance recorded in ADR 0014). The source and the reframed master are committed with the generator so the icons are reproducible.
- **Reframing:** scale the subject to about 72% of its current size, centred and lifted slightly, on a sky extended with the painting's own navy-to-slate gradient. This keeps the moon, both outlined clouds and the book inside Android's 66/108 adaptive safe zone and clear of the iOS corner mask. The tips of the side clouds may clip on Android.
- **Human approval gate:** before committing generated icons, produce previews at 48px and 180px under Android circle and squircle masks and the iOS rounded-square mask, and get the diarist's approval.
- **Android:** an adaptive icon whose background layer is the full reframed painting with a transparent foreground (no parallax), legacy square and round PNGs at every density, and a **monochrome** layer: a flat single-colour silhouette of the moon disc, two ruyi clouds and an open book, drawn in Dart and rendered to PNG by a committed tool script.
- **iOS:** the full AppIcon set from the reframed master, 1024px without alpha.
- **Tooling:** a free (MIT) build-time icon generator (e.g. `flutter_launcher_icons`) as a dev dependency. Format conversion from WebP and silhouette rendering use Flutter/Dart (no host imaging tools are available). Nothing ships at runtime.
- **Name:** `云皓日记` for the iOS display name, the Android default-locale app label (the `zh` label already says so) and `MaterialApp.title`.

### 7. Glossary and ADR

- Add **Home Shell**, **Tab Rail**, **Diarist Panel** and **Scroll Roller Button** to `GLOSSARY.md`.
- ADR 0014 records the move from cover-as-hub to Home Shell, the Back-gesture exclusion channel, and the icon's provenance.

## Testing Decisions

Good tests drive the app the way a diarist does (pump the app, tap, drag, press Back, read what is on screen and in semantics) and assert visible outcomes. They do not assert private widget fields, animation controller values or which internal widget class sits where.

1. **App seam: `MemoDiaryApp` with an in-memory database (primary).** Prior art: the app smoke tests at the root of the test suite, `book_intro_screen_test`, `timeline_screen_test`, `album_collections_screen_test`. Cover:
   - cover on: the cover shows with no Tab Rail; each door lands on the right tab, and the cover is gone from the route stack afterwards.
   - cover off: the app opens on the 日记 tab.
   - `返回封面` from the panel shows the cover, and re-entering works.
   - tab switching preserves the timeline's scroll offset and filters; 相册 builds only on first selection.
   - the centre button reads `写日记` or `新建相册` per tab and opens the entry editor or the create-album sheet; the list refreshes after creating.
   - scrolling hides the rail and scrolling back reveals it; a tab switch reveals it.
   - the panel opens from the avatar button and from an edge drag inside the band, and not from an edge drag below the band; it closes via the scrim, a swipe and Back.
   - stats show correct counts after seeding entries (including a weekly review, a time capsule and a soft-deleted entry) and albums; `收藏` shows `—`; tapping `日记` or `相册` switches tabs.
   - each panel row opens its screen, and returning keeps tab state.
   - Back order via the binding's pop-route handling: panel → 相册 to 日记 → exit.
   - semantics labels and selected states; no overflow at 320dp and 1.3× text scale.
2. **Platform channel seam: the Back-gesture exclusion bridge**, faked with a mock method-channel handler inside the app-seam tests. Prior art: OCR channel fakes in the OCR test suite. Assert that the shell sends a left-edge band at most 200dp tall when it becomes visible, and clears it when a pushed screen covers it.
3. **Platform config seam: a small hardening test** that reads the iOS and Android platform config files and asserts the app name is `云皓日记`, and that the adaptive icon, its monochrome layer and the iOS 1024 icon exist. Prior art: the existing hardening tests (e.g. the PDF network quarantine and manifest checks). Icon artwork quality is verified by the human approval gate, not by automated tests.
4. **Updated existing tests:**
   - `settings_screen_test` asserts `写作统计`, `回收站` and the import/export section are absent.
   - `timeline_app_bar_test` replaces its `返回封面` tests with avatar-button tests.
   - `album_collections_screen_test` asserts no back arrow and no own `新建相册` buttons.
   - backup and import widget tests (e.g. `backup_dialogs_test`) follow the moved section to the Import & Backup screen.

## Out of Scope

- A real profile: editable name, photo avatar, motto, persisted profile model.
- Favourites (`收藏`) as a feature, drafts (`草稿箱`), and anything resembling publishing (`发布`). The app stays local-first with zero backend.
- Additional tabs (复盘, 搜索, 我的) or moving 每周复盘, 搜索 or 设置 out of the timeline header.
- Swipe paging between tabs.
- Visual changes to the cover itself, beyond its doors replacing rather than pushing.
- A "我的画册" carousel in the panel (the 相册 tab already serves this).
- A parallax-layered adaptive icon or a vector redraw of the painting.
- Further decomposition of `SettingsScreen` beyond the extraction above.

## Further Notes

- Domain terms (**Home Shell**, **Tab Rail**, **Diarist Panel**, **Scroll Roller Button**) are recorded in `GLOSSARY.md`. The rationale is in `docs/adr/0014-home-shell-navigation-and-diarist-panel.md`.
- The icon source is kept at `.scratch/home-shell-tab-rail-and-diarist-panel/notes/app-icon-source.webp` for implementers. The committed copy is created by the icon ticket.
- The icon and name work shares no code with the shell, rail and panel work and can proceed in parallel.
- SPEC-022's timeline-header `返回封面` button and its pop-or-replace routing are superseded by this spec.
