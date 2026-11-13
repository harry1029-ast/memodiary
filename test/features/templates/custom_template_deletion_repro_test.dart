import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/editor/widgets/scholar_chest/artifact_stationery_fan.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('template_delete_test_');
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Custom Template Deletion & Default Protection', () {
    testWidgets('Default 4 templates have no delete button in stationery fan sub-panel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StationeryFanSubPanel(
              database: db,
              activeTemplateId: 'template_minimalist_white',
              onSelectTemplate: (selected) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the 4 default templates do NOT display any delete buttons
      const defaultTemplateIds = [
        'template_minimalist_white',
        'template_lined_paper',
        'template_weekly_review',
        'template_retro_kraft',
      ];

      for (final templateId in defaultTemplateIds) {
        expect(
          find.byKey(Key('delete_template_$templateId')),
          findsNothing,
          reason: 'Default template $templateId must not be deletable',
        );
      }
    });

    test('Database rejects deletion of all 4 default templates with StateError', () async {
      const defaultTemplateIds = [
        'template_minimalist_white',
        'template_lined_paper',
        'template_weekly_review',
        'template_retro_kraft',
      ];

      for (final defaultId in defaultTemplateIds) {
        expect(
          () => db.templatesDao.deleteCustomTemplate(defaultId),
          throwsA(isA<StateError>()),
          reason: '$defaultId must throw StateError on deletion attempt',
        );
      }
    });

    testWidgets('Custom template displays trash can button and can be deleted with fallback', (tester) async {
      // 1. Create a custom template
      final customTemplate = await db.templatesDao.createCustomTemplate(
        name: 'My Special Paper',
        backgroundType: 'lined',
        backgroundValue: '#FDF7E7',
      );

      Template? currentSelected;
      String activeId = customTemplate.id;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return StationeryFanSubPanel(
                  database: db,
                  activeTemplateId: activeId,
                  onSelectTemplate: (selected) {
                    setState(() {
                      currentSelected = selected;
                      activeId = selected.id;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2. Locate the delete button for the custom template
      final deleteBtnFinder = find.byKey(Key('delete_template_${customTemplate.id}'));
      expect(
        deleteBtnFinder,
        findsOneWidget,
        reason: 'Custom template card must display a delete/trash can button',
      );

      // Verify it shows a trash can icon
      expect(
        find.descendant(
          of: deleteBtnFinder,
          matching: find.byIcon(Icons.delete_outline),
        ),
        findsOneWidget,
      );

      // 3. Tap the delete button to open the confirmation dialog
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      expect(find.text('Delete Custom Template?'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('My Special Paper'),
        ),
        findsOneWidget,
      );

      // 4. Confirm deletion
      final confirmBtn = find.byKey(const Key('confirm_delete_custom_template_button'));
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // 5. Verify the custom template is deleted from DB
      final inDb = await db.templatesDao.getTemplateById(customTemplate.id);
      expect(inDb, isNull, reason: 'Custom template must be removed from the database');

      // 6. Verify custom template card is gone from the sub-panel
      expect(find.text('My Special Paper'), findsNothing);

      // 7. Verify active template fell back to default template
      expect(currentSelected, isNotNull);
      expect(currentSelected!.id, equals('template_minimalist_white'));
    });
  });
}
