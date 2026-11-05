import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../domain/stationery_sheet_descriptor.dart';
import 'brush_reveal/brush_reveal.dart';
import 'desk_media_control.dart';
import 'keepsake_thumbnail.dart';

/// One Staging Handscroll slot. A freshly collected item plays its Brush
/// Reveal here (its controls stay inert until painted). ✕ plays an in-place
/// ink-wash dissolve (the print drains to grey and fades) before reporting the
/// erase; with reduce-motion the erase is reported at once.
class StagingHandscrollSlot extends StatefulWidget {
  final SheetMediaItem item;
  final int ordinal;
  final int activeSheetNumber;
  final MediaSandboxService mediaSandboxService;
  final bool isPaperDark;
  final BrushRevealStatus revealStatus;
  final VoidCallback? onRevealComplete;
  final ValueChanged<SheetMediaItem>? onTap;
  final ValueChanged<SheetMediaItem>? onMount;
  final ValueChanged<SheetMediaItem>? onErase;

  const StagingHandscrollSlot({
    super.key,
    required this.item,
    required this.ordinal,
    required this.activeSheetNumber,
    required this.mediaSandboxService,
    required this.isPaperDark,
    this.revealStatus = BrushRevealStatus.settled,
    this.onRevealComplete,
    this.onTap,
    this.onMount,
    this.onErase,
  });

  @override
  State<StagingHandscrollSlot> createState() => _StagingHandscrollSlotState();
}

class _StagingHandscrollSlotState extends State<StagingHandscrollSlot> with SingleTickerProviderStateMixin {
  static const Duration kDissolveDuration = Duration(milliseconds: 450);
  static const double _kDragFeedbackSize = 72.0;

  late final AnimationController _dissolve = AnimationController(
    vsync: this,
    duration: kDissolveDuration,
  );

  Future<void> _erase() async {
    if (_dissolve.isAnimating) return;
    if (!MediaQuery.disableAnimationsOf(context)) {
      await _dissolve.forward();
    }
    if (mounted) widget.onErase?.call(widget.item);
  }

  @override
  void dispose() {
    _dissolve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dissolve,
      builder: (animatedContext, child) {
        final progress = Curves.easeIn.transform(_dissolve.value);
        return IgnorePointer(
          ignoring: _dissolve.isAnimating || widget.revealStatus != BrushRevealStatus.settled,
          child: Opacity(
            key: Key('handscroll_dissolve_${widget.item.id}'),
            opacity: 1.0 - progress,
            child: ColorFiltered(
              colorFilter: inkWashFilter(math.min(1.0, progress * 2.0)),
              child: child,
            ),
          ),
        );
      },
      child: _buildSlot(context),
    );
  }

  Widget _buildSlot(BuildContext context) {
    final item = widget.item;
    final ordinal = widget.ordinal;
    final isPaperDark = widget.isPaperDark;
    final cinnabar = DeskMediaPalette(isPaperDark: isPaperDark).cinnabar;
    final isVideo = item.mediaType == EphemeraMediaType.video;
    final kind = isVideo ? '短影' : '影札';

    final isSettled = widget.revealStatus == BrushRevealStatus.settled;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            button: true,
            label: '待贴第 $ordinal 影 · $kind，点按查看',
            onTap: widget.onTap == null ? null : () => widget.onTap!(item),
            excludeSemantics: true,
            // Long-press lifts the print to drop it on the active sheet (same
            // mount as 📌); a plain tap still opens the lightbox and a swipe
            // still scrolls the handscroll.
            child: LongPressDraggable<String>(
              key: Key('handscroll_item_${item.id}'),
              data: item.id,
              maxSimultaneousDrags: 1,
              feedback: SizedBox(
                width: _kDragFeedbackSize,
                height: _kDragFeedbackSize,
                child: Material(
                  elevation: 6.0,
                  borderRadius: BorderRadius.circular(4.0),
                  clipBehavior: Clip.antiAlias,
                  child: KeepsakeThumbnail(
                    item: item,
                    mediaSandboxService: widget.mediaSandboxService,
                    isPaperDark: isPaperDark,
                    showPlayGlyph: false,
                  ),
                ),
              ),
              childWhenDragging: const Opacity(opacity: 0.3, child: SizedBox.expand()),
              child: GestureDetector(
              onTap: () => widget.onTap?.call(item),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: BrushReveal(
                  revealId: item.id,
                  status: widget.revealStatus,
                  isVideo: isVideo,
                  onComplete: widget.onRevealComplete,
                  seal: isVideo
                      ? _CinnabarPlaySeal(key: Key('handscroll_video_seal_${item.id}'), color: cinnabar)
                      : null,
                  child: KeepsakeThumbnail(
                    item: item,
                    mediaSandboxService: widget.mediaSandboxService,
                    isPaperDark: isPaperDark,
                    showPlayGlyph: false,
                  ),
                ),
              ),
              ),
            ),
          ),
          // 📌 and ✕ float on the print's upper corners (the video seal holds the
          // lower right), so the print keeps the slot's full height. They stay
          // hidden until the Brush Reveal settles.
          Positioned(
            top: 0,
            left: 0,
            child: _SlotCornerControl(
              isShown: isSettled,
              child: DeskMediaControl(
                key: Key('handscroll_mount_${item.id}'),
                icon: Icons.push_pin_outlined,
                isPaperDark: isPaperDark,
                hasBackdrop: true,
                semanticLabel: '贴至本页：待贴第 $ordinal 影 → 第 ${widget.activeSheetNumber} 页',
                onPressed: () => widget.onMount?.call(item),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _SlotCornerControl(
              isShown: isSettled,
              child: DeskMediaControl(
                key: Key('handscroll_erase_${item.id}'),
                icon: Icons.close,
                tone: DeskMediaControlTone.cinnabar,
                isPaperDark: isPaperDark,
                hasBackdrop: true,
                semanticLabel: '舍弃待贴第 $ordinal 影 · $kind',
                onPressed: _erase,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fades a corner control in once its print has been revealed.
class _SlotCornerControl extends StatelessWidget {
  final bool isShown;
  final Widget child;

  const _SlotCornerControl({required this.isShown, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isShown ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: child,
    );
  }
}

/// The cinnabar seal play stamp (朱印·映) marking a video: a carved square seal
/// with a paper-white play mark in intaglio (白文).
class _CinnabarPlaySeal extends StatelessWidget {
  final Color color;

  const _CinnabarPlaySeal({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24.0,
      height: 24.0,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3.0),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 2.0)],
      ),
      child: const Icon(Icons.play_arrow_rounded, size: 18, color: Color(0xFFFBF7EE)),
    );
  }
}
