import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/widgets/begonia_plaque_button.dart';
import 'package:memodiary/features/timeline/screens/timeline_screen.dart';
import 'package:memodiary/features/timeline/widgets/chronicle_charm_filter_sheet.dart';
import 'package:memodiary/features/timeline/widgets/timeline_empty_states.dart';
import 'package:memodiary/features/weekly_review/screens/weekly_review_screen.dart';
import 'package:memodiary/features/scenery/screens/contemplation_view_screen.dart';
import 'package:memodiary/features/scenery/widgets/shanshui_scenery_card.dart';

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;

  setUp(() {
    db = AppDatabase.memory();
    mediaService = MediaSandboxService();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpTimelineScreen(
    WidgetTester tester, {
    AppDatabase? database,
    MediaSandboxService? sandboxService,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TimelineScreen(
          database: database ?? db,
          mediaService: sandboxService ?? mediaService,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('TimelineScreen Widget Tests', () {
    testWidgets('displays empty state when no entries exist', (WidgetTester tester) async {
      await pumpTimelineScreen(tester);

      expect(find.text('云皓日记'), findsOneWidget);
      expect(find.text('YUNHAO'), findsOneWidget);
      expect(find.text('云伴皓光 · 收录旅途与心事'), findsOneWidget);
      expect(find.text('MemoDiary'), findsNothing);
      expect(find.text('墨记'), findsNothing);
      expect(find.text('个人离线日记'), findsNothing);
      expect(find.text('日记'), findsOneWidget);
      expect(find.text('共 0 篇'), findsOneWidget);
      expect(find.text('暂无日记'), findsOneWidget);
      expect(find.text('写第一篇日记'), findsOneWidget);
      expect(find.text('写日记'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('renders both normal entry cards and sealed Time Capsule cards with privacy protection', (WidgetTester tester) async {
      final now = DateTime.now();

      // Standard entry
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'normal_entry_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Sunshine Walk'),
          contentDelta: jsonEncode([{'insert': 'Walking in the park with friends.\n'}]),
          plainText: 'Walking in the park with friends.',
          entryDate: now.subtract(const Duration(hours: 2)),
          mood: const Value(5),
          weather: const Value('sunny'),
        ),
      );

      // Sealed Time Capsule
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'sealed_capsule_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Letter to my 2030 Self'),
          contentDelta: jsonEncode([{'insert': 'Deep secret confidential thoughts.\n'}]),
          plainText: 'Deep secret confidential thoughts.',
          entryDate: now.subtract(const Duration(hours: 1)),
          unlockAt: Value(now.add(const Duration(days: 30))),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TimelineScreen(
            database: db,
            mediaService: mediaService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Sealed Time Capsule is rendered with capsule banner and countdown
      expect(find.text('时间胶囊'), findsOneWidget);
      expect(find.text('待解锁'), findsOneWidget);
      expect(find.text('Letter to my 2030 Self'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.textContaining('将于 '), findsOneWidget);
      expect(find.textContaining('天解锁'), findsOneWidget);

      // Privacy invariant check: The sealed plain text snippet must NOT appear anywhere
      expect(find.text('Deep secret confidential thoughts.'), findsNothing);

      // Scroll down slightly so the second entry ("Sunshine Walk") enters the sliver viewport
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -180));
      await tester.pumpAndSettle();

      // Normal entry is rendered with snippet and badges
      expect(find.text('Sunshine Walk'), findsOneWidget);
      expect(find.text('Walking in the park with friends.'), findsOneWidget);
      expect(find.text('😄'), findsOneWidget); // Mood 5 emoji

      // Scroll back up to tap sealed Time Capsule
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 180));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Letter to my 2030 Self'));
      await tester.pumpAndSettle();

      expect(find.text('时间胶囊待解锁'), findsOneWidget);
      expect(find.text('知道了'), findsOneWidget);

      await tester.tap(find.text('知道了'));
      await tester.pumpAndSettle();
    });

    testWidgets('AppBar Weekly Review shortcut navigates to WeeklyReviewScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TimelineScreen(
            database: db,
            mediaService: mediaService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final weeklyBtn = find.byKey(const Key('timeline_weekly_review_button'));
      expect(weeklyBtn, findsOneWidget);

      await tester.tap(weeklyBtn);
      await tester.pumpAndSettle();

      expect(find.byType(WeeklyReviewScreen), findsOneWidget);
      expect(find.text('每周复盘'), findsOneWidget);
    });

    testWidgets('AppBar renders 3 octagonal medallions without back arrow or albums overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TimelineScreen(
            database: db,
            mediaService: mediaService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar actions: Weekly Review, Search, Settings (Albums removed to declutter Title)
      expect(find.byKey(const Key('timeline_weekly_review_button')), findsOneWidget);
      expect(find.byKey(const Key('timeline_search_button')), findsOneWidget);
      expect(find.byKey(const Key('timeline_settings_button')), findsOneWidget);
      expect(find.byKey(const Key('timeline_albums_button')), findsNothing);
      expect(find.byType(BackButton), findsNothing);

      // Verify title, avatar button, and plain tooltips render cleanly
      expect(find.byKey(const Key('timeline_avatar_button')), findsOneWidget);
      expect(find.text('云皓日记'), findsOneWidget);
      expect(find.text('YUNHAO'), findsOneWidget);
      expect(find.text('MemoDiary'), findsNothing);
      expect(find.text('墨记'), findsNothing);
      expect(find.text('个人离线日记'), findsNothing);
      expect(find.byTooltip('每周复盘'), findsOneWidget);
      expect(find.byTooltip('搜索'), findsOneWidget);
      expect(find.byTooltip('设置'), findsOneWidget);
    });

    testWidgets('AppBar renders streamlined actions without overflow on mobile screen width', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: TimelineScreen(
            database: db,
            mediaService: mediaService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar actions: 3 octagonal medallions
      expect(find.byKey(const Key('timeline_weekly_review_button')), findsOneWidget);
      expect(find.byKey(const Key('timeline_search_button')), findsOneWidget);
      expect(find.byKey(const Key('timeline_settings_button')), findsOneWidget);

      // Travel albums button removed to prevent title squishing
      expect(find.byKey(const Key('timeline_albums_button')), findsNothing);

      // Infrequent maintenance actions are no longer cluttering the top bar
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
      expect(find.byIcon(Icons.insights_rounded), findsNothing);

      // Verify title, avatar button, and plain tooltips render cleanly without overflow
      expect(find.byKey(const Key('timeline_avatar_button')), findsOneWidget);
      expect(find.text('云皓日记'), findsOneWidget);
      expect(find.text('YUNHAO'), findsOneWidget);
      expect(find.text('MemoDiary'), findsNothing);
      expect(find.text('墨记'), findsNothing);
      expect(find.text('个人离线日记'), findsNothing);
      expect(find.byTooltip('每周复盘'), findsOneWidget);
      expect(find.byTooltip('搜索'), findsOneWidget);
      expect(find.byTooltip('设置'), findsOneWidget);
    });

    testWidgets('ShanshuiSceneryCard renders unobstructed in header without ThoughtSparkDock', (tester) async {
      await pumpTimelineScreen(tester);

      expect(find.byType(ShanshuiSceneryCard), findsOneWidget);
      expect(find.byKey(const Key('thought_spark_dock')), findsNothing);
      expect(find.byKey(const Key('scenery_pull_cord_handle')), findsOneWidget);
    });

    testWidgets('pull-cord collapses ShanshuiSceneryCard into 44dp bamboo bar and tapping bar restores it', (tester) async {
      await pumpTimelineScreen(tester);

      expect(find.byKey(const Key('scenery_card_expanded')), findsOneWidget);
      expect(find.byKey(const Key('scenery_card_collapsed')), findsNothing);

      // Tap pull-cord
      await tester.tap(find.byKey(const Key('scenery_pull_cord_handle')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scenery_card_collapsed')), findsOneWidget);
      expect(find.byKey(const Key('scenery_card_expanded')), findsNothing);

      // Tap collapsed bamboo bar to restore
      await tester.tap(find.byKey(const Key('scenery_collapsed_blind_bar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scenery_card_expanded')), findsOneWidget);
      expect(find.byKey(const Key('scenery_card_collapsed')), findsNothing);
    });

    testWidgets('tapping scenery area navigates to ContemplationViewScreen', (tester) async {
      await pumpTimelineScreen(tester);

      await tester.tap(find.byKey(const Key('scenery_canvas_tap_target')));
      await tester.pumpAndSettle();

      expect(find.byType(ContemplationViewScreen), findsOneWidget);
      expect(find.byKey(const Key('contemplation_lake_canvas')), findsOneWidget);

      // Close back to timeline
      await tester.tap(find.byKey(const Key('contemplation_close_button')));
      await tester.pumpAndSettle();

      expect(find.byType(TimelineScreen), findsOneWidget);
    });

    testWidgets('ShanshuiSceneryCard reflects recent entry weather tag', (tester) async {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'rainy_entry_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Rainy Day Reflection'),
          contentDelta: jsonEncode([{'insert': 'Listening to the raindrops.\n'}]),
          plainText: 'Listening to the raindrops.',
          entryDate: DateTime.now(),
          weather: const Value('rainy'),
        ),
      );

      await pumpTimelineScreen(tester);

      // Weather badge contains 小雨
      expect(find.textContaining('小雨'), findsAtLeast(1));
    });

    testWidgets('scrolling timeline past header unmounts scenery card and scroll restoration re-renders it', (tester) async {
      // Create several entries so list is scrollable
      for (int i = 0; i < 15; i++) {
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'scroll_entry_$i',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: Value('Entry $i'),
            contentDelta: jsonEncode([{'insert': 'Content for entry $i\n'}]),
            plainText: 'Content for entry $i',
            entryDate: DateTime.now().subtract(Duration(days: i)),
          ),
        );
      }

      await pumpTimelineScreen(tester);

      // Initially scenery card is visible
      expect(find.byType(ShanshuiSceneryCard), findsOneWidget);

      // Scroll down past header
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.byType(ShanshuiSceneryCard), findsNothing);
      // Pinned Chronicle Desk header & Date Index Tray remain visible
      expect(find.byKey(const Key('timeline_date_index_tray')), findsOneWidget);

      // Scroll back up to the top
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 600));
      await tester.pumpAndSettle();

      expect(find.byType(ShanshuiSceneryCard), findsOneWidget);
    });

    testWidgets(
      'Charm filter BegoniaPlaqueButton opens ChronicleCharmFilterSheet, filters timeline, updates month dots, and clears via empty state',
      (tester) async {
        final seeded = [
          (
            id: 'charm_joy_media_nov',
            title: 'Joyful Photo Nov',
            date: DateTime(2026, 11, 10, 9, 0),
            mood: 5,
            weather: 'sunny',
            weekly: false,
            hasMedia: true,
          ),
          (
            id: 'charm_rainy_weekly_oct',
            title: 'Rainy Weekly Oct',
            date: DateTime(2026, 10, 15, 18, 0),
            mood: 3,
            weather: 'rainy',
            weekly: true,
            hasMedia: false,
          ),
          (
            id: 'charm_joy_text_aug',
            title: 'Joyful Text Aug',
            date: DateTime(2026, 8, 5, 12, 0),
            mood: 5,
            weather: 'cloudy',
            weekly: false,
            hasMedia: false,
          ),
        ];

        for (final item in seeded) {
          await db.entriesDao.createEntry(
            EntriesCompanion.insert(
              id: item.id,
              notebookId: 'notebook_default',
              templateId: 'template_minimalist_white',
              title: Value(item.title),
              contentDelta: jsonEncode([
                {'insert': 'Body for ${item.title}\n'},
              ]),
              plainText: 'Body for ${item.title}',
              entryDate: item.date,
              mood: Value(item.mood),
              weather: Value(item.weather),
              isWeeklyReview: Value(item.weekly),
            ),
          );
          if (item.hasMedia) {
            await db.mediaOcrDao.attachMediaToEntry(
              id: 'media_${item.id}',
              entryId: item.id,
              relativePath: 'media/${item.id}.webp',
            );
          }
        }

        await pumpTimelineScreen(tester);

        // Legacy notebook selector button is replaced by charm filter plaque
        expect(
          find.byKey(const Key('timeline_notebook_selector_button')),
          findsNothing,
        );
        final charmBtnFinder = find.byKey(const Key('timeline_charm_filter_button'));
        expect(charmBtnFinder, findsOneWidget);
        expect(find.text('筛选'), findsOneWidget);
        expect(tester.widget<BegoniaPlaqueButton>(charmBtnFinder).isAccent, isFalse);

        final buttonSize = tester.getSize(charmBtnFinder);
        expect(buttonSize.width, greaterThanOrEqualTo(44.0));
        expect(buttonSize.height, greaterThanOrEqualTo(44.0));

        // Open ChronicleCharmFilterSheet
        await tester.tap(charmBtnFinder);
        await tester.pumpAndSettle();
        expect(find.byType(ChronicleCharmFilterSheet), findsOneWidget);

        // Select 喜悦 + 含照片
        await tester.ensureVisible(find.byKey(const Key('charm_filter_mood_5')));
        await tester.tap(find.byKey(const Key('charm_filter_mood_5')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(const Key('charm_filter_media_toggle')));
        await tester.tap(find.byKey(const Key('charm_filter_media_toggle')));
        await tester.pumpAndSettle();

        // Dismiss sheet
        await tester.tap(find.byKey(const Key('charm_filter_close_button')));
        await tester.pumpAndSettle();

        // Begonia plaque shows active summary & cinnabar accent styling
        expect(find.text('喜悦 · 含照片'), findsOneWidget);
        expect(tester.widget<BegoniaPlaqueButton>(charmBtnFinder).isAccent, isTrue);
        expect(find.text('共 1 篇'), findsOneWidget);
        expect(find.text('Joyful Photo Nov'), findsOneWidget);
        expect(find.text('Rainy Weekly Oct'), findsNothing);
        expect(find.text('Joyful Text Aug'), findsNothing);

        // Month presence dots synchronize with active charm filter (Nov has dot, Oct & Aug do not)
        await tester.ensureVisible(find.byKey(const Key('timeline_month_chip_11')));
        expect(find.byKey(const Key('timeline_month_dot_11')), findsOneWidget);
        expect(find.byKey(const Key('timeline_month_dot_10')), findsNothing);
        expect(find.byKey(const Key('timeline_month_dot_8')), findsNothing);

        // Combine with empty month (10月) -> filtered empty card appears
        await tester.ensureVisible(find.byKey(const Key('timeline_month_chip_10')));
        await tester.tap(find.byKey(const Key('timeline_month_chip_10')));
        await tester.pumpAndSettle();
        expect(find.text('共 0 篇'), findsOneWidget);
        expect(find.text('当前筛选条件下暂无日记'), findsOneWidget);

        // Tap 清除筛选 -> resets BOTH Date Index Tray AND Charm & Tag Filter
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -180));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('timeline_clear_filters_button')));
        await tester.pumpAndSettle();

        expect(find.text('筛选'), findsOneWidget);
        expect(tester.widget<BegoniaPlaqueButton>(charmBtnFinder).isAccent, isFalse);
        expect(find.text('共 3 篇'), findsOneWidget);
        expect(find.text('上旬'), findsNothing);
        expect(find.text('Rainy Weekly Oct'), findsOneWidget);

        // Also test Weather + Weekly Review filtering via sheet
        await tester.tap(charmBtnFinder);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('charm_filter_weather_rainy')));
        await tester.tap(find.byKey(const Key('charm_filter_weather_rainy')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('charm_filter_weekly_toggle')));
        await tester.tap(find.byKey(const Key('charm_filter_weekly_toggle')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('charm_filter_close_button')));
        await tester.pumpAndSettle();

        expect(find.text('下雨 · 每周复盘'), findsOneWidget);
        expect(find.text('共 1 篇'), findsOneWidget);
        expect(find.text('Rainy Weekly Oct'), findsOneWidget);
      },
    );

    testWidgets(
      'ChronicleDeskHeader charm filter plaque never overflows on 320dp viewport at 1.6x text scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.6),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            home: TimelineScreen(
              database: db,
              mediaService: mediaService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('timeline_charm_filter_button')));
        await tester.pumpAndSettle();

        // Select all 4 charm filters to stress-test the summary plaque width
        await tester.ensureVisible(find.byKey(const Key('charm_filter_mood_5')));
        await tester.tap(find.byKey(const Key('charm_filter_mood_5')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('charm_filter_weather_sunny')));
        await tester.tap(find.byKey(const Key('charm_filter_weather_sunny')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('charm_filter_media_toggle')));
        await tester.tap(find.byKey(const Key('charm_filter_media_toggle')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('charm_filter_weekly_toggle')));
        await tester.tap(find.byKey(const Key('charm_filter_weekly_toggle')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('charm_filter_close_button')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('timeline_charm_filter_button')), findsOneWidget);

        // Expand 三旬 at 320dp + 2.0x text scale to verify zero header sliver overflow
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2.0),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
            home: TimelineScreen(
              database: db,
              mediaService: mediaService,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('timeline_month_chip_11')));
        await tester.tap(find.byKey(const Key('timeline_month_chip_11')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('timeline_xun_chip_shang')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('removes OnThisDayBanner and poetic header while rendering WindowSillLedge and candlestick glow toggle', (tester) async {
      final lastYearToday = DateTime.now().subtract(const Duration(days: 365));
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'past_year_entry',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Last Year Memory'),
          contentDelta: jsonEncode([{'insert': 'A year ago today.\n'}]),
          plainText: 'A year ago today.',
          entryDate: lastYearToday,
        ),
      );

      await pumpTimelineScreen(tester);

      // Legacy retrospection & poetic header are gone
      expect(find.textContaining('岁时忆昔'), findsNothing);
      expect(find.text('忆昔'), findsNothing);
      expect(find.text('岁月微澜'), findsNothing);
      expect(find.text('研墨静思'), findsNothing);

      // Window Sill Ledge is present below scenery
      expect(find.byKey(const Key('timeline_window_sill_ledge')), findsOneWidget);
      expect(find.byKey(const Key('timeline_candlestick_button')), findsOneWidget);

      // Candlelight glow starts lit, is scoped strictly below WindowSillLedge, and toggles off/on
      final sillRect = tester.getRect(find.byKey(const Key('timeline_window_sill_ledge')));
      final glowFinder = find.byKey(const Key('timeline_candle_glow_overlay'));
      expect(glowFinder, findsOneWidget);
      final glowRect = tester.getRect(glowFinder);
      expect(glowRect.top, greaterThanOrEqualTo(sillRect.bottom));

      // Brass grommet center aligns horizontally with the vertical spine line
      final grommetCenter = tester.getCenter(
        find.byKey(const Key('timeline_brass_grommet_knot')),
      );
      final spineLineCenter = tester.getCenter(
        find.byKey(const Key('timeline_date_spine_line')).first,
      );
      expect(grommetCenter.dx, closeTo(spineLineCenter.dx, 1.0));

      await tester.tap(find.byKey(const Key('timeline_candlestick_button')));
      await tester.pumpAndSettle();
      expect(glowFinder, findsNothing);

      await tester.tap(find.byKey(const Key('timeline_candlestick_button')));
      await tester.pumpAndSettle();
      expect(glowFinder, findsOneWidget);
    });

    testWidgets('DateIndexTray filters by year, auto-promotes year on month tap, expands 三旬, toggles sort, and recovers from filtered empty state', (tester) async {
      final seeded = [
        (id: 'e_2026_11_05', title: 'Early Nov Entry', date: DateTime(2026, 11, 5, 9, 0)),
        (id: 'e_2026_11_15', title: 'Mid Nov Entry', date: DateTime(2026, 11, 15, 14, 0)),
        (id: 'e_2026_11_25', title: 'Late Nov Entry', date: DateTime(2026, 11, 25, 20, 0)),
        (id: 'e_2025_09_09', title: 'Autumn 2025 Entry', date: DateTime(2025, 9, 9, 18, 0)),
      ];
      for (final item in seeded) {
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: item.id,
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: Value(item.title),
            contentDelta: jsonEncode([{'insert': 'Body for ${item.title}\n'}]),
            plainText: 'Body for ${item.title}',
            entryDate: item.date,
          ),
        );
      }

      await pumpTimelineScreen(tester);

      // Default state: 全部, 最新 ↓, 三旬 collapsed, all 4 entries shown
      expect(find.text('共 4 篇'), findsOneWidget);
      expect(find.text('上旬'), findsNothing);
      expect(find.text('Late Nov Entry'), findsOneWidget);

      // Tap 11月 while year is 全部 -> auto-promotes year to 2026 and expands 三旬
      await tester.ensureVisible(find.byKey(const Key('timeline_month_chip_11')));
      await tester.tap(find.byKey(const Key('timeline_month_chip_11')));
      await tester.pumpAndSettle();

      expect(find.text('共 3 篇'), findsOneWidget);
      expect(find.text('上旬'), findsOneWidget);
      expect(find.text('1–10日'), findsOneWidget);
      expect(find.text('中旬'), findsOneWidget);
      expect(find.text('11–20日'), findsOneWidget);
      expect(find.text('下旬'), findsOneWidget);
      expect(find.text('21日–月底'), findsOneWidget);
      expect(find.text('Autumn 2025 Entry'), findsNothing);

      // Tap 上旬 -> only Early Nov Entry remains
      await tester.tap(find.byKey(const Key('timeline_xun_chip_shang')));
      await tester.pumpAndSettle();

      expect(find.text('共 1 篇'), findsOneWidget);
      expect(find.text('Early Nov Entry'), findsOneWidget);
      expect(find.text('Mid Nov Entry'), findsNothing);

      // Tap an empty month (3月) -> shows filtered empty card (not 暂无日记)
      await tester.ensureVisible(find.byKey(const Key('timeline_month_chip_3')));
      await tester.tap(find.byKey(const Key('timeline_month_chip_3')));
      await tester.pumpAndSettle();

      expect(find.text('共 0 篇'), findsOneWidget);
      expect(find.text('当前筛选条件下暂无日记'), findsOneWidget);
      expect(find.text('暂无日记'), findsNothing);

      // Scroll slightly so 清除筛选 sits well inside the viewport, then tap
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -180));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('timeline_clear_filters_button')));
      await tester.pumpAndSettle();

      expect(find.text('共 4 篇'), findsOneWidget);
      expect(find.text('上旬'), findsNothing);
      expect(find.text('Autumn 2025 Entry'), findsOneWidget);

      // Toggle sort order -> oldestFirst puts Autumn 2025 Entry at the top
      await tester.tap(find.byKey(const Key('timeline_sort_toggle_button')));
      await tester.pumpAndSettle();

      expect(find.text('最早'), findsOneWidget);
      final oldestTop = tester.getTopLeft(find.text('Autumn 2025 Entry')).dy;
      final newestTop = tester.getTopLeft(find.text('Late Nov Entry')).dy;
      expect(oldestTop, lessThan(newestTop));
    });

    testWidgets('TimelineErrorState renders plain Chinese 加载失败 and 重试', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimelineErrorState(
              errorMessage: 'Database unavailable',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
      await tester.tap(find.text('重试'));
      expect(retried, isTrue);
    });
  });
}
