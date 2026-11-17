import 'dart:collection';

import 'package:flutter/services.dart';

import '../controllers/stationery_quill_controller.dart';
import 'character_strokes.dart';
import 'hanzi_stroke_table.dart';
import 'ink_choreography_config.dart';
import 'ink_choreography_timeline.dart';
import 'ink_slot.dart';

/// Decides which characters of one Stationery Sheet Ink Choreography writes
/// (SPEC-020 §4) and keeps their queue of [InkSlot]s on the right characters
/// as the diarist goes on editing.
///
/// It hears the sheet's edits as its controller's [StationeryEditObserver]
/// and the IME composing range through [onComposingChanged]:
/// - a committed insertion of [maxAnimatedCharacters] characters or fewer is
///   queued, character by character, when each has strokes;
/// - text typed while the IME composes waits, and is queued when the
///   composing range collapses;
/// - longer insertions, programmatic edits, edits without focus and
///   structural changes queue nothing and settle every slot;
/// - nothing is queued during live typing in `off`.
class InkInsertionTracker implements StationeryEditObserver {
  /// The longest insertion that is written out; anything longer is a paste
  /// or a dictation burst and appears at once.
  static const int maxAnimatedCharacters = 20;

  final InkDeliveryMode Function() _deliveryMode;
  final bool Function() _hasFocus;
  final String Function() _plainText;
  final CharacterStrokes? Function(String character) _strokesFor;
  final VoidCallback? _onChanged;

  /// [deliveryMode] is the saved mode, [hasFocus] whether the sheet's editor
  /// holds focus and [plainText] the sheet's document text. [onChanged] runs
  /// whenever the queue or its offsets change.
  InkInsertionTracker({
    required InkDeliveryMode Function() deliveryMode,
    required bool Function() hasFocus,
    required String Function() plainText,
    CharacterStrokes? Function(String character)? strokesFor,
    VoidCallback? onChanged,
  })  : _deliveryMode = deliveryMode,
        _hasFocus = hasFocus,
        _plainText = plainText,
        _strokesFor = strokesFor ?? HanziStrokeTable.instance.strokesFor,
        _onChanged = onChanged;

  final List<InkSlot> _slots = [];
  bool _isComposing = false;

  /// The document range the composition in flight has inserted so far.
  int? _pendingStart;
  int _pendingEnd = 0;
  int _settleCount = 0;

  /// The characters waiting to be written or being written, oldest first.
  late final List<InkSlot> slots = UnmodifiableListView(_slots);

  /// How many times every slot was settled at once. A change tells the
  /// overlay to put its brush away immediately.
  int get settleCount => _settleCount;

  /// Whether a full-sheet replay (全页挥毫) is still running.
  bool get isReplaying => _slots.any((slot) => slot.isReplay);

  /// The sheet's IME composing range changed. When it collapses, the text
  /// the composition inserted is committed.
  void onComposingChanged(TextRange composing) {
    final isComposing = composing.isValid && !composing.isCollapsed;
    if (isComposing == _isComposing) return;
    _isComposing = isComposing;
    if (isComposing) return;

    final pendingStart = _pendingStart;
    _pendingStart = null;
    if (pendingStart == null || !_hasFocus()) return;
    final text = _plainText();
    final start = pendingStart.clamp(0, text.length);
    final end = _pendingEnd.clamp(start, text.length);
    final settledBefore = _settleCount;
    final didQueue = _enqueueCommitted(start, text.substring(start, end));
    if (didQueue || _settleCount != settledBefore) _onChanged?.call();
  }

  @override
  void onTextReplaced(int index, int deletedLength, String insertedText, {required bool ignoreFocus}) {
    final wasReplaying = isReplaying;
    if (wasReplaying || ignoreFocus || !_hasFocus()) _settle();
    final insertedLength = insertedText.length;
    final deletedEnd = index + deletedLength;
    final shift = insertedLength - deletedLength;

    _slots.removeWhere((slot) => slot.offset >= index && slot.offset < deletedEnd);
    for (final slot in _slots) {
      if (slot.offset >= deletedEnd) slot.offset += shift;
      slot.needsLocating = true;
    }
    final pendingStart = _pendingStart;
    if (pendingStart != null) {
      int moved(int position) => position < index ? position : (position >= deletedEnd ? position + shift : index);
      _pendingStart = moved(pendingStart);
      _pendingEnd = moved(_pendingEnd);
    }

    if (!ignoreFocus && _hasFocus()) {
      if (_isComposing) {
        if (insertedLength > 0) {
          final start = _pendingStart;
          _pendingStart = start == null || index < start ? index : start;
          _pendingEnd = start == null || index + insertedLength > _pendingEnd ? index + insertedLength : _pendingEnd;
        }
      } else {
        _enqueueCommitted(index, insertedText);
      }
    }
    _onChanged?.call();
  }

  @override
  void onStructuralChange() => settleAll();

  /// Settles every slot at once: the printed glyphs stand on their own.
  void settleAll() {
    if (_settle()) _onChanged?.call();
  }

  /// Starts a full-sheet replay (全页挥毫): every character with strokes, in
  /// document order, as a boosted Single Fluent Brush whatever the saved
  /// mode is.
  void replay() {
    _settle();
    _enqueue(
      0,
      _plainText(),
      delivery: InkDeliveryMode.singleFluent,
      replayBoost: InkChoreographyTimeline.replayBoost,
    );
    _onChanged?.call();
  }

  /// Takes a settled [slot] off the queue.
  void remove(InkSlot slot) => _slots.remove(slot);

  bool _settle() {
    _pendingStart = null;
    if (_slots.isEmpty) return false;
    _slots.clear();
    _settleCount++;
    return true;
  }

  /// Queues committed [text] standing at [start] under the saved mode, when
  /// it is short enough to be written out. Returns whether anything queued.
  bool _enqueueCommitted(int start, String text) {
    final mode = _deliveryMode();
    if (mode == InkDeliveryMode.off || text.isEmpty) return false;
    if (text.runes.length > maxAnimatedCharacters) {
      // A paste or dictation burst: structural, so nothing is left waiting.
      _settle();
      return false;
    }
    return _enqueue(start, text, delivery: mode);
  }

  bool _enqueue(int start, String text, {required InkDeliveryMode delivery, double replayBoost = 1.0}) {
    final queuedBefore = _slots.length;
    var offset = start;
    for (final rune in text.runes) {
      final character = String.fromCharCode(rune);
      final strokes = _strokesFor(character);
      if (strokes != null && strokes.strokes.isNotEmpty) {
        _slots.add(
          InkSlot(
            offset: offset,
            character: character,
            strokes: strokes,
            delivery: delivery,
            replayBoost: replayBoost,
          ),
        );
      }
      offset += character.length;
    }
    return _slots.length > queuedBefore;
  }
}
