import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memodiary/features/editor/services/audio_sanctum_service.dart';

/// Bottom sheet modal allowing the user to toggle offline Writing Sanctum
/// ambient soundscapes and adjust volume.
class SoundscapeModal extends StatelessWidget {
  final AudioSanctumService sanctumService;

  const SoundscapeModal({
    super.key,
    required this.sanctumService,
  });

  static Future<void> show({
    required BuildContext context,
    required AudioSanctumService sanctumService,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SoundscapeModal(sanctumService: sanctumService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListenableBuilder(
        listenable: sanctumService,
        builder: (context, _) {
          final active = sanctumService.activePreset;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.headphones_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Writing Sanctum Soundscapes',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (sanctumService.isPlaying)
                      TextButton(
                        key: const Key('soundscape_stop_btn'),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          sanctumService.stop();
                        },
                        child: const Text('Turn Off'),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '100% offline synthesized ambient audio for deep focus.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                for (final preset in SoundscapePreset.values)
                  ListTile(
                    key: Key('soundscape_preset_${preset.id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      active == preset
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: active == preset
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      preset.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      preset.subtitle,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      sanctumService.selectPreset(preset);
                    },
                  ),
                const Divider(height: 16),
                Row(
                  children: [
                    const Icon(Icons.volume_down_rounded, size: 20),
                    Expanded(
                      child: Slider(
                        key: const Key('soundscape_volume_slider'),
                        value: sanctumService.volume,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (v) => sanctumService.setVolume(v),
                      ),
                    ),
                    const Icon(Icons.volume_up_rounded, size: 20),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
