import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/timeline/models/chronicle_feed_item.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_summary.dart';
import 'package:memodiary/features/timeline/models/timeline_filter_state.dart';
import 'package:memodiary/features/timeline/services/timeline_viewport_tracker.dart';

typedef TimelineJumpApplyCallback = void Function({
  required List<TimelineEntrySummary> entries,
  required Map<String, MediaAttachment> mediaMap,
  required int offset,
  required bool hasMore,
});

/// Parameter object carrying feed state, viewport references, and callbacks
/// for [TimelineScrubberJumpController.jumpToIndex].
@immutable
class TimelineScrubberJumpRequest {
  final int rawTargetIndex;
  final AppDatabase database;
  final TimelineFilterState filters;
  final int totalFilteredCount;
  final List<TimelineEntrySummary> currentEntries;
  final Map<String, MediaAttachment> currentMediaMap;
  final ScrollController scrollController;
  final TimelineViewportTracker viewportTracker;
  final bool Function() isMounted;
  final TimelineJumpApplyCallback onApplyLoadedState;

  const TimelineScrubberJumpRequest({
    required this.rawTargetIndex,
    required this.database,
    required this.filters,
    required this.totalFilteredCount,
    required this.currentEntries,
    required this.currentMediaMap,
    required this.scrollController,
    required this.viewportTracker,
    required this.isMounted,
    required this.onApplyLoadedState,
  });
}

class _BackfillRequest {
  final AppDatabase database;
  final List<TimelineEntrySummary> currentEntries;
  final TimelineViewportTracker viewportTracker;
  final bool Function() isMounted;
  final void Function(Map<String, MediaAttachment> fetchedMedia) onMergeMedia;

  const _BackfillRequest({
    required this.database,
    required this.currentEntries,
    required this.viewportTracker,
    required this.isMounted,
    required this.onMergeMedia,
  });
}

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
  bool _hasPendingBackfill = false;
  _BackfillRequest? _pendingBackfillRequest;

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

  /// Prefix-loads summaries up to `targetIndex + 20`, batch-loads primary media
  /// for the landing window around `request.rawTargetIndex`, and aligns the
  /// target entry below the pinned `Chronicle Desk` header.
  Future<void> jumpToIndex(TimelineScrubberJumpRequest request) async {
    if (isJumping || request.totalFilteredCount <= 0) return;
    isJumping = true;
    _hasPendingBackfill = false;
    _pendingBackfillRequest = null;

    try {
      final targetIndex =
          request.rawTargetIndex.clamp(0, request.totalFilteredCount - 1);
      final workingEntries = await _loadPrefixAndLandingMedia(
        request: request,
        targetIndex: targetIndex,
      );
      if (workingEntries == null || !request.scrollController.hasClients) {
        return;
      }

      if (targetIndex == 0) {
        request.scrollController.jumpTo(0.0);
        return;
      }

      await _waitForNextFrame();
      if (!request.isMounted() || !request.scrollController.hasClients) return;

      await _alignScrollToTarget(
        request: request,
        workingEntries: workingEntries,
        targetIndex: targetIndex,
      );
    } finally {
      isJumping = false;
    }
  }

  Future<List<TimelineEntrySummary>?> _loadPrefixAndLandingMedia({
    required TimelineScrubberJumpRequest request,
    required int targetIndex,
  }) async {
    final requiredCount = math.min(
      request.totalFilteredCount,
      targetIndex + prefixLookahead,
    );

    var workingEntries =
        List<TimelineEntrySummary>.from(request.currentEntries);
    final workingMedia =
        Map<String, MediaAttachment>.from(request.currentMediaMap);

    if (workingEntries.length < requiredCount) {
      final fetchLimit = requiredCount - workingEntries.length;
      final prefixBatch =
          await request.database.entriesDao.getFilteredTimelineSummaries(
        filters: request.filters,
        limit: fetchLimit,
        offset: workingEntries.length,
      );
      if (!request.isMounted()) return null;
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
      final landingMedia = await request.database.mediaOcrDao
          .getPrimaryMediaForEntries(landingIds);
      if (!request.isMounted()) return null;
      workingMedia.addAll(landingMedia);
    }

    request.onApplyLoadedState(
      entries: workingEntries,
      mediaMap: workingMedia,
      offset: workingEntries.length,
      hasMore: workingEntries.length < request.totalFilteredCount,
    );
    return workingEntries;
  }

  Future<void> _alignScrollToTarget({
    required TimelineScrubberJumpRequest request,
    required List<TimelineEntrySummary> workingEntries,
    required int targetIndex,
  }) async {
    final viewportTracker = request.viewportTracker;
    final scrollController = request.scrollController;
    final pinnedHeaderHeight = viewportTracker.lastPinnedHeaderHeight;

    final immediateDelta = viewportTracker.exactDeltaToEntry(
      targetEntryIndex: targetIndex,
      pinnedHeaderHeight: pinnedHeaderHeight,
    );
    if (immediateDelta == null) {
      final dividerCount =
          countChronicleMonthDividersThrough(workingEntries, targetIndex);
      final estimated = viewportTracker.estimateScrollOffsetToEntry(
        targetEntryIndex: targetIndex,
        dividerCount: dividerCount,
      );
      final maxExtent = scrollController.position.maxScrollExtent;
      scrollController.jumpTo(estimated.clamp(0.0, maxExtent));
      await _waitForNextFrame();
    }

    for (var step = 0; step < _maxAlignmentIterations; step++) {
      if (!request.isMounted() || !scrollController.hasClients) break;

      final stepDelta = viewportTracker.resolveAlignmentDeltaToEntry(
        targetEntryIndex: targetIndex,
        pinnedHeaderHeight: pinnedHeaderHeight,
      );
      if (stepDelta == null) break;

      final maxExtent = scrollController.position.maxScrollExtent;
      final currentOffset = scrollController.offset;
      final nextOffset = (currentOffset + stepDelta).clamp(0.0, maxExtent);
      if ((nextOffset - currentOffset).abs() <= 1.0) break;

      scrollController.jumpTo(nextOffset);
      await _waitForNextFrame();
    }
  }

  List<String> _collectMissingVisibleMediaIds(
    List<TimelineEntrySummary> currentEntries,
    TimelineViewportTracker viewportTracker,
  ) {
    final mountedRange = viewportTracker.mountedEntryRange();
    if (mountedRange == null) return const [];

    final start = math.max(0, mountedRange.$1 - 4);
    final end = math.min(currentEntries.length, mountedRange.$2 + 8);
    final missingIds = <String>[];
    for (var idx = start; idx < end; idx++) {
      final id = currentEntries[idx].id;
      if (!_queriedMediaEntryIds.contains(id)) {
        missingIds.add(id);
      }
    }
    return missingIds;
  }

  /// Lazily batch-loads primary media for mounted/nearby entries whose media
  /// was skipped during an earlier scrubber jump (e.g. when scrolling upward).
  ///
  /// Rapid calls arriving while a query is already in flight coalesce into one
  /// follow-up rescan so entries entering the viewport mid-query are never skipped.
  Future<void> backfillVisibleMedia({
    required AppDatabase database,
    required List<TimelineEntrySummary> currentEntries,
    required TimelineViewportTracker viewportTracker,
    required bool Function() isMounted,
    required void Function(Map<String, MediaAttachment> fetchedMedia)
        onMergeMedia,
  }) async {
    if (isJumping || !isMounted() || currentEntries.isEmpty) return;

    final nextRequest = _BackfillRequest(
      database: database,
      currentEntries: currentEntries,
      viewportTracker: viewportTracker,
      isMounted: isMounted,
      onMergeMedia: onMergeMedia,
    );

    if (_isLoadingVisibleMedia) {
      _hasPendingBackfill = true;
      _pendingBackfillRequest = nextRequest;
      return;
    }

    final initialMissingIds = _collectMissingVisibleMediaIds(
      currentEntries,
      viewportTracker,
    );
    if (initialMissingIds.isEmpty) return;

    _isLoadingVisibleMedia = true;
    _queriedMediaEntryIds.addAll(initialMissingIds);
    var followUpRequest = nextRequest;
    var shouldRunFollowUp = false;

    try {
      final fetched = await database.mediaOcrDao
          .getPrimaryMediaForEntries(initialMissingIds);
      if (isMounted() && fetched.isNotEmpty) {
        onMergeMedia(fetched);
      }
    } finally {
      _isLoadingVisibleMedia = false;
      if (_hasPendingBackfill) {
        shouldRunFollowUp = true;
        followUpRequest = _pendingBackfillRequest ?? followUpRequest;
        _hasPendingBackfill = false;
        _pendingBackfillRequest = null;
      }
    }

    if (shouldRunFollowUp &&
        !isJumping &&
        followUpRequest.isMounted() &&
        followUpRequest.currentEntries.isNotEmpty) {
      await backfillVisibleMedia(
        database: followUpRequest.database,
        currentEntries: followUpRequest.currentEntries,
        viewportTracker: followUpRequest.viewportTracker,
        isMounted: followUpRequest.isMounted,
        onMergeMedia: followUpRequest.onMergeMedia,
      );
    }
  }
}
