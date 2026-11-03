import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/services/stationery_delta_splitter.dart';

void main() {
  group('StationeryDeltaSplitter Tests', () {
    const typography = TypographySettings(fontSize: 16.0, lineSpacing: 1.5);

    test('splitDeltaAtCharacterOffset preserves inline formatting across cut point', () {
      final delta = Delta()
        ..insert('前段文字', {'bold': true, 'color': '#FF0000'})
        ..insert('中段文字', {'italic': true})
        ..insert('后段文字\n');

      // Cut at offset 6 (middle of '中段文字', which starts at offset 4 and has 4 chars)
      // '前段文字' is 4 chars. Offset 6 cuts '中段' and '文字'
      final split = StationeryDeltaSplitter.splitDeltaAtCharacterOffset(
        sourceDelta: delta,
        splitOffset: 6,
      );

      // First slice has: '前段文字' (bold+red), '中段' (italic), and soft '\n'
      expect(split.hasTrailingSoftNewline, isTrue);
      expect(split.firstSlice.operations.length, equals(3));
      expect(split.firstSlice.operations[0].data, equals('前段文字'));
      expect(split.firstSlice.operations[0].attributes?['bold'], isTrue);
      expect(split.firstSlice.operations[1].data, equals('中段'));
      expect(split.firstSlice.operations[1].attributes?['italic'], isTrue);
      expect(split.firstSlice.operations[2].data, equals('\n'));

      // Second slice has: '文字' (italic), '后段文字\n'
      expect(split.secondSlice.operations[0].data, equals('文字'));
      expect(split.secondSlice.operations[0].attributes?['italic'], isTrue);
      expect(split.secondSlice.operations[1].data, equals('后段文字\n'));
    });

    test('mergeDeltaSlices strips soft newline and losslessly reunites continuous text', () {
      final delta = Delta()
        ..insert('前段文字', {'bold': true})
        ..insert('中段文字', {'italic': true})
        ..insert('后段文字\n');

      final split = StationeryDeltaSplitter.splitDeltaAtCharacterOffset(
        sourceDelta: delta,
        splitOffset: 6,
      );

      final merged = StationeryDeltaSplitter.mergeDeltaSlices(
        firstSlice: split.firstSlice,
        secondSlice: split.secondSlice,
        firstSliceHasSoftNewline: split.hasTrailingSoftNewline,
      );

      // Merged delta must be 100% equivalent to original delta
      expect(merged.toJson(), equals(delta.toJson()));
    });

    test('splitDeltaAtCharacterOffset does not cut through emoji surrogate pairs', () {
      final delta = Delta()
        ..insert('诗意🌸墨韵\n');

      // '诗意' is 2 chars. '🌸' is 2 code units at indices 2 and 3.
      // Requesting cut at offset 3 (inside the emoji) must safely back off to 2.
      final split = StationeryDeltaSplitter.splitDeltaAtCharacterOffset(
        sourceDelta: delta,
        splitOffset: 3,
      );

      // First slice should have '诗意\n' (with soft newline merged by Delta)
      expect(split.firstSlice.operations[0].data, equals('诗意\n'));
      expect(split.hasTrailingSoftNewline, isTrue);

      // Second slice should have the whole emoji '🌸墨韵\n'
      expect(split.secondSlice.operations[0].data, equals('🌸墨韵\n'));

      // Re-merging must be lossless
      final merged = StationeryDeltaSplitter.mergeDeltaSlices(
        firstSlice: split.firstSlice,
        secondSlice: split.secondSlice,
        firstSliceHasSoftNewline: split.hasTrailingSoftNewline,
      );
      expect(merged.toJson(), equals(delta.toJson()));
    });

    test('extractOverflow extracts trailing lines when rows exceed capacity', () {
      // 10 lines of 17 chars fits in 10 rows. 15 lines has 5 rows overflow.
      final delta = Delta();
      for (int i = 1; i <= 15; i++) {
        delta.insert('第${i.toString().padLeft(2, '0')}行测试内容文字字\n'); // 11 chars + '\n' = 1 row each
      }

      final overflow = StationeryDeltaSplitter.extractOverflow(
        sheetDelta: delta,
        rowCapacity: 10,
        typography: typography,
        contentWidth: null, // unconstrained 17 chars/row
      );

      // Remaining delta should have 10 lines
      final remainingLines = (overflow.remainingDelta.operations
              .map((op) => op.data.toString())
              .join(''))
          .trim()
          .split('\n');
      expect(remainingLines.length, equals(10));
      expect(remainingLines.first, contains('第01行'));
      expect(remainingLines.last, contains('第10行'));

      // Overflowing delta should have 5 lines
      final overflowingLines = (overflow.overflowingDelta.operations
              .map((op) => op.data.toString())
              .join(''))
          .trim()
          .split('\n');
      expect(overflowingLines.length, equals(5));
      expect(overflowingLines.first, contains('第11行'));
      expect(overflowingLines.last, contains('第15行'));
    });
  });
}
