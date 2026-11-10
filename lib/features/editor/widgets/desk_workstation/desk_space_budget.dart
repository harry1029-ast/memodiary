import 'dart:math' as math;

/// How the Scholar's Desk below the app bar is shared between the
/// desk's header band (page indicator and the tops of the Tucked Prints), the
/// active Stationery Sheet, the room beneath it for the Cinnabar Signature Seal
/// and the Desk Workstation.
///
/// While the workstation is docked the sheet sits just under the header band
/// and the workstation takes all the space left beneath, never less than
/// [kOpenMinHeight] (open handscroll) or [kClosedMinHeight] (closed brocade
/// scroll). When the diarist collapses the workstation the sheet centres on
/// the desk instead. Tucked Prints take no band of their own: they peek out of
/// the header band above the sheet.
///
/// The budget is resolved against the resting desk height (keyboard closed),
/// so opening the software keyboard never moves or resizes the sheet: the
/// workstation steps aside, and the KeyboardDeskLift lifts the whole desk so
/// the whole sheet shows (or, when it cannot fit, just far enough for the
/// caret).
///
/// Whether the workstation fits is an entry-wide, start-up decision, judged
/// against the sheet alone.
class DeskSpaceBudget {
  static const double kOpenMinHeight = 150.0;
  static const double kClosedMinHeight = 110.0;

  /// Desk band above the sheet holding the page indicator and Tucked Prints.
  static const double kHeaderHeight = 30.0;

  /// Gap between the desk's foot and the Restore Pill.
  static const double kBottomMargin = 12.0;
  static const double kSheetGap = 10.0;

  /// Distance from the canvas top to the Stationery Sheet card.
  final double sheetTop;
  final bool showWorkstation;

  /// Height of the workstation, measured up from the canvas bottom.
  final double workstationHeight;

  /// Whether the cinnabar seal rests between the sheet and the workstation.
  final bool showSeal;

  /// Whether the workstation's minimum height fits beneath the sheet.
  final bool workstationFits;

  const DeskSpaceBudget._({
    required this.sheetTop,
    required this.showWorkstation,
    required this.workstationHeight,
    required this.showSeal,
    required this.workstationFits,
  });

  /// Distance from the canvas top to the header band.
  double get headerTop => sheetTop - kHeaderHeight;

  /// [canvasHeight] is the resting desk height, keyboard closed.
  factory DeskSpaceBudget.resolve({
    required double canvasHeight,
    required double sheetHeight,
    required double sealBlockHeight,
    required bool isHandscrollEmpty,
    required bool isWorkstationCollapsed,
    required bool isKeyboardVisible,
    required bool isLastSheet,
  }) {
    final minHeight = isHandscrollEmpty ? kClosedMinHeight : kOpenMinHeight;
    final roomBelowSheet = canvasHeight - kHeaderHeight - sheetHeight - kSheetGap;
    final workstationFits = roomBelowSheet >= minHeight;
    final showWorkstation = !isWorkstationCollapsed && !isKeyboardVisible;

    // Docked: the sheet sits under the header band. Collapsed: it centres,
    // with room beneath it for the seal.
    final centredTop = (canvasHeight - sheetHeight - sealBlockHeight + kHeaderHeight) / 2.0;
    final sheetTop = isWorkstationCollapsed
        ? math.max(kHeaderHeight, centredTop)
        : kHeaderHeight;

    final sheetBottom = sheetTop + sheetHeight;
    final reservedBelow = isWorkstationCollapsed ? 0.0 : minHeight;
    final showSeal = !isKeyboardVisible &&
        isLastSheet &&
        sheetBottom + sealBlockHeight <= canvasHeight - reservedBelow;

    return DeskSpaceBudget._(
      sheetTop: sheetTop,
      showWorkstation: showWorkstation,
      // The seal's room is kept on every sheet, not only the last, so the
      // workstation keeps one height across page turns.
      workstationHeight: math.max(minHeight, canvasHeight - sheetBottom - sealBlockHeight),
      showSeal: showSeal,
      workstationFits: workstationFits,
    );
  }
}
