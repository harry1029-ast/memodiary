import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/intro_sky_atmosphere.dart';
import 'intro_lake_ferryboat_painter.dart';
import 'intro_waterside_actors_painter.dart';

/// CustomPainter rendering the dynamic 24-hour Shanshui sky, parabolic Sun/Moon
/// trajectory, drifting clouds, cathedral peaks, continuous river-to-lake surface,
/// glowing waterside pavilions, palace lanterns, and animated ferryboat.
class LivingInkBackgroundPainter extends CustomPainter {
  final double coverOpenRatio; // 0.0 (closed) to 1.0 (fully open)
  final double animationTime; // Elapsed seconds from animation ticker
  final double timeHours; // Fractional hour in [0, 24)

  LivingInkBackgroundPainter({
    required this.coverOpenRatio,
    required this.animationTime,
    this.timeHours = 21.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sky = InterpolatedIntroSky.fromHour(timeHours);
    final celestial = CelestialOrbPosition.fromHour(timeHours, size);
    final sx = size.width / 400.0;
    final sy = size.height / 812.0;

    canvas.save();
    canvas.scale(sx, sy);

    // 1. Dynamic 24-Hour Sky Backdrop
    _paintSkyBackdrop(canvas, sky);

    // 2. Parabolic Celestial Trajectory Guide Arc
    _paintGuideArc(canvas, sky);

    // 3. Starfield & Milky Way Dust
    _paintStars(canvas, sky);

    // 4. Sun / Moon Celestial Orb
    _paintCelestialOrb(canvas, celestial);

    // 5. Drifting Cloud-Mist Layers & Gliding Cranes
    _paintCloudsAndCranes(canvas, sky);

    // 6. Far & Mid-Ground Towering Shanshui Peaks (with subtle cover parallax)
    _paintMountains(canvas, sky);

    // 7. Continuous River & Lake Surface + Waterfall + Cloud-Sea Mist Ribbon
    _paintContinuousWaterAndMist(canvas, sky);

    canvas.restore();

    // 8. Waterside Pavilions, Bridge, Branches, Palace Lanterns, Reflection & Ferryboat
    IntroWatersideActorsPainter.paintPavilionsAndBridge(canvas, size, sky);
    IntroWatersideActorsPainter.paintTopBranchesAndLanterns(
      canvas,
      size,
      sky,
      animationTime,
    );
    IntroLakeFerryboatPainter.paintForegroundLakeAndFerryboat(
      canvas,
      size,
      sky,
      celestial,
      animationTime,
    );
  }

  void _paintSkyBackdrop(Canvas canvas, InterpolatedIntroSky sky) {
    const skyRect = Rect.fromLTWH(0, 0, 400, 320);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            sky.skyTop,
            sky.skyMid,
            sky.skyHorizon,
            sky.waterBase,
          ],
          stops: const [0.0, 0.52, 0.88, 1.0],
        ).createShader(skyRect),
    );
  }

  void _paintGuideArc(Canvas canvas, InterpolatedIntroSky sky) {
    // Matches CelestialOrbPosition.fromHour: endpoints (36, 212)..(364, 212) with apex at y = 96.
    final arcPath = Path()
      ..moveTo(36, 212)
      ..quadraticBezierTo(200, -20, 364, 212);
    final color = (sky.isNight ? const Color(0xFF8AA4CC) : Colors.white)
        .withValues(alpha: 0.15);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke;

    for (final metric in arcPath.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + 3.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 9.0;
      }
    }
  }

  void _paintStars(Canvas canvas, InterpolatedIntroSky sky) {
    if (sky.starOpacity <= 0.01) return;
    final alpha = sky.starOpacity.clamp(0.0, 1.0);
    final starPaint = Paint()..color = const Color(0xFFFFFDF6).withValues(alpha: alpha);

    const stars = [
      (48.0, 54.0, 1.1),
      (88.0, 88.0, 0.8),
      (132.0, 44.0, 1.3),
      (176.0, 76.0, 0.9),
      (228.0, 48.0, 1.2),
      (274.0, 66.0, 1.4),
      (318.0, 42.0, 0.9),
      (356.0, 82.0, 1.2),
      (66.0, 134.0, 1.0),
      (336.0, 130.0, 1.1),
      (154.0, 112.0, 0.8),
      (248.0, 108.0, 1.0),
    ];
    for (final star in stars) {
      canvas.drawCircle(Offset(star.$1, star.$2), star.$3, starPaint);
    }

    canvas.save();
    canvas.translate(195, 74);
    canvas.rotate(-14.0 * math.pi / 180.0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 230, height: 32),
      Paint()..color = const Color(0xFFC5D8FF).withValues(alpha: 0.06 * alpha),
    );
    canvas.restore();
  }

  void _paintCelestialOrb(Canvas canvas, CelestialOrbPosition celestial) {
    final orbOpacity = math.max(0.2, celestial.edgeFade).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(celestial.refX, celestial.refY);

    final innerStop = celestial.isMoon ? const Color(0xFFFFFDF8) : const Color(0xFFFFF7D6);
    final midStop = celestial.isMoon ? const Color(0xFFE4EEFF) : const Color(0xFFFFE194);

    void drawHalo(double radius, double strength) {
      final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              innerStop.withValues(alpha: 0.95 * orbOpacity * strength),
              midStop.withValues(alpha: 0.38 * orbOpacity * strength),
              const Color(0xFFB0C8F0).withValues(alpha: 0.12 * orbOpacity * strength),
              const Color(0xFFB0C8F0).withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.38, 0.72, 1.0],
          ).createShader(rect),
      );
    }

    drawHalo(68.0, 1.0);
    drawHalo(42.0, 0.7);

    if (celestial.isMoon) {
      canvas.drawCircle(
        Offset.zero,
        27,
        Paint()..color = const Color(0xFFFFFDF7).withValues(alpha: orbOpacity),
      );
      const craters = [
        (-7.0, -5.0, 7.5, 0.42),
        (8.0, 6.0, 9.5, 0.35),
        (4.0, -10.0, 4.5, 0.30),
        (-10.0, 9.0, 5.0, 0.28),
      ];
      for (final crater in craters) {
        canvas.drawCircle(
          Offset(crater.$1, crater.$2),
          crater.$3,
          Paint()..color = const Color(0xFFE3DFD3).withValues(alpha: crater.$4 * orbOpacity),
        );
      }
    } else {
      canvas.drawCircle(
        Offset.zero,
        23,
        Paint()..color = const Color(0xFFFFF3D1).withValues(alpha: orbOpacity),
      );
      canvas.drawCircle(
        Offset.zero,
        19,
        Paint()..color = const Color(0xFFFFFDF7).withValues(alpha: orbOpacity),
      );
    }

    canvas.restore();
  }

  void _paintCloudsAndCranes(Canvas canvas, InterpolatedIntroSky sky) {
    final slowWave = 0.5 - 0.5 * math.cos((animationTime / 11.0) * 2 * math.pi);
    canvas.save();
    canvas.translate(-14.0 + slowWave * 30.0, -slowWave * 2.0);
    canvas.drawPath(
      Path()
        ..moveTo(42, 136)
        ..quadraticBezierTo(86, 120, 132, 132)
        ..quadraticBezierTo(178, 144, 224, 126)
        ..quadraticBezierTo(266, 114, 308, 136)
        ..lineTo(325, 148)
        ..lineTo(28, 148)
        ..close(),
      Paint()..color = sky.cloudTint.withValues(alpha: 0.38 * 0.35),
    );
    canvas.restore();

    final reverseWave = 0.5 - 0.5 * math.cos((animationTime / 14.0) * 2 * math.pi);
    canvas.save();
    canvas.translate(14.0 - reverseWave * 30.0, reverseWave * 2.0);
    canvas.drawPath(
      Path()
        ..moveTo(95, 168)
        ..quadraticBezierTo(150, 152, 205, 164)
        ..quadraticBezierTo(260, 176, 315, 156)
        ..quadraticBezierTo(350, 144, 382, 168)
        ..lineTo(390, 180)
        ..lineTo(82, 180)
        ..close(),
      Paint()..color = sky.cloudTint.withValues(alpha: 0.32 * 0.28),
    );
    canvas.restore();

    // Distant Gliding Cranes
    final craneDy = -4.0 * (0.5 - 0.5 * math.cos((animationTime / 4.2) * 2 * math.pi));
    final craneAlpha = sky.isNight ? 0.55 : 0.85;
    final craneColor = (sky.isNight ? const Color(0xFFDCE8F8) : const Color(0xFF263849))
        .withValues(alpha: craneAlpha);
    canvas.save();
    canvas.translate(0, craneDy);
    canvas.drawPath(
      Path()
        ..moveTo(116, 138)
        ..quadraticBezierTo(123, 131, 129, 137)
        ..quadraticBezierTo(135, 131, 142, 138),
      Paint()
        ..color = craneColor
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(92, 152)
        ..quadraticBezierTo(97, 147, 101, 151)
        ..quadraticBezierTo(105, 147, 110, 152),
      Paint()
        ..color = craneColor.withValues(alpha: craneAlpha * 0.75)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();
  }

  void _paintMountains(Canvas canvas, InterpolatedIntroSky sky) {
    final farParallax = -coverOpenRatio * 8.0;
    canvas.save();
    canvas.translate(farParallax, 0);
    canvas.drawPath(
      Path()
        ..moveTo(-12, 255)
        ..lineTo(-12, 192)
        ..lineTo(0, 192)
        ..quadraticBezierTo(22, 165, 44, 142)
        ..quadraticBezierTo(64, 118, 82, 158)
        ..quadraticBezierTo(104, 195, 124, 155)
        ..quadraticBezierTo(148, 102, 168, 136)
        ..quadraticBezierTo(186, 168, 202, 126)
        ..quadraticBezierTo(218, 88, 236, 132)
        ..quadraticBezierTo(256, 178, 278, 138)
        ..quadraticBezierTo(304, 92, 326, 138)
        ..quadraticBezierTo(352, 186, 376, 162)
        ..lineTo(400, 145)
        ..lineTo(412, 140)
        ..lineTo(412, 262)
        ..lineTo(-12, 262)
        ..close(),
      Paint()..color = sky.farMountain.withValues(alpha: 0.68),
    );
    canvas.restore();

    final midParallax = coverOpenRatio * 4.0;
    canvas.save();
    canvas.translate(midParallax, 0);
    canvas.drawPath(
      Path()
        ..moveTo(-12, 264)
        ..lineTo(-12, 206)
        ..lineTo(0, 206)
        ..quadraticBezierTo(32, 162, 64, 198)
        ..quadraticBezierTo(96, 232, 128, 184)
        ..quadraticBezierTo(154, 146, 180, 196)
        ..quadraticBezierTo(200, 228, 222, 192)
        ..quadraticBezierTo(252, 144, 284, 188)
        ..quadraticBezierTo(316, 226, 352, 182)
        ..quadraticBezierTo(378, 154, 400, 185)
        ..lineTo(412, 188)
        ..lineTo(412, 264)
        ..lineTo(-12, 264)
        ..close(),
      Paint()..color = sky.midMountain.withValues(alpha: 0.88),
    );
    canvas.restore();
  }

  void _paintContinuousWaterAndMist(Canvas canvas, InterpolatedIntroSky sky) {
    const waterRect = Rect.fromLTWH(0, 246, 400, 566);
    canvas.drawRect(
      waterRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            sky.skyHorizon.withValues(alpha: 0.96),
            sky.waterBase.withValues(alpha: 0.99),
            sky.nearMountain,
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(waterRect),
    );

    const refRect = Rect.fromLTWH(0, 252, 400, 190);
    canvas.drawPath(
      Path()
        ..moveTo(0, 252)
        ..lineTo(400, 252)
        ..lineTo(400, 415)
        ..quadraticBezierTo(352, 442, 308, 388)
        ..quadraticBezierTo(258, 430, 202, 375)
        ..quadraticBezierTo(148, 425, 92, 385)
        ..quadraticBezierTo(42, 438, 0, 405)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            sky.nearMountain.withValues(alpha: 0.45),
            sky.midMountain.withValues(alpha: 0.18),
            sky.waterBase.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(refRect),
    );

    // Central Mountain Gorge Waterfall (飞瀑流泉)
    canvas.drawPath(
      Path()
        ..moveTo(199, 198)
        ..quadraticBezierTo(201, 226, 198, 254),
      Paint()
        ..color = const Color(0xFFE6F2FF).withValues(alpha: 0.55)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(199, 254), width: 32, height: 6),
      Paint()..color = const Color(0xFFDCE8F5).withValues(alpha: 0.45 * 0.55),
    );

    // Billowing Cloud-Sea Mist Ribbon Blending the Mountain Base & Far Shoreline
    const mistBandRect = Rect.fromLTWH(-10, 196, 420, 70);
    canvas.drawPath(
      Path()
        ..moveTo(-10, 222)
        ..quadraticBezierTo(55, 206, 118, 220)
        ..quadraticBezierTo(185, 234, 252, 214)
        ..quadraticBezierTo(325, 196, 410, 218)
        ..lineTo(410, 266)
        ..lineTo(-10, 266)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            sky.cloudTint.withValues(alpha: 0.52),
            sky.cloudTint.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(mistBandRect),
    );
  }

  @override
  bool shouldRepaint(covariant LivingInkBackgroundPainter oldDelegate) {
    return oldDelegate.coverOpenRatio != coverOpenRatio ||
        oldDelegate.animationTime != animationTime ||
        oldDelegate.timeHours != timeHours;
  }
}
