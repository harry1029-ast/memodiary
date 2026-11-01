import 'package:flutter/material.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../models/typography_settings.dart';

/// Stationery artifact representing the porcelain brush rest (青花笔架).
/// Houses typography, ink tones, font size, line spacing, and poetic alignment controls.
class ArtifactBrushMountain extends StatelessWidget {
  final bool isSelected;
  final VoidCallback? onTap;

  const ArtifactBrushMountain({
    super.key,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '青花笔架: 调整字体、字号、行距与墨色',
      selected: isSelected,
      child: GestureDetector(
        key: const Key('chest_artifact_brush_mountain'),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6B1A1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF8B262A),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSelected ? 0.35 : 0.2),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Porcelain Mountain & Brush Graphic
              SizedBox(
                height: 42,
                width: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 3-peak cobalt rest
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildPeak(14, 18),
                          _buildPeak(18, 26, isCenter: true),
                          _buildPeak(14, 18),
                        ],
                      ),
                    ),
                    // Floating or resting brush
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 240),
                      top: isSelected ? 2 : 12,
                      child: Container(
                        width: 58,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8A5A2B),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Plaque
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1A17),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
                ),
                child: Text(
                  '青花笔架',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontKaiti,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE6C875),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeak(double width, double height, {bool isCenter = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(width / 2)),
        border: Border.all(color: const Color(0xFF1A4778), width: 1.2),
      ),
      child: Center(
        child: Container(
          width: 3,
          height: height * 0.45,
          color: const Color(0xFF1A4778),
        ),
      ),
    );
  }
}

/// In-chest sub-panel for the Porcelain Brush Mountain artifact
class BrushMountainSubPanel extends StatelessWidget {
  final TypographySettings typography;
  final ValueChanged<TypographySettings> onTypographyChanged;
  final bool isCenterAligned;
  final VoidCallback? onToggleAlignment;

  const BrushMountainSubPanel({
    super.key,
    required this.typography,
    required this.onTypographyChanged,
    this.isCenterAligned = false,
    this.onToggleAlignment,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '字法墨韵 · 笔意规制',
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontNotoSerif,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: tokens.jiaomo,
              ),
            ),
            // Poetry layout alignment toggle
            IconButton(
              key: const Key('chest_poetry_align_button'),
              icon: Icon(
                isCenterAligned ? Icons.format_align_center : Icons.format_align_left,
                size: 18,
                color: isCenterAligned ? tokens.cinnabar : tokens.danmo,
              ),
              tooltip: isCenterAligned ? '切换齐头排版' : '切换居中诗意排版',
              onPressed: onToggleAlignment,
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Font Family Selector
        DropdownButtonFormField<String>(
          key: const Key('chest_font_family_dropdown'),
          initialValue: typography.fontFamily ?? 'System',
          isDense: true,
          decoration: InputDecoration(
            labelText: '字体式样',
            filled: true,
            fillColor: tokens.ricePaper,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.agedFiber),
            ),
          ),
          items: [
            const DropdownMenuItem(value: 'System', child: Text('系统字体')),
            ...TypographyCatalog.options.map((opt) {
              return DropdownMenuItem(
                value: opt.fontFamily ?? opt.id,
                child: Text(opt.name, style: TextStyle(fontFamily: opt.fontFamily)),
              );
            }),
          ],
          onChanged: (val) {
            onTypographyChanged(
              typography.copyWith(fontFamily: val == 'System' ? null : val),
            );
          },
        ),
        const SizedBox(height: 10),

        // Font Size Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('字形大小 (${typography.fontSize.round()} pt)', style: const TextStyle(fontSize: 12)),
            Text('${typography.fontSize.round()} pt', style: TextStyle(color: tokens.cinnabar, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          key: const Key('chest_font_size_slider'),
          value: typography.fontSize.clamp(14.0, 24.0),
          min: 14.0,
          max: 24.0,
          divisions: 10,
          activeColor: tokens.cinnabar,
          onChanged: (val) {
            onTypographyChanged(typography.copyWith(fontSize: val.roundToDouble()));
          },
        ),

        // Line Spacing Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('行间高距 (${typography.lineSpacing.toStringAsFixed(1)}x)', style: const TextStyle(fontSize: 12)),
            Text('${typography.lineSpacing.toStringAsFixed(1)}x', style: TextStyle(color: tokens.cinnabar, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          key: const Key('chest_line_spacing_slider'),
          value: typography.lineSpacing.clamp(1.2, 2.2),
          min: 1.2,
          max: 2.2,
          divisions: 10,
          activeColor: tokens.cinnabar,
          onChanged: (val) {
            onTypographyChanged(typography.copyWith(lineSpacing: double.parse(val.toStringAsFixed(1))));
          },
        ),

        // Ink Tone Selection (#1F1D1A 焦墨, #B83B2E 朱砂, #2F5241 竹青)
        const SizedBox(height: 6),
        Text('墨色韵调', style: TextStyle(fontSize: 12, color: tokens.danmo)),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildInkToneChip(
              label: '焦墨',
              color: const Color(0xFF1F1D1A),
              keyName: 'chest_ink_tone_jiaomo',
              isSelected: typography.textColor == const Color(0xFF1F1D1A) || typography.textColor == null,
              onTap: () => onTypographyChanged(typography.copyWith(textColor: const Color(0xFF1F1D1A))),
            ),
            const SizedBox(width: 8),
            _buildInkToneChip(
              label: '朱砂',
              color: const Color(0xFFB83B2E),
              keyName: 'chest_ink_tone_cinnabar',
              isSelected: typography.textColor == const Color(0xFFB83B2E),
              onTap: () => onTypographyChanged(typography.copyWith(textColor: const Color(0xFFB83B2E))),
            ),
            const SizedBox(width: 8),
            _buildInkToneChip(
              label: '竹青',
              color: const Color(0xFF2F5241),
              keyName: 'chest_ink_tone_bamboo',
              isSelected: typography.textColor == const Color(0xFF2F5241),
              onTap: () => onTypographyChanged(typography.copyWith(textColor: const Color(0xFF2F5241))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInkToneChip({
    required String label,
    required Color color,
    required String keyName,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: Key(keyName),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isSelected ? 0.16 : 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
