import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/timeline/models/timeline_date_index_entry.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_summary.dart';
import 'package:memodiary/features/timeline/models/timeline_filter_state.dart';
import 'package:uuid/uuid.dart';

/// Snapshot returned when loading or refreshing the `Chronicle Desk` timeline.
@immutable
class TimelineFeedSnapshot {
  final List<TimelineEntrySummary> entries;
  final List<TimelineDateIndexEntry> dateIndex;
  final TimelineDateFacetSummary facetSummary;
  final int totalFilteredCount;
  final Map<String, MediaAttachment> mediaMap;
  final List<TimelineEntrySummary>? recentSceneryEntries;
  final Notebook? activeNotebook;

  const TimelineFeedSnapshot({
    required this.entries,
    required this.dateIndex,
    required this.facetSummary,
    required this.totalFilteredCount,
    required this.mediaMap,
    required this.recentSceneryEntries,
    required this.activeNotebook,
  });
}

/// Fetches a full initial/refreshed snapshot for [TimelineScreen] using
/// lightweight summary and date-index projections.
Future<TimelineFeedSnapshot> loadTimelineFeedSnapshot({
  required AppDatabase database,
  required TimelineFilterState filters,
  required int limit,
  required bool refreshSceneryEntries,
  required void Function(Iterable<String> initialIds) onResetQueriedMedia,
}) async {
  final dao = database.entriesDao;
  final entries = await dao.getFilteredTimelineSummaries(
    filters: filters,
    limit: limit,
    offset: 0,
  );
  final filteredCount = await dao.countFilteredTimelineEntries(
    filters: filters,
  );
  final dateIndex = await dao.getFilteredTimelineDateIndex(
    filters: filters,
  );
  final facetSummary = await dao.getTimelineDateFacetSummary(
    filters: filters,
  );

  final ids = entries.map((entry) => entry.id).toList();
  onResetQueriedMedia(ids);
  final mediaMap = await database.mediaOcrDao.getPrimaryMediaForEntries(ids);

  List<TimelineEntrySummary>? recentSceneryEntries;
  if (refreshSceneryEntries) {
    if (!filters.hasActiveFilters &&
        filters.sortOrder == TimelineSortOrder.newestFirst) {
      recentSceneryEntries = entries;
    } else {
      recentSceneryEntries = await dao.getTimelineSummaries(limit: 5);
    }
  }

  final notebooks = await database.templatesDao.getAllNotebooks();
  final activeNotebook = notebooks.isNotEmpty ? notebooks.first : null;

  return TimelineFeedSnapshot(
    entries: entries,
    dateIndex: dateIndex,
    facetSummary: facetSummary,
    totalFilteredCount: filteredCount,
    mediaMap: mediaMap,
    recentSceneryEntries: recentSceneryEntries,
    activeNotebook: activeNotebook,
  );
}

/// Persists a blank draft entry in [database] and returns its generated ID.
Future<String> createBlankTimelineEntry({
  required AppDatabase database,
  required Notebook? activeNotebook,
}) async {
  final newId = const Uuid().v4();
  final notebookId = activeNotebook?.id ?? 'notebook_default';
  final defaultTemplateId =
      activeNotebook?.defaultTemplateId ?? 'template_minimalist_white';

  await database.entriesDao.createEntry(
    EntriesCompanion.insert(
      id: newId,
      notebookId: notebookId,
      templateId: defaultTemplateId,
      title: const Value(''),
      contentDelta: jsonEncode([
        {'insert': '\n'}
      ]),
      plainText: '',
      entryDate: DateTime.now(),
    ),
  );
  return newId;
}
