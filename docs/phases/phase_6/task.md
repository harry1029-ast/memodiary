# Phase 6 Task Checklist: High-Fidelity PDF Export Engine

- [x] **Step 1: Dependencies & Foundation**
  - [x] Add `pdf: ^3.11.1` and `printing: ^5.13.2` to `pubspec.yaml`.
  - [x] Run `flutter pub get` and verify dependency resolution.

- [x] **Step 2: WebP In-Memory Transcoder & Offline Font Resolver**
  - [x] Implement `ImageFormatTranscoder` in `lib/features/import_export/services/image_format_transcoder.dart`.
  - [x] Implement `PdfFontResolver` in `lib/features/import_export/services/pdf_font_resolver.dart`.
  - [x] Write unit tests in `test/features/import_export/image_format_transcoder_test.dart` and `test/features/import_export/pdf_font_resolver_test.dart`.

- [x] **Step 3: Procedural PDF Template Canvas Renderer**
  - [x] Implement `PdfTemplateRenderer` in `lib/features/import_export/services/pdf_template_renderer.dart`.
  - [x] Support Minimalist White, Lined Paper, Grid Paper, Retro Kraft, and custom template styles in PDF vector space.
  - [x] Write unit tests in `test/features/import_export/pdf_template_renderer_test.dart`.

- [x] **Step 4: Multi-Page Quill Delta to PDF Serializer**
  - [x] Implement `PdfEntrySerializer` in `lib/features/import_export/services/pdf_entry_serializer.dart`.
  - [x] Handle headers, styled spans, blockquotes, bullet/ordered lists, dividers, and sandboxed WebP photos.
  - [x] Write unit tests in `test/features/import_export/pdf_entry_serializer_test.dart`.

- [x] **Step 5: PDF Export Engine & Batch Consolidated Book Generator**
  - [x] Implement `PdfExportEngine` in `lib/features/import_export/services/pdf_export_engine.dart`.
  - [x] Implement single entry export and multi-entry consolidated book export with cover page.
  - [x] Write integration tests in `test/features/import_export/pdf_export_engine_test.dart`.

- [x] **Step 6: Network Quarantine Test Suite**
  - [x] Implement `test/features/import_export/pdf_network_quarantine_test.dart` asserting 0 network/socket calls during PDF generation.

- [x] **Step 7: UI Integration & Print Preview Screen**
  - [x] Implement `PdfPreviewScreen` in `lib/features/import_export/widgets/pdf_preview_screen.dart`.
  - [x] Update `ExportDialog` with PDF format option and routing.
  - [x] Update `EntryDetailScreen` with direct PDF export action.
  - [x] Write widget tests in `test/features/import_export/pdf_preview_screen_test.dart` with `net.nfet.printing` method channel mocking.

- [x] **Step 8: Static Analysis & Full Test Suite**
  - [x] Run `analyze_files` across the entire project (0 errors, 0 warnings).
  - [x] Run complete `flutter test` regression suite (134/134 tests passing).
