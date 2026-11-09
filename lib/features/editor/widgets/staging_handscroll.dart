import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/desk_media_handlers.dart';
import 'brush_reveal/brush_reveal.dart';
import 'staging_handscroll_slot.dart';

/// The entry-wide Staging Handscroll (待贴画卷) holding collected photos and
/// videos that are not yet mounted on any Stationery Sheet.
///
/// Scrolls horizontally with about three slots visible, reading left to right
/// in collect order. Items awaiting their Brush Reveal in the handlers' queue are
/// painted one at a time: the handscroll first glides to the slot, then the
/// slot plays its reveal. With reduce-motion every pending item settles at
/// once. When [unrollOnOpen] is set (it has just opened from closed) the
/// handscroll unrolls before the first reveal. Pure presentation: every action
/// bubbles through callbacks.
class StagingHandscroll extends StatefulWidget {
  final List<SheetMediaItem> items;
  final MediaSandboxService mediaSandboxService;

  /// 1-based number of the active Stationery Sheet that 📌 mounts onto.
  final int activeSheetNumber;
  final ValueChanged<SheetMediaItem>? onTapItem;

  /// Mount, erase and Brush Reveal plumbing.
  final DeskMediaHandlers handlers;
  final bool isPaperDark;
  final bool unrollOnOpen;

  static const double kVisibleSlots = 3;
  static const Duration kGlideDuration = Duration(milliseconds: 420);
  static const Duration kUnrollDuration = Duration(milliseconds: 520);

  const StagingHandscroll({
    super.key,
    required this.items,
    required this.mediaSandboxService,
    required this.activeSheetNumber,
    this.onTapItem,
    this.handlers = const DeskMediaHandlers(),
    this.isPaperDark = false,
    this.unrollOnOpen = false,
  });

  @override
  State<StagingHandscroll> createState() => _StagingHandscrollState();
}

class _StagingHandscrollState extends State<StagingHandscroll> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _unroll = AnimationController(
    vsync: this,
    duration: StagingHandscroll.kUnrollDuration,
    value: widget.unrollOnOpen ? 0.0 : 1.0,
  );

  String? _revealingId;
  bool _isGliding = false;
  double _slotWidth = 0.0;

  @override
  void initState() {
    super.initState();
    widget.handlers.brushReveals?.addListener(_onRevealsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _unroll.value = 1.0;
      } else if (_unroll.value < 1.0) {
        _unroll.forward();
      }
      _advanceReveals();
    });
  }

  @override
  void didUpdateWidget(covariant StagingHandscroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handlers.brushReveals != widget.handlers.brushReveals) {
      oldWidget.handlers.brushReveals?.removeListener(_onRevealsChanged);
      widget.handlers.brushReveals?.addListener(_onRevealsChanged);
    }
    _scheduleAdvance();
  }

  @override
  void dispose() {
    widget.handlers.brushReveals?.removeListener(_onRevealsChanged);
    _scrollController.dispose();
    _unroll.dispose();
    super.dispose();
  }

  void _onRevealsChanged() {
    if (!mounted) return;
    setState(() {
      final revealing = _revealingId;
      if (revealing != null && !(widget.handlers.brushReveals?.isPending(revealing) ?? false)) {
        _revealingId = null;
      }
    });
    _scheduleAdvance();
  }

  void _scheduleAdvance() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _advanceReveals());

  /// Starts the next pending reveal: waits for the unroll, glides to the slot,
  /// then marks it revealing.
  Future<void> _advanceReveals() async {
    final queue = widget.handlers.brushReveals;
    if (!mounted || queue == null || !queue.hasPending) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      queue.clear();
      return;
    }
    final next = queue.current!;
    final index = widget.items.indexWhere((item) => item.id == next);
    if (_revealingId != null || _isGliding || index == -1) return;

    _isGliding = true;
    try {
      if (_unroll.isAnimating) await _unroll.forward().orCancel;
      await _glideTo(index);
    } on TickerCanceled {
      return;
    } finally {
      _isGliding = false;
    }
    if (!mounted) return;
    if (queue.current != next) {
      _scheduleAdvance();
      return;
    }
    setState(() => _revealingId = next);
  }

  Future<void> _glideTo(int index) async {
    if (!_scrollController.hasClients || _slotWidth == 0.0) return;
    final position = _scrollController.position;
    final centred = index * _slotWidth - (position.viewportDimension - _slotWidth) / 2;
    final target = centred.clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < 0.5) return;
    await _scrollController.animateTo(
      target,
      duration: StagingHandscroll.kGlideDuration,
      curve: Curves.easeInOutCubic,
    );
  }

  BrushRevealStatus _statusOf(String mediaId, bool reduceMotion) {
    if (reduceMotion) return BrushRevealStatus.settled;
    if (mediaId == _revealingId) return BrushRevealStatus.revealing;
    final isPending = widget.handlers.brushReveals?.isPending(mediaId) ?? false;
    return isPending ? BrushRevealStatus.waiting : BrushRevealStatus.settled;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();

    final isPaperDark = widget.isPaperDark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final silkColor = isPaperDark ? const Color(0xFF2A2724) : const Color(0xFFF3ECDD);
    final rollerColor = isPaperDark ? const Color(0xFF5A4632) : const Color(0xFF8A6A48);

    final handscroll = Semantics(
      container: true,
      label: '待贴画卷 · ${items.length} 影',
      child: Container(
        key: const Key('staging_handscroll'),
        decoration: BoxDecoration(
          color: silkColor,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.symmetric(
            vertical: BorderSide(color: rollerColor, width: 6.0),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        child: LayoutBuilder(
          builder: (layoutContext, constraints) {
            _slotWidth = constraints.maxWidth / StagingHandscroll.kVisibleSlots;
            return ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemExtent: _slotWidth,
              itemBuilder: (itemContext, itemIndex) {
                final item = items[itemIndex];
                return StagingHandscrollSlot(
                  key: ValueKey(item.id),
                  item: item,
                  ordinal: itemIndex + 1,
                  activeSheetNumber: widget.activeSheetNumber,
                  mediaSandboxService: widget.mediaSandboxService,
                  isPaperDark: isPaperDark,
                  revealStatus: _statusOf(item.id, reduceMotion),
                  onRevealComplete: () => widget.handlers.brushReveals?.complete(item.id),
                  onTap: widget.onTapItem,
                  onMount: (item) => widget.handlers.onMount?.call(item.id),
                  onErase: (item) => widget.handlers.onErase?.call(item.id),
                );
              },
            );
          },
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _unroll,
      builder: (animatedContext, child) {
        final fraction = Curves.easeOutCubic.transform(_unroll.value);
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRect(
                key: const Key('staging_handscroll_unroll'),
                clipper: HandscrollUnrollClipper(fraction),
                child: child,
              ),
            ),
            if (fraction < 1.0)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction,
                  child: Align(
                    alignment: Alignment.centerRight,
                    // The roller travelling with the unrolling edge.
                    child: Container(width: 8.0, color: rollerColor),
                  ),
                ),
              ),
          ],
        );
      },
      child: handscroll,
    );
  }
}

/// Clips the handscroll to the unrolled [fraction] of its width, from the left.
class HandscrollUnrollClipper extends CustomClipper<Rect> {
  final double fraction;

  const HandscrollUnrollClipper(this.fraction);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0.0, 0.0, size.width * fraction, size.height);

  @override
  bool shouldReclip(covariant HandscrollUnrollClipper oldClipper) => oldClipper.fraction != fraction;
}
