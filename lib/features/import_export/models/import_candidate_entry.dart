import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:memodiary/core/database/app_database.dart';

/// Confidence score indicating how reliably a date was parsed from the source text.
enum DateParseConfidence {
  /// Full date (year, month, day) explicitly parsed from standard format.
  high,

  /// Partial date (month, day) with inferred year, or relative date marker (e.g. "昨天").
  medium,

  /// Low confidence or ambiguous numerical pattern.
  low,

  /// No date anchor detected; fallback date or user assignment required.
  none,
}

/// A parsed candidate diary entry waiting in the staging review area before committing to SQLite.
class ImportCandidateEntry {
  final String id;
  DateTime? parsedDate;
  String title;
  String plainText;
  String contentDelta;
  DateParseConfidence confidence;
  bool isSelected;
  int? mood;
  String? weather;
  bool isWeeklyReview;
  int? weekNumber;

  ImportCandidateEntry({
    required this.id,
    this.parsedDate,
    required this.title,
    required this.plainText,
    required this.contentDelta,
    required this.confidence,
    this.isSelected = true,
    this.mood,
    this.weather,
    this.isWeeklyReview = false,
    this.weekNumber,
  });

  /// Converts this candidate into an EntriesCompanion ready for Drift batch insertion.
  /// Guarantees that Delta JSON documents strictly end with a trailing newline.
  EntriesCompanion toCompanion({
    required String notebookId,
    required String templateId,
  }) {
    final effectiveDate = parsedDate ?? DateTime.now();

    // Invariant: Quill Delta JSON documents must strictly terminate with '\n'
    String safeDelta = contentDelta;
    if (safeDelta.isEmpty) {
      safeDelta = jsonEncode([
        {'insert': '$plainText\n'}
      ]);
    } else {
      try {
        final decoded = jsonDecode(safeDelta);
        if (decoded is List && decoded.isNotEmpty) {
          final last = decoded.last;
          if (last is Map && last['insert'] is String) {
            final str = last['insert'] as String;
            if (!str.endsWith('\n')) {
              last['insert'] = '$str\n';
              safeDelta = jsonEncode(decoded);
            }
          }
        }
      } catch (_) {
        safeDelta = jsonEncode([
          {'insert': '$plainText\n'}
        ]);
      }
    }

    return EntriesCompanion.insert(
      id: id,
      notebookId: notebookId,
      templateId: templateId,
      title: Value(title),
      contentDelta: safeDelta,
      plainText: plainText,
      entryDate: effectiveDate,
      mood: mood != null ? Value(mood) : const Value.absent(),
      weather: weather != null ? Value(weather) : const Value.absent(),
      isWeeklyReview: Value(isWeeklyReview),
      weekNumber: weekNumber != null ? Value(weekNumber) : const Value.absent(),
      createdAt: Value(effectiveDate),
      updatedAt: Value(DateTime.now()),
    );
  }

  ImportCandidateEntry copyWith({
    String? id,
    DateTime? parsedDate,
    String? title,
    String? plainText,
    String? contentDelta,
    DateParseConfidence? confidence,
    bool? isSelected,
    int? mood,
    String? weather,
    bool? isWeeklyReview,
    int? weekNumber,
  }) {
    return ImportCandidateEntry(
      id: id ?? this.id,
      parsedDate: parsedDate ?? this.parsedDate,
      title: title ?? this.title,
      plainText: plainText ?? this.plainText,
      contentDelta: contentDelta ?? this.contentDelta,
      confidence: confidence ?? this.confidence,
      isSelected: isSelected ?? this.isSelected,
      mood: mood ?? this.mood,
      weather: weather ?? this.weather,
      isWeeklyReview: isWeeklyReview ?? this.isWeeklyReview,
      weekNumber: weekNumber ?? this.weekNumber,
    );
  }
}

