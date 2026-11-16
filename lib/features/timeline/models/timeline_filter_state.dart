import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Traditional Chinese ten-day period (*三旬*) within a selected month.
enum TimelineXun {
  /// Days 1..10 (初一–初十).
  shang,

  /// Days 11..20 (十一–二十).
  zhong,

  /// Days 21..end-of-month (廿一–晦日).
  xia,
}

/// Chronological sort direction for the timeline feed.
enum TimelineSortOrder {
  newestFirst,
  oldestFirst,
}

/// Immutable filter and sort value object backing the `Date Index Tray` and
/// Charm/Tag filters on `TimelineScreen`.
@immutable
class TimelineFilterState {
  /// Selected Gregorian year, or `null` for `全部`.
  final int? year;

  /// Selected Gregorian month (`1..12`), or `null` for all months.
  final int? month;

  /// Selected ten-day period (`三旬`); only active when [month] != null.
  final TimelineXun? xun;

  /// Chronological ordering of entries.
  final TimelineSortOrder sortOrder;

  /// Optional mood filter (`1..5`).
  final int? mood;

  /// Optional weather filter (`sunny` | `cloudy` | `rainy` | `windy` | `snowy`).
  final String? weather;

  /// When `true`, restricts results to entries with at least one media attachment.
  final bool hasMediaOnly;

  /// When `true`, restricts results to weekly review entries (`isWeeklyReview == true`).
  final bool weeklyReviewOnly;

  const TimelineFilterState({
    this.year,
    this.month,
    this.xun,
    this.sortOrder = TimelineSortOrder.newestFirst,
    this.mood,
    this.weather,
    this.hasMediaOnly = false,
    this.weeklyReviewOnly = false,
  });

  /// Whether any date or charm/tag filter is currently applied.
  bool get hasActiveFilters =>
      year != null ||
      month != null ||
      xun != null ||
      mood != null ||
      (weather != null && weather!.isNotEmpty) ||
      hasMediaOnly ||
      weeklyReviewOnly;

  /// Whether any charm/tag attribute filter is active.
  bool get hasActiveCharmFilters =>
      mood != null ||
      (weather != null && weather!.isNotEmpty) ||
      hasMediaOnly ||
      weeklyReviewOnly;

  /// Returns a copy with updated fields; use `clear*` flags to explicitly clear nullable fields.
  TimelineFilterState copyWith({
    int? year,
    bool clearYear = false,
    int? month,
    bool clearMonth = false,
    TimelineXun? xun,
    bool clearXun = false,
    TimelineSortOrder? sortOrder,
    int? mood,
    bool clearMood = false,
    String? weather,
    bool clearWeather = false,
    bool? hasMediaOnly,
    bool? weeklyReviewOnly,
  }) {
    return TimelineFilterState(
      year: clearYear ? null : (year ?? this.year),
      month: clearMonth ? null : (month ?? this.month),
      xun: clearXun ? null : (xun ?? this.xun),
      sortOrder: sortOrder ?? this.sortOrder,
      mood: clearMood ? null : (mood ?? this.mood),
      weather: clearWeather ? null : (weather ?? this.weather),
      hasMediaOnly: hasMediaOnly ?? this.hasMediaOnly,
      weeklyReviewOnly: weeklyReviewOnly ?? this.weeklyReviewOnly,
    );
  }

  /// Selects a [nextYear] (`null` = `全部`), clearing [month] and [xun] when `null`.
  TimelineFilterState selectYear(int? nextYear) {
    if (nextYear == null) {
      return copyWith(clearYear: true, clearMonth: true, clearXun: true);
    }
    if (nextYear == year) {
      return this;
    }
    return copyWith(year: nextYear, clearXun: true);
  }

  /// Toggles [targetMonth] (`1..12`). Selecting a month while [year] is `null`
  /// auto-promotes [year] to the latest entry year (or [currentYear]).
  TimelineFilterState selectMonth(
    int targetMonth, {
    required List<int> availableYears,
    int? currentYear,
  }) {
    if (month == targetMonth) {
      return copyWith(clearMonth: true, clearXun: true);
    }
    final resolvedYear = year ??
        (availableYears.isNotEmpty
            ? availableYears.reduce(math.max)
            : (currentYear ?? DateTime.now().year));
    return copyWith(
      year: resolvedYear,
      month: targetMonth,
      clearXun: true,
    );
  }

  /// Toggles [targetXun] (`上旬`/`中旬`/`下旬`) on or off.
  TimelineFilterState selectXun(TimelineXun targetXun) {
    if (month == null) return this;
    if (xun == targetXun) {
      return copyWith(clearXun: true);
    }
    return copyWith(xun: targetXun);
  }

  /// Flips between [TimelineSortOrder.newestFirst] and [TimelineSortOrder.oldestFirst].
  TimelineFilterState toggleSortOrder() {
    return copyWith(
      sortOrder: sortOrder == TimelineSortOrder.newestFirst
          ? TimelineSortOrder.oldestFirst
          : TimelineSortOrder.newestFirst,
    );
  }

  /// Clears all date and charm filters while preserving [sortOrder].
  TimelineFilterState resetAll() {
    return TimelineFilterState(sortOrder: sortOrder);
  }

  /// Returns the half-open `[startInclusive, endExclusive)` Gregorian bounds
  /// derived from [year], [month], and [xun], or `null` when [year] is `null`.
  (DateTime, DateTime)? dateRange() {
    final activeYear = year;
    if (activeYear == null) return null;

    final activeMonth = month;
    if (activeMonth == null) {
      return (DateTime(activeYear, 1, 1), DateTime(activeYear + 1, 1, 1));
    }

    final activeXun = xun;
    if (activeXun == null) {
      return (
        DateTime(activeYear, activeMonth, 1),
        DateTime(activeYear, activeMonth + 1, 1),
      );
    }

    return switch (activeXun) {
      TimelineXun.shang => (
          DateTime(activeYear, activeMonth, 1),
          DateTime(activeYear, activeMonth, 11),
        ),
      TimelineXun.zhong => (
          DateTime(activeYear, activeMonth, 11),
          DateTime(activeYear, activeMonth, 21),
        ),
      TimelineXun.xia => (
          DateTime(activeYear, activeMonth, 21),
          DateTime(activeYear, activeMonth + 1, 1),
        ),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is TimelineFilterState &&
        other.year == year &&
        other.month == month &&
        other.xun == xun &&
        other.sortOrder == sortOrder &&
        other.mood == mood &&
        other.weather == weather &&
        other.hasMediaOnly == hasMediaOnly &&
        other.weeklyReviewOnly == weeklyReviewOnly;
  }

  @override
  int get hashCode => Object.hash(
        year,
        month,
        xun,
        sortOrder,
        mood,
        weather,
        hasMediaOnly,
        weeklyReviewOnly,
      );
}

/// Facet summary powering Row 1 (years) and Row 2 (month presence dots) of the
/// `Date Index Tray`, plus total unfiltered active entry count.
@immutable
class TimelineDateFacetSummary {
  /// Distinct active entry years (always including current year), descending.
  final List<int> years;

  /// Months (`1..12`) that have at least one matching entry for the active year + charm filters.
  final Set<int> activeMonths;

  /// Total non-deleted entries in the database regardless of active filters.
  final int totalActiveEntries;

  const TimelineDateFacetSummary({
    required this.years,
    required this.activeMonths,
    required this.totalActiveEntries,
  });

  factory TimelineDateFacetSummary.empty({int? currentYear}) {
    return TimelineDateFacetSummary(
      years: [currentYear ?? DateTime.now().year],
      activeMonths: const {},
      totalActiveEntries: 0,
    );
  }
}
