import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import '../../templates/models/template_style.dart';
import '../../templates/models/template_text_insets.dart';
import '../../templates/services/stationery_layout_calculator.dart';
import '../models/typography_settings.dart';
import 'stationery_sheet_descriptor.dart';

/// Immutable value object representing the complete spatial contract of a tactile
/// Stationery Sheet (信笺书页) on the Scholar's Desk (文房案头).
@immutable
class StationerySheetGeometry {
  /// Outer dimensions of the paper card resting on the desk.
  final Size cardSize;

  /// Convenience getter for [cardSize.height].
  double get cardHeight => cardSize.height;

  /// The bounded Paper Heart (版心) enclosing ruling lines and text flow.
  final Rect paperHeart;

  /// Vertical line stride in pixels between baselines.
  final double lineStridePx;

  /// Ruled row capacity of this sheet.
  final SheetRowCapacity rowCapacity;

  /// Height reserved for the Journal Letterhead on opening sheets (4 ruled rows).
  final double openingHeaderHeight;

  /// Available writing height for the text editor body on sheet 1.
  final double openingBodyHeight;

  /// Available writing height for the text editor body on continuation sheets.
  final double continuationBodyHeight;

  /// Bounding rectangle for the running colophon in the Heaven margin on continuation sheets.
  final Rect continuationColophonRect;

  /// Horizontal text insets relative to the [paperHeart] bounds.
  final TemplateTextInsets textInsets;

  /// Horizontal text insets relative to the outer card edges.
  final EdgeInsets textInsetsFromCardEdge;

  /// Available text width inside the Paper Heart after subtracting template text insets.
  final double usableTextWidth;

  /// Underlying layout metrics calculated for the stationery.
  final StationeryLayoutMetrics metrics;

  const StationerySheetGeometry({
    required this.cardSize,
    required this.paperHeart,
    required this.lineStridePx,
    required this.rowCapacity,
    required this.openingHeaderHeight,
    required this.openingBodyHeight,
    required this.continuationBodyHeight,
    required this.continuationColophonRect,
    required this.textInsets,
    required this.textInsetsFromCardEdge,
    required this.usableTextWidth,
    required this.metrics,
  });

  /// Deterministically resolves the complete sheet geometry given viewport bounds,
  /// resting desk height, template styling, and optional typography.
  factory StationerySheetGeometry.resolve({
    required double canvasWidth,
    required double restingDeskHeight,
    required TemplateStyle templateStyle,
    TypographySettings? typography,
  }) {
    final cardCanvasHeight = math.max(380.0, math.min(restingDeskHeight, 420.0));
    final cardCanvasSize = Size(canvasWidth, cardCanvasHeight);

    final metrics = StationeryLayoutCalculator.calculate(
      canvasSize: cardCanvasSize,
      style: templateStyle,
      typography: typography,
      compactMargins: true,
      maxRows: kStandardFolioRowsPerLeaf,
    );

    final cardHeight = metrics.innerFrameRect.bottom + 16.0;
    final cardSize = Size(canvasWidth, cardHeight);

    final paperHeart = metrics.innerFrameRect;
    final lineStridePx = metrics.lineStridePx;
    final rowCapacity = SheetRowCapacity(visibleRows: metrics.rowCount);

    final openingHeaderHeight = kJournalLetterheadReservedRows * lineStridePx;
    final openingBodyHeight = math.max(0.0, paperHeart.height - openingHeaderHeight);
    final continuationBodyHeight = math.max(0.0, paperHeart.height);

    final textInsets = TemplateTextInsets.forType(templateStyle.type);
    final textInsetsFromCardEdge = EdgeInsets.only(
      left: paperHeart.left + textInsets.left,
      right: math.max(0.0, cardSize.width - paperHeart.right) + textInsets.right,
    );

    final colophonTop = math.max(0.0, paperHeart.top - 26.0);
    final colophonHeight = math.min(24.0, paperHeart.top - colophonTop);
    final colophonLeft = textInsetsFromCardEdge.left;
    final colophonWidth = math.max(
      0.0,
      cardSize.width - textInsetsFromCardEdge.left - textInsetsFromCardEdge.right,
    );
    final continuationColophonRect = Rect.fromLTWH(
      colophonLeft,
      colophonTop,
      colophonWidth,
      colophonHeight,
    );

    final usableTextWidth = math.max(
      120.0,
      paperHeart.width - textInsets.left - textInsets.right,
    );

    return StationerySheetGeometry(
      cardSize: cardSize,
      paperHeart: paperHeart,
      lineStridePx: lineStridePx,
      rowCapacity: rowCapacity,
      openingHeaderHeight: openingHeaderHeight,
      openingBodyHeight: openingBodyHeight,
      continuationBodyHeight: continuationBodyHeight,
      continuationColophonRect: continuationColophonRect,
      textInsets: textInsets,
      textInsetsFromCardEdge: textInsetsFromCardEdge,
      usableTextWidth: usableTextWidth,
      metrics: metrics,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StationerySheetGeometry &&
          runtimeType == other.runtimeType &&
          cardSize == other.cardSize &&
          paperHeart == other.paperHeart &&
          lineStridePx == other.lineStridePx &&
          rowCapacity == other.rowCapacity &&
          openingHeaderHeight == other.openingHeaderHeight &&
          openingBodyHeight == other.openingBodyHeight &&
          continuationBodyHeight == other.continuationBodyHeight &&
          continuationColophonRect == other.continuationColophonRect &&
          textInsets == other.textInsets &&
          textInsetsFromCardEdge == other.textInsetsFromCardEdge &&
          usableTextWidth == other.usableTextWidth &&
          metrics == other.metrics;

  @override
  int get hashCode => Object.hash(
        cardSize,
        paperHeart,
        lineStridePx,
        rowCapacity,
        openingHeaderHeight,
        openingBodyHeight,
        continuationBodyHeight,
        continuationColophonRect,
        textInsets,
        textInsetsFromCardEdge,
        usableTextWidth,
        metrics,
      );

  @override
  String toString() =>
      'StationerySheetGeometry(cardSize: $cardSize, paperHeart: $paperHeart, '
      'lineStridePx: $lineStridePx, rowCapacity: $rowCapacity, '
      'openingHeaderHeight: $openingHeaderHeight, openingBodyHeight: $openingBodyHeight, '
      'continuationBodyHeight: $continuationBodyHeight, '
      'continuationColophonRect: $continuationColophonRect, '
      'textInsets: $textInsets, textInsetsFromCardEdge: $textInsetsFromCardEdge, '
      'usableTextWidth: $usableTextWidth, metrics: $metrics)';
}
