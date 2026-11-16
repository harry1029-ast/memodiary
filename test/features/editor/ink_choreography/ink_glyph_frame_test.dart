import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/ink_choreography/brush_kinematics.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_glyph_frame.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_glyph_performance.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_stroke_path.dart';

/// 十 in a 100dp box: a horizontal then a vertical, then a short dot.
InkGlyphPlan _threeStrokePlan() => InkGlyphPlan.prepare(
      strokes: const [
        [Offset(10, 50), Offset(90, 50)],
        [Offset(50, 10), Offset(50, 90)],
        [Offset(70, 70), Offset(80, 80)],
      ],
      box: const Rect.fromLTWH(0, 0, 100, 100),
      isCjk: true,
    );

const _stroke = Duration(milliseconds: 200);

void main() {
  group('InkGlyphTimeline.frameAt', () {
    final timeline = InkGlyphTimeline(plan: _threeStrokePlan(), strokeDuration: _stroke);

    test('opens with the tip on the first stroke and nothing inked', () {
      final frame = timeline.frameAt(Duration.zero);

      expect(frame.phase, InkGlyphPhase.writing);
      expect(frame.strokeIndex, 0);
      expect(frame.completedStrokes, 0);
      expect(frame.inkProgress, 0.0);
      expect(frame.tip, const Offset(10, 50));
      expect(frame.isPressing, isFalse, reason: 'the bristles have not landed yet');
      expect(frame.wetOpacity, 1.0);
    });

    test('mid-way through the second stroke the first is complete and the tip follows the cadence', () {
      final frame = timeline.frameAt(const Duration(milliseconds: 300));

      expect(frame.phase, InkGlyphPhase.writing);
      expect(frame.strokeIndex, 1);
      expect(frame.completedStrokes, 1);
      expect(frame.strokeProgress, closeTo(0.5, 1e-9));
      // Linear 0.5 lies in the travel phase: 0.16 + (0.3 / 0.65) * 0.70.
      expect(frame.inkProgress, closeTo(0.483077, 1e-6));
      expect(frame.tip.dx, closeTo(50, 1e-9));
      expect(frame.tip.dy, closeTo(10 + 80 * 0.483077, 1e-4));
      expect(frame.isPressing, isTrue);
    });

    test('a stroke hands over to the next exactly at its duration', () {
      final frame = timeline.frameAt(const Duration(milliseconds: 200));

      expect(frame.strokeIndex, 1);
      expect(frame.completedStrokes, 1);
      expect(frame.tip, const Offset(50, 10));
    });

    test('after the last stroke the character settles for 260ms and is then done', () {
      expect(timeline.writingDuration, const Duration(milliseconds: 600));
      expect(timeline.totalDuration, const Duration(milliseconds: 860));

      final settleStart = timeline.frameAt(const Duration(milliseconds: 600));
      expect(settleStart.phase, InkGlyphPhase.settling);
      expect(settleStart.completedStrokes, 3);
      expect(settleStart.settleProgress, 0.0);
      expect(settleStart.wetOpacity, 1.0);
      expect(settleStart.tip, offsetMoreOrLessEquals(const Offset(80, 80), epsilon: 1e-9));
      expect(settleStart.isPressing, isFalse);

      final halfSettled = timeline.frameAt(const Duration(milliseconds: 730));
      expect(halfSettled.phase, InkGlyphPhase.settling);
      expect(halfSettled.settleProgress, closeTo(0.5, 1e-9));
      expect(halfSettled.wetOpacity, inExclusiveRange(0.0, 1.0));

      final settled = timeline.frameAt(const Duration(milliseconds: 860));
      expect(settled.phase, InkGlyphPhase.settled);
      expect(settled.settleProgress, 1.0);
      expect(settled.wetOpacity, 0.0);
      expect(timeline.frameAt(const Duration(seconds: 5)).phase, InkGlyphPhase.settled);
    });

    test('the wet ink only ever fades while settling, with a brief print-press swell', () {
      var previous = 1.0;
      for (var millis = 600; millis <= 860; millis += 10) {
        final frame = timeline.frameAt(Duration(milliseconds: millis));
        expect(frame.wetOpacity, lessThanOrEqualTo(previous));
        previous = frame.wetOpacity;
      }
      expect(timeline.frameAt(const Duration(milliseconds: 300)).settleScale, 1.0);
      expect(timeline.frameAt(const Duration(milliseconds: 600)).settleScale, closeTo(1.08, 1e-9));
      expect(timeline.frameAt(const Duration(milliseconds: 860)).settleScale, closeTo(1.0, 1e-9));
      expect(timeline.frameAt(const Duration(milliseconds: 600)).settleBlurSigma, closeTo(0.8, 1e-9));
      expect(timeline.frameAt(const Duration(milliseconds: 860)).settleBlurSigma, closeTo(0.0, 1e-9));
    });

    test('the same elapsed time always gives the same frame', () {
      final first = timeline.frameAt(const Duration(milliseconds: 437));
      final second = timeline.frameAt(const Duration(milliseconds: 437));

      expect(first.tip, second.tip);
      expect(first.strokeIndex, second.strokeIndex);
      expect(first.inkProgress, second.inkProgress);
    });
  });

  group('InkGlyphPerformance', () {
    const frame60 = Duration(microseconds: 16667);

    InkGlyphPerformance perform() => InkGlyphPerformance(
          timeline: InkGlyphTimeline(plan: _threeStrokePlan(), strokeDuration: _stroke),
          lagFactor: 0.18,
        );

    test('reports each stroke start exactly once, for the brush sound', () {
      final performance = perform();
      var strokeStarts = 0;
      var ticks = 0;
      while (!performance.isSettled && ticks < 200) {
        if (performance.advance(frame60)) strokeStarts++;
        ticks++;
      }

      expect(strokeStarts, 3);
      expect(performance.isSettled, isTrue);
      expect(performance.elapsed, greaterThanOrEqualTo(const Duration(milliseconds: 860)));
    });

    test('lands the brush above-right of the first stroke and lets it chase the tip', () {
      final performance = perform();

      performance.advance(Duration.zero);
      expect(performance.brush.handle, const Offset(16, 34));

      for (var tick = 0; tick < 6; tick++) {
        performance.advance(frame60);
      }
      final pose = performance.pose(brushScale: 1.0)!;
      expect(pose.tip, performance.frame.tip);
      expect(pose.handle.dx, lessThan(pose.tip.dx + 4), reason: 'the handle lags behind a tip moving right');
      expect(pose.isPressing, isTrue);
    });

    test('its own brush is sized to the glyph, so brushes of neighbouring characters do not collide', () {
      final performance = InkGlyphPerformance(
        timeline: InkGlyphTimeline(
          plan: InkGlyphPlan.prepare(
            strokes: const [
              [Offset(0, 0), Offset(100, 100)],
            ],
            box: const Rect.fromLTWH(40, 90, 21, 21),
            isCjk: true,
          ),
          strokeDuration: _stroke,
        ),
        lagFactor: 0.18,
      );

      performance.advance(Duration.zero);

      // One brush unit is one stroke-box unit: 0.21dp for a 21dp glyph.
      expect(performance.brush.pxPerUnit, closeTo(0.21, 1e-9));
      expect(performance.brush.handle, offsetMoreOrLessEquals(const Offset(41.26, 86.64), epsilon: 1e-9));
      expect(performance.bristleStretch, closeTo(17.09, 0.01));
    });

    test('flicks the handle up when the tip jumps to the next stroke', () {
      final performance = perform();
      // Just before the first stroke ends...
      performance.advance(const Duration(milliseconds: 199));
      final before = performance.brush.handle;

      // ...a zero-lag-time tick crosses into the second stroke.
      performance.advance(const Duration(milliseconds: 1));
      performance.advance(Duration.zero);

      expect(performance.frame.strokeIndex, 1);
      expect(performance.brush.handle.dy, lessThan(before.dy - 3.5));
    });

    test('the brush is put down once the character starts to settle', () {
      final performance = perform();
      performance.advance(const Duration(milliseconds: 650));

      expect(performance.frame.phase, InkGlyphPhase.settling);
      expect(performance.pose(brushScale: 1.0), isNull);
      expect(performance.isSettled, isFalse);
    });

    test('a shared master brush carries on from where it already is', () {
      final master = BrushKinematics()..land(const Offset(200, 200));
      final performance = InkGlyphPerformance(
        timeline: InkGlyphTimeline(plan: _threeStrokePlan(), strokeDuration: _stroke),
        lagFactor: 0.18,
        brush: master,
      );

      performance.advance(Duration.zero);

      expect(master.handle, const Offset(206, 184), reason: 'not re-landed on the new character');
    });

    test('bristle stretch grows while the tip outruns the handle', () {
      final performance = perform();
      performance.advance(Duration.zero);
      final resting = performance.bristleStretch;

      for (var tick = 0; tick < 8; tick++) {
        performance.advance(frame60);
      }

      expect(resting, closeTo(17.09, 0.01), reason: 'landing offset (6, -16) in stroke-box units');
      expect(performance.bristleStretch, greaterThan(resting));
    });
  });
}
