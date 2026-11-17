import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../../editor/models/typography_settings.dart';

/// Preset diary background color swatch with plain Chinese naming.
class ColorSwatchOption {
  final String name;
  final String hex;
  final Color color;

  const ColorSwatchOption({
    required this.name,
    required this.hex,
    required this.color,
  });
}

String _displayFontOptionLabel(FontOption option) {
  switch (option.id) {
    case 'system':
      return '系统默认（原生）';
    case 'serif':
      return '系统衬线';
    case 'sans-serif':
      return '系统无衬线';
    case 'monospace':
      return '等宽字体';
    case 'noto_serif':
      return 'Noto Serif（衬线）';
    case 'inter':
      return 'Inter（无衬线）';
    case 'lora':
      return 'Lora（衬线）';
    case 'merriweather':
      return 'Merriweather（衬线）';
    case 'playfair':
      return 'Playfair Display（标题）';
    case 'source_code':
      return 'Source Code Pro（等宽）';
    case 'caveat':
      return 'Caveat（手写体）';
    case 'ma_shan_zheng':
      return '马善政毛笔楷书';
    default:
      return option.name;
  }
}

/// Paper color swatches, hex input, spacing/margin sliders, and font selector.
class CustomTemplateColorTypographySection extends StatelessWidget {
  final List<ColorSwatchOption> presetSwatches;
  final String backgroundHex;
  final TextEditingController hexController;
  final double lineSpacing;
  final double marginHorizontal;
  final String selectedFontFamily;
  final ValueChanged<String> onSelectSwatchHex;
  final ValueChanged<String> onHexChanged;
  final ValueChanged<double> onLineSpacingChanged;
  final ValueChanged<double> onMarginHorizontalChanged;
  final ValueChanged<String?> onFontFamilyChanged;

  const CustomTemplateColorTypographySection({
    super.key,
    required this.presetSwatches,
    required this.backgroundHex,
    required this.hexController,
    required this.lineSpacing,
    required this.marginHorizontal,
    required this.selectedFontFamily,
    required this.onSelectSwatchHex,
    required this.onHexChanged,
    required this.onLineSpacingChanged,
    required this.onMarginHorizontalChanged,
    required this.onFontFamilyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '纸张颜色',
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontNotoSerif,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: tokens.jiaomo,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: presetSwatches.map((swatch) {
            final isSelected =
                backgroundHex.toUpperCase() == swatch.hex.toUpperCase();
            return Semantics(
              button: true,
              selected: isSelected,
              label: '纸张颜色：${swatch.name}',
              child: GestureDetector(
                key: Key('color_swatch_${swatch.hex}'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelectSwatchHex(swatch.hex);
                },
                child: Tooltip(
                  message: swatch.name,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: swatch.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? tokens.cinnabar : tokens.agedFiber,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: tokens.cinnabar.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: tokens.cinnabar,
                          )
                        : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('template_hex_input'),
          controller: hexController,
          decoration: InputDecoration(
            labelText: '自定义颜色 (#RRGGBB)',
            filled: true,
            fillColor: tokens.ricePaper,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tokens.agedFiber),
            ),
            prefixIcon: Icon(Icons.palette_outlined, color: tokens.danmo),
            isDense: true,
          ),
          onChanged: onHexChanged,
          validator: (val) {
            final regex = RegExp(r'^#?[0-9A-Fa-f]{6}$');
            if (val == null || !regex.hasMatch(val.trim())) {
              return '请输入有效 6 位十六进制色值 (例如 #FDFBF7)';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '行距',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
              ),
            ),
            Text(
              '${lineSpacing.toStringAsFixed(1)}x',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: tokens.cinnabar,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: tokens.cinnabar,
            inactiveTrackColor: tokens.agedFiber,
            thumbColor: tokens.cinnabar,
            trackHeight: 3.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            key: const Key('line_spacing_slider'),
            value: lineSpacing,
            min: 1.0,
            max: 2.5,
            divisions: 15,
            label: '${lineSpacing.toStringAsFixed(1)}x',
            onChanged: onLineSpacingChanged,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '左右边距',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
              ),
            ),
            Text(
              '${marginHorizontal.round()} px',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: tokens.cinnabar,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: tokens.cinnabar,
            inactiveTrackColor: tokens.agedFiber,
            thumbColor: tokens.cinnabar,
            trackHeight: 3.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            key: const Key('margin_horizontal_slider'),
            value: marginHorizontal,
            min: 12.0,
            max: 48.0,
            divisions: 18,
            label: '${marginHorizontal.round()} px',
            onChanged: onMarginHorizontalChanged,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '默认字体',
          style: TextStyle(
            fontFamily: InkDiaryTheme.fontNotoSerif,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: tokens.jiaomo,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: const Key('font_family_dropdown'),
          isExpanded: true,
          initialValue: selectedFontFamily,
          decoration: InputDecoration(
            filled: true,
            fillColor: tokens.ricePaper,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tokens.agedFiber),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          items: [
            const DropdownMenuItem(
              value: 'System',
              child: Text('系统默认'),
            ),
            ...TypographyCatalog.options
                .where((opt) =>
                    opt.id != 'system' || selectedFontFamily == 'system')
                .map((opt) {
              return DropdownMenuItem(
                value: opt.fontFamily ?? opt.id,
                child: Text(
                  _displayFontOptionLabel(opt),
                  style: TextStyle(fontFamily: opt.fontFamily),
                ),
              );
            }),
          ],
          onChanged: onFontFamilyChanged,
        ),
      ],
    );
  }
}
