import 'dart:math' as math;
import 'package:flutter_quill/quill_delta.dart';
import '../../templates/models/template_style.dart';
import '../models/mount_marker.dart';
import '../models/typography_settings.dart';
import 'stationery_line_measurer.dart';

/// Value object representing the outcome of a virtual Delta split.
class DeltaSplitResult {
  final Delta firstSlice;
  final Delta secondSlice;
  final bool hasTrailingSoftNewline;

  const DeltaSplitResult({
    required this.firstSlice,
    required this.secondSlice,
    required this.hasTrailingSoftNewline,
  });
}

/// Result of extracting overflowing trailing content from a stationery sheet.
class SheetOverflowResult {
  final Delta remainingDelta;
  final Delta overflowingDelta;
  final int splitOffset;
  final bool hasTrailingSoftNewline;

  const SheetOverflowResult({
    required this.remainingDelta,
    required this.overflowingDelta,
    required this.splitOffset,
    required this.hasTrailingSoftNewline,
  });
}

/// Pure service handling lossless splitting and bidirectional re-merging
/// of Quill Delta operations across Stationery Sheets without dropping attributes
/// or splitting UTF-16 surrogate pairs.
class StationeryDeltaSplitter {
  const StationeryDeltaSplitter._();

  /// Appends [source] operations onto [target], optionally stripping a single
  /// trailing artificial soft newline from [source]'s final string insert operation.
  static void appendDeltaStrippingSoftNewline({
    required Delta target,
    required Delta source,
    required bool stripTrailingSoftNewline,
  }) {
    if (!stripTrailingSoftNewline || source.isEmpty) {
      for (final operation in source.operations) {
        target.push(operation);
      }
      return;
    }

    for (int opIndex = 0; opIndex < source.operations.length; opIndex++) {
      final operation = source.operations[opIndex];
      final isLast = opIndex == source.operations.length - 1;

      if (isLast && operation.isInsert && operation.data is String) {
        final text = operation.data as String;
        if (text.endsWith('\n')) {
          final stripped = text.substring(0, text.length - 1);
          if (stripped.isNotEmpty) {
            target.push(Operation.insert(stripped, operation.attributes));
          }
        } else {
          target.push(operation);
        }
      } else {
        target.push(operation);
      }
    }
  }

  /// Maps a plain-text [textOffset] (which excludes mount markers) to the
  /// matching Delta offset, where each marker takes one position. Markers at
  /// or before the offset stay with the leading slice, so an item mounted at
  /// the end of a sheet's text stays on that sheet.
  static int deltaOffsetOfTextOffset(Delta delta, int textOffset) {
    var textCount = 0;
    var deltaCount = 0;
    for (final operation in delta.operations) {
      if (!operation.isInsert) continue;
      final data = operation.data;
      if (data is String) {
        final remaining = textOffset - textCount;
        if (remaining < data.length) return deltaCount + remaining;
        textCount += data.length;
        deltaCount += data.length;
      } else {
        deltaCount += 1;
      }
    }
    return deltaCount;
  }

  /// Splits [sourceDelta] at character [splitOffset].
  ///
  /// If the split occurs mid-paragraph, an artificial soft newline is appended
  /// to [firstSlice] to satisfy Quill's trailing-newline invariant, and
  /// [hasTrailingSoftNewline] is set to true.
  static DeltaSplitResult splitDeltaAtCharacterOffset({
    required Delta sourceDelta,
    required int splitOffset,
    Map<String, dynamic>? trailingParagraphAttributes,
  }) {
    final firstSlice = Delta();
    final secondSlice = Delta();
    int currentOffset = 0;

    for (final operation in sourceDelta.operations) {
      if (!operation.isInsert) continue;

      if (operation.data is Map) {
        if (currentOffset + 1 <= splitOffset) {
          firstSlice.push(operation);
        } else {
          secondSlice.push(operation);
        }
        currentOffset += 1;
        continue;
      }

      if (operation.data is String) {
        final text = operation.data as String;
        final opLength = text.length;

        if (currentOffset + opLength <= splitOffset) {
          firstSlice.push(operation);
          currentOffset += opLength;
        } else if (currentOffset < splitOffset &&
            currentOffset + opLength > splitOffset) {
          final cutPoint = splitOffset - currentOffset;
          var safeCutPoint = StationeryLineMeasurer.snapToSafeCodePointBoundary(
            text,
            cutPoint,
          );
          if (cutPoint > 0 && safeCutPoint == 0 && text.isNotEmpty) {
            safeCutPoint = math.min(text.length, cutPoint + 1);
          }

          final part1 = text.substring(0, safeCutPoint);
          final part2 = text.substring(safeCutPoint);

          if (part1.isNotEmpty) {
            firstSlice.push(Operation.insert(part1, operation.attributes));
          }
          if (part2.isNotEmpty) {
            secondSlice.push(Operation.insert(part2, operation.attributes));
          }
          currentOffset += opLength;
        } else {
          secondSlice.push(operation);
          currentOffset += opLength;
        }
      }
    }

    final hasTrailingSoftNewline = _ensureTrailingNewline(
      firstSlice,
      trailingParagraphAttributes,
    );
    _ensureTrailingNewline(secondSlice);

    return DeltaSplitResult(
      firstSlice: firstSlice,
      secondSlice: secondSlice,
      hasTrailingSoftNewline: hasTrailingSoftNewline,
    );
  }

  /// Merges [firstSlice] and [secondSlice] back into a single continuous Delta.
  static Delta mergeDeltaSlices({
    required Delta firstSlice,
    required Delta secondSlice,
    bool firstSliceHasSoftNewline = false,
  }) {
    final combined = Delta();
    appendDeltaStrippingSoftNewline(
      target: combined,
      source: firstSlice,
      stripTrailingSoftNewline: firstSliceHasSoftNewline,
    );
    _pushAll(combined, secondSlice.operations);
    return combined;
  }

  /// Extracts overflowing content from [sheetDelta] when it exceeds [rowCapacity].
  static SheetOverflowResult extractOverflow({
    required Delta sheetDelta,
    required int rowCapacity,
    required TypographySettings typography,
    double? contentWidth,
    TemplateBackgroundType backgroundType = TemplateBackgroundType.lined,
    double? lineStridePx,
  }) {
    final paragraphs = StationeryLineMeasurer.extractParagraphsFromDelta(
      sheetDelta,
    );
    int remainingRows = rowCapacity;
    int cumulativeDocumentOffset = 0;

    final headDelta = Delta();
    final tailDelta = Delta();
    bool isOverflowing = false;
    int splitOffset = 0;
    bool hasTrailingSoftNewline = false;

    for (final paragraph in paragraphs) {
      if (isOverflowing) {
        _pushAll(tailDelta, paragraph.operations);
        continue;
      }

      final measured = StationeryLineMeasurer.measureParagraph(
        text: paragraph.plainText,
        blockAttributes: paragraph.blockAttributes,
        inlineOperations: paragraph.operations,
        typography: typography,
        contentWidth: contentWidth,
        backgroundType: backgroundType,
        lineStridePx: lineStridePx,
      );
      final paragraphDocLength = paragraph.operations.fold<int>(
        0,
        (sum, operation) => sum + (operation.length ?? 0),
      );

      if (measured.totalRows <= remainingRows) {
        _pushAll(headDelta, paragraph.operations);
        remainingRows -= measured.totalRows;
        // Document offsets, where each mount marker takes one position.
        cumulativeDocumentOffset += paragraphDocLength;
      } else {
        final rawLinesThatFit = math.max(0, remainingRows ~/ measured.rowWeight);
        final linesThatFit =
            (rawLinesThatFit == 0 && headDelta.isEmpty) ? 1 : rawLinesThatFit;

        if (linesThatFit == 0) {
          isOverflowing = true;
          splitOffset = cumulativeDocumentOffset;
          hasTrailingSoftNewline = false;
          _pushAll(tailDelta, paragraph.operations);
        } else {
          final lineBreakIndex = math.min(
            linesThatFit - 1,
            measured.lineBreakOffsets.length - 1,
          );
          var paragraphCutOffset = measured.lineBreakOffsets[lineBreakIndex];
          final textBodyLength = paragraph.plainText.endsWith('\n')
              ? paragraph.plainText.length - 1
              : paragraph.plainText.length;
          if (paragraphCutOffset <= 0 && textBodyLength > 0) {
            paragraphCutOffset = 1;
          }

          if (paragraphCutOffset >= textBodyLength) {
            _pushAll(headDelta, paragraph.operations);
            remainingRows -= measured.totalRows;
            cumulativeDocumentOffset += paragraphDocLength;
            continue;
          }

          final paragraphDeltaCut = deltaOffsetOfTextOffset(
            paragraph.delta,
            paragraphCutOffset,
          );
          final split = splitDeltaAtCharacterOffset(
            sourceDelta: paragraph.delta,
            splitOffset: paragraphDeltaCut,
            trailingParagraphAttributes: paragraph.blockAttributes,
          );

          final nextPlainText = _extractPlainText(split.secondSlice);
          final nextBodyLength = nextPlainText.endsWith('\n')
              ? nextPlainText.length - 1
              : nextPlainText.length;

          // Strict forward-progress guard: never allow non-shrinking remainder
          if (nextBodyLength == 0 || nextBodyLength >= textBodyLength) {
            _pushAll(headDelta, paragraph.operations);
            remainingRows -= measured.totalRows;
            cumulativeDocumentOffset += paragraphDocLength;
            continue;
          }

          isOverflowing = true;
          splitOffset = cumulativeDocumentOffset + paragraphDeltaCut;
          _pushAll(headDelta, split.firstSlice.operations);
          _pushAll(tailDelta, split.secondSlice.operations);
          hasTrailingSoftNewline = split.hasTrailingSoftNewline;
        }
      }
    }

    if (!isOverflowing) {
      _ensureTrailingNewline(headDelta);
      return SheetOverflowResult(
        remainingDelta: headDelta,
        overflowingDelta: Delta(),
        splitOffset: cumulativeDocumentOffset,
        hasTrailingSoftNewline: false,
      );
    }

    _retainEmptyRowMountMarkers(headDelta: headDelta, tailDelta: tailDelta);
    if (_ensureTrailingNewline(headDelta) && headDelta.operations.length > 1) {
      hasTrailingSoftNewline = true;
    }
    _ensureTrailingNewline(tailDelta);

    return SheetOverflowResult(
      remainingDelta: headDelta,
      overflowingDelta: tailDelta,
      splitOffset: splitOffset,
      hasTrailingSoftNewline: hasTrailingSoftNewline,
    );
  }

  /// Ensures mount markers pushed into [tailDelta] solely by empty newlines
  /// without preceding spilled text are retained in [headDelta] on the source sheet.
  static void _retainEmptyRowMountMarkers({
    required Delta headDelta,
    required Delta tailDelta,
  }) {
    if (MountMarker.mediaIdsIn(tailDelta).isEmpty) return;

    final markersToRetain = <String>[];
    final cleanTail = Delta();
    bool hasSeenSpilledText = false;

    for (final op in tailDelta.operations) {
      if (!op.isInsert) {
        cleanTail.push(op);
        continue;
      }

      final mediaId = MountMarker.mediaIdOf(op);
      if (mediaId != null) {
        if (!hasSeenSpilledText) {
          // No non-whitespace text preceded this marker in the overflow;
          // it was pushed over solely by empty lines. Retain on source sheet.
          markersToRetain.add(mediaId);
        } else {
          // Marker follows actual text that spilled into the overflow.
          cleanTail.push(op);
        }
        continue;
      }

      if (op.data is String) {
        final text = op.data as String;
        if (text.trim().isNotEmpty) {
          hasSeenSpilledText = true;
        }
      } else {
        // Content embed (image, video) counts as content
        hasSeenSpilledText = true;
      }
      cleanTail.push(op);
    }

    if (markersToRetain.isEmpty) return;

    final insertOffset = MountMarker.endOfTextOffset(headDelta);
    final insertDelta = Delta()..retain(insertOffset);
    for (final id in markersToRetain) {
      insertDelta.insert(MountMarker.embeddable(id).toJson());
    }
    final composedHead = headDelta.compose(insertDelta);

    headDelta.operations
      ..clear()
      ..addAll(composedHead.operations);

    tailDelta.operations
      ..clear()
      ..addAll(cleanTail.operations);
  }

  static void _pushAll(Delta target, Iterable<Operation> operations) {
    for (final operation in operations) {
      target.push(operation);
    }
  }

  static bool _ensureTrailingNewline(
    Delta delta, [
    Map<String, dynamic>? attributes,
  ]) {
    if (delta.isNotEmpty) {
      final lastOp = delta.operations.last;
      if (lastOp.data is String && (lastOp.data as String).endsWith('\n')) {
        return false;
      }
    }
    delta.push(Operation.insert('\n', attributes));
    return true;
  }

  static String _extractPlainText(Delta delta) {
    final buffer = StringBuffer();
    for (final operation in delta.operations) {
      if (operation.isInsert && operation.data is String) {
        buffer.write(operation.data as String);
      }
    }
    return buffer.toString();
  }
}
