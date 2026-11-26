import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/fenghuang_palette.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_scenery_geometry.dart';
import 'fenghuang_architecture_layers.dart';
import 'fenghuang_atmosphere_layers.dart';
import 'fenghuang_river_layers.dart';
import 'fenghuang_static_architecture.dart';
import 'fenghuang_stepping_stones_layer.dart';
import 'scenery_canvas_painter_base.dart';
import 'shanshui_atmospheric_effects.dart';

/// Full interactive 1500x1000 vector painter for Xiangxi Fenghuang Ancient Town (`凤凰`).
///
/// Pairs an immutable cached `ui.Picture` static backdrop (layered NanHua and
/// Wuling karst ridges, emerald Tuojiang River base, 7-tiered white Wanming Pagoda,
/// 3-arch Hongqiao Wind & Rain Covered Bridge, riverbank seasonal trees, and 10
/// multi-story wooden Stilt Houses) with dynamic 60 FPS animations across all
/// 4 seasons, 4 times of day, and 5 weathers.
class FenghuangPainter extends SceneryCanvasPainterBase {
  final FenghuangPalette fenghuangPalette;
  final List<ShanshuiRipple> ripples;

  static const _calligraphyConfig = SceneryCalligraphyConfig(
    titleX: 1422.0,
    titleY: 58.0,
    poemStartX: 1376.0,
    poemStartY: 66.0,
    sealX: 1412.0,
  );

  FenghuangPainter({
    required super.atmosphere,
    FenghuangPalette? fenghuangPalette,
    required super.animationTime,
    required super.particles,
    required super.weatherDrops,
    this.ripples = const [],
    super.showCalligraphy = false,
    super.fullPoem = false,
    super.lightningAlpha = 0.0,
    super.cachedStaticPicture,
  }) : fenghuangPalette = fenghuangPalette ??
            FenghuangPalette.of(atmosphere.season, atmosphere.timeOfDay);

  /// Records static Fenghuang landscape & architecture into an immutable
  /// `ui.Picture` cached per `(season, timeOfDay, weather)` environment.
  static ui.Picture recordStaticPicture({
    required ShanshuiAtmosphereState atmosphere,
    required FenghuangPalette fenghuangPalette,
  }) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1500, 1000));
    FenghuangStaticArchitecture.paintStaticBackdrop(
      canvas,
      const Size(1500, 1000),
      atmosphere: atmosphere,
      fenghuangPalette: fenghuangPalette,
    );
    return recorder.endRecording();
  }

  /// Exposes the effective lantern/window illumination factor (`0.0..1.0`).
  static double effectiveLanternLevel(
    FenghuangPalette palette,
    ShanshuiWeather weather,
  ) =>
      FenghuangStaticArchitecture.effectiveLanternLevel(palette, weather);

  /// Exposes active Tuojiang Stepping Stones visitor count per time of day.
  static int visibleSteppingVisitors(ShanshuiTimeOfDay timeOfDay) =>
      FenghuangSteppingStonesLayer.visibleSteppingVisitorCount(timeOfDay);

  /// Exposes active Tuojiang wooden punt boat count per time of day.
  static int visibleBoats(ShanshuiTimeOfDay timeOfDay) =>
      FenghuangRiverLayers.visibleBoatCount(timeOfDay);

  /// Exposes active floating lotus river lantern count per time of day.
  static int floatingRiverLanterns(ShanshuiTimeOfDay timeOfDay) =>
      FenghuangRiverLayers.floatingLanternCount(timeOfDay);

  @override
  int get rippleCount => ripples.length;

  @override
  bool shouldRepaintExtra(covariant FenghuangPainter oldDelegate) =>
      oldDelegate.fenghuangPalette != fenghuangPalette;

  @override
  void paintScene(Canvas canvas) {
    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;
    final isWetWeather = atmosphere.weather == ShanshuiWeather.rainy ||
        atmosphere.weather == ShanshuiWeather.stormy;
    final isSnowWeather = atmosphere.weather == ShanshuiWeather.snowy;
    final hasSnowCover =
        atmosphere.season == ShanshuiSeason.winter || isSnowWeather;
    final wind = atmosphere.weather.windFactor;
    final lanternLevel = FenghuangStaticArchitecture.effectiveLanternLevel(
      fenghuangPalette,
      atmosphere.weather,
    );

    // 1. Sky gradient, weather overlay, stars, celestial body & stormy lightning
    FenghuangAtmosphereLayers.paintSkyAndCelestial(
      canvas,
      atmosphere: atmosphere,
      fenghuangPalette: fenghuangPalette,
      animationTime: animationTime,
      lightningAlpha: lightningAlpha,
    );

    // 2. Karst ridges, Tuojiang River base, Wanming Pagoda, Hongqiao Bridge & Stilt Houses
    if (cachedStaticPicture != null) {
      canvas.drawPicture(cachedStaticPicture!);
    } else {
      FenghuangStaticArchitecture.paintStaticBackdrop(
        canvas,
        const Size(1500, 1000),
        atmosphere: atmosphere,
        fenghuangPalette: fenghuangPalette,
      );
    }

    // 3. Shimmering golden/red reflections clipped to open Tuojiang water
    FenghuangRiverLayers.paintRiverReflections(
      canvas,
      atmosphere: atmosphere,
      fenghuangPalette: fenghuangPalette,
      animationTime: animationTime,
      celX: FenghuangAtmosphereLayers.celestialX,
      lanternLevel: lanternLevel,
    );

    // 4. Swaying corner red lanterns under stilt-house eaves
    FenghuangArchitectureLayers.paintStiltHouseCornerLanterns(
      canvas,
      animationTime: animationTime,
      wind: wind,
      lanternLevel: lanternLevel,
    );

    // 5. Drifting river mist & gliding Tuojiang wooden punt boats (乌篷船)
    FenghuangRiverLayers.paintRiverMist(
      canvas,
      atmosphere: atmosphere,
      fenghuangPalette: fenghuangPalette,
      animationTime: animationTime,
      wind: wind,
    );
    FenghuangRiverLayers.paintTuojiangBoats(
      canvas,
      timeOfDay: atmosphere.timeOfDay,
      animationTime: animationTime,
      lanternLevel: lanternLevel,
      hasSnowCover: hasSnowCover,
    );

    // 6. Tuojiang Stepping Stones (跳岩), white rapids & Miao-headdress visitors
    FenghuangSteppingStonesLayer.paintSteppingStonesAndVisitors(
      canvas,
      timeOfDay: atmosphere.timeOfDay,
      animationTime: animationTime,
      hasSnowCover: hasSnowCover,
      isWetWeather: isWetWeather,
      isSnowWeather: isSnowWeather,
    );

    // 7. Floating pink lotus river lanterns (沱江河灯) & river ripples
    FenghuangRiverLayers.paintFloatingRiverLanterns(
      canvas,
      timeOfDay: atmosphere.timeOfDay,
      animationTime: animationTime,
    );
    FenghuangRiverLayers.paintRiverRipples(
      canvas,
      ripples: ripples,
      isWetWeather: isWetWeather,
      isStormy: atmosphere.weather == ShanshuiWeather.stormy,
      animationTime: animationTime,
    );

    // 8. Swaying foreground overhanging seasonal branches
    FenghuangAtmosphereLayers.paintForegroundBranches(
      canvas,
      fenghuangPalette: fenghuangPalette,
      hasSnowCover: hasSnowCover,
      animationTime: animationTime,
      wind: wind,
    );

    // 9. Seasonal particles, summer fireflies & weather precipitation
    FenghuangAtmosphereLayers.paintParticlesAndPrecipitation(
      canvas,
      atmosphere: atmosphere,
      fenghuangPalette: fenghuangPalette,
      particles: particles,
      weatherDrops: weatherDrops,
      animationTime: animationTime,
    );

    // 10. Top-right vertical calligraphy colophon, 2x2 cinnabar seal & vignette
    if (showCalligraphy) {
      ShanshuiAtmosphericEffects.drawCalligraphyAndSeal(
        canvas,
        atmosphere: atmosphere,
        isNight: isNight,
        fullPoem: fullPoem,
        config: _calligraphyConfig,
      );
    }
    ShanshuiAtmosphericEffects.drawVignette(canvas, isNight: isNight);
  }
}
