import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/ink_choreography/curated_strokes.dart';

const _capitals = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const _lowercase = 'abcdefghijklmnopqrstuvwxyz';
const _digits = '0123456789';
const _punctuation = '，。、·！？；：“”‘’.,!?-';

Iterable<List<int>> _allPoints() => curatedStrokes.values
    .expand((strokes) => strokes)
    .expand((stroke) => stroke);

void main() {
  test('covers exactly Latin letters, digits and the spec punctuation', () {
    final expected = '$_capitals$_lowercase$_digits$_punctuation'.split('');

    expect(expected, hasLength(79));
    expect(curatedStrokes.keys.toSet(), expected.toSet());
  });

  test('every glyph is written in one to four strokes', () {
    for (final entry in curatedStrokes.entries) {
      expect(entry.value.length, inInclusiveRange(1, 4), reason: entry.key);
    }
  });

  test('every stroke is a polyline of 2 to 32 points', () {
    for (final entry in curatedStrokes.entries) {
      for (final stroke in entry.value) {
        expect(stroke.length, inInclusiveRange(2, 32), reason: entry.key);
      }
    }
  });

  test('every point is an [x, y] pair inside the 0..100 box', () {
    for (final point in _allPoints()) {
      expect(point, hasLength(2));
      expect(point[0], inInclusiveRange(0, 100));
      expect(point[1], inInclusiveRange(0, 100));
    }
  });

  test('no stroke repeats a point back to back', () {
    for (final entry in curatedStrokes.entries) {
      for (final stroke in entry.value) {
        for (var i = 1; i < stroke.length; i++) {
          expect(stroke[i], isNot(equals(stroke[i - 1])), reason: entry.key);
        }
      }
    }
  });

  test('lowercase letters are real forms, not their capitals', () {
    for (final lower in _lowercase.split('')) {
      expect(
        curatedStrokes[lower],
        isNot(equals(curatedStrokes[lower.toUpperCase()])),
        reason: lower,
      );
    }
  });

  test('capitals and digits span cap height down to the baseline', () {
    for (final char in '$_capitals$_digits'.split('')) {
      final ys = curatedStrokes[char]!
          .expand((stroke) => stroke)
          .map((point) => point[1])
          .toList()
        ..sort();

      expect(ys.first, inInclusiveRange(14, 18), reason: char);
      expect(ys.last, inInclusiveRange(82, 90), reason: char);
    }
  });
}
