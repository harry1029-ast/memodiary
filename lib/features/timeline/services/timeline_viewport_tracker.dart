import 'package:flutter/material.dart';

/// Tracks mounted timeline entry items, `Month Spine Divider` headers, and the
/// upper scenery window inside `ChronicleDeskScrollBody` without `GlobalKey`
/// overhead, enabling accurate thumb progress and multi-step scrubber jumps.
class TimelineViewportTracker {
  static const double _defaultEntryHeight = 128.0;
  static const double _defaultDividerHeight = 34.0;
  static const double _defaultUpperWindowHeight = 260.0;

  final ValueNotifier<bool> isScrollableNotifier = ValueNotifier(false);
  final Map<int, BuildContext> _entryContexts = {};
  final Map<int, BuildContext> _dividerContexts = {};
  BuildContext? _scrollViewContext;
  BuildContext? _upperWindowContext;
  double lastPinnedHeaderHeight = 176.0;

  void updateScrollMetrics(ScrollMetrics metrics) {
    final scrollable = metrics.maxScrollExtent > 0.5;
    if (isScrollableNotifier.value != scrollable) {
      isScrollableNotifier.value = scrollable;
    }
  }

  void dispose() {
    isScrollableNotifier.dispose();
  }

  void attachScrollView(BuildContext context) {
    _scrollViewContext = context;
  }

  void detachScrollView(BuildContext context) {
    if (_scrollViewContext == context) {
      _scrollViewContext = null;
    }
  }

  void attachUpperWindow(BuildContext context) {
    _upperWindowContext = context;
  }

  void detachUpperWindow(BuildContext context) {
    if (_upperWindowContext == context) {
      _upperWindowContext = null;
    }
  }

  void registerEntry(int entryIndex, BuildContext context) {
    _entryContexts[entryIndex] = context;
  }

  void unregisterEntry(int entryIndex, BuildContext context) {
    if (_entryContexts[entryIndex] == context) {
      _entryContexts.remove(entryIndex);
    }
  }

  void registerDivider(int firstEntryIndex, BuildContext context) {
    _dividerContexts[firstEntryIndex] = context;
  }

  void unregisterDivider(int firstEntryIndex, BuildContext context) {
    if (_dividerContexts[firstEntryIndex] == context) {
      _dividerContexts.remove(firstEntryIndex);
    }
  }

  RenderBox? _attachedBox(BuildContext? context) {
    if (context == null || !context.mounted) return null;
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox &&
        renderObject.attached &&
        renderObject.hasSize) {
      return renderObject;
    }
    return null;
  }

  /// Current height of the `UpperWindowAndSill` sliver when mounted, or `null`.
  double? measureUpperWindowHeight() {
    return _attachedBox(_upperWindowContext)?.size.height;
  }

  /// Global Y coordinate where the scrollable feed starts (immediately below
  /// the pinned `ChronicleDeskHeaderDelegate`).
  double? feedTopGlobalY(double pinnedHeaderHeight) {
    final scrollBox = _attachedBox(_scrollViewContext);
    if (scrollBox == null) return null;
    return scrollBox.localToGlobal(Offset.zero).dy + pinnedHeaderHeight;
  }

  /// Computes normalized reading progress `0.0..1.0` from the topmost visible
  /// entry index relative to [totalFilteredCount].
  double computeTopProgress({
    required int totalFilteredCount,
    required double pinnedHeaderHeight,
  }) {
    if (totalFilteredCount <= 1) return 0.0;
    final feedTop = feedTopGlobalY(pinnedHeaderHeight);
    if (feedTop == null) return 0.0;

    int? topEntryIndex;
    double topEntryFraction = 0.0;

    final sortedIndices = _entryContexts.keys.toList()..sort();
    for (final entryIndex in sortedIndices) {
      final box = _attachedBox(_entryContexts[entryIndex]);
      if (box == null) continue;
      final itemTop = box.localToGlobal(Offset.zero).dy;
      final itemHeight = box.size.height;
      final itemBottom = itemTop + itemHeight;
      if (itemBottom > feedTop + 1.0) {
        topEntryIndex = entryIndex;
        if (itemTop < feedTop && itemHeight > 0) {
          topEntryFraction = ((feedTop - itemTop) / itemHeight).clamp(0.0, 1.0);
        }
        break;
      }
    }

    if (topEntryIndex == null) return 0.0;
    return ((topEntryIndex + topEntryFraction) / (totalFilteredCount - 1))
        .clamp(0.0, 1.0);
  }

  /// Returns `(minMountedEntryIndex, maxMountedEntryIndex)` currently mounted
  /// in the sliver cache/viewport, or `null` if none are mounted.
  (int, int)? mountedEntryRange() {
    if (_entryContexts.isEmpty) return null;
    int? minIndex;
    int? maxIndex;
    for (final entry in _entryContexts.entries) {
      if (_attachedBox(entry.value) == null) continue;
      final idx = entry.key;
      if (minIndex == null || idx < minIndex) minIndex = idx;
      if (maxIndex == null || idx > maxIndex) maxIndex = idx;
    }
    if (minIndex == null || maxIndex == null) return null;
    return (minIndex, maxIndex);
  }

  double _averageMountedHeight(
    Map<int, BuildContext> contexts, {
    required double fallback,
  }) {
    var totalHeight = 0.0;
    var count = 0;
    for (final context in contexts.values) {
      final box = _attachedBox(context);
      if (box == null) continue;
      totalHeight += box.size.height;
      count++;
    }
    return count > 0 ? totalHeight / count : fallback;
  }

  /// Average measured height across currently mounted entry cards, or `128.0`.
  double averageEntryHeight() =>
      _averageMountedHeight(_entryContexts, fallback: _defaultEntryHeight);

  /// Average measured height across currently mounted month dividers, or `34.0`.
  double averageDividerHeight() =>
      _averageMountedHeight(_dividerContexts, fallback: _defaultDividerHeight);

  /// Returns the exact scroll delta needed to align [targetEntryIndex] (or its
  /// preceding `Month Spine Divider` when present) with [feedTopGlobalY],
  /// or `null` if [targetEntryIndex] is not currently mounted.
  double? exactDeltaToEntry({
    required int targetEntryIndex,
    required double pinnedHeaderHeight,
  }) {
    final feedTop = feedTopGlobalY(pinnedHeaderHeight);
    if (feedTop == null) return null;

    final dividerBox = _attachedBox(_dividerContexts[targetEntryIndex]);
    if (dividerBox != null) {
      return dividerBox.localToGlobal(Offset.zero).dy - feedTop;
    }

    final entryBox = _attachedBox(_entryContexts[targetEntryIndex]);
    if (entryBox != null) {
      return entryBox.localToGlobal(Offset.zero).dy - feedTop;
    }
    return null;
  }

  /// Returns the global Y top of a mounted anchor entry [entryIndex], if laid out.
  double? mountedEntryTopY(int entryIndex) {
    final box = _attachedBox(_entryContexts[entryIndex]);
    return box?.localToGlobal(Offset.zero).dy;
  }

  /// Estimates the initial scroll offset for [targetEntryIndex] using the
  /// measured upper window height, [dividerCount] preceding month dividers, and
  /// average mounted card/divider heights.
  double estimateScrollOffsetToEntry({
    required int targetEntryIndex,
    required int dividerCount,
  }) {
    final upperHeight = measureUpperWindowHeight() ?? _defaultUpperWindowHeight;
    return upperHeight +
        dividerCount * averageDividerHeight() +
        targetEntryIndex * averageEntryHeight();
  }

  /// Resolves the exact scroll delta for [targetEntryIndex] when mounted, or an
  /// estimated delta relative to the nearest mounted anchor entry.
  double? resolveAlignmentDeltaToEntry({
    required int targetEntryIndex,
    required double pinnedHeaderHeight,
  }) {
    final exactDelta = exactDeltaToEntry(
      targetEntryIndex: targetEntryIndex,
      pinnedHeaderHeight: pinnedHeaderHeight,
    );
    if (exactDelta != null) return exactDelta;

    final mountedRange = mountedEntryRange();
    if (mountedRange == null) return null;

    final anchorIndex =
        targetEntryIndex > mountedRange.$2 ? mountedRange.$2 : mountedRange.$1;
    final anchorTopY = mountedEntryTopY(anchorIndex);
    final feedTop = feedTopGlobalY(pinnedHeaderHeight);
    final anchorAdjust =
        (anchorTopY != null && feedTop != null) ? (anchorTopY - feedTop) : 0.0;
    return (targetEntryIndex - anchorIndex) * averageEntryHeight() +
        anchorAdjust;
  }
}

typedef _TrackerContextCallback = void Function(
  TimelineViewportTracker tracker,
  BuildContext context,
);

/// Shared lifecycle widget that registers and updates a widget's [BuildContext]
/// against a [TimelineViewportTracker] slot.
class _TimelineTrackerMarker extends StatefulWidget {
  final TimelineViewportTracker? tracker;
  final Object? slotKey;
  final _TrackerContextCallback onAttach;
  final _TrackerContextCallback onDetach;
  final Widget child;

  const _TimelineTrackerMarker({
    required this.tracker,
    this.slotKey,
    required this.onAttach,
    required this.onDetach,
    required this.child,
  });

  @override
  State<_TimelineTrackerMarker> createState() => _TimelineTrackerMarkerState();
}

class _TimelineTrackerMarkerState extends State<_TimelineTrackerMarker> {
  @override
  void initState() {
    super.initState();
    final tracker = widget.tracker;
    if (tracker != null) {
      widget.onAttach(tracker, context);
    }
  }

  @override
  void didUpdateWidget(covariant _TimelineTrackerMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tracker != widget.tracker ||
        oldWidget.slotKey != widget.slotKey) {
      final oldTracker = oldWidget.tracker;
      if (oldTracker != null) {
        oldWidget.onDetach(oldTracker, context);
      }
      final newTracker = widget.tracker;
      if (newTracker != null) {
        widget.onAttach(newTracker, context);
      }
    }
  }

  @override
  void dispose() {
    final tracker = widget.tracker;
    if (tracker != null) {
      widget.onDetach(tracker, context);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Registers a mounted entry card's [BuildContext] with [tracker].
class TimelineViewportMarker extends StatelessWidget {
  final int entryIndex;
  final TimelineViewportTracker? tracker;
  final Widget child;

  const TimelineViewportMarker({
    super.key,
    required this.entryIndex,
    required this.tracker,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _TimelineTrackerMarker(
      tracker: tracker,
      slotKey: entryIndex,
      onAttach: (targetTracker, markerContext) =>
          targetTracker.registerEntry(entryIndex, markerContext),
      onDetach: (targetTracker, markerContext) =>
          targetTracker.unregisterEntry(entryIndex, markerContext),
      child: child,
    );
  }
}

/// Registers a mounted `Month Spine Divider` with [tracker] under the
/// [firstEntryIndex] that begins that month group.
class TimelineDividerViewportMarker extends StatelessWidget {
  final int firstEntryIndex;
  final TimelineViewportTracker? tracker;
  final Widget child;

  const TimelineDividerViewportMarker({
    super.key,
    required this.firstEntryIndex,
    required this.tracker,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _TimelineTrackerMarker(
      tracker: tracker,
      slotKey: firstEntryIndex,
      onAttach: (targetTracker, markerContext) =>
          targetTracker.registerDivider(firstEntryIndex, markerContext),
      onDetach: (targetTracker, markerContext) =>
          targetTracker.unregisterDivider(firstEntryIndex, markerContext),
      child: child,
    );
  }
}

/// Registers the `UpperWindowAndSill` sliver container with [tracker].
class TimelineUpperWindowMarker extends StatelessWidget {
  final TimelineViewportTracker? tracker;
  final Widget child;

  const TimelineUpperWindowMarker({
    super.key,
    required this.tracker,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _TimelineTrackerMarker(
      tracker: tracker,
      onAttach: (targetTracker, markerContext) =>
          targetTracker.attachUpperWindow(markerContext),
      onDetach: (targetTracker, markerContext) =>
          targetTracker.detachUpperWindow(markerContext),
      child: child,
    );
  }
}

/// Registers the `CustomScrollView` viewport container with [tracker].
class TimelineScrollViewMarker extends StatelessWidget {
  final TimelineViewportTracker? tracker;
  final Widget child;

  const TimelineScrollViewMarker({
    super.key,
    required this.tracker,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _TimelineTrackerMarker(
      tracker: tracker,
      onAttach: (targetTracker, markerContext) =>
          targetTracker.attachScrollView(markerContext),
      onDetach: (targetTracker, markerContext) =>
          targetTracker.detachScrollView(markerContext),
      child: child,
    );
  }
}
