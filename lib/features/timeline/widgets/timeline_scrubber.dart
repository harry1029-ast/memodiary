import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/features/timeline/models/timeline_date_index_entry.dart';
import 'package:memodiary/features/timeline/models/timeline_scrubber_milestones.dart';
import 'package:memodiary/features/timeline/services/timeline_viewport_tracker.dart';
import 'package:memodiary/features/timeline/widgets/timeline_scrubber_rail_painter.dart';

/// Auto-hiding right-edge `Timeline Scrubber` chromatic rail, hollow ring
/// thumb, two-stage milestone orientation overlay, and floating `YYYY年M月`
/// date plaque for jumping across the full filtered timeline.
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

  List<TimelineDateIndexEntry>? _cachedDateIndex;
  AtmospherePalette? _cachedPalette;
  List<Color> _cachedChromaticPalette = const [];
  List<ScrubberMilestone> _cachedMilestones = const [];

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

  void _ensureMilestones(AtmospherePalette palette) {
    if (identical(_cachedDateIndex, widget.dateIndex) &&
        _cachedPalette == palette) {
      return;
    }
    _cachedDateIndex = widget.dateIndex;
    _cachedPalette = palette;
    _cachedChromaticPalette = buildScrubberChromaticPalette(palette);
    _cachedMilestones = buildScrubberMilestones(
      widget.dateIndex,
      _cachedChromaticPalette,
    );
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
    setState(() {
      _isPressHoldActive = true;
      _isVisible = true;
    });
  }

  void _handleVerticalDragStart(DragStartDetails details, double trackHeight) {
    if (!_hasEnoughEntries || !widget.isScrollableListenable.value) return;
    _hideTimer?.cancel();
    final progress = _progressForLocalY(details.localPosition.dy, trackHeight);
    final targetIndex = _indexForProgress(progress);
    final date = widget.dateIndex[targetIndex].entryDate;
    setState(() {
      _isPressHoldActive = false;
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
      setState(() => _isPressHoldActive = false);
      _scheduleHide();
    }
  }

  Future<void> _finishDrag() async {
    if (!_isDragging) {
      if (_isPressHoldActive) {
        setState(() => _isPressHoldActive = false);
      }
      _scheduleHide();
      return;
    }
    final targetIndex = _dragTargetIndex;
    setState(() {
      _isPressHoldActive = false;
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

  Map<Type, GestureRecognizerFactory> _buildTrackGestures(double trackHeight) {
    return {
      VerticalDragGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
        () => VerticalDragGestureRecognizer()..onlyAcceptDragOnThreshold = true,
        (recognizer) {
          recognizer.dragStartBehavior = DragStartBehavior.start;
          recognizer.onlyAcceptDragOnThreshold = true;
          recognizer.onDown = _handleVerticalDragDown;
          recognizer.onStart =
              (details) => _handleVerticalDragStart(details, trackHeight);
          recognizer.onUpdate =
              (details) => _handleVerticalDragUpdate(details, trackHeight);
          recognizer.onEnd = (_) => unawaited(_finishDrag());
          recognizer.onCancel = _handleVerticalDragCancel;
        },
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isScrollableListenable,
      builder: (context, isScrollable, _) {
        if (!_hasEnoughEntries || !isScrollable) return const SizedBox.shrink();

        final reduced = MediaQuery.disableAnimationsOf(context);
        final fadeDuration = reduced ? Duration.zero : const Duration(milliseconds: 200);
        final chipFadeDuration = reduced ? Duration.zero : const Duration(milliseconds: 120);
        final thumbAnimDuration = reduced ? Duration.zero : const Duration(milliseconds: 140);
        final bottomClearance = math.max(28.0, MediaQuery.paddingOf(context).bottom + 12.0);

        return AnimatedBuilder(
          animation: widget.scrollController,
          builder: (context, _) {
            return Positioned(
              top: _resolveTrackTop(),
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
                  _ensureMilestones(palette);
                  final usableHeight = trackHeight - TimelineScrubber._thumbHeight;
                  const trackInset = TimelineScrubber._thumbHeight / 2;
                  final trackGeometry = ScrubberTrackGeometry(
                    trackHeight: trackHeight,
                    topInset: trackInset,
                    bottomInset: trackInset,
                    usableHeight: usableHeight,
                    hitStripWidth: TimelineScrubber._hitStripWidth,
                    rightEdgeInset: TimelineScrubber._rightEdgeInset,
                  );
                  final visibleMilestones = selectVisibleMilestones(_cachedMilestones, usableHeight);
                  final clampedProgress = _progress.clamp(0.0, 1.0);
                  final activeColor = colorForScrubberProgress(
                    clampedProgress,
                    _cachedMilestones,
                    palette.accentPrimary,
                  );
                  final thumbTop = clampedProgress * usableHeight;
                  final plaqueTop = (thumbTop +
                          (TimelineScrubber._thumbHeight - TimelineScrubber._plaqueHeight) / 2)
                      .clamp(0.0, trackHeight - TimelineScrubber._plaqueHeight);
                  final activeIndex = _dragTargetIndex.clamp(0, widget.dateIndex.length - 1);

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (_isPressHoldActive || _isDragging)
                        Positioned.fill(
                          child: ScrubberMilestoneOverlay(
                            labelMilestones: visibleMilestones.labels,
                            geometry: trackGeometry,
                            isDragging: _isDragging,
                            plaqueCenterY: _isDragging
                                ? plaqueTop + TimelineScrubber._plaqueHeight / 2
                                : null,
                            palette: palette,
                            fadeDuration: chipFadeDuration,
                          ),
                        ),
                      Positioned(
                        key: const ValueKey('timeline_scrubber_track_slot'),
                        top: 0,
                        bottom: 0,
                        right: 0,
                        width: TimelineScrubber._hitStripWidth,
                        child: Semantics(
                          label: '时间轴快速滚动条',
                          container: true,
                          child: RawGestureDetector(
                            key: const Key('timeline_scrubber_track'),
                            behavior: HitTestBehavior.translucent,
                            gestures: _buildTrackGestures(trackHeight),
                            child: AnimatedOpacity(
                              key: const Key('timeline_scrubber_visibility'),
                              opacity: _isVisible ? 1.0 : 0.0,
                              duration: fadeDuration,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: ChromaticScrubberRailPainter(
                                        chromaticPalette: _cachedChromaticPalette,
                                        allMilestones: _cachedMilestones,
                                        nodeMilestones: visibleMilestones.nodes,
                                        palette: palette,
                                        geometry: trackGeometry,
                                        railOpacity: (_isDragging || _isPressHoldActive) ? 1.0 : 0.82,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0.0,
                                    top: thumbTop,
                                    child: ScrubberHollowRingThumb(
                                      isActive: _isDragging || _isPressHoldActive,
                                      activeColor: activeColor,
                                      palette: palette,
                                      thumbHeight: TimelineScrubber._thumbHeight,
                                      animationDuration: thumbAnimDuration,
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
                          child: FloatingMonthPlaque(
                            monthLabel: widget.dateIndex[activeIndex].monthLabel,
                            activeColor: activeColor,
                            palette: palette,
                            minHeight: TimelineScrubber._plaqueHeight,
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
