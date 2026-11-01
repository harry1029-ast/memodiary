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
                activePrompt: '瓦檐下一滴落雨的声响。',
                onRefreshPrompt: () {},
                onWritePrompt: (_) {},
                onOpenContemplation: onOpenContemplation ?? () {},
                onRealmPreferenceChanged: onRealmPreferenceChanged,
                settingsService: settingsService,
                enableAmbientAnimation: false,
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
        expect(find.text('随文入境 · 雅室'), findsOneWidget);
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
        // Realm badge displays active realm label without 随文入境 prefix
        expect(find.byKey(const Key('scenery_realm_badge')), findsOneWidget);
        expect(find.text('市井'), findsOneWidget);
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
        expect(find.text('随文入境 · 雅室'), findsOneWidget);
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

        expect(find.textContaining('Auto (随文入境)'), findsOneWidget);
        expect(find.textContaining('Indoor (雅室)'), findsOneWidget);

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
        expect(find.text('雅室'), findsOneWidget);
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

        expect(find.text('随文入境 · 市井'), findsOneWidget);

        // 1. Manually select Indoor
        await tester.tap(find.byKey(const Key('scenery_realm_badge')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('scenery_realm_option_indoor')));
        await tester.pumpAndSettle();

        expect(changedPref, equals(SceneryRealmPreference.indoor));
        expect(find.text('雅室'), findsOneWidget);
        expect(find.text('随文入境 · 市井'), findsNothing);

        // 2. Select Auto again
        await tester.tap(find.byKey(const Key('scenery_realm_badge')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('scenery_realm_option_auto')));
        await tester.pumpAndSettle();

        expect(changedPref, equals(SceneryRealmPreference.auto));
        expect(mockStorage.data['memodiary_scenery_realm_preference'], equals('auto'));

        // Card immediately resets back to real-time inferred realm
        expect(find.text('随文入境 · 市井'), findsOneWidget);
        expect(find.text('雅室'), findsNothing);
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
  });
}
