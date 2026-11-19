import 'package:flutter/material.dart';
import '../atmosphere_palette.dart';
import '../ink_diary_theme.dart';
import '../shapes/classical_chinese_borders.dart';
import 'min_tap_target.dart';

/// Imperial Begonia Cut-Corner Plaque Button (海棠切角题签钮)
///
/// An ornate plaque widget featuring chamfered cut corners, subtle dual hairline borders,
/// and smooth paper relief shadows, styled after classic literati book slips and signage.
class BegoniaPlaqueButton extends StatelessWidget {
  final String label;
  final String? semanticLabel;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double cutSize;
  final EdgeInsetsGeometry padding;
  final bool isAccent;
  final bool ensureMinTapTarget;
  final Color? backgroundColor;
  final Color? textColor;

  const BegoniaPlaqueButton({
    super.key,
    required this.label,
    this.semanticLabel,
    this.leading,
    this.trailing,
    this.onTap,
    this.cutSize = 6.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.isAccent = false,
    this.ensureMinTapTarget = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final palette = context.atmospherePalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isAccent ? palette.tallyFeaturedBorder : tokens.deckleBorder;

    final innerBorderColor = isAccent
        ? palette.tallyFeaturedText.withValues(alpha: 0.3)
        : (isDark
            ? tokens.qingmo.withValues(alpha: 0.3)
            : tokens.cinnabar.withValues(alpha: 0.25));

    final gradient = isAccent
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.tallyFeaturedTop, palette.tallyFeaturedBottom],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [tokens.xuanPureLeaf, tokens.agedFiber],
          );

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
            ? palette.tallyFeaturedText
            : (isDark ? tokens.jiaomo : tokens.cinnabarDark));

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: effectiveTextColor,
              letterSpacing: 0.4,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 3),
          trailing!,
        ],
      ],
    );

    final decoration = ShapeDecoration(
      shape: border,
      gradient: backgroundColor == null ? gradient : null,
      color: backgroundColor,
      shadows: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.35)
              : tokens.jiaomo.withValues(alpha: 0.08),
          blurRadius: 4,
          offset: const Offset(0, 1.5),
        ),
      ],
    );

    if (ensureMinTapTarget) {
      return MinTapTarget(
        semanticLabel: semanticLabel ?? label,
        excludeChildSemantics: true,
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: decoration,
          padding: padding,
          child: content,
        ),
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: ExcludeSemantics(
        child: Container(
          decoration: decoration,
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
        ),
      ),
    );
  }
}
