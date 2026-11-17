import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/features/editor/ink_choreography/ink_choreography_config.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_choreography_timeline.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_insertion_tracker.dart';

/// A sheet's text as the tracker sees it: edits are applied to [text] and
/// then reported, the way `StationeryQuillController` reports them.
class _Sheet {
  String text = '\n';
  InkDeliveryMode mode = InkDeliveryMode.singleFluent;
  bool hasFocus = true;
  int changes = 0;

  late final InkInsertionTracker tracker = InkInsertionTracker(
    deliveryMode: () => mode,
    hasFocus: () => hasFocus,
    plainText: () => text,
    onChanged: () => changes++,
  );

  void replace(int index, int deleted, String inserted, {bool ignoreFocus = false}) {
    text = text.replaceRange(index, index + deleted, inserted);
    tracker.onTextReplaced(index, deleted, inserted, ignoreFocus: ignoreFocus);
  }

  void compose(int start, int end) => tracker.onComposingChanged(TextRange(start: start, end: end));
  void endComposing() => tracker.onComposingChanged(TextRange.empty);

  /// The queued characters with their offsets, e.g. `你@0 好@1`.
  String get queued => tracker.slots.map((slot) => '${slot.character}@${slot.offset}').join(' ');
}

void main() {
  late _Sheet sheet;

  setUp(() => sheet = _Sheet());

  group('insertions with no composition in flight', () {
    test('a short insertion queues each of its characters at its offset', () {
      sheet.replace(0, 0, '你好');

      expect(sheet.queued, '你@0 好@1');
      expect(sheet.changes, 1);
    });

    test('twenty characters are queued; twenty-one (a paste) are not', () {
      sheet.replace(0, 0, 'a' * 20);
      expect(sheet.tracker.slots, hasLength(20));

      final pasted = _Sheet()..replace(0, 0, 'a' * 21);
      expect(pasted.tracker.slots, isEmpty);
    });

    test('only characters with strokes are queued: no whitespace, emoji or other scripts', () {
      sheet.replace(0, 0, 'a 😀я\n永');

      // The emoji is two UTF-16 units, so 永 stands at offset 6.
      expect(sheet.queued, 'a@0 永@6');
    });

    test('each slot carries the saved delivery mode and no replay boost', () {
      sheet.mode = InkDeliveryMode.multiConcurrent;
      sheet.replace(0, 0, '永');

      expect(sheet.tracker.slots.single.delivery, InkDeliveryMode.multiConcurrent);
      expect(sheet.tracker.slots.single.replayBoost, 1.0);
    });

    test('off queues nothing', () {
      sheet.mode = InkDeliveryMode.off;
      sheet.replace(0, 0, '你好');

      expect(sheet.tracker.slots, isEmpty);
    });
  });

  group('later edits', () {
    setUp(() => sheet.replace(0, 0, '山高水长'));

    test('an insertion before a queued character shifts it; one after leaves it', () {
      sheet.replace(2, 0, '云');

      expect(sheet.queued, '山@0 高@1 水@3 长@4 云@2');
    });

    test('a deletion drops the slots inside it and pulls later ones back', () {
      sheet.replace(1, 2, '');

      expect(sheet.queued, '山@0 长@1');
    });

    test('a replacement drops what it deletes and queues what it inserts', () {
      sheet.replace(1, 1, '远');

      expect(sheet.queued, '山@0 水@2 长@3 远@1');
    });
  });

  group('settling', () {
    setUp(() => sheet.replace(0, 0, '山高'));

    test('a programmatic (ignoreFocus) edit settles every slot and queues nothing', () {
      sheet.replace(2, 0, '水', ignoreFocus: true);

      expect(sheet.tracker.slots, isEmpty);
      expect(sheet.tracker.settleCount, 1);
    });

    test('an edit while the sheet has no focus settles every slot and queues nothing', () {
      sheet.hasFocus = false;
      sheet.replace(2, 0, '水');

      expect(sheet.tracker.slots, isEmpty);
    });

    test('a structural change settles every slot', () {
      sheet.tracker.onStructuralChange();

      expect(sheet.tracker.slots, isEmpty);
      expect(sheet.tracker.settleCount, 1);
    });

    test('a paste longer than twenty characters settles every slot and queues nothing', () {
      sheet.replace(2, 0, 'a' * 21);

      expect(sheet.tracker.slots, isEmpty);
      expect(sheet.tracker.settleCount, 1);
    });

    test('settling an idle sheet changes nothing', () {
      final idle = _Sheet();
      idle.tracker.settleAll();

      expect(idle.changes, 0);
      expect(idle.tracker.settleCount, 0);
    });
  });

  group('IME composition', () {
    test('text typed while composing is not queued until the composing range collapses', () {
      sheet.compose(0, 1);
      sheet.replace(0, 0, 'n');
      sheet.compose(0, 2);
      sheet.replace(1, 0, 'i');
      expect(sheet.tracker.slots, isEmpty);

      sheet.endComposing();
      expect(sheet.queued, 'n@0 i@1');
    });

    test('a candidate committed in one update queues the committed phrase, not the raw input', () {
      sheet.compose(0, 2);
      sheet.replace(0, 0, 'ni');

      // Quill clears the composing range before it applies the committed text.
      sheet.endComposing();
      sheet.replace(0, 2, '你');

      expect(sheet.queued, '你@0');
    });

    test('a Latin word held in the composing region is queued whole when it commits', () {
      for (var length = 1; length <= 5; length++) {
        sheet.compose(0, length);
        sheet.replace(length - 1, 0, 'hello'[length - 1]);
      }
      sheet.endComposing();
      sheet.replace(5, 0, ' ');

      expect(sheet.queued, 'h@0 e@1 l@2 l@3 o@4');
    });

    test('a committed composition longer than twenty characters is dropped', () {
      sheet.compose(0, 21);
      sheet.replace(0, 0, 'a' * 21);
      sheet.endComposing();

      expect(sheet.tracker.slots, isEmpty);
    });

    test('recomposing an existing word queues only what the composition inserted', () {
      sheet.replace(0, 0, 'helo', ignoreFocus: true);

      sheet.compose(0, 4);
      sheet.replace(3, 0, 'l');
      sheet.compose(0, 5);
      sheet.endComposing();

      expect(sheet.queued, 'l@3');
    });

    test('a composition committed in off queues nothing', () {
      sheet.mode = InkDeliveryMode.off;
      sheet.compose(0, 1);
      sheet.replace(0, 0, 'n');
      sheet.endComposing();

      expect(sheet.tracker.slots, isEmpty);
    });
  });

  group('full-sheet replay', () {
    setUp(() {
      sheet.mode = InkDeliveryMode.off;
      sheet.replace(0, 0, '山高 a\n水长', ignoreFocus: true);
    });

    test('queues every character with strokes in document order as a boosted Single Fluent Brush', () {
      sheet.tracker.replay();

      expect(sheet.queued, '山@0 高@1 a@3 水@5 长@6');
      expect(sheet.tracker.isReplaying, isTrue);
      for (final slot in sheet.tracker.slots) {
        expect(slot.delivery, InkDeliveryMode.singleFluent);
        expect(slot.replayBoost, InkChoreographyTimeline.replayBoost);
      }
    });

    test('a keystroke cancels the replay and is itself queued under the saved mode', () {
      sheet.mode = InkDeliveryMode.inkOnly;
      sheet.tracker.replay();

      sheet.replace(7, 0, '云');

      expect(sheet.queued, '云@7');
      expect(sheet.tracker.isReplaying, isFalse);
      expect(sheet.tracker.slots.single.delivery, InkDeliveryMode.inkOnly);
    });

    test('a keystroke in off cancels the replay and queues nothing', () {
      sheet.tracker.replay();
      sheet.replace(7, 0, '云');

      expect(sheet.tracker.slots, isEmpty);
    });

    test('the replay is over once its last slot is taken off the queue', () {
      sheet.tracker.replay();
      for (final slot in sheet.tracker.slots.toList()) {
        sheet.tracker.remove(slot);
      }

      expect(sheet.tracker.isReplaying, isFalse);
    });
  });
}
