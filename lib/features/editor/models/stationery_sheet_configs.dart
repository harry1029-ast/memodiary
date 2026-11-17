import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../templates/models/template_style.dart';
import 'letterhead_data.dart';
import 'typography_settings.dart';

/// Cohesive immutable styling configuration for rendering a Stationery Sheet canvas.
class StationerySheetThemeConfig {
  final TemplateStyle templateStyle;
  final TypographySettings typography;
  final ThemeData paperBaseTheme;
  final Color inkColor;
  final bool isPaperDark;

  const StationerySheetThemeConfig({
    required this.templateStyle,
    required this.typography,
    required this.paperBaseTheme,
    required this.inkColor,
    required this.isPaperDark,
  });

  /// Derives paper brightness, base theme and ink colour from [templateStyle].
  factory StationerySheetThemeConfig.fromTemplateStyle({
    required TemplateStyle templateStyle,
    required TypographySettings typography,
  }) {
    final isPaperDark =
        ThemeData.estimateBrightnessForColor(templateStyle.backgroundColor) == Brightness.dark;
    return StationerySheetThemeConfig(
      templateStyle: templateStyle,
      typography: typography,
      paperBaseTheme: isPaperDark ? ThemeData.dark() : ThemeData.light(),
      inkColor: isPaperDark ? const Color(0xFFF0ECE3) : const Color(0xFF212121),
      isPaperDark: isPaperDark,
    );
  }

  /// A template's own paper and typography, as a freshly selected template
  /// shows them.
  factory StationerySheetThemeConfig.fromTemplate(Template template) => StationerySheetThemeConfig.fromTemplateStyle(
        templateStyle: TemplateStyle.fromTemplate(template),
        typography: TypographySettings.fromTemplate(template),
      );

  /// The colour characters are written in: the typography's text colour,
  /// else the paper's own [inkColor]. Ink Choreography writes on the sheet
  /// and in the Trial Rice-Grid in this colour.
  Color get writingInkColor => resolveWritingInk(typography, paperInk: inkColor);

  /// The single resolver behind [writingInkColor].
  static Color resolveWritingInk(TypographySettings typography, {required Color paperInk}) =>
      typography.textColor ?? paperInk;

  /// Secondary icon colour for chrome drawn over this paper.
  Color get iconColor => isPaperDark ? const Color(0xFFDCD6CA) : const Color(0xFF2D2D2D);
}

/// What the Trial Rice-Grid writes with: the sheet's writing ink, its paper,
/// and the Brush Mountain font family, so the grid previews exactly what the
/// Stationery Sheet will show.
@immutable
class TrialInkStyle {
  /// The resolved writing ink (see [StationerySheetThemeConfig.writingInkColor]).
  final Color inkColor;
  final Color paperColor;
  final String? fontFamily;

  /// The paper's own ink under any typography text colour, kept so a
  /// typography change re-resolves [inkColor].
  final Color paperInkColor;

  const TrialInkStyle({
    required this.inkColor,
    required this.paperColor,
    required this.paperInkColor,
    this.fontFamily,
  });

  /// Light paper with its default ink, for a drawer opened without a sheet.
  static const TrialInkStyle fallback = TrialInkStyle(
    inkColor: Color(0xFF212121),
    paperColor: Color(0xFFFBF8F1),
    paperInkColor: Color(0xFF212121),
  );

  factory TrialInkStyle.of(StationerySheetThemeConfig sheetTheme) => TrialInkStyle(
        inkColor: sheetTheme.writingInkColor,
        paperColor: sheetTheme.templateStyle.backgroundColor,
        paperInkColor: sheetTheme.inkColor,
        fontFamily: sheetTheme.typography.fontFamily,
      );

  /// The same paper written with [typography]'s text colour and font.
  TrialInkStyle withTypography(TypographySettings typography) => TrialInkStyle(
        inkColor: StationerySheetThemeConfig.resolveWritingInk(typography, paperInk: paperInkColor),
        paperColor: paperColor,
        paperInkColor: paperInkColor,
        fontFamily: typography.fontFamily,
      );

  @override
  bool operator ==(Object other) =>
      other is TrialInkStyle &&
      other.inkColor == inkColor &&
      other.paperColor == paperColor &&
      other.paperInkColor == paperInkColor &&
      other.fontFamily == fontFamily;

  @override
  int get hashCode => Object.hash(inkColor, paperColor, paperInkColor, fontFamily);
}

/// Cohesive immutable metadata and callbacks for Sheet 1's Journal Letterhead.
class StationeryLetterheadConfig {
  final LetterheadData data;
  final TextEditingController titleController;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int?> onMoodChanged;
  final ValueChanged<String?> onWeatherChanged;

  const StationeryLetterheadConfig({
    required this.data,
    required this.titleController,
    required this.onDateChanged,
    required this.onMoodChanged,
    required this.onWeatherChanged,
  });
}

