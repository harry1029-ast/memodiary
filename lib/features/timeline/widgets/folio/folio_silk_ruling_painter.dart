import 'package:flutter/material.dart';
import '../../../templates/models/template_style.dart';
import '../../../templates/services/stationery_geometry.dart';
import '../../../templates/widgets/stationery_canvas_framing.dart';
import 'folio_reading_perspective.dart';

/// Paints the integer-locked Paper Heart frame (320px x 448px) with a classical
/// Double Outer Border (文武双栏), conditional Fishtail Mark (版心黑鱼尾),
/// and ruling lines corresponding to [FolioRulingLayout] and [TemplateBackgroundType].
class FolioSilkRulingPainter extends CustomPainter {
  /// The ruling geometry (horizontal rules, vermilion vertical columns, or genkō grid).
  final FolioRulingLayout layout;

  /// Active template background type when rendering horizontal faithful layout.
  final TemplateBackgroundType backgroundType;

  /// Primary color for vertical/horizontal ruling lines.
  final Color ruleColor;

  /// Outer and inner border frame color.
  final Color frameColor;

  /// Whether the substrate is dark (e.g. Obsidian Night).
  final bool isDark;

  /// Whether to paint the classical woodblock Fishtail Mark (版心黑鱼尾).
  final bool showFishtail;

  /// Whether to paint the left vertical margin rule on horizontal layouts.
  final bool showLeftMarginRule;

  const FolioSilkRulingPainter({
    required this.layout,
    this.backgroundType = TemplateBackgroundType.lined,
    required this.ruleColor,
    required this.frameColor,
    this.isDark = false,
    bool? showFishtail,
    bool? showLeftMarginRule,
  })  : showFishtail = showFishtail ?? (layout == FolioRulingLayout.genkoVertical),
        showLeftMarginRule =
            showLeftMarginRule ?? (backgroundType == TemplateBackgroundType.lined);

  @override
  void paint(Canvas canvas, Size size) {
    final frame = StationeryGeometry.buildFolioFrame(
      size: size,
      showFishtail: showFishtail,
    );

    // 1. Classical Double Outer Border (文武双栏: outer 2.0px, inner 0.8px, gap 3.0px)
    final outerFramePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = frame.outerStrokeWidth;

    final innerFramePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = frame.innerStrokeWidth;

    canvas.drawRect(frame.outerRect, outerFramePaint);
    canvas.drawRect(frame.innerRect, innerFramePaint);

    // 2. Conditional Fishtail Mark (版心黑鱼尾)
    final fishtail = frame.fishtailPolygon;
    if (fishtail != null) {
      final fishtailPaint = Paint()
        ..color = isDark ? const Color(0x4AFFFFFF) : frameColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawPath(
        StationeryCanvasFraming.pathFromPolygon(fishtail),
        fishtailPaint,
      );
    }

    // 3. Ruling Lines & Dots from StationeryGeometry
    final rulings = StationeryGeometry.buildFolioRulings(
      size: size,
      isVerticalColumns: layout == FolioRulingLayout.vermilionVertical,
      isGenkoVertical: layout == FolioRulingLayout.genkoVertical,
      backgroundType: backgroundType,
      showLeftMarginRule: showLeftMarginRule,
    );

    _paintRulings(canvas, rulings);
  }

  void _paintRulings(Canvas canvas, StationeryRulingGeometry rulings) {
    switch (layout) {
      case FolioRulingLayout.vermilionVertical:
        _drawLines(
          canvas,
          rulings.primaryLines,
          Paint()
            ..color = ruleColor
            ..strokeWidth = 1.0,
        );

      case FolioRulingLayout.genkoVertical:
        _drawLines(
          canvas,
          rulings.primaryLines,
          Paint()
            ..color = ruleColor
            ..strokeWidth = 1.0,
        );
        _drawLines(
          canvas,
          rulings.secondaryLines,
          Paint()
            ..color = ruleColor.withValues(alpha: 0.38)
            ..strokeWidth = 0.8,
        );

      case FolioRulingLayout.faithfulHorizontal:
        _paintHorizontalRulings(canvas, rulings);
    }
  }

  void _paintHorizontalRulings(Canvas canvas, StationeryRulingGeometry rulings) {
    switch (backgroundType) {
      case TemplateBackgroundType.color:
        break;
      case TemplateBackgroundType.lined:
      case TemplateBackgroundType.paperTexture:
        _drawLines(
          canvas,
          rulings.primaryLines,
          Paint()
            ..color = ruleColor
            ..strokeWidth =
                backgroundType == TemplateBackgroundType.paperTexture ? 0.9 : 1.0,
        );
        if (rulings.leftMarginRule case final marginRule?) {
          final marginPaint = Paint()
            ..color = isDark ? const Color(0x38EF9A9A) : const Color(0x52C04851)
            ..strokeWidth = 1.2;
          canvas.drawLine(marginRule.start, marginRule.end, marginPaint);
        }
      case TemplateBackgroundType.grid:
        _drawLines(
          canvas,
          rulings.secondaryLines,
          Paint()
            ..color = ruleColor.withValues(alpha: ruleColor.a * 0.85)
            ..strokeWidth = 0.6,
        );
        _drawLines(
          canvas,
          rulings.primaryLines,
          Paint()
            ..color = ruleColor
            ..strokeWidth = 0.8,
        );
      case TemplateBackgroundType.dotGrid:
        final dotPaint = Paint()
          ..color = ruleColor
          ..style = PaintingStyle.fill;
        for (final dot in rulings.dots) {
          canvas.drawCircle(dot, 1.2, dotPaint);
        }
    }
  }

  void _drawLines(
    Canvas canvas,
    List<StationeryLineSegment> lines,
    Paint paint,
  ) {
    for (final line in lines) {
      canvas.drawLine(line.start, line.end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FolioSilkRulingPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.backgroundType != backgroundType ||
        oldDelegate.ruleColor != ruleColor ||
        oldDelegate.frameColor != frameColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.showFishtail != showFishtail ||
        oldDelegate.showLeftMarginRule != showLeftMarginRule;
  }
}

