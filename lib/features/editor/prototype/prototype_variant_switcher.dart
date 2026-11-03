import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'paper_framing_prototype_models.dart';

/// Floating switcher bar anchored above the bottom controls, allowing
/// immediate one-tap or keyboard-driven cycling across the 3 layout prototypes.
class PrototypeVariantSwitcher extends StatelessWidget {
  final PaperFramingVariant currentVariant;
  final ValueChanged<PaperFramingVariant> onVariantChanged;

  const PrototypeVariantSwitcher({
    super.key,
    required this.currentVariant,
    required this.onVariantChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            onVariantChanged(currentVariant.previous);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            onVariantChanged(currentVariant.next);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xE61E1E22),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: const Color(0x33FFFFFF), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 16.0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: const Key('prototype_prev_variant_btn'),
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
                  onPressed: () => onVariantChanged(currentVariant.previous),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC04851),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PROTOTYPE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currentVariant.keyName}: ${currentVariant.title}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currentVariant.shortSummary,
                        style: const TextStyle(
                          color: Color(0xB3FFFFFF),
                          fontSize: 9.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  key: const Key('prototype_next_variant_btn'),
                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                  onPressed: () => onVariantChanged(currentVariant.next),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
