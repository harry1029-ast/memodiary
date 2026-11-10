import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/widgets/desk_workstation/desk_space_budget.dart';
import 'package:memodiary/features/editor/widgets/editor_paper_canvas.dart';
import 'package:memodiary/features/editor/widgets/fullscreen_media_lightbox.dart';
import 'package:memodiary/features/editor/widgets/paper_heart_metrics.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/tucked_prints_test_helpers.dart';
import '../../helpers/widget_test_helpers.dart';

const _entryId = 'tucked_prints_entry';
const _viewport = Size(360.0, 780.0);

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;

  setUpAll(() {
    VideoPlayerPlatform.instance = FakeEditorVideoPlatform();
  });

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('tucked_prints_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  /// Seeds an entry whose first passage carries [mounted] markers (`print_0` ...)
  /// and [staged] attachments without markers (`staged_0` ...). [videoIds] are
  /// attached as videos.
  Future<void> seedEntry({int mounted = 0, int staged = 0, Set<String> videoIds = const {}}) async {
    final mountedIds = [for (var index = 0; index < mounted; index++) 'print_$index'];
    final stagedIds = [for (var index = 0; index < staged; index++) 'staged_$index'];
    await database.into(database.entries).insert(
          EntriesCompanion.insert(
            id: _entryId,
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('江南雨景'),
            contentDelta: jsonEncode([
              {'insert': '雨巷。'},
              for (final mediaId in mountedIds)
                {
                  'insert': {'mount': mediaId},
                },
              {'insert': '\n'},
            ]),
            plainText: '雨巷。',
            entryDate: DateTime(2026, 11, 4, 21, 30),
          ),
        );
    for (final mediaId in [...mountedIds, ...stagedIds]) {
      final isVideo = videoIds.contains(mediaId);
      final relativePath = isVideo ? 'media/$mediaId.mp4' : 'media/$mediaId.webp';
      File('${tempDirectory.path}/$relativePath')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(isVideo ? kValidMp4FtypBytes : kValid1x1PngBytes);
      await database.attachMediaToEntry(
        id: mediaId,
        entryId: _entryId,
        relativePath: relativePath,
        mediaType: isVideo ? 'video' : 'image',
      );
    }
  }

  Future<void> openEditor(WidgetTester tester) => pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: _entryId,
        viewportSize: _viewport,
      );

  Rect sheetRect(WidgetTester tester) => tester.getRect(find.byType(TemplateCanvasContainer));
  final workstation = find.byKey(const Key('desk_workstation'));

  group('Tucked Prints at rest', () {
    testWidgets('a sheet with no mounts shows no prints', (tester) async {
      await seedEntry(staged: 1);
      await openEditor(tester);

      expect(tuckedPrintsFan, findsNothing);
      expect(tuckedPrint('staged_0'), findsNothing);
    });

    testWidgets('one to three mounts peek out above the sheet\'s top right edge, in mount order', (tester) async {
      await seedEntry(mounted: 3);
      await openEditor(tester);

      final sheet = sheetRect(tester);
      final canvas = tester.getRect(find.byType(EditorPaperCanvas));
      final lefts = <double>[];
      for (var index = 0; index < 3; index++) {
        final printRect = tester.getRect(tuckedPrint('print_$index'));
        // Its top shows in the header band, the rest is tucked behind the sheet.
        expect(printRect.top, lessThan(sheet.top), reason: 'print_$index');
        expect(printRect.top, greaterThanOrEqualTo(sheet.top - DeskSpaceBudget.kHeaderHeight - 1.0));
        expect(printRect.bottom, greaterThan(sheet.top));
        expect(printRect.width, closeTo(40.0, 4.0));
        expect(printRect.center.dx, greaterThan(canvas.center.dx));
        lefts.add(printRect.left);
      }
      expect(lefts, orderedEquals([...lefts]..sort()));
      expect(find.descendant(of: tuckedPrintsFan, matching: find.textContaining('+')), findsNothing);
    });

    testWidgets('a legacy sheet with more than three mounts shows three plus "+N"', (tester) async {
      await seedEntry(mounted: 5);
      await openEditor(tester);

      final coordinator = tester.widget<EditorPaperCanvas>(find.byType(EditorPaperCanvas)).coordinator;
      expect((coordinator.sheets.first as TextStationerySheet).mediaAttachments, hasLength(5));
      expect(tuckedPrint('print_0'), findsOneWidget);
      expect(tuckedPrint('print_2'), findsOneWidget);
      expect(tuckedPrint('print_3'), findsNothing);
      expect(find.descendant(of: tuckedPrintsFan, matching: find.text('+2')), findsOneWidget);
    });

    testWidgets('a video\'s print carries a cinnabar ▶ stamp', (tester) async {
      await seedEntry(mounted: 2, videoIds: {'print_1'});
      await openEditor(tester);

      expect(find.byKey(const Key('tucked_print_play_print_1')), findsOneWidget);
      expect(find.byKey(const Key('tucked_print_play_print_0')), findsNothing);
    });

    testWidgets('there is no band below the sheet: the workstation fills the desk beneath it', (tester) async {
      await seedEntry(mounted: 3);
      await openEditor(tester);

      final sheet = sheetRect(tester);
      final canvas = tester.getRect(find.byType(EditorPaperCanvas));
      final workstationRect = tester.getRect(workstation);
      expect(sheet.top - canvas.top, closeTo(DeskSpaceBudget.kHeaderHeight, 1.0));
      expect(workstationRect.bottom, closeTo(canvas.bottom, 0.5));
      // Only the seal's room separates the sheet from the workstation.
      expect(
        workstationRect.top - sheet.bottom,
        lessThanOrEqualTo(PaperHeartMetrics.kDefaultSealSize + 16.0 + 2.0),
      );
      // Mounted items no longer displace the seal on the last sheet.
      expect(find.byType(BoundedCinnabarSeal), findsOneWidget);
    });

    testWidgets('the fan is one 44×44 target labelled with its count', (tester) async {
      final semantics = tester.ensureSemantics();
      await seedEntry(mounted: 2);
      await openEditor(tester);

      final fanSize = tester.getSize(tuckedPrintsFan);
      expect(fanSize.width, greaterThanOrEqualTo(44.0));
      expect(fanSize.height, greaterThanOrEqualTo(44.0));
      expect(find.bySemanticsLabel('本页夹页影札 2 枚，轻触展开'), findsOneWidget);
      await expectAccessibleTapTargets(tester, within: tuckedPrintsFan);
      semantics.dispose();
    });

    testWidgets('tapping the fan opens the mounted items in the lightbox', (tester) async {
      await seedEntry(mounted: 2);
      await openEditor(tester);

      await tester.tap(tuckedPrintsFan);
      await tester.pumpAndSettle();

      expect(find.byType(FullscreenMediaLightbox), findsOneWidget);
    });

    testWidgets('with the keyboard open the prints stay with the header band and the sheet', (tester) async {
      await seedEntry(mounted: 1);
      await openEditor(tester);
      final restingGap = sheetRect(tester).top - tester.getRect(tuckedPrint('print_0')).top;

      final sheet = tester
          .widget<EditorPaperCanvas>(find.byType(EditorPaperCanvas))
          .coordinator
          .sheets
          .whereType<TextStationerySheet>()
          .first;
      sheet.focusNode.requestFocus();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300.0);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      expect(tuckedPrint('print_0'), findsOneWidget);
      expect(sheetRect(tester).top - tester.getRect(tuckedPrint('print_0')).top, closeTo(restingGap, 0.5));
    });
  });

  group('Sheet-Paired Ephemera Auto-Spill Invariant', () {
    testWidgets('typing past row 14 auto-spills onto Sheet 2, retaining Sheet 1 prints on Sheet 1', (tester) async {
      await seedEntry(mounted: 1);
      await openEditor(tester);

      final coordinator = tester.widget<EditorPaperCanvas>(find.byType(EditorPaperCanvas)).coordinator;
      expect(coordinator.sheets.length, equals(1));
      final sheet1 = coordinator.sheets[0] as TextStationerySheet;
      expect(sheet1.mediaAttachments.single.id, 'print_0');

      final longProse = List.generate(16, (index) => '第 $index 行细雨蒙蒙落入青石古巷。').join('\n');
      // Write after the marker so the mounted passage stays at the top of Sheet 1.
      sheet1.controller.document.insert(sheet1.controller.document.length - 1, longProse);
      sheet1.controller.updateSelection(
        TextSelection.collapsed(offset: sheet1.controller.document.length - 1),
        ChangeSource.local,
      );

      coordinator.checkAndPerformAutoSpill(0);
      await tester.pumpAndSettle();

      expect(coordinator.sheets.length, greaterThanOrEqualTo(2));
      expect((coordinator.sheets[0] as TextStationerySheet).mediaAttachments.single.id, 'print_0');
      expect((coordinator.sheets[1] as TextStationerySheet).mediaAttachments, isEmpty);
    });
  });
}
