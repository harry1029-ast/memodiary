import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'tables/templates.dart';
import 'tables/notebooks.dart';
import 'tables/entries.dart';
import 'tables/media_attachments.dart';

part 'app_database.g.dart';

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
    final executor = NativeDatabase.createInBackground(
      dbFile,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = '$encryptionKey';");
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

          // 4. Seed the 4 default templates
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
}


