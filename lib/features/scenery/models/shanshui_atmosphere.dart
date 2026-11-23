import 'package:flutter/material.dart';
import 'shanshui_realm_metadata.dart';

export 'shanshui_realm_metadata.dart';

/// Seasonal particle rendering kinds across five-realm scenery painters.
enum SeasonalParticleKind {
  petals(id: 'petals'),
  fireflies(id: 'fireflies'),
  leaves(id: 'leaves'),
  snow(id: 'snow');

  final String id;

  const SeasonalParticleKind({required this.id});
}

/// User preference for scenery realm resolution.
enum SceneryRealmPreference {
  auto(id: 'auto', nameZh: '自动', nameEn: 'Auto'),
  nature(id: 'nature', nameZh: '山水', nameEn: 'Nature'),
  westLake(id: 'westLake', nameZh: '西湖', nameEn: 'West Lake'),
  fenghuang(id: 'fenghuang', nameZh: '凤凰', nameEn: 'Fenghuang'),
  indoor(id: 'indoor', nameZh: '室内', nameEn: 'Indoor Tea Hall'),
  outdoor(id: 'outdoor', nameZh: '街市', nameEn: 'Ancient Market Street');

  final String id;
  final String nameZh;
  final String nameEn;

  const SceneryRealmPreference({
    required this.id,
    required this.nameZh,
    required this.nameEn,
  });

  /// Canonical [ShanshuiRealm] mapped to this preference
  /// (`ShanshuiRealm.nature` for [SceneryRealmPreference.auto]).
  ShanshuiRealm get defaultRealm => switch (this) {
        SceneryRealmPreference.auto ||
        SceneryRealmPreference.nature =>
          ShanshuiRealm.nature,
        SceneryRealmPreference.westLake => ShanshuiRealm.westLake,
        SceneryRealmPreference.fenghuang => ShanshuiRealm.fenghuang,
        SceneryRealmPreference.indoor => ShanshuiRealm.indoor,
        SceneryRealmPreference.outdoor => ShanshuiRealm.outdoor,
      };

  /// Canonical icon representing this realm preference in switcher sheets and settings.
  IconData get icon => switch (this) {
        SceneryRealmPreference.auto => Icons.auto_awesome_outlined,
        SceneryRealmPreference.nature => Icons.landscape_outlined,
        SceneryRealmPreference.westLake => Icons.water_outlined,
        SceneryRealmPreference.fenghuang => Icons.holiday_village_outlined,
        SceneryRealmPreference.indoor => Icons.meeting_room_outlined,
        SceneryRealmPreference.outdoor => Icons.storefront_outlined,
      };

  static SceneryRealmPreference? fromId(String? rawId) {
    if (rawId == null) return null;
    for (final candidate in SceneryRealmPreference.values) {
      if (candidate.id == rawId) return candidate;
    }
    return null;
  }
}

/// Time-of-day brackets for celestial lighting.
enum ShanshuiTimeOfDay {
  dawn(id: 'dawn', nameZh: '清晨', nameEn: 'Dawn'),
  day(id: 'day', nameZh: '白天', nameEn: 'Day'),
  dusk(id: 'dusk', nameZh: '傍晚', nameEn: 'Dusk'),
  night(id: 'night', nameZh: '夜晚', nameEn: 'Night');

  final String id;
  final String nameZh;
  final String nameEn;

  const ShanshuiTimeOfDay({
    required this.id,
    required this.nameZh,
    required this.nameEn,
  });

  static ShanshuiTimeOfDay? fromId(String? rawId) {
    if (rawId == null) return null;
    for (final candidate in ShanshuiTimeOfDay.values) {
      if (candidate.id == rawId) return candidate;
    }
    return null;
  }
}

/// Five meteorological states modulating wind, mist, and precipitation.
enum ShanshuiWeather {
  sunny(
    id: 'sunny', nameZh: '晴天', nameEn: 'Sunny', badgeZh: '晴空万里',
    windFactor: 1.0, mistMultiplier: 1.0, celestialAlpha: 1.0, skyOverlay: null,
  ),
  cloudy(
    id: 'cloudy', nameZh: '多云', nameEn: 'Cloudy', badgeZh: '云海山岚',
    windFactor: 1.25, mistMultiplier: 1.45, celestialAlpha: 0.42,
    skyOverlay: Color.fromRGBO(135, 145, 152, 0.22),
  ),
  rainy(
    id: 'rainy', nameZh: '小雨', nameEn: 'Rainy', badgeZh: '烟雨朦胧',
    windFactor: 1.6, mistMultiplier: 1.35, celestialAlpha: 0.22,
    skyOverlay: Color.fromRGBO(95, 110, 118, 0.32),
  ),
  stormy(
    id: 'stormy', nameZh: '雷雨', nameEn: 'Stormy', badgeZh: '风雷骤雨',
    windFactor: 3.1, mistMultiplier: 1.25, celestialAlpha: 0.08,
    skyOverlay: Color.fromRGBO(28, 36, 44, 0.56),
  ),
  snowy(
    id: 'snowy', nameZh: '下雪', nameEn: 'Snowy', badgeZh: '漫天飞雪',
    windFactor: 1.4, mistMultiplier: 1.3, celestialAlpha: 0.55,
    skyOverlay: Color.fromRGBO(220, 230, 238, 0.24),
  );

  final String id;
  final String nameZh;
  final String nameEn;
  final String badgeZh;
  final double windFactor;
  final double mistMultiplier;
  final double celestialAlpha;
  final Color? skyOverlay;

  /// Sunlight/moonlight beam strength modifier for the Indoor Moon Window.
  double get indoorBeamMultiplier => switch (this) {
        ShanshuiWeather.sunny => 1.0,
        ShanshuiWeather.cloudy => 0.40,
        ShanshuiWeather.rainy => 0.15,
        ShanshuiWeather.stormy => 0.05,
        ShanshuiWeather.snowy => 0.50,
      };

  /// Base atmospheric dimming modifier under overcast, rainy, stormy, or snowy skies.
  double get ambientDimming => switch (this) {
        ShanshuiWeather.sunny => 0.0,
        ShanshuiWeather.cloudy => 0.10,
        ShanshuiWeather.rainy => 0.20,
        ShanshuiWeather.stormy => 0.35,
        ShanshuiWeather.snowy => 0.08,
      };

  /// Ambient room dimming modifier for the Indoor realm under heavy weather.
  double get indoorRoomDimming => ambientDimming;

  /// Ambient street/exterior dimming modifier for open-air realms under heavy weather.
  double get exteriorDimming => ambientDimming * 0.85;

  /// Resolves the authentic meteorological seal badge for [realm].
  String badgeZhFor(ShanshuiRealm realm) => switch (realm) {
        ShanshuiRealm.indoor => switch (this) {
            ShanshuiWeather.sunny => '晴窗日暖',
            ShanshuiWeather.cloudy => '云岚漫窗',
            ShanshuiWeather.rainy => '蕉窗听雨',
            ShanshuiWeather.stormy => '风雨惊雷',
            ShanshuiWeather.snowy => '推窗看雪',
          },
        ShanshuiRealm.nature ||
        ShanshuiRealm.westLake ||
        ShanshuiRealm.fenghuang ||
        ShanshuiRealm.outdoor =>
          badgeZh,
      };

  const ShanshuiWeather({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    required this.badgeZh,
    required this.windFactor,
    required this.mistMultiplier,
    required this.celestialAlpha,
    required this.skyOverlay,
  });

  static ShanshuiWeather? fromId(String? rawId) {
    if (rawId == null) return null;
    for (final candidate in ShanshuiWeather.values) {
      if (candidate.id == rawId) return candidate;
    }
    return null;
  }
}

/// Immutable value object bundling the active Shanshui atmospheric state across
/// realm (`山水` / `西湖` / `凤凰` / `室内` / `街市`), season, time of day, weather, and inference source.
@immutable
class ShanshuiAtmosphereState {
  final ShanshuiRealm realm;
  final ShanshuiSeason season;
  final ShanshuiTimeOfDay timeOfDay;
  final ShanshuiWeather weather;
  final bool isJournalInferred;
  final bool isManualPreview;

  const ShanshuiAtmosphereState({
    this.realm = ShanshuiRealm.nature,
    required this.season,
    required this.timeOfDay,
    required this.weather,
    this.isJournalInferred = false,
    this.isManualPreview = false,
  });

  String get timeWeatherBadgeZh => '${timeOfDay.nameZh} · ${weather.nameZh}';

  /// Realm-specific classical Chinese title (e.g. `春 · 桃夭茶寮`).
  String get titleZh => season.nameZhFor(realm);

  /// Realm-specific English subtitle (e.g. `Spring · Peach Blossom Tea Hall`).
  String get titleEn => season.nameEnFor(realm);

  /// Realm-specific classical poetic couplet.
  String get poem => season.poemFor(realm);

  /// Realm-specific 4-character cinnabar seal inscription.
  String get sealText => season.sealTextFor(realm);

  /// Realm-specific compact seal badge (e.g. `春 · 桃夭`).
  String get sealBadgeZh => season.sealBadgeZhFor(realm);

  /// Realm badge text: `自动 · <realm>` when inferred, or `<realm>` when manually pinned.
  String get realmBadgeZh =>
      isJournalInferred ? '自动 · ${realm.shortNameZh}' : realm.shortNameZh;

  ShanshuiAtmosphereState copyWith({
    ShanshuiRealm? realm,
    ShanshuiSeason? season,
    ShanshuiTimeOfDay? timeOfDay,
    ShanshuiWeather? weather,
    bool? isJournalInferred,
    bool? isManualPreview,
  }) {
    return ShanshuiAtmosphereState(
      realm: realm ?? this.realm,
      season: season ?? this.season,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      weather: weather ?? this.weather,
      isJournalInferred: isJournalInferred ?? this.isJournalInferred,
      isManualPreview: isManualPreview ?? this.isManualPreview,
    );
  }

  /// Checks whether the 4 core environmental dimensions match [other].
  bool matchesEnvironment(ShanshuiAtmosphereState other) {
    return realm == other.realm &&
        season == other.season &&
        timeOfDay == other.timeOfDay &&
        weather == other.weather;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShanshuiAtmosphereState &&
        other.realm == realm &&
        other.season == season &&
        other.timeOfDay == timeOfDay &&
        other.weather == weather &&
        other.isJournalInferred == isJournalInferred &&
        other.isManualPreview == isManualPreview;
  }

  @override
  int get hashCode => Object.hash(
        realm,
        season,
        timeOfDay,
        weather,
        isJournalInferred,
        isManualPreview,
      );
}

