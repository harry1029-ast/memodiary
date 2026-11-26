import 'package:drift/drift.dart';
import '../../../features/timeline/models/timeline_date_index_entry.dart';
import '../../../features/timeline/models/timeline_entry_summary.dart';
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

/// Executes a paginated filtered/sorted timeline summary projection omitting
/// `content_delta` and capping `plain_text` to [snippetMaxLength] characters.
Future<List<TimelineEntrySummary>> queryFilteredTimelineSummaries(
  EntriesDao dao, {
  TimelineFilterState filters = const TimelineFilterState(),
  int limit = 20,
  int offset = 0,
  int snippetMaxLength = TimelineEntrySummary.defaultSnippetMaxLength,
}) async {
  final entryTable = dao.entries;
  final cappedLength = snippetMaxLength < 0 ? 0 : snippetMaxLength;
  final snippetExpr = FunctionCallExpression<String>(
    'substr',
    [entryTable.plainText, const Constant<int>(1), Constant<int>(cappedLength)],
  );

  final query = dao.selectOnly(entryTable)
    ..addColumns([
      entryTable.id,
      entryTable.title,
      snippetExpr,
      entryTable.entryDate,
      entryTable.mood,
      entryTable.weather,
      entryTable.isLocked,
      entryTable.isWeeklyReview,
      entryTable.weekNumber,
      entryTable.unlockAt,
      entryTable.isDeleted,
    ])
    ..where(
      buildTimelineFilterPredicate(
        dao: dao,
        entryTable: entryTable,
        filters: filters,
      ),
    )
    ..orderBy([
      filters.sortOrder == TimelineSortOrder.oldestFirst
          ? OrderingTerm.asc(entryTable.entryDate)
          : OrderingTerm.desc(entryTable.entryDate),
    ])
    ..limit(limit, offset: offset);

  final rows = await query.get();
  return rows.map((row) {
    return TimelineEntrySummary(
      id: row.read(entryTable.id)!,
      title: row.read(entryTable.title),
      plainTextSnippet: row.read(snippetExpr) ?? '',
      entryDate: row.read(entryTable.entryDate)!,
      mood: row.read(entryTable.mood),
      weather: row.read(entryTable.weather),
      isLocked: row.read(entryTable.isLocked) ?? false,
      isWeeklyReview: row.read(entryTable.isWeeklyReview) ?? false,
      weekNumber: row.read(entryTable.weekNumber),
      unlockAt: row.read(entryTable.unlockAt),
      isDeleted: row.read(entryTable.isDeleted) ?? false,
    );
  }).toList();
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
/// populated months `1..12` matching [filters] (year + charm attributes), and total active count.
Future<TimelineDateFacetSummary> queryTimelineDateFacetSummary(
  EntriesDao dao, {
  TimelineFilterState filters = const TimelineFilterState(),
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
    year: filters.year,
    mood: filters.mood,
    weather: filters.weather,
    hasMediaOnly: filters.hasMediaOnly,
    weeklyReviewOnly: filters.weeklyReviewOnly,
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

/// Executes a lightweight ordered date-index query returning only `(id, entryDate)`
/// pairs matching [filters] in the active sort order.
Future<List<TimelineDateIndexEntry>> queryFilteredTimelineDateIndex(
  EntriesDao dao, {
  TimelineFilterState filters = const TimelineFilterState(),
}) async {
  final entryTable = dao.entries;
  final query = dao.selectOnly(entryTable)
    ..addColumns([
      entryTable.id,
      entryTable.entryDate,
    ])
    ..where(
      buildTimelineFilterPredicate(
        dao: dao,
        entryTable: entryTable,
        filters: filters,
      ),
    )
    ..orderBy([
      filters.sortOrder == TimelineSortOrder.oldestFirst
          ? OrderingTerm.asc(entryTable.entryDate)
          : OrderingTerm.desc(entryTable.entryDate),
    ]);

  final rows = await query.get();
  return rows.map((row) {
    return TimelineDateIndexEntry(
      id: row.read(entryTable.id)!,
      entryDate: row.read(entryTable.entryDate)!,
    );
  }).toList();
}
