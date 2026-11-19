import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/atmosphere_palettes.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/core/theme/theme_settings_service.dart';
import 'package:memodiary/core/theme/widgets/octagonal_medallion_button.dart';
import 'package:memodiary/features/intro/screens/book_intro_screen.dart';
import 'package:memodiary/features/intro/widgets/bottom_seal_slider.dart';
import 'package:memodiary/features/scenery/services/scenery_settings_service.dart';
import 'package:memodiary/features/search/screens/search_screen.dart';
import 'package:memodiary/features/settings/screens/settings_screen.dart';
import 'package:memodiary/features/timeline/screens/timeline_screen.dart';
import 'package:memodiary/features/timeline/widgets/timeline_app_bar.dart';
import 'package:memodiary/features/weekly_review/screens/weekly_review_screen.dart';
import 'package:memodiary/main.dart';
import '../../helpers/mock_secure_storage.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;
  late ScenerySettingsService scenerySettings;

  setUp(() {
    db = AppDatabase.memory();
    mediaService = MediaSandboxService();
    scenerySettings = ScenerySettingsService(storage: MockSecureStorage());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpTimelineAppBar(
    WidgetTester tester, {
    required AtmospherePalette palette,
    double viewportWidth = 400,
    double textScale = 1.0,
    VoidCallback? onReturnFromSubscreen,
    VoidCallback? onReturnFromSettings,
  }) async {
    tester.view.physicalSize = Size(viewportWidth, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: InkDiaryTheme.forAtmosphere(palette),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          appBar: TimelineAppBar(
            database: db,
            mediaService: mediaService,
            ocrQueueManager: null,
            scenerySettings: scenerySettings,
            onReturnFromSubscreen: onReturnFromSubscreen ?? () {},
            onReturnFromSettings: onReturnFromSettings ?? () {},
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('TimelineAppBar Casement Framing & Branding', () {
    testWidgets(
      'displays Yunhao branding, retires legacy copy, and applies casement woodwork surface across yunhaoDay, yunhaoNight, and classicWalnut',
      (tester) async {
        final palettes = <AtmospherePalette>[
          AtmospherePalettes.yunhaoDay,
          AtmospherePalettes.yunhaoNight,
          AtmospherePalettes.classicWalnut,
        ];

        for (final palette in palettes) {
          await pumpTimelineAppBar(tester, palette: palette);

          expect(find.text('云皓日记'), findsOneWidget, reason: palette.id);
          expect(find.text('YUNHAO'), findsOneWidget, reason: palette.id);
          expect(
            find.text('云伴皓光 · 收录旅途与心事'),
            findsOneWidget,
            reason: palette.id,
          );
          expect(find.text('MemoDiary'), findsNothing, reason: palette.id);
          expect(find.text('墨记'), findsNothing, reason: palette.id);
          expect(find.text('个人离线日记'), findsNothing, reason: palette.id);

          final appBar = tester.widget<AppBar>(find.byType(AppBar));
          expect(appBar.backgroundColor, equals(palette.woodFrameDark));
          expect(appBar.foregroundColor, equals(palette.headerTitleText));
          expect(appBar.elevation, equals(0));
          expect(appBar.scrolledUnderElevation, equals(0));
          expect(appBar.surfaceTintColor, equals(Colors.transparent));
          expect(
            appBar.systemOverlayStyle,
            equals(
              const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              ),
            ),
          );
        }
      },
    );

    testWidgets(
      'back-to-cover button meets 44x44 tap target, exposes 返回封面 button semantics, and renders without overflow at 320px and 1.3x text scale',
      (tester) async {
        final semanticsHandle = tester.ensureSemantics();
        try {
          await pumpTimelineAppBar(
            tester,
            palette: AtmospherePalettes.yunhaoDay,
            viewportWidth: 320,
            textScale: 1.3,
          );

          expect(tester.takeException(), isNull);

          final backFinder = find.byKey(const Key('timeline_back_to_cover_button'));
          expect(backFinder, findsOneWidget);

          final backSize = tester.getSize(backFinder);
          expect(backSize.width, greaterThanOrEqualTo(44.0));
          expect(backSize.height, greaterThanOrEqualTo(44.0));

          expect(
            tester.getSemantics(backFinder),
            matchesSemantics(
              isButton: true,
              label: '返回封面',
              hasEnabledState: true,
              isEnabled: true,
              hasTapAction: true,
              hasFocusAction: true,
              isFocusable: true,
            ),
          );

          await expectAccessibleTapTargets(tester, within: backFinder);

          expect(
            find.descendant(
              of: backFinder,
              matching: find.byType(CustomPaint),
            ),
            findsAtLeastNWidgets(1),
          );
          expect(
            find.descendant(
              of: backFinder,
              matching: find.byIcon(Icons.chevron_left_rounded),
            ),
            findsOneWidget,
          );
        } finally {
          semanticsHandle.dispose();
        }
      },
    );

    testWidgets(
      'tapping 返回封面 pops back to existing BookIntroScreen when pushed from cover (canPop == true)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: InkDiaryTheme.light,
            home: BookIntroScreen(
              database: db,
              mediaService: mediaService,
              startOpened: true,
              clock: () => DateTime(2026, 11, 19, 11, 30),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(BookIntroScreen), findsOneWidget);
        expect(find.text('私人日记'), findsOneWidget);

        await tester.tap(find.text('私人日记'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(TimelineScreen), findsOneWidget);
        expect(
          Navigator.of(tester.element(find.byType(TimelineScreen))).canPop(),
          isTrue,
        );

        await tester.tap(find.byKey(const Key('timeline_back_to_cover_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(TimelineScreen), findsNothing);
        expect(find.byType(BookIntroScreen), findsOneWidget);
        expect(find.text('私人日记'), findsOneWidget);
        expect(
          Navigator.of(tester.element(find.byType(BookIntroScreen))).canPop(),
          isFalse,
        );
      },
    );

    testWidgets(
      'tapping 返回封面 push-replaces to BookIntroScreen when TimelineScreen started as root (canPop == false)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final themeSettings = ThemeSettingsService(storage: MockSecureStorage());
        await tester.pumpWidget(
          MemoDiaryApp(
            database: db,
            mediaService: mediaService,
            showIntroOnLaunch: false,
            themeSettings: themeSettings,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TimelineScreen), findsOneWidget);
        expect(
          Navigator.of(tester.element(find.byType(TimelineScreen))).canPop(),
          isFalse,
        );

        await tester.tap(find.byKey(const Key('timeline_back_to_cover_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(TimelineScreen), findsNothing);
        expect(find.byType(BookIntroScreen), findsOneWidget);
        expect(
          Navigator.of(tester.element(find.byType(BookIntroScreen))).canPop(),
          isFalse,
        );

        // Open the cover and re-enter 私人日记; returning again pops cleanly back to cover.
        await tester.tap(find.byType(BottomSealSlider));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));

        await tester.tap(find.text('私人日记'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(TimelineScreen), findsOneWidget);

        await tester.tap(find.byKey(const Key('timeline_back_to_cover_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(TimelineScreen), findsNothing);
        expect(find.byType(BookIntroScreen), findsOneWidget);
      },
    );

    testWidgets(
      'styles all three right octagonal medallions for woodwork headers and preserves navigation and callbacks',
      (tester) async {
        for (final palette in [
          AtmospherePalettes.yunhaoDay,
          AtmospherePalettes.yunhaoNight,
          AtmospherePalettes.classicWalnut,
        ]) {
          await pumpTimelineAppBar(tester, palette: palette);

          for (final keyName in const [
            'timeline_weekly_review_button',
            'timeline_search_button',
            'timeline_settings_button',
          ]) {
            final button = tester.widget<OctagonalMedallionButton>(
              find.byKey(Key(keyName)),
            );
            expect(button.iconColor, equals(palette.headerTitleText), reason: '${palette.id}:$keyName');
            expect(button.borderColor, equals(Colors.white.withValues(alpha: 0.24)), reason: '${palette.id}:$keyName');
            expect(button.bevelColor, equals(Colors.white.withValues(alpha: 0.14)), reason: '${palette.id}:$keyName');
            final gradient = button.gradient! as LinearGradient;
            expect(
              gradient.colors,
              equals([
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.05),
              ]),
              reason: '${palette.id}:$keyName',
            );
          }
        }

        var subscreenReturnCount = 0;
        var settingsReturnCount = 0;
        await pumpTimelineAppBar(
          tester,
          palette: AtmospherePalettes.yunhaoDay,
          onReturnFromSubscreen: () => subscreenReturnCount++,
          onReturnFromSettings: () => settingsReturnCount++,
        );

        await tester.tap(find.byKey(const Key('timeline_weekly_review_button')));
        await tester.pumpAndSettle();
        expect(find.byType(WeeklyReviewScreen), findsOneWidget);
        Navigator.of(tester.element(find.byType(WeeklyReviewScreen))).pop();
        await tester.pumpAndSettle();
        expect(subscreenReturnCount, equals(1));

        await tester.tap(find.byKey(const Key('timeline_search_button')));
        await tester.pumpAndSettle();
        expect(find.byType(SearchScreen), findsOneWidget);
        Navigator.of(tester.element(find.byType(SearchScreen))).pop();
        await tester.pumpAndSettle();
        expect(subscreenReturnCount, equals(2));

        await tester.tap(find.byKey(const Key('timeline_settings_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(SettingsScreen), findsOneWidget);
        Navigator.of(tester.element(find.byType(SettingsScreen))).pop();
        await tester.pumpAndSettle();
        expect(settingsReturnCount, equals(1));
      },
    );
  });
}
