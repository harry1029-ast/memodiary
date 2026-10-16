class ThoughtSpark {
  final String id;
  final String promptZh;
  final String promptEn;
  final String category;

  const ThoughtSpark({
    required this.id,
    required this.promptZh,
    required this.promptEn,
    required this.category,
  });

  String get localizedPrompt => promptZh;
}

