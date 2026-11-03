import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import '../models/media_embed_data.dart';

/// Row capacity limits for stationery sheet viewports.
const int kOpeningSheetRowCapacity = 10;
const int kContinuationSheetRowCapacity = 14;
const int kJournalLetterheadReservedRows = 4;
const int kStandardFolioRowsPerLeaf = 14;

/// Base descriptor for discrete Stationery Sheets (信笺书页) in the paginated editor.
sealed class StationerySheetDescriptor {
  final int sheetIndex;

  const StationerySheetDescriptor({
    required this.sheetIndex,
  });

  /// Whether this sheet represents the opening page hosting the Journal Letterhead.
  bool get isOpeningSheet => this is OpeningSheet;

  /// Whether this sheet represents a continuation page with running colophon header.
  bool get isContinuationSheet => this is ContinuationSheet;

  /// Whether this sheet represents a dedicated photo or video ephemera mount.
  bool get isEphemeraSheet => this is EphemeraSheet;

  /// Whether this sheet contains an editable rich-text Quill controller.
  bool get isTextSheet => this is TextStationerySheet;

  /// Disposes internal controllers and focus nodes.
  void dispose();

  /// Creates a shallow copy with an updated sheet index.
  StationerySheetDescriptor copyWithIndex(int newIndex);
}

/// Abstract base descriptor for text-bearing stationery sheets.
sealed class TextStationerySheet extends StationerySheetDescriptor {
  QuillController controller;
  final FocusNode focusNode;

  /// Whether the sheet's document ends with an artificial soft newline
  /// introduced to split a single paragraph across sheets for valid Quill Document structure.
  bool hasTrailingSoftNewline;

  TextStationerySheet({
    required super.sheetIndex,
    required this.controller,
    FocusNode? focusNode,
    this.hasTrailingSoftNewline = false,
  }) : focusNode = focusNode ?? FocusNode();

  /// Maximum integer visual row capacity on this stationery sheet.
  int get rowCapacity;

  /// The active Quill document for this sheet.
  Document get document => controller.document;

  /// The active Delta for this sheet.
  Delta get delta => document.toDelta();

  /// Plain text content of this sheet.
  String get plainText => document.toPlainText();

  /// Whether the sheet contains only whitespace or is empty.
  bool get isEmpty => plainText.trim().isEmpty;

  /// Replaces this sheet's controller document cleanly with [newDelta]
  /// preserving or restoring appropriate text selection.
  void setDelta(Delta newDelta, {TextSelection? selection}) {
    final newDoc = Document.fromDelta(newDelta);
    final targetSelection = selection ??
        TextSelection.collapsed(
          offset: math.min(
            controller.selection.baseOffset,
            math.max(0, newDoc.length - 1),
          ),
        );
    controller.dispose();
    controller = QuillController(
      document: newDoc,
      selection: targetSelection,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

/// Sheet 1: The opening stationery sheet capped at 10 integer body rows
/// beneath the 4-row interactive Journal Letterhead.
class OpeningSheet extends TextStationerySheet {
  static const int kRowCapacity = kOpeningSheetRowCapacity;
  static const int kLetterheadRows = kJournalLetterheadReservedRows;

  OpeningSheet({
    required super.sheetIndex,
    required super.controller,
    super.focusNode,
    super.hasTrailingSoftNewline = false,
  });

  /// Creates an empty opening sheet with a fresh basic QuillController.
  factory OpeningSheet.empty({int sheetIndex = 0}) {
    return OpeningSheet(
      sheetIndex: sheetIndex,
      controller: QuillController.basic(),
    );
  }

  /// Creates an opening sheet populated with the specified Delta.
  factory OpeningSheet.fromDelta({
    required int sheetIndex,
    required Delta delta,
    bool hasTrailingSoftNewline = false,
  }) {
    final controller = QuillController(
      document: Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );
    return OpeningSheet(
      sheetIndex: sheetIndex,
      controller: controller,
      hasTrailingSoftNewline: hasTrailingSoftNewline,
    );
  }

  @override
  int get rowCapacity => kRowCapacity;

  @override
  OpeningSheet copyWithIndex(int newIndex) {
    return OpeningSheet(
      sheetIndex: newIndex,
      controller: controller,
      focusNode: focusNode,
      hasTrailingSoftNewline: hasTrailingSoftNewline,
    );
  }
}

/// Sheet 2+: Continuation stationery sheets capped at 14 integer body rows
/// beneath a compact running colophon header.
class ContinuationSheet extends TextStationerySheet {
  static const int kRowCapacity = kContinuationSheetRowCapacity;

  ContinuationSheet({
    required super.sheetIndex,
    required super.controller,
    super.focusNode,
    super.hasTrailingSoftNewline = false,
  });

  /// Creates an empty continuation sheet with a fresh basic QuillController.
  factory ContinuationSheet.empty({required int sheetIndex}) {
    return ContinuationSheet(
      sheetIndex: sheetIndex,
      controller: QuillController.basic(),
    );
  }

  /// Creates a continuation sheet populated with the specified Delta.
  factory ContinuationSheet.fromDelta({
    required int sheetIndex,
    required Delta delta,
    bool hasTrailingSoftNewline = false,
  }) {
    final controller = QuillController(
      document: Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );
    return ContinuationSheet(
      sheetIndex: sheetIndex,
      controller: controller,
      hasTrailingSoftNewline: hasTrailingSoftNewline,
    );
  }

  @override
  int get rowCapacity => kRowCapacity;

  @override
  ContinuationSheet copyWithIndex(int newIndex) {
    return ContinuationSheet(
      sheetIndex: newIndex,
      controller: controller,
      focusNode: focusNode,
      hasTrailingSoftNewline: hasTrailingSoftNewline,
    );
  }
}

/// A dedicated full-page ephemera mount presenting an embedded photo or short video
/// paired with an editable caption and silk corner framing.
class EphemeraSheet extends StationerySheetDescriptor {
  /// 'image' or 'video'
  final String mediaType;

  /// Parsed embed metadata (path, caption, aspect ratio)
  final MediaEmbedData mediaData;

  /// Editable text controller for the ephemera caption
  final TextEditingController captionController;

  /// Dedicated focus node for caption input
  final FocusNode focusNode;

  EphemeraSheet({
    required super.sheetIndex,
    required this.mediaType,
    required this.mediaData,
    TextEditingController? captionController,
    FocusNode? focusNode,
  })  : captionController = captionController ??
            TextEditingController(text: mediaData.caption),
        focusNode = focusNode ?? FocusNode();

  /// Creates an ephemera sheet descriptor from raw BlockEmbed data.
  factory EphemeraSheet.fromEmbed({
    required int sheetIndex,
    required String mediaType,
    required dynamic rawData,
  }) {
    final embedData = MediaEmbedData.fromRaw(rawData);
    return EphemeraSheet(
      sheetIndex: sheetIndex,
      mediaType: mediaType,
      mediaData: embedData,
    );
  }

  /// Sandboxed relative path inside app documents directory.
  String get sandboxedRelativePath => mediaData.path;

  /// The active caption text.
  String get caption => captionController.text;

  /// Aspect ratio code ('auto', '4:3', '1:1').
  String get aspect => mediaData.aspect;

  /// Current metadata reflecting any edits made in [captionController].
  MediaEmbedData get currentMediaData =>
      mediaData.copyWith(caption: captionController.text);

  @override
  void dispose() {
    captionController.dispose();
    focusNode.dispose();
  }

  @override
  EphemeraSheet copyWithIndex(int newIndex) {
    return EphemeraSheet(
      sheetIndex: newIndex,
      mediaType: mediaType,
      mediaData: currentMediaData,
      captionController: captionController,
      focusNode: focusNode,
    );
  }
}
