import 'folio_content_parser.dart';
import 'folio_leaf_model.dart';
import 'folio_reading_perspective.dart';
import '../../../editor/services/vertical_typography_mapper.dart';

/// Helper for packing content blocks into right-to-left vertical folio leaves.
class FolioVerticalPaginator {
  const FolioVerticalPaginator._();

  static const int kVerticalColumnsPerLeaf = 10;
  static const int kVerticalRowsPerColumn = 16;

  /// Paginates [blocks] into vertical content body and ephemera leaves.
  static void paginateVerticalLeaves({
    required List<FolioContentBlock> blocks,
    required FolioRulingLayout layout,
    required String title,
    required String lunarDate,
    required List<FolioLeaf> outLeaves,
  }) {
    var currentColumns = <FolioVerticalColumn>[];
    var currentColumnCells = <FolioVerticalCell>[];

    void flushColumn() {
      if (currentColumnCells.isNotEmpty) {
        currentColumns.add(FolioVerticalColumn(cells: List.of(currentColumnCells)));
        currentColumnCells = <FolioVerticalCell>[];
      }
    }

    void flushLeaf() {
      flushColumn();
      if (currentColumns.isNotEmpty) {
        outLeaves.add(FolioContentBodyLeaf(
          leafIndex: 0,
          totalLeaves: 0,
          pageIndexInContent: 0,
          totalContentPages: 0,
          layout: layout,
          verticalColumns: List.of(currentColumns),
          title: title,
          lunarDate: lunarDate,
        ));
        currentColumns = <FolioVerticalColumn>[];
      }
    }

    for (final block in blocks) {
      if (block is FolioMediaBlock) {
        flushLeaf();
        outLeaves.add(FolioTippedInEphemeraLeaf(
          leafIndex: 0,
          totalLeaves: 0,
          mediaType: block.mediaType,
          sandboxedRelativePath: block.relativePath,
          caption: block.caption,
          title: title,
          lunarDate: lunarDate,
        ));
        continue;
      }

      if (block is FolioTextBlock) {
        if (currentColumnCells.isNotEmpty) {
          flushColumn();
          if (currentColumns.length >= kVerticalColumnsPerLeaf) flushLeaf();
        }

        for (final segment in block.segments) {
          if (segment.isJiazhuNote) {
            final chars = segment.text.trim().runes.map((rune) => String.fromCharCode(rune)).toList();
            for (int index = 0; index < chars.length; index += 2) {
              final c1 = chars[index];
              final c2 = (index + 1 < chars.length) ? chars[index + 1] : ' ';
              currentColumnCells.add(FolioVerticalCell(
                mainChar: c1,
                secondChar: c2,
                isJiazhuPair: true,
              ));
              if (currentColumnCells.length >= kVerticalRowsPerColumn) {
                flushColumn();
                if (currentColumns.length >= kVerticalColumnsPerLeaf) flushLeaf();
              }
            }
          } else {
            final tokens = VerticalTypographyMapper.tokenize(segment.text);
            for (final token in tokens) {
              if (token is VerticalInterlinearPairToken) {
                currentColumnCells.add(FolioVerticalCell(
                  mainChar: token.rightChar,
                  secondChar: token.leftChar,
                  isJiazhuPair: true,
                ));
              } else if (token is VerticalGlyphToken) {
                if (token.glyph == '\n') {
                  flushColumn();
                  if (currentColumns.length >= kVerticalColumnsPerLeaf) flushLeaf();
                  continue;
                }
                currentColumnCells.add(FolioVerticalCell(
                  mainChar: token.glyph,
                  isTodo: segment.isTodo,
                  isChecked: segment.isChecked,
                  isCornerPunctuation: token.isCornerPunctuation,
                  requiresQuarterTurnRotation: token.requiresQuarterTurnRotation,
                  color: segment.color,
                ));
              }

              if (currentColumnCells.length >= kVerticalRowsPerColumn) {
                flushColumn();
                if (currentColumns.length >= kVerticalColumnsPerLeaf) flushLeaf();
              }
            }
          }
        }
      }
    }

    flushLeaf();
  }
}

