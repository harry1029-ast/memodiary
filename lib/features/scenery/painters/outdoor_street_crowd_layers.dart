import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/outdoor_street_models.dart';
import '../models/shanshui_atmosphere.dart';

/// Dynamic crowd, cloud, lantern, and food-stall steam rendering helpers for the
/// Outdoor Ancient Market Street (`街市`) realm.
class OutdoorStreetCrowdLayers {
  const OutdoorStreetCrowdLayers._();

  /// Paints drifting billowy clouds and distant flying birds across the sky.
  static void paintCloudsAndBirds(
    Canvas canvas, {
    required double animationTime,
    required double wind,
    required bool isNight,
    required ShanshuiWeather weather,
  }) {
    final clouds = OutdoorCloud.createDefaultClouds();
    final isStormy = weather == ShanshuiWeather.stormy;
    final cloudFill = Paint()
      ..color = isNight
          ? const Color.fromRGBO(55, 72, 92, 0.55)
          : isStormy
              ? const Color.fromRGBO(65, 75, 85, 0.72)
              : const Color.fromRGBO(255, 252, 244, 0.86);
    final cloudStroke = Paint()
      ..color = isNight
          ? const Color.fromRGBO(30, 42, 55, 0.40)
          : const Color.fromRGBO(160, 140, 115, 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    for (int index = 0; index < clouds.length; index++) {
      final cloud = clouds[index];
      final cx = ((cloud.x + animationTime * cloud.speed * wind) % 1400) + 50;
      final cy = cloud.y + math.sin(animationTime * 0.6 + index) * 4;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(cloud.scale, cloud.scale);

      final path = Path()
        ..addArc(const Rect.fromLTWH(-38, -38, 76, 76), 0.8 * math.pi, 1.1 * math.pi)
        ..arcTo(const Rect.fromLTWH(-10, -58, 92, 92), math.pi, 1.1 * math.pi, false)
        ..arcTo(const Rect.fromLTWH(48, -32, 68, 68), 1.1 * math.pi, 1.1 * math.pi, false)
        ..lineTo(-36, 18)
        ..close();
      canvas.drawPath(path, cloudFill);
      canvas.drawPath(path, cloudStroke);
      canvas.restore();
    }

    final birdPaint = Paint()
      ..color = isNight ? const Color(0xFFCBD5E1) : const Color(0xFF3B3028)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    const birds = [
      [1085.0, 138.0, 1.0],
      [1108.0, 125.0, 0.85],
      [1132.0, 134.0, 0.75],
      [1150.0, 118.0, 0.65],
    ];
    for (int index = 0; index < birds.length; index++) {
      final bird = birds[index];
      final flap = math.sin(animationTime * 5.5 + index) * 5;
      final driftX = (animationTime * 14) % 240;
      final curX = bird[0] - driftX * 0.4;
      final birdScale = bird[2];

      final birdPath = Path()
        ..moveTo(curX - 7 * birdScale, bird[1] + flap * birdScale)
        ..quadraticBezierTo(curX, bird[1] - 4 * birdScale, curX, bird[1])
        ..quadraticBezierTo(
          curX,
          bird[1] - 4 * birdScale,
          curX + 7 * birdScale,
          bird[1] + flap * birdScale,
        );
      canvas.drawPath(birdPath, birdPaint);
    }
  }

  /// Paints rising food-stall steam wisps from the pastry and noodle stalls.
  static void paintFoodSteam(
    Canvas canvas, {
    required double animationTime,
    required bool isNight,
    required bool isDawn,
    required bool hasSnow,
    required double wind,
  }) {
    if (isDawn) return;

    final wisps = OutdoorSteamWisp.createDefaultWisps();
    for (final wisp in wisps) {
      if (isNight && wisp.isLeftStall) continue;

      final progress = (wisp.progress + animationTime * 0.12) % 1.0;
      final sourceX = wisp.isLeftStall ? 85.0 : 1235.0;
      final sourceY = wisp.isLeftStall ? 695.0 : 705.0;
      final curX = sourceX +
          math.sin(progress * math.pi * 3 + animationTime * 2.0 + wisp.phase) *
              (10 + progress * 18 * wind);
      final curY = sourceY - progress * 95;
      final alpha = math.sin(progress * math.pi) * (hasSnow || isNight ? 0.38 : 0.25);

      final steamPaint = Paint()
        ..color = const Color.fromRGBO(255, 252, 245, 1.0).withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(curX, curY), 4 + progress * 13, steamPaint);
    }
  }

  /// Paints a list of [figures] (either behind-counter vendors or foreground walkers).
  static void paintTownsfolkList(
    Canvas canvas,
    List<TownsfolkWalker> figures, {
    required double animationTime,
    required bool isNight,
    required bool isPrecipitation,
    required double wind,
  }) {
    for (final walker in figures) {
      _drawTownsfolk(
        canvas,
        walker,
        animationTime: animationTime,
        isNight: isNight,
        isPrecipitation: isPrecipitation,
        wind: wind,
      );
    }
  }

  static void _drawTownsfolk(
    Canvas canvas,
    TownsfolkWalker walker, {
    required double animationTime,
    required bool isNight,
    required bool isPrecipitation,
    required double wind,
  }) {
    final bobY =
        (math.sin(animationTime * walker.speed * 2.2 + walker.phase).abs()) * 6 * walker.scale;
    final swayX = math.sin(animationTime * walker.speed * 1.1 + walker.phase) * 4 * walker.scale;
    final cx = walker.baseX + swayX;
    final cy = walker.baseY - bobY;
    final scale = walker.scale;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale, scale);

    // Ground cast shadow
    final shadowPaint = Paint()
      ..color = isNight
          ? const Color.fromRGBO(8, 12, 18, 0.55)
          : const Color.fromRGBO(55, 42, 30, 0.32);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 88 + bobY / scale), width: 68, height: 22),
      shadowPaint,
    );

    // Legs / trousers with stride
    final legSwing = math.sin(animationTime * walker.speed * 2.2 + walker.phase) * 7;
    final pantsPaint = Paint()..color = walker.pants;
    final strokePaint = Paint()
      ..color = const Color(0xFF231B16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final leftLeg = RRect.fromRectAndRadius(
      Rect.fromLTWH(-18, 32, 15, 50 + legSwing * 0.4),
      const Radius.circular(4),
    );
    canvas.drawRRect(leftLeg, pantsPaint);
    canvas.drawRRect(leftLeg, strokePaint);

    final rightLeg = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 32, 15, 50 - legSwing * 0.4),
      const Radius.circular(4),
    );
    canvas.drawRRect(rightLeg, pantsPaint);
    canvas.drawRRect(rightLeg, strokePaint);

    // White-soled cloth shoes (千层底布鞋)
    final solePaint = Paint()..color = const Color(0xFFF2EDE2);
    final shoePaint = Paint()..color = const Color(0xFF262220);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-10, 85.2 + legSwing * 0.4), width: 19, height: 10.5),
      solePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(10, 85.2 - legSwing * 0.4), width: 19, height: 10.5),
      solePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-10, 83.0 + legSwing * 0.4), width: 17.5, height: 8.0),
      shoePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(10, 83.0 - legSwing * 0.4), width: 17.5, height: 8.0),
      shoePaint,
    );

    // Outer sleeves / tunic
    final tunic = Path()
      ..moveTo(-22, -26)
      ..quadraticBezierTo(-36, 4, -28, 32)
      ..lineTo(28, 32)
      ..quadraticBezierTo(36, 4, 22, -26)
      ..close();
    canvas.drawPath(tunic, Paint()..color = walker.jacket);
    canvas.drawPath(tunic, strokePaint);

    // Waistcoat / vest
    final vestRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-20, -26, 40, 62),
      const Radius.circular(6),
    );
    canvas.drawRRect(vestRRect, Paint()..color = walker.vest);
    canvas.drawRRect(vestRRect, strokePaint);

    // Center seam & frog buttons
    canvas.drawLine(const Offset(0, -26), const Offset(0, 36), strokePaint);
    for (double by = -14; by <= 22; by += 12) {
      canvas.drawLine(Offset(-5, by), Offset(5, by), strokePaint);
    }

    // Holding cup
    if (walker.holdingCup) {
      const cupRect = Rect.fromLTWH(-14, -4, 11, 13);
      canvas.drawRect(cupRect, Paint()..color = const Color(0xFFE8EEF2));
      canvas.drawRect(cupRect, strokePaint);
    }

    // Head & serene face
    canvas.drawCircle(const Offset(0, -45), 16, Paint()..color = const Color(0xFFF2D2B6));
    canvas.drawCircle(const Offset(0, -45), 16, strokePaint);

    // Hair cap / bun
    final hair = Path()
      ..addArc(const Rect.fromLTWH(-16.5, -65.5, 33, 33), 0.95 * math.pi, 1.1 * math.pi);
    canvas.drawPath(hair, Paint()..color = const Color(0xFF26201D));

    // Serene eyes and smile arc
    final eyePaint = Paint()..color = const Color(0xFF2B211B);
    canvas.drawCircle(const Offset(-5, -45), 1.6, eyePaint);
    canvas.drawCircle(const Offset(5, -45), 1.6, eyePaint);
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0, -39), radius: 3.5),
      0.15 * math.pi,
      0.70 * math.pi,
      false,
      Paint()
        ..color = const Color(0xFF2B211B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Oiled-paper umbrella in precipitation weather
    if (isPrecipitation && walker.hasUmbrella) {
      canvas.save();
      canvas.translate(10, -68);
      canvas.rotate(0.08 * wind);

      canvas.drawLine(
        Offset.zero,
        const Offset(0, 62),
        Paint()
          ..color = const Color(0xFF5C3A21)
          ..strokeWidth = 2.5,
      );

      final umbrella = Path()
        ..addArc(const Rect.fromLTWH(-44, -36, 88, 88), math.pi, math.pi)
        ..close();
      canvas.drawPath(umbrella, Paint()..color = const Color(0xFFD96B43));
      canvas.drawPath(umbrella, strokePaint);
      canvas.restore();
    }

    canvas.restore();
  }

  /// Paints the 12 street lanterns and 2 Paifang hanging lanterns with
  /// multi-stop radial gradients for silk bodies and warm halos.
  static void paintStreetLanterns(
    Canvas canvas, {
    required double animationTime,
    required double lanternLevel,
    required double wind,
  }) {
    final lanterns = OutdoorLantern.createStreetLanterns();
    final baseSway = math.sin(animationTime * 1.8 * wind) * 0.06 * wind;
    final flicker1 = math.sin(animationTime * 7.2) * 0.5 + math.cos(animationTime * 12.5) * 0.5;
    final flicker2 =
        math.sin(animationTime * 6.4 + 1.2) * 0.5 + math.sin(animationTime * 11.1) * 0.5;

    for (int index = 0; index < lanterns.length; index++) {
      final lantern = lanterns[index];
      final sway = baseSway * math.cos(animationTime * 1.5 + lantern.phase);
      final flicker = index.isEven ? flicker1 : flicker2;
      _drawSingleLantern(
        canvas,
        lantern.x,
        lantern.y,
        lantern.rx,
        lantern.ry,
        sway,
        lanternLevel,
        flicker,
      );
    }

    _drawSingleLantern(canvas, 648, 484, 13, 11, baseSway, lanternLevel, flicker1);
    _drawSingleLantern(canvas, 852, 484, 13, 11, -baseSway, lanternLevel, flicker2);
  }

  static void _drawSingleLantern(
    Canvas canvas,
    double lx,
    double ly,
    double rx,
    double ry,
    double sway,
    double glow,
    double flicker,
  ) {
    canvas.save();
    canvas.translate(lx, ly);
    canvas.rotate(sway);

    // Hanging cord
    canvas.drawLine(
      Offset(0, -ry - 14),
      Offset(0, -ry),
      Paint()
        ..color = const Color(0xFF2B1B12)
        ..strokeWidth = 2.0,
    );

    // Multi-stop radial warm glow halo
    if (glow > 0.08) {
      final haloR = rx * (3.6 + flicker * 0.25);
      final haloShader = RadialGradient(
        colors: [
          Color.fromRGBO(255, 235, 165, (0.85 * glow).clamp(0.0, 1.0)),
          Color.fromRGBO(255, 140, 50, (0.48 * glow).clamp(0.0, 1.0)),
          Color.fromRGBO(220, 65, 25, (0.16 * glow).clamp(0.0, 1.0)),
          const Color.fromRGBO(220, 65, 25, 0.0),
        ],
        stops: const [0.06, 0.32, 0.70, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: haloR));
      canvas.drawCircle(Offset.zero, haloR, Paint()..shader = haloShader);
    }

    // Multi-stop radial red silk lantern body
    final bodyOval = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);
    final bodyShader = RadialGradient(
      colors: glow > 0.25
          ? const [Color(0xFFFFF3B0), Color(0xFFFF6B35), Color(0xFFB8291E)]
          : const [Color(0xFFE8533F), Color(0xFFC83728), Color(0xFF8F2117)],
      stops: glow > 0.25 ? const [0.15, 0.45, 1.0] : const [0.15, 0.65, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: rx));
    canvas.drawOval(bodyOval, Paint()..shader = bodyShader);
    canvas.drawOval(
      bodyOval,
      Paint()
        ..color = const Color(0xFF2B1810)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Ribs
    final ribPaint = Paint()
      ..color = const Color.fromRGBO(60, 15, 10, 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (final frac in const [-0.55, -0.22, 0.22, 0.55]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2 * frac.abs(), height: ry * 2),
        ribPaint,
      );
    }

    // Top & bottom caps
    final capPaint = Paint()..color = const Color(0xFFD49B38);
    final capStroke = Paint()
      ..color = const Color(0xFF2B1810)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final topCap = Rect.fromLTWH(-rx * 0.42, -ry - 3, rx * 0.84, 5);
    final botCap = Rect.fromLTWH(-rx * 0.42, ry - 2, rx * 0.84, 5);
    canvas.drawRect(topCap, capPaint);
    canvas.drawRect(topCap, capStroke);
    canvas.drawRect(botCap, capPaint);

    // Silk tassel
    final tassel = Path()
      ..moveTo(0, ry + 3)
      ..quadraticBezierTo(sway * 18, ry + ry * 0.55, sway * 28, ry + ry * 0.95);
    canvas.drawPath(
      tassel,
      Paint()
        ..color = const Color(0xFFC83226)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    canvas.restore();
  }
}
