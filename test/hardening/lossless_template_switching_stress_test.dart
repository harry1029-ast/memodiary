import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  group('Lossless Template Switching Stress Test', () {
    test('100 cycles across all 4 templates preserves contentDelta and media attachments 100% byte-identical', () async {
      const entryId = 'stress_entry_template_decoupling';
      const initialTitle = 'Arashiyama Bamboo Grove Travelogue';
      final initialPlainText = 'Trip to Arashiyama Bamboo Grove\nThe morning mist was truly magical and serene.\n'
          'Key moments:\n- Woke up early\n- Drank matcha tea\nSilence is the greatest sanctuary.';

      // 1. Construct rich-text Delta document containing headings, bold, italic, lists, blockquotes, and media embeds
      final initialDelta = jsonEncode([
        {'insert': 'Trip to Arashiyama Bamboo Grove\n', 'attributes': {'header': 1}},
        {'insert': 'The morning mist was '},
        {'insert': 'truly magical', 'attributes': {'bold': true}},
        {'insert': ' and '},
        {'insert': 'serene', 'attributes': {'italic': true}},
        {'insert': '.\n'},
        {'insert': {'image': 'media/bamboo_grove.webp'}},
        {'insert': '\nKey moments:\n'},
        {'insert': 'Woke up at 6:00 AM\n', 'attributes': {'list': 'bullet'}},
        {'insert': 'Drank matcha tea by the river\n', 'attributes': {'list': 'bullet'}},
        {'insert': {'image': 'media/matcha_teahouse.webp'}},
        {'insert': '\n'},
        {'insert': 'Silence is the greatest sanctuary.\n', 'attributes': {'blockquote': true}},
      ]);

      // 2. Insert into SQLite entries table
      await db.createEntry(
        EntriesCompanion.insert(
          id: entryId,
          notebookId: 'default',
          templateId: 'template_minimalist_white',
          title: const Value(initialTitle),
          contentDelta: initialDelta,
          plainText: initialPlainText,
          entryDate: DateTime(2026, 10, 16, 8, 30),
          mood: const Value(5),
          weather: const Value('sunny'),
        ),
      );

      // 3. Attach two sandboxed WebP media attachments
      await db.attachMediaToEntry(
        id: 'media_attachment_1',
        entryId: entryId,
        relativePath: 'media/bamboo_grove.webp',
        mediaType: 'image',
      );
      await db.attachMediaToEntry(
        id: 'media_attachment_2',
        entryId: entryId,
        relativePath: 'media/matcha_teahouse.webp',
        mediaType: 'image',
      );

      // Verify baseline media attachments
      final initialMedia = await db.getMediaForEntry(entryId);
      expect(initialMedia.length, equals(2));

      // 4. Perform 100 consecutive template switches cycling across all 4 templates
      final templateIds = [
        'template_minimalist_white',
        'template_lined_paper',
        'template_retro_kraft',
        'template_weekly_review',
      ];

      for (int cycle = 0; cycle < 100; cycle++) {
        final targetTemplateId = templateIds[cycle % templateIds.length];
        final rowsAffected = await db.updateEntryTemplate(entryId, targetTemplateId);
        expect(rowsAffected, equals(1));
      }

      // 5. Query entry after 100 stress cycles
      final finalEntry = await db.getEntryById(entryId);
      expect(finalEntry, isNotNull);

      // INVARIANT 1: contentDelta JSON string must be 100% byte-for-byte identical
      expect(finalEntry!.contentDelta, equals(initialDelta));

      // INVARIANT 2: plainText must be 100% byte-for-byte identical
      expect(finalEntry.plainText, equals(initialPlainText));

      // INVARIANT 3: title, mood, and weather remain untouched
      expect(finalEntry.title, equals(initialTitle));
      expect(finalEntry.mood, equals(5));
      expect(finalEntry.weather, equals('sunny'));

      // INVARIANT 4: templateId reflects the final cycled template (100 % 4 = 0 -> template_minimalist_white or template_weekly_review)
      final expectedFinalTemplate = templateIds[99 % templateIds.length];
      expect(finalEntry.templateId, equals(expectedFinalTemplate));

      // INVARIANT 5: SQLite media attachments records are 100% intact
      final finalMedia = await db.getMediaForEntry(entryId);
      expect(finalMedia.length, equals(2));
      expect(finalMedia.map((m) => m.relativePath).toSet(), equals({
        'media/bamboo_grove.webp',
        'media/matcha_teahouse.webp',
      }));
    });
  });
}

