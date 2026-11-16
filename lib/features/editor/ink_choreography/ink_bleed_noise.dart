import 'dart:ui';

/// The slow, deterministic wander of wet ink soaking into paper fibres
/// (水墨晕染): a smooth 2D noise field that nudges the soft under-layer of
/// each stroke by up to [maxDrift] logical pixels per axis.
///
/// Stands in for the prototype's `feTurbulence` + `feDisplacementMap` filter
/// (base frequency 0.048, 3 octaves, scale 2.6).
abstract final class InkBleedNoise {
  static const double maxDrift = 1.3;
  static const double _baseFrequency = 0.048;
  static const int _octaves = 3;

  /// The drift at [position], measured from the glyph box's top-left so a
  /// character bleeds the same way wherever it sits on the sheet.
  static Offset displacement(Offset position) => Offset(
        maxDrift * _fractal(position, 9),
        maxDrift * _fractal(position, 14),
      );

  static double _fractal(Offset position, int seed) {
    var total = 0.0;
    var amplitude = 1.0;
    var frequency = _baseFrequency;
    for (var octave = 0; octave < _octaves; octave++) {
      total += amplitude * _valueNoise(position.dx * frequency, position.dy * frequency, seed + octave * 31);
      amplitude /= 2;
      frequency *= 2;
    }
    // Three octaves sum to at most 1.75; typical fields stay well inside it.
    return (total / 1.4).clamp(-1.0, 1.0);
  }

  static double _valueNoise(double x, double y, int seed) {
    final cellX = x.floor();
    final cellY = y.floor();
    final blendX = _smooth(x - cellX);
    final blendY = _smooth(y - cellY);
    final top = _lerp(_lattice(cellX, cellY, seed), _lattice(cellX + 1, cellY, seed), blendX);
    final bottom = _lerp(_lattice(cellX, cellY + 1, seed), _lattice(cellX + 1, cellY + 1, seed), blendX);
    return _lerp(top, bottom, blendY);
  }

  static double _smooth(double t) => t * t * (3 - 2 * t);

  static double _lerp(double from, double to, double t) => from + (to - from) * t;

  /// A fixed pseudo-random value in `-1..1` for one lattice corner.
  static double _lattice(int x, int y, int seed) {
    var hash = (x * 374761393 + y * 668265263 + seed * 1274126177) & 0x7fffffff;
    hash = ((hash ^ (hash >> 13)) * 1274126177) & 0x7fffffff;
    hash ^= hash >> 16;
    return (hash & 0xffff) / 32767.5 - 1.0;
  }
}
