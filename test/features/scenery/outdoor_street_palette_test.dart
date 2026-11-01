import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/scenery/models/outdoor_street_palette.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';

void main() {
  group('OutdoorStreetPalette', () {
    test('resolves authentic palettes across all 16 season and time-of-day pairs', () {
      for (final season in ShanshuiSeason.values) {
        for (final timeOfDay in ShanshuiTimeOfDay.values) {
          final palette = OutdoorStreetPalette.of(season, timeOfDay);
          expect(palette, isNotNull);
          expect(palette.skyTop, isNotNull);
          expect(palette.skyBottom, isNotNull);
          expect(palette.celestialColor, isNotNull);
          expect(palette.celestialGlow, isNotNull);
          expect(palette.ambientOverlay, isNotNull);
          expect(palette.mtnTop, isNotNull);
          expect(palette.mtnMid, isNotNull);
          expect(palette.mtnBase, isNotNull);
          expect(palette.mtnCrag, isNotNull);
          expect(palette.foliagePrimary, isNotNull);
          expect(palette.foliageSecondary, isNotNull);
          expect(palette.foliageAccent, isNotNull);
          expect(palette.particleColor1, isNotNull);
          expect(palette.particleColor2, isNotNull);
          expect(palette.wallPlaster, isNotNull);
          expect(palette.wallPlasterDark, isNotNull);
          expect(palette.woodFrame, isNotNull);
          expect(palette.streetBase, isNotNull);
          expect(palette.streetMid, isNotNull);
          expect(palette.streetDark, isNotNull);
        }
      }
    });

    test('verifies distinct seasonal particle types and foliage identities', () {
      final spring = OutdoorStreetPalette.of(ShanshuiSeason.spring, ShanshuiTimeOfDay.day);
      expect(spring.particleType, 'petals');
      expect(spring.foliagePrimary, const Color(0xFFE57383));

      final summer = OutdoorStreetPalette.of(ShanshuiSeason.summer, ShanshuiTimeOfDay.day);
      expect(summer.particleType, 'fireflies');
      expect(summer.foliagePrimary, const Color(0xFF2E6E49));

      final fall = OutdoorStreetPalette.of(ShanshuiSeason.fall, ShanshuiTimeOfDay.day);
      expect(fall.particleType, 'leaves');
      expect(fall.foliagePrimary, const Color(0xFFC8462C));

      final winter = OutdoorStreetPalette.of(ShanshuiSeason.winter, ShanshuiTimeOfDay.day);
      expect(winter.particleType, 'snow');
      expect(winter.foliagePrimary, const Color(0xFFF8FAFC));
    });

    test('verifies lantern candle intensity transitions from daytime to night', () {
      final day = OutdoorStreetPalette.of(ShanshuiSeason.spring, ShanshuiTimeOfDay.day);
      final night = OutdoorStreetPalette.of(ShanshuiSeason.spring, ShanshuiTimeOfDay.night);
      expect(day.candleIntensity, lessThan(0.30));
      expect(night.candleIntensity, equals(1.0));
    });

    test('verifies night mode flagstone and plaster darkening', () {
      final day = OutdoorStreetPalette.of(ShanshuiSeason.fall, ShanshuiTimeOfDay.day);
      final night = OutdoorStreetPalette.of(ShanshuiSeason.fall, ShanshuiTimeOfDay.night);
      expect(day.wallPlaster, const Color(0xFFDFC6A8));
      expect(night.wallPlaster, const Color(0xFF786B5E));
      expect(day.streetBase, const Color(0xFFF5DEC0));
      expect(night.streetBase, const Color(0xFF4A4642));
    });
  });
}
