import 'package:flutter/material.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import 'fan_spread_stationery_painter.dart';

export 'stationery_fan_sub_panel.dart';

/// Stationery artifact representing the fanned paper tray (叠印花笺).
/// Allows diarists to preview and switch stationery templates.
class ArtifactStationeryFan extends StatelessWidget {
  final bool isSelected;
  final VoidCallback? onTap;

  const ArtifactStationeryFan({
    super.key,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '叠印花笺: 切换笺纸底色与界格',
      selected: isSelected,
      child: GestureDetector(
        key: const Key('chest_artifact_stationery_fan'),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF6B1A1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFD4AF37)
                  : const Color(0xFF8B262A),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isSelected ? 0.35 : 0.2,
                ),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                bottom: 24,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, fanProgress, child) {
                    return CustomPaint(
                      painter: FanSpreadStationeryPainter(
                        fanProgress: fanProgress,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: 4,
                right: 4,
                bottom: 2,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1A17),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFF8C7148),
                        width: 0.8,
                      ),
                    ),
                    child: const Text(
                      '叠印花笺',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontKaiti,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE6C875),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
