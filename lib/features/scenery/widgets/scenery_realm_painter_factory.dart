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

/// Holds immutable static `ui.Picture` layers cached by [ShanshuiRealm].
class SceneryRealmPictureCache {
  final Map<ShanshuiRealm, ui.Picture> _pictures = {};

  /// Returns the cached `ui.Picture` for [realm], or records one via [recorder].
  /// Realms without a static backdrop (such as Nature) return `null` cleanly.
  ui.Picture? getOrRecord(
    ShanshuiRealm realm,
    ui.Picture? Function() recorder,
  ) {
    final existing = _pictures[realm];
    if (existing != null) return existing;
    final recorded = recorder();
    if (recorded != null) {
      _pictures[realm] = recorded;
    }
    return recorded;
  }

  /// Whether a static picture is currently cached for [realm].
  bool contains(ShanshuiRealm realm) => _pictures.containsKey(realm);

  /// Number of cached static pictures currently retained.
  int get length => _pictures.length;

  /// Disposes all retained `ui.Picture` layers and empties the cache.
  void dispose() {
    for (final picture in _pictures.values) {
      picture.dispose();
    }
    _pictures.clear();
  }
}

/// Immutable per-frame render inputs passed to a scenery realm painter factory.
@immutable
class SceneryRealmFrame {
  final ShanshuiAtmosphereState atmosphere;
  final ShanshuiPalette palette;
  final double animationTime;
  final List<ShanshuiParticle> particles;
  final List<ShanshuiWeatherDrop> weatherDrops;
  final List<ShanshuiCrane> cranes;
  final List<ShanshuiRipple> ripples;
  final bool showCalligraphy;
  final bool fullPoem;
  final double lightningAlpha;

  const SceneryRealmFrame({
    required this.atmosphere,
    required this.palette,
    required this.animationTime,
    required this.particles,
    required this.weatherDrops,
    required this.cranes,
    required this.ripples,
    required this.showCalligraphy,
    required this.fullPoem,
    required this.lightningAlpha,
  });
}

/// Single authoritative registry entry describing a scenery realm's tap
/// interaction policy and `CustomPainter` construction.
@immutable
class SceneryRealmDescriptor {
  final ShanshuiRealm realm;

  /// Normalized minimum Y boundary for water ripples, or `null` if taps do not
  /// spawn water ripples in this realm.
  final double? rippleMinY;

  /// Whether taps in this realm spawn a swirl of petals/motes.
  final bool spawnPetalSwirl;

  /// Constructs the `CustomPainter` for a frame, populating [cache] if needed.
  final CustomPainter Function(
    SceneryRealmFrame frame,
    SceneryRealmPictureCache cache,
  ) buildPainter;

  const SceneryRealmDescriptor({
    required this.realm,
    required this.rippleMinY,
    required this.spawnPetalSwirl,
    required this.buildPainter,
  });

  static final Map<ShanshuiRealm, SceneryRealmDescriptor> _registry = {
    ShanshuiRealm.nature: SceneryRealmDescriptor(
      realm: ShanshuiRealm.nature,
      rippleMinY: 615.0,
      spawnPetalSwirl: false,
      buildPainter: (frame, _) => ShanshuiCanvasPainter(
        atmosphere: frame.atmosphere,
        palette: frame.palette,
        animationTime: frame.animationTime,
        particles: frame.particles,
        weatherDrops: frame.weatherDrops,
        cranes: frame.cranes,
        ripples: frame.ripples,
        showCalligraphy: frame.showCalligraphy,
        fullPoem: frame.fullPoem,
        lightningAlpha: frame.lightningAlpha,
      ),
    ),
    ShanshuiRealm.westLake: SceneryRealmDescriptor(
      realm: ShanshuiRealm.westLake,
      rippleMinY: 520.0,
      spawnPetalSwirl: true,
      buildPainter: (frame, cache) {
        final palette = WestLakePalette.of(
          frame.atmosphere.season,
          frame.atmosphere.timeOfDay,
        );
        final cachedPicture = cache.getOrRecord(
          ShanshuiRealm.westLake,
          () => WestLakePainter.recordStaticPicture(
            atmosphere: frame.atmosphere,
            westLakePalette: palette,
          ),
        );
        return WestLakePainter(
          atmosphere: frame.atmosphere,
          westLakePalette: palette,
          animationTime: frame.animationTime,
          particles: frame.particles,
          weatherDrops: frame.weatherDrops,
          ripples: frame.ripples,
          showCalligraphy: frame.showCalligraphy,
          fullPoem: frame.fullPoem,
          lightningAlpha: frame.lightningAlpha,
          cachedStaticPicture: cachedPicture,
        );
      },
    ),
    ShanshuiRealm.fenghuang: SceneryRealmDescriptor(
      realm: ShanshuiRealm.fenghuang,
      rippleMinY: 555.0,
      spawnPetalSwirl: true,
      buildPainter: (frame, cache) {
        final palette = FenghuangPalette.of(
          frame.atmosphere.season,
          frame.atmosphere.timeOfDay,
        );
        final cachedPicture = cache.getOrRecord(
          ShanshuiRealm.fenghuang,
          () => FenghuangPainter.recordStaticPicture(
            atmosphere: frame.atmosphere,
            fenghuangPalette: palette,
          ),
        );
        return FenghuangPainter(
          atmosphere: frame.atmosphere,
          fenghuangPalette: palette,
          animationTime: frame.animationTime,
          particles: frame.particles,
          weatherDrops: frame.weatherDrops,
          ripples: frame.ripples,
          showCalligraphy: frame.showCalligraphy,
          fullPoem: frame.fullPoem,
          lightningAlpha: frame.lightningAlpha,
          cachedStaticPicture: cachedPicture,
        );
      },
    ),
    ShanshuiRealm.indoor: SceneryRealmDescriptor(
      realm: ShanshuiRealm.indoor,
      rippleMinY: null,
      spawnPetalSwirl: true,
      buildPainter: (frame, cache) {
        final palette = AncientRoomPalette.of(
          frame.atmosphere.season,
          frame.atmosphere.timeOfDay,
        );
        final cachedPicture = cache.getOrRecord(
          ShanshuiRealm.indoor,
          () => AncientRoomPainter.recordStaticPicture(
            atmosphere: frame.atmosphere,
            roomPalette: palette,
          ),
        );
        return AncientRoomPainter(
          atmosphere: frame.atmosphere,
          roomPalette: palette,
          animationTime: frame.animationTime,
          particles: frame.particles,
          weatherDrops: frame.weatherDrops,
          showCalligraphy: frame.showCalligraphy,
          fullPoem: frame.fullPoem,
          lightningAlpha: frame.lightningAlpha,
          cachedStaticPicture: cachedPicture,
        );
      },
    ),
    ShanshuiRealm.outdoor: SceneryRealmDescriptor(
      realm: ShanshuiRealm.outdoor,
      rippleMinY: 615.0,
      spawnPetalSwirl: true,
      buildPainter: (frame, cache) {
        final palette = OutdoorStreetPalette.of(
          frame.atmosphere.season,
          frame.atmosphere.timeOfDay,
        );
        final cachedPicture = cache.getOrRecord(
          ShanshuiRealm.outdoor,
          () => OutdoorStreetPainter.recordStaticPicture(
            atmosphere: frame.atmosphere,
            streetPalette: palette,
          ),
        );
        return OutdoorStreetPainter(
          atmosphere: frame.atmosphere,
          streetPalette: palette,
          animationTime: frame.animationTime,
          particles: frame.particles,
          weatherDrops: frame.weatherDrops,
          ripples: frame.ripples,
          showCalligraphy: frame.showCalligraphy,
          fullPoem: frame.fullPoem,
          lightningAlpha: frame.lightningAlpha,
          cachedStaticPicture: cachedPicture,
        );
      },
    ),
  };

  /// Returns the descriptor governing [realm].
  static SceneryRealmDescriptor of(ShanshuiRealm realm) => _registry[realm]!;
}

/// Dispatches [atmosphere.realm] through [SceneryRealmDescriptor] and populates
/// static `ui.Picture` layers in [cache] on first render.
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
}) {
  return SceneryRealmDescriptor.of(atmosphere.realm).buildPainter(
    SceneryRealmFrame(
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
    ),
    cache,
  );
}
