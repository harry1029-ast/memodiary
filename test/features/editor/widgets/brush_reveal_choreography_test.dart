import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/features/editor/widgets/brush_reveal/brush_reveal_choreography.dart';

Duration _ms(int milliseconds) => Duration(milliseconds: milliseconds);

void main() {
  group('BrushRevealTimeline', () {
    const photo = BrushRevealTimeline(isVideo: false);
    const video = BrushRevealTimeline(isVideo: true);

    test('paints five sweeps of 175ms each before the cover starts to fade', () {
      expect(photo.frameAt(Duration.zero).sweepsPainted, 0.0);
      expect(photo.frameAt(_ms(175)).sweepsPainted, closeTo(1.0, 1e-9));
      expect(photo.frameAt(_ms(350)).sweepsPainted, closeTo(2.0, 1e-9));
      expect(photo.frameAt(_ms(875)).sweepsPainted, closeTo(5.0, 1e-9));
      expect(photo.frameAt(_ms(800)).coverOpacity, 1.0);
      expect(photo.frameAt(_ms(800)).isBrushVisible, isTrue);
    });

    test('fades the cover over 550ms in monochrome ink wash, then blooms into full colour', () {
      final midFade = photo.frameAt(_ms(875 + 275));
      expect(midFade.coverOpacity, closeTo(0.5, 0.05));
      expect(midFade.colour, 0.0);
      expect(midFade.isBrushVisible, isFalse);

      final coverGone = photo.frameAt(_ms(875 + 550));
      expect(coverGone.coverOpacity, 0.0);
      expect(coverGone.colour, 0.0);

      final end = photo.frameAt(photo.total);
      expect(end.colour, 1.0);
      expect(end.isComplete, isTrue);
    });

    test('stamps the cinnabar seal on a video only, 260ms after its bloom', () {
      final bloomEnd = photo.total;
      expect(photo.frameAt(bloomEnd).sealProgress, 0.0);
      expect(video.frameAt(bloomEnd).sealProgress, 0.0);
      expect(video.frameAt(bloomEnd + _ms(259)).sealProgress, 0.0);
      expect(video.frameAt(bloomEnd + _ms(300)).sealProgress, greaterThan(0.0));
      expect(video.frameAt(video.total).sealProgress, 1.0);
      expect(video.total, greaterThan(bloomEnd + _ms(260)));
      expect(video.frameAt(bloomEnd).isComplete, isFalse);
    });
  });

  group('BrushRevealSweeps', () {
    test('lays five quadratic sweeps whose radii stay 22–28 on a 100px slot', () {
      final sweeps = BrushRevealSweeps.forSize(const Size(100, 100));
      expect(sweeps, hasLength(5));
      for (final sweep in sweeps) {
        expect(sweep.radius, inInclusiveRange(22.0, 28.0));
      }
    });

    test('scales radii with the slot', () {
      final small = BrushRevealSweeps.forSize(const Size(100, 100));
      final large = BrushRevealSweeps.forSize(const Size(200, 200));
      expect(large.first.radius, closeTo(small.first.radius * 2, 1e-9));
    });

    test('together the sweeps reach every corner of the slot', () {
      const size = Size(120, 90);
      final sweeps = BrushRevealSweeps.forSize(size);
      bool covered(Offset point) => sweeps.any((sweep) {
            for (var step = 0; step <= 40; step++) {
              if ((sweep.pointAt(step / 40) - point).distance <= sweep.radius) return true;
            }
            return false;
          });
      for (final corner in [Offset.zero, const Offset(120, 0), const Offset(0, 90), const Offset(120, 90)]) {
        expect(covered(corner), isTrue, reason: 'corner $corner');
      }
    });
  });

  group('BrushPose', () {
    test('trails the tip by the 0.24 lag and clamps tilt to ±28°', () {
      const fastSweep = BrushSweep(
        start: Offset(0, 50),
        control: Offset(500, 50),
        end: Offset(1000, 50),
        radius: 25,
      );
      final pose = BrushPose.at(fastSweep, 0.5);
      expect(pose.tip, fastSweep.pointAt(0.5));
      expect(pose.trail, fastSweep.pointAt(0.5 - BrushPose.kLag));
      expect(pose.tilt.abs(), lessThanOrEqualTo(28 * math.pi / 180 + 1e-9));
      expect(pose.tilt.abs(), closeTo(28 * math.pi / 180, 1e-9));
    });

    test('leans against the direction of travel', () {
      const rightward = BrushSweep(start: Offset(0, 0), control: Offset(50, 0), end: Offset(100, 0), radius: 25);
      const leftward = BrushSweep(start: Offset(100, 0), control: Offset(50, 0), end: Offset(0, 0), radius: 25);
      expect(BrushPose.at(rightward, 0.6).tilt.sign, -BrushPose.at(leftward, 0.6).tilt.sign);
    });
  });
}
