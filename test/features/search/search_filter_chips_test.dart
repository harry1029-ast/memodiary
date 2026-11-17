import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/search/models/search_filters.dart';
import 'package:memodiary/features/search/widgets/search_filter_chips.dart';

void main() {
  Future<List<SearchFilters>> pumpChips(
    WidgetTester tester, {
    SearchFilters initialFilters = const SearchFilters(),
  }) async {
    // A phone viewport: the pickers' sheets hold seven rows.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final changes = <SearchFilters>[];
    await tester.pumpWidget(MaterialApp(
      theme: InkDiaryTheme.light,
      home: Scaffold(
        body: SearchFilterChips(
          filters: initialFilters,
          onFiltersChanged: changes.add,
        ),
      ),
    ));
    return changes;
  }

  group('SearchFilterChips', () {
    testWidgets('displays plain Chinese filter pills and date range sheet without English suffixes', (tester) async {
      final changes = await pumpChips(tester);

      expect(find.text('时间: 全部'), findsOneWidget);
      expect(find.text('心情: 全部'), findsOneWidget);
      expect(find.text('天气: 全部'), findsOneWidget);
      expect(find.text('含照片'), findsOneWidget);
      expect(find.text('每周复盘'), findsOneWidget);

      await tester.tap(find.byKey(const Key('search_date_filter_pill')));
      await tester.pumpAndSettle();

      for (final label in ['全部时间', '本周', '本月', '自定义日期范围...']) {
        expect(find.widgetWithText(ListTile, label), findsOneWidget);
      }

      await tester.tap(find.widgetWithText(ListTile, '本周'));
      await tester.pumpAndSettle();
      expect(changes.single.dateType, DateFilterType.thisWeek);
    });

    testWidgets('the mood picker offers the five letterhead moods and filters by the chosen one', (tester) async {
      final changes = await pumpChips(tester);

      await tester.tap(find.byKey(const Key('search_mood_filter_pill')));
      await tester.pumpAndSettle();
      expect(find.text('按心情筛选'), findsOneWidget);
      expect(find.widgetWithText(ListTile, '全部心情'), findsOneWidget);
      for (final label in ['低落', '疲惫', '平静', '开心', '喜悦']) {
        expect(find.widgetWithText(ListTile, label), findsOneWidget);
      }

      await tester.tap(find.widgetWithText(ListTile, '喜悦'));
      await tester.pumpAndSettle();
      expect(changes.single.mood, 5);
    });

    testWidgets('the weather picker offers the five letterhead weathers and renders Chinese chip labels', (tester) async {
      final changes = await pumpChips(tester);

      await tester.tap(find.byKey(const Key('search_weather_filter_pill')));
      await tester.pumpAndSettle();
      expect(find.text('按天气筛选'), findsOneWidget);
      expect(find.widgetWithText(ListTile, '全部天气'), findsOneWidget);
      for (final label in ['晴天', '多云', '下雨', '大风', '下雪']) {
        expect(find.widgetWithText(ListTile, label), findsOneWidget);
      }

      await tester.tap(find.widgetWithText(ListTile, '下雨'));
      await tester.pumpAndSettle();
      expect(changes.single.weather, 'rainy');

      // Active filters show localized weather label and reset pill
      final resetChanges = await pumpChips(
        tester,
        initialFilters: const SearchFilters(weather: 'rainy', hasImage: true),
      );
      expect(find.text('天气: 下雨'), findsOneWidget);
      expect(find.text('重置筛选'), findsOneWidget);

      await tester.tap(find.byKey(const Key('reset_filters_pill')));
      await tester.pumpAndSettle();
      expect(resetChanges.single.hasActiveFilters, isFalse);
    });
  });
}
