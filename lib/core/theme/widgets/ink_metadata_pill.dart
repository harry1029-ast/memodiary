import 'package:flutter/material.dart';
import '../ink_diary_theme.dart';

/// Horizontal metadata capsule chip with deckle border and literati typography.
/// Enforces text-scale clamping (max <= 1.3) and width bounds per CODING_STANDARDS.md.
class InkMetadataPill extends StatelessWidget {
  final String label;
  final Widget? leading;
  final Widget? trailing;
  final IconData? icon;
  final String? emoji;
  final bool isAccent;
  final String? semanticLabel;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final String? deleteSemanticLabel;
  final bool isSelected;
  final double maxWidth;

  const InkMetadataPill({
    super.key,
    required this.label,
    this.leading,
    this.trailing,
    this.icon,
    this.emoji,
    this.isAccent = false,
    this.semanticLabel,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.onTap,
    this.onDeleted,
    this.deleteSemanticLabel,
    this.isSelected = false,
    this.maxWidth = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;

    Color bg;
    Color fg;
    Color border;

    if (isSelected || isAccent) {
      bg = tokens.cinnabarWash;
      fg = tokens.cinnabar;
      border = tokens.cinnabar.withValues(alpha: 0.5);
    } else {
      bg = backgroundColor ?? tokens.xuanPureLeaf;
      fg = textColor ?? tokens.nongmo;
      border = borderColor ?? tokens.deckleBorder;
    }

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null) {
      if (icon != null) {
        effectiveLeading = Icon(icon, size: 14, color: fg);
      } else if (emoji != null) {
        effectiveLeading = Text(emoji!, style: const TextStyle(fontSize: 13));
      }
    }

    final mediaQuery = MediaQuery.of(context);
    final clampedMediaQuery = mediaQuery.copyWith(
      textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.3),
    );

    Widget pill = MediaQuery(
      data: clampedMediaQuery,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: tokens.jiaomo.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (effectiveLeading != null) ...[
              effectiveLeading,
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 12,
                  fontWeight: (isSelected || isAccent) ? FontWeight.w600 : FontWeight.w400,
                  color: fg,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onDeleted != null) ...[
              const SizedBox(width: 4),
              Semantics(
                button: true,
                label: deleteSemanticLabel ?? 'Remove $label filter',
                child: GestureDetector(
                  onTap: onDeleted,
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: fg.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ] else if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing!,
            ],
          ],
        ),
      ),
    );

    if (semanticLabel != null) {
      pill = Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: pill,
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: pill,
      );
    }

    return pill;
  }
}
