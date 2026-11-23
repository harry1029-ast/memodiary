import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/ancient_room_palette.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_scenery_geometry.dart';
import 'ancient_room_alcove_layer.dart';
import 'ancient_room_lantern_layers.dart';
import 'ancient_room_lighting_layers.dart';
import 'ancient_room_static_architecture.dart';
import 'ancient_room_window_layer.dart';

/// Full interactive vector painter for the Indoor Tea Hall (`室内`) realm.
///
/// Combines a cached static architectural `ui.Picture` layer with dynamic 60 FPS
/// animations: live outdoor weather visible through the Moon Window (`月洞窗`),
/// swaying cyan silk drapes and hanging banners, volumetric sun/moon beams,
/// curling incense smoke & tea steam, glowing lanterns, winter red-clay charcoal
/// embers (`红泥小火炉`), floating dust motes/petals, ambient screen candle
/// halos, and bottom-right vertical calligraphy colophons.
class AncientRoomPainter extends CustomPainter {
  final ShanshuiAtmosphereState atmosphere;
  final AncientRoomPalette roomPalette;
  final double animationTime;
  final List<ShanshuiParticle> particles;
  final List<ShanshuiWeatherDrop> weatherDrops;
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

    // 1. Live Outdoor Courtyard clipped to Left Moon Window (月洞窗), frame drawn after restore
    AncientRoomWindowLayer.paintLiveMoonWindow(
      canvas,
      atmosphere: atmosphere,
      roomPalette: roomPalette,
      animationTime: animationTime,
      particles: particles,
      weatherDrops: weatherDrops,
      lightningAlpha: lightningAlpha,
    );

    // 2. Static room architecture (from cached Picture or direct call)
    if (cachedStaticPicture != null) {
      canvas.drawPicture(cachedStaticPicture!);
    } else {
      AncientRoomStaticArchitecture.paintStaticArchitecture(
        canvas,
        const Size(1500, 1000),
        atmosphere: atmosphere,
        roomPalette: roomPalette,
      );
    }

    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;
    final windFactor = atmosphere.weather.windFactor;
    final flicker1 =
        math.sin(animationTime * 7.5) * 0.5 + math.cos(animationTime * 13.2) * 0.5;
    final flicker2 = math.sin(animationTime * 6.2 + 1.4) * 0.5 +
        math.sin(animationTime * 11.8) * 0.5;
    final hasSnow = atmosphere.season == ShanshuiSeason.winter ||
        atmosphere.weather == ShanshuiWeather.snowy;
    final candleLevel = _candleLevel;
    final chandelierX = 720.0 +
        math.sin(animationTime * 1.1 * windFactor) * (2.5 * windFactor);

    // 3. Inner Shoji Lantern Halo (clipped clear of Moon Gate rim)
    _paintInnerLanternGlow(canvas, candleLevel: candleLevel, flicker: flicker2);

    // 4. Dynamic Right Wall Moon Archway Alcove (swaying cyan drapes, emerald banner, wall lantern)
    _paintDynamicRightAlcove(canvas, flicker: flicker1);

    // 5. Twin Swaying Cream-Silk Hanging Banners flanking Moon Gate
    AncientRoomLanternLayers.paintHangingBanners(
      canvas,
      isNight: isNight,
      animationTime: animationTime,
      windFactor: windFactor,
    );

    // 6. Dual BlendMode.screen Volumetric Light Beams & Elliptical Floor Pools
    AncientRoomLightingLayers.paintVolumetricLightBeams(
      canvas,
      atmosphere: atmosphere,
      palette: roomPalette,
    );

    // 7. Left Tall Wooden Floor Palace Lantern (tassels, glowing shade, flame)
    AncientRoomLanternLayers.paintFloorPalaceLanternShade(
      canvas,
      roomPalette,
      candleLevel: candleLevel,
      flicker: flicker2,
    );

    // 8. Conditional Winter/Snow Red-Clay Charcoal Brazier (760, 740)
    if (hasSnow) {
      AncientRoomLanternLayers.paintWinterCharcoalBrazier(
        canvas,
        animationTime: animationTime,
        flicker: flicker1,
      );
    }

    // 9. Curling Incense Smoke & Tea Steam Particle Spheres
    AncientRoomLightingLayers.paintSmokeAndSteam(
      canvas,
      animationTime: animationTime,
      windFactor: windFactor,
      isNight: isNight,
    );

    // 10. Foreground Hero Painted Plum-Blossom Table Lantern (465, 835)
    AncientRoomLanternLayers.paintTablePlumLantern(
      canvas,
      candleLevel: candleLevel,
      flicker: flicker1,
    );

    // 11. Top Swaying Woven Bamboo Chandelier (720, 215)
    AncientRoomLanternLayers.paintBambooChandelier(
      canvas,
      candleLevel: candleLevel,
      flicker: flicker2,
      animationTime: animationTime,
      windFactor: windFactor,
    );

    // 12. Room Ambient Overlay, Weather Dimming, Lightning Flash & Screen Candle Halos
    AncientRoomLightingLayers.paintAmbientAndScreenHalos(
      canvas,
      atmosphere: atmosphere,
      palette: roomPalette,
      lightningAlpha: lightningAlpha,
      candleLevel: candleLevel,
      flicker1: flicker1,
      flicker2: flicker2,
      chandelierX: chandelierX,
    );

    // 13. Floating Indoor Golden Dust Motes & Rotating Petals
    AncientRoomLightingLayers.paintIndoorParticles(
      canvas,
      particles: particles,
      palette: roomPalette,
      animationTime: animationTime,
      isNight: isNight,
    );

    // 14. Bottom-Right Vertical Calligraphy Colophon, 2x2 Seal & Soft Radial Vignette
    if (showCalligraphy) {
      AncientRoomLightingLayers.paintCalligraphyAndSeal(
        canvas,
        atmosphere: atmosphere,
        isNight: isNight,
        fullPoem: fullPoem,
      );
    }
    AncientRoomLightingLayers.paintVignette(canvas, isNight: isNight);

    canvas.restore();
  }

  double get _candleLevel {
    final weatherBoost = atmosphere.weather == ShanshuiWeather.rainy
        ? 0.25
        : atmosphere.weather == ShanshuiWeather.stormy
            ? 0.45
            : 0.0;
    return (roomPalette.candleIntensity + weatherBoost).clamp(0.0, 1.0);
  }

  void _paintInnerLanternGlow(
    Canvas canvas, {
    required double candleLevel,
    required double flicker,
  }) {
    canvas.save();
    final innerClip = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(const Rect.fromLTWH(566, 244, 308, 381))
      ..addOval(Rect.fromCircle(center: const Offset(720, 478), radius: 167))
      ..addOval(Rect.fromCircle(center: const Offset(720, 478), radius: 149));
    canvas.clipPath(innerClip);
    AncientRoomLightingLayers.paintCandleGlow(
      canvas,
      const Offset(720, 365),
      95.0,
      candleLevel * 0.85,
      flicker,
      showFlame: false,
    );
    canvas.restore();
  }

  void _paintDynamicRightAlcove(Canvas canvas, {required double flicker}) {
    final windFactor = atmosphere.weather.windFactor;
    final curtainSway =
        math.sin(animationTime * 1.3 * windFactor) * (5.0 * windFactor);
    final isNight = atmosphere.timeOfDay == ShanshuiTimeOfDay.night;

    canvas.save();
    canvas.clipPath(AncientRoomAlcoveLayer.buildRightWallPath());
    canvas.clipPath(
      Path()
        ..addOval(
          Rect.fromCircle(
            center: AncientRoomAlcoveLayer.rightArchCenter,
            radius: AncientRoomAlcoveLayer.rightArchInnerRadius,
          ),
        ),
    );
    AncientRoomAlcoveLayer.paintRightAlcoveContent(
      canvas,
      roomPalette,
      isNight: isNight,
      candleLevel: _candleLevel,
      curtainSway: curtainSway,
      flicker: flicker,
      includeGlow: true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(AncientRoomPainter oldDelegate) {
    return animationTime != oldDelegate.animationTime ||
        atmosphere != oldDelegate.atmosphere ||
        roomPalette != oldDelegate.roomPalette ||
        particles.length != oldDelegate.particles.length ||
        weatherDrops.length != oldDelegate.weatherDrops.length ||
        showCalligraphy != oldDelegate.showCalligraphy ||
        fullPoem != oldDelegate.fullPoem ||
        lightningAlpha != oldDelegate.lightningAlpha ||
        cachedStaticPicture != oldDelegate.cachedStaticPicture;
  }
}
