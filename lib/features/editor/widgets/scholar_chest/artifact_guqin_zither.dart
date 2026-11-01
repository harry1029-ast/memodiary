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
      duration: const Duration(milliseconds: 260),
    );
    if (widget.isPlaying) {
      _triggerVibration();
    }
  }

  void _triggerVibration() {
    _vibrationController.forward(from: 0.0).then((_) {
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
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6B1A1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected ? const Color(0xFFD4AF37) : const Color(0xFF8B262A),
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isSelected ? 0.35 : 0.2),
                blurRadius: widget.isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Guqin body & strings graphic
              SizedBox(
                height: 42,
                width: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Paulownia wood instrument body
                    Container(
                      width: 58,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF382315),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF5A3A22), width: 1.0),
                      ),
                    ),
                    // 7 golden silk strings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(7, (stringIndex) {
                        return AnimatedBuilder(
                          animation: _vibrationController,
                          builder: (context, _) {
                            final offset = widget.isPlaying
                                ? (_vibrationController.value * (stringIndex % 2 == 0 ? 0.8 : -0.8))
                                : 0.0;
                            return Transform.translate(
                              offset: Offset(offset, 0),
                              child: Container(
                                width: 1,
                                height: 26,
                                color: const Color(0xFFE6C875),
                              ),
                            );
                          },
                        );
                      }),
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
                  '桐木古琴',
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
}

/// In-chest sub-panel for the Guqin Zither artifact
class GuqinZitherSubPanel extends StatelessWidget {
  final AudioSanctumService audioSanctumService;

  const GuqinZitherSubPanel({
    super.key,
    required this.audioSanctumService,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return ListenableBuilder(
      listenable: audioSanctumService,
      builder: (context, _) {
        final active = audioSanctumService.activePreset;
        final isPlaying = audioSanctumService.isPlaying;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '书斋清音 · 琴韵自然',
                  style: TextStyle(
                    fontFamily: InkDiaryTheme.fontNotoSerif,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: tokens.jiaomo,
                  ),
                ),
                if (isPlaying)
                  TextButton.icon(
                    key: const Key('chest_soundscape_stop_button'),
                    style: TextButton.styleFrom(
                      foregroundColor: tokens.cinnabar,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    icon: const Icon(Icons.stop_circle_outlined, size: 14),
                    label: const Text('静默收琴', style: TextStyle(fontSize: 12)),
                    onPressed: () => audioSanctumService.stop(),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip(
                  context,
                  key: const Key('chest_soundscape_chip_rain'),
                  label: '蕉窗听雨',
                  preset: SoundscapePreset.gentleRain,
                  active: active,
                  tokens: tokens,
                ),
                _buildPresetChip(
                  context,
                  key: const Key('chest_soundscape_chip_bamboo'),
                  label: '松下抚琴',
                  preset: SoundscapePreset.bambooBreeze,
                  active: active,
                  tokens: tokens,
                ),
                _buildPresetChip(
                  context,
                  key: const Key('chest_soundscape_chip_library'),
                  label: '书斋炉暖',
                  preset: SoundscapePreset.vintageLibrary,
                  active: active,
                  tokens: tokens,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Volume Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('琴音音量 (${(audioSanctumService.volume * 100).round()}%)',
                    style: const TextStyle(fontSize: 12)),
                Icon(Icons.volume_up, size: 16, color: tokens.danmo),
              ],
            ),
            Slider(
              key: const Key('chest_soundscape_volume_slider'),
              value: audioSanctumService.volume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              activeColor: tokens.cinnabar,
              onChanged: (val) => audioSanctumService.setVolume(val),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPresetChip(
    BuildContext context, {
    required Key key,
    required String label,
    required SoundscapePreset preset,
    required SoundscapePreset? active,
    required InkDiaryTokens tokens,
  }) {
    final isSelected = active == preset;
    return ChoiceChip(
      key: key,
      label: Text(label),
      selected: isSelected,
      selectedColor: tokens.cinnabar,
      backgroundColor: tokens.ricePaper,
      labelStyle: TextStyle(
        fontFamily: InkDiaryTheme.fontKaiti,
        fontSize: 12,
        color: isSelected ? Colors.white : tokens.jiaomo,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          audioSanctumService.play(preset);
        } else {
          audioSanctumService.stop();
        }
      },
    );
  }
}
