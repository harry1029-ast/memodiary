import 'package:flutter/material.dart';
import '../models/template_style.dart';
import '../services/stationery_layout_calculator.dart';

/// Modular drawing service responsible for classical Double Outer Border (文武双栏)
/// and central folding Fishtail Mark (版心黑鱼尾) geometry.
class StationeryCanvasFraming {
  const StationeryCanvasFraming._();

  /// Determines whether the Double Outer Border should be drawn for a template.
  static bool shouldDrawDoubleBorder(TemplateStyle style) {
    if (style.type == TemplateBackgroundType.lined ||
        style.type == TemplateBackgroundType.grid ||
        style.type == TemplateBackgroundType.paperTexture) {
      return true;
    }
    // Solid color / dotGrid with non-minimal substrate or non-default tint
    if (style.tokens.substrate != PaperSubstrate.minimal ||
        style.tokens.ruleTint != RuleInkTint.slate) {
      return true;
    }
    return false;
  }

  /// Resolves the stroke color for outer or inner border rectangles,
  /// adapting automatically for low-glare contrast on [PaperSubstrate.obsidian].
  static Color resolveBorderColor({
    required TemplateStyle style,
    required bool isOuter,
  }) {
    final isDark = style.tokens.substrate == PaperSubstrate.obsidian ||
        ThemeData.estimateBrightnessForColor(style.backgroundColor) == Brightness.dark;

    if (isDark) {
      return isOuter
          ? const Color(0x3DFFFFFF)
          : const Color(0x26FFFFFF);
    }

    final base = style.tokens.ruleTint.color;
    final alpha = isOuter ? 0.85 : 0.70;
    return base.withValues(alpha: alpha);
  }

  /// Determines whether the classical Fishtail Mark should be rendered.
  /// Only rendered on manuscript grid (grid background type) when columnCount >= 7.
  static bool shouldRenderFishtail({
    required TemplateStyle style,
    required int columnCount,
  }) {
    if (style.type != TemplateBackgroundType.grid) {
      return false;
    }
    return columnCount >= 7;
  }

  /// Resolves the fill color for the Fishtail Mark.
  static Color resolveFishtailColor({
    required TemplateStyle style,
    required bool isDark,
  }) {
    if (isDark) {
      return const Color(0x4AFFFFFF);
    }
    if (style.tokens.ruleTint == RuleInkTint.vermilion) {
      return const Color(0xD9C04851);
    }
    return const Color(0xD94A4B4D);
  }

  /// Paints the Double Outer Border (文武双栏) and conditional Fishtail Mark (版心黑鱼尾).
  static void paintFraming({
    required Canvas canvas,
    required StationeryLayoutMetrics metrics,
    required TemplateStyle style,
    double scrollOffsetY = 0.0,
  }) {
    if (!shouldDrawDoubleBorder(style)) return;

    final isDark = style.tokens.substrate == PaperSubstrate.obsidian ||
        ThemeData.estimateBrightnessForColor(style.backgroundColor) == Brightness.dark;

    final translatedRect = metrics.innerFrameRect.translate(0.0, -scrollOffsetY);

    final outerColor = resolveBorderColor(style: style, isOuter: true);
    final innerColor = resolveBorderColor(style: style, isOuter: false);

    final outerPaint = Paint()
      ..color = outerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    // 文武双栏: Outer stroke inflated by 4.0px, inner stroke on innerFrameRect
    final outerRect = translatedRect.inflate(4.0);
    canvas.drawRect(outerRect, outerPaint);
    canvas.drawRect(translatedRect, innerPaint);

    if (shouldRenderFishtail(style: style, columnCount: metrics.columnCount)) {
      paintFishtailMark(
        canvas: canvas,
        metrics: metrics,
        style: style,
        isDark: isDark,
        scrollOffsetY: scrollOffsetY,
      );
    }
  }

  /// Constructs the classical notched Fishtail Mark (版心黑鱼尾) polygon path.
  static Path createFishtailPath({
    required Rect columnRect,
    required double lineStridePx,
  }) {
    final path = Path();
    final midX = columnRect.center.dx;
    final leftX = columnRect.left + 2.0;
    final rightX = columnRect.right - 2.0;

    final topY = columnRect.top + lineStridePx * 0.2;
    final tailHeight = lineStridePx * 0.75;
    final bottomY = topY + tailHeight;

    path.moveTo(leftX, topY);
    path.lineTo(midX, topY + tailHeight * 0.45);
    path.lineTo(rightX, topY);
    path.lineTo(rightX, bottomY - tailHeight * 0.15);
    path.lineTo(midX, bottomY);
    path.lineTo(leftX, bottomY - tailHeight * 0.15);
    path.close();

    return path;
  }

  /// Paints the classical Fishtail Mark near the top of the central folding column.
  static void paintFishtailMark({
    required Canvas canvas,
    required StationeryLayoutMetrics metrics,
    required TemplateStyle style,
    required bool isDark,
    double scrollOffsetY = 0.0,
  }) {
    final translatedRect = metrics.innerFrameRect.translate(0.0, -scrollOffsetY);
    final midCol = metrics.columnCount ~/ 2;
    final colLeft = translatedRect.left + midCol * metrics.cellAdvancePx;
    final colRect = Rect.fromLTWH(
      colLeft,
      translatedRect.top,
      metrics.cellAdvancePx,
      metrics.lineStridePx,
    );

    final fishtailPath = createFishtailPath(
      columnRect: colRect,
      lineStridePx: metrics.lineStridePx,
    );

    final fishtailPaint = Paint()
      ..color = resolveFishtailColor(style: style, isDark: isDark)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fishtailPath, fishtailPaint);
  }
}
