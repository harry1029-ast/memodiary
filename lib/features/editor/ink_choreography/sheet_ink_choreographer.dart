import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'brush_kinematics.dart';
import 'ink_choreography_config.dart';
import 'ink_choreography_timeline.dart';
import 'ink_glyph_frame.dart';
import 'ink_glyph_performance.dart';
import 'ink_insertion_tracker.dart';
import 'ink_slot.dart';
import 'ink_stroke_path.dart';

/// Writes one Stationery Sheet's queued characters (SPEC-020 §4): steps
/// every [InkSlot] of its [tracker] by ticker time, in the slot's delivery
/// mode, and holds what the overlay's two layers paint.
///
/// - Single Fluent Brush slots are written one at a time by the sheet's
///   master brush, which glides between them on an [InkTransit] and speeds
///   up while characters wait (行书提速).
/// - Concurrent Multi-Brush and Ink-Only Bloom slots all start at once.
/// - A slot leaves the queue when its settle has dissolved.
///
/// Positions are in the ink layer's coordinates. A slot is located by
/// [locate] while the layer paints ([resolveGeometry]), when the editor has
/// laid the text out; an edit clears every location, so the next paint
/// finds the glyphs where they moved to. Notifies on every change to what
/// is painted.
class SheetInkChoreographer extends ChangeNotifier {
  /// The diarist's live preferences.
  InkChoreographyConfig Function() config;

  /// The sheet's text size: the em of the stroke box and the brush's scale.
  double Function() fontSize;

  /// Where [slot]'s glyph stands now, or null while it cannot be found.
  InkGlyphGeometry? Function(InkSlot slot) locate;

  final String Function() _plainText;

  /// Runs when there is something to animate, so the owner can start its
  /// ticker.
  final VoidCallback? onWake;

  late final InkInsertionTracker tracker;

  SheetInkChoreographer({
    required this.config,
    required this.fontSize,
    required this.locate,
    required bool Function() hasFocus,
    required String Function() plainText,
    this.onWake,
  }) : _plainText = plainText {
    tracker = InkInsertionTracker(
      deliveryMode: () => config().deliveryMode,
      hasFocus: hasFocus,
      plainText: plainText,
      onChanged: _onQueueChanged,
    );
  }

  /// How long a slot may wait for the editor to lay its glyph out before it
  /// is given up on (its printed glyph is showing all the while).
  static const Duration locateTimeout = Duration(milliseconds: 400);

  final BrushKinematics _masterBrush = BrushKinematics();

  /// The Single Fluent Brush slot under the master brush.
  InkSlot? _masterSlot;

  /// Where the master brush last touched the paper, and how high it is.
  Offset? _masterTip;
  double _masterLift = 0.0;
  Duration _restElapsed = Duration.zero;

  InkTransit? _transit;
  InkSlot? _transitTarget;
  InkGlyphGeometry? _transitGeometry;
  Duration _transitElapsed = Duration.zero;
  Duration _transitDuration = Duration.zero;
  double _transitCatchup = 1.0;

  int _seenSettleCount = 0;

  /// The characters waiting to be written or being written, oldest first.
  List<InkSlot> get slots => tracker.slots;

  /// Whether a full-sheet replay (全页挥毫) is running.
  bool get isReplaying => tracker.isReplaying;

  /// Nothing left to animate: no slot, and the master brush is put away.
  bool get isIdle => slots.isEmpty && !_masterBrush.hasLanded;

  /// The transit whose Airborne Silk Trace is showing, if any.
  InkTransit? get silkTrace => _transit;

  /// Starts a full-sheet replay.
  void replay() => tracker.replay();

  /// Settles every slot at once and puts the brush away.
  void settleAll() {
    tracker.settleAll();
    if (!_masterBrush.hasLanded) return;
    _putMasterAway();
    notifyListeners();
  }

  void _onQueueChanged() {
    _syncSettle();
    if (!isIdle) onWake?.call();
    notifyListeners();
  }

  /// Puts the master brush away as soon as the tracker has settled all.
  void _syncSettle() {
    if (tracker.settleCount == _seenSettleCount) return;
    _seenSettleCount = tracker.settleCount;
    _putMasterAway();
  }

  void _putMasterAway() {
    _masterBrush.putAway();
    _masterSlot = null;
    _masterTip = null;
    _masterLift = 0.0;
    _restElapsed = Duration.zero;
    _endTransit();
  }

  void _endTransit() {
    _transit = null;
    _transitTarget = null;
    _transitGeometry = null;
    _masterLift = 0.0;
  }

  /// Locates every slot that is new or that an edit may have moved. Call
  /// while painting: the editor's layout is then the one about to be shown.
  /// Never notifies.
  void resolveGeometry() {
    for (final slot in slots) {
      if (!slot.needsLocating) continue;
      final located = locate(slot);
      final previous = slot.geometry;
      if (located == null) {
        slot.geometry = null;
        continue;
      }
      slot.needsLocating = false;
      if (previous != null && previous.isCloseTo(located)) continue;
      slot.geometry = located;
      final performance = slot.performance;
      if (performance != null) {
        // The glyph moved (a wrap, an edit before it): carry on writing it
        // where it now stands.
        slot.performance = _perform(
          slot,
          strokeDuration: performance.timeline.strokeDuration,
          brush: identical(slot, _masterSlot) ? _masterBrush : null,
        )..advance(performance.elapsed);
      }
    }
  }

  /// Advances every slot by [dt] of ticker time. Returns how many strokes
  /// started, which is when the brush rustles on the paper.
  int advance(Duration dt) {
    // A slot whose character is no longer at its offset means the document
    // changed behind the tracker's back: reveal everything.
    final text = _plainText();
    if (slots.any((slot) => slot.offset >= text.length || !text.startsWith(slot.character, slot.offset))) {
      tracker.settleAll();
    }
    _syncSettle();
    for (final slot in slots.where((slot) => slot.geometry == null).toList()) {
      slot.unlocatedFor += dt;
      if (slot.unlocatedFor > locateTimeout) tracker.remove(slot);
    }
    var strokeStarts = 0;
    for (final slot in slots) {
      if (slot.performance?.advance(dt) ?? false) strokeStarts++;
    }
    for (final slot in slots.where((slot) => slot.performance?.isSettled ?? false).toList()) {
      tracker.remove(slot);
    }
    for (final slot in slots) {
      if (slot.isQueued && !slot.isSequential && slot.geometry != null) {
        slot.performance = _perform(slot, strokeDuration: _strokeDuration(slot, catchup: 1.0));
      }
    }
    _advanceMaster(dt);
    notifyListeners();
    return strokeStarts;
  }

  void _advanceMaster(Duration dt) {
    final lagFactor = config().bristleStiffness.lagFactor;

    final writing = _masterSlot;
    if (writing != null) {
      final performance = writing.performance;
      if (performance != null) _masterTip = performance.frame.tip;
      if (writing.isWriting && slots.contains(writing)) {
        _restElapsed = Duration.zero;
        return;
      }
      _masterSlot = null;
    }

    final transit = _transit;
    final target = _transitTarget;
    if (transit != null && target != null) {
      if (slots.contains(target) && identical(target.geometry, _transitGeometry)) {
        _transitElapsed += dt;
        final progress = _transitElapsed.inMicroseconds / _transitDuration.inMicroseconds;
        final frame = transit.frameAt(progress);
        _masterTip = frame.tip;
        _masterLift = frame.liftHeight;
        _masterBrush.follow(
          tip: frame.tip,
          dt: dt,
          lagFactor: InkChoreographyTimeline.transitLagFactor(lagFactor),
          liftHeight: frame.liftHeight,
        );
        if (progress >= 1.0) {
          _endTransit();
          _beginWithMaster(target, catchup: _transitCatchup);
        }
        return;
      }
      // The character it was gliding to is gone or has moved: aim again.
      _endTransit();
    }

    final sequential = slots.where((slot) => slot.isSequential && slot.isQueued);
    if (sequential.isNotEmpty) {
      _restElapsed = Duration.zero;
      final next = sequential.first;
      final geometry = next.geometry;
      if (geometry == null) return;
      final catchup = InkChoreographyTimeline.catchupMult(sequential.length - 1);
      final from = _masterTip;
      if (!_masterBrush.hasLanded || from == null) {
        _beginWithMaster(next, catchup: catchup);
        return;
      }
      final entry = next.strokes.strokes.firstWhere((stroke) => stroke.isNotEmpty).first;
      _transit = InkTransit(from: from, to: InkChoreographyTimeline.mapToGlyphBox(entry, geometry.glyphBox));
      _transitTarget = next;
      _transitGeometry = geometry;
      _transitElapsed = Duration.zero;
      _transitCatchup = catchup;
      _transitDuration = InkChoreographyTimeline.transitDuration(
        speedMultiplier: config().cadence.speedMultiplier,
        catchupMult: catchup,
        replayBoost: next.replayBoost,
      );
      return;
    }

    // Nothing left to write: the brush rests on the paper, then is put away.
    final restingOn = _masterTip;
    if (!_masterBrush.hasLanded || restingOn == null) return;
    _restElapsed += dt;
    if (_restElapsed >= InkChoreographyTimeline.brushRestDuration) {
      _putMasterAway();
    } else {
      _masterBrush.follow(tip: restingOn, dt: dt, lagFactor: lagFactor);
    }
  }

  void _beginWithMaster(InkSlot slot, {required double catchup}) {
    slot.performance = _perform(slot, strokeDuration: _strokeDuration(slot, catchup: catchup), brush: _masterBrush);
    _masterSlot = slot;
    _masterTip = slot.performance!.frame.tip;
  }

  Duration _strokeDuration(InkSlot slot, {required double catchup}) => InkChoreographyTimeline.strokeDuration(
        isCjk: slot.strokes.isCjk,
        speedMultiplier: config().cadence.speedMultiplier,
        catchupMult: catchup,
        replayBoost: slot.replayBoost,
      );

  InkGlyphPerformance _perform(InkSlot slot, {required Duration strokeDuration, BrushKinematics? brush}) =>
      InkGlyphPerformance(
        timeline: InkGlyphTimeline(
          plan: InkGlyphPlan.prepare(
            strokes: slot.strokes.strokes,
            box: slot.geometry!.glyphBox,
            isCjk: slot.strokes.isCjk,
          ),
          strokeDuration: strokeDuration,
        ),
        lagFactor: config().bristleStiffness.lagFactor,
        brush: brush,
      );

  /// The brushes to draw this frame: the master brush while it writes,
  /// glides or rests, and the own brush of every Concurrent Multi-Brush
  /// character.
  List<BrushPose> brushPoses() {
    final poses = <BrushPose>[];
    final textSize = fontSize();
    final masterTip = _masterTip;
    if (_masterBrush.hasLanded && masterTip != null) {
      final masterScale = InkChoreographyTimeline.brushScaleFor(textSize);
      poses.add(
        _masterSlot?.performance?.pose(brushScale: masterScale) ??
            _masterBrush.pose(tip: masterTip, isPressing: false, brushScale: masterScale, liftHeight: _masterLift),
      );
    }
    final localScale = InkChoreographyTimeline.localBrushScaleFor(textSize);
    for (final slot in slots) {
      if (slot.delivery != InkDeliveryMode.multiConcurrent) continue;
      final pose = slot.performance?.pose(brushScale: localScale);
      if (pose != null) poses.add(pose);
    }
    return poses;
  }
}
