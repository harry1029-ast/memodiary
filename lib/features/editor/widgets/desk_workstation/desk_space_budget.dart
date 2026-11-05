import 'dart:math' as math;

import '../sheet_mount_strip.dart';

/// How the scholar's desk below the app bar is shared between the active
/// Stationery Sheet, its Sheet Mount Strip and the Desk Workstation.
///
/// The workstation rests at the bottom and takes whatever vertical space the
/// sheet and strip leave, never less than [kOpenMinHeight] (open handscroll) or
/// [kClosedMinHeight] (closed brocade scroll). While the software keyboard is
/// open the strip and workstation step aside so the active line stays visible.
///
/// Whether the workstation fits is an entry-wide, start-up decision, so it is
/// judged against the sheet alone: strips come and go with page turns. Where a
/// strip is shown the open handscroll may settle to [kClosedMinHeight] rather
/// than cover the strip.
class DeskSpaceBudget {
  static const double kOpenMinHeight = 150.0;
  static const double kClosedMinHeight = 110.0;
  static const double kTopMargin = 12.0;
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

  /// Bottom inset that docks the page indicator on the workstation's top edge,
  /// clear of the strip and the slot controls.
  double get pageIndicatorBottomInset =>
      showWorkstation ? math.max(kBottomMargin, workstationHeight - 11.0) : kBottomMargin;

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
    final stripBlock = hasMountedItems ? kStripHeight + kStripGap : 0.0;
    final minHeight = isHandscrollEmpty ? kClosedMinHeight : kOpenMinHeight;
    final roomBelowSheet = canvasHeight - kTopMargin - sheetHeight - kSheetGap;
    final workstationFits = roomBelowSheet >= minHeight;
    final floorHeight = showStrip ? kClosedMinHeight : minHeight;
    final showWorkstation = !isWorkstationCollapsed && !isKeyboardVisible;

    // Text-only sheets keep SPEC-009's centering in the room above the workstation.
    final reserved = showWorkstation ? minHeight : 0.0;
    final centeredRoom = canvasHeight - reserved;
    final centers = !hasMountedItems &&
        !isKeyboardVisible &&
        centeredRoom > sheetHeight + sealBlockHeight + 2 * kTopMargin;
    final sheetTop = centers
        ? math.max(kTopMargin, (centeredRoom - sheetHeight - sealBlockHeight) / 2.0)
        : kTopMargin;

    final showSeal = !hasMountedItems &&
        !isKeyboardVisible &&
        isLastSheet &&
        sheetTop + sheetHeight + sealBlockHeight <= centeredRoom;
    final stripTop = sheetTop + sheetHeight + kSheetGap;
    final occupied = showSeal
        ? sheetTop + sheetHeight + sealBlockHeight
        : stripTop + (showStrip ? stripBlock : 0.0);

    return DeskSpaceBudget._(
      sheetTop: sheetTop,
      stripTop: stripTop,
      showStrip: showStrip,
      showWorkstation: showWorkstation,
      workstationHeight: math.max(floorHeight, canvasHeight - occupied),
      showSeal: showSeal,
      workstationFits: workstationFits,
    );
  }
}
