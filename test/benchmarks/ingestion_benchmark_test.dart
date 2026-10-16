import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/import_export/models/import_candidate_entry.dart';
import 'package:memodiary/features/import_export/services/date_parser_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ingestion Benchmark & Precision Suite', () {
    test('200-entry benchmark document parsing time <= 10s and date accuracy >= 95%', () async {
      final buffer = StringBuffer();
      const totalEntries = 200;
      final refDate = DateTime(2026, 10, 16);

      // Construct 200 synthetic diary entries covering various date conventions:
      // - 60 ISO numeric (YYYY-MM-DD or YYYY/MM/DD)
      // - 60 Chinese full dates (YYYY年MM月DD日)
      // - 40 Western month name dates (Month Day, Year)
      // - 35 Chinese month/day with weekday (MM月DD日)
      // - 5 Markdown headers without dates (unanchored body notes)
      for (int i = 0; i < totalEntries; i++) {
        if (i < 60) {
          final year = 2020 + (i % 5);
          final month = ((i % 12) + 1).toString().padLeft(2, '0');
          final day = ((i % 28) + 1).toString().padLeft(2, '0');
          buffer.writeln('$year-$month-$day 14:30');
          buffer.writeln('Entry #$i: Daily journal notes recording my thoughts and activities.');
          buffer.writeln('Enjoyed a warm cup of coffee in the afternoon.');
          buffer.writeln();
        } else if (i < 120) {
          final year = 2021 + (i % 4);
          final month = ((i % 12) + 1);
          final day = ((i % 28) + 1);
          buffer.writeln('$year年$month月$day日 晴');
          buffer.writeln('第$i篇日记：今天天气晴朗，散步走过湖畔，心情非常平静愉快。');
          buffer.writeln('晚上看了一本有趣的书。');
          buffer.writeln();
        } else if (i < 160) {
          final months = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
          ];
          final monthName = months[i % 12];
          final day = (i % 28) + 1;
          final year = 2022 + (i % 4);
          buffer.writeln('$monthName $day, $year');
          buffer.writeln('Western entry #$i: Visited the national museum today.');
          buffer.writeln('The architecture was truly breathtaking.');
          buffer.writeln();
        } else if (i < 195) {
          final month = ((i % 12) + 1);
          final day = ((i % 28) + 1);
          buffer.writeln('$month月$day日 星期三');
          buffer.writeln('年中随笔第$i条：整理了最近的工作计划与读书笔记。');
          buffer.writeln();
        } else {
          // Unanchored notes testing robustness
          buffer.writeln('随笔思考 #$i');
          buffer.writeln('偶尔写下的零散灵感片段，没有明确的时间锚点。');
          buffer.writeln();
        }
      }

      final documentText = buffer.toString();

      // Benchmark ingestion execution time
      final stopwatch = Stopwatch()..start();
      final candidates = await DateParserEngine.parseDocumentInIsolate(
        text: documentText,
        referenceDate: refDate,
      );
      stopwatch.stop();

      // 1. Assert execution time <= 10 seconds
      expect(
        stopwatch.elapsedMilliseconds,
        lessThanOrEqualTo(10000),
        reason: 'Ingestion parse time (${stopwatch.elapsedMilliseconds}ms) must be <= 10s',
      );

      // 2. Assert date recognition precision >= 95%
      // Candidates with high or medium confidence are successfully recognized dates
      final recognizedCount = candidates.where(
        (c) => c.confidence == DateParseConfidence.high || c.confidence == DateParseConfidence.medium,
      ).length;

      final accuracy = recognizedCount / 195; // 195 entries had explicit date anchors

      expect(
        accuracy,
        greaterThanOrEqualTo(0.95),
        reason: 'Date recognition accuracy (${(accuracy * 100).toStringAsFixed(1)}%) must be >= 95%',
      );

      // Verify non-empty candidate list and valid quill Delta structures
      expect(candidates.length, greaterThanOrEqualTo(190));
      for (final candidate in candidates) {
        expect(candidate.contentDelta.endsWith('\\n"}]'), isTrue);
      }
    });
  });
}

