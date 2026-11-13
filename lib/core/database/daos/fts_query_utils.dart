final RegExp _cjkCharacterRegex = RegExp(r'[\u4e00-\u9fff]');

/// Returns whether [query] contains any Han (CJK Unified Ideograph) characters
/// requiring SQL `LIKE` substring fallback alongside FTS5 token search.
bool containsCjkCharacters(String query) {
  return _cjkCharacterRegex.hasMatch(query);
}

/// Escapes double quotes in [trimmedQuery] and wraps it as an FTS5 prefix
/// phrase query (`"<escaped>"*`).
String formatFts5PrefixQuery(String trimmedQuery) {
  final escaped = trimmedQuery.replaceAll('"', '""');
  return '"$escaped"*';
}

/// Escapes SQL `LIKE` wildcards (`\`, `%`, `_`) in [trimmedQuery] and wraps
/// it as a substring contains pattern (`%<escaped>%`) for `ESCAPE '\'`.
String formatSqlLikeContainsPattern(String trimmedQuery) {
  final escaped = trimmedQuery
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
  return '%$escaped%';
}
