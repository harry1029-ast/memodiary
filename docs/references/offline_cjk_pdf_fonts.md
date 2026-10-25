# Offline CJK TrueType Font Generation in package:pdf

## Problem & Constraint
MemoDiary enforces a **$0 Build & Runtime Cost** and **100% Offline-First** architecture. Exporting PDFs with Chinese, Japanese, or Korean (CJK) characters natively via `package:pdf` without dynamic network font downloads fails because the default Helvetica/Times fonts are Latin-1 only, outputting fallback question marks (`"???????"`).

## Architecture: OfflineCjkTtfGenerator
[`OfflineCjkTtfGenerator`](file:///home/harry1029/projects/memodiary/lib/features/import_export/services/offline_cjk_ttf_generator.dart) generates a minimal valid OpenType/TrueType `sfnt` binary dynamically in memory without external assets or network access.

### `package:pdf` TtfWriter Invariant
`package:pdf` parses embedded TrueType fonts using `TtfWriter.withChars(TtfParser font, List<int> chars)`.
Internally, `TtfWriter` performs character subsetting by mapping each Unicode character to its `glyphIndex` via `cmap` Format 4:
1. When generating the font subset, it iterates over character codes and removes emitted glyph IDs from an internal tracking map.
2. **Critical Gotcha**: If multiple characters share the same `glyphIndex` (e.g. mapping all non-Latin characters to a single generic box or space glyph ID `1`), the internal set mutates during iteration and throws:
   ```text
   Exception: Missing glyph for character 'X'
   ```

### Linear 1:1 `idDelta` CMap Mapping
To satisfy `TtfWriter`'s subsetter without network dependencies, `OfflineCjkTtfGenerator` defines 32,097 unique glyphs across contiguous Unicode ranges:
- Latin & Extensions: `0x0020..0x03FF`
- General Punctuation & Symbols: `0x2000..0x27BF`
- CJK Symbols, Kana, Ext A & Unified Ideographs: `0x3000..0x9FFF`
- CJK Compatibility & Fullwidth: `0xFE30..0xFFEF`

Each segment uses `idRangeOffset = 0` and computes a linear `idDelta = glyphIndex - startCode`, guaranteeing that **every single character has a unique glyph index** (`1..32096`), avoiding any glyph collision.

### Reference Files
- Generator: [`lib/features/import_export/services/offline_cjk_ttf_generator.dart`](file:///home/harry1029/projects/memodiary/lib/features/import_export/services/offline_cjk_ttf_generator.dart)
- Resolver: [`lib/features/import_export/services/pdf_font_resolver.dart`](file:///home/harry1029/projects/memodiary/lib/features/import_export/services/pdf_font_resolver.dart)
- Unit & Round-Trip Tests: [`test/features/import_export/pdf_font_resolver_test.dart`](file:///home/harry1029/projects/memodiary/test/features/import_export/pdf_font_resolver_test.dart)
