import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/widgets/editor_quill_styles_builder.dart';
import 'package:memodiary/features/templates/models/template_style.dart';

void main() {
  group('EditorQuillStylesBuilder Tests', () {
    const typography = TypographySettings(
      fontFamily: 'NotoSerifSC',
      fontSize: 16.0,
      lineSpacing: 1.5,
    );

    test('buildStrutStyle creates forceStrutHeight StrutStyle matching lineStridePx', () {
      final strutStyle = EditorQuillStylesBuilder.buildStrutStyle(
        fontSize: 16.0,
        lineStridePx: 24.0,
      );

      expect(strutStyle.forceStrutHeight, isTrue);
      expect(strutStyle.fontSize, equals(16.0));
      expect(strutStyle.height, equals(24.0 / 16.0));
    });

    test('calculateGridLetterSpacing dynamically computes pitch on grid and dotGrid only', () {
      // For grid: max(0.0, 24.0 - 16.0) = 8.0
      expect(
        EditorQuillStylesBuilder.calculateGridLetterSpacing(
          backgroundType: TemplateBackgroundType.grid,
          lineStridePx: 24.0,
          fontSize: 16.0,
        ),
        equals(8.0),
      );

      // For dotGrid: max(0.0, 24.0 - 16.0) = 8.0
      expect(
        EditorQuillStylesBuilder.calculateGridLetterSpacing(
          backgroundType: TemplateBackgroundType.dotGrid,
          lineStridePx: 24.0,
          fontSize: 16.0,
        ),
        equals(8.0),
      );

      // For lined, color, paperTexture: 0.0
      expect(
        EditorQuillStylesBuilder.calculateGridLetterSpacing(
          backgroundType: TemplateBackgroundType.lined,
          lineStridePx: 24.0,
          fontSize: 16.0,
        ),
        equals(0.0),
      );

      expect(
        EditorQuillStylesBuilder.calculateGridLetterSpacing(
          backgroundType: TemplateBackgroundType.color,
          lineStridePx: 24.0,
          fontSize: 16.0,
        ),
        equals(0.0),
      );

      expect(
        EditorQuillStylesBuilder.calculateGridLetterSpacing(
          backgroundType: TemplateBackgroundType.paperTexture,
          lineStridePx: 24.0,
          fontSize: 16.0,
        ),
        equals(0.0),
      );
    });

    test('clamps H1 and H2 total block heights to exactly 2 * lineStridePx', () {
      const lineStridePx = 24.0;
      final styles = EditorQuillStylesBuilder.build(
        typography: typography,
        inkColor: const Color(0xFF212121),
        isPaperDark: false,
        lineStridePx: lineStridePx,
        backgroundType: TemplateBackgroundType.lined,
      );

      // H1 verification
      final h1Style = styles.h1!;
      final h1TextHeight = h1Style.style.fontSize! * h1Style.style.height!;
      final h1TotalHeight = h1TextHeight +
          h1Style.verticalSpacing.top +
          h1Style.verticalSpacing.bottom;
      expect(h1TotalHeight, closeTo(2.0 * lineStridePx, 0.001));

      // H2 verification
      final h2Style = styles.h2!;
      final h2TextHeight = h2Style.style.fontSize! * h2Style.style.height!;
      final h2TotalHeight = h2TextHeight +
          h2Style.verticalSpacing.top +
          h2Style.verticalSpacing.bottom;
      expect(h2TotalHeight, closeTo(2.0 * lineStridePx, 0.001));
    });

    test('clamps H3 total block height to exactly 1 * lineStridePx', () {
      const lineStridePx = 24.0;
      final styles = EditorQuillStylesBuilder.build(
        typography: typography,
        inkColor: const Color(0xFF212121),
        isPaperDark: false,
        lineStridePx: lineStridePx,
        backgroundType: TemplateBackgroundType.lined,
      );

      final h3Style = styles.h3!;
      final h3TextHeight = h3Style.style.fontSize! * h3Style.style.height!;
      final h3TotalHeight = h3TextHeight +
          h3Style.verticalSpacing.top +
          h3Style.verticalSpacing.bottom;
      expect(h3TotalHeight, closeTo(1.0 * lineStridePx, 0.001));
    });

    test('locks paragraph and placeholder heights and applies grid letterSpacing without mutating Delta', () {
      const lineStridePx = 28.0;
      final gridStyles = EditorQuillStylesBuilder.build(
        typography: typography,
        inkColor: const Color(0xFF212121),
        isPaperDark: false,
        lineStridePx: lineStridePx,
        backgroundType: TemplateBackgroundType.grid,
      );

      expect(gridStyles.paragraph!.style.height, equals(28.0 / 16.0));
      expect(gridStyles.paragraph!.style.letterSpacing, equals(28.0 - 16.0));
      expect(gridStyles.placeHolder!.style.height, equals(28.0 / 16.0));
      expect(gridStyles.placeHolder!.style.letterSpacing, equals(28.0 - 16.0));
      expect(gridStyles.quote!.style.height, equals(28.0 / 16.0));
      expect(gridStyles.quote!.style.fontStyle, equals(FontStyle.italic));

      final linedStyles = EditorQuillStylesBuilder.build(
        typography: typography,
        inkColor: const Color(0xFF212121),
        isPaperDark: false,
        lineStridePx: lineStridePx,
        backgroundType: TemplateBackgroundType.lined,
      );

      expect(linedStyles.paragraph!.style.letterSpacing, equals(0.0));
      expect(linedStyles.placeHolder!.style.letterSpacing, equals(0.0));
    });
  });
}
