# Milestone 3.6 — Task Checklist

## Phase 14: Studio Models & Collage Layout Library (Completed)
- [x] Task 14.1: Drift Schema v4 Migration & Studio Data Models
- [x] Task 14.2: Multi-Photo Collage Layout Catalog & Multi-Photo Auto-Packing
- [x] Task 14.3: Themes & Style Catalog + Procedural Background & Sticker Painters
- [x] Task 14.4: AlbumStudioController with 50-Step Undo/Redo Stack
- [x] Task 14.5: Code Review Fixes (Standards & Spec Refinement)
- [x] Task 14.6: Automated Unit Tests, Regression Suite & Static Analysis (64/64 passed)

---

## Phase 15: Book Overview Spread Feed & Interactive Drag-and-Drop Page Editor UI (Completed)
- [x] Task 15.1: Shared WYSIWYG Page Canvas & Interactive Components (`lib/features/albums/widgets/interactive_canvas/`)
- [x] Task 15.2: Book Overview Spread Feed Screen (`lib/features/albums/screens/album_book_overview_screen.dart` & `widgets/book_spread_tile.dart`)
- [x] Task 15.3: Interactive Single-Page Canvas Editor Screen (`lib/features/albums/screens/album_page_editor_screen.dart`)
- [x] Task 15.4: Studio Bottom Drawers & Themes Sheet (`lib/features/albums/widgets/studio_drawers/`)
- [x] Task 15.5: Entry Point & Navigation Integration (`AlbumWorkspaceScreen`)
- [x] Task 15.6: Automated Verification & Hardening (65/65 passed, 0 analyzer issues)

---

## Phase 16: WYSIWYG Vector PDF Photobook Renderer, Offline CJK Font Fix & Hardening (Completed)
- [x] **Task 16.1: Offline CJK Font Resolution Fix** (`lib/features/import_export/services/`)
  - [x] Create `offline_cjk_ttf_generator.dart` to provide a deterministic, zero-network TrueType (`sfnt`) CJK font binary for `pw.Font.ttf(...)` (checking `rootBundle` first and strictly enforcing OpenType table checksums/headers).
  - [x] Add `PdfFontResolver.cjk()` in `pdf_font_resolver.dart` and make it the default in `AlbumPdfExporter` and `PdfExportEngine`.
  - [x] Add unit tests in `test/features/import_export/pdf_font_resolver_test.dart` asserting `"深圳 · 江南春行纪"`, `"十月廿三"`, and `"测试相册"` render into PDF bytes with zero `'?'` fallbacks.
- [x] **Task 16.2: WYSIWYG Studio Vector PDF Renderer & Memory Guard** (`lib/features/albums/services/`)
  - [x] Update `ImageFormatTranscoder` to clamp image dimensions to 1400px and dispose native `ui.Image` handles immediately.
  - [x] Create `pdf_vector_graphics_painter.dart` for vector PDF rendering of the 9 background graphic motifs and vector stickers/seals/date pills.
  - [x] Create `album_studio_pdf_renderer.dart` to compile `AlbumStudioDocument` (normalized `0.0..1.0` photo slots, single-page overflow protection with `pw.TextOverflow.clip` and `maxLines: 2`, sorted overlays, and 2-Page Bound Spreads partitioned cleanly at $x = 0.5 \times W$ with a centered $0.03 \times W$ spine crease).
  - [x] Update `album_pdf_exporter.dart` with `AlbumPdfPageFormat.boundSpread` and `generatePhotobookFromStudioDocument(...)`.
- [x] **Task 16.3: Export Format Options & Preview Sheet** (`lib/features/albums/widgets/album_pdf_preview_sheet.dart`)
  - [x] Support all 3 export formats (`A4 Landscape`, `Square Keepsake`, `2-Page Bound Spreads`).
  - [x] Wire `AlbumBookOverviewScreen` (`_handleContinueToExport`) to pass `studioDocument` and `photos` into `AlbumPdfPreviewSheet`.
- [x] **Task 16.4: Hardening & Full Verification Suite**
  - [x] Expand `test/features/albums/album_pdf_exporter_test.dart` to verify multi-photo collage layouts (2, 3, 4 photos), CJK text rendering, vector backgrounds/overlays, and 2-Page Bound Spread export.
  - [x] Run `flutter analyze` (0 issues) and full project regression & network quarantine test suite (117/117 passed).
