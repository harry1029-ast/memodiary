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

  /// Human-readable remaining time string (e.g., "3 天", "5 小时", "20 分钟")
  String get remainingUnlockTimeFormatted {
    final diff = timeUntilUnlock;
    if (diff == null || diff == Duration.zero) return '已可解锁';
    if (diff.inDays > 0) {
      return '${diff.inDays} 天';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours} 小时';
    }
    return '${diff.inMinutes} 分钟';
  }
}

