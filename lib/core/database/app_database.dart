import 'dart:io';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:uuid/uuid.dart';
import '../../features/import_export/models/backup_manifest.dart';
import '../../features/weekly_review/services/calendar_week_utils.dart';
import 'tables/templates.dart';
import 'tables/notebooks.dart';
import 'tables/entries.dart';
import 'tables/media_attachments.dart';

part 'app_database.g.dart';

/// Top-level isolate setup to ensure background isolates load SQLCipher on Android
@pragma('vm:entry-point')
void _isolateDatabaseSetup() {
  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }
}

/// MemoDiary core encrypted database with SQLCipher and FTS5 search.
@DriftDatabase(tables: [Templates, Notebooks, Entries, MediaAttachments])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Testing constructor using an arbitrary executor (e.g. NativeDatabase.memory())
  AppDatabase.forTesting(super.e);

  /// Factory constructor for encrypted database file using SQLCipher
  factory AppDatabase.encrypted({
    required File dbFile,
    required String encryptionKey,
  }) {
    if (Platform.isAndroid) {
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    }

    final executor = NativeDatabase.createInBackground(
      dbFile,
      isolateSetup: _isolateDatabaseSetup,
      setup: (rawDb) {
        final escapedKey = encryptionKey.replaceAll("'", "''");
        rawDb.execute("PRAGMA key = '$escapedKey';");
      },
    );
    return AppDatabase(executor);
  }

  /// In-memory database factory for quick testing
  factory AppDatabase.memory() {
    return AppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          // 1. Create standard Drift tables
          await m.createAll();

          // 2. Create SQLite FTS5 Virtual Table for full-text search
          await customStatement('''
            CREATE VIRTUAL TABLE IF NOT EXISTS entries_fts USING fts5(
              id UNINDEXED,
              title,
              plain_text,
              tokenize='unicode61'
            );
          ''');

          // 3. Create triggers to automatically keep FTS5 synchronized with entries table
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS entries_ai AFTER INSERT ON entries BEGIN
              INSERT INTO entries_fts(id, title, plain_text)
              VALUES (new.id, coalesce(new.title, ''), new.plain_text);
            END;
          ''');

          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS entries_au AFTER UPDATE ON entries BEGIN
              UPDATE entries_fts
              SET title = coalesce(new.title, ''),
                  plain_text = new.plain_text
              WHERE id = new.id;
            END;
          ''');

          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS entries_ad AFTER DELETE ON entries BEGIN
              DELETE FROM entries_fts WHERE id = old.id;
            END;
          ''');

          // 4. Create index for ultra-fast reverse-chronological timeline pagination
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_entries_timeline ON entries(is_deleted, entry_date DESC);
          ''');

          // 5. Seed the 4 default templates
          await batch((b) {
            b.insertAll(templates, [
              TemplatesCompanion.insert(
                id: 'template_minimalist_white',
                name: 'Minimalist White',
                backgroundType: 'color',
                backgroundValue: '#FFFFFF',
                fontFamily: const Value('System'),
                lineSpacing: const Value(1.5),
                marginHorizontal: const Value(20.0),
                isCustom: const Value(false),
              ),
              TemplatesCompanion.insert(
                id: 'template_lined_paper',
                name: 'Lined Paper',
                backgroundType: 'lined',
                backgroundValue: '#FDFBF7',
                fontFamily: const Value('System'),
                lineSpacing: const Value(1.8),
                marginHorizontal: const Value(24.0),
                isCustom: const Value(false),
              ),
              TemplatesCompanion.insert(
                id: 'template_retro_kraft',
                name: 'Retro Kraft Scrapbook',
                backgroundType: 'paper_texture',
                backgroundValue: '#EFE6D5',
                fontFamily: const Value('System'),
                lineSpacing: const Value(1.6),
                marginHorizontal: const Value(20.0),
                isCustom: const Value(false),
              ),
              TemplatesCompanion.insert(
                id: 'template_weekly_review',
                name: 'Weekly Review',
                backgroundType: 'grid',
                backgroundValue: '#F4F5F7',
                fontFamily: const Value('System'),
                lineSpacing: const Value(1.5),
                marginHorizontal: const Value(16.0),
                isCustom: const Value(false),
              ),
            ]);

            // 5. Seed default notebook so entries can be inserted immediately
            b.insert(
              notebooks,
              NotebooksCompanion.insert(
                id: 'notebook_default',
                title: 'My Diary',
                defaultTemplateId: 'template_minimalist_white',
              ),
            );
          });
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(entries, entries.isLocked);
            await m.addColumn(entries, entries.entryPinHash);
          }
        },
      );

  /// Performs full-text search across entry title and plain text using FTS5,
  /// supplemented with escaped substring matching for CJK characters.
  Future<List<Entry>> searchEntries(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    // Escape quotes for safe FTS5 query syntax
    final escaped = trimmed.replaceAll('"', '""');
    final ftsRows = await customSelect(
      'SELECT id FROM entries_fts WHERE entries_fts MATCH ?',
      variables: [Variable.withString('"$escaped"*')],
      readsFrom: {entries},
    ).get();

    final ids = ftsRows.map((r) => r.read<String>('id')).toSet();

    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(trimmed)) {
      final escapedLike =
          '%${trimmed.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
      final likeRows = await customSelect(
        r"SELECT id FROM entries WHERE is_deleted = 0 AND (coalesce(title, '') LIKE ? ESCAPE '\' OR plain_text LIKE ? ESCAPE '\')",
        variables: [
          Variable.withString(escapedLike),
          Variable.withString(escapedLike),
        ],
        readsFrom: {entries},
      ).get();
      ids.addAll(likeRows.map((r) => r.read<String>('id')));
    }

    if (ids.isEmpty) return [];

    return (select(entries)
          ..where((t) => t.id.isIn(ids) & t.isDeleted.equals(false)))
        .get();
  }

  /// Retrieves all visual templates
  Future<List<Template>> getAllTemplates() => select(templates).get();

  /// Retrieves a template by its ID
  Future<Template?> getTemplateById(String id) {
    return (select(templates)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Retrieves all notebooks
  Future<List<Notebook>> getAllNotebooks() => select(notebooks).get();

  /// Inserts a new notebook into the database
  Future<int> createNotebook(NotebooksCompanion notebook) => into(notebooks).insert(notebook);

  /// Inserts a new entry into the database
  Future<int> createEntry(EntriesCompanion entry) => into(entries).insert(entry);

  /// Retrieves a single entry by its ID
  Future<Entry?> getEntryById(String id) {
    return (select(entries)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Updates an entry's visual template without mutating contentDelta or plainText
  Future<int> updateEntryTemplate(String entryId, String newTemplateId) {
    return (update(entries)..where((t) => t.id.equals(entryId))).write(
      EntriesCompanion(
        templateId: Value(newTemplateId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Updates an entry's Delta content and plainText representation (triggers FTS5 update)
  Future<int> updateEntryContent(
    String entryId,
    String contentDelta,
    String plainText,
  ) {
    return (update(entries)..where((t) => t.id.equals(entryId))).write(
      EntriesCompanion(
        contentDelta: Value(contentDelta),
        plainText: Value(plainText),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Updates entry metadata (date, mood, weather, unlockAt, title)
  Future<int> updateEntryMetadata(
    String entryId, {
    DateTime? entryDate,
    int? mood,
    String? weather,
    DateTime? unlockAt,
    String? title,
  }) {
    return (update(entries)..where((t) => t.id.equals(entryId))).write(
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

  /// Records a media attachment linked to an entry with strictly relative path
  Future<int> attachMediaToEntry({
    required String id,
    required String entryId,
    required String relativePath,
    String mediaType = 'image',
    String? thumbnailPath,
  }) {
    return into(mediaAttachments).insert(
      MediaAttachmentsCompanion.insert(
        id: id,
        entryId: entryId,
        mediaType: mediaType,
        relativePath: relativePath,
        thumbnailPath: Value(thumbnailPath),
      ),
    );
  }

  /// Retrieves paginated timeline entries ordered reverse-chronologically
  Future<List<Entry>> getTimelineEntries({int limit = 20, int offset = 0}) {
    return (select(entries)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.entryDate)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Retrieves all media attachments associated with a specific entry
  Future<List<MediaAttachment>> getMediaForEntry(String entryId) {
    return (select(mediaAttachments)..where((t) => t.entryId.equals(entryId)))
        .get();
  }

  /// Retrieves all video media attachments associated with a specific entry
  Future<List<MediaAttachment>> getVideosForEntry(String entryId) {
    return (select(mediaAttachments)
          ..where((t) =>
              t.entryId.equals(entryId) & t.mediaType.equals('video')))
        .get();
  }

  /// Batch retrieves the primary (first) media attachment for each given entry ID
  Future<Map<String, MediaAttachment>> getPrimaryMediaForEntries(
      List<String> entryIds) async {
    if (entryIds.isEmpty) return {};
    final records = await (select(mediaAttachments)
          ..where((t) => t.entryId.isIn(entryIds)))
        .get();
    final map = <String, MediaAttachment>{};
    for (final item in records) {
      map.putIfAbsent(item.entryId, () => item);
    }
    return map;
  }

  /// Soft deletes an entry (moves to 30-day recycle bin)
  Future<int> softDeleteEntry(String entryId) {
    return (update(entries)..where((t) => t.id.equals(entryId))).write(
      EntriesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Restores an entry from the recycle bin back to the active timeline
  Future<int> restoreEntry(String entryId) {
    return (update(entries)..where((t) => t.id.equals(entryId))).write(
      EntriesCompanion(
        isDeleted: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Retrieves soft-deleted entries ordered by most recently deleted
  Future<List<Entry>> getDeletedEntries() {
    return (select(entries)
          ..where((t) => t.isDeleted.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  /// Retrieves soft-deleted entries that have exceeded retention period (default 30 days)
  Future<List<Entry>> getExpiredDeletedEntries({
    Duration retention = const Duration(days: 30),
  }) {
    final threshold = DateTime.now().subtract(retention);
    return (select(entries)
          ..where((t) =>
              t.isDeleted.equals(true) &
              t.updatedAt.isSmallerThanValue(threshold)))
        .get();
  }

  /// Permanently removes SQLite records for an entry and its media attachments
  Future<int> hardDeleteEntryRecords(String entryId) async {
    await (delete(mediaAttachments)..where((t) => t.entryId.equals(entryId)))
        .go();
    return (delete(entries)..where((t) => t.id.equals(entryId))).go();
  }

  /// Multi-condition search combining FTS5 full-text indexing with relational filters.
  /// When query is empty, branches directly to relational predicates.
  /// Conceals or excludes sealed Time Capsules to guarantee search privacy.
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

    // 1. Clean query branching: only execute FTS5 MATCH / CJK LIKE if query is non-empty
    if (trimmed.isNotEmpty) {
      final escaped = trimmed.replaceAll('"', '""');
      final ftsRows = await customSelect(
        'SELECT id FROM entries_fts WHERE entries_fts MATCH ?',
        variables: [Variable.withString('"$escaped"*')],
        readsFrom: {entries},
      ).get();

      ftsMatchedIds = ftsRows.map((r) => r.read<String>('id')).toSet();

      if (RegExp(r'[\u4e00-\u9fff]').hasMatch(trimmed)) {
        final escapedLike =
            '%${trimmed.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
        final likeRows = await customSelect(
          r"SELECT id FROM entries WHERE is_deleted = 0 AND (coalesce(title, '') LIKE ? ESCAPE '\' OR plain_text LIKE ? ESCAPE '\')",
          variables: [
            Variable.withString(escapedLike),
            Variable.withString(escapedLike),
          ],
          readsFrom: {entries},
        ).get();
        ftsMatchedIds.addAll(likeRows.map((r) => r.read<String>('id')));
      }

      if (ftsMatchedIds.isEmpty) return [];
    }

    // 2. Has image filter
    Set<String>? imageEntryIds;
    if (hasImage) {
      final mediaRows = await (selectOnly(mediaAttachments, distinct: true)
            ..addColumns([mediaAttachments.entryId]))
          .get();
      imageEntryIds =
          mediaRows.map((r) => r.read(mediaAttachments.entryId)!).toSet();
      if (imageEntryIds.isEmpty) return [];
    }

    final now = DateTime.now();

    // 3. Combine relational filter predicates
    final queryBuilder = select(entries)
      ..where((t) {
        Expression<bool> predicate = t.isDeleted.equals(false);

        if (ftsMatchedIds != null) {
          predicate = predicate & t.id.isIn(ftsMatchedIds);
        }
        if (imageEntryIds != null) {
          predicate = predicate & t.id.isIn(imageEntryIds);
        }
        if (startDate != null) {
          predicate = predicate & t.entryDate.isBiggerOrEqualValue(startDate);
        }
        if (endDate != null) {
          predicate = predicate & t.entryDate.isSmallerOrEqualValue(endDate);
        }
        if (mood != null) {
          predicate = predicate & t.mood.equals(mood);
        }
        if (weather != null && weather.isNotEmpty) {
          predicate = predicate & t.weather.equals(weather);
        }
        if (weeklyReviewOnly) {
          predicate = predicate & t.isWeeklyReview.equals(true);
        }
        // Privacy invariant: sealed capsules are concealed from text search
        if (excludeSealedTimeCapsules) {
          predicate = predicate &
              (t.unlockAt.isNull() | t.unlockAt.isSmallerOrEqualValue(now));
        }

        return predicate;
      })
      ..orderBy([(t) => OrderingTerm.desc(t.entryDate)])
      ..limit(limit);

    return queryBuilder.get();
  }

  /// Atomically inserts multiple entries within a single transaction.
  /// If any insertion fails, the entire batch is rolled back cleanly.
  Future<int> batchImportEntries(List<EntriesCompanion> companions) {
    return transaction(() async {
      int count = 0;
      for (final companion in companions) {
        await into(entries).insert(companion);
        count++;
      }
      return count;
    });
  }

  /// Retrieves a set of all media relative paths currently referenced in media_attachments
  /// (including both primary video/image relativePath and companion poster thumbnailPath).
  Future<Set<String>> getAllMediaRelativePaths() async {
    final rows = await (selectOnly(mediaAttachments, distinct: true)
          ..addColumns([
            mediaAttachments.relativePath,
            mediaAttachments.thumbnailPath,
          ]))
        .get();
    final paths = <String>{};
    for (final r in rows) {
      final rel = r.read(mediaAttachments.relativePath);
      if (rel != null && rel.isNotEmpty) paths.add(rel);
      final thumb = r.read(mediaAttachments.thumbnailPath);
      if (thumb != null && thumb.isNotEmpty) paths.add(thumb);
    }
    return paths;
  }

  /// Retrieves all non-deleted entries without pagination (for full backup export)
  Future<List<Entry>> getAllActiveEntries() {
    return (select(entries)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.entryDate)]))
        .get();
  }

  /// Retrieves only user-defined custom templates (`isCustom = true`).
  Future<List<Template>> getCustomTemplates() {
    return (select(templates)..where((t) => t.isCustom.equals(true))).get();
  }

  /// Creates and persists a new user-defined custom template (strictly enforces `isCustom = true`).
  Future<Template> createCustomTemplate({
    String? id,
    required String name,
    required String backgroundType,
    required String backgroundValue,
    String? fontFamily = 'System',
    double lineSpacing = 1.5,
    double marginHorizontal = 16.0,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Template name cannot be empty.');
    }

    final templateId = id ?? 'template_custom_${const Uuid().v4()}';
    await into(templates).insert(
      TemplatesCompanion.insert(
        id: templateId,
        name: trimmedName,
        backgroundType: backgroundType,
        backgroundValue: backgroundValue,
        fontFamily: Value(fontFamily),
        lineSpacing: Value(lineSpacing),
        marginHorizontal: Value(marginHorizontal),
        isCustom: const Value(true),
      ),
    );

    return (select(templates)..where((t) => t.id.equals(templateId))).getSingle();
  }

  /// Updates an existing custom template.
  /// Throws [StateError] if attempting to modify a seeded system template (`isCustom = false`).
  Future<int> updateCustomTemplate(
    String id, {
    String? name,
    String? backgroundType,
    String? backgroundValue,
    String? fontFamily,
    double? lineSpacing,
    double? marginHorizontal,
  }) async {
    final existing = await getTemplateById(id);
    if (existing == null) {
      throw ArgumentError('Template not found: $id');
    }
    if (!existing.isCustom) {
      throw StateError('Default system templates cannot be modified.');
    }
    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('Template name cannot be empty.');
    }

    return (update(templates)..where((t) => t.id.equals(id))).write(
      TemplatesCompanion(
        name: name != null ? Value(name.trim()) : const Value.absent(),
        backgroundType: backgroundType != null
            ? Value(backgroundType)
            : const Value.absent(),
        backgroundValue: backgroundValue != null
            ? Value(backgroundValue)
            : const Value.absent(),
        fontFamily:
            fontFamily != null ? Value(fontFamily) : const Value.absent(),
        lineSpacing:
            lineSpacing != null ? Value(lineSpacing) : const Value.absent(),
        marginHorizontal: marginHorizontal != null
            ? Value(marginHorizontal)
            : const Value.absent(),
      ),
    );
  }

  /// Reassigns all entries referencing [fromTemplateId] to [toTemplateId]
  /// without mutating entry contentDelta or plainText.
  Future<int> reassignEntriesTemplate({
    required String fromTemplateId,
    required String toTemplateId,
  }) {
    return (update(entries)..where((t) => t.templateId.equals(fromTemplateId)))
        .write(
      EntriesCompanion(
        templateId: Value(toTemplateId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Safely deletes a user-defined custom template.
  /// Throws [StateError] if attempting to delete a seeded system template (`isCustom = false`).
  /// Executes an atomic transaction that first reassigns all dependent entries to [fallbackTemplateId]
  /// prior to deleting the template row, preventing SQLite foreign key constraint violations.
  Future<void> deleteCustomTemplate(
    String templateId, {
    String fallbackTemplateId = 'template_minimalist_white',
  }) async {
    final existing = await getTemplateById(templateId);
    if (existing == null) {
      throw ArgumentError('Template not found: $templateId');
    }
    if (!existing.isCustom) {
      throw StateError('Default system templates cannot be deleted.');
    }

    await transaction(() async {
      // 1. Reassign all entries pointing to this custom template before deleting
      await reassignEntriesTemplate(
        fromTemplateId: templateId,
        toTemplateId: fallbackTemplateId,
      );

      // 2. Delete the custom template record
      await (delete(templates)..where((t) => t.id.equals(templateId))).go();
    });
  }

  /// Fetches all non-deleted entries falling within the given ISO 8601 calendar [year] and [weekNumber]
  /// (Monday 00:00:00.000 through Sunday 23:59:59.999 inclusive), ordered chronologically.
  Future<List<Entry>> getEntriesForCalendarWeek(int year, int weekNumber) {
    final range = CalendarWeekUtils.getIsoWeekRange(year, weekNumber);
    return (select(entries)
          ..where((t) =>
              t.isDeleted.equals(false) &
              t.entryDate.isBiggerOrEqualValue(range.start) &
              t.entryDate.isSmallerOrEqualValue(range.end))
          ..orderBy([(t) => OrderingTerm.asc(t.entryDate)]))
        .get();
  }

  /// Finds an existing weekly review entry (`isWeeklyReview = true`) for the given ISO [year] and [weekNumber].
  Future<Entry?> getWeeklyReviewEntry(int year, int weekNumber) async {
    final range = CalendarWeekUtils.getIsoWeekRange(year, weekNumber);
    final candidates = await (select(entries)
          ..where((t) =>
              t.isDeleted.equals(false) &
              t.isWeeklyReview.equals(true) &
              (t.weekNumber.equals(weekNumber) |
                  (t.entryDate.isBiggerOrEqualValue(range.start) &
                      t.entryDate.isSmallerOrEqualValue(range.end))))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
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

  // ===========================================================================
  // Phase 8: Single-Entry Password Lock & Retrospective Reflection Queries
  // ===========================================================================

  /// Locks a specific entry with an optional custom salted SHA-256 PIN hash.
  /// If [pinHash] is null, the entry relies on the master application PIN or biometric gate.
  Future<int> lockEntry(String entryId, {String? pinHash}) {
    return (update(entries)..where((t) => t.id.equals(entryId))).write(
      EntriesCompanion(
        isLocked: const Value(true),
        entryPinHash: Value(pinHash),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Permanently unlocks a specific entry and clears any custom entry PIN hash.
  Future<int> unlockEntryPermanently(String entryId) {
    return (update(entries)..where((t) => t.id.equals(entryId))).write(
      EntriesCompanion(
        isLocked: const Value(false),
        entryPinHash: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Checks whether [year] is a Gregorian leap year.
  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Fetches all active (non-deleted) entries written on the same month and day
  /// in previous calendar years (`entryDate.year < date.year`), ordered newest year first.
  ///
  /// Leap Year Safeguard:
  /// - When [date] is Feb 28 in a non-leap year, entries written on Feb 29 in past leap years
  ///   are also included so leap-day memories are never orphaned.
  /// - When [date] is Feb 29 in a leap year, entries written on Feb 29 in past leap years match.
  Future<List<Entry>> getEntriesOnThisDay(DateTime date) async {
    final allActive = await (select(entries)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.entryDate)]))
        .get();

    final includeLeapFeb29OnFeb28 =
        date.month == 2 && date.day == 28 && !isLeapYear(date.year);

    return allActive.where((entry) {
      final d = entry.entryDate;
      if (d.year >= date.year) return false;

      // Exact month and day match
      if (d.month == date.month && d.day == date.day) {
        return true;
      }

      // Include Feb 29 historical memories on Feb 28 of non-leap years
      if (includeLeapFeb29OnFeb28 && d.month == 2 && d.day == 29) {
        return true;
      }

      return false;
    }).toList();
  }

  /// Randomly draws a past active entry written at least [minDaysAgo] days prior to [referenceDate]
  /// (defaults to 90 days ago from now). Excludes sealed time capsules.
  Future<Entry?> getRandomOldEntry({
    int minDaysAgo = 90,
    DateTime? referenceDate,
    Random? random,
  }) async {
    final now = referenceDate ?? DateTime.now();
    final cutoff = now.subtract(Duration(days: minDaysAgo));

    final candidates = await (select(entries)
          ..where((t) =>
              t.isDeleted.equals(false) &
              t.entryDate.isSmallerOrEqualValue(cutoff)))
        .get();

    // Filter out sealed time capsules whose unlockAt is in the future
    final eligible = candidates.where((e) {
      if (e.unlockAt != null && e.unlockAt!.isAfter(now)) {
        return false;
      }
      return true;
    }).toList();

    if (eligible.isEmpty) return null;

    final rng = random ?? Random();
    return eligible[rng.nextInt(eligible.length)];
  }

  // ===========================================================================
  // Phase 9: Encrypted Full-Archive Backup & Atomic Restore Queries
  // ===========================================================================

  /// Exports a consistent snapshot of all 4 core SQLite tables (including soft-deleted,
  /// locked, and time-capsule entries) inside a read transaction.
  Future<BackupDatabaseSnapshot> exportAllTablesSnapshot() {
    return transaction(() async {
      final allTemplates = await select(templates).get();
      final allNotebooks = await select(notebooks).get();
      final allEntries = await select(entries).get();
      final allMedia = await select(mediaAttachments).get();
      return BackupDatabaseSnapshot(
        templates: allTemplates,
        notebooks: allNotebooks,
        entries: allEntries,
        mediaAttachments: allMedia,
      );
    });
  }

  /// Atomically replaces all database records with [snapshot] inside a single transaction.
  ///
  /// Watchpoint 1 Defense:
  /// - Clears `entries_fts` alongside relational tables (`media_attachments`, `entries`, `notebooks`, `templates`).
  /// - Inserts `templates` -> `notebooks` -> `entries` -> `media_attachments` in foreign-key dependency order.
  /// - Because the `entries_ai` AFTER INSERT trigger automatically populates `entries_fts`
  ///   as rows are inserted into `entries`, no duplicate manual `INSERT INTO entries_fts` is executed.
  Future<void> replaceAllFromBackup(BackupDatabaseSnapshot snapshot) async {
    await customStatement('PRAGMA foreign_keys = ON;');
    await transaction(() async {
      // 1. Delete existing rows in reverse foreign-key dependency order
      await delete(mediaAttachments).go();
      await delete(entries).go();
      await customStatement('DELETE FROM entries_fts;');
      await delete(notebooks).go();
      await delete(templates).go();

      // 2. Ensure the 4 default system templates are present if omitted in snapshot
      final templateIds = snapshot.templates.map((t) => t.id).toSet();
      final defaults = <TemplatesCompanion>[
        if (!templateIds.contains('template_minimalist_white'))
          TemplatesCompanion.insert(
            id: 'template_minimalist_white',
            name: 'Minimalist White',
            backgroundType: 'color',
            backgroundValue: '#FFFFFF',
            fontFamily: const Value('System'),
            lineSpacing: const Value(1.5),
            marginHorizontal: const Value(20.0),
            isCustom: const Value(false),
          ),
        if (!templateIds.contains('template_lined_paper'))
          TemplatesCompanion.insert(
            id: 'template_lined_paper',
            name: 'Lined Paper',
            backgroundType: 'lined',
            backgroundValue: '#FDFBF7',
            fontFamily: const Value('System'),
            lineSpacing: const Value(1.8),
            marginHorizontal: const Value(24.0),
            isCustom: const Value(false),
          ),
        if (!templateIds.contains('template_retro_kraft'))
          TemplatesCompanion.insert(
            id: 'template_retro_kraft',
            name: 'Retro Kraft Scrapbook',
            backgroundType: 'paper_texture',
            backgroundValue: '#EFE6D5',
            fontFamily: const Value('System'),
            lineSpacing: const Value(1.6),
            marginHorizontal: const Value(20.0),
            isCustom: const Value(false),
          ),
        if (!templateIds.contains('template_weekly_review'))
          TemplatesCompanion.insert(
            id: 'template_weekly_review',
            name: 'Weekly Review',
            backgroundType: 'grid',
            backgroundValue: '#F4F5F7',
            fontFamily: const Value('System'),
            lineSpacing: const Value(1.5),
            marginHorizontal: const Value(16.0),
            isCustom: const Value(false),
          ),
      ];

      // 3. Insert records in foreign-key dependency order with referential integrity checks
      for (final d in defaults) {
        await into(templates).insert(d);
      }
      for (final t in snapshot.templates) {
        await into(templates).insert(t);
      }

      final validTemplateIds = <String>{
        'template_minimalist_white',
        'template_lined_paper',
        'template_retro_kraft',
        'template_weekly_review',
        ...snapshot.templates.map((t) => t.id),
      };

      final validNotebookIds = <String>{};
      if (snapshot.notebooks.isNotEmpty) {
        for (final n in snapshot.notebooks) {
          if (!validTemplateIds.contains(n.defaultTemplateId)) {
            throw StateError(
              'Foreign key violation: notebook ${n.id} references missing template ${n.defaultTemplateId}.',
            );
          }
          await into(notebooks).insert(n);
          validNotebookIds.add(n.id);
        }
      } else {
        await into(notebooks).insert(
          NotebooksCompanion.insert(
            id: 'notebook_default',
            title: 'My Diary',
            defaultTemplateId: 'template_minimalist_white',
          ),
        );
        validNotebookIds.add('notebook_default');
      }

      final validEntryIds = <String>{};
      for (final e in snapshot.entries) {
        if (!validNotebookIds.contains(e.notebookId)) {
          throw StateError(
            'Foreign key violation: entry ${e.id} references missing notebook ${e.notebookId}.',
          );
        }
        if (!validTemplateIds.contains(e.templateId)) {
          throw StateError(
            'Foreign key violation: entry ${e.id} references missing template ${e.templateId}.',
          );
        }
        await into(entries).insert(e);
        validEntryIds.add(e.id);
      }

      for (final m in snapshot.mediaAttachments) {
        if (!validEntryIds.contains(m.entryId)) {
          throw StateError(
            'Foreign key violation: mediaAttachment ${m.id} references missing entry ${m.entryId}.',
          );
        }
        await into(mediaAttachments).insert(m);
      }
    });
  }
}



