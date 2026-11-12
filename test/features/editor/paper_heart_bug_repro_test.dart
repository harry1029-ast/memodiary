import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_geometry.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/templates/models/template_style.dart';
import 'package:memodiary/features/templates/models/template_text_insets.dart';
import 'package:memodiary/features/templates/services/stationery_layout_calculator.dart';

void main() {
  group('Paper Heart Geometry & Framing Regression Tests', () {
    const typography = TypographySettings(fontSize: 16.0, lineSpacing: 1.5);
    const linedStyle = TemplateStyle(
      type: TemplateBackgroundType.lined,
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

    test('Bug 1a & 1b Fix: characters have breathing room and do not write over red margin line', () {
      final geometry = StationerySheetGeometry.resolve(
        canvasWidth: 390.0,
        restingDeskHeight: 780.0,
        templateStyle: linedStyle,
        typography: typography,
      );

      final horizontalLeft = geometry.paperHeart.left + geometry.textInsets.left;
      final marginX = geometry.paperHeart.left + kLinedMarginRuleInset;

      // Glyph 1 starts at horizontalLeft and extends by fontSize
      final glyph1Start = horizontalLeft;
      final glyph1End = horizontalLeft + typography.fontSize;

      // Assert 1b: The margin line at marginX is strictly to the left of glyph 1
      final marginLineIntersectsGlyph1 = marginX >= glyph1Start && marginX <= glyph1End;
      expect(
        marginLineIntersectsGlyph1,
        isFalse,
        reason: 'Text at horizontalLeft=$horizontalLeft must start after the red margin line at marginX=$marginX',
      );
      expect(glyph1Start, greaterThan(marginX));

      // Assert 1a: Breathing room inside Paper Heart
      final innerPaddingLeft = glyph1Start - geometry.paperHeart.left;
      expect(
        innerPaddingLeft,
        greaterThanOrEqualTo(20.0),
        reason: 'Text glyphs must have comfortable breathing room inside the Paper Heart border',
      );

      // Verify on plain / color style:
      final colorGeometry = StationerySheetGeometry.resolve(
        canvasWidth: 390.0,
        restingDeskHeight: 780.0,
        templateStyle: colorStyle,
        typography: typography,
      );
      final colorHorizontalLeft = colorGeometry.paperHeart.left + colorGeometry.textInsets.left;
      expect(colorGeometry.textInsets.left, equals(20.0));
      expect(colorHorizontalLeft - colorGeometry.paperHeart.left, equals(20.0));
      expect(colorGeometry.textInsetsFromCardEdge.left - colorGeometry.paperHeart.left, equals(20.0));
    });

    test('Bug 1c Fix: compactMargins reclaims vertical space and eliminates wasted margins', () {
      final metrics = StationeryLayoutCalculator.calculate(
        canvasSize: const Size(390.0, 800.0),
        style: linedStyle,
        typography: typography,
        compactMargins: true,
      );

      final totalWastedVerticalSpace = metrics.heavenMarginPx + metrics.earthMarginPx;

      // compactMargins keeps top/bottom margins tight (under 80px total), preserving 60+px of extra writing rows
      expect(
        totalWastedVerticalSpace,
        lessThan(80.0),
        reason: 'Total vertical margin outside paper heart must be compact in editor, but was $totalWastedVerticalSpace px',
      );
      expect(metrics.heavenMarginPx, greaterThanOrEqualTo(metrics.earthMarginPx));
      expect(metrics.rowCount, greaterThanOrEqualTo(30));
    });

    test('Bug 2 Fix: totalPaperHeight protects Paper Heart from shrinking when keyboard opens or scrolling', () {
      const normalHeight = 700.0;
      const keyboardHeight = 400.0;
      const scrollExtent = 200.0;

      // In entry_editor_screen.dart:
      // baseCanvasHeight uses unconstrained screen height, unaffected by keyboard
      final baseCanvasHeight = math.max(keyboardHeight, normalHeight);
      final totalPaperHeight = math.max(baseCanvasHeight, baseCanvasHeight + scrollExtent);

      final metrics = StationeryLayoutCalculator.calculate(
        canvasSize: Size(390.0, totalPaperHeight),
        style: linedStyle,
        typography: typography,
        compactMargins: true,
      );

      // totalPaperHeight accommodates the full document (900px), not shrinking to 400px
      expect(metrics.innerFrameRect.height, greaterThan(800.0));

      // When scrolled by 150px:
      const scrollOffset = 150.0;
      final drawnBottom = metrics.innerFrameRect.bottom - scrollOffset;

      // In the 400px visible viewport above keyboard, cursor at y=350px is safely INSIDE the border
      const cursorY = 350.0;
      final isCursorOutsideBorder = cursorY > drawnBottom;

      expect(
        isCursorOutsideBorder,
        isFalse,
        reason: 'Cursor at y=$cursorY must stay enclosed inside drawnBottom=$drawnBottom',
      );
    });
  });
}
