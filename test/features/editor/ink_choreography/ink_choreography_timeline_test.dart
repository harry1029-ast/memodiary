import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_choreography_timeline.dart';

void main() {
  group('dynamic cursive catch-up', () {
    test('steps up at 1, 3 and 6 waiting characters', () {
      expect(InkChoreographyTimeline.catchupMult(0), 1.0);
      expect(InkChoreographyTimeline.catchupMult(1), 1.35);
      expect(InkChoreographyTimeline.catchupMult(2), 1.35);
      expect(InkChoreographyTimeline.catchupMult(3), 1.9);
      expect(InkChoreographyTimeline.catchupMult(5), 1.9);
      expect(InkChoreographyTimeline.catchupMult(6), 2.6);
      expect(InkChoreographyTimeline.catchupMult(240), 2.6);
    });
  });

  group('three-phase stroke cadence', () {
    test('runs from 0 to 1 through the entry, travel and exit phases', () {
      expect(InkChoreographyTimeline.easedProgress(0.0), 0.0);
      expect(InkChoreographyTimeline.easedProgress(0.10), closeTo(0.08, 1e-9));
      expect(InkChoreographyTimeline.easedProgress(0.525), closeTo(0.51, 1e-9));
      expect(InkChoreographyTimeline.easedProgress(0.925), closeTo(0.93, 1e-9));
      expect(InkChoreographyTimeline.easedProgress(1.0), closeTo(1.0, 1e-9));
    });

    test('is continuous where the entry press hands over to the travel at 0.20', () {
      const epsilon = 1e-6;
      expect(InkChoreographyTimeline.easedProgress(0.20), closeTo(0.16, 1e-9));
      expect(
        InkChoreographyTimeline.easedProgress(0.20 + epsilon) - InkChoreographyTimeline.easedProgress(0.20 - epsilon),
        closeTo(0.0, 1e-5),
      );
    });

    test('is continuous where the travel hands over to the exit dwell at 0.85', () {
      const epsilon = 1e-6;
      expect(InkChoreographyTimeline.easedProgress(0.85), closeTo(0.86, 1e-9));
      expect(
        InkChoreographyTimeline.easedProgress(0.85 + epsilon) - InkChoreographyTimeline.easedProgress(0.85 - epsilon),
        closeTo(0.0, 1e-5),
      );
    });

    test('never runs backwards and clamps outside 0..1', () {
      var previous = -1.0;
      for (var step = 0; step <= 200; step++) {
        final eased = InkChoreographyTimeline.easedProgress(step / 200);
        expect(eased, greaterThanOrEqualTo(previous));
        previous = eased;
      }
      expect(InkChoreographyTimeline.easedProgress(-0.5), 0.0);
      expect(InkChoreographyTimeline.easedProgress(1.5), closeTo(1.0, 1e-9));
    });

    test('the brush presses between 2% and 96% of a stroke', () {
      expect(InkChoreographyTimeline.isPressing(0.0), isFalse);
      expect(InkChoreographyTimeline.isPressing(0.02), isFalse);
      expect(InkChoreographyTimeline.isPressing(0.5), isTrue);
      expect(InkChoreographyTimeline.isPressing(0.96), isFalse);
      expect(InkChoreographyTimeline.isPressing(1.0), isFalse);
    });
  });

  group('durations', () {
    test('a CJK stroke takes 245ms and a Latin stroke 205ms at standard cadence', () {
      expect(
        InkChoreographyTimeline.strokeDuration(isCjk: true, speedMultiplier: 1.0),
        const Duration(milliseconds: 245),
      );
      expect(
        InkChoreographyTimeline.strokeDuration(isCjk: false, speedMultiplier: 1.0),
        const Duration(milliseconds: 205),
      );
    });

    test('cadence, catch-up and replay boost all shorten a stroke', () {
      expect(
        InkChoreographyTimeline.strokeDuration(isCjk: true, speedMultiplier: 0.55).inMicroseconds,
        closeTo(445455, 1),
      );
      expect(
        InkChoreographyTimeline.strokeDuration(
          isCjk: true,
          speedMultiplier: 1.8,
          catchupMult: 2.6,
          replayBoost: InkChoreographyTimeline.replayBoost,
        ).inMicroseconds,
        closeTo(32719, 1),
      );
      expect(InkChoreographyTimeline.replayBoost, 1.6);
    });

    test('the transit between characters takes 135ms, shortened by the same multipliers', () {
      expect(
        InkChoreographyTimeline.transitDuration(speedMultiplier: 1.0),
        const Duration(milliseconds: 135),
      );
      expect(
        InkChoreographyTimeline.transitDuration(speedMultiplier: 1.0, catchupMult: 1.35),
        const Duration(milliseconds: 100),
      );
      expect(
        InkChoreographyTimeline.transitDuration(speedMultiplier: 0.55),
        const Duration(milliseconds: 245),
      );
    });

    test('the transit never drops below 38ms', () {
      expect(
        InkChoreographyTimeline.transitDuration(speedMultiplier: 1.8, catchupMult: 2.6, replayBoost: 1.6),
        const Duration(milliseconds: 38),
      );
    });

    test('a finished character settles over 260ms', () {
      expect(InkChoreographyTimeline.settleDuration, const Duration(milliseconds: 260));
    });
  });

  group('Airborne Silk Trace', () {
    test('is drawn only for transits of 6..180dp', () {
      expect(InkChoreographyTimeline.showsSilkTrace(5.9), isFalse);
      expect(InkChoreographyTimeline.showsSilkTrace(6.0), isTrue);
      expect(InkChoreographyTimeline.showsSilkTrace(90.0), isTrue);
      expect(InkChoreographyTimeline.showsSilkTrace(180.0), isTrue);
      expect(InkChoreographyTimeline.showsSilkTrace(180.1), isFalse);
    });

    test('the transit starts and ends on the paper at its two characters', () {
      final transit = InkTransit(from: const Offset(20, 100), to: const Offset(120, 100));

      final start = transit.frameAt(0.0);
      final end = transit.frameAt(1.0);

      expect(start.tip, const Offset(20, 100));
      expect(start.liftHeight, closeTo(0.0, 1e-9));
      expect(end.tip.dx, closeTo(120, 1e-9));
      expect(end.tip.dy, closeTo(100, 1e-9));
      expect(end.liftHeight, closeTo(0.0, 1e-9));
    });

    test('the tip arcs over a parabola whose apex rises 22% of the distance, between 8 and 28dp', () {
      // 100dp apart: control point lifted 22dp, so the curve's midpoint rises 11dp.
      final transit = InkTransit(from: const Offset(20, 100), to: const Offset(120, 100));
      final middle = transit.frameAt(0.5);
      expect(transit.distance, 100.0);
      expect(transit.control, const Offset(70, 78));
      expect(middle.tip.dx, closeTo(70, 1e-9));
      expect(middle.tip.dy, closeTo(89, 1e-9));

      expect(InkTransit(from: Offset.zero, to: const Offset(10, 0)).control, const Offset(5, -8));
      expect(InkTransit(from: Offset.zero, to: const Offset(400, 0)).control, const Offset(200, -28));
    });

    test('the brush lifts most at mid-transit: 14% of the distance, between 5 and 14dp', () {
      expect(InkTransit(from: Offset.zero, to: const Offset(50, 0)).frameAt(0.5).liftHeight, closeTo(7.0, 1e-9));
      expect(InkTransit(from: Offset.zero, to: const Offset(10, 0)).frameAt(0.5).liftHeight, closeTo(5.0, 1e-9));
      expect(InkTransit(from: Offset.zero, to: const Offset(400, 0)).frameAt(0.5).liftHeight, closeTo(14.0, 1e-9));
    });

    test('the transit eases in and out', () {
      final transit = InkTransit(from: Offset.zero, to: const Offset(100, 0));
      expect(transit.frameAt(0.25).tip.dx, lessThan(25));
      expect(transit.frameAt(0.75).tip.dx, greaterThan(75));
    });
  });

  group('two-body kinematic lag', () {
    const frame60 = Duration(microseconds: 16667);

    test('one 60 Hz step closes exactly lagFactor of the gap', () {
      for (final lagFactor in const [0.28, 0.18, 0.11]) {
        expect(InkChoreographyTimeline.lagAlpha(lagFactor, frame60), closeTo(lagFactor, 1e-5));

        // Target handle sits at tip + (4, -15): start 100 to its left.
        final handle = InkChoreographyTimeline.followHandle(
          handle: const Offset(-96, -15),
          tip: Offset.zero,
          lagFactor: lagFactor,
          dt: frame60,
        );
        expect(handle.dx, closeTo(-96 + 100 * lagFactor, 1e-3));
        expect(handle.dy, closeTo(-15, 1e-9));
      }
    });

    test('the handle after 1/6 s agrees at 30, 60 and 120 Hz', () {
      Offset settleAt(int hertz) {
        var handle = const Offset(-60, 40);
        final dt = Duration(microseconds: (1000000 / hertz).round());
        for (var step = 0; step < hertz ~/ 6; step++) {
          handle = InkChoreographyTimeline.followHandle(
            handle: handle,
            tip: const Offset(30, 20),
            lagFactor: 0.18,
            dt: dt,
          );
        }
        return handle;
      }

      final at60 = settleAt(60);
      // 10 steps at 60 Hz leave 0.82^10 of the 94 x -35 gap to the target (34, 5).
      expect(at60.dx, closeTo(34 - 94 * 0.13744803, 0.01));
      expect(at60.dy, closeTo(5 + 35 * 0.13744803, 0.01));
      expect((settleAt(30) - at60).distance, lessThan(0.5));
      expect((settleAt(120) - at60).distance, lessThan(0.5));
    });

    test('the handle chasing a gliding tip stays within half a unit across frame rates', () {
      Offset glideAt(int hertz) {
        var handle = const Offset(4, -15);
        final dt = Duration(microseconds: (1000000 / hertz).round());
        final steps = hertz ~/ 6;
        for (var step = 1; step <= steps; step++) {
          handle = InkChoreographyTimeline.followHandle(
            handle: handle,
            tip: Offset(5.0 * step / steps, 0),
            lagFactor: 0.18,
            dt: dt,
          );
        }
        return handle;
      }

      expect((glideAt(30) - glideAt(60)).distance, lessThan(0.5));
      expect((glideAt(120) - glideAt(60)).distance, lessThan(0.5));
    });

    test('a lifted brush aims its handle higher by the lift height', () {
      final handle = InkChoreographyTimeline.followHandle(
        handle: const Offset(4, -15),
        tip: Offset.zero,
        lagFactor: 0.18,
        dt: frame60,
        liftHeight: 10,
      );
      expect(handle.dx, closeTo(4, 1e-9));
      expect(handle.dy, closeTo(-15 - 10 * 0.18, 1e-3));
    });
  });

  group('shaft angle', () {
    test('rests at 22 degrees over a settled handle', () {
      // dx = -4, dy = 15: tilt = 2.2 - 0.16 = 2.04.
      expect(InkChoreographyTimeline.dragTilt(const Offset(-4, 15)), closeTo(2.04, 1e-9));
      expect(InkChoreographyTimeline.shaftAngle(const Offset(-4, 15)), closeTo(24.04, 1e-9));
    });

    test('drag tilt clamps to 22 degrees either way', () {
      expect(InkChoreographyTimeline.dragTilt(const Offset(-500, 16)), 22.0);
      expect(InkChoreographyTimeline.dragTilt(const Offset(500, 16)), -22.0);
      expect(InkChoreographyTimeline.shaftAngle(const Offset(-500, 16)), 44.0);
      expect(InkChoreographyTimeline.shaftAngle(const Offset(500, 16)), 0.0);
    });
  });

  group('bristle bulge', () {
    test('grows with bristle stretch at 0.42 while pressing', () {
      expect(
        InkChoreographyTimeline.bristleBulge(localDistance: 10, isPressing: true, brushScale: 1.0),
        closeTo(4.2, 1e-9),
      );
    });

    test('relaxes to 28% of that when lifted', () {
      expect(
        InkChoreographyTimeline.bristleBulge(localDistance: 10, isPressing: false, brushScale: 1.0),
        closeTo(1.176, 1e-9),
      );
    });

    test('never exceeds 16 x brushScale', () {
      expect(InkChoreographyTimeline.bristleBulge(localDistance: 900, isPressing: true, brushScale: 1.0), 16.0);
      expect(
        InkChoreographyTimeline.bristleBulge(localDistance: 900, isPressing: true, brushScale: 0.68),
        closeTo(10.88, 1e-9),
      );
      expect(InkChoreographyTimeline.bristleBulge(localDistance: 0, isPressing: true, brushScale: 1.0), 0.0);
    });

    test('the brush is scaled from the font size, between 0.68 and 1.08', () {
      expect(InkChoreographyTimeline.brushScaleFor(22), closeTo(1.0, 1e-9));
      expect(InkChoreographyTimeline.brushScaleFor(10), 0.68);
      expect(InkChoreographyTimeline.brushScaleFor(40), 1.08);
    });

    test('a character\'s own brush is scaled a little smaller, between 0.55 and 0.95', () {
      expect(InkChoreographyTimeline.localBrushScaleFor(21), closeTo(0.875, 1e-9));
      expect(InkChoreographyTimeline.localBrushScaleFor(10), 0.55);
      expect(InkChoreographyTimeline.localBrushScaleFor(40), 0.95);
    });
  });

  group('glyph-box mapping', () {
    test('a CJK glyph gets a square em box centred on its text line', () {
      final box = InkChoreographyTimeline.glyphBox(left: 40, advance: 20, lineCenterY: 100, emSize: 20);

      expect(box, const Rect.fromLTWH(40, 90, 20, 20));
      expect(box.width, box.height);
    });

    test('a narrow Latin glyph is scaled horizontally to its advance', () {
      final box = InkChoreographyTimeline.glyphBox(left: 40, advance: 9, lineCenterY: 100, emSize: 20);

      expect(box, const Rect.fromLTWH(40, 90, 9, 20));
      expect(InkChoreographyTimeline.mapToGlyphBox(const Offset(0, 0), box), const Offset(40, 90));
      expect(InkChoreographyTimeline.mapToGlyphBox(const Offset(100, 100), box), const Offset(49, 110));
      expect(InkChoreographyTimeline.mapToGlyphBox(const Offset(50, 84), box), const Offset(44.5, 106.8));
    });
  });
}
