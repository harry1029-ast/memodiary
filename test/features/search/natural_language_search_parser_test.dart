import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/search/models/search_filters.dart';
import 'package:memodiary/features/search/services/natural_language_search_parser.dart';

void main() {
  const parser = NaturalLanguageSearchParser();
  final refNow = DateTime(2026, 10, 18, 15, 30); // Sunday, Oct 18, 2026

  group('NaturalLanguageSearchParser — Temporal & Holiday Queries', () {
    test('parses "去年国庆发生的事" into Oct 1–7 of last year with empty residual keywords', () {
      final res = parser.parse('去年国庆发生的事', now: refNow);

      expect(res.startDate, DateTime(2025, 10, 1, 0, 0, 0));
      expect(res.endDate, DateTime(2025, 10, 7, 23, 59, 59, 999));
      expect(res.keywords, isEmpty);
      expect(res.detected.length, 1);
      expect(res.detected.single.kind, ConstraintKind.dateRange);
    });

    test('parses "今年国庆" and bare "国庆" before/after Oct 1', () {
      final thisYearRes = parser.parse('今年国庆旅行', now: refNow);
      expect(thisYearRes.startDate, DateTime(2026, 10, 1, 0, 0, 0));
      expect(thisYearRes.endDate, DateTime(2026, 10, 7, 23, 59, 59, 999));
      expect(thisYearRes.keywords, '旅行');

      // Bare "国庆" in Oct 2026 -> 2026
      final afterOct1 = parser.parse('国庆', now: DateTime(2026, 10, 18));
      expect(afterOct1.startDate, DateTime(2026, 10, 1, 0, 0, 0));

      // Bare "国庆" in May 2026 -> most recent past = 2025
      final beforeOct1 = parser.parse('国庆', now: DateTime(2026, 5, 10));
      expect(beforeOct1.startDate, DateTime(2025, 10, 1, 0, 0, 0));
    });

    test('parses other fixed Gregorian holidays (元旦, 情人节, 五一/劳动节, 圣诞 + English)', () {
      final newYear = parser.parse('今年元旦', now: refNow);
      expect(newYear.startDate, DateTime(2026, 1, 1, 0, 0, 0));
      expect(newYear.endDate, DateTime(2026, 1, 3, 23, 59, 59, 999));

      final labor = parser.parse('五一露营', now: refNow);
      expect(labor.startDate, DateTime(2026, 5, 1, 0, 0, 0));
      expect(labor.endDate, DateTime(2026, 5, 5, 23, 59, 59, 999));
      expect(labor.keywords, '露营');

      // Bare Christmas in Oct 2026 -> Dec 24-25, 2025
      final xmas = parser.parse('christmas party', now: refNow);
      expect(xmas.startDate, DateTime(2025, 12, 24, 0, 0, 0));
      expect(xmas.endDate, DateTime(2025, 12, 25, 23, 59, 59, 999));
      expect(xmas.keywords, 'party');
    });

    test('parses "10月所有周记" into Oct 2026 + weeklyReviewOnly = true', () {
      final res = parser.parse('10月所有周记', now: refNow);

      expect(res.startDate, DateTime(2026, 10, 1, 0, 0, 0));
      expect(res.endDate, DateTime(2026, 10, 31, 23, 59, 59, 999));
      expect(res.weeklyReviewOnly, isTrue);
      expect(res.keywords, isEmpty);
      expect(res.detected.length, 2);
    });

    test('resolves ambiguous bare month "12月" in Oct 2026 to most-recent-past (Dec 2025)', () {
      final res = parser.parse('12月总结', now: refNow);

      expect(res.startDate, DateTime(2025, 12, 1, 0, 0, 0));
      expect(res.endDate, DateTime(2025, 12, 31, 23, 59, 59, 999));
      expect(res.keywords, '总结');
    });

    test('parses explicit year+month ("2025年10月", "October 2025") and full years ("去年", "今年")', () {
      final zhYm = parser.parse('2025年10月', now: refNow);
      expect(zhYm.startDate, DateTime(2025, 10, 1, 0, 0, 0));
      expect(zhYm.endDate, DateTime(2025, 10, 31, 23, 59, 59, 999));

      final enYm = parser.parse('in October 2025 hiking', now: refNow);
      expect(enYm.startDate, DateTime(2025, 10, 1, 0, 0, 0));
      expect(enYm.endDate, DateTime(2025, 10, 31, 23, 59, 59, 999));
      expect(enYm.keywords, 'hiking');

      final lastYear = parser.parse('去年阅读', now: refNow);
      expect(lastYear.startDate, DateTime(2025, 1, 1, 0, 0, 0));
      expect(lastYear.endDate, DateTime(2025, 12, 31, 23, 59, 59, 999));
      expect(lastYear.keywords, '阅读');
    });

    test('parses relative months and weeks ("上个月"/"last month", "本月", "上周", "本周") including January rollover', () {
      final lastMonth = parser.parse('上个月', now: refNow);
      expect(lastMonth.startDate, DateTime(2026, 9, 1, 0, 0, 0));
      expect(lastMonth.endDate, DateTime(2026, 9, 30, 23, 59, 59, 999));

      // January rollover -> December of previous year
      final janLastMonth = parser.parse('last month', now: DateTime(2026, 1, 15));
      expect(janLastMonth.startDate, DateTime(2025, 12, 1, 0, 0, 0));
      expect(janLastMonth.endDate, DateTime(2025, 12, 31, 23, 59, 59, 999));

      // refNow is Sunday 2026-10-18 -> this week is Mon Oct 12 .. Sun Oct 18
      final thisWeek = parser.parse('本周运动', now: refNow);
      expect(thisWeek.startDate, DateTime(2026, 10, 12, 0, 0, 0));
      expect(thisWeek.endDate, DateTime(2026, 10, 18, 23, 59, 59, 999));
      expect(thisWeek.keywords, '运动');

      // last week is Mon Oct 5 .. Sun Oct 11
      final lastWeek = parser.parse('上周', now: refNow);
      expect(lastWeek.startDate, DateTime(2026, 10, 5, 0, 0, 0));
      expect(lastWeek.endDate, DateTime(2026, 10, 11, 23, 59, 59, 999));
    });
  });

  group('NaturalLanguageSearchParser — Categories, Photos, Weather & Edge Cases', () {
    test('parses photo flags, weather terms, and preserves non-weather words like "雪糕"', () {
      final combo = parser.parse('上个月雨天带图徒步', now: refNow);
      expect(combo.startDate, DateTime(2026, 9, 1, 0, 0, 0));
      expect(combo.weather, 'rainy');
      expect(combo.hasImage, isTrue);
      expect(combo.keywords, '徒步');

      final enCombo = parser.parse('with photos last week sunny', now: refNow);
      expect(enCombo.hasImage, isTrue);
      expect(enCombo.weather, 'sunny');
      expect(enCombo.keywords, isEmpty);

      // "雪糕" must NOT trigger snowy weather filter!
      final iceCream = parser.parse('雪糕', now: refNow);
      expect(iceCream.weather, isNull);
      expect(iceCream.keywords, '雪糕');
      expect(iceCream.hasDetectedConstraints, isFalse);
    });

    test('applyTo overrides manual SearchFilters and ignoredKinds skips dismissed constraints', () {
      const manualFilters = SearchFilters(
        dateType: DateFilterType.thisWeek,
        weather: 'sunny',
      );
      final parsed = parser.parse('去年国庆雨天', now: refNow);
      final effective = parsed.applyTo(manualFilters);

      expect(effective.dateType, DateFilterType.custom);
      expect(effective.resolvedStartDate, DateTime(2025, 10, 1, 0, 0, 0));
      expect(effective.weather, 'rainy');

      // When user dismisses the weather chip, weather is not extracted and stays in keywords
      final dismissedWeather = parser.parse(
        '去年国庆雨天',
        now: refNow,
        ignoredKinds: {ConstraintKind.weather},
      );
      expect(dismissedWeather.weather, isNull);
      expect(dismissedWeather.keywords, '雨天');
    });
  });

  group('AppDatabase — Chinese Substring (LIKE + FTS5) Search Fallback', () {
    test('matches Chinese substring inside contiguous CJK sentence via LIKE fallback', () async {
      final db = AppDatabase.memory();
      addTearDown(() => db.close());

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'cjk_entry_1',
          notebookId: 'notebook_default',
          templateId: 'template_minimalist_white',
          title: const Value('国庆杭州之行'),
          contentDelta: '[{"insert":"今天去西湖旅行了，风景特别美。\\n"}]',
          plainText: '今天去西湖旅行了，风景特别美。',
          entryDate: DateTime(2025, 10, 2, 14, 0),
          weather: const Value('sunny'),
        ),
      );

      final parsed = parser.parse('去年国庆旅行', now: refNow);
      final results = await db.searchEntriesWithFilters(
        query: parsed.keywords, // '旅行'
        startDate: parsed.startDate,
        endDate: parsed.endDate,
      );

      expect(results.length, 1);
      expect(results.single.id, 'cjk_entry_1');
    });
  });
}

