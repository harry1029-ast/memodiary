/// Utility for converting solar dates into classical Chinese lunar-style calendar numerals
/// (e.g. "十月廿八", "十月廿三") for manuscript journal seals and display cards.
class ChineseCalendarHelper {
  static const List<String> _chineseMonths = [
    '正月',
    '二月',
    '三月',
    '四月',
    '五月',
    '六月',
    '七月',
    '八月',
    '九月',
    '十月',
    '冬月',
    '腊月',
  ];

  static const List<String> _chineseDays = [
    '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
    '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
    '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十',
    '三十一',
  ];

  /// Formats a [DateTime] into a four-character classical calendar string like `十月廿八`.
  static String formatMonthDay(DateTime date) {
    final monthIndex = (date.month - 1).clamp(0, 11);
    final dayIndex = (date.day - 1).clamp(0, _chineseDays.length - 1);
    final monthStr = _chineseMonths[monthIndex];
    final dayStr = _chineseDays[dayIndex];
    return '$monthStr$dayStr';
  }

  /// Splits the four-character calendar string into individual vertical characters.
  static List<String> formatVerticalChars(DateTime date) {
    final str = formatMonthDay(date);
    return str.split('');
  }
}

