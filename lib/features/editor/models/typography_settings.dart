import 'package:flutter/material.dart';

class FontOption {
  final String id;
  final String name;
  final String? fontFamily;
  final String description;

  const FontOption({
    required this.id,
    required this.name,
    this.fontFamily,
    required this.description,
  });
}

/// Catalog of 100% offline system & SIL OFL font families
class TypographyCatalog {
  static const List<FontOption> options = [
    FontOption(
      id: 'system',
      name: 'System Default',
      fontFamily: null,
      description: 'Native OS font typography',
    ),
    FontOption(
      id: 'serif',
      name: 'System Serif',
      fontFamily: 'serif',
      description: 'Classic literary serif styling',
    ),
    FontOption(
      id: 'sans-serif',
      name: 'System Sans',
      fontFamily: 'sans-serif',
      description: 'Modern clean sans-serif',
    ),
    FontOption(
      id: 'monospace',
      name: 'Monospace',
      fontFamily: 'monospace',
      description: 'Typewriter monospaced aesthetic',
    ),
    FontOption(
      id: 'noto_serif',
      name: 'Noto Serif',
      fontFamily: 'Noto Serif',
      description: 'SIL OFL editorial serif typography',
    ),
    FontOption(
      id: 'inter',
      name: 'Inter',
      fontFamily: 'Inter',
      description: 'SIL OFL ultra-readable contemporary sans',
    ),
    FontOption(
      id: 'lora',
      name: 'Lora',
      fontFamily: 'Lora',
      description: 'SIL OFL elegant reading font',
    ),
    FontOption(
      id: 'merriweather',
      name: 'Merriweather',
      fontFamily: 'Merriweather',
      description: 'SIL OFL pleasant screen-reading serif',
    ),
    FontOption(
      id: 'playfair',
      name: 'Playfair Display',
      fontFamily: 'Playfair Display',
      description: 'SIL OFL high-contrast decorative title serif',
    ),
    FontOption(
      id: 'source_code',
      name: 'Source Code Pro',
      fontFamily: 'Source Code Pro',
      description: 'SIL OFL crisp monospace code & journal font',
    ),
    FontOption(
      id: 'caveat',
      name: 'Caveat',
      fontFamily: 'Caveat',
      description: 'SIL OFL casual handwritten script',
    ),
    FontOption(
      id: 'ma_shan_zheng',
      name: 'Ma Shan Zheng',
      fontFamily: 'Ma Shan Zheng',
      description: 'SIL OFL expressive Chinese brush calligraphy',
    ),
  ];

  static FontOption findById(String id) {
    return options.firstWhere(
      (opt) => opt.id == id,
      orElse: () => options.first,
    );
  }
}

/// Dynamic typography state controlling visual editor presentation
class TypographySettings {
  final String fontId;
  final String? fontFamily;
  final double fontSize;
  final double lineSpacing;

  const TypographySettings({
    this.fontId = 'system',
    this.fontFamily,
    this.fontSize = 16.0,
    this.lineSpacing = 1.5,
  });

  /// Derives initial typography settings from a Template model
  factory TypographySettings.fromTemplate(dynamic template) {
    final family = template?.fontFamily as String?;
    final spacing = (template?.lineSpacing as num?)?.toDouble();
    return TypographySettings(
      fontFamily: (family == null || family == 'System') ? null : family,
      lineSpacing: spacing ?? 1.5,
    );
  }

  TypographySettings copyWith({
    String? fontId,
    String? fontFamily,
    double? fontSize,
    double? lineSpacing,
  }) {
    return TypographySettings(
      fontId: fontId ?? this.fontId,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
    );
  }

  TextStyle toTextStyle({Color color = const Color(0xFF212121)}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: lineSpacing,
      color: color,
    );
  }
}

