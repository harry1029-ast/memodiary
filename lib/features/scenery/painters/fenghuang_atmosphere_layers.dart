import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/fenghuang_palette.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_scenery_geometry.dart';
import 'fenghuang_static_architecture.dart';
import 'shanshui_atmospheric_effects.dart';

/// Sky, celestial body, overhanging foreground seasonal branches,
/// particles/fireflies, precipitation, vertical calligraphy colophon,
/// cinnabar seal, and vignette layers for Fenghuang (`凤凰`).
class FenghuangAtmosphereLayers {
  const FenghuangAtmosphereLayers._();

  static const double celestialX = 760.0;

  static void paintSkyAndCelestial(
    Canvas canvas, {
    required ShanshuiAtmosphereState atmosphere,
    required FenghuangPalette fenghuangPalette,
    required double animationTime,
    required double lightningAlpha,
  }) {
    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;
    final isDawn = atmosphere.timeOfDay == ShanshuiTimeOfDay.dawn;
    final isDusk = atmosphere.timeOfDay == ShanshuiTimeOfDay.dusk;
    const skyRect = Rect.fromLTWH(0, 0, 1500, 530);

    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fenghuangPalette.skyTop, fenghuangPalette.skyBottom],
        ).createShader(skyRect),
    );

    final overlay = atmosphere.weather.skyOverlay;
    if (overlay != null) {
      canvas.drawRect(skyRect, Paint()..color = overlay);
    }

    final isStormy = atmosphere.weather == ShanshuiWeather.stormy;
    if (isStormy && lightningAlpha > 0.02) {
      canvas.drawRect(
        skyRect,
        Paint()
          ..color = Colors.white.withValues(
            alpha: (lightningAlpha * 0.55).clamp(0.0, 0.7),
          ),
      );
    }

    if ((isNight || isDawn) &&
        (atmosphere.weather == ShanshuiWeather.sunny ||
            atmosphere.weather == ShanshuiWeather.snowy)) {
      final starCount = isDawn ? 18 : 48;
      final starPaint = Paint();
      for (int index = 0; index < starCount; index++) {
        final sx = 120.0 + ((index * 293) % 1260);
        final sy = 16.0 + ((index * 139) % 230);
        final twinkle =
            ((isDawn ? 0.2 : 0.38) + 0.5 * math.sin(animationTime * 2.1 + index))
                .clamp(0.0, 1.0);
        starPaint.color = Color.fromRGBO(255, 255, 245, twinkle);
        canvas.drawCircle(Offset(sx, sy), index % 3 == 0 ? 1.9 : 1.2, starPaint);
      }
    }

    final celY = isDawn ? 225.0 : isDusk ? 205.0 : 125.0;
    final celR = (isDawn || isDusk) ? 54.0 : 46.0;
    final celAlpha = atmosphere.weather.celestialAlpha;
    final celCenter = Offset(celestialX, celY);

    canvas.drawCircle(
      celCenter,
      celR * 3.5,
      Paint()
        ..shader = RadialGradient(
          colors: [
            fenghuangPalette.celestialGlow.withValues(
              alpha: fenghuangPalette.celestialGlow.a * celAlpha,
            ),
            Colors.transparent,
          ],
          stops: const [0.05, 1.0],
        ).createShader(Rect.fromCircle(center: celCenter, radius: celR * 3.5)),
    );

    canvas.drawCircle(
      celCenter,
      celR,
      Paint()
        ..color = fenghuangPalette.celestialColor.withValues(
          alpha: ((isNight ? 0.95 : 0.88) * celAlpha).clamp(0.0, 1.0),
        ),
    );

    if (isStormy && lightningAlpha > 0.08) {
      ShanshuiAtmosphericEffects.drawJaggedLightningBolt(
        canvas,
        time: animationTime,
        alpha: lightningAlpha,
      );
    }
  }

  /// Paints swaying top-left and top-right overhanging seasonal branches.
  static void paintForegroundBranches(
    Canvas canvas, {
    required FenghuangPalette fenghuangPalette,
    required bool hasSnowCover,
    required double animationTime,
    required double wind,
  }) {
    final fgSway = math.sin(animationTime * 1.4 * wind) * (5.0 * wind);
    final branchPath = Path()
      ..moveTo(0, 120)
      ..quadraticBezierTo(95, 145, 165 + fgSway, 215)
      ..moveTo(1500, 110)
      ..quadraticBezierTo(1395, 140, 1325 + fgSway, 210);
    canvas.drawPath(
      branchPath,
      Paint()
        ..color = const Color(0xFF231710)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0,
    );

    FenghuangStaticArchitecture.paintFoliageCluster(
      canvas, 145 + fgSway, 195, 42, fenghuangPalette.foliagePrimary, hasSnowCover,
    );
    FenghuangStaticArchitecture.paintFoliageCluster(
      canvas, 85 + fgSway * 0.7, 155, 48, fenghuangPalette.foliageSecondary, hasSnowCover,
    );
    FenghuangStaticArchitecture.paintFoliageCluster(
      canvas, 1345 + fgSway, 190, 42, fenghuangPalette.foliagePrimary, hasSnowCover,
    );
    FenghuangStaticArchitecture.paintFoliageCluster(
      canvas, 1410 + fgSway * 0.7, 150, 48, fenghuangPalette.foliageSecondary, hasSnowCover,
    );
  }

  /// Paints seasonal particles/fireflies and rain/snow precipitation.
  static void paintParticlesAndPrecipitation(
    Canvas canvas, {
    required ShanshuiAtmosphereState atmosphere,
    required FenghuangPalette fenghuangPalette,
    required List<ShanshuiParticle> particles,
    required List<ShanshuiWeatherDrop> weatherDrops,
    required double animationTime,
  }) {
    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;
    final isDawn = atmosphere.timeOfDay == ShanshuiTimeOfDay.dawn;
    final isDusk = atmosphere.timeOfDay == ShanshuiTimeOfDay.dusk;
    final isWet = atmosphere.weather == ShanshuiWeather.rainy ||
        atmosphere.weather == ShanshuiWeather.stormy;
    final isSnow = atmosphere.weather == ShanshuiWeather.snowy;

    ShanshuiAtmosphericEffects.drawSeasonalParticles(
      canvas,
      particles,
      time: animationTime,
      wind: atmosphere.weather.windFactor,
      isNight: isNight,
      isDusk: isDusk,
      isFireflies: fenghuangPalette.particleKind == SeasonalParticleKind.fireflies &&
          !isWet &&
          !isSnow,
      isSnow: fenghuangPalette.particleKind == SeasonalParticleKind.snow,
      color1: fenghuangPalette.particleColor1,
      color2: fenghuangPalette.particleColor2,
    );

    final isStorm = atmosphere.weather == ShanshuiWeather.stormy;
    ShanshuiAtmosphericEffects.drawPrecipitation(
      canvas,
      weatherDrops,
      weather: atmosphere.weather,
      rainColor: (isNight || isDawn)
          ? const Color.fromRGBO(215, 232, 248, 0.46)
          : const Color.fromRGBO(80, 100, 115, 0.42),
      rainStrokeWidth: isStorm ? 1.8 : 1.3,
      slantMultiplier: 2.1,
      lengthMultiplier: 1.0,
      snowAlpha: 0.82,
    );
  }
}
