import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/import_export/models/import_candidate_entry.dart';
import 'package:memodiary/features/import_export/screens/import_staging_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  group('Import Database & Staging Tests', () {
    test('batchImportEntries inserts multiple entries atomically', () async {
      final now = DateTime.now();

      final companions = [
        EntriesCompanion.insert(
          id: 'import_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Imported One'),
          contentDelta: jsonEncode([{'insert': 'First\n'}]),
          plainText: 'First',
          entryDate: now,
        ),
        EntriesCompanion.insert(
          id: 'import_2',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Imported Two'),
          contentDelta: jsonEncode([{'insert': 'Second\n'}]),
          plainText: 'Second',
          entryDate: now,
        ),
      ];

      final count = await db.batchImportEntries(companions);
      expect(count, equals(2));

      final active = await db.getAllActiveEntries();
      expect(active.length, equals(2));
    });

    test('batchImportEntries rolls back atomically when any insertion fails', () async {
      final now = DateTime.now();

      // Pre-insert an entry with id 'conflict_id'
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'conflict_id',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Pre-existing'),
          contentDelta: jsonEncode([{'insert': 'Existing\n'}]),
          plainText: 'Existing',
          entryDate: now,
        ),
      );

      final companions = [
        EntriesCompanion.insert(
          id: 'valid_import_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Should roll back'),
          contentDelta: jsonEncode([{'insert': 'Content\n'}]),
          plainText: 'Content',
          entryDate: now,
        ),
        // Duplicate primary key will cause SQLite unique constraint failure!
        EntriesCompanion.insert(
          id: 'conflict_id',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Duplicate Primary Key'),
          contentDelta: jsonEncode([{'insert': 'Crash\n'}]),
          plainText: 'Crash',
          entryDate: now,
        ),
      ];

      // Expect batchImportEntries to throw
      expect(
        () => db.batchImportEntries(companions),
        throwsA(isA<Exception>()),
      );

      // Verify atomic rollback: valid_import_1 must NOT exist in the database!
      final rolledBackEntry = await db.getEntryById('valid_import_1');
      expect(rolledBackEntry, isNull);

      final total = await db.getAllActiveEntries();
      expect(total.length, equals(1)); // Only the pre-existing entry
    });

    testWidgets('ImportStagingScreen renders candidates, allows selection, and commits import', (WidgetTester tester) async {
      final candidates = [
        ImportCandidateEntry(
          id: 'cand_1',
          parsedDate: DateTime(2026, 10, 14),
          title: 'Tokyo Arrival',
          plainText: 'Arrived at hotel',
          contentDelta: jsonEncode([{'insert': 'Arrived at hotel\n'}]),
          confidence: DateParseConfidence.high,
          isSelected: true,
        ),
        ImportCandidateEntry(
          id: 'cand_2',
          parsedDate: null,
          title: 'Notes without Date',
          plainText: 'Need to review date',
          contentDelta: jsonEncode([{'insert': 'Need to review date\n'}]),
          confidence: DateParseConfidence.none,
          isSelected: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ImportStagingScreen(
            initialCandidates: candidates,
            database: db,
            fileName: 'my_diary.md',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify candidate entries rendered
      expect(find.text('Tokyo Arrival'), findsOneWidget);
      expect(find.text('Notes without Date'), findsOneWidget);
      expect(find.text('Missing Date'), findsOneWidget);
      expect(find.text('1 entries need date review'), findsOneWidget);

      // Tap "Import Selected (2)"
      await tester.tap(find.text('Import Selected (2)'));
      await tester.pumpAndSettle();

      // Summary completion dialog should appear
      expect(find.text('Import Complete'), findsOneWidget);
      expect(find.textContaining('Successfully imported 2 diary entries'), findsOneWidget);

      // Close dialog & verify DB commit
      await tester.tap(find.text('View Timeline'));
      await tester.pumpAndSettle();

      final active = await db.getAllActiveEntries();
      expect(active.length, equals(2));
    });
  });
}

