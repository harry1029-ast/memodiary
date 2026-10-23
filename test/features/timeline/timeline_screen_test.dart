import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/albums/screens/album_collections_screen.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/timeline/screens/timeline_screen.dart';
import 'package:memodiary/features/weekly_review/screens/weekly_review_screen.dart';

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

  group('TimelineScreen Widget Tests', () {
    testWidgets('displays empty state when no entries exist', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TimelineScreen(
            database: db,
            mediaService: mediaService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('MemoDiary'), findsOneWidget);
      expect(find.text('No Diary Entries Yet'), findsOneWidget);
      expect(find.text('Write Your First Entry'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('renders both normal entry cards and sealed Time Capsule cards with privacy protection', (WidgetTester tester) async {
      final now = DateTime.now();

      // Standard entry
      await db.createEntry(
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
      await db.createEntry(
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
      expect(find.text('TIME CAPSULE'), findsOneWidget);
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

    testWidgets('AppBar Travel Albums shortcut navigates to AlbumCollectionsScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TimelineScreen(
            database: db,
            mediaService: mediaService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final albumsBtn = find.byKey(const Key('timeline_albums_button'));
      expect(albumsBtn, findsOneWidget);

      await tester.tap(albumsBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AlbumCollectionsScreen), findsOneWidget);
      expect(find.text('旅行影集'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
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

      // Top bar actions: Travel Albums, Weekly Review, Search, Settings
      expect(find.byKey(const Key('timeline_albums_button')), findsOneWidget);
      expect(find.byKey(const Key('timeline_weekly_review_button')), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      // Infrequent maintenance actions are no longer cluttering the top bar
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
      expect(find.byIcon(Icons.insights_rounded), findsNothing);

      // Verify title is rendered cleanly without overflow
      expect(find.text('MemoDiary'), findsOneWidget);
      expect(find.text('拾光日记'), findsOneWidget);
    });
  });
}
