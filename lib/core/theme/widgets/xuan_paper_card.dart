import 'package:flutter/material.dart';
import '../ink_diary_theme.dart';

/// Tactile Xuan paper slip card with authentic deckle border and diffused ambient paper shadow.
class XuanPaperCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool hasShadow;

  const XuanPaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.onLongPress,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final bg = backgroundColor ?? tokens.xuanPureLeaf;
    final border = borderColor ?? tokens.deckleBorder;

    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: 1.0),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: tokens.jiaomo.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: tokens.jiaomo.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );

    if (onTap != null || onLongPress != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(borderRadius),
            child: cardContent,
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      child: cardContent,
    );
  }
}

