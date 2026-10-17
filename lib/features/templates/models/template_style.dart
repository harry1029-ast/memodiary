import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';

/// Supported procedural background styles
enum TemplateBackgroundType {
  color,
  lined,
  grid,
  paperTexture;

  static TemplateBackgroundType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'lined':
        return TemplateBackgroundType.lined;
      case 'grid':
        return TemplateBackgroundType.grid;
      case 'paper_texture':
      case 'papertexture':
        return TemplateBackgroundType.paperTexture;
      case 'color':
      default:
        return TemplateBackgroundType.color;
    }
  }

  String get toDbValue {
    switch (this) {
      case TemplateBackgroundType.color:
        return 'color';
      case TemplateBackgroundType.lined:
        return 'lined';
      case TemplateBackgroundType.grid:
        return 'grid';
      case TemplateBackgroundType.paperTexture:
        return 'paper_texture';
    }
  }

  String get label {
    switch (this) {
      case TemplateBackgroundType.color:
        return 'Solid Color';
      case TemplateBackgroundType.lined:
        return 'Lined Paper';
      case TemplateBackgroundType.grid:
        return 'Grid Paper';
      case TemplateBackgroundType.paperTexture:
        return 'Kraft Paper';
    }
  }
}

/// Resolved presentation style model derived from Drift [Template] entity
class TemplateStyle {
  final TemplateBackgroundType type;
  final Color backgroundColor;
  final double lineSpacing;
  final double marginHorizontal;
  final String? fontFamily;

  const TemplateStyle({
    required this.type,
    required this.backgroundColor,
    required this.lineSpacing,
    required this.marginHorizontal,
    this.fontFamily,
  });

  factory TemplateStyle.fromTemplate(Template template) {
    return TemplateStyle(
      type: TemplateBackgroundType.fromString(template.backgroundType),
      backgroundColor: parseHexColor(template.backgroundValue),
      lineSpacing: template.lineSpacing,
      marginHorizontal: template.marginHorizontal,
      fontFamily: template.fontFamily,
    );
  }

  /// Parses 6-char or 8-char hex strings with '#' prefix into Flutter [Color]
  static Color parseHexColor(String hexString, {Color fallback = Colors.white}) {
    try {
      String clean = hexString.replaceAll('#', '').trim();
      if (clean.length == 6) {
        clean = 'FF$clean';
      }
      if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  /// Formats a [Color] into a 6-character uppercase `#RRGGBB` string.
  static String toHexString(Color color) {
    final r = (color.r * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';
  }
}

