import 'package:flutter/material.dart';
import '../../../templates/models/template_style.dart';

/// Available non-destructive reading perspective modes for the Thread-Bound Folio.
enum ReadingPerspective {
  /// Faithful to the entry's saved stationery template (Default).
  faithfulOriginal,

  /// Classical vermilion red ruled vertical columns (10 columns R-to-L).
  vermilionVertical,

  /// Genkō manuscript grid (10 columns x 16 character cells R-to-L).
  genkoManuscript,

  /// Obsidian dark gold night rubbing with horizontal rules.
  obsidianNight;

  /// Chinese display label for perspective selector.
  String get label => switch (this) {
        ReadingPerspective.faithfulOriginal => '忠实原貌',
        ReadingPerspective.vermilionVertical => '朱丝古刻',
        ReadingPerspective.genkoManuscript => '原稿墨格',
        ReadingPerspective.obsidianNight => '松烟夜卷',
      };

  /// Concise subtitle explaining the presentation without bloated flavor text.
  String get subtitle => switch (this) {
        ReadingPerspective.faithfulOriginal => '遵循手稿原定信笺格式',
        ReadingPerspective.vermilionVertical => '十列朱丝栏古籍竖排',
        ReadingPerspective.genkoManuscript => '十六行原稿纸朱墨方格',
        ReadingPerspective.obsidianNight => '玄石金粉暗夜沉浸横排',
      };

  /// The ruling layout associated with this perspective.
  FolioRulingLayout get rulingLayout => switch (this) {
        ReadingPerspective.faithfulOriginal => FolioRulingLayout.faithfulHorizontal,
        ReadingPerspective.vermilionVertical => FolioRulingLayout.vermilionVertical,
        ReadingPerspective.genkoManuscript => FolioRulingLayout.genkoVertical,
        ReadingPerspective.obsidianNight => FolioRulingLayout.faithfulHorizontal,
      };

  /// Resolves the visual substrate theme for this perspective, taking into account
  /// the entry's saved [templateStyle] when [faithfulOriginal] is selected.
  FolioSubstrateTheme resolveTheme({TemplateStyle? templateStyle}) {
    switch (this) {
      case ReadingPerspective.vermilionVertical:
        return FolioSubstrateTheme.xuan;
      case ReadingPerspective.genkoManuscript:
        return FolioSubstrateTheme.coldGold;
      case ReadingPerspective.obsidianNight:
        return FolioSubstrateTheme.obsidian;
      case ReadingPerspective.faithfulOriginal:
        if (templateStyle == null) {
          return FolioSubstrateTheme.xuan;
        }
        final substrate = templateStyle.tokens.substrate;
        if (substrate == PaperSubstrate.obsidian) {
          return FolioSubstrateTheme.obsidian.copyWith(
            fontFamily: templateStyle.fontFamily,
          );
        }
        if (substrate == PaperSubstrate.coldGold) {
          return FolioSubstrateTheme.coldGold.copyWith(
            fontFamily: templateStyle.fontFamily,
          );
        }
        final isDark = substrate.brightness == Brightness.dark;
        return FolioSubstrateTheme(
          label: substrate.label,
          pageBg: templateStyle.backgroundColor,
          pageBackBg: Color.lerp(templateStyle.backgroundColor, isDark ? Colors.white : Colors.black, 0.04) ??
              templateStyle.backgroundColor,
          inkPrimary: isDark ? const Color(0xFFE6E1D8) : const Color(0xFF231F1C),
          inkSecondary: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF70675E),
          ruleColor: templateStyle.tokens.ruleTint.color,
          frameColor: templateStyle.tokens.ruleTint.color.withValues(alpha: 0.85),
          showGoldFlecks: substrate == PaperSubstrate.coldGold,
          isDark: isDark,
          fontFamily: templateStyle.fontFamily,
        );
    }
  }

  /// Resolves the colophon seal carving style for this perspective.
  SealCarvingStyle resolveSealStyle({TemplateStyle? templateStyle}) {
    return switch (this) {
      ReadingPerspective.vermilionVertical => SealCarvingStyle.zhuwen,
      ReadingPerspective.genkoManuscript => SealCarvingStyle.zhuwen,
      ReadingPerspective.obsidianNight => SealCarvingStyle.baiwen,
      ReadingPerspective.faithfulOriginal =>
        templateStyle?.tokens.sealStyle ?? SealCarvingStyle.zhuwen,
    };
  }
}

/// Ruling layout geometry supported within the Thread-Bound Folio content leaves.
enum FolioRulingLayout {
  /// Horizontal ruled lines (14 integer-snapped rows).
  faithfulHorizontal,

  /// Classical 10 vertical columns from right to left.
  vermilionVertical,

  /// Genkō 10 columns x 16 rows (160 cells) right to left.
  genkoVertical;

  /// Whether this layout reads vertically right-to-left.
  bool get isVertical =>
      this == FolioRulingLayout.vermilionVertical || this == FolioRulingLayout.genkoVertical;
}

/// Visual color and texture theme for a physical folio substrate leaf.
class FolioSubstrateTheme {
  final String label;
  final Color pageBg;
  final Color pageBackBg;
  final Color inkPrimary;
  final Color inkSecondary;
  final Color ruleColor;
  final Color frameColor;
  final bool showGoldFlecks;
  final bool isDark;
  final String? fontFamily;

  const FolioSubstrateTheme({
    required this.label,
    required this.pageBg,
    required this.pageBackBg,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.ruleColor,
    required this.frameColor,
    required this.showGoldFlecks,
    required this.isDark,
    this.fontFamily,
  });

  /// Classical Raw Xuan paper substrate (`生宣纸`).
  static const FolioSubstrateTheme xuan = FolioSubstrateTheme(
    label: '生宣纸',
    pageBg: Color(0xFFFAF7F0),
    pageBackBg: Color(0xFFF3EFE4),
    inkPrimary: Color(0xFF231F1C),
    inkSecondary: Color(0xFF70675E),
    ruleColor: Color(0x6BB83B2E),
    frameColor: Color(0xC7B83B2E),
    showGoldFlecks: false,
    isDark: false,
  );

  /// Cold Gold speckled paper substrate (`冷金笺`).
  static const FolioSubstrateTheme coldGold = FolioSubstrateTheme(
    label: '冷金笺',
    pageBg: Color(0xFFF5EFE0),
    pageBackBg: Color(0xFFEDE4CE),
    inkPrimary: Color(0xFF241D16),
    inkSecondary: Color(0xFF73624C),
    ruleColor: Color(0x70B83B2E),
    frameColor: Color(0xCCB83B2E),
    showGoldFlecks: true,
    isDark: false,
  );

  /// Obsidian dark gold night paper substrate (`松烟夜墨`).
  static const FolioSubstrateTheme obsidian = FolioSubstrateTheme(
    label: '松烟夜墨',
    pageBg: Color(0xFF1B1D20),
    pageBackBg: Color(0xFF15171A),
    inkPrimary: Color(0xFFE6E1D8),
    inkSecondary: Color(0xFF9CA3AF),
    ruleColor: Color(0x4DD4AF37),
    frameColor: Color(0x99D4AF37),
    showGoldFlecks: true,
    isDark: true,
  );

  FolioSubstrateTheme copyWith({
    String? label,
    Color? pageBg,
    Color? pageBackBg,
    Color? inkPrimary,
    Color? inkSecondary,
    Color? ruleColor,
    Color? frameColor,
    bool? showGoldFlecks,
    bool? isDark,
    String? fontFamily,
  }) {
    return FolioSubstrateTheme(
      label: label ?? this.label,
      pageBg: pageBg ?? this.pageBg,
      pageBackBg: pageBackBg ?? this.pageBackBg,
      inkPrimary: inkPrimary ?? this.inkPrimary,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      ruleColor: ruleColor ?? this.ruleColor,
      frameColor: frameColor ?? this.frameColor,
      showGoldFlecks: showGoldFlecks ?? this.showGoldFlecks,
      isDark: isDark ?? this.isDark,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}

