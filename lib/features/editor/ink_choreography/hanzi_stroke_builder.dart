// Pure-Dart compiler from *Make Me a Hanzi* `graphics.txt` to `MDST` bytes.
// No Flutter imports: it is shared by `tool/build_hanzi_strokes.dart` and tests.
import 'dart:math' as math;
import 'dart:typed_data';

import 'stroke_binary_format.dart';

const int _maxPointsPerStroke = 32;
const double _baseEpsilon = 1.0;

int _clamp100(num value) => value.round().clamp(0, 100).toInt();

/// Normalizes a 1024x1024 y-up median point (top at y = 900) into `0..100`
/// top-left space.
List<int> normalizeMedianPoint(num x, num y) => [
  _clamp100(x / 1024 * 100),
  _clamp100((900 - y) / 1024 * 100),
];

/// Ramer-Douglas-Peucker simplification keeping the endpoints.
List<List<int>> simplifyStroke(List<List<int>> points, double epsilon) {
  if (points.length < 3) return List.of(points);
  final keep = List<bool>.filled(points.length, false);
  keep[0] = keep[points.length - 1] = true;
  final pending = <(int, int)>[(0, points.length - 1)];
  while (pending.isNotEmpty) {
    final (first, last) = pending.removeLast();
    var farthest = -1.0;
    var farthestIndex = first;
    for (var at = first + 1; at < last; at++) {
      final distance = _distanceToSegment(points[at], points[first], points[last]);
      if (distance > farthest) {
        farthest = distance;
        farthestIndex = at;
      }
    }
    if (farthest > epsilon) {
      keep[farthestIndex] = true;
      pending
        ..add((first, farthestIndex))
        ..add((farthestIndex, last));
    }
  }
  return [
    for (var at = 0; at < points.length; at++)
      if (keep[at]) points[at],
  ];
}

double _distanceToSegment(List<int> point, List<int> start, List<int> end) {
  final dx = (end[0] - start[0]).toDouble();
  final dy = (end[1] - start[1]).toDouble();
  final lengthSquared = dx * dx + dy * dy;
  if (lengthSquared == 0) {
    return math.sqrt(
      math.pow(point[0] - start[0], 2) + math.pow(point[1] - start[1], 2),
    );
  }
  final t = (((point[0] - start[0]) * dx + (point[1] - start[1]) * dy) /
          lengthSquared)
      .clamp(0.0, 1.0);
  final px = start[0] + t * dx;
  final py = start[1] + t * dy;
  return math.sqrt(math.pow(point[0] - px, 2) + math.pow(point[1] - py, 2));
}

/// Normalizes, de-duplicates and simplifies one raw median to <= 32 points.
List<List<int>> processMedian(List<List<num>> median) {
  final normalized = <List<int>>[];
  for (final point in median) {
    final next = normalizeMedianPoint(point[0], point[1]);
    if (normalized.isNotEmpty &&
        normalized.last[0] == next[0] &&
        normalized.last[1] == next[1]) {
      continue;
    }
    normalized.add(next);
  }
  var epsilon = _baseEpsilon;
  var simplified = simplifyStroke(normalized, epsilon);
  while (simplified.length > _maxPointsPerStroke) {
    epsilon += 0.5;
    simplified = simplifyStroke(normalized, epsilon);
  }
  return simplified;
}

/// Compiles `graphics.txt` JSON lines plus the [curated] table into bytes.
/// Curated entries win over dataset entries. Multi-code-point and empty
/// entries are skipped.
Uint8List buildHanziStrokeTable({
  required Iterable<String> graphicsLines,
  required Map<String, StrokeSet> curated,
}) {
  final entries = <int, StrokeSet>{};
  for (final line in graphicsLines) {
    final parsed = parseGraphicsLine(line);
    if (parsed == null) continue;
    final runes = parsed.character.runes.toList();
    if (runes.length != 1 || parsed.medians.isEmpty) continue;
    final strokes = [
      for (final median in parsed.medians)
        if (median.isNotEmpty) processMedian(median),
    ];
    if (strokes.isEmpty || strokes.length > 255) continue;
    entries[runes.single] = strokes;
  }
  for (final entry in curated.entries) {
    entries[entry.key.runes.first] = entry.value;
  }
  return encodeStrokeTable(entries);
}
