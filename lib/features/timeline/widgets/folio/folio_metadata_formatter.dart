import '../../../../core/calendar/lunar_calendar.dart';
import '../../../../core/documents/vertical_typography_mapper.dart';

/// Pure-Dart formatter for classical lunar/Gregorian dates, cinnabar seal
/// inscriptions, and opening reflection ribbons in the Thread-Bound Folio.
class FolioMetadataFormatter {
  const FolioMetadataFormatter._();

  /// Extracts an opening reflection ribbon string from explicit `{夹注:...}` annotation.
  ///
  /// Returns `null` if no `{夹注:...}` tag is authored, ensuring standard diary body
  /// text is never erroneously hijacked or displayed on the frontispiece cover.
  static String? extractOpeningReflection({
    required String plainText,
    String? title,
  }) {
    final match = VerticalTypographyMapper.interlinearRegex.firstMatch(plainText);
    if (match != null && match.group(1)?.isNotEmpty == true) {
      return '眉批夹注：${match.group(1)!.trim()}';
    }
    return null;
  }

  /// Formats the classical lunar date with its stem-branch year, e.g.
  /// `岁次丙午 · 十月十五`. Outside the lunar data range only the year is shown.
  static String formatFullLunarDate(DateTime date) {
    final lunar = LunarCalendar.fromSolar(date);
    final monthDay = lunar.monthDayName;
    return monthDay == null ? lunar.yearName : '${lunar.yearName} · $monthDay';
  }

  /// Formats Gregorian date with classical Shichen & Ke, e.g. `2026.11.23 · 亥时初刻`.
  static String formatGregorianDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final timeStr = _timeToShichenKe(date);
    return '$year.$month.$day · $timeStr';
  }

  static String _timeToShichenKe(DateTime date) {
    const shichenNames = [
      '子时',
      '丑时',
      '寅时',
      '卯时',
      '辰时',
      '巳时',
      '午时',
      '未时',
      '申时',
      '酉时',
      '戌时',
      '亥时',
    ];
    final hourIndex = ((date.hour + 1) ~/ 2) % 12;
    final shichen = shichenNames[hourIndex];

    const keNames = ['初刻', '一刻', '二刻', '三刻'];
    final keIndex = (date.minute ~/ 15).clamp(0, 3);
    final ke = keNames[keIndex];

    return '$shichen$ke';
  }

  /// Pads seal inscription to exactly 4 characters with '印' if shorter.
  static String normalizeSealText(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), '');
    final runes = clean.runes.map((rune) => String.fromCharCode(rune)).toList();
    if (runes.isEmpty) return '心迹安放';
    while (runes.length < 4) {
      runes.add('印');
    }
    return runes.take(4).join('');
  }
}
