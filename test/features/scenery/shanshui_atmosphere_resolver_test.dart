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
  });
}

