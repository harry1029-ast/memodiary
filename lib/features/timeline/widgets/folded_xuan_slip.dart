import 'package:flutter/material.dart';

/// Color tokens for the folded Xuan-paper slip (*折笺影札*) surface.
@immutable
class FoldedXuanSlipPalette {
  final Color cardColor;
  final Color lipColor;
  final Color borderColor;
  final Color vermilionRuleColor;
  final Color innerFrameColor;
  final Color dividerColor;
  final Color shadowColor;

  const FoldedXuanSlipPalette({
    required this.cardColor,
    required this.lipColor,
    required this.borderColor,
    required this.vermilionRuleColor,
    required this.innerFrameColor,
    required this.dividerColor,
    required this.shadowColor,
  });

  /// Dark theme ("碑拓乌木" — Stone Rubbing & Ebony) palette.
  static final FoldedXuanSlipPalette dark = FoldedXuanSlipPalette(
    cardColor: const Color(0xFF242320),
    lipColor: const Color(0xFF36332D),
    borderColor: const Color(0xFF3D3A34),
    vermilionRuleColor: const Color(0xFFD25447).withValues(alpha: 0.065),
    innerFrameColor: const Color(0xFFC8A96E).withValues(alpha: 0.11),
    dividerColor: const Color(0xFFC8A96E).withValues(alpha: 0.16),
    shadowColor: Colors.black.withValues(alpha: 0.32),
  );

  /// Light theme ("宣纸胡桃" — Xuan Paper & Walnut) palette.
  static final FoldedXuanSlipPalette light = FoldedXuanSlipPalette(
    cardColor: const Color(0xFFFAF6EE),
    lipColor: const Color(0xFFD4C7B0),
    borderColor: const Color(0xFFC9B99E),
    vermilionRuleColor: const Color(0xFFB84335).withValues(alpha: 0.08),
    innerFrameColor: const Color(0xFF9A7432).withValues(alpha: 0.14),
    dividerColor: const Color(0xFF9A7432).withValues(alpha: 0.18),
    shadowColor: Colors.black.withValues(alpha: 0.09),
  );

  /// Resolves the palette matching the active [ThemeData.brightness].
  static FoldedXuanSlipPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dark : light;
  }
}

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
    final palette = FoldedXuanSlipPalette.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: palette.borderColor, width: 1.0),
    );

    Widget slipContent = CustomPaint(
      painter: _FoldedXuanSlipPainter(
        vermilionRuleColor: palette.vermilionRuleColor,
        innerFrameColor: palette.innerFrameColor,
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
        color: palette.lipColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: palette.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: palette.cardColor,
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
