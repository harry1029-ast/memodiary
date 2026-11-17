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
      await db.entriesDao.createEntry(
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

      await db.entriesDao.createEntry(
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

      expect(find.text('每周复盘'), findsOneWidget);
      expect(find.text('本周每日记录'), findsOneWidget);
      expect(find.text('2026年 第42周'), findsOneWidget);
      expect(find.text('2026年10月12日 – 10月18日'), findsOneWidget);
      expect(find.text('2 篇日记'), findsOneWidget);

      // Both Monday entries are rendered inside Monday's card
      expect(find.text('Morning Espresso'), findsOneWidget);
      expect(find.text('Rich aroma at dawn.'), findsOneWidget);
      expect(find.text('Evening Run'), findsOneWidget);
      expect(find.text('5km by the river.'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('weekday_card_2')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('今日暂无记录'), findsWidgets);
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

      expect(find.text('2026年 第42周'), findsOneWidget);

      // Step to previous week
      await tester.tap(find.byKey(const Key('prev_week_button')));
      await tester.pumpAndSettle();
      expect(find.text('2026年 第41周'), findsOneWidget);

      // Step forward twice -> Week 43
      await tester.tap(find.byKey(const Key('next_week_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('next_week_button')));
      await tester.pumpAndSettle();
      expect(find.text('2026年 第43周'), findsOneWidget);
    });

    testWidgets('Start Review creates an isWeeklyReview = true entry titled 第N周复盘 and navigates to editor', (tester) async {
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

      expect(find.text('写本周复盘'), findsOneWidget);

      await tester.tap(find.byKey(const Key('weekly_debrief_action_button')));
      await tester.pumpAndSettle();

      // Editor screen is opened
      expect(find.byType(EntryEditorScreen), findsOneWidget);

      // Verify weekly review entry was created in database with plain default title
      final debrief = await db.entriesDao.getWeeklyReviewEntry(2026, 42);
      expect(debrief, isNotNull);
      expect(debrief!.isWeeklyReview, isTrue);
      expect(debrief.weekNumber, equals(42));
      expect(debrief.title, equals('第42周复盘'));
      expect(debrief.templateId, equals('template_weekly_review'));
    });

    testWidgets('preserves existing saved weekly debrief title and shows 已完成 and 查看复盘', (tester) async {
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'existing_debrief_w42',
          notebookId: 'notebook_default',
          templateId: 'template_weekly_review',
          title: const Value('第42周 · 周志复盘'),
          contentDelta: jsonEncode([{'insert': '旧日已保存复盘正文\n'}]),
          plainText: '旧日已保存复盘正文',
          entryDate: DateTime(2026, 10, 18, 20, 0),
          isWeeklyReview: const Value(true),
          weekNumber: const Value(42),
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

      expect(find.text('已完成'), findsOneWidget);
      expect(find.text('查看复盘'), findsOneWidget);
      expect(find.text('第42周 · 周志复盘'), findsOneWidget);
    });
  });
}

