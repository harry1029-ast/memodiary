import 'package:flutter/material.dart';
import '../models/template_style.dart';
import '../services/stationery_geometry.dart';
import '../services/stationery_layout_calculator.dart';

/// Flutter [Canvas] adapter for classical Double Outer Border (文武双栏)
/// and central folding Fishtail Mark (版心黑鱼尾) geometry.
class StationeryCanvasFraming {
  const StationeryCanvasFraming._();

  /// Determines whether the Double Outer Border should be drawn for a template.
  static bool shouldDrawDoubleBorder(TemplateStyle style) =>
      StationeryGeometry.shouldDrawDoubleBorder(style);

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
  }) =>
      StationeryGeometry.shouldRenderFishtail(
        style: style,
        columnCount: columnCount,
      );

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

  /// Converts a polygon vertex list from [StationeryGeometry] into a closed [Path].
  static Path pathFromPolygon(List<Offset> vertices) {
    final path = Path();
    if (vertices.isEmpty) return path;
    path.moveTo(vertices.first.dx, vertices.first.dy);
    for (int index = 1; index < vertices.length; index++) {
      path.lineTo(vertices[index].dx, vertices[index].dy);
    }
    path.close();
    return path;
  }

  /// Constructs the classical notched Fishtail Mark (版心黑鱼尾) polygon path.
  static Path createFishtailPath({
    required Rect columnRect,
    required double lineStridePx,
  }) {
    return pathFromPolygon(
      StationeryGeometry.buildFishtailPolygon(
        leftX: columnRect.left + 2.0,
        rightX: columnRect.right - 2.0,
        topY: columnRect.top + lineStridePx * 0.2,
        tailHeight: lineStridePx * 0.75,
      ),
    );
  }

  /// Paints the Double Outer Border (文武双栏) and conditional Fishtail Mark (版心黑鱼尾).
  static void paintFraming({
    required Canvas canvas,
    required StationeryLayoutMetrics metrics,
    required TemplateStyle style,
    double scrollOffsetY = 0.0,
  }) {
    final frame = StationeryGeometry.buildFrame(
      metrics: metrics,
      style: style,
      scrollOffsetY: scrollOffsetY,
    );
    if (!frame.drawDoubleBorder) return;

    final isDark = style.tokens.substrate == PaperSubstrate.obsidian ||
        ThemeData.estimateBrightnessForColor(style.backgroundColor) == Brightness.dark;

    final outerPaint = Paint()
      ..color = resolveBorderColor(style: style, isOuter: true)
      ..style = PaintingStyle.stroke
      ..strokeWidth = frame.outerStrokeWidth;

    final innerPaint = Paint()
      ..color = resolveBorderColor(style: style, isOuter: false)
      ..style = PaintingStyle.stroke
      ..strokeWidth = frame.innerStrokeWidth;

    // 文武双栏: Outer stroke inflated by 4.0px, inner stroke on innerFrameRect
    canvas.drawRect(frame.outerRect, outerPaint);
    canvas.drawRect(frame.innerRect, innerPaint);

    final fishtail = frame.fishtailPolygon;
    if (fishtail != null) {
      final fishtailPaint = Paint()
        ..color = resolveFishtailColor(style: style, isDark: isDark)
        ..style = PaintingStyle.fill;
      canvas.drawPath(pathFromPolygon(fishtail), fishtailPaint);
    }
  }
}
