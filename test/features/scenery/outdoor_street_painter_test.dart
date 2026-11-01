import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/scenery/models/outdoor_street_models.dart';
import 'package:memodiary/features/scenery/models/outdoor_street_palette.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/scenery/models/shanshui_scenery_geometry.dart';
import 'package:memodiary/features/scenery/painters/outdoor_street_painter.dart';

void main() {
  group('OutdoorStreetPainter & Crowd Lifecycle', () {
    test('renders onto canvas across all seasons, times of day, and weather modes without error', () {
      final seasons = ShanshuiSeason.values;
      final times = ShanshuiTimeOfDay.values;
      final weathers = ShanshuiWeather.values;

      for (final season in seasons) {
        for (final time in times) {
          for (final weather in weathers) {
            final atmosphere = ShanshuiAtmosphereState(
              realm: ShanshuiRealm.outdoor,
              season: season,
              timeOfDay: time,
              weather: weather,
            );
            final painter = OutdoorStreetPainter(
              atmosphere: atmosphere,
              streetPalette: OutdoorStreetPalette.of(season, time),
              animationTime: 1.5,
              particles: [
                ShanshuiParticle(
                  x: 300,
                  y: 400,
                  vx: 0.5,
                  vy: 0.5,
                  size: 4.0,
                  angle: 0.5,
                  vAngle: 0.02,
                  phase: 1.0,
                  colorToggle: true,
                ),
              ],
              weatherDrops: [
                ShanshuiWeatherDrop(
                  x: 100,
                  y: 200,
                  len: 20,
                  speed: 12,
                  size: 3,
                  phase: 0.5,
                ),
              ],
              showCalligraphy: true,
              fullPoem: true,
              lightningAlpha: 0.5,
            );

            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1500, 1000));
            // Paint at 3:2 fullscreen size
            painter.paint(canvas, const Size(1500, 1000));
            // Paint at 16:9 header size
            painter.paint(canvas, const Size(1600, 900));

            final picture = recorder.endRecording();
            picture.dispose();
          }
        }
      }
    });

    test('static picture recorder caches static street architecture and can be rendered cleanly', () {
      const atmosphere = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.outdoor,
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.sunny,
      );
      final palette = OutdoorStreetPalette.of(atmosphere.season, atmosphere.timeOfDay);

      final picture = OutdoorStreetPainter.recordStaticPicture(
        atmosphere: atmosphere,
        streetPalette: palette,
      );

      expect(picture, isNotNull);

      final painter = OutdoorStreetPainter(
        atmosphere: atmosphere,
        streetPalette: palette,
        animationTime: 2.0,
        particles: const [],
        weatherDrops: const [],
        cachedStaticPicture: picture,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1500, 1000));
      painter.paint(canvas, const Size(1500, 1000));

      final output = recorder.endRecording();
      expect(output, isNotNull);
      output.dispose();
      picture.dispose();
    });

    test('crowd lifecycle respects time-of-day crowd density', () {
      // Dawn: 0 people
      final dawnCrowd = OutdoorStreetCrowd.getActiveFigures(ShanshuiTimeOfDay.dawn);
      expect(dawnCrowd.length, equals(0));

      // Day & Dusk: 15 avenue walkers + 7 stall vendors/patrons = 22 people
      final dayCrowd = OutdoorStreetCrowd.getActiveFigures(ShanshuiTimeOfDay.day);
      expect(dayCrowd.length, equals(22));

      final duskCrowd = OutdoorStreetCrowd.getActiveFigures(ShanshuiTimeOfDay.dusk);
      expect(duskCrowd.length, equals(22));

      // Night: 3 night walkers + 2 late-night noodle stall figures = 5 people
      final nightCrowd = OutdoorStreetCrowd.getActiveFigures(ShanshuiTimeOfDay.night);
      expect(nightCrowd.length, equals(5));
      expect(nightCrowd.where((f) => f.showAtNight).length, equals(5));
    });

    test('oiled-paper umbrella eligibility in precipitation weather', () {
      expect(OutdoorStreetCrowd.isPrecipitationWeather(ShanshuiWeather.sunny), isFalse);
      expect(OutdoorStreetCrowd.isPrecipitationWeather(ShanshuiWeather.cloudy), isFalse);
      expect(OutdoorStreetCrowd.isPrecipitationWeather(ShanshuiWeather.rainy), isTrue);
      expect(OutdoorStreetCrowd.isPrecipitationWeather(ShanshuiWeather.stormy), isTrue);
      expect(OutdoorStreetCrowd.isPrecipitationWeather(ShanshuiWeather.snowy), isTrue);

      final dayCrowd = OutdoorStreetCrowd.getActiveFigures(ShanshuiTimeOfDay.day);
      final umbrellaBearers = dayCrowd.where((f) => f.hasUmbrella).toList();
      expect(umbrellaBearers.length, greaterThan(0));
    });

    test('food stall steam lifecycle', () {
      // At dawn: stalls closed, steam inactive
      expect(OutdoorStreetCrowd.isSteamActive(ShanshuiTimeOfDay.dawn, isLeftStall: true), isFalse);
      expect(OutdoorStreetCrowd.isSteamActive(ShanshuiTimeOfDay.dawn, isLeftStall: false), isFalse);

      // At day/dusk: both left (pastry) and right (noodle) stalls steam
      expect(OutdoorStreetCrowd.isSteamActive(ShanshuiTimeOfDay.day, isLeftStall: true), isTrue);
      expect(OutdoorStreetCrowd.isSteamActive(ShanshuiTimeOfDay.day, isLeftStall: false), isTrue);
      expect(OutdoorStreetCrowd.isSteamActive(ShanshuiTimeOfDay.dusk, isLeftStall: true), isTrue);
      expect(OutdoorStreetCrowd.isSteamActive(ShanshuiTimeOfDay.dusk, isLeftStall: false), isTrue);

      // At night: left pastry stall closed, right noodle stall still steams
      expect(OutdoorStreetCrowd.isSteamActive(ShanshuiTimeOfDay.night, isLeftStall: true), isFalse);
      expect(OutdoorStreetCrowd.isSteamActive(ShanshuiTimeOfDay.night, isLeftStall: false), isTrue);
    });

    test('stone puddle ripples expand and fade cleanly', () {
      final ripple = OutdoorPuddleRipple(x: 750, y: 700, radius: 4.0, alpha: 0.8);
      expect(ripple.isExpired, isFalse);

      ripple.update();
      expect(ripple.radius, greaterThan(4.0));
      expect(ripple.alpha, lessThan(0.8));

      // Simulate fading until expired
      for (int i = 0; i < 100; i++) {
        ripple.update();
      }
      expect(ripple.isExpired, isTrue);
    });
  });
}
