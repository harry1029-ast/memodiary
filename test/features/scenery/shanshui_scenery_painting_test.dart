import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/scenery/painters/ancient_room_painter.dart';
import 'package:memodiary/features/scenery/painters/fenghuang_painter.dart';
import 'package:memodiary/features/scenery/painters/outdoor_street_painter.dart';
import 'package:memodiary/features/scenery/painters/west_lake_painter.dart';
import 'package:memodiary/features/scenery/widgets/shanshui_canvas_painter.dart';
import 'package:memodiary/features/scenery/widgets/shanshui_scenery_painting.dart';

void main() {
  group('ShanshuiSceneryPainting modular painter dispatch and interactions', () {
    testWidgets('dispatches to ShanshuiCanvasPainter for nature realm by default', (tester) async {
      const atmosphere = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.nature,
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.sunny,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: ShanshuiSceneryPainting(
                  atmosphere: atmosphere,
                  enableAmbientAnimation: false,
                ),
              ),
            ),
          ),
        ),
      );

      final customPaintFinder = find.byType(CustomPaint);
      expect(customPaintFinder, findsWidgets);

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AspectRatio),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.painter, isA<ShanshuiCanvasPainter>());
    });

    testWidgets('dispatches to AncientRoomPainter when indoor realm is active', (tester) async {
      const atmosphere = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.indoor,
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.sunny,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: ShanshuiSceneryPainting(
                  atmosphere: atmosphere,
                  enableAmbientAnimation: false,
                ),
              ),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AspectRatio),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.painter, isA<AncientRoomPainter>());
    });

    testWidgets('triggers petal swirls on indoor tap and ripples on nature tap', (tester) async {
      final stateKey = GlobalKey<ShanshuiSceneryPaintingState>();

      // Indoor tap
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: ShanshuiSceneryPainting(
                  key: stateKey,
                  atmosphere: const ShanshuiAtmosphereState(
                    realm: ShanshuiRealm.indoor,
                    season: ShanshuiSeason.spring,
                    timeOfDay: ShanshuiTimeOfDay.day,
                    weather: ShanshuiWeather.sunny,
                  ),
                  enableAmbientAnimation: false,
                ),
              ),
            ),
          ),
        ),
      );

      final initialParticles = stateKey.currentState!.particleCount;
      final initialRipples = stateKey.currentState!.rippleCount;

      await tester.tap(find.byType(ShanshuiSceneryPainting));
      await tester.pump();

      // Petals spawned, no water ripples in indoor
      expect(stateKey.currentState!.particleCount, greaterThan(initialParticles));
      expect(stateKey.currentState!.rippleCount, equals(initialRipples));

      // Rebuild with Nature
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: ShanshuiSceneryPainting(
                  key: stateKey,
                  atmosphere: const ShanshuiAtmosphereState(
                    realm: ShanshuiRealm.nature,
                    season: ShanshuiSeason.spring,
                    timeOfDay: ShanshuiTimeOfDay.day,
                    weather: ShanshuiWeather.sunny,
                  ),
                  enableAmbientAnimation: false,
                ),
              ),
            ),
          ),
        ),
      );

      final natureRipplesBefore = stateKey.currentState!.rippleCount;
      await tester.tap(find.byType(ShanshuiSceneryPainting));
      await tester.pump();

      // Lake ripples spawned in nature
      expect(stateKey.currentState!.rippleCount, greaterThan(natureRipplesBefore));

      // Rebuild with Outdoor
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: ShanshuiSceneryPainting(
                  key: stateKey,
                  atmosphere: const ShanshuiAtmosphereState(
                    realm: ShanshuiRealm.outdoor,
                    season: ShanshuiSeason.spring,
                    timeOfDay: ShanshuiTimeOfDay.day,
                    weather: ShanshuiWeather.sunny,
                  ),
                  enableAmbientAnimation: false,
                ),
              ),
            ),
          ),
        ),
      );

      final outdoorParticlesBefore = stateKey.currentState!.particleCount;
      final outdoorRipplesBefore = stateKey.currentState!.rippleCount;
      await tester.tap(find.byType(ShanshuiSceneryPainting));
      await tester.pump();

      // Both ripples and festive particles spawned on outdoor tap
      expect(stateKey.currentState!.rippleCount, greaterThan(outdoorRipplesBefore));
      expect(stateKey.currentState!.particleCount, greaterThan(outdoorParticlesBefore));
    });

    testWidgets('dispatches to OutdoorStreetPainter for outdoor realm by default', (tester) async {
      const atmosphere = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.outdoor,
        season: ShanshuiSeason.summer,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.sunny,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: ShanshuiSceneryPainting(
                  atmosphere: atmosphere,
                  enableAmbientAnimation: false,
                ),
              ),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AspectRatio),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.painter, isA<OutdoorStreetPainter>());
    });

    testWidgets('dispatches to WestLakePainter for westLake realm and clamps sky taps to y >= 520', (tester) async {
      final stateKey = GlobalKey<ShanshuiSceneryPaintingState>();
      const atmosphere = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.westLake,
        season: ShanshuiSeason.spring,
        timeOfDay: ShanshuiTimeOfDay.day,
        weather: ShanshuiWeather.sunny,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: ShanshuiSceneryPainting(
                  key: stateKey,
                  atmosphere: atmosphere,
                  enableAmbientAnimation: false,
                ),
              ),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AspectRatio),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.painter, isA<WestLakePainter>());

      // Tap near top sky (y=20 out of 200 -> normalized y=100) and verify ripple is clamped to y >= 520
      final paintingTopLeft = tester.getTopLeft(find.byType(ShanshuiSceneryPainting));
      final particlesBefore = stateKey.currentState!.particleCount;
      final ripplesBefore = stateKey.currentState!.rippleCount;

      await tester.tapAt(paintingTopLeft + const Offset(150, 20));
      await tester.pump();

      expect(stateKey.currentState!.rippleCount, equals(ripplesBefore + 1));
      expect(stateKey.currentState!.particleCount, greaterThan(particlesBefore));
      expect(stateKey.currentState!.ripples.last.y, greaterThanOrEqualTo(520.0));
    });

    testWidgets('dispatches to FenghuangPainter for fenghuang realm and clamps sky taps to y >= 555', (tester) async {
      final stateKey = GlobalKey<ShanshuiSceneryPaintingState>();
      const atmosphere = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.fenghuang,
        season: ShanshuiSeason.summer,
        timeOfDay: ShanshuiTimeOfDay.dusk,
        weather: ShanshuiWeather.sunny,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: ShanshuiSceneryPainting(
                  key: stateKey,
                  atmosphere: atmosphere,
                  enableAmbientAnimation: false,
                ),
              ),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AspectRatio),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.painter, isA<FenghuangPainter>());

      // Tap near top sky (y=20 out of 200 -> normalized y=100) and verify ripple is clamped to y >= 555
      final paintingTopLeft = tester.getTopLeft(find.byType(ShanshuiSceneryPainting));
      final particlesBefore = stateKey.currentState!.particleCount;
      final ripplesBefore = stateKey.currentState!.rippleCount;

      await tester.tapAt(paintingTopLeft + const Offset(150, 20));
      await tester.pump();

      expect(stateKey.currentState!.rippleCount, equals(ripplesBefore + 1));
      expect(stateKey.currentState!.particleCount, greaterThan(particlesBefore));
      expect(stateKey.currentState!.ripples.last.y, greaterThanOrEqualTo(555.0));
    });
  });
}
