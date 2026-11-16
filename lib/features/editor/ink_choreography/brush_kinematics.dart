import 'dart:math' as math;
import 'dart:ui';

import 'ink_choreography_timeline.dart';

/// The hand holding a bamboo brush: a handle (the ferrule base) that chases
/// the ink tip with bristle lag. One instance is the master brush of a sheet
/// (Single Fluent Brush) or the local brush of one character.
///
/// Positions are logical pixels. [pxPerUnit] is the size of one brush unit:
/// 1.0 on a Stationery Sheet, smaller on the Trial Rice-Grid so the whole
/// brush and its motion shrink together.
class BrushKinematics {
  final double pxPerUnit;

  BrushKinematics({this.pxPerUnit = 1.0});

  Offset? _handle;

  bool get hasLanded => _handle != null;

  /// The ferrule base. Only valid once the brush [hasLanded].
  Offset get handle => _handle!;

  /// Brings the brush down over [tip], poised above-right of it so the first
  /// stroke opens with an entry press (落笔藏锋).
  void land(Offset tip) => _handle = tip + InkChoreographyTimeline.handleLandingOffset * pxPerUnit;

  /// Lets the handle chase [tip] for [dt]. Lands first if the brush is new.
  void follow({
    required Offset tip,
    required Duration dt,
    required double lagFactor,
    double liftHeight = 0.0,
  }) {
    if (!hasLanded) land(tip);
    _handle = InkChoreographyTimeline.followHandle(
      handle: handle,
      tip: tip,
      lagFactor: lagFactor,
      dt: dt,
      liftHeight: liftHeight,
      pxPerUnit: pxPerUnit,
    );
  }

  /// The small upward flick of the hand between two strokes (提笔换锋).
  void flickForNextStroke() {
    if (!hasLanded) return;
    _handle = handle - Offset(0, InkChoreographyTimeline.strokeChangeLift * pxPerUnit);
  }

  /// The brush leaves the paper; the next [land] starts afresh.
  void putAway() => _handle = null;

  /// How far the bristles are stretched from handle to [tip], measured in
  /// `0..100` stroke-box units of size [inkUnit]: about 15.5 at rest, more
  /// while the tip outruns the handle. Feeds the wet-ink tip pool.
  double bristleStretch({required Offset tip, required double inkUnit}) {
    final rest = InkChoreographyTimeline.handleRestOffset;
    if (!hasLanded || inkUnit <= 0) return rest.distance;
    final lag = handle - (tip + rest * pxPerUnit);
    return (rest + lag / inkUnit).distance;
  }

  BrushPose pose({
    required Offset tip,
    required bool isPressing,
    required double brushScale,
    double liftHeight = 0.0,
  }) =>
      BrushPose.resolve(
        handle: handle,
        tip: tip,
        isPressing: isPressing,
        liftHeight: liftHeight,
        brushScale: brushScale,
        pxPerUnit: pxPerUnit,
      );
}

/// Everything the bamboo brush painter needs for one frame: where the shaft
/// stands, how it leans, and how the bristle cone bends from the ferrule to
/// the ink tip. Lengths named "local" are brush units in shaft space (origin
/// at the handle, `y` down the shaft); the rest are logical pixels.
class BrushPose {
  /// The ferrule base (lift included).
  final Offset handle;

  /// The ink contact point on the paper.
  final Offset tip;
  final double liftHeight;
  final bool isPressing;
  final double brushScale;
  final double pxPerUnit;

  /// Degrees clockwise from upright: 22 at rest, 0..44 under drag.
  final double shaftAngle;

  /// The bristle tip in shaft space.
  final Offset localTip;

  /// Half the width of the bristle root.
  final double ferruleRadius;

  /// How far the bristle belly swells sideways.
  final double bulge;

  /// Quadratic Bézier control points of the cone's left and right flanks.
  final Offset leftControl;
  final Offset rightControl;

  /// Handle-to-tip distance in brush units.
  final double stretch;

  const BrushPose._({
    required this.handle,
    required this.tip,
    required this.liftHeight,
    required this.isPressing,
    required this.brushScale,
    required this.pxPerUnit,
    required this.shaftAngle,
    required this.localTip,
    required this.ferruleRadius,
    required this.bulge,
    required this.leftControl,
    required this.rightControl,
    required this.stretch,
  });

  factory BrushPose.resolve({
    required Offset handle,
    required Offset tip,
    required bool isPressing,
    required double brushScale,
    double liftHeight = 0.0,
    double pxPerUnit = 1.0,
  }) {
    // Handle-to-tip in brush units; a lifted tip hangs 65% of the lift up.
    final toTip = Offset(tip.dx - handle.dx, (tip.dy - liftHeight * 0.65) - handle.dy) / pxPerUnit;
    final shaftAngle = InkChoreographyTimeline.shaftAngle(toTip);

    // Counter-rotate into shaft space so the bent bristles end exactly on the tip.
    final radians = -shaftAngle * math.pi / 180.0;
    final localTip = Offset(
      toTip.dx * math.cos(radians) - toTip.dy * math.sin(radians),
      toTip.dx * math.sin(radians) + toTip.dy * math.cos(radians),
    );
    final stretch = math.max(localTip.distance, 0.001);
    final perpendicular = Offset(-localTip.dy / stretch, localTip.dx / stretch);

    final ferruleRadius = math.max(3.8, 6.4 * brushScale);
    final bulge = InkChoreographyTimeline.bristleBulge(
      localDistance: stretch,
      isPressing: isPressing,
      brushScale: brushScale,
    );

    return BrushPose._(
      handle: handle,
      tip: tip,
      liftHeight: liftHeight,
      isPressing: isPressing,
      brushScale: brushScale,
      pxPerUnit: pxPerUnit,
      shaftAngle: shaftAngle,
      localTip: localTip,
      ferruleRadius: ferruleRadius,
      bulge: bulge,
      leftControl: Offset(-ferruleRadius, 0) + perpendicular * bulge + localTip * 0.24,
      rightControl: Offset(ferruleRadius, 0) - perpendicular * (bulge * 0.55) + localTip * 0.28,
      stretch: stretch,
    );
  }

  double get shaftRadians => shaftAngle * math.pi / 180.0;

  /// The shaft's scale: it looms slightly larger while lifted in transit.
  double get shaftScale => brushScale * (1 + liftHeight / pxPerUnit * 0.008);

  /// Where the bristle tip is drawn: on [tip], or above it while lifted.
  Offset get bristleTipOnPaper {
    final local = localTip * pxPerUnit;
    return handle +
        Offset(
          local.dx * math.cos(shaftRadians) - local.dy * math.sin(shaftRadians),
          local.dx * math.sin(shaftRadians) + local.dy * math.cos(shaftRadians),
        );
  }

  /// The soft shadow the bristles cast on the paper; it drifts away from the
  /// tip as the brush lifts.
  Offset get shadowCenter => tip + Offset(2 * pxPerUnit + liftHeight * 0.45, 2 * pxPerUnit + liftHeight * 0.65);

  Size get shadowRadii => isPressing
      ? Size(5.5 + math.min(4.0, stretch * 0.12), 3.0 + math.min(2.0, stretch * 0.06)) * pxPerUnit
      : Size(3.2, 1.8) * pxPerUnit;

  double get shadowOpacity => isPressing ? 0.22 : 0.10;
}
