import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Draws the miniature welcoming pine bonsai (`迎客松盆景`).
class PineBonsaiPainter extends CustomPainter {
  const PineBonsaiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 54.0;
    final sy = size.height / 52.0;
    canvas.save();
    canvas.scale(sx, sy);

    final potPath = Path()
      ..moveTo(12, 39)
      ..lineTo(42, 39)
      ..lineTo(38, 49)
      ..lineTo(16, 49)
      ..close();
    canvas.drawPath(potPath, Paint()..color = const Color(0xFF3B4D47));
    canvas.drawPath(
      potPath,
      Paint()
        ..color = const Color(0xFF6B877E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(10, 37, 34, 3), const Radius.circular(1)),
      Paint()..color = const Color(0xFF4E665E),
    );

    final trunkPaint = Paint()
      ..color = const Color(0xFF4A3222)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final trunk = Path()
      ..moveTo(26, 37)
      ..quadraticBezierTo(22, 28, 28, 21)
      ..quadraticBezierTo(33, 16, 39, 17);
    canvas.drawPath(trunk, trunkPaint);

    final branch = Path()
      ..moveTo(25, 27)
      ..quadraticBezierTo(18, 24, 14, 26);
    canvas.drawPath(branch, trunkPaint..strokeWidth = 2.2);

    canvas.drawOval(Rect.fromCenter(center: const Offset(14, 24), width: 16, height: 8), Paint()..color = const Color(0xFF2D5A3C));
    canvas.drawOval(Rect.fromCenter(center: const Offset(27, 16), width: 20, height: 9), Paint()..color = const Color(0xFF366B48));
    canvas.drawOval(Rect.fromCenter(center: const Offset(39, 15), width: 18, height: 8), Paint()..color = const Color(0xFF2D5A3C));
    canvas.drawOval(Rect.fromCenter(center: const Offset(31, 13), width: 14, height: 6), Paint()..color = const Color(0xFF468259));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PineBonsaiPainter oldDelegate) => false;
}

/// Draws the wooden calligraphy brush stand (`笔架搁毫`).
class BrushStandPainter extends CustomPainter {
  const BrushStandPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 42.0;
    final sy = size.height / 46.0;
    canvas.save();
    canvas.scale(sx, sy);

    final baseRect = RRect.fromRectAndRadius(const Rect.fromLTWH(4, 41, 34, 3.5), const Radius.circular(1));
    canvas.drawRRect(baseRect, Paint()..color = const Color(0xFF2A1B12));
    canvas.drawRRect(
      baseRect,
      Paint()
        ..color = const Color(0xFF6E4B32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );

    final pillarPaint = Paint()
      ..color = const Color(0xFF4A301F)
      ..strokeWidth = 2.2;
    canvas.drawLine(const Offset(9, 7), const Offset(9, 41), pillarPaint);
    canvas.drawLine(const Offset(33, 7), const Offset(33, 41), pillarPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(5, 5, 32, 3), const Radius.circular(1)),
      Paint()..color = const Color(0xFF5C3D28),
    );

    // Left ivory-tipped brush
    canvas.drawLine(
      const Offset(16, 8),
      const Offset(16, 27),
      Paint()
        ..color = const Color(0xFFA68254)
        ..strokeWidth = 1.8,
    );
    final tipLeft = Path()
      ..moveTo(14.3, 27)
      ..quadraticBezierTo(16, 35, 17.7, 27)
      ..close();
    canvas.drawPath(tipLeft, Paint()..color = const Color(0xFFF0ECE3));

    // Right cinnabar-tipped brush
    canvas.drawLine(
      const Offset(25, 8),
      const Offset(25, 29),
      Paint()
        ..color = const Color(0xFF735334)
        ..strokeWidth = 1.8,
    );
    final tipRight = Path()
      ..moveTo(23.3, 29)
      ..quadraticBezierTo(25, 37, 26.7, 29)
      ..close();
    canvas.drawPath(tipRight, Paint()..color = const Color(0xFFD25447));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BrushStandPainter oldDelegate) => false;
}

/// Draws the interactive brass candlestick (`黄铜烛台`) with optional flickering flame.
class BrassCandlestickPainter extends CustomPainter {
  final bool isLit;
  final double flickerPhase;

  const BrassCandlestickPainter({
    required this.isLit,
    required this.flickerPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 28.0;
    final sy = size.height / 48.0;
    canvas.save();
    canvas.scale(sx, sy);

    if (isLit) {
      final pulse = math.sin(flickerPhase * math.pi * 2);
      final scaleX = 1.0 + 0.08 * pulse;
      final scaleY = 1.0 - 0.06 * pulse;
      final lift = -0.6 * pulse;

      canvas.save();
      canvas.translate(14, 15 + lift);
      canvas.scale(scaleX, scaleY);
      canvas.translate(-14, -15);

      canvas.drawCircle(
        const Offset(14, 10),
        8,
        Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.36 + 0.06 * pulse),
      );
      final outerFlame = Path()
        ..moveTo(14, 2)
        ..quadraticBezierTo(18, 9, 14, 15)
        ..quadraticBezierTo(10, 9, 14, 2)
        ..close();
      canvas.drawPath(outerFlame, Paint()..color = const Color(0xFFFDE047));

      final innerFlame = Path()
        ..moveTo(14, 6)
        ..quadraticBezierTo(16, 10, 14, 14)
        ..quadraticBezierTo(12, 10, 14, 6)
        ..close();
      canvas.drawPath(innerFlame, Paint()..color = const Color(0xFFFFFBEB));
      canvas.restore();
    }

    // Candle stick
    final candleRect = RRect.fromRectAndRadius(const Rect.fromLTWH(11.5, 15, 5, 14), const Radius.circular(1));
    canvas.drawRRect(candleRect, Paint()..color = const Color(0xFFF5E6C8));
    canvas.drawRRect(
      candleRect,
      Paint()
        ..color = const Color(0xFFD4BC8B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    // Brass drip pan, stem, and pedestal
    canvas.drawOval(Rect.fromCenter(center: const Offset(14, 30), width: 14, height: 4), Paint()..color = const Color(0xFFD4AF37));
    canvas.drawLine(
      const Offset(14, 30),
      const Offset(14, 42),
      Paint()
        ..color = const Color(0xFFC8A96E)
        ..strokeWidth = 2.5,
    );
    final basePath = Path()
      ..moveTo(7, 45)
      ..lineTo(21, 45)
      ..lineTo(18, 41)
      ..lineTo(10, 41)
      ..close();
    canvas.drawPath(basePath, Paint()..color = const Color(0xFFB5924C));
    canvas.drawPath(
      basePath,
      Paint()
        ..color = const Color(0xFFE6C983)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BrassCandlestickPainter oldDelegate) =>
      oldDelegate.isLit != isLit || oldDelegate.flickerPhase != flickerPhase;
}

/// Draws the celadon incense burner (`青瓷香炉`) with gentle rising smoke wisps.
class CeladonIncensePainter extends CustomPainter {
  final double smokePhase;

  const CeladonIncensePainter({required this.smokePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 32.0;
    final sy = size.height / 32.0;
    canvas.save();
    canvas.scale(sx, sy);

    final sway = math.sin(smokePhase * math.pi * 2) * 1.6;
    final smokeAlpha = 0.25 + 0.35 * (0.5 + 0.5 * math.sin(smokePhase * math.pi * 2));
    final smokePaint = Paint()
      ..color = const Color(0xFFD8D2C5).withValues(alpha: smokeAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final wisp1 = Path()
      ..moveTo(13, 14)
      ..quadraticBezierTo(10 + sway, 8, 15 - sway * 0.5, 3);
    final wisp2 = Path()
      ..moveTo(19, 14)
      ..quadraticBezierTo(22 - sway, 9, 17 + sway * 0.5, 4);
    canvas.drawPath(wisp1, smokePaint);
    canvas.drawPath(wisp2, smokePaint..strokeWidth = 1.0);

    // Celadon tripod bowl
    final rimRect = Rect.fromCenter(center: const Offset(16, 17), width: 18, height: 7);
    canvas.drawOval(rimRect, Paint()..color = const Color(0xFF5E7E73));
    canvas.drawOval(
      rimRect,
      Paint()
        ..color = const Color(0xFF88ABA0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    final bodyPath = Path()
      ..moveTo(7, 17)
      ..quadraticBezierTo(7, 26, 16, 26)
      ..quadraticBezierTo(25, 26, 25, 17)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = const Color(0xFF49665C));
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFF76998D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    final legPaint = Paint()
      ..color = const Color(0xFF395249)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(10, 25), const Offset(9, 29), legPaint);
    canvas.drawLine(const Offset(16, 26), const Offset(16, 30), legPaint);
    canvas.drawLine(const Offset(22, 25), const Offset(23, 29), legPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CeladonIncensePainter oldDelegate) =>
      oldDelegate.smokePhase != smokePhase;
}

/// Draws the left & right brass corner brackets (`铜包角`) on the carved sill lip.
class BrassCornerBracketsPainter extends CustomPainter {
  final Color brassColor;

  const BrassCornerBracketsPainter({required this.brassColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = brassColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.square;

    const insetX = 8.0;
    const bracketWidth = 16.0;
    final topY = 2.0;
    final bottomY = size.height - 2.0;

    final leftBracket = Path()
      ..moveTo(insetX, bottomY)
      ..lineTo(insetX, topY)
      ..lineTo(insetX + bracketWidth, topY);
    canvas.drawPath(leftBracket, paint);

    final rightX = size.width - insetX;
    final rightBracket = Path()
      ..moveTo(rightX, bottomY)
      ..lineTo(rightX, topY)
      ..lineTo(rightX - bracketWidth, topY);
    canvas.drawPath(rightBracket, paint);
  }

  @override
  bool shouldRepaint(covariant BrassCornerBracketsPainter oldDelegate) =>
      oldDelegate.brassColor != brassColor;
}
