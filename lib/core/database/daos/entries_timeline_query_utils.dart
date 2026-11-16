import 'package:drift/drift.dart';
import '../../../features/timeline/models/timeline_filter_state.dart';
import '../app_database.dart';

/// Builds the Drift filter predicate matching [filters] on [entryTable].
Expression<bool> buildTimelineFilterPredicate({
  required EntriesDao dao,
  required $EntriesTable entryTable,
  required TimelineFilterState filters,
}) {
  Expression<bool> predicate = entryTable.isDeleted.equals(false);

  final range = filters.dateRange();
  if (range != null) {
    predicate = predicate &
        entryTable.entryDate.isBiggerOrEqualValue(range.$1) &
        entryTable.entryDate.isSmallerThanValue(range.$2);
  }
  if (filters.mood != null) {
    predicate = predicate & entryTable.mood.equals(filters.mood!);
  }
  if (filters.weather != null && filters.weather!.isNotEmpty) {
    predicate = predicate & entryTable.weather.equals(filters.weather!);
  }
  if (filters.weeklyReviewOnly) {
    predicate = predicate & entryTable.isWeeklyReview.equals(true);
  }
  if (filters.hasMediaOnly) {
    predicate = predicate &
        existsQuery(
          dao.select(dao.mediaAttachments)
            ..where(
              (attachment) => attachment.entryId.equalsExp(entryTable.id),
            ),
        );
  }
  return predicate;
}

/// Executes a paginated filtered/sorted timeline query against [dao].
Future<List<Entry>> queryFilteredTimelineEntries(
  EntriesDao dao, {
  TimelineFilterState filters = const TimelineFilterState(),
  int limit = 20,
  int offset = 0,
}) {
  final query = dao.select(dao.entries)
    ..where(
      (entry) => buildTimelineFilterPredicate(
        dao: dao,
        entryTable: entry,
        filters: filters,
      ),
    )
    ..orderBy([
      (entry) => filters.sortOrder == TimelineSortOrder.oldestFirst
          ? OrderingTerm.asc(entry.entryDate)
          : OrderingTerm.desc(entry.entryDate),
    ])
    ..limit(limit, offset: offset);
  return query.get();
}

/// Counts all non-deleted entries matching [filters].
Future<int> countMatchingTimelineEntries(
  EntriesDao dao, {
  TimelineFilterState filters = const TimelineFilterState(),
}) async {
  final countExpr = dao.entries.id.count();
  final query = dao.selectOnly(dao.entries)
    ..addColumns([countExpr])
    ..where(
      buildTimelineFilterPredicate(
        dao: dao,
        entryTable: dao.entries,
        filters: filters,
      ),
    );
  final row = await query.getSingle();
  return row.read(countExpr) ?? 0;
}

/// Computes distinct active years (descending, including [currentYear]),
/// populated months `1..12` matching [year] + charm filters, and total active count.
Future<TimelineDateFacetSummary> queryTimelineDateFacetSummary(
  EntriesDao dao, {
  int? year,
  int? mood,
  String? weather,
  bool hasMediaOnly = false,
  bool weeklyReviewOnly = false,
  int? currentYear,
}) async {
  final resolvedCurrentYear = currentYear ?? DateTime.now().year;

  final allDateRows = await (dao.selectOnly(dao.entries)
        ..addColumns([dao.entries.entryDate])
        ..where(dao.entries.isDeleted.equals(false)))
      .get();

  final yearSet = <int>{resolvedCurrentYear};
  for (final row in allDateRows) {
    final entryDate = row.read(dao.entries.entryDate);
    if (entryDate != null) {
      yearSet.add(entryDate.year);
    }
  }
  final sortedYears = yearSet.toList()
    ..sort((yearA, yearB) => yearB.compareTo(yearA));

  final monthFilter = TimelineFilterState(
    year: year,
    mood: mood,
    weather: weather,
    hasMediaOnly: hasMediaOnly,
    weeklyReviewOnly: weeklyReviewOnly,
  );
  final matchingRows = await (dao.selectOnly(dao.entries)
        ..addColumns([dao.entries.entryDate])
        ..where(
          buildTimelineFilterPredicate(
            dao: dao,
            entryTable: dao.entries,
            filters: monthFilter,
          ),
        ))
      .get();

  final activeMonths = <int>{};
  for (final row in matchingRows) {
    final entryDate = row.read(dao.entries.entryDate);
    if (entryDate != null) {
      activeMonths.add(entryDate.month);
    }
  }

  return TimelineDateFacetSummary(
    years: sortedYears,
    activeMonths: activeMonths,
    totalActiveEntries: allDateRows.length,
  );
}
