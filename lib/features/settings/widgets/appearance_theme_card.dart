import 'package:flutter/material.dart';
import '../../../core/theme/atmosphere_palette.dart';
import '../../../core/theme/atmosphere_palettes.dart';
import '../../../core/theme/atmosphere_theme_models.dart';
import '../../../core/theme/ink_diary_theme.dart';
import '../../../core/theme/theme_settings_service.dart';
import '../../../core/theme/widgets/xuan_paper_card.dart';
import 'appearance_palette_drawer.dart';

/// Two-axis Appearance & Atmosphere Theme settings card (`外观模式` × `主题风格`).
class AppearanceThemeCard extends StatelessWidget {
  final ThemeSettingsService themeSettings;

  const AppearanceThemeCard({
    super.key,
    required this.themeSettings,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedTextColor = isDark ? tokens.cinnabar : tokens.cinnabarDark;

    return ValueListenableBuilder<AtmosphereThemeConfig>(
      valueListenable: themeSettings.configNotifier,
      builder: (context, config, _) {
        return XuanPaperCard(
          key: const Key('settings_appearance_card'),
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(16),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeaderRow(
                  icon: config.themeMode.filledIcon,
                  title: '外观模式',
                  subtitle: config.themeMode.description,
                  tokens: tokens,
                ),
                const SizedBox(height: 12),
                _buildThemeModeRow(config, tokens, selectedTextColor),
                Divider(height: 24, color: tokens.agedFiber),
                _SectionHeaderRow(
                  icon: Icons.palette_outlined,
                  title: '主题风格',
                  subtitle: config.preset.description,
                  tokens: tokens,
                ),
                const SizedBox(height: 12),
                _buildPresetRow(config, tokens, selectedTextColor),
                if (config.preset == AtmosphereThemePreset.custom) ...[
                  const SizedBox(height: 12),
                  AppearanceCustomPaletteDrawer(
                    config: config,
                    tokens: tokens,
                    selectedTextColor: selectedTextColor,
                    onSelectLight: themeSettings.setCustomLightPalette,
                    onSelectDark: themeSettings.setCustomDarkPalette,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeModeRow(
    AtmosphereThemeConfig config,
    InkDiaryTokens tokens,
    Color selectedTextColor,
  ) {
    return Row(
      children: [
        for (var index = 0; index < ThemeMode.values.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: _buildModeTile(
              mode: ThemeMode.values[index],
              isSelected: config.themeMode == ThemeMode.values[index],
              tokens: tokens,
              selectedTextColor: selectedTextColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModeTile({
    required ThemeMode mode,
    required bool isSelected,
    required InkDiaryTokens tokens,
    required Color selectedTextColor,
  }) {
    return SelectableThemeTile(
      optionKey: Key('settings_theme_mode_${mode.name}'),
      semanticLabel: mode.label,
      isSelected: isSelected,
      tokens: tokens,
      unselectedColor: tokens.agedFiber.withValues(alpha: 0.5),
      minHeight: 44,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      onTap: () => themeSettings.setThemeMode(mode),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(mode.icon, size: 20, color: isSelected ? tokens.cinnabar : tokens.danmo),
          const SizedBox(height: 5),
          Text(
            mode.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? selectedTextColor : tokens.jiaomo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetRow(
    AtmosphereThemeConfig config,
    InkDiaryTokens tokens,
    Color selectedTextColor,
  ) {
    return Row(
      children: [
        for (var index = 0; index < AtmosphereThemePreset.values.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: _PresetOptionTile(
              preset: AtmosphereThemePreset.values[index],
              config: config,
              isSelected: config.preset == AtmosphereThemePreset.values[index],
              tokens: tokens,
              selectedTextColor: selectedTextColor,
              onTap: () => themeSettings.setPreset(AtmosphereThemePreset.values[index]),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final InkDiaryTokens tokens;

  const _SectionHeaderRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tokens.agedFiber,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: tokens.cinnabar, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tokens.jiaomo,
                  fontFamily: InkDiaryTheme.fontNotoSerif,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 11, color: tokens.danmo)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PresetOptionTile extends StatelessWidget {
  final AtmosphereThemePreset preset;
  final AtmosphereThemeConfig config;
  final bool isSelected;
  final InkDiaryTokens tokens;
  final Color selectedTextColor;
  final VoidCallback onTap;

  const _PresetOptionTile({
    required this.preset,
    required this.config,
    required this.isSelected,
    required this.tokens,
    required this.selectedTextColor,
    required this.onTap,
  });

  ({AtmospherePalette light, AtmospherePalette dark}) _previewPair() {
    switch (preset) {
      case AtmosphereThemePreset.yunhao:
        return (light: AtmospherePalettes.yunhaoDay, dark: AtmospherePalettes.yunhaoNight);
      case AtmosphereThemePreset.classic:
        return (light: AtmospherePalettes.classicWalnut, dark: AtmospherePalettes.classicEbony);
      case AtmosphereThemePreset.custom:
        return (
          light: AtmospherePalettes.forLight(config.customLightPalette),
          dark: AtmospherePalettes.forDark(config.customDarkPalette),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pair = _previewPair();
    return SelectableThemeTile(
      optionKey: Key('settings_theme_preset_${preset.storageKey}'),
      semanticLabel: preset == AtmosphereThemePreset.yunhao ? '云皓 默认' : preset.label,
      isSelected: isSelected,
      tokens: tokens,
      unselectedColor: tokens.agedFiber.withValues(alpha: 0.5),
      minHeight: 56,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AtmosphereDualSwatchDots(
            lightPalette: pair.light,
            darkPalette: pair.dark,
            borderColor: tokens.deckleBorder,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  preset.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? selectedTextColor : tokens.jiaomo,
                  ),
                ),
              ),
              if (preset == AtmosphereThemePreset.yunhao) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tokens.cinnabar.withValues(alpha: 0.16)
                        : tokens.deckleBorder.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '默认',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? selectedTextColor : tokens.danmo,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
