import 'package:flutter/material.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'chronicle_desk_palette.dart';

/// Year filter chip (`纪年`) used in Row 1 of [DateIndexTray].
class TrayFilterChip extends StatelessWidget {
  final String label;
  final String semanticLabel;
  final bool isActive;
  final ChronicleDeskPalette palette;
  final VoidCallback onTap;

  const TrayFilterChip({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.isActive,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive
        ? palette.cinnabar.withValues(alpha: 0.20)
        : palette.agedChip;
    final borderColor = isActive
        ? palette.cinnabar.withValues(alpha: 0.55)
        : Colors.transparent;
    final textColor = isActive ? palette.cinnabar : palette.textMuted;

    return Semantics(
      button: true,
      selected: isActive,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(minHeight: 28, minWidth: 38),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: 1.0),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: palette.cinnabar,
                        offset: const Offset(0, 1.5),
                        blurRadius: 0,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chronological sort toggle (`最新 ↓` / `最早 ↑`) used in Row 1 of [DateIndexTray].
class TraySortToggleButton extends StatelessWidget {
  final bool isNewestFirst;
  final ChronicleDeskPalette palette;
  final VoidCallback onTap;

  const TraySortToggleButton({
    super.key,
    required this.isNewestFirst,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isNewestFirst ? '切换排序，当前最新优先' : '切换排序，当前最早优先',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(minHeight: 28, minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: palette.agedChip,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: palette.deckleBorder, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isNewestFirst ? '最新' : '最早',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  isNewestFirst ? '↓' : '↑',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: palette.cinnabar,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Month chip (`1月`–`12月`) with cinnabar entry-presence dot used in Row 2.
class MonthIndexChip extends StatelessWidget {
  final GlobalKey? containerKey;
  final int month;
  final bool isActive;
  final bool hasEntries;
  final ChronicleDeskPalette palette;
  final VoidCallback onTap;

  const MonthIndexChip({
    super.key,
    required this.containerKey,
    required this.month,
    required this.isActive,
    required this.hasEntries,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive
        ? palette.cinnabar.withValues(alpha: 0.20)
        : palette.agedChip;
    final borderColor = isActive
        ? palette.cinnabar.withValues(alpha: 0.55)
        : Colors.transparent;
    final textColor = isActive ? palette.cinnabar : palette.textMuted;

    return Semantics(
      button: true,
      selected: isActive,
      label: '$month月${hasEntries ? '，有卷宗' : ''}',
      child: Material(
        key: containerKey,
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 30),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$month月',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                if (hasEntries)
                  Container(
                    key: Key('timeline_month_dot_$month'),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.cinnabar,
                    ),
                  )
                else
                  const SizedBox(width: 4, height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ten-day period segment (`上旬`/`中旬`/`下旬`) used in Row 3.
class XunSegmentChip extends StatelessWidget {
  final String label;
  final String rangeLabel;
  final bool isActive;
  final ChronicleDeskPalette palette;
  final VoidCallback onTap;

  const XunSegmentChip({
    super.key,
    required this.label,
    required this.rangeLabel,
    required this.isActive,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive
        ? palette.cinnabar.withValues(alpha: 0.20)
        : palette.agedChip;
    final borderColor = isActive
        ? palette.cinnabar.withValues(alpha: 0.55)
        : Colors.transparent;
    final textColor = isActive ? palette.cinnabar : palette.textMuted;

    return Semantics(
      button: true,
      selected: isActive,
      label: '$label $rangeLabel',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(minHeight: 28),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: InkDiaryTheme.fontNotoSerif,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    rangeLabel,
                    style: TextStyle(
                      fontSize: 9,
                      color: textColor.withValues(alpha: 0.8),
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
}
