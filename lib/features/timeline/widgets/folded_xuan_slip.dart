import 'package:flutter/material.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';

/// Folded Xuan-paper slip (*折笺影札*) card container.
///
/// Renders faint vertical vermilion ruling lines (`28dp` stride), a `3dp`
/// stacked-paper bottom edge lip, and an inner hairline frame across both
/// Dark (`碑拓乌木`) and Light (`宣纸胡桃`) themes.
class FoldedXuanSlip extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const FoldedXuanSlip({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 11.0,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: palette.deckleBorder, width: 1.0),
    );

    Widget slipContent = CustomPaint(
      painter: _FoldedXuanSlipPainter(
        vermilionRuleColor: palette.slipRuleColor,
        innerFrameColor: palette.slipInnerFrameColor,
        borderRadius: borderRadius,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null || onLongPress != null) {
      slipContent = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(borderRadius),
        child: slipContent,
      );
    }

    return Container(
      margin: margin,
      padding: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: palette.cardStackLip,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: palette.slipShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: palette.cardPaper,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: slipContent,
      ),
    );
  }
}

class _FoldedXuanSlipPainter extends CustomPainter {
  static const double _ruleStride = 28.0;
  static const double _innerInset = 4.0;

  final Color vermilionRuleColor;
  final Color innerFrameColor;
  final double borderRadius;

  const _FoldedXuanSlipPainter({
    required this.vermilionRuleColor,
    required this.innerFrameColor,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rulePaint = Paint()
      ..color = vermilionRuleColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double x = _ruleStride; x < size.width; x += _ruleStride) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), rulePaint);
    }

    if (size.width > _innerInset * 2 && size.height > _innerInset * 2) {
      final innerRect = Rect.fromLTWH(
        _innerInset,
        _innerInset,
        size.width - _innerInset * 2,
        size.height - _innerInset * 2,
      );
      final innerRadius = Radius.circular(
        borderRadius > _innerInset ? borderRadius - _innerInset : 2.0,
      );
      final framePaint = Paint()
        ..color = innerFrameColor
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(RRect.fromRectAndRadius(innerRect, innerRadius), framePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FoldedXuanSlipPainter oldDelegate) =>
      oldDelegate.vermilionRuleColor != vermilionRuleColor ||
      oldDelegate.innerFrameColor != innerFrameColor ||
      oldDelegate.borderRadius != borderRadius;
}
