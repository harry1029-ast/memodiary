import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/intro/utils/chinese_calendar_helper.dart';

void main() {
  group('ChineseCalendarHelper Tests', () {
    test('formats month and day into classical Chinese numerals', () {
      final dateOct23 = DateTime(2026, 10, 23);
      expect(ChineseCalendarHelper.formatMonthDay(dateOct23), equals('十月廿三'));

      final dateOct28 = DateTime(2026, 10, 28);
      expect(ChineseCalendarHelper.formatMonthDay(dateOct28), equals('十月廿八'));

      final dateJan1 = DateTime(2026, 1, 1);
      expect(ChineseCalendarHelper.formatMonthDay(dateJan1), equals('正月初一'));

      final dateDec31 = DateTime(2026, 12, 31);
      expect(ChineseCalendarHelper.formatMonthDay(dateDec31), equals('腊月三十一'));
    });

    test('splits formatted date into vertical characters', () {
      final date = DateTime(2026, 10, 23);
      final chars = ChineseCalendarHelper.formatVerticalChars(date);
      expect(chars, equals(['十', '月', '廿', '三']));
    });
  });
}

