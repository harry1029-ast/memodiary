import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Weekly Review Database Query Tests', () {
    test('getEntriesForCalendarWeek respects exact Monday 00:00:00.000 to Sunday 23:59:59.999 bounds (Watchpoint 2)', () async {
      // ISO Week 42 of 2026: Mon Oct 12 00:00:00.000 to Sun Oct 18 23:59:59.999
      // 1. Entry 1ms before Monday start (Sun Oct 11 23:59:59.999 -> Week 41)
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_prev_week_edge',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: '[]',
          plainText: 'Previous week edge',
          entryDate: DateTime(2026, 10, 11, 23, 59, 59, 999),
        ),
      );

      // 2. Entry at exact Monday start (Mon Oct 12 00:00:00.000 -> Week 42)
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_mon_start',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: '[]',
          plainText: 'Monday midnight start',
          entryDate: DateTime(2026, 10, 12, 0, 0, 0, 0),
        ),
      );

      // 3. Multiple entries on Wednesday (Wed Oct 14 -> Week 42)
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_wed_morning',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: '[]',
          plainText: 'Wednesday morning',
          entryDate: DateTime(2026, 10, 14, 9, 0),
        ),
      );
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_wed_night',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: '[]',
          plainText: 'Wednesday night',
          entryDate: DateTime(2026, 10, 14, 22, 30),
        ),
      );

      // 4. Entry at exact Sunday end (Sun Oct 18 23:59:59.999 -> Week 42)
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_sun_end',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: '[]',
          plainText: 'Sunday end of week',
          entryDate: DateTime(2026, 10, 18, 23, 59, 59, 999),
        ),
      );

      // 5. Entry 1ms after Sunday end (Mon Oct 19 00:00:00.000 -> Week 43)
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_next_week_edge',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: '[]',
          plainText: 'Next week edge',
          entryDate: DateTime(2026, 10, 19, 0, 0, 0, 0),
        ),
      );

      // 6. Soft-deleted entry inside Week 42 (must be excluded)
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_deleted_in_week',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          contentDelta: '[]',
          plainText: 'Deleted entry',
          entryDate: DateTime(2026, 10, 15, 12, 0),
          isDeleted: const Value(true),
        ),
      );

      final week42Entries = await db.getEntriesForCalendarWeek(2026, 42);
      expect(
        week42Entries.map((e) => e.id).toList(),
        equals([
          'entry_mon_start',
          'entry_wed_morning',
          'entry_wed_night',
          'entry_sun_end',
        ]),
      );
    });

    test('getWeeklyReviewEntry retrieves existing weekly debrief for target ISO week', () async {
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'debrief_w42_2026',
          notebookId: 'notebook_default',
          templateId: 'template_weekly_review',
          title: const Value('Week 42 Review'),
          contentDelta: '[{"insert":"Highlights of week 42\\n"}]',
          plainText: 'Highlights of week 42',
          entryDate: DateTime(2026, 10, 18, 19, 0),
          isWeeklyReview: const Value(true),
          weekNumber: const Value(42),
        ),
      );

      final found = await db.getWeeklyReviewEntry(2026, 42);
      expect(found, isNotNull);
      expect(found!.id, equals('debrief_w42_2026'));

      final notFoundOtherWeek = await db.getWeeklyReviewEntry(2026, 41);
      expect(notFoundOtherWeek, isNull);

      final notFoundOtherYear = await db.getWeeklyReviewEntry(2025, 42);
      expect(notFoundOtherYear, isNull);
    });
  });
}

