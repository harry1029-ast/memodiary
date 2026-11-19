---
id: SPEC-022
title: Dual-Atmosphere Theme System and Yunhao Timeline Overhaul
status: completed
created_at: 2026-11-19T23:36:00+08:00
adr: ADR-0013
---

# Specification: Dual-Atmosphere Theme System and Yunhao Timeline Overhaul

## Problem Statement

1. **Unfinished Brand & Cover Navigation on the Timeline**: Although the 3D cover intro now presents **云皓日记** (`云伴皓光，收录旅途与心事`), the timeline app bar still displays `"MemoDiary"` and `"个人离线日记"` beside a static `"墨记"` seal that gives the diarist no noticeable way to return to the 3D book cover once inside the diary.
2. **Rigid Single-Pair App Theme**: The app supports only one fixed Light/Dark aesthetic (`宣纸胡桃` / `碑拓乌木`). Diarists cannot choose the signature Cloud-Moon aesthetic (`云岚昼` / `皓月夜`), keep the original walnut-and-ebony aesthetic side-by-side, or mix custom Light and Dark palettes (including experimental ink/lantern palettes like `淡墨暮岚`, `清辉烟雨`, and `花影灯火`).
3. **Crowded Curtain Bar & Duplicate Window Labels**: When the living scenery curtain is pulled down into its compact `44dp` bar, it squeezes five overlapping elements into a single row (`拽绳卷帘 ↑`, `竹帘低垂 · ...`, `[时间 · 天气]`, `[画卷场景]`, and `[季节徽章]`), repeating information that is unhelpful while the window is folded. Similarly, the expanded window overlay repeats both a 4-character poetic title and a seasonal seal badge.

## Solution

Deliver a cohesive **Atmosphere Theme** system alongside a clean, Cloud-Moon-branded timeline overhaul built atop the existing `Shanshui Scenery Card`, `Window Sill Ledge`, and `Chronicle Desk` architecture:

1. **Two-Axis Atmosphere Theme System (`主题风格` × `外观模式`)**:
   - Preserve `外观模式` (`跟随系统` / `浅色模式` / `深色模式`).
   - Add **`主题风格`** presets: **`云皓`** (default: `云岚昼` Light + `皓月夜` Dark), **`经典`** (`宣纸胡桃` Light + `碑拓乌木` Dark), and **`自定义`** (independent Light and Dark palette pickers stored separately across restarts).
   - Provide **3 Light Palettes** (`云岚昼`, `宣纸胡桃`, `淡墨暮岚`) and **4 Dark Palettes** (`皓月夜`, `碑拓乌木`, `清辉烟雨`, `花影灯火`), separating general interactive accents (`accentPrimary`, e.g., lantern amber or cerulean) from precious seal cinnabar (`sealAccent`).
   - Propagate all 7 palettes across `MaterialApp`, desktop/screen surfaces, window woodwork framing, bamboo blind slats & pull-cord tassel, `Window Sill Ledge`, `Chronicle Desk`, entry slips, spine tallies, `WetMountedThumbnail` silk mounts, and `ScrollRollerFab` (while preserving `'写日记'` label copy and keeping the 3-realm scenery painting engine + entry stationery templates untouched).
2. **Casement Woodwork Header & Back-to-Cover Emblem Button**:
   - Style `TimelineAppBar` with the active palette's dark window-frame woodwork surface and light ivory typography across both Light and Dark modes, integrating the header visually with the upper window casement.
   - Retire `"MemoDiary"` and `"个人离线日记"`; display **`云皓日记`** + **`YUNHAO`** on the title row and **`云伴皓光 · 收录旅途与心事`** below.
   - Replace the static `"墨记"` seal with a prominent interactive **`[‹ Cloud-Moon Emblem]`** button (`返回封面`) that pops back to the cover intro when pushed from it, or navigates to it when the timeline launched directly as the root screen.
3. **De-Cluttered Collapsed Curtain Bar & Window Overlay**:
   - Simplify the collapsed `44dp` curtain bar to show only **`[● 拽绳卷帘 ↑]`** on the left and **`[时间 · 天气]`** on the right—removing the redundant title phrase, `[画卷场景]` pill, and duplicate seasonal seal.
   - On the expanded window overlay, keep **`[时间 · 天气]`** and **`[画卷场景]`** on the left and a single compact seasonal badge on the right (removing the duplicate 4-character poetic phrase).
   - Omit the prototype's upper poetic header bar above the window, hanging palace lanterns inside the window, and retired archaic/fluff copy.
4. **Chronicle Desk & Entry Card Polish**:
   - Add a miniature **lunar-phase icon** (derived from lunar day) at the top of each `WaistTally` spine badge.
   - Restore a compact 2×2 **`云皓珍藏`** collector seal (`sealAccent`) in the bottom-left corner of `WetMountedThumbnail` paired with palette-harmonized silk mounts.

## User Stories

### Two-Axis Atmosphere Theme System & Presets

1. As a diarist opening **Settings → 外观主题**, I want to choose both my **Appearance Mode** (`跟随系统`, `浅色模式`, `深色模式`) and my **Theme Style** (`主题风格`: `云皓`, `经典`, `自定义`), so that my preferred visual palette still adapts automatically between daytime and nighttime when `跟随系统` is enabled.
2. As a new or existing diarist after updating the app, I want `云皓` (`云岚昼` Light + `皓月夜` Dark) to be active by default, so that the app matches the new **云皓日记** identity out of the box.
3. As a diarist who loves the original warm walnut-and-cinnabar paper workspace, I want to select `经典` (`宣纸胡桃` Light + `碑拓乌木` Dark) in one tap, so that I can keep the classic look unchanged.
4. As a diarist who enjoys mixing atmospheres, I want selecting `自定义` to reveal a **Light Palette** picker (`浅色色板`: `云岚昼`, `宣纸胡桃`, `淡墨暮岚`) and a **Dark Palette** picker (`深色色板`: `皓月夜`, `碑拓乌木`, `清辉烟雨`, `花影灯火`), so that I can freely pair any light and dark palette.
5. As a diarist switching from `自定义` to `云皓` or `经典` and later back to `自定义`, I want the app to remember my previously chosen custom light and dark palettes, so that I do not have to re-pick my pairing every time.
6. As a diarist relaunching the app, I want my selected `ThemeStyle`, custom light palette, and custom dark palette persisted securely across app restarts, so that my chosen atmosphere loads immediately on startup.
7. As a diarist using `皓月夜`, `清辉烟雨`, `花影灯火`, or `淡墨暮岚`, I want interactive UI accents (selected filter chips, featured date badges, timeline cords, FAB highlights) to use the palette's primary accent while reserving true vermilion/cinnabar strictly for seals and stamps (`云皓珍藏`, lock seal), so that buttons and photos remain harmonious without visual red fatigue.
8. As a diarist browsing **Settings**, **Search**, **Weekly Review**, **Analytics**, **Recycle Bin**, or the desk surround behind the **Entry Editor** and **Thread-Bound Folio**, I want all UI surfaces, cards, borders, and chips to follow my active `AtmospherePalette`, so that the entire app feels unified.
9. As a diarist writing or reading an entry, I want changing the app-wide `AtmosphereTheme` to leave my entry's saved stationery template (`StationerySheet`) and `ReadingPerspective` untouched, so that switching light/dark atmosphere never alters my handwritten/styled diary content.
10. As a diarist looking through the `Shanshui Scenery Card` window glass, I want the existing 3-realm procedural painting (`山水` / `室内` / `街市` across seasons, times of day, and weather) and tap-to-open `ContemplationView` preserved regardless of which UI palette I pick, while the wooden casement frame, bamboo blind slats, and pull-cord tassel adopt the active `AtmospherePalette`.

### Yunhao Timeline Header & Back-to-Cover Navigation

11. As a diarist viewing the timeline in either Light or Dark mode, I want `TimelineAppBar` rendered on the active palette's dark window-frame woodwork surface with high-contrast light text and subtle woodwork-toned action buttons, so that the top bar forms a continuous wooden casement lintel above the scenery window.
12. As a diarist glancing at the timeline header, I want it to display **`云皓日记`** alongside **`YUNHAO`** and the subtitle **`云伴皓光 · 收录旅途与心事`** instead of `"MemoDiary"` and `"个人离线日记"`, so that the app branding is consistent from cover to timeline.
13. As a diarist wanting to return to the 3D cover screen, I want the old static `"墨记"` seal replaced by an unmistakably interactive **`[‹ Cloud-Moon Emblem]`** back-to-cover button (`返回封面`), so that navigating back to `BookIntroScreen` is discoverable in one tap.
14. As a diarist who entered the timeline from `BookIntroScreen` (`showIntroOnLaunch = true`), I want tapping the back-to-cover emblem button to pop cleanly back to the existing `BookIntroScreen` (preserving its cover state), without stacking duplicate routes.
15. As a diarist who bypassed the cover on launch (`showIntroOnLaunch = false`), I want tapping the back-to-cover emblem button to navigate directly to `BookIntroScreen`, so that the button still works even when the timeline was the initial route.
16. As a diarist using the timeline header tools, I want the three right-hand octagonal medallion buttons to continue opening **Weekly Review** (`每周复盘`), **Search** (`搜索`), and **Settings** (`设置`) with readable contrast against the woodwork header background.

### De-Cluttered Scenery Window & Collapsed Curtain Bar

17. As a diarist viewing the timeline with the curtain open, I want no extra poetic header band above the `Shanshui Scenery Card` and no hanging palace lanterns dangling across the painting, so that the 16:9 landscape stays crisp and unobstructed.
18. As a diarist glancing at the open scenery overlay strip, I want `[时间 · 天气]` and `[画卷场景]` on the left and a single compact seasonal seal on the right (without the duplicate 4-character poetic season phrase), so that the sky remains open.
19. As a diarist pulling the `Bamboo Blind Pull-Cord` down to collapse the window into its `44dp` bar, I want the collapsed bar to show only **`[● 拽绳卷帘 ↑]`** on the left and **`[时间 · 天气]`** on the right (removing `竹帘低垂 · ...`, `[画卷场景]`, and the duplicate seasonal badge), so that the folded bar looks calm, spacious, and immediately readable.
20. As a diarist interacting with the collapsed `44dp` curtain bar, I want tapping anywhere on it to smoothly expand the `16:9` window and roll up the blind, just as before.
21. As a diarist viewing the `Window Sill Ledge` below the scenery window, I want the four classic ornaments to keep their clean visual style re-tinted for the active palette, with only the candlestick interactive (no `"姿态：..."` status pills, `"忆昔"` modal buttons, or poetic slogans added back).

### Chronicle Desk, Entry Slips, Lunar Tallies & Wet-Mounted Seals

22. As a diarist scanning the timeline spine, I want each `WaistTally` date badge to show a delicate miniature lunar-phase icon (computed from the entry's lunar day—crescent, quarter, gibbous, or full moon) above the month and day, rendered in featured contrast color on highlighted badges and primary accent otherwise.
23. As a diarist looking at `WetMountedThumbnail` media previews inside timeline cards, I want the silk brocade mat and mitered seams styled for the active `AtmospherePalette` and stamped in the bottom-left corner with a crisp 2×2 **`云皓珍藏`** cinnabar collector seal, so that attached travel memories feel archival and cohesive.
24. As a diarist scrolling through `Chronicle Desk` entries, I want the `Date Index Tray`, entry slips (`FoldedXuanSlip`), time capsule lock cards, `EntrySummaryCard` metadata pills (mood, weather, weekly review tag, tags), and `ScrollRollerFab` (`写日记`) to reflect the active `AtmospherePalette` colors cleanly while keeping all retired archaic/fluff copy out.

### Accessibility & Contrast

25. As a diarist using a screen reader (`TalkBack` / `VoiceOver`), I want the new back-to-cover button (`返回封面`), Theme Style selector (`主题风格`), and Custom Light/Dark palette pickers (`浅色色板`, `深色色板`) to expose accurate `Semantics` labels and selected states, and meet standard `44dp × 44dp` minimum tap targets.
26. As a diarist reading in Light or Dark mode—including `淡墨暮岚`—I want status bar icons on `TimelineScreen` (white icons over dark casement woodwork) and primary/secondary text contrast across cards, chips, and woodwork AppBars to remain crisp and legible.

## Implementation Decisions

### 1. Domain State Shape & Persistence Contracts

Adapted from the HTML prototype's CSS token architecture into a two-axis Flutter model so OS `ThemeMode.system` remains seamless:

```dart
enum AtmosphereThemePreset { yunhao, classic, custom }

enum LightAtmospherePaletteId {
  yunhaoDay,     // 云岚昼 (Default Light)
  classicWalnut, // 宣纸胡桃 (Legacy Light)
  mistyTwilight, // 淡墨暮岚 (Alt 3 Light)
}

enum DarkAtmospherePaletteId {
  yunhaoNight,    // 皓月夜 (Default Dark)
  classicEbony,   // 碑拓乌木 (Legacy Dark)
  silveryRain,    // 清辉烟雨 (Alt 1 Dark)
  blossomLantern, // 花影灯火 (Alt 2 Dark)
}
```

- **Storage Keys (`ThemeSettingsService`)**: Persist `theme_mode` (`system` | `light` | `dark`), `atmosphere_preset` (`yunhao` | `classic` | `custom`), `custom_light_palette` (`yunhaoDay` | `classicWalnut` | `mistyTwilight`), and `custom_dark_palette` (`yunhaoNight` | `classicEbony` | `silveryRain` | `blossomLantern`). Default on clean launch or invalid stored values: `ThemeMode.system`, `AtmosphereThemePreset.yunhao`, `LightAtmospherePaletteId.yunhaoDay`, `DarkAtmospherePaletteId.yunhaoNight`.
- **Reactive Resolution**: Expose a unified `ValueListenable` (or paired notifiers) on `ThemeSettingsService` so `MaterialApp` builds `theme` from the resolved active `LightAtmospherePaletteId` (`yunhao` -> `yunhaoDay`, `classic` -> `classicWalnut`, `custom` -> stored custom light) and `darkTheme` from the resolved active `DarkAtmospherePaletteId` (`yunhao` -> `yunhaoNight`, `classic` -> `classicEbony`, `custom` -> stored custom dark). Changing any of preset/custom light/custom dark updates both `ThemeData` builders immediately without restarting the app.

### 2. Seven-Palette Token Matrix (Adapted from Prototype)

Every `AtmospherePalette` defines unified tokens mapped into `InkDiaryTokens` (app-wide `ThemeExtension`), `ChronicleDeskPalette`, `FoldedXuanSlipPalette`, `SceneryWindowFrame`, `XiangfeiBambooBlind`, `BambooBlindPullCord`, `WetMountedThumbnail`, `TimelineDateSpineItem`, and `ScrollRollerFab`.

Notice the semantic separation between **`accentPrimary`** (active controls, filter highlights, highlighted tallies, spine cord accents) and **`sealAccent`** (precious vermilion/cinnabar reserved strictly for stamps & seals).

| Palette (`id` / 名称) | Brightness | Ground / Mat / Slip | Ink Primary / Muted / Faint | Woodwork (`dark -> mid / light`) | Accent Primary / Secondary | Seal Cinnabar | Spine Tally Gradient / Featured Border | Silk Mount (`Bg / Border`) | Blind Slats / Cord | FAB Gradient / Border |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `yunhaoDay` (**云岚昼**) | Light | `#EFF3F6` / `#F6F8FA` / `#FFFFFF` | `#1E2A38` / `#516578` / `#7E93A6` | `#48647A -> #5B7B94` / `#89A8BF` | `#4A7A9C` / `#4E8782` | `#C24D43` | `#5285A8 -> #3A6685` / `#87B5D4` | `#EBF1F5` / `#A8BDCE` | `#DAE4EC`/`#EEF4F8`/`#C4D4E0` · `#4A7A9C`/`#C9975B` | `#4E8782 -> #376662` / `#8BC2BC` |
| `classicWalnut` (**宣纸胡桃**) | Light | `#FCF9F2` / `#EAE2D3` / `#FAF6EE` | `#1E1E1E` / `#68645E` / `#9E998F` | `#3D2719 -> #593A26` / `#785036` | `#B83B2E` (`#C43E30` desk) / `#9A7432` | `#C43E30` | `#D95B4D -> #A6362A` / `#EC897E` | `#E8DFCE` / `#B8A689` | Warm bamboo (`#6E4F32`/`#8A6542`/`#543B24`) | `#C43E30 -> #8C2014` / `#D9A962` |
| `mistyTwilight` (**淡墨暮岚**) | Light | `#D8D5CE` / `#E6E3DC` / `#F4F1EA` | `#2B2E33` / `#5A5F66` / `#6F737A` *(contrast-safe step)* | `#45474A -> #5B5D60` / `#7D7E80` | `#6A7682` / `#B08642` | `#B55B52` | `#5F6A75 -> #414A52` / `#C89B54` | `#E6E2D8` / `#B0ABA0` | `#C8C4BA`/`#DBD7CE`/`#B0ACA2` · `#6A7682`/`#C89B54` | `#555D66 -> #3A4047` / `#C89B54` |
| `yunhaoNight` (**皓月夜**) | Dark | `#0E1520` / `#141E2B` / `#1B2738` | `#EEF2F6` / `#9EB0C4` / `#6D8299` | `#0D1624 -> #152336` / `#2B425E` | `#F2B866` / `#A8C0D6` | `#D16B62` | `#2B425F -> #192A40` / `#F2B866` | `#DCE4EC` / `#8EA4B8` | `#1C2B3D`/`#293D54`/`#14202E` · `#A8C0D6`/`#F2B866` | `#223752 -> #132133` / `#F2B866` |
| `classicEbony` (**碑拓乌木**) | Dark | `#181816` / `#181816` / `#242320` | `#F0ECE3` / `#A69F93` / `#756E63` | `#1C140F -> #2D2018` / `#473325` | `#D25447` / `#C8A96E` | `#D25447` | `#C23E30 -> #A42B1E` / `#6E180F` | `#E8DFCE` / `#B8A689` | Warm bamboo (`#4E3723`/`#684A30`/`#3D2A1A`) | `#9E2E22 -> #5E150E` / `#8B6B3E` |
| `silveryRain` (**清辉烟雨**) | Dark | `#111922` / `#18232E` / `#202E3B` | `#E6EEF5` / `#9FB3C4` / `#708596` | `#131D27 -> #1D2B38` / `#394F63` | `#8FB2C9` / `#E8C07D` | `#C9766E` | `#334A5E -> #203140` / `#8FB2C9` | `#D8E2EA` / `#7F97AB` | `#243340`/`#324557`/`#19242E` · `#8FB2C9`/`#E8C07D` | `#2D4254 -> #1A2835` / `#8FB2C9` |
| `blossomLantern` (**花影灯火**) | Dark | `#0D1B1E` / `#13262A` / `#1A3136` | `#F7ECE8` / `#B3C2C2` / `#7A9496` | `#132225 -> #1B3034` / `#35595F` | `#E89AA4` / `#F4B860` | `#D9685B` | `#C76975 -> #873E49` / `#F5B5BE` | `#EFE3DF` / `#C49D98` | `#1C353B`/`#284952`/`#13252A` · `#E89AA4`/`#F4B860` | `#9C4A55 -> #6B2E37` / `#F4B860` |

- **`InkDiaryTokens` Backwards-Compatible Field Mapping**: Keep existing getters (`xuanGround`, `xuanPureLeaf`, `agedFiber`, `deckleBorder`, `jiaomo`, `nongmo`, `danmo`, `qingmo`, `cinnabar`, `cinnabarWash`, `cinnabarDark`, `emeraldSaved`) so all secondary screens theme automatically, while adding explicit fields (`sealCinnabar`, woodwork/header tokens, or resolving `AtmosphereThemeExtension` on `ThemeData`) so amber/cerulean primary accents never hijack red stamps or badges.
- **Featured Tally Text Contrast**: In palettes where `accentPrimary` is warm pale amber (`#F2B866` in `皓月夜`) or soft pink (`#E89AA4`), ensure text/icons inside featured tallies (`#FFF6E5` / `#FFF8F7`) sit over the deep gradient (`#2B425F -> #192A40` / `#C76975 -> #873E49`), and buttons/chips using `cinnabar` background with white text check contrast cleanly against dark/light grounds (or pair amber accent with dark ink `#1E160C` where solid amber fill is used).

### 3. `TimelineAppBar` Casement Framing & Back-to-Cover Routing

- **Surface & System Overlay**: Background uses `woodFrameDark` (paired subtly with bottom hairline divider `Colors.white.withValues(alpha: 0.14)`). Header typography uses `headerTitleText` / `headerSubText`, and `AppBar.systemOverlayStyle` uses light status-bar icons (`Brightness.dark` / `statusBarIconBrightness: Brightness.light`) even when app brightness is `ThemeMode.light`.
- **Top-Left `[‹ Cloud-Moon Emblem]` Button**:
  - Replace `CinnabarSealBadge(text: '墨记')` with a bordered pill (`>= 44dp` min tap target, `Semantics(button: true, label: '返回封面')`) displaying a subtle left chevron (`Icons.chevron_left_rounded`) alongside a rounded Cloud-Moon vector glyph (`CustomPaint` matching `yunhao_intro` crest styling, bordered by `accentPrimary`).
  - **Navigation Rule**:
    - If `Navigator.of(context).canPop()` is `true`, call `Navigator.of(context).pop()` to return to `BookIntroScreen`.
    - Otherwise (e.g., when launched directly with `showIntroOnLaunch = false`), push-replace with a route to `BookIntroScreen` (passing the same `database`, `mediaService`, `ocrQueueManager`) so tapping "Enter Personal Diary" from the cover returns back to `TimelineScreen` cleanly without infinite route stacking.
- **Header Branding Copy**: Primary row renders `云皓日记` (bold serif) + `YUNHAO` (compact monospace/tracking tag); subtitle row renders `云伴皓光 · 收录旅途与心事`.
- **Right Octagonal Buttons**: Retain `每周复盘`, `搜索`, `设置`, styled with translucent woodwork fills and `headerTitleText` icons so they stay legible on both slate blue (`#48647A`) and midnight (`#0D1624`) headers.

### 4. Scenery Window, Curtain Bar & Window Sill Adaptation

- **Collapsed 44dp Curtain Bar (`BambooBlindCollapsedBar`)**:
  - Render slats, border, pull-up pill border, and text tokens using the active `AtmospherePalette`'s blind slat & cord colors.
  - Display **only two slots**:
    - Left: `[● 拽绳卷帘 ↑]` pull-up pill.
    - Right: `[时间 · 天气]` pill (e.g., `夜晚 · 晴天` / `午后 · 晴天`).
  - Remove the collapsed title text (`竹帘低垂 · ...`), the embedded `SceneryRealmBadge`, and the trailing seasonal seal badge.
- **Expanded Window Overlay (`SceneryWindowOverlayStrip`)**:
  - Left: `[时间 · 天气]` pill + interactive `[画卷场景]` (`SceneryRealmBadge`).
  - Right: Single compact seasonal seal badge (`atmosphere.sealBadgeZh`) rendered using `sealAccent`, removing the redundant 4-character `atmosphere.titleZh` text alongside it.
- **Framing & Sill (`SceneryWindowFrame` & `WindowSillLedge`)**:
  - Pull wood gradients, highlights, blind cord stripes, tassel body/cap, sill gradients, lip highlights, brass corner brackets, and candlelight radial glow from the active `AtmospherePalette` instead of binary `isDark` walnut constants.
  - Retain existing `ShanshuiSceneryPainting` 3-realm canvas, `BambooBlindPullCord` drag-to-fold physics, and candlestick-only sill interactivity; omit prototype upper lintel bar, hanging lanterns inside the window, and `"姿态：..."` / `"忆昔"` / motto copy.

### 5. Chronicle Desk, `WaistTally` Lunar Phase & `WetMountedThumbnail` Seal

- **`WaistTally` Miniature Lunar Phase Icon**:
  - Resolve lunar day (`1..30`) for `entry.date` via the existing `LunarCalendar` utility, and map it into 7 lunar phase glyphs drawn via a lightweight `CustomPaint` above the month/day label inside the tally badge:
    - Days 1–5 (`newCrescent`), Days 6–10 (`firstQuarter`), Days 11–13 (`waxingGibbous`), Days 14–17 (`fullMoon`), Days 18–21 (`waningGibbous`), Days 22–25 (`thirdQuarter`), Days 26–30 (`waningCrescent`).
  - Preserve existing `useLunarDay` toggle compatibility for the day numeral text underneath (`1日` vs `初一`).
- **`WetMountedThumbnail` Collector Seal & Silk Mount**:
  - Replace static cream mount constants with palette-resolved `silkMountBg` / `silkMountBorder` / inner rule colors.
  - Restore a compact 14×14dp–15×15dp 2×2 cinnabar stamp (`云` / `皓` / `珍` / `藏`) in the bottom-left corner using `sealAccent` (with white ink and subtle `-2°` tilt matching the prototype), non-interactive (`IgnorePointer`) so card taps remain clean.
- **`ScrollRollerFab`**:
  - Keep the clean `'写日记'` label and roll-up scroll physics; pull gradient fill, bevel border colors, and inner rail highlight from the active `AtmospherePalette`'s `fabGradient` / `fabBorder` / `fabText`.

### 6. `SettingsScreen` Appearance Card

- Place two structured sections inside the `外观主题` card:
  1. **`外观模式`** (existing 3-way selector: `跟随系统` / `浅色模式` / `深色模式`).
  2. **`主题风格`** (new 3-card row: **`云皓`** · 默认, **`经典`**, **`自定义`** with dual Light/Dark color-dot previews).
  3. **Custom Pair Drawer** (animated/conditionally visible when `主题风格 == 自定义`): **`浅色色板`** (`云岚昼`, `宣纸胡桃`, `淡墨暮岚`) and **`深色色板`** (`皓月夜`, `碑拓乌木`, `清辉烟雨`, `花影灯火`), each showing swatch circles, name, and selected ring + semantic `selected` state.

## Testing Decisions

Good tests verify observable UI rendering, semantic accessibility, persisted state, and navigation outcomes at the highest public seams rather than asserting private widget fields or helper methods:

1. **Theme Service & Palette Matrix Unit Seam (`ThemeSettingsService` & `AtmospherePalettes`)**:
   - Prior art: existing theme settings & tokens unit tests in the core theme test suite.
   - Verify clean defaults (`ThemeMode.system`, `yunhao`, `yunhaoDay`, `yunhaoNight`), preset switching (`yunhao` ↔ `classic` ↔ `custom`), persistence round-trip of custom light/dark pairings across service recreation (so switching away to `云皓`/`经典` and returning to `自定义` restores the prior custom pair), graceful fallback on corrupted storage values, and non-null complete tokens across all 3 Light and 4 Dark palettes.
2. **`SettingsScreen` Appearance Card Widget Seam (`pumpWidget(SettingsScreen)`)**:
   - Prior art: existing `settings_screen_test.dart`.
   - Verify `主题风格` presets (`云皓`, `经典`, `自定义`) update `ThemeSettingsService` and root `MaterialApp` theme tokens live; verify custom pickers (`浅色色板` 3 options, `深色色板` 4 options) appear only when `自定义` is selected; verify `外观模式` + `主题风格` work orthogonally and expose valid `Semantics` selected states.
3. **`TimelineScreen` & `ShanshuiSceneryCard` Integration / Widget Seam (`pumpWidget(MemoDiaryApp / TimelineScreen)`)**:
   - Prior art: existing `timeline_screen_test.dart`, `scenery_card_test.dart`, `chronicle_desk_test.dart`.
   - Verify `TimelineAppBar` displays `云皓日记`, `YUNHAO`, and `云伴皓光 · 收录旅途与心事` (and zero `"MemoDiary"` / `"墨记"` / `"个人离线日记"`), renders with `woodFrameDark` surface across both Light and Dark modes, and keeps `每周复盘`, `搜索`, `设置` functional.
   - Verify tapping the top-left `返回封面` emblem button pops back to `BookIntroScreen` when pushed from the cover, and opens `BookIntroScreen` when `TimelineScreen` started as root.
   - Verify collapsed `BambooBlindCollapsedBar` displays only `拽绳卷帘 ↑` and time/weather badge (removing `竹帘低垂` and embedded realm/season duplicates), while tapping expands back to the 16:9 `ShanshuiSceneryPainting`; verify expanded overlay omits `titleZh` fluff and keeps `[时间 · 天气]`, `[画卷场景]`, and `[季节徽章]`.
   - Verify `WaistTally` renders its lunar-phase glyph without layout overflow, `WetMountedThumbnail` displays the `云皓珍藏` seal, and switching between `云岚昼` / `皓月夜` / `宣纸胡桃` / `碑拓乌木` updates chrome tokens while leaving `Scenery` painting and `ThreadBoundFolio` stationery perspectives intact.

## Out of Scope

- Changing the internal procedural artwork palettes of `ShanshuiSceneryPainting` (4 seasons × 4 times × 3 realms) to match the 7 UI themes.
- Overwriting saved Entry stationery templates or `ReadingPerspective` paper/ink colors inside the Editor or Thread-Bound Folio beyond desk surround framing.
- Implementing quick-write modals, `岁时忆昔` incense modals, `"姿态：..."` sill pills, hanging lanterns in the window, or a poetic header band above the scenery card.
- Converting the top-left or in-window sun/moon into a persistent global Light/Dark toggle on the Timeline (theme switching remains cleanly in `Settings → 外观主题`).
- App-wide lunar calendar formatting toggle in Settings or English `AppLocalizations` extraction.

## Further Notes

- Canonical domain terminology (`Atmosphere Theme` and updated `云皓日记` project header) is recorded in `GLOSSARY.md`.
- Architectural rationale and boundaries for the two-axis theme system and woodwork header framing are recorded in `docs/adr/0013-dual-atmosphere-theme-system.md`.
