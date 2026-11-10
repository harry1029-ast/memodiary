import 'dart:math' as math;
import 'package:flutter_quill/quill_delta.dart';
import '../../templates/models/template_style.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/mount_marker.dart';
import '../models/typography_settings.dart';
import 'editor_pagination_models.dart';
import 'sheet_mount_resolver.dart';
import 'stationery_delta_splitter.dart';
import 'stationery_delta_synthesizer.dart';
import 'stationery_line_measurer.dart';

export 'editor_pagination_models.dart' show EditorPartition, MountResolution;
export 'sheet_mount_resolver.dart' show SheetMountResolver;

/// Pure algorithmic partitioner segmenting a continuous Quill Delta
/// into discrete [StationerySheetDescriptor] instances.
class EditorDeltaPartitioner {
  const EditorDeltaPartitioner._();

  /// Partitions [unifiedDelta] into a sequence of stationery sheets, each
  /// holding the rows [rowCapacity] gives it, mounting each item of [media] on
  /// the sheet holding its mount marker and reporting the unreferenced items
  /// (in [media] order) as staged.
  static EditorPartition partition({
    required Delta unifiedDelta,
    List<SheetMediaItem> media = const [],
    required TypographySettings typography,
    double? contentWidth,
    required TemplateStyle templateStyle,
    double? lineStridePx,
    SheetRowCapacity rowCapacity = SheetRowCapacity.folioLeaf,
  }) {
    final sheets = <StationerySheetDescriptor>[];
    final blocks = extractContentBlocks(unifiedDelta);

    if (blocks.isEmpty) {
      return EditorPartition(
        sheets: [OpeningSheet.empty(sheetIndex: 0)],
        stagedItems: List.of(media),
      );
    }

    Delta currentTextDelta = Delta();
    int currentBudget = rowCapacity.openingRows;
    int currentUsedRows = 0;
    bool currentSoftNewline = false;

    void flushTextSheet() {
      if (sheets.isEmpty) {
        sheets.add(OpeningSheet.fromDelta(
          sheetIndex: 0,
          delta: currentTextDelta.isEmpty
              ? (Delta()..insert('\n'))
              : currentTextDelta,
          hasTrailingSoftNewline: currentSoftNewline,
        ));
      } else if (currentTextDelta.isNotEmpty) {
        sheets.add(ContinuationSheet.fromDelta(
          sheetIndex: sheets.length,
          delta: currentTextDelta,
          hasTrailingSoftNewline: currentSoftNewline,
        ));
      }
      currentTextDelta = Delta();
      currentBudget = rowCapacity.continuationRows;
      currentUsedRows = 0;
      currentSoftNewline = false;
    }

    for (final block in blocks) {
      if (block is EditorEphemeraBlock) {
        flushTextSheet();
        sheets.add(EphemeraSheet.fromEmbed(
          sheetIndex: sheets.length,
          mediaType: block.mediaType,
          rawData: block.rawData,
        ));
        continue;
      }

      if (block is EditorTextBlock) {
        var remainingParagraphDelta = block.delta;

        while (remainingParagraphDelta.isNotEmpty) {
          final remainingPlainText = _extractPlainText(remainingParagraphDelta);
          if (remainingPlainText.isEmpty) {
            break;
          }

          final measured = StationeryLineMeasurer.measureParagraph(
            text: remainingPlainText,
            blockAttributes: block.blockAttributes,
            inlineOperations: remainingParagraphDelta.operations,
            typography: typography,
            contentWidth: contentWidth,
            backgroundType: templateStyle.type,
            lineStridePx: lineStridePx,
          );

          final availableRows = currentBudget - currentUsedRows;
          if (measured.totalRows <= availableRows) {
            for (final operation in remainingParagraphDelta.operations) {
              currentTextDelta.push(operation);
            }
            currentUsedRows += measured.totalRows;
            currentSoftNewline = false;
            break;
          }

          final rawLinesThatFit = math.max(0, availableRows ~/ measured.rowWeight);
          if (rawLinesThatFit == 0 && (currentTextDelta.isNotEmpty || currentUsedRows > 0)) {
            flushTextSheet();
            continue;
          }

          final linesThatFit = math.max(1, rawLinesThatFit);
          final lineBreakIndex = math.min(
            linesThatFit - 1,
            measured.lineBreakOffsets.length - 1,
          );
          var cutOffset = measured.lineBreakOffsets[lineBreakIndex];
          final textBodyLength = remainingPlainText.endsWith('\n')
              ? remainingPlainText.length - 1
              : remainingPlainText.length;

          if (cutOffset <= 0 && textBodyLength > 0) {
            cutOffset = 1;
          }

          if (cutOffset >= textBodyLength) {
            for (final operation in remainingParagraphDelta.operations) {
              currentTextDelta.push(operation);
            }
            currentUsedRows += measured.totalRows;
            currentSoftNewline = false;
            if (currentUsedRows >= currentBudget) {
              flushTextSheet();
            }
            break;
          }

          final split = StationeryDeltaSplitter.splitDeltaAtCharacterOffset(
            sourceDelta: remainingParagraphDelta,
            splitOffset: StationeryDeltaSplitter.deltaOffsetOfTextOffset(
              remainingParagraphDelta,
              cutOffset,
            ),
            trailingParagraphAttributes: block.blockAttributes,
          );

          final nextPlainText = _extractPlainText(split.secondSlice);
          final nextBodyLength = nextPlainText.endsWith('\n')
              ? nextPlainText.length - 1
              : nextPlainText.length;

          // Strict forward-progress guard: never allow non-shrinking remainder
          if (nextBodyLength == 0 || nextBodyLength >= textBodyLength) {
            for (final operation in remainingParagraphDelta.operations) {
              currentTextDelta.push(operation);
            }
            currentSoftNewline = false;
            flushTextSheet();
            break;
          }

          for (final operation in split.firstSlice.operations) {
            currentTextDelta.push(operation);
          }
          currentSoftNewline = split.hasTrailingSoftNewline;
          flushTextSheet();
          remainingParagraphDelta = split.secondSlice;
        }
      }
    }

    if (currentTextDelta.isNotEmpty || sheets.isEmpty) {
      flushTextSheet();
    }

    // Opening never unmounts: overflow past the last sheet is tolerated there.
    final mounts = SheetMountResolver.resolveMounts(sheets: sheets, media: media);

    for (int index = 0; index < sheets.length; index++) {
      sheets[index] = sheets[index].copyWithIndex(index);
    }

    return EditorPartition(
      sheets: sheets,
      stagedItems: mounts.stagedItems,
      toleratedOverflowIds: mounts.toleratedOverflowIds,
      markerHomes: mounts.markerHomes,
    );
  }

  /// Legacy mounting pass for entries written before mount markers existed
  /// (ADR-0009): returns [unifiedDelta] with a marker written for every
  /// unanchored item of [media], placed with the pre-marker first-come rule
  /// (the first text sheet with fewer than three items, else the last text
  /// sheet) at the end of that sheet's text, in [media] order.
  ///
  /// Returns [unifiedDelta] unchanged when nothing is unanchored, so applying
  /// it twice is a no-op.
  static Delta mountLegacyAttachments({
    required Delta unifiedDelta,
    required List<SheetMediaItem> media,
    required TypographySettings typography,
    double? contentWidth,
    required TemplateStyle templateStyle,
    double? lineStridePx,
    SheetRowCapacity rowCapacity = SheetRowCapacity.folioLeaf,
  }) {
    final partitioned = partition(
      unifiedDelta: unifiedDelta,
      media: media,
      typography: typography,
      contentWidth: contentWidth,
      templateStyle: templateStyle,
      lineStridePx: lineStridePx,
      rowCapacity: rowCapacity,
    );
    try {
      final textSheets = partitioned.sheets.whereType<TextStationerySheet>().toList();
      if (partitioned.stagedItems.isEmpty || textSheets.isEmpty) return unifiedDelta;

      final assignedIds = <TextStationerySheet, List<String>>{};
      for (final item in partitioned.stagedItems) {
        final target = textSheets.firstWhere(
          (sheet) => !sheet.isAtMediaCapacity,
          orElse: () => textSheets.last,
        );
        target.mediaAttachments.add(item);
        (assignedIds[target] ??= <String>[]).add(item.id);
      }

      for (final MapEntry(key: sheet, value: mediaIds) in assignedIds.entries) {
        final endOfText = math.max(0, sheet.document.length - 1);
        final markers = Delta()..retain(endOfText);
        for (final mediaId in mediaIds) {
          markers.insert(MountMarker.embeddable(mediaId).toJson());
        }
        sheet.setDelta(sheet.delta.compose(markers));
      }
      return StationeryDeltaSynthesizer.synthesize(partitioned.sheets);
    } finally {
      for (final sheet in partitioned.sheets) {
        sheet.dispose();
      }
    }
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

  /// Extracts structured text and ephemera blocks from continuous Delta.
  static List<EditorContentBlock> extractContentBlocks(Delta delta) {
    final blocks = <EditorContentBlock>[];
    var currentOps = <Operation>[];
    final textBuffer = StringBuffer();
    bool skipNextNewline = false;

    for (final operation in delta.operations) {
      if (!operation.isInsert) continue;

      if (MountMarker.mediaIdOf(operation) != null) {
        // Zero-height marker: travels with its line but adds no text or rows.
        currentOps.add(operation);
        continue;
      }

      if (operation.data is Map) {
        final map = operation.data as Map;
        if (map.containsKey('image') || map.containsKey('video')) {
          if (currentOps.isNotEmpty) {
            blocks.add(EditorTextBlock(
              delta: Delta.fromOperations(currentOps),
              plainText: textBuffer.toString(),
            ));
            currentOps = <Operation>[];
            textBuffer.clear();
          }
          final isVideo = map.containsKey('video');
          blocks.add(EditorEphemeraBlock(
            mediaType: isVideo ? EphemeraMediaType.video : EphemeraMediaType.image,
            rawData: isVideo ? map['video'] : map['image'],
          ));
          skipNextNewline = true;
          continue;
        }
      }

      if (operation.data is String) {
        var text = operation.data as String;
        if (skipNextNewline && text.startsWith('\n')) {
          text = text.substring(1);
          skipNextNewline = false;
          if (text.isEmpty) {
            continue;
          }
        }
        skipNextNewline = false;

        if (!text.contains('\n')) {
          currentOps.add(Operation.insert(text, operation.attributes));
          textBuffer.write(text);
        } else {
          final lines = text.split('\n');
          for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
            final part = lines[lineIndex];
            if (part.isNotEmpty) {
              currentOps.add(Operation.insert(part, operation.attributes));
              textBuffer.write(part);
            }
            if (lineIndex < lines.length - 1) {
              textBuffer.write('\n');
              currentOps.add(Operation.insert('\n', operation.attributes));
              blocks.add(EditorTextBlock(
                delta: Delta.fromOperations(currentOps),
                plainText: textBuffer.toString(),
                blockAttributes: operation.attributes,
              ));
              currentOps = <Operation>[];
              textBuffer.clear();
            }
          }
        }
      }
    }

    if (currentOps.isNotEmpty || textBuffer.isNotEmpty) {
      blocks.add(EditorTextBlock(
        delta: Delta.fromOperations(currentOps),
        plainText: textBuffer.toString(),
      ));
    }

    return blocks;
  }
}
