import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'ink_bleed_noise.dart';
import 'ink_choreography_timeline.dart';
import 'ink_glyph_frame.dart';
import 'ink_stroke_path.dart';

/// The sizes of the wet-ink marks that differ between the Stationery Sheet
/// and the larger Trial Rice-Grid, in `0..100` stroke-box units.
class WetInkStyle {
  /// The entry blot pressed where the active stroke starts (顿笔).
  final double startBlotRadius;

  /// The ink pooled under the tip before bristle stretch widens it.
  final double tipPoolBaseRadius;

  const WetInkStyle({required this.startBlotRadius, required this.tipPoolBaseRadius});

  static const WetInkStyle sheet = WetInkStyle(startBlotRadius: 4.5, tipPoolBaseRadius: 3.8);
  static const WetInkStyle trialGrid = WetInkStyle(startBlotRadius: 5.5, tipPoolBaseRadius: 4.8);

  /// The tip pool swells as the bristles stretch behind a fast-moving tip.
  double tipPoolRadius(double bristleStretch) => tipPoolBaseRadius + math.min(2.4, bristleStretch * 0.09);
}

/// One character's wet ink at one instant.
class WetInkGlyph {
  final InkGlyphFrame frame;

  /// Bristle stretch in stroke-box units (`BrushKinematics.bristleStretch`).
  final double bristleStretch;

  const WetInkGlyph({required this.frame, this.bristleStretch = restingBristleStretch});

  /// The stretch of a brush at rest over the tip: its (4, -15) rest offset.
  static const double restingBristleStretch = 15.524174696260024;
}

/// Paints the progressive wet ink of the characters being written: for each
/// stroke a wide translucent halo and a saturated core, entry and exit blots,
/// dwell beads, and the pool under the moving tip, all over a soft displaced
/// bleed layer, fading through the settle. Pure: everything comes from the
/// [WetInkGlyph]s.
class WetInkPainter extends CustomPainter {
  final List<WetInkGlyph> glyphs;
  final Color inkColor;
  final WetInkStyle style;

  const WetInkPainter({
    required this.glyphs,
    required this.inkColor,
    this.style = WetInkStyle.sheet,
    super.repaint,
  });

  // Stroke widths, radii and alphas below are the prototype's, in stroke-box
  // units; `cjk`/`latin` pairs follow its `isCjk ? a : b` choices.
  static const double _doneHaloAlpha = 0.19;
  static const double _doneCoreAlpha = 0.93;
  static const double _liveHaloAlpha = 0.25;
  static const double _liveCoreAlpha = 0.96;
  static const double _entryNodeAlpha = 0.45;
  static const double _exitNodeAlpha = 0.35;
  static const double _startBlotAlpha = 0.34;
  static const double _tipPoolAlpha = 0.62;
  static const double _beadAlpha = 0.16;
  static const double _bleedBlurSigma = 0.38;

  /// Linear stroke times at which the brush leaves a dwell bead.
  static const List<double> _beadTimes = [0.0, 0.22, 0.44, 0.66, 0.88];

  @override
  void paint(Canvas canvas, Size size) {
    for (final glyph in glyphs) {
      paintGlyph(canvas, glyph, inkColor: inkColor, style: style);
    }
  }

  @override
  bool shouldRepaint(WetInkPainter oldDelegate) =>
      !identical(oldDelegate.glyphs, glyphs) || oldDelegate.inkColor != inkColor || oldDelegate.style != style;

  /// Paints one character's wet ink. Exposed so a sheet overlay can interleave
  /// it with its own paper masks in a single painter.
  static void paintGlyph(
    Canvas canvas,
    WetInkGlyph glyph, {
    required Color inkColor,
    WetInkStyle style = WetInkStyle.sheet,
  }) {
    final frame = glyph.frame;
    final plan = frame.plan;
    if (frame.isSettled || plan.strokes.isEmpty) return;

    final opacity = frame.wetOpacity;
    final blurSigma = frame.settleBlurSigma;
    final scale = frame.settleScale;
    final isSettling = !frame.isWriting;

    canvas.save();
    if (scale != 1.0) {
      final center = plan.box.center;
      canvas.translate(center.dx, center.dy);
      canvas.scale(scale);
      canvas.translate(-center.dx, -center.dy);
    }
    if (isSettling) {
      final layer = Paint()..color = Color.fromRGBO(0, 0, 0, opacity);
      if (blurSigma > 0.02) {
        layer.imageFilter = ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma, tileMode: TileMode.decal);
      }
      canvas.saveLayer(plan.box.inflate(plan.inkUnit * 24 + 4), layer);
    }

    final layers = _GlyphLayers(canvas, glyph, inkColor, style);
    layers.paint(isBleed: true);
    layers.paint(isBleed: false);

    if (isSettling) canvas.restore();
    canvas.restore();
  }
}

/// Draws one pass of a glyph's ink: either the crisp marks or their soft,
/// noise-displaced bleed copy underneath.
class _GlyphLayers {
  final Canvas canvas;
  final WetInkGlyph glyph;
  final Color inkColor;
  final WetInkStyle style;

  _GlyphLayers(this.canvas, this.glyph, this.inkColor, this.style);

  InkGlyphFrame get _frame => glyph.frame;
  InkGlyphPlan get _plan => _frame.plan;
  double get _unit => _plan.inkUnit;
  bool get _isCjk => _plan.isCjk;

  void paint({required bool isBleed}) {
    final blur = isBleed ? const MaskFilter.blur(BlurStyle.normal, WetInkPainter._bleedBlurSigma) : null;
    final fill = Paint()..maskFilter = blur;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = blur;

    // Strokes already down: entry and exit nodes under a halo and a core.
    for (var index = 0; index < _frame.completedStrokes; index++) {
      final stroke = _plan.strokes[index];
      _dot(stroke.start, _isCjk ? 4.8 : 4.2, WetInkPainter._entryNodeAlpha, fill, isBleed);
      _dot(stroke.end, _isCjk ? 4.2 : 3.8, WetInkPainter._exitNodeAlpha, fill, isBleed);
      final path = isBleed ? stroke.fullBleedPath : stroke.fullPath;
      _stroke(path, _isCjk ? 13.5 : 12.5, WetInkPainter._doneHaloAlpha, line);
      _stroke(path, _isCjk ? 8.6 : 8.0, WetInkPainter._doneCoreAlpha, line);
    }
    if (!_frame.isWriting) return;

    // Dwell beads left along every stroke started so far.
    final beadRadius = (style.tipPoolBaseRadius + 2.0) * 0.85;
    for (var index = 0; index <= _frame.strokeIndex; index++) {
      final isActive = index == _frame.strokeIndex;
      for (final beadTime in WetInkPainter._beadTimes) {
        if (isActive && beadTime > _frame.strokeProgress) break;
        final center = _plan.strokes[index].pointAt(InkChoreographyTimeline.easedProgress(beadTime));
        _dot(center, beadRadius, WetInkPainter._beadAlpha, fill, isBleed);
      }
    }

    // The stroke under the brush: start blot, wider live halo and core up to
    // the tip, and the pool of ink beneath it.
    final active = _plan.strokes[_frame.strokeIndex];
    _dot(active.start, style.startBlotRadius, WetInkPainter._startBlotAlpha, fill, isBleed);
    final revealed = InkStrokePath.polylinePath(
      isBleed ? active.bleedRevealedUpTo(_frame.inkProgress) : active.revealedUpTo(_frame.inkProgress),
    );
    _stroke(revealed, _isCjk ? 15.0 : 14.0, WetInkPainter._liveHaloAlpha, line);
    _stroke(revealed, _isCjk ? 9.2 : 8.5, WetInkPainter._liveCoreAlpha, line);
    _dot(_frame.tip, style.tipPoolRadius(glyph.bristleStretch), WetInkPainter._tipPoolAlpha, fill, isBleed);
  }

  void _stroke(Path path, double widthUnits, double alpha, Paint line) {
    line
      ..strokeWidth = widthUnits * _unit
      ..color = inkColor.withValues(alpha: inkColor.a * alpha);
    canvas.drawPath(path, line);
  }

  void _dot(Offset center, double radiusUnits, double alpha, Paint fill, bool isBleed) {
    fill.color = inkColor.withValues(alpha: inkColor.a * alpha);
    final drift = isBleed ? InkBleedNoise.displacement(center - _plan.box.topLeft) : Offset.zero;
    canvas.drawCircle(center + drift, radiusUnits * _unit, fill);
  }
}
