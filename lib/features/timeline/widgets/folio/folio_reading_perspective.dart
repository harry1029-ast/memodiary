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
        final backgroundType = templateStyle.type;
        final showLeftMarginRule = backgroundType == TemplateBackgroundType.lined;
        final showKraftTexture =
            backgroundType == TemplateBackgroundType.paperTexture ||
                substrate == PaperSubstrate.kraft;
        final isDark = substrate.brightness == Brightness.dark;
        final kraftRuleColor =
            (!isDark && backgroundType == TemplateBackgroundType.paperTexture)
                ? const Color(0x148D6E63)
                : null;

        final baseTheme = switch (substrate) {
          PaperSubstrate.obsidian => FolioSubstrateTheme.obsidian,
          PaperSubstrate.coldGold => FolioSubstrateTheme.coldGold,
          _ => FolioSubstrateTheme(
              label: substrate.label,
              pageBg: templateStyle.backgroundColor,
              pageBackBg: Color.lerp(
                    templateStyle.backgroundColor,
                    isDark ? Colors.white : Colors.black,
                    0.04,
                  ) ??
                  templateStyle.backgroundColor,
              inkPrimary: isDark ? const Color(0xFFE6E1D8) : const Color(0xFF231F1C),
              inkSecondary: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF70675E),
              ruleColor: templateStyle.tokens.ruleTint.color,
              frameColor: templateStyle.tokens.ruleTint.color.withValues(alpha: 0.85),
              showGoldFlecks: false,
              isDark: isDark,
            ),
        };

        return baseTheme.copyWith(
          fontFamily: templateStyle.fontFamily,
          backgroundType: backgroundType,
          showLeftMarginRule: showLeftMarginRule,
          showKraftTexture: showKraftTexture,
          ruleColor: kraftRuleColor,
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
  static const double paperHeartWidth = 320.0;
  static const double jiazhuNoteHorizontalMargin = 2.0;
  static const double jiazhuNoteHorizontalPadding = 3.0;
  static const double jiazhuNoteBorderWidth = 0.7;
  static const double jiazhuNoteChromeWidth =
      2 * (jiazhuNoteHorizontalMargin + jiazhuNoteHorizontalPadding + jiazhuNoteBorderWidth) + 0.6;

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
  final TemplateBackgroundType backgroundType;
  final bool showLeftMarginRule;
  final bool showKraftTexture;

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
    this.backgroundType = TemplateBackgroundType.lined,
    this.showLeftMarginRule = true,
    this.showKraftTexture = false,
  });

  /// Horizontal text padding inside the 320px Paper Heart for horizontal layouts.
  EdgeInsets get horizontalBodyPadding => showLeftMarginRule
      ? const EdgeInsets.fromLTRB(32.0, 0, 20.0, 0)
      : const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0);

  /// Usable text width inside the 320px Paper Heart after horizontal insets.
  double get horizontalUsableWidth =>
      paperHeartWidth - horizontalBodyPadding.left - horizontalBodyPadding.right;

  /// Canonical horizontal body [TextStyle] shared by pagination measurement and rendering.
  TextStyle horizontalTextStyle({
    bool isBold = false,
    bool isItalic = false,
    TextDecoration? decoration,
    Color? color,
  }) {
    return TextStyle(
      fontSize: 15.0,
      height: 1.2,
      letterSpacing: 1.1,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: decoration,
      color: color ?? inkPrimary,
      fontFamily: fontFamily,
    );
  }

  /// Canonical horizontal inline interlinear sub-note (`双行夹注`) [TextStyle].
  TextStyle horizontalJiazhuTextStyle({Color? color}) {
    return TextStyle(
      fontSize: 10.5,
      height: 1.1,
      fontFamily: fontFamily,
      color: color ?? inkPrimary,
    );
  }

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
    TemplateBackgroundType? backgroundType,
    bool? showLeftMarginRule,
    bool? showKraftTexture,
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
      backgroundType: backgroundType ?? this.backgroundType,
      showLeftMarginRule: showLeftMarginRule ?? this.showLeftMarginRule,
      showKraftTexture: showKraftTexture ?? this.showKraftTexture,
    );
  }
}

