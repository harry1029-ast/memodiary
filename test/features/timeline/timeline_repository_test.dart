import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_item.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  group('Timeline Repository & Model Tests', () {
    test('getTimelineEntries returns reverse-chronological paginated entries', () async {
      final now = DateTime.now();

      for (int i = 0; i < 5; i++) {
        await db.createEntry(
          EntriesCompanion.insert(
            id: 'entry_$i',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: Value('Entry $i'),
            contentDelta: jsonEncode([{'insert': 'Content $i\n'}]),
            plainText: 'Content $i',
            entryDate: now.add(Duration(days: i)),
          ),
        );
      }

      // Fetch page 1 (limit 3, offset 0)
      final page1 = await db.getTimelineEntries(limit: 3, offset: 0);
      expect(page1.length, equals(3));
      // Reverse chronological order: entry_4 (newest), entry_3, entry_2
      expect(page1[0].id, equals('entry_4'));
      expect(page1[1].id, equals('entry_3'));
      expect(page1[2].id, equals('entry_2'));

      // Fetch page 2 (limit 3, offset 3)
      final page2 = await db.getTimelineEntries(limit: 3, offset: 3);
      expect(page2.length, equals(2));
      expect(page2[0].id, equals('entry_1'));
      expect(page2[1].id, equals('entry_0'));
    });

    test('getTimelineEntries strictly excludes soft-deleted entries', () async {
      final now = DateTime.now();

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'active_entry',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Active'),
          contentDelta: jsonEncode([{'insert': 'Hello\n'}]),
          plainText: 'Hello',
          entryDate: now,
        ),
      );

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'deleted_entry',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Deleted'),
          contentDelta: jsonEncode([{'insert': 'Gone\n'}]),
          plainText: 'Gone',
          entryDate: now.add(const Duration(hours: 1)),
        ),
      );

      await db.softDeleteEntry('deleted_entry');

      final timeline = await db.getTimelineEntries();
      expect(timeline.length, equals(1));
      expect(timeline.first.id, equals('active_entry'));
    });

    test('getPrimaryMediaForEntries batch retrieves first media attachment per entry', () async {
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_with_media',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('Photos'),
          contentDelta: jsonEncode([{'insert': 'Pics\n'}]),
          plainText: 'Pics',
          entryDate: DateTime.now(),
        ),
      );

      await db.attachMediaToEntry(
        id: 'media_1',
        entryId: 'entry_with_media',
        relativePath: 'media/photo1.webp',
      );
      await db.attachMediaToEntry(
        id: 'media_2',
        entryId: 'entry_with_media',
        relativePath: 'media/photo2.webp',
      );

      final mediaMap = await db.getPrimaryMediaForEntries(['entry_with_media', 'entry_empty']);
      expect(mediaMap.containsKey('entry_with_media'), isTrue);
      expect(mediaMap['entry_with_media']!.relativePath, equals('media/photo1.webp'));
      expect(mediaMap.containsKey('entry_empty'), isFalse);
    });

    test('TimelineEntryItem correctly evaluates sealed vs unlocked Time Capsules', () {
      final now = DateTime.now();

      // Sealed capsule (unlockAt is tomorrow)
      final sealedEntry = Entry(
        id: 'capsule_sealed',
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        title: 'Future letter',
        contentDelta: jsonEncode([{'insert': 'Secret\n'}]),
        plainText: 'Secret',
        entryDate: now,
        unlockAt: now.add(const Duration(days: 5)),
        createdAt: now,
        updatedAt: now,
        isWeeklyReview: false,
        isDeleted: false,
      );

      final sealedItem = TimelineEntryItem(entry: sealedEntry);
      expect(sealedItem.isSealedTimeCapsule, isTrue);
      expect(sealedItem.timeUntilUnlock!.inDays, greaterThanOrEqualTo(4));
      expect(sealedItem.remainingUnlockTimeFormatted, contains('days'));

      // Unlocked capsule (unlockAt was yesterday)
      final unlockedEntry = Entry(
        id: 'capsule_unlocked',
        notebookId: 'notebook_default',
        templateId: 'template_minimalist_white',
        title: 'Open letter',
        contentDelta: jsonEncode([{'insert': 'Now visible\n'}]),
        plainText: 'Now visible',
        entryDate: now,
        unlockAt: now.subtract(const Duration(days: 1)),
        createdAt: now,
        updatedAt: now,
        isWeeklyReview: false,
        isDeleted: false,
      );

      final unlockedItem = TimelineEntryItem(entry: unlockedEntry);
      expect(unlockedItem.isSealedTimeCapsule, isFalse);
    });
  });
}

