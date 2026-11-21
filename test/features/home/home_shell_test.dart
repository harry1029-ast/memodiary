import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;
import 'package:drift/drift.dart' show Value;
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
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
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
    tempDir = Directory.systemTemp.createTempSync('home_shell_test_');
    mediaService = MediaSandboxService(baseDirProvider: () async => tempDir);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  final tabRail = find.byKey(const Key('home_tab_rail'));
  final diaryTab = find.byKey(const Key('home_tab_diary'));
  final albumsTab = find.byKey(const Key('home_tab_albums'));
  final centreButton = find.byKey(const Key('home_centre_button'));

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
    if (showIntroOnLaunch) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    } else {
      await tester.pumpAndSettle();
    }
    return themeSettings;
  }

  Future<void> seedEntries(int count) async {
    for (var index = 0; index < count; index++) {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'seed_entry_$index',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: Value('Seed Entry $index'),
          contentDelta: jsonEncode([
            {'insert': 'Body $index\n'}
          ]),
          plainText: 'Body $index',
          entryDate: DateTime(2026, 11, 20, 12).subtract(Duration(days: index)),
        ),
      );
    }
  }

  Future<void> openCoverAndTap(WidgetTester tester, String door) async {
    await tester.tap(find.byType(BottomSealSlider));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(find.text(door));
    await tester.pumpAndSettle();
  }

  Future<void> selectTab(WidgetTester tester, Finder tab) async {
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  /// Unmounts the app and drains Drift stream timers (the 相册 tab watches
  /// collections) so tearDown can close the database.
  Future<void> unmountApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  bool shellCanPop(WidgetTester tester) =>
      Navigator.of(tester.element(tabRail)).canPop();

  group('Home Shell entry', () {
    testWidgets('cover on: the cover shows without a Tab Rail', (tester) async {
      await pumpApp(tester, showIntroOnLaunch: true);

      expect(find.byType(BookIntroScreen), findsOneWidget);
      expect(tabRail, findsNothing);
    });

    testWidgets('cover on: 私人日记 replaces the cover with the 日记 tab', (tester) async {
      await pumpApp(tester, showIntroOnLaunch: true);
      await openCoverAndTap(tester, '私人日记');

      expect(tabRail, findsOneWidget);
      expect(find.text('暂无日记'), findsOneWidget);
      expect(find.byType(BookIntroScreen, skipOffstage: false), findsNothing);
      expect(shellCanPop(tester), isFalse);
    });

    testWidgets('cover on: 旅行相册 replaces the cover with the 相册 tab', (tester) async {
      await pumpApp(tester, showIntroOnLaunch: true);
      await openCoverAndTap(tester, '旅行相册');

      expect(tabRail, findsOneWidget);
      expect(find.text('暂无旅行相册'), findsOneWidget);
      expect(find.descendant(of: centreButton, matching: find.text('新建相册')), findsOneWidget);
      expect(find.byType(BookIntroScreen, skipOffstage: false), findsNothing);
      expect(shellCanPop(tester), isFalse);

      await unmountApp(tester);
    });

    testWidgets('cover off: opens on the 日记 tab with the Tab Rail', (tester) async {
      await pumpApp(tester);

      expect(tabRail, findsOneWidget);
      expect(find.descendant(of: diaryTab, matching: find.text('日记')), findsOneWidget);
      expect(find.descendant(of: albumsTab, matching: find.text('相册')), findsOneWidget);
      expect(find.descendant(of: centreButton, matching: find.text('写日记')), findsOneWidget);
      expect(find.text('暂无日记'), findsOneWidget);
      // The timeline owns no floating write button: 写日记 lives only in the rail.
      expect(find.text('写日记'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });

  group('Tab switching', () {
    testWidgets('相册 is built only on first selection and the centre label follows the tab', (tester) async {
      await pumpApp(tester);

      expect(find.text('暂无旅行相册', skipOffstage: false), findsNothing);

      await selectTab(tester, albumsTab);
      expect(find.text('暂无旅行相册'), findsOneWidget);
      expect(find.text('暂无日记'), findsNothing);
      expect(find.descendant(of: centreButton, matching: find.text('新建相册')), findsOneWidget);
      expect(find.descendant(of: centreButton, matching: find.text('写日记')), findsNothing);

      await selectTab(tester, diaryTab);
      expect(find.text('暂无日记'), findsOneWidget);
      expect(find.descendant(of: centreButton, matching: find.text('写日记')), findsOneWidget);

      await unmountApp(tester);
    });

    testWidgets('the centre label cross-fades on switch', (tester) async {
      await pumpApp(tester);

      await tester.tap(albumsTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.descendant(of: centreButton, matching: find.text('写日记')), findsOneWidget);
      expect(find.descendant(of: centreButton, matching: find.text('新建相册')), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.descendant(of: centreButton, matching: find.text('写日记')), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('switching away and back keeps the timeline scroll offset and filters', (tester) async {
      await seedEntries(12);
      await pumpApp(tester);

      await tester.tap(find.byKey(const Key('timeline_sort_toggle_button')));
      await tester.pumpAndSettle();
      expect(find.text('最早'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      final scrolledTop = tester.getTopLeft(find.text('Seed Entry 9')).dy;

      await selectTab(tester, albumsTab);
      await selectTab(tester, diaryTab);

      expect(find.text('最早'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Seed Entry 9')).dy, scrolledTop);

      await unmountApp(tester);
    });
  });

  group('Scroll Roller Button', () {
    testWidgets('on 日记 it opens a new entry and the timeline shows it afterwards', (tester) async {
      await pumpApp(tester);
      expect(find.text('共 0 篇'), findsOneWidget);

      await tester.tap(centreButton);
      await tester.pumpAndSettle();
      expect(find.byType(EntryEditorScreen), findsOneWidget);
      expect(tabRail, findsNothing);

      Navigator.of(tester.element(find.byType(EntryEditorScreen))).pop();
      await tester.pumpAndSettle();

      expect(tabRail, findsOneWidget);
      expect(find.text('共 1 篇'), findsOneWidget);
    });

    testWidgets('on 相册 it opens the create-album sheet and the list shows the new album', (tester) async {
      await pumpApp(tester);
      await selectTab(tester, albumsTab);

      await tester.tap(centreButton);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('album_form_title')), '江南春行纪');
      await tester.tap(find.byKey(const Key('album_form_submit')));
      await tester.pumpAndSettle();

      expect(find.text('江南春行纪'), findsOneWidget);
      expect(find.text('暂无旅行相册'), findsNothing);

      await unmountApp(tester);
    });
  });

  group('Android Back', () {
    testWidgets('相册 goes back to 日记, then 日记 exits without showing the cover', (tester) async {
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

      await pumpApp(tester, showIntroOnLaunch: true);
      await openCoverAndTap(tester, '旅行相册');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('暂无日记'), findsOneWidget);
      expect(find.descendant(of: centreButton, matching: find.text('写日记')), findsOneWidget);
      expect(platformCalls, isNot(contains('SystemNavigator.pop')));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(platformCalls, contains('SystemNavigator.pop'));
      expect(find.byType(BookIntroScreen), findsNothing);
      expect(tabRail, findsOneWidget);
      await unmountApp(tester);
    });
  });

  group('Tab Rail appearance', () {
    void expectRailColours(WidgetTester tester, AtmospherePalette palette) {
      final surface = tester.widget<DecoratedBox>(find.byKey(const Key('tab_rail_surface')));
      final decoration = surface.decoration as ShapeDecoration;
      expect(
        (decoration.gradient! as LinearGradient).colors,
        [palette.woodFrameMid, palette.woodFrameDark],
        reason: palette.id,
      );

      final selectedLabel = tester.widget<Text>(
        find.descendant(of: diaryTab, matching: find.text('日记')),
      );
      expect(selectedLabel.style!.color, palette.headerTitleText, reason: palette.id);
      expect(selectedLabel.style!.fontWeight, FontWeight.w700, reason: palette.id);
      final unselectedLabel = tester.widget<Text>(
        find.descendant(of: albumsTab, matching: find.text('相册')),
      );
      expect(unselectedLabel.style!.color, isNot(palette.headerTitleText), reason: palette.id);

      final mark = tester.widget<Container>(
        find.descendant(of: diaryTab, matching: find.byKey(const Key('tab_rail_selected_mark'))),
      );
      expect((mark.decoration! as BoxDecoration).color, palette.accentPrimary, reason: palette.id);

      final centreLabel = tester.widget<Text>(
        find.descendant(of: centreButton, matching: find.text('写日记')),
      );
      expect(centreLabel.style!.color, palette.fabText, reason: palette.id);
    }

    testWidgets('uses the active palette woodwork tokens and recolours live', (tester) async {
      final themeSettings = await pumpApp(tester);
      expectRailColours(tester, AtmospherePalettes.yunhaoDay);

      await themeSettings.setPreset(AtmosphereThemePreset.classic);
      await tester.pumpAndSettle();
      expectRailColours(tester, AtmospherePalettes.classicWalnut);
    });
  });

  group('Tab Rail accessibility', () {
    testWidgets('tabs announce tab role and selected state; the centre button its current label', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      try {
        await pumpApp(tester);

        final diarySemantics = tester.getSemantics(diaryTab).getSemanticsData();
        expect(diarySemantics.role, SemanticsRole.tab);
        expect(diarySemantics.label, '日记');
        expect(diarySemantics.flagsCollection.isSelected, Tristate.isTrue);
        expect(diarySemantics.hasAction(SemanticsAction.tap), isTrue);
        final albumsSemantics = tester.getSemantics(albumsTab).getSemanticsData();
        expect(albumsSemantics.role, SemanticsRole.tab);
        expect(albumsSemantics.flagsCollection.isSelected, Tristate.isFalse);
        expect(find.bySemanticsLabel('写日记'), findsOneWidget);

        await selectTab(tester, albumsTab);
        expect(
          tester.getSemantics(albumsTab).getSemanticsData().flagsCollection.isSelected,
          Tristate.isTrue,
        );
        expect(find.bySemanticsLabel('新建相册'), findsOneWidget);
        expect(find.bySemanticsLabel('写日记'), findsNothing);
        await unmountApp(tester);
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('fits 320dp at 1.3x text scale with tap targets of at least 44x44', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semanticsHandle = tester.ensureSemantics();
      try {
        await pumpApp(tester, size: const Size(320, 640));
        expect(tester.takeException(), isNull);
        await expectAccessibleTapTargets(tester, within: tabRail);

        await selectTab(tester, albumsTab);
        expect(tester.takeException(), isNull);
        await expectAccessibleTapTargets(tester, within: tabRail);
        await unmountApp(tester);
      } finally {
        semanticsHandle.dispose();
      }
    });
  });
}
