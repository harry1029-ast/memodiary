import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/theme/widgets/min_tap_target.dart';
import '../../ink_choreography/brush_kinematics.dart';
import '../../ink_choreography/hanzi_stroke_table.dart';
import '../../ink_choreography/ink_choreography_config.dart';
import '../../ink_choreography/ink_choreography_timeline.dart';
import '../../ink_choreography/ink_glyph_frame.dart';
import '../../ink_choreography/ink_glyph_performance.dart';
import '../../ink_choreography/ink_stroke_path.dart';
import '../../models/stationery_sheet_configs.dart';
import '../../services/audio_sanctum_service.dart';
import 'trial_rice_grid_painter.dart';

/// The Trial Rice-Grid row (米字格试笔窗) of the Twin Bamboo Brushes
/// compartment: a 60×60dp square that writes the selected sample character
/// with the live Ink Choreography settings, the sample chips, and `重演 ↻`.
///
/// It writes the current sample on mount, on a chip or `重演` tap, and
/// whenever [replayToken] changes. In `off` it previews Single Fluent Brush,
/// so the grid is never blank. Its ticker runs only while a character is
/// being written.
class TrialRiceGrid extends StatefulWidget {
  static const List<String> samples = ['永', '墨', '拾', '光', 'E', 'A'];
  static const double gridSize = 60;

  /// The glyph box inside the grid, inset so the brush lands on the paper.
  static const Rect glyphBox = Rect.fromLTWH(4, 4, 52, 52);

  final InkChoreographyConfig config;

  /// Bumped by the compartment on every selector tap to replay the sample.
  final int replayToken;

  /// The sheet's writing ink, paper and Brush Mountain font family.
  final TrialInkStyle ink;
  final AudioSanctumService audioSanctumService;

  const TrialRiceGrid({
    super.key,
    required this.config,
    required this.replayToken,
    required this.ink,
    required this.audioSanctumService,
  });

  @override
  State<TrialRiceGrid> createState() => _TrialRiceGridState();
}

class _TrialRiceGridState extends State<TrialRiceGrid> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final ValueNotifier<int> _frames = ValueNotifier<int>(0);
  String _sample = TrialRiceGrid.samples.first;
  InkGlyphPerformance? _performance;
  Duration _lastElapsed = Duration.zero;

  bool get _isWriting => _ticker.isActive;

  /// The delivery mode the grid previews: `off` shows Single Fluent Brush.
  InkDeliveryMode get _previewMode {
    final mode = widget.config.deliveryMode;
    return mode == InkDeliveryMode.off ? InkDeliveryMode.singleFluent : mode;
  }

  @override
  void initState() {
    super.initState();
    _write(_sample);
  }

  @override
  void didUpdateWidget(covariant TrialRiceGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replayToken != widget.replayToken) _write(_sample);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frames.dispose();
    super.dispose();
  }

  /// Starts writing [sample] afresh with the current settings. Callers in
  /// a gesture wrap this in `setState`.
  void _write(String sample) {
    _sample = sample;
    _ticker.stop();
    _lastElapsed = Duration.zero;
    final strokes = HanziStrokeTable.instance.strokesFor(sample);
    if (strokes == null || strokes.strokes.isEmpty) {
      _performance = null;
      return;
    }
    final plan = InkGlyphPlan.prepare(strokes: strokes.strokes, box: TrialRiceGrid.glyphBox, isCjk: strokes.isCjk);
    _performance = InkGlyphPerformance(
      timeline: InkGlyphTimeline(
        plan: plan,
        strokeDuration: InkChoreographyTimeline.strokeDuration(
          isCjk: plan.isCjk,
          speedMultiplier: widget.config.cadence.speedMultiplier,
        ),
      ),
      lagFactor: widget.config.bristleStiffness.lagFactor,
      brush: BrushKinematics(pxPerUnit: TrialRiceGrid.glyphBox.height / 100.0),
    );
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final performance = _performance;
    if (performance == null) return;
    final startsStroke = performance.advance(elapsed - _lastElapsed);
    _lastElapsed = elapsed;
    if (startsStroke) widget.audioSanctumService.playBrushStroke(soundEnabled: widget.config.soundEnabled);
    _frames.value++;
    if (performance.isSettled) setState(_ticker.stop);
  }

  @override
  Widget build(BuildContext context) {
    final caption = _isWriting ? '「$_sample」挥毫中' : '「$_sample」落墨已成';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: '米字格试笔窗',
          value: caption,
          image: true,
          child: RepaintBoundary(
            child: CustomPaint(
              size: const Size.square(TrialRiceGrid.gridSize),
              painter: TrialRiceGridPainter(
                sample: _sample,
                performance: () => _performance,
                glyphBox: TrialRiceGrid.glyphBox,
                showsBrush: _previewMode.showsBrush,
                inkColor: widget.ink.inkColor,
                paperColor: widget.ink.paperColor,
                fontFamily: widget.ink.fontFamily,
                repaint: _frames,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      caption,
                      key: const Key('chest_trial_grid_caption'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFF3D99B)),
                    ),
                  ),
                  MinTapTarget(
                    key: const Key('chest_trial_grid_replay_button'),
                    semanticLabel: '重演此字',
                    excludeChildSemantics: true,
                    onTap: () => setState(() => _write(_sample)),
                    child: const Text('重演 ↻', style: TextStyle(fontSize: 11, color: Color(0xFFE8826F))),
                  ),
                ],
              ),
              Wrap(children: [for (final sample in TrialRiceGrid.samples) _buildChip(sample)]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String sample) {
    final isSelected = sample == _sample;
    return MinTapTarget(
      key: Key('chest_trial_grid_chip_$sample'),
      semanticLabel: '试写「$sample」',
      selected: isSelected,
      excludeChildSemantics: true,
      onTap: () => setState(() => _write(sample)),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? TrialRiceGridPainter.vermilion : const Color(0xFF2A1C16),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? const Color(0xFFE8826F) : const Color(0xFF4A382B)),
        ),
        child: Text(
          sample,
          style: TextStyle(
            fontFamily: widget.ink.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFFE8DCC8),
          ),
        ),
      ),
    );
  }
}
