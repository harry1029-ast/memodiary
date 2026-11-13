import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/services/audio_sanctum_service.dart';
import 'package:memodiary/features/editor/widgets/scholar_chest/scholar_chest_drawer.dart';

void main() {
  late AppDatabase db;
  late AudioSanctumService audioSanctumService;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('scholar_chest_live_test_');
    audioSanctumService = AudioSanctumService(enablePlatformAudio: false);

    await db.entriesDao.createEntry(
          EntriesCompanion.insert(
            id: 'test_live_entry',
            notebookId: 'nb_default',
            templateId: 'template_minimalist_white',
            title: const Value('测试日记'),
            contentDelta: '[{"insert":"测试内容\\n"}]',
            plainText: '测试内容',
            entryDate: DateTime.now(),
          ),
        );
  });

  tearDown(() async {
    audioSanctumService.dispose();
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ScholarChestDrawer Live State Sync Reproduction', () {
    testWidgets('Template selection immediately updates highlighted card in drawer without reopening', (tester) async {
      String activeTemplateId = 'template_minimalist_white';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (builderContext) => ElevatedButton(
                onPressed: () {
                  ScholarChestDrawer.show(
                    context: builderContext,
                    database: db,
                    activeTemplateId: activeTemplateId,
                    typography: const TypographySettings(fontSize: 16.0),
                    audioSanctumService: audioSanctumService,
                    initialArtifact: ScholarArtifactType.stationeryFan,
                    onSelectTemplate: (template) {
                      activeTemplateId = template.id;
                    },
                    onTypographyChanged: (typography) {},
                    onLockChanged: (lock) {},
                  );
                },
                child: const Text('Open Chest'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Chest'));
      await tester.pumpAndSettle();

      // Check that template_minimalist_white initially has the checkmark icon
      final checkmarkFinder = find.byIcon(Icons.check);
      expect(checkmarkFinder, findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('chest_template_chip_template_minimalist_white')),
          matching: checkmarkFinder,
        ),
        findsOneWidget,
      );

      // Tap lined paper template card
      await tester.tap(find.byKey(const Key('chest_template_chip_template_lined_paper')));
      await tester.pumpAndSettle();

      // Symptom 1: The checkmark icon MUST now be on template_lined_paper
      expect(
        find.descendant(
          of: find.byKey(const Key('chest_template_chip_template_lined_paper')),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
        reason: 'The newly selected template must show the active checkmark immediately',
      );
    });

    testWidgets('Typography slider changes immediately update slider label in drawer without reopening', (tester) async {
      TypographySettings typography = const TypographySettings(fontSize: 16.0, lineSpacing: 1.5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (builderContext) => ElevatedButton(
                onPressed: () {
                  ScholarChestDrawer.show(
                    context: builderContext,
                    database: db,
                    activeTemplateId: 'template_minimalist_white',
                    typography: typography,
                    audioSanctumService: audioSanctumService,
                    initialArtifact: ScholarArtifactType.brushMountain,
                    onSelectTemplate: (template) {},
                    onTypographyChanged: (newTypography) {
                      typography = newTypography;
                    },
                    onLockChanged: (lock) {},
                  );
                },
                child: const Text('Open Chest'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Chest'));
      await tester.pumpAndSettle();

      // Initial font size is 16pt
      expect(find.text('字形大小 (16pt)'), findsOneWidget);

      // Drag font size slider to 22pt (max is 28, min is 12)
      final sliderFinder = find.byKey(const Key('chest_font_size_slider'));
      expect(sliderFinder, findsOneWidget);

      // Adjust slider value
      final Slider slider = tester.widget(sliderFinder);
      slider.onChanged!(22.0);
      await tester.pumpAndSettle();

      // Symptom 2: The font size text MUST update to 22pt immediately
      expect(
        find.text('字形大小 (22pt)'),
        findsOneWidget,
        reason: 'Font size label must reflect new value without reopening drawer',
      );
    });
  });
}
