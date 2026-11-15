import 'package:flutter/material.dart';
import '../../../../core/documents/entry_content_decoder.dart';
import '../../../templates/models/template_style.dart';
import 'folio_leaf_model.dart';
import 'folio_reading_perspective.dart';

/// Width-aware horizontal paginator for Thread-Bound Folio content leaves.
class FolioHorizontalPaginator {
  const FolioHorizontalPaginator._();

  static const int kMaxRowsPerLeaf = 14;

  /// Paginates rich [blocks] into horizontal [FolioContentBodyLeaf] and
  /// [FolioTippedInEphemeraLeaf] items constrained to [theme.horizontalUsableWidth].
  static void paginateHorizontalLeaves({
    required List<EntryContentBlock> blocks,
    required FolioRulingLayout layout,
    required FolioSubstrateTheme theme,
    required String title,
    required String lunarDate,
    required List<FolioLeaf> outLeaves,
  }) {
    var currentRows = <FolioHorizontalRow>[];
    final measurer = _HorizontalRowMeasurer(theme: theme);
    final maxRowWidth = theme.horizontalUsableWidth;

    void flushRows() {
      if (currentRows.isNotEmpty) {
        outLeaves.add(FolioContentBodyLeaf(
          leafIndex: 0,
          totalLeaves: 0,
          pageIndexInContent: 0,
          totalContentPages: 0,
          layout: layout,
          horizontalRows: List.of(currentRows),
          title: title,
          lunarDate: lunarDate,
        ));
        currentRows = <FolioHorizontalRow>[];
      }
    }

    for (final block in blocks) {
      switch (block) {
        case EntryMediaBlock mediaBlock:
          flushRows();
          outLeaves.add(
            FolioTippedInEphemeraLeaf.fromMediaEmbed(
              media: mediaBlock.media,
              isVideo: mediaBlock.isVideo,
              title: title,
              lunarDate: lunarDate,
            ),
          );
        case EntryTextBlock textBlock:
          final paragraphRows = _tokenizeParagraph(
            textBlock,
            maxRowWidth: maxRowWidth,
            measurer: measurer,
          );
          for (final row in paragraphRows) {
            currentRows.add(row);
            if (currentRows.length >= kMaxRowsPerLeaf) {
              flushRows();
            }
          }
      }
    }

    flushRows();
  }

  static List<FolioHorizontalRow> _tokenizeParagraph(
    EntryTextBlock block, {
    required double maxRowWidth,
    required _HorizontalRowMeasurer measurer,
  }) {
    if (block.runs.isEmpty) {
      return const [FolioHorizontalRow(segments: [])];
    }

    final isTodo = block.kind == EntryBlockKind.checkedList ||
        block.kind == EntryBlockKind.uncheckedList;
    final isChecked = block.kind == EntryBlockKind.checkedList;

    final rows = <FolioHorizontalRow>[];
    var currentRowSegments = <FolioHorizontalSegment>[];

    void flushCurrentRow() {
      if (currentRowSegments.isNotEmpty) {
        rows.add(FolioHorizontalRow(segments: List.of(currentRowSegments)));
        currentRowSegments = <FolioHorizontalSegment>[];
      }
    }

    for (final run in block.runs) {
      final color = TemplateStyle.tryParseHexColor(run.colorHex);
      if (run.isInterlinearNote) {
        final noteSegment = FolioHorizontalSegment(
          text: run.text,
          isJiazhuNote: true,
          color: color,
        );
        if (currentRowSegments.isNotEmpty &&
            measurer.measureRowWidth(
                  currentRowSegments,
                  pendingSegment: noteSegment,
                ) >
                maxRowWidth) {
          flushCurrentRow();
        }
        currentRowSegments.add(noteSegment);
      } else {
        final chars = run.text.runes
            .map((rune) => String.fromCharCode(rune))
            .toList(growable: false);
        final buffer = StringBuffer();

        void flushBuffer() {
          if (buffer.isEmpty) return;
          currentRowSegments.add(
            FolioHorizontalSegment(
              text: buffer.toString(),
              isTodo: isTodo,
              isChecked: isChecked,
              isBold: run.isBold,
              isItalic: run.isItalic,
              color: color,
            ),
          );
          buffer.clear();
        }

        for (final character in chars) {
          if (character == '\n') {
            flushBuffer();
            flushCurrentRow();
            continue;
          }

          final candidate = '${buffer.toString()}$character';
          final pendingSegment = FolioHorizontalSegment(
            text: candidate,
            isTodo: isTodo,
            isChecked: isChecked,
            isBold: run.isBold,
            isItalic: run.isItalic,
            color: color,
          );
          if ((currentRowSegments.isNotEmpty || buffer.isNotEmpty) &&
              measurer.measureRowWidth(
                    currentRowSegments,
                    pendingSegment: pendingSegment,
                  ) >
                  maxRowWidth) {
            flushBuffer();
            flushCurrentRow();
          }

          buffer.write(character);
        }

        flushBuffer();
      }
    }

    flushCurrentRow();
    return rows;
  }
}

class _HorizontalRowMeasurer {
  final FolioSubstrateTheme theme;

  const _HorizontalRowMeasurer({required this.theme});

  double measureRowWidth(
    List<FolioHorizontalSegment> segments, {
    FolioHorizontalSegment? pendingSegment,
  }) {
    final spans = <InlineSpan>[];
    final placeholders = <PlaceholderDimensions>[];

    void appendSegment(FolioHorizontalSegment segment) {
      if (segment.isJiazhuNote) {
        final notePainter = TextPainter(
          text: TextSpan(
            text: segment.text,
            style: theme.horizontalJiazhuTextStyle(),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        placeholders.add(
          PlaceholderDimensions(
            size: Size(notePainter.width + FolioSubstrateTheme.jiazhuNoteChromeWidth, 16.0),
            alignment: PlaceholderAlignment.middle,
          ),
        );
        spans.add(
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SizedBox.shrink(),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: segment.text,
            style: theme.horizontalTextStyle(
              isBold: segment.isBold,
              isItalic: segment.isItalic,
            ),
          ),
        );
      }
    }

    for (final segment in segments) {
      appendSegment(segment);
    }
    if (pendingSegment != null) {
      appendSegment(pendingSegment);
    }

    final rowPainter = TextPainter(
      text: TextSpan(children: spans),
      textDirection: TextDirection.ltr,
    );
    if (placeholders.isNotEmpty) {
      rowPainter.setPlaceholderDimensions(placeholders);
    }
    rowPainter.layout();
    return rowPainter.width;
  }
}
