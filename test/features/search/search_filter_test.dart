import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/search/models/search_filters.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  group('Offline FTS5 & Multi-Condition Search Tests', () {
    test('FTS5 matches keyword in title or plainText', () async {
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_coffee',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Morning Cafe'),
          contentDelta: jsonEncode([{'insert': 'Drank an espresso today\n'}]),
          plainText: 'Drank an espresso today',
          entryDate: DateTime.now(),
        ),
      );

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_tea',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Afternoon Tea'),
          contentDelta: jsonEncode([{'insert': 'Green tea ceremony\n'}]),
          plainText: 'Green tea ceremony',
          entryDate: DateTime.now(),
        ),
      );

      // Search keyword in title
      final titleMatch = await db.searchEntriesWithFilters(query: 'Cafe');
      expect(titleMatch.length, equals(1));
      expect(titleMatch.first.id, equals('entry_coffee'));

      // Search keyword in plain text
      final bodyMatch = await db.searchEntriesWithFilters(query: 'ceremony');
      expect(bodyMatch.length, equals(1));
      expect(bodyMatch.first.id, equals('entry_tea'));
    });

    test('Clean query branching: empty query uses relational filters directly', () async {
      final now = DateTime.now();

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_happy_sunny',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Sunny Day'),
          contentDelta: jsonEncode([{'insert': 'Walking outside\n'}]),
          plainText: 'Walking outside',
          entryDate: now,
          mood: const Value(5),
          weather: const Value('sunny'),
        ),
      );

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_calm_rainy',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Rainy Day'),
          contentDelta: jsonEncode([{'insert': 'Reading books\n'}]),
          plainText: 'Reading books',
          entryDate: now,
          mood: const Value(3),
          weather: const Value('rainy'),
        ),
      );

      // Filter by mood with empty query
      final moodResults = await db.searchEntriesWithFilters(query: '', mood: 5);
      expect(moodResults.length, equals(1));
      expect(moodResults.first.id, equals('entry_happy_sunny'));

      // Filter by weather with empty query
      final weatherResults = await db.searchEntriesWithFilters(query: '', weather: 'rainy');
      expect(weatherResults.length, equals(1));
      expect(weatherResults.first.id, equals('entry_calm_rainy'));
    });

    test('Multi-condition search combines FTS5 keyword and relational filters', () async {
      final now = DateTime.now();

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Flutter coding'),
          contentDelta: jsonEncode([{'insert': 'Writing tests\n'}]),
          plainText: 'Writing tests',
          entryDate: now,
          mood: const Value(4),
          weather: const Value('sunny'),
        ),
      );

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_2',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Flutter debugging'),
          contentDelta: jsonEncode([{'insert': 'Fixing bugs\n'}]),
          plainText: 'Fixing bugs',
          entryDate: now,
          mood: const Value(2),
          weather: const Value('rainy'),
        ),
      );

      // Keyword "Flutter" + mood 4 => only entry_1
      final combined = await db.searchEntriesWithFilters(
        query: 'Flutter',
        mood: 4,
      );
      expect(combined.length, equals(1));
      expect(combined.first.id, equals('entry_1'));
    });

    test('Filter by weekly review only and has image', () async {
      final now = DateTime.now();

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_review',
          notebookId: 'notebook_default',
          templateId: 'template_weekly_review',
          title: const Value('Week 42'),
          contentDelta: jsonEncode([{'insert': 'Summary\n'}]),
          plainText: 'Summary',
          entryDate: now,
          isWeeklyReview: const Value(true),
        ),
      );

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_with_img',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Camera photo'),
          contentDelta: jsonEncode([{'insert': 'Snapshot\n'}]),
          plainText: 'Snapshot',
          entryDate: now,
        ),
      );
      await db.attachMediaToEntry(
        id: 'media_img_1',
        entryId: 'entry_with_img',
        relativePath: 'media/test.webp',
      );

      final reviewOnly = await db.searchEntriesWithFilters(weeklyReviewOnly: true);
      expect(reviewOnly.length, equals(1));
      expect(reviewOnly.first.id, equals('entry_review'));

      final hasImgOnly = await db.searchEntriesWithFilters(hasImage: true);
      expect(hasImgOnly.length, equals(1));
      expect(hasImgOnly.first.id, equals('entry_with_img'));
    });

    test('Privacy Invariant: Sealed Time Capsules are strictly excluded from text search', () async {
      final now = DateTime.now();

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'capsule_sealed',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Top Secret Future Prediction'),
          contentDelta: jsonEncode([{'insert': 'Secret vault contents\n'}]),
          plainText: 'Secret vault contents',
          entryDate: now,
          unlockAt: Value(now.add(const Duration(days: 100))),
        ),
      );

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'normal_entry',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Public Diary'),
          contentDelta: jsonEncode([{'insert': 'Secret recipe for pancakes\n'}]),
          plainText: 'Secret recipe for pancakes',
          entryDate: now,
        ),
      );

      // Search for keyword 'Secret' with excludeSealedTimeCapsules = true
      final results = await db.searchEntriesWithFilters(
        query: 'Secret',
        excludeSealedTimeCapsules: true,
      );

      expect(results.length, equals(1));
      expect(results.first.id, equals('normal_entry'));
      expect(results.any((e) => e.id == 'capsule_sealed'), isFalse);
    });

    test('SearchFilters date range helper resolves expected week and month boundaries', () {
      final now = DateTime.now();

      const weekFilter = SearchFilters(dateType: DateFilterType.thisWeek);
      final weekStart = weekFilter.resolvedStartDate!;
      final weekEnd = weekFilter.resolvedEndDate!;
      expect(weekStart.weekday, equals(DateTime.monday));
      expect(weekEnd.weekday, equals(DateTime.sunday));

      const monthFilter = SearchFilters(dateType: DateFilterType.thisMonth);
      final monthStart = monthFilter.resolvedStartDate!;
      final monthEnd = monthFilter.resolvedEndDate!;
      expect(monthStart.day, equals(1));
      expect(monthEnd.month, equals(now.month));
    });
  });
}

