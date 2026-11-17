import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/features/editor/ink_choreography/ink_choreography_config.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_choreography_timeline.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_slot.dart';
import 'package:memodiary/features/editor/ink_choreography/sheet_ink_choreographer.dart';

const _frame = Duration(milliseconds: 16);
const _cell = 20.0;

/// A sheet of [_cell]-wide glyphs on one row, written by a choreographer
/// that is stepped and "painted" by hand.
class _Stage {
  String text = '\n';
  InkChoreographyConfig config;
  int wakes = 0;
  int strokeStarts = 0;

  /// How far every glyph is pushed right, as after an edit before it.
  double indent = 0.0;

  /// Whether the editor can say where glyphs stand.
  bool isLaidOut = true;

  _Stage(InkDeliveryMode mode) : config = InkChoreographyConfig(deliveryMode: mode);

  late final SheetInkChoreographer ink = SheetInkChoreographer(
    config: () => config,
    fontSize: () => _cell,
    locate: (slot) {
      if (!isLaidOut) return null;
      final left = indent + slot.offset * _cell;
      return InkGlyphGeometry(
        maskRect: Rect.fromLTWH(left, 0, _cell, 30),
        glyphBox: Rect.fromLTWH(left, 5, _cell, _cell),
      );
    },
    hasFocus: () => true,
    plainText: () => text,
    onWake: () => wakes++,
  );

  void type(String inserted) {
    final index = text.length - 1;
    text = text.replaceRange(index, index, inserted);
    ink.tracker.onTextReplaced(index, 0, inserted, ignoreFocus: false);
    ink.resolveGeometry();
  }

  /// One frame: the ticker's tick, then the layer's paint.
  void frame([Duration dt = _frame]) {
    strokeStarts += ink.advance(dt);
    ink.resolveGeometry();
  }

  /// Steps frames until [isDone], failing after [limit] of animation time.
  void framesUntil(bool Function() isDone, {Duration limit = const Duration(seconds: 30)}) {
    var elapsed = Duration.zero;
    while (!isDone()) {
      frame();
      elapsed += _frame;
      if (elapsed > limit) fail('still animating after $limit');
    }
  }

  String get writing => ink.slots.where((slot) => slot.isWriting).map((slot) => slot.character).join();
  String get queued => ink.slots.where((slot) => slot.isQueued).map((slot) => slot.character).join();
}

void main() {
  group('Single Fluent Brush', () {
    test('writes the queue one character at a time under one master brush', () {
      final stage = _Stage(InkDeliveryMode.singleFluent)..type('山水');
      expect(stage.wakes, 1);

      stage.frame();
      stage.frame();
      expect(stage.writing, '山');
      expect(stage.queued, '水');
      expect(stage.ink.brushPoses(), hasLength(1));
      expect(stage.ink.brushPoses().single.isPressing, isTrue);
    });

    test('glides to the next character on a lifted transit with a silk trace, then writes it', () {
      final stage = _Stage(InkDeliveryMode.singleFluent)..type('山水');

      stage.framesUntil(() => stage.ink.silkTrace != null);
      final transit = stage.ink.silkTrace!;
      expect(stage.queued, '水');
      expect(transit.showsSilkTrace, isTrue);
      expect(transit.to.dx, inInclusiveRange(_cell, 2 * _cell), reason: 'aims at the first stroke of 水');

      stage.frame();
      stage.frame();
      final gliding = stage.ink.brushPoses().single;
      expect(gliding.isPressing, isFalse);
      expect(gliding.liftHeight, greaterThan(0));

      stage.framesUntil(() => stage.writing == '水');
      expect(stage.ink.silkTrace, isNull);
      expect(stage.ink.brushPoses().single.liftHeight, 0);
    });

    test('speeds up while characters wait: 2.6x with six or more behind, 1x for the last', () {
      final stage = _Stage(InkDeliveryMode.singleFluent)..type('一二三四五六七');
      stage.frame();
      stage.frame();

      final first = stage.ink.slots.first;
      expect(
        first.performance!.timeline.strokeDuration,
        InkChoreographyTimeline.strokeDuration(isCjk: true, speedMultiplier: 1.0, catchupMult: 2.6),
      );

      stage.framesUntil(() => stage.writing == '七');
      expect(
        stage.ink.slots.last.performance!.timeline.strokeDuration,
        InkChoreographyTimeline.strokeDuration(isCjk: true, speedMultiplier: 1.0),
      );
    });

    test('rests the brush while the last character settles, then puts it away with an empty queue', () {
      final stage = _Stage(InkDeliveryMode.singleFluent)..type('A');
      stage.frame();
      stage.framesUntil(() => stage.writing.isEmpty);

      expect(stage.ink.slots, hasLength(1), reason: 'the wet ink is still settling');
      expect(stage.ink.brushPoses().single.isPressing, isFalse);

      stage.framesUntil(() => stage.ink.isIdle, limit: const Duration(milliseconds: 400));
      expect(stage.ink.slots, isEmpty);
      expect(stage.ink.brushPoses(), isEmpty);
      expect(stage.strokeStarts, 3, reason: 'one rustle per stroke of the curated A');
    });

    test('a glyph moved by an edit before it goes on being written where it now stands', () {
      final stage = _Stage(InkDeliveryMode.singleFluent)..type('山');
      stage.frame();
      stage.frame();
      final before = stage.ink.brushPoses().single.tip;

      stage.indent = 40;
      stage.ink.tracker.onTextReplaced(0, 0, '', ignoreFocus: false);
      stage.ink.resolveGeometry();
      stage.frame();

      expect(stage.writing, '山');
      expect(stage.ink.slots.single.geometry!.maskRect.left, 40);
      expect(stage.ink.brushPoses().single.tip.dx, greaterThan(before.dx + 30));
    });
  });

  test('Concurrent Multi-Brush writes every character at once, each with its own brush', () {
    final stage = _Stage(InkDeliveryMode.multiConcurrent)..type('山水');
    stage.frame();
    stage.frame();

    expect(stage.writing, '山水');
    expect(stage.ink.brushPoses(), hasLength(2));
    expect(stage.ink.silkTrace, isNull);

    stage.framesUntil(() => stage.ink.isIdle);
  });

  test('Ink-Only Bloom writes every character at once with no brush', () {
    final stage = _Stage(InkDeliveryMode.inkOnly)..type('山水');
    stage.frame();
    stage.frame();

    expect(stage.writing, '山水');
    expect(stage.ink.brushPoses(), isEmpty);
  });

  test('a full-sheet replay runs as a boosted Single Fluent Brush whatever the saved mode', () {
    final stage = _Stage(InkDeliveryMode.off)..text = '山水\n';
    stage.ink.replay();
    stage.ink.resolveGeometry();
    stage.frame();
    stage.frame();

    expect(stage.ink.isReplaying, isTrue);
    expect(stage.writing, '山');
    expect(
      stage.ink.slots.first.performance!.timeline.strokeDuration,
      InkChoreographyTimeline.strokeDuration(
        isCjk: true,
        speedMultiplier: 1.0,
        catchupMult: 1.35,
        replayBoost: InkChoreographyTimeline.replayBoost,
      ),
    );
    expect(stage.config.deliveryMode, InkDeliveryMode.off);
  });

  test('settling everything reveals all characters and puts the brush away in one step', () {
    final stage = _Stage(InkDeliveryMode.singleFluent)..type('山水');
    stage.frame();
    stage.frame();

    stage.ink.settleAll();

    expect(stage.ink.slots, isEmpty);
    expect(stage.ink.isIdle, isTrue);
    expect(stage.ink.brushPoses(), isEmpty);
  });

  test('characters the editor never lays out are given up on rather than waited for forever', () {
    final stage = _Stage(InkDeliveryMode.singleFluent)..isLaidOut = false;
    stage.type('山水');

    stage.frame();
    expect(stage.ink.slots, hasLength(2), reason: 'a late layout is waited for');

    stage.framesUntil(() => stage.ink.isIdle, limit: const Duration(seconds: 1));
    expect(stage.ink.slots, isEmpty);
  });

  test('a character that is no longer at its offset settles everything', () {
    final stage = _Stage(InkDeliveryMode.singleFluent)..type('山水');
    stage.frame();

    stage.text = '云\n';
    stage.frame();

    expect(stage.ink.slots, isEmpty);
    expect(stage.ink.isIdle, isTrue);
  });
}
