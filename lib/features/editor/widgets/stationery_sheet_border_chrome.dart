import 'package:flutter/material.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../../templates/models/template_style.dart';

/// Resolved color palette for paper-adaptive border navigation chrome and page badges.
class _ChromeThemeData {
  final Color chevronTextColor;
  final Color chevronBgColor;
  final Color chevronBorderColor;
  final Color indicatorTextColor;
  final Color indicatorBgColor;
  final Color indicatorBorderColor;

  const _ChromeThemeData({
    required this.chevronTextColor,
    required this.chevronBgColor,
    required this.chevronBorderColor,
    required this.indicatorTextColor,
    required this.indicatorBgColor,
    required this.indicatorBorderColor,
  });
}

_ChromeThemeData _resolveChromeTheme({
  required PaperSubstrate substrate,
  bool isPaperDark = false,
  Color? customInkColor,
}) {
  if (isPaperDark || substrate == PaperSubstrate.obsidian) {
    return _ChromeThemeData(
      chevronTextColor: customInkColor ?? const Color(0xFFF0ECE3),
      chevronBgColor: const Color(0x33000000),
      chevronBorderColor: const Color(0x33FFFFFF),
      indicatorTextColor: customInkColor ?? const Color(0xFFF0ECE3),
      indicatorBgColor: const Color(0x40000000),
      indicatorBorderColor: const Color(0x33FFFFFF),
    );
  }

  switch (substrate) {
    case PaperSubstrate.coldGold:
      return _ChromeThemeData(
        chevronTextColor: customInkColor ?? const Color(0xFF262320),
        chevronBgColor: const Color(0x28000000),
        chevronBorderColor: const Color(0x33B8860B),
        indicatorTextColor: customInkColor ?? const Color(0xFF2A2216),
        indicatorBgColor: const Color(0x2E000000),
        indicatorBorderColor: const Color(0x33B8860B),
      );

    case PaperSubstrate.kraft:
      return _ChromeThemeData(
        chevronTextColor: customInkColor ?? const Color(0xFF2B2621),
        chevronBgColor: const Color(0x24000000),
        chevronBorderColor: const Color(0x265C4033),
        indicatorTextColor: customInkColor ?? const Color(0xFF2C241B),
        indicatorBgColor: const Color(0x26000000),
        indicatorBorderColor: const Color(0x265C4033),
      );

    case PaperSubstrate.xuan:
    case PaperSubstrate.minimal:
    default:
      return _ChromeThemeData(
        chevronTextColor: customInkColor ?? const Color(0xFF2D2D2D),
        chevronBgColor: const Color(0x14000000),
        chevronBorderColor: const Color(0x18000000),
        indicatorTextColor: customInkColor ?? const Color(0xFF2D2D2D),
        indicatorBgColor: const Color(0x14000000),
        indicatorBorderColor: const Color(0x18000000),
      );
  }
}

/// Paper-adaptive floating navigation chevron pill button ('‹' or '›')
/// positioned along the left or right borders of the Journal Sheet.
class StationeryBorderChevron extends StatelessWidget {
  final bool isNext;
  final bool isVisible;
  final VoidCallback? onPressed;
  final PaperSubstrate substrate;
  final bool isPaperDark;
  final Color? inkColor;

  const StationeryBorderChevron({
    super.key,
    required this.isNext,
    required this.isVisible,
    this.onPressed,
    this.substrate = PaperSubstrate.xuan,
    this.isPaperDark = false,
    this.inkColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final keyName = isNext ? 'editor_next_sheet_btn' : 'editor_prev_sheet_btn';
    final semanticLabel = isNext ? '下一页 · Next Sheet' : '上一页 · Previous Sheet';
    final symbol = isNext ? '›' : '‹';

    final chromeTheme = _resolveChromeTheme(
      substrate: substrate,
      isPaperDark: isPaperDark,
      customInkColor: inkColor,
    );

    return Semantics(
      button: true,
      label: semanticLabel,
      container: true,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key(keyName),
          onTap: onPressed,
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 36,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: chromeTheme.chevronBgColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: chromeTheme.chevronBorderColor, width: 0.8),
            ),
            child: Text(
              symbol,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: chromeTheme.chevronTextColor,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact page counter badge ('第 X / N 页') docked cleanly near the bottom Earth Margin.
class StationeryPageIndicator extends StatelessWidget {
  final int currentSheetIndex;
  final int totalSheets;
  final PaperSubstrate substrate;
  final bool isPaperDark;
  final Color? inkColor;

  const StationeryPageIndicator({
    super.key,
    required this.currentSheetIndex,
    required this.totalSheets,
    this.substrate = PaperSubstrate.xuan,
    this.isPaperDark = false,
    this.inkColor,
  });

  @override
  Widget build(BuildContext context) {
    final chromeTheme = _resolveChromeTheme(
      substrate: substrate,
      isPaperDark: isPaperDark,
      customInkColor: inkColor,
    );

    final displayPage = currentSheetIndex + 1;
    final text = '第 $displayPage / $totalSheets 页';

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Semantics(
        container: true,
        label: '第 $displayPage 页，共 $totalSheets 页',
        excludeSemantics: true,
        child: Container(
          key: const Key('editor_sheet_indicator'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
          decoration: BoxDecoration(
            color: chromeTheme.indicatorBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: chromeTheme.indicatorBorderColor, width: 0.8),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontKaiti,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: chromeTheme.indicatorTextColor,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable overlay layout placing the border navigation chevrons and bottom page counter badge.
class StationerySheetBorderChrome extends StatelessWidget {
  final int currentSheetIndex;
  final int totalSheets;
  final VoidCallback? onPreviousSheet;
  final VoidCallback? onNextSheet;
  final PaperSubstrate substrate;
  final bool isPaperDark;
  final Color? inkColor;
  final double horizontalInset;
  final double bottomInset;

  const StationerySheetBorderChrome({
    super.key,
    required this.currentSheetIndex,
    required this.totalSheets,
    this.onPreviousSheet,
    this.onNextSheet,
    this.substrate = PaperSubstrate.xuan,
    this.isPaperDark = false,
    this.inkColor,
    this.horizontalInset = 8.0,
    this.bottomInset = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final showPrev = currentSheetIndex > 0;
    final showNext = currentSheetIndex < totalSheets - 1;

    return Stack(
      children: [
        // Left border navigation chevron
        if (showPrev)
          Positioned(
            left: horizontalInset,
            top: 0,
            bottom: 0,
            child: Center(
              child: StationeryBorderChevron(
                isNext: false,
                isVisible: true,
                onPressed: onPreviousSheet,
                substrate: substrate,
                isPaperDark: isPaperDark,
                inkColor: inkColor,
              ),
            ),
          ),

        // Right border navigation chevron
        if (showNext)
          Positioned(
            right: horizontalInset,
            top: 0,
            bottom: 0,
            child: Center(
              child: StationeryBorderChevron(
                isNext: true,
                isVisible: true,
                onPressed: onNextSheet,
                substrate: substrate,
                isPaperDark: isPaperDark,
                inkColor: inkColor,
              ),
            ),
          ),

        // Bottom page indicator badge
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomInset,
          child: IgnorePointer(
            child: Center(
              child: StationeryPageIndicator(
                currentSheetIndex: currentSheetIndex,
                totalSheets: totalSheets,
                substrate: substrate,
                isPaperDark: isPaperDark,
                inkColor: inkColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
