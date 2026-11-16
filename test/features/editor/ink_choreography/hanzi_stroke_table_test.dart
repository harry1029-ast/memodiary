
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/ink_choreography/curated_strokes.dart';
import 'package:memodiary/features/editor/ink_choreography/hanzi_stroke_table.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('without an asset loaded', () {
    final table = HanziStrokeTable();

    test('resolves curated entries synchronously', () {
      final strokes = table.strokesFor('A')!;
      expect(strokes.isCjk, isFalse);
      expect(strokes.strokes.length, curatedStrokes['A']!.length);
      expect(strokes.strokes.first.first, const Offset(50, 15));
    });

    test('procedural fallback is deterministic for unindexed CJK', () {
      final first = table.strokesFor('丁')!;
      final second = table.strokesFor('丁')!;
      expect(first.isCjk, isTrue);
      expect(first.strokes.length, 6);
      expect(
        [for (final stroke in second.strokes) ...stroke],
        [for (final stroke in first.strokes) ...stroke],
      );
      final other = table.strokesFor('丂')!;
      expect(
        [for (final stroke in other.strokes) ...stroke],
        isNot([for (final stroke in first.strokes) ...stroke]),
      );
    });

    test('returns null for emoji, Cyrillic, whitespace and embeds', () {
      for (final char in ['😀', 'Ж', ' ', '\n', '￼', '', 'ab', 'あ']) {
        expect(table.strokesFor(char), isNull, reason: 'U+${char.runes}');
      }
    });
  });

  group('load', () {
    test('rejects a corrupt asset, stays on the fallback and logs once', () {
      final table = HanziStrokeTable();
      final bad = ByteData.sublistView(Uint8List.fromList(List.filled(32, 7)));
      expect(table.loadFromBytes(bad), isFalse);
      expect(table.loadFromBytes(bad), isFalse);
      expect(table.isLoaded, isFalse);
      expect(table.strokesFor('A'), isNotNull);
    });
  });

  group('committed asset', () {
    late HanziStrokeTable table;

    setUpAll(() async {
      table = HanziStrokeTable();
      await table.load(rootBundle);
    });

    test('loads and validates', () => expect(table.isLoaded, isTrue));

    test('resolves authentic Hanzi with real strokes', () {
      expect(table.strokesFor('永')!.strokes.length, 5);
      expect(table.strokesFor('墨')!.strokes.length, 15);
      expect(table.strokesFor('龍')!.strokes.length, 16);
      expect(table.strokesFor('書')!.strokes.length, 10);
      for (final char in ['永', '墨', '龍', '書']) {
        final strokes = table.strokesFor(char)!;
        expect(strokes.isCjk, isTrue);
        for (final stroke in strokes.strokes) {
          expect(stroke.length, inInclusiveRange(2, 32));
          for (final point in stroke) {
            expect(point.dx, inInclusiveRange(0, 100));
            expect(point.dy, inInclusiveRange(0, 100));
          }
        }
      }
    });

    test('resolves every curated key', () {
      for (final char in curatedStrokes.keys) {
        expect(table.strokesFor(char), isNotNull, reason: char);
      }
      expect(table.strokesFor('。')!.isCjk, isFalse);
    });

    test('returns null for emoji and Cyrillic', () {
      expect(table.strokesFor('😀'), isNull);
      expect(table.strokesFor('Ж'), isNull);
    });
  });
}
