import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'offline_cjk_ttf_generator.dart';

/// Manages offline PDF font configuration and safe character encoding.
///
/// Standard PDF fonts (Type 1 Helvetica/Times) only support Western Latin-1 (codes 0-255).
/// When rendering Chinese or Unicode characters, a TrueType font (`.ttf`) loaded via
/// `pw.Font.ttf()` must be used to prevent `Font Helvetica has no character...` exceptions.
class PdfFontResolver {
  final pw.Font regularFont;
  final pw.Font boldFont;
  final pw.Font italicFont;
  final pw.Font boldItalicFont;
  final bool isCjkCapable;

  const PdfFontResolver({
    required this.regularFont,
    required this.boldFont,
    required this.italicFont,
    required this.boldItalicFont,
    this.isCjkCapable = false,
  });

  /// Creates a 100% offline CJK-capable TrueType PDF font resolver.
  ///
  /// Uses [OfflineCjkTtfGenerator] so Chinese characters, CJK punctuation,
  /// and Unicode symbols (`·`, `→`) render cleanly without Latin-1 `'?'` fallbacks
  /// or dynamic network downloads.
  factory PdfFontResolver.cjk() {
    final cjkFont = OfflineCjkTtfGenerator.resolveCjkFont();
    return PdfFontResolver(
      regularFont: cjkFont,
      boldFont: cjkFont,
      italicFont: cjkFont,
      boldItalicFont: cjkFont,
      isCjkCapable: true,
    );
  }

  /// Asynchronously loads an offline CJK TrueType font from [assetPath] if bundled,
  /// falling back to the deterministic in-memory CJK TrueType font.
  static Future<PdfFontResolver> loadOfflineCjk({String? assetPath}) async {
    final cjkFont =
        await OfflineCjkTtfGenerator.loadOrGenerateFont(assetPath: assetPath);
    return PdfFontResolver.fromFont(cjkFont);
  }

  /// Creates a standard Latin-1 PostScript PDF font resolver (zero network, built-in).
  factory PdfFontResolver.standard() {
    return PdfFontResolver(
      regularFont: pw.Font.helvetica(),
      boldFont: pw.Font.helveticaBold(),
      italicFont: pw.Font.helveticaOblique(),
      boldItalicFont: pw.Font.helveticaBoldOblique(),
      isCjkCapable: false,
    );
  }

  /// Creates a CJK TrueType font resolver from offline font byte data.
  factory PdfFontResolver.fromTtfBytes({
    required ByteData regularBytes,
    ByteData? boldBytes,
    ByteData? italicBytes,
  }) {
    final regular = pw.Font.ttf(regularBytes);
    final bold = boldBytes != null ? pw.Font.ttf(boldBytes) : regular;
    final italic = italicBytes != null ? pw.Font.ttf(italicBytes) : regular;

    return PdfFontResolver(
      regularFont: regular,
      boldFont: bold,
      italicFont: italic,
      boldItalicFont: bold,
      isCjkCapable: true,
    );
  }

  /// Creates a custom font resolver wrapping pre-loaded [pw.Font] instances.
  factory PdfFontResolver.fromFont(pw.Font font) {
    return PdfFontResolver(
      regularFont: font,
      boldFont: font,
      italicFont: font,
      boldItalicFont: font,
      isCjkCapable: true,
    );
  }

  /// Sanitizes text for standard Latin-1 PDF fonts if no CJK font is loaded (Watchpoint 1).
  /// Characters outside Latin-1 (> 255) are safely preserved if [isCjkCapable] is true,
  /// or escaped into readable tokens if using standard PostScript fonts to prevent encoding exceptions.
  String sanitizeText(String text) {
    if (isCjkCapable) {
      final buffer = StringBuffer();
      for (int i = 0; i < text.length; i++) {
        final codeUnit = text.codeUnitAt(i);
        // Strip null bytes and control codes that corrupt PDF streams
        if (codeUnit == 0x0000 ||
            (codeUnit < 0x0020 &&
                codeUnit != 0x0009 &&
                codeUnit != 0x000A &&
                codeUnit != 0x000D) ||
            codeUnit == 0x007F) {
          continue;
        }
        // Skip UTF-16 surrogate pairs (e.g. non-BMP emoji) so Type0 BMP font never faults
        if (codeUnit >= 0xD800 && codeUnit <= 0xDFFF) {
          continue;
        }
        buffer.writeCharCode(codeUnit);
      }
      return buffer.toString();
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      if (codeUnit <= 255) {
        buffer.writeCharCode(codeUnit);
      } else {
        // Safe character fallback for standard Latin-1 font
        buffer.write('?');
      }
    }
    return buffer.toString();
  }
}

