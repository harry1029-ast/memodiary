import 'package:flutter/material.dart';

import '../../../core/theme/ink_diary_theme.dart';

/// The page indicator ('第 N / M 页') engraved in brass at the left of the
/// Scholar's Desk header band above the active Stationery Sheet.
class StationeryPageIndicator extends StatelessWidget {
  final int currentSheetIndex;
  final int totalSheets;

  static const Color kTextColor = Color(0xE6FDE68A);
  static const Color kBgColor = Color(0x59000000);
  static const Color kBorderColor = Color(0x66C89D42);

  const StationeryPageIndicator({
    super.key,
    required this.currentSheetIndex,
    required this.totalSheets,
  });

  @override
  Widget build(BuildContext context) {
    final displayPage = currentSheetIndex + 1;

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
            color: kBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorderColor, width: 0.8),
          ),
          child: Text(
            '第 $displayPage / $totalSheets 页',
            style: const TextStyle(
              fontFamily: InkDiaryTheme.fontKaiti,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kTextColor,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
