import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/weekly_review/screens/weekly_review_screen.dart';

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mediaService = MediaSandboxService();
  });

  tearDown(() async {
    await db.close();
  });

  group('WeeklyReviewScreen Widget Tests', () {
    testWidgets('renders multiple entries logged on the same weekday without truncation (Watchpoint 1)', (tester) async {
      // ISO Week 42 of 2026: Monday Oct 12 to Sunday Oct 18
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'mon_entry_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Morning Espresso'),
          contentDelta: jsonEncode([{'insert': 'Rich aroma at dawn.\n'}]),
          plainText: 'Rich aroma at dawn.',
          entryDate: DateTime(2026, 10, 12, 8, 30),
          mood: const Value(5),
        ),
      );

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'mon_entry_2',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Evening Run'),
          contentDelta: jsonEncode([{'insert': '5km by the river.\n'}]),
          plainText: '5km by the river.',
          entryDate: DateTime(2026, 10, 12, 19, 15),
          mood: const Value(4),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WeeklyReviewScreen(
            database: db,
            mediaService: mediaService,
            initialYear: 2026,
            initialWeekNumber: 42,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Week 42, 2026'), findsOneWidget);
      expect(find.text('2 Entries'), findsOneWidget);

      // Both Monday entries are rendered inside Monday's card
      expect(find.text('Morning Espresso'), findsOneWidget);
      expect(find.text('Rich aroma at dawn.'), findsOneWidget);
      expect(find.text('Evening Run'), findsOneWidget);
      expect(find.text('5km by the river.'), findsOneWidget);
    });

    testWidgets('week stepper navigates backward and forward across weeks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WeeklyReviewScreen(
            database: db,
            mediaService: mediaService,
            initialYear: 2026,
            initialWeekNumber: 42,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Week 42, 2026'), findsOneWidget);

      // Step to previous week
      await tester.tap(find.byKey(const Key('prev_week_button')));
      await tester.pumpAndSettle();
      expect(find.text('Week 41, 2026'), findsOneWidget);

      // Step forward twice -> Week 43
      await tester.tap(find.byKey(const Key('next_week_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('next_week_button')));
      await tester.pumpAndSettle();
      expect(find.text('Week 43, 2026'), findsOneWidget);
    });

    testWidgets('Start Review creates an isWeeklyReview = true entry and navigates to editor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WeeklyReviewScreen(
            database: db,
            mediaService: mediaService,
            initialYear: 2026,
            initialWeekNumber: 42,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('W42 Debrief Pending'), findsOneWidget);
      expect(find.text('Start Review'), findsOneWidget);

      await tester.tap(find.byKey(const Key('weekly_debrief_action_button')));
      await tester.pumpAndSettle();

      // Editor screen is opened
      expect(find.byType(EntryEditorScreen), findsOneWidget);

      // Verify weekly review entry was created in database
      final debrief = await db.getWeeklyReviewEntry(2026, 42);
      expect(debrief, isNotNull);
      expect(debrief!.isWeeklyReview, isTrue);
      expect(debrief.weekNumber, equals(42));
      expect(debrief.templateId, equals('template_weekly_review'));
    });
  });
}

