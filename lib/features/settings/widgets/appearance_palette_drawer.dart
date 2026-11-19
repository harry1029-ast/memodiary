import 'package:flutter/material.dart';
import '../../../core/theme/atmosphere_palette.dart';
import '../../../core/theme/atmosphere_palettes.dart';
import '../../../core/theme/atmosphere_theme_models.dart';
import '../../../core/theme/ink_diary_theme.dart';

/// Shared accessible selectable tile used across appearance mode, preset,
/// and custom palette controls.
class SelectableThemeTile extends StatelessWidget {
  final Key optionKey;
  final String semanticLabel;
  final bool isSelected;
  final InkDiaryTokens tokens;
  final Color unselectedColor;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback onTap;
  final Widget child;

  const SelectableThemeTile({
    super.key,
    required this.optionKey,
    required this.semanticLabel,
    required this.isSelected,
    required this.tokens,
    required this.unselectedColor,
    required this.minHeight,
    required this.padding,
    this.borderRadius = 10,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: optionKey,
      button: true,
      selected: isSelected,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: () {
            if (!isSelected) onTap();
          },
          child: ExcludeSemantics(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: BoxConstraints(minHeight: minHeight),
              padding: padding,
              decoration: BoxDecoration(
                color: isSelected ? tokens.cinnabarWash : unselectedColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: isSelected ? tokens.cinnabar : tokens.deckleBorder,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Conditional custom Light/Dark palette drawer shown when `主题风格 == 自定义`.
class AppearanceCustomPaletteDrawer extends StatelessWidget {
  final AtmosphereThemeConfig config;
  final InkDiaryTokens tokens;
  final Color selectedTextColor;
  final ValueChanged<LightAtmospherePaletteId> onSelectLight;
  final ValueChanged<DarkAtmospherePaletteId> onSelectDark;

  const AppearanceCustomPaletteDrawer({
    super.key,
    required this.config,
    required this.tokens,
    required this.selectedTextColor,
    required this.onSelectLight,
    required this.onSelectDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('settings_custom_palette_drawer'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.xuanGround.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.deckleBorder, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 8) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _groupTitle('浅色色板'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final lightId in LightAtmospherePaletteId.values)
                    _buildPaletteOption(
                      width: itemWidth,
                      optionKey: Key('settings_light_palette_${lightId.widgetKeySuffix}'),
                      palette: AtmospherePalettes.forLight(lightId),
                      isSelected: config.customLightPalette == lightId,
                      onTap: () => onSelectLight(lightId),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _groupTitle('深色色板'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final darkId in DarkAtmospherePaletteId.values)
                    _buildPaletteOption(
                      width: itemWidth,
                      optionKey: Key('settings_dark_palette_${darkId.widgetKeySuffix}'),
                      palette: AtmospherePalettes.forDark(darkId),
                      isSelected: config.customDarkPalette == darkId,
                      onTap: () => onSelectDark(darkId),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _groupTitle(String label) => Text(
        label,
        style: TextStyle(
          fontFamily: InkDiaryTheme.fontNotoSerif,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tokens.nongmo,
        ),
      );

  Widget _buildPaletteOption({
    required double width,
    required Key optionKey,
    required AtmospherePalette palette,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: SelectableThemeTile(
        optionKey: optionKey,
        semanticLabel: palette.nameZh,
        isSelected: isSelected,
        tokens: tokens,
        unselectedColor: tokens.xuanPureLeaf,
        minHeight: 44,
        borderRadius: 8,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        onTap: onTap,
        child: Row(
          children: [
            AtmosphereSwatchDot(
              fill: palette.ground,
              ring: palette.woodFrameDark,
              accent: palette.accentPrimary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                palette.nameZh,
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
          ],
        ),
      ),
    );
  }
}

/// Overlapping Light/Dark dual swatch preview for preset theme cards.
class AtmosphereDualSwatchDots extends StatelessWidget {
  final AtmospherePalette lightPalette;
  final AtmospherePalette darkPalette;
  final Color borderColor;

  const AtmosphereDualSwatchDots({
    super.key,
    required this.lightPalette,
    required this.darkPalette,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 15,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          AtmosphereSwatchDot(
            fill: lightPalette.ground,
            ring: borderColor,
            accent: lightPalette.accentPrimary,
          ),
          Positioned(
            left: 11,
            child: AtmosphereSwatchDot(
              fill: darkPalette.ground,
              ring: borderColor,
              accent: darkPalette.accentPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular palette swatch dot displaying background fill, frame ring, and primary accent core.
class AtmosphereSwatchDot extends StatelessWidget {
  final Color fill;
  final Color ring;
  final Color accent;

  const AtmosphereSwatchDot({
    super.key,
    required this.fill,
    required this.ring,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: ring, width: 1.0),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
      ),
    );
  }
}
