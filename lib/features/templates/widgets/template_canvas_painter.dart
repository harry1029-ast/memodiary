import 'package:flutter/material.dart';
import '../../editor/models/typography_settings.dart';
import '../../editor/services/baseline_metrics_calculator.dart';
import '../models/template_style.dart';

/// Procedural CustomPainter rendering diary backgrounds, ruled lines, grids,
/// margins, and paper textures with baseline-locked typographic alignment.
class TemplateCanvasPainter extends CustomPainter {
  final TemplateStyle style;
  final TypographySettings? typography;
  final double scrollOffset;
  final double headerHeight;

  const TemplateCanvasPainter({
    required this.style,
    this.typography,
    this.scrollOffset = 0.0,
    this.headerHeight = 0.0,
  });

  bool get _isDark =>
      ThemeData.estimateBrightnessForColor(style.backgroundColor) == Brightness.dark;

  double get _rowHeight {
    if (typography != null) {
      return BaselineMetricsCalculator.calculateLineHeight(typography!.toTextStyle());
    }
    return 28.0 * (style.lineSpacing / 1.5).clamp(0.8, 2.5);
  }

  double get _baselineOffset {
    if (typography != null) {
      return BaselineMetricsCalculator.calculateBaselineOffset(typography!.toTextStyle());
    }
    return _rowHeight * 0.78;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Draw base canvas background
    final bgPaint = Paint()..color = style.backgroundColor;
    canvas.drawRect(rect, bgPaint);

    switch (style.type) {
      case TemplateBackgroundType.color:
        // Plain solid background
        break;

      case TemplateBackgroundType.lined:
        _paintLinedPaper(canvas, size);
        break;

      case TemplateBackgroundType.grid:
        _paintGridPaper(canvas, size);
        break;

      case TemplateBackgroundType.dotGrid:
        _paintDotGridPaper(canvas, size);
        break;

      case TemplateBackgroundType.paperTexture:
        _paintPaperTexture(canvas, size);
        break;
    }
  }

  void _paintLinedPaper(Canvas canvas, Size size) {
    final rowHeight = _rowHeight;
    final baselineOffset = _baselineOffset;

    // Horizontal notebook rules
    final linePaint = Paint()
      ..color = _isDark ? const Color(0x18FFFFFF) : const Color(0x1E4A6572)
      ..strokeWidth = 1.0;

    if (headerHeight > 0) {
      final dividerPaint = Paint()
        ..color = _isDark ? const Color(0x28FFFFFF) : const Color(0x2478909C)
        ..strokeWidth = 0.8;
      canvas.drawLine(
        Offset(0, headerHeight),
        Offset(size.width, headerHeight),
        dividerPaint,
      );
    }

    final startY = headerHeight - scrollOffset + baselineOffset;
    final int minLineIndex = startY < headerHeight
        ? ((headerHeight - startY) / rowHeight).ceil()
        : 0;

    for (int lineIndex = minLineIndex; ; lineIndex++) {
      final y = startY + lineIndex * rowHeight;
      if (y > size.height) break;
      if (y < headerHeight) continue;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Left vertical margin line (classic notebook red rule)
    final marginPaint = Paint()
      ..color = _isDark ? const Color(0x38EF9A9A) : const Color(0x33E57373)
      ..strokeWidth = 1.2;

    final marginX = style.marginHorizontal.clamp(12.0, 48.0);
    canvas.drawLine(
      Offset(marginX, headerHeight),
      Offset(marginX, size.height),
      marginPaint,
    );
  }

  void _paintGridPaper(Canvas canvas, Size size) {
    final rowHeight = _rowHeight;
    final baselineOffset = _baselineOffset;

    final hGridPaint = Paint()
      ..color = _isDark ? const Color(0x18FFFFFF) : const Color(0x1A78909C)
      ..strokeWidth = 0.8;

    final vGridPaint = Paint()
      ..color = _isDark ? const Color(0x12FFFFFF) : const Color(0x1478909C)
      ..strokeWidth = 0.6;

    if (headerHeight > 0) {
      final dividerPaint = Paint()
        ..color = _isDark ? const Color(0x28FFFFFF) : const Color(0x2478909C)
        ..strokeWidth = 0.8;
      canvas.drawLine(
        Offset(0, headerHeight),
        Offset(size.width, headerHeight),
        dividerPaint,
      );
    }

    // Vertical grid guidelines (Hobonichi style: subtle, non-intrusive)
    for (double x = 0; x < size.width; x += rowHeight) {
      canvas.drawLine(Offset(x, headerHeight), Offset(x, size.height), vGridPaint);
    }

    // Horizontal grid rules aligned to text baseline
    final startY = headerHeight - scrollOffset + baselineOffset;
    final int minLineIndex = startY < headerHeight
        ? ((headerHeight - startY) / rowHeight).ceil()
        : 0;

    for (int lineIndex = minLineIndex; ; lineIndex++) {
      final y = startY + lineIndex * rowHeight;
      if (y > size.height) break;
      if (y < headerHeight) continue;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), hGridPaint);
    }
  }

  void _paintDotGridPaper(Canvas canvas, Size size) {
    final rowHeight = _rowHeight;
    final baselineOffset = _baselineOffset;

    final dotPaint = Paint()
      ..color = _isDark ? const Color(0x24FFFFFF) : const Color(0x2878909C)
      ..style = PaintingStyle.fill;

    if (headerHeight > 0) {
      final dividerPaint = Paint()
        ..color = _isDark ? const Color(0x28FFFFFF) : const Color(0x2478909C)
        ..strokeWidth = 0.8;
      canvas.drawLine(
        Offset(0, headerHeight),
        Offset(size.width, headerHeight),
        dividerPaint,
      );
    }

    final startY = headerHeight - scrollOffset + baselineOffset;
    final int minLineIndex = startY < headerHeight
        ? ((headerHeight - startY) / rowHeight).ceil()
        : 0;

    for (int lineIndex = minLineIndex; ; lineIndex++) {
      final y = startY + lineIndex * rowHeight;
      if (y > size.height) break;
      if (y < headerHeight) continue;

      for (double x = 0; x < size.width; x += rowHeight) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  void _paintPaperTexture(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Soft vignette aging effect around borders
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.95,
        colors: const [
          Colors.transparent,
          Color(0x184E342E),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, vignettePaint);

    // 2. Procedural paper fibers & specks (deterministic pseudo-random loop)
    final fiberPaint = Paint()
      ..color = const Color(0x0C3E2723)
      ..strokeWidth = 1.0;

    const step = 45.0;
    for (double y = 10; y < size.height; y += step) {
      for (double x = 10; x < size.width; x += step) {
        final dx = ((x * 17 + y * 31) % 15) - 7;
        final dy = ((x * 23 + y * 13) % 9) - 4;
        final length = ((x * 7 + y * 11) % 12) + 3;
        canvas.drawLine(
          Offset(x + dx, y + dy),
          Offset(x + dx + length, y + dy + (dx.abs() > 4 ? 1 : 0)),
          fiberPaint,
        );
      }
    }

    // 3. Faint warm kraft guidelines aligned to baseline
    final guidePaint = Paint()
      ..color = const Color(0x148D6E63)
      ..strokeWidth = 0.9;

    final rowHeight = _rowHeight;
    final baselineOffset = _baselineOffset;
    final marginX = style.marginHorizontal;

    final startY = headerHeight - scrollOffset + baselineOffset;
    final int minLineIndex = startY < headerHeight
        ? ((headerHeight - startY) / rowHeight).ceil()
        : 0;

    for (int lineIndex = minLineIndex; ; lineIndex++) {
      final y = startY + lineIndex * rowHeight;
      if (y > size.height) break;
      if (y < headerHeight) continue;
      canvas.drawLine(
        Offset(marginX, y),
        Offset(size.width - marginX, y),
        guidePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TemplateCanvasPainter oldDelegate) {
    return oldDelegate.style.type != style.type ||
        oldDelegate.style.backgroundColor != style.backgroundColor ||
        oldDelegate.style.lineSpacing != style.lineSpacing ||
        oldDelegate.style.marginHorizontal != style.marginHorizontal ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.headerHeight != headerHeight ||
        oldDelegate.typography?.fontId != typography?.fontId ||
        oldDelegate.typography?.fontFamily != typography?.fontFamily ||
        oldDelegate.typography?.fontSize != typography?.fontSize ||
        oldDelegate.typography?.lineSpacing != typography?.lineSpacing;
  }
}
