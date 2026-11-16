import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/ink_choreography/brush_kinematics.dart';

void main() {
  const frame60 = Duration(microseconds: 16667);

  group('BrushKinematics', () {
    test('has no handle until the brush lands', () {
      final brush = BrushKinematics();

      expect(brush.hasLanded, isFalse);
      brush.land(const Offset(100, 100));
      expect(brush.hasLanded, isTrue);
      expect(brush.handle, const Offset(106, 84));
    });

    test('comes to rest 4 right of and 15 above a still tip', () {
      final brush = BrushKinematics()..land(const Offset(100, 100));

      for (var tick = 0; tick < 240; tick++) {
        brush.follow(tip: const Offset(100, 100), dt: frame60, lagFactor: 0.18);
      }

      expect(brush.handle, offsetMoreOrLessEquals(const Offset(104, 85), epsilon: 1e-6));
    });

    test('a stiffer brush closes on the tip faster', () {
      Offset after(double lagFactor) {
        final brush = BrushKinematics()..land(const Offset(0, 0));
        for (var tick = 0; tick < 5; tick++) {
          brush.follow(tip: const Offset(60, 0), dt: frame60, lagFactor: lagFactor);
        }
        return brush.handle;
      }

      expect(after(0.28).dx, greaterThan(after(0.18).dx));
      expect(after(0.18).dx, greaterThan(after(0.11).dx));
    });

    test('following before landing lands the brush on the tip first', () {
      final brush = BrushKinematics()..follow(tip: const Offset(10, 10), dt: Duration.zero, lagFactor: 0.18);

      expect(brush.handle, const Offset(16, -6));
    });

    test('putting the brush away forgets where it was', () {
      final brush = BrushKinematics()
        ..land(const Offset(10, 10))
        ..putAway();

      expect(brush.hasLanded, isFalse);
    });

    test('on a small Trial Rice-Grid the rest offsets shrink with the brush unit', () {
      final brush = BrushKinematics(pxPerUnit: 0.5)..land(const Offset(30, 30));

      expect(brush.handle, const Offset(33, 22));
      for (var tick = 0; tick < 240; tick++) {
        brush.follow(tip: const Offset(30, 30), dt: frame60, lagFactor: 0.18);
      }
      expect(brush.handle, offsetMoreOrLessEquals(const Offset(32, 22.5), epsilon: 1e-6));
    });
  });

  group('BrushPose', () {
    BrushPose resolve({
      Offset handle = const Offset(104, 85),
      Offset tip = const Offset(100, 100),
      bool isPressing = true,
      double liftHeight = 0.0,
      double brushScale = 1.0,
      double pxPerUnit = 1.0,
    }) =>
        BrushPose.resolve(
          handle: handle,
          tip: tip,
          isPressing: isPressing,
          liftHeight: liftHeight,
          brushScale: brushScale,
          pxPerUnit: pxPerUnit,
        );

    test('at rest the shaft leans 24 degrees, held from the upper right', () {
      expect(resolve().shaftAngle, closeTo(24.04, 1e-9));
    });

    test('however the hand drags, the shaft stays between 0 and 44 degrees', () {
      expect(resolve(handle: const Offset(400, 85)).shaftAngle, 44.0);
      expect(resolve(handle: const Offset(-200, 85)).shaftAngle, 0.0);
    });

    test('the bent bristles always end exactly on the ink tip', () {
      for (final handle in const [Offset(104, 85), Offset(130, 70), Offset(80, 95), Offset(100, 60)]) {
        final pose = resolve(handle: handle);
        expect(pose.bristleTipOnPaper, offsetMoreOrLessEquals(const Offset(100, 100), epsilon: 1e-9));
      }
    });

    test('a lifted brush hangs its bristle tip 65% of the lift above the paper', () {
      final pose = resolve(handle: const Offset(104, 75), liftHeight: 10, isPressing: false);

      expect(pose.bristleTipOnPaper, offsetMoreOrLessEquals(const Offset(100, 93.5), epsilon: 1e-9));
    });

    test('the belly swells with the stretch while pressing and relaxes when lifted', () {
      final pressing = resolve(handle: const Offset(120, 80));
      final lifted = resolve(handle: const Offset(120, 80), isPressing: false);

      // Stretch is hypot(20, 20) = 28.28 brush units.
      expect(pressing.bulge, closeTo(28.2843 * 0.42, 1e-3));
      expect(lifted.bulge, closeTo(28.2843 * 0.42 * 0.28, 1e-3));
    });

    test('the belly never swells beyond 16 x brushScale', () {
      expect(resolve(handle: const Offset(400, -300)).bulge, 16.0);
      expect(resolve(handle: const Offset(400, -300), brushScale: 0.68).bulge, closeTo(10.88, 1e-9));
    });

    test('the bristle root is as wide as the ferrule, with a floor for small brushes', () {
      expect(resolve(brushScale: 1.0).ferruleRadius, closeTo(6.4, 1e-9));
      expect(resolve(brushScale: 0.5).ferruleRadius, 3.8);
    });

    test('the shaft looms slightly larger while lifted', () {
      expect(resolve().shaftScale, 1.0);
      expect(resolve(liftHeight: 10, isPressing: false).shaftScale, closeTo(1.08, 1e-9));
    });

    test('the contact shadow sits under the tip, darker and wider while pressing', () {
      final pressing = resolve(handle: const Offset(120, 80));
      final lifted = resolve(handle: const Offset(120, 80), isPressing: false, liftHeight: 10);

      expect(pressing.shadowCenter, const Offset(102, 102));
      expect(pressing.shadowOpacity, 0.22);
      expect(pressing.shadowRadii.width, closeTo(5.5 + 28.2843 * 0.12, 1e-3));
      expect(pressing.shadowRadii.height, closeTo(3.0 + 28.2843 * 0.06, 1e-3));

      expect(lifted.shadowCenter, const Offset(106.5, 108.5));
      expect(lifted.shadowOpacity, 0.10);
      expect(lifted.shadowRadii, const Size(3.2, 1.8));
    });

    test('the shadow stops growing once the bristles are fully stretched', () {
      final pose = resolve(handle: const Offset(400, -300));

      expect(pose.shadowRadii, const Size(9.5, 5.0));
    });

    test('scaling the whole scene by the brush unit leaves the pose the same shape', () {
      final sheet = resolve(handle: const Offset(120, 80));
      final grid = resolve(handle: const Offset(60, 40), tip: const Offset(50, 50), pxPerUnit: 0.5);

      expect(grid.shaftAngle, closeTo(sheet.shaftAngle, 1e-9));
      expect(grid.bulge, closeTo(sheet.bulge, 1e-9));
      expect(grid.localTip, offsetMoreOrLessEquals(sheet.localTip, epsilon: 1e-9));
      expect(grid.shadowRadii.width, closeTo(sheet.shadowRadii.width * 0.5, 1e-9));
      expect(grid.bristleTipOnPaper, offsetMoreOrLessEquals(const Offset(50, 50), epsilon: 1e-9));
    });
  });
}
