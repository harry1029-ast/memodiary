import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/editor/services/audio_sanctum_service.dart';
import 'package:memodiary/features/editor/widgets/scholar_chest/scholar_chest_drawer.dart';

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;
  late Directory tempDir;
  late AudioSanctumService audioSanctumService;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('scholar_chest_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
    );
    audioSanctumService = AudioSanctumService(enablePlatformAudio: false);

    // Seed test entry
    await db.into(db.entries).insert(
          EntriesCompanion.insert(
            id: 'test_chest_entry',
            notebookId: 'nb_default',
            templateId: 'template_blank_white',
            title: const Value('锦盒测试日记'),
            contentDelta: '[{"insert":"文房百宝，锦盒雅致。\\n"}]',
            plainText: '文房百宝，锦盒雅致。',
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

  group('ScholarChestDrawer Unit & Interaction Tests', () {
    testWidgets('renders all 5 artifacts and dismisses on handle tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  ScholarChestDrawer.show(
                    context: ctx,
                    database: db,
                    activeTemplateId: 'template_blank_white',
                    typography: const TypographySettings(fontSize: 16.0),
                    audioSanctumService: audioSanctumService,
                    onSelectTemplate: (_) {},
                    onTypographyChanged: (_) {},
                    onLockChanged: (_) {},
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

      // Drawer is open
      expect(find.byKey(const Key('scholar_chest_drawer')), findsOneWidget);
      expect(find.text('文房百宝匣 · 锦盒书案'), findsOneWidget);

      // Verify all 5 artifacts exist
      expect(find.byKey(const Key('chest_artifact_twin_brushes')), findsOneWidget);
      expect(find.byKey(const Key('chest_artifact_stationery_fan')), findsOneWidget);
      expect(find.byKey(const Key('chest_artifact_brush_mountain')), findsOneWidget);
      expect(find.byKey(const Key('chest_artifact_guqin_zither')), findsOneWidget);
      expect(find.byKey(const Key('chest_artifact_fish_lock')), findsOneWidget);

      // Tap dismissal handle
      await tester.tap(find.byKey(const Key('chest_dismiss_handle')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scholar_chest_drawer')), findsNothing);
    });

    testWidgets('Twin Bamboo Brushes displays poetic placeholder sub-panel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScholarChestDrawer(
              database: db,
              activeTemplateId: 'template_blank_white',
              typography: const TypographySettings(fontSize: 16.0),
              audioSanctumService: audioSanctumService,
              initialArtifact: ScholarArtifactType.twinBrushes,
              onSelectTemplate: (_) {},
              onTypographyChanged: (_) {},
              onLockChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chest_subpanel_twin_brushes')), findsOneWidget);
      expect(find.text('笔锋运墨动效 · 敬请期待'), findsOneWidget);
      expect(find.textContaining('双管并提'), findsOneWidget);
    });

    testWidgets('Porcelain Brush Mountain adjusts typography and center alignment', (tester) async {
      TypographySettings? updatedTypography;
      bool alignmentToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScholarChestDrawer(
              database: db,
              activeTemplateId: 'template_blank_white',
              typography: const TypographySettings(fontSize: 16.0, lineSpacing: 1.5),
              audioSanctumService: audioSanctumService,
              initialArtifact: ScholarArtifactType.brushMountain,
              onSelectTemplate: (_) {},
              onTypographyChanged: (typography) => updatedTypography = typography,
              onLockChanged: (_) {},
              onToggleAlignment: () => alignmentToggled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sliders exist
      expect(find.byKey(const Key('chest_font_size_slider')), findsOneWidget);
      expect(find.byKey(const Key('chest_line_spacing_slider')), findsOneWidget);

      // Tap alignment toggle button
      await tester.tap(find.byKey(const Key('chest_poetry_align_button')));
      await tester.pumpAndSettle();
      expect(alignmentToggled, isTrue);

      // Change font family
      await tester.tap(find.byKey(const Key('chest_font_family_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Noto Serif').first);
      await tester.pumpAndSettle();
      expect(updatedTypography, isNotNull);
    });

    testWidgets('Guqin Zither controls ambient soundscapes and volume', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScholarChestDrawer(
              database: db,
              activeTemplateId: 'template_blank_white',
              typography: const TypographySettings(fontSize: 16.0),
              audioSanctumService: audioSanctumService,
              initialArtifact: ScholarArtifactType.guqinZither,
              onSelectTemplate: (_) {},
              onTypographyChanged: (_) {},
              onLockChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chest_soundscape_chip_rain')), findsOneWidget);
      expect(find.byKey(const Key('chest_soundscape_volume_slider')), findsOneWidget);

      // Select rain preset
      await tester.tap(find.byKey(const Key('chest_soundscape_chip_rain')));
      await tester.pumpAndSettle();

      expect(audioSanctumService.activePreset, equals(SoundscapePreset.gentleRain));
      expect(audioSanctumService.isPlaying, isTrue);

      // Stop button appears and can stop playback
      expect(find.byKey(const Key('chest_soundscape_stop_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('chest_soundscape_stop_button')));
      await tester.pumpAndSettle();
      expect(audioSanctumService.isPlaying, isFalse);
    });

    testWidgets('Brass Fish Lock triggers lock presets and clears unlockAt', (tester) async {
      DateTime? lockedAt;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScholarChestDrawer(
              database: db,
              activeTemplateId: 'template_blank_white',
              typography: const TypographySettings(fontSize: 16.0),
              audioSanctumService: audioSanctumService,
              initialArtifact: ScholarArtifactType.fishLock,
              onSelectTemplate: (_) {},
              onTypographyChanged: (_) {},
              onLockChanged: (dt) => lockedAt = dt,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('当前未封缄 · 随笔随览'), findsOneWidget);

      // Tap +30 days preset
      await tester.tap(find.byKey(const Key('chest_lock_preset_1month')));
      await tester.pumpAndSettle();

      expect(lockedAt, isNotNull);
      expect(lockedAt!.isAfter(DateTime.now().add(const Duration(days: 28))), isTrue);
    });
  });

  group('EntryEditorScreen Dual Chest Triggers & Indicator Pills Tests', () {
    testWidgets('opens ScholarChestDrawer from top bar emblem button and WritingDock pull handle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: mediaService,
            entryId: 'test_chest_entry',
            audioSanctumService: audioSanctumService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Open from top bar emblem
      final topBtn = find.byKey(const Key('top_bar_scholar_chest_button'));
      expect(topBtn, findsOneWidget);
      await tester.tap(topBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scholar_chest_drawer')), findsOneWidget);

      // Dismiss
      await tester.tap(find.byKey(const Key('chest_dismiss_handle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scholar_chest_drawer')), findsNothing);

      // 2. Open from dock pull handle
      final dockBtn = find.byKey(const Key('dock_scholar_chest_button'));
      expect(dockBtn, findsOneWidget);
      await tester.tap(dockBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scholar_chest_drawer')), findsOneWidget);
    });

    testWidgets('displays soundscape pill when music is playing and opens Guqin zither', (tester) async {
      await audioSanctumService.play(SoundscapePreset.bambooBreeze);

      await tester.pumpWidget(
        MaterialApp(
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: mediaService,
            entryId: 'test_chest_entry',
            audioSanctumService: audioSanctumService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pill = find.byKey(const Key('top_bar_soundscape_pill'));
      expect(pill, findsOneWidget);
      expect(find.text('清音'), findsOneWidget);

      // Tapping pill opens chest directly into Guqin Zither
      await tester.tap(pill);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scholar_chest_drawer')), findsOneWidget);
      expect(find.text('书斋清音 · 琴韵自然'), findsOneWidget);
    });

    testWidgets('Fanned Stationery exposes curated suites and selects wenfang suite', (tester) async {
      Template? selectedTemplate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScholarChestDrawer(
              database: db,
              activeTemplateId: 'template_blank_white',
              typography: const TypographySettings(fontSize: 16.0),
              audioSanctumService: audioSanctumService,
              initialArtifact: ScholarArtifactType.stationeryFan,
              onSelectTemplate: (template) => selectedTemplate = template,
              onTypographyChanged: (_) {},
              onLockChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Curated suites title exists
      expect(find.text('典藏雅笺 · 四时风致'), findsOneWidget);
      expect(find.byKey(const Key('chest_suite_chip_wenfang')), findsOneWidget);
      expect(find.byKey(const Key('chest_suite_chip_lengjin')), findsOneWidget);

      // Select wenfang suite
      await tester.tap(find.byKey(const Key('chest_suite_chip_wenfang')));
      await tester.pumpAndSettle();

      expect(selectedTemplate, isNotNull);
      expect(selectedTemplate!.id, 'suite_wenfang');
      expect(selectedTemplate!.name, '文房遗韵 · 朱丝宣纸');
    });

    testWidgets('Poetry alignment button in Brush Mountain toggles editor center alignment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: mediaService,
            entryId: 'test_chest_entry',
            audioSanctumService: audioSanctumService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open chest and navigate to Brush Mountain
      await tester.tap(find.byKey(const Key('top_bar_scholar_chest_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chest_artifact_brush_mountain')));
      await tester.pumpAndSettle();

      // Tap poetry alignment button
      expect(find.byKey(const Key('chest_poetry_align_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('chest_poetry_align_button')));
      await tester.pumpAndSettle();
    });
  });
}
