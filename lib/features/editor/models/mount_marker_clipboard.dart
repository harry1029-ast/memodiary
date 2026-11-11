// Quill's paste hook is marked experimental; it is the only seam that lets an
// internal paste drop embeds, and the pinned flutter_quill version is locked.
// ignore_for_file: experimental_member_use
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'mount_marker.dart';

/// Keeps mount markers off the clipboard path (ADR-0009): pasting a passage
/// copied inside the editor inserts its text and formatting but never its
/// markers, so one keepsake is never mounted twice.
class MountMarkerClipboard {
  const MountMarkerClipboard._();

  /// Handles an internal paste whose copied Delta holds markers; returns false
  /// to leave every other paste to Quill's default handling.
  static Future<bool> pasteWithoutMarkers(QuillController controller) async {
    final copiedDelta = controller.pasteDelta;
    if (MountMarker.mediaIdsIn(copiedDelta).isEmpty) return false;
    final clipboardText = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (clipboardText == null ||
        clipboardText.isEmpty ||
        clipboardText != controller.pastePlainText) {
      return false;
    }
    final stripped = MountMarker.strip(copiedDelta);
    final selection = controller.selection;
    controller.replaceText(
      selection.start,
      selection.end - selection.start,
      stripped,
      TextSelection.collapsed(offset: selection.start + stripped.length),
    );
    return true;
  }
}
