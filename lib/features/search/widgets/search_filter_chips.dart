import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/widgets/ink_metadata_pill.dart';
import '../../editor/widgets/entry_metadata_bar.dart';
import '../../timeline/widgets/entry_summary_card.dart';
import '../models/search_filters.dart';

/// Horizontally scrollable literati filter bar with chips for Date Range, Mood, Weather,
/// Has Photo, and Weekly Review.
class SearchFilterChips extends StatelessWidget {
  final SearchFilters filters;
  final ValueChanged<SearchFilters> onFiltersChanged;

  const SearchFilterChips({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  String _getDateChipLabel() {
    switch (filters.dateType) {
      case DateFilterType.all:
        return '时日: 全部';
      case DateFilterType.thisWeek:
        return '时日: 本周';
      case DateFilterType.thisMonth:
        return '时日: 本月';
      case DateFilterType.custom:
        final start = filters.customStart != null
            ? DateFormat('MM/dd').format(filters.customStart!)
            : '?';
        final end = filters.customEnd != null
            ? DateFormat('MM/dd').format(filters.customEnd!)
            : '?';
        return '时日: $start-$end';
    }
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final tokens = InkDiaryTheme.tokensOf(context);

    final selected = await showModalBottomSheet<DateFilterType>(
      context: context,
      backgroundColor: tokens.xuanGround,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('全部时日 · All Time'),
              leading: const Icon(Icons.all_inclusive),
              selected: filters.dateType == DateFilterType.all,
              onTap: () => Navigator.pop(ctx, DateFilterType.all),
            ),
            ListTile(
              title: const Text('本周墨痕 · This Week'),
              leading: const Icon(Icons.view_week_outlined),
              selected: filters.dateType == DateFilterType.thisWeek,
              onTap: () => Navigator.pop(ctx, DateFilterType.thisWeek),
            ),
            ListTile(
              title: const Text('当月册卷 · This Month'),
              leading: const Icon(Icons.calendar_month_outlined),
              selected: filters.dateType == DateFilterType.thisMonth,
              onTap: () => Navigator.pop(ctx, DateFilterType.thisMonth),
            ),
            ListTile(
              title: const Text('自定义日期区间... · Custom Range'),
              leading: const Icon(Icons.date_range_outlined),
              selected: filters.dateType == DateFilterType.custom,
              onTap: () => Navigator.pop(ctx, DateFilterType.custom),
            ),
          ],
        ),
      ),
    );

    if (selected == null || !context.mounted) return;

    if (selected == DateFilterType.custom) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDateRange: filters.customStart != null && filters.customEnd != null
            ? DateTimeRange(
                start: filters.customStart!,
                end: filters.customEnd!,
              )
            : null,
      );
      if (range != null) {
        onFiltersChanged(filters.copyWith(
          dateType: DateFilterType.custom,
          customStart: range.start,
          customEnd: DateTime(
            range.end.year,
            range.end.month,
            range.end.day,
            23,
            59,
            59,
          ),
        ));
      }
    } else {
      onFiltersChanged(filters.copyWith(dateType: selected));
    }
  }

  void _showMoodPicker(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.xuanGround,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '按心境感怀筛选',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: tokens.jiaomo,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('全部心境'),
                leading: const Icon(Icons.clear_all),
                selected: filters.mood == null,
                onTap: () {
                  onFiltersChanged(filters.copyWith(clearMood: true));
                  Navigator.pop(ctx);
                },
              ),
              ...EntryMetadataBar.moodOptions.map((opt) {
                final isSelected = filters.mood == opt['value'];
                return ListTile(
                  leading: Text(opt['emoji'] as String, style: const TextStyle(fontSize: 22)),
                  title: Text(opt['label'] as String),
                  selected: isSelected,
                  onTap: () {
                    onFiltersChanged(filters.copyWith(mood: opt['value'] as int));
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeatherPicker(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.xuanGround,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '按物候天候筛选',
                style: TextStyle(
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: tokens.jiaomo,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('全部天候'),
                leading: const Icon(Icons.clear_all),
                selected: filters.weather == null,
                onTap: () {
                  onFiltersChanged(filters.copyWith(clearWeather: true));
                  Navigator.pop(ctx);
                },
              ),
              ...EntryMetadataBar.weatherOptions.map((opt) {
                final isSelected = filters.weather == opt['value'];
                return ListTile(
                  leading: Icon(opt['icon'] as IconData, color: tokens.danmo),
                  title: Text(opt['label'] as String),
                  selected: isSelected,
                  onTap: () {
                    onFiltersChanged(filters.copyWith(weather: opt['value'] as String));
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moodEmoji = filters.mood != null ? EntrySummaryCard.moodEmojis[filters.mood!] : null;
    final weatherLabel = filters.weather;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          // Reset Filter Chip (if active)
          if (filters.hasActiveFilters) ...[
            InkMetadataPill(
              key: const Key('reset_filters_pill'),
              icon: Icons.close,
              label: '重置检索',
              isAccent: true,
              onTap: () {
                HapticFeedback.lightImpact();
                onFiltersChanged(const SearchFilters());
              },
              semanticLabel: '重置所有检索筛选',
            ),
            const SizedBox(width: 8),
          ],

          // Date Filter
          InkMetadataPill(
            key: const Key('search_date_filter_pill'),
            icon: Icons.calendar_today_outlined,
            label: _getDateChipLabel(),
            isAccent: filters.dateType != DateFilterType.all,
            onTap: () => _showDateRangePicker(context),
            semanticLabel: _getDateChipLabel(),
          ),
          const SizedBox(width: 8),

          // Mood Filter
          InkMetadataPill(
            key: const Key('search_mood_filter_pill'),
            emoji: moodEmoji,
            icon: moodEmoji == null ? Icons.mood_outlined : null,
            label: filters.mood != null ? '心境: $moodEmoji' : '心境: 全部',
            isAccent: filters.mood != null,
            onTap: () => _showMoodPicker(context),
            semanticLabel: '按心境筛选',
          ),
          const SizedBox(width: 8),

          // Weather Filter
          InkMetadataPill(
            key: const Key('search_weather_filter_pill'),
            icon: Icons.wb_sunny_outlined,
            label: weatherLabel != null ? '天候: $weatherLabel' : '天候: 全部',
            isAccent: filters.weather != null,
            onTap: () => _showWeatherPicker(context),
            semanticLabel: '按天候筛选',
          ),
          const SizedBox(width: 8),

          // Photos Filter
          InkMetadataPill(
            key: const Key('search_has_image_filter_pill'),
            icon: Icons.photo_outlined,
            label: '附画卷',
            isAccent: filters.hasImage,
            onTap: () {
              HapticFeedback.lightImpact();
              onFiltersChanged(filters.copyWith(hasImage: !filters.hasImage));
            },
            semanticLabel: '仅看附画卷日记',
          ),
          const SizedBox(width: 8),

          // Weekly Review Filter
          InkMetadataPill(
            key: const Key('search_weekly_review_filter_pill'),
            icon: Icons.rate_review_outlined,
            label: '温故复盘',
            isAccent: filters.weeklyReviewOnly,
            onTap: () {
              HapticFeedback.lightImpact();
              onFiltersChanged(filters.copyWith(weeklyReviewOnly: !filters.weeklyReviewOnly));
            },
            semanticLabel: '仅看温故复盘日记',
          ),
        ],
      ),
    );
  }
}
