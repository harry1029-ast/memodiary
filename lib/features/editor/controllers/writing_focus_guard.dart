import 'package:flutter/widgets.dart';

import '../domain/stationery_sheet_descriptor.dart';

/// Keeps the software keyboard from appearing unbidden.
///
/// Quill asks for the keyboard on every change to a focused editor, and
/// Android keeps focus after the diarist dismisses the keyboard, so a desk
/// action (mount, unmount, erase) or returning from a picker or lightbox would
/// otherwise bring the keyboard back. The guard takes writing focus off the
/// Stationery Sheets before desk actions and whenever the keyboard is
/// dismissed, so only a tap on the text reopens it.
class WritingFocusGuard {
  final Iterable<StationerySheetDescriptor> Function() sheets;
  final bool Function() isKeyboardVisible;

  WritingFocusGuard({required this.sheets, required this.isKeyboardVisible});

  /// Takes focus off any focused sheet and settles the change at once, so the
  /// edit that follows (and the coordinator's focus restore after a
  /// repartition) already sees the sheet unfocused.
  void release() {
    for (final sheet in sheets()) {
      if (sheet is TextStationerySheet && sheet.focusNode.hasFocus) {
        sheet.focusNode.unfocus();
      }
    }
    FocusManager.instance.applyFocusChangesIfNeeded();
  }

  /// Call when the keyboard has just closed. Dismissing the keyboard while
  /// the editor is the current route ends writing, unless it reopens within
  /// the frame.
  void onKeyboardClosed(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted || isKeyboardVisible()) return;
      if (ModalRoute.of(context)?.isCurrent ?? true) release();
    });
  }
}
