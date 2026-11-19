import 'package:flutter/material.dart';
import 'package:memodiary/core/theme/atmosphere_palette.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/timeline/widgets/folded_xuan_slip.dart';
import 'chronicle_desk_palette.dart';

/// Compact inline empty state card displayed when active `Date Index Tray`
/// filters match 0 entries while active entries still exist in SQLite.
class FilteredChronicleEmptyCard extends StatelessWidget {
  final int totalActiveInDb;
  final VoidCallback onClearFilters;

  const FilteredChronicleEmptyCard({
    super.key,
    required this.totalActiveInDb,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ChronicleDeskPalette.of(context);

    return FoldedXuanSlip(
      key: const Key('timeline_filtered_empty_card'),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.cinnabar, width: 1.2),
            ),
            alignment: Alignment.center,
            child: Text(
              '空',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: palette.cinnabar,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '当前筛选条件下暂无日记',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '可调整上方日期或标签筛选，或清除全部筛选',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            key: const Key('timeline_clear_filters_button'),
            onPressed: onClearFilters,
            style: FilledButton.styleFrom(
              backgroundColor: palette.cinnabar,
              foregroundColor: context.atmospherePalette.onAccentPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            ),
            child: Text(
              '清除筛选 ($totalActiveInDb 篇)',
              style: const TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
