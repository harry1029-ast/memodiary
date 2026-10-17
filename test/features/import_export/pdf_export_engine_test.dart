import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/import_export/services/pdf_export_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory tempDir;
  late MediaSandboxService mediaService;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('pdf_engine_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PdfExportEngine Tests', () {
    test('generatePdfForEntry generates valid PDF bytes with template preservation', () async {
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_single_1',
          notebookId: 'default',
          templateId: 'template_lined_paper',
          title: const Value('Autumn Reflections'),
          contentDelta: jsonEncode([
            {'insert': 'Today I went for a walk in the park.\n'},
            {'insert': 'The leaves were golden.\n', 'attributes': {'italic': true}},
          ]),
          plainText: 'Today I went for a walk in the park.\nThe leaves were golden.',
          entryDate: DateTime(2026, 10, 15),
          mood: const Value(5),
          weather: const Value('sunny'),
        ),
      );

      final entry = await db.getEntryById('entry_single_1');
      expect(entry, isNotNull);

      final bytes = await PdfExportEngine.generatePdfForEntry(
        entry: entry!,
        database: db,
        mediaService: mediaService,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('generateConsolidatedPdf generates multi-entry journal book with cover page', () async {
      // 1. Create a custom template
      await db.createCustomTemplate(
        id: 'custom_lavender',
        name: 'Lavender Field',
        backgroundType: 'color',
        backgroundValue: '#E6E6FA',
        fontFamily: 'Roboto',
        lineSpacing: 1.6,
        marginHorizontal: 28.0,
      );

      // 2. Insert entries using different templates
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_book_1',
          notebookId: 'default',
          templateId: 'template_minimalist_white',
          title: const Value('Chapter One'),
          contentDelta: jsonEncode([{'insert': 'Beginning of the journey.\n'}]),
          plainText: 'Beginning of the journey.',
          entryDate: DateTime(2026, 10, 1),
          mood: const Value(4),
          weather: const Value('sunny'),
        ),
      );

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_book_2',
          notebookId: 'default',
          templateId: 'template_grid_paper',
          title: const Value('Technical Notes'),
          contentDelta: jsonEncode([
            {'insert': 'Architecture Decisions:\n', 'attributes': {'bold': true}},
            {'insert': 'Zero Cloud, 100% Local SQLite.\n'},
          ]),
          plainText: 'Architecture Decisions:\nZero Cloud, 100% Local SQLite.',
          entryDate: DateTime(2026, 10, 5),
          mood: const Value(5),
          weather: const Value('cloudy'),
        ),
      );

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_book_3',
          notebookId: 'default',
          templateId: 'custom_lavender',
          title: const Value('Quiet Evening'),
          contentDelta: jsonEncode([{'insert': 'Resting under the stars.\n'}]),
          plainText: 'Resting under the stars.',
          entryDate: DateTime(2026, 10, 10),
          mood: const Value(3),
          weather: const Value('rainy'),
        ),
      );

      final entries = await db.getTimelineEntries(limit: 100);
      expect(entries.length, equals(3));

      final bytes = await PdfExportEngine.generateConsolidatedPdf(
        entries: entries,
        database: db,
        mediaService: mediaService,
        bookTitle: 'Autumn 2026 Chronicles',
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('generateConsolidatedPdf handles empty entries list gracefully', () async {
      final bytes = await PdfExportEngine.generateConsolidatedPdf(
        entries: [],
        database: db,
        mediaService: mediaService,
        bookTitle: 'Empty Notebook',
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });
  });
}
