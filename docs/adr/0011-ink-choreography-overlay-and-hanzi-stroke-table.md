---
status: accepted
---

# Non-Destructive Ink Choreography Overlay and Offline Binary Hanzi Stroke Table

Live stroke-by-stroke calligraphy animation (**Ink Choreography** · 挥毫落墨) on a `StationerySheet` is drawn by a non-destructive overlay on the sheet card rather than by replacing `QuillEditor` with per-character widget cells. `QuillEditor` remains the single source of truth for text layout, baseline locking (ADR-0005), Virtual Delta Partitioning (`AutoSpill` / `SpillBack`, ADR-0008), invisible `MountMarker` embeds (ADR-0009), and native IME composition.

When committed text insertions occur (`≤ 20` characters after the IME composing range collapses) or when the diarist triggers a full-sheet replay (`全页挥毫`), the overlay:
- resolves each character's rect from `RenderEditor` caret geometry (`getLocalRectForCaret` at the character's two edges, snapped to its ruled row);
- masks queued and active characters by repainting the sheet's own paper (`TemplateCanvasPainter`, clipped to those rects);
- paints the wet-ink strokes at 60 FPS, with the kinematic bamboo brush on a separate unclipped layer so its shaft is not cut off by the Paper Heart;
- dissolves the mask (`inkPrintSettle`) to reveal the underlying `QuillEditor` glyph.

To provide authentic stroke order across Chinese and Latin scripts at $0 build and runtime cost with 100% offline privacy, stroke medians from the *Make Me a Hanzi* dataset (~9,574 Simplified and Traditional Hanzi), plus curated Latin, digit, and punctuation medians, are quantized to `0..100` (`Uint8` coordinate pairs) and compiled into a single sorted binary asset (`assets/calligraphy/hanzi_strokes.bin`). At runtime a binary search over the sorted code-point index resolves any character's medians in `O(log N)` without JSON parsing. CJK ideographs outside the table fall back to a deterministic 6-stroke procedural generator, and characters from other scripts are not animated.

## Considered Options

- **Per-character flex/grid widget cells instead of `QuillEditor`**: Used in the standalone HTML studio prototype, where each character is its own `<span>` with an inline `<svg>`. Rejected for the production editor because decomposing text into per-character widgets breaks native Pinyin phrase composition, selection handles, rich-text formatting, `MountMarker` anchoring, and integer-row baseline pagination.
- **Additive wet-ink over-painting without masking**: Rejected because the static glyph showing under the brush destroys the illusion that the character is emerging from the tip.
- **Flat `backgroundColor` mask**: Rejected because the paper beneath the text carries rulings, grids, and texture (`TemplateCanvasContainer`); a flat fill would punch visible holes in them.
- **Overlay inside the Paper Heart `ClipRect`**: Rejected because the brush shaft stands ~100dp above its tip and would be cut off on the top rows.
- **Bundling raw `graphics.txt` JSON or runtime TTF path extraction**: Raw JSON adds ~30 MB and parsing overhead; TTF contours are closed outlines, not ordered directional stroke medians. The quantized median table (≈ 1 MB) keeps true stroke order and direction.

## Consequences

- **Licence exception**: the stroke data is derived from Arphic fonts under the **Arphic Public License**, which is outside `GEMINI.md`'s MIT/BSD/Apache/SIL OFL list. Like ADR 0004's ML Kit binary, this is a documented exception. The app ships the APL text (`LicenseRegistry` + asset), and the derived `hanzi_strokes.bin` remains under the APL. `GEMINI.md` §1 is updated to name this exception when the asset lands.
- **Zero schema or Delta mutation**: Ink Choreography preferences (delivery mode, bristle elasticity, cadence, brush sound) live in `EditorSettingsService` as app-wide preferences; `entries.content_delta` is never touched.
- **One `flutter_quill` coupling point**: the live IME composing range is only available on `QuillRawEditorState.composingRange` (`plainTextEditingValue.composing` is always empty). 11.6.0 exports that state publicly, so no `src/` import is needed, but the member is undocumented; it is read in one adapter file (`quill_composing_probe.dart`) that must be rechecked whenever the pinned `flutter_quill` version moves. The `StationeryQuillController` overrides that report edits (`replaceText`, `undo`, `redo`, `formatText`, the `document` setter) must likewise be rechecked for new mutation paths. The same signal now drives `EditorPaginationCoordinator.isImeComposing`, which previously was never set outside tests.
- **Immediate interruption safety**: `QuillEditor` already holds the committed text under the mask, so any interruption (typing, tapping the sheet, turning pages, undo, spill) simply clears the overlay queue and reveals all glyphs at once.
