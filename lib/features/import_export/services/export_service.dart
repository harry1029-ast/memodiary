import 'package:intl/intl.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'file_selector_service.dart';

enum ExportFormat {
  markdown,
  plainText,
  pdf,
}

enum ExportScope {
  single,
  all,
}

/// Service managing Markdown serialization with YAML frontmatter,
/// plain text backup formatting, and direct local storage saving.
class ExportService {
  /// Serializes a single entry into Markdown with YAML frontmatter
  static String formatEntryToMarkdown(Entry entry) {
    final buffer = StringBuffer();
    final dateIso = entry.entryDate.toIso8601String();
    final title = entry.title?.trim() ?? '';

    buffer.writeln('---');
    buffer.writeln('id: "${entry.id}"');
    buffer.writeln('title: "${title.replaceAll('"', r'\"')}"');
    buffer.writeln('date: "$dateIso"');
    if (entry.mood != null) buffer.writeln('mood: ${entry.mood}');
    if (entry.weather != null && entry.weather!.isNotEmpty) {
      buffer.writeln('weather: "${entry.weather}"');
    }
    buffer.writeln('is_weekly_review: ${entry.isWeeklyReview}');
    if (entry.weekNumber != null) buffer.writeln('week_number: ${entry.weekNumber}');
    buffer.writeln('---');
    buffer.writeln();

    if (title.isNotEmpty) {
      buffer.writeln('# $title');
      buffer.writeln();
    }

    buffer.writeln(entry.plainText.trim());
    buffer.writeln();
    return buffer.toString();
  }

  /// Serializes a single entry into clean human-readable plain text
  static String formatEntryToPlainText(Entry entry) {
    final buffer = StringBuffer();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.entryDate);
    final title = (entry.title?.trim().isNotEmpty ?? false) ? entry.title!.trim() : 'Untitled';

    buffer.writeln('========================================');
    buffer.writeln(title);
    buffer.writeln('Date: $dateStr');
    if (entry.mood != null) buffer.writeln('Mood: ${entry.mood}/5');
    if (entry.weather != null && entry.weather!.isNotEmpty) {
      buffer.writeln('Weather: ${entry.weather}');
    }
    if (entry.isWeeklyReview) {
      buffer.writeln('Weekly Review: Week ${entry.weekNumber ?? ""}');
    }
    buffer.writeln('========================================');
    buffer.writeln();
    buffer.writeln(entry.plainText.trim());
    buffer.writeln();
    return buffer.toString();
  }

  /// Serializes multiple entries into a consolidated Markdown document
  static String formatBatchToMarkdown(List<Entry> entries) {
    final buffer = StringBuffer();
    for (int i = 0; i < entries.length; i++) {
      buffer.write(formatEntryToMarkdown(entries[i]));
      if (i < entries.length - 1) {
        buffer.writeln('---'); // Markdown horizontal rule delimiter
        buffer.writeln();
      }
    }
    return buffer.toString();
  }

  /// Serializes multiple entries into a consolidated plain text document
  static String formatBatchToPlainText(List<Entry> entries) {
    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer.write(formatEntryToPlainText(entry));
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// Generates the exported string for given entries and format
  static String serialize({
    required List<Entry> entries,
    required ExportFormat format,
  }) {
    if (entries.isEmpty) return '';
    if (format == ExportFormat.markdown) {
      return entries.length == 1
          ? formatEntryToMarkdown(entries.first)
          : formatBatchToMarkdown(entries);
    } else {
      return entries.length == 1
          ? formatEntryToPlainText(entries.first)
          : formatBatchToPlainText(entries);
    }
  }

  /// Prompts the user to save the exported content to disk in <= 3 taps
  static Future<String?> saveToFile({
    required List<Entry> entries,
    required ExportFormat format,
    required FileSelectorService fileSelector,
    String? customFileName,
  }) async {
    final content = serialize(entries: entries, format: format);
    final extension = format == ExportFormat.markdown ? 'md' : 'txt';
    final nowStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());

    String baseName;
    if (customFileName != null && customFileName.isNotEmpty) {
      baseName = customFileName;
    } else if (entries.length == 1 && (entries.first.title?.trim().isNotEmpty ?? false)) {
      baseName = entries.first.title!.trim().replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
    } else {
      baseName = 'MemoDiary_Export_$nowStr';
    }

    final targetFileName = '$baseName.$extension';

    return fileSelector.saveExportFile(
      fileName: targetFileName,
      content: content,
    );
  }
}

