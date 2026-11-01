import 'dart:math' as math;
import '../../editor/services/audio_sanctum_service.dart';
import '../models/shanshui_atmosphere.dart';

/// Deterministic pure-Dart resolver mapping local device date/time, user realm
/// preference, and entry situation metadata into a [ShanshuiAtmosphereState] and
/// paired offline soundscape.
class ShanshuiAtmosphereResolver {
  const ShanshuiAtmosphereResolver._();

  static const List<String> _indoorKeywordsZh = [
    '书房', '雅室', '茶室', '茶寮', '室内', '客厅', '卧室', '房间', '桌面', '书桌',
    '案头', '伏案', '读本', '读书', '看书', '翻书', '泡茶', '煮茶', '品茗', '烹茶',
    '煎茶', '焚香', '炉火', '火炉', '暖炉', '窗前', '窗边', '窗台', '坐卧', '倚枕',
    '床榻', '床上', '榻榻米', '宿舍', '写字楼', '屋里', '屋内', '居所', '宅家', '小憩',
    '独处', '躺在床',
  ];

  static const List<String> _indoorKeywordsEn = [
    'desk', 'study', 'bedroom', 'living room', 'tea room', 'indoor', 'indoors',
    'reading', 'read', 'book', 'books', 'bookshelf', 'teapot', 'tea', 'brew',
    'incense', 'fireplace', 'hearth', 'room', 'sofa', 'couch', 'bed', 'pillow',
    'apartment', 'kitchen', 'office', 'home', 'cozy', 'blanket', 'lounge',
    'dormitory', 'dorm',
  ];

  static const List<String> _outdoorKeywordsZh = [
    '市井', '街市', '集市', '街道', '街头', '牌坊', '店铺', '商铺', '摊位', '小摊',
    '面馆', '茶肆', '酒馆', '酒楼', '咖啡馆', '咖啡厅', '菜市场', '超市', '商场', '步行街',
    '巷弄', '巷子', '深巷', '胡同', '马路', '广场', '闹市', '人群', '喧闹', '车水马龙',
    '熙熙攘攘', '逛街', '散步', '遛弯', '漫步', '摆摊', '叫卖', '通勤', '地铁', '公交',
    '车站', '码头', '渡口', '市民', '石板路',
  ];

  static const List<String> _outdoorKeywordsEn = [
    'street', 'market', 'bazaar', 'shop', 'store', 'cafe', 'coffee', 'restaurant',
    'avenue', 'alley', 'downtown', 'city', 'town', 'crowd', 'pedestrian', 'pedestrians',
    'stall', 'stalls', 'noodle', 'bakery', 'walk', 'walking', 'commute', 'subway',
    'bus', 'station', 'sidewalk', 'plaza', 'square', 'shopping', 'errand', 'urban',
  ];

  static const List<String> _natureKeywordsZh = [
    '林泉', '山泉', '山峦', '崇山', '远山', '青山', '孤峰', '山峰', '峰峦', '峡谷',
    '溪流', '溪涧', '溪水', '湖泊', '湖畔', '游湖', '扁舟', '孤舟', '渔舟', '舟楫',
    '泛舟', '垂钓', '钓鱼', '旷野', '荒野', '原野', '森林', '密林', '树林', '苍松',
    '翠竹', '竹林', '飞瀑', '瀑布', '飞鸟', '白鹭', '白鹤', '仙鹤', '徒步', '登山',
    '爬山', '露营', '宿营', '远足', '郊游', '游山', '观湖', '田园', '农田', '山水',
  ];

  static const List<String> _natureKeywordsEn = [
    'nature', 'mountain', 'mountains', 'peak', 'hiking', 'hike', 'trail', 'wilderness',
    'forest', 'woods', 'lake', 'river', 'stream', 'valley', 'canyon', 'camping', 'camp',
    'waterfall', 'wildlife', 'crane', 'bird', 'birds', 'trees', 'meadow', 'countryside',
    'landscape', 'outdoors', 'scenery', 'summit', 'trekked',
  ];

  /// Privacy eligibility filter ensuring soft-deleted entries, PIN-locked entries,
  /// and sealed future Time Capsule entries (`unlockAt > now`) are excluded
  /// before journal text is inspected for situation detection.
  static bool isEntryEligibleForInference({
    required bool isDeleted,
    required bool isLocked,
    DateTime? unlockAt,
    DateTime? now,
  }) {
    if (isDeleted || isLocked) return false;
    if (unlockAt != null && unlockAt.isAfter(now ?? DateTime.now())) {
      return false;
    }
    return true;
  }

  /// Resolves the real-world [ShanshuiAtmosphereState] from [now], optional
  /// [latestEntryWeather], user [realmPreference], and optional accessible journal entry text.
  static ShanshuiAtmosphereState resolve({
    required DateTime now,
    String? latestEntryWeather,
    DateTime? entryTimestamp,
    String? entryTitle,
    String? entryPlainText,
    SceneryRealmPreference realmPreference = SceneryRealmPreference.auto,
  }) {
    final season = resolveSeason(now.month);
    final timeOfDay = resolveTimeOfDay(now.hour);
    final weather = resolveWeather(latestEntryWeather);

    // 1. Explicit user override takes priority
    if (realmPreference != SceneryRealmPreference.auto) {
      final realm = switch (realmPreference) {
        SceneryRealmPreference.nature => ShanshuiRealm.nature,
        SceneryRealmPreference.indoor => ShanshuiRealm.indoor,
        SceneryRealmPreference.outdoor => ShanshuiRealm.outdoor,
        SceneryRealmPreference.auto => ShanshuiRealm.nature,
      };
      return ShanshuiAtmosphereState(
        realm: realm,
        season: season,
        timeOfDay: timeOfDay,
        weather: weather,
        isJournalInferred: false,
        isManualPreview: false,
      );
    }

    // 2. Auto realm inference from latest accessible journal entry within 24h
    final inferred = _inferRealmFromJournal(
      now: now,
      entryTimestamp: entryTimestamp,
      title: entryTitle,
      plainText: entryPlainText,
    );

    return ShanshuiAtmosphereState(
      realm: inferred.realm,
      season: season,
      timeOfDay: timeOfDay,
      weather: weather,
      isJournalInferred: inferred.isInferred,
      isManualPreview: false,
    );
  }

  static ({ShanshuiRealm realm, bool isInferred}) _inferRealmFromJournal({
    required DateTime now,
    required DateTime? entryTimestamp,
    required String? title,
    required String? plainText,
  }) {
    if (entryTimestamp == null) {
      return (realm: ShanshuiRealm.nature, isInferred: false);
    }

    final age = now.difference(entryTimestamp);
    // Recency window: entry must be created within 24 hours (allowing minor clock skew)
    if (age < const Duration(minutes: -5) || age > const Duration(hours: 24)) {
      return (realm: ShanshuiRealm.nature, isInferred: false);
    }

    final scoreIndoor = _scoreRealm(
      title: title,
      body: plainText,
      keywordsZh: _indoorKeywordsZh,
      keywordsEn: _indoorKeywordsEn,
    );
    final scoreOutdoor = _scoreRealm(
      title: title,
      body: plainText,
      keywordsZh: _outdoorKeywordsZh,
      keywordsEn: _outdoorKeywordsEn,
    );
    final scoreNature = _scoreRealm(
      title: title,
      body: plainText,
      keywordsZh: _natureKeywordsZh,
      keywordsEn: _natureKeywordsEn,
    );

    // Zero-score neutral entry
    if (scoreIndoor <= 0 && scoreOutdoor <= 0 && scoreNature <= 0) {
      return (realm: ShanshuiRealm.nature, isInferred: false);
    }

    final maxScore = math.max(scoreIndoor, math.max(scoreOutdoor, scoreNature));

    // Check for ties
    int topCount = 0;
    if (scoreIndoor == maxScore) topCount++;
    if (scoreOutdoor == maxScore) topCount++;
    if (scoreNature == maxScore) topCount++;

    if (topCount > 1) {
      return (realm: ShanshuiRealm.nature, isInferred: false);
    }

    if (scoreIndoor == maxScore) {
      return (realm: ShanshuiRealm.indoor, isInferred: true);
    }
    if (scoreOutdoor == maxScore) {
      return (realm: ShanshuiRealm.outdoor, isInferred: true);
    }
    return (realm: ShanshuiRealm.nature, isInferred: true);
  }

  static int _scoreRealm({
    required String? title,
    required String? body,
    required List<String> keywordsZh,
    required List<String> keywordsEn,
  }) {
    int titleScore = 0;
    int bodyScore = 0;

    if (title != null && title.isNotEmpty) {
      for (final kw in keywordsZh) {
        titleScore += _countOccurrences(title, kw);
      }
      for (final kw in keywordsEn) {
        titleScore += _countWordMatches(title, kw);
      }
    }

    if (body != null && body.isNotEmpty) {
      for (final kw in keywordsZh) {
        bodyScore += _countOccurrences(body, kw);
      }
      for (final kw in keywordsEn) {
        bodyScore += _countWordMatches(body, kw);
      }
    }

    // Title matches are weighted 2x body matches
    return (titleScore * 2) + bodyScore;
  }

  static int _countOccurrences(String text, String keyword) {
    int count = 0;
    int index = 0;
    while ((index = text.indexOf(keyword, index)) != -1) {
      count++;
      index += keyword.length;
    }
    return count;
  }

  static int _countWordMatches(String text, String keyword) {
    final regex = RegExp(
      r'\b' + RegExp.escape(keyword) + r'\b',
      caseSensitive: false,
    );
    return regex.allMatches(text).length;
  }

  /// Maps calendar month (1..12) into the four classical seasons.
  static ShanshuiSeason resolveSeason(int month) {
    if (month >= 3 && month <= 5) return ShanshuiSeason.spring;
    if (month >= 6 && month <= 8) return ShanshuiSeason.summer;
    if (month >= 9 && month <= 11) return ShanshuiSeason.fall;
    return ShanshuiSeason.winter;
  }

  /// Maps 24-hour local clock hour (0..23) into Dawn, Day, Dusk, or Night.
  static ShanshuiTimeOfDay resolveTimeOfDay(int hour) {
    if (hour >= 5 && hour < 7) return ShanshuiTimeOfDay.dawn;
    if (hour >= 7 && hour < 17) return ShanshuiTimeOfDay.day;
    if (hour >= 17 && hour < 19) return ShanshuiTimeOfDay.dusk;
    return ShanshuiTimeOfDay.night;
  }

  /// Maps a diary entry weather tag into [ShanshuiWeather], defaulting to [ShanshuiWeather.sunny].
  static ShanshuiWeather resolveWeather(String? rawWeatherTag) {
    if (rawWeatherTag == null || rawWeatherTag.isEmpty) {
      return ShanshuiWeather.sunny;
    }

    switch (rawWeatherTag.trim().toLowerCase()) {
      case 'sunny':
      case 'clear':
        return ShanshuiWeather.sunny;
      case 'cloudy':
      case 'windy':
      case 'overcast':
      case 'foggy':
        return ShanshuiWeather.cloudy;
      case 'rainy':
      case 'rain':
      case 'drizzle':
        return ShanshuiWeather.rainy;
      case 'stormy':
      case 'thunder':
      case 'thunderstorm':
        return ShanshuiWeather.stormy;
      case 'snowy':
      case 'snow':
        return ShanshuiWeather.snowy;
      default:
        return ShanshuiWeather.sunny;
    }
  }

  /// Contextually pairs an active [ShanshuiAtmosphereState] with an offline [SoundscapePreset].
  ///
  /// - Rainy or Stormy weather across any realm -> [SoundscapePreset.gentleRain].
  /// - Non-rainy [ShanshuiRealm.indoor] atmospheres -> [SoundscapePreset.vintageLibrary].
  /// - Non-rainy [ShanshuiRealm.nature] or [ShanshuiRealm.outdoor] atmospheres in winter or night -> [SoundscapePreset.vintageLibrary]; otherwise [SoundscapePreset.bambooBreeze].
  static SoundscapePreset resolveSoundscape(ShanshuiAtmosphereState atmosphere) {
    if (atmosphere.weather == ShanshuiWeather.rainy ||
        atmosphere.weather == ShanshuiWeather.stormy) {
      return SoundscapePreset.gentleRain;
    }
    if (atmosphere.realm == ShanshuiRealm.indoor) {
      return SoundscapePreset.vintageLibrary;
    }
    if (atmosphere.season == ShanshuiSeason.winter ||
        atmosphere.timeOfDay == ShanshuiTimeOfDay.night) {
      return SoundscapePreset.vintageLibrary;
    }
    return SoundscapePreset.bambooBreeze;
  }
}
