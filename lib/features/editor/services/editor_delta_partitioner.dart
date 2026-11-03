import 'dart:math' as math;
import 'package:flutter_quill/quill_delta.dart';
import '../../../../core/database/app_database.dart';
import '../../templates/models/template_style.dart';
import '../domain/stationery_sheet_descriptor.dart';
import '../models/media_embed_data.dart';
import '../models/typography_settings.dart';
import 'editor_pagination_models.dart';
import 'stationery_delta_splitter.dart';
import 'stationery_line_measurer.dart';

/// Pure algorithmic partitioner segmenting a continuous Quill Delta
/// into discrete [StationerySheetDescriptor] instances.
class EditorDeltaPartitioner {
  const EditorDeltaPartitioner._();

  /// Partitions [unifiedDelta] and [attachments] into a sequence of stationery sheets.
  static List<StationerySheetDescriptor> partition({
    required Delta unifiedDelta,
    List<MediaAttachment> attachments = const [],
    required TypographySettings typography,
    double? contentWidth,
    required TemplateStyle templateStyle,
    double? lineStridePx,
  }) {
    final sheets = <StationerySheetDescriptor>[];
    final blocks = extractContentBlocks(unifiedDelta);

    if (blocks.isEmpty) {
      sheets.add(OpeningSheet.empty(sheetIndex: 0));
      return sheets;
    }

    Delta currentTextDelta = Delta();
    int currentBudget = kOpeningSheetRowCapacity;
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
      currentBudget = kContinuationSheetRowCapacity;
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
          final measured = StationeryLineMeasurer.measureParagraph(
            text: block.plainText,
            blockAttributes: block.blockAttributes,
            inlineOperations: remainingParagraphDelta.operations,
            typography: typography,
            contentWidth: contentWidth,
            backgroundType: templateStyle.type,
            lineStridePx: lineStridePx,
          );

          final availableRows = currentBudget - currentUsedRows;
          if (measured.totalRows <= availableRows) {
            for (final op in remainingParagraphDelta.operations) {
              currentTextDelta.push(op);
            }
            currentUsedRows += measured.totalRows;
            currentSoftNewline = false;
            break;
          }

          // Overflows sheet capacity
          final linesThatFit = math.max(0, availableRows ~/ measured.rowWeight);
          if (linesThatFit > 0) {
            final lineBreakIndex = math.min(
              linesThatFit - 1,
              measured.lineBreakOffsets.length - 1,
            );
            final cutOffset = measured.lineBreakOffsets[lineBreakIndex];
            final split = StationeryDeltaSplitter.splitDeltaAtCharacterOffset(
              sourceDelta: remainingParagraphDelta,
              splitOffset: cutOffset,
              trailingParagraphAttributes: block.blockAttributes,
            );

            for (final op in split.firstSlice.operations) {
              currentTextDelta.push(op);
            }
            currentSoftNewline = split.hasTrailingSoftNewline;
            flushTextSheet();
            remainingParagraphDelta = split.secondSlice;
          } else {
            flushTextSheet();
          }
        }
      }
    }

    if (currentTextDelta.isNotEmpty || sheets.isEmpty) {
      flushTextSheet();
    }

    // Attach any missing external media attachments
    final existingPaths = sheets
        .whereType<EphemeraSheet>()
        .map((ephemera) => ephemera.sandboxedRelativePath)
        .toSet();

    for (final attachment in attachments) {
      if (!existingPaths.contains(attachment.relativePath)) {
        sheets.add(EphemeraSheet(
          sheetIndex: sheets.length,
          mediaType: attachment.mediaType,
          mediaData: MediaEmbedData(
            path: attachment.relativePath,
            caption: attachment.ocrText ?? '',
          ),
        ));
      }
    }

    for (int index = 0; index < sheets.length; index++) {
      sheets[index] = sheets[index].copyWithIndex(index);
    }

    return sheets;
  }

  /// Extracts structured text and ephemera blocks from continuous Delta.
  static List<EditorContentBlock> extractContentBlocks(Delta delta) {
    final blocks = <EditorContentBlock>[];
    var currentOps = <Operation>[];
    final textBuffer = StringBuffer();
    bool skipNextNewline = false;

    for (final op in delta.operations) {
      if (!op.isInsert) continue;

      if (op.data is Map) {
        final map = op.data as Map;
        if (map.containsKey('image')) {
          if (currentOps.isNotEmpty) {
            blocks.add(EditorTextBlock(
              delta: Delta.fromOperations(currentOps),
              plainText: textBuffer.toString(),
            ));
            currentOps = <Operation>[];
            textBuffer.clear();
          }
          blocks.add(EditorEphemeraBlock(
            mediaType: 'image',
            rawData: map['image'],
          ));
          skipNextNewline = true;
          continue;
        } else if (map.containsKey('video')) {
          if (currentOps.isNotEmpty) {
            blocks.add(EditorTextBlock(
              delta: Delta.fromOperations(currentOps),
              plainText: textBuffer.toString(),
            ));
            currentOps = <Operation>[];
            textBuffer.clear();
          }
          blocks.add(EditorEphemeraBlock(
            mediaType: 'video',
            rawData: map['video'],
          ));
          skipNextNewline = true;
          continue;
        }
      }

      if (op.data is String) {
        var text = op.data as String;
        if (skipNextNewline && text.startsWith('\n')) {
          text = text.substring(1);
          skipNextNewline = false;
          if (text.isEmpty) {
            continue;
          }
        }
        skipNextNewline = false;

        if (!text.contains('\n')) {
          currentOps.add(Operation.insert(text, op.attributes));
          textBuffer.write(text);
        } else {
          final lines = text.split('\n');
          for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
            final part = lines[lineIndex];
            if (part.isNotEmpty) {
              currentOps.add(Operation.insert(part, op.attributes));
              textBuffer.write(part);
            }
            if (lineIndex < lines.length - 1) {
              textBuffer.write('\n');
              currentOps.add(Operation.insert('\n', op.attributes));
              blocks.add(EditorTextBlock(
                delta: Delta.fromOperations(currentOps),
                plainText: textBuffer.toString(),
                blockAttributes: op.attributes,
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
