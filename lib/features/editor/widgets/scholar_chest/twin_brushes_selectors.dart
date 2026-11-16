import 'package:flutter/material.dart';

import '../../../../core/theme/widgets/min_tap_target.dart';
import '../../ink_choreography/ink_choreography_config.dart';
import 'ink_choreography_labels.dart';

const Color _gold = Color(0xFFD4AF37);
const Color _goldText = Color(0xFFF3D99B);
const Color _mutedText = Color(0xFFD4C5B0);
const Color _cardGround = Color(0xFF2A1C16);

/// The Delivery Mode selector (运笔模式): four cards, two per row.
class InkDeliveryModeCards extends StatelessWidget {
  final InkDeliveryMode selected;
  final ValueChanged<InkDeliveryMode> onSelected;

  const InkDeliveryModeCards({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const modes = InkDeliveryMode.values;
    return Column(
      children: [
        for (var row = 0; row < modes.length; row += 2) ...[
          if (row > 0) const SizedBox(height: 6),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildCard(modes[row])),
                const SizedBox(width: 6),
                Expanded(child: _buildCard(modes[row + 1])),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCard(InkDeliveryMode mode) {
    final isSelected = mode == selected;
    return MinTapTarget(
      key: Key('chest_ink_mode_card_${mode.name}'),
      semanticLabel: '运笔模式: ${mode.title}',
      selected: isSelected,
      excludeChildSemantics: true,
      stretchWidth: true,
      borderRadius: BorderRadius.circular(10),
      onTap: () => onSelected(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
        decoration: BoxDecoration(
          color: _cardGround,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _gold.withValues(alpha: 0.85) : const Color(0xFF4A382B),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${mode.icon} ${mode.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFFFFDF85) : const Color(0xFFE8DCC8),
                    ),
                  ),
                ),
                if (isSelected)
                  const Text('✓', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: _gold)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              mode.description,
              style: const TextStyle(fontSize: 10, height: 1.35, color: _mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled row of preset pills, e.g. Bristle Elasticity (毫锋弹性) or
/// Writing Cadence (运笔疾徐).
class InkPresetPills<T extends Enum> extends StatelessWidget {
  final String label;
  final String keyPrefix;
  final List<T> options;
  final T selected;
  final String Function(T option) titleOf;
  final ValueChanged<T> onSelected;

  const InkPresetPills({
    super.key,
    required this.label,
    required this.keyPrefix,
    required this.options,
    required this.selected,
    required this.titleOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _goldText)),
        Wrap(
          spacing: 6,
          children: [for (final option in options) _buildPill(option)],
        ),
      ],
    );
  }

  Widget _buildPill(T option) {
    final isSelected = option == selected;
    final title = titleOf(option);
    return MinTapTarget(
      key: Key('${keyPrefix}_${option.name}'),
      semanticLabel: '$label: $title',
      selected: isSelected,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(14),
      onTap: () => onSelected(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5A3F1A).withValues(alpha: 0.7) : _cardGround,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _gold.withValues(alpha: 0.8) : const Color(0xFF4A382B),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? const Color(0xFFFFF1CF) : _mutedText,
          ),
        ),
      ),
    );
  }
}
