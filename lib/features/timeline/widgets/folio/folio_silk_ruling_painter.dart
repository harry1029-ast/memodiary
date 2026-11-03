import 'package:flutter/material.dart';
import 'folio_reading_perspective.dart';

/// Paints the integer-locked Paper Heart frame (320px x 448px) with a classical
/// Double Outer Border (文武双栏), conditional Fishtail Mark (版心黑鱼尾),
/// and ruling lines corresponding to [FolioRulingLayout].
class FolioSilkRulingPainter extends CustomPainter {
  /// The ruling geometry (horizontal rules, vermilion vertical columns, or genkō grid).
  final FolioRulingLayout layout;

  /// Primary color for vertical/horizontal ruling lines.
  final Color ruleColor;

  /// Outer and inner border frame color.
  final Color frameColor;

  /// Whether the substrate is dark (e.g. Obsidian Night).
  final bool isDark;

  /// Whether to paint the classical woodblock Fishtail Mark (版心黑鱼尾).
  final bool showFishtail;

  const FolioSilkRulingPainter({
    required this.layout,
    required this.ruleColor,
    required this.frameColor,
    this.isDark = false,
    bool? showFishtail,
  }) : showFishtail = showFishtail ?? (layout == FolioRulingLayout.genkoVertical);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Classical Double Outer Border (文武双栏: outer 2.0px, inner 0.8px, gap 3.0px)
    final outerFramePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final innerFramePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawRect(rect.inflate(3.0), outerFramePaint);
    canvas.drawRect(rect, innerFramePaint);

    // 2. Conditional Fishtail Mark (版心黑鱼尾)
    if (showFishtail) {
      _paintFishtailMark(canvas, size);
    }

    // 3. Ruling Lines
    final rulePaint = Paint()
      ..color = ruleColor
      ..strokeWidth = 1.0;

    switch (layout) {
      case FolioRulingLayout.vermilionVertical:
        // 10 vertical columns (32px width each across 320px)
        for (int column = 1; column < 10; column++) {
          final x = column * 32.0;
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), rulePaint);
        }

      case FolioRulingLayout.genkoVertical:
        // 10 vertical columns x 16 rows (160 square grid cells, 32px x 28px)
        for (int column = 1; column < 10; column++) {
          final x = column * 32.0;
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), rulePaint);
        }
        final cellPaint = Paint()
          ..color = ruleColor.withValues(alpha: 0.38)
          ..strokeWidth = 0.8;
        for (int row = 1; row < 16; row++) {
          final y = row * 28.0;
          canvas.drawLine(Offset(0, y), Offset(size.width, y), cellPaint);
        }

      case FolioRulingLayout.faithfulHorizontal:
        // 14 horizontal ruled lines (32px height each across 448px)
        for (int row = 1; row < 14; row++) {
          final y = row * 32.0;
          canvas.drawLine(Offset(0, y), Offset(size.width, y), rulePaint);
        }

        // Left red vertical margin rule
        final marginPaint = Paint()
          ..color = isDark ? const Color(0x38EF9A9A) : const Color(0x52C04851)
          ..strokeWidth = 1.2;
        canvas.drawLine(const Offset(24.0, 0), Offset(24.0, size.height), marginPaint);
    }
  }

  void _paintFishtailMark(Canvas canvas, Size size) {
    final midX = size.width / 2;
    final leftX = midX - 14.0;
    final rightX = midX + 14.0;
    const topY = 2.0;
    const tailHeight = 18.0;
    const bottomY = topY + tailHeight;

    final fishtailPath = Path()
      ..moveTo(leftX, topY)
      ..lineTo(midX, topY + tailHeight * 0.45)
      ..lineTo(rightX, topY)
      ..lineTo(rightX, bottomY - tailHeight * 0.15)
      ..lineTo(midX, bottomY)
      ..lineTo(leftX, bottomY - tailHeight * 0.15)
      ..close();

    final fishtailPaint = Paint()
      ..color = isDark ? const Color(0x4AFFFFFF) : frameColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fishtailPath, fishtailPaint);
  }

  @override
  bool shouldRepaint(covariant FolioSilkRulingPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.ruleColor != ruleColor ||
        oldDelegate.frameColor != frameColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.showFishtail != showFishtail;
  }
}

