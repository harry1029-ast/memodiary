import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';

/// Supported procedural background styles
enum TemplateBackgroundType {
  color,
  lined,
  grid,
  dotGrid,
  paperTexture;

  static TemplateBackgroundType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'lined':
        return TemplateBackgroundType.lined;
      case 'grid':
        return TemplateBackgroundType.grid;
      case 'dot_grid':
      case 'dotgrid':
        return TemplateBackgroundType.dotGrid;
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
      case TemplateBackgroundType.dotGrid:
        return 'dot_grid';
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
      case TemplateBackgroundType.dotGrid:
        return 'Dot Grid';
      case TemplateBackgroundType.paperTexture:
        return 'Kraft Paper';
    }
  }
}

/// Paper substrate texture types for procedural canvas rendering
enum PaperSubstrate {
  xuan,
  coldGold,
  minimal,
  kraft,
  obsidian;

  String get label {
    switch (this) {
      case PaperSubstrate.xuan:
        return '生宣原色';
      case PaperSubstrate.coldGold:
        return '冷金洒粉';
      case PaperSubstrate.minimal:
        return '素白简约';
      case PaperSubstrate.kraft:
        return '怀旧牛皮';
      case PaperSubstrate.obsidian:
        return '松烟暗夜';
    }
  }

  Color get defaultColor {
    switch (this) {
      case PaperSubstrate.xuan:
        return const Color(0xFFFBF8F1);
      case PaperSubstrate.coldGold:
        return const Color(0xFFF7F3E8);
      case PaperSubstrate.minimal:
        return const Color(0xFFFFFFFF);
      case PaperSubstrate.kraft:
        return const Color(0xFFE8DFCC);
      case PaperSubstrate.obsidian:
        return const Color(0xFF1E2022);
    }
  }

  Brightness get brightness {
    return this == PaperSubstrate.obsidian ? Brightness.dark : Brightness.light;
  }

  static PaperSubstrate fromString(String? value) {
    if (value == null) return PaperSubstrate.xuan;
    switch (value.toLowerCase()) {
      case 'coldgold':
      case 'cold_gold':
        return PaperSubstrate.coldGold;
      case 'minimal':
      case 'white':
        return PaperSubstrate.minimal;
      case 'kraft':
        return PaperSubstrate.kraft;
      case 'obsidian':
      case 'dark':
        return PaperSubstrate.obsidian;
      case 'xuan':
      default:
        return PaperSubstrate.xuan;
    }
  }
}

/// Tint colors for ruled lines, orthogonal grids, and dot matrices
enum RuleInkTint {
  slate,
  vermilion,
  charcoal,
  jade;

  String get label {
    switch (this) {
      case RuleInkTint.slate:
        return '淡墨青灰';
      case RuleInkTint.vermilion:
        return '朱砂印泥';
      case RuleInkTint.charcoal:
        return '松烟深黛';
      case RuleInkTint.jade:
        return '竹青碧玉';
    }
  }

  Color get color {
    switch (this) {
      case RuleInkTint.slate:
        return const Color(0x477A8B99);
      case RuleInkTint.vermilion:
        return const Color(0x52C04851);
      case RuleInkTint.charcoal:
        return const Color(0x404A4B4D);
      case RuleInkTint.jade:
        return const Color(0x47437A6D);
    }
  }

  static RuleInkTint fromString(String? value) {
    if (value == null) return RuleInkTint.slate;
    switch (value.toLowerCase()) {
      case 'vermilion':
        return RuleInkTint.vermilion;
      case 'charcoal':
        return RuleInkTint.charcoal;
      case 'jade':
        return RuleInkTint.jade;
      case 'slate':
      default:
        return RuleInkTint.slate;
    }
  }
}

/// Colophon seal carving styles
enum SealCarvingStyle {
  zhuwen,
  baiwen,
  hidden;

  String get label {
    switch (this) {
      case SealCarvingStyle.zhuwen:
        return '朱文 (阳刻)';
      case SealCarvingStyle.baiwen:
        return '白文 (阴刻)';
      case SealCarvingStyle.hidden:
        return '不加盖';
    }
  }

  static SealCarvingStyle fromString(String? value) {
    if (value == null) return SealCarvingStyle.zhuwen;
    switch (value.toLowerCase()) {
      case 'baiwen':
        return SealCarvingStyle.baiwen;
      case 'hidden':
      case 'none':
        return SealCarvingStyle.hidden;
      case 'zhuwen':
      default:
        return SealCarvingStyle.zhuwen;
    }
  }
}

/// Structured visual tokens encoded into template.background_value
class StationeryVisualTokens {
  final PaperSubstrate substrate;
  final RuleInkTint ruleTint;
  final SealCarvingStyle sealStyle;
  final Color? customBgColor;

  const StationeryVisualTokens({
    this.substrate = PaperSubstrate.xuan,
    this.ruleTint = RuleInkTint.slate,
    this.sealStyle = SealCarvingStyle.zhuwen,
    this.customBgColor,
  });

  Map<String, dynamic> toJson() => {
        'substrate': substrate.name,
        'ruleTint': ruleTint.name,
        'sealStyle': sealStyle.name,
        if (customBgColor != null)
          'customBgColor': TemplateStyle.toHexString(customBgColor!),
      };

  String toBackgroundValue() => jsonEncode(toJson());

  static StationeryVisualTokens fromJson(Map<String, dynamic> json) {
    return StationeryVisualTokens(
      substrate: PaperSubstrate.fromString(json['substrate'] as String?),
      ruleTint: RuleInkTint.fromString(json['ruleTint'] as String?),
      sealStyle: SealCarvingStyle.fromString(json['sealStyle'] as String?),
      customBgColor: json['customBgColor'] != null
          ? TemplateStyle.parseHexColor(json['customBgColor'] as String)
          : null,
    );
  }

  /// Parses backward-compatibly from JSON token or legacy #RRGGBB / #AARRGGBB hex
  static StationeryVisualTokens fromBackgroundValue(String value) {
    final clean = value.trim();
    if (clean.startsWith('{') && clean.endsWith('}')) {
      try {
        final decoded = jsonDecode(clean) as Map<String, dynamic>;
        return StationeryVisualTokens.fromJson(decoded);
      } catch (_) {
        // Fall through to fallback
      }
    }
    // Legacy hex string support
    if (clean.startsWith('#') || RegExp(r'^[0-9A-Fa-f]{6,8}$').hasMatch(clean)) {
      final color = TemplateStyle.parseHexColor(clean);
      final isDark = ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
      return StationeryVisualTokens(
        substrate: isDark ? PaperSubstrate.obsidian : PaperSubstrate.xuan,
        ruleTint: isDark ? RuleInkTint.slate : RuleInkTint.vermilion,
        sealStyle: SealCarvingStyle.zhuwen,
        customBgColor: color,
      );
    }
    return const StationeryVisualTokens();
  }

  StationeryVisualTokens copyWith({
    PaperSubstrate? substrate,
    RuleInkTint? ruleTint,
    SealCarvingStyle? sealStyle,
    Color? customBgColor,
  }) {
    return StationeryVisualTokens(
      substrate: substrate ?? this.substrate,
      ruleTint: ruleTint ?? this.ruleTint,
      sealStyle: sealStyle ?? this.sealStyle,
      customBgColor: customBgColor ?? this.customBgColor,
    );
  }
}

/// Curated stationery suite bundling paper substrate, rule tint, seal style, and layout
class StationerySuite {
  final String id;
  final String name;
  final String description;
  final PaperSubstrate substrate;
  final RuleInkTint ruleTint;
  final SealCarvingStyle sealStyle;
  final TemplateBackgroundType backgroundType;
  final String fontFamily;

  const StationerySuite({
    required this.id,
    required this.name,
    required this.description,
    required this.substrate,
    required this.ruleTint,
    required this.sealStyle,
    required this.backgroundType,
    required this.fontFamily,
  });

  /// Converts this curated suite into a full [Template] entity.
  Template toTemplate() {
    final tokens = StationeryVisualTokens(
      substrate: substrate,
      ruleTint: ruleTint,
      sealStyle: sealStyle,
      customBgColor: substrate.defaultColor,
    );
    return Template(
      id: 'suite_$id',
      name: name,
      backgroundType: backgroundType.name,
      backgroundValue: tokens.toBackgroundValue(),
      fontFamily: fontFamily,
      lineSpacing: 1.6,
      marginHorizontal: 24.0,
      isCustom: false,
    );
  }
}

/// Curated stationery suites available across the app
abstract final class StationerySuites {
  static const wenfang = StationerySuite(
    id: 'wenfang',
    name: '文房遗韵 · 朱丝宣纸',
    description: '生宣温润，朱丝雅致，如临兰亭',
    substrate: PaperSubstrate.xuan,
    ruleTint: RuleInkTint.vermilion,
    sealStyle: SealCarvingStyle.zhuwen,
    backgroundType: TemplateBackgroundType.lined,
    fontFamily: 'NotoSerifSC',
  );

  static const lengjin = StationerySuite(
    id: 'lengjin',
    name: '冷金洒粉 · 暖笺',
    description: '澄金细碎，松烟墨痕，岁月生辉',
    substrate: PaperSubstrate.coldGold,
    ruleTint: RuleInkTint.charcoal,
    sealStyle: SealCarvingStyle.zhuwen,
    backgroundType: TemplateBackgroundType.lined,
    fontFamily: 'NotoSerifSC',
  );

  static const zhuqing = StationerySuite(
    id: 'zhuqing',
    name: '竹青九宫 · 手账方格',
    description: '素白清爽，竹青正格，井然有序',
    substrate: PaperSubstrate.minimal,
    ruleTint: RuleInkTint.jade,
    sealStyle: SealCarvingStyle.baiwen,
    backgroundType: TemplateBackgroundType.grid,
    fontFamily: 'NotoSansSC',
  );

  static const songyan = StationerySuite(
    id: 'songyan',
    name: '松烟夜墨 · 暗夜',
    description: '玄石幽深，青灰微光，护眼静思',
    substrate: PaperSubstrate.obsidian,
    ruleTint: RuleInkTint.slate,
    sealStyle: SealCarvingStyle.baiwen,
    backgroundType: TemplateBackgroundType.lined,
    fontFamily: 'NotoSerifSC',
  );

  static const List<StationerySuite> all = [
    wenfang,
    lengjin,
    zhuqing,
    songyan,
  ];
}

/// Resolved presentation style model derived from Drift [Template] entity
class TemplateStyle {
  final TemplateBackgroundType type;
  final Color backgroundColor;
  final double lineSpacing;
  final double marginHorizontal;
  final String? fontFamily;
  final StationeryVisualTokens tokens;

  const TemplateStyle({
    required this.type,
    required this.backgroundColor,
    required this.lineSpacing,
    required this.marginHorizontal,
    this.fontFamily,
    this.tokens = const StationeryVisualTokens(),
  });

  /// Horizontal margin clamped to valid paper boundaries (16.0 to 36.0 px)
  double get resolvedHorizontalMargin => marginHorizontal.clamp(16.0, 36.0);

  /// Additional left gutter to clear the vertical red rule on lined stationery
  double get contentGutter => type == TemplateBackgroundType.lined ? 12.0 : 0.0;

  /// Effective left margin for content, including the lined stationery gutter
  double get contentMarginLeft => resolvedHorizontalMargin + contentGutter;

  factory TemplateStyle.fromTemplate(Template template) {
    final tokens = StationeryVisualTokens.fromBackgroundValue(template.backgroundValue);
    final resolvedColor = tokens.customBgColor ?? tokens.substrate.defaultColor;

    return TemplateStyle(
      type: TemplateBackgroundType.fromString(template.backgroundType),
      backgroundColor: resolvedColor,
      lineSpacing: template.lineSpacing,
      marginHorizontal: template.marginHorizontal,
      fontFamily: template.fontFamily,
      tokens: tokens,
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
