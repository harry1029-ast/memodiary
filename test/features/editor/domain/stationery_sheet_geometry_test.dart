import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_geometry.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/templates/models/template_text_insets.dart';
import 'package:memodiary/features/templates/services/stationery_layout_calculator.dart';

void main() {
  group('TemplateTextInsets Domain Tests', () {
    test('kLinedMarginRuleInset constant is exactly 24.0px', () {
      expect(kLinedMarginRuleInset, equals(24.0));
    });

    test('resolves insets for grid and dotGrid to zero', () {
      final gridInsets = TemplateTextInsets.forType(TemplateBackgroundType.grid);
      expect(gridInsets.left, equals(0.0));
      expect(gridInsets.right, equals(0.0));

      final dotGridInsets = TemplateTextInsets.forType(TemplateBackgroundType.dotGrid);
      expect(dotGridInsets.left, equals(0.0));
      expect(dotGridInsets.right, equals(0.0));
    });

    test('resolves insets for lined paper with at least 8px clearance from margin rule', () {
      final linedInsets = TemplateTextInsets.forType(TemplateBackgroundType.lined);
      expect(linedInsets.left, equals(32.0));
      expect(linedInsets.right, equals(20.0));
      expect(linedInsets.left - kLinedMarginRuleInset, equals(8.0));
    });

    test('resolves standard 20px insets for plain color and paper texture', () {
      final colorInsets = TemplateTextInsets.forType(TemplateBackgroundType.color);
      expect(colorInsets.left, equals(20.0));
      expect(colorInsets.right, equals(20.0));

      final textureInsets = TemplateTextInsets.forType(TemplateBackgroundType.paperTexture);
      expect(textureInsets.left, equals(20.0));
      expect(textureInsets.right, equals(20.0));
    });

    test('supports value equality, hashCode, and toString', () {
      const insets1 = TemplateTextInsets(left: 32.0, right: 20.0);
      const insets2 = TemplateTextInsets(left: 32.0, right: 20.0);
      const insetsDiff = TemplateTextInsets(left: 20.0, right: 20.0);

      expect(insets1, equals(insets2));
      expect(insets1.hashCode, equals(insets2.hashCode));
      expect(insets1, isNot(equals(insetsDiff)));
      expect(insets1.toString(), contains('TemplateTextInsets(left: 32.0, right: 20.0)'));
    });
  });

  group('StationerySheetGeometry Domain Tests', () {
    const standardTypography = TypographySettings(fontSize: 16.0, lineSpacing: 1.5);
    const customTypography29 = TypographySettings(fontSize: 18.0, lineSpacing: 1.6);

    const linedStyle = TemplateStyle(
      type: TemplateBackgroundType.lined,
      backgroundColor: Colors.white,
      lineSpacing: 1.5,
      marginHorizontal: 24.0,
    );

    const gridStyle = TemplateStyle(
      type: TemplateBackgroundType.grid,
      backgroundColor: Colors.white,
      lineSpacing: 1.5,
      marginHorizontal: 24.0,
    );

    const colorStyle = TemplateStyle(
      type: TemplateBackgroundType.color,
      backgroundColor: Colors.white,
      lineSpacing: 1.5,
      marginHorizontal: 24.0,
    );

    test('clamps canvas height between 380px and 420px', () {
      // Small restingDeskHeight (300.0) -> clamps to 380.0
      final smallGeometry = StationerySheetGeometry.resolve(
        canvasWidth: 360.0,
        restingDeskHeight: 300.0,
        templateStyle: linedStyle,
        typography: standardTypography,
      );
      final expectedSmallMetrics = StationeryLayoutCalculator.calculate(
        canvasSize: const Size(360.0, 380.0),
        style: linedStyle,
        typography: standardTypography,
        compactMargins: true,
        maxRows: kStandardFolioRowsPerLeaf,
      );
      expect(smallGeometry.metrics, equals(expectedSmallMetrics));
      expect(smallGeometry.cardSize.width, equals(360.0));
      expect(smallGeometry.cardHeight, equals(expectedSmallMetrics.innerFrameRect.bottom + 16.0));
      expect(smallGeometry.cardSize.height, equals(smallGeometry.cardHeight));

      // Mid restingDeskHeight (400.0) -> stays 400.0
      final midGeometry = StationerySheetGeometry.resolve(
        canvasWidth: 360.0,
        restingDeskHeight: 400.0,
        templateStyle: linedStyle,
        typography: standardTypography,
      );
      final expectedMidMetrics = StationeryLayoutCalculator.calculate(
        canvasSize: const Size(360.0, 400.0),
        style: linedStyle,
        typography: standardTypography,
        compactMargins: true,
        maxRows: kStandardFolioRowsPerLeaf,
      );
      expect(midGeometry.metrics, equals(expectedMidMetrics));
      expect(midGeometry.cardHeight, equals(expectedMidMetrics.innerFrameRect.bottom + 16.0));

      // Large restingDeskHeight (600.0) -> clamps to 420.0
      final largeGeometry = StationerySheetGeometry.resolve(
        canvasWidth: 360.0,
        restingDeskHeight: 600.0,
        templateStyle: linedStyle,
        typography: standardTypography,
      );
      final expectedLargeMetrics = StationeryLayoutCalculator.calculate(
        canvasSize: const Size(360.0, 420.0),
        style: linedStyle,
        typography: standardTypography,
        compactMargins: true,
        maxRows: kStandardFolioRowsPerLeaf,
      );
      expect(largeGeometry.metrics, equals(expectedLargeMetrics));
      expect(largeGeometry.cardHeight, equals(expectedLargeMetrics.innerFrameRect.bottom + 16.0));
    });

    test('row capacity is strictly bounded by kStandardFolioRowsPerLeaf (14 rows)', () {
      final geometry = StationerySheetGeometry.resolve(
        canvasWidth: 400.0,
        restingDeskHeight: 500.0,
        templateStyle: linedStyle,
        typography: standardTypography,
      );

      expect(geometry.rowCapacity.visibleRows, equals(geometry.metrics.rowCount));
      expect(geometry.rowCapacity.visibleRows, lessThanOrEqualTo(kStandardFolioRowsPerLeaf));
      expect(geometry.rowCapacity.continuationRows, equals(geometry.rowCapacity.visibleRows));
      expect(
        geometry.rowCapacity.openingRows,
        equals(math.max(1, geometry.rowCapacity.visibleRows - kJournalLetterheadReservedRows)),
      );
    });

    test('openingHeaderHeight is strictly 4 * lineStridePx for standard and custom typography', () {
      // Standard typography: 16px * 1.5 = 24px stride -> 4 * 24 = 96px
      final standardGeometry = StationerySheetGeometry.resolve(
        canvasWidth: 360.0,
        restingDeskHeight: 400.0,
        templateStyle: linedStyle,
        typography: standardTypography,
      );
      expect(standardGeometry.lineStridePx, equals(24.0));
      expect(standardGeometry.openingHeaderHeight, equals(96.0));
      expect(
        standardGeometry.openingHeaderHeight,
        equals(kJournalLetterheadReservedRows * standardGeometry.lineStridePx),
      );

      // Custom typography: 18px font with custom stride -> 29px stride -> 4 * 29 = 116px
      final customGeometry = StationerySheetGeometry.resolve(
        canvasWidth: 360.0,
        restingDeskHeight: 400.0,
        templateStyle: linedStyle,
        typography: customTypography29,
      );
      expect(customGeometry.lineStridePx, equals(29.0));
      expect(customGeometry.openingHeaderHeight, equals(116.0));
      expect(
        customGeometry.openingHeaderHeight,
        equals(kJournalLetterheadReservedRows * customGeometry.lineStridePx),
      );
    });

    test('resolves correct template text insets and margin rule clearance', () {
      // Lined: left 32.0, right 20.0
      final linedGeometry = StationerySheetGeometry.resolve(
        canvasWidth: 360.0,
        restingDeskHeight: 400.0,
        templateStyle: linedStyle,
        typography: standardTypography,
      );
      expect(linedGeometry.textInsets.left, equals(32.0));
      expect(linedGeometry.textInsets.right, equals(20.0));

      // Margin line position on lined paper
      final marginLineX = linedGeometry.paperHeart.left + kLinedMarginRuleInset;
      final textStartX = linedGeometry.textInsetsFromCardEdge.left;
      expect(textStartX, equals(linedGeometry.paperHeart.left + linedGeometry.textInsets.left));
      expect(
        textStartX - marginLineX,
        greaterThanOrEqualTo(8.0),
        reason: 'Text start must clear the vertical red margin line by at least 8.0px breathing room',
      );

      // Grid: left 0.0, right 0.0
      final gridGeometry = StationerySheetGeometry.resolve(
        canvasWidth: 360.0,
        restingDeskHeight: 400.0,
        templateStyle: gridStyle,
        typography: standardTypography,
      );
      expect(gridGeometry.textInsets.left, equals(0.0));
      expect(gridGeometry.textInsets.right, equals(0.0));
      expect(gridGeometry.textInsetsFromCardEdge.left, equals(gridGeometry.paperHeart.left));

      // Color: left 20.0, right 20.0
      final colorGeometry = StationerySheetGeometry.resolve(
        canvasWidth: 360.0,
        restingDeskHeight: 400.0,
        templateStyle: colorStyle,
        typography: standardTypography,
      );
      expect(colorGeometry.textInsets.left, equals(20.0));
      expect(colorGeometry.textInsets.right, equals(20.0));
      expect(
        colorGeometry.textInsetsFromCardEdge.left,
        equals(colorGeometry.paperHeart.left + 20.0),
      );
    });

    test('openingBodyHeight and continuationBodyHeight correctly match ruled surface', () {
      final geometry = StationerySheetGeometry.resolve(
        canvasWidth: 360.0,
        restingDeskHeight: 400.0,
        templateStyle: linedStyle,
        typography: standardTypography,
      );

      expect(
        geometry.openingBodyHeight,
        equals(math.max(0.0, geometry.paperHeart.height - geometry.openingHeaderHeight)),
      );
      expect(geometry.continuationBodyHeight, equals(geometry.paperHeart.height));

      // Sum of opening header and opening body matches total paperHeart height
      expect(
        geometry.openingHeaderHeight + geometry.openingBodyHeight,
        equals(geometry.paperHeart.height),
      );

      // Continuation body height matches visibleRows * lineStridePx
      expect(
        geometry.continuationBodyHeight,
        equals(geometry.rowCapacity.visibleRows * geometry.lineStridePx),
      );
    });

    test('continuationColophonRect is positioned strictly in Heaven margin above Paper Heart', () {
      final geometry = StationerySheetGeometry.resolve(
        canvasWidth: 360.0,
        restingDeskHeight: 400.0,
        templateStyle: linedStyle,
        typography: standardTypography,
      );

      final colophonRect = geometry.continuationColophonRect;
      expect(colophonRect.left, equals(geometry.textInsetsFromCardEdge.left));
      expect(
        colophonRect.width,
        equals(math.max(
          0.0,
          geometry.cardSize.width -
              geometry.textInsetsFromCardEdge.left -
              geometry.textInsetsFromCardEdge.right,
        )),
      );
      expect(
        colophonRect.bottom,
        lessThanOrEqualTo(geometry.paperHeart.top),
        reason: 'Colophon must reside strictly above the Paper Heart in the Heaven margin',
      );
      expect(colophonRect.top, greaterThanOrEqualTo(0.0));
      expect(colophonRect.height, lessThanOrEqualTo(24.0));
    });

    test('usableTextWidth enforces minimum 120px safety bound', () {
      // Normal canvas width
      final normalGeometry = StationerySheetGeometry.resolve(
        canvasWidth: 360.0,
        restingDeskHeight: 400.0,
        templateStyle: linedStyle,
        typography: standardTypography,
      );
      expect(
        normalGeometry.usableTextWidth,
        equals(normalGeometry.paperHeart.width - normalGeometry.textInsets.left - normalGeometry.textInsets.right),
      );
      expect(normalGeometry.usableTextWidth, greaterThan(120.0));

      // Extremely narrow canvas width (100.0) -> clamps to 120.0
      final narrowGeometry = StationerySheetGeometry.resolve(
        canvasWidth: 100.0,
        restingDeskHeight: 400.0,
        templateStyle: linedStyle,
        typography: standardTypography,
      );
      expect(narrowGeometry.usableTextWidth, equals(120.0));
    });

    test('supports value equality, hashCode, and toString', () {
      final g1 = StationerySheetGeometry.resolve(
        canvasWidth: 360.0,
        restingDeskHeight: 400.0,
        templateStyle: linedStyle,
        typography: standardTypography,
      );
      final g2 = StationerySheetGeometry.resolve(
        canvasWidth: 360.0,
        restingDeskHeight: 400.0,
        templateStyle: linedStyle,
        typography: standardTypography,
      );
      final gDiff = StationerySheetGeometry.resolve(
        canvasWidth: 380.0,
        restingDeskHeight: 400.0,
        templateStyle: linedStyle,
        typography: standardTypography,
      );

      expect(g1, equals(g2));
      expect(g1.hashCode, equals(g2.hashCode));
      expect(g1, isNot(equals(gDiff)));
      expect(g1.toString(), contains('StationerySheetGeometry('));
      expect(g1.toString(), contains('cardSize:'));
      expect(g1.toString(), contains('paperHeart:'));
    });
  });
}
