import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/models/letterhead_data.dart';

/// Expected strings are published almanac values (2026-11-07 is 九月廿九,
/// 2026-11-10 is 十月初二), not recomputed from the converter.
void main() {
  group('LetterheadData', () {
    test('builds the solar date line as yyyy年M月d日 周X', () {
      final data = LetterheadData.resolve(entryDate: DateTime(2026, 11, 10, 9, 5));
      expect(data.solarDateLine, '2026年11月10日 周二');
      expect(LetterheadData.resolve(entryDate: DateTime(2026, 11, 8)).solarDateLine, '2026年11月8日 周日');
    });

    test('exposes the seal text as seasonal month and stem-branch year', () {
      final data = LetterheadData.resolve(entryDate: DateTime(2026, 11, 10));
      expect(data.sealYearText, '丙午');
      expect(data.sealMonthText, '孟冬');
      expect(data.lunarDayName, '初二');
      expect(data.lunarDayLine, '十月初二');
    });

    test('keeps the seasonal month of the lunar month a date falls in', () {
      final data = LetterheadData.resolve(entryDate: DateTime(2026, 11, 7));
      expect(data.sealMonthText, '季秋');
      expect(data.lunarDayName, '廿九');
    });

    test('out-of-range dates carry the stem-branch year only', () {
      final data = LetterheadData.resolve(entryDate: DateTime(1850, 6, 1));
      expect(data.sealYearText, '庚戌');
      expect(data.sealMonthText, isNull);
      expect(data.lunarDayName, isNull);
      expect(data.lunarDayLine, isNull);
      expect(data.sealSemanticsLabel, '岁次庚戌，轻触修改日期');
    });

    test('labels the seal for screen readers', () {
      final data = LetterheadData.resolve(entryDate: DateTime(2026, 11, 10));
      expect(data.sealSemanticsLabel, '岁次丙午 孟冬初二，轻触修改日期');
    });

    test('labels the date block with solar date, lunar day and solar term', () {
      final data = LetterheadData.resolve(entryDate: DateTime(2026, 11, 10));
      expect(data.dateSemanticsLabel, '2026年11月10日 周二，农历十月初二，立冬');
    });

    test('defaults weather to 晴明 and mood to 怡然, and keeps raw values', () {
      final defaults = LetterheadData.resolve(entryDate: DateTime(2026, 11, 10));
      expect(defaults.weatherOption.label, '晴明');
      expect(defaults.moodOption.label, '怡然');
      expect(defaults.weather, isNull);
      expect(defaults.mood, isNull);

      final chosen = LetterheadData.resolve(
        entryDate: DateTime(2026, 11, 10),
        weather: 'rainy',
        mood: 5,
      );
      expect(chosen.weatherOption.label, '润雨');
      expect(chosen.moodOption.label, '欢欣');
      expect(chosen.weather, 'rainy');
      expect(chosen.mood, 5);
    });
  });
}
