import 'package:flutter/material.dart';
import '../../../scenery/models/shanshui_atmosphere.dart';
import '../../../templates/models/template_style.dart';
import 'folio_reading_perspective.dart';

/// Base class for all physical leaves in a Thread-Bound Folio.
sealed class FolioLeaf {
  /// Zero-based physical index of this leaf in the folio.
  final int leafIndex;

  /// Total number of leaves in the complete folio.
  final int totalLeaves;

  const FolioLeaf({
    required this.leafIndex,
    required this.totalLeaves,
  });

  /// Whether this is the ceremonial frontispiece cover leaf (Page 0).
  bool get isCover => this is FolioFrontispieceCoverLeaf;

  /// Whether this leaf concludes the reading sequence and displays the diarist's seal.
  bool get isConcludingLeaf;
}

/// Page 0: Ceremonial Frontispiece Cover of the Thread-Bound Folio.
class FolioFrontispieceCoverLeaf extends FolioLeaf {
  final String entryTitle;
  final String lunarDate;
  final String gregorianDate;
  final String? weather;
  final int? mood;
  final bool isWeeklyReview;
  final int? weekNumber;
  final String? heroPhotoPath;
  final String? heroMediaType;
  final ShanshuiAtmosphereState sceneryAtmosphere;
  final String? openingReflection;
  final bool isZeroWordDraft;
  final String? sealText;
  final SealCarvingStyle sealStyle;
  final int wordCount;

  const FolioFrontispieceCoverLeaf({
    required super.leafIndex,
    required super.totalLeaves,
    required this.entryTitle,
    required this.lunarDate,
    required this.gregorianDate,
    this.weather,
    this.mood,
    this.isWeeklyReview = false,
    this.weekNumber,
    this.heroPhotoPath,
    this.heroMediaType,
    required this.sceneryAtmosphere,
    this.openingReflection,
    this.isZeroWordDraft = false,
    this.sealText,
    this.sealStyle = SealCarvingStyle.zhuwen,
    this.wordCount = 0,
  });

  @override
  bool get isConcludingLeaf => totalLeaves <= 1;
}

/// A ruled or gridded content leaf containing paginated diary body text.
class FolioContentBodyLeaf extends FolioLeaf {
  /// 1-based index among content body leaves.
  final int pageIndexInContent;

  /// Total number of content body leaves.
  final int totalContentPages;

  /// Ruling geometry for this body leaf.
  final FolioRulingLayout layout;

  /// Ruled rows for horizontal layout (14 rows).
  final List<FolioHorizontalRow>? horizontalRows;

  /// Vertical columns for vertical layout (10 columns R-to-L).
  final List<FolioVerticalColumn>? verticalColumns;

  /// Running folio header title.
  final String title;

  /// Lunar date string for footer colophon.
  final String lunarDate;

  /// Diarist's seal inscription (rendered on concluding leaf).
  final String? sealText;

  /// Carving style of the cinnabar seal.
  final SealCarvingStyle sealStyle;

  @override
  final bool isConcludingLeaf;

  const FolioContentBodyLeaf({
    required super.leafIndex,
    required super.totalLeaves,
    required this.pageIndexInContent,
    required this.totalContentPages,
    required this.layout,
    this.horizontalRows,
    this.verticalColumns,
    required this.title,
    required this.lunarDate,
    this.sealText,
    this.sealStyle = SealCarvingStyle.zhuwen,
    this.isConcludingLeaf = false,
  });
}

/// A dedicated leaf presenting an embedded photo or short video.
class FolioTippedInEphemeraLeaf extends FolioLeaf {
  /// 'image' or 'video'.
  final String mediaType;

  /// Sandboxed relative path inside the application directory.
  final String sandboxedRelativePath;

  /// Optional caption.
  final String? caption;

  /// Natural aspect ratio of the media asset.
  final double aspectRatio;

  /// Running folio header title.
  final String title;

  /// Lunar date string for footer colophon.
  final String lunarDate;

  /// Diarist's seal inscription (rendered if this is the concluding leaf).
  final String? sealText;

  /// Carving style of the cinnabar seal.
  final SealCarvingStyle sealStyle;

  @override
  final bool isConcludingLeaf;

  const FolioTippedInEphemeraLeaf({
    required super.leafIndex,
    required super.totalLeaves,
    required this.mediaType,
    required this.sandboxedRelativePath,
    this.caption,
    this.aspectRatio = 1.0,
    required this.title,
    required this.lunarDate,
    this.sealText,
    this.sealStyle = SealCarvingStyle.zhuwen,
    this.isConcludingLeaf = false,
  });
}

/// Single horizontal row in a horizontal ruled content leaf.
class FolioHorizontalRow {
  final List<FolioHorizontalSegment> segments;

  const FolioHorizontalRow({
    required this.segments,
  });

  bool get isEmpty =>
      segments.isEmpty || segments.every((segment) => segment.text.isEmpty);
}

/// Inline text segment within a horizontal ruled line.
class FolioHorizontalSegment {
  final String text;
  final bool isJiazhuNote;
  final bool isTodo;
  final bool isChecked;
  final bool isBold;
  final bool isItalic;
  final Color? color;

  const FolioHorizontalSegment({
    required this.text,
    this.isJiazhuNote = false,
    this.isTodo = false,
    this.isChecked = false,
    this.isBold = false,
    this.isItalic = false,
    this.color,
  });
}

/// Single vertical column in a classical vertical leaf.
class FolioVerticalColumn {
  final List<FolioVerticalCell> cells;

  const FolioVerticalColumn({
    required this.cells,
  });

  bool get isEmpty => cells.isEmpty;
}

/// Single character cell in a vertical column (up to 16 cells per column).
class FolioVerticalCell {
  final String mainChar;
  final String secondChar;
  final bool isJiazhuPair;
  final bool isTodo;
  final bool isChecked;
  final bool isCornerPunctuation;
  final bool requiresQuarterTurnRotation;
  final Color? color;

  const FolioVerticalCell({
    required this.mainChar,
    this.secondChar = '',
    this.isJiazhuPair = false,
    this.isTodo = false,
    this.isChecked = false,
    this.isCornerPunctuation = false,
    this.requiresQuarterTurnRotation = false,
    this.color,
  });
}
