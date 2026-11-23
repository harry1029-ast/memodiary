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
