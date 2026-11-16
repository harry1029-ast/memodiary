import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/timeline/screens/timeline_screen.dart';
import 'package:memodiary/features/weekly_review/screens/weekly_review_screen.dart';
import 'package:memodiary/features/timeline/widgets/notebook_selector_sheet.dart';
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

      expect(find.text('MemoDiary'), findsOneWidget);
      expect(find.text('No Diary Entries Yet'), findsOneWidget);
      expect(find.text('Write Your First Entry'), findsOneWidget);
      expect(find.byKey(const Key('timeline_write_fab')), findsOneWidget);
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

      // Normal entry is rendered with snippet and badges
      expect(find.text('Sunshine Walk'), findsOneWidget);
      expect(find.text('Walking in the park with friends.'), findsOneWidget);
      expect(find.text('😄'), findsOneWidget); // Mood 5 emoji

      // Sealed Time Capsule is rendered with capsule banner and countdown
      expect(find.textContaining('TIME CAPSULE'), findsOneWidget);
      expect(find.text('Letter to my 2030 Self'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.textContaining('Unlocks in'), findsOneWidget);

      // Privacy invariant check: The sealed plain text snippet must NOT appear anywhere
      expect(find.text('Deep secret confidential thoughts.'), findsNothing);

      // Tap on sealed Time Capsule opens explanation dialog
      await tester.tap(find.text('Letter to my 2030 Self'));
      await tester.pumpAndSettle();

      expect(find.text('Time Capsule Sealed'), findsOneWidget);
      expect(find.text('Keep Waiting'), findsOneWidget);

      await tester.tap(find.text('Keep Waiting'));
      await tester.pumpAndSettle();
    });

    testWidgets('FAB creates new entry and navigates to editor', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TimelineScreen(
            database: db,
            mediaService: mediaService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Write Diary" FAB
      await tester.tap(find.text('Write Diary'));
      await tester.pumpAndSettle();

      // Editor screen should now be opened
      expect(find.byType(EntryEditorScreen), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
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
      expect(find.text('Weekly Review'), findsOneWidget);
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

      // Verify title is rendered cleanly without overflow
      expect(find.text('MemoDiary'), findsOneWidget);
      expect(find.text('拾光日记'), findsOneWidget);
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

      // Verify title is rendered cleanly without overflow
      expect(find.text('MemoDiary'), findsOneWidget);
      expect(find.text('拾光日记'), findsOneWidget);
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

      // Weather badge contains 烟雨
      expect(find.textContaining('烟雨'), findsAtLeast(1));
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
      await tester.drag(find.byType(ListView), const Offset(0, -450));
      await tester.pumpAndSettle();

      expect(find.byType(ShanshuiSceneryCard), findsNothing);

      // Scroll back up to the top
      await tester.drag(find.byType(ListView), const Offset(0, 450));
      await tester.pumpAndSettle();

      expect(find.byType(ShanshuiSceneryCard), findsOneWidget);
    });

    testWidgets('Active volume BegoniaPlaque button opens NotebookSelectorSheet', (tester) async {
      await pumpTimelineScreen(tester);

      final notebookBtn = find.byKey(const Key('timeline_notebook_selector_button'));
      expect(notebookBtn, findsOneWidget);

      await tester.tap(notebookBtn);
      await tester.pumpAndSettle();

      expect(find.byType(NotebookSelectorSheet), findsOneWidget);
    });
  });
}
