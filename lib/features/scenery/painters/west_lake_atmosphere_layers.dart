import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_scenery_geometry.dart';
import '../models/west_lake_palette.dart';
import 'shanshui_atmospheric_effects.dart';
import 'west_lake_static_architecture.dart';

/// Sky, reflections, weeping willow curtains, seasonal particles/fireflies,
/// precipitation, calligraphy colophon, and vignette layers for West Lake (`西湖`).
class WestLakeAtmosphereLayers {
  const WestLakeAtmosphereLayers._();

  static void paintSkyAndCelestial(
    Canvas canvas, {
    required ShanshuiAtmosphereState atmosphere,
    required WestLakePalette westLakePalette,
    required double animationTime,
    required double lightningAlpha,
    required double celX,
  }) {
    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;
    final isDawn = atmosphere.timeOfDay == ShanshuiTimeOfDay.dawn;
    final isDusk = atmosphere.timeOfDay == ShanshuiTimeOfDay.dusk;
    const skyRect = Rect.fromLTWH(0, 0, 1500, 525);

    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [westLakePalette.skyTop, westLakePalette.skyBottom],
        ).createShader(skyRect),
    );

    final overlay = atmosphere.weather.skyOverlay;
    if (overlay != null) {
      canvas.drawRect(skyRect, Paint()..color = overlay);
    }

    if (atmosphere.weather == ShanshuiWeather.stormy && lightningAlpha > 0.02) {
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
        final sx = 90.0 + ((index * 293) % 1320);
        final sy = 16.0 + ((index * 139) % 230);
        final twinkle =
            ((isDawn ? 0.2 : 0.38) + 0.5 * math.sin(animationTime * 2.1 + index))
                .clamp(0.0, 1.0);
        starPaint.color = Color.fromRGBO(255, 255, 245, twinkle);
        canvas.drawCircle(Offset(sx, sy), index % 3 == 0 ? 1.9 : 1.2, starPaint);
      }
    }

    final celY = isDawn ? 235.0 : isDusk ? 245.0 : 135.0;
    final celR = (isDawn || isDusk) ? 56.0 : 48.0;
    final celAlpha = atmosphere.weather.celestialAlpha;
    final celCenter = Offset(celX, celY);

    canvas.drawCircle(
      celCenter,
      celR * 3.8,
      Paint()
        ..shader = RadialGradient(
          colors: [
            westLakePalette.celestialGlow.withValues(
              alpha: westLakePalette.celestialGlow.a * celAlpha,
            ),
            Colors.transparent,
          ],
          stops: const [0.05, 1.0],
        ).createShader(Rect.fromCircle(center: celCenter, radius: celR * 3.8)),
    );

    canvas.drawCircle(
      celCenter,
      celR,
      Paint()
        ..color = westLakePalette.celestialColor.withValues(
          alpha: ((isNight ? 0.95 : 0.88) * celAlpha).clamp(0.0, 1.0),
        ),
    );

    if (atmosphere.weather == ShanshuiWeather.stormy && lightningAlpha > 0.08) {
      ShanshuiAtmosphericEffects.drawJaggedLightningBolt(
        canvas,
        time: animationTime,
        alpha: lightningAlpha,
      );
    }
  }

  static void paintLakeReflections(
    Canvas canvas, {
    required ShanshuiAtmosphereState atmosphere,
    required WestLakePalette westLakePalette,
    required double animationTime,
    required double celX,
    required double lanternLevel,
  }) {
    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;
    final isDusk = atmosphere.timeOfDay == ShanshuiTimeOfDay.dusk;
    const horizon = WestLakeStaticArchitecture.waterHorizonY;
    final celPaint = Paint();
    final lfPaint = Paint();

    for (double ry = horizon + 6; ry < 950; ry += 8) {
      final prog = (ry - horizon) / 435.0;
      final wave = math.sin(animationTime * 2.6 + ry * 0.15) * (5 + prog * 14);

      final celAlpha = ((isNight || isDusk ? 0.36 : 0.22) *
              (1 - prog * 0.65) *
              atmosphere.weather.celestialAlpha)
          .clamp(0.0, 1.0);
      celPaint.color = westLakePalette.celestialColor.withValues(alpha: celAlpha);
      final celRefW = 24 + prog * 70;
      canvas.drawRect(Rect.fromLTWH(celX - celRefW / 2 + wave, ry, celRefW, 2.8), celPaint);

      if (lanternLevel > 0.25 && prog < 0.55) {
        final lfAlpha = ((0.35 - prog * 0.5) * lanternLevel).clamp(0.0, 1.0);
        lfPaint.color = Color.fromRGBO(255, 190, 75, lfAlpha);
        final lfRefW = math.max(8.0, 52.0 - prog * 75);
        canvas.drawRect(
          Rect.fromLTWH(
            WestLakeStaticArchitecture.leifengX - lfRefW / 2 - wave * 0.8,
            ry,
            lfRefW,
            3.0,
          ),
          lfPaint,
        );
      }
    }
  }

  static void paintWillows(
    Canvas canvas, {
    required ShanshuiSeason season,
    required bool hasSnowCover,
    required double animationTime,
    required double wind,
  }) {
    final willowSway = math.sin(animationTime * 1.5 * wind) * (14 * wind);
    _paintWillowCurtain(canvas, 0, isLeft: true, season: season, hasSnowCover: hasSnowCover, willowSway: willowSway);
    _paintWillowCurtain(canvas, 1500, isLeft: false, season: season, hasSnowCover: hasSnowCover, willowSway: willowSway);
  }

  static void _paintWillowCurtain(
    Canvas canvas,
    double anchorX, {
    required bool isLeft,
    required ShanshuiSeason season,
    required bool hasSnowCover,
    required double willowSway,
  }) {
    final boughPath = Path()
      ..moveTo(anchorX, -10)
      ..quadraticBezierTo(
        anchorX + (isLeft ? 135 : -135),
        45,
        anchorX + (isLeft ? 245 : -245),
        115,
      );
    canvas.drawPath(
      boughPath,
      Paint()
        ..color = const Color(0xFF2B2118)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9.0,
    );

    final strandColor = hasSnowCover
        ? const Color.fromRGBO(241, 245, 249, 0.85)
        : season == ShanshuiSeason.fall
            ? const Color(0xFFC88A3B)
            : const Color(0xFF3D6E4C);
    final strandPaint = Paint()
      ..color = strandColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final leafPaint = Paint();

    const frondCount = 11;
    for (int index = 0; index < frondCount; index++) {
      final frac = index / (frondCount - 1);
      final startX = anchorX + (isLeft ? 235 : -235) * frac;
      final startY = 12 + frac * 85;
      final frondLen = 185 + (index % 3) * 55 - frac * 65;
      final swayTip = willowSway * (0.7 + (index % 3) * 0.25);

      final strand = Path()
        ..moveTo(startX, startY)
        ..quadraticBezierTo(startX + swayTip * 0.45, startY + frondLen * 0.5, startX + swayTip, startY + frondLen);
      canvas.drawPath(strand, strandPaint);

      for (double lf = 0.2; lf <= 0.95; lf += 0.15) {
        final lx = startX + swayTip * (lf * lf);
        final ly = startY + frondLen * lf;
        if (hasSnowCover) {
          leafPaint.color = Colors.white;
        } else if (season == ShanshuiSeason.spring && (index + (lf * 10).round()) % 4 == 0) {
          leafPaint.color = const Color(0xFFF48FB1);
        } else if (season == ShanshuiSeason.fall) {
          leafPaint.color = const Color(0xFFE09F45);
        } else {
          leafPaint.color = const Color(0xFF529468);
        }
        canvas.save();
        canvas.translate(lx, ly);
        canvas.rotate(0.4);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 11, height: 4.4), leafPaint);
        canvas.restore();
      }
    }
  }

  static void paintParticlesAndPrecipitation(
    Canvas canvas, {
    required ShanshuiAtmosphereState atmosphere,
    required WestLakePalette westLakePalette,
    required List<ShanshuiParticle> particles,
    required List<ShanshuiWeatherDrop> weatherDrops,
    required double animationTime,
  }) {
    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;
    final isDawn = atmosphere.timeOfDay == ShanshuiTimeOfDay.dawn;
    final isDusk = atmosphere.timeOfDay == ShanshuiTimeOfDay.dusk;
    final isWetWeather = atmosphere.weather == ShanshuiWeather.rainy ||
        atmosphere.weather == ShanshuiWeather.stormy;
    final isSnowWeather = atmosphere.weather == ShanshuiWeather.snowy;

    ShanshuiAtmosphericEffects.drawSeasonalParticles(
      canvas,
      particles,
      time: animationTime,
      wind: atmosphere.weather.windFactor,
      isNight: isNight,
      isDusk: isDusk,
      isFireflies: westLakePalette.particleKind == SeasonalParticleKind.fireflies &&
          !isWetWeather &&
          !isSnowWeather,
      isSnow: westLakePalette.particleKind == SeasonalParticleKind.snow,
      color1: westLakePalette.particleColor1,
      color2: westLakePalette.particleColor2,
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

  static void paintCalligraphyAndSeal(
    Canvas canvas, {
    required ShanshuiAtmosphereState atmosphere,
    required bool isNight,
    required bool fullPoem,
  }) {
    final title = atmosphere.season.nameZhFor(ShanshuiRealm.westLake).replaceAll(' · ', '');
    final textColor = isNight
        ? const Color.fromRGBO(248, 244, 232, 0.92)
        : const Color.fromRGBO(38, 28, 20, 0.86);
    final shadow = Shadow(
      color: isNight ? const Color(0xBF000000) : const Color(0xBFFFF8EB),
      blurRadius: 6,
    );

    for (int index = 0; index < title.length; index++) {
      final tp = TextPainter(
        text: TextSpan(
          text: title[index],
          style: TextStyle(
            color: textColor,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
            shadows: [shadow],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(1418, 58.0 + index * 30.0));
    }

    if (fullPoem) {
      final lines = atmosphere.season
          .poemFor(ShanshuiRealm.westLake)
          .split(RegExp(r'[，。]'))
          .where((part) => part.isNotEmpty)
          .toList();
      for (int col = 0; col < lines.length; col++) {
        final colText = lines[col];
        final colX = 1372.0 - col * 28.0;
        for (int idx = 0; idx < colText.length; idx++) {
          final tp = TextPainter(
            text: TextSpan(
              text: colText[idx],
              style: TextStyle(
                color: textColor.withValues(alpha: 0.82),
                fontSize: 17,
                fontFamily: 'serif',
                shadows: [shadow],
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(colX, 66.0 + idx * 22.0));
        }
      }
    }

    ShanshuiAtmosphericEffects.drawCinnabarSeal(
      canvas,
      x: 1408.0,
      y: 66.0 + title.length * 30.0,
      size: 36.0,
      sealText: atmosphere.season.sealTextFor(ShanshuiRealm.westLake),
      fontSize: 12,
      leftPad: 5,
      rowOffset1: 5,
      rowOffset2: 18,
    );
  }

  static void paintVignette(Canvas canvas, {required bool isNight}) {
    const fullRect = Rect.fromLTWH(0, 0, 1500, 1000);
    canvas.drawRect(
      fullRect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            Colors.transparent,
            isNight
                ? const Color.fromRGBO(4, 8, 14, 0.48)
                : const Color.fromRGBO(32, 22, 14, 0.20),
          ],
          stops: const [0.65, 1.0],
        ).createShader(fullRect),
    );
  }
}
