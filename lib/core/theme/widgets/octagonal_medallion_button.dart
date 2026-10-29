import 'package:flutter/material.dart';
import '../ink_diary_theme.dart';
import '../shapes/classical_chinese_borders.dart';

/// Octagonal Bronze/Jade Medallion Action Button (八角青玉古铜罗盘钮)
///
/// An ornate, non-rectangular action button modeled after traditional Chinese
/// bronze compass medallions and carved jade seal amulets.
class OctagonalMedallionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final bool hasIndicator;
  final Color? indicatorColor;

  const OctagonalMedallionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 38.0,
    this.iconSize = 18.0,
    this.iconColor,
    this.hasIndicator = false,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDark ? tokens.deckleBorder : const Color(0xFFB5A486);
    final bevelColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.75);

    final border = OctagonalMedallionBorder(
      chamferRatio: 0.28,
      borderColor: borderColor,
      borderWidth: 1.0,
      bevelHighlightColor: bevelColor,
    );

    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C2A26), Color(0xFF1F1D1A)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF9F5EB), Color(0xFFE6DCC8)],
          );

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : const Color(0xFF2A2216).withValues(alpha: 0.12);

    final effectiveIconColor = iconColor ?? tokens.jiaomo;

    Widget buttonBody = Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: effectiveIconColor,
        ),
        if (hasIndicator)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: indicatorColor ?? tokens.cinnabar,
              ),
            ),
          ),
      ],
    );

    Widget interactive = Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        shape: border,
        gradient: gradient,
        shadows: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: border,
          onTap: onPressed,
          child: Center(child: buttonBody),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      interactive = Tooltip(
        message: tooltip!,
        child: interactive,
      );
    }

    return Semantics(
      button: true,
      label: tooltip,
      child: interactive,
    );
  }
}
