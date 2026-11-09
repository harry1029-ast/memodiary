import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import '../models/media_embed_data.dart';
import '../models/mount_marker_clipboard.dart';
import 'sheet_media_item.dart';

export 'sheet_media_item.dart';

/// Row capacity limits for stationery sheet viewports.
const int kOpeningSheetRowCapacity = 10;
const int kContinuationSheetRowCapacity = 14;
const int kJournalLetterheadReservedRows = 4;
const int kStandardFolioRowsPerLeaf = 14;

/// Supported media types for full-sheet ephemera mounts.
enum EphemeraMediaType {
  image('image'),
  video('video');

  final String embedKey;

  const EphemeraMediaType(this.embedKey);

  /// Resolves an [EphemeraMediaType] from its serialized Delta embed key or SQLite column value.
  static EphemeraMediaType fromEmbedKey(String rawKey) {
    return rawKey == 'video' ? EphemeraMediaType.video : EphemeraMediaType.image;
  }
}

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
  final QuillController controller;
  final FocusNode focusNode;

  /// Reaches this sheet's live editor so the canvas can find the caret and keep
  /// it above the software keyboard.
  final GlobalKey<EditorState> editorKey = GlobalKey<EditorState>();

  /// Keepsake photos or short videos attached directly to this sheet (up to 3 items).
  final List<SheetMediaItem> mediaAttachments;

  /// Whether the sheet's document ends with an artificial soft newline
  /// introduced to split a single paragraph across sheets for valid Quill Document structure.
  bool hasTrailingSoftNewline;

  TextStationerySheet({
    required super.sheetIndex,
    required this.controller,
    FocusNode? focusNode,
    List<SheetMediaItem>? mediaAttachments,
    this.hasTrailingSoftNewline = false,
  })  : focusNode = focusNode ?? FocusNode(),
        mediaAttachments = mediaAttachments != null
            ? List<SheetMediaItem>.from(mediaAttachments)
            : <SheetMediaItem>[];

  /// Whether this sheet has at least one paired photo or video keepsake.
  bool get hasMediaAttachments => mediaAttachments.isNotEmpty;

  /// Most items a sheet's Mount Strip (and a Folio leaf or PDF page) shows.
  static const int kMountCapacity = 3;

  /// Whether this sheet has reached the maximum allowed attachment capacity.
  bool get isAtMediaCapacity => mediaAttachments.length >= kMountCapacity;

  /// Maximum integer visual row capacity on this stationery sheet.
  int get rowCapacity;

  /// The active Quill document for this sheet.
  Document get document => controller.document;

  /// The active Delta for this sheet.
  Delta get delta => document.toDelta();

  /// Plain text content of this sheet.
  String get plainText => document.toPlainText();

  /// Whether the sheet contains zero user content (only the mandatory document terminal newline).
  bool get isEmpty => document.length <= 1;

  /// Replaces this sheet's controller document in place with [newDelta],
  /// keeping the [QuillController] instance alive so bound listeners and [QuillEditor] stay valid.
  void setDelta(Delta newDelta, {TextSelection? selection}) {
    final newDoc = Document.fromDelta(newDelta);
    final maxOffset = math.max(0, newDoc.length - 1);
    final rawBase = selection?.baseOffset ?? controller.selection.baseOffset;
    final clampedBase = rawBase.clamp(0, maxOffset);
    final clampedExtent = selection != null
        ? selection.extentOffset.clamp(0, maxOffset)
        : clampedBase;

    editWithoutKeyboard(() {
      controller.document = newDoc;
      controller.updateSelection(
        TextSelection(baseOffset: clampedBase, extentOffset: clampedExtent),
        ChangeSource.local,
      );
    });
  }

  /// Runs a programmatic change to this sheet's controller (re-laying sheets,
  /// restoring a selection) without Quill treating it as typing. While the
  /// keyboard is hidden Quill requests it on every controller change, and
  /// even focuses an unfocused editor to do so. [QuillController.replaceText]
  /// resets the flag after itself, so pass it `ignoreFocus: true` instead.
  void editWithoutKeyboard(VoidCallback edit) {
    final previous = controller.ignoreFocusOnTextChange;
    controller.ignoreFocusOnTextChange = true;
    try {
      edit();
    } finally {
      controller.ignoreFocusOnTextChange = previous;
    }
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
    super.mediaAttachments,
    super.hasTrailingSoftNewline = false,
  });

  /// Creates an empty opening sheet with a fresh basic QuillController.
  factory OpeningSheet.empty({
    int sheetIndex = 0,
    List<SheetMediaItem>? mediaAttachments,
  }) {
    return OpeningSheet(
      sheetIndex: sheetIndex,
      controller: MountMarkerClipboard.controller(),
      mediaAttachments: mediaAttachments,
    );
  }

  /// Creates an opening sheet populated with the specified Delta.
  factory OpeningSheet.fromDelta({
    required int sheetIndex,
    required Delta delta,
    List<SheetMediaItem>? mediaAttachments,
    bool hasTrailingSoftNewline = false,
  }) {
    final controller = MountMarkerClipboard.controller(document: Document.fromDelta(delta));
    return OpeningSheet(
      sheetIndex: sheetIndex,
      controller: controller,
      mediaAttachments: mediaAttachments,
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
      mediaAttachments: mediaAttachments,
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
    super.mediaAttachments,
    super.hasTrailingSoftNewline = false,
  });

  /// Creates an empty continuation sheet with a fresh basic QuillController.
  factory ContinuationSheet.empty({
    required int sheetIndex,
    List<SheetMediaItem>? mediaAttachments,
  }) {
    return ContinuationSheet(
      sheetIndex: sheetIndex,
      controller: MountMarkerClipboard.controller(),
      mediaAttachments: mediaAttachments,
    );
  }

  /// Creates a continuation sheet populated with the specified Delta.
  factory ContinuationSheet.fromDelta({
    required int sheetIndex,
    required Delta delta,
    List<SheetMediaItem>? mediaAttachments,
    bool hasTrailingSoftNewline = false,
  }) {
    final controller = MountMarkerClipboard.controller(document: Document.fromDelta(delta));
    return ContinuationSheet(
      sheetIndex: sheetIndex,
      controller: controller,
      mediaAttachments: mediaAttachments,
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
      mediaAttachments: mediaAttachments,
      hasTrailingSoftNewline: hasTrailingSoftNewline,
    );
  }
}

/// A dedicated full-page ephemera mount presenting an embedded photo or short video
/// paired with an editable caption and silk corner framing.
class EphemeraSheet extends StationerySheetDescriptor {
  /// Typed media kind (`image` or `video`).
  final EphemeraMediaType mediaType;

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
    required EphemeraMediaType mediaType,
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
