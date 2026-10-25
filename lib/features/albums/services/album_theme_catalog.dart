import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/album_studio_models.dart';

/// Curated background color swatch paired with an automatically contrasting
/// text color (`Aa` preview indicator).
@immutable
class ColorSwatchOption {
  final int backgroundColorArgb;
  final int textColorArgb;
  final String label;

  const ColorSwatchOption({
    required this.backgroundColorArgb,
    required this.textColorArgb,
    required this.label,
  });

  /// Computes a high-contrast text color (`0xFF1E1E1E` dark ink or `0xFFFCF9F2` ivory)
  /// for any arbitrary ARGB background color using relative luminance.
  static int contrastingTextColorFor(int backgroundArgb) {
    final r = ((backgroundArgb >> 16) & 0xFF) / 255.0;
    final g = ((backgroundArgb >> 8) & 0xFF) / 255.0;
    final b = (backgroundArgb & 0xFF) / 255.0;

    double linearize(double channel) {
      return channel <= 0.03928
          ? channel / 12.92
          : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }

    final luminance = 0.2126 * linearize(r) +
        0.7152 * linearize(g) +
        0.0722 * linearize(b);
    return luminance > 0.42 ? 0xFF1E1E1E : 0xFFFCF9F2;
  }
}

/// Procedural vector background graphic pattern preset.
@immutable
class GraphicPatternPreset {
  final String id;
  final String name;
  final String themeId;

  const GraphicPatternPreset({
    required this.id,
    required this.name,
    required this.themeId,
  });
}

/// Complete visual book theme defining suggested color swatches and graphic motifs.
@immutable
class AlbumThemePreset {
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final List<ColorSwatchOption> suggestedSwatches;
  final List<String> graphicPatternIds;
  final PageBackgroundConfig defaultBackgroundConfig;

  AlbumThemePreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required List<ColorSwatchOption> suggestedSwatches,
    required List<String> graphicPatternIds,
    required this.defaultBackgroundConfig,
  })  : suggestedSwatches =
            List<ColorSwatchOption>.unmodifiable(suggestedSwatches),
        graphicPatternIds = List<String>.unmodifiable(graphicPatternIds);

  /// Computes a [PageBackgroundConfig] for [pageIndex] by cycling through the
  /// theme's curated color swatches and procedural graphic patterns.
  PageBackgroundConfig backgroundConfigForIndex(int pageIndex) {
    final swatch = suggestedSwatches.isNotEmpty
        ? suggestedSwatches[pageIndex % suggestedSwatches.length]
        : null;
    final patternId = graphicPatternIds.isNotEmpty
        ? graphicPatternIds[pageIndex % graphicPatternIds.length]
        : defaultBackgroundConfig.graphicPatternId;

    return PageBackgroundConfig(
      backgroundColorArgb: swatch?.backgroundColorArgb ??
          defaultBackgroundConfig.backgroundColorArgb,
      textColorArgb: swatch?.textColorArgb ??
          defaultBackgroundConfig.textColorArgb,
      graphicPatternId: patternId,
    );
  }
}

/// Categories of vector stickers and ephemera in [StickerCatalog].
enum StickerCategory {
  travel,
  flora,
  weather,
  washi,
  stamp,
  datePill;

  String get displayLabel {
    switch (this) {
      case StickerCategory.travel:
        return '行旅足迹';
      case StickerCategory.flora:
        return '草木繁花';
      case StickerCategory.weather:
        return '晴雨风物';
      case StickerCategory.washi:
        return '和纸胶带';
      case StickerCategory.stamp:
        return '朱印邮戳';
      case StickerCategory.datePill:
        return '日期胶囊';
    }
  }
}

/// Built-in vector sticker definition.
@immutable
class StickerPreset {
  final String id;
  final String name;
  final StickerCategory category;
  final int defaultColorArgb;

  const StickerPreset({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultColorArgb,
  });
}

/// Catalog of 5 book themes, 9 procedural vector background graphic patterns,
/// and 12 suggested color swatches.
class AlbumThemeCatalog {
  const AlbumThemeCatalog._();

  static const String defaultThemeId = 'shanshui_ink';

  /// Universal suggested palette swatches (matching Journi Image 6).
  static const List<ColorSwatchOption> universalSwatches = [
    ColorSwatchOption(
      backgroundColorArgb: 0xFFFFFFFF,
      textColorArgb: 0xFF1E1E1E,
      label: '素白纯笺',
    ),
    ColorSwatchOption(
      backgroundColorArgb: 0xFFFCF9F2,
      textColorArgb: 0xFF1E1E1E,
      label: '宣纸米白',
    ),
    ColorSwatchOption(
      backgroundColorArgb: 0xFFEAF6F6,
      textColorArgb: 0xFF2B6777,
      label: '天青冰瓷',
    ),
    ColorSwatchOption(
      backgroundColorArgb: 0xFFEDF2F7,
      textColorArgb: 0xFF3B5978,
      label: '云水淡蓝',
    ),
    ColorSwatchOption(
      backgroundColorArgb: 0xFFF2ECF9,
      textColorArgb: 0xFF5A4B81,
      label: '暮山烟紫',
    ),
    ColorSwatchOption(
      backgroundColorArgb: 0xFFF9ECEC,
      textColorArgb: 0xFF8C4A4A,
      label: '桃花浅粉',
    ),
    ColorSwatchOption(
      backgroundColorArgb: 0xFFE9F7F2,
      textColorArgb: 0xFF2D6A4F,
      label: '竹露微翠',
    ),
    ColorSwatchOption(
      backgroundColorArgb: 0xFF63C5DA,
      textColorArgb: 0xFFFFFFFF,
      label: '晴海碧蓝',
    ),
    ColorSwatchOption(
      backgroundColorArgb: 0xFF7B9EB2,
      textColorArgb: 0xFFFFFFFF,
      label: '松烟青灰',
    ),
    ColorSwatchOption(
      backgroundColorArgb: 0xFF7D74A8,
      textColorArgb: 0xFFFFFFFF,
      label: '藤萝雅紫',
    ),
    ColorSwatchOption(
      backgroundColorArgb: 0xFFC89D9C,
      textColorArgb: 0xFFFFFFFF,
      label: '干枯玫瑰',
    ),
    ColorSwatchOption(
      backgroundColorArgb: 0xFF6CC4B8,
      textColorArgb: 0xFFFFFFFF,
      label: '翡翠青绿',
    ),
  ];

  /// All procedural vector graphic pattern presets.
  static const List<GraphicPatternPreset> allGraphicPatterns = [
    GraphicPatternPreset(
      id: 'none',
      name: '纯色留白',
      themeId: 'shanshui_ink',
    ),
    GraphicPatternPreset(
      id: 'ink_bamboo_mountains',
      name: '远山墨竹',
      themeId: 'shanshui_ink',
    ),
    GraphicPatternPreset(
      id: 'floral_allover',
      name: '满幅繁花缠枝',
      themeId: 'jardin',
    ),
    GraphicPatternPreset(
      id: 'corner_vines',
      name: '对角藤蔓花枝',
      themeId: 'jardin',
    ),
    GraphicPatternPreset(
      id: 'bottom_left_sprig',
      name: '左下折枝繁花',
      themeId: 'jardin',
    ),
    GraphicPatternPreset(
      id: 'bottom_right_bloom',
      name: '右下东方花卉',
      themeId: 'jardin',
    ),
    GraphicPatternPreset(
      id: 'abstract_fluid',
      name: '青白流体写意',
      themeId: 'abstract_blue',
    ),
    GraphicPatternPreset(
      id: 'beach_lemon_palm',
      name: '盛夏青柠棕榈',
      themeId: 'day_at_beach',
    ),
    GraphicPatternPreset(
      id: 'rainbow_paper_plane',
      name: '彩虹纸飞机',
      themeId: 'playful_rainbow',
    ),
  ];

  /// The 5 curated book themes (matching Journi Image 7 + Shanshui Ink).
  static final List<AlbumThemePreset> allThemes =
      List<AlbumThemePreset>.unmodifiable([
    AlbumThemePreset(
      id: 'shanshui_ink',
      name: 'Shanshui Ink · 水墨丹青',
      subtitle: '宣纸留白与远山墨竹',
      description: '温润宣纸底色配以远山黛影、墨竹斜枝与双线文人边框，尽显东方雅韵。',
      suggestedSwatches: const [
        ColorSwatchOption(
          backgroundColorArgb: 0xFFFCF9F2,
          textColorArgb: 0xFF1E1E1E,
          label: '宣纸原色',
        ),
        ColorSwatchOption(
          backgroundColorArgb: 0xFFF4EFE6,
          textColorArgb: 0xFF2C2623,
          label: '古卷素笺',
        ),
        ColorSwatchOption(
          backgroundColorArgb: 0xFFE9EFEA,
          textColorArgb: 0xFF2B3D34,
          label: '竹林听雨',
        ),
        ColorSwatchOption(
          backgroundColorArgb: 0xFFE8EEF2,
          textColorArgb: 0xFF253440,
          label: '烟雨江南',
        ),
      ],
      graphicPatternIds: const [
        'ink_bamboo_mountains',
        'corner_vines',
        'none',
      ],
      defaultBackgroundConfig: const PageBackgroundConfig(
        backgroundColorArgb: 0xFFFCF9F2,
        textColorArgb: 0xFF1E1E1E,
        graphicPatternId: 'ink_bamboo_mountains',
      ),
    ),
    AlbumThemePreset(
      id: 'jardin',
      name: 'Jardin · 东方花苑',
      subtitle: '温润草木与东方缠枝花卉',
      description:
          'An oriental touch that fits with every occasion, a warm floral theme ready to enhance your book.',
      suggestedSwatches: const [
        ColorSwatchOption(
          backgroundColorArgb: 0xFFF9F1E6,
          textColorArgb: 0xFF4A3B32,
          label: '暖杏花笺',
        ),
        ColorSwatchOption(
          backgroundColorArgb: 0xFFC89D9C,
          textColorArgb: 0xFFFFFFFF,
          label: '干枯玫瑰',
        ),
        ColorSwatchOption(
          backgroundColorArgb: 0xFFE4F0EE,
          textColorArgb: 0xFF2C4A47,
          label: '玉露浅青',
        ),
        ColorSwatchOption(
          backgroundColorArgb: 0xFFC7BDB8,
          textColorArgb: 0xFF2E2724,
          label: '亚麻暖灰',
        ),
      ],
      graphicPatternIds: const [
        'floral_allover',
        'corner_vines',
        'bottom_left_sprig',
        'bottom_right_bloom',
      ],
      defaultBackgroundConfig: const PageBackgroundConfig(
        backgroundColorArgb: 0xFFF9F1E6,
        textColorArgb: 0xFF4A3B32,
        graphicPatternId: 'corner_vines',
      ),
    ),
    AlbumThemePreset(
      id: 'abstract_blue',
      name: 'Abstract Blue · 留白青瓷',
      subtitle: '手绘流体线条与青花色阶',
      description:
          'Blues, whites and hand-drawn elements make this theme delicate and fluid.',
      suggestedSwatches: const [
        ColorSwatchOption(
          backgroundColorArgb: 0xFFF4F8FB,
          textColorArgb: 0xFF1F3A60,
          label: '冰瓷微白',
        ),
        ColorSwatchOption(
          backgroundColorArgb: 0xFFD9E6F2,
          textColorArgb: 0xFF1E3557,
          label: '晴空浅蓝',
        ),
        ColorSwatchOption(
          backgroundColorArgb: 0xFFA5BFE0,
          textColorArgb: 0xFF152642,
          label: '霁色天蓝',
        ),
        ColorSwatchOption(
          backgroundColorArgb: 0xFF42599A,
          textColorArgb: 0xFFFFFFFF,
          label: '青花钴蓝',
        ),
      ],
      graphicPatternIds: const [
        'abstract_fluid',
        'corner_vines',
        'none',
      ],
      defaultBackgroundConfig: const PageBackgroundConfig(
        backgroundColorArgb: 0xFFF4F8FB,
        textColorArgb: 0xFF1F3A60,
        graphicPatternId: 'abstract_fluid',
      ),
    ),
    AlbumThemePreset(
      id: 'day_at_beach',
      name: 'Day at the Beach · 盛夏海风',
      subtitle: '鲜亮青柠、棕榈与海岸活力',
      description:
          'The perfect style for summer. Add some zing with fresh fruit and playful colors.',
      suggestedSwatches: const [
        ColorSwatchOption(
          backgroundColorArgb: 0xFFFFFBF0,
          textColorArgb: 0xFF2D3A3A,
          label: '暖沙白',
        ),
        ColorSwatchOption(
          backgroundColorArgb: 0xFFFFE566,
          textColorArgb: 0xFF332900,
          label: '盛夏青柠',
        ),
        ColorSwatchOption(
          backgroundColorArgb: 0xFF52C4B0,
          textColorArgb: 0xFFFFFFFF,
          label: '碧海松石',
        ),
        ColorSwatchOption(
          backgroundColorArgb: 0xFFF06292,
          textColorArgb: 0xFFFFFFFF,
          label: '海岛珊瑚',
        ),
      ],
      graphicPatternIds: const [
        'beach_lemon_palm',
        'none',
      ],
      defaultBackgroundConfig: const PageBackgroundConfig(
        backgroundColorArgb: 0xFFFFFBF0,
        textColorArgb: 0xFF2D3A3A,
        graphicPatternId: 'beach_lemon_palm',
      ),
    ),
    AlbumThemePreset(
      id: 'playful_rainbow',
      name: 'Playful Rainbow · 拾光彩虹',
      subtitle: '柔和彩虹渐变与童趣手绘',
      description:
          'A playful and delicate theme. Let soft rainbow colors and graphics complement your pages.',
      suggestedSwatches: const [
        ColorSwatchOption(
          backgroundColorArgb: 0xFFFDF8FF,
          textColorArgb: 0xFF3E3554,
          label: '云朵微粉',
        ),
        ColorSwatchOption(
          backgroundColorArgb: 0xFFF9E5EC,
          textColorArgb: 0xFF593140,
          label: '朝霞柔粉',
        ),
        ColorSwatchOption(
          backgroundColorArgb: 0xFFE6F4FA,
          textColorArgb: 0xFF2C4D63,
          label: '晴虹浅蓝',
        ),
        ColorSwatchOption(
          backgroundColorArgb: 0xFFFEF3DC,
          textColorArgb: 0xFF5C471E,
          label: '暖阳杏黄',
        ),
      ],
      graphicPatternIds: const [
        'rainbow_paper_plane',
        'none',
      ],
      defaultBackgroundConfig: const PageBackgroundConfig(
        backgroundColorArgb: 0xFFFDF8FF,
        textColorArgb: 0xFF3E3554,
        graphicPatternId: 'rainbow_paper_plane',
      ),
    ),
  ]);

  /// Looks up a book theme by [themeId], defaulting to `'shanshui_ink'`.
  static AlbumThemePreset getThemeById(String? themeId) {
    for (final theme in allThemes) {
      if (theme.id == themeId) {
        return theme;
      }
    }
    return allThemes.first;
  }

  /// Looks up a graphic pattern by [patternId], defaulting to `'none'`.
  static GraphicPatternPreset getPatternById(String? patternId) {
    for (final pattern in allGraphicPatterns) {
      if (pattern.id == patternId) {
        return pattern;
      }
    }
    return allGraphicPatterns.first;
  }
}

/// Built-in vector sticker catalog for DIY scrapbook pages (matching Journi Image 9).
class StickerCatalog {
  const StickerCatalog._();

  static const List<StickerPreset> allStickers = [
    // Flora
    StickerPreset(
      id: 'sticker_flora_blossom',
      name: '八瓣繁花',
      category: StickerCategory.flora,
      defaultColorArgb: 0xFFB565A7,
    ),
    StickerPreset(
      id: 'sticker_flora_bamboo',
      name: '清风墨竹',
      category: StickerCategory.flora,
      defaultColorArgb: 0xFF3B6E5C,
    ),
    StickerPreset(
      id: 'sticker_flora_sprig',
      name: '春枝绿叶',
      category: StickerCategory.flora,
      defaultColorArgb: 0xFF6B8E67,
    ),

    // Travel
    StickerPreset(
      id: 'sticker_travel_map_pin',
      name: '地图坐标',
      category: StickerCategory.travel,
      defaultColorArgb: 0xFF8C64A6,
    ),
    StickerPreset(
      id: 'sticker_travel_compass',
      name: '远行罗盘',
      category: StickerCategory.travel,
      defaultColorArgb: 0xFF3E5F7A,
    ),
    StickerPreset(
      id: 'sticker_travel_plane',
      name: '纸飞机轨迹',
      category: StickerCategory.travel,
      defaultColorArgb: 0xFF4A7BB0,
    ),

    // Weather
    StickerPreset(
      id: 'sticker_weather_postcard',
      name: '晴云明信片',
      category: StickerCategory.weather,
      defaultColorArgb: 0xFF8A5EA1,
    ),
    StickerPreset(
      id: 'sticker_weather_sun',
      name: '暖阳晴空',
      category: StickerCategory.weather,
      defaultColorArgb: 0xFFE09F3E,
    ),

    // Washi Tape
    StickerPreset(
      id: 'sticker_washi_cinnabar',
      name: '丹砂和纸胶带',
      category: StickerCategory.washi,
      defaultColorArgb: 0xFFC85A53,
    ),
    StickerPreset(
      id: 'sticker_washi_grid',
      name: '格纹手账胶带',
      category: StickerCategory.washi,
      defaultColorArgb: 0xFF7B9EB2,
    ),

    // Stamps & Seals
    StickerPreset(
      id: 'sticker_stamp_shiguang',
      name: '拾光朱印',
      category: StickerCategory.stamp,
      defaultColorArgb: 0xFFB83B2A,
    ),
    StickerPreset(
      id: 'sticker_stamp_postmark',
      name: '纪行邮戳',
      category: StickerCategory.stamp,
      defaultColorArgb: 0xFF5C4B3B,
    ),

    // Date Pills
    StickerPreset(
      id: 'sticker_date_pill_ribbon',
      name: '丝带日期徽章',
      category: StickerCategory.datePill,
      defaultColorArgb: 0xFF5C4B3B,
    ),
    StickerPreset(
      id: 'sticker_date_pill_minimal',
      name: '极简素雅日期',
      category: StickerCategory.datePill,
      defaultColorArgb: 0xFF2C3E50,
    ),
  ];

  static StickerPreset getById(String id) {
    for (final sticker in allStickers) {
      if (sticker.id == id) {
        return sticker;
      }
    }
    return allStickers.first;
  }

  static List<StickerPreset> byCategory(StickerCategory category) {
    return allStickers
        .where((sticker) => sticker.category == category)
        .toList(growable: false);
  }
}

