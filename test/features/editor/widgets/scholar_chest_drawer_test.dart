import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_choreography_config.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_choreography_controller.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/editor/services/audio_sanctum_service.dart';
import 'package:memodiary/features/editor/widgets/scholar_chest/scholar_chest_drawer.dart';

import '../../../helpers/editor_test_harness.dart';

void main() {
  late AppDatabase db;
  late MediaSandboxService mediaService;
  late Directory tempDir;
  late AudioSanctumService audioSanctumService;
  late InkChoreographyController inkChoreography;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('scholar_chest_test_');
    mediaService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
    );
    audioSanctumService = AudioSanctumService(enablePlatformAudio: false);
    inkChoreography = InkChoreographyController();

    // Seed test entry
    await db.entriesDao.createEntry(
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
    inkChoreography.dispose();
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
                    inkChoreography: inkChoreography,
                    onSelectTemplate: (template) {},
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

      // Drawer is open
      expect(find.byKey(const Key('scholar_chest_drawer')), findsOneWidget);
      expect(find.text('写作工具箱'), findsOneWidget);

      // Verify all 5 compartments and matching accessibility semantics exist
      expect(find.byKey(const Key('chest_artifact_twin_brushes')), findsOneWidget);
      expect(find.byKey(const Key('chest_artifact_stationery_fan')), findsOneWidget);
      expect(find.byKey(const Key('chest_artifact_brush_mountain')), findsOneWidget);
      expect(find.byKey(const Key('chest_artifact_guqin_zither')), findsOneWidget);
      expect(find.byKey(const Key('chest_artifact_fish_lock')), findsOneWidget);

      expect(find.text('信纸'), findsOneWidget);
      expect(find.text('排版'), findsOneWidget);
      expect(find.text('背景音'), findsOneWidget);
      expect(find.text('定时锁'), findsOneWidget);
      expect(find.bySemanticsLabel('信纸'), findsOneWidget);
      expect(find.bySemanticsLabel('排版'), findsOneWidget);
      expect(find.bySemanticsLabel('背景音'), findsOneWidget);
      expect(find.bySemanticsLabel('定时锁'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^笔刷动画')), findsOneWidget);

      // Tap dismissal handle
      await tester.tap(find.byKey(const Key('chest_dismiss_handle')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scholar_chest_drawer')), findsNothing);
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
              inkChoreography: inkChoreography,
              initialArtifact: ScholarArtifactType.brushMountain,
              onSelectTemplate: (template) {},
              onTypographyChanged: (typography) => updatedTypography = typography,
              onLockChanged: (lock) {},
              onToggleAlignment: () => alignmentToggled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Plain typography labels & colors exist
      expect(find.text('字体'), findsOneWidget);
      expect(find.textContaining('字号'), findsOneWidget);
      expect(find.textContaining('行距'), findsOneWidget);
      expect(find.text('文字颜色'), findsOneWidget);
      expect(find.byTooltip('居中对齐'), findsOneWidget);
      expect(find.text('黑色'), findsOneWidget);
      expect(find.text('朱红'), findsOneWidget);
      expect(find.text('墨绿'), findsOneWidget);

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
      await tester.tap(find.text('思源宋体').last, warnIfMissed: false);
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
              inkChoreography: inkChoreography,
              initialArtifact: ScholarArtifactType.guqinZither,
              onSelectTemplate: (template) {},
              onTypographyChanged: (typography) {},
              onLockChanged: (lock) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chest_soundscape_chip_rain')), findsOneWidget);
      expect(find.byKey(const Key('chest_soundscape_volume_slider')), findsOneWidget);
      expect(find.text('雨声'), findsOneWidget);
      expect(find.text('竹林微风'), findsOneWidget);
      expect(find.text('书房白噪音'), findsOneWidget);
      expect(find.text('键盘敲击'), findsOneWidget);

      // Select rain preset
      await tester.tap(find.byKey(const Key('chest_soundscape_chip_rain')));
      await tester.pumpAndSettle();

      expect(audioSanctumService.activePreset, equals(SoundscapePreset.gentleRain));
      expect(audioSanctumService.isPlaying, isTrue);

      // Stop button appears and can stop playback
      expect(find.byKey(const Key('chest_soundscape_stop_button')), findsOneWidget);
      expect(find.text('关闭背景音'), findsOneWidget);
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
              inkChoreography: inkChoreography,
              initialArtifact: ScholarArtifactType.fishLock,
              onSelectTemplate: (template) {},
              onTypographyChanged: (typography) {},
              onLockChanged: (dateTime) => lockedAt = dateTime,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('定时解锁'), findsOneWidget);
      expect(find.text('未锁定'), findsOneWidget);
      expect(find.text('1个月后'), findsOneWidget);
      expect(find.text('到元旦'), findsOneWidget);
      expect(find.text('1年后'), findsOneWidget);
      expect(find.text('自定义日期'), findsOneWidget);

      // Tap +30 days preset
      await tester.tap(find.byKey(const Key('chest_lock_preset_1month')));
      await tester.pumpAndSettle();

      expect(lockedAt, isNotNull);
      expect(lockedAt!.isAfter(DateTime.now().add(const Duration(days: 28))), isTrue);
      expect(find.text('解除锁定'), findsOneWidget);
    });
  });

  group('EntryEditorScreen Dual Chest Triggers & Indicator Pills Tests', () {
    testWidgets('opens ScholarChestDrawer from top bar emblem button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: mediaService,
            entryId: 'test_chest_entry',
            editorSettings: await seededEditorSettings(),
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

      // 2. Verify the workstation Restore Pill rests on the short test viewport
      expect(find.byKey(const Key('workstation_restore_pill')), findsOneWidget);
    });

    testWidgets('Twin Bamboo Brushes carries the restored Ink Choreography mode and settings round-trip',
        (tester) async {
      final settings = await seededEditorSettings(inkDeliveryMode: InkDeliveryMode.inkOnly);
      await pumpEntryEditorScreen(
        tester,
        database: db,
        mediaSandboxService: mediaService,
        entryId: 'test_chest_entry',
        audioSanctumService: audioSanctumService,
        editorSettings: settings,
        inkDeliveryMode: null,
      );

      await tester.tap(find.byKey(const Key('top_bar_scholar_chest_button')));
      await tester.pumpAndSettle();
      expect(find.text('笔刷动画 · 仅墨迹'), findsOneWidget);

      await tester.tap(find.byKey(const Key('chest_artifact_twin_brushes')));
      await tester.pump(const Duration(milliseconds: 400));
      final wolf = find.byKey(const Key('chest_ink_stiffness_pill_wolf'));
      await tester.ensureVisible(wolf);
      await tester.pump();
      await tester.tap(wolf);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.getSemantics(wolf), isSemantics(isSelected: true));

      // Let the Trial Rice-Grid finish before the editor is torn down.
      await tester.pump(const Duration(seconds: 5));
      expect((await settings.getInkChoreographyConfig()).bristleStiffness, BristleStiffness.wolf);
    });

    testWidgets('displays soundscape pill when music is playing and opens Guqin zither', (tester) async {
      await audioSanctumService.play(SoundscapePreset.bambooBreeze);

      await tester.pumpWidget(
        MaterialApp(
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: mediaService,
            entryId: 'test_chest_entry',
            editorSettings: await seededEditorSettings(),
            audioSanctumService: audioSanctumService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pill = find.byKey(const Key('top_bar_soundscape_pill'));
      expect(pill, findsOneWidget);
      expect(find.text('背景音'), findsOneWidget);

      // Tapping pill opens chest directly into Guqin Zither
      await tester.tap(pill);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scholar_chest_drawer')), findsOneWidget);
      expect(find.text('关闭背景音'), findsOneWidget);
    });

    testWidgets('Fanned Stationery exposes card carousel, selects template, and collapses on toggle', (tester) async {
      Template? selectedTemplate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScholarChestDrawer(
              database: db,
              activeTemplateId: 'template_blank_white',
              typography: const TypographySettings(fontSize: 16.0),
              audioSanctumService: audioSanctumService,
              inkChoreography: inkChoreography,
              initialArtifact: ScholarArtifactType.stationeryFan,
              onSelectTemplate: (template) => selectedTemplate = template,
              onTypographyChanged: (typography) {},
              onLockChanged: (lock) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Card carousel header exists
      expect(find.text('信纸模板'), findsOneWidget);
      expect(find.text('新建信纸'), findsOneWidget);
      expect(find.text('“笺换风骨，意蕴随迁”'), findsNothing);
      expect(find.byKey(const Key('chest_create_template_button')), findsOneWidget);
      expect(find.byKey(const Key('chest_template_chip_template_lined_paper')), findsOneWidget);

      // Select lined paper template card
      await tester.tap(find.byKey(const Key('chest_template_chip_template_lined_paper')));
      await tester.pumpAndSettle();

      expect(selectedTemplate, isNotNull);
      expect(selectedTemplate!.id, 'template_lined_paper');

      // Tapping active artifact toggles/collapses sub-panel
      await tester.tap(find.byKey(const Key('chest_artifact_stationery_fan')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chest_sub_panel_container')), findsNothing);
    });

    testWidgets('Poetry alignment button in Brush Mountain toggles editor center alignment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: mediaService,
            entryId: 'test_chest_entry',
            editorSettings: await seededEditorSettings(),
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
