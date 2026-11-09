import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/widgets/editor_paper_canvas.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/staged_editor_fixture.dart';

const _entryId = 'desk_actions_keyboard_entry';

/// Quill asks for the keyboard on every change to a focused editor, and Android
/// keeps focus after the keyboard is dismissed. Desk actions must therefore
/// take focus off the sheet so that mounting, unmounting or erasing never
/// summons the keyboard.
void main() {
  final fixture = StagedEditorFixture(entryId: _entryId);

  setUp(fixture.setUp);
  tearDown(fixture.tearDown);

  Future<TextStationerySheet> openEditorWriting(WidgetTester tester) async {
    await pumpEntryEditorScreen(
      tester,
      database: fixture.database,
      mediaSandboxService: fixture.sandboxService,
      entryId: _entryId,
      viewportSize: const Size(360.0, 780.0),
    );
    final sheet = tester
        .widget<EditorPaperCanvas>(find.byType(EditorPaperCanvas))
        .coordinator
        .sheets
        .whereType<TextStationerySheet>()
        .first;
    sheet.focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(sheet.focusNode.hasFocus, isTrue);
    return sheet;
  }

  Iterable<String> inputCalls(WidgetTester tester) => tester.testTextInput.log.map((call) => call.method);

  testWidgets('mounting and unmounting take focus off the sheet and never show the keyboard', (tester) async {
    await fixture.seedStagedPhotos(1);
    final sheet = await openEditorWriting(tester);
    tester.testTextInput.log.clear();

    await tester.tap(find.byKey(const Key('handscroll_mount_seeded_0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sheet_mount_strip')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mount_strip_unmount_seeded_0')));
    await tester.pumpAndSettle();

    expect(sheet.focusNode.hasFocus, isFalse);
    expect(inputCalls(tester), isNot(contains('TextInput.show')));
  });

  testWidgets('erasing a staged item takes focus off the sheet', (tester) async {
    await fixture.seedStagedPhotos(1);
    final sheet = await openEditorWriting(tester);
    tester.testTextInput.log.clear();

    await tester.tap(find.byKey(const Key('handscroll_erase_seeded_0')));
    await tester.pumpAndSettle();

    expect(sheet.focusNode.hasFocus, isFalse);
    expect(inputCalls(tester), isNot(contains('TextInput.show')));
  });

  testWidgets('dismissing the keyboard ends writing: the sheet lets go of focus', (tester) async {
    final sheet = await openEditorWriting(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300.0);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(sheet.focusNode.hasFocus, isTrue);

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();

    expect(sheet.focusNode.hasFocus, isFalse);
  });
}
