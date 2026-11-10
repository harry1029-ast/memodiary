import 'dart:math' as math;

import '../sheet_mount_strip.dart';

/// How the walnut scholar's desk below the app bar is shared between the
/// desk's header band (page indicator), the active Stationery Sheet, the band
/// beneath it (Sheet Mount Strip or cinnabar seal) and the Desk Workstation.
///
/// While the workstation is docked the sheet sits just under the header band
/// and the workstation takes all the space left beneath, never less than
/// [kOpenMinHeight] (open handscroll) or [kClosedMinHeight] (closed brocade
/// scroll). When the diarist collapses the workstation the sheet centres on
/// the desk instead.
///
/// The budget is resolved against the resting desk height (keyboard closed),
/// so opening the software keyboard never moves or resizes the sheet: the
/// strip and workstation step aside, and the canvas lifts the sheet only as
/// far as the caret needs.
///
/// Whether the workstation fits is an entry-wide, start-up decision, so it is
/// judged against the sheet alone: strips come and go with page turns. Where a
/// strip is shown only the empty (closed) workstation settles to
/// [kClosedMinHeight]; a handscroll with staged prints keeps [kStripOpenMinHeight]
/// so each print stays above its caption bar.
class DeskSpaceBudget {
  static const double kOpenMinHeight = 150.0;
  static const double kClosedMinHeight = 110.0;
  static const double kStripOpenMinHeight = 130.0;

  /// Desk band above the sheet holding the page indicator.
  static const double kHeaderHeight = 30.0;
  static const double kBottomMargin = 12.0;
  static const double kSheetGap = 10.0;

  /// The Sheet Mount Strip's band, with breathing room for its shake.
  static const double kStripHeight = SheetMountStrip.kStripHeight + 4.0;
  static const double kStripGap = 8.0;

  /// Distance from the canvas top to the Stationery Sheet card.
  final double sheetTop;

  /// Distance from the canvas top to the Sheet Mount Strip.
  final double stripTop;
  final bool showStrip;
  final bool showWorkstation;

  /// Height of the workstation, measured up from the canvas bottom.
  final double workstationHeight;

  /// Whether the cinnabar seal rests between the sheet and the workstation.
  final bool showSeal;

  /// Whether the workstation's minimum height fits beneath the sheet and strip.
  final bool workstationFits;

  const DeskSpaceBudget._({
    required this.sheetTop,
    required this.stripTop,
    required this.showStrip,
    required this.showWorkstation,
    required this.workstationHeight,
    required this.showSeal,
    required this.workstationFits,
  });

  /// Distance from the canvas top to the header band holding the page indicator.
  double get headerTop => sheetTop - kHeaderHeight;

  /// [canvasHeight] is the resting desk height, keyboard closed.
  factory DeskSpaceBudget.resolve({
    required double canvasHeight,
    required double sheetHeight,
    required double sealBlockHeight,
    required bool hasMountedItems,
    required bool isHandscrollEmpty,
    required bool isWorkstationCollapsed,
    required bool isKeyboardVisible,
    required bool isLastSheet,
  }) {
    final showStrip = hasMountedItems && !isKeyboardVisible;
    final minHeight = isHandscrollEmpty ? kClosedMinHeight : kOpenMinHeight;
    final roomBelowSheet = canvasHeight - kHeaderHeight - sheetHeight - kSheetGap;
    final workstationFits = roomBelowSheet >= minHeight;
    // Staged prints need room above their 44pt caption bar, so a non-empty
    // handscroll keeps [kStripOpenMinHeight] even beneath a strip.
    final floorHeight = !hasMountedItems
        ? minHeight
        : (isHandscrollEmpty ? kClosedMinHeight : kStripOpenMinHeight);
    final showWorkstation = !isWorkstationCollapsed && !isKeyboardVisible;

    // The band beneath the sheet: its strip, or room for the seal.
    final belowSheetBlock = hasMountedItems
        ? kSheetGap + kStripHeight + kStripGap
        : sealBlockHeight;

    // Docked: the sheet sits under the header band. Collapsed: it centres.
    final centredTop = (canvasHeight - sheetHeight - belowSheetBlock + kHeaderHeight) / 2.0;
    final sheetTop = isWorkstationCollapsed
        ? math.max(kHeaderHeight, centredTop)
        : kHeaderHeight;

    final sheetBottom = sheetTop + sheetHeight;
    final reservedBelow = isWorkstationCollapsed ? 0.0 : floorHeight;
    final showSeal = !hasMountedItems &&
        !isKeyboardVisible &&
        isLastSheet &&
        sheetBottom + sealBlockHeight <= canvasHeight - reservedBelow;
    final occupied = sheetBottom + belowSheetBlock;

    return DeskSpaceBudget._(
      sheetTop: sheetTop,
      stripTop: sheetBottom + kSheetGap,
      showStrip: showStrip,
      showWorkstation: showWorkstation,
      workstationHeight: math.max(floorHeight, canvasHeight - occupied),
      showSeal: showSeal,
      workstationFits: workstationFits,
    );
  }
}
