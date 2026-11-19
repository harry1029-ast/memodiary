---
status: accepted
---

# Dual-Atmosphere Theme System and Casement Chrome Boundary

To evolve the app's visual identity into **云皓日记** while preserving the classic walnut-and-ebony aesthetic and native OS Light/Dark mode switching, we decouple theme selection into two orthogonal axes: **Appearance Mode** (`跟随系统 / 浅色模式 / 深色模式`) and **Atmosphere Theme** (`主题风格`: `云皓` default pairing `云岚昼` Light + `皓月夜` Dark, `经典` pairing `宣纸胡桃` Light + `碑拓乌木` Dark, or `自定义` pairing any of the 3 Light palettes `云岚昼 / 宣纸胡桃 / 淡墨暮岚` with any of the 4 Dark palettes `皓月夜 / 碑拓乌木 / 清辉烟雨 / 花影灯火`). On `TimelineScreen`, the top `TimelineAppBar` adopts the active palette's dark window-frame woodwork surface (`woodFrameDark` with light ivory text) across both Light and Dark modes to form a continuous casement lintel above the `Shanshui Scenery Card`. Atmosphere Palettes govern only UI and study-desk chrome—never overwriting the `Shanshui Scenery Card`'s 3-realm procedural painting engine (`山水 / 室内 / 街市`) or an entry's saved stationery template / `ReadingPerspective`.

## Considered Options

- **Flat 7-palette selector replacing Light/Dark mode**: Considered letting the user pick a single static palette out of 7, but rejected because it breaks automatic OS `ThemeMode.system` day/night transitions.
- **Coupling the Scenery Card canvas painting to the selected UI palette**: Considered overriding the window painting with static palette colors as in the HTML mockup, but rejected because it would discard the 3-realm × 4-season × 4-time-of-day × 5-weather procedural engine and `ContemplationViewScreen`.
- **Replacing the Classic (`宣纸胡桃 / 碑拓乌木`) palettes outright**: Rejected so diarists who prefer the warm walnut-and-cinnabar study desk can keep it via the `经典` preset or mix-and-match via `自定义`.

## Consequences

- `MaterialApp` always receives both a valid Light `ThemeData` (built from the active Light `AtmospherePalette`) and a valid Dark `ThemeData` (built from the active Dark `AtmospherePalette`), smoothly honoring `ThemeMode.system`, `ThemeMode.light`, and `ThemeMode.dark`.
- `InkDiaryTokens`, `ChronicleDeskPalette`, `FoldedXuanSlipPalette`, `SceneryWindowFrame`, `XiangfeiBambooBlind`, `BambooBlindPullCord`, `TimelineDateSpineItem`, `WetMountedThumbnail`, and `ScrollRollerFab` resolve their tokens from the active `AtmospherePalette` rather than hardcoded light/dark branches.
- Semantic token roles separate primary interactive accent (`accentPrimary`: lantern amber `#F2B866` in `皓月夜`, cerulean `#4A7A9C` in `云岚昼`, cinnabar in `经典`) from precious seal cinnabar (`sealAccent`: `#D16B62` / `#C24D43`) used exclusively on collector seals and stamps.
