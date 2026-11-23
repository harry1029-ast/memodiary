import 'package:flutter/material.dart';

/// The five scenery realms for MemoDiary:
/// Nature (`山水`), West Lake (`西湖`), Fenghuang (`凤凰`), Indoor (`室内`), and Outdoor (`街市`).
enum ShanshuiRealm {
  nature(id: 'nature', shortNameZh: '山水', nameEn: 'Nature'),
  westLake(id: 'westLake', shortNameZh: '西湖', nameEn: 'West Lake'),
  fenghuang(id: 'fenghuang', shortNameZh: '凤凰', nameEn: 'Fenghuang'),
  indoor(id: 'indoor', shortNameZh: '室内', nameEn: 'Indoor Tea Hall'),
  outdoor(id: 'outdoor', shortNameZh: '街市', nameEn: 'Ancient Market Street');

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

class _RealmSeasonMeta {
  final String nameZh;
  final String nameEn;
  final String poem;
  final String sealText;
  final String sealBadgeZh;

  const _RealmSeasonMeta(
    this.nameZh,
    this.nameEn,
    this.poem,
    this.sealText,
    this.sealBadgeZh,
  );
}

const Map<ShanshuiRealm, Map<ShanshuiSeason, _RealmSeasonMeta>> _realmSeasonMetadata = {
  ShanshuiRealm.westLake: {
    ShanshuiSeason.spring: _RealmSeasonMeta(
      '春 · 苏堤春晓柳如烟',
      'Spring · Su Causeway Dawn & Peach Blossoms',
      '间株杨柳间株桃，水光潋滟晴方好',
      '苏堤春晓',
      '春 · 苏堤',
    ),
    ShanshuiSeason.summer: _RealmSeasonMeta(
      '夏 · 曲院风荷碧连天',
      'Summer · Breeze-Ruffled Lotus at Quyuan',
      '接天莲叶无穷碧，映日荷花别样红',
      '曲院风荷',
      '夏 · 风荷',
    ),
    ShanshuiSeason.fall: _RealmSeasonMeta(
      '秋 · 平湖秋月雷峰晚',
      'Fall · Autumn Moon & Leifeng Pagoda Sunset',
      '雷峰夕照金波涌，三潭印月桂子香',
      '平湖秋月',
      '秋 · 秋月',
    ),
    ShanshuiSeason.winter: _RealmSeasonMeta(
      '冬 · 断桥残雪留荷影',
      'Winter · Melting Snow on Broken Bridge',
      '晴雪初消断桥石，留得枯荷听雨声',
      '断桥残雪',
      '冬 · 残雪',
    ),
  },
  ShanshuiRealm.fenghuang: {
    ShanshuiSeason.spring: _RealmSeasonMeta(
      '春 · 烟雨桃花映沱江',
      'Spring · Misty Peach Blossoms on Tuojiang',
      '江水初平翠黛低，吊脚楼前桃花溪',
      '湘西春晓',
      '春 · 沱江',
    ),
    ShanshuiSeason.summer: _RealmSeasonMeta(
      '夏 · 沱江碧水听摇橹',
      'Summer · Emerald Tuojiang & Rowing Skiffs',
      '两岸吊脚悬碧水，一舟摇碎满江星',
      '沱江清夏',
      '夏 · 摇橹',
    ),
    ShanshuiSeason.fall: _RealmSeasonMeta(
      '秋 · 丹枫尽染虹桥晚',
      'Fall · Crimson Maples at Hongqiao Evening',
      '万名塔下秋波静，虹桥风起落丹枫',
      '边城秋色',
      '秋 · 虹桥',
    ),
    ShanshuiSeason.winter: _RealmSeasonMeta(
      '冬 · 雪落凤凰万家灯',
      'Winter · Snowfall & Stilt-House Lanterns',
      '跳岩雪映红灯影，吊脚楼头暖火明',
      '凤城瑞雪',
      '冬 · 凤凰',
    ),
  },
  ShanshuiRealm.indoor: {
    ShanshuiSeason.spring: _RealmSeasonMeta(
      '春 · 桃夭茶寮',
      'Spring · Peach Blossom Tea Hall',
      '小楼一夜听春雨，深巷明朝卖杏花',
      '春风入室',
      '春 · 桃夭',
    ),
    ShanshuiSeason.summer: _RealmSeasonMeta(
      '夏 · 翠竹听荷',
      'Summer · Emerald Bamboo & Tea Pavilion',
      '水晶帘动微风起，满架蔷薇一院香',
      '夏木阴阴',
      '夏 · 听荷',
    ),
    ShanshuiSeason.fall: _RealmSeasonMeta(
      '秋 · 霜枫品茗',
      'Fall · Cinnabar Maple & Hearth Tea',
      '寒夜客来茶当酒，竹炉汤沸火初红',
      '秋水长天',
      '秋 · 品茗',
    ),
    ShanshuiSeason.winter: _RealmSeasonMeta(
      '冬 · 瑞雪温炉',
      'Winter · Red Plum & Warm Hearth',
      '绿蚁新醅酒，红泥小火炉。晚来天欲雪，能饮一杯无',
      '瑞雪迎春',
      '冬 · 温炉',
    ),
  },
  ShanshuiRealm.outdoor: {
    ShanshuiSeason.spring: _RealmSeasonMeta(
      '春 · 桃李春风集',
      'Spring · Vernal Market & Peach Blossom',
      '千门万户曈曈日，总把新桃换旧符',
      '春和景明',
      '春 · 春风集',
    ),
    ShanshuiSeason.summer: _RealmSeasonMeta(
      '夏 · 翠峰槐夏市',
      'Summer · Emerald Crags & Mountain Market',
      '绿树阴浓夏日长，楼台倒影入池塘',
      '碧山晴夏',
      '夏 · 槐夏市',
    ),
    ShanshuiSeason.fall: _RealmSeasonMeta(
      '秋 · 霜峰丹枫街',
      'Fall · Cinnabar Maple & Autumn Harvest Street',
      '停车坐爱枫林晚，霜叶红于二月花',
      '金秋盛景',
      '秋 · 丹枫街',
    ),
    ShanshuiSeason.winter: _RealmSeasonMeta(
      '冬 · 瑞雪岁朝集',
      'Winter · Snow-Capped Mountain Market',
      '千山鸟飞绝，万径人踪灭。瑞雪兆丰年',
      '万山飞雪',
      '冬 · 岁朝集',
    ),
  },
};

/// Seasonal epochs rendered on the Shanshui Scenery Card and Contemplation View.
enum ShanshuiSeason {
  spring(
    id: 'spring', nameZh: '春 · 桃夭青绿', shortNameZh: '春', sealBadgeZh: '春 · 桃夭',
    nameEn: 'Spring · Peach Blossom & Celadon', poem: '水面初平云脚低，几处早莺争暖树', sealText: '春和景明',
  ),
  summer(
    id: 'summer', nameZh: '夏 · 苍山碧水', shortNameZh: '夏', sealBadgeZh: '夏 · 苍山',
    nameEn: 'Summer · Emerald Crags & Lotus Lake', poem: '接天莲叶无穷碧，山色空蒙雨亦奇', sealText: '夏木阴阴',
  ),
  fall(
    id: 'fall', nameZh: '秋 · 霜林丹枫', shortNameZh: '秋', sealBadgeZh: '秋 · 丹枫',
    nameEn: 'Fall · Frosted Crags & Cinnabar Maple', poem: '停车坐爱枫林晚，霜叶红于二月花', sealText: '秋水长天',
  ),
  winter(
    id: 'winter', nameZh: '冬 · 寒江瑞雪', shortNameZh: '冬', sealBadgeZh: '冬 · 瑞雪',
    nameEn: 'Winter · Snow Crags & Warm Hearth', poem: '孤舟蓑笠翁，独钓寒江雪', sealText: '万山飞雪',
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
  String nameZhFor(ShanshuiRealm realm) =>
      _realmSeasonMetadata[realm]?[this]?.nameZh ?? nameZh;

  /// Resolves the authentic realm-specific English subtitle for [realm].
  String nameEnFor(ShanshuiRealm realm) =>
      _realmSeasonMetadata[realm]?[this]?.nameEn ?? nameEn;

  /// Resolves the authentic realm-specific classical poetic couplet for [realm].
  String poemFor(ShanshuiRealm realm) =>
      _realmSeasonMetadata[realm]?[this]?.poem ?? poem;

  /// Resolves the authentic realm-specific 4-character cinnabar seal text for [realm].
  String sealTextFor(ShanshuiRealm realm) =>
      _realmSeasonMetadata[realm]?[this]?.sealText ?? sealText;

  /// Resolves the compact Chinese seal badge for [realm].
  String sealBadgeZhFor(ShanshuiRealm realm) =>
      _realmSeasonMetadata[realm]?[this]?.sealBadgeZh ?? sealBadgeZh;

  static ShanshuiSeason? fromId(String? rawId) {
    if (rawId == null) return null;
    for (final candidate in ShanshuiSeason.values) {
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

  /// Ambient room dimming modifier for the Indoor realm under heavy weather.
  double get indoorRoomDimming => switch (this) {
        ShanshuiWeather.sunny => 0.0,
        ShanshuiWeather.cloudy => 0.10,
        ShanshuiWeather.rainy => 0.20,
        ShanshuiWeather.stormy => 0.35,
        ShanshuiWeather.snowy => 0.08,
      };

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

