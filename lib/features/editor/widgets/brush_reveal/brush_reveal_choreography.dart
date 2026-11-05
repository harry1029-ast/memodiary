import 'dart:math' as math;
import 'dart:ui';

/// Pure timing and geometry of the Brush Reveal (泼墨显影): five splash-ink
/// sweeps uncover an opaque silk-paper cover, the rest of the cover fades away
/// over a monochrome ink-wash print, the print blooms into full colour, and a
/// video then receives its cinnabar seal play stamp.
class BrushRevealTimeline {
  final bool isVideo;

  static const int kSweepCount = 5;
  static const Duration kSweep = Duration(milliseconds: 175);
  static const Duration kCoverFade = Duration(milliseconds: 550);
  static const Duration kBloom = Duration(milliseconds: 450);
  static const Duration kSealDelay = Duration(milliseconds: 260);
  static const Duration kSealStamp = Duration(milliseconds: 240);

  const BrushRevealTimeline({required this.isVideo});

  static Duration get _sweepsEnd => kSweep * kSweepCount;
  static Duration get _coverEnd => _sweepsEnd + kCoverFade;
  static Duration get _bloomEnd => _coverEnd + kBloom;

  /// Full length of the reveal, including a video's seal stamp.
  Duration get total => isVideo ? _bloomEnd + kSealDelay + kSealStamp : _bloomEnd;

  static double _phase(Duration elapsed, Duration start, Duration length) =>
      ((elapsed - start).inMicroseconds / length.inMicroseconds).clamp(0.0, 1.0);

  BrushRevealFrame frameAt(Duration elapsed) {
    final sweepsPainted =
        kSweepCount * _phase(elapsed, Duration.zero, _sweepsEnd);
    final sealStart = _bloomEnd + kSealDelay;
    return BrushRevealFrame(
      sweepsPainted: sweepsPainted,
      coverOpacity: 1.0 - _phase(elapsed, _sweepsEnd, kCoverFade),
      colour: _phase(elapsed, _coverEnd, kBloom),
      sealProgress: isVideo ? _phase(elapsed, sealStart, kSealStamp) : 0.0,
      isComplete: elapsed >= total,
    );
  }
}

/// One moment of the Brush Reveal.
class BrushRevealFrame {
  /// Sweeps painted so far, 0–5; the fraction is the progress of the current one.
  final double sweepsPainted;

  /// Opacity of what remains of the silk-paper cover, 1 → 0.
  final double coverOpacity;

  /// 0 = monochrome ink wash, 1 = full colour.
  final double colour;

  /// Cinnabar seal stamp progress (videos only), 0–1.
  final double sealProgress;
  final bool isComplete;

  const BrushRevealFrame({
    required this.sweepsPainted,
    required this.coverOpacity,
    required this.colour,
    required this.sealProgress,
    required this.isComplete,
  });

  /// The brush is on the slot only while sweeps are being painted.
  bool get isBrushVisible =>
      sweepsPainted > 0.0 && sweepsPainted < BrushRevealTimeline.kSweepCount;

  @override
  bool operator ==(Object other) =>
      other is BrushRevealFrame &&
      other.sweepsPainted == sweepsPainted &&
      other.coverOpacity == coverOpacity &&
      other.colour == colour &&
      other.sealProgress == sealProgress &&
      other.isComplete == isComplete;

  @override
  int get hashCode => Object.hash(sweepsPainted, coverOpacity, colour, sealProgress, isComplete);
}

/// One splash-ink sweep: a quadratic Bézier stroked with a round brush.
class BrushSweep {
  final Offset start;
  final Offset control;
  final Offset end;
  final double radius;

  const BrushSweep({
    required this.start,
    required this.control,
    required this.end,
    required this.radius,
  });

  Offset pointAt(double t) {
    final inverse = 1.0 - t;
    return start * (inverse * inverse) + control * (2 * inverse * t) + end * (t * t);
  }

  /// The sweep from its start to [t], as its own quadratic (de Casteljau split).
  BrushSweep partial(double t) => BrushSweep(
        start: start,
        control: Offset.lerp(start, control, t)!,
        end: pointAt(t),
        radius: radius,
      );
}

/// The five zig-zag sweeps that together cover a slot of a given size.
class BrushRevealSweeps {
  const BrushRevealSweeps._();

  /// Radii at the 100px reference slot.
  static const List<double> _baseRadii = [24.0, 26.0, 22.0, 28.0, 25.0];

  static List<BrushSweep> forSize(Size size) {
    final scale = size.shortestSide / 100.0;
    final overshoot = size.width * 0.08;
    return [
      for (var index = 0; index < BrushRevealTimeline.kSweepCount; index++)
        _sweep(size, index, scale, overshoot),
    ];
  }

  static BrushSweep _sweep(Size size, int index, double scale, double overshoot) {
    final rowY = size.height * (0.1 + 0.2 * index);
    final bow = size.height * (index.isEven ? -0.08 : 0.08);
    final left = Offset(-overshoot, rowY);
    final right = Offset(size.width + overshoot, rowY);
    final leftToRight = index.isEven;
    return BrushSweep(
      start: leftToRight ? left : right,
      control: Offset(size.width / 2, rowY + bow),
      end: leftToRight ? right : left,
      radius: _baseRadii[index] * scale,
    );
  }
}

/// Where the bamboo brush is on a sweep: its tip, the lagging point its body
/// trails toward, and its tilt (clamped to ±28°), leaning against travel.
class BrushPose {
  final Offset tip;
  final Offset trail;
  final double tilt;

  static const double kLag = 0.24;
  static const double kMaxTilt = 28 * math.pi / 180;

  const BrushPose({required this.tip, required this.trail, required this.tilt});

  factory BrushPose.at(BrushSweep sweep, double t) {
    final tip = sweep.pointAt(t);
    final trail = sweep.pointAt(math.max(0.0, t - kLag));
    final lean = -(tip.dx - trail.dx) / (4 * sweep.radius);
    return BrushPose(tip: tip, trail: trail, tilt: lean.clamp(-kMaxTilt, kMaxTilt));
  }
}
