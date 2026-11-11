// Quill's paste hook is marked experimental; it is the only seam that lets an
// internal paste drop embeds, and the pinned flutter_quill version is locked.
// ignore_for_file: experimental_member_use
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

import '../models/mount_marker.dart';
import '../models/mount_marker_clipboard.dart';

/// A [QuillController] tailored for Stationery Sheets.
///
/// Anchors invisible [MountMarker] embeds to their preceding text passage,
/// protects them from accidental single-character Backspace deletions while
/// editing, and preserves the unmount lifecycle when a diarist explicitly
/// deletes the passage or backspaces past the last character.
class StationeryQuillController extends QuillController {
  /// Invoked when a single-character Backspace from a collapsed cursor hits a
  /// leading mount marker with no preceding text on the sheet.
  VoidCallback? onBackspaceAtStart;

  StationeryQuillController._({
    required super.document,
    required super.selection,
    super.config,
    this.onBackspaceAtStart,
  });

  /// Creates a [StationeryQuillController] configured with mount marker
  /// clipboard filtering and replacement heuristics.
  factory StationeryQuillController({
    Document? document,
    TextSelection selection = const TextSelection.collapsed(offset: 0),
    QuillControllerConfig? config,
    VoidCallback? onBackspaceAtStart,
  }) {
    late final StationeryQuillController controller;
    controller = StationeryQuillController._(
      document: document ?? Document(),
      selection: selection,
      onBackspaceAtStart: onBackspaceAtStart,
      config: config ??
          QuillControllerConfig(
            clipboardConfig: QuillClipboardConfig(
              onClipboardPaste: () => MountMarkerClipboard.pasteWithoutMarkers(controller),
            ),
          ),
    );
    return controller;
  }

  @override
  void replaceText(
    int index,
    int len,
    Object? data,
    TextSelection? textSelection, {
    bool ignoreFocus = false,
    bool shouldNotifyListeners = true,
  }) {
    // Programmatic operations (e.g. unmounting or stripping duplicates) explicitly
    // bypass user-input heuristics via ignoreFocus.
    if (ignoreFocus) {
      super.replaceText(
        index,
        len,
        data,
        textSelection,
        ignoreFocus: ignoreFocus,
        shouldNotifyListeners: shouldNotifyListeners,
      );
      return;
    }

    // Heuristic 1: If inserting a newline at an offset holding one or more
    // mount markers, advance insertion past the markers so they remain
    // anchored to the current line and the new line is truly empty.
    if (data is String && (data.startsWith('\n') || data.startsWith('\r\n'))) {
      final markerSpan = MountMarker.consecutiveMarkersAt(document.toDelta(), index);
      if (markerSpan > 0) {
        final shiftedIndex = index + markerSpan;
        final shiftedSelection = (textSelection != null && textSelection.isCollapsed)
            ? TextSelection.collapsed(offset: textSelection.baseOffset + markerSpan)
            : textSelection;
        super.replaceText(
          shiftedIndex,
          len,
          data,
          shiftedSelection,
          ignoreFocus: ignoreFocus,
          shouldNotifyListeners: shouldNotifyListeners,
        );
        return;
      }
    }

    // Heuristic 2: Single-character Backspace from a collapsed cursor targeting
    // an invisible mount marker embed is redirected to the nearest preceding
    // real character. If no text precedes the marker (e.g. start of sheet),
    // single-character deletion invokes [onBackspaceAtStart] (for continuation
    // sheet spill-back) without unmounting the keepsake on Sheet 1.
    // Explicit selections (len > 1 or !priorSelection.isCollapsed) delete normally.
    final priorSelection = selection;
    final isEmptyReplacement = (data is! String || data.isEmpty) &&
        data is! Embeddable &&
        data is! Delta;
    if (priorSelection.isCollapsed && isEmptyReplacement) {
      if (index == 0 && len == 0 && priorSelection.baseOffset == 0) {
        onBackspaceAtStart?.call();
        return;
      }
      if (len == 1) {
        final delta = document.toDelta();
        if (MountMarker.isMarkerAt(delta, index)) {
          if (priorSelection.baseOffset >= index + 1) {
            final target = MountMarker.prevNonMarkerOffset(delta, index);
            if (target != null) {
              super.replaceText(
                target,
                1,
                '',
                TextSelection.collapsed(offset: target),
                ignoreFocus: ignoreFocus,
                shouldNotifyListeners: shouldNotifyListeners,
              );
            } else {
              onBackspaceAtStart?.call();
            }
          }
          return;
        }
      }
    }

    super.replaceText(
      index,
      len,
      data,
      textSelection,
      ignoreFocus: ignoreFocus,
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }
}
