import 'package:flutter/material.dart';
import '../models/template_style.dart';

/// Renders lightweight, full-bleed thumbnail patterns for template cards and selectors.
///
/// Thumbnail Contract:
/// - Small viewports (< 160px) bypass full-screen manuscript framing and heavy margins.
/// - Renders clear, recognizable visual textures: horizontal notebook rules, orthogonal grid,
///   dot matrix, kraft paper texture, and clean solid substrates.
class TemplateThumbnailPainter {
  const TemplateThumbnailPainter._();

  /// Paints the thumbnail pattern for the specified [TemplateStyle].
  static void paintPattern({
    required Canvas canvas,
    required Size size,
    required TemplateStyle style,
    required bool isDark,
  }) {
    switch (style.type) {
      case TemplateBackgroundType.color:
        // Plain solid substrate paper without miniature frame
        break;

      case TemplateBackgroundType.lined:
        final linePaint = Paint()
          ..color = isDark
              ? const Color(0x28FFFFFF)
              : (style.tokens.ruleTint == RuleInkTint.vermilion
                  ? const Color(0x40C04851)
                  : const Color(0x334A6572))
          ..strokeWidth = 1.0;

        final marginPaint = Paint()
          ..color = isDark ? const Color(0x38EF9A9A) : const Color(0x38E57373)
          ..strokeWidth = 1.0;

        const lineStep = 14.0;
        for (double y = lineStep; y < size.height - 4.0; y += lineStep) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
        }

        final marginX = (size.width * 0.22).clamp(16.0, 24.0);
        canvas.drawLine(Offset(marginX, 0), Offset(marginX, size.height), marginPaint);
        break;

      case TemplateBackgroundType.grid:
        final gridPaint = Paint()
          ..color = isDark
              ? const Color(0x24FFFFFF)
              : (style.tokens.ruleTint == RuleInkTint.vermilion
                  ? const Color(0x33C04851)
                  : const Color(0x2E78909C))
          ..strokeWidth = 0.8;

        const gridStep = 13.0;
        for (double x = gridStep; x < size.width; x += gridStep) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
        }
        for (double y = gridStep; y < size.height; y += gridStep) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
        }
        break;

      case TemplateBackgroundType.dotGrid:
        final dotPaint = Paint()
          ..color = isDark
              ? const Color(0x38FFFFFF)
              : (style.tokens.ruleTint == RuleInkTint.vermilion
                  ? const Color(0x4DC04851)
                  : const Color(0x4078909C))
          ..style = PaintingStyle.fill;

        const dotStep = 13.0;
        for (double y = dotStep; y < size.height; y += dotStep) {
          for (double x = dotStep; x < size.width; x += dotStep) {
            canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
          }
        }
        break;

      case TemplateBackgroundType.paperTexture:
        final guidePaint = Paint()
          ..color = const Color(0x1F8D6E63)
          ..strokeWidth = 0.9;
        const kraftStep = 14.0;
        for (double y = kraftStep; y < size.height - 4.0; y += kraftStep) {
          canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), guidePaint);
        }
        break;
    }
  }
}
