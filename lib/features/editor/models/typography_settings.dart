import 'package:flutter/material.dart';

class FontOption {
  final String id;
  final String name;
  final String displayName;
  final String? fontFamily;
  final String description;

  const FontOption({
    required this.id,
    required this.name,
    String? displayName,
    this.fontFamily,
    required this.description,
  }) : displayName = displayName ?? name;
}

/// Catalog of 100% offline system & SIL OFL font families
class TypographyCatalog {
  static const List<FontOption> options = [
    FontOption(
      id: 'system',
      name: 'System Default',
      displayName: '系统默认',
      fontFamily: null,
      description: 'Native OS font typography',
    ),
    FontOption(
      id: 'serif',
      name: 'System Serif',
      displayName: '系统衬线',
      fontFamily: 'serif',
      description: 'Classic literary serif styling',
    ),
    FontOption(
      id: 'sans-serif',
      name: 'System Sans',
      displayName: '系统无衬线',
      fontFamily: 'sans-serif',
      description: 'Modern clean sans-serif',
    ),
    FontOption(
      id: 'monospace',
      name: 'Monospace',
      displayName: '等宽字体',
      fontFamily: 'monospace',
      description: 'Typewriter monospaced aesthetic',
    ),
    FontOption(
      id: 'noto_serif',
      name: 'Noto Serif',
      displayName: '思源宋体',
      fontFamily: 'Noto Serif',
      description: 'SIL OFL editorial serif typography',
    ),
    FontOption(
      id: 'inter',
      name: 'Inter',
      displayName: 'Inter（无衬线）',
      fontFamily: 'Inter',
      description: 'SIL OFL ultra-readable contemporary sans',
    ),
    FontOption(
      id: 'lora',
      name: 'Lora',
      displayName: 'Lora（衬线）',
      fontFamily: 'Lora',
      description: 'SIL OFL elegant reading font',
    ),
    FontOption(
      id: 'merriweather',
      name: 'Merriweather',
      displayName: 'Merriweather（衬线）',
      fontFamily: 'Merriweather',
      description: 'SIL OFL pleasant screen-reading serif',
    ),
    FontOption(
      id: 'playfair',
      name: 'Playfair Display',
      displayName: 'Playfair Display（标题）',
      fontFamily: 'Playfair Display',
      description: 'SIL OFL high-contrast decorative title serif',
    ),
    FontOption(
      id: 'source_code',
      name: 'Source Code Pro',
      displayName: 'Source Code Pro（等宽）',
      fontFamily: 'Source Code Pro',
      description: 'SIL OFL crisp monospace code & journal font',
    ),
    FontOption(
      id: 'caveat',
      name: 'Caveat',
      displayName: 'Caveat（手写体）',
      fontFamily: 'Caveat',
      description: 'SIL OFL casual handwritten script',
    ),
    FontOption(
      id: 'ma_shan_zheng',
      name: 'Ma Shan Zheng',
      displayName: '楷体',
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
  final Color? textColor;

  const TypographySettings({
    this.fontId = 'system',
    this.fontFamily,
    this.fontSize = 16.0,
    this.lineSpacing = 1.5,
    this.textColor,
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
    Color? textColor,
  }) {
    return TypographySettings(
      fontId: fontId ?? this.fontId,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      textColor: textColor ?? this.textColor,
    );
  }

  TextStyle toTextStyle({Color color = const Color(0xFF212121)}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: lineSpacing,
      color: textColor ?? color,
    );
  }
}

