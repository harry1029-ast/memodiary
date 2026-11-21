import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/atmosphere_palettes.dart';
import 'package:memodiary/core/theme/atmosphere_theme_models.dart';
import 'package:memodiary/core/theme/theme_settings_service.dart';
import 'package:memodiary/features/intro/screens/book_intro_screen.dart';
import 'package:memodiary/features/intro/widgets/bottom_seal_slider.dart';
import 'package:memodiary/main.dart';
import '../../helpers/mock_secure_storage.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase.memory();
    tempDir = Directory.systemTemp.createTempSync('diarist_panel_test_');
    mediaService = MediaSandboxService(baseDirProvider: () async => tempDir);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  final avatarButton = find.byKey(const Key('timeline_avatar_button'));
  final panel = find.byKey(const Key('diarist_panel'));

  Future<ThemeSettingsService> pumpApp(
    WidgetTester tester, {
    bool showIntroOnLaunch = false,
    Size size = const Size(400, 800),
  }) async {
    tester.view.physicalSize = size;
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
        showIntroOnLaunch: showIntroOnLaunch,
        themeSettings: themeSettings,
      ),
    );
    await tester.pumpAndSettle();
    return themeSettings;
  }

  /// Unmounts the app and drains Drift stream timers (the 相册 tab watches
  /// collections) so tearDown can close the database.
  Future<void> unmountApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> openPanel(WidgetTester tester) async {
    await tester.tap(avatarButton);
    await tester.pumpAndSettle();
  }

  group('Opening and closing', () {
    testWidgets('the avatar button on 日记 opens the panel with the placeholder profile', (tester) async {
      await pumpApp(tester);
      expect(find.text('云皓主人'), findsNothing);

      await openPanel(tester);

      expect(panel, findsOneWidget);
      expect(find.descendant(of: panel, matching: find.text('云皓主人')), findsOneWidget);
      expect(find.descendant(of: panel, matching: find.text('记录今日，也收藏远方')), findsOneWidget);
      expect(find.descendant(of: panel, matching: find.text('返回封面')), findsOneWidget);
    });

    testWidgets('tapping the dimmed strip closes the panel', (tester) async {
      await pumpApp(tester);
      await openPanel(tester);

      await tester.tapAt(const Offset(385, 400));
      await tester.pumpAndSettle();

      expect(panel, findsNothing);
      expect(find.text('暂无日记'), findsOneWidget);
    });

    testWidgets('swiping left closes the panel; a short nudge leaves it open', (tester) async {
      await pumpApp(tester);
      await openPanel(tester);

      await tester.timedDrag(panel, const Offset(-40, 0), const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(panel, findsOneWidget);

      await tester.fling(panel, const Offset(-200, 0), 1000);
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
    });

    testWidgets('the 相册 header has the same avatar button', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('home_tab_albums')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('albums_avatar_button')));
      await tester.pumpAndSettle();
      expect(find.descendant(of: panel, matching: find.text('云皓主人')), findsOneWidget);

      await unmountApp(tester);
    });
  });

  group('Android Back', () {
    testWidgets('closes the open panel first, then 相册 → 日记, then exits', (tester) async {
      final platformCalls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          platformCalls.add(call.method);
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('home_tab_albums')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('albums_avatar_button')));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      expect(find.text('暂无旅行相册'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('暂无日记'), findsOneWidget);
      expect(platformCalls, isNot(contains('SystemNavigator.pop')));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(platformCalls, contains('SystemNavigator.pop'));
      await unmountApp(tester);
    });
  });

  group('返回封面', () {
    testWidgets('replaces the Home Shell with the cover, and re-entering lands on the door\'s tab', (tester) async {
      await pumpApp(tester, size: const Size(800, 1600));
      final tabRail = find.byKey(const Key('home_tab_rail'));

      Future<void> returnToCover(Finder avatar) async {
        await tester.tap(avatar);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('diarist_panel_return_to_cover_row')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byKey(const Key('home_tab_rail'), skipOffstage: false), findsNothing);
        expect(panel, findsNothing);
        expect(find.byType(BookIntroScreen), findsOneWidget);
        expect(Navigator.of(tester.element(find.byType(BookIntroScreen))).canPop(), isFalse);
      }

      Future<void> enterThrough(String door) async {
        await tester.tap(find.byType(BottomSealSlider));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));
        await tester.tap(find.text(door));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tabRail, findsOneWidget);
        expect(find.byType(BookIntroScreen, skipOffstage: false), findsNothing);
        expect(Navigator.of(tester.element(tabRail)).canPop(), isFalse);
      }

      await returnToCover(avatarButton);
      await enterThrough('私人日记');
      expect(find.text('暂无日记'), findsOneWidget);

      await returnToCover(avatarButton);
      await enterThrough('旅行相册');
      expect(find.text('暂无旅行相册'), findsOneWidget);

      await returnToCover(find.byKey(const Key('albums_avatar_button')));
      await unmountApp(tester);
    });
  });

  group('Placeholder profile', () {
    testWidgets('is display-only: tapping it changes nothing and it offers no actions', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      try {
        await pumpApp(tester);
        await openPanel(tester);
        final profile = find.byKey(const Key('diarist_panel_profile'));

        await tester.tap(find.text('云皓主人'));
        await tester.pumpAndSettle();

        expect(panel, findsOneWidget);
        expect(find.byType(EditableText), findsNothing);
        expect(find.byType(TextField), findsNothing);
        for (final text in ['云皓主人', '记录今日，也收藏远方']) {
          final data = tester.getSemantics(find.descendant(of: profile, matching: find.text(text))).getSemanticsData();
          expect(data.hasAction(SemanticsAction.tap), isFalse, reason: text);
          expect(data.flagsCollection.isButton, isFalse, reason: text);
        }
      } finally {
        semanticsHandle.dispose();
      }
    });
  });

  group('Appearance', () {
    void expectPanelColours(WidgetTester tester, AtmospherePalette palette) {
      final surface = tester.widget<DecoratedBox>(panel);
      final decoration = surface.decoration as BoxDecoration;
      expect(
        (decoration.gradient! as LinearGradient).colors,
        [palette.woodFrameMid, palette.woodFrameDark],
        reason: palette.id,
      );
      final name = tester.widget<Text>(find.text('云皓主人'));
      expect(name.style!.color, palette.headerTitleText, reason: palette.id);
    }

    testWidgets('uses the active palette woodwork with light status-bar icons, and recolours live', (tester) async {
      final themeSettings = await pumpApp(tester);
      await openPanel(tester);
      expectPanelColours(tester, AtmospherePalettes.yunhaoDay);

      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.ancestor(of: panel, matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>)).first,
      );
      expect(region.value.statusBarIconBrightness, Brightness.light);
      expect(region.value.statusBarBrightness, Brightness.dark);

      await themeSettings.setPreset(AtmosphereThemePreset.classic);
      await tester.pumpAndSettle();
      expect(panel, findsOneWidget);
      expectPanelColours(tester, AtmospherePalettes.classicWalnut);
    });
  });

  group('Accessibility', () {
    testWidgets('the avatar button reads 我的; the open panel names itself and hides the shell behind', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      try {
        await pumpApp(tester);
        expect(
          tester.getSemantics(avatarButton),
          matchesSemantics(
            isButton: true,
            label: '我的',
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
          ),
        );

        expect(find.semantics.byLabel('写日记'), findsOne);

        await openPanel(tester);

        final panelRoute = find
            .ancestor(
              of: panel,
              matching: find.byWidgetPredicate(
                (widget) => widget is Semantics && widget.properties.namesRoute == true,
              ),
            )
            .first;
        final routeData = tester.getSemantics(panelRoute).getSemanticsData();
        expect(routeData.label, '我的');
        expect(routeData.flagsCollection.namesRoute, isTrue);
        expect(routeData.flagsCollection.scopesRoute, isTrue);
        expect(find.semantics.byLabel('写日记'), findsNothing);
        expect(find.semantics.byLabel('返回封面'), findsOne);
        expect(find.semantics.byLabel('关闭我的'), findsOne);
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('with reduced motion the panel opens and closes without sliding', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pumpApp(tester);

      await tester.tap(avatarButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getTopLeft(panel).dx, 0);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(panel, findsNothing);
    });

    testWidgets('fits 320dp at 1.3x text scale with tap targets of at least 44x44', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semanticsHandle = tester.ensureSemantics();
      try {
        await pumpApp(tester, size: const Size(320, 640));
        await expectAccessibleTapTargets(tester, within: avatarButton);
        await openPanel(tester);
        expect(tester.takeException(), isNull);
        expect(tester.getSize(panel).width, closeTo(320 * 0.85, 0.5));
        await expectAccessibleTapTargets(tester, within: panel);
      } finally {
        semanticsHandle.dispose();
      }
    });
  });
}
