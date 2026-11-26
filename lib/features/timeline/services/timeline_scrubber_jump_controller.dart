import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_summary.dart';
import 'package:memodiary/features/timeline/models/timeline_filter_state.dart';
import 'package:memodiary/features/timeline/services/timeline_viewport_tracker.dart';

/// Coordinates single-sliver prefix loading (`0 .. targetIndex + 20`),
/// landing-window primary-media batching, incremental visible-window media
/// backfill, and multi-step post-frame scroll alignment for `Timeline Scrubber`.
class TimelineScrubberJumpController {
  static const int prefixLookahead = 20;
  static const int mediaWindowBehind = 10;
  static const int mediaWindowAhead = 20;
  static const int _maxAlignmentIterations = 5;

  final Set<String> _queriedMediaEntryIds = <String>{};
  bool isJumping = false;
  bool _isLoadingVisibleMedia = false;

  void resetQueriedMedia(Iterable<String> initialEntryIds) {
    _queriedMediaEntryIds
      ..clear()
      ..addAll(initialEntryIds);
  }

  void markMediaQueried(Iterable<String> entryIds) {
    _queriedMediaEntryIds.addAll(entryIds);
  }

  Future<void> _waitForNextFrame() {
    final completer = Completer<void>();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    return completer.future;
  }

  int _countDividersThrough(
    List<TimelineEntrySummary> entries,
    int targetIndex,
  ) {
    var count = 0;
    int? prevYear;
    int? prevMonth;
    final limit = math.min(targetIndex, entries.length - 1);
    for (var idx = 0; idx <= limit; idx++) {
      final date = entries[idx].entryDate;
      if (prevYear != date.year || prevMonth != date.month) {
        count++;
        prevYear = date.year;
        prevMonth = date.month;
      }
    }
    return count;
  }

  /// Prefix-loads summaries up to `targetIndex + 20`, batch-loads primary media
  /// for the landing window around [rawTargetIndex], and aligns the target entry
  /// below the pinned `Chronicle Desk` header.
  Future<void> jumpToIndex({
    required int rawTargetIndex,
    required AppDatabase database,
    required TimelineFilterState filters,
    required int totalFilteredCount,
    required List<TimelineEntrySummary> currentEntries,
    required Map<String, MediaAttachment> currentMediaMap,
    required ScrollController scrollController,
    required TimelineViewportTracker viewportTracker,
    required bool Function() isMounted,
    required void Function({
      required List<TimelineEntrySummary> entries,
      required Map<String, MediaAttachment> mediaMap,
      required int offset,
      required bool hasMore,
    }) onApplyLoadedState,
  }) async {
    if (isJumping || totalFilteredCount <= 0) return;
    isJumping = true;

    try {
      final targetIndex = rawTargetIndex.clamp(0, totalFilteredCount - 1);
      final requiredCount = math.min(
        totalFilteredCount,
        targetIndex + prefixLookahead,
      );

      var workingEntries = List<TimelineEntrySummary>.from(currentEntries);
      final workingMedia = Map<String, MediaAttachment>.from(currentMediaMap);

      if (workingEntries.length < requiredCount) {
        final fetchLimit = requiredCount - workingEntries.length;
        final prefixBatch =
            await database.entriesDao.getFilteredTimelineSummaries(
          filters: filters,
          limit: fetchLimit,
          offset: workingEntries.length,
        );
        if (!isMounted()) return;
        workingEntries = [...workingEntries, ...prefixBatch];
      }

      // Batch-fetch primary media strictly around the landing window so skipped
      // prefix entries are not queried eagerly.
      final windowStart = math.max(0, targetIndex - mediaWindowBehind);
      final windowEnd = math.min(
        workingEntries.length,
        targetIndex + mediaWindowAhead,
      );
      final landingIds = <String>[];
      for (var idx = windowStart; idx < windowEnd; idx++) {
        final id = workingEntries[idx].id;
        if (!_queriedMediaEntryIds.contains(id)) {
          landingIds.add(id);
        }
      }
      if (landingIds.isNotEmpty) {
        _queriedMediaEntryIds.addAll(landingIds);
        final landingMedia =
            await database.mediaOcrDao.getPrimaryMediaForEntries(landingIds);
        if (!isMounted()) return;
        workingMedia.addAll(landingMedia);
      }

      onApplyLoadedState(
        entries: workingEntries,
        mediaMap: workingMedia,
        offset: workingEntries.length,
        hasMore: workingEntries.length < totalFilteredCount,
      );

      if (!scrollController.hasClients) return;
      if (targetIndex == 0) {
        scrollController.jumpTo(0.0);
        return;
      }

      await _waitForNextFrame();
      if (!isMounted() || !scrollController.hasClients) return;

      final pinnedHeaderHeight = viewportTracker.lastPinnedHeaderHeight;
      final immediateDelta = viewportTracker.exactDeltaToEntry(
        targetEntryIndex: targetIndex,
        pinnedHeaderHeight: pinnedHeaderHeight,
      );

      if (immediateDelta == null) {
        final upperHeight =
            viewportTracker.measureUpperWindowHeight() ?? 260.0;
        final dividerCount = _countDividersThrough(workingEntries, targetIndex);
        final avgCard = viewportTracker.averageEntryHeight();
        final avgDivider = viewportTracker.averageDividerHeight();
        final estimated = upperHeight +
            dividerCount * avgDivider +
            targetIndex * avgCard;
        final maxExtent = scrollController.position.maxScrollExtent;
        scrollController.jumpTo(estimated.clamp(0.0, maxExtent));
        await _waitForNextFrame();
      }

      for (var step = 0; step < _maxAlignmentIterations; step++) {
        if (!isMounted() || !scrollController.hasClients) break;
        final exactDelta = viewportTracker.exactDeltaToEntry(
          targetEntryIndex: targetIndex,
          pinnedHeaderHeight: pinnedHeaderHeight,
        );
        final maxExtent = scrollController.position.maxScrollExtent;
        final currentOffset = scrollController.offset;

        if (exactDelta != null) {
          final targetOffset =
              (currentOffset + exactDelta).clamp(0.0, maxExtent);
          if ((targetOffset - currentOffset).abs() <= 1.0) {
            break;
          }
          scrollController.jumpTo(targetOffset);
          await _waitForNextFrame();
          continue;
        }

        final mountedRange = viewportTracker.mountedEntryRange();
        if (mountedRange == null) break;
        final anchorIndex =
            targetIndex > mountedRange.$2 ? mountedRange.$2 : mountedRange.$1;
        final anchorTopY = viewportTracker.mountedEntryTopY(anchorIndex);
        final feedTop = viewportTracker.feedTopGlobalY(pinnedHeaderHeight);
        final avgCard = viewportTracker.averageEntryHeight();
        final anchorAdjust =
            (anchorTopY != null && feedTop != null) ? (anchorTopY - feedTop) : 0.0;
        final stepDelta =
            (targetIndex - anchorIndex) * avgCard + anchorAdjust;
        final nextOffset = (currentOffset + stepDelta).clamp(0.0, maxExtent);
        if ((nextOffset - currentOffset).abs() <= 1.0) break;
        scrollController.jumpTo(nextOffset);
        await _waitForNextFrame();
      }
    } finally {
      isJumping = false;
    }
  }

  /// Lazily batch-loads primary media for mounted/nearby entries whose media
  /// was skipped during an earlier scrubber jump (e.g. when scrolling upward).
  Future<void> backfillVisibleMedia({
    required AppDatabase database,
    required List<TimelineEntrySummary> currentEntries,
    required TimelineViewportTracker viewportTracker,
    required bool Function() isMounted,
    required void Function(Map<String, MediaAttachment> fetchedMedia)
        onMergeMedia,
  }) async {
    if (isJumping || _isLoadingVisibleMedia || currentEntries.isEmpty) return;
    final mountedRange = viewportTracker.mountedEntryRange();
    if (mountedRange == null) return;

    final start = math.max(0, mountedRange.$1 - 4);
    final end = math.min(currentEntries.length, mountedRange.$2 + 8);
    final missingIds = <String>[];
    for (var idx = start; idx < end; idx++) {
      final id = currentEntries[idx].id;
      if (!_queriedMediaEntryIds.contains(id)) {
        missingIds.add(id);
      }
    }
    if (missingIds.isEmpty) return;

    _isLoadingVisibleMedia = true;
    _queriedMediaEntryIds.addAll(missingIds);
    try {
      final fetched =
          await database.mediaOcrDao.getPrimaryMediaForEntries(missingIds);
      if (isMounted() && fetched.isNotEmpty) {
        onMergeMedia(fetched);
      }
    } finally {
      _isLoadingVisibleMedia = false;
    }
  }
}
