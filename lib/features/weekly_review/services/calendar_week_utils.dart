import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';

/// Represents the inclusive start (Monday 00:00:00.000) and end (Sunday 23:59:59.999)
/// timestamps of an ISO 8601 calendar week.
class IsoWeekRange {
  final int year;
  final int weekNumber;
  final DateTime start;
  final DateTime end;

  const IsoWeekRange({
    required this.year,
    required this.weekNumber,
    required this.start,
    required this.end,
  });

  /// Returns the 7 normalized calendar dates (Monday through Sunday at 00:00:00.000)
  List<DateTime> get days {
    return List.generate(
      7,
      (index) => DateTime(start.year, start.month, start.day + index),
    );
  }
}

/// Pure ISO 8601 calendar week calculation engine using the official Thursday rule.
/// Immune to Daylight Saving Time (DST) shifts and handles 52/53-week year boundaries.
class CalendarWeekUtils {
  const CalendarWeekUtils._();

  /// Computes the ISO 8601 week-numbering year and week number (1..53) for a given [date].
  static ({int year, int weekNumber}) getIsoWeekAndYear(DateTime date) {
    // Use UTC calendar coordinates to avoid any DST hour-shift anomalies
    final targetUtc = DateTime.utc(date.year, date.month, date.day);
    // In ISO 8601, Monday = 1, Thursday = 4, Sunday = 7.
    // Find the Thursday of the same ISO week.
    final thursdayUtc = DateTime.utc(
      targetUtc.year,
      targetUtc.month,
      targetUtc.day + (4 - targetUtc.weekday),
    );
    final isoYear = thursdayUtc.year;
    final jan1Utc = DateTime.utc(isoYear, 1, 1);
    final weekNumber = ((thursdayUtc.difference(jan1Utc).inDays) ~/ 7) + 1;
    return (year: isoYear, weekNumber: weekNumber);
  }

  /// Computes the ISO 8601 week number (1..53) for [date].
  static int getIsoWeekNumber(DateTime date) =>
      getIsoWeekAndYear(date).weekNumber;

  /// Computes the ISO 8601 week-numbering year for [date].
  static int getIsoWeekYear(DateTime date) => getIsoWeekAndYear(date).year;

  /// Computes the exact Monday 00:00:00.000 to Sunday 23:59:59.999 range
  /// for a given ISO [year] and [weekNumber] using the ISO January 4 / Thursday rule.
  static IsoWeekRange getIsoWeekRange(int year, int weekNumber) {
    // January 4 is always in ISO Week 1 of its year
    final jan4 = DateTime(year, 1, 4);
    final monday = DateTime(
      year,
      1,
      4 - (jan4.weekday - 1) + (weekNumber - 1) * 7,
      0,
      0,
      0,
      0,
    );
    final sunday = DateTime(
      monday.year,
      monday.month,
      monday.day + 6,
      23,
      59,
      59,
      999,
    );
    return IsoWeekRange(
      year: year,
      weekNumber: weekNumber,
      start: monday,
      end: sunday,
    );
  }

  /// Steps forward or backward by [deltaWeeks] from `(year, weekNumber)`,
  /// accurately crossing 52-week and 53-week year boundaries.
  static ({int year, int weekNumber}) getAdjacentWeek(
    int year,
    int weekNumber,
    int deltaWeeks,
  ) {
    final currentRange = getIsoWeekRange(year, weekNumber);
    final targetMonday = DateTime(
      currentRange.start.year,
      currentRange.start.month,
      currentRange.start.day + (deltaWeeks * 7),
    );
    return getIsoWeekAndYear(targetMonday);
  }

  /// Returns the number of ISO weeks (52 or 53) in a given [year].
  static int getWeeksInIsoYear(int year) {
    final dec28 = DateTime(year, 12, 28); // Dec 28 is always in the last ISO week of the year
    return getIsoWeekNumber(dec28);
  }

  /// Normalizes a [DateTime] to midnight local time (`00:00:00.000`).
  static DateTime normalizeToDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Groups a list of entries into a Monday-through-Sunday map keyed by normalized day.
  /// Supports multiple entries per day, preserving chronological order within each day.
  static Map<DateTime, List<Entry>> groupEntriesByWeekday(
    List<Entry> entries,
    int year,
    int weekNumber, {
    bool excludeWeeklyReview = true,
  }) {
    final range = getIsoWeekRange(year, weekNumber);
    final grouped = <DateTime, List<Entry>>{
      for (final day in range.days) day: <Entry>[],
    };

    for (final entry in entries) {
      if (excludeWeeklyReview && entry.isWeeklyReview) {
        continue;
      }
      final dayKey = normalizeToDay(entry.entryDate);
      if (grouped.containsKey(dayKey)) {
        grouped[dayKey]!.add(entry);
      }
    }

    for (final list in grouped.values) {
      list.sort((a, b) => a.entryDate.compareTo(b.entryDate));
    }

    return grouped;
  }

  /// Formats the week range as a human-readable string (e.g., "Oct 12 – Oct 18, 2026").
  static String formatWeekRange(int year, int weekNumber) {
    final range = getIsoWeekRange(year, weekNumber);
    final startFmt = DateFormat('MMM d');
    final endFmt = range.start.year == range.end.year
        ? DateFormat('MMM d, y')
        : DateFormat('MMM d, y');
    if (range.start.year != range.end.year) {
      final startWithYear = DateFormat('MMM d, y').format(range.start);
      return '$startWithYear – ${endFmt.format(range.end)}';
    }
    return '${startFmt.format(range.start)} – ${endFmt.format(range.end)}';
  }
}

