import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:uuid/uuid.dart';
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
  int get schemaVersion => 1;

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
      );

  /// Performs full-text search across entry title and plain text using FTS5
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

    // 1. Clean query branching: only execute FTS5 MATCH if query is non-empty
    if (trimmed.isNotEmpty) {
      final escaped = trimmed.replaceAll('"', '""');
      final ftsRows = await customSelect(
        'SELECT id FROM entries_fts WHERE entries_fts MATCH ?',
        variables: [Variable.withString('"$escaped"*')],
        readsFrom: {entries},
      ).get();

      ftsMatchedIds = ftsRows.map((r) => r.read<String>('id')).toSet();
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

  /// Retrieves a set of all media relative paths currently referenced in media_attachments.
  Future<Set<String>> getAllMediaRelativePaths() async {
    final rows = await (selectOnly(mediaAttachments, distinct: true)
          ..addColumns([mediaAttachments.relativePath]))
        .get();
    return rows
        .map((r) => r.read(mediaAttachments.relativePath))
        .whereType<String>()
        .toSet();
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
}



