import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders 3 authentic fan-spread classical stationery sheets (松烟夜墨, 冷金洒金, 朱丝栏宣纸).
/// Separated into a modular file to respect file length limits (< 450 LOC).
class FanSpreadStationeryPainter extends CustomPainter {
  final double fanProgress;

  FanSpreadStationeryPainter({required this.fanProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width * 0.5;
    final bottomY = size.height * 0.90;
    final sheetWidth = size.width * 0.64;
    final sheetHeight = size.height * 0.72;

    // Sheet 3 (Back): Night Ink Sheet (松烟夜墨)
    canvas.save();
    canvas.translate(centerX, bottomY);
    canvas.rotate((-10 - 12 * fanProgress) * math.pi / 180);
    canvas.translate(-centerX - 5 * fanProgress, -bottomY - 4 * fanProgress);
    final backRect = Rect.fromCenter(
      center: Offset(centerX, size.height * 0.48),
      width: sheetWidth,
      height: sheetHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(backRect, const Radius.circular(5)),
      Paint()..color = const Color(0xFF23272B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(backRect, const Radius.circular(5)),
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.restore();

    // Sheet 2 (Middle): Cold Gold-Flecked Parchment (冷金宣笺)
    canvas.save();
    canvas.translate(centerX, bottomY);
    canvas.rotate((-2 - 2 * fanProgress) * math.pi / 180);
    canvas.translate(-centerX, -bottomY - 6 * fanProgress);
    final midRect = Rect.fromCenter(
      center: Offset(centerX, size.height * 0.48),
      width: sheetWidth,
      height: sheetHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(midRect, const Radius.circular(5)),
      Paint()..color = const Color(0xFFF3E6CE),
    );
    // Gold specks
    final speckPaint = Paint()..color = const Color(0xFFC89D32);
    canvas.drawCircle(Offset(midRect.left + 10, midRect.top + 16), 1.6, speckPaint);
    canvas.drawCircle(Offset(midRect.right - 12, midRect.top + 28), 1.4, speckPaint);
    canvas.drawCircle(Offset(midRect.left + 20, midRect.bottom - 24), 1.8, speckPaint);
    canvas.restore();

    // Sheet 1 (Front): Cinnabar Vermilion-Ruled Xuan Paper (朱丝栏宣纸)
    canvas.save();
    canvas.translate(centerX, bottomY);
    canvas.rotate((8 + 12 * fanProgress) * math.pi / 180);
    canvas.translate(-centerX + 5 * fanProgress, -bottomY - 5 * fanProgress);
    final frontRect = Rect.fromCenter(
      center: Offset(centerX, size.height * 0.50),
      width: sheetWidth,
      height: sheetHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frontRect, const Radius.circular(5)),
      Paint()..color = const Color(0xFFFAF7F2),
    );
    // Cinnabar outer border & vertical columns
    final vermilionPaint = Paint()
      ..color = const Color(0xFFB83B2E).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final innerRect = frontRect.deflate(5);
    canvas.drawRect(innerRect, vermilionPaint);
    for (int colIndex = 1; colIndex <= 3; colIndex++) {
      final lineX = innerRect.left + (innerRect.width / 4) * colIndex;
      canvas.drawLine(
        Offset(lineX, innerRect.top),
        Offset(lineX, innerRect.bottom),
        vermilionPaint,
      );
    }
    // Red seal stamp on front sheet
    canvas.drawRect(
      Rect.fromLTWH(innerRect.right - 10, innerRect.bottom - 12, 7, 7),
      Paint()..color = const Color(0xFFB83B2E),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FanSpreadStationeryPainter oldDelegate) =>
      oldDelegate.fanProgress != fanProgress;
}
