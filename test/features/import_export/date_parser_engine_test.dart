import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/import_export/models/import_candidate_entry.dart';
import 'package:memodiary/features/import_export/services/date_parser_engine.dart';

void main() {
  final refDate = DateTime(2026, 10, 16, 12, 0); // Friday

  group('DateParserEngine Regex Suite Tests', () {
    test('parses ISO 8601 date formats with high confidence', () {
      final res1 = DateParserEngine.tryParseDateAnchor(
        line: '# 2026-10-16 Trip to Osaka',
        referenceDate: refDate,
        defaultYear: 2026,
      );
      expect(res1, isNotNull);
      expect(res1!.date.year, equals(2026));
      expect(res1.date.month, equals(10));
      expect(res1.date.day, equals(16));
      expect(res1.remainingTitle, equals('Trip to Osaka'));
      expect(res1.confidence, equals(DateParseConfidence.high));

      final res2 = DateParserEngine.tryParseDateAnchor(
        line: '2026/05/20 08:30 Morning run',
        referenceDate: refDate,
        defaultYear: 2026,
      );
      expect(res2, isNotNull);
      expect(res2!.date.month, equals(5));
      expect(res2.date.day, equals(20));
      expect(res2.date.hour, equals(8));
      expect(res2.date.minute, equals(30));
    });

    test('parses Chinese full date and month-day formats', () {
      final resFull = DateParserEngine.tryParseDateAnchor(
        line: '## 2026年10月16日 晴 京都之行',
        referenceDate: refDate,
        defaultYear: 2026,
      );
      expect(resFull, isNotNull);
      expect(resFull!.date.year, equals(2026));
      expect(resFull.date.month, equals(10));
      expect(resFull.date.day, equals(16));
      expect(resFull.weather, equals('sunny'));
      expect(resFull.confidence, equals(DateParseConfidence.high));

      // Month-day with inferred year
      final resMonthDay = DateParserEngine.tryParseDateAnchor(
        line: '12月25日 星期五 圣诞聚会',
        referenceDate: refDate,
        defaultYear: 2026,
      );
      expect(resMonthDay, isNotNull);
      expect(resMonthDay!.date.year, equals(2026));
      expect(resMonthDay.date.month, equals(12));
      expect(resMonthDay.date.day, equals(25));
      expect(resMonthDay.confidence, equals(DateParseConfidence.medium));
    });

    test('parses Western date formats', () {
      final resWest1 = DateParserEngine.tryParseDateAnchor(
        line: 'October 16, 2026 Autumn Coffee',
        referenceDate: refDate,
        defaultYear: 2026,
      );
      expect(resWest1, isNotNull);
      expect(resWest1!.date.year, equals(2026));
      expect(resWest1.date.month, equals(10));
      expect(resWest1.date.day, equals(16));
      expect(resWest1.remainingTitle, equals('Autumn Coffee'));

      final resWest2 = DateParserEngine.tryParseDateAnchor(
        line: '16th Oct 2026 Reading books',
        referenceDate: refDate,
        defaultYear: 2026,
      );
      expect(resWest2, isNotNull);
      expect(resWest2!.date.month, equals(10));
      expect(resWest2.date.day, equals(16));

      final resNumeric = DateParserEngine.tryParseDateAnchor(
        line: '10/16/2026 Weekend hike',
        referenceDate: refDate,
        defaultYear: 2026,
      );
      expect(resNumeric, isNotNull);
      expect(resNumeric!.date.month, equals(10));
      expect(resNumeric.date.day, equals(16));
    });

    test('parses relative date markers', () {
      final resToday = DateParserEngine.tryParseDateAnchor(
        line: '今天 买了新耳机',
        referenceDate: refDate,
        defaultYear: 2026,
      );
      expect(resToday, isNotNull);
      expect(resToday!.date.day, equals(16));

      final resYesterday = DateParserEngine.tryParseDateAnchor(
        line: '昨天 雨夜漫步',
        referenceDate: refDate,
        defaultYear: 2026,
      );
      expect(resYesterday, isNotNull);
      expect(resYesterday!.date.day, equals(15));
      expect(resYesterday.weather, equals('rainy'));

      final resBeforeYesterday = DateParserEngine.tryParseDateAnchor(
        line: '前天 准备演讲',
        referenceDate: refDate,
        defaultYear: 2026,
      );
      expect(resBeforeYesterday, isNotNull);
      expect(resBeforeYesterday!.date.day, equals(14));
    });

    test('safely ignores date mentions in the middle of sentences (contextual anchor)', () {
      final nonAnchor = DateParserEngine.tryParseDateAnchor(
        line: 'We decided on 2026-10-16 that we should take a trip.',
        referenceDate: refDate,
        defaultYear: 2026,
      );
      expect(nonAnchor, isNull);
    });
  });

  group('Multi-Entry Document Splitting Tests', () {
    test('splits a multi-entry document by date anchors into candidate entries', () {
      const doc = '''
# 2026-10-14 Preparing for Tokyo
Packed my luggage and finished tickets.

# 2026-10-15 Flight Day
Landed at Haneda airport at 4 PM. Took the monorail to the hotel.

# 2026-10-16 晴 Walking in Shinjuku
Visited Gyoen garden. Weather was fantastic!
''';

      final candidates = DateParserEngine.parseDocument(
        text: doc,
        referenceDate: refDate,
      );

      expect(candidates.length, equals(3));

      expect(candidates[0].parsedDate!.day, equals(14));
      expect(candidates[0].title, equals('Preparing for Tokyo'));
      expect(candidates[0].plainText, contains('Packed my luggage'));

      expect(candidates[1].parsedDate!.day, equals(15));
      expect(candidates[1].title, equals('Flight Day'));
      expect(candidates[1].plainText, contains('Landed at Haneda airport'));

      expect(candidates[2].parsedDate!.day, equals(16));
      expect(candidates[2].title, equals('Walking in Shinjuku'));
      expect(candidates[2].weather, equals('sunny'));
      expect(candidates[2].plainText, contains('Visited Gyoen garden'));
    });

    test('Quill Delta JSON invariant: document strictly terminates with newline', () {
      const doc = '''
2026-10-16
Single line content without ending return''';

      final candidates = DateParserEngine.parseDocument(
        text: doc,
        referenceDate: refDate,
      );

      expect(candidates.length, equals(1));
      final decoded = jsonDecode(candidates.first.contentDelta) as List;
      final lastInsert = decoded.last['insert'] as String;
      expect(lastInsert.endsWith('\n'), isTrue);
    });

    test('unanchored plain text fallback creates a single reviewable candidate', () {
      const plainNotes = 'Just random notes without any date headers at all.';
      final candidates = DateParserEngine.parseDocument(
        text: plainNotes,
        referenceDate: refDate,
      );

      expect(candidates.length, equals(1));
      expect(candidates.first.confidence, equals(DateParseConfidence.none));
      expect(candidates.first.plainText, equals(plainNotes));
    });
  });
}

