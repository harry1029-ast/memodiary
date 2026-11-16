import 'dart:ui';

import 'character_strokes.dart';

/// Inclusive CJK Unified Ideographs block served by the procedural fallback.
const int proceduralCjkStart = 0x4E00;
const int proceduralCjkEnd = 0x9FFF;

double _clampCoord(num value) => value.clamp(0, 100).toDouble();

/// Deterministic six-stroke calligraphic sequence seeded by [codePoint], for
/// ideographs absent from the binary table.
CharacterStrokes proceduralCjkStrokes(int codePoint) {
  final shiftA = ((codePoint * 17) % 16) - 8;
  final shiftB = ((codePoint * 31) % 16) - 8;
  Offset point(num x, num y) => Offset(_clampCoord(x), _clampCoord(y));
  return CharacterStrokes(
    isCjk: true,
    strokes: [
      [point(24 + shiftA % 5, 20), point(50, 18), point(76 + shiftB % 5, 19)],
      [point(30 + shiftB % 4, 22), point(26, 52), point(18, 78)],
      [point(36, 38), point(72, 35), point(70, 60)],
      [point(36, 50), point(68, 48)],
      [point(52, 22), point(52, 82), point(42, 86)],
      [point(48, 54), point(66, 72), point(84, 84)],
    ],
  );
}
