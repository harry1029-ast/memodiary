import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/intro/models/intro_sky_atmosphere.dart';
import 'package:memodiary/features/intro/screens/book_intro_screen.dart';
import 'package:memodiary/features/intro/widgets/book_3d_stage.dart';
import 'package:memodiary/features/intro/widgets/bottom_seal_slider.dart';
import 'package:memodiary/features/intro/widgets/living_ink_background_painter.dart';
import 'package:memodiary/features/timeline/widgets/folio/folio_metadata_formatter.dart';

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase.memory();
    tempDir = Directory.systemTemp.createTempSync('book_intro_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  /// Shared test harness extracting view dimensions and dependency wiring
  /// to eliminate duplicated boilerplate and maintain CODING_STANDARDS.md §4 compliance.
  Future<void> pumpBookIntroScreen(
    WidgetTester tester, {
    required AppDatabase database,
    required MediaSandboxService mediaService,
    bool startOpened = false,
    DateTime Function()? clock,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BookIntroScreen(
          database: database,
          mediaService: mediaService,
          startOpened: startOpened,
          clock: clock,
        ),
      ),
    );
    await tester.pump();
    if (startOpened) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  LivingInkBackgroundPainter findBackgroundPainter(WidgetTester tester) {
    final customPaints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    return customPaints
        .map((widget) => widget.painter)
        .whereType<LivingInkBackgroundPainter>()
        .first;
  }

  group('IntroSkyAtmosphere Unit Tests', () {
    test('interpolates sky phases across 晓岚 (6.0), 云岚昼 (11.5), 暮霞 (17.5), and 皓月夜 (21.4)', () {
      final dawn = InterpolatedIntroSky.fromHour(6.0);
      expect(dawn.mode, equals('云岚昼'));
      expect(dawn.phaseName, contains('晓岚'));
      expect(dawn.isNight, isFalse);
      expect(dawn.lanternGlow, greaterThan(0.0));

      final day = InterpolatedIntroSky.fromHour(11.5);
      expect(day.mode, equals('云岚昼'));
      expect(day.phaseName, contains('云岚昼'));
      expect(day.isNight, isFalse);
      expect(day.starOpacity, equals(0.0));
      expect(day.lanternGlow, equals(0.0));

      final dusk = InterpolatedIntroSky.fromHour(17.5);
      expect(dusk.mode, equals('云岚昼'));
      expect(dusk.phaseName, contains('暮霞'));
      expect(dusk.isNight, isFalse);
      expect(dusk.lanternGlow, closeTo(0.72, 0.01));

      final night = InterpolatedIntroSky.fromHour(21.4);
      expect(night.mode, equals('皓月夜'));
      expect(night.phaseName, contains('皓月夜'));
      expect(night.isNight, isTrue);
      expect(night.starOpacity, greaterThan(0.8));
      expect(night.lanternGlow, closeTo(1.0, 0.01));
    });

    test('computes scaled parabolic Sun/Moon trajectory coordinates across phases', () {
      const canvasSize = Size(400, 812);

      final dawnOrb = CelestialOrbPosition.fromHour(6.0, canvasSize);
      expect(dawnOrb.isMoon, isFalse);
      expect(dawnOrb.progress, closeTo(0.0, 0.001));
      expect(dawnOrb.x, closeTo(36.0, 0.1));
      expect(dawnOrb.y, closeTo(212.0, 0.1));

      final dayOrb = CelestialOrbPosition.fromHour(11.5, canvasSize);
      expect(dayOrb.isMoon, isFalse);
      expect(dayOrb.progress, closeTo(5.5 / 12.0, 0.001));
      expect(dayOrb.y, lessThan(110.0));
      expect(dayOrb.edgeFade, equals(1.0));

      final duskOrb = CelestialOrbPosition.fromHour(17.5, canvasSize);
      expect(duskOrb.isMoon, isFalse);
      expect(duskOrb.x, greaterThan(340.0));
      expect(duskOrb.lightAngleDeg, greaterThan(130.0));

      final nightOrb = CelestialOrbPosition.fromHour(21.4, canvasSize);
      expect(nightOrb.isMoon, isTrue);
      expect(nightOrb.progress, closeTo(3.4 / 12.0, 0.001));
      expect(nightOrb.x, closeTo(36.0 + (3.4 / 12.0) * 328.0, 0.1));
      expect(nightOrb.edgeFade, equals(1.0));

      final doubledOrb = CelestialOrbPosition.fromHour(21.4, const Size(800, 1624));
      expect(doubledOrb.x, closeTo(nightOrb.x * 2.0, 0.1));
      expect(doubledOrb.y, closeTo(nightOrb.y * 2.0, 0.1));
    });
  });

  group('BookIntroScreen Widget Tests', () {
    testWidgets('renders closed thread-bound book cover, slogan, and slider on initial load', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: false,
      );

      expect(find.text('云皓日记'), findsOneWidget);
      expect(find.text('云伴皓光，收录旅途与心事'), findsOneWidget);
      final titleWidget = tester.widget<Text>(find.text('云皓日记'));
      final sloganWidget = tester.widget<Text>(find.text('云伴皓光，收录旅途与心事'));
      expect(titleWidget.style?.fontFamily, equals('Noto Serif SC'));
      expect(sloganWidget.style?.fontFamily, equals('Ma Shan Zheng'));
      expect(find.byType(BottomSealSlider), findsOneWidget);
      expect(find.byType(Book3DStage), findsOneWidget);
      expect(find.byKey(const Key('intro_celestial_toggle_button')), findsOneWidget);
      expect(find.text('左滑翻开'), findsAtLeast(1));
      expect(find.textContaining('Swipe Left'), findsNothing);

      // In closed state, vertical cover slip renders 云皓日记
      expect(find.textContaining('云\n皓\n日\n记'), findsOneWidget);
    });

    testWidgets('syncs initial sky mode with injected local clock (皓月夜 vs 云岚昼)', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        clock: () => DateTime(2026, 11, 19, 21, 24),
      );

      expect(findBackgroundPainter(tester).timeHours, closeTo(21.4, 0.01));
      expect(tester.widget<Book3DStage>(find.byType(Book3DStage)).isNight, isTrue);
      expect(tester.widget<BottomSealSlider>(find.byType(BottomSealSlider)).isNight, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        clock: () => DateTime(2026, 11, 19, 11, 30),
      );

      expect(findBackgroundPainter(tester).timeHours, closeTo(11.5, 0.01));
      expect(tester.widget<Book3DStage>(find.byType(Book3DStage)).isNight, isFalse);
      expect(tester.widget<BottomSealSlider>(find.byType(BottomSealSlider)).isNight, isFalse);
    });

    testWidgets('tapping celestial toggle button animates smoothly between 皓月夜 and 云岚昼', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        clock: () => DateTime(2026, 11, 19, 21, 24),
      );

      expect(tester.widget<Book3DStage>(find.byType(Book3DStage)).isNight, isTrue);

      // Tap Moon orb to transition smoothly into 云岚昼 (11.5)
      await tester.tap(find.byKey(const Key('intro_celestial_toggle_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      final midHour = findBackgroundPainter(tester).timeHours;
      expect(midHour, isNot(closeTo(21.4, 0.1)));
      expect(midHour, isNot(closeTo(11.5, 0.1)));

      await tester.pump(const Duration(milliseconds: 550));
      expect(findBackgroundPainter(tester).timeHours, closeTo(11.5, 0.01));
      expect(tester.widget<Book3DStage>(find.byType(Book3DStage)).isNight, isFalse);
      expect(tester.widget<BottomSealSlider>(find.byType(BottomSealSlider)).isNight, isFalse);

      // Tap Sun orb to transition smoothly back into 皓月夜 (21.4)
      await tester.tap(find.byKey(const Key('intro_celestial_toggle_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(findBackgroundPainter(tester).timeHours, closeTo(21.4, 0.01));
      expect(tester.widget<Book3DStage>(find.byType(Book3DStage)).isNight, isTrue);
      expect(tester.widget<BottomSealSlider>(find.byType(BottomSealSlider)).isNight, isTrue);
    });

    testWidgets('reveals 选择栏目, 私人日记 and 旅行相册 when startOpened is true', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: true,
      );

      expect(find.text('选择栏目'), findsOneWidget);
      expect(find.text('私人日记'), findsOneWidget);
      expect(find.text('记录日常心情与生活'), findsOneWidget);
      expect(find.text('旅行相册'), findsOneWidget);
      expect(find.text('整理旅途照片与足迹'), findsOneWidget);
      expect(find.text('进入 →'), findsNWidgets(2));
      expect(find.text('点击「私人日记」或「旅行相册」进入'), findsOneWidget);
    });

    testWidgets('私人日记 card shows today\'s true lunar month and day', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: true,
        // Solar 2026-11-10 is lunar 十月初二.
        clock: () => DateTime(2026, 11, 10, 8, 30),
      );

      expect(find.text('初'), findsOneWidget);
      final lunarColumn = find
          .ancestor(of: find.text('初'), matching: find.byType(Column))
          .first;
      final characters = tester
          .widgetList<Text>(find.descendant(of: lunarColumn, matching: find.byType(Text)))
          .map((text) => text.data)
          .toList();
      expect(characters, equals(['十', '月', '初', '二']));
    });

    testWidgets('outside the lunar data range the 私人日记 card shows the year as the Folio does', (tester) async {
      final outOfRange = DateTime(2200, 6, 1);
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: true,
        clock: () => outOfRange,
      );

      expect(FolioMetadataFormatter.formatFullLunarDate(outOfRange), '岁次庚子');
      expect(find.text('次'), findsOneWidget);
      final lunarColumn = find
          .ancestor(of: find.text('次'), matching: find.byType(Column))
          .first;
      final characters = tester
          .widgetList<Text>(find.descendant(of: lunarColumn, matching: find.byType(Text)))
          .map((text) => text.data)
          .toList();
      expect(characters, equals(['岁', '次', '庚', '子']));
    });

    testWidgets('tapping 私人日记 replaces the cover with the Home Shell 日记 tab', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: true,
      );

      await tester.tap(find.text('私人日记'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('home_tab_rail')), findsOneWidget);
      expect(find.text('暂无日记'), findsOneWidget);
      expect(find.byType(BookIntroScreen, skipOffstage: false), findsNothing);
    });

    testWidgets('swiping left across the book opens it smoothly', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: false,
      );

      await tester.drag(find.byType(Book3DStage), const Offset(-200, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('私人日记'), findsOneWidget);
      expect(find.text('旅行相册'), findsOneWidget);
    });

    testWidgets('tapping bottom seal slider toggles book open and closed', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: false,
      );

      await tester.tap(find.byType(BottomSealSlider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('私人日记'), findsOneWidget);
      expect(find.text('旅行相册'), findsOneWidget);

      await tester.tap(find.byType(BottomSealSlider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('左滑翻开'), findsAtLeast(1));
    });

    testWidgets('tapping directly on the closed book cover opens it', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: false,
      );

      await tester.tap(find.byType(Book3DStage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('私人日记'), findsOneWidget);
      expect(find.text('旅行相册'), findsOneWidget);
    });

    testWidgets('swiping right when opened closes the book', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: true,
      );

      expect(find.text('私人日记'), findsOneWidget);

      await tester.drag(find.byType(Book3DStage), const Offset(200, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('左滑翻开'), findsAtLeast(1));
    });

    testWidgets('dragging bottom slider handle left opens the book', (tester) async {
      await pumpBookIntroScreen(
        tester,
        database: db,
        mediaService: mediaService,
        startOpened: false,
      );

      await tester.drag(find.byType(BottomSealSlider), const Offset(-200, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('私人日记'), findsOneWidget);
      expect(find.text('旅行相册'), findsOneWidget);
    });
  });
}
