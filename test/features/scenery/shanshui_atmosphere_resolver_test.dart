import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/services/audio_sanctum_service.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/scenery/services/scenery_settings_service.dart';
import 'package:memodiary/features/scenery/services/shanshui_atmosphere_resolver.dart';

import '../../helpers/mock_secure_storage.dart';

void main() {
  group('ShanshuiAtmosphereResolver', () {
    test('maps calendar months into the four classical seasons', () {
      expect(
        ShanshuiAtmosphereResolver.resolve(now: DateTime(2026, 3, 15, 10)).season,
        equals(ShanshuiSeason.spring),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(now: DateTime(2026, 5, 31, 10)).season,
        equals(ShanshuiSeason.spring),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(now: DateTime(2026, 6, 1, 10)).season,
        equals(ShanshuiSeason.summer),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(now: DateTime(2026, 8, 20, 10)).season,
        equals(ShanshuiSeason.summer),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(now: DateTime(2026, 9, 10, 10)).season,
        equals(ShanshuiSeason.fall),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(now: DateTime(2026, 11, 25, 10)).season,
        equals(ShanshuiSeason.fall),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(now: DateTime(2026, 12, 5, 10)).season,
        equals(ShanshuiSeason.winter),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(now: DateTime(2026, 1, 18, 10)).season,
        equals(ShanshuiSeason.winter),
      );
    });

    test('maps 24-hour local clock into Dawn, Day, Dusk, and Night brackets', () {
      // Dawn: 05:00 - 06:59
      expect(
        ShanshuiAtmosphereResolver.resolve(now: DateTime(2026, 4, 10, 5, 0)).timeOfDay,
        equals(ShanshuiTimeOfDay.dawn),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(now: DateTime(2026, 4, 10, 6, 59)).timeOfDay,
        equals(ShanshuiTimeOfDay.dawn),
      );

      // Day: 07:00 - 16:59
      expect(
        ShanshuiAtmosphereResolver.resolve(now: DateTime(2026, 4, 10, 7, 0)).timeOfDay,
        equals(ShanshuiTimeOfDay.day),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(now: DateTime(2026, 4, 10, 16, 59)).timeOfDay,
        equals(ShanshuiTimeOfDay.day),
      );

      // Dusk: 17:00 - 18:59
      expect(
        ShanshuiAtmosphereResolver.resolve(now: DateTime(2026, 4, 10, 17, 0)).timeOfDay,
        equals(ShanshuiTimeOfDay.dusk),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(now: DateTime(2026, 4, 10, 18, 59)).timeOfDay,
        equals(ShanshuiTimeOfDay.dusk),
      );

      // Night: 19:00 - 04:59
      expect(
        ShanshuiAtmosphereResolver.resolve(now: DateTime(2026, 4, 10, 19, 0)).timeOfDay,
        equals(ShanshuiTimeOfDay.night),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(now: DateTime(2026, 4, 10, 2, 30)).timeOfDay,
        equals(ShanshuiTimeOfDay.night),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(now: DateTime(2026, 4, 10, 4, 59)).timeOfDay,
        equals(ShanshuiTimeOfDay.night),
      );
    });

    test('resolves entry weather tags and falls back to sunny on null or unknown tags', () {
      final sampleTime = DateTime(2026, 5, 12, 12, 0);

      expect(
        ShanshuiAtmosphereResolver.resolve(
          now: sampleTime,
          latestEntryWeather: 'rainy',
        ).weather,
        equals(ShanshuiWeather.rainy),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(
          now: sampleTime,
          latestEntryWeather: 'cloudy',
        ).weather,
        equals(ShanshuiWeather.cloudy),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(
          now: sampleTime,
          latestEntryWeather: 'windy',
        ).weather,
        equals(ShanshuiWeather.cloudy),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(
          now: sampleTime,
          latestEntryWeather: 'stormy',
        ).weather,
        equals(ShanshuiWeather.stormy),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(
          now: sampleTime,
          latestEntryWeather: 'snowy',
        ).weather,
        equals(ShanshuiWeather.snowy),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(
          now: sampleTime,
          latestEntryWeather: null,
        ).weather,
        equals(ShanshuiWeather.sunny),
      );
      expect(
        ShanshuiAtmosphereResolver.resolve(
          now: sampleTime,
          latestEntryWeather: 'unrecognized_tag',
        ).weather,
        equals(ShanshuiWeather.sunny),
      );
    });

    test('pairs active atmosphere with contextual offline SoundscapePreset', () {
      expect(
        ShanshuiAtmosphereResolver.resolveSoundscape(
          const ShanshuiAtmosphereState(
            season: ShanshuiSeason.spring,
            timeOfDay: ShanshuiTimeOfDay.day,
            weather: ShanshuiWeather.rainy,
          ),
        ),
        equals(SoundscapePreset.gentleRain),
      );

      expect(
        ShanshuiAtmosphereResolver.resolveSoundscape(
          const ShanshuiAtmosphereState(
            season: ShanshuiSeason.summer,
            timeOfDay: ShanshuiTimeOfDay.dusk,
            weather: ShanshuiWeather.stormy,
          ),
        ),
        equals(SoundscapePreset.gentleRain),
      );

      expect(
        ShanshuiAtmosphereResolver.resolveSoundscape(
          const ShanshuiAtmosphereState(
            season: ShanshuiSeason.winter,
            timeOfDay: ShanshuiTimeOfDay.day,
            weather: ShanshuiWeather.sunny,
          ),
        ),
        equals(SoundscapePreset.vintageLibrary),
      );

      expect(
        ShanshuiAtmosphereResolver.resolveSoundscape(
          const ShanshuiAtmosphereState(
            season: ShanshuiSeason.spring,
            timeOfDay: ShanshuiTimeOfDay.day,
            weather: ShanshuiWeather.sunny,
          ),
        ),
        equals(SoundscapePreset.bambooBreeze),
      );

      // Realm-specific soundscape pairing:
      // Rainy/stormy across any realm -> gentleRain
      expect(
        ShanshuiAtmosphereResolver.resolveSoundscape(
          const ShanshuiAtmosphereState(
            realm: ShanshuiRealm.indoor,
            season: ShanshuiSeason.spring,
            timeOfDay: ShanshuiTimeOfDay.day,
            weather: ShanshuiWeather.rainy,
          ),
        ),
        equals(SoundscapePreset.gentleRain),
      );

      expect(
        ShanshuiAtmosphereResolver.resolveSoundscape(
          const ShanshuiAtmosphereState(
            realm: ShanshuiRealm.outdoor,
            season: ShanshuiSeason.summer,
            timeOfDay: ShanshuiTimeOfDay.dusk,
            weather: ShanshuiWeather.stormy,
          ),
        ),
        equals(SoundscapePreset.gentleRain),
      );

      // Non-rainy indoor -> vintageLibrary (warm hearth & quiet study tone)
      expect(
        ShanshuiAtmosphereResolver.resolveSoundscape(
          const ShanshuiAtmosphereState(
            realm: ShanshuiRealm.indoor,
            season: ShanshuiSeason.spring,
            timeOfDay: ShanshuiTimeOfDay.day,
            weather: ShanshuiWeather.sunny,
          ),
        ),
        equals(SoundscapePreset.vintageLibrary),
      );

      // Non-rainy outdoor -> bambooBreeze in spring/summer daytime
      expect(
        ShanshuiAtmosphereResolver.resolveSoundscape(
          const ShanshuiAtmosphereState(
            realm: ShanshuiRealm.outdoor,
            season: ShanshuiSeason.spring,
            timeOfDay: ShanshuiTimeOfDay.day,
            weather: ShanshuiWeather.sunny,
          ),
        ),
        equals(SoundscapePreset.bambooBreeze),
      );

      // Non-rainy outdoor in winter -> vintageLibrary
      expect(
        ShanshuiAtmosphereResolver.resolveSoundscape(
          const ShanshuiAtmosphereState(
            realm: ShanshuiRealm.outdoor,
            season: ShanshuiSeason.winter,
            timeOfDay: ShanshuiTimeOfDay.day,
            weather: ShanshuiWeather.sunny,
          ),
        ),
        equals(SoundscapePreset.vintageLibrary),
      );

      // Non-rainy outdoor at night -> vintageLibrary
      expect(
        ShanshuiAtmosphereResolver.resolveSoundscape(
          const ShanshuiAtmosphereState(
            realm: ShanshuiRealm.outdoor,
            season: ShanshuiSeason.summer,
            timeOfDay: ShanshuiTimeOfDay.night,
            weather: ShanshuiWeather.sunny,
          ),
        ),
        equals(SoundscapePreset.vintageLibrary),
      );

      // West Lake & Fenghuang soundscape pairing:
      expect(
        ShanshuiAtmosphereResolver.resolveSoundscape(
          const ShanshuiAtmosphereState(
            realm: ShanshuiRealm.westLake,
            season: ShanshuiSeason.spring,
            timeOfDay: ShanshuiTimeOfDay.day,
            weather: ShanshuiWeather.sunny,
          ),
        ),
        equals(SoundscapePreset.bambooBreeze),
      );
      expect(
        ShanshuiAtmosphereResolver.resolveSoundscape(
          const ShanshuiAtmosphereState(
            realm: ShanshuiRealm.westLake,
            season: ShanshuiSeason.fall,
            timeOfDay: ShanshuiTimeOfDay.dusk,
            weather: ShanshuiWeather.rainy,
          ),
        ),
        equals(SoundscapePreset.gentleRain),
      );
      expect(
        ShanshuiAtmosphereResolver.resolveSoundscape(
          const ShanshuiAtmosphereState(
            realm: ShanshuiRealm.westLake,
            season: ShanshuiSeason.winter,
            timeOfDay: ShanshuiTimeOfDay.day,
            weather: ShanshuiWeather.sunny,
          ),
        ),
        equals(SoundscapePreset.vintageLibrary),
      );
      expect(
        ShanshuiAtmosphereResolver.resolveSoundscape(
          const ShanshuiAtmosphereState(
            realm: ShanshuiRealm.fenghuang,
            season: ShanshuiSeason.summer,
            timeOfDay: ShanshuiTimeOfDay.dawn,
            weather: ShanshuiWeather.cloudy,
          ),
        ),
        equals(SoundscapePreset.bambooBreeze),
      );
      expect(
        ShanshuiAtmosphereResolver.resolveSoundscape(
          const ShanshuiAtmosphereState(
            realm: ShanshuiRealm.fenghuang,
            season: ShanshuiSeason.summer,
            timeOfDay: ShanshuiTimeOfDay.night,
            weather: ShanshuiWeather.sunny,
          ),
        ),
        equals(SoundscapePreset.vintageLibrary),
      );
      expect(
        ShanshuiAtmosphereResolver.resolveSoundscape(
          const ShanshuiAtmosphereState(
            realm: ShanshuiRealm.fenghuang,
            season: ShanshuiSeason.fall,
            timeOfDay: ShanshuiTimeOfDay.day,
            weather: ShanshuiWeather.stormy,
          ),
        ),
        equals(SoundscapePreset.gentleRain),
      );
    });

    test('validates privacy eligibility for journal situation detection', () {
      final now = DateTime(2026, 4, 15, 14, 0);

      // Eligible: not deleted, not locked, no unlockAt
      expect(
        ShanshuiAtmosphereResolver.isEntryEligibleForInference(
          isDeleted: false,
          isLocked: false,
          unlockAt: null,
          now: now,
        ),
        isTrue,
      );

      // Eligible: unlockAt is already past
      expect(
        ShanshuiAtmosphereResolver.isEntryEligibleForInference(
          isDeleted: false,
          isLocked: false,
          unlockAt: now.subtract(const Duration(days: 1)),
          now: now,
        ),
        isTrue,
      );

      // Ineligible: soft-deleted
      expect(
        ShanshuiAtmosphereResolver.isEntryEligibleForInference(
          isDeleted: true,
          isLocked: false,
          unlockAt: null,
          now: now,
        ),
        isFalse,
      );

      // Ineligible: PIN-locked
      expect(
        ShanshuiAtmosphereResolver.isEntryEligibleForInference(
          isDeleted: false,
          isLocked: true,
          unlockAt: null,
          now: now,
        ),
        isFalse,
      );

      // Ineligible: sealed Time Capsule in the future
      expect(
        ShanshuiAtmosphereResolver.isEntryEligibleForInference(
          isDeleted: false,
          isLocked: false,
          unlockAt: now.add(const Duration(days: 30)),
          now: now,
        ),
        isFalse,
      );
    });

    test('resolves explicit SceneryRealmPreference overrides directly', () {
      final now = DateTime(2026, 4, 15, 14, 0);

      final indoorState = ShanshuiAtmosphereResolver.resolve(
        now: now,
        realmPreference: SceneryRealmPreference.indoor,
        entryTimestamp: now.subtract(const Duration(hours: 1)),
        entryTitle: '山水漫步', // nature keywords in text should be ignored due to explicit override
        entryPlainText: '湖泊荒野露营',
      );
      expect(indoorState.realm, equals(ShanshuiRealm.indoor));
      expect(indoorState.isJournalInferred, isFalse);

      final outdoorState = ShanshuiAtmosphereResolver.resolve(
        now: now,
        realmPreference: SceneryRealmPreference.outdoor,
      );
      expect(outdoorState.realm, equals(ShanshuiRealm.outdoor));
      expect(outdoorState.isJournalInferred, isFalse);

      final natureState = ShanshuiAtmosphereResolver.resolve(
        now: now,
        realmPreference: SceneryRealmPreference.nature,
      );
      expect(natureState.realm, equals(ShanshuiRealm.nature));
      expect(natureState.isJournalInferred, isFalse);

      final westLakeState = ShanshuiAtmosphereResolver.resolve(
        now: now,
        realmPreference: SceneryRealmPreference.westLake,
      );
      expect(westLakeState.realm, equals(ShanshuiRealm.westLake));
      expect(westLakeState.isJournalInferred, isFalse);

      final fenghuangState = ShanshuiAtmosphereResolver.resolve(
        now: now,
        realmPreference: SceneryRealmPreference.fenghuang,
      );
      expect(fenghuangState.realm, equals(ShanshuiRealm.fenghuang));
      expect(fenghuangState.isJournalInferred, isFalse);

      expect(SceneryRealmPreference.auto.defaultRealm, equals(ShanshuiRealm.nature));
      expect(SceneryRealmPreference.nature.defaultRealm, equals(ShanshuiRealm.nature));
      expect(SceneryRealmPreference.westLake.defaultRealm, equals(ShanshuiRealm.westLake));
      expect(SceneryRealmPreference.fenghuang.defaultRealm, equals(ShanshuiRealm.fenghuang));
      expect(SceneryRealmPreference.indoor.defaultRealm, equals(ShanshuiRealm.indoor));
      expect(SceneryRealmPreference.outdoor.defaultRealm, equals(ShanshuiRealm.outdoor));
    });

    test('infers indoor, outdoor, westLake, fenghuang, and nature realms from Chinese and English keywords', () {
      final now = DateTime(2026, 4, 15, 14, 0);
      final recent = now.subtract(const Duration(hours: 2));

      // Chinese Indoor
      final indoorZh = ShanshuiAtmosphereResolver.resolve(
        now: now,
        entryTimestamp: recent,
        entryTitle: '书房读书记',
        entryPlainText: '窗前烹茶，静坐案头翻阅旧书，炉火微温。',
      );
      expect(indoorZh.realm, equals(ShanshuiRealm.indoor));
      expect(indoorZh.isJournalInferred, isTrue);

      // English Indoor
      final indoorEn = ShanshuiAtmosphereResolver.resolve(
        now: now,
        entryTimestamp: recent,
        entryTitle: 'Quiet afternoon in my study',
        entryPlainText: 'Brewing a pot of tea at my desk with cozy blankets.',
      );
      expect(indoorEn.realm, equals(ShanshuiRealm.indoor));
      expect(indoorEn.isJournalInferred, isTrue);

      // Chinese Outdoor
      final outdoorZh = ShanshuiAtmosphereResolver.resolve(
        now: now,
        entryTimestamp: recent,
        entryTitle: '古镇街市闲步',
        entryPlainText: '穿过石板路牌坊，街头熙熙攘攘，在面馆点了一碗热面。',
      );
      expect(outdoorZh.realm, equals(ShanshuiRealm.outdoor));
      expect(outdoorZh.isJournalInferred, isTrue);

      // English Outdoor
      final outdoorEn = ShanshuiAtmosphereResolver.resolve(
        now: now,
        entryTimestamp: recent,
        entryTitle: 'Downtown street market walk',
        entryPlainText: 'Crowded avenue with food stalls and busy pedestrians.',
      );
      expect(outdoorEn.realm, equals(ShanshuiRealm.outdoor));
      expect(outdoorEn.isJournalInferred, isTrue);

      // Chinese Nature
      final natureZh = ShanshuiAtmosphereResolver.resolve(
        now: now,
        entryTimestamp: recent,
        entryTitle: '周末山林远足',
        entryPlainText: '登临孤峰远眺，峡谷飞瀑奔流，在湖畔溪水边宿营。',
      );
      expect(natureZh.realm, equals(ShanshuiRealm.nature));
      expect(natureZh.isJournalInferred, isTrue);

      // English Nature
      final natureEn = ShanshuiAtmosphereResolver.resolve(
        now: now,
        entryTimestamp: recent,
        entryTitle: 'Mountain hiking trail',
        entryPlainText: 'Trekked through deep forest to reach the canyon lake and peak.',
      );
      expect(natureEn.realm, equals(ShanshuiRealm.nature));
      expect(natureEn.isJournalInferred, isTrue);

      // Chinese West Lake
      final westLakeZh = ShanshuiAtmosphereResolver.resolve(
        now: now,
        entryTimestamp: recent,
        entryTitle: '西湖断桥漫记',
        entryPlainText: '清晨走过苏堤，远眺雷峰塔与保俶塔，曲院风荷香气袭人。',
      );
      expect(westLakeZh.realm, equals(ShanshuiRealm.westLake));
      expect(westLakeZh.isJournalInferred, isTrue);

      // English West Lake (even when 'West Lake' is the only location keyword)
      final westLakeEn = ShanshuiAtmosphereResolver.resolve(
        now: now,
        entryTimestamp: recent,
        entryTitle: 'Morning by West Lake',
        entryPlainText: 'Enjoyed the gentle breeze near the willow causeway.',
      );
      expect(westLakeEn.realm, equals(ShanshuiRealm.westLake));
      expect(westLakeEn.isJournalInferred, isTrue);

      // Chinese Fenghuang
      final fenghuangZh = ShanshuiAtmosphereResolver.resolve(
        now: now,
        entryTimestamp: recent,
        entryTitle: '凤凰古城夜泊',
        entryPlainText: '沱江吊脚楼亮起灯火，走过跳岩看万名塔下河灯漂流。',
      );
      expect(fenghuangZh.realm, equals(ShanshuiRealm.fenghuang));
      expect(fenghuangZh.isJournalInferred, isTrue);

      // English Fenghuang (even when compound phrase like 'ancient town' or 'river lantern' is used)
      final fenghuangEn = ShanshuiAtmosphereResolver.resolve(
        now: now,
        entryTimestamp: recent,
        entryTitle: 'Ancient town evening',
        entryPlainText: 'Watched a river lantern drift past the stilt house and stepping stones.',
      );
      expect(fenghuangEn.realm, equals(ShanshuiRealm.fenghuang));
      expect(fenghuangEn.isJournalInferred, isTrue);
    });

    test('weights title matches 2x body matches', () {
      final now = DateTime(2026, 4, 15, 14, 0);
      final recent = now.subtract(const Duration(hours: 1));

      // Title has 1 outdoor keyword ('市井' -> weight 2)
      // Body has 1 indoor keyword ('泡茶' -> weight 1)
      // Result should be outdoor (score 2 > 1)
      final state = ShanshuiAtmosphereResolver.resolve(
        now: now,
        entryTimestamp: recent,
        entryTitle: '市井掠影',
        entryPlainText: '回家后泡茶。',
      );
      expect(state.realm, equals(ShanshuiRealm.outdoor));
      expect(state.isJournalInferred, isTrue);
    });

    test('falls back to nature when entries are older than 24 hours', () {
      final now = DateTime(2026, 4, 15, 14, 0);
      final expired = now.subtract(const Duration(hours: 24, minutes: 1));

      final state = ShanshuiAtmosphereResolver.resolve(
        now: now,
        entryTimestamp: expired,
        entryTitle: '书房静夜',
        entryPlainText: '独坐案头煮茶读书。',
      );
      expect(state.realm, equals(ShanshuiRealm.nature));
      expect(state.isJournalInferred, isFalse);
    });

    test('falls back to nature for neutral, empty, missing, or tied entries', () {
      final now = DateTime(2026, 4, 15, 14, 0);
      final recent = now.subtract(const Duration(hours: 2));

      // Missing entry
      final missingState = ShanshuiAtmosphereResolver.resolve(
        now: now,
        entryTimestamp: null,
      );
      expect(missingState.realm, equals(ShanshuiRealm.nature));
      expect(missingState.isJournalInferred, isFalse);

      // Neutral entry without spatial keywords
      final neutralState = ShanshuiAtmosphereResolver.resolve(
        now: now,
        entryTimestamp: recent,
        entryTitle: '日常琐思',
        entryPlainText: '今天思考了一些工作项目和未来的计划，心情平静。',
      );
      expect(neutralState.realm, equals(ShanshuiRealm.nature));
      expect(neutralState.isJournalInferred, isFalse);

      // Tied entry: equal score between indoor and outdoor
      final tiedState = ShanshuiAtmosphereResolver.resolve(
        now: now,
        entryTimestamp: recent,
        entryTitle: '书房与市井',
        entryPlainText: '上午在书房，下午逛市井。',
      );
      expect(tiedState.realm, equals(ShanshuiRealm.nature));
      expect(tiedState.isJournalInferred, isFalse);

      // Tied entry between westLake and fenghuang falls back to nature
      final tiedLandmarkState = ShanshuiAtmosphereResolver.resolve(
        now: now,
        entryTimestamp: recent,
        entryTitle: '杭州与湘西',
        entryPlainText: '先去了西湖，又去了凤凰。',
      );
      expect(tiedLandmarkState.realm, equals(ShanshuiRealm.nature));
      expect(tiedLandmarkState.isJournalInferred, isFalse);
    });
  });

  group('ShanshuiAtmosphereState realm and seasonal metadata', () {
    test('defaults realm to nature and isJournalInferred to false', () {
      const state = ShanshuiAtmosphereState(
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.sunny,
      );

      expect(state.realm, equals(ShanshuiRealm.nature));
      expect(state.isJournalInferred, isFalse);
      expect(state.realmBadgeZh, equals('山水'));
    });

    test('displays 自动 badge when isJournalInferred is true', () {
      const state = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.indoor,
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.sunny,
        isJournalInferred: true,
      );

      expect(state.realmBadgeZh, equals('自动 · 室内'));
    });

    test('exposes plain Chinese labels and distinct icons for 5 realms, 6 preferences, times of day, and weather chips', () {
      expect(
        ShanshuiRealm.values.map((realm) => realm.shortNameZh).toList(),
        equals(['山水', '西湖', '凤凰', '室内', '街市']),
      );
      expect(
        SceneryRealmPreference.values.map((pref) => pref.nameZh).toList(),
        equals(['自动', '山水', '西湖', '凤凰', '室内', '街市']),
      );
      expect(
        SceneryRealmPreference.values.map((pref) => pref.icon).toSet().length,
        equals(SceneryRealmPreference.values.length),
      );
      expect(
        ShanshuiTimeOfDay.values.map((time) => time.nameZh).toList(),
        equals(['清晨', '白天', '傍晚', '夜晚']),
      );
      expect(
        ShanshuiWeather.values.map((weather) => weather.nameZh).toList(),
        equals(['晴天', '多云', '小雨', '雷雨', '下雪']),
      );
      expect(
        ShanshuiWeather.rainy.badgeZhFor(ShanshuiRealm.westLake),
        equals('烟雨朦胧'),
      );
      expect(
        ShanshuiWeather.snowy.badgeZhFor(ShanshuiRealm.fenghuang),
        equals('漫天飞雪'),
      );
      const state = ShanshuiAtmosphereState(
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.dawn,
        weather: ShanshuiWeather.rainy,
      );
      expect(state.timeWeatherBadgeZh, equals('清晨 · 小雨'));
    });

    test('resolves realm-specific titles, couplets, seals, and compact badges across all 20 combinations', () {
      // Spring
      expect(ShanshuiSeason.spring.nameZhFor(ShanshuiRealm.nature), equals('春 · 桃夭青绿'));
      expect(ShanshuiSeason.spring.nameZhFor(ShanshuiRealm.westLake), equals('春 · 苏堤春晓柳如烟'));
      expect(ShanshuiSeason.spring.nameZhFor(ShanshuiRealm.fenghuang), equals('春 · 烟雨桃花映沱江'));
      expect(ShanshuiSeason.spring.nameZhFor(ShanshuiRealm.indoor), equals('春 · 桃夭茶寮'));
      expect(ShanshuiSeason.spring.nameZhFor(ShanshuiRealm.outdoor), equals('春 · 桃李春风集'));

      expect(ShanshuiSeason.spring.nameEnFor(ShanshuiRealm.westLake), equals('Spring · Su Causeway Dawn & Peach Blossoms'));
      expect(ShanshuiSeason.spring.nameEnFor(ShanshuiRealm.fenghuang), equals('Spring · Misty Peach Blossoms on Tuojiang'));

      expect(ShanshuiSeason.spring.poemFor(ShanshuiRealm.nature), equals('水面初平云脚低，几处早莺争暖树'));
      expect(ShanshuiSeason.spring.poemFor(ShanshuiRealm.westLake), equals('间株杨柳间株桃，水光潋滟晴方好'));
      expect(ShanshuiSeason.spring.poemFor(ShanshuiRealm.fenghuang), equals('江水初平翠黛低，吊脚楼前桃花溪'));
      expect(ShanshuiSeason.spring.poemFor(ShanshuiRealm.indoor), equals('小楼一夜听春雨，深巷明朝卖杏花'));
      expect(ShanshuiSeason.spring.poemFor(ShanshuiRealm.outdoor), equals('千门万户曈曈日，总把新桃换旧符'));

      expect(ShanshuiSeason.spring.sealTextFor(ShanshuiRealm.nature), equals('春和景明'));
      expect(ShanshuiSeason.spring.sealTextFor(ShanshuiRealm.westLake), equals('苏堤春晓'));
      expect(ShanshuiSeason.spring.sealTextFor(ShanshuiRealm.fenghuang), equals('湘西春晓'));
      expect(ShanshuiSeason.spring.sealTextFor(ShanshuiRealm.indoor), equals('春风入室'));
      expect(ShanshuiSeason.spring.sealTextFor(ShanshuiRealm.outdoor), equals('春和景明'));

      expect(ShanshuiSeason.spring.sealBadgeZhFor(ShanshuiRealm.westLake), equals('春 · 苏堤'));
      expect(ShanshuiSeason.spring.sealBadgeZhFor(ShanshuiRealm.fenghuang), equals('春 · 沱江'));

      // Summer
      expect(ShanshuiSeason.summer.nameZhFor(ShanshuiRealm.nature), equals('夏 · 苍山碧水'));
      expect(ShanshuiSeason.summer.nameZhFor(ShanshuiRealm.westLake), equals('夏 · 曲院风荷碧连天'));
      expect(ShanshuiSeason.summer.nameZhFor(ShanshuiRealm.fenghuang), equals('夏 · 沱江碧水听摇橹'));
      expect(ShanshuiSeason.summer.nameZhFor(ShanshuiRealm.indoor), equals('夏 · 翠竹听荷'));
      expect(ShanshuiSeason.summer.nameZhFor(ShanshuiRealm.outdoor), equals('夏 · 翠峰槐夏市'));

      expect(ShanshuiSeason.summer.nameEnFor(ShanshuiRealm.westLake), equals('Summer · Breeze-Ruffled Lotus at Quyuan'));
      expect(ShanshuiSeason.summer.nameEnFor(ShanshuiRealm.fenghuang), equals('Summer · Emerald Tuojiang & Rowing Skiffs'));

      expect(ShanshuiSeason.summer.poemFor(ShanshuiRealm.nature), equals('接天莲叶无穷碧，山色空蒙雨亦奇'));
      expect(ShanshuiSeason.summer.poemFor(ShanshuiRealm.westLake), equals('接天莲叶无穷碧，映日荷花别样红'));
      expect(ShanshuiSeason.summer.poemFor(ShanshuiRealm.fenghuang), equals('两岸吊脚悬碧水，一舟摇碎满江星'));
      expect(ShanshuiSeason.summer.poemFor(ShanshuiRealm.indoor), equals('水晶帘动微风起，满架蔷薇一院香'));
      expect(ShanshuiSeason.summer.poemFor(ShanshuiRealm.outdoor), equals('绿树阴浓夏日长，楼台倒影入池塘'));

      expect(ShanshuiSeason.summer.sealTextFor(ShanshuiRealm.nature), equals('夏木阴阴'));
      expect(ShanshuiSeason.summer.sealTextFor(ShanshuiRealm.westLake), equals('曲院风荷'));
      expect(ShanshuiSeason.summer.sealTextFor(ShanshuiRealm.fenghuang), equals('沱江清夏'));
      expect(ShanshuiSeason.summer.sealTextFor(ShanshuiRealm.indoor), equals('夏木阴阴'));
      expect(ShanshuiSeason.summer.sealTextFor(ShanshuiRealm.outdoor), equals('碧山晴夏'));

      expect(ShanshuiSeason.summer.sealBadgeZhFor(ShanshuiRealm.westLake), equals('夏 · 风荷'));
      expect(ShanshuiSeason.summer.sealBadgeZhFor(ShanshuiRealm.fenghuang), equals('夏 · 摇橹'));

      // Fall
      expect(ShanshuiSeason.fall.nameZhFor(ShanshuiRealm.nature), equals('秋 · 霜林丹枫'));
      expect(ShanshuiSeason.fall.nameZhFor(ShanshuiRealm.westLake), equals('秋 · 平湖秋月雷峰晚'));
      expect(ShanshuiSeason.fall.nameZhFor(ShanshuiRealm.fenghuang), equals('秋 · 丹枫尽染虹桥晚'));
      expect(ShanshuiSeason.fall.nameZhFor(ShanshuiRealm.indoor), equals('秋 · 霜枫品茗'));
      expect(ShanshuiSeason.fall.nameZhFor(ShanshuiRealm.outdoor), equals('秋 · 霜峰丹枫街'));

      expect(ShanshuiSeason.fall.nameEnFor(ShanshuiRealm.westLake), equals('Fall · Autumn Moon & Leifeng Pagoda Sunset'));
      expect(ShanshuiSeason.fall.nameEnFor(ShanshuiRealm.fenghuang), equals('Fall · Crimson Maples at Hongqiao Evening'));

      expect(ShanshuiSeason.fall.poemFor(ShanshuiRealm.nature), equals('停车坐爱枫林晚，霜叶红于二月花'));
      expect(ShanshuiSeason.fall.poemFor(ShanshuiRealm.westLake), equals('雷峰夕照金波涌，三潭印月桂子香'));
      expect(ShanshuiSeason.fall.poemFor(ShanshuiRealm.fenghuang), equals('万名塔下秋波静，虹桥风起落丹枫'));
      expect(ShanshuiSeason.fall.poemFor(ShanshuiRealm.indoor), equals('寒夜客来茶当酒，竹炉汤沸火初红'));
      expect(ShanshuiSeason.fall.poemFor(ShanshuiRealm.outdoor), equals('停车坐爱枫林晚，霜叶红于二月花'));

      expect(ShanshuiSeason.fall.sealTextFor(ShanshuiRealm.nature), equals('秋水长天'));
      expect(ShanshuiSeason.fall.sealTextFor(ShanshuiRealm.westLake), equals('平湖秋月'));
      expect(ShanshuiSeason.fall.sealTextFor(ShanshuiRealm.fenghuang), equals('边城秋色'));
      expect(ShanshuiSeason.fall.sealTextFor(ShanshuiRealm.indoor), equals('秋水长天'));
      expect(ShanshuiSeason.fall.sealTextFor(ShanshuiRealm.outdoor), equals('金秋盛景'));

      expect(ShanshuiSeason.fall.sealBadgeZhFor(ShanshuiRealm.westLake), equals('秋 · 秋月'));
      expect(ShanshuiSeason.fall.sealBadgeZhFor(ShanshuiRealm.fenghuang), equals('秋 · 虹桥'));

      // Winter
      expect(ShanshuiSeason.winter.nameZhFor(ShanshuiRealm.nature), equals('冬 · 寒江瑞雪'));
      expect(ShanshuiSeason.winter.nameZhFor(ShanshuiRealm.westLake), equals('冬 · 断桥残雪留荷影'));
      expect(ShanshuiSeason.winter.nameZhFor(ShanshuiRealm.fenghuang), equals('冬 · 雪落凤凰万家灯'));
      expect(ShanshuiSeason.winter.nameZhFor(ShanshuiRealm.indoor), equals('冬 · 瑞雪温炉'));
      expect(ShanshuiSeason.winter.nameZhFor(ShanshuiRealm.outdoor), equals('冬 · 瑞雪岁朝集'));

      expect(ShanshuiSeason.winter.nameEnFor(ShanshuiRealm.westLake), equals('Winter · Melting Snow on Broken Bridge'));
      expect(ShanshuiSeason.winter.nameEnFor(ShanshuiRealm.fenghuang), equals('Winter · Snowfall & Stilt-House Lanterns'));

      expect(ShanshuiSeason.winter.poemFor(ShanshuiRealm.nature), equals('孤舟蓑笠翁，独钓寒江雪'));
      expect(ShanshuiSeason.winter.poemFor(ShanshuiRealm.westLake), equals('晴雪初消断桥石，留得枯荷听雨声'));
      expect(ShanshuiSeason.winter.poemFor(ShanshuiRealm.fenghuang), equals('跳岩雪映红灯影，吊脚楼头暖火明'));
      expect(ShanshuiSeason.winter.poemFor(ShanshuiRealm.indoor), equals('绿蚁新醅酒，红泥小火炉。晚来天欲雪，能饮一杯无'));
      expect(ShanshuiSeason.winter.poemFor(ShanshuiRealm.outdoor), equals('千山鸟飞绝，万径人踪灭。瑞雪兆丰年'));

      expect(ShanshuiSeason.winter.sealTextFor(ShanshuiRealm.nature), equals('万山飞雪'));
      expect(ShanshuiSeason.winter.sealTextFor(ShanshuiRealm.westLake), equals('断桥残雪'));
      expect(ShanshuiSeason.winter.sealTextFor(ShanshuiRealm.fenghuang), equals('凤城瑞雪'));
      expect(ShanshuiSeason.winter.sealTextFor(ShanshuiRealm.indoor), equals('瑞雪迎春'));
      expect(ShanshuiSeason.winter.sealTextFor(ShanshuiRealm.outdoor), equals('万山飞雪'));

      expect(ShanshuiSeason.winter.sealBadgeZhFor(ShanshuiRealm.westLake), equals('冬 · 残雪'));
      expect(ShanshuiSeason.winter.sealBadgeZhFor(ShanshuiRealm.fenghuang), equals('冬 · 凤凰'));
    });

    test('preserves backward compatibility for legacy properties', () {
      expect(ShanshuiSeason.spring.nameZh, equals('春 · 桃夭青绿'));
      expect(ShanshuiSeason.spring.poem, equals('水面初平云脚低，几处早莺争暖树'));
      expect(ShanshuiSeason.spring.sealText, equals('春和景明'));

      const state = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.indoor,
        season: ShanshuiSeason.winter,
        timeOfDay: ShanshuiTimeOfDay.night,
        weather: ShanshuiWeather.snowy,
      );
      expect(state.titleZh, equals('冬 · 瑞雪温炉'));
      expect(state.sealText, equals('瑞雪迎春'));
      expect(state.matchesEnvironment(state), isTrue);
      expect(
        state.matchesEnvironment(
          state.copyWith(realm: ShanshuiRealm.nature),
        ),
        isFalse,
      );
    });
  });

  group('ScenerySettingsService', () {
    test('persists collapsed state and optional pinned atmosphere override', () async {
      final storage = MockSecureStorage();
      final service = ScenerySettingsService(storage: storage);

      expect(await service.getIsCollapsed(), isFalse);
      expect(await service.getPinnedAtmosphere(), isNull);

      await service.setIsCollapsed(true);
      expect(await service.getIsCollapsed(), isTrue);

      const pinned = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.nature,
        season: ShanshuiSeason.winter,
        timeOfDay: ShanshuiTimeOfDay.night,
        weather: ShanshuiWeather.snowy,
      );
      await service.setPinnedAtmosphere(pinned);

      final restored = await service.getPinnedAtmosphere();
      expect(restored, equals(pinned));

      await service.setPinnedAtmosphere(null);
      expect(await service.getPinnedAtmosphere(), isNull);
    });

    test('persists and restores SceneryRealmPreference, defaulting to auto', () async {
      final storage = MockSecureStorage();
      final service = ScenerySettingsService(storage: storage);

      // Default on fresh storage
      expect(await service.getRealmPreference(), equals(SceneryRealmPreference.auto));

      // Persist indoor
      await service.setRealmPreference(SceneryRealmPreference.indoor);
      expect(await service.getRealmPreference(), equals(SceneryRealmPreference.indoor));

      // Persist outdoor
      await service.setRealmPreference(SceneryRealmPreference.outdoor);
      expect(await service.getRealmPreference(), equals(SceneryRealmPreference.outdoor));

      // Persist nature
      await service.setRealmPreference(SceneryRealmPreference.nature);
      expect(await service.getRealmPreference(), equals(SceneryRealmPreference.nature));

      // Persist westLake
      await service.setRealmPreference(SceneryRealmPreference.westLake);
      expect(await service.getRealmPreference(), equals(SceneryRealmPreference.westLake));

      // Persist fenghuang
      await service.setRealmPreference(SceneryRealmPreference.fenghuang);
      expect(await service.getRealmPreference(), equals(SceneryRealmPreference.fenghuang));

      // Reset pinned atmosphere resets realm preference back to auto
      await service.setPinnedAtmosphere(null);
      expect(await service.getRealmPreference(), equals(SceneryRealmPreference.auto));
    });

    test('recovers safely from corrupted realm preference values in secure storage', () async {
      final storage = MockSecureStorage();
      final service = ScenerySettingsService(storage: storage);

      await storage.write(
        key: 'memodiary_scenery_realm_preference',
        value: 'corrupted_invalid_preference_id',
      );
      expect(await service.getRealmPreference(), equals(SceneryRealmPreference.auto));
    });
  });
}

