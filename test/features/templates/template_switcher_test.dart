import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/templates/widgets/template_switcher_sheet.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Template Switching Core Invariant Tests', () {
    test('swapping templateId updates presentation without mutating contentDelta or plainText', () async {
      const originalDelta = '[{"insert":"A precious memory of sunset at the lake.\\n"}]';
      const originalText = 'A precious memory of sunset at the lake.';

      // Insert entry with initial template
      await db.into(db.entries).insert(
            EntriesCompanion.insert(
              id: 'entry_swap_test',
              notebookId: 'notebook_default',
              templateId: 'template_minimalist_white',
              title: const Value('Lake Sunset'),
              contentDelta: originalDelta,
              plainText: originalText,
              entryDate: DateTime.now(),
            ),
          );

      // Verify initial state
      final before = await db.getEntryById('entry_swap_test');
      expect(before, isNotNull);
      expect(before!.templateId, 'template_minimalist_white');
      expect(before.contentDelta, originalDelta);
      expect(before.plainText, originalText);

      // Swap template to Retro Kraft Scrapbook
      final rowsUpdated = await db.updateEntryTemplate(
        'entry_swap_test',
        'template_retro_kraft',
      );
      expect(rowsUpdated, 1);

      // Verify template changed, but Delta & plainText remain 100% unchanged
      final after = await db.getEntryById('entry_swap_test');
      expect(after, isNotNull);
      expect(after!.templateId, 'template_retro_kraft');
      expect(after.contentDelta, equals(originalDelta));
      expect(after.plainText, equals(originalText));
    });

    testWidgets('TemplateSwitcherSheet renders all templates and triggers selection', (tester) async {
      final templates = await db.select(db.templates).get();
      Template? selectedTemplate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  TemplateSwitcherSheet.show(
                    context: context,
                    templates: templates,
                    currentTemplateId: 'template_minimalist_white',
                    onTemplateSelected: (t) => selectedTemplate = t,
                  );
                },
                child: const Text('Open Switcher'),
              ),
            ),
          ),
        ),
      );

      // Tap button to open sheet
      await tester.tap(find.text('Open Switcher'));
      await tester.pumpAndSettle();

      expect(find.text('Switch Template'), findsOneWidget);
      expect(find.text('Minimalist White'), findsOneWidget);
      expect(find.text('Retro Kraft Scrapbook'), findsOneWidget);

      // Tap on Retro Kraft Scrapbook
      await tester.tap(find.text('Retro Kraft Scrapbook'));
      await tester.pumpAndSettle();

      expect(selectedTemplate, isNotNull);
      expect(selectedTemplate!.id, 'template_retro_kraft');
      // Bottom sheet is dismissed
      expect(find.text('Switch Template'), findsNothing);
    });

    testWidgets('TemplateSwitcherSheet supports deleting a custom template and falls back safely', (tester) async {
      final custom = await db.createCustomTemplate(
        name: 'Sky Blue Custom',
        backgroundType: 'lined',
        backgroundValue: '#E3F2FD',
      );
      final templates = await db.getAllTemplates();
      Template? activeSelection = custom;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  TemplateSwitcherSheet.show(
                    context: context,
                    templates: templates,
                    currentTemplateId: custom.id,
                    database: db,
                    onTemplateSelected: (t) => activeSelection = t,
                  );
                },
                child: const Text('Open Switcher With DB'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Switcher With DB'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('new_custom_template_button')), findsOneWidget);
      expect(find.text('Sky Blue Custom'), findsOneWidget);

      // Scroll or locate delete icon for custom template
      await tester.ensureVisible(find.byKey(Key('delete_template_${custom.id}')));
      await tester.tap(find.byKey(Key('delete_template_${custom.id}')));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Delete Custom Template?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm_delete_custom_template_button')));
      await tester.pumpAndSettle();

      // Custom template is removed and activeSelection fell back to Minimalist White
      expect(find.text('Sky Blue Custom'), findsNothing);
      expect(activeSelection!.id, equals('template_minimalist_white'));
    });
  });
}
