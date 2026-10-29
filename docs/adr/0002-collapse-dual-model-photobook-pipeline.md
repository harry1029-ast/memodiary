# Collapse Dual-Model Photobook Pipeline onto Canonical Studio Document

## Context
In Milestone 3.5, photobook generation introduced a rigid `AlbumSpread` hierarchy (`CoverSpread`, `SingleHeroSpread`, `DuoSpread`, `QuadSpread`, `EpilogueSpread`) with hardcoded layout partitions. Milestone 3.6 subsequently introduced `AlbumStudioDocument` and `AlbumPageModel` for DIY scrapbook editing, dynamic collage templates, and vector PDF rendering. 

Because the original `AlbumSpread` hierarchy was not retired, the system suffered from an architectural fracture:
- `AlbumFlipbookScreen` re-synthesized legacy `AlbumSpread`s on startup, discarding all user-customized page layouts, background colors, and stickers created in the Studio.
- `AlbumBookOverviewScreen` synthesized dummy `AlbumSpread` lists purely to satisfy `AlbumPdfPreviewSheet`'s required parameters.
- `AlbumPdfExporter` maintained over 500 lines of duplicate vector drawing and literati palette styling across dual generation pipelines.

## Decision
We collapse the photobook pipeline onto a single canonical document module: **`AlbumStudioDocument`**.

1. **Single Canonical Document at the Seam**: All album presentation and export modules (`AlbumBookOverviewScreen`, `AlbumFlipbookScreen`, `AlbumPdfPreviewSheet`, `AlbumPdfExporter`, `AlbumStudioPdfRenderer`) operate exclusively on `AlbumStudioDocument`.
2. **Retire `AlbumSpread`**: Delete `lib/features/albums/models/album_spread.dart`, `lib/features/albums/widgets/album_spread_card.dart`, and legacy spread branches in `AlbumPdfExporter`.
3. **Bookend Architecture**: `AlbumStudioDocument.pages` contains only user-editable content pages. Front Cover (page 1 / spread 0) and Epilogue Colophon (final spread) are dynamically rendered as bookends from `AlbumCollection` metadata across both `AlbumFlipbookScreen` and `AlbumStudioPdfRenderer`.
4. **WYSIWYG Flipbook Parity**: `AlbumFlipbookScreen` accepts `AlbumStudioDocument? document` (resolving from repository or `AlbumLayoutEngine.compileStudioDocument()`) and renders facing 2-page spreads via `BookSpreadTile`.
5. **Auto-Persistence**: `AlbumStudioController` provides an optional debounced persistence hook (`Future<void> Function(AlbumStudioDocument)? onPersist`), keeping state synchronized without caller orchestration.

## Consequences
- **Depth & Leverage**: Callers learn one small, unified document interface (`AlbumStudioDocument`) that powers the Editor, Overview Feed, Flipbook viewer, and PDF exporter.
- **Locality**: Eliminates ~1,200 lines of duplicate vector code, layout compilers, and test fixtures. Layout rules and bug fixes are concentrated in one place.
- **Full WYSIWYG Parity**: Changes made in the DIY Studio are instantly reflected when browsing in the Flipbook and exporting to PDF.

