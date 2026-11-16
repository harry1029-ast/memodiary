import 'dart:math' as math;
import 'dart:ui';

import 'ink_bleed_noise.dart';
import 'ink_choreography_timeline.dart';

/// Turns coarse stroke medians into the smooth, evenly sampled curves the
/// brush tip travels (SPEC-020 §3).
abstract final class InkStrokeSmoothing {
  /// A median vertex turning more sharply than this is a fold or hook (折, 钩)
  /// and stays a crisp corner. Gentler turns are simplification artefacts of
  /// a curve and are rounded.
  static const double cornerAngleDegrees = 60.0;

  /// Centripetal Catmull–Rom through every point of [points], keeping sharp
  /// corners sharp.
  static List<Offset> smooth(List<Offset> points, {int subdivisions = 8}) {
    final runs = smoothRuns(points, subdivisions: subdivisions);
    return [
      for (var index = 0; index < runs.length; index++) ...(index == 0 ? runs[index] : runs[index].skip(1)),
    ];
  }

  /// [smooth], split at the sharp corners: each run ends on the corner the
  /// next one starts from.
  static List<List<Offset>> smoothRuns(List<Offset> points, {int subdivisions = 8}) {
    final vertices = _withoutRepeats(points);
    if (vertices.length < 3) return [vertices];

    final runs = <List<Offset>>[];
    var runStart = 0;
    for (var index = 1; index < vertices.length; index++) {
      final isLast = index == vertices.length - 1;
      if (!isLast && !_isCorner(vertices[index - 1], vertices[index], vertices[index + 1])) continue;
      runs.add(_smoothRun(vertices.sublist(runStart, index + 1), subdivisions));
      runStart = index;
    }
    return runs;
  }

  /// Re-samples [points] at even steps of at most [spacing] along its arc,
  /// keeping both ends.
  static List<Offset> resampleByArcLength(List<Offset> points, double spacing) {
    if (points.length < 2) return List.of(points);
    final path = InkStrokePath(points);
    if (path.length == 0) return [points.first];
    final segments = math.max(1, (path.length / spacing - 1e-9).ceil());
    return [
      points.first,
      for (var step = 1; step < segments; step++) path.pointAt(step / segments),
      points.last,
    ];
  }

  static List<Offset> _withoutRepeats(List<Offset> points) {
    final result = <Offset>[];
    for (final point in points) {
      if (result.isEmpty || (point - result.last).distanceSquared > 1e-12) result.add(point);
    }
    return result;
  }

  static bool _isCorner(Offset before, Offset vertex, Offset after) {
    final incoming = vertex - before;
    final outgoing = after - vertex;
    final turn = (outgoing.direction - incoming.direction).abs();
    final degrees = (turn > math.pi ? 2 * math.pi - turn : turn) * 180 / math.pi;
    return degrees > cornerAngleDegrees;
  }

  static List<Offset> _smoothRun(List<Offset> run, int subdivisions) {
    if (run.length < 3) return run;
    final last = run.length - 1;
    // Phantom end points continue the arc through the first/last three
    // points, so a curved stroke leaves and arrives along its own tangent.
    final lead = _mirrorAcrossBisector(run[2], run[0], run[1]);
    final trail = _mirrorAcrossBisector(run[last - 2], run[last], run[last - 1]);

    final result = <Offset>[run.first];
    for (var index = 0; index < last; index++) {
      final before = index == 0 ? lead : run[index - 1];
      final after = index + 2 > last ? trail : run[index + 2];
      for (var step = 1; step <= subdivisions; step++) {
        result.add(
          step == subdivisions
              ? run[index + 1]
              : _catmullRom(before, run[index], run[index + 1], after, step / subdivisions),
        );
      }
    }
    return result;
  }

  /// Mirrors [point] across the perpendicular bisector of [start]..[end].
  static Offset _mirrorAcrossBisector(Offset point, Offset start, Offset end) {
    final axis = end - start;
    final length = axis.distance;
    if (length == 0) return point;
    final unit = axis / length;
    final fromMiddle = point - (start + end) / 2;
    final along = fromMiddle.dx * unit.dx + fromMiddle.dy * unit.dy;
    return point - unit * (2 * along);
  }

  /// Centripetal (alpha = 0.5) Catmull–Rom between [p1] and [p2]
  /// (Barry–Goldman form).
  static Offset _catmullRom(Offset p0, Offset p1, Offset p2, Offset p3, double fraction) {
    double knot(Offset from, Offset to) => math.max(math.sqrt((to - from).distance), 1e-6);
    const t0 = 0.0;
    final t1 = t0 + knot(p0, p1);
    final t2 = t1 + knot(p1, p2);
    final t3 = t2 + knot(p2, p3);
    final t = t1 + (t2 - t1) * fraction;

    final a1 = p0 * ((t1 - t) / (t1 - t0)) + p1 * ((t - t0) / (t1 - t0));
    final a2 = p1 * ((t2 - t) / (t2 - t1)) + p2 * ((t - t1) / (t2 - t1));
    final a3 = p2 * ((t3 - t) / (t3 - t2)) + p3 * ((t - t2) / (t3 - t2));
    final b1 = a1 * ((t2 - t) / (t2 - t0)) + a2 * ((t - t0) / (t2 - t0));
    final b2 = a2 * ((t3 - t) / (t3 - t1)) + a3 * ((t - t1) / (t3 - t1));
    return b1 * ((t2 - t) / (t2 - t1)) + b2 * ((t - t1) / (t2 - t1));
  }
}

/// One prepared stroke: a dense polyline with its arc lengths, so progress
/// along it is distance, not vertex count.
class InkStrokePath {
  final List<Offset> points;

  /// [points] nudged by the wet-paper bleed noise: the stroke's soft,
  /// irregular under-layer. Same length as [points].
  final List<Offset> bleedPoints;

  final List<double> _cumulative;

  InkStrokePath(this.points, {List<Offset>? bleedPoints})
      : assert(points.isNotEmpty),
        assert(bleedPoints == null || bleedPoints.length == points.length),
        bleedPoints = bleedPoints ?? points,
        _cumulative = _measure(points);

  static List<double> _measure(List<Offset> points) {
    final cumulative = List<double>.filled(points.length, 0.0);
    for (var index = 1; index < points.length; index++) {
      cumulative[index] = cumulative[index - 1] + (points[index] - points[index - 1]).distance;
    }
    return cumulative;
  }

  double get length => _cumulative.last;
  Offset get start => points.first;
  Offset get end => points.last;

  /// The whole stroke and its bleed copy, built once for the settled layers.
  late final Path fullPath = polylinePath(points);
  late final Path fullBleedPath = polylinePath(bleedPoints);

  /// The point [fraction] (`0..1`) of the way along the stroke by arc length.
  Offset pointAt(double fraction) {
    final target = fraction.clamp(0.0, 1.0) * length;
    final index = _segmentAt(target);
    if (index >= points.length - 1) return points.last;
    return Offset.lerp(points[index], points[index + 1], _segmentFraction(index, target))!;
  }

  /// The part of the stroke already inked at [fraction], ending at the tip.
  List<Offset> revealedUpTo(double fraction) => _reveal(points, fraction);

  /// The matching part of the bleed copy.
  List<Offset> bleedRevealedUpTo(double fraction) => _reveal(bleedPoints, fraction);

  List<Offset> _reveal(List<Offset> source, double fraction) {
    if (fraction >= 1.0 || length == 0) return source;
    final target = fraction.clamp(0.0, 1.0) * length;
    final index = _segmentAt(target);
    final within = _segmentFraction(index, target);
    return [
      ...source.take(index + 1),
      if (within > 1e-9) Offset.lerp(source[index], source[index + 1], within)!,
    ];
  }

  /// The index of the last vertex at or before arc length [target].
  int _segmentAt(double target) {
    var low = 0;
    var high = points.length - 1;
    while (low < high) {
      final middle = (low + high + 1) >> 1;
      if (_cumulative[middle] <= target) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return low;
  }

  double _segmentFraction(int index, double target) {
    if (index >= points.length - 1) return 0.0;
    final span = _cumulative[index + 1] - _cumulative[index];
    return span == 0 ? 0.0 : (target - _cumulative[index]) / span;
  }

  static Path polylinePath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) path.lineTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }
}

/// A character's strokes laid out in its glyph box, ready to be written:
/// smoothed, evenly sampled, in stroke order. Built once per character.
class InkGlyphPlan {
  /// The rect the `0..100` stroke box was mapped onto.
  final Rect box;
  final bool isCjk;
  final List<InkStrokePath> strokes;

  InkGlyphPlan._(this.box, this.isCjk, this.strokes);

  /// One unit of the `0..100` stroke box in logical pixels. Ink widths are
  /// measured in it; it follows the em height, so a narrow Latin glyph keeps
  /// the same stroke weight as its neighbours.
  double get inkUnit => box.height / 100.0;

  /// [strokes] are plain `0..100` polylines in stroke order.
  factory InkGlyphPlan.prepare({
    required List<List<Offset>> strokes,
    required Rect box,
    required bool isCjk,
  }) {
    final inkUnit = box.height / 100.0;
    final spacing = (inkUnit * 2.0).clamp(0.75, 3.0);
    final prepared = <InkStrokePath>[];
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final mapped = [for (final point in stroke) InkChoreographyTimeline.mapToGlyphBox(point, box)];
      final runs = InkStrokeSmoothing.smoothRuns(mapped);
      final points = <Offset>[];
      for (final run in runs) {
        final resampled = InkStrokeSmoothing.resampleByArcLength(run, spacing);
        points.addAll(points.isEmpty ? resampled : resampled.skip(1));
      }
      prepared.add(
        InkStrokePath(
          points,
          bleedPoints: [for (final point in points) point + InkBleedNoise.displacement(point - box.topLeft)],
        ),
      );
    }
    return InkGlyphPlan._(box, isCjk, List.unmodifiable(prepared));
  }
}
