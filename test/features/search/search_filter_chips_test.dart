import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/search/models/search_filters.dart';
import 'package:memodiary/features/search/widgets/search_filter_chips.dart';

void main() {
  Future<List<SearchFilters>> pumpChips(WidgetTester tester) async {
    // A phone viewport: the pickers' sheets hold seven rows.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final changes = <SearchFilters>[];
    await tester.pumpWidget(MaterialApp(
      theme: InkDiaryTheme.light,
      home: Scaffold(
        body: SearchFilterChips(filters: const SearchFilters(), onFiltersChanged: changes.add),
      ),
    ));
    return changes;
  }

  group('SearchFilterChips', () {
    testWidgets('the mood picker offers the five letterhead moods and filters by the chosen one', (tester) async {
      final changes = await pumpChips(tester);

      await tester.tap(find.byKey(const Key('search_mood_filter_pill')));
      await tester.pumpAndSettle();
      for (final label in ['沉郁', '倦怠', '静穆', '怡然', '欢欣']) {
        expect(find.widgetWithText(ListTile, label), findsOneWidget);
      }

      await tester.tap(find.widgetWithText(ListTile, '欢欣'));
      await tester.pumpAndSettle();
      expect(changes.single.mood, 5);
    });

    testWidgets('the weather picker offers the five letterhead weathers and filters by the chosen one', (tester) async {
      final changes = await pumpChips(tester);

      await tester.tap(find.byKey(const Key('search_weather_filter_pill')));
      await tester.pumpAndSettle();
      for (final label in ['晴明', '阴翳', '润雨', '朔风', '凝雪']) {
        expect(find.widgetWithText(ListTile, label), findsOneWidget);
      }

      await tester.tap(find.widgetWithText(ListTile, '润雨'));
      await tester.pumpAndSettle();
      expect(changes.single.weather, 'rainy');
    });
  });
}
