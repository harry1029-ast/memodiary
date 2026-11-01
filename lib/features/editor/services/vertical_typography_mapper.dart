/// Utility for converting horizontal CJK punctuation and brackets
/// to traditional vertical calligraphy presentation glyphs.
class VerticalTypographyMapper {
  const VerticalTypographyMapper._();

  /// Direct mapping table from horizontal punctuation to vertical presentation glyphs.
  static const Map<String, String> cjkVerticalPunctuationMap = {
    // Quotation marks
    '「': '﹁', // U+FE43
    '」': '﹂', // U+FE44
    '『': '﹃', // U+FE41
    '』': '﹄', // U+FE42
    '“': '﹁',
    '”': '﹂',
    '‘': '﹃',
    '’': '﹄',
    // Book title marks / angle brackets
    '《': '︽', // U+FE3D
    '》': '︾', // U+FE3E
    '〈': '︿', // U+FE3F
    '〉': '﹀', // U+FE40
    // Parentheses
    '（': '︵', // U+FE35
    '）': '︶', // U+FE36
    '(': '︵',
    ')': '︶',
    // Brackets
    '【': '︻', // U+FE3B
    '】': '︼', // U+FE3C
    '〔': '︹', // U+FE39
    '〕': '︺', // U+FE3A
    '［': '﹇', // U+FE47
    '］': '﹈', // U+FE48
    '[': '﹇',
    ']': '﹈',
    // Dashes
    '—': '︱', // U+FE31
    '–': '︱',
    // Ellipses
    '…': '⋮', // U+22EE
    '⋯': '⋮',
  };

  /// Converts horizontal CJK brackets, quotes, dashes, and ellipses
  /// to their classical vertical presentation forms.
  static String mapPunctuation(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final ch = input[i];
      buffer.write(cjkVerticalPunctuationMap[ch] ?? ch);
    }
    return buffer.toString();
  }

  /// Partitions text into tokens suitable for vertical columnar layout.
  /// CJK characters and mapped punctuation are single-character cells.
  /// Latin character runs and numeric digits are preserved as coherent units.
  static List<String> tokenizeForVertical(String input) {
    final mapped = mapPunctuation(input);
    final tokens = <String>[];
    final latinBuffer = StringBuffer();

    void flushLatin() {
      if (latinBuffer.isNotEmpty) {
        tokens.add(latinBuffer.toString());
        latinBuffer.clear();
      }
    }

    final latinRegex = RegExp(r'[a-zA-Z0-9_\-.]');

    for (int i = 0; i < mapped.length; i++) {
      final ch = mapped[i];
      if (latinRegex.hasMatch(ch)) {
        latinBuffer.write(ch);
      } else {
        flushLatin();
        if (ch != '\r') {
          tokens.add(ch);
        }
      }
    }
    flushLatin();

    return tokens;
  }
}
