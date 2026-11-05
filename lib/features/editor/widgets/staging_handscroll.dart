import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../domain/stationery_sheet_descriptor.dart';
import 'keepsake_thumbnail.dart';

/// The entry-wide Staging Handscroll (待贴画卷) holding collected photos and
/// videos that are not yet mounted on any Stationery Sheet.
///
/// Scrolls horizontally with about three slots visible, reading left to right
/// in collect order. Pure presentation: every action bubbles through callbacks.
class StagingHandscroll extends StatelessWidget {
  final List<SheetMediaItem> items;
  final MediaSandboxService mediaSandboxService;

  /// 1-based number of the active Stationery Sheet that 📌 mounts onto.
  final int activeSheetNumber;
  final ValueChanged<SheetMediaItem>? onTapItem;
  final ValueChanged<SheetMediaItem>? onMountItem;
  final ValueChanged<SheetMediaItem>? onEraseItem;
  final bool isPaperDark;

  static const double kVisibleSlots = 3;
  static const double kControlExtent = 44.0;

  const StagingHandscroll({
    super.key,
    required this.items,
    required this.mediaSandboxService,
    required this.activeSheetNumber,
    this.onTapItem,
    this.onMountItem,
    this.onEraseItem,
    this.isPaperDark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final silkColor = isPaperDark ? const Color(0xFF2A2724) : const Color(0xFFF3ECDD);
    final rollerColor = isPaperDark ? const Color(0xFF5A4632) : const Color(0xFF8A6A48);

    return Semantics(
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
            final slotWidth = constraints.maxWidth / kVisibleSlots;
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemExtent: slotWidth,
              itemBuilder: (itemContext, itemIndex) => _HandscrollSlot(
                key: ValueKey(items[itemIndex].id),
                item: items[itemIndex],
                ordinal: itemIndex + 1,
                activeSheetNumber: activeSheetNumber,
                mediaSandboxService: mediaSandboxService,
                isPaperDark: isPaperDark,
                onTap: onTapItem,
                onMount: onMountItem,
                onErase: onEraseItem,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One handscroll slot. ✕ plays an in-place ink-wash dissolve (the print
/// drains to grey and fades) before reporting the erase; with reduce-motion
/// the erase is reported at once.
class _HandscrollSlot extends StatefulWidget {
  final SheetMediaItem item;
  final int ordinal;
  final int activeSheetNumber;
  final MediaSandboxService mediaSandboxService;
  final bool isPaperDark;
  final ValueChanged<SheetMediaItem>? onTap;
  final ValueChanged<SheetMediaItem>? onMount;
  final ValueChanged<SheetMediaItem>? onErase;

  const _HandscrollSlot({
    super.key,
    required this.item,
    required this.ordinal,
    required this.activeSheetNumber,
    required this.mediaSandboxService,
    required this.isPaperDark,
    this.onTap,
    this.onMount,
    this.onErase,
  });

  @override
  State<_HandscrollSlot> createState() => _HandscrollSlotState();
}

class _HandscrollSlotState extends State<_HandscrollSlot> with SingleTickerProviderStateMixin {
  static const Duration kDissolveDuration = Duration(milliseconds: 450);

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

  static ColorFilter _inkWash(double amount) {
    // Linear blend between identity and luminance greyscale.
    final keep = 1.0 - amount;
    const r = 0.2126, g = 0.7152, b = 0.0722;
    return ColorFilter.matrix(<double>[
      keep + amount * r, amount * g, amount * b, 0, 0,
      amount * r, keep + amount * g, amount * b, 0, 0,
      amount * r, amount * g, keep + amount * b, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dissolve,
      builder: (animatedContext, child) {
        final progress = Curves.easeIn.transform(_dissolve.value);
        return IgnorePointer(
          ignoring: _dissolve.isAnimating,
          child: Opacity(
            key: Key('handscroll_dissolve_${widget.item.id}'),
            opacity: 1.0 - progress,
            child: ColorFiltered(
              colorFilter: _inkWash(math.min(1.0, progress * 2.0)),
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
    final inkColor = isPaperDark ? const Color(0xFFD6D1C7) : const Color(0xFF3C3836);
    final cinnabar = isPaperDark ? const Color(0xFFE57373) : const Color(0xFFB83B2E);
    final kind = item.mediaType == EphemeraMediaType.video ? '短影' : '影札';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: '待贴第 $ordinal 影 · $kind，点按查看',
              excludeSemantics: true,
              child: GestureDetector(
                key: Key('handscroll_item_${item.id}'),
                onTap: () => widget.onTap?.call(item),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: SizedBox.expand(
                    child: KeepsakeThumbnail(
                      item: item,
                      mediaSandboxService: widget.mediaSandboxService,
                      isPaperDark: isPaperDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SlotControl(
                key: Key('handscroll_mount_${item.id}'),
                icon: Icons.push_pin_outlined,
                color: inkColor,
                semanticLabel: '贴至本页：待贴第 $ordinal 影 → 第 ${widget.activeSheetNumber} 页',
                onPressed: () => widget.onMount?.call(item),
              ),
              _SlotControl(
                key: Key('handscroll_erase_${item.id}'),
                icon: Icons.close,
                color: cinnabar,
                semanticLabel: '舍弃待贴第 $ordinal 影 · $kind',
                onPressed: _erase,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A 44×44 slot action whose semantics name only that action.
class _SlotControl extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String semanticLabel;
  final VoidCallback onPressed;

  const _SlotControl({
    super.key,
    required this.icon,
    required this.color,
    required this.semanticLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: color,
        constraints: const BoxConstraints.tightFor(
          width: StagingHandscroll.kControlExtent,
          height: StagingHandscroll.kControlExtent,
        ),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        onPressed: onPressed,
      ),
    );
  }
}
