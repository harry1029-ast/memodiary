import 'dart:isolate';
import 'dart:math';
import 'package:memodiary/core/database/app_database.dart';
import 'event_suggestion_vocabulary.dart';

/// Represents a ranked historical event or topic suggestion chip.
class EventSuggestion {
  final String term;
  final String label;
  final int count;
  final DateTime lastSeen;
  final double score;
  final bool isCurated;

  const EventSuggestion({
    required this.term,
    required this.label,
    required this.count,
    required this.lastSeen,
    required this.score,
    this.isCurated = true,
  });
}

/// Offline analyzer scanning active entries to extract and rank frequent historical
/// event/topic terms (curated vocabulary + recurring title tokens).
class EventSuggestionService {
  final AppDatabase database;

  const EventSuggestionService(this.database);

  /// Scans active entries (offloading to a background Isolate for large datasets
  /// or when [forceIsolate] is true) and returns up to [limit] smart event
  /// suggestions ordered by frequency and recency.
  Future<List<EventSuggestion>> getSuggestions({
    int limit = 8,
    DateTime? now,
    int minRecurringTitleCount = 3,
    bool forceIsolate = false,
  }) async {
    final activeEntries = await database.entriesDao.getAllActiveEntries();
    if (activeEntries.isEmpty) return const [];

    final refNow = now ?? DateTime.now();
    if (!forceIsolate && activeEntries.length < 100) {
      return rankFromEntries(
        activeEntries,
        now: refNow,
        limit: limit,
        minRecurringTitleCount: minRecurringTitleCount,
      );
    }

    // Serialize minimal primitives for Isolate transfer
    final rawRecords = activeEntries
        .map((entry) => <String, Object?>{
              'id': entry.id,
              'title': entry.title,
              'plainText': entry.plainText,
              'entryDateMs': entry.entryDate.millisecondsSinceEpoch,
              'unlockAtMs': entry.unlockAt?.millisecondsSinceEpoch,
              'isDeleted': entry.isDeleted,
              'isLocked': entry.isLocked,
            })
        .toList();

    final refNowMs = refNow.millisecondsSinceEpoch;

    return Isolate.run(() {
      final reconstructed = rawRecords
          .map((record) => _LightweightEntry(
                id: record['id'] as String,
                title: record['title'] as String?,
                plainText: record['plainText'] as String,
                entryDate: DateTime.fromMillisecondsSinceEpoch(
                  record['entryDateMs'] as int,
                ),
                unlockAt: record['unlockAtMs'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        record['unlockAtMs'] as int,
                      )
                    : null,
                isDeleted: record['isDeleted'] as bool,
                isLocked: record['isLocked'] as bool,
              ))
          .toList();

      return _rankLightweightEntries(
        reconstructed,
        now: DateTime.fromMillisecondsSinceEpoch(refNowMs),
        limit: limit,
        minRecurringTitleCount: minRecurringTitleCount,
      );
    });
  }

  /// Pure synchronous ranking method for unit testing and isolate execution.
  static List<EventSuggestion> rankFromEntries(
    List<Entry> entries, {
    DateTime? now,
    int limit = 8,
    int minRecurringTitleCount = 3,
  }) {
    final refNow = now ?? DateTime.now();
    final lightweight = entries
        .map((entry) => _LightweightEntry(
              id: entry.id,
              title: entry.title,
              plainText: entry.plainText,
              entryDate: entry.entryDate,
              unlockAt: entry.unlockAt,
              isDeleted: entry.isDeleted,
              isLocked: entry.isLocked,
            ))
        .toList();

    return _rankLightweightEntries(
      lightweight,
      now: refNow,
      limit: limit,
      minRecurringTitleCount: minRecurringTitleCount,
    );
  }

  static List<EventSuggestion> _rankLightweightEntries(
    List<_LightweightEntry> entries, {
    required DateTime now,
    required int limit,
    required int minRecurringTitleCount,
  }) {
    if (limit <= 0) return const [];

    // 1. Filter out deleted entries and sealed time capsules
    final eligible = entries.where((entry) {
      if (entry.isDeleted) return false;
      if (entry.unlockAt != null && entry.unlockAt!.isAfter(now)) return false;
      return true;
    }).toList();

    if (eligible.isEmpty) return const [];

    final allCuratedSynonymsLower = <String>{};
    for (final group in EventSuggestionVocabulary.curatedGroups) {
      allCuratedSynonymsLower.addAll(group.zhSynonyms);
      allCuratedSynonymsLower
          .addAll(group.enSynonyms.map((synonym) => synonym.toLowerCase()));
    }

    final suggestions = <EventSuggestion>[];

    // 2. Evaluate Curated Topic Groups (merges Chinese & English synonyms)
    for (final group in EventSuggestionVocabulary.curatedGroups) {
      int matchedCount = 0;
      int zhMatchCount = 0;
      DateTime? latestDate;

      final enRegexes = group.enSynonyms
          .map((word) =>
              RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false))
          .toList();

      for (final entry in eligible) {
        // Privacy invariant: locked entries are inspected ONLY via their title, never their body
        final searchableText = entry.isLocked
            ? (entry.title ?? '')
            : '${entry.title ?? ''}\n${entry.plainText}';

        if (searchableText.trim().isEmpty) continue;

        bool hasZh = false;
        for (final zhSyn in group.zhSynonyms) {
          if (searchableText.contains(zhSyn)) {
            hasZh = true;
            break;
          }
        }

        bool hasEn = false;
        if (!hasZh) {
          for (final rx in enRegexes) {
            if (rx.hasMatch(searchableText)) {
              hasEn = true;
              break;
            }
          }
        }

        if (hasZh || hasEn) {
          matchedCount++;
          if (hasZh) zhMatchCount++;
          if (latestDate == null || entry.entryDate.isAfter(latestDate)) {
            latestDate = entry.entryDate;
          }
        }
      }

      if (matchedCount > 0 && latestDate != null) {
        final chosenTerm =
            zhMatchCount > 0 ? group.zhCanonical : group.enCanonical;
        final score = _computeScore(matchedCount, latestDate, now);
        suggestions.add(
          EventSuggestion(
            term: chosenTerm,
            label: chosenTerm,
            count: matchedCount,
            lastSeen: latestDate,
            score: score,
            isCurated: true,
          ),
        );
      }
    }

    // 3. Extract Recurring Title Tokens (threshold >= minRecurringTitleCount)
    final titleTokenCounts = <String, int>{};
    final titleTokenLatest = <String, DateTime>{};
    final titleTokenDisplay = <String, String>{};

    for (final entry in eligible) {
      final rawTitle = entry.title?.trim();
      if (rawTitle == null || rawTitle.isEmpty) continue;

      final entryTokens = _extractTokensFromTitle(rawTitle);
      for (final token in entryTokens) {
        final normKey = token.toLowerCase();
        if (allCuratedSynonymsLower.contains(normKey)) {
          continue; // Already covered by curated vocabulary
        }
        titleTokenCounts[normKey] = (titleTokenCounts[normKey] ?? 0) + 1;
        titleTokenDisplay.putIfAbsent(normKey, () => token);
        final prevDate = titleTokenLatest[normKey];
        if (prevDate == null || entry.entryDate.isAfter(prevDate)) {
          titleTokenLatest[normKey] = entry.entryDate;
        }
      }
    }

    final candidateKeys = titleTokenCounts.entries
        .where((entry) => entry.value >= minRecurringTitleCount)
        .map((entry) => entry.key)
        .toList();

    for (final normKey in candidateKeys) {
      final count = titleTokenCounts[normKey]!;
      // Suppress shorter CJK substrings when a longer super-phrase has >= count
      final isSubsumed = candidateKeys.any(
        (other) =>
            other != normKey &&
            other.length > normKey.length &&
            other.contains(normKey) &&
            (titleTokenCounts[other]! >= count),
      );
      if (isSubsumed) continue;

      final lastSeen = titleTokenLatest[normKey]!;
      final display = titleTokenDisplay[normKey]!;
      final score = _computeScore(count, lastSeen, now);
      suggestions.add(
        EventSuggestion(
          term: display,
          label: display,
          count: count,
          lastSeen: lastSeen,
          score: score,
          isCurated: false,
        ),
      );
    }

    // 4. Sort descending by score, then count, then lastSeen, then alphabetically
    suggestions.sort((left, right) {
      final scoreCmp = right.score.compareTo(left.score);
      if (scoreCmp != 0) return scoreCmp;
      final countCmp = right.count.compareTo(left.count);
      if (countCmp != 0) return countCmp;
      final dateCmp = right.lastSeen.compareTo(left.lastSeen);
      if (dateCmp != 0) return dateCmp;
      return left.term.compareTo(right.term);
    });

    return suggestions.take(limit).toList();
  }

  static Set<String> _extractTokensFromTitle(String title) {
    final result = <String>{};

    // 1. English words (3+ letters)
    final enMatches = RegExp(r'\b[a-zA-Z]{3,}\b').allMatches(title);
    for (final match in enMatches) {
      final word = match.group(0)!;
      if (!EventSuggestionVocabulary.enStopWords.contains(word.toLowerCase())) {
        result.add(word);
      }
    }

    // 2. Contiguous CJK segments and their 2..6 char prefixes/ngrams
    final zhMatches = RegExp(r'[\u4e00-\u9fff]{2,12}').allMatches(title);
    for (final match in zhMatches) {
      var seg = match.group(0)!;
      for (final suffix in EventSuggestionVocabulary.zhStopWords) {
        if (seg.endsWith(suffix) && seg.length > suffix.length) {
          seg = seg.substring(0, seg.length - suffix.length);
        }
      }
      if (seg.length < 2 ||
          EventSuggestionVocabulary.zhStopWords.contains(seg)) {
        continue;
      }

      if (seg.length <= 6) {
        result.add(seg);
      }
      // Also add 2..6 char prefixes so unspaced CJK titles with varying suffixes
      // (e.g. '马拉松训练准备', '马拉松训练冲刺') share their common stem ('马拉松训练').
      final maxPrefix = min(6, seg.length);
      for (int len = 2; len <= maxPrefix; len++) {
        final prefix = seg.substring(0, len);
        if (!EventSuggestionVocabulary.zhStopWords.contains(prefix)) {
          result.add(prefix);
        }
      }
    }

    return result;
  }

  static double _computeScore(int count, DateTime lastSeen, DateTime now) {
    final daysSince = max(0, now.difference(lastSeen).inDays);
    final recencyBoost = (1.0 - (daysSince / 180.0)).clamp(0.0, 1.0);
    return count * (1.0 + 0.5 * recencyBoost);
  }
}

class _LightweightEntry {
  final String id;
  final String? title;
  final String plainText;
  final DateTime entryDate;
  final DateTime? unlockAt;
  final bool isDeleted;
  final bool isLocked;

  const _LightweightEntry({
    required this.id,
    required this.title,
    required this.plainText,
    required this.entryDate,
    required this.unlockAt,
    required this.isDeleted,
    required this.isLocked,
  });
}
