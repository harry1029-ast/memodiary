import 'dart:ui';

import 'character_strokes.dart';
import 'ink_choreography_config.dart';
import 'ink_glyph_performance.dart';

/// Where one character stands on its Stationery Sheet, in the ink layer's
/// coordinates.
class InkGlyphGeometry {
  /// The glyph's advance across the full ruled row it stands on: what the
  /// paper mask covers.
  final Rect maskRect;

  /// The rect the character's `0..100` stroke box maps onto.
  final Rect glyphBox;

  const InkGlyphGeometry({required this.maskRect, required this.glyphBox});

  /// Whether [other] is the same place to within a hairline, so a character
  /// laid out for it need not be laid out again.
  bool isCloseTo(InkGlyphGeometry other) =>
      _isClose(maskRect, other.maskRect) && _isClose(glyphBox, other.glyphBox);

  static bool _isClose(Rect first, Rect second) =>
      (first.left - second.left).abs() < 0.01 &&
      (first.top - second.top).abs() < 0.01 &&
      (first.right - second.right).abs() < 0.01 &&
      (first.bottom - second.bottom).abs() < 0.01;
}

/// One character Ink Choreography is to write on a Stationery Sheet. Queued
/// until its [performance] starts; settled slots leave the queue.
class InkSlot {
  /// The character's offset in the sheet's document, kept current as the
  /// diarist edits around it.
  int offset;
  final String character;
  final CharacterStrokes strokes;

  /// How this character is delivered: the saved mode when it was typed, or
  /// Single Fluent Brush in a full-sheet replay.
  final InkDeliveryMode delivery;

  /// `InkChoreographyTimeline.replayBoost` in a full-sheet replay, else 1.
  final double replayBoost;

  /// Where the glyph stands, once the editor has laid it out.
  InkGlyphGeometry? geometry;

  /// Whether [geometry] must be looked up (again): the slot is new, or an
  /// edit may have moved its glyph.
  bool needsLocating = true;

  /// How long the slot has gone without a [geometry].
  Duration unlocatedFor = Duration.zero;

  /// The character being written; null while it waits in the queue.
  InkGlyphPerformance? performance;

  InkSlot({
    required this.offset,
    required this.character,
    required this.strokes,
    required this.delivery,
    this.replayBoost = 1.0,
  });

  bool get isReplay => replayBoost != 1.0;
  bool get isQueued => performance == null;

  /// Whether the strokes are still being inked (not yet settling).
  bool get isWriting => performance?.frame.isWriting ?? false;

  /// Whether this character waits its turn behind the sheet's master brush.
  bool get isSequential => delivery == InkDeliveryMode.singleFluent;
}
