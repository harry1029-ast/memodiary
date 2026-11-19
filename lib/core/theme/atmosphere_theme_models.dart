import 'package:flutter/material.dart';

/// Top-level paired Light/Dark atmosphere preset (`主题风格`),
/// orthogonal to OS/user [ThemeMode] (`外观模式`).
enum AtmosphereThemePreset {
  yunhao('yunhao', '云皓', '云岚昼 · 皓月夜（默认）'),
  classic('classic', '经典', '宣纸胡桃 · 碑拓乌木'),
  custom('custom', '自定义', '自由搭配浅色与深色色板');

  final String storageKey;
  final String label;
  final String description;

  const AtmosphereThemePreset(this.storageKey, this.label, this.description);

  /// Parses a persisted storage key safely, defaulting to [yunhao].
  static AtmosphereThemePreset parse(String? value) {
    for (final preset in values) {
      if (preset.storageKey == value) return preset;
    }
    return yunhao;
  }
}

/// Light-mode palette choices for the two-axis Atmosphere Theme system.
enum LightAtmospherePaletteId {
  yunhaoDay('yunhaoDay', 'yunhao_day', '云岚昼'),
  classicWalnut('classicWalnut', 'classic_walnut', '宣纸胡桃'),
  mistyTwilight('mistyTwilight', 'misty_twilight', '淡墨暮岚');

  final String storageKey;
  final String widgetKeySuffix;
  final String nameZh;

  const LightAtmospherePaletteId(
    this.storageKey,
    this.widgetKeySuffix,
    this.nameZh,
  );

  /// Parses a persisted storage key safely, defaulting to [yunhaoDay].
  static LightAtmospherePaletteId parse(String? value) {
    for (final paletteId in values) {
      if (paletteId.storageKey == value) return paletteId;
    }
    return yunhaoDay;
  }
}

/// Dark-mode palette choices for the two-axis Atmosphere Theme system.
enum DarkAtmospherePaletteId {
  yunhaoNight('yunhaoNight', 'yunhao_night', '皓月夜'),
  classicEbony('classicEbony', 'classic_ebony', '碑拓乌木'),
  silveryRain('silveryRain', 'silvery_rain', '清辉烟雨'),
  blossomLantern('blossomLantern', 'blossom_lantern', '花影灯火');

  final String storageKey;
  final String widgetKeySuffix;
  final String nameZh;

  const DarkAtmospherePaletteId(
    this.storageKey,
    this.widgetKeySuffix,
    this.nameZh,
  );

  /// Parses a persisted storage key safely, defaulting to [yunhaoNight].
  static DarkAtmospherePaletteId parse(String? value) {
    for (final paletteId in values) {
      if (paletteId.storageKey == value) return paletteId;
    }
    return yunhaoNight;
  }
}

/// Immutable two-axis atmosphere theme state combining [themeMode],
/// [preset], and independently persisted custom Light/Dark palette pairings.
@immutable
class AtmosphereThemeConfig {
  final ThemeMode themeMode;
  final AtmosphereThemePreset preset;
  final LightAtmospherePaletteId customLightPalette;
  final DarkAtmospherePaletteId customDarkPalette;

  const AtmosphereThemeConfig({
    this.themeMode = ThemeMode.system,
    this.preset = AtmosphereThemePreset.yunhao,
    this.customLightPalette = LightAtmospherePaletteId.yunhaoDay,
    this.customDarkPalette = DarkAtmospherePaletteId.yunhaoNight,
  });

  /// Effective light palette resolved from [preset] and [customLightPalette].
  LightAtmospherePaletteId get activeLightPalette {
    switch (preset) {
      case AtmosphereThemePreset.yunhao:
        return LightAtmospherePaletteId.yunhaoDay;
      case AtmosphereThemePreset.classic:
        return LightAtmospherePaletteId.classicWalnut;
      case AtmosphereThemePreset.custom:
        return customLightPalette;
    }
  }

  /// Effective dark palette resolved from [preset] and [customDarkPalette].
  DarkAtmospherePaletteId get activeDarkPalette {
    switch (preset) {
      case AtmosphereThemePreset.yunhao:
        return DarkAtmospherePaletteId.yunhaoNight;
      case AtmosphereThemePreset.classic:
        return DarkAtmospherePaletteId.classicEbony;
      case AtmosphereThemePreset.custom:
        return customDarkPalette;
    }
  }

  AtmosphereThemeConfig copyWith({
    ThemeMode? themeMode,
    AtmosphereThemePreset? preset,
    LightAtmospherePaletteId? customLightPalette,
    DarkAtmospherePaletteId? customDarkPalette,
  }) {
    return AtmosphereThemeConfig(
      themeMode: themeMode ?? this.themeMode,
      preset: preset ?? this.preset,
      customLightPalette: customLightPalette ?? this.customLightPalette,
      customDarkPalette: customDarkPalette ?? this.customDarkPalette,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AtmosphereThemeConfig &&
            runtimeType == other.runtimeType &&
            themeMode == other.themeMode &&
            preset == other.preset &&
            customLightPalette == other.customLightPalette &&
            customDarkPalette == other.customDarkPalette;
  }

  @override
  int get hashCode => Object.hash(
        themeMode,
        preset,
        customLightPalette,
        customDarkPalette,
      );
}
