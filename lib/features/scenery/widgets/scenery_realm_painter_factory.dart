import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/ancient_room_palette.dart';
import '../models/fenghuang_palette.dart';
import '../models/outdoor_street_palette.dart';
import '../models/shanshui_atmosphere.dart';
import '../models/shanshui_palette.dart';
import '../models/shanshui_scenery_geometry.dart';
import '../models/west_lake_palette.dart';
import '../painters/ancient_room_painter.dart';
import '../painters/fenghuang_painter.dart';
import '../painters/outdoor_street_painter.dart';
import '../painters/west_lake_painter.dart';
import 'shanshui_canvas_painter.dart';
import 'shanshui_scenery_painting.dart';

/// Holds immutable static `ui.Picture` layers cached per scenery atmosphere.
class SceneryRealmPictureCache {
  ui.Picture? indoor;
  ui.Picture? outdoor;
  ui.Picture? westLake;
  ui.Picture? fenghuang;

  void dispose() {
    indoor?.dispose();
    indoor = null;
    outdoor?.dispose();
    outdoor = null;
    westLake?.dispose();
    westLake = null;
    fenghuang?.dispose();
    fenghuang = null;
  }
}

/// Dispatches [atmosphere.realm] to its modular `CustomPainter` or override builder,
/// populating static `ui.Picture` caches inside [cache] on first render.
CustomPainter buildSceneryRealmPainter({
  required ShanshuiAtmosphereState atmosphere,
  required ShanshuiPalette palette,
  required SceneryRealmPictureCache cache,
  required double animationTime,
  required List<ShanshuiParticle> particles,
  required List<ShanshuiWeatherDrop> weatherDrops,
  required List<ShanshuiCrane> cranes,
  required List<ShanshuiRipple> ripples,
  required bool showCalligraphy,
  required bool fullPoem,
  required double lightningAlpha,
  RealmPainterBuilder? indoorPainterBuilder,
  RealmPainterBuilder? outdoorPainterBuilder,
  RealmPainterBuilder? westLakePainterBuilder,
  RealmPainterBuilder? fenghuangPainterBuilder,
}) {
  CustomPainter invokeBuilder(RealmPainterBuilder builder) {
    return builder(
      atmosphere: atmosphere,
      palette: palette,
      animationTime: animationTime,
      particles: particles,
      weatherDrops: weatherDrops,
      cranes: cranes,
      ripples: ripples,
      showCalligraphy: showCalligraphy,
      fullPoem: fullPoem,
      lightningAlpha: lightningAlpha,
    );
  }

  switch (atmosphere.realm) {
    case ShanshuiRealm.nature:
      return ShanshuiCanvasPainter(
        atmosphere: atmosphere,
        palette: palette,
        animationTime: animationTime,
        particles: particles,
        weatherDrops: weatherDrops,
        cranes: cranes,
        ripples: ripples,
        showCalligraphy: showCalligraphy,
        fullPoem: fullPoem,
        lightningAlpha: lightningAlpha,
      );
    case ShanshuiRealm.westLake:
      if (westLakePainterBuilder != null) {
        return invokeBuilder(westLakePainterBuilder);
      }
      final westLakePalette =
          WestLakePalette.of(atmosphere.season, atmosphere.timeOfDay);
      cache.westLake ??= WestLakePainter.recordStaticPicture(
        atmosphere: atmosphere,
        westLakePalette: westLakePalette,
      );
      return WestLakePainter(
        atmosphere: atmosphere,
        westLakePalette: westLakePalette,
        animationTime: animationTime,
        particles: particles,
        weatherDrops: weatherDrops,
        ripples: ripples,
        showCalligraphy: showCalligraphy,
        fullPoem: fullPoem,
        lightningAlpha: lightningAlpha,
        cachedStaticPicture: cache.westLake,
      );
    case ShanshuiRealm.fenghuang:
      if (fenghuangPainterBuilder != null) {
        return invokeBuilder(fenghuangPainterBuilder);
      }
      final fenghuangPalette =
          FenghuangPalette.of(atmosphere.season, atmosphere.timeOfDay);
      cache.fenghuang ??= FenghuangPainter.recordStaticPicture(
        atmosphere: atmosphere,
        fenghuangPalette: fenghuangPalette,
      );
      return FenghuangPainter(
        atmosphere: atmosphere,
        fenghuangPalette: fenghuangPalette,
        animationTime: animationTime,
        particles: particles,
        weatherDrops: weatherDrops,
        ripples: ripples,
        showCalligraphy: showCalligraphy,
        fullPoem: fullPoem,
        lightningAlpha: lightningAlpha,
        cachedStaticPicture: cache.fenghuang,
      );
    case ShanshuiRealm.indoor:
      if (indoorPainterBuilder != null) {
        return invokeBuilder(indoorPainterBuilder);
      }
      final roomPalette =
          AncientRoomPalette.of(atmosphere.season, atmosphere.timeOfDay);
      cache.indoor ??= AncientRoomPainter.recordStaticPicture(
        atmosphere: atmosphere,
        roomPalette: roomPalette,
      );
      return AncientRoomPainter(
        atmosphere: atmosphere,
        roomPalette: roomPalette,
        animationTime: animationTime,
        particles: particles,
        weatherDrops: weatherDrops,
        showCalligraphy: showCalligraphy,
        fullPoem: fullPoem,
        lightningAlpha: lightningAlpha,
        cachedStaticPicture: cache.indoor,
      );
    case ShanshuiRealm.outdoor:
      if (outdoorPainterBuilder != null) {
        return invokeBuilder(outdoorPainterBuilder);
      }
      final streetPalette =
          OutdoorStreetPalette.of(atmosphere.season, atmosphere.timeOfDay);
      cache.outdoor ??= OutdoorStreetPainter.recordStaticPicture(
        atmosphere: atmosphere,
        streetPalette: streetPalette,
      );
      return OutdoorStreetPainter(
        atmosphere: atmosphere,
        streetPalette: streetPalette,
        animationTime: animationTime,
        particles: particles,
        weatherDrops: weatherDrops,
        ripples: ripples,
        showCalligraphy: showCalligraphy,
        fullPoem: fullPoem,
        lightningAlpha: lightningAlpha,
        cachedStaticPicture: cache.outdoor,
      );
  }
}
