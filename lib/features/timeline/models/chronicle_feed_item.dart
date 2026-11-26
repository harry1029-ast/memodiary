import 'package:flutter/foundation.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_summary.dart';

/// Base item inside the flattened `ChronicleDeskFeedSliver` entry sequence,
/// interleaving `Month Spine Divider` headers and diary entry slips.
@immutable
sealed class ChronicleFeedItem {
  const ChronicleFeedItem();
}

/// Inline `YYYY年M月` Month Spine Divider header along the Chronicle Desk's
/// vertical spine.
@immutable
final class ChronicleMonthDividerItem extends ChronicleFeedItem {
  final int year;
  final int month;
  final bool isFirstInFeed;

  const ChronicleMonthDividerItem({
    required this.year,
    required this.month,
    required this.isFirstInFeed,
  });

  /// Plain modern Chinese label formatted as `YYYY年M月`.
  String get label => '$year年$month月';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChronicleMonthDividerItem &&
        other.year == year &&
        other.month == month &&
        other.isFirstInFeed == isFirstInFeed;
  }

  @override
  int get hashCode => Object.hash(year, month, isFirstInFeed);
}

/// Diary entry slip item carrying its index within the loaded [entries] list.
@immutable
final class ChronicleEntryFeedItem extends ChronicleFeedItem {
  final TimelineEntrySummary summary;
  final int entryIndex;
  final bool isLastEntry;

  const ChronicleEntryFeedItem({
    required this.summary,
    required this.entryIndex,
    required this.isLastEntry,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChronicleEntryFeedItem &&
        other.summary == summary &&
        other.entryIndex == entryIndex &&
        other.isLastEntry == isLastEntry;
  }

  @override
  int get hashCode => Object.hash(summary, entryIndex, isLastEntry);
}

/// Builds the interleaved sequence of [ChronicleMonthDividerItem] headers and
/// [ChronicleEntryFeedItem] rows for a sorted list of [entries].
///
/// Emits a divider before index `0` and whenever consecutive entries differ in
/// calendar year or month.
List<ChronicleFeedItem> buildChronicleFeedItems(
  List<TimelineEntrySummary> entries,
) {
  if (entries.isEmpty) return const [];

  final items = <ChronicleFeedItem>[];
  int? previousYear;
  int? previousMonth;

  for (var index = 0; index < entries.length; index++) {
    final summary = entries[index];
    final year = summary.entryDate.year;
    final month = summary.entryDate.month;
    if (previousYear != year || previousMonth != month) {
      items.add(
        ChronicleMonthDividerItem(
          year: year,
          month: month,
          isFirstInFeed: index == 0,
        ),
      );
      previousYear = year;
      previousMonth = month;
    }
    items.add(
      ChronicleEntryFeedItem(
        summary: summary,
        entryIndex: index,
        isLastEntry: index == entries.length - 1,
      ),
    );
  }

  return items;
}
