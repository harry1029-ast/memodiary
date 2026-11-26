import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/timeline/models/timeline_date_index_entry.dart';
import 'package:memodiary/features/timeline/services/timeline_viewport_tracker.dart';

/// Auto-hiding right-edge `Timeline Scrubber` thumb and floating `YYYY年M月`
/// date plaque for jumping directly across the full filtered timeline.
class TimelineScrubber extends StatefulWidget {
  /// Minimum filtered entries required before the scrubber activates.
  static const int minEntriesForScrubber = 15;

  /// Idle delay before the scrubber auto-fades out.
  static const Duration idleHideDelay = Duration(milliseconds: 1500);

  static const double _thumbHeight = 44.0;
  static const double _hitStripWidth = 44.0;
  static const double _rightEdgeInset = 10.0;
  static const double _plaqueHeight = 32.0;

  final ScrollController scrollController;
  final List<TimelineDateIndexEntry> dateIndex;
  final TimelineViewportTracker viewportTracker;
  final ValueListenable<bool> isScrollableListenable;
  final double pinnedHeaderHeight;
  final Future<void> Function(int targetIndex) onJumpToIndex;

  const TimelineScrubber({
    super.key,
    required this.scrollController,
    required this.dateIndex,
    required this.viewportTracker,
    required this.isScrollableListenable,
    required this.pinnedHeaderHeight,
    required this.onJumpToIndex,
  });

  @override
  State<TimelineScrubber> createState() => TimelineScrubberState();
}

class TimelineScrubberState extends State<TimelineScrubber> {
  Timer? _hideTimer;
  bool _isVisible = false;
  bool _isDragging = false;
  bool _isPressHoldActive = false;
  bool _syncScheduled = false;
  double _progress = 0.0;
  double _lastReportedScrollOffset = 0.0;
  int _dragTargetIndex = 0;
  (int, int)? _lastHapticYearMonth;

  bool get _hasEnoughEntries =>
      widget.dateIndex.length >= TimelineScrubber.minEntriesForScrubber;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScrollControllerChanged);
    widget.isScrollableListenable.addListener(_handleScrollabilityChanged);
    _syncScrollProgressOnly();
  }

  @override
  void didUpdateWidget(covariant TimelineScrubber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_handleScrollControllerChanged);
      widget.scrollController.addListener(_handleScrollControllerChanged);
    }
    if (oldWidget.isScrollableListenable != widget.isScrollableListenable) {
      oldWidget.isScrollableListenable.removeListener(_handleScrollabilityChanged);
      widget.isScrollableListenable.addListener(_handleScrollabilityChanged);
    }
    if (oldWidget.dateIndex != widget.dateIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _isDragging) return;
        _syncScrollProgressOnly();
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.scrollController.removeListener(_handleScrollControllerChanged);
    widget.isScrollableListenable.removeListener(_handleScrollabilityChanged);
    super.dispose();
  }

  void _handleScrollabilityChanged() {
    if (!mounted) return;
    setState(() {
      if (!widget.isScrollableListenable.value) {
        _hideTimer?.cancel();
        _isVisible = false;
        _isDragging = false;
        _isPressHoldActive = false;
      }
    });
  }

  void _handleScrollControllerChanged() {
    if (!mounted || _isDragging) return;
    final hasClients = widget.scrollController.hasClients;
    final currentOffset = hasClients ? widget.scrollController.offset : 0.0;
    final didOffsetMove = (currentOffset - _lastReportedScrollOffset).abs() > 0.5;
    _lastReportedScrollOffset = currentOffset;

    _syncScrollProgressOnly();
    _schedulePostFrameProgressSync();
    if (didOffsetMove && _hasEnoughEntries && widget.isScrollableListenable.value) {
      _revealAndScheduleHide();
    }
  }

  void _schedulePostFrameProgressSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted || _isDragging) return;
      _syncScrollProgressOnly();
    });
  }

  void _syncScrollProgressOnly() {
    if (!mounted || _isDragging) return;
    final nextProgress = widget.viewportTracker.computeTopProgress(
      totalFilteredCount: widget.dateIndex.length,
      pinnedHeaderHeight: widget.pinnedHeaderHeight,
    );
    if ((nextProgress - _progress).abs() > 0.0005) {
      setState(() => _progress = nextProgress);
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (_isDragging || _isPressHoldActive) return;
    _hideTimer = Timer(TimelineScrubber.idleHideDelay, () {
      if (!mounted || _isDragging || _isPressHoldActive) return;
      setState(() => _isVisible = false);
    });
  }

  void _revealAndScheduleHide() {
    _hideTimer?.cancel();
    if (!_isVisible) {
      setState(() => _isVisible = true);
    }
    _scheduleHide();
  }

  int _indexForProgress(double normalizedProgress) {
    final total = widget.dateIndex.length;
    if (total <= 1) return 0;
    return (normalizedProgress.clamp(0.0, 1.0) * (total - 1)).round();
  }

  double _progressForLocalY(double localY, double trackHeight) {
    final usableHeight = math.max(1.0, trackHeight - TimelineScrubber._thumbHeight);
    final clampedY =
        (localY - TimelineScrubber._thumbHeight / 2).clamp(0.0, usableHeight);
    return (clampedY / usableHeight).clamp(0.0, 1.0);
  }

  void _handleVerticalDragDown(DragDownDetails details) {
    if (!_hasEnoughEntries || !widget.isScrollableListenable.value) return;
    _hideTimer?.cancel();
    _isPressHoldActive = true;
    if (!_isVisible) {
      setState(() => _isVisible = true);
    }
  }

  void _handleVerticalDragStart(DragStartDetails details, double trackHeight) {
    if (!_hasEnoughEntries || !widget.isScrollableListenable.value) return;
    _hideTimer?.cancel();
    _isPressHoldActive = false;
    final progress = _progressForLocalY(details.localPosition.dy, trackHeight);
    final targetIndex = _indexForProgress(progress);
    final date = widget.dateIndex[targetIndex].entryDate;
    setState(() {
      _isDragging = true;
      _isVisible = true;
      _progress = progress;
      _dragTargetIndex = targetIndex;
      _lastHapticYearMonth = (date.year, date.month);
    });
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details, double trackHeight) {
    if (!_isDragging || widget.dateIndex.isEmpty) return;
    final progress = _progressForLocalY(details.localPosition.dy, trackHeight);
    final targetIndex = _indexForProgress(progress);
    final date = widget.dateIndex[targetIndex].entryDate;
    final nextYearMonth = (date.year, date.month);

    if (_lastHapticYearMonth != null && _lastHapticYearMonth != nextYearMonth) {
      unawaited(HapticFeedback.selectionClick());
    }
    _lastHapticYearMonth = nextYearMonth;

    setState(() {
      _progress = progress;
      _dragTargetIndex = targetIndex;
    });
  }

  void _handleVerticalDragCancel() {
    if (_isDragging) {
      unawaited(_finishDrag());
      return;
    }
    if (_isPressHoldActive) {
      _isPressHoldActive = false;
      _scheduleHide();
    }
  }

  Future<void> _finishDrag() async {
    _isPressHoldActive = false;
    if (!_isDragging) {
      _scheduleHide();
      return;
    }
    final targetIndex = _dragTargetIndex;
    setState(() {
      _isDragging = false;
      _lastHapticYearMonth = null;
    });
    _revealAndScheduleHide();
    await widget.onJumpToIndex(targetIndex);
    if (mounted && !_isDragging) {
      _syncScrollProgressOnly();
    }
  }

  double _resolveTrackTop() {
    final upperHeight = widget.viewportTracker.measureUpperWindowHeight() ?? 0.0;
    final offset =
        widget.scrollController.hasClients ? widget.scrollController.offset : 0.0;
    final remainingUpper = (upperHeight - offset).clamp(0.0, upperHeight);
    return remainingUpper + widget.pinnedHeaderHeight + 6.0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isScrollableListenable,
      builder: (context, isScrollable, _) {
        if (!_hasEnoughEntries || !isScrollable) {
          return const SizedBox.shrink();
        }

        final disableAnimations = MediaQuery.disableAnimationsOf(context);
        final fadeDuration = disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 200);
        final bottomClearance = math.max(
          28.0,
          MediaQuery.paddingOf(context).bottom + 12.0,
        );

        return AnimatedBuilder(
          animation: widget.scrollController,
          builder: (context, _) {
            final trackTop = _resolveTrackTop();
            return Positioned(
              top: trackTop,
              bottom: bottomClearance,
              right: TimelineScrubber._rightEdgeInset,
              left: 0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final trackHeight = constraints.maxHeight;
                  if (trackHeight < TimelineScrubber._thumbHeight + 8.0) {
                    return const SizedBox.shrink();
                  }

                  final palette = context.atmospherePalette;
                  final usableHeight =
                      trackHeight - TimelineScrubber._thumbHeight;
                  final thumbTop = (_progress.clamp(0.0, 1.0)) * usableHeight;
                  final plaqueTop = (thumbTop +
                          (TimelineScrubber._thumbHeight -
                                  TimelineScrubber._plaqueHeight) /
                              2)
                      .clamp(0.0, trackHeight - TimelineScrubber._plaqueHeight);

                  final activeIndex = _dragTargetIndex.clamp(
                    0,
                    widget.dateIndex.length - 1,
                  );
                  final monthLabel = widget.dateIndex[activeIndex].monthLabel;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        key: const ValueKey('timeline_scrubber_track_slot'),
                        top: 0,
                        bottom: 0,
                        right: 0,
                        width: TimelineScrubber._hitStripWidth,
                        child: Semantics(
                          label: '时间轴快速滚动条',
                          container: true,
                          child: GestureDetector(
                            key: const Key('timeline_scrubber_track'),
                            behavior: HitTestBehavior.translucent,
                            dragStartBehavior: DragStartBehavior.down,
                            onVerticalDragDown: _handleVerticalDragDown,
                            onVerticalDragStart: (details) =>
                                _handleVerticalDragStart(details, trackHeight),
                            onVerticalDragUpdate: (details) =>
                                _handleVerticalDragUpdate(details, trackHeight),
                            onVerticalDragEnd: (_) => unawaited(_finishDrag()),
                            onVerticalDragCancel: _handleVerticalDragCancel,
                            child: AnimatedOpacity(
                              key: const Key('timeline_scrubber_visibility'),
                              opacity: _isVisible ? 1.0 : 0.0,
                              duration: fadeDuration,
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: 6.0,
                                    top: 4.0,
                                    bottom: 4.0,
                                    width: 2.0,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: palette.deckleBorder
                                            .withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 2.0,
                                    top: thumbTop,
                                    height: TimelineScrubber._thumbHeight,
                                    width: _isDragging ? 10.0 : 8.0,
                                    child: DecoratedBox(
                                      key: const Key('timeline_scrubber_thumb'),
                                      decoration: BoxDecoration(
                                        color: _isDragging
                                            ? palette.accentPrimary
                                            : palette.accentSecondary,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: palette.cardPaper
                                              .withValues(alpha: 0.7),
                                          width: 0.8,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: palette.slipShadowColor,
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_isDragging)
                        Positioned(
                          key: const ValueKey('timeline_scrubber_plaque_slot'),
                          right: TimelineScrubber._hitStripWidth + 8.0,
                          top: plaqueTop,
                          child: _FloatingMonthPlaque(
                            monthLabel: monthLabel,
                            palette: palette,
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _FloatingMonthPlaque extends StatelessWidget {
  final String monthLabel;
  final AtmospherePalette palette;

  const _FloatingMonthPlaque({
    required this.monthLabel,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 160,
            minHeight: TimelineScrubber._plaqueHeight,
          ),
          child: Container(
            key: const Key('timeline_scrubber_plaque'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: palette.cardPaper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.deckleBorder, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: palette.slipShadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              monthLabel,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
