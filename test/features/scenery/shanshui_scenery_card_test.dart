import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/scenery/services/scenery_settings_service.dart';
import 'package:memodiary/features/scenery/widgets/shanshui_scenery_card.dart';
import '../../helpers/mock_secure_storage.dart';

void main() {
  group('ShanshuiSceneryCard Widget Tests', () {
    late MockSecureStorage mockStorage;
    late ScenerySettingsService settingsService;

    setUp(() {
      mockStorage = MockSecureStorage();
      settingsService = ScenerySettingsService(storage: mockStorage);
    });

    Widget buildTestHarness({
      required ShanshuiAtmosphereState atmosphere,
      ShanshuiAtmosphereState? realTimeAtmosphere,
      VoidCallback? onOpenContemplation,
      ValueChanged<SceneryRealmPreference>? onRealmPreferenceChanged,
      bool? enableAmbientAnimation = false,
      bool isVisible = true,
      double width = 400,
    }) {
      return MaterialApp(
        theme: InkDiaryTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: ShanshuiSceneryCard(
                atmosphere: atmosphere,
                realTimeAtmosphere: realTimeAtmosphere,
                onOpenContemplation: onOpenContemplation ?? () {},
                onRealmPreferenceChanged: onRealmPreferenceChanged,
                settingsService: settingsService,
                enableAmbientAnimation: enableAmbientAnimation,
                isVisible: isVisible,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'displays realm seasonal title, seal, and 随文入境 attribution badge when inferred',
      (tester) async {
        const indoorInferredAtmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.indoor,
          season: ShanshuiSeason.spring,
          timeOfDay: ShanshuiTimeOfDay.day,
          weather: ShanshuiWeather.sunny,
          isJournalInferred: true,
        );

        await tester.pumpWidget(
          buildTestHarness(atmosphere: indoorInferredAtmosphere),
        );
        await tester.pumpAndSettle();

        // Seasonal title for indoor spring: 春 · 桃夭茶寮
        expect(find.text('春 · 桃夭茶寮'), findsOneWidget);
        // Seasonal seal for spring: 春 · 桃夭
        expect(find.text('春 · 桃夭'), findsOneWidget);
        // Attribution badge
        expect(find.byKey(const Key('scenery_realm_badge')), findsOneWidget);
        expect(find.text('自动 · 室内'), findsOneWidget);
      },
    );

    testWidgets(
      'displays active realm label when manually selected/pinned (isJournalInferred is false)',
      (tester) async {
        const outdoorManualAtmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.outdoor,
          season: ShanshuiSeason.summer,
          timeOfDay: ShanshuiTimeOfDay.dusk,
          weather: ShanshuiWeather.sunny,
          isJournalInferred: false,
        );

        await tester.pumpWidget(
          buildTestHarness(atmosphere: outdoorManualAtmosphere),
        );
        await tester.pumpAndSettle();

        // Seasonal title for outdoor summer: 夏 · 翠峰槐夏市
        expect(find.text('夏 · 翠峰槐夏市'), findsOneWidget);
        // Realm badge displays active realm label without 自动 prefix
        expect(find.byKey(const Key('scenery_realm_badge')), findsOneWidget);
        expect(find.text('街市'), findsOneWidget);
      },
    );

    testWidgets(
      'collapsed strip displays seasonal seal and realm badge',
      (tester) async {
        // Pre-configure collapsed in settings
        mockStorage.data['memodiary_scenery_card_collapsed'] = 'true';

        const indoorAtmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.indoor,
          season: ShanshuiSeason.winter,
          timeOfDay: ShanshuiTimeOfDay.night,
          weather: ShanshuiWeather.snowy,
          isJournalInferred: true,
        );

        await tester.pumpWidget(buildTestHarness(atmosphere: indoorAtmosphere));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('scenery_card_collapsed')), findsOneWidget);
        expect(find.byKey(const Key('scenery_realm_badge')), findsOneWidget);
        expect(find.text('自动 · 室内'), findsOneWidget);
        expect(find.text('冬 · 温炉'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping realm badge opens 1-tap realm switcher modal bottom sheet and persists choice',
      (tester) async {
        SceneryRealmPreference? changedPref;
        const initialAtmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.nature,
          season: ShanshuiSeason.spring,
          timeOfDay: ShanshuiTimeOfDay.day,
          weather: ShanshuiWeather.sunny,
          isJournalInferred: false,
        );

        await tester.pumpWidget(
          buildTestHarness(
            atmosphere: initialAtmosphere,
            onRealmPreferenceChanged: (pref) => changedPref = pref,
          ),
        );
        await tester.pumpAndSettle();

        // Tap the realm badge
        await tester.tap(find.byKey(const Key('scenery_realm_badge')));
        await tester.pumpAndSettle();

        // Verify bottom sheet options
        expect(find.byKey(const Key('scenery_realm_option_auto')), findsOneWidget);
        expect(find.byKey(const Key('scenery_realm_option_nature')), findsOneWidget);
        expect(find.byKey(const Key('scenery_realm_option_indoor')), findsOneWidget);
        expect(find.byKey(const Key('scenery_realm_option_outdoor')), findsOneWidget);

        expect(
          find.descendant(
            of: find.byKey(const Key('scenery_realm_option_auto')),
            matching: find.text('自动'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('scenery_realm_option_nature')),
            matching: find.text('山水'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('scenery_realm_option_indoor')),
            matching: find.text('室内'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('scenery_realm_option_outdoor')),
            matching: find.text('街市'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Auto'), findsNothing);
        expect(find.textContaining('Indoor'), findsNothing);

        // Tap Indoor option
        await tester.tap(find.byKey(const Key('scenery_realm_option_indoor')));
        await tester.pumpAndSettle();

        // Sheet closed
        expect(find.byKey(const Key('scenery_realm_option_indoor')), findsNothing);

        // Callback invoked & persisted
        expect(changedPref, equals(SceneryRealmPreference.indoor));
        expect(mockStorage.data['memodiary_scenery_realm_preference'], equals('indoor'));

        // Card immediately updated
        expect(find.text('春 · 桃夭茶寮'), findsOneWidget);
        expect(find.text('室内'), findsOneWidget);
      },
    );

    testWidgets(
      'reverting to Auto immediately restores inferred realm from realTimeAtmosphere without stale manual realm',
      (tester) async {
        SceneryRealmPreference? changedPref;
        const initialAtmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.outdoor,
          season: ShanshuiSeason.spring,
          timeOfDay: ShanshuiTimeOfDay.day,
          weather: ShanshuiWeather.sunny,
          isJournalInferred: true,
        );
        const realTimeAtmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.outdoor,
          season: ShanshuiSeason.spring,
          timeOfDay: ShanshuiTimeOfDay.day,
          weather: ShanshuiWeather.sunny,
          isJournalInferred: true,
        );

        await tester.pumpWidget(
          buildTestHarness(
            atmosphere: initialAtmosphere,
            realTimeAtmosphere: realTimeAtmosphere,
            onRealmPreferenceChanged: (pref) => changedPref = pref,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('自动 · 街市'), findsOneWidget);

        // 1. Manually select Indoor
        await tester.tap(find.byKey(const Key('scenery_realm_badge')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('scenery_realm_option_indoor')));
        await tester.pumpAndSettle();

        expect(changedPref, equals(SceneryRealmPreference.indoor));
        expect(find.text('室内'), findsOneWidget);
        expect(find.text('自动 · 街市'), findsNothing);

        // 2. Select Auto again
        await tester.tap(find.byKey(const Key('scenery_realm_badge')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('scenery_realm_option_auto')));
        await tester.pumpAndSettle();

        expect(changedPref, equals(SceneryRealmPreference.auto));
        expect(mockStorage.data['memodiary_scenery_realm_preference'], equals('auto'));

        // Card immediately resets back to real-time inferred realm
        expect(find.text('自动 · 街市'), findsOneWidget);
        expect(find.text('室内'), findsNothing);
      },
    );

    testWidgets(
      'tapping canvas tap target triggers onOpenContemplation without gesture conflict',
      (tester) async {
        bool contemplationOpened = false;
        const atmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.nature,
          season: ShanshuiSeason.spring,
          timeOfDay: ShanshuiTimeOfDay.day,
          weather: ShanshuiWeather.sunny,
        );

        await tester.pumpWidget(
          buildTestHarness(
            atmosphere: atmosphere,
            onOpenContemplation: () => contemplationOpened = true,
          ),
        );
        await tester.pumpAndSettle();

        // Tapping the main canvas target should open contemplation view
        await tester.tap(find.byKey(const Key('scenery_canvas_tap_target')));
        await tester.pumpAndSettle();

        expect(contemplationOpened, isTrue);
      },
    );

    testWidgets(
      'renders cleanly down to 320px width without layout overflow',
      (tester) async {
        const indoorInferred = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.indoor,
          season: ShanshuiSeason.winter,
          timeOfDay: ShanshuiTimeOfDay.night,
          weather: ShanshuiWeather.snowy,
          isJournalInferred: true,
        );

        await tester.pumpWidget(
          buildTestHarness(
            atmosphere: indoorInferred,
            width: 320,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('scenery_realm_badge')), findsOneWidget);
      },
    );

    testWidgets(
      'renders unobstructed window frame and pull-cord clear of top overlay pills',
      (tester) async {
        const atmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.nature,
          season: ShanshuiSeason.fall,
          timeOfDay: ShanshuiTimeOfDay.night,
          weather: ShanshuiWeather.sunny,
          isJournalInferred: false,
        );

        await tester.pumpWidget(buildTestHarness(atmosphere: atmosphere));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('scenery_window_frame')), findsOneWidget);
        expect(find.byKey(const Key('scenery_pull_cord_handle')), findsOneWidget);
        expect(find.byKey(const Key('scenery_pull_cord_tag')), findsOneWidget);
        expect(find.textContaining('下拉垂帘'), findsOneWidget);
        expect(find.byKey(const Key('thought_spark_dock')), findsNothing);
        expect(find.byKey(const Key('thought_spark_reveal_button')), findsNothing);

        final cordRect = tester.getRect(find.byKey(const Key('scenery_pull_cord_handle')));
        final realmRect = tester.getRect(find.byKey(const Key('scenery_realm_badge')));
        expect(cordRect.right, lessThanOrEqualTo(realmRect.left));
      },
    );

    testWidgets(
      'tapping pull-cord executes two-stage blind drop then shrinks into 44dp collapsed bamboo bar and persists state',
      (tester) async {
        const atmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.nature,
          season: ShanshuiSeason.fall,
          timeOfDay: ShanshuiTimeOfDay.night,
          weather: ShanshuiWeather.sunny,
          isJournalInferred: false,
        );

        await tester.pumpWidget(buildTestHarness(atmosphere: atmosphere));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('scenery_card_expanded')), findsOneWidget);
        expect(find.byKey(const Key('scenery_card_collapsed')), findsNothing);

        await tester.tap(find.byKey(const Key('scenery_pull_cord_handle')));
        await tester.pump();
        // Mid-stage 1 (~250ms): blind is unrolling, window height is still > 44dp
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byKey(const Key('scenery_bamboo_blind_curtain')), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const Key('scenery_card_expanded'))).height,
          greaterThan(100),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('scenery_card_collapsed')), findsOneWidget);
        expect(find.byKey(const Key('scenery_collapsed_blind_bar')), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const Key('scenery_card_collapsed'))).height,
          equals(44.0),
        );
        expect(find.textContaining('拽绳卷帘'), findsOneWidget);
        expect(find.textContaining('竹帘低垂'), findsOneWidget);
        expect(mockStorage.data['memodiary_scenery_card_collapsed'], equals('true'));

        // Tapping the collapsed bar restores expanded state
        await tester.tap(find.byKey(const Key('scenery_collapsed_blind_bar')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('scenery_card_expanded')), findsOneWidget);
        expect(find.byKey(const Key('scenery_card_collapsed')), findsNothing);
        expect(mockStorage.data['memodiary_scenery_card_collapsed'], equals('false'));
      },
    );

    testWidgets(
      'tapping 44dp collapsed bamboo bar expands window first then rolls blind upward and persists state',
      (tester) async {
        mockStorage.data['memodiary_scenery_card_collapsed'] = 'true';

        const atmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.nature,
          season: ShanshuiSeason.spring,
          timeOfDay: ShanshuiTimeOfDay.day,
          weather: ShanshuiWeather.sunny,
          isJournalInferred: false,
        );

        await tester.pumpWidget(buildTestHarness(atmosphere: atmosphere));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('scenery_card_collapsed')), findsOneWidget);

        await tester.tap(find.byKey(const Key('scenery_collapsed_blind_bar')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 260));
        expect(find.byKey(const Key('scenery_bamboo_blind_curtain')), findsOneWidget);

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('scenery_card_expanded')), findsOneWidget);
        expect(find.byKey(const Key('scenery_card_collapsed')), findsNothing);
        expect(mockStorage.data['memodiary_scenery_card_collapsed'], equals('false'));
      },
    );

    testWidgets(
      'short drag on pull-cord (< 36dp) springs cord and blind back up without collapsing',
      (tester) async {
        const atmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.nature,
          season: ShanshuiSeason.spring,
          timeOfDay: ShanshuiTimeOfDay.day,
          weather: ShanshuiWeather.sunny,
        );

        await tester.pumpWidget(buildTestHarness(atmosphere: atmosphere));
        await tester.pumpAndSettle();

        final cordCenter = tester.getCenter(find.byKey(const Key('scenery_pull_cord_handle')));
        final gesture = await tester.startGesture(cordCenter);
        await gesture.moveBy(const Offset(0, 20));
        await tester.pump();

        expect(find.textContaining('继续下拉'), findsOneWidget);

        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('scenery_card_expanded')), findsOneWidget);
        expect(find.byKey(const Key('scenery_card_collapsed')), findsNothing);
        expect(find.textContaining('下拉垂帘'), findsOneWidget);
        expect(mockStorage.data['memodiary_scenery_card_collapsed'], isNot(equals('true')));
      },
    );

    testWidgets(
      'drag on pull-cord >= 36dp updates tag to 松手收窗 ✓ and collapses window on release',
      (tester) async {
        const atmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.nature,
          season: ShanshuiSeason.fall,
          timeOfDay: ShanshuiTimeOfDay.night,
          weather: ShanshuiWeather.sunny,
        );

        await tester.pumpWidget(buildTestHarness(atmosphere: atmosphere));
        await tester.pumpAndSettle();

        final cordCenter = tester.getCenter(find.byKey(const Key('scenery_pull_cord_handle')));
        final gesture = await tester.startGesture(cordCenter);
        await gesture.moveBy(const Offset(0, 44));
        await tester.pump();

        expect(find.text('松手收窗 ✓'), findsOneWidget);

        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('scenery_card_collapsed')), findsOneWidget);
        expect(find.byKey(const Key('scenery_card_expanded')), findsNothing);
        expect(mockStorage.data['memodiary_scenery_card_collapsed'], equals('true'));
      },
    );

    testWidgets(
      'tapping realm badge on collapsed 44dp bar opens realm switcher without expanding window',
      (tester) async {
        mockStorage.data['memodiary_scenery_card_collapsed'] = 'true';

        const atmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.nature,
          season: ShanshuiSeason.spring,
          timeOfDay: ShanshuiTimeOfDay.day,
          weather: ShanshuiWeather.sunny,
        );

        await tester.pumpWidget(buildTestHarness(atmosphere: atmosphere));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('scenery_realm_badge')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('scenery_realm_option_indoor')), findsOneWidget);
        await tester.tap(find.byKey(const Key('scenery_realm_option_indoor')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('scenery_card_collapsed')), findsOneWidget);
        expect(find.text('室内'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping lower third of 16:9 canvas triggers onOpenContemplation without ThoughtSparkDock obstruction',
      (tester) async {
        bool contemplationOpened = false;
        const atmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.nature,
          season: ShanshuiSeason.summer,
          timeOfDay: ShanshuiTimeOfDay.day,
          weather: ShanshuiWeather.sunny,
        );

        await tester.pumpWidget(
          buildTestHarness(
            atmosphere: atmosphere,
            onOpenContemplation: () => contemplationOpened = true,
          ),
        );
        await tester.pumpAndSettle();

        final targetRect = tester.getRect(
          find.byKey(const Key('scenery_canvas_tap_target')),
        );
        final lowerThirdTapPoint = Offset(
          targetRect.center.dx,
          targetRect.bottom - 18,
        );
        await tester.tapAt(lowerThirdTapPoint);
        await tester.pumpAndSettle();

        expect(contemplationOpened, isTrue);
      },
    );

    testWidgets(
      'collapsed 44dp bar renders cleanly down to 320px width without overflow',
      (tester) async {
        mockStorage.data['memodiary_scenery_card_collapsed'] = 'true';

        const atmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.indoor,
          season: ShanshuiSeason.winter,
          timeOfDay: ShanshuiTimeOfDay.night,
          weather: ShanshuiWeather.snowy,
          isJournalInferred: true,
        );

        await tester.pumpWidget(
          buildTestHarness(atmosphere: atmosphere, width: 320),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('scenery_card_collapsed')), findsOneWidget);
      },
    );

    testWidgets(
      'pull-cord ambient idle sway runs when enableAmbientAnimation is true and suspends when isVisible is false',
      (tester) async {
        const atmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.nature,
          season: ShanshuiSeason.spring,
          timeOfDay: ShanshuiTimeOfDay.day,
          weather: ShanshuiWeather.sunny,
        );

        await tester.pumpWidget(
          buildTestHarness(
            atmosphere: atmosphere,
            enableAmbientAnimation: true,
            isVisible: true,
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byKey(const Key('scenery_pull_cord_handle')), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          buildTestHarness(
            atmosphere: atmosphere,
            enableAmbientAnimation: true,
            isVisible: false,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'auto-hides overlay strip and pull-cord tag after 3s, ignores hidden badge taps, and requires tap-to-reveal before contemplation',
      (tester) async {
        var contemplationOpened = false;
        const atmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.nature,
          season: ShanshuiSeason.winter,
          timeOfDay: ShanshuiTimeOfDay.night,
          weather: ShanshuiWeather.sunny,
          isJournalInferred: true,
        );

        await tester.pumpWidget(
          buildTestHarness(
            atmosphere: atmosphere,
            onOpenContemplation: () => contemplationOpened = true,
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        // Initially visible at opacity 1.0
        AnimatedOpacity stripOpacity = tester.widget<AnimatedOpacity>(
          find.byKey(const Key('scenery_overlay_strip_opacity')),
        );
        AnimatedOpacity tagOpacity = tester.widget<AnimatedOpacity>(
          find.byKey(const Key('scenery_pull_cord_tag_opacity')),
        );
        expect(stripOpacity.opacity, 1.0);
        expect(tagOpacity.opacity, 1.0);

        // Advance past the 3s auto-hide timer + fade duration
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 450));

        stripOpacity = tester.widget<AnimatedOpacity>(
          find.byKey(const Key('scenery_overlay_strip_opacity')),
        );
        tagOpacity = tester.widget<AnimatedOpacity>(
          find.byKey(const Key('scenery_pull_cord_tag_opacity')),
        );
        expect(stripOpacity.opacity, 0.0);
        expect(tagOpacity.opacity, 0.0);
        expect(find.byKey(const Key('scenery_pull_cord_handle')), findsOneWidget);

        // Hidden realm badge should ignore taps (falling through to reveal HUD)
        await tester.tap(find.byKey(const Key('scenery_realm_badge')), warnIfMissed: false);
        await tester.pump();
        expect(find.byKey(const Key('scenery_realm_option_nature')), findsNothing);
        expect(contemplationOpened, isFalse);

        // Wait 3s again to verify canvas tap reveals HUD without entering contemplation
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 450));
        expect(
          tester.widget<AnimatedOpacity>(find.byKey(const Key('scenery_overlay_strip_opacity'))).opacity,
          0.0,
        );

        // First tap on canvas reveals overlays without entering contemplation
        await tester.tap(find.byKey(const Key('scenery_canvas_tap_target')));
        await tester.pump();
        expect(contemplationOpened, isFalse);

        stripOpacity = tester.widget<AnimatedOpacity>(
          find.byKey(const Key('scenery_overlay_strip_opacity')),
        );
        tagOpacity = tester.widget<AnimatedOpacity>(
          find.byKey(const Key('scenery_pull_cord_tag_opacity')),
        );
        expect(stripOpacity.opacity, 1.0);
        expect(tagOpacity.opacity, 1.0);

        // Second tap while overlays are visible opens contemplation
        await tester.tap(find.byKey(const Key('scenery_canvas_tap_target')));
        await tester.pump();
        expect(contemplationOpened, isTrue);
      },
    );

    testWidgets(
      'keeps overlays visible under accessibleNavigation and shows drag feedback during pull after auto-hide',
      (tester) async {
        const atmosphere = ShanshuiAtmosphereState(
          realm: ShanshuiRealm.nature,
          season: ShanshuiSeason.spring,
          timeOfDay: ShanshuiTimeOfDay.day,
          weather: ShanshuiWeather.sunny,
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(accessibleNavigation: true),
            child: buildTestHarness(atmosphere: atmosphere),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 4));

        final stripOpacity = tester.widget<AnimatedOpacity>(
          find.byKey(const Key('scenery_overlay_strip_opacity')),
        );
        expect(stripOpacity.opacity, 1.0);

        // Unmount accessible wrapper cleanly, then verify drag feedback after normal auto-hide
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(buildTestHarness(atmosphere: atmosphere));
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 450));

        expect(
          tester.widget<AnimatedOpacity>(find.byKey(const Key('scenery_pull_cord_tag_opacity'))).opacity,
          0.0,
        );

        final cordCenter = tester.getCenter(find.byKey(const Key('scenery_pull_cord_handle')));
        final gesture = await tester.startGesture(cordCenter);
        await gesture.moveBy(const Offset(0, 22));
        await tester.pump();

        expect(find.text('继续下拉 ↓'), findsOneWidget);
        expect(
          tester.widget<AnimatedOpacity>(find.byKey(const Key('scenery_pull_cord_tag_opacity'))).opacity,
          1.0,
        );

        await gesture.up();
        await tester.pumpAndSettle();

        // Reduced-motion expand from collapsed reveals HUD and restarts 3s auto-hide timer
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: buildTestHarness(atmosphere: atmosphere),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('scenery_pull_cord_handle')));
        await tester.pump();
        expect(find.byKey(const Key('scenery_collapsed_blind_bar')), findsOneWidget);

        await tester.tap(find.byKey(const Key('scenery_collapsed_blind_bar')));
        await tester.pump();
        expect(
          tester.widget<AnimatedOpacity>(find.byKey(const Key('scenery_overlay_strip_opacity'))).opacity,
          1.0,
        );
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
        expect(
          tester.widget<AnimatedOpacity>(find.byKey(const Key('scenery_overlay_strip_opacity'))).opacity,
          0.0,
        );
      },
    );
  });
}
