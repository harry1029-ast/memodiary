import 'curated_lowercase_strokes.dart';
import 'curated_symbol_strokes.dart';
import 'curated_uppercase_strokes.dart';

/// Hand-curated stroke medians for the characters *Make Me a Hanzi* does not
/// cover: `A–Z`, `a–z`, `0–9` and `，。、·！？；：“”‘’.,!?-` (SPEC-020 §2).
///
/// Maps a character to its strokes in writing order. Each stroke is a
/// directional median polyline of `[x, y]` points in pen direction, authored
/// in the same `0..100` top-left box as the compiled Hanzi table: cap height
/// `y 16..84`, x-height top `y ≈ 42`, baseline `y = 84`, descenders to
/// `y ≈ 96`.
///
/// `tool/build_hanzi_strokes.dart` compiles this table into
/// `hanzi_strokes.bin`; `HanziStrokeTable` also reads it directly as the
/// synchronous fallback before the asset loads.
const Map<String, List<List<List<int>>>> curatedStrokes = {
  ...curatedUppercaseStrokes,
  ...curatedLowercaseStrokes,
  ...curatedSymbolStrokes,
};
