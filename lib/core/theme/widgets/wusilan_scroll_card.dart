import 'package:flutter/material.dart';
import '../ink_diary_theme.dart';

/// Wusilan Scroll Card Container (乌丝栏水墨画笺容器)
///
/// An authentic Chinese calligraphic paper container featuring:
/// - Multi-stop aged Xuan paper gradient wash
/// - Double-hairline "Wusilan" (乌丝栏) framing
/// - Corner cloud Ruyi bracket fretwork
/// - Optional top retractable toggle to collapse into a slim status tab.
class WusilanScrollCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final bool canCollapse;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final String collapsedLabel;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const WusilanScrollCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    this.borderRadius = 10.0,
    this.canCollapse = false,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.collapsedLabel = '✦ 灵感火花 · 展开',
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final outerBorderColor = isDark
        ? tokens.deckleBorder
        : const Color(0xFFC4B59B);

    final innerBorderColor = isDark
        ? tokens.qingmo.withValues(alpha: 0.25)
        : const Color(0xFF8A7B62).withValues(alpha: 0.28);

    final defaultLightGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFBF8F0),
        Color(0xFFF0E9DA),
      ],
    );

    final defaultDarkGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF282521),
        Color(0xFF1D1B18),
      ],
    );

    final gradient = isDark ? defaultDarkGradient : defaultLightGradient;

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : const Color(0xFF1C1914).withValues(alpha: 0.08);

    Widget cardBody;

    if (canCollapse && isCollapsed) {
      cardBody = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onToggleCollapse,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  collapsedLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? tokens.qingmo : tokens.cinnabar,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isDark ? tokens.qingmo : tokens.cinnabar,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      cardBody = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canCollapse)
            Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: onToggleCollapse,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? tokens.agedFiber.withValues(alpha: 0.5)
                          : const Color(0xFFE5DBC7).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 16,
                      color: isDark ? tokens.danmo : const Color(0xFF8F2419),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: backgroundColor == null ? gradient : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: outerBorderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Inner Wusilan Hairline Border with Corner Ruyi Accents
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _WusilanCornerPainter(
                  innerBorderColor: innerBorderColor,
                  borderRadius: borderRadius,
                  inset: 3.5,
                ),
              ),
            ),
          ),
          cardBody,
        ],
      ),
    );
  }
}

class _WusilanCornerPainter extends CustomPainter {
  final Color innerBorderColor;
  final double borderRadius;
  final double inset;

  const _WusilanCornerPainter({
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

    // Corner Ruyi Fret Accents (corner L-brackets)
    final fretPaint = Paint()
      ..color = innerBorderColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const fretLen = 6.0;

    // Top-Left
    canvas.drawLine(Offset(rect.left + 4, rect.top + 4), Offset(rect.left + 4 + fretLen, rect.top + 4), fretPaint);
    canvas.drawLine(Offset(rect.left + 4, rect.top + 4), Offset(rect.left + 4, rect.top + 4 + fretLen), fretPaint);

    // Top-Right
    canvas.drawLine(Offset(rect.right - 4, rect.top + 4), Offset(rect.right - 4 - fretLen, rect.top + 4), fretPaint);
    canvas.drawLine(Offset(rect.right - 4, rect.top + 4), Offset(rect.right - 4, rect.top + 4 + fretLen), fretPaint);

    // Bottom-Left
    canvas.drawLine(Offset(rect.left + 4, rect.bottom - 4), Offset(rect.left + 4 + fretLen, rect.bottom - 4), fretPaint);
    canvas.drawLine(Offset(rect.left + 4, rect.bottom - 4), Offset(rect.left + 4, rect.bottom - 4 - fretLen), fretPaint);

    // Bottom-Right
    canvas.drawLine(Offset(rect.right - 4, rect.bottom - 4), Offset(rect.right - 4 - fretLen, rect.bottom - 4), fretPaint);
    canvas.drawLine(Offset(rect.right - 4, rect.bottom - 4), Offset(rect.right - 4, rect.bottom - 4 - fretLen), fretPaint);
  }

  @override
  bool shouldRepaint(covariant _WusilanCornerPainter oldDelegate) =>
      oldDelegate.innerBorderColor != innerBorderColor ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.inset != inset;
}

