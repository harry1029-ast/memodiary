import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/ancient_room_palette.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_scenery_geometry.dart';
import 'ancient_room_furniture_layers.dart';

/// Live courtyard renderer and perspective-rotated frame helpers for the left
/// Moon Window (`月洞窗`) in the Indoor Tea Hall (`室内`).
class AncientRoomWindowLayer {
  const AncientRoomWindowLayer._();

  static const Offset moonWindowCenter = Offset(65.0, 435.0);
  static const double moonWindowRx = 175.0;
  static const double moonWindowRy = 278.0;
  static const double moonWindowRotation = -0.04;

  /// Builds the perspective-rotated elliptical clip path for the left Moon Window (`月洞窗`).
  static Path buildMoonWindowClipPath() {
    final matrix = Matrix4.translationValues(
      moonWindowCenter.dx,
      moonWindowCenter.dy,
      0.0,
    )..rotateZ(moonWindowRotation);
    return (Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: moonWindowRx * 2,
              height: moonWindowRy * 2,
            ),
          ))
        .transform(matrix.storage);
  }

  /// Paints the heavy rosewood Moon Window frame, inner bevel highlight, and
  /// conditional Winter/Snow sill snow accumulation on top of the window opening.
  static void paintMoonWindowFrame(
    Canvas canvas,
    AncientRoomPalette palette, {
    required bool hasSnow,
  }) {
    canvas.save();
    canvas.translate(moonWindowCenter.dx, moonWindowCenter.dy);
    canvas.rotate(moonWindowRotation);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: moonWindowRx * 2,
        height: moonWindowRy * 2,
      ),
      Paint()
        ..color = palette.woodDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22.0,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: const Offset(6.0, 0.0),
        width: (moonWindowRx - 6.0) * 2,
        height: (moonWindowRy - 6.0) * 2,
      ),
      -math.pi * 0.45,
      math.pi * 0.90,
      false,
      Paint()
        ..color = palette.woodHighlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0,
    );

    if (hasSnow) {
      canvas.drawArc(
        Rect.fromCenter(
          center: const Offset(4.0, -4.0),
          width: (moonWindowRx - 8.0) * 2,
          height: (moonWindowRy - 8.0) * 2,
        ),
        math.pi * 0.18,
        math.pi * 0.28,
        false,
        Paint()
          ..color = const Color(0xFFF8FAFC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9.0
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  /// Clips the live outdoor courtyard inside the Moon Window, paints sky, weather
  /// overlays, stars, sun/moon, mountain, mist, lightning, swaying seasonal tree,
  /// outdoor particles/fireflies, and precipitation, restores clip, then draws
  /// the rosewood frame and snow sill on top so they are never occluded.
  static void paintLiveMoonWindow(
    Canvas canvas, {
    required ShanshuiAtmosphereState atmosphere,
    required AncientRoomPalette roomPalette,
    required double animationTime,
    required List<ShanshuiParticle> particles,
    required List<ShanshuiWeatherDrop> weatherDrops,
    required double lightningAlpha,
  }) {
    final isWinter = atmosphere.season == ShanshuiSeason.winter;
    final isSnowWeather = atmosphere.weather == ShanshuiWeather.snowy;
    final hasSnowCover = isWinter || isSnowWeather;
    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;
    final isDawn = atmosphere.timeOfDay == ShanshuiTimeOfDay.dawn;
    final isDusk = atmosphere.timeOfDay == ShanshuiTimeOfDay.dusk;
    final windFactor = atmosphere.weather.windFactor;
    final parallaxX = math.sin(animationTime * 0.3) * 5.0;
    final parallaxY = math.cos(animationTime * 0.25) * 3.0;

    final winCenterY = moonWindowCenter.dy;
    const winRadiusY = moonWindowRy;
    final windowRect = Rect.fromLTWH(
      -120,
      winCenterY - winRadiusY - 10,
      390,
      winRadiusY * 2 + 20,
    );

    canvas.save();
    canvas.clipPath(buildMoonWindowClipPath());

    // 3A. Outdoor Sky Gradient + Weather Sky Overlay + Lightning Flash
    canvas.drawRect(
      windowRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, winCenterY - winRadiusY),
          Offset(0, winCenterY + winRadiusY),
          [roomPalette.skyTop, roomPalette.skyBottom],
        ),
    );
    if (atmosphere.weather.skyOverlay != null) {
      canvas.drawRect(
        windowRect,
        Paint()..color = atmosphere.weather.skyOverlay!,
      );
    }
    if (atmosphere.weather == ShanshuiWeather.stormy && lightningAlpha > 0.02) {
      canvas.drawRect(
        windowRect,
        Paint()
          ..color = Color.fromRGBO(
            240,
            248,
            255,
            (lightningAlpha * 0.75).clamp(0.0, 1.0),
          ),
      );
    }

    // 3B. Night / Dawn Twinkling Stars outside window
    if ((isNight || isDawn) &&
        (atmosphere.weather == ShanshuiWeather.sunny ||
            atmosphere.weather == ShanshuiWeather.snowy)) {
      final starCount = isDawn ? 8 : 22;
      for (int starIndex = 0; starIndex < starCount; starIndex++) {
        final starX = 25.0 + ((starIndex * 67) % 190);
        final starY = 190.0 + ((starIndex * 43) % 210);
        final twinkle = ((isDawn ? 0.2 : 0.35) +
                0.5 * math.sin(animationTime * 2.1 + starIndex))
            .clamp(0.0, 1.0);
        canvas.drawCircle(
          Offset(starX, starY),
          starIndex % 3 == 0 ? 1.8 : 1.2,
          Paint()..color = Color.fromRGBO(255, 255, 245, twinkle),
        );
      }
    }

    // 3C. Celestial Body (Sun at Dawn/Day/Dusk, Moon at Night)
    final celX = 128.0 - parallaxX * 0.45;
    final celY = (isDawn ? 430.0 : (isDusk ? 405.0 : 285.0)) - parallaxY * 0.3;
    final celRadius = (isDawn || isDusk) ? 38.0 : 32.0;
    final celCenter = Offset(celX, celY);
    final celAlpha = atmosphere.weather.celestialAlpha;

    canvas.drawCircle(
      celCenter,
      celRadius * 3.2,
      Paint()
        ..shader = ui.Gradient.radial(
          celCenter,
          celRadius * 3.2,
          [
            roomPalette.celestialGlow.withValues(
              alpha: (roomPalette.celestialGlow.a * celAlpha).clamp(0.0, 1.0),
            ),
            const Color(0x00000000),
          ],
          const [0.2 / 3.2, 1.0],
        ),
    );
    canvas.drawCircle(
      celCenter,
      celRadius,
      Paint()
        ..color = roomPalette.celestialColor.withValues(
          alpha: ((isNight ? 0.95 : 0.88) * celAlpha).clamp(0.0, 1.0),
        ),
    );

    // 3D. Distant Courtyard Mountain Silhouette & Drifting Mist
    final mountainPath = Path()
      ..moveTo(-20, 560)
      ..quadraticBezierTo(85, 465, 165, 515)
      ..quadraticBezierTo(215, 480, 260, 545)
      ..lineTo(260, 740)
      ..lineTo(-20, 740)
      ..close();
    canvas.drawPath(
      mountainPath,
      Paint()
        ..color = isNight
            ? const Color(0xFF1B2836)
            : const Color.fromRGBO(110, 125, 118, 0.38),
    );

    final mistOffset = (animationTime * 16.0 * windFactor) % 300.0;
    final mistPaint = Paint()..color = roomPalette.courtyardMist;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(60 + mistOffset * 0.4, 485),
        width: 280,
        height: 56,
      ),
      mistPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(180 - mistOffset * 0.3, 360),
        width: 260,
        height: 48,
      ),
      mistPaint,
    );

    // Stormy multi-segment jagged lightning bolt
    if (atmosphere.weather == ShanshuiWeather.stormy && lightningAlpha > 0.08) {
      final boltSeed = (animationTime * 0.6).floor();
      final boltRng = math.Random(boltSeed + 7);
      double currX = 110.0 + boltRng.nextDouble() * 140.0;
      double currY = 140.0;
      final boltPath = Path()..moveTo(currX, currY);
      for (int segIndex = 0; segIndex < 7; segIndex++) {
        currX += (boltRng.nextDouble() - 0.5) * 45.0;
        currY += 35.0 + boltRng.nextDouble() * 25.0;
        boltPath.lineTo(currX, currY);
      }
      canvas.drawPath(
        boltPath,
        Paint()
          ..color = Colors.white.withValues(alpha: lightningAlpha.clamp(0.0, 1.0))
          ..strokeWidth = 2.6
          ..style = PaintingStyle.stroke,
      );
    }

    // 3E. Swaying Courtyard Tree & 5 Foliage Clusters
    final branchSway = math.sin(animationTime * 1.4 * windFactor) * (4.5 * windFactor);
    _paintCourtyardTree(
      canvas,
      roomPalette: roomPalette,
      branchSway: branchSway,
      parallaxX: parallaxX,
      hasSnowCover: hasSnowCover,
    );

    // 3F. Outdoor Petals / Fireflies / Leaves / Snow inside Moon Window
    _paintOutdoorParticles(
      canvas,
      atmosphere: atmosphere,
      roomPalette: roomPalette,
      animationTime: animationTime,
      particles: particles,
    );

    // 3G. Outdoor Rain / Storm / Snow Precipitation inside Moon Window
    _paintOutdoorPrecipitation(
      canvas,
      atmosphere: atmosphere,
      weatherDrops: weatherDrops,
      isNight: isNight,
    );

    canvas.restore();

    // 3H. Heavy Rosewood Circular Moon Window Frame & Snow Sill drawn AFTER restoring clip
    paintMoonWindowFrame(canvas, roomPalette, hasSnow: hasSnowCover);
  }

  static void _paintCourtyardTree(
    Canvas canvas, {
    required AncientRoomPalette roomPalette,
    required double branchSway,
    required double parallaxX,
    required bool hasSnowCover,
  }) {
    final branchPaint = Paint()
      ..color = const Color(0xFF2B211B)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final branchPath = Path()
      ..moveTo(145 - parallaxX * 0.25, 690)
      ..quadraticBezierTo(132 - parallaxX * 0.25, 550, 155 + branchSway, 455)
      ..moveTo(140 - parallaxX * 0.25, 560)
      ..quadraticBezierTo(95, 515, 55 + branchSway, 490)
      ..moveTo(148 - parallaxX * 0.25, 510)
      ..quadraticBezierTo(190, 470, 215 + branchSway, 440);
    canvas.drawPath(branchPath, branchPaint);

    AncientRoomFurnitureLayers.paintFoliageCluster(
      canvas,
      Offset(152 + branchSway, 455),
      42,
      roomPalette.foliagePrimary,
      isSnowCapped: hasSnowCover,
    );
    AncientRoomFurnitureLayers.paintFoliageCluster(
      canvas,
      Offset(105 + branchSway * 0.8, 485),
      36,
      roomPalette.foliageSecondary,
      isSnowCapped: hasSnowCover,
    );
    AncientRoomFurnitureLayers.paintFoliageCluster(
      canvas,
      Offset(62 + branchSway * 0.9, 505),
      32,
      roomPalette.foliagePrimary,
      isSnowCapped: hasSnowCover,
    );
    AncientRoomFurnitureLayers.paintFoliageCluster(
      canvas,
      Offset(195 + branchSway * 1.1, 450),
      34,
      roomPalette.foliageAccent,
      isSnowCapped: hasSnowCover,
    );
    AncientRoomFurnitureLayers.paintFoliageCluster(
      canvas,
      Offset(140 + branchSway * 0.6, 535),
      38,
      roomPalette.foliageSecondary,
      isSnowCapped: hasSnowCover,
    );
  }

  static void _paintOutdoorParticles(
    Canvas canvas, {
    required ShanshuiAtmosphereState atmosphere,
    required AncientRoomPalette roomPalette,
    required double animationTime,
    required List<ShanshuiParticle> particles,
  }) {
    final isSummerFireflyWeather = atmosphere.season == ShanshuiSeason.summer &&
        atmosphere.weather != ShanshuiWeather.rainy &&
        atmosphere.weather != ShanshuiWeather.stormy &&
        atmosphere.weather != ShanshuiWeather.snowy;

    for (final particle in particles) {
      final outX = particle.x % 260.0;
      final outY = 150.0 + (particle.y % 560.0);
      if (isSummerFireflyWeather) {
        final fireflyY = 680.0 - ((particle.y + animationTime * 24.0) % 530.0);
        final fireflyX =
            (outX + math.sin(animationTime * 1.5 + particle.phase) * 8.0) % 260.0;
        final pulse =
            0.35 + 0.65 * math.sin(animationTime * 2.8 + particle.phase).abs();
        final color = (particle.colorToggle
                ? roomPalette.particleColor1
                : roomPalette.particleColor2)
            .withValues(alpha: pulse.clamp(0.0, 1.0));
        canvas.drawCircle(
          Offset(fireflyX, fireflyY),
          particle.size * 0.7,
          Paint()..color = color,
        );
      } else {
        canvas.save();
        canvas.translate(outX, outY);
        canvas.rotate(particle.angle);
        final color = (particle.colorToggle
                ? roomPalette.particleColor1
                : roomPalette.particleColor2)
            .withValues(alpha: 0.85);
        final paint = Paint()..color = color;
        if (atmosphere.season == ShanshuiSeason.winter) {
          canvas.drawCircle(Offset.zero, particle.size * 0.55, paint);
        } else {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size * 2.0,
              height: particle.size,
            ),
            paint,
          );
        }
        canvas.restore();
      }
    }
  }

  static void _paintOutdoorPrecipitation(
    Canvas canvas, {
    required ShanshuiAtmosphereState atmosphere,
    required List<ShanshuiWeatherDrop> weatherDrops,
    required bool isNight,
  }) {
    if (atmosphere.weather == ShanshuiWeather.rainy ||
        atmosphere.weather == ShanshuiWeather.stormy) {
      final isStorm = atmosphere.weather == ShanshuiWeather.stormy;
      final slantX = isStorm ? -5.5 : -2.2;
      final rainPaint = Paint()
        ..color = isNight
            ? const Color.fromRGBO(210, 230, 245, 0.52)
            : const Color.fromRGBO(90, 110, 125, 0.45)
        ..strokeWidth = isStorm ? 1.8 : 1.3;
      for (final drop in weatherDrops) {
        final dropX = drop.x % 280.0;
        final dropY = 140.0 + (drop.y % 580.0);
        canvas.drawLine(
          Offset(dropX, dropY),
          Offset(dropX + slantX * 2.0, dropY + drop.len),
          rainPaint,
        );
      }
    } else if (atmosphere.weather == ShanshuiWeather.snowy) {
      final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.82);
      for (final drop in weatherDrops) {
        final dropX = drop.x % 250.0;
        final dropY = 140.0 + (drop.y % 580.0);
        canvas.drawCircle(Offset(dropX, dropY), drop.size * 0.75, snowPaint);
      }
    }
  }
}
