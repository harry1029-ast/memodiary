import 'package:flutter/widgets.dart';

/// Tapping the bare Scholar's Desk, off the active Stationery Sheet, ends
/// writing, which puts the software keyboard away (iOS keyboards have no
/// close key of their own).
///
/// Taps on the sheet are ignored, and a control resting on the desk (a Page
/// Corner, a Tucked Print, the workstation) wins the gesture over this one, so
/// those keep their own behaviour.
class DeskOffSheetTap extends StatelessWidget {
  /// The active sheet, in [child]'s coordinates.
  final Rect sheetRect;

  /// Called for a tap off the sheet; null leaves the desk inert.
  final VoidCallback? onTapOffSheet;
  final Widget child;

  const DeskOffSheetTap({super.key, required this.sheetRect, required this.onTapOffSheet, required this.child});

  @override
  Widget build(BuildContext context) {
    final onTap = onTapOffSheet;
    if (onTap == null) return child;
    return GestureDetector(
      key: const Key('editor_desk_off_sheet_tap'),
      behavior: HitTestBehavior.translucent,
      onTapUp: (details) {
        if (!sheetRect.contains(details.localPosition)) onTap();
      },
      child: child,
    );
  }
}
