import 'dart:math';
import 'package:drift/drift.dart';
import '../app_database.dart';

/// Fetches all active entries written on the same month and day in previous
/// calendar years (`entryDate.year < date.year`), including Feb 29 memories
/// on Feb 28 of non-leap years.
Future<List<Entry>> queryEntriesOnThisDay(EntriesDao dao, DateTime date) async {
  final priorYearCutoff = DateTime(date.year, 1, 1);
  final priorCandidates = await (dao.select(dao.entries)
        ..where((entry) =>
            entry.isDeleted.equals(false) &
            entry.entryDate.isSmallerThanValue(priorYearCutoff))
        ..orderBy([(entry) => OrderingTerm.desc(entry.entryDate)]))
      .get();

  final includeLeapFeb29OnFeb28 =
      date.month == 2 && date.day == 28 && !EntriesDao.isLeapYear(date.year);

  return priorCandidates.where((entry) {
    final entryDate = entry.entryDate;
    if (entryDate.month == date.month && entryDate.day == date.day) {
      return true;
    }
    if (includeLeapFeb29OnFeb28 &&
        entryDate.month == 2 &&
        entryDate.day == 29) {
      return true;
    }
    return false;
  }).toList();
}

/// Randomly draws a past active entry written at least [minDaysAgo] days prior
/// to [referenceDate], excluding sealed time capsules.
Future<Entry?> queryRandomOldEntry(
  EntriesDao dao, {
  int minDaysAgo = 90,
  DateTime? referenceDate,
  Random? random,
}) async {
  final now = referenceDate ?? DateTime.now();
  final cutoff = now.subtract(Duration(days: minDaysAgo));

  final candidates = await (dao.select(dao.entries)
        ..where((entry) =>
            entry.isDeleted.equals(false) &
            entry.entryDate.isSmallerOrEqualValue(cutoff) &
            (entry.unlockAt.isNull() |
                entry.unlockAt.isSmallerOrEqualValue(now))))
      .get();

  if (candidates.isEmpty) return null;

  final rng = random ?? Random();
  return candidates[rng.nextInt(candidates.length)];
}
