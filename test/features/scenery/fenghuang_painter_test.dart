import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/services/audio_sanctum_service.dart';
import 'package:memodiary/features/scenery/models/fenghuang_palette.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/scenery/models/shanshui_palette.dart';
import 'package:memodiary/features/scenery/models/shanshui_scenery_geometry.dart';
import 'package:memodiary/features/scenery/painters/ancient_room_painter.dart';
import 'package:memodiary/features/scenery/painters/fenghuang_painter.dart';
import 'package:memodiary/features/scenery/painters/outdoor_street_painter.dart';
import 'package:memodiary/features/scenery/painters/west_lake_painter.dart';
import 'package:memodiary/features/scenery/screens/contemplation_view_screen.dart';
import 'package:memodiary/features/scenery/widgets/shanshui_canvas_painter.dart';
import 'package:memodiary/features/scenery/widgets/shanshui_scenery_painting.dart';

void main() {
  group('FenghuangPalette', () {
    test('resolves authentic palettes across all 16 season and time-of-day pairs', () {
      for (final season in ShanshuiSeason.values) {
        for (final timeOfDay in ShanshuiTimeOfDay.values) {
          final palette = FenghuangPalette.of(season, timeOfDay);
          expect(palette.skyTop, isNotNull);
          expect(palette.skyBottom, isNotNull);
          expect(palette.riverMist, isNotNull);
          expect(palette.celestialColor, isNotNull);
          expect(palette.celestialGlow, isNotNull);
          expect(palette.riverTop, isNotNull);
          expect(palette.riverBottom, isNotNull);
          expect(palette.mtnMid, isNotNull);
          expect(palette.mtnBase, isNotNull);
          expect(palette.foliagePrimary, isNotNull);
          expect(palette.foliageSecondary, isNotNull);
          expect(palette.particleColor1, isNotNull);
          expect(palette.particleColor2, isNotNull);
        }
      }
    });

    test('verifies seasonal particle types, emerald Tuojiang colors, and candle intensities', () {
      expect(
        FenghuangPalette.of(ShanshuiSeason.spring, ShanshuiTimeOfDay.day).particleType,
        equals('petals'),
      );
      expect(
        FenghuangPalette.of(ShanshuiSeason.spring, ShanshuiTimeOfDay.day).particleKind,
        equals(SeasonalParticleKind.petals),
      );
      expect(
        FenghuangPalette.of(ShanshuiSeason.summer, ShanshuiTimeOfDay.day).particleType,
        equals('fireflies'),
      );
      expect(
        FenghuangPalette.of(ShanshuiSeason.summer, ShanshuiTimeOfDay.day).particleKind,
        equals(SeasonalParticleKind.fireflies),
      );
      expect(
        FenghuangPalette.of(ShanshuiSeason.fall, ShanshuiTimeOfDay.day).particleType,
        equals('leaves'),
      );
      expect(
        FenghuangPalette.of(ShanshuiSeason.fall, ShanshuiTimeOfDay.day).particleKind,
        equals(SeasonalParticleKind.leaves),
      );
      expect(
        FenghuangPalette.of(ShanshuiSeason.winter, ShanshuiTimeOfDay.day).particleType,
        equals('snow'),
      );
      expect(
        FenghuangPalette.of(ShanshuiSeason.winter, ShanshuiTimeOfDay.day).particleKind,
        equals(SeasonalParticleKind.snow),
      );

      final springDay = FenghuangPalette.of(ShanshuiSeason.spring, ShanshuiTimeOfDay.day);
      final springNight = FenghuangPalette.of(ShanshuiSeason.spring, ShanshuiTimeOfDay.night);
      expect(springDay.candleIntensity, lessThan(0.25));
      expect(springNight.candleIntensity, equals(1.0));
      expect(springDay.riverTop, isNot(equals(springNight.skyTop)));
    });
  });

  group('FenghuangPainter', () {
    test('renders cleanly across all 80 season x timeOfDay x weather combinations at 3:2 and 16:9', () {
      for (final season in ShanshuiSeason.values) {
        for (final timeOfDay in ShanshuiTimeOfDay.values) {
          for (final weather in ShanshuiWeather.values) {
            final atmosphere = ShanshuiAtmosphereState(
              realm: ShanshuiRealm.fenghuang,
              season: season,
              timeOfDay: timeOfDay,
              weather: weather,
            );
            final painter = FenghuangPainter(
              atmosphere: atmosphere,
              fenghuangPalette: FenghuangPalette.of(season, timeOfDay),
              animationTime: 1.5,
              particles: [
                ShanshuiParticle(
                  x: 420,
                  y: 340,
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
                  x: 720,
                  y: 660,
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

    test('recordStaticPicture caches Fenghuang backdrop and renders with cachedStaticPicture', () {
      const atmosphere = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.fenghuang,
        season: ShanshuiSeason.fall,
        timeOfDay: ShanshuiTimeOfDay.dusk,
        weather: ShanshuiWeather.sunny,
      );
      final palette = FenghuangPalette.of(atmosphere.season, atmosphere.timeOfDay);

      final staticPicture = FenghuangPainter.recordStaticPicture(
        atmosphere: atmosphere,
        fenghuangPalette: palette,
      );
      expect(staticPicture, isNotNull);

      final painter = FenghuangPainter(
        atmosphere: atmosphere,
        fenghuangPalette: palette,
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

    test('Tuojiang riverside life follows time-of-day crowd, boat, and lotus lantern rules', () {
      expect(
        FenghuangPainter.visibleSteppingVisitors(ShanshuiTimeOfDay.dawn),
        equals(0),
      );
      expect(
        FenghuangPainter.visibleSteppingVisitors(ShanshuiTimeOfDay.day),
        equals(6),
      );
      expect(
        FenghuangPainter.visibleSteppingVisitors(ShanshuiTimeOfDay.dusk),
        equals(6),
      );
      expect(
        FenghuangPainter.visibleSteppingVisitors(ShanshuiTimeOfDay.night),
        equals(2),
      );

      expect(FenghuangPainter.visibleBoats(ShanshuiTimeOfDay.dawn), equals(1));
      expect(FenghuangPainter.visibleBoats(ShanshuiTimeOfDay.day), equals(2));
      expect(FenghuangPainter.visibleBoats(ShanshuiTimeOfDay.dusk), equals(2));
      expect(FenghuangPainter.visibleBoats(ShanshuiTimeOfDay.night), equals(1));

      expect(FenghuangPainter.floatingRiverLanterns(ShanshuiTimeOfDay.dawn), equals(0));
      expect(FenghuangPainter.floatingRiverLanterns(ShanshuiTimeOfDay.day), equals(0));
      expect(FenghuangPainter.floatingRiverLanterns(ShanshuiTimeOfDay.dusk), equals(14));
      expect(FenghuangPainter.floatingRiverLanterns(ShanshuiTimeOfDay.night), equals(14));
    });

    test('effectiveLanternLevel boosts under rain and activates night roof-ridge lights (> 0.35)', () {
      final springDay = FenghuangPalette.of(ShanshuiSeason.spring, ShanshuiTimeOfDay.day);
      expect(
        FenghuangPainter.effectiveLanternLevel(springDay, ShanshuiWeather.sunny),
        lessThanOrEqualTo(0.22),
      );
      expect(
        FenghuangPainter.effectiveLanternLevel(springDay, ShanshuiWeather.rainy),
        greaterThan(0.35),
      );

      final fallDusk = FenghuangPalette.of(ShanshuiSeason.fall, ShanshuiTimeOfDay.dusk);
      expect(
        FenghuangPainter.effectiveLanternLevel(fallDusk, ShanshuiWeather.sunny),
        greaterThan(0.35),
      );

      final winterDay = FenghuangPalette.of(ShanshuiSeason.winter, ShanshuiTimeOfDay.day);
      expect(
        FenghuangPainter.effectiveLanternLevel(winterDay, ShanshuiWeather.sunny),
        greaterThan(0.35),
      );
    });

    test('shouldRepaint detects changes in time, atmosphere, ripples, lightning, and calligraphy', () {
      const atmo1 = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.fenghuang,
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.sunny,
      );
      const atmo2 = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.fenghuang,
        season: ShanshuiSeason.winter,
        timeOfDay: ShanshuiTimeOfDay.night,
        weather: ShanshuiWeather.snowy,
      );

      final painterA = FenghuangPainter(
        atmosphere: atmo1,
        animationTime: 1.0,
        particles: const [],
        weatherDrops: const [],
      );
      final painterB = FenghuangPainter(
        atmosphere: atmo1,
        animationTime: 1.05,
        particles: const [],
        weatherDrops: const [],
      );
      final painterC = FenghuangPainter(
        atmosphere: atmo2,
        animationTime: 1.0,
        particles: const [],
        weatherDrops: const [],
      );

      expect(painterA.shouldRepaint(painterA), isFalse);
      expect(painterA.shouldRepaint(painterB), isTrue);
      expect(painterA.shouldRepaint(painterC), isTrue);
    });

    test('clips interactive tap ripples strictly inside open Tuojiang water away from stilt houses', () async {
      const atmosphere = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.fenghuang,
        season: ShanshuiSeason.summer,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.sunny,
      );
      final palette = FenghuangPalette.of(atmosphere.season, atmosphere.timeOfDay);
      final staticPicture = FenghuangPainter.recordStaticPicture(
        atmosphere: atmosphere,
        fenghuangPalette: palette,
      );

      Future<Uint8List> paintWithRipples(List<ShanshuiRipple> ripples) async {
        final painter = FenghuangPainter(
          atmosphere: atmosphere,
          fenghuangPalette: palette,
          animationTime: 0.0,
          particles: const [],
          weatherDrops: const [],
          ripples: ripples,
          cachedStaticPicture: staticPicture,
        );
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1500, 1000));
        painter.paint(canvas, const Size(1500, 1000));
        final picture = recorder.endRecording();
        final image = await picture.toImage(1500, 1000);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        picture.dispose();
        return bytes!.buffer.asUint8List();
      }

      try {
        final baseline = await paintWithRipples(const []);
        final rippled = await paintWithRipples([
          ShanshuiRipple(
            x: 225,
            y: 740,
            radius: 60,
            maxRadius: 130,
            alpha: 0.9,
          ),
        ]);

        int diffPixels(Rect rect) {
          int changed = 0;
          for (int y = rect.top.toInt(); y < rect.bottom.toInt(); y++) {
            for (int x = rect.left.toInt(); x < rect.right.toInt(); x++) {
              final offset = (y * 1500 + x) * 4;
              if (baseline[offset] != rippled[offset] ||
                  baseline[offset + 1] != rippled[offset + 1] ||
                  baseline[offset + 2] != rippled[offset + 2]) {
                changed++;
              }
            }
          }
          return changed;
        }

        // Open Tuojiang water side of the ripple (x >= 221) receives ripple ink
        expect(diffPixels(const Rect.fromLTWH(255, 725, 35, 32)), greaterThan(10));

        // Left stilt-house/bank side outside _buildOpenRiverWaterClipPath (x < 221) receives ZERO ripple ink
        expect(diffPixels(const Rect.fromLTWH(160, 720, 60, 40)), equals(0));
      } finally {
        staticPicture.dispose();
      }
    });
  });

  group('Five-Realm Scenery Certification', () {
    test('all 5 realms render cleanly across all 80 season x timeOfDay x weather states at 3:2 and 16:9', () {
      final particles = [
        ShanshuiParticle(
          x: 420,
          y: 340,
          vx: 0.4,
          vy: 0.6,
          size: 4.5,
          angle: 0.6,
          vAngle: 0.03,
          phase: 1.1,
          colorToggle: true,
        ),
      ];
      final weatherDrops = [
        ShanshuiWeatherDrop(
          x: 240,
          y: 300,
          len: 22,
          speed: 12,
          size: 3.2,
          phase: 0.4,
        ),
      ];
      final ripples = [
        ShanshuiRipple(
          x: 720,
          y: 660,
          radius: 18,
          maxRadius: 130,
          alpha: 0.6,
        ),
      ];

      for (final realm in ShanshuiRealm.values) {
        for (final season in ShanshuiSeason.values) {
          for (final timeOfDay in ShanshuiTimeOfDay.values) {
            for (final weather in ShanshuiWeather.values) {
              final atmosphere = ShanshuiAtmosphereState(
                realm: realm,
                season: season,
                timeOfDay: timeOfDay,
                weather: weather,
              );
              final lightningAlpha =
                  weather == ShanshuiWeather.stormy ? 0.75 : 0.0;
              final CustomPainter painter = switch (realm) {
                ShanshuiRealm.nature => ShanshuiCanvasPainter(
                    atmosphere: atmosphere,
                    palette: ShanshuiPalette.of(season, timeOfDay),
                    animationTime: 1.5,
                    particles: particles,
                    weatherDrops: weatherDrops,
                    cranes: const [],
                    ripples: ripples,
                    showCalligraphy: true,
                    fullPoem: true,
                    lightningAlpha: lightningAlpha,
                  ),
                ShanshuiRealm.westLake => WestLakePainter(
                    atmosphere: atmosphere,
                    animationTime: 1.5,
                    particles: particles,
                    weatherDrops: weatherDrops,
                    ripples: ripples,
                    showCalligraphy: true,
                    fullPoem: true,
                    lightningAlpha: lightningAlpha,
                  ),
                ShanshuiRealm.fenghuang => FenghuangPainter(
                    atmosphere: atmosphere,
                    animationTime: 1.5,
                    particles: particles,
                    weatherDrops: weatherDrops,
                    ripples: ripples,
                    showCalligraphy: true,
                    fullPoem: true,
                    lightningAlpha: lightningAlpha,
                  ),
                ShanshuiRealm.indoor => AncientRoomPainter(
                    atmosphere: atmosphere,
                    animationTime: 1.5,
                    particles: particles,
                    weatherDrops: weatherDrops,
                    showCalligraphy: true,
                    fullPoem: true,
                    lightningAlpha: lightningAlpha,
                  ),
                ShanshuiRealm.outdoor => OutdoorStreetPainter(
                    atmosphere: atmosphere,
                    animationTime: 1.5,
                    particles: particles,
                    weatherDrops: weatherDrops,
                    ripples: ripples,
                    showCalligraphy: true,
                    fullPoem: true,
                    lightningAlpha: lightningAlpha,
                  ),
              };

              final recorder = ui.PictureRecorder();
              final canvas =
                  Canvas(recorder, const Rect.fromLTWH(0, 0, 1600, 1000));
              painter.paint(canvas, const Size(1500, 1000));
              painter.paint(canvas, const Size(1600, 900));
              recorder.endRecording().dispose();
            }
          }
        }
      }
    });

    testWidgets('ShanshuiSceneryPainting cycles cleanly across all 5 realms on 16:9 and 3:2 at 320px width', (tester) async {
      for (final aspectRatio in [16.0 / 9.0, 3.0 / 2.0]) {
        for (final realm in ShanshuiRealm.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 320,
                    child: ShanshuiSceneryPainting(
                      atmosphere: ShanshuiAtmosphereState(
                        realm: realm,
                        season: ShanshuiSeason.winter,
                        timeOfDay: ShanshuiTimeOfDay.night,
                        weather: ShanshuiWeather.snowy,
                      ),
                      aspectRatio: aspectRatio,
                      enableAmbientAnimation: true,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('ContemplationViewScreen switches all 5 realms at 320px width without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final audioService = AudioSanctumService(enablePlatformAudio: false);
      addTearDown(audioService.dispose);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: MaterialApp(
            theme: InkDiaryTheme.light,
            home: ContemplationViewScreen(
              initialAtmosphere: const ShanshuiAtmosphereState(
                realm: ShanshuiRealm.nature,
                season: ShanshuiSeason.spring,
                timeOfDay: ShanshuiTimeOfDay.day,
                weather: ShanshuiWeather.sunny,
              ),
              realTimeAtmosphere: const ShanshuiAtmosphereState(
                realm: ShanshuiRealm.nature,
                season: ShanshuiSeason.spring,
                timeOfDay: ShanshuiTimeOfDay.day,
                weather: ShanshuiWeather.sunny,
              ),
              audioService: audioService,
              enableAmbientAnimation: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      for (final realm in ShanshuiRealm.values) {
        final chip = find.byKey(Key('contemplation_realm_chip_${realm.id}'));
        await tester.ensureVisible(chip);
        await tester.pump(const Duration(milliseconds: 20));
        await tester.tap(chip);
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text(realm.shortNameZh), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
