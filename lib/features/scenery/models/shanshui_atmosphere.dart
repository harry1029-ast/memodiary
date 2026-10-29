import 'package:flutter/material.dart';

/// Seasonal epochs rendered on the Shanshui Scenery Card and Contemplation View.
enum ShanshuiSeason {
  spring(
    id: 'spring',
    nameZh: '春 · 桃夭青绿',
    shortNameZh: '春',
    sealBadgeZh: '春 · 桃夭',
    nameEn: 'Spring · Peach Blossom & Celadon',
    poem: '水面初平云脚低，几处早莺争暖树',
    sealText: '春和景明',
  ),
  summer(
    id: 'summer',
    nameZh: '夏 · 苍山碧水',
    shortNameZh: '夏',
    sealBadgeZh: '夏 · 苍山',
    nameEn: 'Summer · Emerald Crags & Lotus Lake',
    poem: '接天莲叶无穷碧，山色空蒙雨亦奇',
    sealText: '夏木阴阴',
  ),
  fall(
    id: 'fall',
    nameZh: '秋 · 霜林丹枫',
    shortNameZh: '秋',
    sealBadgeZh: '秋 · 丹枫',
    nameEn: 'Fall · Frosted Crags & Cinnabar Maple',
    poem: '停车坐爱枫林晚，霜叶红于二月花',
    sealText: '秋水长天',
  ),
  winter(
    id: 'winter',
    nameZh: '冬 · 寒江瑞雪',
    shortNameZh: '冬',
    sealBadgeZh: '冬 · 瑞雪',
    nameEn: 'Winter · Snow Crags & Warm Hearth',
    poem: '孤舟蓑笠翁，独钓寒江雪',
    sealText: '万山飞雪',
  );

  final String id;
  final String nameZh;
  final String shortNameZh;
  final String sealBadgeZh;
  final String nameEn;
  final String poem;
  final String sealText;

  const ShanshuiSeason({
    required this.id,
    required this.nameZh,
    required this.shortNameZh,
    required this.sealBadgeZh,
    required this.nameEn,
    required this.poem,
    required this.sealText,
  });

  static ShanshuiSeason? fromId(String? rawId) {
    if (rawId == null) return null;
    for (final candidate in ShanshuiSeason.values) {
      if (candidate.id == rawId) return candidate;
    }
    return null;
  }
}

/// Classical Chinese two-hour / solar brackets (时辰) for celestial lighting.
enum ShanshuiTimeOfDay {
  dawn(id: 'dawn', nameZh: '破晓', nameEn: 'Dawn'),
  day(id: 'day', nameZh: '旭日', nameEn: 'Day'),
  dusk(id: 'dusk', nameZh: '夕照', nameEn: 'Dusk'),
  night(id: 'night', nameZh: '明月', nameEn: 'Night');

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

/// Five classical meteorological states (五候气象) modulating wind, mist, and precipitation.
enum ShanshuiWeather {
  sunny(
    id: 'sunny',
    nameZh: '晴空',
    nameEn: 'Sunny',
    badgeZh: '晴空万里',
    windFactor: 1.0,
    mistMultiplier: 1.0,
    celestialAlpha: 1.0,
    skyOverlay: null,
  ),
  cloudy(
    id: 'cloudy',
    nameZh: '云海',
    nameEn: 'Cloudy',
    badgeZh: '云海山岚',
    windFactor: 1.25,
    mistMultiplier: 1.45,
    celestialAlpha: 0.42,
    skyOverlay: Color.fromRGBO(135, 145, 152, 0.22),
  ),
  rainy(
    id: 'rainy',
    nameZh: '烟雨',
    nameEn: 'Rainy',
    badgeZh: '烟雨朦胧',
    windFactor: 1.6,
    mistMultiplier: 1.35,
    celestialAlpha: 0.22,
    skyOverlay: Color.fromRGBO(95, 110, 118, 0.32),
  ),
  stormy(
    id: 'stormy',
    nameZh: '雷雨',
    nameEn: 'Stormy',
    badgeZh: '风雷骤雨',
    windFactor: 3.1,
    mistMultiplier: 1.25,
    celestialAlpha: 0.08,
    skyOverlay: Color.fromRGBO(28, 36, 44, 0.56),
  ),
  snowy(
    id: 'snowy',
    nameZh: '飞雪',
    nameEn: 'Snowy',
    badgeZh: '漫天飞雪',
    windFactor: 1.4,
    mistMultiplier: 1.3,
    celestialAlpha: 0.55,
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

/// Immutable value object bundling the active Shanshui atmospheric state.
@immutable
class ShanshuiAtmosphereState {
  final ShanshuiSeason season;
  final ShanshuiTimeOfDay timeOfDay;
  final ShanshuiWeather weather;
  final bool isManualPreview;

  const ShanshuiAtmosphereState({
    required this.season,
    required this.timeOfDay,
    required this.weather,
    this.isManualPreview = false,
  });

  String get timeWeatherBadgeZh => '${timeOfDay.nameZh} · ${weather.nameZh}';

  ShanshuiAtmosphereState copyWith({
    ShanshuiSeason? season,
    ShanshuiTimeOfDay? timeOfDay,
    ShanshuiWeather? weather,
    bool? isManualPreview,
  }) {
    return ShanshuiAtmosphereState(
      season: season ?? this.season,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      weather: weather ?? this.weather,
      isManualPreview: isManualPreview ?? this.isManualPreview,
    );
  }

  /// Checks whether the 3 core environmental dimensions match [other].
  bool matchesEnvironment(ShanshuiAtmosphereState other) {
    return season == other.season &&
        timeOfDay == other.timeOfDay &&
        weather == other.weather;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShanshuiAtmosphereState &&
        other.season == season &&
        other.timeOfDay == timeOfDay &&
        other.weather == weather &&
        other.isManualPreview == isManualPreview;
  }

  @override
  int get hashCode => Object.hash(season, timeOfDay, weather, isManualPreview);
}

