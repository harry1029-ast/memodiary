import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../models/template_style.dart';
import '../models/template_text_insets.dart';
import 'stationery_layout_calculator.dart';

/// Immutable line segment in top-down canvas coordinates.
@immutable
class StationeryLineSegment {
  final Offset start;
  final Offset end;

  const StationeryLineSegment(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StationeryLineSegment &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Resolved Paper Heart framing geometry: Double Outer Border (文武双栏)
/// and optional Fishtail Mark (版心黑鱼尾) polygon vertices.
@immutable
class StationeryFrameGeometry {
  final bool drawDoubleBorder;
  final Rect outerRect;
  final Rect innerRect;
  final double outerStrokeWidth;
  final double innerStrokeWidth;
  final List<Offset>? fishtailPolygon;

  const StationeryFrameGeometry({
    required this.drawDoubleBorder,
    required this.outerRect,
    required this.innerRect,
    required this.outerStrokeWidth,
    required this.innerStrokeWidth,
    required this.fishtailPolygon,
  });
}

/// Resolved ruling segments and dot coordinates bounded inside the Paper Heart.
@immutable
class StationeryRulingGeometry {
  final List<StationeryLineSegment> primaryLines;
  final List<StationeryLineSegment> secondaryLines;
  final StationeryLineSegment? leftMarginRule;
  final List<Offset> dots;

  const StationeryRulingGeometry({
    this.primaryLines = const [],
    this.secondaryLines = const [],
    this.leftMarginRule,
    this.dots = const [],
  });
}

/// Canonical R-to-L column layout for a 2×2 Cinnabar Signature Seal (落款朱砂印).
@immutable
class CinnabarSealLayout {
  final bool isVisible;
  final bool isBaiwen;
  final List<String> colRight;
  final List<String> colLeft;
  final String semanticText;

  const CinnabarSealLayout({
    required this.isVisible,
    required this.isBaiwen,
    required this.colRight,
    required this.colLeft,
    required this.semanticText,
  });

  String get carvedText => '${colRight.join()}${colLeft.join()}';
}

/// Canonical vertical colophon (题跋落款) metadata shared by Keepsake and PDF renderers.
@immutable
class StationeryColophon {
  final String dateLine;
  final List<String> detailParts;

  const StationeryColophon({
    required this.dateLine,
    required this.detailParts,
  });

  String get detailLine => detailParts.join(' ');

  String get fullLabel =>
      detailParts.isEmpty ? dateLine : '$dateLine ${detailParts.join(" · ")}';
}

/// Pure geometry module unifying Paper Heart framing, ruling lines,
/// Cinnabar Signature Seal layout, and Colophon metadata across
/// Editor Canvas, Thread-Bound Folio, Keepsake Scroll View, and PDF export.
class StationeryGeometry {
  const StationeryGeometry._();

  static const String defaultSealText = '心迹安放';
  static const List<String> _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  /// Determines whether the Double Outer Border should be drawn for [style].
  static bool shouldDrawDoubleBorder(TemplateStyle style) {
    if (style.type == TemplateBackgroundType.lined ||
        style.type == TemplateBackgroundType.grid ||
        style.type == TemplateBackgroundType.paperTexture) {
      return true;
    }
    return style.tokens.substrate != PaperSubstrate.minimal ||
        style.tokens.ruleTint != RuleInkTint.slate;
  }

  /// Determines whether the classical Fishtail Mark (版心黑鱼尾) renders.
  /// Only rendered on manuscript grid (`grid` type) when `columnCount >= 7`.
  static bool shouldRenderFishtail({
    required TemplateStyle style,
    required int columnCount,
  }) {
    return style.type == TemplateBackgroundType.grid && columnCount >= 7;
  }

  /// Builds the 6 canonical clockwise vertices of the Fishtail Mark polygon.
  static List<Offset> buildFishtailPolygon({
    required double leftX,
    required double rightX,
    required double topY,
    required double tailHeight,
  }) {
    final midX = (leftX + rightX) / 2.0;
    final bottomY = topY + tailHeight;
    return [
      Offset(leftX, topY),
      Offset(midX, topY + tailHeight * 0.45),
      Offset(rightX, topY),
      Offset(rightX, bottomY - tailHeight * 0.15),
      Offset(midX, bottomY),
      Offset(leftX, bottomY - tailHeight * 0.15),
    ];
  }

  /// Computes Double Outer Border and conditional Fishtail Mark geometry.
  static StationeryFrameGeometry buildFrame({
    required StationeryLayoutMetrics metrics,
    required TemplateStyle style,
    double scrollOffsetY = 0.0,
    double borderGap = 4.0,
    double outerStrokeWidth = 2.0,
    double innerStrokeWidth = 0.9,
    bool? forceDoubleBorder,
    bool? forceFishtail,
  }) {
    final drawDoubleBorder = forceDoubleBorder ?? shouldDrawDoubleBorder(style);
    final innerRect = metrics.innerFrameRect.translate(0.0, -scrollOffsetY);
    final outerRect = innerRect.inflate(borderGap);

    final showFishtail = drawDoubleBorder &&
        (forceFishtail ??
            shouldRenderFishtail(style: style, columnCount: metrics.columnCount));

    List<Offset>? fishtailPolygon;
    if (showFishtail) {
      final midCol = metrics.columnCount ~/ 2;
      final colLeft = innerRect.left + midCol * metrics.cellAdvancePx;
      fishtailPolygon = buildFishtailPolygon(
        leftX: colLeft + 2.0,
        rightX: colLeft + metrics.cellAdvancePx - 2.0,
        topY: innerRect.top + metrics.lineStridePx * 0.2,
        tailHeight: metrics.lineStridePx * 0.75,
      );
    }

    return StationeryFrameGeometry(
      drawDoubleBorder: drawDoubleBorder,
      outerRect: outerRect,
      innerRect: innerRect,
      outerStrokeWidth: outerStrokeWidth,
      innerStrokeWidth: innerStrokeWidth,
      fishtailPolygon: fishtailPolygon,
    );
  }

  /// Computes Double Outer Border and optional Fishtail Mark for Thread-Bound Folio leaves.
  static StationeryFrameGeometry buildFolioFrame({
    required Size size,
    required bool showFishtail,
  }) {
    final innerRect = Offset.zero & size;
    final midX = size.width / 2.0;
    return StationeryFrameGeometry(
      drawDoubleBorder: true,
      outerRect: innerRect.inflate(3.0),
      innerRect: innerRect,
      outerStrokeWidth: 2.0,
      innerStrokeWidth: 0.8,
      fishtailPolygon: showFishtail
          ? buildFishtailPolygon(
              leftX: midX - 14.0,
              rightX: midX + 14.0,
              topY: 2.0,
              tailHeight: 18.0,
            )
          : null,
    );
  }

  /// Computes all ruling line segments and dot coordinates inside the Paper Heart.
  static StationeryRulingGeometry buildRulings({
    required StationeryLayoutMetrics metrics,
    required TemplateStyle style,
    bool isVertical = false,
    double verticalColumnStride = 36.0,
    double scrollOffsetY = 0.0,
    double headerHeight = 0.0,
    double? viewportHeight,
    double leftMarginInset = kLinedMarginRuleInset,
    bool? showLeftMarginRule,
    bool? splitManuscriptCenter,
  }) {
    final innerRect = metrics.innerFrameRect.translate(0.0, -scrollOffsetY);
    final effectiveHeaderY = innerRect.top + headerHeight;
    final topY = math.max(0.0, math.max(innerRect.top, effectiveHeaderY));
    final bottomY = viewportHeight != null
        ? math.min(viewportHeight, innerRect.bottom)
        : innerRect.bottom;

    if (isVertical &&
        (style.type == TemplateBackgroundType.lined ||
            style.type == TemplateBackgroundType.paperTexture)) {
      if (topY >= bottomY) return const StationeryRulingGeometry();
      final columns = <StationeryLineSegment>[];
      for (double x = innerRect.right - verticalColumnStride;
          x >= innerRect.left + verticalColumnStride;
          x -= verticalColumnStride) {
        columns.add(StationeryLineSegment(Offset(x, topY), Offset(x, bottomY)));
      }
      return StationeryRulingGeometry(primaryLines: columns);
    }

    switch (style.type) {
      case TemplateBackgroundType.color:
        return const StationeryRulingGeometry();

      case TemplateBackgroundType.lined:
      case TemplateBackgroundType.paperTexture:
        final rows = _buildHorizontalRows(
          innerRect: innerRect,
          rowCount: metrics.rowCount,
          lineStridePx: metrics.lineStridePx,
          effectiveHeaderY: effectiveHeaderY,
          viewportHeight: viewportHeight,
        );
        final includeMargin =
            showLeftMarginRule ?? (style.type == TemplateBackgroundType.lined);
        StationeryLineSegment? marginRule;
        if (includeMargin && topY < bottomY) {
          final marginX = innerRect.left + leftMarginInset;
          marginRule = StationeryLineSegment(
            Offset(marginX, topY),
            Offset(marginX, bottomY),
          );
        }
        return StationeryRulingGeometry(
          primaryLines: rows,
          leftMarginRule: marginRule,
        );

      case TemplateBackgroundType.grid:
        final verticalLines = <StationeryLineSegment>[];
        if (topY < bottomY) {
          for (int colIndex = 1; colIndex < metrics.columnCount; colIndex++) {
            final x = innerRect.left + colIndex * metrics.cellAdvancePx;
            verticalLines.add(
              StationeryLineSegment(Offset(x, topY), Offset(x, bottomY)),
            );
          }
        }
        final isManuscript = splitManuscriptCenter ??
            shouldRenderFishtail(style: style, columnCount: metrics.columnCount);
        final midCol = metrics.columnCount ~/ 2;
        final midColLeft = innerRect.left + midCol * metrics.cellAdvancePx;
        final midColRight = midColLeft + metrics.cellAdvancePx;
        final horizontalLines = <StationeryLineSegment>[];

        for (int rowIndex = 1; rowIndex < metrics.rowCount; rowIndex++) {
          final y = innerRect.top + rowIndex * metrics.lineStridePx;
          if (viewportHeight != null && y > viewportHeight) break;
          if (y < effectiveHeaderY) continue;
          if (isManuscript) {
            horizontalLines.add(
              StationeryLineSegment(Offset(innerRect.left, y), Offset(midColLeft, y)),
            );
            horizontalLines.add(
              StationeryLineSegment(Offset(midColRight, y), Offset(innerRect.right, y)),
            );
          } else {
            horizontalLines.add(
              StationeryLineSegment(Offset(innerRect.left, y), Offset(innerRect.right, y)),
            );
          }
        }
        return StationeryRulingGeometry(
          primaryLines: horizontalLines,
          secondaryLines: verticalLines,
        );

      case TemplateBackgroundType.dotGrid:
        final dots = <Offset>[];
        for (int rowIndex = 1; rowIndex < metrics.rowCount; rowIndex++) {
          final y = innerRect.top + rowIndex * metrics.lineStridePx;
          if (viewportHeight != null && y > viewportHeight) break;
          if (y < effectiveHeaderY) continue;
          for (int colIndex = 1; colIndex < metrics.columnCount; colIndex++) {
            final x = innerRect.left + colIndex * metrics.cellAdvancePx;
            dots.add(Offset(x, y));
          }
        }
        return StationeryRulingGeometry(dots: dots);
    }
  }

  static List<StationeryLineSegment> _buildHorizontalRows({
    required Rect innerRect,
    required int rowCount,
    required double lineStridePx,
    required double effectiveHeaderY,
    double? viewportHeight,
  }) {
    final rows = <StationeryLineSegment>[];
    for (int rowIndex = 1; rowIndex < rowCount; rowIndex++) {
      final y = innerRect.top + rowIndex * lineStridePx;
      if (viewportHeight != null && y > viewportHeight) break;
      if (y < effectiveHeaderY) continue;
      rows.add(StationeryLineSegment(Offset(innerRect.left, y), Offset(innerRect.right, y)));
    }
    return rows;
  }

  /// Computes fixed-proportion ruling lines and dots for Thread-Bound Folio leaves.
  static StationeryRulingGeometry buildFolioRulings({
    required Size size,
    required bool isVerticalColumns,
    required bool isGenkoVertical,
    required TemplateBackgroundType backgroundType,
    required bool showLeftMarginRule,
  }) {
    if (isVerticalColumns || isGenkoVertical) {
      final verticalCols = [
        for (int column = 1; column < 10; column++)
          StationeryLineSegment(
            Offset(column * 32.0, 0),
            Offset(column * 32.0, size.height),
          ),
      ];
      final cellRows = isGenkoVertical
          ? [
              for (int row = 1; row < 16; row++)
                StationeryLineSegment(
                  Offset(0, row * 28.0),
                  Offset(size.width, row * 28.0),
                ),
            ]
          : const <StationeryLineSegment>[];
      return StationeryRulingGeometry(
        primaryLines: verticalCols,
        secondaryLines: cellRows,
      );
    }

    switch (backgroundType) {
      case TemplateBackgroundType.color:
        return const StationeryRulingGeometry();

      case TemplateBackgroundType.lined:
      case TemplateBackgroundType.paperTexture:
        return StationeryRulingGeometry(
          primaryLines: [
            for (int row = 1; row < 14; row++)
              StationeryLineSegment(
                Offset(0, row * 32.0),
                Offset(size.width, row * 32.0),
              ),
          ],
          leftMarginRule: showLeftMarginRule
              ? StationeryLineSegment(const Offset(24.0, 0), Offset(24.0, size.height))
              : null,
        );

      case TemplateBackgroundType.grid:
        return StationeryRulingGeometry(
          primaryLines: [
            for (int row = 1; row < 14; row++)
              StationeryLineSegment(
                Offset(0, row * 32.0),
                Offset(size.width, row * 32.0),
              ),
          ],
          secondaryLines: [
            for (int column = 1; column < 10; column++)
              StationeryLineSegment(
                Offset(column * 32.0, 0),
                Offset(column * 32.0, size.height),
              ),
          ],
        );

      case TemplateBackgroundType.dotGrid:
        return StationeryRulingGeometry(
          dots: [
            for (int row = 1; row < 14; row++)
              for (int column = 1; column < 10; column++)
                Offset(column * 32.0, row * 32.0),
          ],
        );
    }
  }

  /// Resolves traditional R-to-L 2×2 Cinnabar Signature Seal column partitioning.
  ///
  /// Odd lengths (1 and 3 characters) are padded with `'印'` so the 2×2 grid stays
  /// balanced, while 2- and 4-character names stay exact without padding.
  static CinnabarSealLayout buildSealLayout({
    String? text,
    SealCarvingStyle sealStyle = SealCarvingStyle.zhuwen,
  }) {
    final cleaned = (text ?? '').replaceAll(RegExp(r'\s+'), '');
    final semantic = cleaned.isEmpty ? defaultSealText : cleaned;
    final chars = semantic.characters.take(4).toList();

    final (colRight, colLeft) = switch (chars.length) {
      1 => ([chars[0]], ['印']),
      2 => ([chars[0]], [chars[1]]),
      3 => ([chars[0], chars[1]], [chars[2], '印']),
      _ => ([chars[0], chars[1]], [chars[2], chars[3]]),
    };

    return CinnabarSealLayout(
      isVisible: sealStyle != SealCarvingStyle.hidden,
      isBaiwen: sealStyle == SealCarvingStyle.baiwen,
      colRight: colRight,
      colLeft: colLeft,
      semanticText: semantic,
    );
  }

  /// Formats canonical colophon metadata for Keepsake Scroll View and vertical PDF.
  static StationeryColophon buildColophon(Entry entry) {
    final dateFormatted = DateFormat('yyyy年M月d日').format(entry.entryDate);
    final dayOfWeek = '星期${_weekdays[entry.entryDate.weekday - 1]}';

    final details = <String>[];
    if (entry.isWeeklyReview) {
      details.add('第${entry.weekNumber ?? ""}周复盘');
    }
    if (entry.mood != null) {
      details.add('心情 ${entry.mood}/5');
    }
    if (entry.weather != null && entry.weather!.trim().isNotEmpty) {
      details.add('天气 ${entry.weather!.trim()}');
    }

    return StationeryColophon(
      dateLine: '$dateFormatted $dayOfWeek',
      detailParts: details,
    );
  }
}
