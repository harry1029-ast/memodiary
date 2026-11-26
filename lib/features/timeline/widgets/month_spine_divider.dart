import 'package:flutter/material.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';

/// Inline `YYYY年M月` Month Spine Divider placed along the Chronicle Desk's
/// continuous vertical silk-cord spine (`X = 37.0`).
class MonthSpineDivider extends StatelessWidget {
  final int year;
  final int month;
  final bool isFirstInFeed;

  const MonthSpineDivider({
    super.key,
    required this.year,
    required this.month,
    this.isFirstInFeed = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.atmospherePalette;
    final label = '$year年$month月';
    final topPadding = isFirstInFeed ? 6.0 : 4.0;
    const bottomPadding = 6.0;

    return Semantics(
      header: true,
      label: label,
      excludeSemantics: true,
      child: Stack(
        children: [
          // 1. Continuous Vertical Spine Line aligned with ChronicleBrassGrommet
          // and TimelineDateSpineItem (left: 36, width: 2.0 -> center X = 37.0).
          Positioned(
            left: 36.0,
            top: 0.0,
            bottom: 0.0,
            child: Container(
              key: const Key('timeline_month_spine_divider_line'),
              width: 2.0,
              decoration: BoxDecoration(
                gradient: isFirstInFeed
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          palette.spineCordTop,
                          palette.deckleBorder,
                        ],
                      )
                    : null,
                color: isFirstInFeed ? null : palette.deckleBorder,
              ),
            ),
          ),

          // 2. Spine Ring Node centered at X = 37.0
          Positioned(
            left: 32.5,
            top: topPadding,
            bottom: bottomPadding,
            child: Center(
              child: Container(
                width: 9.0,
                height: 9.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.deskMat,
                  border: Border.all(
                    color: isFirstInFeed
                        ? palette.accentPrimary
                        : palette.accentSecondary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // 3. Horizontal hairline connecting spine node to the month label
          Positioned(
            left: 41.5,
            top: topPadding,
            bottom: bottomPadding,
            child: Center(
              child: Container(
                width: 26.5,
                height: 1.0,
                color: palette.deckleBorder.withValues(alpha: 0.75),
              ),
            ),
          ),

          // 4. Month label pill + trailing deckle rule aligned with entry cards
          Padding(
            padding: EdgeInsets.fromLTRB(68.0, topPadding, 14.0, bottomPadding),
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: palette.deskTray,
                      borderRadius: BorderRadius.circular(11.0),
                      border: Border.all(
                        color: palette.deckleBorder,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontNotoSerif,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        height: 1.2,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Container(
                    height: 1.0,
                    color: palette.deckleBorder.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
