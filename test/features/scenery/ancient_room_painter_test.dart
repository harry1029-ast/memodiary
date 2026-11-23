import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/scenery/models/ancient_room_palette.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/scenery/models/shanshui_scenery_geometry.dart';
import 'package:memodiary/features/scenery/painters/ancient_room_painter.dart';

Future<ByteData> _renderPainterRgba(AncientRoomPainter painter) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1500, 1000));
  painter.paint(canvas, const Size(1500, 1000));
  final picture = recorder.endRecording();
  final image = await picture.toImage(1500, 1000);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();
  return bytes!;
}

Future<ByteData> _renderRoomRgba({
  required ShanshuiSeason season,
  required ShanshuiTimeOfDay timeOfDay,
  ShanshuiWeather weather = ShanshuiWeather.sunny,
  bool showCalligraphy = false,
  bool fullPoem = false,
}) async {
  final atmosphere = ShanshuiAtmosphereState(
    realm: ShanshuiRealm.indoor,
    season: season,
    timeOfDay: timeOfDay,
    weather: weather,
  );
  final palette = AncientRoomPalette.of(season, timeOfDay);
  final staticPicture = AncientRoomPainter.recordStaticPicture(
    atmosphere: atmosphere,
    roomPalette: palette,
  );
  try {
    return await _renderPainterRgba(
      AncientRoomPainter(
        atmosphere: atmosphere,
        roomPalette: palette,
        animationTime: 0.0,
        particles: const [],
        weatherDrops: const [],
        showCalligraphy: showCalligraphy,
        fullPoem: fullPoem,
        cachedStaticPicture: staticPicture,
      ),
    );
  } finally {
    staticPicture.dispose();
  }
}

Color _pixelAt(ByteData rgba, int x, int y) {
  final offset = (y * 1500 + x) * 4;
  return Color.fromARGB(
    rgba.getUint8(offset + 3),
    rgba.getUint8(offset),
    rgba.getUint8(offset + 1),
    rgba.getUint8(offset + 2),
  );
}

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

    test('left Moon Window renders outdoor sky behind unoccluded rosewood frame, snow sill, and foreground pot', () async {
      final winterBytes = await _renderRoomRgba(
        season: ShanshuiSeason.winter,
        timeOfDay: ShanshuiTimeOfDay.day,
      );

      final upperFramePixel = _pixelAt(winterBytes, 2, 177);
      expect(upperFramePixel.r * 255, lessThan(80));
      expect(upperFramePixel.g * 255, lessThan(60));
      expect(upperFramePixel.b * 255, lessThan(50));

      final rightFramePixel = _pixelAt(winterBytes, 233, 428);
      expect(rightFramePixel.r * 255, lessThan(140));
      expect(rightFramePixel.g * 255, lessThan(140));

      final snowSillPixel = _pixelAt(winterBytes, 167, 655);
      expect(snowSillPixel.r * 255, greaterThan(230));
      expect(snowSillPixel.g * 255, greaterThan(230));
      expect(snowSillPixel.b * 255, greaterThan(230));

      final potBlossomPixel = _pixelAt(winterBytes, 20, 629);
      expect(potBlossomPixel.r * 255, greaterThan(180));
      expect(potBlossomPixel.g * 255, lessThan(110));

      final springNightBytes = await _renderRoomRgba(
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.night,
      );

      final nightSkyPixel = _pixelAt(springNightBytes, 25, 250);
      expect(nightSkyPixel.b, greaterThan(nightSkyPixel.r));
      expect(nightSkyPixel.b * 255, lessThan(90));

      final springSillPixel = _pixelAt(springNightBytes, 167, 655);
      expect(springSillPixel.r * 255, lessThan(60));
      expect(springSillPixel.g * 255, lessThan(50));
    });

    test('right wall carves even-odd circular Moon Archway revealing cyan drapes, emerald banner, and wall lantern', () async {
      final rgba = await _renderRoomRgba(
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
      );

      // Cyan silk drape inside circular Moon Archway (1450, 450)
      final cyanDrape = _pixelAt(rgba, 1450, 450);
      expect(cyanDrape.b * 255, greaterThan(150));
      expect(cyanDrape.g * 255, greaterThan(130));
      expect(cyanDrape.r * 255, lessThan(100));

      // Emerald banner inside Moon Archway (1360, 325)
      final emeraldBanner = _pixelAt(rgba, 1360, 325);
      expect(emeraldBanner.g, greaterThan(emeraldBanner.r));
      expect(emeraldBanner.g, greaterThan(emeraldBanner.b));

      // Octagonal wall lantern face on alcove pillar (1286, 400)
      final wallLantern = _pixelAt(rgba, 1286, 400);
      expect(wallLantern.r * 255, greaterThan(200));
      expect(wallLantern.g * 255, greaterThan(185));

      // Right wall plaster between slats outside Moon Archway (1160, 300)
      final rightWallPlaster = _pixelAt(rgba, 1160, 300);
      expect(rightWallPlaster.r, greaterThan(rightWallPlaster.b));

      // Right circular Moon Archway dark wood casing at (1170, 515)
      final archFrame = _pixelAt(rgba, 1170, 515);
      expect(archFrame.r * 255, lessThan(80));
      expect(archFrame.g * 255, lessThan(60));
    });

    test('renders Moon Gate banners, chandelier, full-perspective tea table, plum table lantern, and winter brazier', () async {
      final springRgba = await _renderRoomRgba(
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
      );

      // Moon Gate top wooden ring at (720, 320)
      final moonGateRim = _pixelAt(springRgba, 720, 320);
      expect(moonGateRim.r * 255, lessThan(80));
      expect(moonGateRim.g * 255, lessThan(60));

      // Twin cream-silk hanging banners flanking Moon Gate
      final leftBanner = _pixelAt(springRgba, 455, 329);
      expect(leftBanner.r * 255, greaterThan(215));
      expect(leftBanner.g * 255, greaterThan(205));
      expect(leftBanner.b * 255, greaterThan(180));

      final rightBanner = _pixelAt(springRgba, 920, 329);
      expect(rightBanner.r * 255, greaterThan(215));
      expect(rightBanner.g * 255, greaterThan(205));

      // Top woven bamboo chandelier inner bowl at (730, 215) clear of center rib
      final chandelier = _pixelAt(springRgba, 730, 215);
      expect(chandelier.r * 255, greaterThan(225));
      expect(chandelier.g * 255, greaterThan(215));

      // Full-perspective tea table runner extending to bottom foreground (435, 985)
      final tableRunner = _pixelAt(springRgba, 435, 985);
      expect(tableRunner.r * 255, greaterThan(205));
      expect(tableRunner.g * 255, greaterThan(195));
      expect(tableRunner.b * 255, greaterThan(185));

      // Foreground plum-blossom table lantern shade (480, 795) and red blossom (480, 817)
      final tableLanternShade = _pixelAt(springRgba, 480, 795);
      expect(tableLanternShade.r * 255, greaterThan(210));
      expect(tableLanternShade.g * 255, greaterThan(190));

      final plumBlossom = _pixelAt(springRgba, 480, 817);
      expect(plumBlossom.r * 255, greaterThan(175));
      expect(plumBlossom.g * 255, lessThan(110));

      // Winter red-clay charcoal brazier ember at (760, 734) only appears in Winter/Snowy
      final winterRgba = await _renderRoomRgba(
        season: ShanshuiSeason.winter,
        timeOfDay: ShanshuiTimeOfDay.day,
      );

      final brazierEmber = _pixelAt(winterRgba, 760, 734);
      expect(brazierEmber.r * 255, greaterThan(220));
      expect(brazierEmber.g * 255, greaterThan(160));
      expect(brazierEmber.r, greaterThan(brazierEmber.b));

      final brazierClayBody = _pixelAt(winterRgba, 732, 742);
      expect(brazierClayBody.r, greaterThan(brazierClayBody.b));
    });

    test('renders bottom-right vertical calligraphy colophon, 2x2 cinnabar seal, and vignette when enabled', () async {
      final withCalligraphy = await _renderRoomRgba(
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
        showCalligraphy: true,
        fullPoem: true,
      );
      final withoutCalligraphy = await _renderRoomRgba(
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
        showCalligraphy: false,
        fullPoem: false,
      );

      // Legacy top-left seal spot (65, 145) must not hold cinnabar red
      final legacySpot = _pixelAt(withCalligraphy, 65, 145);
      expect(legacySpot.r - legacySpot.b, lessThan(0.25));

      // Bottom-right carved 2x2 cinnabar seal border fill at (1421, 916)
      final sealPixel = _pixelAt(withCalligraphy, 1421, 916);
      expect(sealPixel.r * 255, greaterThan(120));
      expect((sealPixel.r - sealPixel.g) * 255, greaterThan(50));
      expect((sealPixel.r - sealPixel.b) * 255, greaterThan(50));

      // Without calligraphy, bottom-right spot shows dark floor/vignette instead of seal
      final hiddenSealSpot = _pixelAt(withoutCalligraphy, 1421, 916);
      expect(hiddenSealSpot.r * 255, lessThan(90));
    });

    test('shouldRepaint responds to calligraphy, poem, palette, lightning, and picture changes', () {
      const atmosphere = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.indoor,
        season: ShanshuiSeason.fall,
        timeOfDay: ShanshuiTimeOfDay.dusk,
        weather: ShanshuiWeather.stormy,
      );
      final base = AncientRoomPainter(
        atmosphere: atmosphere,
        animationTime: 1.0,
        particles: const [],
        weatherDrops: const [],
        showCalligraphy: false,
        fullPoem: false,
        lightningAlpha: 0.0,
      );
      expect(
        base.shouldRepaint(
          AncientRoomPainter(
            atmosphere: atmosphere,
            animationTime: 1.0,
            particles: const [],
            weatherDrops: const [],
            showCalligraphy: true,
            fullPoem: false,
            lightningAlpha: 0.0,
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          AncientRoomPainter(
            atmosphere: atmosphere,
            animationTime: 1.0,
            particles: const [],
            weatherDrops: const [],
            showCalligraphy: false,
            fullPoem: true,
            lightningAlpha: 0.0,
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          AncientRoomPainter(
            atmosphere: atmosphere,
            animationTime: 1.0,
            particles: const [],
            weatherDrops: const [],
            showCalligraphy: false,
            fullPoem: false,
            lightningAlpha: 0.6,
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          AncientRoomPainter(
            atmosphere: atmosphere,
            roomPalette: AncientRoomPalette.of(
              ShanshuiSeason.spring,
              ShanshuiTimeOfDay.day,
            ),
            animationTime: 1.0,
            particles: const [],
            weatherDrops: const [],
          ),
        ),
        isTrue,
      );
    });
  });
}
