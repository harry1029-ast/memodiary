import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../models/template_style.dart';

/// Chip selectors for stationery paper pattern, substrate, rule ink tint, and seal carving style.
class CustomTemplateStyleSelectors extends StatelessWidget {
  final TemplateBackgroundType backgroundType;
  final PaperSubstrate selectedSubstrate;
  final RuleInkTint selectedRuleTint;
  final SealCarvingStyle selectedSealStyle;
  final ValueChanged<TemplateBackgroundType> onBackgroundTypeChanged;
  final ValueChanged<PaperSubstrate> onSubstrateChanged;
  final ValueChanged<RuleInkTint> onRuleTintChanged;
  final ValueChanged<SealCarvingStyle> onSealStyleChanged;

  const CustomTemplateStyleSelectors({
    super.key,
    required this.backgroundType,
    required this.selectedSubstrate,
    required this.selectedRuleTint,
    required this.selectedSealStyle,
    required this.onBackgroundTypeChanged,
    required this.onSubstrateChanged,
    required this.onRuleTintChanged,
    required this.onSealStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(tokens, '界格规制 · Paper Pattern'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TemplateBackgroundType.values.map((type) {
            return _buildChip(
              tokens: tokens,
              chipKey: Key('bg_type_${type.toDbValue}'),
              label: type.label,
              isSelected: backgroundType == type,
              onSelect: () => onBackgroundTypeChanged(type),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle(tokens, '宣纸基底 · Paper Substrate'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PaperSubstrate.values.map((sub) {
            return _buildChip(
              tokens: tokens,
              chipKey: Key('substrate_${sub.name}'),
              label: sub.label,
              isSelected: selectedSubstrate == sub,
              onSelect: () => onSubstrateChanged(sub),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle(tokens, '界格印色 · Rule Ink Tint'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RuleInkTint.values.map((tint) {
            return _buildChip(
              tokens: tokens,
              chipKey: Key('rule_tint_${tint.name}'),
              label: tint.label,
              isSelected: selectedRuleTint == tint,
              onSelect: () => onRuleTintChanged(tint),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle(tokens, '落款印式 · Seal Style'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SealCarvingStyle.values.map((style) {
            return _buildChip(
              tokens: tokens,
              chipKey: Key('seal_style_${style.name}'),
              label: style.label,
              isSelected: selectedSealStyle == style,
              onSelect: () => onSealStyleChanged(style),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(InkDiaryTokens tokens, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: InkDiaryTheme.fontNotoSerif,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: tokens.jiaomo,
      ),
    );
  }

  Widget _buildChip({
    required InkDiaryTokens tokens,
    required Key chipKey,
    required String label,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return ChoiceChip(
      key: chipKey,
      label: Text(label),
      selected: isSelected,
      selectedColor: tokens.jiaomo,
      backgroundColor: tokens.ricePaper,
      labelStyle: TextStyle(
        fontFamily: InkDiaryTheme.fontKaiti,
        color: isSelected ? tokens.xuanGround : tokens.nongmo,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          HapticFeedback.lightImpact();
          onSelect();
        }
      },
    );
  }
}
