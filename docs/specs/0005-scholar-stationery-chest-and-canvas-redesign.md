---
id: SPEC-005
title: Scholar's Stationery Chest, Baseline-Snapped Media Cards & Keepsake Scroll View
status: ready-for-agent
created_at: 2026-11-02T00:52:00+08:00
---

# Specification: Scholar's Stationery Chest, Baseline-Snapped Media Cards & Keepsake Scroll View

## Problem Statement

While the **Journal Sheet** and **Writing Dock** established a full-bleed stationery foundation for the diary editor, real-world journaling revealed four structural and aesthetic gaps:

1. **Spatial & Ruling Drift Across Custom Configurations**: Background paper rulings, orthogonal grids, and dot matrices must remain mathematically locked to typographic line strides and centered cleanly within page bounds—without leaving clipped fractional columns at screen edges or drifting out of sync when font size, line spacing, or custom stationery settings change.
2. **Media Embeds Break Baseline Rhythm & Classical Aesthetics**: Inserting a photo or short video with an arbitrary natural height pushes every subsequent line of text off the underlying ruled lines or grid squares for the remainder of the entry. Furthermore, unstyled digital frames and dark video placeholders visually clash with warm Xuan paper, cold gold flecks, and silk rulings.
3. **Fragmented Secondary Tooling**: Switching stationery templates, tuning typography, toggling ambient soundscapes, and sealing Time Capsules were scattered across generic overflow menus and disconnected modal bottom sheets, breaking the tactile quietude of a scholar's desk.
4. **Classical Vertical Calligraphy vs. Mobile Input Ergonomics**: Diarists desire classical right-to-left vertical calligraphy (`纵书竖排`) and rich stationery substrates (cold gold flecks, vermilion/charcoal/jade silk rules, carved cinnabar seals) for reading and PDF keepsakes, yet forcing vertical or single-cell editing onto live mobile keyboards breaks native Pinyin phrase composition, selection handles, and typing fluency.

## Solution

Restructure the diary editor around a **Four-Layer Decoupled Stationery Model (`Substrate × Geometry × Typography × Ephemera`)**, an **Integer-Row Height Snapper** for **Tipped-In Ephemera Cards**, a read-only **Keepsake Scroll View**, and a unified **Scholar's Stationery Chest (`文房百宝匣`)**:

1. **Four-Layer Decoupled Stationery Canvas**:
   - **Substrate (`纸肌层`)**: Base paper tint, procedural fiber texture, shimmering cold gold flecks (`冷金洒粉`), obsidian night paper (`松烟夜墨`), and soft spine/edge vignette—persisted backward-compatibly inside template configuration JSON without mutating entry Delta content.
   - **Geometry (`界格层`)**: Integer-snapped layout bounds (`computeLayoutMetrics`) that center whole columns and rows cleanly inside horizontal margins, paired with configurable silk rule ink tints (vermilion `朱丝栏`, charcoal `乌丝栏`, bamboo jade `竹青栏`).
   - **Typography (`字法层`)**: Continuous horizontal rich-text editing with baseline-locked line strides, font scale, ink tone, and optional poetry center alignment.
   - **Ephemera (`印记层`)**: In-paper **Journal Letterhead** paired with a customizable colophon **Cinnabar Signature Seal (`落款朱砂印`)** displaying the diarist's persistent 2–4 character signature in template-governed relief (`朱文`) or intaglio (`白文`).
2. **Integer-Row Height Snapper & Tipped-In Ephemera Cards (`贴片拓影`)**:
   - Every embedded photo and short video is framed as a physical print tipped onto the **Journal Sheet** with a paper-matched opaque matte border (masking background rules behind the print), subtle drop shadow, optional caption, and inline video thumbnail playback.
   - Total vertical footprint (media height plus top/bottom matte margins) is snapped deterministically to $N \times \text{rowHeight}$ so every line of text following an embed lands squarely on the next ruled baseline.
   - Tapping an embedded card reveals a lightweight contextual floating action bar for captioning, aspect-ratio framing, or removal—keeping media actions directly on the print.
3. **Scholar's Stationery Chest (`文房百宝匣 · 锦盒书案`)**:
   - Consolidates all secondary writing tools into a single skeuomorphic brocade-and-crimson-velvet bottom drawer housing five interactive **Stationery Artifacts (`文房器物`)** with cached vector geometry, spring micro-animations, tactile haptics, and procedural acoustic chimes:
     - **Fanned Stationery (`叠印花笺`)**: Instant switching across curated stationery suites and custom templates.
     - **Porcelain Brush Mountain (`青花笔架`)**: Unified font family, font size, line spacing, ink tone, and poetry alignment controls.
     - **Guqin Zither (`桐木古琴`)**: Ambient writing soundscapes with harmonic string vibration.
     - **Brass Fish Lock (`古法鱼锁`)**: Time Capsule seal presets and custom unlock dates.
     - **Twin Bamboo Brushes (`双管毛笔`)**: Interactive visual artifact reserved as a clean placeholder for a future calligraphy stroke-animation toggle.
   - Accessible via dual ergonomic triggers: a status-bearing antique chest emblem in the top app bar and a one-handed thumb pull-up handle/trigger on the bottom **Writing Dock**.
4. **Keepsake Scroll View (`卷轴赏鉴`) & Vector PDF Parity**:
   - Provides a dedicated read-only presentation modal and matching PDF export layout mode that renders the entry's Delta content in classical right-to-left vertical columns (`vertical-rl`) with punctuation mapping, tipped-in media prints, colophon metadata, and the **Cinnabar Signature Seal**—preserving 100% horizontal input comfort during live editing.

## User Stories

1. As a diarist, I want background horizontal rules, grids, and dot matrices on the **Journal Sheet** to snap to integer multiples of my active line height and center cleanly within margins, so that rules never slice through characters or leave half-cut orphan columns at screen edges.
2. As a diarist switching between built-in and custom stationery templates, I want substrate textures (Xuan paper, Cold Gold flecks, Retro Kraft, Minimalist White, Obsidian Night) and silk rule tints (Vermilion, Charcoal, Bamboo Jade) to transform visual presentation immediately while leaving my underlying diary text and formatting 100% untouched.
3. As a nocturnal writer, I want the Obsidian Night (`松烟夜墨`) substrate to automatically adapt status bar brightness, ink contrast, rule opacity, and **Writing Dock** chrome to low-glare dark tones, so that late-night journaling never strains my eyes.
4. As a multimodal diarist inserting a photo into a ruled or gridded entry, I want the photo's total vertical footprint to snap automatically to an exact integer multiple of `rowHeight` via the **Integer-Row Height Snapper**, so that every line of text below the photo stays perfectly aligned on the stationery baselines.
5. As a multimodal diarist inserting a short video into an entry, I want the video block's height to also snap to $N \times \text{rowHeight}$ and display its poster thumbnail inside a **Tipped-In Ephemera Card** with a warm cinnabar/brass play emblem, so that unplayed videos look like tactile keepsakes rather than harsh black rectangles.
6. As a diarist viewing an entry with embedded short videos, I want tapping a video's **Tipped-In Ephemera Card** to play and pause smoothly inline within its matted frame without forcing a jarring fullscreen takeover.
7. As a diarist appreciating physical stationery, I want embedded photos and videos to mask background ruled lines behind an opaque paper-toned matte border with a soft natural shadow, so that grid and ruled lines never bleed through my photographs.
8. As a diarist curating my memories, I want tapping an embedded photo or video in edit mode to surface a contextual floating action bar allowing me to add or edit a handwritten-style caption, toggle framing aspect ratio (`Auto`, `4:3`, `1:1`), or remove the attachment—while keeping total block height snapped to `rowHeight`.
9. As a diarist changing font size or line spacing after inserting photos and videos, I want all **Tipped-In Ephemera Cards** in the entry to dynamically recompute their snapped $N \times \text{rowHeight}$ padding on the fly, so that text below media never loses baseline lockstep.
10. As a writer seeking distraction-free immersion, I want all secondary studio controls consolidated into the **Scholar's Stationery Chest** rather than scattered across generic overflow popups and separate modal sheets.
11. As a mobile user holding my phone with one hand, I want dual access to the **Scholar's Stationery Chest**—both via the top-right antique chest emblem and via a thumb-reachable trigger/pull-up gesture on the bottom **Writing Dock**—so that I can open my stationery chest effortlessly while writing.
12. As a writer glancing at the editor top bar, I want the **Scholar's Stationery Chest** emblem to display subtle live status indicators when an ambient soundscape is playing or when a Time Capsule lock is active, so that I always know my sanctum state even when the chest is closed.
13. As a diarist opening the **Scholar's Stationery Chest**, I want to see five crafted **Stationery Artifacts** nestled in crimson velvet recesses with dark-lacquer plaques and a dynamic contextual sub-panel inside the chest, so that adjusting settings feels like handling treasured desk instruments.
14. As a diarist tapping the **Fanned Stationery (`叠印花笺`)** artifact, I want the paper fan to animate open with a soft paper-rustle cue and present one-tap stationery suites alongside my custom templates and an entry point to the Custom Template Studio.
15. As a diarist tapping the **Porcelain Brush Mountain (`青花笔架`)** artifact, I want the resting spotted-bamboo brush to lift subtly with a ceramic tap cue and reveal unified controls for font family, font size, line spacing, ink tone (`松烟焦墨`, `朱砂批注`, `竹青石绿`), and poetry center alignment.
16. As a diarist tapping the **Guqin Zither (`桐木古琴`)** artifact, I want the seven silk strings to vibrate gently with a harmonic pluck cue and let me start, switch, adjust volume, or silence offline ambient soundscapes (`蕉窗听雨`, `松下抚琴`, `书斋炉暖`, `静默收琴`).
17. As a diarist tapping the **Brass Fish Lock (`古法鱼锁`)** artifact, I want the brass key and shackle to animate with a crisp metallic click and let me seal the entry until a preset milestone (1 month, New Year, 1 year, custom date) or unlock an unsealed draft.
18. As a diarist tapping the **Twin Bamboo Brushes (`双管毛笔`)** artifact in the top groove, I want the brushes to respond with a gentle lift micro-animation and clear "coming soon" placeholder status in the contextual sub-panel without altering my text, reserving that slot cleanly for future stroke-animation controls.
19. As a quiet-environment user, I want artifact micro-chimes to respect system/sanctum mute preferences and pair with subtle native haptics, so that tactile feedback never intrudes unexpectedly in silent settings.
20. As an author personalizing my journal, I want to configure my 2–4 character **Cinnabar Signature Seal** text (defaulting to `心迹安放`) once in Settings as my global signature, so that all my diary entries carry my personal colophon stamp.
21. As a stationery enthusiast, I want the **Cinnabar Signature Seal** rendered on the **Journal Sheet** to automatically adopt relief (`朱文`阳刻) or intaglio (`白文`阴刻) carving and complementary seal ink according to the active template, and allow cycling relief/intaglio in Custom Template Studio.
22. As a lover of classical Chinese literature, I want to open a read-only **Keepsake Scroll View (`卷轴赏鉴`)** from the editor top bar to admire my entry laid out in right-to-left vertical columns (`vertical-rl`) with vertical CJK punctuation, **Tipped-In Ephemera Cards**, lunar/seasonal colophon, and my **Cinnabar Signature Seal**—while keeping live typing in fast, natural horizontal flow.
23. As a diarist archiving or printing entries to PDF, I want the PDF export engine to reproduce my stationery substrate tint, cold gold flecks, silk rule tint, snapped **Tipped-In Ephemera Cards**, **Cinnabar Signature Seal**, and optional vertical-column (`卷轴竖排`) or horizontal layout with 1:1 vector fidelity.
24. As a custom stationery creator in the Custom Template Studio, I want to configure substrate texture/flecks, silk rule tint, and seal carving style and save them seamlessly without breaking existing templates or backups.
25. As a user with accessibility needs or a compact 320px screen, I want every **Stationery Artifact** plaque, contextual sub-panel chip, and media action bar button to expose clear `Semantics` labels, clamp horizontal toolbar text scaling (`<= 1.3`), and render on mid-range devices at 60 FPS using cached `ui.Picture` static vector layers.

## Implementation Decisions

### 1. Backward-Compatible Four-Layer Stationery Token Serialization (Derived from Prototype)
- Preserve the locked SQLite `templates` table schema without requiring a destructive database migration by encoding extended multi-layer visual tokens inside `background_value` as a structured JSON object, while continuing to accept plain `#RRGGBB` / `#AARRGGBB` hex strings for all existing built-in and custom rows:

```dart
// Derived from the 4-layer Canvas Workbench prototype state shape
enum PaperSubstrate { xuan, coldGold, minimal, kraft, obsidian }
enum RuleInkTint { slate, vermilion, charcoal, jade }
enum SealCarvingStyle { zhuwen, baiwen, hidden }

class StationeryVisualTokens {
  final Color backgroundColor;
  final PaperSubstrate substrate;
  final RuleInkTint ruleTint;
  final SealCarvingStyle sealStyle;
  final bool showGoldFlecks;
}
```

- When `background_value` starts with `{`, parse the JSON keys (`bg`, `substrate`, `ruleTint`, `sealStyle`, `goldFlecks`) with safe fallbacks; when it starts with `#` or hex digits, resolve sensible defaults (`PaperSubstrate.minimal` or `PaperSubstrate.kraft` for `paper_texture`, `RuleInkTint.slate`, `SealCarvingStyle.zhuwen`).
- Curated **Stationery Suites** exposed in **Fanned Stationery** (*文房遗韵 · 朱丝宣纸*, *冷金洒粉 · 暖笺*, *竹青九宫 · 手账方格*, *松烟夜墨 · 暗夜*, plus existing built-in templates) apply cohesive substrate, rule tint, and typography defaults in one tap without mutating `content_delta`.

### 2. Snapped Canvas Layout Metrics & Baseline Alignment
- Extend `BaselineMetricsCalculator` and `TemplateCanvasPainter` with an integer-snapped frame calculator derived from the prototype's `computeLayoutMetrics`:
  - Line stride $H_{\text{row}}$ equals the exact measured line height of the active `TypographySettings`.
  - For `grid` and `dot_grid` backgrounds, horizontal cell pitch equals $H_{\text{row}}$ and the inner grid width snaps to $\lfloor W_{\text{avail}} / H_{\text{row}} \rfloor \times H_{\text{row}}$, centered symmetrically inside horizontal margins so partial orphan cells are never cut in half at the right edge.
  - Horizontal rules, grid rows, and dot rows anchor below `JournalLetterhead` (`effectiveHeaderY`), respecting scroll offset and silk rule ink tint (`RuleInkTint`).
  - Static substrate layers (Xuan paper fiber noise, Cold Gold fleck polygons/dots, and soft book-spine vignette) record once per `(size, substrate, backgroundColor)` tuple into an immutable `ui.Picture` cache.

### 3. Integer-Row Height Snapper & Tipped-In Ephemera Cards
- Wrap both `SandboxedImageEmbedBuilder` and `SandboxedVideoEmbedBuilder` inside a shared **Integer-Row Height Snapper** (`GridSnappedEmbedContainer`) parameterized by the editor's active `rowHeight`, paper background/matte color, and read-only state:
  - Given available content width $W$, aspect ratio $AR$ (`auto` natural ratio clamped between `4:5` and `16:9`, or explicit `4:3` / `1:1`), and caption height $H_{\text{caption}}$, compute raw card height $H_{\text{raw}} = (W / AR) + H_{\text{caption}}$.
  - Compute integer row count:
    $$N = \max\left(3, \left\lceil \frac{H_{\text{raw}} + 24.0}{\text{rowHeight}} \right\rceil\right)$$
  - Enforce an exact `SizedBox(height: N * rowHeight)` outer box and distribute surplus vertical space $\Delta = (N \times \text{rowHeight}) - H_{\text{raw}}$ evenly across top and bottom padding. Because `GridSnappedEmbedContainer` reads the live `rowHeight`, changing font size or line spacing immediately re-snaps every media block on screen.
- **Tipped-In Ephemera Card** visual treatment & metadata:
  - Opaque warm paper-toned matte frame (masking canvas rules underneath), rounded print corners, subtle elevation shadow, and inline video playback (`SandboxedVideoPlayer`) displaying its WebP poster frame with a cinnabar/brass play seal until tapped.
  - Optional per-embed caption and framing aspect ratio serialize backward-compatibly inside the Quill embed payload (accepting plain relative path strings `'media/{uuid}.webp'` for legacy entries and structured JSON `{'path': 'media/...', 'caption': '...', 'aspect': 'auto'}` when annotated, while preserving relative-path sandbox isolation).
  - Tapping a card in edit mode toggles an inline contextual floating action bar (`[题跋 Caption]`, `[画幅 Aspect]`, `[移除 Remove]`) directly above the card rather than inside the **Scholar's Stationery Chest**.

### 4. Scholar's Stationery Chest & Decomposed Artifact Painters
- Replace the editor's top-bar overflow menu (`PopupMenuButton`) and separate modal invocations with the unified **Scholar's Stationery Chest** (`ScholarChestDrawer`):
  - **Dual Access Seams**:
    1. Top-bar antique chest emblem button displaying compact live status badges when an ambient soundscape is playing (`AudioSanctumService`) or when a Time Capsule `unlockAt` date is active.
    2. A pull-up handle / chest trigger integrated on the bottom **Writing Dock** for single-handed thumb reach.
  - **Chest Layout & Modularity**:
    - Styled with a woven brocade outer rim, crimson velvet recessed tray, dark-lacquer gold-rimmed plaques, and a dynamic contextual sub-panel at the top of the chest that updates in place when switching artifacts.
    - Decompose each **Stationery Artifact** into its own modular widget (`< 450` lines each) caching static vector paths into `ui.Picture` layers and animating only lightweight moving parts (`Transform.translate` / `Transform.rotate` / damped string wave) guarded against repeating test tickers:
      1. **Twin Bamboo Brushes** (`双管毛笔`): Interactive placeholder in the top horizontal velvet groove; animates brush lift on tap and displays a poetic "笔锋运墨动效 · 敬请期待" notice in the sub-panel without mutating entry state.
      2. **Fanned Stationery** (`叠印花笺`): 3-sheet paper fan animation; sub-panel switches curated stationery suites, custom templates, and links to Custom Template Studio.
      3. **Porcelain Brush Mountain** (`青花笔架`): Spotted-bamboo brush lifts off three-peak cobalt porcelain rest; sub-panel controls font family (`TypographyCatalog`), font size, line spacing, ink tone (`#1F1D1A` 焦墨, `#B83B2E` 朱砂, `#2F5241` 竹青), and paragraph center alignment for poetry.
      4. **Guqin Zither** (`桐木古琴`): 7-string harmonic pluck animation; sub-panel controls `AudioSanctumService` presets (`蕉窗听雨`, `松下抚琴`, `书斋炉暖`, `静默收琴`) and volume.
      5. **Brass Fish Lock** (`古法鱼锁`): Brass key rotation and shackle slide; sub-panel offers quick Time Capsule presets (`封缄一月`, `封至元旦`, `封缄一年`, `自选吉日`, `解除封缄`).
  - **Tactile Chimes & Haptics**:
    - Extend `ProceduralAudioSynthesizer` / `AudioSanctumService` with lightweight cached 16-bit PCM micro-chime WAV buffers (`paperRustle`, `ceramicBrushTap`, `guqinPluck` pentatonic $D_4\text{–}A_4\text{–}E_5$, `brassLockClick`) paired with `HapticFeedback.lightImpact()` / `selectionClick()`, suppressed automatically in unit/widget test environments or when tactile sound is muted.

### 5. Global Cinnabar Signature Seal & Keepsake Scroll View
- **Cinnabar Signature Seal (`落款朱砂印`)**:
  - Persist the user's 2–4 character seal inscription (default `心迹安放`) via an injectable secure/preferences settings service surfaced in `SettingsScreen` under **"落款朱砂印 (Signature Seal)"**.
  - Render the colophon seal on the **Journal Sheet**, **Keepsake Scroll View**, and exported PDFs in either relief (`朱文`: cinnabar border and characters over translucent ground) or intaglio (`白文`: solid cinnabar block with carved paper-colored characters), or hidden when `SealCarvingStyle.hidden`.
- **Keepsake Scroll View (`卷轴赏鉴`) & PDF Parity**:
  - Accessible via a `[📜 赏鉴]` action in the editor top bar, opening a read-only fullscreen modal that converts the entry's Quill Delta blocks and media embeds into a shared right-to-left vertical column layout (`vertical-rl`):
    - Lays out columns from right to left snapped to integer column widths, maps horizontal CJK brackets/punctuation (`「」『』《》（）—…`) to vertical presentation forms (`﹁﹂﹃﹄︽︾︵︶︱⋮`), places **Tipped-In Ephemera Cards** cleanly across column spans, and stamps the lunar/Gregorian colophon and **Cinnabar Signature Seal** at the terminal column.
  - Reuse the shared vertical column layout geometry and 4-layer stationery rendering inside `PdfTemplateRenderer` / `PdfExportEngine`, allowing users to export single entries in either standard horizontal stationery mode or classical vertical scroll (`卷轴竖排`) PDF mode with 1:1 WYSIWYG parity.

## Testing Decisions

### What Makes a Good Test
- Test observable user journeys, layout bounding-box invariants ($H_{\text{total}} = N \times \text{rowHeight}$), SQLite persistence, backward compatibility with legacy entries/templates, and Delta content immutability—never private helper fields, internal `ui.Picture` cache handles, or fragile pixel golden snapshots.
- Use bounded `tester.pump(duration)` calls for spring micro-animations and guard procedural audio players in headless test harnesses.

### Seams & Modules Tested
1. **Primary End-to-End Editor Seam (`EntryEditorScreen`)**:
   - Opening and closing the **Scholar's Stationery Chest** from both the top-bar chest emblem and the bottom **Writing Dock** pull-up trigger, verifying live soundscape and Time Capsule status indicators on the top-bar emblem.
   - Selecting each of the five **Stationery Artifacts** (**Fanned Stationery**, **Porcelain Brush Mountain**, **Guqin Zither**, **Brass Fish Lock**, and the **Twin Bamboo Brushes** placeholder), verifying contextual sub-panel transitions, SQLite `templateId` and `unlockAt` persistence, live typography/ink-tone/alignment updates, `AudioSanctumService` preset activation, and 100% `contentDelta` preservation across repeated template switches.
   - Rendering embedded photos and short videos through the **Integer-Row Height Snapper**, asserting that the rendered widget height equals an exact integer multiple of the active `rowHeight` before and after font-size/line-spacing changes, verifying **Tipped-In Ephemera Card** inline video thumbnail presentation, and exercising the contextual floating action bar (captioning, aspect ratio toggle, removal).
   - Opening the **Keepsake Scroll View** modal from the editor, verifying right-to-left vertical column rendering, CJK vertical punctuation mapping, and **Cinnabar Signature Seal** display without mutating the underlying Quill document.
2. **Canvas Geometry & Vector PDF Export Seam (`TemplateCanvasPainter` & `PdfExportEngine`)**:
   - Recording canvas draw operations to verify integer-snapped column/grid centering, `RuleInkTint` stroke colors, `PaperSubstrate` rendering (including Cold Gold flecks and Obsidian dark mode), and round-trip parsing of both legacy `#RRGGBB` strings and extended `background_value` JSON payloads.
   - Generating valid `%PDF-` bytes in both horizontal stationery and vertical keepsake (`卷轴竖排`) modes with custom substrates, rule tints, media embeds, and **Cinnabar Signature Seal**.
3. **Global Signature & Custom Template Studio Seam (`SettingsScreen` & `CustomTemplateEditorScreen`)**:
   - Editing and persisting the 2–4 character **Cinnabar Signature Seal** inscription in Settings (with validation and default `心迹安放` fallback) and verifying its reflection in the editor.
   - Authoring and saving custom multi-layer templates (substrate, rule tint, seal carving style) in the Custom Template Studio and verifying round-trip SQLite persistence.

### Prior Art
- Existing full-bleed editor, letterhead, and dock widget tests in the editor screen test suite.
- Existing `RecordingCanvas` geometry assertions in the template canvas painter test suite and vector PDF export suites.
- Existing custom template studio and settings preference round-trip widget tests.

## Out of Scope

- Live `vertical-rl` interactive text input, vertical cursor hit-testing, or vertical IME composition inside `flutter_quill` (deliberately excluded per ADR 0005; vertical calligraphy is served cleanly by the read-only **Keepsake Scroll View** and PDF exporter).
- Discrete single-character cell matrix input mode (`逐字入格`) in the live editor (deliberately excluded to preserve native mobile Pinyin phrase composition and selection gestures).
- Implementing the live stroke-by-stroke calligraphy writing animation behind the **Twin Bamboo Brushes** artifact (intentionally scoped as a visual placeholder artifact in this specification for a dedicated future milestone).
- Classical two-line stacked interlinear commentary (`双行夹注`) inside Quill Delta blocks (deferred to keep line-box heights strictly uniform on ruled stationery).
- Cloud sync, remote font downloads, or external audio asset streaming (100% offline, $0 FOSS invariant).

## Further Notes

- Respects **ADR 0003** (Full-Bleed Journal Sheet & Minimalist Writing Dock) and **ADR 0005** (Scholar's Stationery Chest & Canvas Baseline Redesign).
- Upholds **Coding Standards**: all custom artifact painters stay under 450 lines per file with static `ui.Picture` caching, descriptive domain widget keys (`chest_*`, `media_card_*`, `keepsake_*`), clamped horizontal toolbar text scaling (`<= 1.3`), scoped `Semantics` labels, immediate `SnackBar` dismissal before showing new feedback, and strict zero-network quarantine.
