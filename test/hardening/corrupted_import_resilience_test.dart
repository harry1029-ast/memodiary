import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/import_export/services/date_parser_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  group('Corrupted Import Resilience & Atomic Rollback Hardening', () {
    test('Binary gibberish and invalid UTF-8 data does not crash parser or create corrupt entries', () async {
      // 1. Ingest binary gibberish containing null bytes, high ASCII, and random bytes
      final binaryGibberish = '${String.fromCharCodes([
        0x00, 0x01, 0xFF, 0xFE, 0x80, 0x7F, 0x00, 0x1B, 0x50, 0x4B, 0x03, 0x04
      ])}\nCorrupted binary header\n\x00\x00\x00\n';

      final candidates = await DateParserEngine.parseDocumentInIsolate(
        text: binaryGibberish,
        referenceDate: DateTime.now(),
      );

      // In pure Dart, parser safely handles binary strings without throwing unhandled crashes
      expect(candidates, isNotNull);
      for (final candidate in candidates) {
        expect(candidate.contentDelta.isNotEmpty, isTrue);
        expect(candidate.contentDelta.endsWith('\\n"}]'), isTrue);
      }
    });

    test('Mid-batch constraint violation triggers atomic rollback: zero corrupt records in SQLite or FTS5', () async {
      // 1. Seed baseline database state with 3 valid entries
      for (int i = 1; i <= 3; i++) {
        await db.createEntry(
          EntriesCompanion.insert(
            id: 'baseline_entry_$i',
            notebookId: 'default',
            templateId: 'template_minimalist_white',
            title: Value('Baseline #$i'),
            contentDelta: jsonEncode([{'insert': 'Baseline entry $i\n'}]),
            plainText: 'Baseline entry $i',
            entryDate: DateTime(2026, 1, i),
          ),
        );
      }

      final initialCount = (await db.getAllActiveEntries()).length;
      expect(initialCount, equals(3));

      final initialFtsRows = await db.customSelect('SELECT count(*) as count FROM entries_fts').getSingle();
      expect(initialFtsRows.read<int>('count'), equals(3));

      // 2. Prepare a candidate batch of 4 items where the 3rd item intentionally
      // has an identical primary key 'baseline_entry_1' (PRIMARY KEY UNIQUE constraint violation)
      final batchCompanions = [
        EntriesCompanion.insert(
          id: 'new_entry_1',
          notebookId: 'default',
          templateId: 'template_minimalist_white',
          title: const Value('New Batch Entry 1'),
          contentDelta: jsonEncode([{'insert': 'Batch entry 1\n'}]),
          plainText: 'Batch entry 1',
          entryDate: DateTime(2026, 2, 1),
        ),
        EntriesCompanion.insert(
          id: 'new_entry_2',
          notebookId: 'default',
          templateId: 'template_minimalist_white',
          title: const Value('New Batch Entry 2'),
          contentDelta: jsonEncode([{'insert': 'Batch entry 2\n'}]),
          plainText: 'Batch entry 2',
          entryDate: DateTime(2026, 2, 2),
        ),
        // Poison pill: duplicate ID violates PRIMARY KEY constraint
        EntriesCompanion.insert(
          id: 'baseline_entry_1',
          notebookId: 'default',
          templateId: 'template_minimalist_white',
          title: const Value('Conflicting Duplicate Entry'),
          contentDelta: jsonEncode([{'insert': 'Conflicting content\n'}]),
          plainText: 'Conflicting content',
          entryDate: DateTime(2026, 2, 3),
        ),
        EntriesCompanion.insert(
          id: 'new_entry_4',
          notebookId: 'default',
          templateId: 'template_minimalist_white',
          title: const Value('New Batch Entry 4'),
          contentDelta: jsonEncode([{'insert': 'Batch entry 4\n'}]),
          plainText: 'Batch entry 4',
          entryDate: DateTime(2026, 2, 4),
        ),
      ];

      // 3. Attempt batch import and assert it fails with an exception
      expect(
        () => db.batchImportEntries(batchCompanions),
        throwsA(anything),
      );

      // 4. Verify atomic rollback: neither new_entry_1 nor new_entry_2 were persisted
      final postFailureEntries = await db.getAllActiveEntries();
      expect(postFailureEntries.length, equals(initialCount));
      expect(postFailureEntries.any((e) => e.id == 'new_entry_1'), isFalse);
      expect(postFailureEntries.any((e) => e.id == 'new_entry_2'), isFalse);

      // 5. Verify FTS5 virtual table remains synchronized without orphan search tokens
      final postFailureFtsRows = await db.customSelect('SELECT count(*) as count FROM entries_fts').getSingle();
      expect(postFailureFtsRows.read<int>('count'), equals(3));

      final ftsSearchResults = await db.searchEntriesWithFilters(query: 'Batch entry');
      expect(ftsSearchResults.isEmpty, isTrue);

      // 6. Verify subsequent valid batch import executes successfully
      final cleanBatch = [
        EntriesCompanion.insert(
          id: 'valid_entry_1',
          notebookId: 'default',
          templateId: 'template_minimalist_white',
          title: const Value('Valid Recovered Entry'),
          contentDelta: jsonEncode([{'insert': 'Valid recovered content\n'}]),
          plainText: 'Valid recovered content',
          entryDate: DateTime(2026, 3, 1),
        ),
      ];

      final importedCount = await db.batchImportEntries(cleanBatch);
      expect(importedCount, equals(1));

      final updatedEntries = await db.getAllActiveEntries();
      expect(updatedEntries.length, equals(4));
    });
  });
}
