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
}

