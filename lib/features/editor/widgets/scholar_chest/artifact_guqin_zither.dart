import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/ink_diary_theme.dart';
import '../../services/audio_sanctum_service.dart';

/// Stationery artifact representing the Guqin Zither (桐木古琴).
/// Controls offline background soundscapes and ambient meditation audio.
class ArtifactGuqinZither extends StatefulWidget {
  final bool isSelected;
  final bool isPlaying;
  final VoidCallback? onTap;

  const ArtifactGuqinZither({
    super.key,
    this.isSelected = false,
    this.isPlaying = false,
    this.onTap,
  });

  @override
  State<ArtifactGuqinZither> createState() => _ArtifactGuqinZitherState();
}

class _ArtifactGuqinZitherState extends State<ArtifactGuqinZither>
    with SingleTickerProviderStateMixin {
  late final AnimationController _vibrationController;

  @override
  void initState() {
    super.initState();
    _vibrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.isPlaying) {
      _triggerVibration();
    }
  }

  void _triggerVibration() {
    _vibrationController.forward(from: 0.0).then((completed) {
      if (mounted) {
        _vibrationController.reverse();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ArtifactGuqinZither oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying && widget.isPlaying) {
      _triggerVibration();
    }
  }

  @override
  void dispose() {
    _vibrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '桐木古琴: 调节书斋清音与琴韵背景音',
      selected: widget.isSelected,
      child: GestureDetector(
        key: const Key('chest_artifact_guqin_zither'),
        onTap: () {
          _triggerVibration();
          widget.onTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6B1A1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFFD4AF37)
                  : const Color(0xFF8B262A),
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: widget.isSelected ? 0.35 : 0.2,
                ),
                blurRadius: widget.isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _vibrationController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned.fill(
                    bottom: 20,
                    child: CustomPaint(
                      painter: GuqinZitherPainter(
                        pluckProgress: _vibrationController.value,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    right: 6,
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
                            color: widget.isSelected
                                ? const Color(0xFFD4AF37)
                                : const Color(0xFF8C7148),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '桐木古琴',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontKaiti,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE6C875),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Renders the 7-String Paulownia Guqin Zither with silk runner, mother-of-pearl dots & vibrating strings.
class GuqinZitherPainter extends CustomPainter {
  final double pluckProgress;

  GuqinZitherPainter({required this.pluckProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final canvasWidth = size.width;
    final canvasHeight = size.height;

    // Emerald Brocade Table Runner
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          canvasWidth * 0.05,
          canvasHeight * 0.14,
          canvasWidth * 0.90,
          canvasHeight * 0.70,
        ),
        const Radius.circular(6),
      ),
      Paint()
        ..color = const Color(0xFF102A22)
        ..style = PaintingStyle.fill,
    );

    // Shaped Classical Paulownia Wood Guqin Body
    final bodyPath = Path()
      ..moveTo(canvasWidth * 0.04, canvasHeight * 0.28)
      ..quadraticBezierTo(
        canvasWidth * 0.28, canvasHeight * 0.22,
        canvasWidth * 0.48, canvasHeight * 0.29,
      )
      ..quadraticBezierTo(
        canvasWidth * 0.72, canvasHeight * 0.25,
        canvasWidth * 0.94, canvasHeight * 0.32,
      )
      ..lineTo(canvasWidth * 0.94, canvasHeight * 0.68)
      ..quadraticBezierTo(
        canvasWidth * 0.72, canvasHeight * 0.75,
        canvasWidth * 0.48, canvasHeight * 0.71,
      )
      ..quadraticBezierTo(
        canvasWidth * 0.28, canvasHeight * 0.78,
        canvasWidth * 0.04, canvasHeight * 0.72,
      )
      ..close();

    final woodPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4A2A1A), Color(0xFF2B160D), Color(0xFF1B0C06)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight));
    canvas.drawPath(bodyPath, woodPaint);
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFF8C5B3E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    // 13 Mother-of-Pearl Harmonic Dots (螺钿十三徽)
    final pearlPaint = Paint()..color = const Color(0xFFF6EFE2);
    for (int dotIndex = 0; dotIndex < 13; dotIndex++) {
      final dotX = canvasWidth * (0.12 + dotIndex * 0.062);
      canvas.drawCircle(Offset(dotX, canvasHeight * 0.32), 1.2, pearlPaint);
    }

    // 7 Taut Silk Strings with vibrating sine oscillation
    final stringPaint = Paint()
      ..color = const Color(0xFFE8D3A7).withValues(alpha: 0.90)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    for (int stringIndex = 0; stringIndex < 7; stringIndex++) {
      final stringY = canvasHeight * (0.37 + stringIndex * 0.044);
      final vibrationOffset = (stringIndex.isEven ? 1.0 : -1.0) *
          2.0 * pluckProgress * math.sin((stringIndex + 1) * 1.3);
      final stringPath = Path()
        ..moveTo(canvasWidth * 0.09, stringY)
        ..quadraticBezierTo(
          canvasWidth * 0.50, stringY + vibrationOffset,
          canvasWidth * 0.90, stringY,
        );
      canvas.drawPath(stringPath, stringPaint);
    }

    // Red Silk Tassel hanging from tuning end (朱红琴穗)
    final tasselPath = Path()
      ..moveTo(canvasWidth * 0.92, canvasHeight * 0.50)
      ..quadraticBezierTo(
        canvasWidth * 0.95, canvasHeight * 0.62,
        canvasWidth * 0.97, canvasHeight * 0.82,
      );
    canvas.drawPath(
      tasselPath,
      Paint()
        ..color = const Color(0xFFD13426)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant GuqinZitherPainter oldDelegate) =>
      oldDelegate.pluckProgress != pluckProgress;
}

/// In-chest sub-panel for the Guqin Zither ambient audio controls
class GuqinZitherSubPanel extends StatefulWidget {
  final AudioSanctumService audioSanctumService;
  final VoidCallback? onClose;

  const GuqinZitherSubPanel({
    super.key,
    required this.audioSanctumService,
    this.onClose,
  });

  @override
  State<GuqinZitherSubPanel> createState() => _GuqinZitherSubPanelState();
}

class _GuqinZitherSubPanelState extends State<GuqinZitherSubPanel> {
  late double _volume;

  @override
  void initState() {
    super.initState();
    _volume = widget.audioSanctumService.volume;
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.audioSanctumService.isPlaying;
    final activePreset = widget.audioSanctumService.activePreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isPlaying ? Icons.graphic_eq : Icons.music_note_outlined,
                  size: 16,
                  color: const Color(0xFFFFDF85),
                ),
                const SizedBox(width: 6),
                const Text(
                  '书斋清音 · 琴韵自然',
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
                if (isPlaying)
                  TextButton.icon(
                    key: const Key('chest_soundscape_stop_button'),
                    icon: const Icon(Icons.stop_circle_outlined, size: 14),
                    label: const Text('停歇清音', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFFDF85),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    onPressed: () async {
                      await widget.audioSanctumService.stop();
                      setState(() {});
                    },
                  ),
                if (widget.onClose != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: const Icon(Icons.close, size: 16, color: Color(0xFFD4C5B0)),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Soundscape preset chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetChip(key: const Key('chest_soundscape_chip_rain'), label: '蕉窗听雨', preset: SoundscapePreset.gentleRain, activePreset: activePreset),
            _buildPresetChip(key: const Key('chest_soundscape_chip_wind'), label: '深山松风', preset: SoundscapePreset.bambooBreeze, activePreset: activePreset),
            _buildPresetChip(key: const Key('chest_soundscape_chip_stream'), label: '芸窗缃帙', preset: SoundscapePreset.vintageLibrary, activePreset: activePreset),
            _buildPresetChip(key: const Key('chest_soundscape_chip_bell'), label: '砚池墨渧', preset: SoundscapePreset.mechanicalKeyboard, activePreset: activePreset),
          ],
        ),
        const SizedBox(height: 12),

        // Volume slider
        Row(
          children: [
            const Icon(Icons.volume_down, size: 16, color: Color(0xFFD4C5B0)),
            Expanded(
              child: Slider(
                key: const Key('chest_soundscape_volume_slider'),
                value: _volume,
                min: 0.0,
                max: 1.0,
                activeColor: const Color(0xFFD4AF37),
                inactiveColor: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                onChanged: (volumeValue) {
                  setState(() => _volume = volumeValue);
                  widget.audioSanctumService.setVolume(volumeValue);
                },
              ),
            ),
            const Icon(Icons.volume_up, size: 16, color: Color(0xFFD4C5B0)),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetChip({
    required Key key,
    required String label,
    required SoundscapePreset preset,
    required SoundscapePreset? activePreset,
  }) {
    final isSelected =
        widget.audioSanctumService.isPlaying && activePreset == preset;
    return ChoiceChip(
      key: key,
      label: Text(
        label,
        style: TextStyle(
          fontFamily: InkDiaryTheme.fontNotoSerif,
          fontSize: 11.5,
          color: isSelected ? const Color(0xFFFFDF85) : const Color(0xFFF5E6C8),
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFFD4AF37).withValues(alpha: 0.28),
      backgroundColor: const Color(0xFF2A1812),
      side: BorderSide(
        color: isSelected
            ? const Color(0xFFFFDF85)
            : const Color(0xFFD4AF37).withValues(alpha: 0.3),
      ),
      onSelected: (selected) async {
        if (isSelected) {
          await widget.audioSanctumService.stop();
        } else {
          await widget.audioSanctumService.play(preset);
        }
        setState(() {});
      },
    );
  }
}
