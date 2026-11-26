import 'package:memodiary/features/scenery/models/shanshui_atmosphere.dart';
import 'package:memodiary/features/scenery/services/shanshui_atmosphere_resolver.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_summary.dart';

/// Resolves the live `Shanshui Scenery Card` atmosphere from the latest
/// eligible diary entry summaries and active [realmPreference].
ShanshuiAtmosphereState resolveTimelineAtmosphere({
  required List<TimelineEntrySummary> recentEntriesForScenery,
  required List<TimelineEntrySummary> fallbackEntries,
  required SceneryRealmPreference realmPreference,
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  final sourceEntries =
      recentEntriesForScenery.isNotEmpty ? recentEntriesForScenery : fallbackEntries;

  TimelineEntrySummary? eligibleEntry;
  for (final entry in sourceEntries) {
    if (ShanshuiAtmosphereResolver.isEntryEligibleForInference(
      isDeleted: entry.isDeleted,
      isLocked: entry.isLocked,
      unlockAt: entry.unlockAt,
      now: effectiveNow,
    )) {
      eligibleEntry = entry;
      break;
    }
  }

  final latestWeather =
      sourceEntries.isNotEmpty ? sourceEntries.first.weather : null;
  return ShanshuiAtmosphereResolver.resolve(
    now: effectiveNow,
    latestEntryWeather: latestWeather,
    entryTimestamp: eligibleEntry?.entryDate,
    entryTitle: eligibleEntry?.title,
    entryPlainText: eligibleEntry?.plainTextSnippet,
    realmPreference: realmPreference,
  );
}
