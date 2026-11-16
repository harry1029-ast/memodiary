import 'dart:math' as math;
import 'dart:ui';

/// The pure timing and kinematic math of Ink Choreography (SPEC-020 §3),
/// shared by the Stationery Sheet overlay and the Trial Rice-Grid. Lengths
/// are logical pixels unless a function says otherwise; angles are degrees.
abstract final class InkChoreographyTimeline {
  /// Speed-up applied to every duration during a 全页挥毫 sheet replay.
  static const double replayBoost = 1.6;

  /// How long a finished character's wet ink and paper mask take to dissolve
  /// into the printed glyph (`inkPrintSettle`).
  static const Duration settleDuration = Duration(milliseconds: 260);

  /// How long the master brush rests on the paper after its queue empties
  /// before it is put away.
  static const Duration brushRestDuration = Duration(milliseconds: 260);

  static const double silkTraceMinDistance = 6.0;
  static const double silkTraceMaxDistance = 180.0;

  /// The frame the lag factors are defined against.
  static const double referenceFrameMs = 1000.0 / 60.0;

  /// Where the handle comes to rest relative to the tip, in brush units.
  static const Offset handleRestOffset = Offset(4, -15);

  /// Where the handle starts relative to the tip when the brush first lands,
  /// so the first stroke opens with an entry press (落笔藏锋).
  static const Offset handleLandingOffset = Offset(6, -16);

  /// How far the handle is flicked up between two strokes (提笔换锋).
  static const double strokeChangeLift = 4.0;

  static const double restingShaftAngle = 22.0;
  static const double maxDragTilt = 22.0;

  /// Dynamic cursive catch-up (行书提速) for the Single Fluent Brush queue.
  static double catchupMult(int remainingQueueLength) {
    if (remainingQueueLength >= 6) return 2.6;
    if (remainingQueueLength >= 3) return 1.9;
    if (remainingQueueLength >= 1) return 1.35;
    return 1.0;
  }

  /// Three-phase stroke cadence: entry press (顿笔起), brisk travel (疾行),
  /// exit dwell (驻笔收). Maps linear stroke time to distance along the stroke.
  static double easedProgress(double progress) {
    final clamped = progress.clamp(0.0, 1.0);
    if (clamped < 0.20) return (clamped / 0.20) * 0.16;
    if (clamped > 0.85) return 0.86 + ((clamped - 0.85) / 0.15) * 0.14;
    return 0.16 + ((clamped - 0.20) / 0.65) * 0.70;
  }

  /// Whether the bristles are pressed onto the paper at this point of a
  /// stroke's linear time (they land and lift at its two ends).
  static bool isPressing(double progress) => progress > 0.02 && progress < 0.96;

  static Duration strokeDuration({
    required bool isCjk,
    required double speedMultiplier,
    double catchupMult = 1.0,
    double replayBoost = 1.0,
  }) {
    final milliseconds = (isCjk ? 245.0 : 205.0) / (speedMultiplier * catchupMult * replayBoost);
    return Duration(microseconds: (milliseconds * 1000).round());
  }

  /// The lifted glide from one character to the next (Single Fluent Brush).
  static Duration transitDuration({
    required double speedMultiplier,
    double catchupMult = 1.0,
    double replayBoost = 1.0,
  }) {
    final milliseconds = (135.0 / (speedMultiplier * catchupMult * replayBoost)).round();
    return Duration(milliseconds: math.max(38, milliseconds));
  }

  /// Whether a transit of [distance] draws its Airborne Silk Trace (提笔游丝).
  static bool showsSilkTrace(double distance) =>
      distance >= silkTraceMinDistance && distance <= silkTraceMaxDistance;

  /// The share of the handle-to-target gap closed in [dt]. Equals
  /// [lagFactor] at exactly 60 Hz and composes to the same result at any
  /// frame rate.
  static double lagAlpha(double lagFactor, Duration dt) {
    final frames = dt.inMicroseconds / 1000.0 / referenceFrameMs;
    return 1.0 - math.pow(1.0 - lagFactor, frames).toDouble();
  }

  /// The lag used while the brush glides between characters: the hand follows
  /// more tightly in the air.
  static double transitLagFactor(double lagFactor) => math.min(0.38, lagFactor * 1.45);

  /// One step of the handle chasing its rest position over [tip].
  /// [pxPerUnit] is the size of one brush unit (1.0 on a Stationery Sheet).
  static Offset followHandle({
    required Offset handle,
    required Offset tip,
    required double lagFactor,
    required Duration dt,
    double liftHeight = 0.0,
    double pxPerUnit = 1.0,
  }) {
    final target = tip + handleRestOffset * pxPerUnit - Offset(0, liftHeight);
    return handle + (target - handle) * lagAlpha(lagFactor, dt);
  }

  /// How far the hand's drag tilts the shaft off its resting angle.
  /// [handleToTip] is `tip - handle` in brush units, with the tip's `y`
  /// already raised by 65% of any lift.
  static double dragTilt(Offset handleToTip) =>
      (-handleToTip.dx * 0.55 + (handleToTip.dy - 16.0) * 0.16).clamp(-maxDragTilt, maxDragTilt);

  static double shaftAngle(Offset handleToTip) => restingShaftAngle + dragTilt(handleToTip);

  /// How far the bristle belly swells sideways, in brush units.
  /// [localDistance] is the handle-to-tip distance in brush units.
  static double bristleBulge({
    required double localDistance,
    required bool isPressing,
    required double brushScale,
  }) {
    final pressure = isPressing ? 1.0 : 0.28;
    return math.min(localDistance * 0.42 * pressure, 16.0 * brushScale);
  }

  /// The sheet's master bamboo brush's size for text of [fontSize]. Its brush
  /// unit is one logical pixel.
  static double brushScaleFor(double fontSize) => (fontSize / 22.0).clamp(0.68, 1.08);

  /// The size of a character's own brush (Concurrent Multi-Brush) for text of
  /// [fontSize]. Its brush unit is the glyph's stroke-box unit
  /// (`InkGlyphPlan.inkUnit`), so it stands about one glyph tall and
  /// neighbouring brushes do not collide.
  static double localBrushScaleFor(double fontSize) => (fontSize / 24.0).clamp(0.55, 0.95);

  /// The size of the Trial Rice-Grid's brush, in stroke-box units of its
  /// glyph box.
  static const double trialGridBrushScale = 1.05;

  /// The rect a character's `0..100` stroke box maps onto: as wide as the
  /// glyph's advance, one em tall, centred vertically on its text line.
  static Rect glyphBox({
    required double left,
    required double advance,
    required double lineCenterY,
    required double emSize,
  }) =>
      Rect.fromLTWH(left, lineCenterY - emSize / 2, advance, emSize);

  /// Maps a point of the `0..100` stroke box into [box].
  static Offset mapToGlyphBox(Offset unitPoint, Rect box) => Offset(
        box.left + unitPoint.dx * box.width / 100.0,
        box.top + unitPoint.dy * box.height / 100.0,
      );
}

/// The lifted parabolic glide of the master brush from the end of one
/// character to the start of the next.
class InkTransit {
  final Offset from;
  final Offset to;

  InkTransit({required this.from, required this.to});

  late final double distance = (to - from).distance;

  /// The quadratic Bézier control point of the arc (and of its silk trace).
  late final Offset control = Offset(
    (from.dx + to.dx) / 2,
    (from.dy + to.dy) / 2 - (distance * 0.22).clamp(8.0, 28.0),
  );

  /// The brush's height over the paper at mid-transit.
  late final double peakLift = (distance * 0.14).clamp(5.0, 14.0);

  bool get showsSilkTrace => InkChoreographyTimeline.showsSilkTrace(distance);

  /// The tip position and lift at linear transit time [t] in `0..1`.
  InkTransitFrame frameAt(double t) {
    final clamped = t.clamp(0.0, 1.0);
    final ease = clamped < 0.5 ? 2 * clamped * clamped : 1 - math.pow(-2 * clamped + 2, 2) / 2;
    final inverse = 1 - ease;
    final tip = from * (inverse * inverse) + control * (2 * inverse * ease) + to * (ease * ease);
    return InkTransitFrame(tip: tip, liftHeight: math.sin(ease * math.pi) * peakLift);
  }
}

class InkTransitFrame {
  final Offset tip;
  final double liftHeight;

  const InkTransitFrame({required this.tip, required this.liftHeight});
}
