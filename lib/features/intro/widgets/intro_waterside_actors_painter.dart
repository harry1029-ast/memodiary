import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/intro_sky_atmosphere.dart';

/// Helper painting mid-ground waterside pavilions, wooden bridge, golden water
/// reflection pillars, overhanging branches, swaying palace lanterns, and fireflies.
class IntroWatersideActorsPainter {
  const IntroWatersideActorsPainter._();

  static void paintPavilionsAndBridge(
    Canvas canvas,
    Size size,
    InterpolatedIntroSky sky,
  ) {
    final sx = size.width / 400.0;
    final sy = size.height / 812.0;
    canvas.save();
    canvas.scale(sx, sy);

    final nearPaint = Paint()..color = sky.nearMountain;
    final midPaint = Paint()..color = sky.midMountain;

    // 1. Flanking Rocky Promontories
    canvas.drawPath(
      Path()
        ..moveTo(0, 258)..lineTo(0, 224)
        ..quadraticBezierTo(38, 212, 76, 232)..quadraticBezierTo(104, 244, 122, 254)
        ..quadraticBezierTo(65, 260, 0, 258)..close(),
      nearPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(400, 256)..lineTo(400, 218)
        ..quadraticBezierTo(358, 208, 320, 230)..quadraticBezierTo(290, 244, 270, 252)
        ..quadraticBezierTo(335, 258, 400, 256)..close(),
      nearPaint,
    );

    // 2. Left Multi-Tiered Waterside Pavilion (临水飞檐古阁)
    canvas.save();
    canvas.translate(8, 174);
    canvas.drawRect(const Rect.fromLTWH(8, 64, 66, 12), nearPaint);
    canvas.drawPath(_eavePath(-2, 52, 41, 38, 84, 52, 78, 56, 41, 45, 4, 56), nearPaint);
    canvas.drawRect(const Rect.fromLTWH(12, 55, 58, 11), nearPaint);
    canvas.drawPath(_eavePath(4, 38, 41, 25, 78, 38, 72, 42, 41, 32, 10, 42), nearPaint);
    canvas.drawRect(const Rect.fromLTWH(18, 41, 46, 11), nearPaint);
    canvas.drawPath(Path()..moveTo(41, 12)..lineTo(43, 20)..lineTo(39, 20)..close(), nearPaint);
    canvas.drawPath(_eavePath(12, 26, 41, 15, 70, 26, 65, 30, 41, 21, 17, 30), nearPaint);
    canvas.drawRect(const Rect.fromLTWH(24, 29, 34, 9), nearPaint);
    if (sky.lanternGlow > 0.01) {
      final glowAlpha = sky.lanternGlow.clamp(0.0, 1.0);
      drawAmberGlow(canvas, const Offset(41, 48), 24, glowAlpha);
      _drawLitWindows(canvas, glowAlpha, const [
        (Rect.fromLTWH(28, 31, 7, 5), Color(0xFFFFE299)),
        (Rect.fromLTWH(38, 31, 7, 5), Color(0xFFFFE299)),
        (Rect.fromLTWH(48, 31, 6, 5), Color(0xFFFFE299)),
        (Rect.fromLTWH(23, 43, 9, 6), Color(0xFFFFD470)),
        (Rect.fromLTWH(36, 43, 10, 6), Color(0xFFFFE8A3)),
        (Rect.fromLTWH(50, 43, 9, 6), Color(0xFFFFD470)),
        (Rect.fromLTWH(18, 57, 12, 6), Color(0xFFFFCA5C)),
        (Rect.fromLTWH(35, 57, 12, 6), Color(0xFFFFE299)),
        (Rect.fromLTWH(52, 57, 12, 6), Color(0xFFFFCA5C)),
      ]);
      final dot = Paint()..color = const Color(0xFFFFE8A3).withValues(alpha: glowAlpha);
      canvas.drawCircle(const Offset(6, 56), 2.2, dot);
      canvas.drawCircle(const Offset(76, 56), 2.2, dot);
    }
    canvas.restore();

    // 3. Right Multi-Tiered Hillside Pavilion Cluster (层台楼阁)
    canvas.save();
    canvas.translate(310, 160);
    canvas.drawPath(_eavePath(36, 12, 52, 3, 68, 12, 64, 15, 52, 8, 40, 15), nearPaint);
    canvas.drawRect(const Rect.fromLTWH(43, 15, 18, 8), nearPaint);
    canvas.drawPath(_eavePath(32, 23, 52, 14, 72, 23, 68, 26, 52, 19, 36, 26), nearPaint);
    canvas.drawRect(const Rect.fromLTWH(40, 26, 24, 10), nearPaint);
    canvas.drawPath(_eavePath(4, 46, 38, 32, 72, 46, 67, 50, 38, 39, 9, 50), nearPaint);
    canvas.drawRect(const Rect.fromLTWH(15, 49, 46, 11), nearPaint);
    canvas.drawPath(_eavePath(-2, 60, 38, 46, 78, 60, 73, 64, 38, 53, 3, 64), nearPaint);
    canvas.drawRect(const Rect.fromLTWH(10, 63, 56, 12), nearPaint);
    if (sky.lanternGlow > 0.01) {
      final glowAlpha = sky.lanternGlow.clamp(0.0, 1.0);
      drawAmberGlow(canvas, const Offset(42, 52), 26, glowAlpha);
      _drawLitWindows(canvas, glowAlpha, const [
        (Rect.fromLTWH(46, 17, 5, 4), Color(0xFFFFE299)),
        (Rect.fromLTWH(53, 17, 5, 4), Color(0xFFFFE299)),
        (Rect.fromLTWH(44, 28, 7, 5), Color(0xFFFFD470)),
        (Rect.fromLTWH(53, 28, 7, 5), Color(0xFFFFD470)),
        (Rect.fromLTWH(20, 51, 10, 6), Color(0xFFFFE299)),
        (Rect.fromLTWH(33, 51, 10, 6), Color(0xFFFFE8A3)),
        (Rect.fromLTWH(46, 51, 10, 6), Color(0xFFFFE299)),
        (Rect.fromLTWH(16, 65, 12, 6), Color(0xFFFFD470)),
        (Rect.fromLTWH(32, 65, 12, 6), Color(0xFFFFE299)),
        (Rect.fromLTWH(48, 65, 12, 6), Color(0xFFFFD470)),
      ]);
      final dot = Paint()..color = const Color(0xFFFFE8A3).withValues(alpha: glowAlpha);
      canvas.drawCircle(const Offset(4, 64), 2.2, dot);
      canvas.drawCircle(const Offset(72, 64), 2.2, dot);
    }
    canvas.restore();

    // 4. Misty Wooden Corridor Bridge Spanning the Upper Cove (云水木桥)
    canvas.save();
    canvas.translate(0, 232);
    canvas.drawPath(
      Path()
        ..moveTo(62, 12)..quadraticBezierTo(132, 2, 195, 14)
        ..lineTo(195, 18)..quadraticBezierTo(132, 7, 62, 17)..close(),
      Paint()..color = sky.midMountain.withValues(alpha: 0.65),
    );
    final postPaint = Paint()..color = sky.nearMountain.withValues(alpha: 0.65)..strokeWidth = 1.5;
    for (final xPos in const [78.0, 108.0, 142.0, 172.0]) {
      final topY = (xPos == 78.0 || xPos == 172.0) ? 12.0 : 9.0;
      final botY = (xPos == 78.0 || xPos == 172.0) ? 24.0 : 23.0;
      canvas.drawLine(Offset(xPos, topY), Offset(xPos, botY), postPaint);
    }
    canvas.restore();

    // 5. Golden Pavilion Reflection Pillars on Water
    if (sky.lanternGlow > 0.01) {
      final pillarAlpha = (sky.lanternGlow * 0.85).clamp(0.0, 1.0);
      const pillarRects = [
        Rect.fromLTWH(24, 246, 8, 125),
        Rect.fromLTWH(40, 246, 12, 155),
        Rect.fromLTWH(60, 246, 7, 110),
        Rect.fromLTWH(332, 246, 8, 115),
        Rect.fromLTWH(348, 246, 12, 148),
        Rect.fromLTWH(366, 246, 7, 105),
      ];
      for (final rect in pillarRects) {
        canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFFD479).withValues(alpha: 0.62 * pillarAlpha),
                const Color(0xFFFFA940).withValues(alpha: 0.22 * pillarAlpha),
                const Color(0xFFFF8820).withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.45, 1.0],
            ).createShader(rect),
        );
      }
    }

    // 6. Valley Mist Band & Mid-River Shoals + Delicate Water Ripples
    const mistRect = Rect.fromLTWH(0, 232, 400, 86);
    final mistOpacity = sky.isNight ? 0.52 : 0.85;
    canvas.drawRect(
      mistRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            sky.cloudTint.withValues(alpha: 0.52 * mistOpacity),
            sky.cloudTint.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(mistRect),
    );
    canvas.drawPath(
      Path()..moveTo(0, 455)..quadraticBezierTo(34, 462, 56, 476)..quadraticBezierTo(32, 488, 0, 492)..close(),
      Paint()..color = midPaint.color.withValues(alpha: 0.32),
    );
    canvas.drawPath(
      Path()..moveTo(400, 535)..quadraticBezierTo(352, 544, 326, 558)..quadraticBezierTo(360, 572, 400, 576)..close(),
      Paint()..color = sky.nearMountain.withValues(alpha: 0.35),
    );
    final rippleStroke = Paint()
      ..color = const Color(0xFFDCE8F5).withValues(alpha: 0.18)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (final ripple in const [
      (24.0, 335.0, 62.0, 332.0, 98.0, 336.0),
      (302.0, 358.0, 342.0, 355.0, 378.0, 359.0),
      (18.0, 425.0, 54.0, 422.0, 86.0, 426.0),
      (312.0, 485.0, 348.0, 482.0, 384.0, 486.0),
      (28.0, 575.0, 78.0, 572.0, 124.0, 576.0),
      (276.0, 608.0, 328.0, 605.0, 376.0, 609.0),
    ]) {
      canvas.drawPath(
        Path()..moveTo(ripple.$1, ripple.$2)..quadraticBezierTo(ripple.$3, ripple.$4, ripple.$5, ripple.$6),
        rippleStroke,
      );
    }

    canvas.restore();
  }

  static void paintTopBranchesAndLanterns(
    Canvas canvas,
    Size size,
    InterpolatedIntroSky sky,
    double animationTime,
  ) {
    final sx = size.width / 400.0;
    final sy = size.height / 812.0;
    canvas.save();
    canvas.scale(sx, sy);

    final branchPaint = Paint()
      ..color = const Color(0xFF0B111D).withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      Path()..moveTo(-8, 18)..quadraticBezierTo(28, 32, 58, 64)..quadraticBezierTo(76, 84, 92, 115),
      branchPaint..strokeWidth = 4.5,
    );
    canvas.drawPath(Path()..moveTo(28, 34)..quadraticBezierTo(54, 28, 78, 42), branchPaint..strokeWidth = 2.5);
    canvas.drawPath(Path()..moveTo(46, 52)..quadraticBezierTo(24, 72, 12, 96), branchPaint..strokeWidth = 2.2);
    _drawRotatedOval(canvas, const Offset(18, 24), 44, 20, 15, const Color(0xFF0D1524), 0.78);
    _drawRotatedOval(canvas, const Offset(52, 36), 36, 16, 22, const Color(0xFF0D1524), 0.69);
    _drawRotatedOval(canvas, const Offset(74, 44), 28, 12, 10, const Color(0xFF131F33), 0.60);

    canvas.drawPath(
      Path()..moveTo(408, 14)..quadraticBezierTo(372, 28, 344, 56)..quadraticBezierTo(328, 72, 316, 96),
      branchPaint..strokeWidth = 4.0,
    );
    canvas.drawPath(Path()..moveTo(368, 30)..quadraticBezierTo(342, 24, 322, 36), branchPaint..strokeWidth = 2.2);
    _drawRotatedOval(canvas, const Offset(384, 22), 40, 18, -15, const Color(0xFF0D1524), 0.78);
    _drawRotatedOval(canvas, const Offset(348, 34), 32, 14, -20, const Color(0xFF0D1524), 0.69);

    final swayLeft = math.sin((animationTime / 4.8) * 2 * math.pi) * (1.6 * math.pi / 180.0);
    _drawPalaceLantern(canvas, pivot: const Offset(48, 52), cordBottomY: 74, width: 12, height: 17, swayRad: swayLeft, glowAlpha: sky.lanternGlow);
    final swayRight = math.sin(((animationTime - 1.8) / 4.8) * 2 * math.pi) * (1.6 * math.pi / 180.0);
    _drawPalaceLantern(canvas, pivot: const Offset(352, 46), cordBottomY: 66, width: 10, height: 15, swayRad: swayRight, glowAlpha: sky.lanternGlow);

    if (sky.lanternGlow > 0.01) {
      const fireflies = [
        (88.0, 158.0, 5.0, 1.4, 0.0),
        (306.0, 148.0, 5.5, 1.5, 1.4),
        (268.0, 186.0, 4.2, 1.1, 2.3),
        (114.0, 194.0, 4.2, 1.1, 0.8),
      ];
      for (final fly in fireflies) {
        final phase = ((animationTime + fly.$5) / 4.4) * 2 * math.pi;
        final wave = (math.sin(phase) + 1.0) * 0.5;
        final dx = fly.$1 + wave * 4.0;
        final dy = fly.$2 - wave * 7.0;
        final alpha = sky.lanternGlow * (0.45 + wave * 0.5);
        drawAmberGlow(canvas, Offset(dx, dy), fly.$3, alpha);
        canvas.drawCircle(Offset(dx, dy), fly.$4, Paint()..color = const Color(0xFFFFF5D6).withValues(alpha: alpha));
      }
    }

    canvas.restore();
  }

  static void drawAmberGlow(Canvas canvas, Offset center, double radius, double alpha) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE8A3).withValues(alpha: alpha),
            const Color(0xFFFFA834).withValues(alpha: 0.55 * alpha),
            const Color(0xFFFF7B00).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect),
    );
  }

  static Path _eavePath(
    double x1, double y1, double cx1, double cy1, double x2, double y2,
    double x3, double y3, double cx2, double cy2, double x4, double y4,
  ) {
    return Path()
      ..moveTo(x1, y1)
      ..quadraticBezierTo(cx1, cy1, x2, y2)
      ..lineTo(x3, y3)
      ..quadraticBezierTo(cx2, cy2, x4, y4)
      ..close();
  }

  static void _drawLitWindows(Canvas canvas, double glowAlpha, List<(Rect, Color)> windows) {
    for (final win in windows) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(win.$1, const Radius.circular(0.8)),
        Paint()..color = win.$2.withValues(alpha: glowAlpha),
      );
    }
  }

  static void _drawRotatedOval(
    Canvas canvas, Offset center, double width, double height,
    double angleDeg, Color color, double alpha,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angleDeg * math.pi / 180.0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: width, height: height),
      Paint()..color = color.withValues(alpha: alpha),
    );
    canvas.restore();
  }

  static void _drawPalaceLantern(
    Canvas canvas, {
    required Offset pivot,
    required double cordBottomY,
    required double width,
    required double height,
    required double swayRad,
    required double glowAlpha,
  }) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(swayRad);
    canvas.translate(-pivot.dx, -pivot.dy);

    canvas.drawLine(pivot, Offset(pivot.dx, cordBottomY), Paint()..color = const Color(0xFF18120E)..strokeWidth = 1.2);
    if (glowAlpha > 0.01) {
      drawAmberGlow(canvas, Offset(pivot.dx, cordBottomY + height * 0.65), width * 2.0, glowAlpha);
    }

    final topY = cordBottomY;
    final bottomY = topY + height;
    canvas.drawPath(
      Path()
        ..moveTo(pivot.dx - width * 0.65, topY)..lineTo(pivot.dx + width * 0.65, topY)
        ..lineTo(pivot.dx + width * 0.4, topY + 3)..lineTo(pivot.dx - width * 0.4, topY + 3)..close(),
      Paint()..color = const Color(0xFF2A1F18),
    );
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pivot.dx - width / 2, topY + 3, width, height),
      const Radius.circular(3),
    );
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFFFFE49E));
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFF5A3A22)..strokeWidth = 1.0..style = PaintingStyle.stroke);
    canvas.drawLine(Offset(pivot.dx, topY + 3), Offset(pivot.dx, bottomY + 3), Paint()..color = const Color(0xFF8C5A32)..strokeWidth = 0.6);
    canvas.drawPath(
      Path()
        ..moveTo(pivot.dx - width * 0.4, bottomY + 3)..lineTo(pivot.dx + width * 0.4, bottomY + 3)
        ..lineTo(pivot.dx + width * 0.55, bottomY + 6)..lineTo(pivot.dx - width * 0.55, bottomY + 6)..close(),
      Paint()..color = const Color(0xFF2A1F18),
    );
    canvas.drawLine(Offset(pivot.dx, bottomY + 6), Offset(pivot.dx, bottomY + 14), Paint()..color = const Color(0xFFB83B2E)..strokeWidth = 1.4);
    canvas.restore();
  }
}
