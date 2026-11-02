# Synchronized Paper Heart Geometry, Strut Baseline Lock, and Classical Double Outer Border

## Context
Following the analysis of the Canvas Layout Workbench prototype (`memodiary_canvas_layout_benchmark.dart` and `media_1793547181056_31a2f791.html`), several root causes for residual visual untidiness and character/grid desynchronization in `EntryEditorScreen` were identified:
1. **Header Fractional Phase Drift**: `JournalLetterhead` had an unconstrained dynamic height (~109.8px), which was a non-integer multiple of `rowHeight` ($109.8 / 24 = 4.575$). This introduced a fractional phase shift into the text starting point, misaligning horizontal rules and vertical grids.
2. **Grid Pitch & Letter-Spacing Mismatch**: Grid templates (`midori_grid`, `dot_grid`) drew vertical lines at intervals of `lineStridePx` (24px), while CJK characters in `flutter_quill` advanced by their natural font width (16px), causing vertical grid lines to slice through character bodies.
3. **Horizontal Margin Asymmetry**: `_computeSnappedGridX` centered grids with an offset ($X = 28\text{px}$), whereas `QuillEditor` had static left padding ($X = 24\text{px}$), causing a 4px initial offset error.
4. **Lack of Classical Paper Framing**: Ruled lines bled edge-to-edge ($X=0$ to screen width), looking like a spiral notebook rather than a scholar's framed stationery sheet ("一方素笺").
5. **Headings and Quotes Drifting Off Baselines**: In `flutter_quill`, headings had arbitrary padding, allowing lines following an H1/H2 to permanently drift off ruled baselines.

## Decision
We establish the **Synchronized Paper Heart Geometry & Framing Pipeline**:

1. **Paper Heart (`innerFrameRect` · 版心) & Heaven/Earth Margins (`天头地脚`)**:
   - The writing sheet is formally partitioned into top Heaven Margin ($\ge 52\text{px}$), bottom Earth Margin ($\ge 44\text{px}$), and an integer-snapped Paper Heart (`innerFrameRect`).
   - `JournalLetterhead` is wrapped in an integer-row height snapper: $H_{\text{snapped}} = \lceil H_{\text{raw}} / \text{lineStridePx} \rceil \times \text{lineStridePx}$, absorbing internal height variance with symmetric vertical padding.
   - Text viewport padding (`QuillEditor`) is dynamically synchronized with the calculated `innerFrameRect.left` and `innerFrameRect.top`.

2. **Classical Double Outer Border (`文武双栏`)**:
   - Rulings no longer bleed to screen edges. `TemplateCanvasPainter` encloses the Paper Heart in a traditional double outer border (outer stroke 2.0px inflated by 4px, inner stroke 0.9px).
   - In Genkō Yōshi manuscript mode, render the classical Fishtail Mark (`版心黑鱼尾`) in a central unruled column when columns $\ge 7$.

3. **Strut Baseline Lock & Dynamic Grid Letter-Pitch**:
   - In `flutter_quill` `DefaultStyles`, paragraphs enforce `StrutStyle(height: lineStridePx / fontSize, forceStrutHeight: true)` to lock horizontal line heights.
   - For grid/dot-grid templates, dynamically inject `letterSpacing = lineStridePx - fontSize` so each Chinese glyph advances by exactly one grid square width.
   - Headings H1 and H2 are strictly clamped to $2 \times \text{rowHeight}$ total height, H3 to $1 \times \text{rowHeight}$, preventing downstream vertical drift.

4. **Vertical Tategaki & Interlinear Sub-Notes (`双行夹注`) in Keepsake Scroll View**:
   - Active typing in `EntryEditorScreen` remains horizontal LTR for mobile keyboard/IME compatibility.
   - The read-only `KeepsakeScrollView` is upgraded with the benchmark's vertical CJK punctuation rotation (`Transform.rotate(angle: pi / 2)`), corner punctuation offset (`Alignment(0.45, -0.45)`), and authentic dual-column sub-cells for `{夹注:...}` annotations.
   - A dedicated `〘注〙` button is added to the `WritingDock` to insert `{夹注:...}` templates.

## Consequences
- **Zero Phase Drift**: Characters sit squarely on horizontal baselines and centered inside grid squares with 0px fractional offset.
- **Authentic Literati Aesthetic**: Framing lines within the classical double border recreates the refined look of traditional woodblock-printed and silk-lined stationery.
- **Full IME Compatibility**: Diarists enjoy effortless mobile typing in horizontal Quill flow while producing heirloom-quality vertical Keepsake Scrolls and PDF exports.
- **Strict Decoupling**: Delta JSON payloads remain pure strings/deltas; templates remain visual overlays; file sizes strictly comply with repository $< 450$ LOC standards.

