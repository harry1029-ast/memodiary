enum DateFilterType { all, thisWeek, thisMonth, custom }

/// Encapsulates multi-condition search filter options for MemoDiary entries.
class SearchFilters {
  final DateFilterType dateType;
  final DateTime? customStart;
  final DateTime? customEnd;
  final int? mood;
  final String? weather;
  final bool hasImage;
  final bool weeklyReviewOnly;

  const SearchFilters({
    this.dateType = DateFilterType.all,
    this.customStart,
    this.customEnd,
    this.mood,
    this.weather,
    this.hasImage = false,
    this.weeklyReviewOnly = false,
  });

  DateTime? get resolvedStartDate {
    final now = DateTime.now();
    switch (dateType) {
      case DateFilterType.all:
        return null;
      case DateFilterType.thisWeek:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(monday.year, monday.month, monday.day);
      case DateFilterType.thisMonth:
        return DateTime(now.year, now.month, 1);
      case DateFilterType.custom:
        return customStart;
    }
  }

  DateTime? get resolvedEndDate {
    final now = DateTime.now();
    switch (dateType) {
      case DateFilterType.all:
        return null;
      case DateFilterType.thisWeek:
        final sunday =
            now.add(Duration(days: DateTime.daysPerWeek - now.weekday));
        return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
      case DateFilterType.thisMonth:
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        return nextMonth.subtract(const Duration(seconds: 1));
      case DateFilterType.custom:
        return customEnd;
    }
  }

  bool get hasActiveFilters =>
      dateType != DateFilterType.all ||
      mood != null ||
      (weather != null && weather!.isNotEmpty) ||
      hasImage ||
      weeklyReviewOnly;

  SearchFilters copyWith({
    DateFilterType? dateType,
    DateTime? customStart,
    DateTime? customEnd,
    int? mood,
    bool clearMood = false,
    String? weather,
    bool clearWeather = false,
    bool? hasImage,
    bool? weeklyReviewOnly,
  }) {
    return SearchFilters(
      dateType: dateType ?? this.dateType,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      mood: clearMood ? null : (mood ?? this.mood),
      weather: clearWeather ? null : (weather ?? this.weather),
      hasImage: hasImage ?? this.hasImage,
      weeklyReviewOnly: weeklyReviewOnly ?? this.weeklyReviewOnly,
    );
  }
}

