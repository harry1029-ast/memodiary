import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/calendar/lunar_calendar.dart';

/// Expected values are published lunar calendar dates (Hong Kong Observatory /
/// Purple Mountain Observatory almanacs), not recomputed from the data table.
void main() {
  LunarDate convert(int year, int month, int day) =>
      LunarCalendar.fromSolar(DateTime(year, month, day));

  group('known conversions', () {
    test('converts a known autumn date in 2026, ignoring the time of day', () {
      final lunar = LunarCalendar.fromSolar(DateTime(2026, 11, 23, 21, 15));
      expect(lunar.stemBranchYear, '丙午');
      expect(lunar.month, 10);
      expect(lunar.isLeapMonth, isFalse);
      expect(lunar.day, 15);
      expect(lunar.monthName, '十月');
      expect(lunar.dayName, '十五');
      expect(lunar.monthDayName, '十月十五');
      expect(lunar.seasonalMonthName, '孟冬');
      expect(lunar.isInSupportedRange, isTrue);
    });

    test('converts dates around 立冬 2026', () {
      expect(convert(2026, 11, 7).monthDayName, '九月廿九');
      expect(convert(2026, 11, 7).seasonalMonthName, '季秋');
      expect(convert(2026, 11, 10).monthDayName, '十月初二');
    });

    final newYearEves = <({
      DateTime eve,
      String eveYear,
      String eveMonthDay,
      DateTime newYearDay,
      String newYear,
    })>[
      (eve: DateTime(1985, 2, 19), eveYear: '甲子', eveMonthDay: '腊月三十', newYearDay: DateTime(1985, 2, 20), newYear: '乙丑'),
      (eve: DateTime(2000, 2, 4), eveYear: '己卯', eveMonthDay: '腊月廿九', newYearDay: DateTime(2000, 2, 5), newYear: '庚辰'),
      (eve: DateTime(2024, 2, 9), eveYear: '癸卯', eveMonthDay: '腊月三十', newYearDay: DateTime(2024, 2, 10), newYear: '甲辰'),
      (eve: DateTime(2026, 2, 16), eveYear: '乙巳', eveMonthDay: '腊月廿九', newYearDay: DateTime(2026, 2, 17), newYear: '丙午'),
      (eve: DateTime(2027, 2, 5), eveYear: '丙午', eveMonthDay: '腊月廿九', newYearDay: DateTime(2027, 2, 6), newYear: '丁未'),
    ];
    for (final newYearCase in newYearEves) {
      test('converts either side of the ${newYearCase.newYear} lunar new year', () {
        final eveLunar = LunarCalendar.fromSolar(newYearCase.eve);
        expect(eveLunar.stemBranchYear, newYearCase.eveYear);
        expect(eveLunar.monthDayName, newYearCase.eveMonthDay);
        expect(eveLunar.seasonalMonthName, '季冬');

        final newYearLunar = LunarCalendar.fromSolar(newYearCase.newYearDay);
        expect(newYearLunar.stemBranchYear, newYearCase.newYear);
        expect(newYearLunar.monthDayName, '正月初一');
        expect(newYearLunar.seasonalMonthName, '孟春');
      });
    }
  });

  group('leap months', () {
    test('flags 闰二月 2023 and gives it the base month\'s seasonal name', () {
      expect(convert(2023, 3, 21).monthDayName, '二月三十');
      final leap = convert(2023, 3, 22);
      expect(leap.month, 2);
      expect(leap.isLeapMonth, isTrue);
      expect(leap.monthDayName, '闰二月初一');
      expect(leap.seasonalMonthName, '仲春');
      expect(convert(2023, 4, 20).monthDayName, '三月初一');
    });

    test('flags 闰四月 2020', () {
      expect(convert(2020, 5, 22).monthDayName, '四月三十');
      final leap = convert(2020, 5, 23);
      expect(leap.isLeapMonth, isTrue);
      expect(leap.monthDayName, '闰四月初一');
      expect(leap.seasonalMonthName, '孟夏');
      expect(convert(2020, 6, 21).monthDayName, '五月初一');
    });

    test('distinguishes 六月 from 闰六月 in 2025', () {
      final regular = convert(2025, 6, 25);
      expect(regular.isLeapMonth, isFalse);
      expect(regular.monthDayName, '六月初一');
      final leap = convert(2025, 7, 25);
      expect(leap.isLeapMonth, isTrue);
      expect(leap.monthDayName, '闰六月初一');
      expect(leap.seasonalMonthName, '季夏');
      expect(convert(2025, 8, 23).monthDayName, '七月初一');
    });

    test('names the rare 闰冬月 of 2033 仲冬', () {
      final leap = convert(2033, 12, 22);
      expect(leap.isLeapMonth, isTrue);
      expect(leap.month, 11);
      expect(leap.monthDayName, '闰冬月初一');
      expect(leap.seasonalMonthName, '仲冬');
      expect(convert(2034, 1, 20).monthDayName, '腊月初一');
      expect(convert(2034, 1, 20).stemBranchYear, '癸丑');
    });
  });

  group('supported range bounds', () {
    test('converts the first supported day, 1900-01-31', () {
      final first = convert(1900, 1, 31);
      expect(first.stemBranchYear, '庚子');
      expect(first.monthDayName, '正月初一');
      expect(convert(1900, 2, 1).monthDayName, '正月初二');
    });

    test('converts the last days of lunar year 2100', () {
      expect(convert(2100, 2, 9).monthDayName, '正月初一');
      expect(convert(2100, 2, 9).stemBranchYear, '庚申');
      expect(convert(2100, 12, 31).monthDayName, '腊月初一');
      final last = convert(2101, 1, 28);
      expect(last.stemBranchYear, '庚申');
      expect(last.monthDayName, '腊月廿九');
    });

    test('returns only the stem-branch year before 1900-01-31', () {
      final before = convert(1900, 1, 30);
      expect(before.isInSupportedRange, isFalse);
      expect(before.stemBranchYear, '己亥');
      expect(before.month, isNull);
      expect(before.day, isNull);
      expect(before.monthName, isNull);
      expect(before.dayName, isNull);
      expect(before.monthDayName, isNull);
      expect(before.seasonalMonthName, isNull);
      expect(convert(1850, 6, 1).stemBranchYear, '庚戌');
    });

    test('returns only the stem-branch year after lunar year 2100, '
        'turning the year at 立春', () {
      final after = convert(2101, 1, 29);
      expect(after.isInSupportedRange, isFalse);
      expect(after.monthDayName, isNull);
      expect(after.stemBranchYear, '庚申');
      expect(convert(2101, 2, 4).stemBranchYear, '辛酉');
      expect(convert(2150, 6, 1).stemBranchYear, '庚戌');
    });
  });
}
