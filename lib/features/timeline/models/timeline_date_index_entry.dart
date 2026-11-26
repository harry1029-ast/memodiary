import 'package:flutter/foundation.dart';

/// Lightweight ordered date-index item `(id, entryDate)` powering the
/// `Timeline Scrubber` without fetching heavy entry payloads.
@immutable
class TimelineDateIndexEntry {
  final String id;
  final DateTime entryDate;

  const TimelineDateIndexEntry({
    required this.id,
    required this.entryDate,
  });

  /// Plain modern Chinese `YYYY年M月` month label for the floating date plaque.
  String get monthLabel => '${entryDate.year}年${entryDate.month}月';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimelineDateIndexEntry &&
        other.id == id &&
        other.entryDate == entryDate;
  }

  @override
  int get hashCode => Object.hash(id, entryDate);
}
