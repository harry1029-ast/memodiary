import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../editor/models/typography_settings.dart';
import '../../editor/services/baseline_metrics_calculator.dart';
import '../models/template_style.dart';

/// Immutable value object representing bounded Paper Heart geometry and margins.
///
/// Geometry Contract:
/// - [innerFrameRect] defines the outer Paper Heart (版心) bounds.
/// - The top rows (headerHeight) inside [innerFrameRect] are reserved for JournalLetterhead.
/// - Horizontal baselines and vertical grid rulings begin strictly at `innerFrameRect.top + headerHeight`.
class StationeryLayoutMetrics {
  final double fontSize;
  final double lineStridePx;
  final double cellAdvancePx;
  final Rect innerFrameRect;
  final int columnCount;
  final int rowCount;
  final double heavenMarginPx;
  final double earthMarginPx;

  const StationeryLayoutMetrics({
    required this.fontSize,
    required this.lineStridePx,
    required this.cellAdvancePx,
    required this.innerFrameRect,
    required this.columnCount,
    required this.rowCount,
    required this.heavenMarginPx,
    required this.earthMarginPx,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StationeryLayoutMetrics &&
          runtimeType == other.runtimeType &&
          fontSize == other.fontSize &&
          lineStridePx == other.lineStridePx &&
          cellAdvancePx == other.cellAdvancePx &&
          innerFrameRect == other.innerFrameRect &&
          columnCount == other.columnCount &&
          rowCount == other.rowCount &&
          heavenMarginPx == other.heavenMarginPx &&
          earthMarginPx == other.earthMarginPx;

  @override
  int get hashCode => Object.hash(
        fontSize,
        lineStridePx,
        cellAdvancePx,
        innerFrameRect,
        columnCount,
        rowCount,
        heavenMarginPx,
        earthMarginPx,
      );

  @override
  String toString() =>
      'StationeryLayoutMetrics(fontSize: $fontSize, lineStridePx: $lineStridePx, '
      'cellAdvancePx: $cellAdvancePx, innerFrameRect: $innerFrameRect, '
      'columnCount: $columnCount, rowCount: $rowCount, '
      'heavenMarginPx: $heavenMarginPx, earthMarginPx: $earthMarginPx)';
}

/// Pure, deterministic calculator producing immutable [StationeryLayoutMetrics]
/// shared by canvas painters, letterhead snappers, and editor viewport paddings.
class StationeryLayoutCalculator {
  const StationeryLayoutCalculator._();

  /// Calculates layout metrics using resolved [TemplateStyle] and optional [TypographySettings].
  static StationeryLayoutMetrics calculate({
    required Size canvasSize,
    required TemplateStyle style,
    TypographySettings? typography,
    bool compactMargins = false,
  }) {
    return calculateMetrics(
      canvasWidth: canvasSize.width,
      canvasHeight: canvasSize.height,
      backgroundType: style.type,
      horizontalMargin: style.resolvedHorizontalMargin,
      lineSpacing: style.lineSpacing,
      typography: typography,
      compactMargins: compactMargins,
    );
  }

  /// Calculates layout metrics from raw geometry parameters.
  static StationeryLayoutMetrics calculateMetrics({
    required double canvasWidth,
    required double canvasHeight,
    required TemplateBackgroundType backgroundType,
    double horizontalMargin = 24.0,
    double lineSpacing = 1.5,
    double? fontSize,
    TypographySettings? typography,
    bool compactMargins = false,
  }) {
    final resolvedFontSize = fontSize ?? typography?.fontSize ?? 16.0;

    final double rawStride;
    if (typography != null) {
      rawStride = BaselineMetricsCalculator.calculateLineHeight(typography.toTextStyle());
    } else {
      rawStride = resolvedFontSize * lineSpacing;
    }
    final lineStridePx = math.max(resolvedFontSize + 6.0, rawStride.roundToDouble());

    final isGridLike = backgroundType == TemplateBackgroundType.grid ||
        backgroundType == TemplateBackgroundType.dotGrid;

    final cellAdvancePx = isGridLike ? lineStridePx : resolvedFontSize;

    // Horizontal geometry
    final clampedMarginX = horizontalMargin.clamp(16.0, 36.0);
    final availableWidth = math.max(cellAdvancePx, canvasWidth - 2.0 * clampedMarginX);
    final columnCount = math.max(1, (availableWidth / cellAdvancePx).floor());
    final snappedWidth = columnCount * cellAdvancePx;
    final left = math.max(0.0, ((canvasWidth - snappedWidth) / 2.0).roundToDouble());

    // Vertical geometry
    // In compact (in-editor) mode, maximize writing rows and restrain margins.
    // In standard (export/standalone) mode, Heaven Margin enforces minimum 52.0px and Earth 44.0px.
    final minHeaven = compactMargins ? 16.0 : 52.0;
    final minEarth = compactMargins ? 16.0 : 44.0;

    int rowCount;
    double heavenMarginPx;
    double earthMarginPx;

    if (compactMargins) {
      final availableHeight = canvasHeight - minHeaven - minEarth;
      rowCount = math.max(1, (availableHeight / lineStridePx).floor());
      final totalMargin = canvasHeight - (rowCount * lineStridePx);

      heavenMarginPx = (totalMargin * 0.55).roundToDouble();
      earthMarginPx = totalMargin - heavenMarginPx;
      if (earthMarginPx < minEarth && totalMargin >= minHeaven + minEarth) {
        earthMarginPx = minEarth;
        heavenMarginPx = totalMargin - earthMarginPx;
      }
    } else {
      heavenMarginPx = (minHeaven / lineStridePx).ceil() * lineStridePx;
      if (heavenMarginPx < 2.0 * lineStridePx) {
        heavenMarginPx = 2.0 * lineStridePx;
      }

      final availableHeight = canvasHeight - heavenMarginPx - minEarth;
      rowCount = math.max(1, (availableHeight / lineStridePx).floor());
      earthMarginPx = canvasHeight - (heavenMarginPx + rowCount * lineStridePx);

      // Preserve classical Heaven-over-Earth balance (heavenMarginPx >= earthMarginPx)
      while (rowCount > 1 && (earthMarginPx < minEarth || heavenMarginPx < earthMarginPx)) {
        if (earthMarginPx < minEarth) {
          rowCount--;
          earthMarginPx = canvasHeight - (heavenMarginPx + rowCount * lineStridePx);
        } else if (heavenMarginPx < earthMarginPx) {
          heavenMarginPx += lineStridePx;
          rowCount--;
          earthMarginPx = canvasHeight - (heavenMarginPx + rowCount * lineStridePx);
        }
      }
    }

    // Safety fallback if canvasHeight is smaller than standard page proportions
    if (heavenMarginPx + rowCount * lineStridePx > canvasHeight && rowCount > 1) {
      rowCount = math.max(1, ((canvasHeight - (minHeaven + minEarth)) / lineStridePx).floor());
      earthMarginPx = math.max(0.0, canvasHeight - (heavenMarginPx + rowCount * lineStridePx));
    }

    final innerFrameRect = Rect.fromLTWH(
      left,
      heavenMarginPx,
      snappedWidth,
      rowCount * lineStridePx,
    );

    return StationeryLayoutMetrics(
      fontSize: resolvedFontSize,
      lineStridePx: lineStridePx,
      cellAdvancePx: cellAdvancePx,
      innerFrameRect: innerFrameRect,
      columnCount: columnCount,
      rowCount: rowCount,
      heavenMarginPx: heavenMarginPx,
      earthMarginPx: earthMarginPx,
    );
  }
}
