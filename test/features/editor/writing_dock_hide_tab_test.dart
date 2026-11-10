import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/features/editor/services/editor_settings_service.dart';
import 'package:memodiary/features/editor/widgets/editor_paper_canvas.dart';
import 'package:memodiary/features/editor/widgets/desk_workstation/closed_brocade_scroll.dart';
import 'package:memodiary/features/editor/widgets/staging_handscroll.dart';
import 'package:memodiary/features/editor/widgets/writing_dock.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/mock_secure_storage.dart';
import '../../helpers/staged_editor_fixture.dart';

const _entryId = 'dock_hide_entry';

/// The Writing Dock's hide tab and the restore tab left in its place; the
/// hidden state is an app-wide preference kept in the local settings store.
void main() {
  final fixture = StagedEditorFixture(entryId: _entryId);
  late MockSecureStorage storage;

  setUp(() async {
    await fixture.setUp();
    storage = MockSecureStorage();
  });
  tearDown(fixture.tearDown);

  Future<void> openEditor(WidgetTester tester) => pumpEntryEditorScreen(
        tester,
        database: fixture.database,
        mediaSandboxService: fixture.sandboxService,
        entryId: _entryId,
        editorSettings: EditorSettingsService(storage: storage),
        viewportSize: const Size(360.0, 780.0),
      );

  Future<void> reopenEditor(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await openEditor(tester);
  }

  final dock = find.byType(WritingDock);
  final hideTab = find.byKey(const Key('writing_dock_hide_tab'));
  final restoreTab = find.byKey(const Key('writing_dock_restore_tab'));

  testWidgets('the tab on the dock top edge hides it and the bottom-right tab restores it', (tester) async {
    await openEditor(tester);
    expect(dock, findsOneWidget);
    expect(restoreTab, findsNothing);

    final hideRect = tester.getRect(hideTab);
    expect(hideRect.width, greaterThanOrEqualTo(44.0));
    expect(hideRect.height, greaterThanOrEqualTo(44.0));
    expect(hideRect.right, closeTo(360.0, 20.0));
    expect(hideRect.bottom, lessThanOrEqualTo(tester.getRect(dock).bottom));
    expect(hideRect.top, greaterThanOrEqualTo(tester.getRect(dock).top));
    expect(find.bySemanticsLabel('收起文房'), findsOneWidget);

    await tester.tap(hideTab);
    await tester.pumpAndSettle();
    expect(dock, findsNothing);
    expect(hideTab, findsNothing);
    final restoreRect = tester.getRect(restoreTab);
    expect(restoreRect.width, greaterThanOrEqualTo(44.0));
    expect(restoreRect.height, greaterThanOrEqualTo(44.0));
    expect(restoreRect.right, closeTo(360.0, 20.0));
    expect(restoreRect.bottom, closeTo(780.0, 1.0));
    expect(restoreRect.overlaps(tester.getRect(find.byKey(const Key('desk_workstation')))), isTrue);
    expect(find.bySemanticsLabel('展开文房'), findsOneWidget);

    await tester.tap(restoreTab);
    await tester.pumpAndSettle();
    expect(dock, findsOneWidget);
    expect(restoreTab, findsNothing);
  });

  testWidgets('the hidden state survives a new editor session', (tester) async {
    await openEditor(tester);
    await tester.tap(hideTab);
    await tester.pumpAndSettle();

    await reopenEditor(tester);
    expect(dock, findsNothing);
    expect(restoreTab, findsOneWidget);

    await tester.tap(restoreTab);
    await tester.pumpAndSettle();
    await reopenEditor(tester);
    expect(dock, findsOneWidget);
  });

  testWidgets('hiding the dock never moves the sheet and gives its space to the desk', (tester) async {
    await openEditor(tester);
    final sheetBefore = tester.getRect(find.byType(TemplateCanvasContainer));
    final canvasBefore = tester.getRect(find.byType(EditorPaperCanvas));
    final workstationBefore = tester.getRect(find.byKey(const Key('desk_workstation')));
    final dockHeight = tester.getRect(dock).height;

    await tester.tap(hideTab);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(TemplateCanvasContainer)), sheetBefore);
    expect(tester.getRect(find.byType(EditorPaperCanvas)).height, greaterThan(canvasBefore.height));
    final workstationAfter = tester.getRect(find.byKey(const Key('desk_workstation')));
    expect(workstationAfter.height, greaterThan(workstationBefore.height));
    // No strip: the workstation reaches the system bar and gains the dock's full height.
    expect(workstationAfter.bottom, 780.0);
    expect(workstationAfter.height - workstationBefore.height, dockHeight);
    expect(tester.getRect(find.byType(EditorPaperCanvas)).bottom, 780.0);
  });

  testWidgets('the floating tab covers neither the handscroll nor the Restore Pill', (tester) async {
    await openEditor(tester);
    await tester.tap(hideTab);
    await tester.pumpAndSettle();
    final tabRect = tester.getRect(restoreTab);
    // The handscroll (or the closed brocade scroll when nothing is staged).
    final scroll = find.byWidgetPredicate((widget) => widget is StagingHandscroll || widget is ClosedBrocadeScroll);
    expect(tabRect.overlaps(tester.getRect(scroll)), isFalse);

    await tester.tap(find.byKey(const Key('workstation_pull_tab')));
    await tester.pumpAndSettle();
    final pill = find.byKey(const Key('workstation_restore_pill'));
    expect(pill, findsOneWidget);
    expect(tabRect.overlaps(tester.getRect(pill)), isFalse);
  });

  testWidgets('neither tab summons or drops the keyboard', (tester) async {
    await openEditor(tester);
    final focused = FocusManager.instance.primaryFocus;
    await tester.tap(hideTab);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, focused);
    await tester.tap(restoreTab);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, focused);
  });
}
