import 'dart:math';
import 'package:intl/intl.dart';
import 'package:memodiary/core/database/app_database.dart';

/// Aggregated writing statistics and activity metrics.
class WritingStats {
  final int totalEntries;
  final int totalWords;
  final int currentStreakDays;
  final int longestStreakDays;
  final Map<int, int> moodCounts;
  final Map<String, int> dailyActivityMap;

  const WritingStats({
    required this.totalEntries,
    required this.totalWords,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.moodCounts,
    required this.dailyActivityMap,
  });
}

/// Service that computes offline writing analytics, hybrid CJK/Latin word counts,
/// writing streaks, mood distributions, and daily activity heatmaps.
class AnalyticsService {
  static final RegExp _cjkRegex = RegExp(
    r'[\u4E00-\u9FFF\u3400-\u4DBF\u3040-\u309F\u30A0-\u30FF\uAC00-\uD7AF]',
  );
  static final RegExp _latinWordRegex = RegExp(r"[A-Za-z0-9]+(?:'[A-Za-z0-9]+)?");

  /// Counts both individual CJK ideographs/characters and Latin/alphanumeric words.
  static int countWordsAndCharacters(String text) {
    if (text.trim().isEmpty) return 0;
    final cjkCount = _cjkRegex.allMatches(text).length;
    final withoutCjk = text.replaceAll(_cjkRegex, ' ');
    final latinCount = _latinWordRegex.allMatches(withoutCjk).length;
    return cjkCount + latinCount;
  }

  /// Computes full writing statistics from active (non-deleted) entries in [database].
  static Future<WritingStats> computeStats(
    AppDatabase database, {
    DateTime? referenceToday,
  }) async {
    final entries = await (database.select(database.entries)
          ..where((e) => e.isDeleted.equals(false)))
        .get();

    return computeStatsFromEntries(entries, referenceToday: referenceToday);
  }

  /// Pure computation helper for unit testing and direct list aggregation.
  static WritingStats computeStatsFromEntries(
    List<Entry> entries, {
    DateTime? referenceToday,
  }) {
    final today = referenceToday ?? DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    int totalWords = 0;
    final Map<int, int> moodCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    final Map<String, int> dailyActivityMap = {};
    final Set<DateTime> activeDays = {};

    final dateFormatter = DateFormat('yyyy-MM-dd');

    for (final entry in entries) {
      if (entry.isDeleted) continue;

      final combinedText = '${entry.title ?? ''} ${entry.plainText}';
      totalWords += countWordsAndCharacters(combinedText);

      if (entry.mood != null && moodCounts.containsKey(entry.mood!)) {
        moodCounts[entry.mood!] = moodCounts[entry.mood!]! + 1;
      }

      final localDate = DateTime(
        entry.entryDate.year,
        entry.entryDate.month,
        entry.entryDate.day,
      );
      activeDays.add(localDate);

      final key = dateFormatter.format(localDate);
      dailyActivityMap[key] = (dailyActivityMap[key] ?? 0) + 1;
    }

    // Calculate streaks
    final sortedDays = activeDays.toList()..sort();
    int longestStreak = 0;
    int runningStreak = 0;

    for (int i = 0; i < sortedDays.length; i++) {
      if (i == 0) {
        runningStreak = 1;
      } else {
        final prev = sortedDays[i - 1];
        final curr = sortedDays[i];
        final diffDays = curr.difference(prev).inDays;
        if (diffDays == 1) {
          runningStreak += 1;
        } else if (diffDays > 1) {
          runningStreak = 1;
        }
      }
      longestStreak = max(longestStreak, runningStreak);
    }

    // Calculate current streak (must include today or yesterday)
    int currentStreak = 0;
    final yesterday = normalizedToday.subtract(const Duration(days: 1));
    DateTime? cursor;
    if (activeDays.contains(normalizedToday)) {
      cursor = normalizedToday;
    } else if (activeDays.contains(yesterday)) {
      cursor = yesterday;
    }

    while (cursor != null && activeDays.contains(cursor)) {
      currentStreak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return WritingStats(
      totalEntries: entries.where((e) => !e.isDeleted).length,
      totalWords: totalWords,
      currentStreakDays: currentStreak,
      longestStreakDays: longestStreak,
      moodCounts: moodCounts,
      dailyActivityMap: dailyActivityMap,
    );
  }
}

