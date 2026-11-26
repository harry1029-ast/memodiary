import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_summary.dart';

/// Compound model combining a lightweight [TimelineEntrySummary] with its
/// optional visual template and primary media attachment.
class TimelineEntryItem {
  final TimelineEntrySummary summary;
  final Template? template;
  final MediaAttachment? primaryMedia;

  TimelineEntryItem({
    TimelineEntrySummary? summary,
    Entry? entry,
    this.template,
    this.primaryMedia,
  })  : assert(
          summary != null || entry != null,
          'Either summary or entry must be provided.',
        ),
        summary = summary ?? TimelineEntrySummary.fromEntry(entry!);

  /// True if the entry has an unlock date in the future (Time Capsule)
  bool get isSealedTimeCapsule {
    final unlockAt = summary.unlockAt;
    if (unlockAt == null) return false;
    return DateTime.now().isBefore(unlockAt);
  }

  /// Remaining duration until the time capsule unlocks
  Duration? get timeUntilUnlock {
    final unlockAt = summary.unlockAt;
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

