import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/templates/screens/custom_template_editor_screen.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('CustomTemplateEditorScreen Widget Tests', () {
    testWidgets('renders live preview and validates required template name before saving', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomTemplateEditorScreen(database: db),
        ),
      );
      await tester.pumpAndSettle();

      // Live preview card and canvas container are rendered
      expect(find.byKey(const Key('template_live_preview_card')), findsOneWidget);
      expect(find.byType(TemplateCanvasContainer), findsOneWidget);

      // Tap Save with empty name -> triggers validation error
      await tester.tap(find.byKey(const Key('save_custom_template_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a template name'), findsOneWidget);
      final customTemplates = await db.getCustomTemplates();
      expect(customTemplates, isEmpty);
    });

    testWidgets('creates a new custom template and persists it to AppDatabase', (tester) async {
      Template? returnedTemplate;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  returnedTemplate = await Navigator.push<Template>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomTemplateEditorScreen(database: db),
                    ),
                  );
                },
                child: const Text('Open Builder'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Builder'));
      await tester.pumpAndSettle();

      // Enter template name
      await tester.enterText(
        find.byKey(const Key('template_name_input')),
        'Mint Grid Studio',
      );
      await tester.pumpAndSettle();

      // Live preview updates title text immediately
      expect(find.text('Mint Grid Studio'), findsWidgets);

      // Select Grid background type
      final gridChip = find.byKey(const Key('bg_type_grid'));
      await tester.ensureVisible(gridChip);
      await tester.pumpAndSettle();
      await tester.tap(gridChip);
      await tester.pumpAndSettle();

      // Select Mint Whisper color swatch (#E8F5E9)
      final mintSwatch = find.byKey(const Key('color_swatch_#E8F5E9'));
      await tester.ensureVisible(mintSwatch);
      await tester.pumpAndSettle();
      await tester.tap(mintSwatch);
      await tester.pumpAndSettle();

      // Save template
      await tester.tap(find.byKey(const Key('save_custom_template_button')));
      await tester.pumpAndSettle();

      expect(returnedTemplate, isNotNull);
      expect(returnedTemplate!.name, equals('Mint Grid Studio'));
      expect(returnedTemplate!.backgroundType, equals('grid'));
      expect(returnedTemplate!.backgroundValue, equals('#E8F5E9'));
      expect(returnedTemplate!.isCustom, isTrue);

      // Verify in database
      final stored = await db.getTemplateById(returnedTemplate!.id);
      expect(stored, isNotNull);
      expect(stored!.name, equals('Mint Grid Studio'));
      expect(stored.isCustom, isTrue);
    });

    testWidgets('allows selecting dot_grid background pattern and saves correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomTemplateEditorScreen(database: db),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('template_name_input')),
        'Zen Dot Grid',
      );
      await tester.pumpAndSettle();

      final dotGridChip = find.byKey(const Key('bg_type_dot_grid'));
      await tester.ensureVisible(dotGridChip);
      await tester.pumpAndSettle();
      await tester.tap(dotGridChip);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save_custom_template_button')));
      await tester.pumpAndSettle();

      final customTemplates = await db.getCustomTemplates();
      final created = customTemplates.firstWhere((template) => template.name == 'Zen Dot Grid');
      expect(created.backgroundType, equals('dot_grid'));
    });
  });
}
