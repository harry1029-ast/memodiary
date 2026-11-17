import 'dart:async';

import 'package:flutter_quill/flutter_quill.dart' show QuillController;

import 'editor_pagination_coordinator.dart';

/// Keeps [EditorPaginationCoordinator.isImeComposing] true while the IME is
/// composing on a text sheet, so Auto-Spill, Spill-Back and mount reflow
/// wait for the composition to commit (Stationery Sheet Spill IME Symmetry).
abstract final class ImeComposingGuard {
  /// Call when the IME starts or stops composing on [controller]'s sheet
  /// (only the sheet holding the keyboard can compose). When a composition
  /// ends, the pagination it put off is resumed once the keyboard update
  /// that ended it has been applied in full.
  static void report(
    EditorPaginationCoordinator coordinator,
    QuillController controller, {
    required bool isComposing,
  }) {
    final wasComposing = coordinator.isImeComposing;
    coordinator.isImeComposing = isComposing;
    if (wasComposing && !isComposing) {
      // Quill clears the composing range before it writes the committed
      // text of the same update; paginating now would move text under it.
      scheduleMicrotask(() => coordinator.resumeDeferredPagination(controller));
    }
  }
}
