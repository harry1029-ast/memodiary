import 'dart:ui';

import 'package:flutter/animation.dart';

import 'ink_choreography_timeline.dart';
import 'ink_stroke_path.dart';

enum InkGlyphPhase {
  /// Strokes are being inked one after another.
  writing,

  /// All strokes are down; wet ink and paper mask dissolve into the print.
  settling,

  /// Nothing left to draw: the printed glyph stands on its own.
  settled,
}

/// The schedule of one character: its strokes back to back, then the settle.
/// Pure: [frameAt] depends on the elapsed time alone.
class InkGlyphTimeline {
  final InkGlyphPlan plan;
  final Duration strokeDuration;
  final Duration settleDuration;

  const InkGlyphTimeline({
    required this.plan,
    required this.strokeDuration,
    this.settleDuration = InkChoreographyTimeline.settleDuration,
  });

  Duration get writingDuration => strokeDuration * plan.strokes.length;
  Duration get totalDuration => writingDuration + settleDuration;

  InkGlyphFrame frameAt(Duration elapsed) {
    final strokes = plan.strokes;
    final strokeMicros = strokeDuration.inMicroseconds;
    final elapsedMicros = elapsed.isNegative ? 0 : elapsed.inMicroseconds;

    if (strokes.isNotEmpty && strokeMicros > 0 && elapsedMicros < writingDuration.inMicroseconds) {
      final strokeIndex = elapsedMicros ~/ strokeMicros;
      final strokeProgress = (elapsedMicros - strokeIndex * strokeMicros) / strokeMicros;
      final inkProgress = InkChoreographyTimeline.easedProgress(strokeProgress);
      return InkGlyphFrame._(
        plan: plan,
        phase: InkGlyphPhase.writing,
        strokeIndex: strokeIndex,
        completedStrokes: strokeIndex,
        strokeProgress: strokeProgress,
        inkProgress: inkProgress,
        tip: strokes[strokeIndex].pointAt(inkProgress),
        isPressing: InkChoreographyTimeline.isPressing(strokeProgress),
        settleProgress: 0.0,
      );
    }

    final settleMicros = settleDuration.inMicroseconds;
    final sinceWritten = elapsedMicros - writingDuration.inMicroseconds;
    final settleProgress = settleMicros <= 0 ? 1.0 : (sinceWritten / settleMicros).clamp(0.0, 1.0);
    return InkGlyphFrame._(
      plan: plan,
      phase: settleProgress >= 1.0 ? InkGlyphPhase.settled : InkGlyphPhase.settling,
      strokeIndex: strokes.isEmpty ? 0 : strokes.length - 1,
      completedStrokes: strokes.length,
      strokeProgress: 1.0,
      inkProgress: 1.0,
      tip: strokes.isEmpty ? plan.box.center : strokes.last.end,
      isPressing: false,
      settleProgress: settleProgress,
    );
  }
}

/// What one character looks like at one instant: which strokes are down, how
/// far the active stroke has run, where the tip is, and how far the settle
/// has dissolved the wet ink. Painters render it as-is.
class InkGlyphFrame {
  final InkGlyphPlan plan;
  final InkGlyphPhase phase;

  /// The stroke being inked (the last stroke once writing is over).
  final int strokeIndex;

  /// Strokes fully inked before [strokeIndex].
  final int completedStrokes;

  /// Linear time through the active stroke, `0..1`.
  final double strokeProgress;

  /// Distance along the active stroke, `0..1`, after the three-phase cadence.
  final double inkProgress;

  /// The ink contact point.
  final Offset tip;

  /// Whether the bristles are pressed down (they land and lift at the ends of
  /// each stroke).
  final bool isPressing;

  /// `0..1` through the settle; 0 while writing.
  final double settleProgress;

  const InkGlyphFrame._({
    required this.plan,
    required this.phase,
    required this.strokeIndex,
    required this.completedStrokes,
    required this.strokeProgress,
    required this.inkProgress,
    required this.tip,
    required this.isPressing,
    required this.settleProgress,
  });

  static const Cubic _settlePress = Cubic(0.22, 1.0, 0.36, 1.0);

  bool get isWriting => phase == InkGlyphPhase.writing;
  bool get isSettled => phase == InkGlyphPhase.settled;

  /// Opacity of the wet ink and of the paper mask under it: 1 while writing,
  /// fading to 0 through the settle.
  double get wetOpacity => 1.0 - Curves.fastOutSlowIn.transform(settleProgress);

  /// `inkPrintSettle`: the wet ink swells as the print is pressed, dips just
  /// under size, then rests at 1.
  double get settleScale => _settleKeyframes(1.08, 0.98, 1.0);

  /// The wet ink's blur through the settle, in logical pixels.
  double get settleBlurSigma => _settleKeyframes(0.8, 0.15, 0.0);

  double _settleKeyframes(double from, double middle, double to) {
    if (phase == InkGlyphPhase.writing) return to;
    const pivot = 0.65;
    if (settleProgress < pivot) {
      return lerpDouble(from, middle, _settlePress.transform(settleProgress / pivot))!;
    }
    return lerpDouble(middle, to, _settlePress.transform((settleProgress - pivot) / (1 - pivot)))!;
  }
}
