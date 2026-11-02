import 'package:flutter/material.dart';

/// Renders the diagonal-ribbed crimson silk velvet bed inside the Scholar's Chest.
/// Separated into a modular file to respect file length limits (< 450 LOC).
class CrimsonVelvetBedPainter extends CustomPainter {
  const CrimsonVelvetBedPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final backgroundPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, -0.3),
        radius: 1.1,
        colors: [
          Color(0xFFA81C22),
          Color(0xFF7C1016),
          Color(0xFF4F070B),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    final ribPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..strokeWidth = 4.5;
    for (double xOffset = -size.height;
        xOffset < size.width + size.height;
        xOffset += 14) {
      canvas.drawLine(
        Offset(xOffset, 0),
        Offset(xOffset + size.height * 0.7, size.height),
        ribPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
