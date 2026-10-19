import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/search/services/event_suggestion_service.dart';

void main() {
  final refNow = DateTime(2026, 10, 18, 12, 0);

  Entry makeEntry({
    required String id,
    String? title,
    String plainText = '',
    DateTime? entryDate,
    DateTime? unlockAt,
    bool isDeleted = false,
    bool isLocked = false,
  }) {
    final d = entryDate ?? refNow.subtract(const Duration(days: 5));
    return Entry(
      id: id,
      notebookId: 'notebook_default',
      templateId: 'template_minimalist_white',
      title: title,
      contentDelta: '[{"insert":"$plainText\\n"}]',
      plainText: plainText,
      entryDate: d,
      mood: null,
      weather: null,
      isWeeklyReview: false,
      weekNumber: null,
      unlockAt: unlockAt,
      createdAt: d,
      updatedAt: d,
      isDeleted: isDeleted,
      isLocked: isLocked,
      entryPinHash: null,
    );
  }

  group('EventSuggestionService.rankFromEntries', () {
    test('extracts curated vocabulary and merges Chinese/English synonyms', () {
      final entries = [
        makeEntry(
          id: '1',
          title: '国庆杭州旅行',
          plainText: '今天去了西湖旅游。',
          entryDate: DateTime(2026, 10, 2),
        ),
        makeEntry(
          id: '2',
          title: 'Summer Trip to Kyoto',
          plainText: 'Amazing travel experience in Japan.',
          entryDate: DateTime(2026, 8, 15),
        ),
        makeEntry(
          id: '3',
          title: '准备期末考试',
          plainText: '复习高等数学。',
          entryDate: DateTime(2026, 10, 10),
        ),
      ];

      final suggestions = EventSuggestionService.rankFromEntries(
        entries,
        now: refNow,
      );

      expect(suggestions, isNotEmpty);
      final travelChip = suggestions.firstWhere((s) => s.term == '旅行');
      expect(travelChip.count, 2); // Merged entry 1 (zh) + entry 2 (en)
      expect(travelChip.isCurated, isTrue);

      final examChip = suggestions.firstWhere((s) => s.term == '考试');
      expect(examChip.count, 1);
      expect(examChip.isCurated, isTrue);

      // Travel (count 2) ranks above Exam (count 1)
      expect(suggestions.first.term, '旅行');
    });

    test('uses English canonical label when all matches for a topic are English', () {
      final entries = [
        makeEntry(
          id: '1',
          title: 'Weekend Trip',
          plainText: 'Solo travel to the mountains.',
        ),
        makeEntry(
          id: '2',
          title: 'Birthday Celebration',
          plainText: 'Had a great birthday cake.',
        ),
      ];

      final suggestions = EventSuggestionService.rankFromEntries(
        entries,
        now: refNow,
      );

      expect(suggestions.map((s) => s.term), containsAll(['Travel', 'Birthday']));
    });

    test('extracts recurring title tokens appearing in >= 3 entries and ignores stop words', () {
      final entries = [
        makeEntry(id: '1', title: '马拉松训练日记', plainText: 'Day 1'),
        makeEntry(id: '2', title: '马拉松训练准备', plainText: 'Day 2'),
        makeEntry(id: '3', title: '马拉松训练冲刺', plainText: 'Day 3'),
        makeEntry(id: '4', title: '吉他练习', plainText: 'Only 2 entries'),
        makeEntry(id: '5', title: '吉他练习', plainText: 'Only 2 entries'),
      ];

      final suggestions = EventSuggestionService.rankFromEntries(
        entries,
        now: refNow,
      );

      // '马拉松训练' appears in 3 titles (after stripping trailing '日记')
      final marathonChip =
          suggestions.firstWhere((s) => s.term == '马拉松训练');
      expect(marathonChip.count, 3);
      expect(marathonChip.isCurated, isFalse);

      // '吉他练习' only appears twice (< 3 threshold)
      expect(suggestions.any((s) => s.term == '吉他练习'), isFalse);
    });

    test('applies recency boost so newer topics outrank stale topics with equal count', () {
      final entries = [
        // Stale topic (200 days ago, recency boost = 0)
        makeEntry(
          id: '1',
          title: '读书笔记 A',
          plainText: '阅读了一本好书',
          entryDate: refNow.subtract(const Duration(days: 200)),
        ),
        makeEntry(
          id: '2',
          title: '读书笔记 B',
          plainText: '继续阅读',
          entryDate: refNow.subtract(const Duration(days: 195)),
        ),
        // Recent topic (1 day ago, recency boost near 1.0)
        makeEntry(
          id: '3',
          title: '晨跑打卡 1',
          plainText: '运动 5 公里',
          entryDate: refNow.subtract(const Duration(days: 2)),
        ),
        makeEntry(
          id: '4',
          title: '晨跑打卡 2',
          plainText: '今天继续跑步健身',
          entryDate: refNow.subtract(const Duration(days: 1)),
        ),
      ];

      final suggestions = EventSuggestionService.rankFromEntries(
        entries,
        now: refNow,
      );

      final workoutIndex = suggestions.indexWhere((s) => s.term == '运动');
      final readingIndex = suggestions.indexWhere((s) => s.term == '阅读');

      expect(workoutIndex, isNot(-1));
      expect(readingIndex, isNot(-1));
      expect(workoutIndex, lessThan(readingIndex));
      expect(suggestions[workoutIndex].score,
          greaterThan(suggestions[readingIndex].score));
    });

    test('enforces privacy invariants: excludes deleted, sealed capsules, and locked bodies', () {
      final entries = [
        // 1. Soft-deleted entry mentioning 旅行 -> must be excluded
        makeEntry(
          id: 'deleted_1',
          title: '云南旅行',
          plainText: '去了大理旅游',
          isDeleted: true,
        ),
        // 2. Sealed time capsule mentioning 考试 -> must be excluded
        makeEntry(
          id: 'sealed_2',
          title: '高考考试',
          plainText: '考试加油',
          unlockAt: refNow.add(const Duration(days: 30)),
        ),
        // 3. Unlocked time capsule mentioning 生日 -> must be included
        makeEntry(
          id: 'unlocked_3',
          title: '二十岁生日',
          plainText: '生日快乐',
          unlockAt: refNow.subtract(const Duration(days: 1)),
        ),
        // 4. Locked entry: body mentions 电影 & 音乐, title mentions 复盘 ->
        // ONLY title ('复盘') may be indexed; body ('电影', '音乐') must NOT leak!
        makeEntry(
          id: 'locked_4',
          title: '十月工作复盘',
          plainText: '秘密去看了电影和演唱会音乐节',
          isLocked: true,
        ),
      ];

      final suggestions = EventSuggestionService.rankFromEntries(
        entries,
        now: refNow,
      );

      final terms = suggestions.map((s) => s.term).toSet();
      expect(terms, containsAll(['生日', '工作', '复盘']));
      expect(terms, isNot(contains('旅行')));
      expect(terms, isNot(contains('考试')));
      expect(terms, isNot(contains('电影')));
      expect(terms, isNot(contains('音乐')));
    });
  });

  group('EventSuggestionService database + Isolate integration', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    test('getSuggestions queries AppDatabase and ranks in background Isolate', () async {
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'e1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('国庆成都旅行'),
          contentDelta: '[{"insert":"吃火锅旅游\\n"}]',
          plainText: '吃火锅旅游',
          entryDate: DateTime(2026, 10, 1),
        ),
      );
      await db.createEntry(
        EntriesCompanion.insert(
          id: 'e2',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('周末跑步运动'),
          contentDelta: '[{"insert":"健身房锻炼\\n"}]',
          plainText: '健身房锻炼',
          entryDate: DateTime(2026, 10, 12),
        ),
      );

      final service = EventSuggestionService(db);
      final results = await service.getSuggestions(
        now: refNow,
        forceIsolate: true,
      );

      expect(results.map((r) => r.term), containsAll(['旅行', '运动']));
    });
  });
}
