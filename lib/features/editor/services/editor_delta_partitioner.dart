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
      final emptySheet = OpeningSheet.empty(sheetIndex: 0);
      for (final attachment in attachments) {
        if (!emptySheet.isAtMediaCapacity) {
          emptySheet.mediaAttachments.add(SheetMediaItem.fromMediaAttachment(attachment));
        }
      }
      sheets.add(emptySheet);
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
            splitOffset: cutOffset,
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

    final existingEphemeraPaths = sheets
        .whereType<EphemeraSheet>()
        .map((ephemera) => ephemera.sandboxedRelativePath)
        .toSet();

    final textSheets = sheets.whereType<TextStationerySheet>().toList();
    if (textSheets.isNotEmpty) {
      for (final attachment in attachments) {
        if (existingEphemeraPaths.contains(attachment.relativePath)) continue;
        final item = SheetMediaItem.fromMediaAttachment(attachment);
        final targetSheet = textSheets.firstWhere(
          (sheet) => !sheet.isAtMediaCapacity,
          orElse: () => textSheets.last,
        );
        if (!targetSheet.mediaAttachments.any((candidate) => candidate.id == item.id || candidate.relativePath == item.relativePath)) {
          targetSheet.mediaAttachments.add(item);
        }
      }
    } else {
      for (final attachment in attachments) {
        if (!existingEphemeraPaths.contains(attachment.relativePath)) {
          sheets.add(EphemeraSheet(
            sheetIndex: sheets.length,
            mediaType: EphemeraMediaType.fromEmbedKey(attachment.mediaType),
            mediaData: MediaEmbedData(
              path: attachment.relativePath,
              caption: attachment.caption ?? '',
            ),
          ));
        }
      }
    }

    for (int index = 0; index < sheets.length; index++) {
      sheets[index] = sheets[index].copyWithIndex(index);
    }

    return sheets;
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
