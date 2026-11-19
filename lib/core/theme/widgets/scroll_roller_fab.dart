import 'package:flutter/material.dart';
import '../atmosphere_palette.dart';
import '../shapes/classical_chinese_borders.dart';

/// Imperial Scroll-Roller Floating Action Button (卷轴横匾按钮)
///
/// An ornate floating action button inspired by traditional Chinese handscrolls,
/// resolving all gradient, border, rail, knob, and text tokens from [AtmospherePalette].
/// Supports dynamic roll-up physics:
/// - Unfurled (展开态, 178px wide): displays scroll knobs, foil borders, brush icon, and title.
/// - Rolled-up (卷轴闭合态, 52px compact token): compact rolled cylinder showing only the brush icon.
class ScrollRollerFab extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isRolledUp;
  final String label;
  final String subLabel;
  final IconData icon;

  const ScrollRollerFab({
    super.key,
    required this.onPressed,
    this.isRolledUp = false,
    this.label = '写日记',
    this.subLabel = '',
    this.icon = Icons.brush_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;

    final targetWidth = isRolledUp ? 52.0 : 178.0;
    const height = 44.0;

    final border = BegoniaPlaqueBorder(
      cutSize: isRolledUp ? 8.0 : 6.0,
      borderColor: palette.fabBorder,
      borderWidth: 1.5,
      innerBorderInset: 2.0,
      innerBorderColor: palette.fabInnerBorder,
      innerBorderWidth: 1.0,
    );

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        palette.fabTop,
        palette.fabMid,
        palette.fabBottom,
      ],
    );

    return Semantics(
      button: true,
      label: subLabel.isNotEmpty ? '$label $subLabel' : label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: targetWidth,
        height: height,
        decoration: ShapeDecoration(
          shape: border,
          gradient: gradient,
          shadows: [
            BoxShadow(
              color: palette.fabShadow,
              blurRadius: 12,
              offset: const Offset(0, 5),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: border,
            onTap: onPressed,
            child: ExcludeSemantics(
              child: ClipRect(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Decorative top and bottom foil rail lines
                    Positioned(
                      top: 2.5,
                      left: 6,
                      right: 6,
                      child: Container(
                        height: 1.0,
                        color: palette.fabCapHighlight.withValues(alpha: 0.72),
                      ),
                    ),
                    Positioned(
                      bottom: 2.5,
                      left: 6,
                      right: 6,
                      child: Container(
                        height: 1.0,
                        color: palette.fabCapDark.withValues(alpha: 0.72),
                      ),
                    ),

                    // Content Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Scroll Knob Left
                          _buildScrollHead(isLeft: true, palette: palette),
                          const SizedBox(width: 4),

                          // Icon
                          Icon(
                            icon,
                            size: 18,
                            color: palette.fabText,
                          ),

                          // If not rolled up, display text labels
                          if (!isRolledUp) ...[
                            const SizedBox(width: 5),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        color: palette.fabText,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    if (subLabel.isNotEmpty) ...[
                                      const SizedBox(width: 3),
                                      Text(
                                        subLabel,
                                        style: TextStyle(
                                          color: palette.fabText.withValues(alpha: 0.88),
                                          fontSize: 9.0,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(width: 4),
                          // Scroll Knob Right
                          _buildScrollHead(isLeft: false, palette: palette),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollHead({
    required bool isLeft,
    required AtmospherePalette palette,
  }) {
    return Container(
      width: 3.5,
      height: 20,
      decoration: BoxDecoration(
        color: palette.woodFrameDark,
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(2) : Radius.zero,
          right: !isLeft ? const Radius.circular(2) : Radius.zero,
        ),
        border: Border.all(
          color: palette.fabCapMid,
          width: 0.75,
        ),
      ),
    );
  }
}
