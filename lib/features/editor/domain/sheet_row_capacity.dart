import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import 'stationery_sheet_descriptor.dart';

/// How many rows each Stationery Sheet holds before Auto-Spill moves text on,
/// derived from the rows actually ruled inside its Paper Heart, so a sheet
/// never holds a row it does not show (and its content can never scroll).
@immutable
class SheetRowCapacity {
  /// Rows ruled inside the Paper Heart at the current layout.
  final int visibleRows;

  const SheetRowCapacity({required this.visibleRows});

  /// The 14 rows of a Thread-Bound Folio leaf, which is also the most a
  /// Stationery Sheet's card ever shows. Pagination outside the editor (the
  /// Folio's media pairing) and the editor before its first layout use it.
  static const SheetRowCapacity folioLeaf =
      SheetRowCapacity(visibleRows: kStandardFolioRowsPerLeaf);

  /// Body rows on the opening sheet, beneath the 4-row Journal Letterhead
  /// (always at least one).
  int get openingRows => math.max(1, visibleRows - kJournalLetterheadReservedRows);

  /// Rows on a continuation sheet: every row that fits.
  int get continuationRows => math.max(1, visibleRows);

  /// The rows [sheet] holds.
  int of(TextStationerySheet sheet) =>
      sheet is OpeningSheet ? openingRows : continuationRows;

  @override
  bool operator ==(Object other) =>
      other is SheetRowCapacity && other.visibleRows == visibleRows;

  @override
  int get hashCode => visibleRows.hashCode;

  @override
  String toString() => 'SheetRowCapacity(visibleRows: $visibleRows)';
}
