import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/intro_sky_atmosphere.dart';
import 'intro_waterside_actors_painter.dart';

/// Helper painting the synchronized celestial lake shimmer column, animated
/// rowing ferryboat with bow lantern, foreground reeds, and swaying bamboo.
class IntroLakeFerryboatPainter {
  const IntroLakeFerryboatPainter._();

  static void paintForegroundLakeAndFerryboat(
    Canvas canvas,
    Size size,
    InterpolatedIntroSky sky,
    CelestialOrbPosition celestial,
    double animationTime,
  ) {
    final sx = size.width / 400.0;
    final sy = size.height / 812.0;
    canvas.save();
    canvas.scale(sx, sy);

    _paintCelestialLakeReflection(canvas, celestial, animationTime);
    _paintFerryboat(canvas, sky, animationTime);
    _paintForegroundReedsAndLanterns(canvas, sky);
    _paintSwayingBamboo(canvas, animationTime);

    canvas.restore();
  }

  static void _paintCelestialLakeReflection(
    Canvas canvas,
    CelestialOrbPosition celestial,
    double animationTime,
  ) {
    final lakeOpacity = (celestial.edgeFade * 0.85).clamp(0.0, 1.0);
    if (lakeOpacity <= 0.01) return;

    canvas.save();
    canvas.translate(celestial.refX, 645);
    const haloRect = Rect.fromLTWH(-52, -28, 104, 136);
    canvas.drawOval(
      haloRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            (celestial.isMoon ? const Color(0xFFFFFDF8) : const Color(0xFFFFF7D6))
                .withValues(alpha: 0.95 * lakeOpacity * 0.55),
            (celestial.isMoon ? const Color(0xFFE4EEFF) : const Color(0xFFFFE194))
                .withValues(alpha: 0.38 * lakeOpacity * 0.55),
            const Color(0xFFB0C8F0).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.38, 1.0],
        ).createShader(haloRect),
    );

    final shimmerColor =
        celestial.isMoon ? const Color(0xFFFFF7E2) : const Color(0xFFFFFDF5);
    final shimmerPulse = 0.5 + 0.5 * math.sin((animationTime / 3.8) * 2 * math.pi);
    final scaleX = 0.86 + shimmerPulse * 0.28;
    final barOpacityBoost = 0.55 + shimmerPulse * 0.37;
    const bars = [
      (0.0, 38.0, 2.3, 0.82),
      (9.0, 46.0, 2.5, 0.74),
      (19.0, 36.0, 2.2, 0.66),
      (30.0, 52.0, 2.6, 0.58),
      (42.0, 42.0, 2.2, 0.49),
      (55.0, 30.0, 2.0, 0.40),
      (69.0, 40.0, 2.2, 0.32),
      (84.0, 26.0, 1.8, 0.24),
    ];
    for (final bar in bars) {
      final width = bar.$2 * scaleX;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-width / 2.0, bar.$1, width, bar.$3),
          const Radius.circular(1),
        ),
        Paint()
          ..color = shimmerColor.withValues(
            alpha: (bar.$4 * barOpacityBoost * lakeOpacity).clamp(0.0, 1.0),
          ),
      );
    }
    canvas.restore();
  }

  static void _paintForegroundReedsAndLanterns(
    Canvas canvas,
    InterpolatedIntroSky sky,
  ) {
    canvas.save();
    canvas.translate(0, 650);
    canvas.drawPath(
      Path()
        ..moveTo(0, 95)
        ..quadraticBezierTo(28, 78, 52, 88)
        ..quadraticBezierTo(68, 94, 76, 105)
        ..lineTo(0, 115)
        ..close(),
      Paint()..color = sky.nearMountain.withValues(alpha: 0.85),
    );
    final reedPaint = Paint()
      ..color = const Color(0xFF0D1524)
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()..moveTo(14, 98)..quadraticBezierTo(22, 64, 34, 42),
      reedPaint..strokeWidth = 1.8,
    );
    canvas.drawPath(
      Path()..moveTo(24, 102)..quadraticBezierTo(38, 72, 52, 56),
      reedPaint..strokeWidth = 1.5,
    );
    canvas.drawPath(
      Path()..moveTo(10, 100)..quadraticBezierTo(4, 74, 8, 52),
      reedPaint..strokeWidth = 1.4,
    );
    if (sky.lanternGlow > 0.01) {
      final glowAlpha = sky.lanternGlow.clamp(0.0, 1.0);
      IntroWatersideActorsPainter.drawAmberGlow(canvas, const Offset(34, 42), 9, glowAlpha);
      canvas.drawCircle(
        const Offset(34, 42),
        2.2,
        Paint()..color = const Color(0xFFFFF3C4).withValues(alpha: glowAlpha),
      );
      IntroWatersideActorsPainter.drawAmberGlow(canvas, const Offset(52, 56), 7, glowAlpha);
      canvas.drawCircle(
        const Offset(52, 56),
        1.8,
        Paint()..color = const Color(0xFFFFF3C4).withValues(alpha: glowAlpha),
      );
    }
    canvas.restore();
  }

  static void _paintSwayingBamboo(Canvas canvas, double animationTime) {
    final bambooWave = math.sin((animationTime / 5.5) * 2 * math.pi) * 0.5 + 0.5;
    final bambooAngle = -bambooWave * (2.8 * math.pi / 180.0);
    canvas.save();
    canvas.translate(334, 628);
    canvas.scale(0.95);
    canvas.translate(68, 145);
    canvas.rotate(bambooAngle);
    canvas.translate(-68, -145);
    final bambooColor = const Color(0xFF11161F).withValues(alpha: 0.72);
    final bambooFill = Paint()..color = bambooColor;
    canvas.drawPath(
      Path()..moveTo(68, 145)..quadraticBezierTo(44, 92, 18, 28),
      Paint()
        ..color = bambooColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );
    for (final leaf in [
      Path()..moveTo(18, 28)..quadraticBezierTo(4, 25, -4, 31)..quadraticBezierTo(10, 31, 18, 28)..close(),
      Path()..moveTo(18, 28)..quadraticBezierTo(11, 15, 3, 9)..quadraticBezierTo(13, 19, 18, 28)..close(),
      Path()..moveTo(32, 56)..quadraticBezierTo(16, 52, 4, 58)..quadraticBezierTo(20, 58, 32, 56)..close(),
      Path()..moveTo(32, 56)..quadraticBezierTo(22, 42, 14, 35)..quadraticBezierTo(25, 46, 32, 56)..close(),
      Path()..moveTo(45, 86)..quadraticBezierTo(28, 83, 16, 91)..quadraticBezierTo(32, 89, 45, 86)..close(),
      Path()..moveTo(56, 112)..quadraticBezierTo(40, 109, 28, 116)..quadraticBezierTo(44, 115, 56, 112)..close(),
    ]) {
      canvas.drawPath(leaf, bambooFill);
    }
    canvas.restore();
  }

  static void _paintFerryboat(
    Canvas canvas,
    InterpolatedIntroSky sky,
    double animationTime,
  ) {
    final floatPhase = 0.5 - 0.5 * math.cos((animationTime / 7.0) * 2 * math.pi);
    canvas.save();
    canvas.translate(112, 682);
    canvas.scale(1.04);
    canvas.translate(floatPhase * 11.0, -floatPhase * 2.0);
    canvas.rotate(floatPhase * (0.4 * math.pi / 180.0));

    canvas.drawPath(
      Path()
        ..moveTo(28, 25)
        ..quadraticBezierTo(84, 30, 140, 25)
        ..lineTo(130, 31)
        ..lineTo(38, 31)
        ..close(),
      Paint()..color = const Color(0xFF0B121E).withValues(alpha: 0.32),
    );

    if (sky.lanternGlow > 0.01) {
      final glowAlpha = sky.lanternGlow.clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(152, 28);
      canvas.scale(1.0, 3.5 / 16.0);
      IntroWatersideActorsPainter.drawAmberGlow(canvas, Offset.zero, 16, 0.85 * glowAlpha);
      canvas.restore();
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(152, 28), width: 14, height: 2.8),
        Paint()..color = const Color(0xFFFFE8A3).withValues(alpha: 0.75 * glowAlpha),
      );
      canvas.save();
      canvas.translate(94, 27);
      canvas.scale(1.0, 2.2 / 14.0);
      IntroWatersideActorsPainter.drawAmberGlow(canvas, Offset.zero, 14, 0.45 * glowAlpha);
      canvas.restore();
    }

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(84, 25), width: 136, height: 5.6),
      Paint()
        ..color = const Color(0xFFB8CCE4).withValues(alpha: 0.62)
        ..strokeWidth = 0.85
        ..style = PaintingStyle.stroke,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(14, 25), width: 28, height: 3.6),
      Paint()
        ..color = const Color(0xFFDCE8F8).withValues(alpha: 0.55)
        ..strokeWidth = 0.75
        ..style = PaintingStyle.stroke,
    );

    final rowPhase = 0.5 - 0.5 * math.cos((animationTime / 3.2) * 2 * math.pi);
    canvas.save();
    canvas.translate(51 + rowPhase, 20);
    canvas.rotate(rowPhase * (4.5 * math.pi / 180.0));
    canvas.translate(-51, -20);
    canvas.drawPath(
      Path()..moveTo(44, 19)..quadraticBezierTo(46, 9, 52, 9)..lineTo(56, 19)..close(),
      Paint()..color = const Color(0xFF1E2229),
    );
    canvas.drawLine(
      const Offset(51, 12),
      const Offset(57, 14),
      Paint()
        ..color = const Color(0xFF282C34)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(51, 8.5), 2.1, Paint()..color = const Color(0xFF2C2623));
    final hatPath = Path()..moveTo(40, 9.5)..lineTo(51, 3.2)..lineTo(62, 9.5)..close();
    canvas.drawPath(hatPath, Paint()..color = const Color(0xFF3A3024));
    canvas.drawPath(
      hatPath,
      Paint()
        ..color = const Color(0xFF1A1612)
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      const Offset(42, 9.5),
      const Offset(60, 9.5),
      Paint()..color = const Color(0xFF8C7355)..strokeWidth = 0.6,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(54, 15);
    canvas.rotate(-rowPhase * (11.0 * math.pi / 180.0));
    canvas.translate(-54, -15);
    canvas.drawLine(
      const Offset(57, 14),
      const Offset(10, 25),
      Paint()
        ..color = const Color(0xFF5C432C)
        ..strokeWidth = 1.65
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()..moveTo(18, 22.5)..lineTo(6, 25.5)..lineTo(8, 27)..lineTo(20, 23.8)..close(),
      Paint()..color = const Color(0xFF47321F),
    );
    canvas.restore();

    final canopyPath = Path()
      ..moveTo(70, 19)
      ..lineTo(70, 8.5)
      ..quadraticBezierTo(94, 2.5, 118, 8.5)
      ..lineTo(118, 19)
      ..close();
    canvas.drawPath(
      canopyPath,
      Paint()..color = sky.isNight ? const Color(0xFF3B485E) : const Color(0xFF8C7A64),
    );
    canvas.drawPath(
      canopyPath,
      Paint()
        ..color = const Color(0xFF221C16)
        ..strokeWidth = 0.95
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      Path()..moveTo(82, 19)..lineTo(82, 6.5)..moveTo(94, 19)..lineTo(94, 5.5)..moveTo(106, 19)..lineTo(106, 6.5),
      Paint()
        ..color = const Color(0xFF26201A).withValues(alpha: 0.7)
        ..strokeWidth = 0.75
        ..style = PaintingStyle.stroke,
    );
    if (sky.lanternGlow > 0.01) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(89, 10.5, 10, 5.5), const Radius.circular(1)),
        Paint()..color = const Color(0xFFFFE299).withValues(alpha: (sky.lanternGlow * 0.92).clamp(0.0, 1.0)),
      );
    }

    final hullPath = Path()
      ..moveTo(22, 17.5)
      ..quadraticBezierTo(84, 23, 146, 15.5)
      ..lineTo(135, 23.5)
      ..lineTo(32, 23.5)
      ..close();
    canvas.drawPath(
      hullPath,
      Paint()..color = sky.isNight ? const Color(0xFF2B211A) : const Color(0xFF4E3828),
    );
    canvas.drawPath(
      hullPath,
      Paint()
        ..color = const Color(0xFF1C140E)
        ..strokeWidth = 0.9
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      Path()..moveTo(25, 18.2)..quadraticBezierTo(84, 22.8, 143, 16.4),
      Paint()
        ..color = (sky.isNight ? const Color(0xFF9E7B56) : const Color(0xFF7D5C40)).withValues(alpha: 0.85)
        ..strokeWidth = 1.1
        ..style = PaintingStyle.stroke,
    );

    canvas.drawPath(
      Path()..moveTo(135, 17.5)..quadraticBezierTo(142, 4.5, 152, 5.5),
      Paint()
        ..color = const Color(0xFF3B2A1D)
        ..strokeWidth = 1.45
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    final bowSway = math.sin((animationTime / 4.8) * 2 * math.pi) * (1.6 * math.pi / 180.0);
    canvas.save();
    canvas.translate(152, 5.5);
    canvas.rotate(bowSway);
    canvas.translate(-152, -5.5);
    canvas.drawLine(
      const Offset(152, 5.5),
      const Offset(152, 9.5),
      Paint()..color = const Color(0xFF1F1711)..strokeWidth = 0.9,
    );
    if (sky.lanternGlow > 0.01) {
      IntroWatersideActorsPainter.drawAmberGlow(canvas, const Offset(152, 13.5), 18, sky.lanternGlow);
      IntroWatersideActorsPainter.drawAmberGlow(canvas, const Offset(152, 13.5), 8, 0.9 * sky.lanternGlow);
    }
    canvas.drawPath(
      Path()..moveTo(148.5, 9.5)..lineTo(155.5, 9.5)..lineTo(154.5, 10.8)..lineTo(149.5, 10.8)..close(),
      Paint()..color = const Color(0xFF2A1E17),
    );
    final lanternBody = RRect.fromRectAndRadius(
      const Rect.fromLTWH(149.2, 10.8, 5.6, 6.2),
      const Radius.circular(1.6),
    );
    canvas.drawRRect(
      lanternBody,
      Paint()..color = sky.lanternGlow > 0.35 ? const Color(0xFFFFE8A3) : const Color(0xFFE6DEC8),
    );
    canvas.drawRRect(
      lanternBody,
      Paint()
        ..color = const Color(0xFF4A3221)
        ..strokeWidth = 0.65
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      Path()..moveTo(149.5, 17)..lineTo(154.5, 17)..lineTo(155.2, 18)..lineTo(148.8, 18)..close(),
      Paint()..color = const Color(0xFF2A1E17),
    );
    canvas.drawLine(
      const Offset(152, 18),
      const Offset(152, 21.2),
      Paint()..color = const Color(0xFFB83B2E)..strokeWidth = 0.9,
    );
    canvas.restore();
    canvas.restore();
  }
}
