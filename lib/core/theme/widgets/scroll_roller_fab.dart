import 'package:flutter/material.dart';
import '../shapes/classical_chinese_borders.dart';

/// Imperial Scroll-Roller Floating Action Button (朱砂泥金卷轴横匾按钮)
///
/// An ornate floating action button inspired by traditional Chinese imperial proclamation
/// scrolls and handscroll paintings. Supports dynamic roll-up physics:
/// - Unfurled (展开态, ~160px wide): displays scroll knobs, gold silk borders, brush icon,
///   and bilingual title ("挥毫落墨 Write Diary").
/// - Rolled-up (卷轴闭合态, ~52px compact token): compact rolled cylinder showing only the
///   brush icon and cinnabar ribbon knot.
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
    this.label = '挥毫落墨',
    this.subLabel = 'Write Diary',
    this.icon = Icons.brush_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final targetWidth = isRolledUp ? 52.0 : 178.0;
    const height = 44.0;

    final border = BegoniaPlaqueBorder(
      cutSize: isRolledUp ? 8.0 : 6.0,
      borderColor: isDark ? const Color(0xFF8B6B3E) : const Color(0xFFD9A962),
      borderWidth: 1.5,
      innerBorderInset: 2.0,
      innerBorderColor: isDark
          ? const Color(0xFFD25447).withValues(alpha: 0.3)
          : const Color(0xFFFFE8D6).withValues(alpha: 0.35),
      innerBorderWidth: 1.0,
    );

    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF9E2E22),
              Color(0xFF7A1F16),
              Color(0xFF5E150E),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFC43E30),
              Color(0xFFA82F22),
              Color(0xFF8C2014),
            ],
          );

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.55)
        : const Color(0xFF8C2014).withValues(alpha: 0.45);

    return Semantics(
      button: true,
      label: '$label $subLabel',
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
              color: shadowColor,
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
            child: ClipRect(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative top and bottom gold-foiled rail lines
                  Positioned(
                    top: 2.5,
                    left: 6,
                    right: 6,
                    child: Container(
                      height: 1.0,
                      color: const Color(0xFFFFDF9E).withValues(alpha: 0.7),
                    ),
                  ),
                  Positioned(
                    bottom: 2.5,
                    left: 6,
                    right: 6,
                    child: Container(
                      height: 1.0,
                      color: const Color(0xFFB5833E).withValues(alpha: 0.7),
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
                        _buildScrollHead(isLeft: true),
                        const SizedBox(width: 4),

                        // Icon
                        Icon(
                          icon,
                          size: 18,
                          color: const Color(0xFFFFF6ED),
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
                                    style: const TextStyle(
                                      color: Color(0xFFFFF9F2),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    subLabel,
                                    style: TextStyle(
                                      color: const Color(0xFFFFD8CC).withValues(alpha: 0.9),
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(width: 4),
                        // Scroll Knob Right
                        _buildScrollHead(isLeft: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollHead({required bool isLeft}) {
    return Container(
      width: 3.5,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFF2B221B), // Carved ebony wood
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(2) : Radius.zero,
          right: !isLeft ? const Radius.circular(2) : Radius.zero,
        ),
        border: Border.all(
          color: const Color(0xFFD9A962), // Gold cap
          width: 0.75,
        ),
      ),
    );
  }
}
