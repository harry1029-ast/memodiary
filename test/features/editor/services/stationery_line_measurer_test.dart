import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/services/stationery_line_measurer.dart';
import 'package:memodiary/features/templates/models/template_style.dart';

void main() {
  group('StationeryLineMeasurer Tests', () {
    const typography = TypographySettings(fontSize: 16.0, lineSpacing: 1.5);

    test('calculateRowWeight assigns 2 rows per line for H1 and H2, 1 row for others', () {
      expect(StationeryLineMeasurer.calculateRowWeight({'header': 1}), equals(2));
      expect(StationeryLineMeasurer.calculateRowWeight({'header': 2}), equals(2));
      expect(StationeryLineMeasurer.calculateRowWeight({'header': 3}), equals(1));
      expect(StationeryLineMeasurer.calculateRowWeight({'blockquote': true}), equals(1));
      expect(StationeryLineMeasurer.calculateRowWeight({'list': 'bullet'}), equals(1));
      expect(StationeryLineMeasurer.calculateRowWeight({'list': 'ordered'}), equals(1));
      expect(StationeryLineMeasurer.calculateRowWeight({'list': 'checked'}), equals(1));
      expect(StationeryLineMeasurer.calculateRowWeight({'list': 'unchecked'}), equals(1));
      expect(StationeryLineMeasurer.calculateRowWeight(null), equals(1));
    });

    test('H1 and H2 headings occupy 2 rows per wrapped line in unconstrained fallback', () {
      // 10 chars fits in 1 line (< 17 chars). H1 has rowWeight 2 -> 2 rows.
      final h1Short = StationeryLineMeasurer.measureParagraph(
        text: '简短的一级标题\n',
        blockAttributes: {'header': 1},
        typography: typography,
        contentWidth: null, // unconstrained fallback
      );
      expect(h1Short.wrappedLines, equals(1));
      expect(h1Short.rowWeight, equals(2));
      expect(h1Short.totalRows, equals(2));

      // 34 chars wraps to 2 lines (17 chars per line). H2 has rowWeight 2 -> 4 rows.
      final h2Long = StationeryLineMeasurer.measureParagraph(
        text: '一二三四五六七八九十一二三四五六七一二三四五六七八九十一二三四五六七\n', // Exactly 34 chars
        blockAttributes: {'header': 2},
        typography: typography,
        contentWidth: null,
      );
      expect(h2Long.wrappedLines, equals(2));
      expect(h2Long.rowWeight, equals(2));
      expect(h2Long.totalRows, equals(4));
    });

    test('H3, body, quotes, lists occupy 1 row per wrapped line', () {
      final h3 = StationeryLineMeasurer.measureParagraph(
        text: '三级标题\n',
        blockAttributes: {'header': 3},
        typography: typography,
        contentWidth: null,
      );
      expect(h3.wrappedLines, equals(1));
      expect(h3.rowWeight, equals(1));
      expect(h3.totalRows, equals(1));

      final body = StationeryLineMeasurer.measureParagraph(
        text: '普通正文段落文字\n',
        typography: typography,
        contentWidth: null,
      );
      expect(body.wrappedLines, equals(1));
      expect(body.rowWeight, equals(1));
      expect(body.totalRows, equals(1));

      final quote = StationeryLineMeasurer.measureParagraph(
        text: '引述名家经典语句\n',
        blockAttributes: {'blockquote': true},
        typography: typography,
        contentWidth: null,
      );
      expect(quote.wrappedLines, equals(1));
      expect(quote.rowWeight, equals(1));
      expect(quote.totalRows, equals(1));
    });

    test('{夹注:...} Interlinear Sub-Notes occupy 1 row per wrapped line', () {
      final jiazhu = StationeryLineMeasurer.measureParagraph(
        text: '正文文字{夹注:侧室双行夹注小字}继续书写\n',
        typography: typography,
        contentWidth: null,
      );
      expect(jiazhu.rowWeight, equals(1));
      expect(jiazhu.totalRows, equals(jiazhu.wrappedLines * 1));
    });

    test('Unconstrained fallback calculates lines strictly at 17 chars per row', () {
      // 17 characters -> 1 line
      final line17 = StationeryLineMeasurer.measureParagraph(
        text: '一二三四五六七八九十一二三四五六七\n',
        typography: typography,
        contentWidth: null,
      );
      expect(line17.wrappedLines, equals(1));

      // 18 characters -> 2 lines
      final line18 = StationeryLineMeasurer.measureParagraph(
        text: '一二三四五六七八九十一二三四五六七八\n',
        typography: typography,
        contentWidth: null,
      );
      expect(line18.wrappedLines, equals(2));
    });

    test('TextPainter layouts deterministically when contentWidth is constrained', () {
      // With width 200 and fontSize 16, a 50-character string wraps into multiple lines
      const longText = '这是一段很长的测试日记文字，用于验证在具有固定版心宽度的情况下TextPainter能够准确测量折行数与断行字符位置。';
      final measured = StationeryLineMeasurer.measureParagraph(
        text: longText,
        typography: typography,
        contentWidth: 200.0,
      );

      expect(measured.wrappedLines, greaterThan(1));
      expect(measured.lineBreakOffsets.length, equals(measured.wrappedLines));
      expect(measured.lineBreakOffsets.last, equals(longText.length));
    });

    test('snapToSafeCodePointBoundary prevents splitting UTF-16 surrogate pairs and emoji', () {
      const text = '墨痕🌸流芳';
      final emojiIndex = text.indexOf('🌸');
      // '🌸' spans code units [emojiIndex, emojiIndex + 1]
      expect(text.codeUnitAt(emojiIndex) >= 0xD800 && text.codeUnitAt(emojiIndex) <= 0xDBFF, isTrue); // High
      expect(text.codeUnitAt(emojiIndex + 1) >= 0xDC00 && text.codeUnitAt(emojiIndex + 1) <= 0xDFFF, isTrue); // Low

      // Offset pointing into the low surrogate must step back to the start of the emoji
      final safeOffset = StationeryLineMeasurer.snapToSafeCodePointBoundary(
        text,
        emojiIndex + 1,
      );
      expect(safeOffset, equals(emojiIndex));

      // Safe offsets outside surrogate pair remain unchanged
      expect(StationeryLineMeasurer.snapToSafeCodePointBoundary(text, 0), equals(0));
      expect(StationeryLineMeasurer.snapToSafeCodePointBoundary(text, 2), equals(2));
      expect(StationeryLineMeasurer.snapToSafeCodePointBoundary(text, text.length), equals(text.length));
    });

    test('Dynamic grid letter-spacing produces extra space on grid/dotGrid and zero on lined', () {
      final gridSpacing = StationeryLineMeasurer.calculateGridLetterSpacing(
        backgroundType: TemplateBackgroundType.grid,
        lineStridePx: 24.0,
        fontSize: 16.0,
      );
      expect(gridSpacing, equals(8.0)); // 24 - 16 = 8.0

      final dotGridSpacing = StationeryLineMeasurer.calculateGridLetterSpacing(
        backgroundType: TemplateBackgroundType.dotGrid,
        lineStridePx: 28.0,
        fontSize: 16.0,
      );
      expect(dotGridSpacing, equals(12.0));

      final linedSpacing = StationeryLineMeasurer.calculateGridLetterSpacing(
        backgroundType: TemplateBackgroundType.lined,
        lineStridePx: 24.0,
        fontSize: 16.0,
      );
      expect(linedSpacing, equals(0.0));
    });

    test('measureDeltaRows sums visual rows across multi-paragraph document', () {
      final delta = Delta()
        ..insert('第一段标题')
        ..insert('\n', {'header': 1}) // 2 rows
        ..insert('第二段普通正文\n') // 1 row
        ..insert('第三段正文\n'); // 1 row

      final totalRows = StationeryLineMeasurer.measureDeltaRows(
        delta: delta,
        typography: typography,
        contentWidth: null,
      );

      expect(totalRows, equals(4)); // 2 + 1 + 1 = 4
    });
  });
}
