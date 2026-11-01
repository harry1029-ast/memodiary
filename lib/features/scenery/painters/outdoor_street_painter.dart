import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/outdoor_street_models.dart';
import '../models/outdoor_street_palette.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_scenery_geometry.dart';
import 'outdoor_street_static_architecture.dart';

/// Full interactive vector painter for the Outdoor Ancient Market Street (`市井`) realm.
///
/// Combines a cached static architectural `ui.Picture` layer with dynamic 60 FPS
/// animations: drifting billowy clouds, distant flying birds, swaying red paper
/// lanterns with warm night halos, bustling townsfolk crowd with time-of-day
/// lifecycle, rainy-day oiled-paper umbrellas (`油纸伞`), steaming food stalls,
/// wet flagstone reflections, interactive puddle ripples, and classical colophons.
class OutdoorStreetPainter extends CustomPainter {
  final ShanshuiAtmosphereState atmosphere;
  final OutdoorStreetPalette streetPalette;
  final double animationTime;
  final List<ShanshuiParticle> particles;
  final List<ShanshuiWeatherDrop> weatherDrops;
  final List<dynamic>? ripples;
  final bool showCalligraphy;
  final bool fullPoem;
  final double lightningAlpha;
  final ui.Picture? cachedStaticPicture;

  OutdoorStreetPainter({
    required this.atmosphere,
    OutdoorStreetPalette? streetPalette,
    required this.animationTime,
    required this.particles,
    required this.weatherDrops,
    this.ripples,
    this.showCalligraphy = false,
    this.fullPoem = false,
    this.lightningAlpha = 0.0,
    this.cachedStaticPicture,
  }) : streetPalette = streetPalette ??
            OutdoorStreetPalette.of(atmosphere.season, atmosphere.timeOfDay);

  /// Records static architectural geometry into an immutable `ui.Picture`
  /// cached across frames to optimize rendering performance.
  static ui.Picture recordStaticPicture({
    required ShanshuiAtmosphereState atmosphere,
    required OutdoorStreetPalette streetPalette,
  }) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1500, 1000));
    OutdoorStreetStaticArchitecture.paintStaticArchitecture(
      canvas,
      const Size(1500, 1000),
      atmosphere: atmosphere,
      streetPalette: streetPalette,
    );
    return recorder.endRecording();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1500.0, size.height / 1000.0);

    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;
    final isDawn = atmosphere.timeOfDay == ShanshuiTimeOfDay.dawn;
    final isWet = atmosphere.weather == ShanshuiWeather.rainy ||
        atmosphere.weather == ShanshuiWeather.stormy;
    final isSnow = atmosphere.weather == ShanshuiWeather.snowy;
    final wind = atmosphere.weather == ShanshuiWeather.stormy ? 1.4 : 1.0;

    // 1. Sky gradient, celestial sun/moon, twinkling stars, lightning
    _paintSkyAndCelestial(canvas, isNight: isNight, isDawn: isDawn);

    // 2. Drifting billowy clouds & distant flying birds
    _paintCloudsAndBirds(canvas, wind: wind, isNight: isNight);

    // 3. Static architecture (from cached Picture or direct call)
    if (cachedStaticPicture != null) {
      canvas.drawPicture(cachedStaticPicture!);
    } else {
      OutdoorStreetStaticArchitecture.paintStaticArchitecture(
        canvas,
        size,
        atmosphere: atmosphere,
        streetPalette: streetPalette,
      );
    }

    // 4. Lantern reflections on stone avenue & puddle ripples
    _paintLanternReflectionsAndRipples(canvas, isWet: isWet, isNight: isNight);

    // 5. Rising food stall steam wisps
    _paintFoodSteam(canvas, isNight: isNight, isDawn: isDawn, wind: wind);

    // 6. Townsfolk crowd lifecycle & oiled-paper umbrellas
    _paintTownsfolkCrowd(canvas, isNight: isNight, isPrecipitation: isWet || isSnow, wind: wind);

    // 7. Swaying red paper lanterns with warm radial glow halos
    _paintStreetLanterns(canvas, isWet: isWet, wind: wind);

    // 8. Ambient overlay, seasonal particles & weather precipitation
    _paintAmbientAndPrecipitation(canvas, isWet: isWet, isSnow: isSnow);

    // 9. Classical calligraphy colophon & cinnabar seal
    if (showCalligraphy) {
      _paintCalligraphyAndSeal(canvas, isNight: isNight);
    }

    // 10. Soft Vignette around canvas borders
    _paintVignette(canvas, isNight: isNight);

    canvas.restore();
  }

  // ===========================================================================
  // 1. Sky, Sun/Moon, Stars & Lightning Flash
  // ===========================================================================
  void _paintSkyAndCelestial(Canvas canvas, {required bool isNight, required bool isDawn}) {
    final skyRect = const Rect.fromLTWH(0, 0, 1500, 540);
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [streetPalette.skyTop, streetPalette.skyBottom],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // Twinkling stars at Night / Dawn
    if (isNight || isDawn) {
      final starCount = isDawn ? 18 : 45;
      final starPaint = Paint();
      for (int i = 0; i < starCount; i++) {
        final sx = 240.0 + ((i * 293) % 1020);
        final sy = 18.0 + ((i * 137) % 240);
        final tw = (isDawn ? 0.2 : 0.35) + 0.5 * math.sin(animationTime * 2.0 + i);
        starPaint.color = Colors.white.withValues(alpha: tw.clamp(0.0, 1.0));
        canvas.drawCircle(Offset(sx, sy), i % 3 == 0 ? 1.9 : 1.2, starPaint);
      }
    }

    // Sun / Moon with celestial glow
    final isDusk = atmosphere.timeOfDay == ShanshuiTimeOfDay.dusk;
    final celX = 955.0;
    final celY = isDawn ? 225.0 : isDusk ? 205.0 : 118.0;
    final celR = isDawn || isDusk ? 54.0 : 46.0;

    final glowPaint = Paint()..color = streetPalette.celestialGlow;
    canvas.drawCircle(Offset(celX, celY), celR * 2.5, glowPaint);

    final celPaint = Paint()..color = streetPalette.celestialColor;
    canvas.drawCircle(Offset(celX, celY), celR, celPaint);

    // Lightning flash overlay in stormy weather
    if (atmosphere.weather == ShanshuiWeather.stormy && lightningAlpha > 0.05) {
      final flashPaint = Paint()
        ..color = Colors.white.withValues(alpha: (lightningAlpha * 0.55).clamp(0.0, 0.7));
      canvas.drawRect(skyRect, flashPaint);

      // Jagged lightning bolt
      final boltPaint = Paint()
        ..color = Colors.white.withValues(alpha: lightningAlpha.clamp(0.0, 1.0))
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
      final bolt = Path()
        ..moveTo(680, 20)
        ..lineTo(705, 110)
        ..lineTo(670, 180)
        ..lineTo(725, 270)
        ..lineTo(690, 340);
      canvas.drawPath(bolt, boltPaint);
    }
  }

  // ===========================================================================
  // 2. Drifting Clouds & Flying Birds
  // ===========================================================================
  void _paintCloudsAndBirds(Canvas canvas, {required double wind, required bool isNight}) {
    final clouds = OutdoorCloud.createDefaultClouds();
    final cloudFill = Paint()
      ..color = isNight
          ? const Color.fromRGBO(55, 72, 92, 0.55)
          : const Color.fromRGBO(255, 252, 244, 0.86);
    final cloudStroke = Paint()
      ..color = isNight
          ? const Color.fromRGBO(30, 42, 55, 0.40)
          : const Color.fromRGBO(160, 140, 115, 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    for (int i = 0; i < clouds.length; i++) {
      final cl = clouds[i];
      final cx = ((cl.x + animationTime * cl.speed * wind) % 1400) + 50;
      final cy = cl.y + math.sin(animationTime * 0.6 + i) * 4;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(cl.scale, cl.scale);

      final p = Path()
        ..addArc(const Rect.fromLTWH(-38, -38, 76, 76), 0.8 * 3.14159, 1.1 * 3.14159)
        ..arcTo(const Rect.fromLTWH(-10, -58, 92, 92), 3.14159, 1.1 * 3.14159, false)
        ..arcTo(const Rect.fromLTWH(48, -32, 68, 68), 1.1 * 3.14159, 1.1 * 3.14159, false)
        ..lineTo(-36, 18)
        ..close();
      canvas.drawPath(p, cloudFill);
      canvas.drawPath(p, cloudStroke);
      canvas.restore();
    }

    // Distant birds drifting across the right sky
    final birdPaint = Paint()
      ..color = isNight ? const Color(0xFFCBD5E1) : const Color(0xFF3B3028)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final birds = const [
      [1085.0, 138.0, 1.0], [1108.0, 125.0, 0.85],
      [1132.0, 134.0, 0.75], [1150.0, 118.0, 0.65],
    ];
    for (int i = 0; i < birds.length; i++) {
      final b = birds[i];
      final flap = math.sin(animationTime * 5.5 + i) * 5;
      final driftX = (animationTime * 14) % 240;
      final curX = b[0] - driftX * 0.4;
      final bs = b[2];

      final bp = Path()
        ..moveTo(curX - 7 * bs, b[1] + flap * bs)
        ..quadraticBezierTo(curX, b[1] - 4 * bs, curX, b[1])
        ..quadraticBezierTo(curX, b[1] - 4 * bs, curX + 7 * bs, b[1] + flap * bs);
      canvas.drawPath(bp, birdPaint);
    }
  }

  // ===========================================================================
  // 3. Lantern Reflections & Stone Avenue Ripples
  // ===========================================================================
  void _paintLanternReflectionsAndRipples(Canvas canvas, {required bool isWet, required bool isNight}) {
    if (streetPalette.candleIntensity > 0.25 || isWet) {
      final reflAlpha = (streetPalette.candleIntensity * 0.35) + (isWet ? 0.22 : 0);
      final reflPaint = Paint()..color = Color.fromRGBO(255, 145, 55, reflAlpha.clamp(0.0, 0.5));

      canvas.drawOval(
        const Rect.fromLTWH(200, 640, 380, 320),
        reflPaint,
      );
      canvas.drawOval(
        const Rect.fromLTWH(920, 640, 380, 320),
        reflPaint,
      );
    }

    // Puddle ripples on the stone street
    if (ripples != null) {
      for (final r in ripples!) {
        final double rx = r is OutdoorPuddleRipple ? r.x : (r as ShanshuiRipple).x;
        final double ry = r is OutdoorPuddleRipple ? r.y : (r as ShanshuiRipple).y;
        final double radius = r is OutdoorPuddleRipple ? r.radius : (r as ShanshuiRipple).radius;
        final double alpha = r is OutdoorPuddleRipple ? r.alpha : (r as ShanshuiRipple).alpha;

        final ripplePaint = Paint()
          ..color = (isNight ? const Color(0xFFDCEBFF) : const Color(0xFF6E5F50))
              .withValues(alpha: alpha.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawOval(
          Rect.fromCenter(center: Offset(rx, ry), width: radius * 2, height: radius * 0.56),
          ripplePaint,
        );
      }
    }
  }

  // ===========================================================================
  // 4. Rising Food Stall Steam Wisps
  // ===========================================================================
  void _paintFoodSteam(
    Canvas canvas, {
    required bool isNight,
    required bool isDawn,
    required double wind,
  }) {
    if (isDawn) return;

    final wisps = OutdoorSteamWisp.createDefaultWisps();
    for (int i = 0; i < wisps.length; i++) {
      final sw = wisps[i];
      if (isNight && sw.isLeftStall) continue;

      final p = (sw.progress + animationTime * 0.12) % 1.0;
      final sx = sw.isLeftStall ? 85.0 : 1235.0;
      final sy = sw.isLeftStall ? 695.0 : 705.0;
      final curX = sx + math.sin(p * math.pi * 3 + animationTime * 2.0 + sw.phase) * (10 + p * 18 * wind);
      final curY = sy - p * 95;
      final alpha = math.sin(p * math.pi) * (isNight ? 0.38 : 0.25);

      final steamPaint = Paint()
        ..color = const Color.fromRGBO(255, 252, 245, 1.0).withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(curX, curY), 4 + p * 13, steamPaint);
    }
  }

  // ===========================================================================
  // 5. Townsfolk Crowd Lifecycle & Oiled-Paper Umbrellas
  // ===========================================================================
  void _paintTownsfolkCrowd(
    Canvas canvas, {
    required bool isNight,
    required bool isPrecipitation,
    required double wind,
  }) {
    final crowd = OutdoorStreetCrowd.getActiveFigures(atmosphere.timeOfDay);
    for (final w in crowd) {
      _drawTownsfolk(canvas, w, isNight: isNight, isPrecipitation: isPrecipitation, wind: wind);
    }
  }

  void _drawTownsfolk(
    Canvas canvas,
    TownsfolkWalker w, {
    required bool isNight,
    required bool isPrecipitation,
    required double wind,
  }) {
    final bobY = (math.sin(animationTime * w.speed * 2.2 + w.phase).abs()) * 6 * w.scale;
    final swayX = math.sin(animationTime * w.speed * 1.1 + w.phase) * 4 * w.scale;
    final cx = w.baseX + swayX;
    final cy = w.baseY - bobY;
    final s = w.scale;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(s, s);

    // Ground cast shadow
    final shadowPaint = Paint()
      ..color = isNight
          ? const Color.fromRGBO(8, 12, 18, 0.55)
          : const Color.fromRGBO(55, 42, 30, 0.32);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 88 + bobY / s), width: 68, height: 22),
      shadowPaint,
    );

    // Legs / trousers with stride
    final legSwing = math.sin(animationTime * w.speed * 2.2 + w.phase) * 7;
    final pantsPaint = Paint()..color = w.pants;
    final strokePaint = Paint()
      ..color = const Color(0xFF231B16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-18, 32, 15, 50 + legSwing * 0.4), const Radius.circular(4)),
      pantsPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-18, 32, 15, 50 + legSwing * 0.4), const Radius.circular(4)),
      strokePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(3, 32, 15, 50 - legSwing * 0.4), const Radius.circular(4)),
      pantsPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(3, 32, 15, 50 - legSwing * 0.4), const Radius.circular(4)),
      strokePaint,
    );

    // Shoes
    final shoePaint = Paint()..color = const Color(0xFF262220);
    canvas.drawOval(Rect.fromCenter(center: Offset(-10, 84 + legSwing * 0.4), width: 18, height: 10), shoePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(10, 84 - legSwing * 0.4), width: 18, height: 10), shoePaint);

    // Outer sleeves / tunic
    final tunic = Path()
      ..moveTo(-22, -26)
      ..quadraticBezierTo(-36, 4, -28, 32)
      ..lineTo(28, 32)
      ..quadraticBezierTo(36, 4, 22, -26)
      ..close();
    canvas.drawPath(tunic, Paint()..color = w.jacket);
    canvas.drawPath(tunic, strokePaint);

    // Waistcoat / vest
    final vestRRect = RRect.fromRectAndRadius(const Rect.fromLTWH(-20, -26, 40, 62), const Radius.circular(6));
    canvas.drawRRect(vestRRect, Paint()..color = w.vest);
    canvas.drawRRect(vestRRect, strokePaint);

    // Center seam & frog buttons
    canvas.drawLine(const Offset(0, -26), const Offset(0, 36), strokePaint);
    for (double by = -14; by <= 22; by += 12) {
      canvas.drawLine(Offset(-5, by), Offset(5, by), strokePaint);
    }

    // Holding cup
    if (w.holdingCup) {
      canvas.drawRect(const Rect.fromLTWH(-14, -4, 11, 13), Paint()..color = const Color(0xFFE8EEF2));
      canvas.drawRect(const Rect.fromLTWH(-14, -4, 11, 13), strokePaint);
    }

    // Head & face
    canvas.drawCircle(const Offset(0, -45), 16, Paint()..color = const Color(0xFFF2D2B6));
    canvas.drawCircle(const Offset(0, -45), 16, strokePaint);

    // Hair cap / bun
    final hair = Path()
      ..addArc(const Rect.fromLTWH(-16.5, -65.5, 33, 33), 0.95 * 3.14159, 1.1 * 3.14159);
    canvas.drawPath(hair, Paint()..color = const Color(0xFF26201D));

    // Oiled-paper umbrella in precipitation weather
    if (isPrecipitation && w.hasUmbrella) {
      canvas.save();
      canvas.translate(10, -68);
      canvas.rotate(0.08 * wind);

      // Bamboo handle
      canvas.drawLine(
        Offset.zero,
        const Offset(0, 62),
        Paint()
          ..color = const Color(0xFF5C3A21)
          ..strokeWidth = 2.5,
      );

      // Umbrella canopy
      final umbrella = Path()
        ..addArc(const Rect.fromLTWH(-44, -36, 88, 88), 3.14159, 3.14159);
      canvas.drawPath(umbrella, Paint()..color = const Color(0xFFD96B43));
      canvas.drawPath(umbrella, strokePaint);

      canvas.restore();
    }

    canvas.restore();
  }

  // ===========================================================================
  // 6. Swaying Red Paper Lanterns
  // ===========================================================================
  void _paintStreetLanterns(Canvas canvas, {required bool isWet, required double wind}) {
    final lanterns = OutdoorLantern.createStreetLanterns();
    final baseSway = math.sin(animationTime * 1.8 * wind) * 0.06 * wind;
    final flicker1 = math.sin(animationTime * 7.2) * 0.5 + math.cos(animationTime * 12.5) * 0.5;
    final flicker2 = math.sin(animationTime * 6.4 + 1.2) * 0.5 + math.sin(animationTime * 11.1) * 0.5;

    final autoLantern = (streetPalette.candleIntensity + (isWet ? 0.35 : 0.0)).clamp(0.0, 1.0);

    for (int i = 0; i < lanterns.length; i++) {
      final lt = lanterns[i];
      final sw = baseSway * math.cos(animationTime * 1.5 + lt.phase);
      final fl = i % 2 == 0 ? flicker1 : flicker2;
      _drawSingleLantern(canvas, lt.x, lt.y, lt.rx, lt.ry, sw, autoLantern, fl);
    }

    // 2 Paifang hanging lanterns
    _drawSingleLantern(canvas, 648, 484, 13, 11, baseSway, autoLantern, flicker1);
    _drawSingleLantern(canvas, 852, 484, 13, 11, -baseSway, autoLantern, flicker2);
  }

  void _drawSingleLantern(
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

    // Warm radial glow halo
    if (glow > 0.08) {
      final haloR = rx * (3.6 + flicker * 0.25);
      final haloPaint = Paint()
        ..color = Color.fromRGBO(255, 140, 50, (0.35 * glow).clamp(0.0, 0.6));
      canvas.drawCircle(Offset.zero, haloR, haloPaint);
    }

    // Lantern silk body
    final bodyOval = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);
    final bodyPaint = Paint()
      ..color = glow > 0.25 ? const Color(0xFFFF6B35) : const Color(0xFFC83728);
    canvas.drawOval(bodyOval, bodyPaint);
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
    canvas.drawRect(Rect.fromLTWH(-rx * 0.42, -ry - 3, rx * 0.84, 5), capPaint);
    canvas.drawRect(Rect.fromLTWH(-rx * 0.42, ry - 2, rx * 0.84, 5), capPaint);

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

  // ===========================================================================
  // 7. Ambient Overlay, Seasonal Particles & Weather Drops
  // ===========================================================================
  void _paintAmbientAndPrecipitation(Canvas canvas, {required bool isWet, required bool isSnow}) {
    // Ambient color wash
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1500, 1000), Paint()..color = streetPalette.ambientOverlay);

    // Seasonal Particles
    final p1 = Paint()..color = streetPalette.particleColor1.withValues(alpha: 0.85);
    final p2 = Paint()..color = streetPalette.particleColor2.withValues(alpha: 0.85);

    for (final pt in particles) {
      final paint = pt.colorToggle ? p1 : p2;
      canvas.save();
      canvas.translate(pt.x, pt.y);
      canvas.rotate(pt.angle);

      if (streetPalette.particleType == 'snow') {
        canvas.drawCircle(Offset.zero, pt.size * 0.55, paint);
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: pt.size * 2, height: pt.size * 0.96),
          paint,
        );
      }
      canvas.restore();
    }

    // Weather drops (rain or snow)
    if (isWet) {
      final dropPaint = Paint()
        ..color = const Color.fromRGBO(80, 100, 115, 0.42)
        ..strokeWidth = 1.3;
      for (final d in weatherDrops) {
        canvas.drawLine(Offset(d.x, d.y), Offset(d.x - 2.6, d.y + d.len), dropPaint);
      }
    } else if (isSnow) {
      final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.82);
      for (final d in weatherDrops) {
        canvas.drawCircle(Offset(d.x, d.y), d.size * 0.72, snowPaint);
      }
    }
  }

  // ===========================================================================
  // 8. Vertical Calligraphy Colophon & Cinnabar Seal
  // ===========================================================================
  void _paintCalligraphyAndSeal(Canvas canvas, {required bool isNight}) {
    canvas.save();
    final title = atmosphere.season.nameZhFor(ShanshuiRealm.outdoor).replaceAll(' · ', '');
    final textColor = isNight
        ? const Color.fromRGBO(248, 244, 232, 0.90)
        : const Color.fromRGBO(42, 30, 22, 0.86);

    for (int i = 0; i < title.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: title[i],
          style: TextStyle(
            color: textColor,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
            shadows: [
              Shadow(
                color: isNight ? Colors.black54 : Colors.white70,
                blurRadius: 6,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(388, 62.0 + i * 30.0));
    }

    // Carved Cinnabar Seal Stamp
    final sealText = atmosphere.season.sealTextFor(ShanshuiRealm.outdoor);
    final sealX = 378.0;
    final sealY = 68.0 + title.length * 30.0;

    canvas.drawRect(Rect.fromLTWH(sealX, sealY, 36, 36), Paint()..color = const Color(0xFFB8332A));
    canvas.drawRect(
      Rect.fromLTWH(sealX + 3, sealY + 3, 30, 30),
      Paint()
        ..color = const Color(0xFFF7F4EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    if (sealText.length >= 4) {
      final tp1 = TextPainter(
        text: TextSpan(
          text: sealText.substring(0, 2),
          style: const TextStyle(
            color: Color(0xFFF7F4EB),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp1.paint(canvas, Offset(sealX + 5, sealY + 5));

      final tp2 = TextPainter(
        text: TextSpan(
          text: sealText.substring(2, 4),
          style: const TextStyle(
            color: Color(0xFFF7F4EB),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp2.paint(canvas, Offset(sealX + 5, sealY + 18));
    }

    canvas.restore();
  }

  // ===========================================================================
  // 9. Soft Vignette Edge Gradient
  // ===========================================================================
  void _paintVignette(Canvas canvas, {required bool isNight}) {
    final vigPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [
          Colors.transparent,
          isNight ? const Color.fromRGBO(5, 8, 14, 0.48) : const Color.fromRGBO(38, 24, 14, 0.22),
        ],
        stops: const [0.65, 1.0],
      ).createShader(const Rect.fromLTWH(0, 0, 1500, 1000));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1500, 1000), vigPaint);
  }

  @override
  bool shouldRepaint(covariant OutdoorStreetPainter oldDelegate) {
    return oldDelegate.animationTime != animationTime ||
        oldDelegate.atmosphere != atmosphere ||
        oldDelegate.lightningAlpha != lightningAlpha ||
        oldDelegate.showCalligraphy != showCalligraphy ||
        oldDelegate.fullPoem != fullPoem;
  }
}
