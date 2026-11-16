import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/timeline/models/timeline_entry_item.dart';
import 'package:memodiary/features/timeline/models/timeline_filter_state.dart';

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
        await db.entriesDao.createEntry(
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
      final page1 = await db.entriesDao.getTimelineEntries(limit: 3, offset: 0);
      expect(page1.length, equals(3));
      // Reverse chronological order: entry_4 (newest), entry_3, entry_2
      expect(page1[0].id, equals('entry_4'));
      expect(page1[1].id, equals('entry_3'));
      expect(page1[2].id, equals('entry_2'));

      // Fetch page 2 (limit 3, offset 3)
      final page2 = await db.entriesDao.getTimelineEntries(limit: 3, offset: 3);
      expect(page2.length, equals(2));
      expect(page2[0].id, equals('entry_1'));
      expect(page2[1].id, equals('entry_0'));
    });

    test('getTimelineEntries strictly excludes soft-deleted entries', () async {
      final now = DateTime.now();

      await db.entriesDao.createEntry(
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

      await db.entriesDao.createEntry(
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

      await db.entriesDao.softDeleteEntry('deleted_entry');

      final timeline = await db.entriesDao.getTimelineEntries();
      expect(timeline.length, equals(1));
      expect(timeline.first.id, equals('active_entry'));
    });

    test('getPrimaryMediaForEntries batch retrieves first media attachment per entry', () async {
      await db.entriesDao.createEntry(
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

      await db.mediaOcrDao.attachMediaToEntry(
        id: 'media_1',
        entryId: 'entry_with_media',
        relativePath: 'media/photo1.webp',
      );
      await db.mediaOcrDao.attachMediaToEntry(
        id: 'media_2',
        entryId: 'entry_with_media',
        relativePath: 'media/photo2.webp',
      );

      final mediaMap = await db.mediaOcrDao.getPrimaryMediaForEntries(
        ['entry_with_media', 'entry_empty'],
      );
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
        isLocked: false,
        legacyMountsPending: false,
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
        isLocked: false,
        legacyMountsPending: false,
        isDeleted: false,
      );

      final unlockedItem = TimelineEntryItem(entry: unlockedEntry);
      expect(unlockedItem.isSealedTimeCapsule, isFalse);
    });
  });

  group('TimelineFilterState & Filtered EntriesDao Tests', () {
    test('TimelineFilterState transitions follow date index tray rules', () {
      const initial = TimelineFilterState();
      expect(initial.year, isNull);
      expect(initial.month, isNull);
      expect(initial.xun, isNull);
      expect(initial.sortOrder, equals(TimelineSortOrder.newestFirst));
      expect(initial.hasActiveFilters, isFalse);
      expect(initial.dateRange(), isNull);

      // Selecting month while year is null auto-promotes year to latest available
      final promoted = initial.selectMonth(11, availableYears: [2026, 2025]);
      expect(promoted.year, equals(2026));
      expect(promoted.month, equals(11));
      expect(promoted.xun, isNull);
      expect(promoted.hasActiveFilters, isTrue);

      // Selecting xun sets it and tapping again toggles it off
      final withXun = promoted.selectXun(TimelineXun.zhong);
      expect(withXun.xun, equals(TimelineXun.zhong));
      final clearedXun = withXun.selectXun(TimelineXun.zhong);
      expect(clearedXun.xun, isNull);

      // Tapping active month again clears month and xun while keeping year
      final clearedMonth = withXun.selectMonth(11, availableYears: [2026, 2025]);
      expect(clearedMonth.year, equals(2026));
      expect(clearedMonth.month, isNull);
      expect(clearedMonth.xun, isNull);

      // Selecting year null clears both month and xun
      final clearedAllDates = withXun.selectYear(null);
      expect(clearedAllDates.year, isNull);
      expect(clearedAllDates.month, isNull);
      expect(clearedAllDates.xun, isNull);
      expect(clearedAllDates.hasActiveFilters, isFalse);

      // Date bounds handle Dec->Jan rollover and leap-year Feb xia
      const decRange = TimelineFilterState(year: 2026, month: 12);
      expect(
        decRange.dateRange(),
        equals((DateTime(2026, 12, 1), DateTime(2027, 1, 1))),
      );

      const leapFebXia = TimelineFilterState(
        year: 2024,
        month: 2,
        xun: TimelineXun.xia,
      );
      expect(
        leapFebXia.dateRange(),
        equals((DateTime(2024, 2, 21), DateTime(2024, 3, 1))),
      );

      const shang = TimelineFilterState(
        year: 2026,
        month: 11,
        xun: TimelineXun.shang,
      );
      expect(
        shang.dateRange(),
        equals((DateTime(2026, 11, 1), DateTime(2026, 11, 11))),
      );

      const zhong = TimelineFilterState(
        year: 2026,
        month: 11,
        xun: TimelineXun.zhong,
      );
      expect(
        zhong.dateRange(),
        equals((DateTime(2026, 11, 11), DateTime(2026, 11, 21))),
      );
    });

    Future<void> seedFilterCorpus() async {
      final specs = [
        (
          id: 'e_2026_11_01',
          date: DateTime(2026, 11, 1, 9, 0),
          mood: 5,
          weather: 'sunny',
          weekly: false,
          hasMedia: true,
          deleted: false,
        ),
        (
          id: 'e_2026_11_10_late',
          date: DateTime(2026, 11, 10, 23, 59, 59),
          mood: 4,
          weather: 'rainy',
          weekly: false,
          hasMedia: false,
          deleted: false,
        ),
        (
          id: 'e_2026_11_15',
          date: DateTime(2026, 11, 15, 14, 30),
          mood: 3,
          weather: 'cloudy',
          weekly: true,
          hasMedia: true,
          deleted: false,
        ),
        (
          id: 'e_2026_11_30',
          date: DateTime(2026, 11, 30, 21, 0),
          mood: 2,
          weather: 'rainy',
          weekly: false,
          hasMedia: false,
          deleted: false,
        ),
        (
          id: 'e_2026_10_18',
          date: DateTime(2026, 10, 18, 12, 0),
          mood: 5,
          weather: 'sunny',
          weekly: false,
          hasMedia: false,
          deleted: false,
        ),
        (
          id: 'e_2025_09_09',
          date: DateTime(2025, 9, 9, 18, 20),
          mood: 4,
          weather: 'windy',
          weekly: true,
          hasMedia: false,
          deleted: false,
        ),
        (
          id: 'e_2024_02_29',
          date: DateTime(2024, 2, 29, 8, 15),
          mood: 5,
          weather: 'snowy',
          weekly: false,
          hasMedia: true,
          deleted: false,
        ),
        (
          id: 'e_deleted_2026_05',
          date: DateTime(2026, 5, 5, 10, 0),
          mood: 5,
          weather: 'sunny',
          weekly: false,
          hasMedia: true,
          deleted: true,
        ),
      ];

      for (final spec in specs) {
        await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: spec.id,
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: Value('Title ${spec.id}'),
            contentDelta: jsonEncode([{'insert': 'Body ${spec.id}\n'}]),
            plainText: 'Body ${spec.id}',
            entryDate: spec.date,
            mood: Value(spec.mood),
            weather: Value(spec.weather),
            isWeeklyReview: Value(spec.weekly),
            isDeleted: Value(spec.deleted),
          ),
        );
        if (spec.hasMedia) {
          await db.mediaOcrDao.attachMediaToEntry(
            id: 'media_${spec.id}',
            entryId: spec.id,
            relativePath: 'media/${spec.id}.webp',
          );
        }
      }
    }

    test('getFilteredTimelineEntries and countFilteredTimelineEntries filter by date, xun, charm, and sort order', () async {
      await seedFilterCorpus();

      // Default: all 7 active entries newestFirst
      final allNewest = await db.entriesDao.getFilteredTimelineEntries(
        filters: const TimelineFilterState(),
        limit: 3,
        offset: 0,
      );
      final allCount = await db.entriesDao.countFilteredTimelineEntries(
        filters: const TimelineFilterState(),
      );
      expect(allCount, equals(7));
      expect(
        allNewest.map((entry) => entry.id).toList(),
        equals(['e_2026_11_30', 'e_2026_11_15', 'e_2026_11_10_late']),
      );

      // Oldest first
      final allOldest = await db.entriesDao.getFilteredTimelineEntries(
        filters: const TimelineFilterState(
          sortOrder: TimelineSortOrder.oldestFirst,
        ),
        limit: 2,
        offset: 0,
      );
      expect(
        allOldest.map((entry) => entry.id).toList(),
        equals(['e_2024_02_29', 'e_2025_09_09']),
      );

      // Year + Month + Xun (上旬 includes 11/10 23:59:59, excludes 11/15)
      const shangFilter = TimelineFilterState(
        year: 2026,
        month: 11,
        xun: TimelineXun.shang,
      );
      final shangEntries = await db.entriesDao.getFilteredTimelineEntries(
        filters: shangFilter,
      );
      expect(
        shangEntries.map((entry) => entry.id).toList(),
        equals(['e_2026_11_10_late', 'e_2026_11_01']),
      );
      expect(
        await db.entriesDao.countFilteredTimelineEntries(filters: shangFilter),
        equals(2),
      );

      // 中旬
      const zhongFilter = TimelineFilterState(
        year: 2026,
        month: 11,
        xun: TimelineXun.zhong,
      );
      expect(
        (await db.entriesDao.getFilteredTimelineEntries(filters: zhongFilter))
            .map((entry) => entry.id)
            .toList(),
        equals(['e_2026_11_15']),
      );

      // 下旬 (leap year Feb 29)
      const leapXiaFilter = TimelineFilterState(
        year: 2024,
        month: 2,
        xun: TimelineXun.xia,
      );
      expect(
        (await db.entriesDao.getFilteredTimelineEntries(filters: leapXiaFilter))
            .map((entry) => entry.id)
            .toList(),
        equals(['e_2024_02_29']),
      );

      // Charm filters: mood, weather, hasMediaOnly, weeklyReviewOnly
      final rainyEntries = await db.entriesDao.getFilteredTimelineEntries(
        filters: const TimelineFilterState(weather: 'rainy'),
      );
      expect(
        rainyEntries.map((entry) => entry.id).toList(),
        equals(['e_2026_11_30', 'e_2026_11_10_late']),
      );

      final mediaMoodEntries = await db.entriesDao.getFilteredTimelineEntries(
        filters: const TimelineFilterState(mood: 5, hasMediaOnly: true),
      );
      expect(
        mediaMoodEntries.map((entry) => entry.id).toList(),
        equals(['e_2026_11_01', 'e_2024_02_29']),
      );

      final weeklyEntries = await db.entriesDao.getFilteredTimelineEntries(
        filters: const TimelineFilterState(weeklyReviewOnly: true),
      );
      expect(
        weeklyEntries.map((entry) => entry.id).toList(),
        equals(['e_2026_11_15', 'e_2025_09_09']),
      );
    });

    test('getTimelineDateFacetSummary returns active years, currentYear, and activeMonths', () async {
      await seedFilterCorpus();

      final summaryAll = await db.entriesDao.getTimelineDateFacetSummary(
        currentYear: 2027,
      );
      expect(summaryAll.totalActiveEntries, equals(7));
      expect(summaryAll.years, equals([2027, 2026, 2025, 2024]));
      expect(summaryAll.activeMonths, equals({2, 9, 10, 11}));

      // Active year 2026 only shows months 10 and 11 (excludes deleted May entry)
      final summary2026 = await db.entriesDao.getTimelineDateFacetSummary(
        year: 2026,
        currentYear: 2027,
      );
      expect(summary2026.activeMonths, equals({10, 11}));

      // Active year 2026 + hasMediaOnly only shows month 11
      final summary2026Media = await db.entriesDao.getTimelineDateFacetSummary(
        year: 2026,
        hasMediaOnly: true,
        currentYear: 2027,
      );
      expect(summary2026Media.activeMonths, equals({11}));

      // Combined mood + weather facet summary filters activeMonths accurately
      final summaryRainyMood4 = await db.entriesDao.getTimelineDateFacetSummary(
        year: 2026,
        mood: 4,
        weather: 'rainy',
        currentYear: 2027,
      );
      expect(summaryRainyMood4.activeMonths, equals({11}));

      final summaryImpossible = await db.entriesDao.getTimelineDateFacetSummary(
        mood: 1,
        weather: 'sunny',
        currentYear: 2027,
      );
      expect(summaryImpossible.activeMonths, isEmpty);
    });

    test('TimelineFilterState charmSummaryLabel and resetCharms handle single and combined charms', () {
      const empty = TimelineFilterState(
        year: 2026,
        month: 11,
        xun: TimelineXun.shang,
        sortOrder: TimelineSortOrder.oldestFirst,
      );
      expect(empty.hasActiveCharmFilters, isFalse);
      expect(empty.charmSummaryLabel(), equals('全部笺签'));

      final moodAndMedia = empty.copyWith(mood: 5, hasMediaOnly: true);
      expect(moodAndMedia.hasActiveCharmFilters, isTrue);
      expect(moodAndMedia.charmSummaryLabel(), equals('欢欣 · 含图影'));

      final allCharms = empty.copyWith(
        mood: 3,
        weather: 'rainy',
        hasMediaOnly: true,
        weeklyReviewOnly: true,
      );
      expect(
        allCharms.charmSummaryLabel(),
        equals('静穆 · 润雨 · 含图影 · 周志复盘'),
      );

      // resetCharms clears only charm attributes while preserving date & sort
      final charmsReset = allCharms.resetCharms();
      expect(charmsReset.hasActiveCharmFilters, isFalse);
      expect(charmsReset.charmSummaryLabel(), equals('全部笺签'));
      expect(charmsReset.year, equals(2026));
      expect(charmsReset.month, equals(11));
      expect(charmsReset.xun, equals(TimelineXun.shang));
      expect(charmsReset.sortOrder, equals(TimelineSortOrder.oldestFirst));

      // resetAll clears both date and charm filters while preserving sortOrder
      final fullReset = allCharms.resetAll();
      expect(fullReset.hasActiveFilters, isFalse);
      expect(fullReset.year, isNull);
      expect(fullReset.month, isNull);
      expect(fullReset.xun, isNull);
      expect(fullReset.sortOrder, equals(TimelineSortOrder.oldestFirst));
    });

    test('EntriesDao filters combined date + mood + weather + media + weeklyReview accurately', () async {
      await seedFilterCorpus();

      const combined = TimelineFilterState(
        year: 2026,
        month: 11,
        xun: TimelineXun.zhong,
        mood: 3,
        weather: 'cloudy',
        hasMediaOnly: true,
        weeklyReviewOnly: true,
      );
      final matches = await db.entriesDao.getFilteredTimelineEntries(
        filters: combined,
      );
      expect(matches.map((entry) => entry.id).toList(), equals(['e_2026_11_15']));
      expect(
        await db.entriesDao.countFilteredTimelineEntries(filters: combined),
        equals(1),
      );

      const mismatch = TimelineFilterState(
        year: 2026,
        month: 11,
        mood: 5,
        weeklyReviewOnly: true,
      );
      expect(
        await db.entriesDao.getFilteredTimelineEntries(filters: mismatch),
        isEmpty,
      );
      expect(
        await db.entriesDao.countFilteredTimelineEntries(filters: mismatch),
        equals(0),
      );
    });
  });
}

