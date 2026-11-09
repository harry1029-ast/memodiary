import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/desk_media_handlers.dart';
import 'desk_workstation/desk_space_budget.dart';
import 'desk_workstation/desk_workstation.dart';
import 'fullscreen_media_lightbox.dart';
import 'sheet_mount_strip.dart';

/// The desk area around the active Stationery Sheet, laid out by a
/// [DeskSpaceBudget]: that sheet's Sheet Mount Strip just beneath it, and the
/// Desk Workstation holding the entry-wide Staging Handscroll at the bottom.
/// Both step aside (slide and fade) when the budget hides them. Tapping any
/// item opens the fullscreen lightbox; collect, mount and erase bubble up.
///
/// Fills the canvas [Stack]; only the strip and workstation take hits.
class EditorDeskMediaArea extends StatelessWidget {
  final DeskSpaceBudget budget;
  final List<SheetMediaItem> mountedItems;
  final List<SheetMediaItem> stagedItems;
  final MediaSandboxService mediaSandboxService;

  /// 1-based number of the active Stationery Sheet.
  final int activeSheetNumber;
  final bool isPaperDark;

  /// Collect, mount, erase, unmount and Brush Reveal plumbing.
  final DeskMediaHandlers handlers;
  final void Function(String mediaId, String newCaption)? onCaptionChanged;

  static const Duration kStepAsideDuration = Duration(milliseconds: 250);

  const EditorDeskMediaArea({
    super.key,
    required this.budget,
    required this.mountedItems,
    required this.stagedItems,
    required this.mediaSandboxService,
    required this.activeSheetNumber,
    this.isPaperDark = false,
    this.handlers = const DeskMediaHandlers(),
    this.onCaptionChanged,
  });

  void _openLightbox(BuildContext context, List<SheetMediaItem> items, SheetMediaItem item) {
    handlers.onDeskInteraction?.call();
    FullscreenMediaLightbox.show(
      context,
      items: items,
      initialIndex: items.indexOf(item),
      mediaSandboxService: mediaSandboxService,
      onCaptionChanged: onCaptionChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: budget.stripTop,
          left: 16.0,
          right: 16.0,
          height: DeskSpaceBudget.kStripHeight,
          child: _StepAside(
            isShown: budget.showStrip && mountedItems.isNotEmpty,
            child: Center(
              child: SheetMountStrip(
                items: mountedItems,
                mediaSandboxService: mediaSandboxService,
                isPaperDark: isPaperDark,
                onTapItem: (item) => _openLightbox(context, mountedItems, item),
                onUnmountItem: (item) => handlers.onUnmount?.call(item.id),
                refusalSignal: handlers.mountRefusals,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0.0,
          right: 0.0,
          bottom: 0.0,
          height: budget.workstationHeight,
          child: _StepAside(
            isShown: budget.showWorkstation,
            child: DeskWorkstation(
              stagedItems: stagedItems,
              mediaSandboxService: mediaSandboxService,
              activeSheetNumber: activeSheetNumber,
              handlers: handlers,
              onTapItem: (item) => _openLightbox(context, stagedItems, item),
            ),
          ),
        ),
      ],
    );
  }
}

/// Slides a desk element down and fades it out when hidden, then drops it from
/// the tree so it takes no hits and no semantics.
class _StepAside extends StatelessWidget {
  final bool isShown;
  final Widget child;

  const _StepAside({required this.isShown, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: EditorDeskMediaArea.kStepAsideDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (transitionChild, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.0, 0.4), end: Offset.zero).animate(animation),
          child: transitionChild,
        ),
      ),
      child: isShown
          ? KeyedSubtree(key: const ValueKey('shown'), child: child)
          : const SizedBox.shrink(key: ValueKey('hidden')),
    );
  }
}
