import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/services/vertical_typography_mapper.dart';

void main() {
  group('VerticalTypographyMapper Tests', () {
    test('maps CJK quotation marks to vertical glyphs', () {
      expect(
        VerticalTypographyMapper.mapPunctuation('「心迹」『安放』'),
        equals('﹁心迹﹂﹃安放﹄'),
      );
      expect(
        VerticalTypographyMapper.mapPunctuation('“心迹”‘安放’'),
        equals('﹁心迹﹂﹃安放﹄'),
      );
    });

    test('maps CJK title marks and parentheses to vertical glyphs', () {
      expect(
        VerticalTypographyMapper.mapPunctuation('《拾光》（日记）'),
        equals('︽拾光︾︵日记︶'),
      );
      expect(
        VerticalTypographyMapper.mapPunctuation('〈拾光〉(日记)'),
        equals('︿拾光﹀︵日记︶'),
      );
    });

    test('maps CJK brackets, dashes, and ellipses to vertical glyphs', () {
      expect(
        VerticalTypographyMapper.mapPunctuation('【注】〔记〕［卷］'),
        equals('︻注︼︹记︺﹇卷﹈'),
      );
      expect(
        VerticalTypographyMapper.mapPunctuation('春去——秋来…'),
        equals('春去︱︱秋来⋮'),
      );
    });

    test('tokenizeForVertical retains Latin runs and numbers as coherent units', () {
      final tokens = VerticalTypographyMapper.tokenizeForVertical('MemoDiary 2026年「春」');
      expect(
        tokens,
        equals(['MemoDiary', ' ', '2026', '年', '﹁', '春', '﹂']),
      );
    });

    test('handles empty and plain strings safely', () {
      expect(VerticalTypographyMapper.mapPunctuation(''), equals(''));
      expect(VerticalTypographyMapper.tokenizeForVertical(''), isEmpty);
      expect(
        VerticalTypographyMapper.mapPunctuation('天地玄黄'),
        equals('天地玄黄'),
      );
    });
  });
}

