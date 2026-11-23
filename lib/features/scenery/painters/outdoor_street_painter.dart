import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/outdoor_street_models.dart';
import '../models/outdoor_street_palette.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_scenery_geometry.dart';
import 'outdoor_street_crowd_layers.dart';
import 'outdoor_street_shop_layers.dart';
import 'outdoor_street_static_architecture.dart';
import 'shanshui_atmospheric_effects.dart';

/// Full interactive vector painter for the Outdoor Ancient Market Street (`街市`) realm.
///
/// Combines a cached static architectural `ui.Picture` layer with dynamic 60 FPS
/// Z-ordered layers: weather-tinted sky and jagged lightning, drifting clouds,
/// dynamic shopfront window glows, wind-billowing awnings, clipped street lantern
/// reflections, behind-counter vendors occluded by foreground stall counters,
/// foreground customers and avenue walkers, multi-stop radial lanterns,
/// upward-pulsing summer fireflies, rain puddle ripples, and classical colophons.
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
    final isDusk = atmosphere.timeOfDay == ShanshuiTimeOfDay.dusk;
    final isWet = atmosphere.weather == ShanshuiWeather.rainy ||
        atmosphere.weather == ShanshuiWeather.stormy;
    final isSnow = atmosphere.weather == ShanshuiWeather.snowy;
    final hasSnow = atmosphere.season == ShanshuiSeason.winter || isSnow;
    final wind = atmosphere.weather.windFactor;
    final lanternLevel = (streetPalette.candleIntensity + (isWet ? 0.35 : 0.0)).clamp(0.0, 1.0);
    final awningBillow = math.sin(animationTime * 2.0 * wind) * (4.0 * wind);

    // 1. Sky gradient, weather overlay, stars, celestial body, stormy lightning
    _paintSkyAndCelestial(canvas, isNight: isNight, isDawn: isDawn, isDusk: isDusk);

    // 2. Drifting billowy clouds & distant flying birds
    OutdoorStreetCrowdLayers.paintCloudsAndBirds(
      canvas,
      animationTime: animationTime,
      wind: wind,
      isNight: isNight,
      weather: atmosphere.weather,
    );

    // 3. Static architecture (mountains, avenue, Paifang with tile ribs, shopfronts)
    if (cachedStaticPicture != null) {
      canvas.drawPicture(cachedStaticPicture!);
    } else {
      OutdoorStreetStaticArchitecture.paintStaticArchitecture(
        canvas,
        const Size(1500, 1000),
        atmosphere: atmosphere,
        streetPalette: streetPalette,
      );
    }

    // 4. Dynamic warm shopfront lattice windows (Dawn/Dusk/Night/Rainy/Stormy)
    OutdoorStreetShopLayers.paintDynamicShopWindows(canvas, lanternLevel: lanternLevel);

    // 5. Wind-billowing market fabric awnings & right support pole
    OutdoorStreetShopLayers.paintBillowingAwnings(
      canvas,
      hasSnow: hasSnow,
      billow: awningBillow,
    );

    // 6. Clipped street lantern reflections & puddle ripples
    _paintLanternReflectionsAndRipples(
      canvas,
      isWet: isWet,
      isNight: isNight,
      lanternLevel: lanternLevel,
    );

    // 7. Behind-counter vendors/patrons painted BEFORE foreground stall counters
    OutdoorStreetCrowdLayers.paintTownsfolkList(
      canvas,
      OutdoorStreetCrowd.getBehindCounterFigures(atmosphere.timeOfDay),
      animationTime: animationTime,
      isNight: isNight,
      isPrecipitation: false,
      wind: wind,
    );

    // 8. Foreground wooden market stalls, pastries, crates, bowls, stool & barrel
    OutdoorStreetShopLayers.paintForegroundStalls(canvas, isDawn: isDawn);

    // 9. Rising food stall steam wisps
    OutdoorStreetCrowdLayers.paintFoodSteam(
      canvas,
      animationTime: animationTime,
      isNight: isNight,
      isDawn: isDawn,
      hasSnow: hasSnow,
      wind: wind,
    );

    // 10. Foreground customers & avenue walkers painted AFTER stall counters
    OutdoorStreetCrowdLayers.paintTownsfolkList(
      canvas,
      OutdoorStreetCrowd.getForegroundFigures(atmosphere.timeOfDay),
      animationTime: animationTime,
      isNight: isNight,
      isPrecipitation: isWet || isSnow,
      wind: wind,
    );

    // 11. Swaying red paper lanterns with multi-stop radial glow halos
    OutdoorStreetCrowdLayers.paintStreetLanterns(
      canvas,
      animationTime: animationTime,
      lanternLevel: lanternLevel,
      wind: wind,
    );

    // 12. Ambient wash, seasonal particles/fireflies & precipitation
    _paintAmbientAndPrecipitation(
      canvas,
      isWet: isWet,
      isSnow: isSnow,
      isNight: isNight,
      isDawn: isDawn,
      isDusk: isDusk,
      wind: wind,
    );

    // 13. Classical calligraphy colophon & cinnabar seal
    if (showCalligraphy) {
      _paintCalligraphyAndSeal(canvas, isNight: isNight);
    }

    // 14. Soft vignette around canvas borders
    _paintVignette(canvas, isNight: isNight);

    canvas.restore();
  }

  void _paintSkyAndCelestial(
    Canvas canvas, {
    required bool isNight,
    required bool isDawn,
    required bool isDusk,
  }) {
    const skyRect = Rect.fromLTWH(0, 0, 1500, 540);
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [streetPalette.skyTop, streetPalette.skyBottom],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    if (atmosphere.weather.skyOverlay != null) {
      canvas.drawRect(skyRect, Paint()..color = atmosphere.weather.skyOverlay!);
    }

    final isStormy = atmosphere.weather == ShanshuiWeather.stormy;
    if (isStormy && lightningAlpha > 0.05) {
      canvas.drawRect(
        skyRect,
        Paint()..color = Colors.white.withValues(alpha: (lightningAlpha * 0.55).clamp(0.0, 0.7)),
      );
    }

    if ((isNight || isDawn) &&
        (atmosphere.weather == ShanshuiWeather.sunny ||
            atmosphere.weather == ShanshuiWeather.snowy)) {
      final starCount = isDawn ? 18 : 45;
      final starPaint = Paint();
      for (int index = 0; index < starCount; index++) {
        final sx = 240.0 + ((index * 293) % 1020);
        final sy = 18.0 + ((index * 137) % 240);
        final twinkle = (isDawn ? 0.2 : 0.35) + 0.5 * math.sin(animationTime * 2.0 + index);
        starPaint.color = Colors.white.withValues(alpha: twinkle.clamp(0.0, 1.0));
        canvas.drawCircle(Offset(sx, sy), index % 3 == 0 ? 1.9 : 1.2, starPaint);
      }
    }

    const celX = 955.0;
    final celY = isDawn ? 225.0 : isDusk ? 205.0 : 118.0;
    final celR = isDawn || isDusk ? 54.0 : 46.0;
    final celAlpha = atmosphere.weather.celestialAlpha;

    final haloRadius = celR * 3.5;
    final haloShader = RadialGradient(
      colors: [
        streetPalette.celestialGlow.withValues(
          alpha: (streetPalette.celestialGlow.a * celAlpha).clamp(0.0, 1.0),
        ),
        const Color.fromRGBO(0, 0, 0, 0.0),
      ],
      stops: const [0.06, 1.0],
    ).createShader(Rect.fromCircle(center: Offset(celX, celY), radius: haloRadius));
    canvas.drawCircle(Offset(celX, celY), haloRadius, Paint()..shader = haloShader);

    final discAlpha = ((isNight ? 0.95 : 0.88) * celAlpha).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(celX, celY),
      celR,
      Paint()..color = streetPalette.celestialColor.withValues(alpha: discAlpha),
    );

    if (isStormy && lightningAlpha > 0.05) {
      ShanshuiAtmosphericEffects.drawJaggedLightningBolt(
        canvas,
        time: animationTime,
        alpha: lightningAlpha,
      );
    }
  }

  void _paintLanternReflectionsAndRipples(
    Canvas canvas, {
    required bool isWet,
    required bool isNight,
    required double lanternLevel,
  }) {
    canvas.save();
    canvas.clipPath(OutdoorStreetStaticArchitecture.buildAvenuePath());

    if (lanternLevel > 0.25 || isWet) {
      final reflAlpha = ((lanternLevel * 0.35) + (isWet ? 0.22 : 0.0)).clamp(0.0, 0.57);
      final leftShader = ui.Gradient.linear(
        const Offset(250, 620),
        const Offset(580, 960),
        [
          Color.fromRGBO(255, 145, 55, reflAlpha),
          const Color.fromRGBO(255, 145, 55, 0.0),
        ],
      );
      canvas.drawRect(const Rect.fromLTWH(180, 600, 420, 400), Paint()..shader = leftShader);

      final rightShader = ui.Gradient.linear(
        const Offset(1250, 620),
        const Offset(920, 960),
        [
          Color.fromRGBO(255, 145, 55, reflAlpha),
          const Color.fromRGBO(255, 145, 55, 0.0),
        ],
      );
      canvas.drawRect(const Rect.fromLTWH(900, 600, 420, 400), Paint()..shader = rightShader);
    }

    final rippleColor = isNight ? const Color(0xFFDCEBFF) : const Color(0xFF6E5F50);

    if (isWet) {
      final isStorm = atmosphere.weather == ShanshuiWeather.stormy;
      ShanshuiAtmosphericEffects.drawRainPuddleRipples(
        canvas,
        time: animationTime,
        isStormy: isStorm,
        rippleColor: rippleColor,
        minY: 615.0,
        spanY: 340.0,
        minXAt: (avenueY) => OutdoorStreetCrowd.avenueLeftX(avenueY) + 35.0,
        maxXAt: (avenueY) => OutdoorStreetCrowd.avenueRightX(avenueY) - 35.0,
        aspectRatio: 0.56,
        strokeWidth: 1.5,
        minRadius: 2.0,
        maxRadiusExpand: isStorm ? 26.0 : 20.0,
        baseAlpha: isStorm ? 0.55 : 0.38,
        seedMultiplier: 73,
      );
    }

    if (ripples != null) {
      for (final ripple in ripples!) {
        final double rx = ripple is OutdoorPuddleRipple ? ripple.x : (ripple as ShanshuiRipple).x;
        final double ry = ripple is OutdoorPuddleRipple ? ripple.y : (ripple as ShanshuiRipple).y;
        final double radius =
            ripple is OutdoorPuddleRipple ? ripple.radius : (ripple as ShanshuiRipple).radius;
        final double alpha =
            ripple is OutdoorPuddleRipple ? ripple.alpha : (ripple as ShanshuiRipple).alpha;

        canvas.drawOval(
          Rect.fromCenter(center: Offset(rx, ry), width: radius * 2, height: radius * 0.56),
          Paint()
            ..color = rippleColor.withValues(alpha: alpha.clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    canvas.restore();
  }

  void _paintAmbientAndPrecipitation(
    Canvas canvas, {
    required bool isWet,
    required bool isSnow,
    required bool isNight,
    required bool isDawn,
    required bool isDusk,
    required double wind,
  }) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 1500, 1000),
      Paint()..color = streetPalette.ambientOverlay,
    );

    final exteriorDim = atmosphere.weather.exteriorDimming;
    if (exteriorDim > 0) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1500, 1000),
        Paint()..color = Color.fromRGBO(14, 20, 28, exteriorDim.clamp(0.0, 1.0)),
      );
    }

    ShanshuiAtmosphericEffects.drawSeasonalParticles(
      canvas,
      particles,
      time: animationTime,
      wind: wind,
      isNight: isNight,
      isDusk: isDusk,
      isFireflies: streetPalette.particleType == 'fireflies' && !isWet && !isSnow,
      isSnow: streetPalette.particleType == 'snow',
      color1: streetPalette.particleColor1,
      color2: streetPalette.particleColor2,
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

  void _paintCalligraphyAndSeal(Canvas canvas, {required bool isNight}) {
    canvas.save();
    final title = atmosphere.season.nameZhFor(ShanshuiRealm.outdoor).replaceAll(' · ', '');
    final textColor = isNight
        ? const Color.fromRGBO(248, 244, 232, 0.90)
        : const Color.fromRGBO(42, 30, 22, 0.86);

    for (int index = 0; index < title.length; index++) {
      final tp = TextPainter(
        text: TextSpan(
          text: title[index],
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
      tp.paint(canvas, Offset(388, 62.0 + index * 30.0));
    }

    if (fullPoem) {
      final poemChars = atmosphere.season
          .poemFor(ShanshuiRealm.outdoor)
          .replaceAll(RegExp(r'[，。、；：！？\s]'), '');
      if (poemChars.isNotEmpty) {
        final colLen = (poemChars.length / 2).ceil();
        final poemStyle = TextStyle(
          color: textColor.withValues(alpha: 0.82),
          fontSize: 17,
          fontFamily: 'serif',
          shadows: [
            Shadow(
              color: isNight ? Colors.black54 : Colors.white70,
              blurRadius: 6,
            ),
          ],
        );
        for (int index = 0; index < poemChars.length; index++) {
          final col = index ~/ colLen;
          final row = index % colLen;
          final tp = TextPainter(
            text: TextSpan(text: poemChars[index], style: poemStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(424.0 + col * 26.0, 62.0 + row * 19.0));
        }
      }
    }

    ShanshuiAtmosphericEffects.drawCinnabarSeal(
      canvas,
      x: 378.0,
      y: 68.0 + title.length * 30.0,
      size: 36.0,
      sealText: atmosphere.season.sealTextFor(ShanshuiRealm.outdoor),
      fontSize: 12,
      leftPad: 5,
      rowOffset1: 5,
      rowOffset2: 18,
    );
    canvas.restore();
  }

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
        oldDelegate.fullPoem != fullPoem ||
        (oldDelegate.ripples?.length ?? 0) != (ripples?.length ?? 0);
  }
}
