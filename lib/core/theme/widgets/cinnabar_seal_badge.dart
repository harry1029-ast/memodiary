import 'package:flutter/material.dart';
import '../ink_diary_theme.dart';

/// Form factor for classical seal stamp
enum SealShape {
  square,
  roundedSquare,
  circle,
}

/// Vermilion Cinnabar Seal Badge (*Yinzhang*, 印章)
/// Embodies the decisive focal punctum of Chinese calligraphy seals.
class CinnabarSealBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final SealShape shape;
  final double size;
  final bool isRotated;
  final double rotationAngle; // Radians
  final bool isWashVariant; // Subtle background wash vs deep vermilion stone
  final VoidCallback? onTap;

  const CinnabarSealBadge({
    super.key,
    required this.text,
    this.icon,
    SealShape? shape,
    bool? isRound,
    this.size = 44.0,
    this.isRotated = true,
    this.rotationAngle = 0.035, // ~2 degrees organic tilt
    this.isWashVariant = false,
    this.onTap,
  }) : shape = shape ?? (isRound == true ? SealShape.circle : SealShape.roundedSquare);

  /// Compact seal stamp for list items and card headers
  const CinnabarSealBadge.compact({
    super.key,
    required this.text,
    this.icon,
    SealShape? shape,
    bool? isRound,
    this.size = 28.0,
    this.isRotated = false,
    this.rotationAngle = 0.0,
    this.isWashVariant = false,
    this.onTap,
  }) : shape = shape ?? (isRound == true ? SealShape.circle : SealShape.roundedSquare);

  /// Soft wash variant for secondary category badges
  const CinnabarSealBadge.wash({
    super.key,
    required this.text,
    this.icon,
    SealShape? shape,
    bool? isRound,
    this.size = 32.0,
    this.isRotated = false,
    this.rotationAngle = 0.0,
    this.isWashVariant = true,
    this.onTap,
  }) : shape = shape ?? (isRound == true ? SealShape.circle : SealShape.roundedSquare);

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final bgColor = isWashVariant ? tokens.cinnabarWash : tokens.cinnabar;
    final fgColor = isWashVariant ? tokens.cinnabar : Colors.white;
    final borderColor = isWashVariant ? tokens.cinnabar.withValues(alpha: 0.4) : tokens.cinnabarDark;

    BorderRadius borderRadius;
    switch (shape) {
      case SealShape.circle:
        borderRadius = BorderRadius.circular(size / 2);
        break;
      case SealShape.square:
        borderRadius = BorderRadius.circular(2.0);
        break;
      case SealShape.roundedSquare:
        borderRadius = BorderRadius.circular(6.0);
        break;
    }

    Widget content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: isWashVariant
            ? null
            : [
                BoxShadow(
                  color: tokens.cinnabar.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: size * 0.52, color: fgColor)
            : Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: size <= 30 ? 10 : 12,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: -0.5,
                  color: fgColor,
                ),
              ),
      ),
    );

    if (isRotated && rotationAngle != 0.0) {
      content = Transform.rotate(
        angle: rotationAngle,
        child: content,
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
