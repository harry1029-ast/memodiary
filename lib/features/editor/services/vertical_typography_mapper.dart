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

  static final RegExp _interlinearRegex = RegExp(r'\{夹注:(.*?)\}');
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

    final matches = _interlinearRegex.allMatches(input);
    for (final match in matches) {
      if (match.start > currentIndex) {
        final textSlice = input.substring(currentIndex, match.start);
        _tokenizeNormalText(textSlice, tokens);
      }

      final noteContent = match.group(1) ?? '';
      _tokenizeInterlinearNote(noteContent, tokens);

      currentIndex = match.end;
    }

    if (currentIndex < input.length) {
      final textSlice = input.substring(currentIndex);
      _tokenizeNormalText(textSlice, tokens);
    }

    return tokens;
  }

  static void _tokenizeInterlinearNote(
    String rawContent,
    List<VerticalRenderToken> out,
  ) {
    if (rawContent.isEmpty) return;
    final content = mapPunctuation(rawContent);
    final noteLength = content.length;
    final rightCount = (noteLength + 1) ~/ 2;
    final rightChars = content.substring(0, rightCount);
    final leftChars = content.substring(rightCount);

    for (int rowIndex = 0; rowIndex < rightCount; rowIndex++) {
      final rightChar = rightChars[rowIndex];
      final leftChar = rowIndex < leftChars.length ? leftChars[rowIndex] : '';
      out.add(
        VerticalInterlinearPairToken(
          rightChar: rightChar,
          leftChar: leftChar,
        ),
      );
    }
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

  /// Partitions text into string tokens suitable for vertical columnar layout.
  /// Maintained for backwards compatibility with legacy string-based callers.
  static List<String> tokenizeForVertical(String input) {
    final renderTokens = tokenize(input);
    final result = <String>[];
    for (final token in renderTokens) {
      if (token is VerticalGlyphToken) {
        result.add(token.glyph);
      } else if (token is VerticalInterlinearPairToken) {
        if (token.rightChar.isNotEmpty) result.add(token.rightChar);
        if (token.leftChar.isNotEmpty) result.add(token.leftChar);
      }
    }
    return result;
  }
}
