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
    testWidgets('decodes {"ops": [...]} envelope and falls back to plainText when malformed', (tester) async {
      final date = DateTime(2026, 10, 18, 20, 0);
      final envelopeEntry = Entry(
        id: 'debrief_env',
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        title: '周述',
        contentDelta: jsonEncode({
          'ops': [
            {'insert': '信封格式复盘正文\n'},
          ],
        }),
        plainText: '旧纯文本',
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
          id: envelopeEntry.id,
          notebookId: envelopeEntry.notebookId,
          templateId: envelopeEntry.templateId,
          title: Value(envelopeEntry.title),
          contentDelta: envelopeEntry.contentDelta,
          plainText: envelopeEntry.plainText,
          entryDate: envelopeEntry.entryDate,
          isWeeklyReview: const Value(true),
          weekNumber: const Value(42),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WeeklyDebriefDetailScreen(
            debriefEntry: envelopeEntry,
            weekEntries: const [],
            year: 2026,
            weekNumber: 42,
            database: db,
            mediaService: mediaService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('信封格式复盘正文', findRichText: true), findsOneWidget);
      expect(find.textContaining('旧纯文本', findRichText: true), findsNothing);
    });

    testWidgets('falls back to plainText when contentDelta is malformed', (tester) async {
      final date = DateTime(2026, 10, 18, 20, 0);
      final malformedEntry = Entry(
        id: 'debrief_malformed',
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        title: '周述',
        contentDelta: '{not-valid-delta',
        plainText: '纯文本兜底复盘',
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
          id: malformedEntry.id,
          notebookId: malformedEntry.notebookId,
          templateId: malformedEntry.templateId,
          title: Value(malformedEntry.title),
          contentDelta: malformedEntry.contentDelta,
          plainText: malformedEntry.plainText,
          entryDate: malformedEntry.entryDate,
          isWeeklyReview: const Value(true),
          weekNumber: const Value(42),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WeeklyDebriefDetailScreen(
            debriefEntry: malformedEntry,
            weekEntries: const [],
            year: 2026,
            weekNumber: 42,
            database: db,
            mediaService: mediaService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('纯文本兜底复盘', findRichText: true), findsOneWidget);
    });
  });
}
