import 'package:flutter/material.dart';
import 'folio_leaf_model.dart';
import 'folio_reading_perspective.dart';

/// Renders the locked integer calligraphy grid (14-row horizontal or 10-column vertical)
/// for [FolioContentBodyLeaf] on the scholar's paper substrate.
class FolioBodyCalligraphyView extends StatelessWidget {
  final FolioContentBodyLeaf bodyLeaf;
  final FolioSubstrateTheme theme;

  const FolioBodyCalligraphyView({
    super.key,
    required this.bodyLeaf,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return bodyLeaf.layout == FolioRulingLayout.faithfulHorizontal
        ? _buildHorizontalBody()
        : _buildVerticalBody();
  }

  Widget _buildHorizontalBody() {
    final rows = bodyLeaf.horizontalRows ?? const [];
    final jiazhuColor = theme.isDark ? const Color(0xFFD4AF37) : const Color(0xFFB83B2E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(14, (rowIndex) {
        final row = rowIndex < rows.length ? rows[rowIndex] : null;
        return SizedBox(
          height: 32.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: row == null || row.isEmpty
                  ? const SizedBox.shrink()
                  : Text.rich(
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      TextSpan(
                        children: row.segments.map((segment) {
                          if (segment.isJiazhuNote) {
                            return WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                                decoration: BoxDecoration(
                                  color: jiazhuColor.withValues(alpha: 0.08),
                                  border: Border.all(color: jiazhuColor.withValues(alpha: 0.35), width: 0.7),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  segment.text,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    height: 1.1,
                                    fontFamily: theme.fontFamily,
                                    color: segment.color ?? theme.inkPrimary,
                                  ),
                                ),
                              ),
                            );
                          }
                          return TextSpan(
                            text: segment.text,
                            style: TextStyle(
                              fontSize: 15.0,
                              height: 1.2,
                              letterSpacing: 1.1,
                              fontWeight: segment.isBold ? FontWeight.bold : FontWeight.normal,
                              fontStyle: segment.isItalic ? FontStyle.italic : FontStyle.normal,
                              decoration: (segment.isTodo && segment.isChecked) ? TextDecoration.lineThrough : null,
                              color: segment.color ?? ((segment.isTodo && segment.isChecked) ? theme.inkSecondary : theme.inkPrimary),
                              fontFamily: theme.fontFamily,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVerticalBody() {
    final columns = bodyLeaf.verticalColumns ?? const [];
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(10, (colIndex) {
        final column = colIndex < columns.length ? columns[colIndex] : null;
        final cells = column?.cells ?? const [];
        return SizedBox(
          width: 32.0,
          height: 448.0,
          child: Column(
            children: List.generate(16, (rowIndex) {
              final cell = rowIndex < cells.length ? cells[rowIndex] : null;
              return SizedBox(
                width: 32.0,
                height: 28.0,
                child: Center(child: _buildVerticalCell(cell)),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildVerticalCell(FolioVerticalCell? cell) {
    if (cell == null || cell.mainChar.isEmpty) return const SizedBox.shrink();
    final jiazhuColor = theme.isDark ? const Color(0xFFD4AF37) : const Color(0xFFB83B2E);

    if (cell.isJiazhuPair) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 1.0),
        decoration: BoxDecoration(
          color: jiazhuColor.withValues(alpha: 0.08),
          border: Border.all(color: jiazhuColor.withValues(alpha: 0.35), width: 0.6),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(cell.secondChar, style: TextStyle(fontSize: 9.5, height: 1.0, fontFamily: theme.fontFamily, color: theme.inkPrimary.withValues(alpha: 0.88))),
            Text(cell.mainChar, style: TextStyle(fontSize: 9.5, height: 1.0, fontFamily: theme.fontFamily, color: theme.inkPrimary.withValues(alpha: 0.88))),
          ],
        ),
      );
    }
    if (cell.requiresQuarterTurnRotation) {
      return RotatedBox(
        quarterTurns: 1,
        child: Text(cell.mainChar, style: TextStyle(fontSize: 15.0, color: cell.color ?? theme.inkPrimary, fontFamily: theme.fontFamily)),
      );
    }
    if (cell.isCornerPunctuation) {
      return Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 2, right: 3),
          child: Text(cell.mainChar, style: TextStyle(fontSize: 14.0, color: cell.color ?? theme.inkPrimary, fontFamily: theme.fontFamily)),
        ),
      );
    }
    return Text(
      cell.mainChar,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 15.5,
        height: 1.0,
        fontWeight: cell.isTodo ? FontWeight.w600 : FontWeight.w400,
        color: cell.color ?? ((cell.isTodo && cell.isChecked) ? theme.inkSecondary : theme.inkPrimary),
        fontFamily: theme.fontFamily,
      ),
    );
  }
}

