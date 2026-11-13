import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/analytics/services/analytics_service.dart';

void main() {
  group('AnalyticsService Unit Tests', () {
    test('countWordsAndCharacters accurately counts Latin words, CJK characters, and mixed text', () {
      expect(AnalyticsService.countWordsAndCharacters(''), 0);
      expect(AnalyticsService.countWordsAndCharacters('   '), 0);
      expect(
        AnalyticsService.countWordsAndCharacters('Hello world from MemoDiary'),
        4,
      );
      // 4 Chinese characters: "今天天气"
      expect(AnalyticsService.countWordsAndCharacters('今天天气'), 4);
      // Mixed: "Today 写了 2 篇 diary" -> 3 Latin/num tokens ("Today", "2", "diary") + 3 CJK ("写", "了", "篇") = 6
      expect(
        AnalyticsService.countWordsAndCharacters('Today 写了 2 篇 diary'),
        6,
      );
    });

    test('computeStatsFromEntries calculates streaks, mood distribution, and daily activity map', () {
      final refToday = DateTime(2026, 10, 18);

      Entry makeEntry({
        required String id,
        required DateTime date,
        String title = '',
        String body = 'Hello world',
        int? mood,
        bool isDeleted = false,
      }) {
        return Entry(
          id: id,
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: title,
          contentDelta: '[]',
          plainText: body,
          entryDate: date,
          mood: mood,
          weather: null,
          isWeeklyReview: false,
          weekNumber: null,
          unlockAt: null,
          isLocked: false,
          legacyMountsPending: false,
          entryPinHash: null,
          createdAt: date,
          updatedAt: date,
          isDeleted: isDeleted,
        );
      }

      final entries = [
        // 3-day current streak: Oct 16, Oct 17, Oct 18
        makeEntry(
          id: 'e1',
          date: DateTime(2026, 10, 18, 9, 0),
          title: 'Day 3',
          body: '今天开心', // 2 Latin ("Day", "3") + 4 CJK = 6
          mood: 5,
        ),
        makeEntry(
          id: 'e2',
          date: DateTime(2026, 10, 17, 20, 0),
          body: 'One two three', // 3 words
          mood: 4,
        ),
        makeEntry(
          id: 'e3',
          date: DateTime(2026, 10, 16, 18, 0),
          body: 'Four five', // 2 words
          mood: 5,
        ),
        // Earlier 4-day streak in September: Sep 1, 2, 3, 4
        makeEntry(id: 's1', date: DateTime(2026, 9, 1), body: 'a', mood: 3),
        makeEntry(id: 's2', date: DateTime(2026, 9, 2), body: 'b', mood: 3),
        makeEntry(id: 's3', date: DateTime(2026, 9, 3), body: 'c', mood: 2),
        makeEntry(id: 's4', date: DateTime(2026, 9, 4), body: 'd', mood: 1),
        // Soft-deleted entry should be ignored
        makeEntry(
          id: 'del',
          date: DateTime(2026, 10, 15),
          body: 'Should not count',
          mood: 5,
          isDeleted: true,
        ),
      ];

      final stats = AnalyticsService.computeStatsFromEntries(
        entries,
        referenceToday: refToday,
      );

      expect(stats.totalEntries, 7);
      expect(stats.totalWords, 6 + 3 + 2 + 4);
      expect(stats.currentStreakDays, 3);
      expect(stats.longestStreakDays, 4);
      expect(stats.moodCounts[5], 2);
      expect(stats.moodCounts[4], 1);
      expect(stats.moodCounts[3], 2);
      expect(stats.moodCounts[2], 1);
      expect(stats.moodCounts[1], 1);
      expect(stats.dailyActivityMap['2026-10-18'], 1);
      expect(stats.dailyActivityMap.containsKey('2026-10-15'), isFalse);
    });

    test('computeStats reads active entries via EntriesDao and ignores soft-deleted rows', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final refToday = DateTime(2026, 10, 18);
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'active_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Sunny'),
          contentDelta: '[{"insert":"Walked outside\\n"}]',
          plainText: 'Walked outside',
          entryDate: DateTime(2026, 10, 18, 9, 0),
          mood: const Value(5),
        ),
      );
      await db.entriesDao.createEntry(
        EntriesCompanion.insert(
          id: 'deleted_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Deleted'),
          contentDelta: '[{"insert":"Ignored text\\n"}]',
          plainText: 'Ignored text',
          entryDate: DateTime(2026, 10, 17, 9, 0),
          mood: const Value(1),
          isDeleted: const Value(true),
        ),
      );

      final stats = await AnalyticsService.computeStats(
        db,
        referenceToday: refToday,
      );

      expect(stats.totalEntries, 1);
      expect(stats.totalWords, 3); // "Sunny" (1) + "Walked outside" (2)
      expect(stats.currentStreakDays, 1);
      expect(stats.moodCounts[5], 1);
      expect(stats.moodCounts[1], 0);
    });
  });
}

