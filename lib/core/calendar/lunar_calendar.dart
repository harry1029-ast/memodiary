import 'lunar_calendar_data.dart';

/// A solar date expressed in the Chinese lunar calendar.
///
/// Inside the supported range (lunar years 1900–2100, i.e. solar
/// 1900-01-31 to 2101-01-28) every field is set. Outside it only
/// [stemBranchYear] is known: [month], [day] and the derived names are null.
class LunarDate {
  const LunarDate({
    required this.stemBranchYear,
    this.month,
    this.isLeapMonth = false,
    this.day,
  });

  /// The lunar year's sexagenary stem-branch, e.g. `丙午`.
  final String stemBranchYear;

  /// The lunar month number (1–12); a leap month carries its base month's number.
  final int? month;

  /// Whether [month] is the year's intercalary (闰) month.
  final bool isLeapMonth;

  /// The day of the lunar month (1–30).
  final int? day;

  /// Whether the date fell inside the supported lunar data range.
  bool get isInSupportedRange => month != null && day != null;

  /// The month's name, e.g. `正月`, `冬月`, `闰六月`.
  String? get monthName {
    final monthNumber = month;
    if (monthNumber == null) return null;
    final base = _monthNames[monthNumber - 1];
    return isLeapMonth ? '闰$base' : base;
  }

  /// The day's name, e.g. `初五`, `廿三`, `三十`.
  String? get dayName {
    final dayNumber = day;
    return dayNumber == null ? null : _dayNames[dayNumber - 1];
  }

  /// The seasonal month name (孟/仲/季 + season), e.g. `孟冬`. A leap month
  /// takes its base month's name.
  String? get seasonalMonthName {
    final monthNumber = month;
    if (monthNumber == null) return null;
    final seasonIndex = (monthNumber - 1) ~/ 3;
    final rankIndex = (monthNumber - 1) % 3;
    return '${_seasonRanks[rankIndex]}${_seasons[seasonIndex]}';
  }

  /// The year with its classical prefix, e.g. `岁次丙午`; known in and out of
  /// range, so it stands in wherever the month and day are missing.
  String get yearName => '岁次$stemBranchYear';

  /// The month and day together, e.g. `十月十五`, or null out of range.
  String? get monthDayName {
    final monthText = monthName;
    final dayText = dayName;
    if (monthText == null || dayText == null) return null;
    return '$monthText$dayText';
  }

  @override
  bool operator ==(Object other) =>
      other is LunarDate &&
      other.stemBranchYear == stemBranchYear &&
      other.month == month &&
      other.isLeapMonth == isLeapMonth &&
      other.day == day;

  @override
  int get hashCode => Object.hash(stemBranchYear, month, isLeapMonth, day);

  @override
  String toString() =>
      'LunarDate($stemBranchYear${monthDayName == null ? '' : ' $monthDayName'})';

  static const List<String> _monthNames = [
    '正月', '二月', '三月', '四月', '五月', '六月',
    '七月', '八月', '九月', '十月', '冬月', '腊月',
  ];

  static const List<String> _dayNames = [
    '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
    '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
    '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十',
  ];

  static const List<String> _seasonRanks = ['孟', '仲', '季'];
  static const List<String> _seasons = ['春', '夏', '秋', '冬'];
}

/// Pure-Dart solar-to-lunar converter backed by offline data (no package,
/// no network).
abstract final class LunarCalendar {
  static const List<String> _stems = [
    '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
  ];
  static const List<String> _branches = [
    '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
  ];

  /// Converts the calendar day of [date] (its time of day is ignored).
  ///
  /// Outside the supported range only the stem-branch year is returned; with
  /// no lunar data there, the year is taken to turn at 立春 (approximated as
  /// 4 February), the traditional boundary of the sexagenary year.
  static LunarDate fromSolar(DateTime date) {
    final solarDay = DateTime.utc(date.year, date.month, date.day);
    var remainingDays = solarDay.difference(lunarDataEpoch).inDays;
    if (remainingDays < 0) return _outOfRange(solarDay);

    for (var index = 0; index < lunarYearData.length; index++) {
      final yearInfo = lunarYearData[index];
      final yearLength = _yearLength(yearInfo);
      if (remainingDays >= yearLength) {
        remainingDays -= yearLength;
        continue;
      }
      return _locateInYear(lunarDataFirstYear + index, yearInfo, remainingDays);
    }
    return _outOfRange(solarDay);
  }

  static LunarDate _outOfRange(DateTime solarDay) {
    final beforeSpringBegins = solarDay.isBefore(DateTime.utc(solarDay.year, 2, 4));
    final year = beforeSpringBegins ? solarDay.year - 1 : solarDay.year;
    return LunarDate(stemBranchYear: _stemBranchOf(year));
  }

  static LunarDate _locateInYear(int lunarYear, int yearInfo, int dayOfYear) {
    final leapMonth = yearInfo & 0xf;
    var remainingDays = dayOfYear;
    for (var month = 1; month <= 12; month++) {
      final regularLength = _regularMonthLength(yearInfo, month);
      if (remainingDays < regularLength) {
        return LunarDate(
          stemBranchYear: _stemBranchOf(lunarYear),
          month: month,
          day: remainingDays + 1,
        );
      }
      remainingDays -= regularLength;
      if (month == leapMonth) {
        final leapLength = _leapMonthLength(yearInfo);
        if (remainingDays < leapLength) {
          return LunarDate(
            stemBranchYear: _stemBranchOf(lunarYear),
            month: month,
            isLeapMonth: true,
            day: remainingDays + 1,
          );
        }
        remainingDays -= leapLength;
      }
    }
    throw StateError('Day $dayOfYear exceeds lunar year $lunarYear');
  }

  /// The sexagenary stem-branch of [lunarYear], e.g. 2026 → `丙午`.
  static String _stemBranchOf(int lunarYear) =>
      '${_stems[(lunarYear - 4) % 10]}${_branches[(lunarYear - 4) % 12]}';

  static int _regularMonthLength(int yearInfo, int month) =>
      (yearInfo & (0x10000 >> month)) != 0 ? 30 : 29;

  static int _leapMonthLength(int yearInfo) {
    if ((yearInfo & 0xf) == 0) return 0;
    return (yearInfo & 0x10000) != 0 ? 30 : 29;
  }

  static int _yearLength(int yearInfo) {
    var total = _leapMonthLength(yearInfo);
    for (var month = 1; month <= 12; month++) {
      total += _regularMonthLength(yearInfo, month);
    }
    return total;
  }
}
