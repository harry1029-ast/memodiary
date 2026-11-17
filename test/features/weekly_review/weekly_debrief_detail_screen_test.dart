import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/weekly_review/screens/weekly_debrief_detail_screen.dart';

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

  group('WeeklyDebriefDetailScreen Delta Decoding', () {
    Future<void> pumpWeeklyDebriefDetailScreen(
      WidgetTester tester, {
      required String id,
      required String contentDelta,
      required String plainText,
    }) async {
      final date = DateTime(2026, 10, 18, 20, 0);
      final entry = Entry(
        id: id,
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        title: '周述',
        contentDelta: contentDelta,
        plainText: plainText,
        entryDate: date,
        mood: 4,
        weather: '晴',
        isWeeklyReview: true,
        weekNumber: 42,
        isLocked: false,
        legacyMountsPending: false,
        unlockAt: null,
        createdAt: date,
        updatedAt: date,
        isDeleted: false,
      );

      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: entry.id,
          notebookId: entry.notebookId,
          templateId: entry.templateId,
          title: Value(entry.title),
          contentDelta: entry.contentDelta,
          plainText: entry.plainText,
          entryDate: entry.entryDate,
          isWeeklyReview: const Value(true),
          weekNumber: const Value(42),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WeeklyDebriefDetailScreen(
            debriefEntry: entry,
            weekEntries: const [],
            year: 2026,
            weekNumber: 42,
            database: db,
            mediaService: mediaService,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('decodes {"ops": [...]} envelope and falls back to plainText when malformed', (tester) async {
      await pumpWeeklyDebriefDetailScreen(
        tester,
        id: 'debrief_env',
        contentDelta: jsonEncode({
          'ops': [
            {'insert': '信封格式复盘正文\n'},
          ],
        }),
        plainText: '旧纯文本',
      );

      expect(find.textContaining('信封格式复盘正文', findRichText: true), findsOneWidget);
      expect(find.textContaining('旧纯文本', findRichText: true), findsNothing);
    });

    testWidgets('falls back to plainText when contentDelta is malformed', (tester) async {
      await pumpWeeklyDebriefDetailScreen(
        tester,
        id: 'debrief_malformed',
        contentDelta: '{not-valid-delta',
        plainText: '纯文本兜底复盘',
      );

      expect(find.textContaining('纯文本兜底复盘', findRichText: true), findsOneWidget);
    });

    testWidgets('renders plain Chinese weekly debrief labels and preserves saved entry title', (tester) async {
      await pumpWeeklyDebriefDetailScreen(
        tester,
        id: 'debrief_plain_labels',
        contentDelta: jsonEncode([
          {'insert': '复盘内容\n'},
        ]),
        plainText: '复盘内容',
      );

      expect(find.text('每周复盘'), findsOneWidget);
      expect(find.text('已完成'), findsOneWidget);
      expect(find.text('本周概览'), findsOneWidget);
      expect(find.text('篇日记'), findsOneWidget);
      expect(find.text('字'), findsOneWidget);
      expect(find.text('写作天数'), findsOneWidget);
      expect(find.text('本周总结'), findsOneWidget);
      expect(find.text('分享'), findsOneWidget);
      expect(find.text('继续编辑'), findsOneWidget);
      expect(find.text('周述'), findsOneWidget);
    });
  });
}
