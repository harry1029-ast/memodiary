import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../../templates/models/template_style.dart';
import '../../services/vertical_typography_mapper.dart';

/// Renders a single vertical calligraphy column bounded by silk rule tints (朱丝栏/乌丝栏).
/// Faithfully lays out classical CJK vertical glyphs, ideographic corner stops,
/// rotated horizontal fallback punctuation, and dual-subcolumn Interlinear Sub-Notes (双行夹注).
class KeepsakeColumn extends StatelessWidget {
  final List<VerticalRenderToken> tokens;
  final RuleInkTint ruleTint;
  final Color inkColor;
  final String fontFamily;
  final double fontSize;
  final double columnWidth;
  final bool isTitle;
  final bool isHeader;
  final bool isQuote;

  const KeepsakeColumn({
    super.key,
    required this.tokens,
    this.ruleTint = RuleInkTint.vermilion,
    required this.inkColor,
    this.fontFamily = InkDiaryTheme.fontKaiti,
    this.fontSize = 17.0,
    this.columnWidth = 36.0,
    this.isTitle = false,
    this.isHeader = false,
    this.isQuote = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFontSize = isTitle
        ? fontSize * 1.3
        : (isHeader ? fontSize * 1.15 : (isQuote ? fontSize * 0.95 : fontSize));

    final ruleColor = ruleTint.color.withValues(
      alpha: ruleTint == RuleInkTint.charcoal ? 0.20 : 0.35,
    );

    return Semantics(
      container: true,
      label: _buildSemanticsLabel(),
      child: Container(
        width: columnWidth,
        margin: const EdgeInsets.symmetric(horizontal: 2.0),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: ruleColor, width: 0.6),
            left: BorderSide(color: ruleColor, width: 0.6),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          mainAxisAlignment: isTitle ? MainAxisAlignment.center : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: tokens
              .map((token) => _buildTokenCell(token, effectiveFontSize))
              .toList(),
        ),
      ),
    );
  }

  String _buildSemanticsLabel() {
    final buffer = StringBuffer();
    for (final token in tokens) {
      if (token is VerticalGlyphToken) {
        buffer.write(token.glyph);
      } else if (token is VerticalInterlinearPairToken) {
        buffer.write(token.rightChar);
        buffer.write(token.leftChar);
      }
    }
    return buffer.toString();
  }

  Widget _buildTokenCell(VerticalRenderToken token, double baseSize) {
    if (token is VerticalInterlinearPairToken) {
      return _buildInterlinearPairCell(token, baseSize);
    }
    if (token is VerticalGlyphToken) {
      return _buildGlyphCell(token, baseSize);
    }
    return const SizedBox.shrink();
  }

  Widget _buildInterlinearPairCell(
    VerticalInterlinearPairToken token,
    double baseSize,
  ) {
    final noteFontSize = (baseSize * 0.56).clamp(9.0, 14.0);
    // Adapts to both light substrates and Obsidian Night (where inkColor is 0xFFF0ECE3)
    final secondaryInk = inkColor.withValues(alpha: 0.75);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              token.rightChar,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: noteFontSize,
                color: secondaryInk,
                height: 1.0,
              ),
            ),
          ),
          Expanded(
            child: Text(
              token.leftChar,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: noteFontSize,
                color: secondaryInk,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlyphCell(VerticalGlyphToken token, double baseSize) {
    final glyph = token.glyph;
    if (glyph == ' ' || glyph == '\u3000') {
      return SizedBox(height: baseSize * 0.8);
    }

    final textColor = isQuote ? inkColor.withValues(alpha: 0.8) : inkColor;
    final textStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: baseSize,
      color: textColor,
      fontWeight: (isTitle || isHeader) ? FontWeight.bold : FontWeight.normal,
      fontStyle: isQuote ? FontStyle.italic : FontStyle.normal,
      height: 1.0,
    );

    // 1. Ideographic corner stops (。，、) aligned to upper-right quadrant
    if (token.isCornerPunctuation) {
      return Container(
        height: baseSize,
        alignment: const Alignment(0.45, -0.45),
        child: Text(
          glyph,
          style: textStyle,
        ),
      );
    }

    // 2. Rotated horizontal fallback punctuation or Latin word runs
    if (token.requiresQuarterTurnRotation) {
      final isMultiChar = glyph.length > 1;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: isMultiChar
            ? RotatedBox(
                quarterTurns: 1,
                child: Text(
                  glyph,
                  style: textStyle.copyWith(
                    fontSize: baseSize * 0.9,
                    fontWeight: (isTitle || isHeader) ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              )
            : Transform.rotate(
                angle: math.pi / 2,
                child: Text(
                  glyph,
                  style: textStyle,
                ),
              ),
      );
    }

    // 3. Regular CJK glyph or mapped vertical presentation glyph
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTitle ? 3.0 : 1.5),
      child: Text(
        glyph,
        style: textStyle,
      ),
    );
  }
}
