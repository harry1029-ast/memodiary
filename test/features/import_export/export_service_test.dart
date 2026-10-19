import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/import_export/services/export_service.dart';
import 'package:memodiary/features/import_export/services/file_selector_service.dart';
import 'package:memodiary/features/import_export/widgets/export_dialog.dart';

class MockFileSelectorService implements FileSelectorService {
  File? pickedFile;
  File? pickedBackupFile;
  String? lastSavedFileName;
  String? lastSavedContent;
  File? lastSavedBackupSource;
  String? mockBackupSaveDestination;

  @override
  Future<File?> pickTextOrMarkdownFile() async => pickedFile;

  @override
  Future<String?> saveExportFile({
    required String fileName,
    required String content,
  }) async {
    lastSavedFileName = fileName;
    lastSavedContent = content;
    return '/mock/path/$fileName';
  }

  @override
  Future<File?> pickBackupFile() async => pickedBackupFile;

  @override
  Future<String?> saveBackupFile({
    required String fileName,
    required File sourceFile,
  }) async {
    lastSavedFileName = fileName;
    lastSavedBackupSource = sourceFile;
    if (mockBackupSaveDestination != null) {
      await sourceFile.copy(mockBackupSaveDestination!);
      return mockBackupSaveDestination;
    }
    return '/mock/path/$fileName';
  }
}

void main() {
  late AppDatabase db;
  late MockFileSelectorService mockFileSelector;

  setUp(() {
    db = AppDatabase.memory();
    mockFileSelector = MockFileSelectorService();
  });

  tearDown(() async {
    await db.close();
  });

  group('Export Service & Dialog Tests', () {
    final testEntry = Entry(
      id: 'entry_export_1',
      notebookId: 'notebook_default',
      templateId: 'template_minimalist_white',
      title: 'Himalayan Trek',
      contentDelta: jsonEncode([{'insert': 'Hiking high in the mountains.\n'}]),
      plainText: 'Hiking high in the mountains.',
      entryDate: DateTime(2026, 10, 16, 14, 0),
      mood: 5,
      weather: 'sunny',
      isWeeklyReview: false,
      isLocked: false,
      createdAt: DateTime(2026, 10, 16, 14, 0),
      updatedAt: DateTime(2026, 10, 16, 14, 0),
      isDeleted: false,
    );

    test('formatEntryToMarkdown serializes entry with valid YAML frontmatter', () {
      final md = ExportService.formatEntryToMarkdown(testEntry);

      expect(md, startsWith('---'));
      expect(md, contains('id: "entry_export_1"'));
      expect(md, contains('title: "Himalayan Trek"'));
      expect(md, contains('date: "2026-10-16T14:00:00.000"'));
      expect(md, contains('mood: 5'));
      expect(md, contains('weather: "sunny"'));
      expect(md, contains('# Himalayan Trek'));
      expect(md, contains('Hiking high in the mountains.'));
    });

    test('formatEntryToPlainText serializes entry with human-readable headers', () {
      final txt = ExportService.formatEntryToPlainText(testEntry);

      expect(txt, contains('========================================'));
      expect(txt, contains('Himalayan Trek'));
      expect(txt, contains('Date: 2026-10-16 14:00:00'));
      expect(txt, contains('Mood: 5/5'));
      expect(txt, contains('Weather: sunny'));
      expect(txt, contains('Hiking high in the mountains.'));
    });

    test('saveToFile writes serialized content via FileSelectorService', () async {
      final savedPath = await ExportService.saveToFile(
        entries: [testEntry],
        format: ExportFormat.markdown,
        fileSelector: mockFileSelector,
      );

      expect(savedPath, isNotNull);
      expect(mockFileSelector.lastSavedFileName, contains('Himalayan_Trek.md'));
      expect(mockFileSelector.lastSavedContent, contains('---'));
      expect(mockFileSelector.lastSavedContent, contains('Himalayan Trek'));
    });

    testWidgets('ExportDialog allows choosing format and scope, saving file in <= 3 taps', (WidgetTester tester) async {
      await db.createEntry(
        EntriesCompanion.insert(
          id: testEntry.id,
          notebookId: testEntry.notebookId,
          templateId: testEntry.templateId,
          title: Value(testEntry.title),
          contentDelta: testEntry.contentDelta,
          plainText: testEntry.plainText,
          entryDate: testEntry.entryDate,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ExportDialog.show(
                  context: context,
                  database: db,
                  singleEntry: testEntry,
                  fileSelector: mockFileSelector,
                ),
                child: const Text('Open Export'),
              ),
            ),
          ),
        ),
      );

      // Tap 1: Open Export Dialog
      await tester.tap(find.text('Open Export'));
      await tester.pumpAndSettle();

      expect(find.text('Export Diaries'), findsOneWidget);
      expect(find.text('Markdown (.md) with YAML Frontmatter'), findsOneWidget);

      // Tap 2: Tap "Save File" button
      await tester.tap(find.text('Save File'));
      await tester.pumpAndSettle();

      // Dialog closed and mock file selector received export
      expect(mockFileSelector.lastSavedFileName, isNotNull);
      expect(mockFileSelector.lastSavedContent, isNotNull);
      expect(find.textContaining('Exported 1 entries'), findsOneWidget);
    });
  });
}

