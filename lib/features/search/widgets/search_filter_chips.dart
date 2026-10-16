import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memodiary/features/editor/widgets/entry_metadata_bar.dart';
import 'package:memodiary/features/search/models/search_filters.dart';
import 'package:memodiary/features/timeline/widgets/entry_summary_card.dart';

/// Horizontally scrollable filter bar with chips for Date Range, Mood, Weather,
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
        return 'Date: All';
      case DateFilterType.thisWeek:
        return 'This Week';
      case DateFilterType.thisMonth:
        return 'This Month';
      case DateFilterType.custom:
        final start = filters.customStart != null
            ? DateFormat('MM/dd').format(filters.customStart!)
            : '?';
        final end = filters.customEnd != null
            ? DateFormat('MM/dd').format(filters.customEnd!)
            : '?';
        return '$start - $end';
    }
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final selected = await showModalBottomSheet<DateFilterType>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Time'),
              leading: const Icon(Icons.all_inclusive),
              selected: filters.dateType == DateFilterType.all,
              onTap: () => Navigator.pop(ctx, DateFilterType.all),
            ),
            ListTile(
              title: const Text('This Week'),
              leading: const Icon(Icons.view_week_outlined),
              selected: filters.dateType == DateFilterType.thisWeek,
              onTap: () => Navigator.pop(ctx, DateFilterType.thisWeek),
            ),
            ListTile(
              title: const Text('This Month'),
              leading: const Icon(Icons.calendar_month_outlined),
              selected: filters.dateType == DateFilterType.thisMonth,
              onTap: () => Navigator.pop(ctx, DateFilterType.thisMonth),
            ),
            ListTile(
              title: const Text('Custom Date Range...'),
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
      onFiltersChanged(filters.copyWith(
        dateType: selected,
        customStart: null,
        customEnd: null,
      ));
    }
  }

  Future<void> _showMoodPicker(BuildContext context) async {
    final selectedMood = await showModalBottomSheet<int?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Moods'),
              leading: const Icon(Icons.mood),
              selected: filters.mood == null,
              onTap: () => Navigator.pop(ctx, null),
            ),
            ...EntryMetadataBar.moodOptions.map(
              (opt) => ListTile(
                title: Text('${opt["emoji"]} ${opt["label"]}'),
                selected: filters.mood == opt['value'],
                onTap: () => Navigator.pop(ctx, opt['value'] as int),
              ),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) return;
    if (selectedMood == null) {
      onFiltersChanged(filters.copyWith(clearMood: true));
    } else {
      onFiltersChanged(filters.copyWith(mood: selectedMood));
    }
  }

  Future<void> _showWeatherPicker(BuildContext context) async {
    final selectedWeather = await showModalBottomSheet<String?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Weathers'),
              leading: const Icon(Icons.wb_sunny_outlined),
              selected: filters.weather == null,
              onTap: () => Navigator.pop(ctx, null),
            ),
            ...EntryMetadataBar.weatherOptions.map(
              (opt) => ListTile(
                title: Text(opt['label'] as String),
                leading: Icon(opt['icon'] as IconData),
                selected: filters.weather == opt['value'],
                onTap: () => Navigator.pop(ctx, opt['value'] as String),
              ),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) return;
    if (selectedWeather == null) {
      onFiltersChanged(filters.copyWith(clearWeather: true));
    } else {
      onFiltersChanged(filters.copyWith(weather: selectedWeather));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Clear All Filters (if any filter active)
          if (filters.hasActiveFilters) ...[
            ActionChip(
              avatar: const Icon(Icons.close, size: 16),
              label: const Text('Reset'),
              onPressed: () => onFiltersChanged(const SearchFilters()),
            ),
            const SizedBox(width: 8),
          ],

          // Date Range Chip
          FilterChip(
            selected: filters.dateType != DateFilterType.all,
            label: Text(_getDateChipLabel()),
            onSelected: (_) => _showDateRangePicker(context),
          ),
          const SizedBox(width: 8),

          // Mood Chip
          FilterChip(
            selected: filters.mood != null,
            label: Text(
              filters.mood != null
                  ? 'Mood: ${EntrySummaryCard.moodEmojis[filters.mood!] ?? ""}'
                  : 'Mood',
            ),
            onSelected: (_) => _showMoodPicker(context),
          ),
          const SizedBox(width: 8),

          // Weather Chip
          FilterChip(
            selected: filters.weather != null,
            label: Text(
              filters.weather != null ? 'Weather: ${filters.weather}' : 'Weather',
            ),
            onSelected: (_) => _showWeatherPicker(context),
          ),
          const SizedBox(width: 8),

          // Has Photo Chip
          FilterChip(
            selected: filters.hasImage,
            avatar: const Icon(Icons.photo_outlined, size: 16),
            label: const Text('With Photos'),
            onSelected: (val) => onFiltersChanged(filters.copyWith(hasImage: val)),
          ),
          const SizedBox(width: 8),

          // Weekly Review Chip
          FilterChip(
            selected: filters.weeklyReviewOnly,
            avatar: const Icon(Icons.rate_review_outlined, size: 16),
            label: const Text('Weekly Review'),
            onSelected: (val) =>
                onFiltersChanged(filters.copyWith(weeklyReviewOnly: val)),
          ),
        ],
      ),
    );
  }
}

