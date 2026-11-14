/// Typed vertical render token model for classical CJK columnar typography.
sealed class VerticalRenderToken {
  const VerticalRenderToken();
}

/// A single vertical glyph or coherent Latin word run.
class VerticalGlyphToken extends VerticalRenderToken {
  final String glyph;
  final bool isCornerPunctuation;
  final bool requiresQuarterTurnRotation;

  const VerticalGlyphToken(
    this.glyph, {
    this.isCornerPunctuation = false,
    this.requiresQuarterTurnRotation = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerticalGlyphToken &&
          runtimeType == other.runtimeType &&
          glyph == other.glyph &&
          isCornerPunctuation == other.isCornerPunctuation &&
          requiresQuarterTurnRotation == other.requiresQuarterTurnRotation;

  @override
  int get hashCode => Object.hash(glyph, isCornerPunctuation, requiresQuarterTurnRotation);

  @override
  String toString() =>
      'VerticalGlyphToken($glyph, isCorner: $isCornerPunctuation, rot: $requiresQuarterTurnRotation)';
}

/// A paired two-character cell for classical Chinese Interlinear Sub-Notes (双行夹注).
class VerticalInterlinearPairToken extends VerticalRenderToken {
  final String rightChar;
  final String leftChar;

  const VerticalInterlinearPairToken({
    required this.rightChar,
    required this.leftChar,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerticalInterlinearPairToken &&
          runtimeType == other.runtimeType &&
          rightChar == other.rightChar &&
          leftChar == other.leftChar;

  @override
  int get hashCode => Object.hash(rightChar, leftChar);

  @override
  String toString() => 'VerticalInterlinearPairToken($rightChar, $leftChar)';
}

/// Utility for converting horizontal CJK punctuation and brackets
/// to traditional vertical calligraphy presentation glyphs and tokenizing
/// text for vertical columnar layout and classical interlinear sub-notes.
class VerticalTypographyMapper {
  const VerticalTypographyMapper._();

  /// Canonical pattern matching `{夹注:...}` Interlinear Sub-Note spans.
  static final RegExp interlinearRegex = RegExp(r'\{夹注:(.*?)\}');
  static final RegExp _latinCharRegex = RegExp(r'[a-zA-Z0-9_\-.]');

  /// Ideographic stops placed in the upper-right quadrant of their character cell.
  static const Set<String> _cornerPunctuation = {
    '。',
    '，',
    '、',
    '．',
  };

  /// Horizontal fallback punctuation requiring a 90-degree quarter-turn rotation.
  static const Set<String> _rotatedPunctuation = {
    '—',
    '–',
    '―',
    '…',
    '⋯',
    '~',
    '～',
    ':',
    '：',
    ';',
    '；',
    '--',
    '{',
    '}',
    '[',
    ']',
  };

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

  /// Formats interlinear sub-notes {夹注:...} as inline bracketed notes 〖...〗.
  static String formatInterlinearAsInline(String text) {
    return text.replaceAllMapped(
      interlinearRegex,
      (match) => '〖${match.group(1)}〗',
    );
  }

  /// Converts horizontal CJK brackets, quotes, dashes, and ellipses
  /// to their classical vertical presentation forms.
  static String mapPunctuation(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    for (int index = 0; index < input.length; index++) {
      final char = input[index];
      buffer.write(cjkVerticalPunctuationMap[char] ?? char);
    }
    return buffer.toString();
  }

  /// Parses text into structured [VerticalRenderToken] objects:
  /// - `{夹注:...}` sub-notes are parsed into [VerticalInterlinearPairToken] rows.
  /// - Ideographic stops (`。`, `，`, `、`) are marked with `isCornerPunctuation: true`.
  /// - Horizontal fallback punctuation and Latin word runs are marked with `requiresQuarterTurnRotation: true`.
  /// - Standard CJK glyphs are returned as single [VerticalGlyphToken] cells.
  static List<VerticalRenderToken> tokenize(String input) {
    if (input.isEmpty) return const [];

    final tokens = <VerticalRenderToken>[];
    int currentIndex = 0;

    final matches = interlinearRegex.allMatches(input);
    for (final match in matches) {
      if (match.start > currentIndex) {
        final textSlice = input.substring(currentIndex, match.start);
        _tokenizeNormalText(textSlice, tokens);
      }

      final noteContent = match.group(1) ?? '';
      tokens.addAll(tokenizeInterlinear(noteContent));

      currentIndex = match.end;
    }

    if (currentIndex < input.length) {
      final textSlice = input.substring(currentIndex);
      _tokenizeNormalText(textSlice, tokens);
    }

    return tokens;
  }

  /// Tokenizes the inner text of an interlinear sub-note (`{夹注:...}`) into
  /// dual-subcolumn [VerticalInterlinearPairToken] rows ordered classical
  /// right-sub-column top-to-bottom first, then left-sub-column top-to-bottom,
  /// with horizontal CJK punctuation converted via [mapPunctuation].
  static List<VerticalInterlinearPairToken> tokenizeInterlinear(String rawContent) {
    if (rawContent.isEmpty) return const [];
    final content = mapPunctuation(rawContent);
    final chars = content.runes.map(String.fromCharCode).toList(growable: false);
    final rightCount = (chars.length + 1) ~/ 2;
    final pairs = <VerticalInterlinearPairToken>[];

    for (int rowIndex = 0; rowIndex < rightCount; rowIndex++) {
      final rightChar = chars[rowIndex];
      final leftIndex = rightCount + rowIndex;
      final leftChar = leftIndex < chars.length ? chars[leftIndex] : '';
      pairs.add(
        VerticalInterlinearPairToken(
          rightChar: rightChar,
          leftChar: leftChar,
        ),
      );
    }
    return pairs;
  }

  static void _tokenizeNormalText(
    String text,
    List<VerticalRenderToken> out,
  ) {
    final mapped = mapPunctuation(text);
    final latinBuffer = StringBuffer();

    void flushLatin() {
      if (latinBuffer.isNotEmpty) {
        final word = latinBuffer.toString();
        latinBuffer.clear();
        out.add(
          VerticalGlyphToken(
            word,
            requiresQuarterTurnRotation: word.length > 1,
          ),
        );
      }
    }

    for (int index = 0; index < mapped.length; index++) {
      final char = mapped[index];
      if (_latinCharRegex.hasMatch(char)) {
        latinBuffer.write(char);
      } else {
        flushLatin();
        if (char == '\r') continue;

        if (_cornerPunctuation.contains(char)) {
          out.add(VerticalGlyphToken(char, isCornerPunctuation: true));
        } else if (_rotatedPunctuation.contains(char)) {
          out.add(VerticalGlyphToken(char, requiresQuarterTurnRotation: true));
        } else {
          out.add(VerticalGlyphToken(char));
        }
      }
    }
    flushLatin();
  }
}
