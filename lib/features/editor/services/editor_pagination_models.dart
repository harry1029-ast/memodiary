import 'package:flutter_quill/quill_delta.dart';
import '../domain/stationery_sheet_descriptor.dart';

/// Result emitted when content on a stationery sheet overflows and spills onto the next.
class AutoSpillResult {
  final int sourceSheetIndex;
  final int destinationSheetIndex;
  final int destinationCaretOffset;
  final bool didAllocateNewSheet;

  const AutoSpillResult({
    required this.sourceSheetIndex,
    required this.destinationSheetIndex,
    required this.destinationCaretOffset,
    required this.didAllocateNewSheet,
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
