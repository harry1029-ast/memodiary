import 'package:flutter_quill/flutter_quill.dart' show QuillController;
import 'package:flutter_quill/quill_delta.dart';
import '../domain/stationery_sheet_descriptor.dart';

/// Result emitted when content on a stationery sheet overflows and spills onto the next.
class AutoSpillResult {
  final int sourceSheetIndex;
  final int destinationSheetIndex;
  final int destinationCaretOffset;
  final bool didAllocateNewSheet;

  /// Whether the caret was inside the overflow and moved with it to
  /// [destinationSheetIndex]. When false (e.g. Enter mid-sheet pushed only
  /// trailing blank rows over) the caret stays on [sourceSheetIndex] and the
  /// page must not turn.
  final bool caretFollowsOverflow;

  const AutoSpillResult({
    required this.sourceSheetIndex,
    required this.destinationSheetIndex,
    required this.destinationCaretOffset,
    required this.didAllocateNewSheet,
    required this.caretFollowsOverflow,
  });
}

/// Result emitted when backspacing at offset 0 of a continuation sheet triggers backward merge.
class SpillBackResult {
  final int sourceSheetIndex;
  final int destinationSheetIndex;
  final int destinationCaretOffset;
  final bool didCollapse;

  const SpillBackResult({
    required this.sourceSheetIndex,
    required this.destinationSheetIndex,
    required this.destinationCaretOffset,
    required this.didCollapse,
  });
}

/// Structured block extracted from continuous Delta during sheet partitioning.
sealed class EditorContentBlock {}

class EditorTextBlock extends EditorContentBlock {
  final Delta delta;
  final String plainText;
  final Map<String, dynamic>? blockAttributes;

  EditorTextBlock({
    required this.delta,
    required this.plainText,
    this.blockAttributes,
  });
}

class EditorEphemeraBlock extends EditorContentBlock {
  final EphemeraMediaType mediaType;
  final dynamic rawData;

  EditorEphemeraBlock({
    required this.mediaType,
    required this.rawData,
  });
}

/// Outcome of partitioning an entry: its Stationery Sheets (with mounted items
/// resolved from mount markers) and the attachments waiting in the Staging
/// Handscroll because no marker references them.
class EditorPartition {
  final List<StationerySheetDescriptor> sheets;
  final List<SheetMediaItem> stagedItems;

  /// Items shown beyond the three-item cap on the last text sheet because
  /// opening an entry never unmounts (see [MountResolution.toleratedOverflowIds]).
  final Set<String> toleratedOverflowIds;

  /// The sheet controller whose Delta anchors each mounted item.
  final Map<String, QuillController> markerHomes;

  const EditorPartition({
    required this.sheets,
    required this.stagedItems,
    this.toleratedOverflowIds = const {},
    this.markerHomes = const {},
  });
}

/// Outcome of resolving mount markers to the Stationery Sheets that show them.
class MountResolution {
  /// Items no marker references, in the order of the media they were resolved from.
  final List<SheetMediaItem> stagedItems;

  /// Items whose markers overflowed the last text sheet during reflow and were
  /// removed, returning the items to the Staging Handscroll.
  final List<SheetMediaItem> unmountedByOverflow;

  /// Items shown beyond the cap on the last text sheet without being unmounted:
  /// overflow present when the entry was opened (e.g. legacy entries mounted
  /// first-come with extras on the last sheet). An id loses the exemption once
  /// it fits within the cap again.
  final Set<String> toleratedOverflowIds;

  /// The sheet controller whose Delta anchors each mounted item, used to tell
  /// the original marker from a pasted duplicate on the next resolution.
  final Map<String, QuillController> markerHomes;

  const MountResolution({
    required this.stagedItems,
    required this.unmountedByOverflow,
    required this.toleratedOverflowIds,
    required this.markerHomes,
  });
}
