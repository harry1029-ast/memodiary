import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/import_export/services/offline_cjk_ttf_generator.dart';
import 'package:memodiary/features/import_export/services/pdf_font_resolver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

    test(
        'PdfFontResolver.cjk() builds valid offline TrueType CJK font and compiles Chinese strings ("深圳 · 江南春行纪", "十月廿三", "测试相册") into PDF bytes with zero ? glyph fallbacks',
        () async {
      final ttfData = OfflineCjkTtfGenerator.buildTtfByteData();
      expect(ttfData.lengthInBytes, greaterThan(1024));
      // Verify OpenType/TrueType sfnt version 0x00010000
      expect(ttfData.getUint32(0), equals(0x00010000));

      final cjkResolver = PdfFontResolver.cjk();
      expect(cjkResolver.isCjkCapable, isTrue);
      final parser = TtfParser(ttfData);
      expect(parser.charToGlyphIndexMap[0x6DF1], isNotNull);
      expect(parser.charToGlyphIndexMap[0x6C5F], isNotNull);
      expect(
        parser.charToGlyphIndexMap[0x6DF1],
        isNot(equals(parser.charToGlyphIndexMap[0x6C5F])),
      );

      const sample1 = '深圳 · 江南春行纪';
      const sample2 = '十月廿三';
      const sample3 = '测试相册';

      expect(cjkResolver.sanitizeText(sample1), equals(sample1));
      expect(cjkResolver.sanitizeText(sample2), equals(sample2));
      expect(cjkResolver.sanitizeText(sample3), equals(sample3));
      expect(cjkResolver.sanitizeText(sample1).contains('?'), isFalse);

      final doc = pw.Document(compress: false);
      doc.addPage(
        pw.Page(
          build: (context) => pw.Column(
            children: [
              pw.Text(
                cjkResolver.sanitizeText(sample1),
                style: pw.TextStyle(font: cjkResolver.boldFont, fontSize: 18),
              ),
              pw.Text(
                cjkResolver.sanitizeText(sample2),
                style:
                    pw.TextStyle(font: cjkResolver.regularFont, fontSize: 14),
              ),
              pw.Text(
                cjkResolver.sanitizeText(sample3),
                style: pw.TextStyle(font: cjkResolver.italicFont, fontSize: 12),
              ),
            ],
          ),
        ),
      );

      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotEmpty);

      final rawPdfText = latin1.decode(pdfBytes, allowInvalid: true);
      expect(rawPdfText.startsWith('%PDF-'), isTrue);
      // Verify TrueType Identity-H Type0 font embedding, ToUnicode CJK mappings, and zero '?' fallback
      expect(rawPdfText, contains('/Subtype/Type0'));
      expect(rawPdfText, contains('/Encoding/Identity-H'));
      expect(rawPdfText, contains('/BaseFont/MemoDiaryCJK-Regular'));
      expect(rawPdfText, contains('<6DF1>')); // 深
      expect(rawPdfText, contains('<6C5F>')); // 江
      expect(rawPdfText, contains('<5341>')); // 十
      expect(rawPdfText, contains('<6D4B>')); // 测
      expect(rawPdfText, isNot(contains('????')));
    });

    test('cjkResolver preserves CJK Ext A characters and strips null bytes without ? replacement', () async {
      final cjkResolver = PdfFontResolver.cjk();
      // \u3400 is CJK Unified Ideographs Extension A (㐀)
      const textWithExtAAndNull = '江南\u0000\u3400春行';
      final sanitized = cjkResolver.sanitizeText(textWithExtAAndNull);
      expect(sanitized, equals('江南\u3400春行'));
      expect(sanitized.contains('?'), isFalse);
      expect(sanitized.contains(' '), isFalse);

      final loadedFont = await OfflineCjkTtfGenerator.loadOrGenerateFont();
      expect(loadedFont, isNotNull);
    });
  });
}

