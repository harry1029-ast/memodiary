import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/weekly_review/services/calendar_week_utils.dart';

void main() {
  group('CalendarWeekUtils ISO 8601 Week Engine Tests', () {
    test('accurately computes ISO week and year across year boundaries (Thursday rule)', () {
      // 2026-01-01 is a Thursday -> Week 1 of 2026 starts on Monday 2025-12-29
      expect(
        CalendarWeekUtils.getIsoWeekAndYear(DateTime(2025, 12, 28)),
        equals((year: 2025, weekNumber: 52)),
      );
      expect(
        CalendarWeekUtils.getIsoWeekAndYear(DateTime(2025, 12, 29)),
        equals((year: 2026, weekNumber: 1)),
      );
      expect(
        CalendarWeekUtils.getIsoWeekAndYear(DateTime(2026, 1, 1)),
        equals((year: 2026, weekNumber: 1)),
      );
      expect(
        CalendarWeekUtils.getIsoWeekAndYear(DateTime(2026, 1, 4)),
        equals((year: 2026, weekNumber: 1)),
      );
      expect(
        CalendarWeekUtils.getIsoWeekAndYear(DateTime(2026, 1, 5)),
        equals((year: 2026, weekNumber: 2)),
      );

      // 2026 has 53 ISO weeks because 2026-12-31 is a Thursday!
      // Therefore Friday 2027-01-01 through Sunday 2027-01-03 belong to Week 53 of 2026!
      expect(CalendarWeekUtils.getWeeksInIsoYear(2026), equals(53));
      expect(
        CalendarWeekUtils.getIsoWeekAndYear(DateTime(2026, 12, 31)),
        equals((year: 2026, weekNumber: 53)),
      );
      expect(
        CalendarWeekUtils.getIsoWeekAndYear(DateTime(2027, 1, 1)),
        equals((year: 2026, weekNumber: 53)),
      );
      expect(
        CalendarWeekUtils.getIsoWeekAndYear(DateTime(2027, 1, 3)),
        equals((year: 2026, weekNumber: 53)),
      );
      expect(
        CalendarWeekUtils.getIsoWeekAndYear(DateTime(2027, 1, 4)),
        equals((year: 2027, weekNumber: 1)),
      );
    });

    test('getIsoWeekRange returns exact millisecond boundaries from Monday 00:00:00.000 to Sunday 23:59:59.999', () {
      // Week 42 of 2026: Monday Oct 12, 2026 to Sunday Oct 18, 2026
      final range = CalendarWeekUtils.getIsoWeekRange(2026, 42);

      expect(range.start, equals(DateTime(2026, 10, 12, 0, 0, 0, 0)));
      expect(range.end, equals(DateTime(2026, 10, 18, 23, 59, 59, 999)));
      expect(range.start.weekday, equals(DateTime.monday));
      expect(range.end.weekday, equals(DateTime.sunday));

      final days = range.days;
      expect(days.length, equals(7));
      expect(days.first, equals(DateTime(2026, 10, 12)));
      expect(days.last, equals(DateTime(2026, 10, 18)));
    });

    test('getAdjacentWeek steps cleanly across 52-week and 53-week year boundaries', () {
      // Stepping back from Week 1 of 2026 -> Week 52 of 2025
      expect(
        CalendarWeekUtils.getAdjacentWeek(2026, 1, -1),
        equals((year: 2025, weekNumber: 52)),
      );

      // Stepping forward from Week 52 of 2025 -> Week 1 of 2026
      expect(
        CalendarWeekUtils.getAdjacentWeek(2025, 52, 1),
        equals((year: 2026, weekNumber: 1)),
      );

      // Stepping forward from Week 52 of 2026 -> Week 53 of 2026
      expect(
        CalendarWeekUtils.getAdjacentWeek(2026, 52, 1),
        equals((year: 2026, weekNumber: 53)),
      );

      // Stepping forward from Week 53 of 2026 -> Week 1 of 2027
      expect(
        CalendarWeekUtils.getAdjacentWeek(2026, 53, 1),
        equals((year: 2027, weekNumber: 1)),
      );
    });

    test('groupEntriesByWeekday preserves multiple entries on the same day in chronological order', () {
      final now = DateTime.now();
      final entries = [
        Entry(
          id: 'e_mon_evening',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: 'Evening Walk',
          contentDelta: '[]',
          plainText: 'Evening walk thoughts',
          entryDate: DateTime(2026, 10, 12, 20, 30),
          mood: 5,
          weather: 'clear',
          isWeeklyReview: false,
          weekNumber: null,
          unlockAt: null,
          isLocked: false,
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        ),
        Entry(
          id: 'e_mon_morning',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: 'Morning Coffee',
          contentDelta: '[]',
          plainText: 'Morning coffee notes',
          entryDate: DateTime(2026, 10, 12, 8, 15),
          mood: 4,
          weather: 'sunny',
          isWeeklyReview: false,
          weekNumber: null,
          unlockAt: null,
          isLocked: false,
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        ),
        Entry(
          id: 'e_weekly_debrief',
          notebookId: 'notebook_default',
          templateId: 'template_weekly_review',
          title: 'Week 42 Review',
          contentDelta: '[]',
          plainText: 'Debrief content',
          entryDate: DateTime(2026, 10, 18, 21, 0),
          mood: 5,
          weather: null,
          isWeeklyReview: true,
          weekNumber: 42,
          unlockAt: null,
          isLocked: false,
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        ),
      ];

      final grouped = CalendarWeekUtils.groupEntriesByWeekday(entries, 2026, 42);
      expect(grouped.length, equals(7));

      final mondayEntries = grouped[DateTime(2026, 10, 12)]!;
      expect(mondayEntries.length, equals(2));
      expect(mondayEntries[0].id, equals('e_mon_morning'));
      expect(mondayEntries[1].id, equals('e_mon_evening'));

      // Weekly review entry is excluded from daily weekday cards by default
      final sundayEntries = grouped[DateTime(2026, 10, 18)]!;
      expect(sundayEntries, isEmpty);
    });
  });
}

