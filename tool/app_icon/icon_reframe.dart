// Reframes the diarist's night-moon painting into the launcher icon master
// (SPEC-023 Implementation Decision 6, ADR 0014).
//
// The subject (moon, outlined ruyi clouds, open book) shrinks to
// [IconReframeSpec.scale] of its painted size, centred horizontally and lifted
// slightly, on a sky extended from the painting's own navy-to-slate gradient.
// The painting's borders feather into that sky so the edge wisps fade instead
// of ending in a hard seam. Pure Dart over RGBA bytes, so it is deterministic
// and needs no host imaging tools.
import 'dart:math' as math;
import 'dart:typed_data';

/// Framing parameters for [reframeIconMaster].
class IconReframeSpec {
  const IconReframeSpec({
    this.scale = 0.72,
    this.sourceAnchorY = 570,
    this.featherSourcePx = 80,
    this.skyStripSourcePx = 48,
    this.skyPercentile = 0.2,
    this.skySmoothingSigma = 16,
  });

  /// Size of the reframed painting relative to the canvas.
  final double scale;

  /// The source row placed on the canvas centre. The subject spans source rows
  /// ~135 (moon top) to ~910 (ribbon tip), centred near 522, so anchoring a
  /// lower row lifts the subject: (570 - 522) x 0.72 ≈ 35px on a 1024 canvas.
  final double sourceAnchorY;

  /// Width, in source pixels, of the fade from painting into extended sky.
  final double featherSourcePx;

  /// Width of the left and right source strips sampled for the sky gradient.
  final int skyStripSourcePx;

  /// Luminance percentile picked from each row's strip samples. A low value
  /// skips the pale smoke wisps that cross the painting's side edges.
  final double skyPercentile;

  /// Vertical Gaussian smoothing applied to the sampled sky gradient.
  final double skySmoothingSigma;
}

/// Returns the reframed master as opaque RGBA bytes of [canvasSize]².
///
/// [sourceRgba] is the painting as RGBA bytes, [sourceSize] pixels square.
Uint8List reframeIconMaster(
  Uint8List sourceRgba,
  int sourceSize, {
  int canvasSize = 1024,
  IconReframeSpec spec = const IconReframeSpec(),
}) {
  final sky = sampleSkyGradient(sourceRgba, sourceSize, spec);
  final pixelScale = spec.scale * canvasSize / sourceSize;
  final offsetX = (canvasSize - sourceSize * pixelScale) / 2;
  final offsetY = canvasSize / 2 - spec.sourceAnchorY * pixelScale;
  final columns = _areaWeights(canvasSize, sourceSize, pixelScale, offsetX);
  final rows = _areaWeights(canvasSize, sourceSize, pixelScale, offsetY);

  // Horizontal pass: every source row resampled to canvas columns.
  final horizontal = Float64List(canvasSize * sourceSize * 3);
  for (var sourceRow = 0; sourceRow < sourceSize; sourceRow++) {
    for (var column = 0; column < canvasSize; column++) {
      final weights = columns[column];
      var red = 0.0, green = 0.0, blue = 0.0;
      for (var at = 0; at < weights.indices.length; at++) {
        final source = (sourceRow * sourceSize + weights.indices[at]) * 4;
        final weight = weights.weights[at];
        red += sourceRgba[source] * weight;
        green += sourceRgba[source + 1] * weight;
        blue += sourceRgba[source + 2] * weight;
      }
      final target = (sourceRow * canvasSize + column) * 3;
      horizontal[target] = red;
      horizontal[target + 1] = green;
      horizontal[target + 2] = blue;
    }
  }

  final out = Uint8List(canvasSize * canvasSize * 4);
  for (var row = 0; row < canvasSize; row++) {
    final rowWeights = rows[row];
    final sourceY = (row + 0.5 - offsetY) / pixelScale;
    final skyColour = _skyAt(sky, sourceY);
    for (var column = 0; column < canvasSize; column++) {
      final columnWeights = columns[column];
      final sourceX = (column + 0.5 - offsetX) / pixelScale;
      final alpha = rowWeights.coverage *
          columnWeights.coverage *
          _feather(sourceX, sourceY, sourceSize.toDouble(), spec.featherSourcePx);
      final target = (row * canvasSize + column) * 4;
      for (var channel = 0; channel < 3; channel++) {
        var painted = 0.0;
        if (alpha > 0) {
          for (var at = 0; at < rowWeights.indices.length; at++) {
            painted +=
                horizontal[(rowWeights.indices[at] * canvasSize + column) * 3 + channel] * rowWeights.weights[at];
          }
          painted /= rowWeights.coverage * columnWeights.coverage;
        }
        final blended = skyColour[channel] * (1 - alpha) + painted * alpha;
        out[target + channel] = blended.round().clamp(0, 255);
      }
      out[target + 3] = 255;
    }
  }
  return out;
}

/// The painting's sky colour per source row, sampled from the left and right
/// edge strips at [IconReframeSpec.skyPercentile] luminance and smoothed.
List<Float64List> sampleSkyGradient(Uint8List sourceRgba, int sourceSize, IconReframeSpec spec) {
  final raw = List<Float64List>.generate(sourceSize, (sourceRow) {
    final samples = <int>[];
    for (var column = 0; column < spec.skyStripSourcePx; column++) {
      samples.add((sourceRow * sourceSize + column) * 4);
      samples.add((sourceRow * sourceSize + sourceSize - 1 - column) * 4);
    }
    double luminance(int offset) =>
        0.299 * sourceRgba[offset] + 0.587 * sourceRgba[offset + 1] + 0.114 * sourceRgba[offset + 2];
    samples.sort((first, second) => luminance(first).compareTo(luminance(second)));
    final picked = samples[(spec.skyPercentile * (samples.length - 1)).round()];
    return Float64List.fromList([
      sourceRgba[picked].toDouble(),
      sourceRgba[picked + 1].toDouble(),
      sourceRgba[picked + 2].toDouble(),
    ]);
  });

  final radius = (spec.skySmoothingSigma * 3).ceil();
  return List<Float64List>.generate(sourceSize, (sourceRow) {
    final smoothed = Float64List(3);
    var total = 0.0;
    for (var delta = -radius; delta <= radius; delta++) {
      final neighbour = (sourceRow + delta).clamp(0, sourceSize - 1);
      final weight = math.exp(-(delta * delta) / (2 * spec.skySmoothingSigma * spec.skySmoothingSigma));
      for (var channel = 0; channel < 3; channel++) {
        smoothed[channel] += raw[neighbour][channel] * weight;
      }
      total += weight;
    }
    for (var channel = 0; channel < 3; channel++) {
      smoothed[channel] /= total;
    }
    return smoothed;
  });
}

Float64List _skyAt(List<Float64List> sky, double sourceY) {
  final clamped = sourceY.clamp(0.0, sky.length - 1.0);
  final lower = clamped.floor();
  final upper = math.min(lower + 1, sky.length - 1);
  final fraction = clamped - lower;
  return Float64List.fromList([
    for (var channel = 0; channel < 3; channel++) sky[lower][channel] * (1 - fraction) + sky[upper][channel] * fraction,
  ]);
}

/// Smoothstep fade from 0 at the painting border to 1 at [width] inside it.
double _feather(double sourceX, double sourceY, double sourceSize, double width) {
  final inset = math.min(math.min(sourceX, sourceSize - sourceX), math.min(sourceY, sourceSize - sourceY));
  if (inset <= 0) return 0;
  if (inset >= width) return 1;
  final progress = inset / width;
  return progress * progress * (3 - 2 * progress);
}

class _AreaWeights {
  _AreaWeights(this.indices, this.weights, this.coverage);

  final List<int> indices;
  final List<double> weights;

  /// Fraction of the canvas pixel covered by the painting (0 outside it).
  final double coverage;
}

/// Box-filter weights mapping each canvas pixel's footprint onto source
/// pixels, for a painting drawn at [scale] starting at canvas [offset].
List<_AreaWeights> _areaWeights(int canvasCount, int sourceCount, double scale, double offset) {
  return List<_AreaWeights>.generate(canvasCount, (canvasIndex) {
    final start = (canvasIndex - offset) / scale;
    final end = (canvasIndex + 1 - offset) / scale;
    final indices = <int>[];
    final weights = <double>[];
    var covered = 0.0;
    for (var source = math.max(0, start.floor()); source < math.min(sourceCount, end.ceil()); source++) {
      final overlap = math.min(end, source + 1.0) - math.max(start, source.toDouble());
      if (overlap <= 0) continue;
      indices.add(source);
      weights.add(overlap * scale);
      covered += overlap * scale;
    }
    return _AreaWeights(indices, weights, covered);
  });
}
