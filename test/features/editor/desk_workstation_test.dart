import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/core/services/media_sandbox_service.dart';
import 'package:memodiary/features/editor/widgets/desk_workstation/desk_space_budget.dart';
import 'package:memodiary/features/editor/widgets/editor_paper_canvas.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/widget_test_helpers.dart';

const _entryId = 'desk_workstation_entry';
const _tallViewport = Size(360.0, 780.0);
const _shortViewport = Size(360.0, 600.0);

void main() {
  late AppDatabase database;
  late Directory tempDirectory;
  late MediaSandboxService sandboxService;
  late StubEditorImagePicker picker;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDirectory = Directory.systemTemp.createTempSync('desk_workstation_test_');
    sandboxService = SyncTestMediaSandboxService(tempDir: tempDirectory);
    final photo = File('${tempDirectory.path}/picked_photo.png')..writeAsBytesSync(kValid1x1PngBytes);
    picker = StubEditorImagePicker(imageResult: XFile(photo.path));

    await database.into(database.entries).insert(
          EntriesCompanion.insert(
            id: _entryId,
            notebookId: 'notebook_default',
            templateId: 'template_minimalist_white',
            title: const Value('案头'),
            contentDelta: jsonEncode((Delta()..insert('墨池初研。\n')).toJson()),
            plainText: '墨池初研。',
            entryDate: DateTime(2026, 11, 6, 20),
          ),
        );
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Future<void> openEditor(WidgetTester tester, {Size viewport = _tallViewport}) => pumpEntryEditorScreen(
        tester,
        database: database,
        mediaSandboxService: sandboxService,
        entryId: _entryId,
        imagePicker: picker,
        viewportSize: viewport,
      );

  final workstation = find.byKey(const Key('desk_workstation'));
  final closedScroll = find.byKey(const Key('closed_brocade_scroll'));
  final handscroll = find.byKey(const Key('staging_handscroll'));
  final strip = find.byKey(const Key('sheet_mount_strip'));
  final handle = find.byKey(const Key('writing_dock_workstation_grip'));

  Future<void> pickFromGallery(WidgetTester tester) async {
    await tester.tap(find.text('相册选撷 · Photo Gallery'));
    await tester.pumpAndSettle();
  }

  group('Desk Workstation & Closed Brocade Scroll', () {
    testWidgets('an empty handscroll rests closed on the workstation and tapping it starts collecting', (tester) async {
      await openEditor(tester);

      expect(workstation, findsOneWidget);
      expect(closedScroll, findsOneWidget);
      expect(handscroll, findsNothing);
      expect(find.bySemanticsLabel(RegExp('待贴画卷已空')), findsOneWidget);

      final semantics = tester.ensureSemantics();
      await expectAccessibleTapTargets(tester, within: workstation);
      semantics.dispose();

      await tester.tap(closedScroll);
      await tester.pumpAndSettle();
      await pickFromGallery(tester);

      expect(closedScroll, findsNothing);
      expect(handscroll, findsOneWidget);
      expect(await database.getMediaForEntry(_entryId), hasLength(1));
    });

    testWidgets('the workstation takes the remaining space beneath the sheet down to the desk edge', (tester) async {
      await openEditor(tester);

      final canvasRect = tester.getRect(find.byType(EditorPaperCanvas));
      final sheetRect = tester.getRect(find.byType(TemplateCanvasContainer));
      final workstationRect = tester.getRect(workstation);

      expect(workstationRect.bottom, closeTo(canvasRect.bottom, 0.5));
      expect(workstationRect.top, greaterThanOrEqualTo(sheetRect.bottom));
      expect(workstationRect.height, greaterThanOrEqualTo(110.0));
      expect(workstationRect.width, closeTo(canvasRect.width, 0.5));

      // The sheet docks beneath the desk's header band (no dead desk above it),
      // its seal resting between the sheet and the workstation.
      expect(sheetRect.top - canvasRect.top, closeTo(DeskSpaceBudget.kHeaderHeight, 1.0));
      final sealRect = tester.getRect(find.byKey(const Key('cinnabar_signature_seal')));
      expect(sealRect.top, greaterThanOrEqualTo(sheetRect.bottom));
      expect(sealRect.bottom, lessThanOrEqualTo(workstationRect.top));
    });

    testWidgets('on a short viewport the workstation starts collapsed and the footer handle opens and closes it', (tester) async {
      await openEditor(tester, viewport: _shortViewport);

      expect(workstation, findsNothing);
      expect(find.bySemanticsLabel('展开画案'), findsOneWidget);

      await tester.tap(handle);
      await tester.pumpAndSettle();
      expect(workstation, findsOneWidget);
      expect(closedScroll, findsOneWidget);
      expect(tester.getSize(workstation).height, greaterThanOrEqualTo(110.0));
      expect(find.bySemanticsLabel('收起画案'), findsOneWidget);

      await tester.tap(handle);
      await tester.pumpAndSettle();
      expect(workstation, findsNothing);
    });

    testWidgets('on a tall viewport the footer handle collapses the workstation and restores it', (tester) async {
      await openEditor(tester);
      expect(workstation, findsOneWidget);

      await tester.tap(handle);
      await tester.pumpAndSettle();
      expect(workstation, findsNothing);

      await tester.tap(handle);
      await tester.pumpAndSettle();
      expect(workstation, findsOneWidget);
    });

    testWidgets('collecting while the workstation is collapsed opens it onto the new keepsake', (tester) async {
      await openEditor(tester, viewport: _shortViewport);
      expect(workstation, findsNothing);

      await tester.tap(find.byKey(const Key('writing_dock_photo_btn')));
      await tester.pumpAndSettle();
      await pickFromGallery(tester);

      expect(workstation, findsOneWidget);
      expect(handscroll, findsOneWidget);
    });

    testWidgets('opening the keyboard collapses the workstation and Mount Strip; closing it restores them', (tester) async {
      await openEditor(tester);
      await tester.tap(closedScroll);
      await tester.pumpAndSettle();
      await pickFromGallery(tester);
      final mediaId = (await database.getMediaForEntry(_entryId)).single.id;
      await tester.tap(find.byKey(Key('handscroll_mount_$mediaId')));
      await tester.pumpAndSettle();
      expect(strip, findsOneWidget);
      expect(workstation, findsOneWidget);
      final sheetTop = tester.getRect(find.byType(TemplateCanvasContainer)).top;

      tester.view.viewInsets = const FakeViewPadding(bottom: 300.0);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      expect(strip, findsNothing);
      expect(workstation, findsNothing);
      // The sheet stays put, so the active line stays in view without scrolling.
      expect(tester.getRect(find.byType(TemplateCanvasContainer)).top, closeTo(sheetTop, 1.0));

      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();

      expect(strip, findsOneWidget);
      expect(workstation, findsOneWidget);
    });
  });
}
