import 'dart:math';
import 'package:drift/drift.dart';
import '../../../features/weekly_review/services/calendar_week_utils.dart';
import '../app_database.dart';
import '../tables/entries.dart';
import '../tables/media_attachments.dart';
import 'media_reference_utils.dart';

part 'entries_dao.g.dart';

/// Data access object for diary [Entries], timeline pagination, FTS5/CJK search,
/// recycle-bin lifecycle, weekly reviews, and retrospective queries.
@DriftAccessor(tables: [Entries, MediaAttachments])
class EntriesDao extends DatabaseAccessor<AppDatabase> with _$EntriesDaoMixin {
  EntriesDao(super.attachedDatabase);

  static final RegExp _cjkCharacterRegex = RegExp(r'[\u4e00-\u9fff]');

  /// Resolves candidate entry IDs matching [trimmedQuery] via `entries_fts MATCH`
  /// plus escaped CJK substring `LIKE` matching when Han characters are present.
  Future<Set<String>> _findMatchingEntryIds(String trimmedQuery) async {
    final escaped = trimmedQuery.replaceAll('"', '""');
    final ftsRows = await customSelect(
      'SELECT id FROM entries_fts WHERE entries_fts MATCH ?',
      variables: [Variable.withString('"$escaped"*')],
      readsFrom: {entries},
    ).get();

    final ids = ftsRows.map((row) => row.read<String>('id')).toSet();

    if (_cjkCharacterRegex.hasMatch(trimmedQuery)) {
      final escapedLike =
          '%${trimmedQuery.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
      final likeRows = await customSelect(
        r"SELECT id FROM entries WHERE is_deleted = 0 AND (coalesce(title, '') LIKE ? ESCAPE '\' OR plain_text LIKE ? ESCAPE '\')",
        variables: [
          Variable.withString(escapedLike),
          Variable.withString(escapedLike),
        ],
        readsFrom: {entries},
      ).get();
      ids.addAll(likeRows.map((row) => row.read<String>('id')));
    }

    return ids;
  }

  /// Performs full-text search across entry title and plain text using FTS5,
  /// supplemented with escaped substring matching for CJK characters.
  Future<List<Entry>> searchEntries(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final ids = await _findMatchingEntryIds(trimmed);
    if (ids.isEmpty) return [];

    return (select(entries)
          ..where((entry) => entry.id.isIn(ids) & entry.isDeleted.equals(false)))
        .get();
  }

  /// Multi-condition search combining FTS5 full-text indexing with relational filters.
  Future<List<Entry>> searchEntriesWithFilters({
    String query = '',
    DateTime? startDate,
    DateTime? endDate,
    int? mood,
    String? weather,
    bool hasImage = false,
    bool weeklyReviewOnly = false,
    int limit = 50,
    bool excludeSealedTimeCapsules = true,
  }) async {
    final trimmed = query.trim();
    Set<String>? ftsMatchedIds;

    if (trimmed.isNotEmpty) {
      ftsMatchedIds = await _findMatchingEntryIds(trimmed);
      if (ftsMatchedIds.isEmpty) return [];
    }

    Set<String>? imageEntryIds;
    if (hasImage) {
      final mediaRows = await (selectOnly(mediaAttachments, distinct: true)
            ..addColumns([mediaAttachments.entryId]))
          .get();
      imageEntryIds = mediaRows
          .map((row) => row.read(mediaAttachments.entryId)!)
          .toSet();
      if (imageEntryIds.isEmpty) return [];
    }

    final now = DateTime.now();

    final queryBuilder = select(entries)
      ..where((entry) {
        Expression<bool> predicate = entry.isDeleted.equals(false);

        if (ftsMatchedIds != null) {
          predicate = predicate & entry.id.isIn(ftsMatchedIds);
        }
        if (imageEntryIds != null) {
          predicate = predicate & entry.id.isIn(imageEntryIds);
        }
        if (startDate != null) {
          predicate = predicate & entry.entryDate.isBiggerOrEqualValue(startDate);
        }
        if (endDate != null) {
          predicate = predicate & entry.entryDate.isSmallerOrEqualValue(endDate);
        }
        if (mood != null) {
          predicate = predicate & entry.mood.equals(mood);
        }
        if (weather != null && weather.isNotEmpty) {
          predicate = predicate & entry.weather.equals(weather);
        }
        if (weeklyReviewOnly) {
          predicate = predicate & entry.isWeeklyReview.equals(true);
        }
        if (excludeSealedTimeCapsules) {
          predicate = predicate &
              (entry.unlockAt.isNull() |
                  entry.unlockAt.isSmallerOrEqualValue(now));
        }

        return predicate;
      })
      ..orderBy([(entry) => OrderingTerm.desc(entry.entryDate)])
      ..limit(limit);

    return queryBuilder.get();
  }

  /// Inserts a new entry into the database.
  Future<int> createEntry(EntriesCompanion entry) => into(entries).insert(entry);

  /// Inserts a new entry and returns the persisted [Entry] row.
  Future<Entry> createEntryReturning(EntriesCompanion entry) =>
      into(entries).insertReturning(entry);

  /// Retrieves a single entry by its [id].
  Future<Entry?> getEntryById(String id) {
    return (select(entries)..where((entry) => entry.id.equals(id)))
        .getSingleOrNull();
  }

  /// Retrieves paginated timeline entries ordered reverse-chronologically.
  Future<List<Entry>> getTimelineEntries({int limit = 20, int offset = 0}) {
    return (select(entries)
          ..where((entry) => entry.isDeleted.equals(false))
          ..orderBy([(entry) => OrderingTerm.desc(entry.entryDate)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Retrieves all non-deleted entries without pagination.
  Future<List<Entry>> getAllActiveEntries() {
    return (select(entries)
          ..where((entry) => entry.isDeleted.equals(false))
          ..orderBy([(entry) => OrderingTerm.desc(entry.entryDate)]))
        .get();
  }

  /// Updates an entry's visual template without mutating contentDelta or plainText.
  Future<int> updateEntryTemplate(String entryId, String newTemplateId) {
    return (update(entries)..where((entry) => entry.id.equals(entryId))).write(
      EntriesCompanion(
        templateId: Value(newTemplateId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Updates an entry's Delta content and plainText representation (triggers FTS5 update).
  Future<int> updateEntryContent(
    String entryId,
    String contentDelta,
    String plainText,
  ) {
    return (update(entries)..where((entry) => entry.id.equals(entryId))).write(
      EntriesCompanion(
        contentDelta: Value(contentDelta),
        plainText: Value(plainText),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Persists the legacy mounting pass result for [entryId] without touching `updatedAt`.
  Future<int> completeLegacyMountPass(
    String entryId, {
    required String contentDelta,
  }) {
    return (update(entries)..where((entry) => entry.id.equals(entryId))).write(
      EntriesCompanion(
        contentDelta: Value(contentDelta),
        legacyMountsPending: const Value(false),
      ),
    );
  }

  /// Updates entry metadata (date, mood, weather, unlockAt, title).
  Future<int> updateEntryMetadata(
    String entryId, {
    DateTime? entryDate,
    int? mood,
    String? weather,
    DateTime? unlockAt,
    String? title,
  }) {
    return (update(entries)..where((entry) => entry.id.equals(entryId))).write(
      EntriesCompanion(
        entryDate: entryDate != null ? Value(entryDate) : const Value.absent(),
        mood: mood != null ? Value(mood) : const Value.absent(),
        weather: weather != null ? Value(weather) : const Value.absent(),
        unlockAt: unlockAt != null ? Value(unlockAt) : const Value.absent(),
        title: title != null ? Value(title) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Updates or clears the entry's Time Capsule unlockAt timestamp.
  Future<int> updateEntryUnlockAt(String entryId, DateTime? unlockAt) {
    return (update(entries)..where((entry) => entry.id.equals(entryId))).write(
      EntriesCompanion(
        unlockAt: Value(unlockAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Locks a specific entry with an optional custom salted SHA-256 PIN hash.
  Future<int> lockEntry(String entryId, {String? pinHash}) {
    return (update(entries)..where((entry) => entry.id.equals(entryId))).write(
      EntriesCompanion(
        isLocked: const Value(true),
        entryPinHash: Value(pinHash),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Permanently unlocks a specific entry and clears any custom entry PIN hash.
  Future<int> unlockEntryPermanently(String entryId) {
    return (update(entries)..where((entry) => entry.id.equals(entryId))).write(
      EntriesCompanion(
        isLocked: const Value(false),
        entryPinHash: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Soft deletes an entry (moves to 30-day recycle bin).
  Future<int> softDeleteEntry(String entryId) {
    return (update(entries)..where((entry) => entry.id.equals(entryId))).write(
      EntriesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Restores an entry from the recycle bin back to the active timeline.
  Future<int> restoreEntry(String entryId) {
    return (update(entries)..where((entry) => entry.id.equals(entryId))).write(
      EntriesCompanion(
        isDeleted: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Retrieves soft-deleted entries ordered by most recently deleted.
  Future<List<Entry>> getDeletedEntries() {
    return (select(entries)
          ..where((entry) => entry.isDeleted.equals(true))
          ..orderBy([(entry) => OrderingTerm.desc(entry.updatedAt)]))
        .get();
  }

  /// Retrieves soft-deleted entries that have exceeded [retention].
  Future<List<Entry>> getExpiredDeletedEntries({
    Duration retention = const Duration(days: 30),
  }) {
    final threshold = DateTime.now().subtract(retention);
    return (select(entries)
          ..where((entry) =>
              entry.isDeleted.equals(true) &
              entry.updatedAt.isSmallerThanValue(threshold)))
        .get();
  }

  /// Permanently removes SQLite records for [entryId] and its media attachments.
  Future<int> hardDeleteEntryRecords(String entryId) async {
    return transaction(() async {
      await (delete(mediaAttachments)
            ..where((attachment) => attachment.entryId.equals(entryId)))
          .go();
      return (delete(entries)..where((entry) => entry.id.equals(entryId))).go();
    });
  }

  /// Permanently removes SQLite records for [entryId] inside a transaction and
  /// returns strictly the candidate media relative paths that are no longer
  /// referenced by `albumCollections`, `albumPhotos`, or remaining `mediaAttachments`.
  Future<List<String>> hardDeleteEntryAndCollectMediaPaths(
    String entryId,
  ) async {
    return transaction(() async {
      final attachments = await (select(mediaAttachments)
            ..where((attachment) => attachment.entryId.equals(entryId)))
          .get();

      final candidatePaths = <String>{};
      for (final attachment in attachments) {
        addNormalizedMediaPath(candidatePaths, attachment.relativePath);
        addNormalizedMediaPath(candidatePaths, attachment.thumbnailPath);
      }

      await (delete(mediaAttachments)
            ..where((attachment) => attachment.entryId.equals(entryId)))
          .go();
      await (delete(entries)..where((entry) => entry.id.equals(entryId))).go();

      return filterUnreferencedMediaPaths(attachedDatabase, candidatePaths);
    });
  }

  /// Atomically inserts multiple entries within a single transaction.
  Future<int> batchImportEntries(List<EntriesCompanion> companions) {
    return transaction(() async {
      var count = 0;
      for (final companion in companions) {
        await into(entries).insert(companion);
        count++;
      }
      return count;
    });
  }

  /// Fetches all non-deleted entries falling within the given ISO 8601 [year] and [weekNumber].
  Future<List<Entry>> getEntriesForCalendarWeek(int year, int weekNumber) {
    final range = CalendarWeekUtils.getIsoWeekRange(year, weekNumber);
    return (select(entries)
          ..where((entry) =>
              entry.isDeleted.equals(false) &
              entry.entryDate.isBiggerOrEqualValue(range.start) &
              entry.entryDate.isSmallerOrEqualValue(range.end))
          ..orderBy([(entry) => OrderingTerm.asc(entry.entryDate)]))
        .get();
  }

  /// Finds an existing weekly review entry (`isWeeklyReview = true`) for [year] and [weekNumber].
  Future<Entry?> getWeeklyReviewEntry(int year, int weekNumber) async {
    final range = CalendarWeekUtils.getIsoWeekRange(year, weekNumber);
    final candidates = await (select(entries)
          ..where((entry) =>
              entry.isDeleted.equals(false) &
              entry.isWeeklyReview.equals(true) &
              (entry.weekNumber.equals(weekNumber) |
                  (entry.entryDate.isBiggerOrEqualValue(range.start) &
                      entry.entryDate.isSmallerOrEqualValue(range.end))))
          ..orderBy([(entry) => OrderingTerm.desc(entry.updatedAt)]))
        .get();

    for (final entry in candidates) {
      final entryWeekInfo = CalendarWeekUtils.getIsoWeekAndYear(entry.entryDate);
      if (entryWeekInfo.year == year &&
          (entry.weekNumber == weekNumber ||
              entryWeekInfo.weekNumber == weekNumber)) {
        return entry;
      }
    }
    return null;
  }

  /// Checks whether [year] is a Gregorian leap year.
  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Fetches all active entries written on the same month and day in previous
  /// calendar years (`entryDate.year < date.year`), including Feb 29 memories
  /// on Feb 28 of non-leap years.
  Future<List<Entry>> getEntriesOnThisDay(DateTime date) async {
    final priorYearCutoff = DateTime(date.year, 1, 1);
    final priorCandidates = await (select(entries)
          ..where((entry) =>
              entry.isDeleted.equals(false) &
              entry.entryDate.isSmallerThanValue(priorYearCutoff))
          ..orderBy([(entry) => OrderingTerm.desc(entry.entryDate)]))
        .get();

    final includeLeapFeb29OnFeb28 =
        date.month == 2 && date.day == 28 && !isLeapYear(date.year);

    return priorCandidates.where((entry) {
      final entryDate = entry.entryDate;
      if (entryDate.month == date.month && entryDate.day == date.day) {
        return true;
      }
      if (includeLeapFeb29OnFeb28 &&
          entryDate.month == 2 &&
          entryDate.day == 29) {
        return true;
      }
      return false;
    }).toList();
  }

  /// Randomly draws a past active entry written at least [minDaysAgo] days prior
  /// to [referenceDate], excluding sealed time capsules.
  Future<Entry?> getRandomOldEntry({
    int minDaysAgo = 90,
    DateTime? referenceDate,
    Random? random,
  }) async {
    final now = referenceDate ?? DateTime.now();
    final cutoff = now.subtract(Duration(days: minDaysAgo));

    final candidates = await (select(entries)
          ..where((entry) =>
              entry.isDeleted.equals(false) &
              entry.entryDate.isSmallerOrEqualValue(cutoff) &
              (entry.unlockAt.isNull() |
                  entry.unlockAt.isSmallerOrEqualValue(now))))
        .get();

    if (candidates.isEmpty) return null;

    final rng = random ?? Random();
    return candidates[rng.nextInt(candidates.length)];
  }
}
