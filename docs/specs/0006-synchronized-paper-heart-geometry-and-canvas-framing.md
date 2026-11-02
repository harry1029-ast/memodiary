---
id: SPEC-006
title: Synchronized Paper Heart Geometry, Strut Baseline Lock & Classical Double Outer Border
status: completed
created_at: 2026-11-02T14:09:00+08:00
---

# Specification: Synchronized Paper Heart Geometry, Strut Baseline Lock & Classical Double Outer Border

## Problem Statement

Even after introducing four-layer stationery substrates and baseline-snapped media embeds, writing on the **Journal Sheet** still exhibits five visible structural and typographic misalignments when compared against classical scholar stationery and the Canvas Layout Workbench prototype:

1. **Fractional Header Phase Drift**: The **Journal Letterhead** has an unconstrained intrinsic height (e.g., ~109.8px, or $4.575 \times 24\text{px}$ line stride) that changes unpredictably when an entry title wraps onto multiple lines. Because its vertical footprint is not clamped to an integer multiple of the active line stride, the rich-text viewport begins at a fractional vertical offset, causing characters to float above or sink through ruled baselines.
2. **Grid Pitch vs. Character Advance Slicing**: On orthogonal grid and dot-grid templates, vertical grid lines step at intervals equal to the line stride (e.g., 24px or 28px), whereas CJK characters in horizontal editing advance at their natural 16px glyph width (`letterSpacing = 0`). Vertical grid lines consequently slice right through character bodies rather than framing one glyph cleanly inside each cell.
3. **Horizontal Margin Asymmetry**: Snapped grid columns center themselves symmetrically within horizontal margins (e.g., starting at $X = 28\text{px}$), while the rich-text editor applies a static left content padding (e.g., $X = 24\text{px}$), introducing an immediate horizontal offset on the very first character of every line.
4. **Edge-to-Edge Ruling Bleed (Missing Scholar Framing)**: Horizontal rules bleed continuously from $X = 0$ to the physical screen edges and lack dedicated top and bottom isolation zones, making classical Xuan and Cold Gold substrates resemble modern spiral-bound office pads rather than a framed scholar's leaf (*一方素笺*).
5. **Heading Drift & Incomplete Classical Vertical Annotations**: Rich-text headings (`H1`, `H2`, `H3`) use arbitrary vertical spacing that knocks all subsequent body paragraphs off the ruled grid. Meanwhile, diarists who compose literary commentary lack a one-tap way to author classical **Interlinear Sub-Notes** (`双行夹注` via `{夹注:...}`) and view them rendered as authentic dual-column small-script annotations alongside rotated/corner-aligned CJK punctuation in the **Keepsake Scroll View** and exported PDFs.

## Solution

Introduce a unified **Synchronized Paper Heart Geometry & Framing Pipeline** across the **Journal Sheet**, **Keepsake Scroll View**, and headless PDF exporter:

1. **Bounded Paper Heart (`版心`) & Heaven and Earth Margins (`天头地脚`)**:
   - Partition the **Journal Sheet** into dedicated top **Heaven Margin** ($\ge 52\text{px}$) and bottom **Earth Margin** ($\ge 44\text{px}$) zones flanking an integer-snapped **Paper Heart** (`innerFrameRect`) whose width and height are exact integer multiples of the active cell advance and line stride.
   - Wrap the **Journal Letterhead** inside a dynamic integer-row height snapper ($H_{\text{snapped}} = \lceil H_{\text{raw}} / \text{lineStridePx} \rceil \times \text{lineStridePx}$) that absorbs single-line or multi-line title height variations using symmetric vertical padding, eliminating fractional vertical phase shifts.
   - Synchronize the rich-text editor's left, right, and top viewport bounds directly to `innerFrameRect` so the first glyph of every line starts at the exact horizontal origin of the first column/cell.
2. **Classical Double Outer Border (`文武双栏`) & Fishtail Mark (`版心黑鱼尾`)**:
   - Confine all horizontal rules, orthogonal grids, dot matrices, and kraft guidelines strictly inside the **Paper Heart** (`innerFrameRect`), eliminating screen-edge line bleed.
   - Frame the **Paper Heart** on classical lined, grid, and blank-framed stationery with a traditional **Double Outer Border**—an outer heavy stroke (`2.0px`, inflated by `4.0px`) paired with an inner fine stroke (`0.9px`).
   - When rendering manuscript-grid framing with sufficient horizontal breadth ($\ge 7$ columns), reserve a central unruled folding column adorned with a classical **Fishtail Mark** (`版心黑鱼尾`), suppressing it gracefully on narrow viewports ($< 7$ columns).
3. **Strut Baseline Lock, Dynamic Grid Letter-Pitch & Heading Clamping**:
   - Enforce `StrutStyle(fontSize: fontSize, height: lineStridePx / fontSize, forceStrutHeight: true)` on editor body paragraphs, placeholders, and blockquotes so mixed CJK/Latin runs never expand a line's vertical box beyond `lineStridePx`.
   - Dynamically inject `letterSpacing = lineStridePx - fontSize` when an orthogonal grid or dot-grid template is active (reverting to `0.0` on lined and plain substrates) so every CJK character advances horizontally by exactly one grid square width without mutating the underlying Quill Delta content.
   - Clamp `H1` and `H2` block heights (text box + symmetric vertical spacing) to $2 \times \text{lineStridePx}$ and `H3` to $1 \times \text{lineStridePx}$ so body paragraphs following any heading remain 100% locked to ruled baselines.
4. **Interlinear Sub-Notes (`双行夹注`) & Vertical Punctuation Fidelity**:
   - Add a dedicated `〘注〙` quick-insert action to the **Writing Dock** formatting ribbon that inserts `{夹注:}` (or wraps the current inline selection as `{夹注:<selected>}`) and positions the caret inside the braces for effortless mobile input.
   - Upgrade **Keepsake Scroll View** and vertical scroll PDF export (`卷轴竖排`) to parse `{夹注:...}` spans into authentic dual-column half-scale character pairs (`双行夹注`) within a single vertical column width, apply `π/2` rotation to vertical brackets/dashes/ellipses where needed, and offset ideographic stops (`。`, `、`, `，`) toward the upper-right cell corner (`Alignment(0.45, -0.45)`).

## User Stories

1. As a diarist opening an entry on the **Journal Sheet**, I want the canvas partitioned into traditional **Heaven and Earth Margins** ($\ge 52\text{px}$ top, $\ge 44\text{px}$ bottom) around a centered **Paper Heart**, so that my writing rests inside balanced literati stationery proportions rather than crowding screen edges.
2. As a diarist typing a short or multi-line entry title in the **Journal Letterhead**, I want the letterhead container's total height to snap dynamically to an exact integer multiple of my active line stride, so that the first and fiftieth lines of my diary body sit squarely on ruled baselines with zero fractional drift.
3. As a diarist editing an entry whose title wraps from one line to two or three lines on a narrow handset, I want the **Journal Letterhead** snapper to smoothly expand by whole `lineStridePx` increments, so that neither title text is clipped nor body lines shift off their baselines.
4. As a diarist writing on lined, manuscript, or blank-framed classical stationery, I want a **Double Outer Border** (`文武双栏` with a 2.0px outer frame and 0.9px inner frame) enclosing the **Paper Heart**, so that ruled lines never bleed crudely to the bezel.
5. As a diarist switching to an orthogonal grid (`方格`) or dot-grid (`点阵`) template, I want horizontal character pitch to adjust automatically (`letterSpacing = lineStridePx - fontSize`), so that each Chinese character centers cleanly inside its own grid cell without vertical grid lines slicing through glyphs.
6. As a diarist switching back from a grid template to a lined or plain Xuan paper template, I want horizontal character pitch to return automatically to natural fluid spacing (`letterSpacing = 0.0`), so that prose reads with organic calligraphic rhythm while my saved Quill Delta text remains 100% unchanged.
7. As a diarist writing the first character of a paragraph on a grid or lined template, I want the rich-text editor's left and right padding to match the snapped **Paper Heart** (`innerFrameRect.left` and `canvasWidth - innerFrameRect.right`) to the exact pixel, so that there is no horizontal offset between my text margin and the drawn grid border.
8. As a bilingual diarist mixing Chinese characters, English words, numbers, and emoji in the same paragraph, I want `StrutStyle(forceStrutHeight: true)` enforced on every paragraph line, so that differing Latin/CJK font metrics never stretch a single line's height and desynchronize subsequent lines from the background rules.
9. As a diarist structuring long reflections with `H1`, `H2`, `H3`, and `Quote` blocks, I want `H1` and `H2` lines clamped to exactly $2 \times \text{lineStridePx}$ and `H3` and `Quote` lines clamped to $1 \times \text{lineStridePx}$, so that paragraphs beneath headings land cleanly back on the stationery lines.
10. As a diarist adjusting font size or line spacing via the **Porcelain Brush Mountain** inside the **Scholar's Stationery Chest**, I want the **Paper Heart** dimensions, **Journal Letterhead** snapped height, `StrutStyle` height, grid `letterSpacing`, and **Tipped-In Ephemera Cards** to recompute in unison on the next frame.
11. As a diarist appreciating classical woodblock stationery (`原稿` / framed manuscript grid) on a screen wide enough for 7 or more columns, I want a central unruled folding column with a traditional **Fishtail Mark** (`版心黑鱼尾`) rendered inside the **Paper Heart**, recreating the look of thread-bound folio leaves.
12. As a diarist using a compact 320px screen or very large font size where fewer than 7 columns fit across the **Paper Heart**, I want the central **Fishtail Mark** gap suppressed automatically, so that my available writing columns are never cramped or wasted.
13. As a diarist scrolling through a multi-page entry on the **Journal Sheet**, I want the **Paper Heart** rulings and **Double Outer Border** geometry to track scroll offset smoothly at 60 FPS while static paper fibers and Cold Gold flecks remain cached in an immutable `ui.Picture` layer.
14. As a diarist writing literary notes or travel commentary, I want a `〘注〙` button in the **Writing Dock** formatting ribbon that inserts `{夹注:}` at my cursor and places the caret right inside the braces, so I do not have to type curly braces and colons manually on a mobile keyboard.
15. As a diarist who selects a phrase of existing text and taps the `〘注〙` button in the **Writing Dock**, I want the selected phrase wrapped in `{夹注:<selected>}` in a single undoable edit, so I can convert inline remarks into **Interlinear Sub-Notes** effortlessly.
16. As a diarist opening the **Keepsake Scroll View** on an entry containing `{夹注:...}` markers, I want each annotation rendered as classical **Interlinear Sub-Notes** (`双行夹注`)—two parallel right-to-left sub-columns of smaller secondary-ink characters nested neatly within a single vertical column stride—without showing raw `{夹注:}` braces.
17. As a diarist reading an entry in the **Keepsake Scroll View**, I want CJK brackets, quotation marks, dashes, and ellipses oriented vertically (via glyph mapping or `π/2` rotation) and ideographic stops (`。`, `，`, `、`) positioned in the upper-right quadrant (`Alignment(0.45, -0.45)`) of their character cells, matching traditional Chinese vertical typesetting standards.
18. As a diarist exporting an entry to PDF in either horizontal stationery mode or classical vertical scroll (`卷轴竖排`) mode, I want the exported vector PDF pages to reproduce the **Paper Heart** **Double Outer Border** framing and render `{夹注:...}` **Interlinear Sub-Notes** cleanly with 1:1 visual parity.
19. As a nocturnal writer using the Obsidian Night (`松烟夜墨`) substrate, I want the **Double Outer Border**, **Fishtail Mark**, and **Interlinear Sub-Note** secondary ink tones to adapt to low-glare dark-paper contrast automatically.
20. As a privacy-conscious user relying on full-archive backups and FTS5 search, I want `{夹注:...}` annotations stored as plain text inside standard Quill Delta strings so that offline full-text search (`entries_fts`), `.md`/`.txt` exports, and encrypted `.memodiary` backups work with zero schema changes or data loss.

## Implementation Decisions

### 1. Synchronized Paper Heart Metric Engine (Derived from Prototype)
- Introduce a pure, deterministic layout metric calculator (`StationeryLayoutCalculator`) producing an immutable `StationeryLayoutMetrics` value object shared by the canvas painter, editor viewport padding, and integer-snapped letterhead wrapper.
- Derived from the Canvas Layout Workbench prototype, the core metric record captures exact integer-snapped dimensions and **Heaven and Earth Margins**:

```dart
// Trimmed type shape derived from the Canvas Layout Workbench prototype
class StationeryLayoutMetrics {
  final double fontSize;
  final double lineStridePx;
  final double cellAdvancePx;
  final Rect innerFrameRect;
  final int columnCount;
  final int rowCount;
  final double heavenMarginPx;
  final double earthMarginPx;
}
```

- **Metric Rules**:
  - `lineStridePx` equals the active `BaselineMetricsCalculator` line height (or rounded `fontSize * lineSpacing` floored at `fontSize + 6.0`).
  - For `grid` and `dotGrid` templates, `cellAdvancePx = lineStridePx` so every cell is a true square ($H \times H$); for lined and plain substrates, horizontal width snaps cleanly to integer multiples of `cellAdvancePx` centered horizontally (`left = ((canvasWidth - snappedWidth) / 2.0).roundToDouble()`).
  - Top **Heaven Margin** enforces a minimum of `52.0px` (or `2 * lineStridePx`, whichever is greater/snapped cleanly), and bottom **Earth Margin** enforces a minimum of `44.0px`, preserving the classical *Heaven-over-Earth* (`天头大于地脚`) visual balance.

### 2. Integer-Snapped Journal Letterhead Wrapper
- Introduce a dedicated layout wrapper (`IntegerSnappedLetterhead`) around **Journal Letterhead** that measures the child's intrinsic height via a custom `SingleChildRenderObjectWidget` (or `LayoutBuilder` + intrinsic measurement pass without post-frame flicker) and clamps its outer layout box height to:
  $$H_{\text{snapped}} = \left\lceil \frac{H_{\text{raw}}}{\text{lineStridePx}} \right\rceil \times \text{lineStridePx}$$
- Surplus vertical space $\Delta = H_{\text{snapped}} - H_{\text{raw}}$ is distributed symmetrically across top and bottom padding so single-line titles, wrapped multi-line titles, and dynamic font-scale adjustments never introduce a non-integer vertical offset before the first body line.
- Bind the rich-text editor's horizontal padding directly to `metrics.innerFrameRect.left` and `canvasWidth - metrics.innerFrameRect.right`, eliminating the previous 4px discrepancy between grid cell boundaries and paragraph text origins.

### 3. Classical Double Outer Border & Fishtail Mark Decomposition
- Extract framing and manuscript ornament drawing into a dedicated modular helper (`StationeryCanvasFraming`, strictly $< 450$ LOC) invoked by `TemplateCanvasPainter`, keeping `TemplateCanvasPainter` under the 450-line modularity ceiling while preserving its existing `ui.Picture` cache for static substrates (Xuan fibers, Cold Gold flecks, Kraft/Obsidian vignettes):
  - **Confinement to Paper Heart**: All horizontal baselines, orthogonal grid lines, dot intersections, and kraft guidelines terminate strictly at `innerFrameRect.left`, `innerFrameRect.right`, `innerFrameRect.top`, and `innerFrameRect.bottom`—never bleeding across screen edges.
  - **Double Outer Border (`文武双栏`)**: Drawn around `innerFrameRect` on `lined`, `grid`, and framed `color`/`paperTexture` stationery (excluding minimalist borderless `dotGrid` or `PaperSubstrate.minimal` plain color unless silk rule tint is active), consisting of an outer stroke (`strokeWidth: 2.0`, `innerFrameRect.inflate(4.0)`, alpha `0.85`) and an inner stroke (`strokeWidth: 0.9`, `innerFrameRect`, alpha `0.70`) tinted by the active `RuleInkTint` (adapted for dark mode on `PaperSubstrate.obsidian`).
  - **Fishtail Mark (`版心黑鱼尾`)**: When rendering classical manuscript grid framing (e.g., `grid` paired with `RuleInkTint.vermilion` or `RuleInkTint.charcoal` / `PaperSubstrate.xuan` or `coldGold`) and `metrics.columnCount >= 7`, leave the central column (`midColumn = columnCount ~/ 2`) unruled horizontally and draw the traditional notched fishtail polygon near the top of the central folding strip. Automatically omit the central gap and fishtail mark when `columnCount < 7`.

### 4. Strut Baseline Lock, Dynamic Grid Letter-Pitch & Heading Clamping
- Update the editor's `DefaultStyles` builder (`EntryEditorScreen`):
  - **Paragraph, Placeholder & Quote Strut Lock**: Configure `DefaultTextBlockStyle` / text styles with explicit `height: lineStridePx / fontSize` and enforce `StrutStyle(fontSize: fontSize, height: lineStridePx / fontSize, forceStrutHeight: true)` via `QuillEditorConfig` / block styles so mixed Latin, emoji, and CJK runs occupy an invariant `lineStridePx` vertical box per line.
  - **Dynamic Grid Letter-Pitch**: When the active template is `TemplateBackgroundType.grid` or `TemplateBackgroundType.dotGrid`, set `letterSpacing: math.max(0.0, lineStridePx - fontSize)` on body text styles so each full-width CJK glyph advances by `lineStridePx` and centers inside its grid square; set `letterSpacing: 0.0` for `lined`, `paperTexture`, and `color` templates. Because this lives purely in presentation `TextStyle`, switching templates mutates zero characters in `content_delta`.
  - **Integer-Row Heading Clamping**: Set `H1` and `H2` line heights and symmetric `VerticalSpacing` so that `singleLineHeight + topSpacing + bottomSpacing == 2.0 * lineStridePx`, and `H3` so that `singleLineHeight + topSpacing + bottomSpacing == 1.0 * lineStridePx`, guaranteeing zero cumulative baseline drift below headings.

### 5. Interlinear Sub-Notes (`双行夹注`), Vertical Punctuation & PDF Parity
- **Structured Vertical Token Model (Derived from Prototype)**:
  - Extend `VerticalTypographyMapper` with a typed token representation parsing `{夹注:...}` spans alongside single vertical glyphs and rotated Latin runs:

```dart
// Trimmed token union derived from the Canvas Layout Workbench prototype
sealed class VerticalRenderToken {
  const VerticalRenderToken();
}

class VerticalGlyphToken extends VerticalRenderToken {
  final String glyph;
  final bool isCornerPunctuation;
  final bool requiresQuarterTurnRotation;
  const VerticalGlyphToken(
    this.glyph, {
    this.isCornerPunctuation = false,
    this.requiresQuarterTurnRotation = false,
  });
}

class VerticalInterlinearPairToken extends VerticalRenderToken {
  final String rightChar;
  final String leftChar;
  const VerticalInterlinearPairToken({
    required this.rightChar,
    required this.leftChar,
  });
}
```

- **Writing Dock `〘注〙` Quick Action**:
  - Add a compact `〘注〙` button (`Key('writing_dock_interlinear_note_btn')`, tooltip `'双行夹注 · Interlinear Note'`) to the expandable Tier 2 formatting ribbon in **Writing Dock**.
  - If the selection is collapsed, insert `{夹注:}` at the cursor and place the caret at `selectionOffset + 4` (immediately before `}`). If a non-empty inline text range is selected, replace the selection with `{夹注:<selectedText>}` and place the caret after `}`.
- **Keepsake Scroll View & Vector PDF Rendering**:
  - Upgrade `KeepsakeColumn` (used by **Keepsake Scroll View**) to render `VerticalInterlinearPairToken` items as a two-column `Row(textDirection: TextDirection.rtl)` of `0.56 * fontSize` (clamped `9.0..14.0`) secondary-ink characters inside one `columnWidth` cell, apply `Alignment(0.45, -0.45)` to ideographic corner stops (`。`, `，`, `、`), and apply `Transform.rotate(angle: math.pi / 2)` for unmapped horizontal brackets/dashes when fallback glyphs require rotation.
  - Mirror the **Double Outer Border** framing inside `PdfTemplateRenderer` and support `VerticalInterlinearPairToken` dual-subcolumn cells inside `PdfVerticalScrollBuilder` (and clean inline `〖...〗` presentation in horizontal PDF serialization) so exported PDFs never leak raw `{夹注:...}` syntax.

## Testing Decisions

### What Makes a Good Test
- Assert observable layout invariants, public widget geometries, recorded `Canvas` draw coordinates, exported `%PDF-` document validity, and `content_delta` immutability—never private painter fields, internal cache maps, or brittle pixel-diff golden screenshots.
- Keep every source and test module clean, modular (`< 450` LOC per production file), and free of single-letter callback/loop identifiers.

### Seams & Modules Tested
1. **Interactive Editor & Keepsake Seam (`EntryEditorScreen` & `KeepsakeScrollView`)**:
   - Render `EntryEditorScreen` across lined, grid, dot-grid, and classical Xuan templates; assert that the rendered **Journal Letterhead** wrapper height is an exact integer multiple of `lineStridePx` both for a single-line title and after entering a long wrapping multi-line title.
   - Assert that `QuillEditor`'s left/right padding matches the computed **Paper Heart** (`innerFrameRect`) horizontal bounds (`0.0px` discrepancy), that paragraphs apply `StrutStyle(forceStrutHeight: true)` locked to `lineStridePx`, that `H1`/`H2` (`2 × lineStridePx`) and `H3` (`1 × lineStridePx`) preserve downstream paragraph baseline alignment, and that switching between grid and lined templates toggles dynamic `letterSpacing` while leaving `content_delta` byte-for-byte identical.
   - Open the **Writing Dock** formatting ribbon, tap `〘注〙` (`writing_dock_interlinear_note_btn`) both at a collapsed cursor and over selected text to verify `{夹注:...}` insertion and caret placement, then open **Keepsake Scroll View** and assert that `{夹注:...}` renders dual-column **Interlinear Sub-Note** cells without displaying raw `{夹注:}` delimiters, alongside corner-aligned ideographic stops and rotated vertical punctuation.
2. **Canvas Draw-Primitive & Vector PDF Seam (`TemplateCanvasPainter` & `PdfExportEngine`)**:
   - Paint `TemplateCanvasPainter` onto a `RecordingCanvas` across viewport widths (including standard tablet/phone widths with $\ge 7$ columns and compact `320px` viewports with $< 7$ columns):
     - Verify **Heaven and Earth Margins** (`top >= 52px`, `bottom >= 44px`) isolate `innerFrameRect`.
     - Verify zero ruling lines extend to `X = 0` or `X = canvasSize.width` (100% confinement inside `innerFrameRect`).
     - Verify **Double Outer Border** draws both outer (`2.0px` stroke inflated by `4.0px`) and inner (`0.9px` stroke) border rectangles.
     - Verify the central unruled folding column and **Fishtail Mark** path render when manuscript columns $\ge 7$ and suppress cleanly when columns $< 7$.
   - Execute `PdfExportEngine` in both horizontal stationery mode and vertical scroll (`卷轴竖排`) mode on entries containing headings, grid/lined templates, and `{夹注:...}` annotations, verifying valid `%PDF-` vector output and absence of raw `{夹注:}` delimiters.

### Prior Art
- Existing full-bleed editor screen widget tests exercising `EntryEditorScreen`, **Journal Letterhead**, **Writing Dock**, and **Scholar's Stationery Chest** interactions.
- Existing **Keepsake Scroll View** widget tests and `VerticalTypographyMapper` unit assertions verifying right-to-left vertical columns and CJK punctuation mapping.
- Existing `RecordingCanvas` stroke-coordinate verification in the template canvas painter test suite and headless PDF generation assertions in the PDF export engine test suite.

## Out of Scope

- Replacing `flutter_quill` with a WebView/HTML canvas or custom per-character `TextField` matrix in the active editor (explicitly rejected per ADR 0006 to preserve offline security, 60 FPS scrolling, and native mobile Pinyin/handwriting IME composition).
- Live interactive `vertical-rl` cursor editing inside `EntryEditorScreen` (vertical presentation remains purposefully dedicated to the read-only **Keepsake Scroll View** and PDF export).
- Database schema migrations on SQLite `templates` or `entries` tables (all framing geometry, dynamic pitch, and `{夹注:...}` inline syntax operate on existing schema columns with 100% backward compatibility).
- Cloud font fetching or external rendering services ($0 FOSS, 100% offline invariant).

## Further Notes

- Respects **ADR 0003** (Full-Bleed Journal Sheet & Minimalist Writing Dock), **ADR 0005** (Scholar's Stationery Chest & Canvas Baseline Redesign), and **ADR 0006** (Synchronized Paper Heart Geometry, Strut Baseline Lock, and Classical Double Outer Border).
- Enforces **Coding Standards**: all new and refactored canvas/editor modules remain strictly under 450 lines per file, preserve `ui.Picture` static substrate caching, use descriptive domain identifiers with zero single-letter lambda variables, clamp horizontal toolbar text scaling (`<= 1.3`), and expose scoped `Semantics` labels on interactive controls.
