import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/scenery/models/ancient_room_palette.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/scenery/models/shanshui_scenery_geometry.dart';
import 'package:memodiary/features/scenery/painters/ancient_room_painter.dart';

void main() {
  group('AncientRoomPainter', () {
    test('renders onto canvas across all seasons, times of day, and weather modes without error', () {
      final seasons = ShanshuiSeason.values;
      final times = ShanshuiTimeOfDay.values;
      final weathers = ShanshuiWeather.values;

      for (final season in seasons) {
        for (final time in times) {
          for (final weather in weathers) {
            final atmosphere = ShanshuiAtmosphereState(
              realm: ShanshuiRealm.indoor,
              season: season,
              timeOfDay: time,
              weather: weather,
            );
            final painter = AncientRoomPainter(
              atmosphere: atmosphere,
              roomPalette: AncientRoomPalette.of(season, time),
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

    test('static picture recorder caches static room architecture and can be rendered cleanly', () {
      const atmosphere = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.indoor,
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.sunny,
      );
      final roomPalette = AncientRoomPalette.of(atmosphere.season, atmosphere.timeOfDay);

      final picture = AncientRoomPainter.recordStaticPicture(
        atmosphere: atmosphere,
        roomPalette: roomPalette,
      );

      expect(picture, isNotNull);

      // Supply cached picture to painter
      final painter = AncientRoomPainter(
        atmosphere: atmosphere,
        roomPalette: roomPalette,
        animationTime: 2.0,
        particles: const [],
        weatherDrops: const [],
        cachedStaticPicture: picture,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1500, 1000));
      painter.paint(canvas, const Size(1500, 1000));

      final outputPicture = recorder.endRecording();
      outputPicture.dispose();
      picture.dispose();
    });

    test('shouldRepaint returns true when animationTime, particles, or atmosphere change', () {
      const atmosphere1 = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.indoor,
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.sunny,
      );
      const atmosphere2 = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.indoor,
        season: ShanshuiSeason.summer,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.sunny,
      );

      final painterA = AncientRoomPainter(
        atmosphere: atmosphere1,
        animationTime: 1.0,
        particles: const [],
        weatherDrops: const [],
      );

      final painterB = AncientRoomPainter(
        atmosphere: atmosphere1,
        animationTime: 1.02,
        particles: const [],
        weatherDrops: const [],
      );

      final painterC = AncientRoomPainter(
        atmosphere: atmosphere2,
        animationTime: 1.0,
        particles: const [],
        weatherDrops: const [],
      );

      expect(painterA.shouldRepaint(painterB), isTrue);
      expect(painterA.shouldRepaint(painterC), isTrue);
      expect(painterA.shouldRepaint(painterA), isFalse);
    });
  });
}
