import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/services/audio_sanctum_service.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/scenery/screens/contemplation_view_screen.dart';
import 'package:memodiary/features/scenery/widgets/shanshui_scenery_painting.dart';

void main() {
  group('ContemplationViewScreen Widget Tests', () {
    const baseSpringDayAtmosphere = ShanshuiAtmosphereState(
      season: ShanshuiSeason.spring,
      timeOfDay: ShanshuiTimeOfDay.day,
      weather: ShanshuiWeather.sunny,
      isManualPreview: false,
    );

    Future<void> pumpContemplationViewScreen(
      WidgetTester tester, {
      ShanshuiAtmosphereState initialAtmosphere = baseSpringDayAtmosphere,
      ShanshuiAtmosphereState realTimeAtmosphere = baseSpringDayAtmosphere,
      AudioSanctumService? audioService,
      bool enableAmbientAnimation = true,
    }) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: ContemplationViewScreen(
            initialAtmosphere: initialAtmosphere,
            realTimeAtmosphere: realTimeAtmosphere,
            audioService: audioService ??
                AudioSanctumService(enablePlatformAudio: false),
            enableAmbientAnimation: enableAmbientAnimation,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets(
      'renders 3:2 Shanshui canvas, season header, poetic couplet, and hides sync button when in real time',
      (tester) async {
        await pumpContemplationViewScreen(tester);

        expect(find.byKey(const Key('contemplation_lake_canvas')), findsOneWidget);
        expect(find.textContaining('春 · 桃夭青绿'), findsOneWidget);
        expect(find.textContaining('水面初平云脚低，几处早莺争暖树'), findsOneWidget);
        expect(find.text('春和景明'), findsOneWidget);

        // In real-time sync state, the manual reset pill should not be shown
        expect(
          find.byKey(const Key('contemplation_sync_realtime_button')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'switching season, time, or weather previews atmosphere and reveals 恢复实时 reset button',
      (tester) async {
        await pumpContemplationViewScreen(tester);

        // Switch to Winter
        await tester.tap(find.byKey(const Key('contemplation_season_chip_winter')));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.textContaining('冬 · 寒江瑞雪'), findsOneWidget);
        expect(find.textContaining('孤舟蓑笠翁，独钓寒江雪'), findsOneWidget);
        expect(
          find.byKey(const Key('contemplation_sync_realtime_button')),
          findsOneWidget,
        );

        // Switch to Night & Stormy
        await tester.tap(find.byKey(const Key('contemplation_time_chip_night')));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byKey(const Key('contemplation_weather_chip_stormy')));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.textContaining('风雷骤雨'), findsOneWidget);

        // Tap 恢复实时 to restore real-time Spring Day Sunny
        await tester.tap(
          find.byKey(const Key('contemplation_sync_realtime_button')),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.textContaining('春 · 桃夭青绿'), findsOneWidget);
        expect(
          find.byKey(const Key('contemplation_sync_realtime_button')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'tapping lake canvas spawns interactive water ripples cleanly across animation frames',
      (tester) async {
        await pumpContemplationViewScreen(tester);

        final canvasFinder = find.byKey(const Key('contemplation_lake_canvas'));
        final canvasCenter = tester.getCenter(canvasFinder);

        // Tap in the lower lake region of the 3:2 canvas
        await tester.tapAt(Offset(canvasCenter.dx, canvasCenter.dy + 80));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'soundscape starts muted by default, pairs contextually when toggled, and pauses on app background',
      (tester) async {
        final audioService = AudioSanctumService(enablePlatformAudio: false);
        addTearDown(audioService.dispose);

        await pumpContemplationViewScreen(
          tester,
          audioService: audioService,
        );

        // Must be muted by default
        expect(audioService.isPlaying, isFalse);

        // Toggle audio on -> Spring Day Sunny pairs with bambooBreeze
        await tester.tap(find.byKey(const Key('contemplation_soundscape_button')));
        await tester.pump(const Duration(milliseconds: 100));

        expect(audioService.isPlaying, isTrue);
        expect(audioService.activePreset, equals(SoundscapePreset.bambooBreeze));

        // Switch weather to Rainy -> dynamically updates active soundscape to gentleRain
        await tester.tap(find.byKey(const Key('contemplation_weather_chip_rainy')));
        await tester.pump(const Duration(milliseconds: 100));

        expect(audioService.isPlaying, isTrue);
        expect(audioService.activePreset, equals(SoundscapePreset.gentleRain));

        // Simulate app entering background -> pauses soundscape and ticker
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();

        expect(audioService.isPlaying, isFalse);
      },
    );

    testWidgets(
      'ShanshuiSceneryPainting suspends animation ticker when isVisible is false',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ShanshuiSceneryPainting(
                atmosphere: ShanshuiAtmosphereState(
                  season: ShanshuiSeason.spring,
                  timeOfDay: ShanshuiTimeOfDay.day,
                  weather: ShanshuiWeather.sunny,
                ),
                enableAmbientAnimation: true,
                isVisible: false,
              ),
            ),
          ),
        );

        final state = tester.state<ShanshuiSceneryPaintingState>(
          find.byType(ShanshuiSceneryPainting),
        );
        expect(state.isAnimating, isFalse);
      },
    );
  });
}

