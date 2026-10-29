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
  final Gradient? gradient;
  final bool hasWusilanBorder;
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
    this.gradient,
    this.hasWusilanBorder = false,
    this.onTap,
    this.onLongPress,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final bg = backgroundColor ?? tokens.xuanPureLeaf;
    final border = borderColor ?? tokens.deckleBorder;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final innerBorderColor = isDark
        ? tokens.qingmo.withValues(alpha: 0.22)
        : const Color(0xFF8A7B62).withValues(alpha: 0.25);

    Widget innerContent = Material(
      type: MaterialType.transparency,
      child: child,
    );

    if (hasWusilanBorder) {
      innerContent = Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _XuanCardWusilanPainter(
                  innerBorderColor: innerBorderColor,
                  borderRadius: borderRadius,
                  inset: 3.5,
                ),
              ),
            ),
          ),
          innerContent,
        ],
      );
    }

    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? bg : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: 1.0),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: tokens.jiaomo.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: tokens.jiaomo.withValues(alpha: isDark ? 0.15 : 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: innerContent,
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

class _XuanCardWusilanPainter extends CustomPainter {
  final Color innerBorderColor;
  final double borderRadius;
  final double inset;

  const _XuanCardWusilanPainter({
    required this.innerBorderColor,
    required this.borderRadius,
    required this.inset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= inset * 2 || size.height <= inset * 2) return;

    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );

    final innerRadius = Radius.circular(borderRadius > inset ? borderRadius - inset : 2.0);
    final rrect = RRect.fromRectAndRadius(rect, innerRadius);

    final linePaint = Paint()
      ..color = innerBorderColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rrect, linePaint);
  }

  @override
  bool shouldRepaint(covariant _XuanCardWusilanPainter oldDelegate) =>
      oldDelegate.innerBorderColor != innerBorderColor ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.inset != inset;
}


