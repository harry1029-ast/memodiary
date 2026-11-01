import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/scenery/painters/outdoor_street_painter.dart';
import 'package:memodiary/features/scenery/widgets/shanshui_canvas_painter.dart';
import 'package:memodiary/features/scenery/widgets/shanshui_scenery_painting.dart';

class _MockCustomPainter extends CustomPainter {
  final String label;
  const _MockCustomPainter(this.label);

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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

    testWidgets('dispatches through indoorPainterBuilder when indoor realm is active', (tester) async {
      bool indoorBuilderCalled = false;
      const atmosphere = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.indoor,
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
                  atmosphere: atmosphere,
                  enableAmbientAnimation: false,
                  indoorPainterBuilder: ({
                    required atmosphere,
                    required palette,
                    required animationTime,
                    required particles,
                    required weatherDrops,
                    required cranes,
                    required ripples,
                    required showCalligraphy,
                    required fullPoem,
                    required lightningAlpha,
                  }) {
                    indoorBuilderCalled = true;
                    return const _MockCustomPainter('indoor');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(indoorBuilderCalled, isTrue);

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AspectRatio),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.painter, isA<_MockCustomPainter>());
    });

    testWidgets('dispatches through outdoorPainterBuilder when outdoor realm is active', (tester) async {
      bool outdoorBuilderCalled = false;
      const atmosphere = ShanshuiAtmosphereState(
        realm: ShanshuiRealm.outdoor,
        season: ShanshuiSeason.summer,
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
                  atmosphere: atmosphere,
                  enableAmbientAnimation: false,
                  outdoorPainterBuilder: ({
                    required atmosphere,
                    required palette,
                    required animationTime,
                    required particles,
                    required weatherDrops,
                    required cranes,
                    required ripples,
                    required showCalligraphy,
                    required fullPoem,
                    required lightningAlpha,
                  }) {
                    outdoorBuilderCalled = true;
                    return const _MockCustomPainter('outdoor');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(outdoorBuilderCalled, isTrue);

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AspectRatio),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.painter, isA<_MockCustomPainter>());
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
  });
}
