import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../templates/models/template_style.dart';
import '../models/typography_settings.dart';

/// Pure styles builder for [QuillEditor] that locks paragraph and quote lines
/// to ruled stationery baselines via explicit height scaling and [StrutStyle],
/// clamps headings strictly to integer multiples of [lineStridePx], and
/// dynamically calculates grid letter-spacing without mutating document Delta.
class EditorQuillStylesBuilder {
  const EditorQuillStylesBuilder._();

  /// Builds a [StrutStyle] that forces line boxes to strictly match [lineStridePx].
  static StrutStyle buildStrutStyle({
    required double fontSize,
    required double lineStridePx,
  }) {
    final lineHeightMultiplier = lineStridePx / fontSize;
    return StrutStyle(
      fontSize: fontSize,
      height: lineHeightMultiplier,
      forceStrutHeight: true,
    );
  }

  /// Calculates dynamic horizontal letter-spacing to center CJK characters
  /// inside square cells on orthogonal grid and dot-grid templates.
  static double calculateGridLetterSpacing({
    required TemplateBackgroundType backgroundType,
    required double lineStridePx,
    required double fontSize,
  }) {
    final isGridPattern = backgroundType == TemplateBackgroundType.grid ||
        backgroundType == TemplateBackgroundType.dotGrid;
    return isGridPattern ? math.max(0.0, lineStridePx - fontSize) : 0.0;
  }

  /// Builds [DefaultStyles] with locked baselines and integer-clamped headings.
  static DefaultStyles build({
    required TypographySettings typography,
    required Color inkColor,
    required bool isPaperDark,
    required double lineStridePx,
    required TemplateBackgroundType backgroundType,
  }) {
    final fontSize = typography.fontSize;
    final lineHeightMultiplier = lineStridePx / fontSize;
    final dynamicLetterSpacing = calculateGridLetterSpacing(
      backgroundType: backgroundType,
      lineStridePx: lineStridePx,
      fontSize: fontSize,
    );

    final baseStyle = typography.toTextStyle(color: inkColor);

    // Paragraph style: locks height to lineStridePx, applies dynamic letter spacing on grids
    final paragraphTextStyle = baseStyle.copyWith(
      height: lineHeightMultiplier,
      letterSpacing: dynamicLetterSpacing,
    );

    // Placeholder style: identical baseline metrics, lower contrast ink
    final placeholderColor =
        isPaperDark ? const Color(0xFFA69F93) : const Color(0x7F212121);
    final placeholderTextStyle = typography.toTextStyle(color: placeholderColor).copyWith(
      height: lineHeightMultiplier,
      letterSpacing: dynamicLetterSpacing,
    );

    // Quote style: italicized, tinted, locked to lineStridePx
    final quoteColor =
        isPaperDark ? const Color(0xFFDCD6CA) : const Color(0xFF424242);
    final quoteTextStyle = baseStyle.copyWith(
      fontStyle: FontStyle.italic,
      color: quoteColor,
      height: lineHeightMultiplier,
    );

    // Integer-Row Heading Clamping
    // H1: clamped to exactly 2 * lineStridePx total height
    const h1FontSize = 22.0;
    const h1DesignHeight = 1.2;
    final h1TextHeight = math.min(h1FontSize * h1DesignHeight, 2.0 * lineStridePx);
    final h1Padding = math.max(0.0, (2.0 * lineStridePx - h1TextHeight) / 2.0);
    final h1TextStyle = baseStyle.copyWith(
      fontSize: h1FontSize,
      height: h1TextHeight / h1FontSize,
      fontWeight: FontWeight.bold,
      color: isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF1E1E1E),
    );

    // H2: clamped to exactly 2 * lineStridePx total height
    const h2FontSize = 18.0;
    const h2DesignHeight = 1.2;
    final h2TextHeight = math.min(h2FontSize * h2DesignHeight, 2.0 * lineStridePx);
    final h2Padding = math.max(0.0, (2.0 * lineStridePx - h2TextHeight) / 2.0);
    final h2TextStyle = baseStyle.copyWith(
      fontSize: h2FontSize,
      height: h2TextHeight / h2FontSize,
      fontWeight: FontWeight.bold,
      color: isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF1E1E1E),
    );

    // H3: clamped to exactly 1 * lineStridePx total height
    const h3FontSize = 16.0;
    const h3DesignHeight = 1.15;
    final h3TextHeight = math.min(h3FontSize * h3DesignHeight, lineStridePx);
    final h3Padding = math.max(0.0, (lineStridePx - h3TextHeight) / 2.0);
    final h3TextStyle = baseStyle.copyWith(
      fontSize: h3FontSize,
      height: h3TextHeight / h3FontSize,
      fontWeight: FontWeight.bold,
      color: isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF1E1E1E),
    );

    return DefaultStyles(
      placeHolder: DefaultTextBlockStyle(
        placeholderTextStyle,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      paragraph: DefaultTextBlockStyle(
        paragraphTextStyle,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      h1: DefaultTextBlockStyle(
        h1TextStyle,
        const HorizontalSpacing(0, 0),
        VerticalSpacing(h1Padding, h1Padding),
        const VerticalSpacing(0, 0),
        null,
      ),
      h2: DefaultTextBlockStyle(
        h2TextStyle,
        const HorizontalSpacing(0, 0),
        VerticalSpacing(h2Padding, h2Padding),
        const VerticalSpacing(0, 0),
        null,
      ),
      h3: DefaultTextBlockStyle(
        h3TextStyle,
        const HorizontalSpacing(0, 0),
        VerticalSpacing(h3Padding, h3Padding),
        const VerticalSpacing(0, 0),
        null,
      ),
      quote: DefaultTextBlockStyle(
        quoteTextStyle,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
    );
  }
}
