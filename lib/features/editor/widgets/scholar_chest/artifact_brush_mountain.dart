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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                bottom: 20,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  builder: (context, liftProgress, child) {
                    return CustomPaint(
                      painter: PorcelainBrushRestPainter(
                        liftProgress: liftProgress,
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
                      horizontal: 6,
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
                    child: Text(
                      '青花笔架',
                      style: TextStyle(
                        fontFamily: InkDiaryTheme.fontKaiti,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE6C875),
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

/// Renders the Three-Peak Blue-and-White Porcelain Mountain (青花三峰笔山) and resting calligraphy brush.
class PorcelainBrushRestPainter extends CustomPainter {
  final double liftProgress;

  PorcelainBrushRestPainter({required this.liftProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final canvasWidth = size.width;
    final canvasHeight = size.height;

    // 1. Resting Bamboo Calligraphy Brush (lifts up off porcelain peaks on hover/selection)
    canvas.save();
    canvas.translate(0, -7.0 * liftProgress);
    canvas.rotate(-0.05 * liftProgress);

    final shaftPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFDAB77B), Color(0xFF9A6F37)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(canvasWidth * 0.08, canvasHeight * 0.22, canvasWidth * 0.60, 5.5));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(canvasWidth * 0.08, canvasHeight * 0.22, canvasWidth * 0.60, 5.5),
        const Radius.circular(2.5),
      ),
      shaftPaint,
    );
    // Spotted bamboo markings (湘妃斑竹)
    final bambooSpotPaint = Paint()..color = const Color(0x6652361B);
    canvas.drawCircle(Offset(canvasWidth * 0.22, canvasHeight * 0.245), 0.9, bambooSpotPaint);
    canvas.drawCircle(Offset(canvasWidth * 0.40, canvasHeight * 0.245), 1.0, bambooSpotPaint);
    canvas.drawCircle(Offset(canvasWidth * 0.54, canvasHeight * 0.25), 0.9, bambooSpotPaint);

    // Brush ferrule & tip
    canvas.drawRect(
      Rect.fromLTWH(canvasWidth * 0.68, canvasHeight * 0.215, canvasWidth * 0.06, 6.5),
      Paint()..color = const Color(0xFF231D19),
    );
    final brushTip = Path()
      ..moveTo(canvasWidth * 0.74, canvasHeight * 0.22)
      ..quadraticBezierTo(canvasWidth * 0.84, canvasHeight * 0.23, canvasWidth * 0.91, canvasHeight * 0.25)
      ..quadraticBezierTo(canvasWidth * 0.84, canvasHeight * 0.27, canvasWidth * 0.74, canvasHeight * 0.28)
      ..close();
    canvas.drawPath(brushTip, Paint()..color = const Color(0xFFF7F4EE));
    canvas.restore();

    // 2. Three-Peak Blue-and-White Porcelain Mountain (青花三峰笔山)
    final mountainPath = Path()
      ..moveTo(canvasWidth * 0.10, canvasHeight * 0.88)
      ..lineTo(canvasWidth * 0.10, canvasHeight * 0.66)
      ..quadraticBezierTo(canvasWidth * 0.19, canvasHeight * 0.32, canvasWidth * 0.28, canvasHeight * 0.60)
      ..quadraticBezierTo(canvasWidth * 0.36, canvasHeight * 0.76, canvasWidth * 0.42, canvasHeight * 0.52)
      ..quadraticBezierTo(canvasWidth * 0.50, canvasHeight * 0.06, canvasWidth * 0.58, canvasHeight * 0.52)
      ..quadraticBezierTo(canvasWidth * 0.64, canvasHeight * 0.76, canvasWidth * 0.72, canvasHeight * 0.60)
      ..quadraticBezierTo(canvasWidth * 0.81, canvasHeight * 0.32, canvasWidth * 0.90, canvasHeight * 0.66)
      ..lineTo(canvasWidth * 0.90, canvasHeight * 0.88)
      ..close();

    final porcelainPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFE6EEF6), Color(0xFFBDD0E4)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight));
    canvas.drawPath(mountainPath, porcelainPaint);

    final cobaltStroke = Paint()
      ..color = const Color(0xFF1F4E8C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawPath(mountainPath, cobaltStroke);

    // Cobalt decorative peak arcs
    final arcPath = Path()
      ..moveTo(canvasWidth * 0.44, canvasHeight * 0.42)
      ..quadraticBezierTo(canvasWidth * 0.50, canvasHeight * 0.33, canvasWidth * 0.56, canvasHeight * 0.42)
      ..moveTo(canvasWidth * 0.42, canvasHeight * 0.54)
      ..quadraticBezierTo(canvasWidth * 0.50, canvasHeight * 0.45, canvasWidth * 0.58, canvasHeight * 0.54);
    canvas.drawPath(arcPath, cobaltStroke);
  }

  @override
  bool shouldRepaint(covariant PorcelainBrushRestPainter oldDelegate) =>
      oldDelegate.liftProgress != liftProgress;
}

/// In-chest sub-panel for the Brush Mountain typography controls
class BrushMountainSubPanel extends StatelessWidget {
  final TypographySettings typography;
  final ValueChanged<TypographySettings> onTypographyChanged;
  final bool isCenterAligned;
  final VoidCallback? onToggleAlignment;
  final VoidCallback? onClose;

  const BrushMountainSubPanel({
    super.key,
    required this.typography,
    required this.onTypographyChanged,
    this.isCenterAligned = false,
    this.onToggleAlignment,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.text_fields, size: 16, color: Color(0xFFFFDF85)),
                const SizedBox(width: 6),
                const Text(
                  '字法墨韵 · 笔意规制',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3D99B),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  key: const Key('chest_poetry_align_button'),
                  icon: Icon(
                    isCenterAligned
                        ? Icons.format_align_center
                        : Icons.format_align_left,
                    size: 18,
                    color: const Color(0xFFFFDF85),
                  ),
                  tooltip: '诗意居中排印',
                  onPressed: onToggleAlignment,
                ),
                if (onClose != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(Icons.close, size: 16, color: Color(0xFFD4C5B0)),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Font Family Selector
        Row(
          children: [
            const Text(
              '墨宝字型',
              style: TextStyle(fontSize: 11.5, color: Color(0xFFD4C5B0)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1812),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: const Key('chest_font_family_dropdown'),
                    value: typography.fontFamily ?? InkDiaryTheme.fontNotoSerif,
                    isDense: true,
                    dropdownColor: const Color(0xFF2A1812),
                    iconEnabledColor: const Color(0xFFFFDF85),
                    items: [
                      DropdownMenuItem(
                        value: InkDiaryTheme.fontNotoSerif,
                        child: Text('思源雅宋 (Noto Serif)', style: TextStyle(fontFamily: InkDiaryTheme.fontNotoSerif, color: const Color(0xFFF5E6C8))),
                      ),
                      DropdownMenuItem(
                        value: InkDiaryTheme.fontKaiti,
                        child: Text('古法楷书 (Kaiti)', style: TextStyle(fontFamily: InkDiaryTheme.fontKaiti, color: const Color(0xFFF5E6C8))),
                      ),
                    ],
                    onChanged: (selectedFont) {
                      if (selectedFont != null) {
                        onTypographyChanged(typography.copyWith(fontFamily: selectedFont));
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Font Size Slider
        Row(
          children: [
            Text('字形大小 (${typography.fontSize.toInt()}pt)', style: const TextStyle(fontSize: 11, color: Color(0xFFD4C5B0))),
            Expanded(
              child: Slider(
                key: const Key('chest_font_size_slider'),
                value: typography.fontSize,
                min: 12.0,
                max: 28.0,
                divisions: 16,
                activeColor: const Color(0xFFD4AF37),
                inactiveColor: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                onChanged: (newSize) => onTypographyChanged(typography.copyWith(fontSize: newSize)),
              ),
            ),
          ],
        ),

        // Line Spacing Slider
        Row(
          children: [
            Text('行间高距 (${typography.lineSpacing.toStringAsFixed(1)}x)', style: const TextStyle(fontSize: 11, color: Color(0xFFD4C5B0))),
            Expanded(
              child: Slider(
                key: const Key('chest_line_spacing_slider'),
                value: typography.lineSpacing,
                min: 1.0,
                max: 2.4,
                divisions: 14,
                activeColor: const Color(0xFFD4AF37),
                inactiveColor: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                onChanged: (newSpacing) => onTypographyChanged(typography.copyWith(lineSpacing: newSpacing)),
              ),
            ),
          ],
        ),

        // Ink Tone Selection
        const SizedBox(height: 4),
        const Text('墨色韵调', style: TextStyle(fontSize: 11.5, color: Color(0xFFD4C5B0))),
        const SizedBox(height: 4),
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
          color: color.withValues(alpha: isSelected ? 0.35 : 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFDF85) : color.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontKaiti,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFFFDF85) : const Color(0xFFF5E6C8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
