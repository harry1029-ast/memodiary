import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/import_export/services/pdf_font_resolver.dart';

void main() {
  group('PdfFontResolver Tests', () {
    test('standard resolver initializes PostScript fonts and flags isCjkCapable = false', () {
      final resolver = PdfFontResolver.standard();
      expect(resolver.isCjkCapable, isFalse);
      expect(resolver.regularFont, isNotNull);
      expect(resolver.boldFont, isNotNull);
    });

    test('sanitizeText preserves Latin-1 characters and replaces characters > 255 for standard fonts', () {
      final resolver = PdfFontResolver.standard();
      const mixedText = 'Hello World! 拾光日记 (2026)';
      final sanitized = resolver.sanitizeText(mixedText);

      // 'Hello World! ' and ' (2026)' are in Latin-1, while the 4 Chinese characters become '?'
      expect(sanitized, equals('Hello World! ???? (2026)'));
    });

    test('custom CJK resolver preserves all CJK glyphs when isCjkCapable = true', () {
      final standard = PdfFontResolver.standard();
      final cjkResolver = PdfFontResolver(
        regularFont: standard.regularFont,
        boldFont: standard.boldFont,
        italicFont: standard.italicFont,
        boldItalicFont: standard.boldItalicFont,
        isCjkCapable: true,
      );

      const chineseText = '拾光日记 · 记录温暖';
      expect(cjkResolver.sanitizeText(chineseText), equals(chineseText));
    });
  });
}

