import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_palette.dart';
import '../models/shanshui_scenery_geometry.dart';
import '../painters/scenery_canvas_painter_base.dart';
import '../painters/shanshui_atmospheric_effects.dart';
import '../painters/shanshui_nature_layers.dart';

/// 11-layer procedural vector painter rendering the classical Chinese Shanshui
/// landscape painting in true vector coordinates ($1500 \times 1000$ internal space).
class ShanshuiCanvasPainter extends SceneryCanvasPainterBase {
  final ShanshuiPalette palette;
  final List<ShanshuiCrane> cranes;
  final List<ShanshuiRipple> ripples;

  static const _calligraphyConfig = SceneryCalligraphyConfig(
    titleX: 1415.0,
    titleY: 75.0,
    titleStepY: 32.5,
    poemStartX: 1372.0,
    poemStartY: 80.0,
    poemColumnStepX: -30.0,
    poemStepY: 23.4,
    poemFontSize: 18.0,
    poemAlpha: 0.75,
    sealX: 1404.0,
    sealTopGap: 15.0,
    sealSize: 40.0,
    sealFontSize: 11.0,
    dayTextColor: Color(0xD1231F1C),
    nightTextColor: Color(0xDDF1F5F9),
    dayShadowColor: null,
    nightShadowColor: null,
  );

  const ShanshuiCanvasPainter({
    required super.atmosphere,
    required this.palette,
    required super.animationTime,
    required super.particles,
    required super.weatherDrops,
    required this.cranes,
    required this.ripples,
    super.showCalligraphy = true,
    super.fullPoem = true,
    super.lightningAlpha = 0.0,
  });

  @override
  int get rippleCount => ripples.length;

  @override
  bool shouldRepaintExtra(covariant ShanshuiCanvasPainter oldDelegate) =>
      oldDelegate.palette != palette;

  @override
  void paintScene(Canvas canvas) {

    final isWinter = atmosphere.season == ShanshuiSeason.winter;
    final isSnowWeather = atmosphere.weather == ShanshuiWeather.snowy;
    final hasSnowCover = isWinter || isSnowWeather;
    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;
    final isDawn = atmosphere.timeOfDay == ShanshuiTimeOfDay.dawn;
    final isDusk = atmosphere.timeOfDay == ShanshuiTimeOfDay.dusk;
    final isWet = atmosphere.weather == ShanshuiWeather.rainy ||
        atmosphere.weather == ShanshuiWeather.stormy;
    final wind = atmosphere.weather.windFactor;
    final time = animationTime;

    // 1. Sky Gradient, Weather Overlay, Stars & Stormy Lightning
    _drawSkyAndCelestial(
      canvas,
      time: time,
      isNight: isNight,
      isDawn: isDawn,
      isDusk: isDusk,
      isSnowWeather: isSnowWeather,
    );

    // 2. Distant Layered Mountains, Midground Karst Crags & Drifting Mist
    ShanshuiNatureLayers.drawMountainsAndMist(
      canvas,
      palette,
      time: time,
      wind: wind,
      mistMultiplier: atmosphere.weather.mistMultiplier,
      hasSnowCover: hasSnowCover,
    );

    // 3. Center Island & Grand Pavilion
    ShanshuiNatureLayers.drawPolygon(
      canvas,
      ShanshuiGeometry.centerIslandHill,
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.nearMtn, palette.cragStroke],
      ).createShader(const Rect.fromLTWH(590, 510, 395, 135)),
    );
    ShanshuiNatureLayers.drawCenterPavilion(
      canvas,
      790.0,
      522.0,
      palette,
      hasSnowCover: hasSnowCover,
    );

    // 4. Calm Mirror Lake, Shimmer & Ripples
    _drawLakeAndRipples(
      canvas,
      time: time,
      wind: wind,
      isNight: isNight,
      isDawn: isDawn,
      isWet: isWet,
    );

    // 5. Left & Right Waterside Pavilions, Foliage, Boats & Cranes
    ShanshuiNatureLayers.drawLeftPavilionAndBridge(
      canvas,
      palette,
      hasSnowCover: hasSnowCover,
    );
    ShanshuiNatureLayers.drawRightStudyPavilion(
      canvas,
      palette,
      hasSnowCover: hasSnowCover,
    );
    ShanshuiNatureLayers.drawTreesAndFoliage(
      canvas,
      palette,
      hasSnowCover: hasSnowCover,
    );
    ShanshuiNatureLayers.drawBoats(
      canvas,
      palette,
      time: time,
      wind: wind,
      hasSnowCover: hasSnowCover,
    );
    for (final crane in cranes) {
      ShanshuiNatureLayers.drawCrane(canvas, crane, time, isNight);
    }

    // 6. Seasonal Particles (rotating petals/leaves, fireflies, snow) & Precipitation
    ShanshuiAtmosphericEffects.drawSeasonalParticles(
      canvas,
      particles,
      time: time,
      wind: wind,
      isNight: isNight,
      isDusk: isDusk,
      isFireflies: atmosphere.season == ShanshuiSeason.summer && !isWet && !isSnowWeather,
      isSnow: atmosphere.season == ShanshuiSeason.winter || isSnowWeather,
      color1: palette.particleColor1,
      color2: palette.particleColor2,
    );

    final isStorm = atmosphere.weather == ShanshuiWeather.stormy;
    ShanshuiAtmosphericEffects.drawPrecipitation(
      canvas,
      weatherDrops,
      weather: atmosphere.weather,
      rainColor: Color.fromRGBO(215, 230, 240, isStorm ? 0.42 : 0.35),
      rainStrokeWidth: isStorm ? 1.8 : 1.2,
      slantMultiplier: 2.2,
      lengthMultiplier: isStorm ? 1.35 : 1.0,
      snowAlpha: 0.85,
    );

    // 7. Vertical Calligraphy Colophon & Cinnabar Seal
    if (showCalligraphy) {
      ShanshuiAtmosphericEffects.drawCalligraphyAndSeal(
        canvas,
        atmosphere: atmosphere,
        isNight: isNight,
        fullPoem: fullPoem,
        config: _calligraphyConfig,
      );
    }

    // 8. Soft Radial Vignette
    ShanshuiAtmosphericEffects.drawVignette(
      canvas,
      isNight: isNight,
      radius: 0.5,
      innerStop: 0.55,
      dayEdgeColor: const Color(0x2E3A3026),
      nightEdgeColor: const Color(0x66050A0E),
    );
  }

  void _drawSkyAndCelestial(
    Canvas canvas, {
    required double time,
    required bool isNight,
    required bool isDawn,
    required bool isDusk,
    required bool isSnowWeather,
  }) {
    const skyRect = Rect.fromLTWH(0, 0, 1500, 625);
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.skyTop, palette.skyMid, palette.skyBottom],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    if (atmosphere.weather.skyOverlay != null) {
      canvas.drawRect(skyRect, Paint()..color = atmosphere.weather.skyOverlay!);
    }

    if ((isNight || isDawn) &&
        (atmosphere.weather == ShanshuiWeather.sunny || isSnowWeather)) {
      final starCount = isDawn ? 18 : 42;
      final maxStarY = isDawn ? 220.0 : 360.0;
      for (int index = 0; index < starCount; index++) {
        final sx = ((index * 379) % 1460) + 20.0;
        final sy = ((index * 197) % maxStarY) + 20.0;
        final twinkle = (isDawn ? 0.15 : 0.25) + 0.45 * math.sin(time * 1.8 + index);
        canvas.drawCircle(
          Offset(sx, sy),
          (index % 3 == 0) ? 1.8 : 1.1,
          Paint()..color = Colors.white.withValues(alpha: twinkle.clamp(0.0, 1.0)),
        );
      }
    }

    final isStormy = atmosphere.weather == ShanshuiWeather.stormy;
    if (isStormy && lightningAlpha > 0.05) {
      canvas.drawRect(
        skyRect,
        Paint()
          ..color = Color.fromRGBO(240, 246, 255, (lightningAlpha * 0.45).clamp(0.0, 1.0)),
      );
    }

    final celestialX = isDawn ? 655.0 : 695.0;
    final celestialY = isDawn ? 295.0 : (isDusk ? 245.0 : 165.0);
    final celestialR = isDawn ? 54.0 : (isDusk ? 58.0 : 48.0);

    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.celestialGlow.withValues(
            alpha: (palette.celestialGlow.a * atmosphere.weather.celestialAlpha).clamp(0.0, 1.0),
          ),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(center: Offset(celestialX, celestialY), radius: celestialR * 3.4),
      );
    canvas.drawCircle(Offset(celestialX, celestialY), celestialR * 3.4, haloPaint);

    final celestialAlphaVal = (isNight ? 0.94 : 0.86) * atmosphere.weather.celestialAlpha;
    canvas.drawCircle(
      Offset(celestialX, celestialY),
      celestialR,
      Paint()..color = palette.celestialColor.withValues(alpha: celestialAlphaVal.clamp(0.0, 1.0)),
    );

    if (isStormy && lightningAlpha > 0.05) {
      ShanshuiAtmosphericEffects.drawJaggedLightningBolt(
        canvas,
        time: time,
        alpha: lightningAlpha,
      );
    }
  }

  void _drawLakeAndRipples(
    Canvas canvas, {
    required double time,
    required double wind,
    required bool isNight,
    required bool isDawn,
    required bool isWet,
  }) {
    const waterHorizonY = 622.0;
    final lakePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.waterTop, palette.skyBottom, palette.waterBottom],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(const Rect.fromLTWH(0, waterHorizonY, 1500, 1000 - waterHorizonY));
    canvas.drawRect(const Rect.fromLTWH(0, waterHorizonY, 1500, 1000 - waterHorizonY), lakePaint);

    final celestialX = isDawn ? 655.0 : 695.0;
    for (double wy = waterHorizonY + 12; wy < 940; wy += 9) {
      final progress = (wy - waterHorizonY) / 340.0;
      final shimmerW = (18 + progress * 75) + math.sin(time * 3.2 * wind + wy * 0.15) * 8;
      final shimmerAlpha =
          (isNight || isDawn ? 0.34 : 0.22) * (1 - progress * 0.7) * atmosphere.weather.celestialAlpha;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(celestialX, wy), width: shimmerW, height: 2.5),
        Paint()..color = palette.celestialColor.withValues(alpha: shimmerAlpha.clamp(0.0, 1.0)),
      );
    }

    if (isWet) {
      final isStorm = atmosphere.weather == ShanshuiWeather.stormy;
      ShanshuiAtmosphericEffects.drawRainPuddleRipples(
        canvas,
        time: time,
        isStormy: isStorm,
        rippleColor: palette.rippleColor,
        minY: 638.0,
        spanY: 320.0,
        minXAt: (_) => 140.0,
        maxXAt: (_) => 1360.0,
        aspectRatio: 0.44,
        strokeWidth: 1.8,
        minRadius: 3.0,
        maxRadiusExpand: isStorm ? 28.0 : 22.0,
        baseAlpha: isStorm ? 0.65 : 0.48,
        seedMultiplier: 83,
      );
    }

    for (final ripple in ripples) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ripple.x, ripple.y),
          width: ripple.radius * 2,
          height: ripple.radius * 0.44,
        ),
        Paint()
          ..color = palette.rippleColor.withValues(alpha: ripple.alpha.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }
}
