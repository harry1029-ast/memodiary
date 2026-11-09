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
  double _lastKeyboardInset = 0.0;

  WritingFocusGuard({required this.sheets});

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

  /// Call on every build with the current keyboard inset. Dismissing the
  /// keyboard while the editor is the current route ends writing.
  void onKeyboardInset(BuildContext context, double keyboardInset) {
    final wasOpen = _lastKeyboardInset > 0;
    _lastKeyboardInset = keyboardInset;
    if (!wasOpen || keyboardInset > 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted || _lastKeyboardInset > 0) return;
      if (ModalRoute.of(context)?.isCurrent ?? true) release();
    });
  }
}
