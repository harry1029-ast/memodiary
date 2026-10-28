import 'package:flutter/material.dart';

/// CustomPainter rendering the authentic classical Chinese landscape ink wash painting
/// on the Left Folio page (太华山群峰图, 飞瀑古松, 披麻皴法, 半山云亭, 孤舟蓑笠, 太華煙雲印).
class MountHuaPaintingPainter extends CustomPainter {
  const MountHuaPaintingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Base Xuan Sky Gradient
    final bgRect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFDFD0B2),
          Color(0xFFF4ECD8),
          Color(0xFFEFE6D2),
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // 2. Faint Cinnabar Sun / Moon Halo in Distant Mist
    final haloPaint = Paint()
      ..color = const Color(0xFFB83B2E).withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(w * 0.78, h * 0.16), 26, haloPaint);

    // 3. Vertical Poetic Colophon in Top-Left Negative Space (题跋留白)
    _paintColophon(canvas, size);

    // 4. Distant Flying Ink Birds (一行归雁)
    _paintWildGeese(canvas, size);

    // 5. Far Horizon Ethereal Peaks (远景淡墨云山)
    _paintFarPeaks(canvas, size);

    // 6. Upper Valley Cloud Mist
    _paintMistBand(canvas, Rect.fromLTWH(0, h * 0.32, w, 24));

    // 7. Central Towering Mount Hua Crags (太华主峰 + 披麻皴)
    _paintCentralCrags(canvas, size);

    // 8. Cascading Ribbon Waterfall (飞瀑流泉)
    _paintWaterfall(canvas, size);

    // 9. Classical Mountain Pavilion Perched on Cliff Ledge (半山云亭)
    _paintMountainPavilion(canvas, size);

    // 10. Mid-Mountain Cloud Ribbon (腰云留白)
    _paintMistBand(canvas, Rect.fromLTWH(0, h * 0.54, w, 28));

    // 11. Foreground Clustered Dark-Ink Crags & Pine Tree (前景焦墨奇峰与古松)
    _paintForegroundCragsAndPine(canvas, size);

    // 12. Bottom-Left River Cove & Lone Fisherman Skiff (寒江独钓)
    _paintRiverAndSkiff(canvas, size);

    // 13. Bottom-Left Cinnabar Red Square Seal Stamp: 太華煙雲
    _paintCinnabarSeal(canvas, size);
  }

  void _paintColophon(Canvas canvas, Size size) {
    const textStyle1 = TextStyle(
      fontSize: 8.5,
      fontWeight: FontWeight.w500,
      color: Color(0xFF2B2620),
      letterSpacing: 2.0,
      fontFamily: 'Noto Serif SC',
    );
    const textStyle2 = TextStyle(
      fontSize: 7.5,
      fontWeight: FontWeight.w400,
      color: Color(0xFF4A4237),
      letterSpacing: 1.5,
      fontFamily: 'Noto Serif SC',
    );

    // Line 1: 太華千尋拔地起
    _drawVerticalText(canvas, '太華千尋拔地起', textStyle1, size.width * 0.10, size.height * 0.08);

    // Line 2: 一卷私語一卷山河
    _drawVerticalText(canvas, '一卷私語一卷山河', textStyle2, size.width * 0.17, size.height * 0.11);
  }

  void _drawVerticalText(Canvas canvas, String text, TextStyle style, double x, double startY) {
    double curY = startY;
    for (final ch in text.split('')) {
      final tp = TextPainter(
        text: TextSpan(text: ch, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x, curY));
      curY += tp.height + 2.0;
    }
  }

  void _paintWildGeese(Canvas canvas, Size size) {
    final birdPaint = Paint()
      ..color = const Color(0xFF2C302B).withValues(alpha: 0.65)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    final birds = [
      Offset(size.width * 0.55, size.height * 0.14),
      Offset(size.width * 0.62, size.height * 0.12),
      Offset(size.width * 0.51, size.height * 0.17),
    ];

    for (final pt in birds) {
      final p = Path()
        ..moveTo(pt.dx - 4, pt.dy + 2)
        ..quadraticBezierTo(pt.dx - 2, pt.dy - 2, pt.dx, pt.dy + 1)
        ..quadraticBezierTo(pt.dx + 2, pt.dy - 2, pt.dx + 4, pt.dy + 2);
      canvas.drawPath(p, birdPaint);
    }
  }

  void _paintFarPeaks(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(0, h * 0.40)
      ..cubicTo(w * 0.10, h * 0.36, w * 0.18, h * 0.25, w * 0.28, h * 0.23)
      ..cubicTo(w * 0.38, h * 0.22, w * 0.44, h * 0.32, w * 0.54, h * 0.29)
      ..cubicTo(w * 0.64, h * 0.26, w * 0.72, h * 0.15, w * 0.82, h * 0.15)
      ..cubicTo(w * 0.90, h * 0.15, w * 0.96, h * 0.26, w, h * 0.20)
      ..lineTo(w, h * 0.60)
      ..lineTo(0, h * 0.60)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF5D6960).withValues(alpha: 0.46),
          const Color(0xFF8A948A).withValues(alpha: 0.22),
          const Color(0xFFF3EBD9).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.15, w, h * 0.45));

    canvas.drawPath(path, paint);
  }

  void _paintCentralCrags(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final mainPeak = Path()
      ..moveTo(0, h * 0.58)
      ..cubicTo(w * 0.12, h * 0.48, w * 0.20, h * 0.32, w * 0.30, h * 0.28)
      ..cubicTo(w * 0.40, h * 0.24, w * 0.46, h * 0.38, w * 0.56, h * 0.33)
      ..cubicTo(w * 0.64, h * 0.28, w * 0.72, h * 0.19, w * 0.80, h * 0.21)
      ..cubicTo(w * 0.88, h * 0.23, w * 0.94, h * 0.39, w, h * 0.35)
      ..lineTo(w, h * 0.75)
      ..lineTo(0, h * 0.75)
      ..close();

    final peakPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF283A33).withValues(alpha: 0.88),
          const Color(0xFF3F5D50).withValues(alpha: 0.72),
          const Color(0xFF6D8273).withValues(alpha: 0.35),
          const Color(0xFFF3EBD9).withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.19, w, h * 0.55));

    canvas.drawPath(mainPeak, peakPaint);

    // Hemp-Fiber Brush Strokes (披麻皴法肌理线)
    final texturePaint = Paint()
      ..color = const Color(0xFF1E2B25).withValues(alpha: 0.40)
      ..strokeWidth = 0.65
      ..style = PaintingStyle.stroke;

    final textures = [
      Path()..moveTo(w * 0.30, h * 0.29)..cubicTo(w * 0.28, h * 0.38, w * 0.24, h * 0.45, w * 0.20, h * 0.52),
      Path()..moveTo(w * 0.32, h * 0.31)..cubicTo(w * 0.31, h * 0.40, w * 0.29, h * 0.47, w * 0.26, h * 0.54),
      Path()..moveTo(w * 0.78, h * 0.23)..cubicTo(w * 0.75, h * 0.33, w * 0.71, h * 0.42, w * 0.66, h * 0.50),
      Path()..moveTo(w * 0.81, h * 0.24)..cubicTo(w * 0.80, h * 0.34, w * 0.77, h * 0.44, w * 0.74, h * 0.52),
      Path()..moveTo(w * 0.56, h * 0.34)..cubicTo(w * 0.53, h * 0.41, w * 0.50, h * 0.47, w * 0.46, h * 0.53),
    ];

    for (final p in textures) {
      canvas.drawPath(p, texturePaint);
    }
  }

  void _paintWaterfall(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fallPath = Path()
      ..moveTo(w * 0.53, h * 0.39)
      ..quadraticBezierTo(w * 0.55, h * 0.47, w * 0.53, h * 0.55)
      ..quadraticBezierTo(w * 0.51, h * 0.63, w * 0.54, h * 0.71);

    final fallWhite = Paint()
      ..color = const Color(0xFFF5EFE0).withValues(alpha: 0.80)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    final fallShadow = Paint()
      ..color = const Color(0xFF3F5D50).withValues(alpha: 0.55)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    canvas.drawPath(fallPath, fallWhite);
    canvas.drawPath(fallPath, fallShadow);
  }

  void _paintMountainPavilion(Canvas canvas, Size size) {
    final px = size.width * 0.72;
    final py = size.height * 0.37;

    final paint = Paint()
      ..color = const Color(0xFF1D211E).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = const Color(0xFF1D211E).withValues(alpha: 0.85)
      ..strokeWidth = 0.9;

    // Roof eave
    final roof = Path()
      ..moveTo(px - 3, py + 4)
      ..quadraticBezierTo(px + 6, py - 1, px + 15, py + 4)
      ..lineTo(px + 12, py + 5)
      ..lineTo(px, py + 5)
      ..close();
    canvas.drawPath(roof, paint);

    // Columns
    canvas.drawLine(Offset(px + 2, py + 5), Offset(px + 2, py + 12), line);
    canvas.drawLine(Offset(px + 10, py + 5), Offset(px + 10, py + 12), line);

    // Base
    canvas.drawLine(Offset(px - 1, py + 12), Offset(px + 13, py + 12), line..strokeWidth = 1.2);
  }

  void _paintForegroundCragsAndPine(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layer 3: Dark Ink Crags (焦墨攒簇奇峰)
    final forePath = Path()
      ..moveTo(0, h * 0.74)
      ..cubicTo(w * 0.10, h * 0.66, w * 0.18, h * 0.51, w * 0.28, h * 0.49)
      ..cubicTo(w * 0.38, h * 0.48, w * 0.44, h * 0.62, w * 0.54, h * 0.59)
      ..cubicTo(w * 0.64, h * 0.56, w * 0.72, h * 0.44, w * 0.82, h * 0.46)
      ..cubicTo(w * 0.92, h * 0.48, w * 0.98, h * 0.62, w, h * 0.58)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final forePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF141916).withValues(alpha: 0.96),
          const Color(0xFF243830).withValues(alpha: 0.90),
          const Color(0xFF465E51).withValues(alpha: 0.72),
          const Color(0xFFB0A184).withValues(alpha: 0.25),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.44, w, h * 0.56));

    canvas.drawPath(forePath, forePaint);

    // Textured Moss Dots (米点皴 / 苔点)
    final dotPaint = Paint()..color = const Color(0xFF111613).withValues(alpha: 0.75);
    final dotPoints = [
      Offset(w * 0.26, h * 0.48),
      Offset(w * 0.29, h * 0.47),
      Offset(w * 0.31, h * 0.49),
      Offset(w * 0.52, h * 0.58),
      Offset(w * 0.55, h * 0.57),
      Offset(w * 0.80, h * 0.45),
      Offset(w * 0.83, h * 0.44),
    ];
    for (final pt in dotPoints) {
      canvas.drawOval(Rect.fromCenter(center: pt, width: 3.5, height: 1.8), dotPaint);
    }

    // Gnarled Cliffside Ink Pine Tree (悬崖古松)
    final pinePaint = Paint()
      ..color = const Color(0xFF121614)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final trunk = Path()
      ..moveTo(0, h * 0.73)
      ..quadraticBezierTo(w * 0.10, h * 0.70, w * 0.16, h * 0.66)
      ..quadraticBezierTo(w * 0.20, h * 0.64, w * 0.25, h * 0.64);
    canvas.drawPath(trunk, pinePaint);

    final branch = Path()
      ..moveTo(w * 0.13, h * 0.68)
      ..quadraticBezierTo(w * 0.17, h * 0.64, w * 0.22, h * 0.63);
    canvas.drawPath(branch, pinePaint..strokeWidth = 1.1);

    // Pine Needle Clusters
    final needlePaint = Paint()..color = const Color(0xFF182620);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.25, h * 0.63), width: 16, height: 7),
      needlePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.20, h * 0.61), width: 14, height: 6),
      Paint()..color = const Color(0xFF1F332B),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.27, h * 0.66), width: 13, height: 5.5),
      needlePaint,
    );
  }

  void _paintRiverAndSkiff(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Misty River Cove at Bottom Left
    final river = Path()
      ..moveTo(0, h * 0.81)
      ..quadraticBezierTo(w * 0.25, h * 0.83, w * 0.45, h * 0.91)
      ..quadraticBezierTo(w * 0.65, h * 0.98, w * 0.78, h)
      ..lineTo(0, h)
      ..close();

    final riverPaint = Paint()..color = const Color(0xFFEFE6D2).withValues(alpha: 0.92);
    canvas.drawPath(river, riverPaint);

    // Gentle Water Ripple Lines
    final rip = Paint()
      ..color = const Color(0xFF5C665E).withValues(alpha: 0.50)
      ..strokeWidth = 0.6;
    canvas.drawLine(Offset(w * 0.10, h * 0.87), Offset(w * 0.24, h * 0.87), rip);
    canvas.drawLine(Offset(w * 0.18, h * 0.90), Offset(w * 0.35, h * 0.90), rip);

    // Lone Fisherman Skiff (孤舟蓑笠翁)
    final sx = w * 0.24;
    final sy = h * 0.88;
    final skiffPaint = Paint()..color = const Color(0xFF1A1E1B);

    final boat = Path()
      ..moveTo(sx, sy + 3)
      ..quadraticBezierTo(sx + 8, sy + 6, sx + 18, sy + 2)
      ..lineTo(sx + 15, sy + 5)
      ..lineTo(sx + 2, sy + 5)
      ..close();
    canvas.drawPath(boat, skiffPaint);

    // Fisherman
    canvas.drawRect(Rect.fromLTWH(sx + 7, sy, 4, 3), Paint()..color = const Color(0xFF3B4A43));
    canvas.drawLine(Offset(sx + 11, sy + 2), Offset(sx + 16, sy + 4.5), rip..strokeWidth = 0.6);
  }

  void _paintMistBand(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFF5EFE0).withValues(alpha: 0.0),
          const Color(0xFFF5EFE0).withValues(alpha: 0.82),
          const Color(0xFFF5EFE0).withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _paintCinnabarSeal(Canvas canvas, Size size) {
    final sx = size.width * 0.07;
    final sy = size.height * 0.87;
    const sealSize = 25.0;

    final outerRect = Rect.fromLTWH(sx, sy, sealSize, sealSize);

    // Outer Cinnabar Border
    final outerBorder = Paint()
      ..color = const Color(0xFFB83B2E)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(outerRect, outerBorder);

    // Inner Cinnabar Border
    final innerRect = outerRect.deflate(2.0);
    final innerBorder = Paint()
      ..color = const Color(0xFFB83B2E).withValues(alpha: 0.75)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    canvas.drawRect(innerRect, innerBorder);

    // Background Tint
    canvas.drawRect(
      innerRect,
      Paint()..color = const Color(0xFFEFE6D2).withValues(alpha: 0.95),
    );

    // Seal Characters: 太華 / 煙雲
    const sealStyle = TextStyle(
      fontSize: 6.5,
      fontWeight: FontWeight.w700,
      color: Color(0xFFB83B2E),
      height: 1.05,
      letterSpacing: -0.5,
      fontFamily: 'Noto Serif SC',
    );

    final tp1 = TextPainter(
      text: const TextSpan(text: '太華\n煙雲', style: sealStyle),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    tp1.paint(
      canvas,
      Offset(
        outerRect.center.dx - tp1.width / 2,
        outerRect.center.dy - tp1.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant MountHuaPaintingPainter oldDelegate) => false;
}

