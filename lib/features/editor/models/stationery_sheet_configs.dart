import 'package:flutter/material.dart';
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

  /// Secondary icon colour for chrome drawn over this paper.
  Color get iconColor => isPaperDark ? const Color(0xFFDCD6CA) : const Color(0xFF2D2D2D);
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

