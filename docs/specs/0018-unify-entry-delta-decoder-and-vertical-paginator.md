---
id: SPEC-018
title: "Unify the Keepsake Scroll View, Thread-Bound Folio & PDF Delta Decoder"
status: ready-for-agent
created_at: 2026-11-14
adr: ADR-0005, ADR-0006, ADR-0007
---

# Unify the Keepsake Scroll View, Thread-Bound Folio & PDF Delta Decoder

## Problem Statement

When a diarist previews or exports a diary entry across the **Keepsake Scroll View**, **Thread-Bound Folio**, and PDF exporters, four separate presentation modules independently decode Quill Delta JSON (`contentDelta` / `plainText` fallback), parse `{夹注:...}` **Interlinear Sub-Note** annotations, resolve inline media embeds, and pack right-to-left vertical columns:

1. **Dropped Trailing-Newline Headings, Blockquotes & Todo Lists**: In Quill Delta JSON, line-level block attributes (`header` 1–3, `blockquote`, `list`: `bullet` / `ordered` / `checked` / `unchecked`) attach to the terminating `\n` operation (`{"insert": "\n", "attributes": ...}`) rather than to the preceding text operation. `KeepsakeScrollView` checks `header` and `blockquote` on text operations, losing heading and quote column styling on standard Quill deltas; `FolioContentParser` checks `list` on text operations and ignores `header` and `blockquote`; `PdfVerticalScrollBuilder` ignores all block attributes; and `PdfEntrySerializer` ignores `list: 'checked'` and `'unchecked'`.
2. **Spurious Mid-Sentence Vertical Column Splits**: `KeepsakeScrollView` and `PdfVerticalScrollBuilder` tokenize and slice vertical columns per Quill `insert` operation instead of per paragraph, causing any bold, italic, or colored word inside a sentence to break into a new vertical column mid-sentence.
3. **Inconsistent `{夹注:...}` Interlinear Sub-Note Pairing**: `VerticalTypographyMapper` splits a sub-note of length $N$ at `(N + 1) ~/ 2` (classical right sub-column top-to-bottom first, then left sub-column top-to-bottom) and converts horizontal punctuation via `mapPunctuation`, whereas `FolioVerticalPaginator` manually chunks `isJiazhuNote` characters sequentially (`(0,1), (2,3)`) without punctuation mapping after `FolioContentParser` runs a duplicate `{夹注:...}` regular expression.
4. **Broken JSON `MediaEmbedData` Embeds in Folio & Horizontal PDF**: `FolioContentParser` and `PdfEntrySerializer` pass raw `insert['image'].toString()` and `insert['video'].toString()` values instead of normalizing through `MediaEmbedData.fromRaw(...)`, failing to resolve sandboxed files, captions, and aspect ratios whenever an inline embed stores JSON metadata (`{"path": "...", "caption": "...", "aspect": "4:3"}`).
5. **Sideways Cross-Feature Imports & Scattered Delta Decoders**: `timeline` and `import_export` reach sideways into `editor` for `VerticalTypographyMapper` and `MediaEmbedData`, while `StationeryDeltaSynthesizer` and `WeeklyDebriefDetailScreen` duplicate raw `jsonDecode` Delta extraction instead of sharing `decodeDeltaOps`.

## Solution

Establish one shared pure-Dart document decoding and vertical column packing seam in the core documents module (`core/documents`) serving all four presentation adapters and remaining Delta readers:

1. **Relocate & Unify Shared Document Primitives**: Move `VerticalTypographyMapper`, `MediaEmbedData`, and `decodeDeltaOps` into `core/documents` alongside a canonical `EntryContentDecoder` and vertical column packer, updating all callers directly with zero deprecated shims so features depend inward on core rather than sideways on `editor`.
2. **Canonical Block & Inline Run Decoding**: Decode bare op-lists (`[...]`), map envelopes (`{"ops": [...]}`), pre-decoded `ops`, or `plainText` fallback in one place; bind trailing-`\n` block attributes (`header` 1–3, `blockquote`, `bullet`, `ordered` with running 1-based ordinal, `checked`, `unchecked`) to the flushed paragraph block; parse `{夹注:...}` **Interlinear Sub-Note** runs once while preserving inline styles (`bold`, `italic`, `underline`, `strike`, hex `color`); normalize `image` and `video` embeds via `MediaEmbedData.fromRaw(...)`; ignore `{"mount": ...}` markers cleanly; and preserve blank paragraphs and leading text whitespace fidelity.
3. **Paragraph-Level Vertical Column Packing**: Tokenize and flatten all inline runs within each non-empty paragraph before slicing into `maxTokensPerColumn` columns via `VerticalTypographyMapper` (enforcing classical right-sub-column-first `{夹注:...}` pairing and vertical punctuation mapping across every vertical adapter), carrying column-level (`isTitle`, `isHeader`, `isQuote`) and token-level (`isTodo`, `isChecked`, `colorHex`) metadata while skipping whitespace-only paragraphs.
4. **Thin Presentation Adapters & `FolioMetadataFormatter`**:
   - Delete duplicate Delta, media, and `{夹注:...}` parsing from `FolioContentParser`, renaming its four remaining classical calendar/seal helpers cleanly to `FolioMetadataFormatter`.
   - Convert `FolioVerticalPaginator` into a slim 10-column Folio leaf slicer over the shared vertical packer and switch `FolioPaginationEngine`'s horizontal paginator onto the canonical decoded blocks.
   - Drive `KeepsakeScrollView` and `PdfVerticalScrollBuilder` directly from the shared vertical column packer (restoring trailing-`\n` heading/blockquote styling and fixing mid-sentence styled column splits).
   - Drive `PdfEntrySerializer` directly from `EntryContentDecoder` (fixing JSON-encoded media paths + captions, rendering `checked`/`unchecked` todo items, and formatting pre-parsed interlinear sub-notes inline as `〖...〗` without a second regex pass).
   - Route `StationeryDeltaSynthesizer` and `WeeklyDebriefDetailScreen` through `decodeDeltaOps`.

## User Stories

1. As a diarist previewing a formatted entry in **Keepsake Scroll View**, I want headings (`H1`–`H3`) and blockquotes saved by Quill with trailing-`\n` attributes to render with their distinct heading and quote calligraphy styling, so that vertical preview faithfully reflects my formatting.
2. As a diarist exporting a vertical scroll PDF of an entry containing headings and blockquotes, I want heading and quote columns to carry distinct heading and quote styling consistent with **Keepsake Scroll View**, so that exported keepsakes preserve document hierarchy.
3. As a diarist reading an entry with bold, italic, or colored words inside a sentence in **Keepsake Scroll View** or vertical scroll PDF, I want the sentence to flow continuously down the same column without breaking into a new column at every formatting change, so that columnar typography remains readable.
4. As a diarist reading an entry containing `{夹注:...}` **Interlinear Sub-Note** commentary in the vertical **Thread-Bound Folio**, I want dual sub-columns ordered top-to-bottom on the right sub-column first and then left sub-column with vertical CJK punctuation conversion, so that Folio typography matches **Keepsake Scroll View** and vertical PDF.
5. As a diarist reading an entry containing JSON-encoded inline photos or videos (`{"path": "...", "caption": "...", "aspect": "4:3"}`) in the **Thread-Bound Folio**, I want the **Tipped-In Ephemera Leaf** to receive the parsed relative sandbox path, caption, and aspect ratio, so that inline media renders properly instead of showing a missing file error.
6. As a diarist exporting a horizontal PDF for an entry with JSON-encoded inline photos or videos, I want `PdfEntrySerializer` to resolve the extracted sandbox relative path and optional caption (or poster thumbnail), so that the PDF never falls back to raw JSON error placeholders (`[Image: {"path":...}]`).
7. As a diarist exporting a horizontal PDF for an entry containing checked or unchecked todo list items, I want `[✓]` and `[ ]` todo rows to render clearly in the exported PDF, so that checklist entries are not flattened into plain paragraphs.
8. As a diarist writing entries with blank lines or classical CJK paragraph indentation (`　　`), I want horizontal **Thread-Bound Folio** and horizontal PDF views to preserve blank-line spacing and leading indentation while vertical scroll modes omit blank columns, so that each layout honors its medium's reading rules.
9. As a diarist opening a weekly debrief or reloading sheet deltas stored in either bare op-list (`[...]`) or map-enveloped (`{"ops": [...]}`) Quill JSON formats, I want `WeeklyDebriefDetailScreen` and `StationeryDeltaSynthesizer` to decode both formats and fall back cleanly to `plainText`, so that legacy and imported entries always open reliably.
10. As a developer working across editor, Folio, and PDF features, I want one pure-Dart decoding and vertical column packing module inside core with zero sideways `editor` imports or duplicate Delta/Jiazhu parsers, so that any formatting or embed evolution happens once in one place.

## Implementation Decisions

### 1. Canonical Core Document Interface (`core/documents`)
- **Module Relocation**: Move `decodeDeltaOps`, `MediaEmbedData` (`MediaAspectRatio`), and `VerticalTypographyMapper` (`VerticalRenderToken`, `VerticalGlyphToken`, `VerticalInterlinearPairToken`) into `core/documents`, removing the old feature-level originals and updating all imports across `editor`, `timeline`, `import_export`, and `weekly_review` directly (no `@deprecated` wrappers or compatibility barrel exports).
- **Entry Content Block IR (`EntryContentDecoder`)**:
  - Expose two symmetric entry points:
    - `decode({required String contentDeltaJson, required String fallbackPlainText}) -> List<EntryContentBlock>`
    - `decodeOps({required List<dynamic>? ops, required String fallbackPlainText}) -> List<EntryContentBlock>`
  - Block sealed hierarchy (`EntryContentBlock`):
    - `EntryTextBlock`: holds `EntryBlockKind` (`paragraph`, `header1`, `header2`, `header3`, `blockquote`, `bulletList`, `orderedList`, `checkedList`, `uncheckedList`), optional `int? orderedIndex` (1-based sequence reset whenever a non-ordered block intervenes), and `List<EntryInlineRun> runs` (empty `runs` preserves blank-line paragraph blocks; raw leading whitespace in text runs is preserved).
    - `EntryMediaBlock`: holds `EphemeraMediaType` or `isVideo` flag plus normalized `MediaEmbedData media` parsed via `MediaEmbedData.fromRaw(...)`.
  - Inline run model (`EntryInlineRun`): holds `String text`, `bool isInterlinearNote`, inline attributes (`bool isBold`, `isItalic`, `bool isUnderline`, `bool isStrike`, `String? colorHex`), preserving surrounding bold/italic/color metadata cleanly on text runs while splitting `{夹注:...}` spans into `isInterlinearNote: true` runs (retaining `{}` regex parsing in one single place).
  - Decoder rules:
    - Consume each Quill operation sequentially while accumulating `currentRuns` for the active line.
    - On inline `image` or `video` embeds: flush any pending `currentRuns` as a paragraph block, reset ordered-list counter, emit `EntryMediaBlock` with `MediaEmbedData.fromRaw(rawValue)`.
    - On `{"mount": ...}` markers (and non-text/non-media control embeds): ignore without flushing spurious blank media blocks.
    - On string inserts: normalize inline runs, split on `\n`, attach terminating `\n` op attributes (`header`: `1|2|3`, `blockquote: true`, `list`: `'bullet'|'ordered'|'checked'|'unchecked'`) to the flushed `EntryTextBlock`, and emit an empty-runs `EntryTextBlock` for consecutive blank lines (`\n\n`).
    - When ops are null/empty/malformed and `fallbackPlainText` has content: split lines on `\n`, retain leading whitespace (`trimRight()`), and decode `{夹注:...}` runs per line.

### 2. Unified Vertical Column Packer & Token Styling
- Provide a shared vertical column packing operation (on `core/documents`, e.g., `VerticalColumnPacker` or method on `VerticalTypographyMapper`) that accepts decoded `List<EntryContentBlock>`, `int maxTokensPerColumn`, and optional `String? entryTitle`:
  - Emit a single unsplit `VerticalTextColumn(tokens: ..., isTitle: true)` when `entryTitle` is non-empty (tokenized via `VerticalTypographyMapper.tokenize`).
  - Skip `EntryTextBlock` instances whose combined runs trim to empty so blank lines do not allocate empty ruled columns.
  - For each non-empty `EntryTextBlock`, map `header1`/`header2`/`header3` to `isHeader: true` and `blockquote` to `isQuote: true`; optionally synthesize/propagate `isTodo`, `isChecked`, and hex `colorHex` at cell granularity for adapters that render cell-level styling (e.g., **Thread-Bound Folio**).
  - For each run in `block.runs`:
    - If `run.isInterlinearNote`: invoke `VerticalTypographyMapper.tokenizeInterlinear(run.text)` so every vertical adapter shares the exact `(N + 1) ~/ 2` right-sub-column-first + `mapPunctuation` algorithm.
    - Else: invoke `VerticalTypographyMapper.tokenize(run.text)` (preserving raw cell glyphs and punctuation without breaking mid-sentence across runs of the same paragraph).
  - Flatten all tokens of a paragraph into one buffer (wrapping `\r` skip and `\n` explicit breaks if any remain), then chunk only when column token count hits `maxTokensPerColumn`.
  - Emit `VerticalMediaColumn(media: block.media, isVideo: block.isVideo)` on `EntryMediaBlock` after flushing any partial columns.
- Update `VerticalTypographyMapper` to expose `tokenizeInterlinear(String rawContent)` cleanly alongside `tokenize(String input)` and `formatInterlinearAsInline(String text)`, guaranteeing zero duplicate interlinear logic elsewhere.

### 3. Adapter Refactors & Remaining Delta Readers
- **`FolioMetadataFormatter` (replacing `FolioContentParser`)**:
  - Rename/scope the remaining calendar, reflection, and seal helpers (`formatFullLunarDate`, `formatGregorianDate`, `normalizeSealText`, `extractOpeningReflection`) into `FolioMetadataFormatter` and delete `FolioContentBlock`, `FolioTextBlock`, `FolioMediaBlock`, `parseContentBlocks`, and `splitJiazhuSegments`.
  - Update `FolioPaginationEngine` (and affected test references) to call `FolioMetadataFormatter` and decode blocks via `EntryContentDecoder`.
- **`FolioVerticalPaginator` & `FolioPaginationEngine`**:
  - Update `FolioVerticalPaginator` to pack decoded `EntryContentBlock`s via the shared vertical column packer (`maxTokensPerColumn: 16`, omitting `entryTitle` since cover carries title), group contiguous text columns into leaves of `kVerticalColumnsPerLeaf` (10), map cell attributes (`isTodo`, `isChecked`, `color`), and emit `FolioTippedInEphemeraLeaf` (carrying `caption` and parsed `MediaAspectRatio`) on `VerticalMediaColumn` breaks.
  - Update `FolioPaginationEngine`'s horizontal leaf paginator to consume `EntryTextBlock` (retaining leading indent and `list == 'checked'|'unchecked'` / `bold` / `italic` / `color` span metadata) and `EntryMediaBlock` (`MediaEmbedData.path`, `caption`, `MediaEmbedData.aspectRatio`).
- **`KeepsakeScrollView`**:
  - Replace local `jsonDecode` + `_partitionTokensIntoColumns` with the shared vertical column packer using its existing viewport height pitch calculation (`maxCharsPerCol`), preserving `isTitle`, `isHeader`, and `isQuote` on `KeepsakeColumn` and normalized `MediaEmbedData` on `KeepsakeMediaCard`.
- **`PdfVerticalScrollBuilder`**:
  - Replace `_parseEntryItems` manual JSON decode + `_partitionTokens` with the shared vertical column packer, propagating `isHeader` and `isQuote` visual styling onto `_PdfKeepsakeColumnItem` rendering while keeping terminal colophon and page-width slicing local to the PDF builder.
- **`PdfEntrySerializer`**:
  - Remove private Delta op parsing and delegate both `convertDeltaToWidgets` and `convertOpsToWidgets` to `EntryContentDecoder`, consuming `EntryTextBlock` and `EntryMediaBlock` directly.
  - Format interlinear sub-note runs inline as `〖...〗` (`VerticalTypographyMapper.formatInterlinearAsInline` behavior without re-scanning normal text with regex), render `checkedList` / `uncheckedList` blocks cleanly (e.g., checkbox indicator row), and resolve `MediaEmbedData.path` (plus non-empty `MediaEmbedData.caption` below image/video widgets) inside `_buildImageWidget` and `_buildVideoWidget`.
- **`StationeryDeltaSynthesizer` & `WeeklyDebriefDetailScreen`**:
  - Replace inline `jsonDecode` inside `StationeryDeltaSynthesizer.decode` and `WeeklyDebriefDetailScreen` with `decodeDeltaOps` + `plainText` fallback.

### 4. Static Architecture Guardrail
- Extend `test/hardening/code_style_audit_test.dart` to enforce:
  - No duplicate `{夹注:` regex definitions (`\{夹注:`) in `lib/` outside `lib/core/documents/`.
  - No direct `jsonDecode` of `contentDelta` outside `lib/core/documents/`.
  - All modified files comply with `< 450` LOC ceilings (significantly reducing `pdf_entry_serializer.dart`).

## Testing Decisions

### What Makes a Good Test
- **Test observable outputs at the seam, not private helper calls**: Assert returned structured blocks, inline runs, vertical column lists, rendered Folio leaves, widget properties, and PDF widget trees cleanly with zero dependency on private helper structures.
- **No unnecessary mocks**: The entire core decoder, vertical packer, Folio paginator, and PDF serializer run fast and deterministically in pure Dart / in-process memory (using a temporary sandbox directory only for PDF image transcoding tests).

### Modules & Seams to Be Tested
1. **Primary Core Seam (`lib/core/documents/`)**:
   - Comprehensive pure-Dart matrix covering:
     - `decodeDeltaOps` and `EntryContentDecoder` with list JSON, `{"ops": [...]}` maps, pre-decoded `ops`, malformed JSON, empty Delta, and `plainText` fallback.
     - Trailing-`\n` binding for `header` (`1`/`2`/`3`), `blockquote`, `bullet`, consecutive `ordered` indices resetting between non-ordered blocks, `checked`, and `unchecked`.
     - `MediaEmbedData.fromRaw(...)` normalization for raw string paths, JSON string embeds, map embeds (with caption & aspect), and silent ignoring of `{"mount": "<id>"}` markers.
     - `{夹注:...}` parsing fidelity: single-pass inline run splitting, right-sub-column-first `(N + 1) ~/ 2` vertical token ordering with CJK vertical punctuation mapping, and inline `〖...〗` text projection.
     - Mixed inline styles (`bold` + colored + plain + interlinear note) remaining in the same column chunk up to `maxTokensPerColumn`, alongside blank-line preservation in blocks vs omission in vertical columns.
2. **Existing Downstream Adapter Seams (Targeted Integration Regressions)**:
   - **`FolioPaginationEngine` & `FolioMetadataFormatter`** (`folio_pagination_engine_test.dart`, `folio_bug_diagnosis_test.dart`, `book_intro_screen_test.dart`): vertical Folio leaf jiazhu right-sub-column-first + punctuation parity, JSON inline `MediaEmbedData` populating `FolioTippedInEphemeraLeaf`, and `FolioMetadataFormatter` unit parity.
   - **`PdfEntrySerializer` & `PdfVerticalScrollBuilder`** (`pdf_entry_serializer_test.dart`, `pdf_export_engine_test.dart`): horizontal PDF resolving JSON-encoded image/video `MediaEmbedData` embeds + captions + `checked`/`unchecked` todos, and vertical scroll PDF preserving trailing-`\n` headings/quotes and unsplit styled sentences.
   - **`KeepsakeScrollView`** (`keepsake_scroll_view_test.dart`): trailing-`\n` headings and blockquotes rendering `KeepsakeColumn` with `isHeader: true` / `isQuote: true`, and bold/colored inline spans remaining in the same column.
3. **Static Audit Guardrail (`code_style_audit_test.dart`)**:
   - Single-owner invariant on `{夹注:` regex and `contentDelta` JSON decoding, plus `< 450` LOC enforcement.

### Prior Art
- `test/features/editor/services/vertical_typography_mapper_test.dart`
- `test/features/editor/widgets/keepsake_scroll_view_test.dart`
- `test/features/timeline/folio/folio_pagination_engine_test.dart`
- `test/features/import_export/pdf_entry_serializer_test.dart`
- `test/hardening/code_style_audit_test.dart`

## Out of Scope

- Changing live **QuillController** rich-text editing, cursor handling, or `EditorDeltaPartitioner` sheet splitting rules in the paginated entry editor.
- Modifying `FolioMediaPairing` sheet-mount marker resolution rules (ADR-0009).
- Altering SQLite schema, migrations, or Drift generated code.

## Further Notes

- Strengthens **ADR-0005** (Scholar Stationery Chest & Canvas), **ADR-0006** (Synchronized Paper Heart Geometry), and **ADR-0007** (Thread-Bound Folio Preview & Reading Perspective).
- Respects [CODING_STANDARDS.md](file:///home/harry1029/projects/memodiary/CODING_STANDARDS.md) `< 450` LOC ceiling; removing the duplicated Delta state machine from `PdfEntrySerializer` (currently 552 LOC on the grandfathered list) should bring `pdf_entry_serializer.dart` cleanly under 450 LOC so its grandfather exception can also be retired if below threshold.
