import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/scenery/models/outdoor_street_models.dart';
import 'package:memodiary/features/scenery/models/outdoor_street_palette.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/scenery/models/shanshui_scenery_geometry.dart';
import 'package:memodiary/features/scenery/painters/outdoor_street_painter.dart';

Future<Uint8List> _paintOutdoor(
  ShanshuiAtmosphereState atmosphere, {
  OutdoorStreetPalette? palette,
  double animationTime = 0.0,
  List<ShanshuiParticle> particles = const [],
  List<ShanshuiWeatherDrop> weatherDrops = const [],
  double lightningAlpha = 0.0,
  ui.Picture? cachedStaticPicture,
}) async {
  final painter = OutdoorStreetPainter(
    atmosphere: atmosphere,
    streetPalette: palette ?? OutdoorStreetPalette.of(atmosphere.season, atmosphere.timeOfDay),
    animationTime: animationTime,
    particles: particles,
    weatherDrops: weatherDrops,
    lightningAlpha: lightningAlpha,
    cachedStaticPicture: cachedStaticPicture,
  );
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
  group('OutdoorStreetPainter & Crowd Lifecycle', () {
    test('renders onto canvas across all seasons, times of day, and weather modes without error', () {
      for (final season in ShanshuiSeason.values) {
        for (final time in ShanshuiTimeOfDay.values) {
          for (final weather in ShanshuiWeather.values) {
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
            final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1600, 1000));
            painter.paint(canvas, const Size(1500, 1000));
            painter.paint(canvas, const Size(1600, 900));
            recorder.endRecording().dispose();
          }
        }
      }
    });

    test('static picture recorder caches static street architecture and can be rendered cleanly', () async {
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

      final rgba = await _paintOutdoor(
        atmosphere,
        palette: palette,
        animationTime: 2.0,
        cachedStaticPicture: picture,
      );
      expect(rgba.length, equals(1500 * 1000 * 4));
      picture.dispose();
    });

    test('crowd lifecycle respects time-of-day crowd density', () {
      expect(OutdoorStreetCrowd.getActiveFigures(ShanshuiTimeOfDay.dawn).length, equals(0));
      expect(OutdoorStreetCrowd.getActiveFigures(ShanshuiTimeOfDay.day).length, equals(22));
      expect(OutdoorStreetCrowd.getActiveFigures(ShanshuiTimeOfDay.dusk).length, equals(22));

      final nightCrowd = OutdoorStreetCrowd.getActiveFigures(ShanshuiTimeOfDay.night);
      expect(nightCrowd.length, equals(5));
      expect(nightCrowd.where((figure) => figure.showAtNight).length, equals(5));
    });

    test('oiled-paper umbrella eligibility in precipitation weather', () {
      expect(OutdoorStreetCrowd.isPrecipitationWeather(ShanshuiWeather.sunny), isFalse);
      expect(OutdoorStreetCrowd.isPrecipitationWeather(ShanshuiWeather.cloudy), isFalse);
      expect(OutdoorStreetCrowd.isPrecipitationWeather(ShanshuiWeather.rainy), isTrue);
      expect(OutdoorStreetCrowd.isPrecipitationWeather(ShanshuiWeather.stormy), isTrue);
      expect(OutdoorStreetCrowd.isPrecipitationWeather(ShanshuiWeather.snowy), isTrue);

      final dayCrowd = OutdoorStreetCrowd.getActiveFigures(ShanshuiTimeOfDay.day);
      expect(dayCrowd.where((figure) => figure.hasUmbrella).length, greaterThan(0));
    });

    test('food stall steam lifecycle', () {
      expect(OutdoorStreetCrowd.isSteamActive(ShanshuiTimeOfDay.dawn, isLeftStall: true), isFalse);
      expect(OutdoorStreetCrowd.isSteamActive(ShanshuiTimeOfDay.dawn, isLeftStall: false), isFalse);
      expect(OutdoorStreetCrowd.isSteamActive(ShanshuiTimeOfDay.day, isLeftStall: true), isTrue);
      expect(OutdoorStreetCrowd.isSteamActive(ShanshuiTimeOfDay.day, isLeftStall: false), isTrue);
      expect(OutdoorStreetCrowd.isSteamActive(ShanshuiTimeOfDay.dusk, isLeftStall: true), isTrue);
      expect(OutdoorStreetCrowd.isSteamActive(ShanshuiTimeOfDay.dusk, isLeftStall: false), isTrue);
      expect(OutdoorStreetCrowd.isSteamActive(ShanshuiTimeOfDay.night, isLeftStall: true), isFalse);
      expect(OutdoorStreetCrowd.isSteamActive(ShanshuiTimeOfDay.night, isLeftStall: false), isTrue);
    });

    test('stone puddle ripples expand and fade cleanly', () {
      final ripple = OutdoorPuddleRipple(x: 750, y: 700, radius: 4.0, alpha: 0.8);
      expect(ripple.isExpired, isFalse);
      ripple.update();
      expect(ripple.radius, greaterThan(4.0));
      expect(ripple.alpha, lessThan(0.8));
      for (int step = 0; step < 100; step++) {
        ripple.update();
      }
      expect(ripple.isExpired, isTrue);
    });

    test('behind-counter stall figures are cleanly separated from foreground walkers', () {
      final dayCrowd = OutdoorStreetCrowd.getActiveFigures(ShanshuiTimeOfDay.day);
      expect(dayCrowd.where((figure) => figure.isBehindCounter).length, equals(4));
      expect(dayCrowd.where((figure) => !figure.isBehindCounter).length, equals(18));

      final nightCrowd = OutdoorStreetCrowd.getActiveFigures(ShanshuiTimeOfDay.night);
      expect(nightCrowd.where((figure) => figure.isBehindCounter).length, equals(1));
      expect(nightCrowd.where((figure) => !figure.isBehindCounter).length, equals(4));

      for (final walker in OutdoorStreetCrowd.avenueWalkers) {
        expect(walker.isBehindCounter, isFalse);
      }
    });

    test('every active figure across all times of day stays inside the stone avenue and clear of walls/desks', () {
      const obstacleRects = [
        Rect.fromLTWH(0, 665, 295, 150),
        Rect.fromLTWH(118, 805, 168, 85),
        Rect.fromLTWH(1072, 745, 52, 85),
        Rect.fromLTWH(1105, 662, 253, 203),
        Rect.fromLTWH(1255, 794, 76, 99),
      ];

      double wallBottomY(double x) {
        if (x < 275.0) return 935.0 - (120.0 / 275.0) * x;
        if (x < 445.0) return 745.0 - (70.0 / 180.0) * (x - 265.0);
        if (x < 580.0) return 665.0 - (55.0 / 135.0) * (x - 445.0);
        if (x <= 920.0) return 580.0;
        if (x <= 1055.0) return 610.0 + (55.0 / 135.0) * (x - 920.0);
        if (x <= 1225.0) return 675.0 + (70.0 / 180.0) * (x - 1055.0);
        return 815.0 + (120.0 / 275.0) * (x - 1225.0);
      }

      for (final timeOfDay in ShanshuiTimeOfDay.values) {
        for (final figure in OutdoorStreetCrowd.getActiveFigures(timeOfDay)) {
          final footY = figure.footY;
          final leftShoulder = figure.baseX - figure.shoulderHalfSpan;
          final rightShoulder = figure.baseX + figure.shoulderHalfSpan;

          expect(
            OutdoorStreetCrowd.isInsideStoneAvenue(
              figure.baseX,
              footY,
              halfWidth: figure.shoulderHalfSpan,
            ),
            isTrue,
            reason: 'Figure at (${figure.baseX}, ${figure.baseY}) violates avenue bounds',
          );

          if (!figure.isBehindCounter) {
            expect(footY, greaterThan(wallBottomY(figure.baseX)));
            final bodyBand = Rect.fromLTRB(
              leftShoulder,
              figure.baseY - 45.0 * figure.scale,
              rightShoulder,
              footY,
            );
            for (final obstacle in obstacleRects) {
              expect(bodyBand.overlaps(obstacle), isFalse);
            }
          }
        }
      }
    });

    test('occludes behind-counter stall figures behind wooden counters and stools', () async {
      const atmosphere = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.outdoor,
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.sunny,
      );
      final palette = OutdoorStreetPalette.of(atmosphere.season, atmosphere.timeOfDay);
      final cached = OutdoorStreetPainter.recordStaticPicture(
        atmosphere: atmosphere,
        streetPalette: palette,
      );
      final rgba = await _paintOutdoor(atmosphere, palette: palette, cachedStaticPicture: cached);
      cached.dispose();

      // Right noodle shopkeeper head is visible above counter top (y ~ 654)
      expect((_pixelAt(rgba, 1192, 654).r * 255).round(), greaterThan(180));

      // Counter front apron (1192, 755) is uniform wood, occluding lower body
      final apronSampleA = _pixelAt(rgba, 1192, 755);
      final apronSampleB = _pixelAt(rgba, 1202, 755);
      expect(apronSampleA, equals(apronSampleB));
      expect((apronSampleA.r * 255).round(), inInclusiveRange(95, 130));

      // Left-side counter stool patron legs occluded behind wooden stool (1085..1115, 768)
      final stoolSampleA = _pixelAt(rgba, 1102, 768);
      final stoolSampleB = _pixelAt(rgba, 1085, 768);
      expect(stoolSampleA, equals(stoolSampleB));
      expect((stoolSampleA.r * 255).round(), inInclusiveRange(100, 140));
    });

    test('renders dynamic shopfront window glow when lanternLevel > 0.3, tile ribs, and billowing awnings', () async {
      const sunnyDay = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.outdoor,
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.sunny,
      );
      final dayPalette = OutdoorStreetPalette.of(sunnyDay.season, sunnyDay.timeOfDay);

      final sunnyBytes = await _paintOutdoor(sunnyDay, palette: dayPalette, animationTime: 0.4);
      final rainyBytes = await _paintOutdoor(
        sunnyDay.copyWith(weather: ShanshuiWeather.rainy),
        palette: dayPalette,
        animationTime: 0.4,
      );

      final sunnyWin = _pixelAt(sunnyBytes, 120, 520);
      final rainyWin = _pixelAt(rainyBytes, 120, 520);
      expect((rainyWin.r * 255).round() - (rainyWin.b * 255).round(), greaterThan(55));
      expect((rainyWin.r * 255).round(), greaterThan((sunnyWin.r * 255).round() + 40));

      int countRoofEdges(Uint8List rgba) {
        int edges = 0;
        for (int x = 700; x < 800; x++) {
          final leftPx = _pixelAt(rgba, x, 395);
          final rightPx = _pixelAt(rgba, x + 1, 395);
          if (((leftPx.r - rightPx.r) * 255).abs() > 8) edges++;
        }
        return edges;
      }

      expect(countRoofEdges(sunnyBytes), greaterThanOrEqualTo(6));
      final winterBytes = await _paintOutdoor(
        sunnyDay.copyWith(season: ShanshuiSeason.winter),
        animationTime: 0.4,
      );
      expect(countRoofEdges(winterBytes), equals(0));

      final billowPeak = await _paintOutdoor(sunnyDay, palette: dayPalette, animationTime: 0.785);
      final billowTrough = await _paintOutdoor(sunnyDay, palette: dayPalette, animationTime: 2.356);
      expect(
        _regionPixelsEqual(billowPeak, billowTrough, const Rect.fromLTWH(255, 452, 40, 20)),
        isFalse,
      );
    });

    test('renders upward pulsing summer fireflies, skyOverlay, jagged lightning, and rain puddle ripples', () async {
      const summerNight = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.outdoor,
        season: ShanshuiSeason.summer,
        timeOfDay: ShanshuiTimeOfDay.night,
        weather: ShanshuiWeather.sunny,
      );
      final firefly = ShanshuiParticle(
        x: 750,
        y: 150,
        vx: 0.2,
        vy: 0.8,
        size: 6.0,
        angle: 0.0,
        vAngle: 0.02,
        phase: 0.5,
        colorToggle: true,
      );

      final earlyBytes = await _paintOutdoor(summerNight, animationTime: 0.2, particles: [firefly]);
      final laterBytes = await _paintOutdoor(summerNight, animationTime: 2.2, particles: [firefly]);

      int findFireflyY(Uint8List rgba) {
        int bestY = -1;
        int bestLum = -1;
        for (int y = 620; y < 950; y++) {
          for (int x = 720; x < 780; x++) {
            final px = _pixelAt(rgba, x, y);
            final score = (px.g * 255).round() + (px.r * 255).round() - (px.b * 255).round() * 2;
            if (score > bestLum) {
              bestLum = score;
              bestY = y;
            }
          }
        }
        return bestY;
      }

      expect(findFireflyY(laterBytes), lessThan(findFireflyY(earlyBytes)));

      const sunnyDay = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.outdoor,
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.sunny,
      );
      final dayPalette = OutdoorStreetPalette.of(sunnyDay.season, sunnyDay.timeOfDay);
      final clearSky = await _paintOutdoor(sunnyDay, palette: dayPalette, animationTime: 0.5);
      final stormSky = await _paintOutdoor(
        sunnyDay.copyWith(weather: ShanshuiWeather.stormy),
        palette: dayPalette,
        animationTime: 0.5,
      );
      expect(
        (_pixelAt(stormSky, 500, 60).r * 255).round(),
        lessThan((_pixelAt(clearSky, 500, 60).r * 255).round() - 60),
      );

      final stormBolt = await _paintOutdoor(
        sunnyDay.copyWith(weather: ShanshuiWeather.stormy),
        palette: dayPalette,
        animationTime: 0.5,
        lightningAlpha: 0.9,
      );
      final flashedSkyRef = _pixelAt(stormBolt, 460, 40);
      final boltXs = <int>{};
      int boltContrastPixels = 0;
      for (int y = 20; y < 220; y++) {
        for (int x = 500; x < 1000; x++) {
          final boltPx = _pixelAt(stormBolt, x, y);
          if (((boltPx.b - flashedSkyRef.b) * 255).round() > 30 &&
              ((boltPx.r - flashedSkyRef.r) * 255).round() > 25) {
            boltContrastPixels++;
            boltXs.add(x);
          }
        }
      }
      expect(boltContrastPixels, greaterThan(40));
      expect(boltXs.length, greaterThanOrEqualTo(6));

      final rainyDay = sunnyDay.copyWith(weather: ShanshuiWeather.rainy);
      final rainA = await _paintOutdoor(rainyDay, palette: dayPalette, animationTime: 0.25);
      final rainB = await _paintOutdoor(rainyDay, palette: dayPalette, animationTime: 0.65);
      expect(_regionPixelsEqual(rainA, rainB, const Rect.fromLTWH(580, 640, 340, 280)), isFalse);
    });

    test('renders radial lantern gradients, wet clipped reflections, and townsfolk facial details & soles', () async {
      const springNight = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.outdoor,
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.night,
        weather: ShanshuiWeather.sunny,
      );
      final nightClearBytes = await _paintOutdoor(springNight);
      final nightRainBytes = await _paintOutdoor(
        springNight.copyWith(weather: ShanshuiWeather.rainy),
      );

      // Multi-stop radial lantern gradient: bright center vs darker outer rim
      final lanternCore = _pixelAt(nightClearBytes, 242, 272);
      final lanternRim = _pixelAt(nightClearBytes, 272, 272);
      expect((lanternCore.g * 255).round(), greaterThan((lanternRim.g * 255).round() + 40));

      // Wet street reflections warm open avenue stones (420, 780) without spilling outside
      // onto the shopfront/table at (200, 700) inside the unclipped reflection bounding box.
      expect(
        (_pixelAt(nightRainBytes, 420, 780).r * 255).round(),
        greaterThan((_pixelAt(nightClearBytes, 420, 780).r * 255).round()),
      );
      expect(
        (_pixelAt(nightRainBytes, 200, 700).r * 255).round(),
        lessThan((_pixelAt(nightClearBytes, 200, 700).r * 255).round()),
      );

      // Townsfolk serene eyes and white-soled cloth shoes
      final springDayBytes = await _paintOutdoor(
        const ShanshuiAtmosphereState(
          realm: ShanshuiRealm.outdoor,
          season: ShanshuiSeason.spring,
          timeOfDay: ShanshuiTimeOfDay.day,
          weather: ShanshuiWeather.sunny,
        ),
      );
      bool foundDarkEye = false;
      for (int y = 725; y <= 755; y++) {
        for (int x = 320; x <= 352; x++) {
          final px = _pixelAt(springDayBytes, x, y);
          if ((px.r * 255).round() < 65 && (px.g * 255).round() < 60) foundDarkEye = true;
        }
      }
      expect(foundDarkEye, isTrue);

      bool foundWhiteSole = false;
      for (int y = 855; y <= 875; y++) {
        for (int x = 315; x <= 360; x++) {
          final px = _pixelAt(springDayBytes, x, y);
          if ((px.r * 255).round() > 225 &&
              (px.g * 255).round() > 220 &&
              (px.b * 255).round() > 210) {
            foundWhiteSole = true;
          }
        }
      }
      expect(foundWhiteSole, isTrue);
    });
  });
}
