import 'package:flutter/material.dart';
import '../ink_diary_theme.dart';
import '../shapes/classical_chinese_borders.dart';

/// Imperial Begonia Cut-Corner Plaque Button (海棠切角题签钮)
///
/// An ornate plaque widget featuring chamfered cut corners, subtle dual hairline borders,
/// and smooth paper relief shadows, styled after classic literati book slips and signage.
class BegoniaPlaqueButton extends StatelessWidget {
  final String label;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double cutSize;
  final EdgeInsetsGeometry padding;
  final bool isAccent;
  final Color? backgroundColor;
  final Color? textColor;

  const BegoniaPlaqueButton({
    super.key,
    required this.label,
    this.leading,
    this.trailing,
    this.onTap,
    this.cutSize = 6.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.isAccent = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isAccent
        ? tokens.cinnabarDark
        : (isDark ? tokens.deckleBorder : const Color(0xFFB89B72));

    final innerBorderColor = isAccent
        ? Colors.white.withValues(alpha: 0.3)
        : (isDark
            ? tokens.qingmo.withValues(alpha: 0.3)
            : const Color(0xFFB83B2E).withValues(alpha: 0.28));

    final defaultLightGradient = isAccent
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFBA372A), Color(0xFF98261B)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFAF6EC), Color(0xFFEAE0CC)],
          );

    final defaultDarkGradient = isAccent
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF98261B), Color(0xFF6E180F)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2B2824), Color(0xFF1E1C19)],
          );

    final gradient = isDark ? defaultDarkGradient : defaultLightGradient;

    final border = BegoniaPlaqueBorder(
      cutSize: cutSize,
      borderColor: borderColor,
      borderWidth: 1.0,
      innerBorderInset: 2.0,
      innerBorderColor: innerBorderColor,
      innerBorderWidth: 1.0,
    );

    final effectiveTextColor = textColor ??
        (isAccent
            ? Colors.white
            : (isDark ? tokens.jiaomo : const Color(0xFF8F2419)));

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: effectiveTextColor,
            letterSpacing: 0.4,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 3),
          trailing!,
        ],
      ],
    );

    return Container(
      decoration: ShapeDecoration(
        shape: border,
        gradient: backgroundColor == null ? gradient : null,
        color: backgroundColor,
        shadows: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF2A2216).withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: border,
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: content,
          ),
        ),
      ),
    );
  }
}
