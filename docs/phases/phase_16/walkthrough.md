# Walkthrough — Milestone 3.6: DIY Photobook Studio, Offline CJK Font Fix & WYSIWYG Vector PDF Renderer (Phases 15 & 16)

## Overview

**Intermediate Milestone 3.6 (DIY Photobook Studio & Interactive Scrapbook Editor / 自助排版影集工作台)** is now complete across Phases 14, 15, and 16:
- **Phase 15**: Delivered the Book Overview 2-page spread feed (`AlbumBookOverviewScreen`), the interactive drag-and-drop single-page editor (`AlbumPageEditorScreen`), and the 5 studio drawers (`Removed`, `Add`, `Background`, `Layout`, `Themes & Style`).
- **Phase 16**: Resolved the offline CJK PDF font fallback issue (`"???????"` → Type0 `Identity-H` TrueType CJK font with `/ToUnicode` CMap), built the WYSIWYG `AlbumStudioDocument` vector PDF renderer supporting 1–6 photo collage templates, procedural vector background motifs, stickers/overlays, and 3 export formats (`A4 Landscape`, `Square Keepsake`, and `2-Page Bound Spreads`).

---

## Phase 16 Key Deliverables

### 1. Offline CJK Font Resolution Fix (`lib/features/import_export/services/`)
- **[offline_cjk_ttf_generator.dart](file:///home/harry1029/projects/memodiary/lib/features/import_export/services/offline_cjk_ttf_generator.dart)**:
  - **Watchpoint 1 Guard**: Generates a deterministic, OpenType/TrueType (`sfnt`) binary font in memory with verified 32-bit table checksums (`head`, `hhea`, `maxp`, `OS/2`, `hmtx`, `cmap`, `loca`, `glyf`, `name`, `post`) and a Format 4 `cmap` subtable using linear `idDelta` mapping (`idRangeOffset = 0`) so every character across ASCII/Latin (`0x0020..0x03FF`), General Punctuation (`0x2000..0x27BF`), CJK Symbols (`0x3000..0x33FF`), CJK Unified Ideographs (`0x4E00..0x9FFF`), and Fullwidth Forms (`0xFE30..0xFFEF`) maps to a unique glyph index (`1..25440`), preventing `TtfWriter.withChars` glyph-index collisions while keeping subsetted PDF fonts compact (~1–3 KB).
- **[pdf_font_resolver.dart](file:///home/harry1029/projects/memodiary/lib/features/import_export/services/pdf_font_resolver.dart)**:
  - Added `factory PdfFontResolver.cjk()` (`isCjkCapable = true`), now used by default in both [`AlbumPdfExporter`](file:///home/harry1029/projects/memodiary/lib/features/albums/services/album_pdf_exporter.dart) and [`PdfExportEngine`](file:///home/harry1029/projects/memodiary/lib/features/import_export/services/pdf_export_engine.dart).

### 2. WYSIWYG Studio Vector PDF Renderer (`lib/features/albums/services/`)
- **[image_format_transcoder.dart](file:///home/harry1029/projects/memodiary/lib/features/import_export/services/image_format_transcoder.dart)**:
  - **Watchpoint 2 Guard (PDF Memory & File Size)**: Clamps decoded raster frames to `maxDimension = 1400` and immediately disposes native `ui.Image` / `ui.Codec` handles during multi-page photobook generation.
- **[pdf_vector_graphics_painter.dart](file:///home/harry1029/projects/memodiary/lib/features/albums/services/pdf_vector_graphics_painter.dart)**:
  - Renders all 9 procedural background graphic motifs (`ink_bamboo_mountains`, `floral_allover`, `corner_vines`, `bottom_left_sprig`, `bottom_right_bloom`, `abstract_fluid`, `beach_lemon_palm`, `rainbow_paper_plane`) and vector overlay elements (`sticker`, `datePill`, `text`, `sealStamp`) using `package:pdf` `pw.CustomPaint` and `PdfGraphics`.
- **[album_studio_pdf_renderer.dart](file:///home/harry1029/projects/memodiary/lib/features/albums/services/album_studio_pdf_renderer.dart)**:
  - Translates normalized `0.0..1.0` `PageLayoutTemplate` slot `Rect`s into exact PDF page coordinates inside a fixed-size `pw.Stack`.
  - **Watchpoint 3 Guard (2-Page Bound Spread Math)**: Partitions `AlbumPdfPageFormat.boundSpread` (`420 × 210 mm`) strictly at $x = 0.5 \times W$ (`halfW`), placing the left leaf in `[0, halfW]`, the right leaf in `[halfW, W]`, and a $0.03 \times W$ spine crease shadow centered at `halfW`.
  - **Watchpoint 4 Guard (Single-Page Overflow Protection)**: Wraps all captions, date headers, and overlay labels with `maxLines: 2, overflow: pw.TextOverflow.clip` and renders photos inside `pw.ClipRRect` with `pw.BoxFit.cover`.
- **[album_pdf_exporter.dart](file:///home/harry1029/projects/memodiary/lib/features/albums/services/album_pdf_exporter.dart)**:
  - Added `AlbumPdfPageFormat.boundSpread` (`1190.56 × 595.28 pt` / `420 × 210 mm`, file suffix `'Spread'`) and `AlbumPdfExporter.generatePhotobookFromStudioDocument(...)`.
  - Automatically delegates `generatePhotobookPdf` to `generatePhotobookFromStudioDocument` whenever `collection.studioLayoutJson` is populated.

### 3. Export Format Options & Preview Sheet (`lib/features/albums/widgets/album_pdf_preview_sheet.dart`)
- **[album_pdf_preview_sheet.dart](file:///home/harry1029/projects/memodiary/lib/features/albums/widgets/album_pdf_preview_sheet.dart)** & **[album_book_overview_screen.dart](file:///home/harry1029/projects/memodiary/lib/features/albums/screens/album_book_overview_screen.dart)**:
  - Added the 3rd format card (`Key('pdf_format_bound_spread')`, `'双页跨页装帧'`, `'420 × 210 mm · 对开跨页中缝阴影'`) alongside `A4 横版画册` and `方册画幅`.
  - Wired `AlbumBookOverviewScreen._handleContinueToExport` to pass `studioDocument: ctrl.document` and `photos: widget.photos` to `AlbumPdfPreviewSheet.show(...)`.

---

## Verification Summary

| Check | Command | Result |
| :--- | :--- | :--- |
| Static Analysis | `flutter analyze` | **0 issues found** |
| Offline CJK Font Unit Tests | `flutter test test/features/import_export/pdf_font_resolver_test.dart` | **4/4 passed** (verifies `/Subtype/Type0`, `/Encoding/Identity-H`, `/ToUnicode`, and zero `'?'` glyph fallbacks for `"深圳 · 江南春行纪"`, `"十月廿三"`, `"测试相册"`) |
| WYSIWYG Studio PDF Exporter Tests | `flutter test test/features/albums/album_pdf_exporter_test.dart` | **4/4 passed** (verifies 2/3/4-photo collage layouts, vector backgrounds, overlays, and `A4` / `Square` / `BoundSpread` formats) |
| Full Albums, Import/Export & Network Quarantine Suite | `flutter test test/features/albums test/features/import_export test/hardening/network_quarantine_audit_test.dart` | **127/127 passed** |
