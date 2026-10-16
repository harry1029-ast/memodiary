@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  group('Performance & Scale Benchmarking Suite', () {
    test('10,000 entries seeder, timeline pagination <=50ms, FTS5 latency <=500ms', () async {
      const totalEntries = 10000;
      const chunkSize = 1000;

      // 1. Batched chunk insertion (1,000 items per transaction)
      final seedStopwatch = Stopwatch()..start();
      for (int chunkStart = 0; chunkStart < totalEntries; chunkStart += chunkSize) {
        await db.transaction(() async {
          for (int i = chunkStart; i < chunkStart + chunkSize; i++) {
            final isKyoto = (i % 10 == 0);
            await db.into(db.entries).insert(
              EntriesCompanion.insert(
                id: 'entry_$i',
                notebookId: 'default',
                templateId: 'template_minimalist_white',
                title: Value('Diary Entry #$i${isKyoto ? " Kyoto Trip" : ""}'),
                contentDelta: jsonEncode([
                  {'insert': 'Today was journal day $i with thoughtful notes.\n'}
                ]),
                plainText: 'Today was journal day $i with thoughtful notes.${isKyoto ? " Kyoto Trip memories." : ""}',
                entryDate: DateTime(2020, 1, 1).add(Duration(hours: i * 2)),
                mood: Value((i % 5) + 1),
                weather: Value(['sunny', 'cloudy', 'rainy', 'windy', 'snowy'][i % 5]),
              ),
            );
          }
        });
      }
      seedStopwatch.stop();

      // Verify all 10,000 entries and seeded templates are present
      final countQuery = await (db.selectOnly(db.entries)..addColumns([db.entries.id.count()])).getSingle();
      final rowCount = countQuery.read(db.entries.id.count());
      expect(rowCount, equals(totalEntries));

      // 2. Timeline pagination query execution benchmark
      // Warm up once
      await db.getTimelineEntries(limit: 20, offset: 0);

      // Measure pagination at offset 5,000
      final paginationStopwatch = Stopwatch()..start();
      final paginatedEntries = await db.getTimelineEntries(limit: 20, offset: 5000);
      paginationStopwatch.stop();

      expect(paginatedEntries.length, equals(20));
      expect(
        paginationStopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(50),
        reason: 'Timeline pagination execution time (${paginationStopwatch.elapsedMilliseconds}ms) must be <= 50ms',
      );

      // Verify reverse-chronological ordering
      for (int i = 0; i < paginatedEntries.length - 1; i++) {
        expect(
          paginatedEntries[i].entryDate.isAfter(paginatedEntries[i + 1].entryDate) ||
              paginatedEntries[i].entryDate.isAtSameMomentAs(paginatedEntries[i + 1].entryDate),
          isTrue,
        );
      }

      // 3. SQLite FTS5 search query latency benchmark
      // Search for keyword "Kyoto" across the 10,000 indexed entries
      final ftsStopwatch = Stopwatch()..start();
      final searchResults = await db.searchEntriesWithFilters(
        query: 'Kyoto',
        limit: 50,
      );
      ftsStopwatch.stop();

      expect(searchResults.isNotEmpty, isTrue);
      expect(searchResults.length, equals(50));
      for (final result in searchResults) {
        expect(
          result.title?.contains('Kyoto') == true || result.plainText.contains('Kyoto'),
          isTrue,
        );
      }

      expect(
        ftsStopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(500),
        reason: 'SQLite FTS5 search latency (${ftsStopwatch.elapsedMilliseconds}ms) must be <= 500ms',
      );
    });
  });
}

