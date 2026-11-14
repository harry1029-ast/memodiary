import '../../../../core/documents/entry_content_decoder.dart';
import '../../../../core/documents/entry_vertical_packer.dart';
import '../../../../core/documents/vertical_typography_mapper.dart';
import '../../../templates/models/template_style.dart';
import 'folio_leaf_model.dart';
import 'folio_reading_perspective.dart';

/// Helper for packing canonical [EntryContentBlock]s into right-to-left
/// vertical folio leaves via [EntryVerticalPacker].
class FolioVerticalPaginator {
  const FolioVerticalPaginator._();

  static const int kVerticalColumnsPerLeaf = 10;
  static const int kVerticalRowsPerColumn = 16;

  /// Paginates [blocks] into vertical content body and ephemera leaves.
  static void paginateVerticalLeaves({
    required List<EntryContentBlock> blocks,
    required FolioRulingLayout layout,
    required String title,
    required String lunarDate,
    required List<FolioLeaf> outLeaves,
  }) {
    final packedColumns = EntryVerticalPacker.pack(
      blocks: blocks,
      maxTokensPerColumn: kVerticalRowsPerColumn,
    );

    var currentColumns = <FolioVerticalColumn>[];

    void flushLeaf() {
      if (currentColumns.isEmpty) return;
      outLeaves.add(
        FolioContentBodyLeaf(
          leafIndex: 0,
          totalLeaves: 0,
          pageIndexInContent: 0,
          totalContentPages: 0,
          layout: layout,
          verticalColumns: List.of(currentColumns),
          title: title,
          lunarDate: lunarDate,
        ),
      );
      currentColumns = <FolioVerticalColumn>[];
    }

    for (final columnItem in packedColumns) {
      switch (columnItem) {
        case VerticalMediaColumn mediaColumn:
          flushLeaf();
          final caption = mediaColumn.media.caption.trim();
          outLeaves.add(
            FolioTippedInEphemeraLeaf(
              leafIndex: 0,
              totalLeaves: 0,
              mediaType: mediaColumn.isVideo ? 'video' : 'image',
              sandboxedRelativePath: mediaColumn.media.path,
              caption: caption.isNotEmpty ? caption : null,
              aspectRatio: mediaColumn.media.explicitAspectRatio ?? 1.0,
              title: title,
              lunarDate: lunarDate,
            ),
          );
        case VerticalTextColumn textColumn:
          currentColumns.add(
            FolioVerticalColumn(
              cells: textColumn.styledTokens
                  .map(_toFolioVerticalCell)
                  .toList(growable: false),
            ),
          );
          if (currentColumns.length >= kVerticalColumnsPerLeaf) {
            flushLeaf();
          }
      }
    }

    flushLeaf();
  }

  static FolioVerticalCell _toFolioVerticalCell(VerticalStyledToken styled) {
    final cellColor = TemplateStyle.tryParseHexColor(styled.colorHex);
    final token = styled.token;
    return switch (token) {
      VerticalInterlinearPairToken pair => FolioVerticalCell(
          mainChar: pair.rightChar,
          secondChar: pair.leftChar,
          isJiazhuPair: true,
          color: cellColor,
        ),
      VerticalGlyphToken glyphToken => FolioVerticalCell(
          mainChar: glyphToken.glyph,
          isTodo: styled.isTodo,
          isChecked: styled.isChecked,
          isCornerPunctuation: glyphToken.isCornerPunctuation,
          requiresQuarterTurnRotation: glyphToken.requiresQuarterTurnRotation,
          color: cellColor,
        ),
    };
  }
}
