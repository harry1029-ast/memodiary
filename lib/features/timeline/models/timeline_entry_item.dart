import 'package:memodiary/core/database/app_database.dart';

/// Compound model combining an entry with its visual template and primary media attachment.
class TimelineEntryItem {
  final Entry entry;
  final Template? template;
  final MediaAttachment? primaryMedia;

  const TimelineEntryItem({
    required this.entry,
    this.template,
    this.primaryMedia,
  });

  /// True if the entry has an unlock date in the future (Time Capsule)
  bool get isSealedTimeCapsule {
    final unlockAt = entry.unlockAt;
    if (unlockAt == null) return false;
    return DateTime.now().isBefore(unlockAt);
  }

  /// Remaining duration until the time capsule unlocks
  Duration? get timeUntilUnlock {
    final unlockAt = entry.unlockAt;
    if (unlockAt == null) return null;
    final diff = unlockAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Human-readable remaining time string (e.g., "3 days", "5 hours", "20 mins")
  String get remainingUnlockTimeFormatted {
    final diff = timeUntilUnlock;
    if (diff == null || diff == Duration.zero) return 'Ready to open';
    if (diff.inDays > 0) {
      final days = diff.inDays;
      return '$days ${days == 1 ? "day" : "days"}';
    }
    if (diff.inHours > 0) {
      final hours = diff.inHours;
      return '$hours ${hours == 1 ? "hour" : "hours"}';
    }
    final mins = diff.inMinutes;
    return '$mins ${mins <= 1 ? "min" : "mins"}';
  }
}

