import 'package:flutter/foundation.dart';
import 'package:memodiary/core/database/app_database.dart';

/// Lightweight timeline projection for an entry, omitting `contentDelta`
/// and carrying only display metadata and a capped `plainTextSnippet`.
@immutable
class TimelineEntrySummary {
  /// Default maximum character length for SQL-projected plain-text snippets.
  static const int defaultSnippetMaxLength = 240;

  final String id;
  final String? title;
  final String plainTextSnippet;
  final DateTime entryDate;
  final int? mood;
  final String? weather;
  final bool isLocked;
  final bool isWeeklyReview;
  final int? weekNumber;
  final DateTime? unlockAt;
  final bool isDeleted;

  const TimelineEntrySummary({
    required this.id,
    this.title,
    required this.plainTextSnippet,
    required this.entryDate,
    this.mood,
    this.weather,
    this.isLocked = false,
    this.isWeeklyReview = false,
    this.weekNumber,
    this.unlockAt,
    this.isDeleted = false,
  });

  /// Adapts a full [Entry] row into a [TimelineEntrySummary] for non-timeline callers.
  factory TimelineEntrySummary.fromEntry(Entry entry) {
    return TimelineEntrySummary(
      id: entry.id,
      title: entry.title,
      plainTextSnippet: entry.plainText,
      entryDate: entry.entryDate,
      mood: entry.mood,
      weather: entry.weather,
      isLocked: entry.isLocked,
      isWeeklyReview: entry.isWeeklyReview,
      weekNumber: entry.weekNumber,
      unlockAt: entry.unlockAt,
      isDeleted: entry.isDeleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimelineEntrySummary &&
        other.id == id &&
        other.title == title &&
        other.plainTextSnippet == plainTextSnippet &&
        other.entryDate == entryDate &&
        other.mood == mood &&
        other.weather == weather &&
        other.isLocked == isLocked &&
        other.isWeeklyReview == isWeeklyReview &&
        other.weekNumber == weekNumber &&
        other.unlockAt == unlockAt &&
        other.isDeleted == isDeleted;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        plainTextSnippet,
        entryDate,
        mood,
        weather,
        isLocked,
        isWeeklyReview,
        weekNumber,
        unlockAt,
        isDeleted,
      );
}
