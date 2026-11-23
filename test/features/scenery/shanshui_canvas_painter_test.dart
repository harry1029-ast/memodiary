import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/scenery/models/shanshui_palette.dart';
import 'package:memodiary/features/scenery/models/shanshui_scenery_geometry.dart';
import 'package:memodiary/features/scenery/widgets/shanshui_canvas_painter.dart';

Future<Uint8List> _rasterizeNature(ShanshuiCanvasPainter painter) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1500, 1000));
  painter.paint(canvas, const Size(1500, 1000));
  final picture = recorder.endRecording();
  final image = picture.toImageSync(1500, 1000);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();
  return byteData!.buffer.asUint8List();
}

Color _pixelAt(Uint8List rgba, int x, int y) {
  final offset = (y * 1500 + x) * 4;
  return Color.fromARGB(rgba[offset + 3], rgba[offset], rgba[offset + 1], rgba[offset + 2]);
}

bool _regionPixelsEqual(Uint8List a, Uint8List b, Rect rect) {
  for (int y = rect.top.toInt(); y < rect.bottom.toInt(); y++) {
    for (int x = rect.left.toInt(); x < rect.right.toInt(); x++) {
      final offset = (y * 1500 + x) * 4;
      if (a[offset] != b[offset] ||
          a[offset + 1] != b[offset + 1] ||
          a[offset + 2] != b[offset + 2]) {
        return false;
      }
    }
  }
  return true;
}

void main() {
  group('ShanshuiCanvasPainter (Nature Realm Polish)', () {
    test('renders onto canvas across all seasons, times of day, and weather modes at 3:2 and 16:9', () {
      for (final season in ShanshuiSeason.values) {
        for (final time in ShanshuiTimeOfDay.values) {
          for (final weather in ShanshuiWeather.values) {
            final atmosphere = ShanshuiAtmosphereState(
              realm: ShanshuiRealm.nature,
              season: season,
              timeOfDay: time,
              weather: weather,
            );
            final painter = ShanshuiCanvasPainter(
              atmosphere: atmosphere,
              palette: ShanshuiPalette.of(season, time),
              animationTime: 1.5,
              particles: [
                ShanshuiParticle(
                  x: 750,
                  y: 400,
                  vx: 0.4,
                  vy: 0.6,
                  size: 5.0,
                  angle: 0.8,
                  vAngle: 0.03,
                  phase: 0.5,
                  colorToggle: true,
                ),
              ],
              weatherDrops: [
                ShanshuiWeatherDrop(
                  x: 320,
                  y: 220,
                  len: 20,
                  speed: 12,
                  size: 3.5,
                  phase: 0.4,
                ),
              ],
              cranes: [
                ShanshuiCrane(
                  x: 520,
                  y: 290,
                  scale: 1.0,
                  speed: 0.5,
                  phase: 0.2,
                  yAmp: 6.0,
                  isHero: true,
                ),
              ],
              ripples: [
                ShanshuiRipple(x: 750, y: 760, radius: 18, maxRadius: 120, alpha: 0.7),
              ],
              showCalligraphy: true,
              fullPoem: true,
              lightningAlpha: 0.6,
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

    test('renders spring petals and fall leaves as rotating tilted ellipses rather than fixed circles', () async {
      for (final season in const [ShanshuiSeason.spring, ShanshuiSeason.fall]) {
        final atmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.nature,
          season: season,
          timeOfDay: ShanshuiTimeOfDay.day,
          weather: ShanshuiWeather.sunny,
        );
        final palette = ShanshuiPalette.of(season, ShanshuiTimeOfDay.day);

        final flatBytes = await _rasterizeNature(
          ShanshuiCanvasPainter(
            atmosphere: atmosphere,
            palette: palette,
            animationTime: 0.0,
            particles: [
              ShanshuiParticle(
                x: 820,
                y: 800,
                vx: 0,
                vy: 0,
                size: 8.0,
                angle: 0.0,
                vAngle: 0.0,
                phase: 0.0,
                colorToggle: true,
              ),
            ],
            weatherDrops: const [],
            cranes: const [],
            ripples: const [],
            showCalligraphy: false,
          ),
        );
        final rotatedBytes = await _rasterizeNature(
          ShanshuiCanvasPainter(
            atmosphere: atmosphere,
            palette: palette,
            animationTime: 0.0,
            particles: [
              ShanshuiParticle(
                x: 820,
                y: 800,
                vx: 0,
                vy: 0,
                size: 8.0,
                angle: 1.57,
                vAngle: 0.0,
                phase: 0.0,
                colorToggle: true,
              ),
            ],
            weatherDrops: const [],
            cranes: const [],
            ripples: const [],
            showCalligraphy: false,
          ),
        );

        // Rotating an ellipse by 90 degrees changes the pixels around (820, 800)
        expect(_regionPixelsEqual(flatBytes, rotatedBytes, const Rect.fromLTWH(808, 788, 24, 24)), isFalse);
      }
    });

    test('renders summer fireflies drifting upward with pulsing brightness in non-rainy weather', () async {
      const summerNight = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.nature,
        season: ShanshuiSeason.summer,
        timeOfDay: ShanshuiTimeOfDay.night,
        weather: ShanshuiWeather.sunny,
      );
      final palette = ShanshuiPalette.of(summerNight.season, summerNight.timeOfDay);
      final firefly = ShanshuiParticle(
        x: 520,
        y: 120,
        vx: 0.2,
        vy: 0.8,
        size: 7.0,
        angle: 0.0,
        vAngle: 0.0,
        phase: 0.3,
        colorToggle: true,
      );

      final earlyBytes = await _rasterizeNature(
        ShanshuiCanvasPainter(
          atmosphere: summerNight,
          palette: palette,
          animationTime: 0.2,
          particles: [firefly],
          weatherDrops: const [],
          cranes: const [],
          ripples: const [],
          showCalligraphy: false,
        ),
      );
      final laterBytes = await _rasterizeNature(
        ShanshuiCanvasPainter(
          atmosphere: summerNight,
          palette: palette,
          animationTime: 2.2,
          particles: [firefly],
          weatherDrops: const [],
          cranes: const [],
          ripples: const [],
          showCalligraphy: false,
        ),
      );

      int findFireflyY(Uint8List rgba) {
        int bestY = -1;
        int bestScore = -1;
        for (int y = 660; y < 960; y++) {
          for (int x = 490; x < 550; x++) {
            final px = _pixelAt(rgba, x, y);
            final r = (px.r * 255).round();
            final g = (px.g * 255).round();
            final b = (px.b * 255).round();
            final score = r + g - b * 2;
            if (score > bestScore) {
              bestScore = score;
              bestY = y;
            }
          }
        }
        return bestY;
      }

      expect(findFireflyY(laterBytes), lessThan(findFireflyY(earlyBytes)));
    });

    test('renders stormy multi-segment jagged lightning bolts and rain-spawned lake ripples', () async {
      const stormyDay = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.nature,
        season: ShanshuiSeason.summer,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.stormy,
      );
      final palette = ShanshuiPalette.of(stormyDay.season, stormyDay.timeOfDay);

      final stormBolt = await _rasterizeNature(
        ShanshuiCanvasPainter(
          atmosphere: stormyDay,
          palette: palette,
          animationTime: 0.5,
          particles: const [],
          weatherDrops: const [],
          cranes: const [],
          ripples: const [],
          showCalligraphy: false,
          lightningAlpha: 0.9,
        ),
      );

      final skyRef = _pixelAt(stormBolt, 460, 40);
      final boltXs = <int>{};
      int boltPixels = 0;
      for (int y = 20; y < 220; y++) {
        for (int x = 500; x < 1000; x++) {
          final px = _pixelAt(stormBolt, x, y);
          if (((px.b - skyRef.b) * 255).round() > 30 && ((px.r - skyRef.r) * 255).round() > 25) {
            boltPixels++;
            boltXs.add(x);
          }
        }
      }
      expect(boltPixels, greaterThan(40));
      expect(boltXs.length, greaterThanOrEqualTo(6));

      // Rainy weather spawns animated lake ripples without requiring tap input
      final rainyDay = stormyDay.copyWith(weather: ShanshuiWeather.rainy);
      final rainA = await _rasterizeNature(
        ShanshuiCanvasPainter(
          atmosphere: rainyDay,
          palette: palette,
          animationTime: 0.2,
          particles: const [],
          weatherDrops: const [],
          cranes: const [],
          ripples: const [],
          showCalligraphy: false,
        ),
      );
      final rainB = await _rasterizeNature(
        ShanshuiCanvasPainter(
          atmosphere: rainyDay,
          palette: palette,
          animationTime: 0.6,
          particles: const [],
          weatherDrops: const [],
          cranes: const [],
          ripples: const [],
          showCalligraphy: false,
        ),
      );
      expect(_regionPixelsEqual(rainA, rainB, const Rect.fromLTWH(250, 740, 800, 180)), isFalse);
    });

    test('wraps punctuation-stripped poem into two upper-right vertical columns clear of horizon', () async {
      const springDay = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.nature,
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.sunny,
      );
      final palette = ShanshuiPalette.of(springDay.season, springDay.timeOfDay);

      final withPoem = await _rasterizeNature(
        ShanshuiCanvasPainter(
          atmosphere: springDay,
          palette: palette,
          animationTime: 0.0,
          particles: const [],
          weatherDrops: const [],
          cranes: const [],
          ripples: const [],
          showCalligraphy: true,
          fullPoem: true,
        ),
      );
      final withoutPoem = await _rasterizeNature(
        ShanshuiCanvasPainter(
          atmosphere: springDay,
          palette: palette,
          animationTime: 0.0,
          particles: const [],
          weatherDrops: const [],
          cranes: const [],
          ripples: const [],
          showCalligraphy: true,
          fullPoem: false,
        ),
      );

      // First vertical poem column (around x=1368..1396, y=80..255) must contain poem strokes
      expect(_regionPixelsEqual(withPoem, withoutPoem, const Rect.fromLTWH(1366, 80, 30, 175)), isFalse);
      // Second vertical poem column (around x=1336..1366, y=80..255) must also contain poem strokes
      expect(_regionPixelsEqual(withPoem, withoutPoem, const Rect.fromLTWH(1336, 80, 30, 175)), isFalse);
      // Lower region (y=320..520) must NOT have single-column overflowed poem characters
      expect(_regionPixelsEqual(withPoem, withoutPoem, const Rect.fromLTWH(1336, 320, 62, 200)), isTrue);
    });
  });
}
