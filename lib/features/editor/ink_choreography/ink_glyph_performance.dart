import 'brush_kinematics.dart';
import 'ink_glyph_frame.dart';

/// One character being written: its [InkGlyphTimeline] stepped by ticker
/// time, with the brush that writes it. Shared by the Stationery Sheet
/// overlay (one per active slot) and the Trial Rice-Grid.
class InkGlyphPerformance {
  final InkGlyphTimeline timeline;

  /// The active bristle preset's lag factor.
  final double lagFactor;

  /// The brush writing this character: the sheet's master brush when one is
  /// passed in, else the character's own brush, sized in its stroke-box units
  /// and landing on the first stroke. It is simulated in every delivery mode,
  /// since its bristle stretch shapes the wet-ink tip pool even when no brush
  /// is drawn.
  final BrushKinematics brush;

  InkGlyphPerformance({
    required this.timeline,
    required this.lagFactor,
    BrushKinematics? brush,
  }) : brush = brush ?? BrushKinematics(pxPerUnit: timeline.plan.inkUnit) {
    _frame = timeline.frameAt(Duration.zero);
  }

  Duration _elapsed = Duration.zero;
  late InkGlyphFrame _frame;
  int _lastStartedStroke = -1;

  Duration get elapsed => _elapsed;
  InkGlyphFrame get frame => _frame;
  bool get isSettled => _frame.isSettled;

  /// Advances by [dt] of ticker time. Returns whether a new stroke started
  /// during this tick, which is when the brush rustles on the paper.
  bool advance(Duration dt) {
    _elapsed += dt;
    _frame = timeline.frameAt(_elapsed);
    if (!_frame.isWriting) return false;

    final startsStroke = _frame.strokeIndex != _lastStartedStroke;
    if (startsStroke) {
      if (_lastStartedStroke >= 0) brush.flickForNextStroke();
      _lastStartedStroke = _frame.strokeIndex;
    }
    brush.follow(tip: _frame.tip, dt: dt, lagFactor: lagFactor);
    return startsStroke;
  }

  /// The bristle stretch in stroke-box units, for the wet-ink tip pool.
  double get bristleStretch => brush.bristleStretch(tip: _frame.tip, inkUnit: timeline.plan.inkUnit);

  /// The brush's pose while it is writing; null once the character settles
  /// (or before the first [advance]).
  BrushPose? pose({required double brushScale}) {
    if (!_frame.isWriting || !brush.hasLanded) return null;
    return brush.pose(tip: _frame.tip, isPressing: _frame.isPressing, brushScale: brushScale);
  }
}
