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
      return '批注：${match.group(1)!.trim()}';
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

  /// Formats Gregorian date with 24-hour `HH:mm` time, e.g. `2026.11.23 · 21:15`.
  static String formatGregorianDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$year.$month.$day · $hour:$minute';
  }
}
