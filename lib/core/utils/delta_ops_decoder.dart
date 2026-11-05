import 'dart:convert';

/// Decodes a persisted Quill Delta JSON string (a bare op list or an
/// `{"ops": [...]}` document) into its operations.
///
/// Returns null for an empty, malformed or op-less string, so callers can fall
/// back to the entry's plain text.
List<dynamic>? decodeDeltaOps(String contentDeltaJson) {
  if (contentDeltaJson.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(contentDeltaJson);
    final ops = decoded is List ? decoded : (decoded is Map ? decoded['ops'] : null);
    if (ops is List && ops.isNotEmpty) return ops;
  } catch (_) {
    // Malformed Delta: the caller falls back to plain text.
  }
  return null;
}
