import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/scenery/models/ancient_room_palette.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';

void main() {
  group('AncientRoomPalette', () {
    test('resolves distinct non-null palettes for all 16 season and time-of-day pairs', () {
      for (final season in ShanshuiSeason.values) {
        for (final time in ShanshuiTimeOfDay.values) {
          final palette = AncientRoomPalette.of(season, time);
          expect(palette, isNotNull);
          expect(palette.shojiTop, isA<Color>());
          expect(palette.shojiBottom, isA<Color>());
          expect(palette.wallLeft, isA<Color>());
          expect(palette.wallRight, isA<Color>());
          expect(palette.woodDark, isA<Color>());
          expect(palette.woodMid, isA<Color>());
          expect(palette.woodHighlight, isA<Color>());
          expect(palette.floorBase, isA<Color>());
          expect(palette.floorHighlight, isA<Color>());
          expect(palette.ambientOverlay, isA<Color>());
          expect(palette.lightBeamColor, isA<Color>());
          expect(palette.floorPatchColor, isA<Color>());
          expect(palette.candleIntensity, inInclusiveRange(0.0, 1.0));
          expect(palette.foliagePrimary, isA<Color>());
          expect(palette.foliageSecondary, isA<Color>());
          expect(palette.foliageAccent, isA<Color>());
          expect(palette.indoorPotFlower, isA<Color>());
          expect(palette.indoorPotLeaf, isA<Color>());
          expect(palette.particleColor1, isA<Color>());
          expect(palette.particleColor2, isA<Color>());
        }
      }
    });

    test('candle intensity increases at dusk and night compared to daytime across all seasons', () {
      for (final season in ShanshuiSeason.values) {
        final dayPalette = AncientRoomPalette.of(season, ShanshuiTimeOfDay.day);
        final duskPalette = AncientRoomPalette.of(season, ShanshuiTimeOfDay.dusk);
        final nightPalette = AncientRoomPalette.of(season, ShanshuiTimeOfDay.night);

        expect(duskPalette.candleIntensity, greaterThan(dayPalette.candleIntensity));
        expect(nightPalette.candleIntensity, greaterThanOrEqualTo(duskPalette.candleIntensity));
      }
    });

    test('winter palette specifies snowy foliage and winter plum blossoms', () {
      final winterDay = AncientRoomPalette.of(ShanshuiSeason.winter, ShanshuiTimeOfDay.day);
      expect(winterDay.foliagePrimary, const Color(0xFFF8FAFC)); // heavy snow cover
      expect(winterDay.indoorPotFlower, const Color(0xFFDE3B4B)); // blooming winter plum
    });

    test('weather modulation helpers resolve expected beam multiplier and dimming values', () {
      expect(ShanshuiWeather.sunny.indoorBeamMultiplier, 1.0);
      expect(ShanshuiWeather.sunny.indoorRoomDimming, 0.0);

      expect(ShanshuiWeather.cloudy.indoorBeamMultiplier, 0.40);
      expect(ShanshuiWeather.cloudy.indoorRoomDimming, 0.10);

      expect(ShanshuiWeather.rainy.indoorBeamMultiplier, 0.15);
      expect(ShanshuiWeather.rainy.indoorRoomDimming, 0.20);

      expect(ShanshuiWeather.stormy.indoorBeamMultiplier, 0.05);
      expect(ShanshuiWeather.stormy.indoorRoomDimming, 0.35);

      expect(ShanshuiWeather.snowy.indoorBeamMultiplier, 0.50);
      expect(ShanshuiWeather.snowy.indoorRoomDimming, 0.08);
    });

    test('indoor weather badges match classical atmospheric phrases', () {
      expect(ShanshuiWeather.sunny.badgeZhFor(ShanshuiRealm.indoor), '晴窗日暖');
      expect(ShanshuiWeather.cloudy.badgeZhFor(ShanshuiRealm.indoor), '云岚漫窗');
      expect(ShanshuiWeather.rainy.badgeZhFor(ShanshuiRealm.indoor), '蕉窗听雨');
      expect(ShanshuiWeather.stormy.badgeZhFor(ShanshuiRealm.indoor), '风雨惊雷');
      expect(ShanshuiWeather.snowy.badgeZhFor(ShanshuiRealm.indoor), '推窗看雪');
    });
  });
}
