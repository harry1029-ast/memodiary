import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_stroke_path.dart';

/// Distance from [point] to the segment [start]..[end].
double _distanceToSegment(Offset point, Offset start, Offset end) {
  final segment = end - start;
  final lengthSquared = segment.distanceSquared;
  if (lengthSquared == 0) return (point - start).distance;
  final t = (((point - start).dx * segment.dx + (point - start).dy * segment.dy) / lengthSquared).clamp(0.0, 1.0);
  return (point - (start + segment * t)).distance;
}

double _distanceToPolyline(Offset point, List<Offset> polyline) {
  var nearest = double.infinity;
  for (var index = 0; index < polyline.length - 1; index++) {
    nearest = math.min(nearest, _distanceToSegment(point, polyline[index], polyline[index + 1]));
  }
  return nearest;
}

void main() {
  group('centripetal Catmull-Rom smoothing', () {
    test('passes through every median point', () {
      const median = [Offset(10, 80), Offset(30, 40), Offset(55, 25), Offset(85, 30)];

      final smoothed = InkStrokeSmoothing.smooth(median);

      for (final vertex in median) {
        expect(smoothed.any((point) => (point - vertex).distance < 1e-6), isTrue, reason: '$vertex kept');
      }
      expect(smoothed.first, median.first);
      expect(smoothed.last, median.last);
      expect(smoothed.length, greaterThan(median.length));
    });

    test('rounds a coarse arc back towards the curve it was simplified from', () {
      // Four points on a radius-30 quarter circle around the origin.
      final arc = [
        for (final degrees in const [0.0, 30.0, 60.0, 90.0])
          Offset(30 * math.cos(degrees * math.pi / 180), 30 * math.sin(degrees * math.pi / 180)),
      ];

      final smoothed = InkStrokeSmoothing.smooth(arc);

      // The raw chords dip to radius 28.98 mid-segment; the smoothed curve stays near 30.
      for (final point in smoothed) {
        expect(point.distance, inInclusiveRange(29.6, 30.4));
      }
    });

    test('leaves a straight stroke straight', () {
      final smoothed = InkStrokeSmoothing.smooth(const [Offset(20, 50), Offset(45, 50), Offset(80, 50)]);

      for (final point in smoothed) {
        expect(point.dy, closeTo(50, 1e-9));
      }
    });

    test('keeps the sharp corners of a folded stroke such as E', () {
      const letterE = [Offset(72, 22), Offset(28, 22), Offset(28, 78), Offset(72, 78)];

      final smoothed = InkStrokeSmoothing.smooth(letterE);

      for (final point in smoothed) {
        expect(_distanceToPolyline(point, letterE), lessThan(1e-6), reason: '$point bulged off the fold');
      }
    });

    test('a hook keeps its corner while the curve leading into it is smoothed', () {
      // A gently curving vertical that ends in a sharp leftward hook.
      const hooked = [Offset(50, 10), Offset(58, 40), Offset(50, 80), Offset(40, 72)];

      final smoothed = InkStrokeSmoothing.smooth(hooked);

      expect(smoothed.any((point) => (point - const Offset(50, 80)).distance < 1e-6), isTrue);
      final afterCorner = smoothed.skipWhile((point) => point != const Offset(50, 80)).skip(1);
      for (final point in afterCorner) {
        expect(_distanceToSegment(point, const Offset(50, 80), const Offset(40, 72)), lessThan(1e-6));
      }
      expect(
        smoothed.any((point) => _distanceToPolyline(point, hooked) > 0.3),
        isTrue,
        reason: 'the gentle bend is rounded off its raw chords',
      );
    });

    test('degenerate medians are returned as they are', () {
      expect(InkStrokeSmoothing.smooth(const []), isEmpty);
      expect(InkStrokeSmoothing.smooth(const [Offset(5, 5)]), const [Offset(5, 5)]);
      expect(InkStrokeSmoothing.smooth(const [Offset(5, 5), Offset(9, 5)]), const [Offset(5, 5), Offset(9, 5)]);
    });
  });

  group('arc-length resampling', () {
    test('spaces points evenly along the stroke and keeps both ends', () {
      const uneven = [Offset(0, 0), Offset(1, 0), Offset(2, 0), Offset(30, 0), Offset(30, 10)];

      final resampled = InkStrokeSmoothing.resampleByArcLength(uneven, 4.0);

      expect(resampled.first, const Offset(0, 0));
      expect(resampled.last, const Offset(30, 10));
      expect(resampled.length, 11);
      // Walking the L-shaped stroke: every sample is 4 units of arc after the last.
      expect(resampled[5], offsetMoreOrLessEquals(const Offset(20, 0), epsilon: 1e-9));
      expect(resampled[8], offsetMoreOrLessEquals(const Offset(30, 2), epsilon: 1e-9));
      for (var index = 1; index < resampled.length; index++) {
        final step = resampled[index] - resampled[index - 1];
        expect(step.dx.abs() + step.dy.abs(), closeTo(4.0, 1e-9));
      }
    });

    test('a stroke shorter than the spacing keeps its two ends', () {
      final resampled = InkStrokeSmoothing.resampleByArcLength(const [Offset(0, 0), Offset(1, 0)], 4.0);

      expect(resampled, const [Offset(0, 0), Offset(1, 0)]);
    });
  });

  group('InkStrokePath', () {
    final stroke = InkStrokePath(const [Offset(0, 0), Offset(10, 0), Offset(10, 30)]);

    test('the tip moves at an even speed along the stroke, whatever the vertex spacing', () {
      expect(stroke.length, 40.0);
      expect(stroke.pointAt(0.0), const Offset(0, 0));
      expect(stroke.pointAt(0.25), offsetMoreOrLessEquals(const Offset(10, 0), epsilon: 1e-9));
      expect(stroke.pointAt(0.5), offsetMoreOrLessEquals(const Offset(10, 10), epsilon: 1e-9));
      expect(stroke.pointAt(1.0), const Offset(10, 30));
      expect(stroke.pointAt(1.7), const Offset(10, 30));
    });

    test('the revealed part ends exactly at the tip', () {
      final revealed = stroke.revealedUpTo(0.5);

      expect(revealed.length, 3);
      expect(revealed.sublist(0, 2), const [Offset(0, 0), Offset(10, 0)]);
      expect(revealed.last, offsetMoreOrLessEquals(const Offset(10, 10), epsilon: 1e-9));
      expect(stroke.revealedUpTo(1.0), stroke.points);
      expect(stroke.revealedUpTo(0.0), const [Offset(0, 0)]);
    });

    test('a single-point stroke is a dot', () {
      final dot = InkStrokePath(const [Offset(46, 51)]);

      expect(dot.length, 0.0);
      expect(dot.pointAt(0.6), const Offset(46, 51));
      expect(dot.revealedUpTo(0.6), const [Offset(46, 51)]);
    });
  });

  group('InkGlyphPlan', () {
    test('maps the 0..100 stroke box onto the glyph box', () {
      final plan = InkGlyphPlan.prepare(
        strokes: const [
          [Offset(0, 0), Offset(100, 100)],
        ],
        box: const Rect.fromLTWH(40, 90, 9, 20),
        isCjk: false,
      );

      expect(plan.strokes.single.start, const Offset(40, 90));
      expect(plan.strokes.single.end.dx, closeTo(49, 1e-9));
      expect(plan.strokes.single.end.dy, closeTo(110, 1e-9));
      expect(plan.inkUnit, closeTo(0.2, 1e-9), reason: 'ink widths follow the em height, not the advance');
    });

    test('keeps stroke order and drops empty strokes', () {
      final plan = InkGlyphPlan.prepare(
        strokes: const [
          [Offset(10, 20), Offset(90, 20)],
          [],
          [Offset(50, 10), Offset(50, 90)],
        ],
        box: const Rect.fromLTWH(0, 0, 100, 100),
        isCjk: true,
      );

      expect(plan.strokes.length, 2);
      expect(plan.strokes[0].start, const Offset(10, 20));
      expect(plan.strokes[1].start, const Offset(50, 10));
      expect(plan.isCjk, isTrue);
    });

    test('samples densely enough that a large glyph still draws smooth curves', () {
      final plan = InkGlyphPlan.prepare(
        strokes: const [
          [Offset(20, 20), Offset(50, 30), Offset(80, 60)],
        ],
        box: const Rect.fromLTWH(0, 0, 200, 200),
        isCjk: true,
      );

      final points = plan.strokes.single.points;
      for (var index = 1; index < points.length; index++) {
        expect((points[index] - points[index - 1]).distance, lessThan(5.0));
      }
    });

    test('the wet bleed copy wanders by at most 1.3dp and is the same on every build', () {
      List<InkStrokePath> build() => InkGlyphPlan.prepare(
            strokes: const [
              [Offset(10, 20), Offset(90, 20)],
              [Offset(50, 10), Offset(48, 50), Offset(50, 90)],
            ],
            box: const Rect.fromLTWH(12, 40, 60, 60),
            isCjk: true,
          ).strokes;

      final first = build();
      final second = build();
      var wandered = false;
      for (var strokeIndex = 0; strokeIndex < first.length; strokeIndex++) {
        final stroke = first[strokeIndex];
        expect(stroke.bleedPoints.length, stroke.points.length);
        for (var index = 0; index < stroke.points.length; index++) {
          final drift = (stroke.bleedPoints[index] - stroke.points[index]).distance;
          expect(drift, lessThanOrEqualTo(1.3 * math.sqrt2));
          if (drift > 0.05) wandered = true;
          expect(stroke.bleedPoints[index], second[strokeIndex].bleedPoints[index]);
        }
      }
      expect(wandered, isTrue);
    });
  });
}
