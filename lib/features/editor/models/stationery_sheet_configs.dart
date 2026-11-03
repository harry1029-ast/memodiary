import 'package:flutter/material.dart';
import '../../templates/models/template_style.dart';
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
}

/// Cohesive immutable metadata and callbacks for Sheet 1's Journal Letterhead.
class StationeryLetterheadConfig {
  final GlobalKey letterheadKey;
  final double headerHeight;
  final DateTime entryDate;
  final int? mood;
  final String? weather;
  final TextEditingController titleController;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int?> onMoodChanged;
  final ValueChanged<String?> onWeatherChanged;

  const StationeryLetterheadConfig({
    required this.letterheadKey,
    required this.headerHeight,
    required this.entryDate,
    required this.mood,
    required this.weather,
    required this.titleController,
    required this.onDateChanged,
    required this.onMoodChanged,
    required this.onWeatherChanged,
  });
}

