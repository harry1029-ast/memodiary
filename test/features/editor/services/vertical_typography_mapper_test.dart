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

    test('tokenize retains Latin runs and numbers as coherent units', () {
      final tokens = VerticalTypographyMapper.tokenize('MemoDiary 2026年「春」');
      expect(tokens, hasLength(7));
      expect(tokens[0], equals(const VerticalGlyphToken('MemoDiary', requiresQuarterTurnRotation: true)));
      expect(tokens[1], equals(const VerticalGlyphToken(' ')));
      expect(tokens[2], equals(const VerticalGlyphToken('2026', requiresQuarterTurnRotation: true)));
      expect(tokens[3], equals(const VerticalGlyphToken('年')));
      expect(tokens[4], equals(const VerticalGlyphToken('﹁')));
      expect(tokens[5], equals(const VerticalGlyphToken('春')));
      expect(tokens[6], equals(const VerticalGlyphToken('﹂')));
    });

    test('formatInterlinearAsInline converts interlinear sub-notes to bracketed form', () {
      expect(
        VerticalTypographyMapper.formatInterlinearAsInline('前言{夹注:月照花林}后语{夹注:唐诗}'),
        equals('前言〖月照花林〗后语〖唐诗〗'),
      );
      expect(
        VerticalTypographyMapper.formatInterlinearAsInline('无夹注正文'),
        equals('无夹注正文'),
      );
    });

    test('handles empty and plain strings safely', () {
      expect(VerticalTypographyMapper.mapPunctuation(''), equals(''));
      expect(VerticalTypographyMapper.tokenize(''), isEmpty);
      expect(
        VerticalTypographyMapper.mapPunctuation('天地玄黄'),
        equals('天地玄黄'),
      );
    });

    test('tokenize parses interlinear sub-notes into typed VerticalInterlinearPairToken items', () {
      // Even length: 4 characters "月照花林" -> 2 pairs: ("月", "花"), ("照", "林")
      final evenTokens = VerticalTypographyMapper.tokenize('前言{夹注:月照花林}后语');
      expect(evenTokens, hasLength(6));
      expect(evenTokens[0], equals(const VerticalGlyphToken('前')));
      expect(evenTokens[1], equals(const VerticalGlyphToken('言')));
      expect(
        evenTokens[2],
        equals(const VerticalInterlinearPairToken(rightChar: '月', leftChar: '花')),
      );
      expect(
        evenTokens[3],
        equals(const VerticalInterlinearPairToken(rightChar: '照', leftChar: '林')),
      );
      expect(evenTokens[4], equals(const VerticalGlyphToken('后')));
      expect(evenTokens[5], equals(const VerticalGlyphToken('语')));

      // Odd length: 3 characters "唐诗选" -> ("唐", "选"), ("诗", "") (right filled, left empty)
      final oddTokens = VerticalTypographyMapper.tokenize('{夹注:唐诗选}');
      expect(oddTokens, hasLength(2));
      expect(
        oddTokens[0],
        equals(const VerticalInterlinearPairToken(rightChar: '唐', leftChar: '选')),
      );
      expect(
        oddTokens[1],
        equals(const VerticalInterlinearPairToken(rightChar: '诗', leftChar: '')),
      );

      // Single character: "注" -> ("注", "")
      final singleTokens = VerticalTypographyMapper.tokenize('{夹注:注}');
      expect(singleTokens, hasLength(1));
      expect(
        singleTokens[0],
        equals(const VerticalInterlinearPairToken(rightChar: '注', leftChar: '')),
      );

      // Empty note: "{夹注:}" -> 0 pairs
      final emptyTokens = VerticalTypographyMapper.tokenize('{夹注:}');
      expect(emptyTokens, isEmpty);
    });

    test('tokenize identifies ideographic corner stops and rotated vertical punctuation', () {
      final tokens = VerticalTypographyMapper.tokenize('明月。春风，细雨、寒江—夜泊～MemoDiary');

      // Corner punctuation: 。，、
      final stop1 = tokens.firstWhere((token) => token is VerticalGlyphToken && token.glyph == '。') as VerticalGlyphToken;
      expect(stop1.isCornerPunctuation, isTrue);

      final stop2 = tokens.firstWhere((token) => token is VerticalGlyphToken && token.glyph == '，') as VerticalGlyphToken;
      expect(stop2.isCornerPunctuation, isTrue);

      final stop3 = tokens.firstWhere((token) => token is VerticalGlyphToken && token.glyph == '、') as VerticalGlyphToken;
      expect(stop3.isCornerPunctuation, isTrue);

      // Rotated punctuation / Latin runs
      final rotatedPunct = tokens.firstWhere((token) => token is VerticalGlyphToken && token.glyph == '～') as VerticalGlyphToken;
      expect(rotatedPunct.requiresQuarterTurnRotation, isTrue);

      final latinToken = tokens.firstWhere((token) => token is VerticalGlyphToken && token.glyph == 'MemoDiary') as VerticalGlyphToken;
      expect(latinToken.requiresQuarterTurnRotation, isTrue);

      // Unmapped fallback brackets: { and }
      final bracketTokens = VerticalTypographyMapper.tokenize('卷{壹}');
      final leftCurly = bracketTokens.firstWhere((token) => token is VerticalGlyphToken && token.glyph == '{') as VerticalGlyphToken;
      expect(leftCurly.requiresQuarterTurnRotation, isTrue);
      final rightCurly = bracketTokens.firstWhere((token) => token is VerticalGlyphToken && token.glyph == '}') as VerticalGlyphToken;
      expect(rightCurly.requiresQuarterTurnRotation, isTrue);
    });
  });
}

