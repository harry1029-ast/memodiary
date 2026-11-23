import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_scenery_geometry.dart';
import '../models/west_lake_palette.dart';
import 'west_lake_atmosphere_layers.dart';
import 'west_lake_bridges.dart';
import 'west_lake_static_architecture.dart';
import 'west_lake_water_features.dart';

/// Full interactive 1500x1000 vector painter for Hangzhou West Lake (`西湖`).
///
/// Pairs an immutable cached `ui.Picture` static backdrop (northern hills,
/// Baochu Pagoda, Xizhao Hill, 5-story Leifeng Pagoda, and lake base) with
/// dynamic 60 FPS animations across all 4 seasons, 4 times of day, and 5 weathers.
class WestLakePainter extends CustomPainter {
  final ShanshuiAtmosphereState atmosphere;
  final WestLakePalette westLakePalette;
  final double animationTime;
  final List<ShanshuiParticle> particles;
  final List<ShanshuiWeatherDrop> weatherDrops;
  final List<ShanshuiRipple> ripples;
  final bool showCalligraphy;
  final bool fullPoem;
  final double lightningAlpha;
  final ui.Picture? cachedStaticPicture;

  WestLakePainter({
    required this.atmosphere,
    WestLakePalette? westLakePalette,
    required this.animationTime,
    required this.particles,
    required this.weatherDrops,
    this.ripples = const [],
    this.showCalligraphy = false,
    this.fullPoem = false,
    this.lightningAlpha = 0.0,
    this.cachedStaticPicture,
  }) : westLakePalette = westLakePalette ??
            WestLakePalette.of(atmosphere.season, atmosphere.timeOfDay);

  /// Records static backdrop geometry into an immutable `ui.Picture` cached
  /// per `(season, timeOfDay, weather)` environment.
  static ui.Picture recordStaticPicture({
    required ShanshuiAtmosphereState atmosphere,
    required WestLakePalette westLakePalette,
  }) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1500, 1000));
    WestLakeStaticArchitecture.paintStaticBackdrop(
      canvas,
      const Size(1500, 1000),
      atmosphere: atmosphere,
      westLakePalette: westLakePalette,
    );
    return recorder.endRecording();
  }

  /// Exposes the effective illumination factor used by Three Pools candle windows.
  static double effectiveLanternLevel(
    WestLakePalette palette,
    ShanshuiWeather weather,
  ) =>
      WestLakeStaticArchitecture.effectiveLanternLevel(palette, weather);

  /// Exposes active Broken Bridge visitor counts per time of day.
  static int visibleBridgeVisitors(ShanshuiTimeOfDay timeOfDay) =>
      WestLakeBridges.visibleVisitorCount(timeOfDay);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1500.0, size.height / 1000.0);
    canvas.clipRect(const Rect.fromLTWH(0, 0, 1500, 1000));

    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;
    final isDawn = atmosphere.timeOfDay == ShanshuiTimeOfDay.dawn;
    final isDusk = atmosphere.timeOfDay == ShanshuiTimeOfDay.dusk;
    final isWetWeather = atmosphere.weather == ShanshuiWeather.rainy ||
        atmosphere.weather == ShanshuiWeather.stormy;
    final isSnowWeather = atmosphere.weather == ShanshuiWeather.snowy;
    final hasSnowCover =
        atmosphere.season == ShanshuiSeason.winter || isSnowWeather;
    final wind = atmosphere.weather.windFactor;
    final lanternLevel = WestLakeStaticArchitecture.effectiveLanternLevel(
      westLakePalette,
      atmosphere.weather,
    );
    final celX = isDusk ? 1020.0 : 565.0;

    // 1. Sky gradient, weather overlay, stars, celestial sun/moon & lightning
    WestLakeAtmosphereLayers.paintSkyAndCelestial(
      canvas,
      atmosphere: atmosphere,
      westLakePalette: westLakePalette,
      animationTime: animationTime,
      lightningAlpha: lightningAlpha,
      celX: celX,
    );

    // 2. Hills, Baochu Pagoda, Xizhao Hill, Leifeng Pagoda & lake base gradient
    if (cachedStaticPicture != null) {
      canvas.drawPicture(cachedStaticPicture!);
    } else {
      WestLakeStaticArchitecture.paintStaticBackdrop(
        canvas,
        const Size(1500, 1000),
        atmosphere: atmosphere,
        westLakePalette: westLakePalette,
      );
    }

    // 3. Shimmering celestial & Leifeng reflections across West Lake
    WestLakeAtmosphereLayers.paintLakeReflections(
      canvas,
      atmosphere: atmosphere,
      westLakePalette: westLakePalette,
      animationTime: animationTime,
      celX: celX,
      lanternLevel: lanternLevel,
    );

    // 4. Su Causeway & Pinghu Qiuyue Pavilion above lake reflections
    WestLakeBridges.paintCausewayAndPinghuPavilion(
      canvas,
      atmosphere: atmosphere,
      westLakePalette: westLakePalette,
    );

    // 5. Three Pools Mirroring the Moon (三潭印月)
    WestLakeWaterFeatures.paintThreePoolsPagodas(
      canvas,
      animationTime: animationTime,
      lanternLevel: lanternLevel,
      hasSnowCover: hasSnowCover,
    );

    // 6. Painted pleasure boat & hand-rowed punt
    WestLakeWaterFeatures.paintBoats(
      canvas,
      animationTime: animationTime,
      lanternLevel: lanternLevel,
      hasSnowCover: hasSnowCover,
      isDawn: isDawn,
    );

    // 7. Broken Bridge masonry, snow crown, stele pavilion & Hanfu visitors
    WestLakeBridges.paintBrokenBridgeAndStelePavilion(
      canvas,
      atmosphere: atmosphere,
      westLakePalette: westLakePalette,
    );
    WestLakeBridges.paintBrokenBridgeVisitors(
      canvas,
      timeOfDay: atmosphere.timeOfDay,
      animationTime: animationTime,
      isWetWeather: isWetWeather,
      isSnowWeather: isSnowWeather,
    );

    // 8. Quyuan Lotus Cove & water ripples
    WestLakeWaterFeatures.paintQuyuanLotusCove(
      canvas,
      season: atmosphere.season,
      hasSnowCover: hasSnowCover,
      animationTime: animationTime,
    );
    WestLakeWaterFeatures.paintLakeRipples(
      canvas,
      ripples: ripples,
      isWetWeather: isWetWeather,
      isStormy: atmosphere.weather == ShanshuiWeather.stormy,
      animationTime: animationTime,
    );

    // 9. Swaying foreground weeping willow curtains (柳浪闻莺)
    WestLakeAtmosphereLayers.paintWillows(
      canvas,
      season: atmosphere.season,
      hasSnowCover: hasSnowCover,
      animationTime: animationTime,
      wind: wind,
    );

    // 10. Seasonal particles, fireflies & weather precipitation
    WestLakeAtmosphereLayers.paintParticlesAndPrecipitation(
      canvas,
      atmosphere: atmosphere,
      westLakePalette: westLakePalette,
      particles: particles,
      weatherDrops: weatherDrops,
      animationTime: animationTime,
    );

    // 11. Calligraphy colophon, poetic couplet & cinnabar seal
    if (showCalligraphy) {
      WestLakeAtmosphereLayers.paintCalligraphyAndSeal(
        canvas,
        atmosphere: atmosphere,
        isNight: isNight,
        fullPoem: fullPoem,
      );
    }

    // 12. Soft radial vignette
    WestLakeAtmosphereLayers.paintVignette(canvas, isNight: isNight);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WestLakePainter oldDelegate) {
    return oldDelegate.animationTime != animationTime ||
        oldDelegate.atmosphere != atmosphere ||
        oldDelegate.lightningAlpha != lightningAlpha ||
        oldDelegate.showCalligraphy != showCalligraphy ||
        oldDelegate.fullPoem != fullPoem ||
        oldDelegate.ripples.length != ripples.length;
  }
}
