import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/templates/services/stationery_layout_calculator.dart';

void main() {
  group('StationeryLayoutCalculator Tests', () {
    test('enforces lineStridePx floored at fontSize + 6.0', () {
      final metricsTight = StationeryLayoutCalculator.calculateMetrics(
        canvasWidth: 360.0,
        canvasHeight: 640.0,
        backgroundType: TemplateBackgroundType.lined,
        fontSize: 16.0,
        lineSpacing: 1.0, // 16.0 * 1.0 = 16.0, floored at 16.0 + 6.0 = 22.0
      );
      expect(metricsTight.lineStridePx, equals(22.0));

      final metricsNormal = StationeryLayoutCalculator.calculateMetrics(
        canvasWidth: 360.0,
        canvasHeight: 640.0,
        backgroundType: TemplateBackgroundType.lined,
        fontSize: 16.0,
        lineSpacing: 1.5, // 16.0 * 1.5 = 24.0, > 22.0
      );
      expect(metricsNormal.lineStridePx, equals(24.0));
    });

    test('sets cellAdvancePx equal to lineStridePx on grid and dotGrid', () {
      final gridMetrics = StationeryLayoutCalculator.calculateMetrics(
        canvasWidth: 360.0,
        canvasHeight: 640.0,
        backgroundType: TemplateBackgroundType.grid,
        fontSize: 16.0,
        lineSpacing: 1.5,
      );
      expect(gridMetrics.cellAdvancePx, equals(gridMetrics.lineStridePx));
      expect(gridMetrics.cellAdvancePx, equals(24.0));

      final dotGridMetrics = StationeryLayoutCalculator.calculateMetrics(
        canvasWidth: 360.0,
        canvasHeight: 640.0,
        backgroundType: TemplateBackgroundType.dotGrid,
        fontSize: 16.0,
        lineSpacing: 1.5,
      );
      expect(dotGridMetrics.cellAdvancePx, equals(dotGridMetrics.lineStridePx));
      expect(dotGridMetrics.cellAdvancePx, equals(24.0));
    });

    test('sets cellAdvancePx equal to fontSize on lined and color templates', () {
      final linedMetrics = StationeryLayoutCalculator.calculateMetrics(
        canvasWidth: 360.0,
        canvasHeight: 640.0,
        backgroundType: TemplateBackgroundType.lined,
        fontSize: 16.0,
        lineSpacing: 1.5,
      );
      expect(linedMetrics.cellAdvancePx, equals(16.0));
      expect(linedMetrics.lineStridePx, equals(24.0));

      final colorMetrics = StationeryLayoutCalculator.calculateMetrics(
        canvasWidth: 360.0,
        canvasHeight: 640.0,
        backgroundType: TemplateBackgroundType.color,
        fontSize: 18.0,
        lineSpacing: 1.6,
      );
      expect(colorMetrics.cellAdvancePx, equals(18.0));
    });

    test('enforces Heaven Margin >= 52.0 and Earth Margin >= 44.0 with Heaven >= Earth', () {
      const testHeights = [600.0, 640.0, 720.0, 800.0, 844.0, 1024.0];

      for (final canvasHeight in testHeights) {
        final metrics = StationeryLayoutCalculator.calculateMetrics(
          canvasWidth: 375.0,
          canvasHeight: canvasHeight,
          backgroundType: TemplateBackgroundType.grid,
          fontSize: 16.0,
          lineSpacing: 1.5,
        );

        expect(metrics.heavenMarginPx, greaterThanOrEqualTo(52.0));
        expect(metrics.earthMarginPx, greaterThanOrEqualTo(44.0));
        expect(
          metrics.heavenMarginPx,
          greaterThanOrEqualTo(metrics.earthMarginPx),
          reason: 'Preserves Heaven-over-Earth balance at height $canvasHeight',
        );

        // Heaven margin must be an integer multiple of lineStridePx
        final multiple = metrics.heavenMarginPx / metrics.lineStridePx;
        expect((multiple - multiple.round()).abs() < 0.001, isTrue);

        // innerFrameRect top must align with heavenMarginPx
        expect(metrics.innerFrameRect.top, equals(metrics.heavenMarginPx));
        expect(
          metrics.innerFrameRect.height,
          equals(metrics.rowCount * metrics.lineStridePx),
        );
        expect(
          (metrics.innerFrameRect.bottom + metrics.earthMarginPx - canvasHeight).abs() < 0.001,
          isTrue,
        );
      }
    });

    test('snaps width and centers innerFrameRect symmetrically', () {
      const canvasWidth = 375.0;
      final metrics = StationeryLayoutCalculator.calculateMetrics(
        canvasWidth: canvasWidth,
        canvasHeight: 800.0,
        backgroundType: TemplateBackgroundType.grid,
        horizontalMargin: 20.0,
        fontSize: 16.0,
        lineSpacing: 1.5, // stride = 24.0
      );

      // Available width: 375 - 40 = 335.
      // 335 / 24 = 13.95 -> 13 columns * 24 = 312px.
      // (375 - 312) / 2 = 31.5 -> roundToDouble = 32.0.
      expect(metrics.columnCount, equals(13));
      expect(metrics.innerFrameRect.width, equals(312.0));
      expect(metrics.innerFrameRect.left, equals(32.0));
      expect(metrics.innerFrameRect.right, equals(344.0));

      final rightMargin = canvasWidth - metrics.innerFrameRect.right;
      expect((metrics.innerFrameRect.left - rightMargin).abs(), lessThanOrEqualTo(1.0));
    });

    test('respects active TypographySettings line height', () {
      const typography = TypographySettings(
        fontSize: 18.0,
        lineSpacing: 1.6,
      );

      final style = TemplateStyle(
        type: TemplateBackgroundType.lined,
        backgroundColor: Colors.white,
        lineSpacing: 1.6,
        marginHorizontal: 24.0,
      );

      final metrics = StationeryLayoutCalculator.calculate(
        canvasSize: const Size(400.0, 800.0),
        style: style,
        typography: typography,
      );

      expect(metrics.fontSize, equals(18.0));
      expect(metrics.lineStridePx, equals(29.0)); // 18.0 * 1.6 = 28.8 -> 29.0
    });

    test('value equality and hashCode contract', () {
      final metricsFirst = StationeryLayoutCalculator.calculateMetrics(
        canvasWidth: 360.0,
        canvasHeight: 640.0,
        backgroundType: TemplateBackgroundType.grid,
      );
      final metricsSecond = StationeryLayoutCalculator.calculateMetrics(
        canvasWidth: 360.0,
        canvasHeight: 640.0,
        backgroundType: TemplateBackgroundType.grid,
      );
      final metricsDifferent = StationeryLayoutCalculator.calculateMetrics(
        canvasWidth: 400.0,
        canvasHeight: 640.0,
        backgroundType: TemplateBackgroundType.grid,
      );

      expect(metricsFirst, equals(metricsSecond));
      expect(metricsFirst.hashCode, equals(metricsSecond.hashCode));
      expect(metricsFirst, isNot(equals(metricsDifferent)));
    });

    test('compactMargins reduces wasted vertical space while preserving Heaven >= Earth', () {
      final compactMetrics = StationeryLayoutCalculator.calculateMetrics(
        canvasWidth: 390.0,
        canvasHeight: 780.0,
        backgroundType: TemplateBackgroundType.lined,
        compactMargins: true,
      );

      final totalWasted = compactMetrics.heavenMarginPx + compactMetrics.earthMarginPx;
      expect(totalWasted, lessThan(80.0));
      expect(compactMetrics.heavenMarginPx, greaterThanOrEqualTo(compactMetrics.earthMarginPx));
    });
  });
}
