
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'character_strokes.dart';
import 'curated_strokes.dart';
import 'procedural_strokes.dart';
import 'stroke_binary_format.dart';

/// Offline stroke-median lookup (SPEC-020 §2, ADR-0011).
///
/// Lookup order: binary index (`O(log N)`), curated table, procedural
/// six-stroke sequence for `0x4E00..0x9FFF`, otherwise null. Usable
/// synchronously before [load] completes (curated + procedural only).
class HanziStrokeTable {
  HanziStrokeTable();

  /// App-wide shared table; `load()` it once at startup.
  static final HanziStrokeTable instance = HanziStrokeTable();

  static const String assetPath = 'assets/calligraphy/hanzi_strokes.bin';

  HanziStrokeBinary? _binary;
  bool _loadAttempted = false;
  bool _failureLogged = false;

  /// True once a valid binary table is serving lookups.
  bool get isLoaded => _binary != null;

  /// Reads the bundled asset once. On failure logs once and keeps the fallback.
  Future<void> load([AssetBundle? bundle]) async {
    if (_loadAttempted) return;
    _loadAttempted = true;
    try {
      final data = await (bundle ?? rootBundle).load(assetPath);
      loadFromBytes(data);
    } catch (error) {
      _logFailure(error);
    }
  }

  /// Validates and adopts [data]; returns false (and logs once) when invalid.
  bool loadFromBytes(ByteData data) {
    try {
      _binary = HanziStrokeBinary.parse(data);
      return true;
    } on FormatException catch (error) {
      _logFailure(error);
      return false;
    }
  }

  /// Strokes for [char] (exactly one code point), or null to not animate.
  CharacterStrokes? strokesFor(String char) {
    final runes = char.runes.toList(growable: false);
    if (runes.length != 1) return null;
    final codePoint = runes.single;

    final indexed = _binary?.lookup(codePoint);
    if (indexed != null) return _fromStrokeSet(indexed, codePoint, char);

    final curated = curatedStrokes[char];
    if (curated != null) return _fromStrokeSet(curated, codePoint, char);

    if (codePoint >= proceduralCjkStart && codePoint <= proceduralCjkEnd) {
      return proceduralCjkStrokes(codePoint);
    }
    return null;
  }

  CharacterStrokes _fromStrokeSet(StrokeSet set, int codePoint, String char) {
    return CharacterStrokes(
      isCjk: codePoint >= 0x2E80 && !curatedStrokes.containsKey(char),
      strokes: [
        for (final stroke in set)
          [for (final point in stroke) Offset(point[0] * 1.0, point[1] * 1.0)],
      ],
    );
  }

  void _logFailure(Object error) {
    if (_failureLogged) return;
    _failureLogged = true;
    debugPrint('HanziStrokeTable: using fallback strokes ($error)');
  }
}
