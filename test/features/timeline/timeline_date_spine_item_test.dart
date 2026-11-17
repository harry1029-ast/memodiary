import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/timeline/widgets/timeline_date_spine_item.dart';

void main() {
  group('Timeline Date Spine Helpers', () {
    test('formatGregorianDay formats days with numeric 日 suffix', () {
      expect(formatGregorianDay(1), '1日');
      expect(formatGregorianDay(15), '15日');
      expect(formatGregorianDay(25), '25日');
      expect(formatGregorianDay(31), '31日');
    });

    test('formatTraditionalChineseDay formats days to traditional Chinese lunar style', () {
      expect(formatTraditionalChineseDay(1), '初一');
      expect(formatTraditionalChineseDay(5), '初五');
      expect(formatTraditionalChineseDay(10), '初十');
      expect(formatTraditionalChineseDay(15), '十五');
      expect(formatTraditionalChineseDay(20), '二十');
      expect(formatTraditionalChineseDay(25), '廿五');
      expect(formatTraditionalChineseDay(28), '廿八');
      expect(formatTraditionalChineseDay(30), '三十');
      expect(formatTraditionalChineseDay(31), '三十一');
    });

    test('formatChineseWeekday formats weekday index to Chinese weekday', () {
      expect(formatChineseWeekday(1), '周一');
      expect(formatChineseWeekday(2), '周二');
      expect(formatChineseWeekday(3), '周三');
      expect(formatChineseWeekday(4), '周四');
      expect(formatChineseWeekday(5), '周五');
      expect(formatChineseWeekday(6), '周六');
      expect(formatChineseWeekday(7), '周日');
    });
  });

  group('TimelineDateSpineItem Widget Tests', () {
    testWidgets('renders date stamp badge with month, numeric Gregorian day by default, and weekday', (tester) async {
      final testDate = DateTime(2026, 10, 25); // Sunday

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: TimelineDateSpineItem(
              date: testDate,
              isFirst: true,
              isHighlighted: true,
              child: const Text('Test Entry Card'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify date components are rendered
      expect(find.text('10月'), findsOneWidget);
      expect(find.text('25日'), findsOneWidget);
      expect(find.text('廿五'), findsNothing);
      expect(find.text('周日'), findsOneWidget);
      expect(find.text('Test Entry Card'), findsOneWidget);

      // Verify Tooltip on badge
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('renders traditional lunar day when useLunarDay is true', (tester) async {
      final testDate = DateTime(2026, 10, 20); // Tuesday

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: TimelineDateSpineItem(
              date: testDate,
              isFirst: false,
              isLast: true,
              isHighlighted: false,
              useLunarDay: true,
              child: const Text('Standard Entry Card'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('10月'), findsOneWidget);
      expect(find.text('二十'), findsOneWidget);
      expect(find.text('周二'), findsOneWidget);
      expect(find.text('Standard Entry Card'), findsOneWidget);
    });
  });
}

