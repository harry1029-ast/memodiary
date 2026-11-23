import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ink_choreography/bamboo_brush_painter.dart';
import '../../ink_choreography/ink_choreography_timeline.dart';
import '../../ink_choreography/ink_glyph_performance.dart';
import '../../ink_choreography/wet_ink_painter.dart';

/// Paints the Trial Rice-Grid (米字格试笔窗): a square of the template's
/// paper with dashed vermilion crosshairs and diagonals, the printed sample
/// glyph revealed as its wet ink settles, the wet ink itself, and the bamboo
/// brush while it writes. Repaints on [repaint] (one tick per frame).
class TrialRiceGridPainter extends CustomPainter {
  final String sample;
  final InkGlyphPerformance? Function() performance;
  final Rect glyphBox;
  final bool showsBrush;
  final Color inkColor;
  final Color paperColor;
  final String? fontFamily;

  TrialRiceGridPainter({
    required this.sample,
    required this.performance,
    required this.glyphBox,
    required this.showsBrush,
    required this.inkColor,
    required this.paperColor,
    required this.fontFamily,
    super.repaint,
  });

  static const Color vermilion = Color(0xFFB83B2E);

  @override
  void paint(Canvas canvas, Size size) {
    final square = Offset.zero & size;
    _paintGrid(canvas, square);

    final current = performance();
    final frame = current?.frame;
    final printOpacity = frame == null ? 1.0 : 1.0 - frame.wetOpacity;
    if (printOpacity > 0) _paintPrintedGlyph(canvas, printOpacity);
    if (current == null || frame == null || frame.isSettled) return;

    WetInkPainter(
      glyphs: [WetInkGlyph(frame: frame, bristleStretch: current.bristleStretch)],
      inkColor: inkColor,
      style: WetInkStyle.trialGrid,
    ).paint(canvas, size);

    final pose = showsBrush ? current.pose(brushScale: InkChoreographyTimeline.trialGridBrushScale) : null;
    if (pose != null) BambooBrushPainter.paintBrush(canvas, pose, inkColor: inkColor);
  }

  void _paintGrid(Canvas canvas, Rect square) {
    final rounded = RRect.fromRectAndRadius(square, const Radius.circular(10));
    canvas.drawRRect(rounded, Paint()..color = paperColor);
    canvas.drawRRect(
      rounded.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = vermilion.withValues(alpha: 0.4),
    );

    // The prototype's 100-unit viewBox: crosshairs dashed 3/3 at 0.8, diagonals 2/4 at 0.5.
    final unit = square.width / 100.0;
    final guide = Paint()..color = vermilion.withValues(alpha: 0.35);
    guide.strokeWidth = 0.8 * unit;
    _dashed(canvas, square.centerLeft, square.centerRight, 3 * unit, 3 * unit, guide);
    _dashed(canvas, square.topCenter, square.bottomCenter, 3 * unit, 3 * unit, guide);
    guide.strokeWidth = 0.5 * unit;
    _dashed(canvas, square.topLeft, square.bottomRight, 2 * unit, 4 * unit, guide);
    _dashed(canvas, square.topRight, square.bottomLeft, 2 * unit, 4 * unit, guide);
  }

  static void _dashed(Canvas canvas, Offset from, Offset to, double dash, double gap, Paint paint) {
    final span = to - from;
    final length = span.distance;
    if (length <= 0) return;
    final direction = span / length;
    for (var start = 0.0; start < length; start += dash + gap) {
      final end = math.min(start + dash, length);
      canvas.drawLine(from + direction * start, from + direction * end, paint);
    }
  }

  void _paintPrintedGlyph(Canvas canvas, double opacity) {
    final fontSize = glyphBox.height * 0.82;
    final glyph = TextPainter(
      text: TextSpan(
        text: sample,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          height: 1.0,
          color: inkColor.withValues(alpha: inkColor.a * opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    )..layout();
    final baseline = glyph.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final lineMetrics = glyph.computeLineMetrics();
    final glyphWidth = lineMetrics.isNotEmpty ? lineMetrics.first.width : glyph.width;
    final isCjk = sample.runes.isNotEmpty && sample.runes.first >= 0x2E80;
    final origin = resolveGlyphOrigin(
      glyphBox: glyphBox,
      glyphWidth: glyphWidth,
      glyphHeight: glyph.height,
      alphabeticBaseline: baseline,
      fontSize: fontSize,
      isCjk: isCjk,
    );
    glyph.paint(canvas, origin);
    glyph.dispose();
  }

  /// Resolves the top-left paint origin so the glyph's optical ink box centers
  /// on [glyphBox.center], avoiding upward shift from asymmetric font descent.
  static Offset resolveGlyphOrigin({
    required Rect glyphBox,
    required double glyphWidth,
    required double glyphHeight,
    required double alphabeticBaseline,
    required double fontSize,
    required bool isCjk,
  }) {
    final dx = glyphBox.center.dx - glyphWidth / 2;
    if (alphabeticBaseline <= 0) {
      return Offset(dx, glyphBox.center.dy - glyphHeight / 2);
    }
    final visualCenterAboveBaseline = fontSize * (isCjk ? 0.38 : 0.36);
    final dy = glyphBox.center.dy - (alphabeticBaseline - visualCenterAboveBaseline);
    return Offset(dx, dy);
  }

  @override
  bool shouldRepaint(TrialRiceGridPainter oldDelegate) =>
      oldDelegate.sample != sample ||
      oldDelegate.glyphBox != glyphBox ||
      oldDelegate.showsBrush != showsBrush ||
      oldDelegate.inkColor != inkColor ||
      oldDelegate.paperColor != paperColor ||
      oldDelegate.fontFamily != fontFamily;
}
