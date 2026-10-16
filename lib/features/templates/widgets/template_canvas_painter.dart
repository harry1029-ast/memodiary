import 'package:flutter/material.dart';
import '../models/template_style.dart';

/// Procedural CustomPainter rendering diary backgrounds, ruled lines, grids,
/// margins, and paper textures at zero runtime asset cost.
class TemplateCanvasPainter extends CustomPainter {
  final TemplateStyle style;

  const TemplateCanvasPainter({required this.style});

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

      case TemplateBackgroundType.paperTexture:
        _paintPaperTexture(canvas, size);
        break;
    }
  }

  void _paintLinedPaper(Canvas canvas, Size size) {
    final rowHeight = 28.0 * (style.lineSpacing / 1.5).clamp(0.8, 2.5);

    // Horizontal notebook rules
    final linePaint = Paint()
      ..color = const Color(0x224A6572)
      ..strokeWidth = 1.0;

    for (double y = 40.0; y < size.height; y += rowHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Left vertical margin line (classic notebook red rule)
    final marginPaint = Paint()
      ..color = const Color(0x33E57373)
      ..strokeWidth = 1.2;

    final marginX = style.marginHorizontal.clamp(12.0, 48.0);
    canvas.drawLine(Offset(marginX, 0), Offset(marginX, size.height), marginPaint);
  }

  void _paintGridPaper(Canvas canvas, Size size) {
    final gridSize = 24.0 * (style.lineSpacing / 1.5).clamp(0.8, 2.0);

    final gridPaint = Paint()
      ..color = const Color(0x1F78909C)
      ..strokeWidth = 0.8;

    // Vertical grid lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Horizontal grid lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
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

    // Draw deterministic subtle fibers
    final step = 45.0;
    for (double y = 10; y < size.height; y += step) {
      for (double x = 10; x < size.width; x += step) {
        // Deterministic offset based on coordinates
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

    // 3. Faint warm kraft guidelines
    final guidePaint = Paint()
      ..color = const Color(0x148D6E63)
      ..strokeWidth = 0.9;

    final rowHeight = 32.0 * (style.lineSpacing / 1.5).clamp(0.8, 2.5);
    final marginX = style.marginHorizontal;
    for (double y = 40.0; y < size.height; y += rowHeight) {
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
        oldDelegate.style.marginHorizontal != style.marginHorizontal;
  }
}

