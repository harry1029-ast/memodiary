import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/ink_diary_theme.dart';
import '../services/audio_sanctum_service.dart';

/// Bottom sheet modal allowing the user to select offline Writing Sanctum
/// ambient soundscapes and adjust synthesis volume in Ink & Paper aesthetic.
class SoundscapeModal extends StatefulWidget {
  final AudioSanctumService sanctumService;

  const SoundscapeModal({
    super.key,
    required this.sanctumService,
  });

  static Future<void> show({
    required BuildContext context,
    required AudioSanctumService sanctumService,
  }) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.xuanGround,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) => SoundscapeModal(sanctumService: sanctumService),
    );
  }

  @override
  State<SoundscapeModal> createState() => _SoundscapeModalState();
}

class _SoundscapeModalState extends State<SoundscapeModal> {
  static const Map<SoundscapePreset, Map<String, String>> _literatiPresets = {
    SoundscapePreset.gentleRain: {
      'title': '空山疏雨',
      'englishTitle': 'Gentle Rain',
      'tag': '清心',
      'desc': '淅淅沥沥，如松针滴翠、空阶滴沥 (Soft Rainfall)',
      'stamp': '润',
    },
    SoundscapePreset.vintageLibrary: {
      'title': '芸阁旧帙',
      'englishTitle': 'Vintage Library',
      'tag': '古意',
      'desc': '书卷微翻，沉木幽香与案头薪火 (Quiet Hearth)',
      'stamp': '幽',
    },
    SoundscapePreset.mechanicalKeyboard: {
      'title': '幽居刻漏',
      'englishTitle': 'Mechanical Study',
      'tag': '定神',
      'desc': '更漏沉沉，定神静虑之节拍律动 (Study Ticks)',
      'stamp': '恒',
    },
    SoundscapePreset.bambooBreeze: {
      'title': '松风抚竹',
      'englishTitle': 'Bamboo Breeze',
      'tag': '超然',
      'desc': '山谷微风，穿林拂叶之婆娑沙沙 (Breeze)',
      'stamp': '逸',
    },
  };

  @override
  Widget build(BuildContext context) {
    final tokens = InkDiaryTheme.tokensOf(context);

    return SafeArea(
      child: ListenableBuilder(
        listenable: widget.sanctumService,
        builder: (context, _) {
          final activePreset = widget.sanctumService.activePreset;
          final isPlaying = widget.sanctumService.isPlaying;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle pill
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.danmo.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Modal Header
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: tokens.cinnabarWash,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: tokens.cinnabar.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.headphones_rounded,
                        size: 18,
                        color: tokens.cinnabar,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '砚边清韵',
                                style: TextStyle(
                                  fontFamily: InkDiaryTheme.fontNotoSerif,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: tokens.jiaomo,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Writing Sanctum Soundscapes',
                                style: TextStyle(
                                  fontFamily: InkDiaryTheme.fontNotoSerif,
                                  fontSize: 12,
                                  color: tokens.danmo,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '纯净离线合成 · 凝神静虑自然音律',
                            style: TextStyle(
                              fontSize: 11,
                              color: tokens.danmo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPlaying) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildWaveBar(14, tokens.cinnabar),
                          const SizedBox(width: 2.5),
                          _buildWaveBar(20, tokens.cinnabar),
                          const SizedBox(width: 2.5),
                          _buildWaveBar(10, tokens.cinnabar),
                        ],
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        key: const Key('soundscape_stop_btn'),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          widget.sanctumService.stop();
                        },
                        child: Text(
                          '停歇 · Turn Off',
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: tokens.cinnabar,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Soundscape Presets List
                for (final preset in SoundscapePreset.values) ...[
                  _buildPresetItem(
                    preset: preset,
                    isSelected: activePreset == preset && isPlaying,
                    tokens: tokens,
                  ),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 8),

                // Volume and Play/Stop Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: tokens.ricePaper,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tokens.agedFiber),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.volume_down_outlined,
                        size: 20,
                        color: tokens.danmo,
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: tokens.cinnabar,
                            inactiveTrackColor: tokens.agedFiber,
                            thumbColor: tokens.cinnabar,
                            trackHeight: 3.5,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                          ),
                          child: Slider(
                            value: widget.sanctumService.volume,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (val) {
                              widget.sanctumService.setVolume(val);
                            },
                          ),
                        ),
                      ),
                      Icon(
                        Icons.volume_up_outlined,
                        size: 20,
                        color: tokens.nongmo,
                      ),
                      const SizedBox(width: 8),
                      // Classical Stamp Play / Pause Button
                      GestureDetector(
                        key: const Key('soundscape_play_toggle_btn'),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (isPlaying) {
                            widget.sanctumService.stop();
                          } else {
                            widget.sanctumService.play(
                              activePreset ?? SoundscapePreset.gentleRain,
                            );
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isPlaying ? tokens.cinnabar : tokens.danmo.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                            boxShadow: isPlaying
                                ? [
                                    BoxShadow(
                                      color: tokens.cinnabar.withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaveBar(double height, Color color) {
    return Container(
      width: 2.5,
      height: height.clamp(4.0, 22.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildPresetItem({
    required SoundscapePreset preset,
    required bool isSelected,
    required InkDiaryTokens tokens,
  }) {
    final meta = _literatiPresets[preset] ?? {
      'title': preset.label,
      'tag': '音律',
      'desc': preset.subtitle,
      'stamp': '韵',
    };

    return InkWell(
      key: Key('soundscape_preset_${preset.id}'),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.sanctumService.play(preset);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? tokens.ricePaper : tokens.ricePaper.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? tokens.cinnabar : tokens.agedFiber,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tokens.cinnabar.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Cinnabar Seal Radio Indicator
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? tokens.cinnabar : tokens.danmo.withValues(alpha: 0.6),
                  width: 1.8,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tokens.cinnabar,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Sound Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        meta['title']!,
                        style: TextStyle(
                          fontFamily: InkDiaryTheme.fontNotoSerif,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? tokens.jiaomo : tokens.nongmo,
                        ),
                      ),
                      if (meta['englishTitle'] != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          meta['englishTitle']!,
                          style: TextStyle(
                            fontFamily: InkDiaryTheme.fontNotoSerif,
                            fontSize: 12,
                            color: tokens.danmo,
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? tokens.cinnabarWash : tokens.agedFiber.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected ? tokens.cinnabar.withValues(alpha: 0.3) : tokens.agedFiber,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          meta['tag']!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? tokens.cinnabar : tokens.danmo,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta['desc']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: tokens.danmo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Calligraphic Stamp character
            Text(
              meta['stamp']!,
              style: TextStyle(
                fontFamily: InkDiaryTheme.fontMaShanZheng,
                fontSize: 20,
                color: isSelected ? tokens.cinnabar : tokens.danmo.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
