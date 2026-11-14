import 'package:flutter/foundation.dart';
import 'entry_content_decoder.dart';
import 'media_embed_data.dart';
import 'vertical_typography_mapper.dart';

/// A [VerticalRenderToken] paired with cell-level metadata (`isTodo`,
/// `isChecked`, `colorHex`) for vertical adapters such as Thread-Bound Folio.
class VerticalStyledToken {
  final VerticalRenderToken token;
  final bool isTodo;
  final bool isChecked;
  final String? colorHex;

  const VerticalStyledToken({
    required this.token,
    this.isTodo = false,
    this.isChecked = false,
    this.colorHex,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerticalStyledToken &&
          runtimeType == other.runtimeType &&
          token == other.token &&
          isTodo == other.isTodo &&
          isChecked == other.isChecked &&
          colorHex == other.colorHex;

  @override
  int get hashCode => Object.hash(token, isTodo, isChecked, colorHex);

  @override
  String toString() =>
      'VerticalStyledToken(token: $token, todo: $isTodo, checked: $isChecked, color: $colorHex)';
}

/// Base class for items produced by [EntryVerticalPacker] in right-to-left
/// reading sequence.
sealed class VerticalColumnItem {
  const VerticalColumnItem();
}

/// A single vertical text column containing up to `maxTokensPerColumn` tokens
/// (or an unsplit entry title column when [isTitle] is true).
class VerticalTextColumn extends VerticalColumnItem {
  final List<VerticalStyledToken> styledTokens;
  final bool isTitle;
  final bool isHeader;
  final bool isQuote;

  const VerticalTextColumn({
    required this.styledTokens,
    this.isTitle = false,
    this.isHeader = false,
    this.isQuote = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerticalTextColumn &&
          runtimeType == other.runtimeType &&
          isTitle == other.isTitle &&
          isHeader == other.isHeader &&
          isQuote == other.isQuote &&
          listEquals(styledTokens, other.styledTokens);

  @override
  int get hashCode =>
      Object.hash(isTitle, isHeader, isQuote, Object.hashAll(styledTokens));

  @override
  String toString() =>
      'VerticalTextColumn(title: $isTitle, header: $isHeader, quote: $isQuote, styledTokens: $styledTokens)';
}

/// A tipped-in media item interrupting vertical text flow.
class VerticalMediaColumn extends VerticalColumnItem {
  final MediaEmbedData media;
  final bool isVideo;

  const VerticalMediaColumn({
    required this.media,
    required this.isVideo,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerticalMediaColumn &&
          runtimeType == other.runtimeType &&
          media == other.media &&
          isVideo == other.isVideo;

  @override
  int get hashCode => Object.hash(media, isVideo);

  @override
  String toString() => 'VerticalMediaColumn(isVideo: $isVideo, media: $media)';
}

/// Packs canonical [EntryContentBlock]s into vertical columns for Keepsake
/// Scroll View, Thread-Bound Folio, and vertical scroll PDF export.
class EntryVerticalPacker {
  const EntryVerticalPacker._();

  /// Packs [blocks] into vertical text and media columns constrained to
  /// [maxTokensPerColumn] cells per body column.
  ///
  /// Emits a single unsplit [VerticalTextColumn] with `isTitle: true` first
  /// when [entryTitle] is non-empty.
  static List<VerticalColumnItem> pack({
    required List<EntryContentBlock> blocks,
    required int maxTokensPerColumn,
    String? entryTitle,
  }) {
    if (maxTokensPerColumn <= 0) {
      throw ArgumentError.value(
        maxTokensPerColumn,
        'maxTokensPerColumn',
        'Must be positive',
      );
    }

    final columns = <VerticalColumnItem>[];

    final trimmedTitle = entryTitle?.trim() ?? '';
    if (trimmedTitle.isNotEmpty) {
      final titleTokens = VerticalTypographyMapper.tokenize(trimmedTitle);
      if (titleTokens.isNotEmpty) {
        columns.add(
          VerticalTextColumn(
            styledTokens: List<VerticalStyledToken>.unmodifiable(
              titleTokens.map((token) => VerticalStyledToken(token: token)),
            ),
            isTitle: true,
          ),
        );
      }
    }

    for (final block in blocks) {
      switch (block) {
        case EntryMediaBlock mediaBlock:
          columns.add(
            VerticalMediaColumn(
              media: mediaBlock.media,
              isVideo: mediaBlock.isVideo,
            ),
          );
        case EntryTextBlock textBlock:
          _packTextBlock(
            block: textBlock,
            maxTokensPerColumn: maxTokensPerColumn,
            outColumns: columns,
          );
      }
    }

    return columns;
  }

  static void _packTextBlock({
    required EntryTextBlock block,
    required int maxTokensPerColumn,
    required List<VerticalColumnItem> outColumns,
  }) {
    if (block.isBlank) return;

    final isHeader = block.kind == EntryBlockKind.header1 ||
        block.kind == EntryBlockKind.header2 ||
        block.kind == EntryBlockKind.header3;
    final isQuote = block.kind == EntryBlockKind.blockquote;
    final isTodo = block.kind == EntryBlockKind.checkedList ||
        block.kind == EntryBlockKind.uncheckedList;
    final isChecked = block.kind == EntryBlockKind.checkedList;

    final buffer = <VerticalStyledToken>[];

    void flushBuffer() {
      if (buffer.isEmpty) return;
      outColumns.add(
        VerticalTextColumn(
          styledTokens: List<VerticalStyledToken>.unmodifiable(buffer),
          isHeader: isHeader,
          isQuote: isQuote,
        ),
      );
      buffer.clear();
    }

    for (final run in block.runs) {
      final tokens = run.isInterlinearNote
          ? VerticalTypographyMapper.tokenizeInterlinear(run.text)
          : VerticalTypographyMapper.tokenize(run.text);

      for (final token in tokens) {
        if (token is VerticalGlyphToken) {
          if (token.glyph == '\r') continue;
          if (token.glyph == '\n') {
            flushBuffer();
            continue;
          }
        }

        buffer.add(
          VerticalStyledToken(
            token: token,
            isTodo: isTodo,
            isChecked: isChecked,
            colorHex: run.colorHex,
          ),
        );

        if (buffer.length >= maxTokensPerColumn) {
          flushBuffer();
        }
      }
    }

    flushBuffer();
  }
}
