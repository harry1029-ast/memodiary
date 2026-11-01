import 'package:flutter/material.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../../templates/models/template_style.dart';

/// Renders a single vertical calligraphy column bounded by silk rule tints (朱丝栏/乌丝栏).
class KeepsakeColumn extends StatelessWidget {
  final List<String> tokens;
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
      label: tokens.join(),
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
          children: tokens.map((token) => _buildTokenCell(token, effectiveFontSize)).toList(),
        ),
      ),
    );
  }

  Widget _buildTokenCell(String token, double size) {
    if (token == ' ' || token == '\u3000') {
      return SizedBox(height: size * 0.8);
    }

    // Preserve alphanumeric words by turning them 90 degrees along the vertical stride
    final isAlphanumericWord = token.length > 2 && RegExp(r'^[a-zA-Z0-9_\-.]+$').hasMatch(token);

    if (isAlphanumericWord) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: RotatedBox(
          quarterTurns: 1,
          child: Text(
            token,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: size * 0.9,
              color: isQuote ? inkColor.withValues(alpha: 0.8) : inkColor,
              fontWeight: (isTitle || isHeader) ? FontWeight.bold : FontWeight.w500,
              fontStyle: isQuote ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTitle ? 3.0 : 1.5),
      child: Text(
        token,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          color: isQuote ? inkColor.withValues(alpha: 0.8) : inkColor,
          fontWeight: (isTitle || isHeader) ? FontWeight.bold : FontWeight.normal,
          fontStyle: isQuote ? FontStyle.italic : FontStyle.normal,
          height: 1.0,
        ),
      ),
    );
  }
}
