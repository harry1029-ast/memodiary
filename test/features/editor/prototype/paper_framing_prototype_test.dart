import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/prototype/breathing_stride_canvas.dart';
import 'package:memodiary/features/editor/prototype/prototype_variant_switcher.dart';
import 'package:memodiary/features/editor/prototype/screen_adaptive_canvas.dart';
import 'package:memodiary/features/editor/prototype/tactile_stationery_card_canvas.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/editor/widgets/journal_letterhead.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late MediaSandboxService sandboxService;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('prototype_test_');
    sandboxService = MediaSandboxService(
      baseDirProvider: () async => tempDir,
      compressor: (sourcePath, targetPath, {minWidth = 1600, minHeight = 1600, quality = 80}) async {
        return File(sourcePath).copy(targetPath);
      },
    );

    await db.into(db.entries).insert(
          EntriesCompanion.insert(
            id: 'prototype_entry_01',
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('Prototype Framing Test'),
            contentDelta: '[]',
            plainText: '',
            entryDate: DateTime(2026, 11, 4, 12, 0),
            mood: const Value(5),
            weather: const Value('sunny'),
          ),
        );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Paper Framing Prototype Switcher & Variants', () {
    testWidgets('renders floating switcher and smoothly cycles across Variant A, B, and C', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: EntryEditorScreen(
            database: db,
            mediaSandboxService: sandboxService,
            entryId: 'prototype_entry_01',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Initial render defaults to Variant A: Tactile Stationery Card
      expect(find.byType(PrototypeVariantSwitcher), findsOneWidget);
      expect(find.text('PROTOTYPE'), findsOneWidget);
      expect(find.text('A: 触感信笺 (Desk Card)'), findsOneWidget);
      expect(find.byType(TactileStationeryCardCanvas), findsOneWidget);
      expect(find.byType(BreathingStrideCanvas), findsNothing);
      expect(find.byType(ScreenAdaptiveCanvas), findsNothing);

      // Verify QuillEditor and JournalLetterhead are active
      expect(find.byType(JournalLetterhead), findsOneWidget);
      expect(find.byType(QuillEditor), findsOneWidget);

      // 2. Tap Next to cycle to Variant B: Breathing Stride
      await tester.tap(find.byKey(const Key('prototype_next_variant_btn')));
      await tester.pumpAndSettle();

      expect(find.text('B: 呼吸行高 (Breathing Stride)'), findsOneWidget);
      expect(find.byType(BreathingStrideCanvas), findsOneWidget);
      expect(find.byType(TactileStationeryCardCanvas), findsNothing);
      expect(find.byType(ScreenAdaptiveCanvas), findsNothing);
      expect(find.byType(QuillEditor), findsOneWidget);

      // 3. Tap Next to cycle to Variant C: Screen Adaptive Full Height
      await tester.tap(find.byKey(const Key('prototype_next_variant_btn')));
      await tester.pumpAndSettle();

      expect(find.text('C: 全高满版 (Full Height)'), findsOneWidget);
      expect(find.byType(ScreenAdaptiveCanvas), findsOneWidget);
      expect(find.byType(TactileStationeryCardCanvas), findsNothing);
      expect(find.byType(BreathingStrideCanvas), findsNothing);
      expect(find.byType(QuillEditor), findsOneWidget);

      // 4. Tap Next to wrap around back to Variant A
      await tester.tap(find.byKey(const Key('prototype_next_variant_btn')));
      await tester.pumpAndSettle();

      expect(find.text('A: 触感信笺 (Desk Card)'), findsOneWidget);
      expect(find.byType(TactileStationeryCardCanvas), findsOneWidget);

      // 5. Tap Prev to cycle backwards to Variant C
      await tester.tap(find.byKey(const Key('prototype_prev_variant_btn')));
      await tester.pumpAndSettle();

      expect(find.text('C: 全高满版 (Full Height)'), findsOneWidget);
      expect(find.byType(ScreenAdaptiveCanvas), findsOneWidget);
    });
  });
}
