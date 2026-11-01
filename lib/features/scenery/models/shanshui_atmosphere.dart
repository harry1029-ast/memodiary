import 'package:flutter/material.dart';

/// The three classical scenery realms for MemoDiary:
/// Nature (`林泉`), Indoor Scholar Tea Hall (`雅室`), and Outdoor Market Street (`市井`).
enum ShanshuiRealm {
  nature(
    id: 'nature',
    shortNameZh: '林泉',
    nameEn: 'Nature',
  ),
  indoor(
    id: 'indoor',
    shortNameZh: '雅室',
    nameEn: 'Indoor Tea Hall',
  ),
  outdoor(
    id: 'outdoor',
    shortNameZh: '市井',
    nameEn: 'Ancient Market Street',
  );

  final String id;
  final String shortNameZh;
  final String nameEn;

  const ShanshuiRealm({
    required this.id,
    required this.shortNameZh,
    required this.nameEn,
  });

  static ShanshuiRealm? fromId(String? rawId) {
    if (rawId == null) return null;
    for (final candidate in ShanshuiRealm.values) {
      if (candidate.id == rawId) return candidate;
    }
    return null;
  }
}

/// User preference for scenery realm resolution.
enum SceneryRealmPreference {
  auto(
    id: 'auto',
    nameZh: '随文入境',
    nameEn: 'Auto',
  ),
  nature(
    id: 'nature',
    nameZh: '林泉',
    nameEn: 'Nature',
  ),
  indoor(
    id: 'indoor',
    nameZh: '雅室',
    nameEn: 'Indoor Tea Hall',
  ),
  outdoor(
    id: 'outdoor',
    nameZh: '市井',
    nameEn: 'Ancient Market Street',
  );

  final String id;
  final String nameZh;
  final String nameEn;

  const SceneryRealmPreference({
    required this.id,
    required this.nameZh,
    required this.nameEn,
  });

  static SceneryRealmPreference? fromId(String? rawId) {
    if (rawId == null) return null;
    for (final candidate in SceneryRealmPreference.values) {
      if (candidate.id == rawId) return candidate;
    }
    return null;
  }
}

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

  /// Resolves the authentic realm-specific Chinese title for [realm].
  String nameZhFor(ShanshuiRealm realm) {
    switch (realm) {
      case ShanshuiRealm.nature:
        return nameZh;
      case ShanshuiRealm.indoor:
        switch (this) {
          case ShanshuiSeason.spring:
            return '春 · 桃夭茶寮';
          case ShanshuiSeason.summer:
            return '夏 · 翠竹听荷';
          case ShanshuiSeason.fall:
            return '秋 · 霜枫品茗';
          case ShanshuiSeason.winter:
            return '冬 · 瑞雪温炉';
        }
      case ShanshuiRealm.outdoor:
        switch (this) {
          case ShanshuiSeason.spring:
            return '春 · 桃李春风集';
          case ShanshuiSeason.summer:
            return '夏 · 翠峰槐夏市';
          case ShanshuiSeason.fall:
            return '秋 · 霜峰丹枫街';
          case ShanshuiSeason.winter:
            return '冬 · 瑞雪岁朝集';
        }
    }
  }

  /// Resolves the authentic realm-specific English subtitle for [realm].
  String nameEnFor(ShanshuiRealm realm) {
    switch (realm) {
      case ShanshuiRealm.nature:
        return nameEn;
      case ShanshuiRealm.indoor:
        switch (this) {
          case ShanshuiSeason.spring:
            return 'Spring · Peach Blossom Tea Hall';
          case ShanshuiSeason.summer:
            return 'Summer · Emerald Bamboo & Tea Pavilion';
          case ShanshuiSeason.fall:
            return 'Fall · Cinnabar Maple & Hearth Tea';
          case ShanshuiSeason.winter:
            return 'Winter · Red Plum & Warm Hearth';
        }
      case ShanshuiRealm.outdoor:
        switch (this) {
          case ShanshuiSeason.spring:
            return 'Spring · Vernal Market & Peach Blossom';
          case ShanshuiSeason.summer:
            return 'Summer · Emerald Crags & Mountain Market';
          case ShanshuiSeason.fall:
            return 'Fall · Cinnabar Maple & Autumn Harvest Street';
          case ShanshuiSeason.winter:
            return 'Winter · Snow-Capped Mountain Market';
        }
    }
  }

  /// Resolves the authentic realm-specific classical poetic couplet for [realm].
  String poemFor(ShanshuiRealm realm) {
    switch (realm) {
      case ShanshuiRealm.nature:
        return poem;
      case ShanshuiRealm.indoor:
        switch (this) {
          case ShanshuiSeason.spring:
            return '小楼一夜听春雨，深巷明朝卖杏花';
          case ShanshuiSeason.summer:
            return '水晶帘动微风起，满架蔷薇一院香';
          case ShanshuiSeason.fall:
            return '寒夜客来茶当酒，竹炉汤沸火初红';
          case ShanshuiSeason.winter:
            return '绿蚁新醅酒，红泥小火炉。晚来天欲雪，能饮一杯无';
        }
      case ShanshuiRealm.outdoor:
        switch (this) {
          case ShanshuiSeason.spring:
            return '千门万户曈曈日，总把新桃换旧符';
          case ShanshuiSeason.summer:
            return '绿树阴浓夏日长，楼台倒影入池塘';
          case ShanshuiSeason.fall:
            return '停车坐爱枫林晚，霜叶红于二月花';
          case ShanshuiSeason.winter:
            return '千山鸟飞绝，万径人踪灭。瑞雪兆丰年';
        }
    }
  }

  /// Resolves the authentic realm-specific 4-character cinnabar seal text for [realm].
  String sealTextFor(ShanshuiRealm realm) {
    switch (realm) {
      case ShanshuiRealm.nature:
        return sealText;
      case ShanshuiRealm.indoor:
        switch (this) {
          case ShanshuiSeason.spring:
            return '春风入室';
          case ShanshuiSeason.summer:
            return '夏木阴阴';
          case ShanshuiSeason.fall:
            return '秋水长天';
          case ShanshuiSeason.winter:
            return '瑞雪迎春';
        }
      case ShanshuiRealm.outdoor:
        switch (this) {
          case ShanshuiSeason.spring:
            return '春和景明';
          case ShanshuiSeason.summer:
            return '碧山晴夏';
          case ShanshuiSeason.fall:
            return '金秋盛景';
          case ShanshuiSeason.winter:
            return '万山飞雪';
        }
    }
  }

  /// Resolves the compact Chinese seal badge for [realm].
  String sealBadgeZhFor(ShanshuiRealm realm) {
    switch (realm) {
      case ShanshuiRealm.nature:
        return sealBadgeZh;
      case ShanshuiRealm.indoor:
        switch (this) {
          case ShanshuiSeason.spring:
            return '春 · 桃夭';
          case ShanshuiSeason.summer:
            return '夏 · 听荷';
          case ShanshuiSeason.fall:
            return '秋 · 品茗';
          case ShanshuiSeason.winter:
            return '冬 · 温炉';
        }
      case ShanshuiRealm.outdoor:
        switch (this) {
          case ShanshuiSeason.spring:
            return '春 · 春风集';
          case ShanshuiSeason.summer:
            return '夏 · 槐夏市';
          case ShanshuiSeason.fall:
            return '秋 · 丹枫街';
          case ShanshuiSeason.winter:
            return '冬 · 岁朝集';
        }
    }
  }

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

/// Immutable value object bundling the active Shanshui atmospheric state across
/// realm (`林泉` / `雅室` / `市井`), season, time of day, weather, and inference source.
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

  /// Realm badge text: `随文入境 · <realm>` when inferred, or `<realm>` when manually pinned.
  String get realmBadgeZh =>
      isJournalInferred ? '随文入境 · ${realm.shortNameZh}' : realm.shortNameZh;

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

