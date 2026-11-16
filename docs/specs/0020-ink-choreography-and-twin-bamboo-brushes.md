---
id: SPEC-020
title: Ink Choreography & Twin Bamboo Brushes — Live Calligraphic Writing on Stationery Sheets
status: ready-for-agent
created_at: 2026-11-16T22:40:00+08:00
amended_at: 2026-11-16T23:55:00+08:00
adr: ADR-0011
---

# Specification: Ink Choreography & Twin Bamboo Brushes — Live Calligraphic Writing on Stationery Sheets

## Problem Statement

When a diarist opens the **Scholar's Stationery Chest** (`文房百宝匣`), four of the five **Stationery Artifacts**—**Fanned Stationery**, **Porcelain Brush Mountain**, **Guqin Zither**, and **Brass Fish Lock**—open rich interactive compartments, while the top groove holding the **Twin Bamboo Brushes** (`双管毛笔`) displays only a static "coming soon" placeholder (`笔锋运墨动效 · 敬请期待`).

At the same time, writing on a **Stationery Sheet** inside the entry editor snaps characters onto the ruled baselines instantaneously as plain digital glyphs. Diarists who want the meditative, tactile feeling of wet ink flowing from a bamboo brush onto Xuan or Cold Gold paper—watching strokes form in order, seeing bristles bend around curves, or replaying a finished page of calligraphy—have no way to experience live brushwork on the **Paper Heart**.

## Solution

Replace the placeholder inside the **Twin Bamboo Brushes** compartment of the **Scholar's Stationery Chest** with a full **Ink Choreography** (`挥毫落墨`) subsystem and render a non-destructive 60 FPS calligraphic writing overlay on the active **Stationery Sheet**:

1. **Four Delivery Modes (`运笔模式`)**:
   - **Single Fluent Brush (`单笔连绵 · 单笔列队`, Default)**: A single sheet-level master bamboo brush writes characters sequentially in a queue, gliding between characters along a lifted parabolic arc with an **Airborne Silk Trace** (`提笔游丝`) and automatically accelerating via dynamic cursive catch-up (`行书提速`, `1.0x → 2.6x`) when multiple characters wait in the queue.
   - **Concurrent Multi-Brush (`并笔齐书 · 多笔并发`)**: Each newly committed character spawns its own independent bamboo brush simultaneously without queuing.
   - **Ink-Only Bloom (`见墨不见笔 · 纯墨晕染`)**: Hides the bamboo brush shaft and renders only the progressive wet-to-dry ink stroke reveal and print settle transition.
   - **Off (`敛锋静书 · 关闭动效`)**: Disables live stroke animation so characters appear immediately as standard printed glyphs.
2. **Kinematic Bending Brush & Three Bristle Elasticity Presets (`毫锋弹性`)**:
   - Model the brush as a lagging handle (`handle`) chasing the instantaneous stroke contact point (`tip`) with a configurable lag factor (`lagFactor`, defined per 60 Hz frame and applied frame-rate independently), dynamically deforming a quadratic-Bézier bristle cone, dark ink belly, specular hair filament, and paper contact shadow:
     - **Wolf Hair (`狼毫 · 劲健`, `lagFactor = 0.28`)**: Crisp, responsive follow with taut bristle recovery.
     - **Mixed Hair (`兼毫 · 温润`, `lagFactor = 0.18`, Default)**: Balanced literati brush feel combining resilience and fullness.
     - **Goat Hair (`羊毫 · 柔婉`, `lagFactor = 0.11`)**: Deep lag and generous bristle belly bulge around curves.
3. **Writing Cadence (`运笔疾徐`) & Acoustic Feedback (`运笔声效`)**:
   - Three speed multipliers—**Slow (`0.5x 慢品`)**, **Standard (`1.0x 标准`, Default)**, and **Swift (`1.8x 疾书`)**—plus a rate-limited procedural brush-on-paper sound toggle (`运笔声效: 开/关`) integrated with the Writing Sanctum audio synthesizer.
4. **Full Offline Stroke Coverage (~9,574 Hanzi + Latin/Punctuation Binary Table + Procedural Fallback)**:
   - Bundle a precompiled, 100% offline quantized binary stroke-median table covering ~9,574 Simplified and Traditional Chinese characters from the open-source *Make Me a Hanzi* dataset alongside Latin letters (`A–Z`, `a–z`), digits (`0–9`), and common CJK/Latin punctuation, with `O(log N)` binary-search lookup and a deterministic 6-stroke procedural generator for any rare unindexed CJK ideograph.
5. **Non-Destructive Mask-and-Reveal Overlay**:
   - Keep the underlying rich-text editor as the single source of truth for text layout, baseline locking, **Auto-Spill**, **Spill-Back**, invisible mount markers, and native IME composition.
   - When committed characters are inserted (`≤ 20` characters after IME composition collapses) or when the diarist triggers **Replay Active Sheet (`▶ 全页挥毫`)**, resolve each character's rect from the editor's caret geometry, mask queued and actively-written characters by repainting the sheet's own paper (substrate and rulings) over them, paint the wet-ink strokes and kinematic brush, and dissolve the mask (`inkPrintSettle`) to reveal the settled glyph underneath.
6. **Interactive `Trial Rice-Grid` (`米字格试笔窗`) & Live Artifact Status Badge**:
   - Inside the **Twin Bamboo Brushes** sub-panel, provide a 60×60dp **Trial Rice-Grid** (`米字格试笔窗`) with bilingual sample character chips (`永`, `墨`, `拾`, `光`, `E`, `A`) that immediately demonstrate any change to delivery mode, bristle elasticity, or cadence, paired with a **`▶ 全页挥毫` (Replay Active Sheet)** action button.
   - Update the **Twin Bamboo Brushes** artifact in the crimson velvet tray to display a live mode status badge (`双管 · 单笔`, `双管 · 并笔`, `双管 · 纯墨`, `双管 · 静书`) and accurate accessibility semantics.

## User Stories

### Scholar's Stationery Chest & Twin Bamboo Brushes Artifact

1. As a diarist opening the **Scholar's Stationery Chest**, I want the **Twin Bamboo Brushes** (`双管毛笔`) artifact in the top crimson velvet groove to display my active **Ink Choreography** mode badge (`双管 · 单笔`, `双管 · 并笔`, `双管 · 纯墨`, or `双管 · 静书`) instead of placeholder text, so that I can see my current brush configuration at a glance.
2. As a diarist using a screen reader, I want the **Twin Bamboo Brushes** artifact to announce its active **Ink Choreography** mode without any "coming soon" (`敬请期待`) copy, so that accessibility semantics accurately describe the control.
3. As a diarist tapping the **Twin Bamboo Brushes** artifact, I want the brushes to gently lift with a ceramic chime and open the **Ink Choreography** sub-panel above the velvet tray, so that I can configure how my brush writes on the **Stationery Sheet**.
4. As a diarist inside the **Twin Bamboo Brushes** sub-panel, I want to choose among four delivery modes—**Single Fluent Brush (`单笔连绵`)**, **Concurrent Multi-Brush (`并笔齐书`)**, **Ink-Only Bloom (`见墨不见笔`)**, and **Off (`敛锋静书`)**—with **Single Fluent Brush** selected by default, so that I can tailor the visual choreography to my writing mood.
5. As a diarist inside the **Twin Bamboo Brushes** sub-panel, I want to choose among three bristle elasticity presets—**Wolf Hair (`狼毫 · 劲健`)**, **Mixed Hair (`兼毫 · 温润`, default)**, and **Goat Hair (`羊毫 · 柔婉`)**—so that the brush tip's lag and belly bend match my preferred calligraphy brush.
6. As a diarist inside the **Twin Bamboo Brushes** sub-panel, I want to choose among three writing cadence multipliers—**Slow (`0.5x 慢品`)**, **Standard (`1.0x 标准`, default)**, and **Swift (`1.8x 疾书`)**—so that I can savor slow stroke-by-stroke brushwork or write briskly.
7. As a diarist inside the **Twin Bamboo Brushes** sub-panel, I want to toggle **Brush Sound (`运笔声效: 开/关`)**, so that I can hear a soft procedural brush-on-Xuan-paper rustle as strokes are painted or write in complete silence.
8. As a diarist adjusting any setting in the **Twin Bamboo Brushes** sub-panel, I want my delivery mode, bristle elasticity, writing cadence, and brush sound preferences persisted app-wide across sessions without altering any diary entry's saved content, so that my setup is remembered every time I open the editor.

### Trial Rice-Grid (`米字格试笔窗`) & Full-Sheet Replay (`▶ 全页挥毫`)

9. As a diarist configuring the **Twin Bamboo Brushes** sub-panel, I want a 60×60dp **Trial Rice-Grid** (`米字格试笔窗`) with dashed vermilion crosshairs and diagonals right inside the sub-panel, so that I can preview the brush physics and wet-ink bloom without leaving the drawer.
10. As a diarist viewing the **Trial Rice-Grid**, I want tapping any of the bilingual sample chips (`永`, `墨`, `拾`, `光`, `E`, `A`) or tapping the replay button (`重演 ↻`) to immediately animate that character inside the preview square using the active ink color, font family, delivery mode, bristle elasticity, and cadence, so that I can test both Chinese and Latin stroke choreography on the spot.
11. As a diarist changing delivery mode, bristle elasticity, or writing cadence in the **Twin Bamboo Brushes** sub-panel, I want the **Trial Rice-Grid** to automatically re-run the current sample character, so that every adjustment gives instant visual feedback.
12. As a diarist who has written a passage on a **Stationery Sheet**, I want a **`▶ 全页挥毫` (Replay Active Sheet)** button inside the **Twin Bamboo Brushes** sub-panel that dismisses the **Scholar's Stationery Chest** and replays all visible characters on the active **Stationery Sheet** in sequence, so that I can watch my completed entry being written out like a calligraphy scroll.
13. As a diarist who currently has **Ink Choreography** set to **Off (`敛锋静书`)**, I want tapping **`▶ 全页挥毫`** to still perform a full-sheet replay using **Single Fluent Brush (`单笔连绵`)** choreography for that replay session without permanently overwriting my saved **Off** preference, so that the replay action always works when explicitly invoked.
14. As a diarist watching a **`▶ 全页挥毫`** sheet replay, I want any tap on the **Stationery Sheet**, any keystroke, or any page turn to immediately cancel the remaining replay queue and reveal all characters in their settled printed state, so that I am never locked out of editing or navigating my diary.

### Live Writing Choreography on the Stationery Sheet

15. As a diarist typing English letters, digits, or punctuation on a **Stationery Sheet**, I want each committed character to animate stroke-by-stroke at the exact position of its glyph, so that Latin and bilingual text shares the same calligraphic life as Chinese text. Where the platform keyboard holds the current word in a composing region (e.g. Android Gboard with suggestions on), the word appears plain while composing and is masked and written out as a whole when it commits.
16. As a diarist typing Chinese with a Pinyin or handwriting IME, I want the raw uncommitted composition string (`composing` range) to remain un-animated while I choose candidates, and **Ink Choreography** to trigger only once the phrase is committed, so that IME candidate selection stays responsive and flicker-free.
17. As a diarist committing a multi-character Chinese phrase or short dictation segment (`≤ 20` characters) in **Single Fluent Brush (`单笔连绵`)** mode, I want all committed characters to reserve their layout positions immediately while their static glyphs are masked by the sheet's own paper (tone and rulings) and a faint cinnabar guide dot, so that line wrapping and cursor placement never jump while the brush writes them one by one.
18. As a diarist writing in **Single Fluent Brush (`单笔连绵`)** mode, I want a single master bamboo brush to glide from the end of one character's final stroke to the start of the next character's first stroke along a lifted parabolic arc with a faint dashed **Airborne Silk Trace** (`提笔游丝`), so that consecutive characters feel connected by one continuous hand.
19. As a diarist typing rapidly or committing a multi-character phrase in **Single Fluent Brush (`单笔连绵`)** mode, I want the brush to automatically accelerate via dynamic cursive catch-up (`1.35x` when 1–2 characters wait, `1.9x` when 3–5 wait, `2.6x` when 6+ wait), so that the brush keeps pace with my thought flow without falling far behind the caret.
20. As a diarist writing in **Concurrent Multi-Brush (`并笔齐书`)** mode, I want each newly committed character in a phrase to animate simultaneously with its own local bamboo brush, so that multi-character commits bloom across the line all at once.
21. As a diarist writing in **Ink-Only Bloom (`见墨不见笔`)** mode, I want the wet-ink halo, core stroke, tip pool, and settle transition to animate without rendering the bamboo brush shaft, so that I can enjoy an unobstructed view of the ink soaking into the paper.
22. As a diarist watching each stroke form, I want the stroke to follow a three-phase calligraphic cadence—entry press (`顿笔起`), brisk travel (`疾行`), and exit dwell (`驻笔收`)—with a wide translucent wet-ink halo, saturated core stroke, entry/exit ink blots, and a dynamic tip pool modulated by bristle stretch, so that the ink feels organic rather than mechanical.
23. As a diarist watching a character finish its final stroke, I want the temporary wet-ink layers and paper mask to dissolve through a subtle settle transition (`inkPrintSettle`) into the crisp underlying font glyph (`思源雅宋` or `古法楷书`) in the active ink tone (`焦墨`, `朱砂`, `竹青`, or dark-paper gold/silver ink), so that the finished page retains 100% typographic fidelity and baseline alignment.

### Full Hanzi & Script Stroke Coverage

24. As a diarist writing in Simplified or Traditional Chinese, I want common and literary Hanzi (~9,574 characters from the *Make Me a Hanzi* dataset) to animate along their authentic stroke order and stroke directions, so that characters are written in proper calligraphic sequence.
25. As a diarist writing a rare archaic CJK character outside the ~9,574 indexed characters, I want the engine to fall back seamlessly to a deterministic 6-stroke calligraphic sequence seeded by the character's code point, so that every character on my **Stationery Sheet** animates smoothly without missing-glyph errors.
26. As a diarist concerned about privacy and offline reliability, I want the entire stroke dictionary bundled locally inside the app with zero network requests and zero runtime cloud dependencies, so that **Ink Choreography** works 100% offline.

### Structural & Pagination Safety

27. As a diarist opening an existing diary entry, pasting a long passage (`> 20` characters), triggering Undo/Redo, or experiencing an **Auto-Spill** or **Spill-Back** across **Stationery Sheets**, I want the text to appear immediately without triggering stroke animations (and any characters still waiting to be written to settle at once), so that structural document operations remain instantaneous.
28. As a diarist switching stationery templates via **Fanned Stationery** or adjusting font size, line spacing, or ink tone via **Porcelain Brush Mountain**, I want **Ink Choreography** to automatically adopt the active sheet's paper, ink color, font family, and line stride without mutating `entries.content_delta`, so that content and presentation remain strictly decoupled.
29. As a diarist typing emoji or characters from scripts outside the stroke table (e.g. Cyrillic, Kana), I want them to appear immediately as printed glyphs rather than with a placeholder stroke, so that nothing on my page is drawn with strokes that do not belong to it.

## Implementation Decisions

### 1. Domain & State Model for Ink Choreography

- An immutable value object `InkChoreographyConfig` holds:
  - `deliveryMode`: enum `InkDeliveryMode` (`singleFluent`, `multiConcurrent`, `inkOnly`, `off`), default `singleFluent`.
  - `bristleStiffness`: enum `BristleStiffness` (`wolf`, `mixed`, `goat`) carrying `lagFactor` `0.28`, `0.18` (default), `0.11`.
  - `cadence`: enum `WritingCadence` (`slow` `0.55`, `standard` `1.0` default, `swift` `1.8`) carrying `speedMultiplier`.
  - `soundEnabled`: bool, default `true`.
- `EditorSettingsService` persists the four fields under app-wide keys next to `isWritingDockHidden`, reading back defaults for missing or unknown values.
- A dedicated `InkChoreographyController` (`ChangeNotifier`) owned by `EntryEditorScreen` holds the live config, restores it on startup (same "don't overwrite an in-session choice" rule as `EditorChromeController.restorePreferences`), writes every change through, and exposes `requestSheetReplay()`. The **Scholar's Stationery Chest** listens to it directly, so the drawer reflects changes without the screen's `setState` (Modal Route State Encapsulation).
- `InkChoreographyConfig` is never serialized into `entries.content_delta` or SQLite.

### 2. Offline Binary Stroke Dictionary (`hanzi_strokes.bin`)

- **Source & licence**: `graphics.txt` from *Make Me a Hanzi* (`skishore/makemeahanzi`, pinned to a recorded commit), whose stroke data is derived from Arphic fonts under the **Arphic Public License**. Bundling requires an explicit exception to the `GEMINI.md` licence list (recorded in ADR-0011), shipping the licence text in the app (`LicenseRegistry` entry plus `assets/calligraphy/ARPHIC_PUBLIC_LICENSE.txt`), and keeping the derived asset under APL. The implementer confirms the licence terms against the dataset's README at the pinned commit before committing the asset.
- **Build tool** `tool/build_hanzi_strokes.dart` takes `--graphics <path to graphics.txt>` and `--out assets/calligraphy/hanzi_strokes.bin`. The dataset (~30 MB) is downloaded once by the developer and never committed; only the compiled `.bin` is committed. The tool is deterministic (same input → byte-identical output) and prints entry count and byte size.
- **Normalization**: *Make Me a Hanzi* medians live in a `1024×1024` box with `y` upward and the top at about `y = 900`: `x_norm = round(x / 1024 * 100)`, `y_norm = round((900 - y) / 1024 * 100)`, both clamped to `0..100`. Each stroke is simplified (Ramer–Douglas–Peucker, ε ≈ 1 unit) to at most 32 points, and consecutive duplicate points are dropped.
- **Curated Latin & punctuation** strokes live in a Dart source table (`curated_strokes.dart`) authored in the same `0..100` box, compiled into the `.bin` by the tool **and** used directly as the synchronous fallback. Authoring conventions: cap height `y 16..84`, x-height top `y ≈ 42`, baseline `y = 84`, descenders to `y ≈ 96`. Coverage: `A–Z`, all 26 of `a–z` drawn as real lowercase forms (not scaled capitals), `0–9`, and `，。、·！？；：“”‘’.,!?-`. The prototype's capitals, `e`, and six punctuation marks are the starting point; the remaining ~35 letters and digits and ~11 marks are new.
- **Binary format** (little-endian):
  - **Header (8 bytes)**: ASCII magic `MDST` (4 bytes), `uint16` version (`1`), `uint16` entry count `N`.
  - **Index (`N × 8` bytes)**: `uint32 codePoint` (strictly ascending), `uint32 payloadOffset` relative to the start of the payload section.
  - **Payload**: per character `uint8 strokeCount`, then per stroke `uint8 pointCount` followed by `pointCount × (uint8 x, uint8 y)`.
  - Expected size ≈ 1 MB (the tool reports the real figure; record it in the ticket).
- **`HanziStrokeTable`** (runtime):
  - `load()` reads the asset once into a `ByteData` and validates magic, version, and monotonic index; on failure it logs once and stays on the fallback.
  - `strokesFor(String char)` → `CharacterStrokes?` (list of polylines in `0..100` space plus `isCjk`). Lookup order: binary index (`O(log N)` binary search) → curated table → procedural 6-stroke generator for code points in `0x4E00..0x9FFF` → `null`.
  - Returns `null` for anything else (emoji, surrogate pairs, other scripts, whitespace, U+FFFC embeds), which callers treat as "do not animate". There is no single-curve placeholder.
  - Works synchronously before `load()` completes (curated + procedural only), so widget tests need no asset.

### 3. Prototype-Derived Choreography Math (`InkChoreographyTimeline`)

Pure functions, unit-tested without widgets:

```
// 1. Dynamic Cursive Catch-Up Multiplier (Single Fluent Brush queue)
catchupMult(remainingQueueLength):
  remaining >= 6 -> 2.6
  remaining >= 3 -> 1.9
  remaining >= 1 -> 1.35
  otherwise      -> 1.0

// 2. Three-Phase Stroke Cadence (progress p in 0.0..1.0)
strokeDuration = (isCjk ? 245ms : 205ms) / (speedMultiplier * catchupMult * replayBoost)
easedProgress(p):
  p < 0.20  -> (p / 0.20) * 0.16                       // Entry press (顿笔起)
  p > 0.85  -> 0.86 + ((p - 0.85) / 0.15) * 0.14       // Exit dwell (驻笔收)
  otherwise -> 0.16 + ((p - 0.20) / 0.65) * 0.70       // Rapid travel (疾行)

// 3. Inter-character transit (singleFluent only)
transitDuration = max(38ms, round(135ms / (speedMultiplier * catchupMult * replayBoost)))
silk trace drawn when 6dp <= distance <= 180dp

// 4. Two-Body Kinematic Lag, frame-rate independent
alpha(dt)    = 1 - (1 - lagFactor) ^ (dt / 16.667ms)  // equals lagFactor at exactly 60 Hz
targetHandle = Offset(tip.x + 4, tip.y - 15 - liftHeightPx)
handle      += (targetHandle - handle) * alpha(dt)
dx = tip.x - handle.x
dy = (tip.y - liftHeightPx * 0.65) - handle.y
dragTilt   = clamp(-dx * 0.55 + (dy - 16) * 0.16, -22°, +22°)
shaftAngle = 22° + dragTilt
// Counter-rotate (dx, dy) by -shaftAngle into shaft space (localDx, localDy), then
// bulge perpendicular to it by min(localDist * 0.42 * pressure, 16 * brushScale),
// pressure = 1.0 while pressing, 0.28 while lifted.
```

- `replayBoost` is `1.6` during a **`▶ 全页挥毫`** replay and `1.0` otherwise.
- Median polylines are smoothed at runtime (centripetal Catmull–Rom) and resampled by arc length before progress is applied, so the tip moves at an even speed along a stroke.
- **Glyph-box mapping**: a character's `0..100` stroke box maps onto a rect whose width is the glyph's advance (from §4) and whose height is the font's em size (`typography.fontSize`), centred vertically on the glyph's text line. CJK glyphs are therefore near-square. Narrow Latin glyphs are scaled horizontally to their advance, so strokes never spill onto neighbouring glyphs.

### 4. Non-Destructive Overlay on the Stationery Sheet

**Layer placement.** The overlay lives in `EditorPaperCanvas`'s sheet card, not inside `EditorTextSheetView`'s Paper Heart `ClipRect` (the shaft stands ~100dp above the tip and would be clipped on the top rows). It has two `IgnorePointer` layers, both inside the `PageView` item so they move with page swipes:
1. **Mask & ink layer**: inside the card's `ClipRRect`, above the sheet body and below `PageCornerFolds`.
2. **Brush layer**: a sibling above the card, unclipped, so the shaft can extend over the desk.

**Insertion detection (`InkInsertionTracker`, one per text sheet).**
- `StationeryQuillController` gains an observer hook. `replaceText` reports `(index, deletedLength, insertedText, ignoreFocus)` after it applies the edit, including after the mount-marker heuristics have shifted the index. `undo()`, `redo()`, and a document swap (the `document` setter used by `setDelta` during **Auto-Spill** / **Spill-Back**) report a structural change. The tracker does not subscribe to `document.changes`, because that stream is replaced on every document swap.
- **Composing.** `controller.plainTextEditingValue.composing` is always empty: Quill builds it from text and selection only. The real range is `QuillRawEditorState.composingRange` (a `ValueNotifier<TextRange>`), reached through `sheet.editorKey.currentState`. It needs a `package:flutter_quill/src/...` import, which is acceptable against the pinned `11.6.0` and lives in one adapter file (`quill_composing_probe.dart`) with a comment naming the pin.
- **Rules:**
  - `ignoreFocus` edits, structural changes, and edits while the sheet has no focus: no animation, and every queued or active slot on that sheet settles immediately.
  - While composing is non-empty, insertions accumulate into a *pending commit range*. When `composingRange` collapses, the committed text inside that range is enqueued if it holds `1..20` characters. Otherwise it is dropped.
  - Insertions with no composition in flight: enqueue when the inserted text is `1..20` characters. Anything longer (paste, dictation burst) is ignored.
  - Within an accepted insertion, only characters for which `HanziStrokeTable.strokesFor` returns non-null are animated. The rest appear immediately.
  - Every later edit shifts queued slot offsets: a slot before `index` is unchanged, a slot at or after `index + deletedLength` moves by `inserted - deleted`, and a slot inside the deleted range is dropped.
- **Fixes the dead Auto-Spill guard:** `EditorPaginationCoordinator.isImeComposing` is declared and read but never set in production (only tests set it). The same composing probe now drives it (true while any text sheet's `composingRange` is non-empty), so Auto-Spill's IME guard works on device.

**Rect resolution.**
- For offset `o`: `a = renderEditor.getLocalRectForCaret(TextPosition(offset: o))` and `b = …(o + 1)`. If `a` and `b` share a line (tops within 0.5dp), the glyph advance is `a.left .. b.left`. Otherwise (the glyph ends its line) the advance is measured with a `TextPainter` in the active text style.
- Vertically, the mask spans the full ruled row that contains `a.center`. Row bounds come from `StationerySheetGeometry` (`paperHeart.top + k × lineStridePx`, offset by `openingHeaderHeight` on the opening sheet).
- Rects are converted from `RenderEditor` space to sheet-card space with `localToGlobal` / `globalToLocal`. They are resolved when a slot becomes active (so earlier settles and wraps are already laid out). Any geometry, template, or typography change while slots exist settles them all.
- `RenderEditor.getBoxesForSelection` is not available: `flutter_quill` 11.6.0 keeps it private to text lines.

**Mask-and-reveal lifecycle.**
- `queued` and `active` slots are masked by repainting the sheet's paper over their rects: a `TemplateCanvasPainter` built with the same `style`, `typography`, `headerHeight`, and `layoutMetrics` as the card's `TemplateCanvasContainer`, painted under a clip of the union of masked rects. A flat `backgroundColor` fill is not used, because it would erase rulings, grids, and paper texture.
- `queued` slots show a faint `2dp` cinnabar guide dot (`#B83B2E`, 25% alpha) at the rect centre. `active` slots show a faint cinnabar border guide (`#B83B2E`, 35% alpha) plus the progressive wet ink: halo, core, entry/exit blots, and tip pool.
- `singleFluent`: one master brush. Between characters it travels along the parabolic transit of §3, with a dashed **Airborne Silk Trace**.
- `multiConcurrent`: every slot of an accepted insertion goes active at once, each with its own local brush.
- `inkOnly`: wet ink without brush, shaft, or contact shadow.
- `off`: the tracker enqueues nothing during live typing.
- On a slot's final stroke it enters `settling` for `260ms`: mask and wet ink fade `1.0 → 0.0` while the real `QuillEditor` glyph shows through.
- One `Ticker` per sheet overlay runs only while slots exist and stops when the last settles. Only the active sheet's overlay may tick.

**Full-sheet replay (`▶ 全页挥毫`).**
- `InkChoreographyController.requestSheetReplay()` closes the drawer. The active text sheet then enqueues every character on it with non-null strokes, in document order, in `singleFluent` choreography (even if the saved mode is `off` or another mode; the saved preference is untouched) with `replayBoost = 1.6`. Unsupported on ephemera sheets, where the button is disabled.
- Any pointer-down on the sheet card (a `Listener` beside the overlay, which leaves the editor's own gestures alone), any `replaceText` on the sheet, or any page change (`onPageChanged`) cancels the replay. Every remaining slot settles in a single frame. A keystroke that cancels a replay is itself animated under the saved mode.

### 5. Twin Bamboo Brushes Sub-Panel & Velvet Tray Artifact

- `ArtifactTwinBrushes` takes `InkDeliveryMode activeMode` and renders the badge (`双管 · 单笔` / `双管 · 并笔` / `双管 · 纯墨` / `双管 · 静书`) and `Semantics` label `双管毛笔: 挥毫落墨 · <mode name>`. No `敬请期待` copy remains anywhere (Displacement over Coexistence: the placeholder `TwinBrushesSubPanel` and its test assertions are replaced, not kept).
- `TwinBrushesSubPanel` (own file) contains, in order:
  1. Header: title `挥毫落墨 · 双管笔意`, **Brush Sound Toggle** (`🔊/🔇 运笔声效`), **`▶ 全页挥毫`**, close button.
  2. **Trial Rice-Grid** row: a 60×60dp square with dashed vermilion crosshairs and diagonals, sample chips `永 墨 拾 光 E A`, and `重演 ↻`. It uses the same timeline and painters as the sheet overlay, the active template's ink colour, and the Brush Mountain font family. It replays on chip, `重演`, mode, stiffness, or cadence taps. In `off` mode it previews `singleFluent` without moving the saved mode, so the grid is never blank.
  3. **Delivery Mode** 4-card selector.
  4. **Bristle Elasticity** 3-pill and **Writing Cadence** 3-pill selectors.
- `ScholarChestDrawer` and `ScholarChestDrawer.show` gain an `InkChoreographyController` parameter.
- **450-line budget.** `artifact_twin_brushes.dart` (428 lines) loses the sub-panel to its own file. `scholar_chest_drawer.dart` (424 lines) extracts its velvet tray layout into `scholar_chest_velvet_tray.dart` before gaining wiring. `entry_editor_screen.dart` (446 lines) must not grow: the controller's construction, restore, and drawer hand-off move into an extracted editor binding (e.g. the Scholar's Chest launch moves out of the screen).

### 6. Acoustic Feedback in `AudioSanctumService`

- Add `ScholarTactileChime.brushStroke`: 140ms bandpass-filtered noise (prototype: centre ≈ 920 Hz, Q ≈ 1.3, sine envelope), synthesized by `ProceduralAudioSynthesizer`.
- `AudioSanctumService.playBrushStroke()` keeps one cached WAV buffer and one dedicated reused `AudioPlayer` (the generic `playChime` allocates both per call, which at a 110ms cadence would churn hundreds of players during a replay). It is rate-limited to one trigger per `110ms` through an injectable clock, and is a no-op when `soundEnabled` is false, the volume is 0, or platform audio is disabled.
- Fired once per stroke start on the sheet overlay and the Trial Rice-Grid.

## Testing Decisions

### What Makes a Good Test

- Tests verify observable behaviour at public boundaries: what the diarist sees and taps, what persists, when animations run or skip, and that `entries.content_delta` is unchanged. They don't test private widget state or painter internals.
- Every file stays under 450 lines and follows `CODING_STANDARDS.md`.

### Test Defaults

- `test/helpers/editor_test_harness.dart` seeds `InkDeliveryMode.off` through its fake `EditorSettingsService`, so the existing editor suites (which type into sheets and rely on `pumpAndSettle`) are unaffected. Choreography tests opt in to the mode under test.
- All choreography timing is driven by `Ticker` elapsed time, so tests pump fixed durations (`tester.pump(Duration)`); no wall clock.

### Modules & Seams to Be Tested

1. **Pure seam: `HanziStrokeTable` + `InkChoreographyTimeline`**
   - The build tool round-trips: a small fixture `graphics.txt` (a few Simplified + Traditional entries) compiles to bytes that `HanziStrokeTable` decodes to the expected normalized polylines. The table rejects bad magic, bad versions, and non-monotonic indexes.
   - The committed asset (loaded via `rootBundle` in a test) resolves `永`, `墨`, `龍`, `書`, ASCII letters and digits, and punctuation. It returns the procedural 6-stroke sequence (deterministic across calls) for a CJK code point absent from the index, and `null` for emoji and Cyrillic.
   - Catch-up thresholds, eased-progress continuity at `0.20` and `0.85`, stroke and transit durations, and the silk-trace distance window.
   - **Frame-rate independence:** handle position after 1/6 s matches within 0.5 units whether stepped at 60 Hz, 120 Hz, or 30 Hz, and equals `lagFactor` per step at exactly 60 Hz.
   - Shaft-angle clamping, bristle bulge bounds, and the glyph-box mapping (CJK square, Latin advance-scaled).
2. **Widget seam: `ScholarChestDrawer` + `TwinBrushesSubPanel`**
   - The placeholder is gone, and the badge and semantics follow the mode.
   - Each mode, stiffness, cadence, and sound tap highlights while the drawer stays open and persists through `EditorSettingsService`. Settings reload on a fresh screen.
   - Sample chips animate in the Trial Rice-Grid and settle.
   - `▶ 全页挥毫` closes the drawer and starts a replay.
3. **Widget seam: `EntryEditorScreen` / `EditorPaperCanvas`**
   - A short committed insertion masks, animates, and settles. `content_delta` is identical before and after.
   - Composing input (driven through `updateEditingValue` with a non-empty composing range) is not animated until composing collapses.
   - Pastes over 20 characters, initial load, undo/redo, and Auto-Spill do not animate and settle in-flight slots.
   - Editing before a queued character keeps its slot on the right character.
   - Tap, keystroke, or page turn during a replay settles everything in one frame. A replay in `off` leaves the saved mode `off`.
   - With an IME composing range active on a sheet, `isImeComposing` is true, so Auto-Spill defers.

### Prior Art in the Codebase

- `test/features/editor/widgets/scholar_chest_drawer_test.dart` and `scholar_chest_live_sync_test.dart`: drawer artifacts, sub-panels, live sync.
- `test/features/editor/widgets/brush_reveal_choreography_test.dart`: pure frame-at-duration and brush-pose math.
- `test/features/editor/widgets/editor_text_sheet_view_test.dart` and `test/features/editor/entry_editor_screen_test.dart`: `QuillEditor` inside the Paper Heart.
- `test/features/editor/services/editor_pagination_spill_test.dart`: `isImeComposing` deferral.

## Out of Scope

- Replacing `QuillEditor` with per-character widget cells, or vertical (`vertical-rl`) live editing on the authoring canvas (rejected per ADR-0005 and ADR-0011; vertical layout stays in **Keepsake Scroll View** and **Thread-Bound Folio**).
- Duplicating paper, ruling, font family, font size, line spacing, or ink colour pickers inside `TwinBrushesSubPanel` (owned by **Fanned Stationery** and **Porcelain Brush Mountain**).
- Freehand stylus drawing or custom handwriting recognition.
- Mutating `entries.content_delta` or adding SQLite columns for brush preferences.
- Ink Choreography in read-only views (Keepsake Scroll View, Thread-Bound Folio, PDF export).
- Stroke data for scripts other than Han, Latin, digits, and the listed punctuation.

## Further Notes

- **Replay length.** A full sheet is long: ~14 rows × ~17 characters ≈ 240 Hanzi at ~9 strokes each, at `1.6x` boost and `2.6x` catch-up, comes to roughly two minutes. That is intentional (it is a meditative replay, and any tap ends it), but worth confirming on device.
- **Android word-level composing** (story 15) needs a device check with Gboard. If it feels wrong, a follow-up can animate Latin letters live inside the composing region; that would need the mask to track a moving composing range and is deliberately not attempted here.
- `graphics.txt` is downloaded by the developer from GitHub once to run `tool/build_hanzi_strokes.dart`. The app itself performs zero network access.
