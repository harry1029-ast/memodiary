import 'package:flutter/material.dart';
import '../ink_diary_theme.dart';

/// Custom toggle switch styled after the Ink & Paper Journal aesthetic
/// Features a dark ink track with vermilion indicator dot when active.
class InkSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  const InkSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.inkTokens;
    final trackColor = value ? tokens.jiaomo : tokens.agedFiber;

    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: value ? tokens.jiaomo : tokens.deckleBorder,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: tokens.jiaomo.withValues(alpha: 0.08),
                blurRadius: 2,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.xuanPureLeaf,
                boxShadow: [
                  BoxShadow(
                    color: tokens.jiaomo.withValues(alpha: 0.15),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? tokens.cinnabar : tokens.qingmo,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

