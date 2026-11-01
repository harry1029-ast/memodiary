import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/ancient_room_palette.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_scenery_geometry.dart';
import 'ancient_room_static_architecture.dart';

/// Full interactive vector painter for the Indoor Scholar Tea Hall (`雅室`) realm.
///
/// Combines a cached static architectural `ui.Picture` layer with dynamic 60 FPS
/// animations: live outdoor weather visible through the Moon Window (`月洞窗`),
/// volumetric sun/moon beams, curling incense smoke & tea steam, glowing lanterns,
/// winter red-clay charcoal embers (`红泥小火炉`), floating petals/motes, and
/// classical calligraphy colophons.
class AncientRoomPainter extends CustomPainter {
  final ShanshuiAtmosphereState atmosphere;
  final AncientRoomPalette roomPalette;
  final double animationTime;
  final List<ShanshuiParticle> particles;
  final List<ShanshuiWeatherDrop> weatherDrops;
  final List<dynamic>? cranes;
  final List<dynamic>? ripples;
  final bool showCalligraphy;
  final bool fullPoem;
  final double lightningAlpha;
  final ui.Picture? cachedStaticPicture;

  AncientRoomPainter({
    required this.atmosphere,
    AncientRoomPalette? roomPalette,
    required this.animationTime,
    required this.particles,
    required this.weatherDrops,
    this.cranes,
    this.ripples,
    this.showCalligraphy = false,
    this.fullPoem = false,
    this.lightningAlpha = 0.0,
    this.cachedStaticPicture,
  }) : roomPalette = roomPalette ??
            AncientRoomPalette.of(atmosphere.season, atmosphere.timeOfDay);

  /// Records static architectural geometry into an immutable `ui.Picture`
  /// cached across frames to optimize rendering performance.
  static ui.Picture recordStaticPicture({
    required ShanshuiAtmosphereState atmosphere,
    required AncientRoomPalette roomPalette,
  }) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1500, 1000));
    AncientRoomStaticArchitecture.paintStaticArchitecture(
      canvas,
      const Size(1500, 1000),
      atmosphere: atmosphere,
      roomPalette: roomPalette,
    );
    return recorder.endRecording();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1500.0, size.height / 1000.0);

    // 1. Static room architecture (from cached Picture or direct call)
    if (cachedStaticPicture != null) {
      canvas.drawPicture(cachedStaticPicture!);
    } else {
      AncientRoomStaticArchitecture.paintStaticArchitecture(
        canvas,
        size,
        atmosphere: atmosphere,
        roomPalette: roomPalette,
      );
    }

    // 2. Live Outdoor Courtyard clipped to Left Moon Window (月洞窗)
    _paintLiveMoonWindow(canvas);

    // 3. Volumetric Sun/Moon Light Beams
    _paintVolumetricLightBeams(canvas);

    // 4. Dynamic Lighting: Lanterns, Candle Flames, Charcoal Brazier
    _paintDynamicLighting(canvas);

    // 5. Incense Smoke and Tea Steam Wisps
    _paintSmokeAndSteam(canvas);

    // 6. Floating Indoor Dust Motes and Blossom Petals
    _paintIndoorParticles(canvas);

    // 7. Ambient Weather Dimming & Lightning Flash Overlays
    _paintAmbientRoomOverlays(canvas);

    // 8. Vertical Calligraphy Colophon and Cinnabar Seal
    if (showCalligraphy) {
      _paintCalligraphyAndSeal(canvas);
    }

    canvas.restore();
  }

  /// 2. Live Outdoor Courtyard clipped within elliptical Moon Window.
  void _paintLiveMoonWindow(Canvas canvas) {
    const windowCenter = Offset(205, 415);
    const radiusX = 134.0;
    const radiusY = 164.0;

    canvas.save();
    final clipPath = Path()
      ..addOval(
        Rect.fromCenter(center: windowCenter, width: radiusX * 2, height: radiusY * 2),
      );
    canvas.clipPath(clipPath);

    // Sky Gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [roomPalette.skyTop, roomPalette.skyBottom],
      ).createShader(Rect.fromCenter(center: windowCenter, width: radiusX * 2, height: radiusY * 2));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 500, 800), skyPaint);

    // Twinkling stars at Night/Dawn
    if (atmosphere.timeOfDay == ShanshuiTimeOfDay.night ||
        atmosphere.timeOfDay == ShanshuiTimeOfDay.dawn) {
      final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
      for (int i = 0; i < 12; i++) {
        final sx = 120.0 + (i * 23.0) % 170.0;
        final sy = 280.0 + (i * 37.0) % 140.0;
        final twinkle = 0.5 + 0.5 * math.sin(animationTime * 2.5 + i);
        canvas.drawCircle(Offset(sx, sy), 1.2 * twinkle, starPaint);
      }
    }

    // Celestial Body (Sun / Moon)
    final celestialPos = const Offset(195, 335);
    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;
    final celestialGlowPaint = Paint()..color = roomPalette.celestialGlow;
    canvas.drawCircle(celestialPos, isNight ? 28.0 : 36.0, celestialGlowPaint);

    final celestialPaint = Paint()..color = roomPalette.celestialColor;
    canvas.drawCircle(celestialPos, isNight ? 16.0 : 20.0, celestialPaint);

    // Lightning bolt in stormy weather
    if (atmosphere.weather == ShanshuiWeather.stormy && lightningAlpha > 0.05) {
      final boltPaint = Paint()
        ..color = Colors.white.withValues(alpha: lightningAlpha.clamp(0.0, 1.0))
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      final boltPath = Path()
        ..moveTo(220, 260)
        ..lineTo(210, 310)
        ..lineTo(225, 340)
        ..lineTo(205, 400)
        ..lineTo(215, 450);
      canvas.drawPath(boltPath, boltPaint);
    }

    // Swaying Courtyard Bough & Foliage Clusters
    final windSway = math.sin(animationTime * 1.8) * 6.0;
    _paintCourtyardTree(canvas, windowCenter, windSway);

    // Weather drops (Rain streaks / Snowflakes)
    final dropPaint = Paint()
      ..color = atmosphere.weather == ShanshuiWeather.snowy
          ? const Color(0xFFF8FAFC)
          : const Color.fromRGBO(200, 220, 240, 0.65)
      ..strokeWidth = atmosphere.weather == ShanshuiWeather.snowy ? 3.0 : 1.6;

    for (final drop in weatherDrops) {
      if (drop.x < 360 && drop.y > 240 && drop.y < 600) {
        if (atmosphere.weather == ShanshuiWeather.snowy) {
          canvas.drawCircle(Offset(drop.x, drop.y), drop.size * 0.75, dropPaint);
        } else {
          canvas.drawLine(
            Offset(drop.x, drop.y),
            Offset(drop.x - 3.0, drop.y + drop.len * 0.5),
            dropPaint,
          );
        }
      }
    }

    // Drifting seasonal petals/leaves outside the window
    for (final particle in particles) {
      if (particle.x < 360 && particle.y > 240 && particle.y < 600) {
        final petalPaint = Paint()
          ..color = particle.colorToggle
              ? roomPalette.particleColor1
              : roomPalette.particleColor2;
        canvas.drawCircle(Offset(particle.x, particle.y), particle.size * 0.8, petalPaint);
      }
    }

    canvas.restore();
  }

  void _paintCourtyardTree(Canvas canvas, Offset center, double windSway) {
    final hasSnow = atmosphere.season == ShanshuiSeason.winter ||
        atmosphere.weather == ShanshuiWeather.snowy;

    // Tree branches
    final branchPaint = Paint()
      ..color = const Color(0xFF261D17)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final branchPath = Path()
      ..moveTo(center.dx - 110, center.dy + 80)
      ..quadraticBezierTo(
        center.dx - 40,
        center.dy + 20,
        center.dx + 40 + windSway,
        center.dy - 30,
      )
      ..quadraticBezierTo(
        center.dx + 80 + windSway,
        center.dy - 60,
        center.dx + 110 + windSway,
        center.dy - 90,
      );
    canvas.drawPath(branchPath, branchPaint);

    // Foliage clusters
    final primaryPaint = Paint()..color = roomPalette.foliagePrimary;
    final secondaryPaint = Paint()..color = roomPalette.foliageSecondary;

    canvas.drawCircle(Offset(center.dx + 20 + windSway, center.dy - 20), 28, primaryPaint);
    canvas.drawCircle(Offset(center.dx + 55 + windSway, center.dy - 50), 32, secondaryPaint);
    canvas.drawCircle(Offset(center.dx + 90 + windSway, center.dy - 85), 24, primaryPaint);

    if (hasSnow) {
      final snowCapPaint = Paint()..color = const Color(0xFFF8FAFC);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(center.dx + 55 + windSway, center.dy - 58), radius: 32),
        math.pi,
        math.pi,
        true,
        snowCapPaint,
      );
    }
  }

  /// 3. Volumetric screen light beams projecting from Moon Window onto floorboards.
  void _paintVolumetricLightBeams(Canvas canvas) {
    final beamMultiplier = atmosphere.weather.indoorBeamMultiplier;
    if (beamMultiplier <= 0.05) return;

    final beamPaint = Paint()
      ..blendMode = BlendMode.screen
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          roomPalette.lightBeamColor.withValues(alpha: 0.22 * beamMultiplier),
          roomPalette.lightBeamColor.withValues(alpha: 0.0),
        ],
      ).createShader(const Rect.fromLTWH(200, 350, 750, 500));

    final beamPath = Path()
      ..moveTo(210, 320)
      ..lineTo(340, 480)
      ..lineTo(860, 940)
      ..lineTo(440, 940)
      ..close();
    canvas.drawPath(beamPath, beamPaint);

    // Floor highlight patch
    final floorPatchPaint = Paint()
      ..blendMode = BlendMode.screen
      ..color = roomPalette.floorPatchColor.withValues(alpha: 0.26 * beamMultiplier);
    canvas.drawOval(
      const Rect.fromLTWH(420, 840, 380, 90),
      floorPatchPaint,
    );
  }

  /// 4. Dynamic Lighting: Lantern glow, candle flames, charcoal brazier embers.
  void _paintDynamicLighting(Canvas canvas) {
    final flicker = 0.85 + 0.15 * math.sin(animationTime * 9.0);
    final intensity = (roomPalette.candleIntensity * flicker).clamp(0.0, 1.0);

    // Wall lantern flame & radial glow (1278, 354)
    if (intensity > 0.08) {
      final wallGlowPaint = Paint()
        ..color = Color.fromRGBO(255, 175, 75, 0.32 * intensity);
      canvas.drawCircle(const Offset(1278, 354), 58 * intensity, wallGlowPaint);

      final wallFlamePaint = Paint()
        ..color = const Color(0xFFFFECC4).withValues(alpha: intensity);
      canvas.drawCircle(const Offset(1278, 354), 6 * intensity, wallFlamePaint);
    }

    // Miniature table lantern glow (974, 825)
    if (intensity > 0.05) {
      final tableGlowPaint = Paint()
        ..color = Color.fromRGBO(255, 185, 90, 0.28 * intensity);
      canvas.drawCircle(const Offset(974, 825), 44 * intensity, tableGlowPaint);
    }

    // Winter charcoal brazier glowing embers (330, 640)
    final hasSnow = atmosphere.season == ShanshuiSeason.winter ||
        atmosphere.weather == ShanshuiWeather.snowy;
    if (hasSnow) {
      final emberPulse = 0.7 + 0.3 * math.sin(animationTime * 4.2);
      final emberPaint = Paint()
        ..color = Color.fromRGBO(255, 75, 30, 0.55 * emberPulse);
      canvas.drawOval(
        const Rect.fromLTWH(312, 632, 36, 16),
        emberPaint,
      );

      final emberHotPaint = Paint()
        ..color = Color.fromRGBO(255, 200, 70, 0.85 * emberPulse);
      canvas.drawOval(
        const Rect.fromLTWH(320, 635, 20, 10),
        emberHotPaint,
      );
    }
  }

  /// 5. Incense smoke & tea steam wisps rising from burner and teapot.
  void _paintSmokeAndSteam(Canvas canvas) {
    // Teapot steam (735, 830)
    final steamPaint = Paint()
      ..color = const Color.fromRGBO(240, 248, 255, 0.35)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final steamTime = animationTime * 1.5;
    final steamPath = Path()
      ..moveTo(735, 830)
      ..quadraticBezierTo(
        735 + math.sin(steamTime) * 12.0,
        800,
        735 + math.cos(steamTime) * 18.0,
        760,
      );
    canvas.drawPath(steamPath, steamPaint);

    // Incense smoke (540, 816)
    final smokePaint = Paint()
      ..color = const Color.fromRGBO(210, 220, 230, 0.38)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final smokeTime = animationTime * 1.2;
    final smokePath = Path()
      ..moveTo(540, 816)
      ..quadraticBezierTo(
        540 + math.cos(smokeTime) * 16.0,
        780,
        540 + math.sin(smokeTime) * 22.0,
        735,
      )
      ..quadraticBezierTo(
        540 + math.cos(smokeTime * 0.8) * 32.0,
        690,
        540 + math.sin(smokeTime * 0.7) * 40.0,
        640,
      );
    canvas.drawPath(smokePath, smokePaint);
  }

  /// 6. Floating indoor dust motes and blossom petal swirls.
  void _paintIndoorParticles(Canvas canvas) {
    for (final particle in particles) {
      if (particle.x >= 340) {
        final motePaint = Paint()
          ..color = (particle.colorToggle
                  ? roomPalette.particleColor1
                  : roomPalette.particleColor2)
              .withValues(alpha: 0.75);
        canvas.drawCircle(Offset(particle.x, particle.y), particle.size * 0.9, motePaint);
      }
    }
  }

  /// 7. Ambient weather dimming and stormy room lightning flashes.
  void _paintAmbientRoomOverlays(Canvas canvas) {
    final dimming = atmosphere.weather.indoorRoomDimming;
    if (dimming > 0.0) {
      final dimPaint = Paint()
        ..color = const Color(0xFF101418).withValues(alpha: dimming);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 1500, 1000), dimPaint);
    }

    if (atmosphere.weather == ShanshuiWeather.stormy && lightningAlpha > 0.08) {
      final flashPaint = Paint()
        ..color = Colors.white.withValues(alpha: (lightningAlpha * 0.25).clamp(0.0, 0.4));
      canvas.drawRect(const Rect.fromLTWH(0, 0, 1500, 1000), flashPaint);
    }
  }

  /// 8. Vertical calligraphy title, couplet, and 4-character cinnabar seal.
  void _paintCalligraphyAndSeal(Canvas canvas) {
    final title = atmosphere.season.nameZhFor(atmosphere.realm);
    final titleSpan = TextSpan(
      text: title,
      style: const TextStyle(
        fontFamily: 'NotoSerifSC',
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C241E),
        shadows: [
          Shadow(
            color: Color(0x66FFFFFF),
            offset: Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );
    final titlePainter = TextPainter(
      text: titleSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(canvas, const Offset(60, 60));

    if (fullPoem) {
      final poem = atmosphere.season.poemFor(atmosphere.realm);
      final poemSpan = TextSpan(
        text: poem,
        style: const TextStyle(
          fontFamily: 'NotoSerifSC',
          fontSize: 18.0,
          color: Color(0xFF4A3B32),
          letterSpacing: 2.0,
        ),
      );
      final poemPainter = TextPainter(
        text: poemSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      poemPainter.paint(canvas, const Offset(60, 104));
    }

    // 4-Character Cinnabar Seal
    final sealText = atmosphere.season.sealTextFor(atmosphere.realm);
    final sealRect = const Rect.fromLTWH(60, 138, 52, 52);
    final sealBgPaint = Paint()..color = const Color(0xFFB33628);
    canvas.drawRRect(
      RRect.fromRectAndRadius(sealRect, const Radius.circular(6)),
      sealBgPaint,
    );

    final sealTextSpan = TextSpan(
      text: sealText,
      style: const TextStyle(
        fontFamily: 'NotoSerifSC',
        fontSize: 10.0,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
    final sealPainter = TextPainter(
      text: sealTextSpan,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: 48);
    sealPainter.paint(canvas, const Offset(65, 145));
  }

  @override
  bool shouldRepaint(AncientRoomPainter oldDelegate) {
    return animationTime != oldDelegate.animationTime ||
        atmosphere != oldDelegate.atmosphere ||
        particles.length != oldDelegate.particles.length ||
        weatherDrops.length != oldDelegate.weatherDrops.length ||
        lightningAlpha != oldDelegate.lightningAlpha ||
        cachedStaticPicture != oldDelegate.cachedStaticPicture;
  }
}
