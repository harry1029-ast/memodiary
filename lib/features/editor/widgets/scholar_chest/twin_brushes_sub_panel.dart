import 'package:flutter/material.dart';

import '../../../../core/theme/ink_diary_theme.dart';
import '../../../../core/theme/widgets/min_tap_target.dart';
import '../../ink_choreography/ink_choreography_config.dart';
import '../../ink_choreography/ink_choreography_controller.dart';
import '../../services/audio_sanctum_service.dart';
import 'ink_choreography_labels.dart';
import 'trial_rice_grid.dart';
import 'twin_brushes_selectors.dart';

const Color _goldText = Color(0xFFF3D99B);
const Color _mutedText = Color(0xFFD4C5B0);

/// The Ink Choreography compartment (挥毫落墨 · 双管笔意) of the Twin Bamboo
/// Brushes artifact: brush sound, 全页挥毫, the Trial Rice-Grid, and the
/// delivery mode, bristle elasticity and writing cadence selectors. Rebuilds
/// from [controller], which persists every choice.
class TwinBrushesSubPanel extends StatefulWidget {
  final InkChoreographyController controller;
  final AudioSanctumService audioSanctumService;

  /// The active template's ink and paper, and the Brush Mountain font, for
  /// the Trial Rice-Grid.
  final Color inkColor;
  final Color paperColor;
  final String? fontFamily;

  /// False on an ephemera sheet, which has no characters to replay.
  final bool isSheetReplayAvailable;

  /// Runs after 全页挥毫 has been requested, to put the drawer away.
  final VoidCallback? onSheetReplayRequested;
  final VoidCallback? onClose;

  const TwinBrushesSubPanel({
    super.key,
    required this.controller,
    required this.audioSanctumService,
    required this.inkColor,
    required this.paperColor,
    this.fontFamily,
    this.isSheetReplayAvailable = true,
    this.onSheetReplayRequested,
    this.onClose,
  });

  @override
  State<TwinBrushesSubPanel> createState() => _TwinBrushesSubPanelState();
}

class _TwinBrushesSubPanelState extends State<TwinBrushesSubPanel> {
  InkChoreographyController get _controller => widget.controller;
  int _replayToken = 0;

  /// Applies a selector choice and replays the Trial Rice-Grid sample.
  ValueChanged<T> _replaying<T>(ValueChanged<T> apply) => (value) {
        setState(() => _replayToken++);
        apply(value);
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final config = _controller.config;
        return Column(
          key: const Key('chest_subpanel_twin_brushes'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTitleRow(),
            _buildHeaderActions(config),
            const SizedBox(height: 4),
            TrialRiceGrid(
              config: config,
              replayToken: _replayToken,
              inkColor: widget.inkColor,
              paperColor: widget.paperColor,
              fontFamily: widget.fontFamily,
              audioSanctumService: widget.audioSanctumService,
            ),
            const SizedBox(height: 8),
            InkDeliveryModeCards(
              selected: config.deliveryMode,
              onSelected: _replaying(_controller.setDeliveryMode),
            ),
            const SizedBox(height: 8),
            InkPresetPills<BristleStiffness>(
              label: '毫锋弹性',
              keyPrefix: 'chest_ink_stiffness_pill',
              options: BristleStiffness.values,
              selected: config.bristleStiffness,
              titleOf: (stiffness) => stiffness.title,
              onSelected: _replaying(_controller.setBristleStiffness),
            ),
            const SizedBox(height: 4),
            InkPresetPills<WritingCadence>(
              label: '运笔疾徐',
              keyPrefix: 'chest_ink_cadence_pill',
              options: WritingCadence.values,
              selected: config.cadence,
              titleOf: (cadence) => cadence.title,
              onSelected: _replaying(_controller.setCadence),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        const Icon(Icons.brush_outlined, size: 16, color: Color(0xFFFFDF85)),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            '挥毫落墨 · 双管笔意',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: InkDiaryTheme.fontNotoSerif,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: _goldText,
            ),
          ),
        ),
        if (widget.onClose != null)
          MinTapTarget(
            key: const Key('chest_subpanel_close_button'),
            semanticLabel: '收拢面板',
            onTap: widget.onClose,
            child: const Icon(Icons.close, size: 16, color: _mutedText),
          ),
      ],
    );
  }

  Widget _buildHeaderActions(InkChoreographyConfig config) {
    final soundLabel = config.soundEnabled ? '🔊 运笔声效' : '🔇 运笔声效';
    return Wrap(
      spacing: 6,
      children: [
        Semantics(
          key: const Key('chest_ink_sound_toggle'),
          toggled: config.soundEnabled,
          child: MinTapTarget(
            semanticLabel: '运笔声效',
            excludeChildSemantics: true,
            onTap: () => _controller.setSoundEnabled(!config.soundEnabled),
            child: _HeaderChip(label: soundLabel, isActive: config.soundEnabled),
          ),
        ),
        MinTapTarget(
          key: const Key('chest_ink_sheet_replay_button'),
          semanticLabel: '全页挥毫: 重演当前笺页',
          enabled: widget.isSheetReplayAvailable,
          excludeChildSemantics: true,
          onTap: widget.isSheetReplayAvailable ? _requestSheetReplay : null,
          child: _HeaderChip(label: '▶ 全页挥毫', isActive: widget.isSheetReplayAvailable, isAccent: true),
        ),
      ],
    );
  }

  void _requestSheetReplay() {
    _controller.requestSheetReplay();
    widget.onSheetReplayRequested?.call();
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isAccent;

  const _HeaderChip({required this.label, required this.isActive, this.isAccent = false});

  @override
  Widget build(BuildContext context) {
    final accent = isAccent ? const Color(0xFFB83B2E) : const Color(0xFF8C7148);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isActive && isAccent ? accent.withValues(alpha: 0.85) : const Color(0xFF2A1C16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: isActive ? 0.9 : 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? const Color(0xFFFFF1CF) : _mutedText.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
