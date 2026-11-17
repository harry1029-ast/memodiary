// Quill's paste hook is marked experimental; it is the only seam that lets an
// internal paste drop embeds, and the pinned flutter_quill version is locked.
// ignore_for_file: experimental_member_use
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

import '../models/mount_marker.dart';
import '../models/mount_marker_clipboard.dart';

/// Hears every change to one Stationery Sheet's document, in the order the
/// changes are applied: each is reported once the document holds it and
/// before the controller notifies its listeners (which may edit again).
abstract interface class StationeryEditObserver {
  /// [insertedText] now stands at [index], where [deletedLength] characters
  /// were removed. [index] is where the edit really landed, after the mount
  /// marker heuristics. [ignoreFocus] marks a programmatic edit.
  void onTextReplaced(int index, int deletedLength, String insertedText, {required bool ignoreFocus});

  /// The document changed in a way that is not one plain text replacement:
  /// undo, redo, a document swap (Auto-Spill, Spill-Back), an embed, a paste
  /// carrying formatting, or a format change.
  void onStructuralChange();
}

/// A [QuillController] tailored for Stationery Sheets.
///
/// Anchors invisible [MountMarker] embeds to their preceding text passage,
/// protects them from accidental single-character Backspace deletions while
/// editing, and preserves the unmount lifecycle when a diarist explicitly
/// deletes the passage or backspaces past the last character. Reports every
/// document change to its [editObserver].
class StationeryQuillController extends QuillController {
  /// Invoked when a single-character Backspace from a collapsed cursor hits a
  /// leading mount marker with no preceding text on the sheet.
  VoidCallback? onBackspaceAtStart;

  /// Hears this sheet's document changes (the Ink Choreography overlay).
  StationeryEditObserver? editObserver;

  /// The change being applied, reported by [_reportChange] as soon as the
  /// document holds it.
  void Function(StationeryEditObserver observer)? _unreportedChange;

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

  /// Handles a Backspace action at the leading text edge of the sheet (offset 0
  /// or immediately after leading invisible mount markers with no preceding text).
  ///
  /// Invokes [onBackspaceAtStart] when assigned and returns `true` when handled.
  bool handleLeadingBackspace() {
    if (!selection.isCollapsed) return false;
    if (MountMarker.prevNonMarkerOffset(document.toDelta(), selection.baseOffset) != null) {
      return false;
    }
    final callback = onBackspaceAtStart;
    if (callback == null) return false;
    callback();
    return true;
  }

  static void _structuralChange(StationeryEditObserver observer) => observer.onStructuralChange();

  void _reportChange() {
    final report = _unreportedChange;
    _unreportedChange = null;
    final observer = editObserver;
    if (report != null && observer != null) report(observer);
  }

  /// Runs [change] and reports it as structural.
  void _applyStructuralChange(VoidCallback change) {
    _unreportedChange = _structuralChange;
    change();
    _reportChange();
  }

  @override
  void notifyListeners() {
    _reportChange();
    super.notifyListeners();
  }

  @override
  set document(Document newDocument) => _applyStructuralChange(() => super.document = newDocument);

  @override
  void undo() => _applyStructuralChange(super.undo);

  @override
  void redo() => _applyStructuralChange(super.redo);

  @override
  void formatText(int index, int len, Attribute? attribute, {bool shouldNotifyListeners = true}) =>
      _applyStructuralChange(
        () => super.formatText(index, len, attribute, shouldNotifyListeners: shouldNotifyListeners),
      );

  /// Applies the replacement at its final [index] and reports it: as a text
  /// replacement when the document changed by exactly that text, otherwise
  /// (an embed, a Delta, or Quill's own rules reshaping the edit) as a
  /// structural change.
  void _replaceAndReport(
    int index,
    int len,
    Object? data,
    TextSelection? textSelection, {
    required bool ignoreFocus,
    required bool shouldNotifyListeners,
  }) {
    final lengthBefore = document.length;
    _unreportedChange = (observer) {
      if (data is String &&
          document.length - lengthBefore == data.length - len &&
          document.toPlainText().startsWith(data, index)) {
        if (len > 0 || data.isNotEmpty) observer.onTextReplaced(index, len, data, ignoreFocus: ignoreFocus);
        return;
      }
      observer.onStructuralChange();
    };
    super.replaceText(
      index,
      len,
      data,
      textSelection,
      ignoreFocus: ignoreFocus,
      shouldNotifyListeners: shouldNotifyListeners,
    );
    _reportChange();
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
      _replaceAndReport(
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
        _replaceAndReport(
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
    // single-character deletion invokes [handleLeadingBackspace] (for continuation
    // sheet spill-back) without unmounting the keepsake on Sheet 1.
    // Explicit selections (len > 1 or !priorSelection.isCollapsed) delete normally.
    final priorSelection = selection;
    final isEmptyReplacement = (data is! String || data.isEmpty) &&
        data is! Embeddable &&
        data is! Delta;
    if (priorSelection.isCollapsed && isEmptyReplacement) {
      if (index == 0 && len == 0 && priorSelection.baseOffset == 0) {
        handleLeadingBackspace();
        return;
      }
      if (len == 1) {
        final delta = document.toDelta();
        if (MountMarker.isMarkerAt(delta, index)) {
          if (priorSelection.baseOffset >= index + 1) {
            final target = MountMarker.prevNonMarkerOffset(delta, index);
            if (target != null) {
              _replaceAndReport(
                target,
                1,
                '',
                TextSelection.collapsed(offset: target),
                ignoreFocus: ignoreFocus,
                shouldNotifyListeners: shouldNotifyListeners,
              );
            } else {
              handleLeadingBackspace();
            }
          }
          return;
        }
      }
    }

    _replaceAndReport(
      index,
      len,
      data,
      textSelection,
      ignoreFocus: ignoreFocus,
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }
}
