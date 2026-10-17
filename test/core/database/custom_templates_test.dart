import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (rawDb) {
          // Enforce foreign keys strictly to verify Watchpoint 3 (deletion order)
          rawDb.execute('PRAGMA foreign_keys = ON;');
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Custom Template Database CRUD & Safety Invariants', () {
    test('createCustomTemplate enforces isCustom = true and persists all styling attributes', () async {
      final created = await db.createCustomTemplate(
        name: 'Lavender Haze',
        backgroundType: 'lined',
        backgroundValue: '#F3E5F5',
        fontFamily: 'Lora',
        lineSpacing: 1.9,
        marginHorizontal: 28.0,
      );

      expect(created.id, startsWith('template_custom_'));
      expect(created.name, equals('Lavender Haze'));
      expect(created.backgroundType, equals('lined'));
      expect(created.backgroundValue, equals('#F3E5F5'));
      expect(created.fontFamily, equals('Lora'));
      expect(created.lineSpacing, equals(1.9));
      expect(created.marginHorizontal, equals(28.0));
      expect(created.isCustom, isTrue);

      final customList = await db.getCustomTemplates();
      expect(customList.length, equals(1));
      expect(customList.first.id, equals(created.id));
    });

    test('updateCustomTemplate modifies custom templates but protects seeded system templates', () async {
      final custom = await db.createCustomTemplate(
        name: 'Initial Custom',
        backgroundType: 'color',
        backgroundValue: '#FFFFFF',
      );

      final updatedRows = await db.updateCustomTemplate(
        custom.id,
        name: 'Updated Mint Grid',
        backgroundType: 'grid',
        backgroundValue: '#E8F5E9',
        lineSpacing: 2.0,
        marginHorizontal: 32.0,
      );
      expect(updatedRows, equals(1));

      final reloaded = await db.getTemplateById(custom.id);
      expect(reloaded!.name, equals('Updated Mint Grid'));
      expect(reloaded.backgroundType, equals('grid'));
      expect(reloaded.backgroundValue, equals('#E8F5E9'));
      expect(reloaded.lineSpacing, equals(2.0));
      expect(reloaded.marginHorizontal, equals(32.0));

      // Attempting to modify a system template must throw StateError
      await expectLater(
        db.updateCustomTemplate(
          'template_minimalist_white',
          name: 'Hacked System Template',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('deleteCustomTemplate protects all 4 seeded system templates from deletion', () async {
      const systemIds = [
        'template_minimalist_white',
        'template_lined_paper',
        'template_retro_kraft',
        'template_weekly_review',
      ];

      for (final sysId in systemIds) {
        await expectLater(
          db.deleteCustomTemplate(sysId),
          throwsA(isA<StateError>()),
        );
      }

      final allTemplates = await db.getAllTemplates();
      expect(allTemplates.length, equals(4));
    });

    test('deleteCustomTemplate atomically reassigns dependent entries to fallback template before deleting (Watchpoint 3)', () async {
      final custom = await db.createCustomTemplate(
        name: 'Ephemeral Theme',
        backgroundType: 'paper_texture',
        backgroundValue: '#EFE6D5',
      );

      const originalDelta = '[{"insert":"Precious diary text that must never be lost.\\n"}]';
      const originalPlain = 'Precious diary text that must never be lost.';

      await db.createEntry(
        EntriesCompanion.insert(
          id: 'entry_using_custom_1',
          notebookId: 'notebook_default',
          templateId: custom.id,
          title: const Value('My Custom Entry'),
          contentDelta: originalDelta,
          plainText: originalPlain,
          entryDate: DateTime(2026, 10, 15, 14, 0),
        ),
      );

      // Delete custom template while PRAGMA foreign_keys = ON is active
      await db.deleteCustomTemplate(custom.id);

      // Verify custom template was removed
      final deletedTemplate = await db.getTemplateById(custom.id);
      expect(deletedTemplate, isNull);

      // Verify entry was safely reassigned to fallback 'template_minimalist_white'
      // and contentDelta / plainText remain 100% intact
      final entryAfter = await db.getEntryById('entry_using_custom_1');
      expect(entryAfter, isNotNull);
      expect(entryAfter!.templateId, equals('template_minimalist_white'));
      expect(entryAfter.contentDelta, equals(originalDelta));
      expect(entryAfter.plainText, equals(originalPlain));
    });
  });
}

