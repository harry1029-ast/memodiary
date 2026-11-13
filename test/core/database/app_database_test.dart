import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // In-memory SQLite database for fast isolated unit testing
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase Schema & Seeding Tests', () {
    test('seeds 4 default templates on creation', () async {
      final templates = await db.templatesDao.getAllTemplates();
      expect(templates.length, 4);

      final templateMap = {
        for (final template in templates) template.id: template,
      };

      // 1. Minimalist White
      final white = templateMap['template_minimalist_white'];
      expect(white, isNotNull);
      expect(white!.name, 'Minimalist White');
      expect(white.backgroundType, 'color');
      expect(white.backgroundValue, '#FFFFFF');
      expect(white.lineSpacing, 1.5);
      expect(white.marginHorizontal, 20.0);
      expect(white.isCustom, isFalse);

      // 2. Lined Paper
      final lined = templateMap['template_lined_paper'];
      expect(lined, isNotNull);
      expect(lined!.name, 'Lined Paper');
      expect(lined.backgroundType, 'lined');
      expect(lined.backgroundValue, '#FDFBF7');
      expect(lined.lineSpacing, 1.8);
      expect(lined.marginHorizontal, 24.0);
      expect(lined.isCustom, isFalse);

      // 3. Retro Kraft Scrapbook
      final kraft = templateMap['template_retro_kraft'];
      expect(kraft, isNotNull);
      expect(kraft!.name, 'Retro Kraft Scrapbook');
      expect(kraft.backgroundType, 'paper_texture');
      expect(kraft.backgroundValue, '#EFE6D5');
      expect(kraft.lineSpacing, 1.6);
      expect(kraft.marginHorizontal, 20.0);
      expect(kraft.isCustom, isFalse);

      // 4. Weekly Review
      final weekly = templateMap['template_weekly_review'];
      expect(weekly, isNotNull);
      expect(weekly!.name, 'Weekly Review');
      expect(weekly.backgroundType, 'grid');
      expect(weekly.backgroundValue, '#F4F5F7');
      expect(weekly.lineSpacing, 1.5);
      expect(weekly.marginHorizontal, 16.0);
      expect(weekly.isCustom, isFalse);
    });

    test('seeds default notebook on creation', () async {
      final notebooks = await db.templatesDao.getAllNotebooks();
      expect(notebooks.length, 1);
      final defaultNb = notebooks.first;
      expect(defaultNb.id, 'notebook_default');
      expect(defaultNb.title, 'My Diary');
      expect(defaultNb.defaultTemplateId, 'template_minimalist_white');
    });

    test('supports entries and media attachments CRUD', () async {
      final entryDate = DateTime.now();

      // Insert entry
      await db.entriesDao.createEntry(
            EntriesCompanion.insert(
              id: 'entry_test_1',
              notebookId: 'notebook_default',
              templateId: 'template_minimalist_white',
              title: const Value('First Entry'),
              contentDelta: '{"ops":[{"insert":"Hello World\\n"}]}',
              plainText: 'Hello World',
              entryDate: entryDate,
              mood: const Value(5),
              weather: const Value('sunny'),
            ),
          );

      final entry = (await db.entriesDao.getEntryById('entry_test_1'))!;
      expect(entry.title, 'First Entry');
      expect(entry.plainText, 'Hello World');
      expect(entry.mood, 5);
      expect(entry.isDeleted, isFalse);

      // Insert media attachment with strictly relative path
      await db.mediaOcrDao.attachMediaToEntry(
        id: 'media_test_1',
        entryId: 'entry_test_1',
        mediaType: 'image',
        relativePath: 'media/test_uuid.webp',
      );

      final media = (await db.mediaOcrDao.getMediaAttachmentById('media_test_1'))!;
      expect(media.relativePath, 'media/test_uuid.webp');
      expect(media.mediaType, 'image');
    });

    test('FTS5 automatically indexes inserted entries via triggers', () async {
      await db.entriesDao.createEntry(
            EntriesCompanion.insert(
              id: 'entry_fts_1',
              notebookId: 'notebook_default',
              templateId: 'template_minimalist_white',
              title: const Value('Exploring the Mountains'),
              contentDelta: '{"ops":[{"insert":"Hiking along the high alpine ridge\\n"}]}',
              plainText: 'Hiking along the high alpine ridge',
              entryDate: DateTime.now(),
            ),
          );

      await db.entriesDao.createEntry(
            EntriesCompanion.insert(
              id: 'entry_fts_2',
              notebookId: 'notebook_default',
              templateId: 'template_lined_paper',
              title: const Value('City Stroll'),
              contentDelta: '{"ops":[{"insert":"Visited a cozy coffee shop downtown\\n"}]}',
              plainText: 'Visited a cozy coffee shop downtown',
              entryDate: DateTime.now(),
            ),
          );

      // Search by title keyword
      final mountainResults = await db.entriesDao.searchEntries('Mountains');
      expect(mountainResults.length, 1);
      expect(mountainResults.first.id, 'entry_fts_1');

      // Search by body plain text keyword
      final coffeeResults = await db.entriesDao.searchEntries('coffee');
      expect(coffeeResults.length, 1);
      expect(coffeeResults.first.id, 'entry_fts_2');

      // Update entry and check FTS5 reflects the update
      await db.entriesDao.updateEntryMetadata(
        'entry_fts_2',
        title: 'City Stroll and Bakery',
      );
      await db.entriesDao.updateEntryContent(
        'entry_fts_2',
        '{"ops":[{"insert":"Visited a cozy bakery downtown\\n"}]}',
        'Visited a cozy bakery downtown',
      );

      final bakeryResults = await db.entriesDao.searchEntries('bakery');
      expect(bakeryResults.length, 1);
      expect(bakeryResults.first.id, 'entry_fts_2');

      // Delete entry and verify FTS5 no longer returns it
      await db.entriesDao.hardDeleteEntryAndCollectMediaPaths('entry_fts_1');
      final deletedSearch = await db.entriesDao.searchEntries('Mountains');
      expect(deletedSearch.isEmpty, isTrue);
    });

    test('soft deleted entries are excluded from search results', () async {
      await db.entriesDao.createEntry(
            EntriesCompanion.insert(
              id: 'entry_trash_1',
              notebookId: 'notebook_default',
              templateId: 'template_minimalist_white',
              title: const Value('Secret Note'),
              contentDelta: '{"ops":[{"insert":"Confidential reflections\\n"}]}',
              plainText: 'Confidential reflections',
              entryDate: DateTime.now(),
              isDeleted: const Value(true), // Marked in trash bin
            ),
          );

      final results = await db.entriesDao.searchEntries('Confidential');
      expect(results.isEmpty, isTrue);
    });
  });
}
