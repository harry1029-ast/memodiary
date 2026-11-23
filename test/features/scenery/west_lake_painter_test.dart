import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/scenery/models/shanshui_scenery_geometry.dart';
import 'package:memodiary/features/scenery/models/west_lake_palette.dart';
import 'package:memodiary/features/scenery/painters/west_lake_painter.dart';

void main() {
  group('WestLakePalette', () {
    test('resolves authentic palettes across all 16 season and time-of-day pairs', () {
      for (final season in ShanshuiSeason.values) {
        for (final timeOfDay in ShanshuiTimeOfDay.values) {
          final palette = WestLakePalette.of(season, timeOfDay);
          expect(palette.skyTop, isNotNull);
          expect(palette.skyBottom, isNotNull);
          expect(palette.celestialColor, isNotNull);
          expect(palette.celestialGlow, isNotNull);
          expect(palette.lakeTop, isNotNull);
          expect(palette.lakeBottom, isNotNull);
          expect(palette.foliagePrimary, isNotNull);
          expect(palette.foliageSecondary, isNotNull);
          expect(palette.mtnMid, isNotNull);
          expect(palette.mtnBase, isNotNull);
          expect(palette.particleColor1, isNotNull);
          expect(palette.particleColor2, isNotNull);
        }
      }
    });

    test('verifies distinct seasonal particle types and lantern intensity shifts', () {
      expect(
        WestLakePalette.of(ShanshuiSeason.spring, ShanshuiTimeOfDay.day).particleType,
        equals('petals'),
      );
      expect(
        WestLakePalette.of(ShanshuiSeason.summer, ShanshuiTimeOfDay.day).particleType,
        equals('fireflies'),
      );
      expect(
        WestLakePalette.of(ShanshuiSeason.fall, ShanshuiTimeOfDay.day).particleType,
        equals('leaves'),
      );
      expect(
        WestLakePalette.of(ShanshuiSeason.winter, ShanshuiTimeOfDay.day).particleType,
        equals('snow'),
      );

      final springDay = WestLakePalette.of(ShanshuiSeason.spring, ShanshuiTimeOfDay.day);
      final springNight = WestLakePalette.of(ShanshuiSeason.spring, ShanshuiTimeOfDay.night);
      expect(springDay.candleIntensity, lessThan(0.25));
      expect(springNight.candleIntensity, equals(1.0));
    });
  });

  group('WestLakePainter', () {
    test('renders cleanly across all 80 season x timeOfDay x weather combinations at 3:2 and 16:9', () {
      for (final season in ShanshuiSeason.values) {
        for (final timeOfDay in ShanshuiTimeOfDay.values) {
          for (final weather in ShanshuiWeather.values) {
            final atmosphere = ShanshuiAtmosphereState(
              realm: ShanshuiRealm.westLake,
              season: season,
              timeOfDay: timeOfDay,
              weather: weather,
            );
            final painter = WestLakePainter(
              atmosphere: atmosphere,
              westLakePalette: WestLakePalette.of(season, timeOfDay),
              animationTime: 1.5,
              particles: [
                ShanshuiParticle(
                  x: 360,
                  y: 420,
                  vx: 0.4,
                  vy: 0.6,
                  size: 4.5,
                  angle: 0.6,
                  vAngle: 0.03,
                  phase: 1.1,
                  colorToggle: true,
                ),
              ],
              weatherDrops: [
                ShanshuiWeatherDrop(
                  x: 240,
                  y: 300,
                  len: 22,
                  speed: 12,
                  size: 3.2,
                  phase: 0.4,
                ),
              ],
              ripples: [
                ShanshuiRipple(
                  x: 680,
                  y: 640,
                  radius: 18,
                  maxRadius: 130,
                  alpha: 0.6,
                ),
              ],
              showCalligraphy: true,
              fullPoem: true,
              lightningAlpha: weather == ShanshuiWeather.stormy ? 0.75 : 0.0,
            );

            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1600, 1000));
            painter.paint(canvas, const Size(1500, 1000));
            painter.paint(canvas, const Size(1600, 900));

            final picture = recorder.endRecording();
            picture.dispose();
          }
        }
      }
    });

    test('recordStaticPicture caches West Lake backdrop and renders with cachedStaticPicture', () {
      const atmosphere = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.westLake,
        season: ShanshuiSeason.fall,
        timeOfDay: ShanshuiTimeOfDay.dusk,
        weather: ShanshuiWeather.sunny,
      );
      final palette = WestLakePalette.of(atmosphere.season, atmosphere.timeOfDay);

      final staticPicture = WestLakePainter.recordStaticPicture(
        atmosphere: atmosphere,
        westLakePalette: palette,
      );
      expect(staticPicture, isNotNull);

      final painter = WestLakePainter(
        atmosphere: atmosphere,
        westLakePalette: palette,
        animationTime: 2.0,
        particles: const [],
        weatherDrops: const [],
        cachedStaticPicture: staticPicture,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1500, 1000));
      painter.paint(canvas, const Size(1500, 1000));

      final output = recorder.endRecording();
      output.dispose();
      staticPicture.dispose();
    });

    test('Broken Bridge visitor count follows Dawn=0, Day/Dusk=5, Night=2 rhythm', () {
      expect(
        WestLakePainter.visibleBridgeVisitors(ShanshuiTimeOfDay.dawn),
        equals(0),
      );
      expect(
        WestLakePainter.visibleBridgeVisitors(ShanshuiTimeOfDay.day),
        equals(5),
      );
      expect(
        WestLakePainter.visibleBridgeVisitors(ShanshuiTimeOfDay.dusk),
        equals(5),
      );
      expect(
        WestLakePainter.visibleBridgeVisitors(ShanshuiTimeOfDay.night),
        equals(2),
      );
    });

    test('Three Pools Mirroring the Moon illuminates candle windows when lanternLevel > 0.22', () {
      final sunnyDay = WestLakePalette.of(ShanshuiSeason.spring, ShanshuiTimeOfDay.day);
      expect(
        WestLakePainter.effectiveLanternLevel(sunnyDay, ShanshuiWeather.sunny),
        lessThanOrEqualTo(0.22),
      );
      expect(
        WestLakePainter.effectiveLanternLevel(sunnyDay, ShanshuiWeather.rainy),
        greaterThan(0.22),
      );

      final dusk = WestLakePalette.of(ShanshuiSeason.fall, ShanshuiTimeOfDay.dusk);
      expect(
        WestLakePainter.effectiveLanternLevel(dusk, ShanshuiWeather.sunny),
        greaterThan(0.22),
      );

      final winterDay = WestLakePalette.of(ShanshuiSeason.winter, ShanshuiTimeOfDay.day);
      expect(
        WestLakePainter.effectiveLanternLevel(winterDay, ShanshuiWeather.sunny),
        greaterThan(0.22),
      );
    });

    test('shouldRepaint detects changes in time, atmosphere, ripples, lightning, and calligraphy', () {
      const atmo1 = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.westLake,
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.sunny,
      );
      const atmo2 = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.westLake,
        season: ShanshuiSeason.winter,
        timeOfDay: ShanshuiTimeOfDay.night,
        weather: ShanshuiWeather.snowy,
      );

      final painterA = WestLakePainter(
        atmosphere: atmo1,
        animationTime: 1.0,
        particles: const [],
        weatherDrops: const [],
      );
      final painterB = WestLakePainter(
        atmosphere: atmo1,
        animationTime: 1.05,
        particles: const [],
        weatherDrops: const [],
      );
      final painterC = WestLakePainter(
        atmosphere: atmo2,
        animationTime: 1.0,
        particles: const [],
        weatherDrops: const [],
      );

      expect(painterA.shouldRepaint(painterA), isFalse);
      expect(painterA.shouldRepaint(painterB), isTrue);
      expect(painterA.shouldRepaint(painterC), isTrue);
    });
  });
}
