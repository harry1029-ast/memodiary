# Scholar's Stationery Chest & Canvas Baseline Redesign

## Context
Following user trials of the Entry Editor (`EntryEditorScreen`), several critical spatial and visual inconsistencies were identified:
1. **Ruling & Grid Baseline Disruption**: Text baselines floated in unruled gaps, and vertical grid lines sliced down the middle of characters due to arbitrary pixel divisions decoupled from typographic line strides.
2. **Media Embed Displacement**: Arbitrary-height sandboxed photo (`SandboxedImageEmbedBuilder`) and short video (`SandboxedVideoEmbedBuilder`) embeds threw all subsequent text lines off their ruled baselines. Modern digital video frames also visually clashed with classical Xuan and cold gold paper substrates.
3. **Control Sprawl vs. Immersion**: The live editor scattered template selectors, typography sheets, soundscapes, and time-capsule locks across fragmented, generic bottom sheets.
4. **Vertical-RL Feasibility Trap**: While CSS allows trivial `writing-mode: vertical-rl` declarations, `flutter_quill` is architected exclusively around horizontal LTR text line models (`RenderParagraph`, horizontal caret geometry, horizontal touch hit-testing, and IME composition candidates). A fork of Quill to support vertical editing would be fragile and high maintenance.

## Decision
We restructure the entry editor around two foundational components: a **Mathematically Locked Canvas Baseline Pipeline** and the **Scholar's Stationery Chest (文房百宝匣)**:

1. **Horizontal Editing with Canvas Baseline Snapping**:
   - The interactive editing canvas remains strictly in continuous horizontal flow within `flutter_quill`.
   - The canvas geometry painter (`TemplateCanvasPainter`) adopts `BaselineMetricsCalculator` and dynamic metric clamping (`computeLayoutMetrics`), snapping grid step sizes and line strides to integer multiples of typography font heights ($H_{\text{line}} = \text{fontSize} \times \text{lineHeight}$) centered symmetrically within the page margins.
   - We reject discrete single-character cell matrix editing for live entry composition to preserve native mobile Pinyin IME phrase composition and velocity.

2. **Integer-Row Height Snapping for Media Embeds**:
   - Wrap all image and sandboxed video embeds in an `Integer-Row Height Snapper` (`GridSnappedEmbedContainer`).
   - Given content width $W$, aspect ratio $AR$, and raw height $H_{\text{raw}} = W / AR$, the container height is mathematically clamped to:
     $$H_{\text{total}} = N \times \text{rowHeight}, \quad \text{where } N = \left\lceil \frac{H_{\text{raw}} + \text{minPadding}}{\text{rowHeight}} \right\rceil$$
   - The remaining padding $\Delta = H_{\text{total}} - H_{\text{raw}}$ is split equally into top and bottom margins, ensuring following text lines land exactly on ruled baselines.
   - Media embeds are styled as **Tipped-In Ephemera Cards (贴片拓影)** with paper-toned matte borders, soft drop shadows, and inline video playback. Media-specific controls (captions, crop, replace) are isolated in a contextual floating action bar over the tapped embed.

3. **Keepsake Scroll View (卷轴赏鉴) & PDF Export Parity**:
   - Classical right-to-left vertical column layout (`vertical-rl`) is strictly isolated from the editing engine and provided as a dedicated read-only **Keepsake Scroll View** and vector PDF export pipeline (`PdfTemplateRenderer`), rendering Quill Delta into columnar calligraphy with decorative colophons and seals.

4. **Scholar's Stationery Chest (文房百宝匣 · 锦盒书案)**:
   - Consolidate all secondary writing configuration tools into a single, tactile bottom modal drawer (`ScholarChestDrawer`) styled as an antique scholar's brocade box with molded crimson velvet lining.
   - Accessed via dual seams: the antique chest status emblem in the top app bar and a pull-up handle on the bottom writing dock.
   - Houses five physical **Stationery Artifacts (文房器物)** rendered via decomposed, picture-cached vector widgets (`< 450 LOC` per file):
     1. **Fanned Stationery (叠印花笺)** (`artifact_stationery_fan.dart`): Template selection (Xuan paper, Vermilion rules, Cold Gold flecks, Bamboo grid, Obsidian night).
     2. **Porcelain Brush Mountain (青花笔架)** (`artifact_brush_mountain.dart`): Typography font selection, font scale, line spacing, poetry center alignment, and ink density/formatting.
     3. **Guqin Zither (桐木古琴)** (`artifact_guqin_zither.dart`): Ambient soundscape selection (Rain, Pine Wind, Spring, Silence).
     4. **Brass Fish Lock (古法鱼锁)** (`artifact_fish_lock.dart`): Time capsule encryption lock duration.
     5. **Twin Bamboo Brushes (双管毛笔)** (`artifact_twin_brushes.dart`): Maintained as an interactive vector placeholder reserved for future stroke/calligraphy animation toggle.
   - Synchronize tactile spring animations with native device haptics (`HapticFeedback.lightImpact`) and subtle acoustic feedback in `AudioSanctumService`.

5. **Data Model Decoupling & Cinnabar Seal Personalization**:
   - Extended multi-layer visual tokens (paper textures, gold fleck overlays, rule ink tints, seal styles) are serialized into the existing SQLite `templates.background_value` column as structured JSON, requiring zero breaking schema migrations.
   - The Cinnabar Signature Seal text (e.g. 「心迹安放」) is stored as a global user signature preference, while carving style (relief 朱文 vs. intaglio 白文) and ink tint follow the active stationery template.

## Consequences
- **Mathematically Guaranteed Alignment**: Characters and ruled lines maintain 100% baseline synchronization across all font sizes, line spacings, and media insertions.
- **Deep Literati Immersion**: Eliminates sterile software sheets in favor of a cohesive, tactile scholar's desk set.
- **60 FPS Performance**: Modularizing artifacts into cached vector widgets prevents layout thrashing on mobile devices.
- **Zero Schema Disruption**: Existing Drift database tables and Quill Delta payloads remain clean and backward-compatible.

