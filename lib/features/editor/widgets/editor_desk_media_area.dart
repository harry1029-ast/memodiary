import 'package:flutter/material.dart';

import '../../../core/services/media_sandbox_service.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/desk_media_handlers.dart';
import 'desk_workstation/desk_space_budget.dart';
import 'desk_workstation/desk_workstation.dart';
import 'desk_workstation/workstation_collapse_controls.dart';
import 'fullscreen_media_lightbox.dart';
import 'tucked_prints/tucked_prints_fan.dart';

/// The desk area around the active Stationery Sheet, laid out by a
/// [DeskSpaceBudget]: that sheet's Tucked Prints peeking out of the header
/// band above its top right edge, and the Desk Workstation holding the
/// entry-wide Staging Handscroll at the bottom, which steps aside (slides and
/// fades) when the budget hides it. Tapping an item opens the fullscreen
/// lightbox; collect, mount and erase bubble up.
///
/// The workstation's brass pull tab puts it away; while it is away the Restore
/// Pill rests at the foot of the desk and brings it back.
///
/// Fills the canvas [Stack]; only the prints, workstation and these controls
/// take hits.
class EditorDeskMediaArea extends StatelessWidget {
  final DeskSpaceBudget budget;
  final List<SheetMediaItem> mountedItems;
  final List<SheetMediaItem> stagedItems;
  final MediaSandboxService mediaSandboxService;

  /// 1-based number of the active Stationery Sheet.
  final int activeSheetNumber;
  final bool isPaperDark;

  /// Whether the diarist (or a short desk) has put the workstation away.
  final bool isWorkstationCollapsed;
  final VoidCallback? onCollapseWorkstation;
  final VoidCallback? onRestoreWorkstation;

  /// Collect, mount, erase, unmount and Brush Reveal plumbing.
  final DeskMediaHandlers handlers;
  final void Function(String mediaId, String newCaption)? onCaptionChanged;

  static const Duration kStepAsideDuration = Duration(milliseconds: 250);

  /// Inset of the Tucked Prints from the desk's right edge.
  static const double kPrintsRightInset = 24.0;

  const EditorDeskMediaArea({
    super.key,
    required this.budget,
    required this.mountedItems,
    required this.stagedItems,
    required this.mediaSandboxService,
    required this.activeSheetNumber,
    this.isPaperDark = false,
    this.isWorkstationCollapsed = false,
    this.onCollapseWorkstation,
    this.onRestoreWorkstation,
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
          top: budget.headerTop,
          right: kPrintsRightInset,
          height: TuckedPrintsFan.kTargetHeight,
          child: TuckedPrintsFan(
            // Keyed by sheet: a page turn shows its prints at rest.
            key: ValueKey('tucked_prints_sheet_$activeSheetNumber'),
            items: mountedItems,
            mediaSandboxService: mediaSandboxService,
            sheetEdgeOffset: DeskSpaceBudget.kHeaderHeight,
            isPaperDark: isPaperDark,
            // The fanned overlay arrives with SPEC-011 ticket 07.
            onTap: () => _openLightbox(context, mountedItems, mountedItems.first),
            refusalSignal: handlers.mountRefusals,
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
        // The pull tab straddles the workstation's top edge.
        Positioned(
          left: 0.0,
          right: 0.0,
          bottom: budget.workstationHeight - WorkstationPullTab.kTargetSize / 2.0,
          height: WorkstationPullTab.kTargetSize,
          child: _StepAside(
            isShown: budget.showWorkstation && onCollapseWorkstation != null,
            child: Center(child: WorkstationPullTab(onCollapse: onCollapseWorkstation!)),
          ),
        ),
        Positioned(
          left: 16.0,
          right: 16.0,
          bottom: DeskSpaceBudget.kBottomMargin,
          child: _StepAside(
            isShown: isWorkstationCollapsed && onRestoreWorkstation != null,
            child: Center(
              child: WorkstationRestorePill(
                stagedCount: stagedItems.length,
                onRestore: onRestoreWorkstation!,
              ),
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
