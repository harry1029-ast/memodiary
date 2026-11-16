import 'dart:ui';

/// Stroke polylines for one character in `0..100` top-left space.
class CharacterStrokes {
  const CharacterStrokes({required this.strokes, required this.isCjk});

  /// Ordered strokes, each an ordered polyline of points.
  final List<List<Offset>> strokes;

  /// True for ideographs (drives the 245 ms versus 205 ms stroke duration).
  final bool isCjk;
}
