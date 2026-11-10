import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/services/dictation_service.dart';
import 'package:memodiary/features/editor/screens/entry_editor_screen.dart';
import 'package:memodiary/features/editor/services/editor_settings_service.dart';
import 'package:memodiary/features/editor/widgets/dictation_bar.dart';
import 'package:memodiary/features/editor/widgets/editor_paper_canvas.dart';
import 'package:memodiary/features/editor/widgets/journal_letterhead.dart';
import 'package:memodiary/features/editor/widgets/keyboard_accessory_row.dart';
import 'package:memodiary/features/editor/widgets/writing_dock.dart';
import 'package:memodiary/features/editor/widgets/writing_dock_formatting_ribbon.dart';
import 'package:memodiary/features/templates/widgets/template_canvas_container.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/fake_speech_to_text.dart';
import '../../helpers/mock_secure_storage.dart';
import '../../helpers/soft_keyboard_test_helpers.dart';
import '../../helpers/staged_editor_fixture.dart';
import '../../helpers/widget_test_helpers.dart';

const _entryId = 'typing_chrome_entry';

/// The editor's chrome while the software keyboard is open: the app bar
/// slides away (a save-state dot stands in for it in the header band) and the
/// Writing Dock gives way to a slim accessory row.
void main() {
  final fixture = StagedEditorFixture(entryId: _entryId);

  setUp(fixture.setUp);
  tearDown(fixture.tearDown);

  Future<void> openEditor(WidgetTester tester, {DictationService? dictationService, bool launchFromRoute = false}) async {
    simulatePhoneSystemBars(tester);
    await pumpEntryEditorScreen(
      tester,
      database: fixture.database,
      mediaSandboxService: fixture.sandboxService,
      entryId: _entryId,
      dictationService: dictationService,
      editorSettings: EditorSettingsService(storage: MockSecureStorage()),
      viewportSize: const Size(360.0, 780.0),
      launchFromRoute: launchFromRoute,
    );
  }

  Iterable<String> inputCalls(WidgetTester tester) => tester.testTextInput.log.map((call) => call.method);

  // The dictation bar pulses forever, so frames are pumped in bounded steps.
  Future<void> pumpSteps(WidgetTester tester) async {
    for (var step = 0; step < 5; step++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  final doneButton = find.byKey(const Key('editor_seal_done_btn'));
  final saveDot = find.byKey(const Key('editor_save_state_dot'));
  Rect canvasRect(WidgetTester tester) => tester.getRect(find.byType(EditorPaperCanvas));

  group('App bar', () {
    testWidgets('slides away while the keyboard is open, leaving a save-state dot in the header band, and returns when it closes',
        (tester) async {
      await openEditor(tester);
      expect(doneButton.hitTestable(), findsOneWidget);
      expect(saveDot, findsNothing);
      final restingCanvasTop = canvasRect(tester).top;

      await startWritingOn(tester, editorTextSheets(tester).first);
      await openSoftKeyboard(tester);

      expect(doneButton.hitTestable(), findsNothing, reason: 'the app bar is off-screen');
      expect(canvasRect(tester).top, closeTo(kPhoneStatusBarHeight, 0.5), reason: 'the desk takes the app bar\'s room');
      expect(saveDot, findsOneWidget);
      final dotRect = tester.getRect(saveDot);
      final indicatorRect = tester.getRect(find.byKey(const Key('editor_sheet_indicator')));
      final sheetTop = tester.getRect(find.byType(TemplateCanvasContainer).first).top;
      expect(dotRect.left, greaterThan(indicatorRect.right), reason: 'beside the page indicator');
      expect(dotRect.center.dy, closeTo(indicatorRect.center.dy, 1.0));
      expect(dotRect.bottom, lessThanOrEqualTo(sheetTop), reason: 'in the header band above the sheet');
      expect(dotRect.top, greaterThanOrEqualTo(kPhoneStatusBarHeight), reason: 'on screen');

      await closeSoftKeyboard(tester);

      expect(doneButton.hitTestable(), findsOneWidget);
      expect(canvasRect(tester).top, closeTo(restingCanvasTop, 0.5));
      expect(saveDot, findsNothing);
    });

    testWidgets('the save dot mirrors the autosave status', (tester) async {
      await openEditor(tester);
      final sheet = editorTextSheets(tester).first;
      await startWritingOn(tester, sheet);
      await openSoftKeyboard(tester);
      expect(tester.getSemantics(saveDot).label, '已保存');

      sheet.controller.document.insert(sheet.controller.document.length - 1, '暗香浮动。');
      // One frame delivers the document change, the next repaints the dot.
      await tester.pump();
      await tester.pump();
      expect(tester.getSemantics(saveDot).label, '草稿未存');

      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(tester.getSemantics(saveDot).label, '已保存');
    });

    testWidgets('the system back gesture still leaves the editor while the app bar is away', (tester) async {
      await openEditor(tester, launchFromRoute: true);
      await startWritingOn(tester, editorTextSheets(tester).first);
      await openSoftKeyboard(tester);
      expect(doneButton.hitTestable(), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(EntryEditorScreen), findsNothing);
    });

    testWidgets('once the keyboard closes, ← still stops at the exit guard while items are staged', (tester) async {
      await fixture.seedStagedPhotos(1);
      await openEditor(tester, launchFromRoute: true);
      await startWritingOn(tester, editorTextSheets(tester).first);
      await openSoftKeyboard(tester);
      await closeSoftKeyboard(tester);

      await tester.tap(find.byTooltip('返回 · Back'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('staged_exit_reminder')), findsOneWidget);
      expect(find.byType(EntryEditorScreen), findsOneWidget);
    });
  });

  group('Accessory row', () {
    final accessoryRow = find.byKey(const Key('keyboard_accessory_row'));
    final formatButton = find.byKey(const Key('keyboard_accessory_format_btn'));
    final dictationButton = find.byKey(const Key('keyboard_accessory_dictation_btn'));
    final dismissButton = find.byKey(const Key('keyboard_accessory_dismiss_btn'));

    void expectOnlyAccessoryRow(WidgetTester tester) {
      expect(accessoryRow, findsOneWidget);
      expect(find.byType(WritingDock), findsNothing);
      expect(find.byKey(const Key('writing_dock_hide_tab')), findsNothing);
      expect(find.byKey(const Key('writing_dock_restore_tab')), findsNothing);
      for (final dockOnly in ['writing_dock_photo_btn', 'writing_dock_video_btn', 'writing_dock_spark_btn']) {
        expect(find.byKey(Key(dockOnly)), findsNothing, reason: '$dockOnly is not shown while typing');
      }
      for (final control in [formatButton, dictationButton, dismissButton]) {
        expect(find.descendant(of: accessoryRow, matching: control), findsOneWidget);
        final size = tester.getSize(control);
        expect(size.width, greaterThanOrEqualTo(44.0));
        expect(size.height, greaterThanOrEqualTo(44.0));
      }
      expect(find.descendant(of: accessoryRow, matching: find.byType(IconButton)), findsNWidgets(2));
      expect(find.text('收起键盘'), findsOneWidget);
      // About 40dp tall, resting on the keyboard.
      final rowRect = tester.getRect(accessoryRow);
      expect(rowRect.height, inInclusiveRange(40.0, 46.0));
      expect(rowRect.bottom, closeTo(780.0 - kPhoneKeyboardInset, 0.5));
    }

    testWidgets('replaces the Writing Dock while the keyboard is open, holding only Tt, dictation and 收起键盘', (tester) async {
      await openEditor(tester);
      expect(accessoryRow, findsNothing);

      await startWritingOn(tester, editorTextSheets(tester).first);
      await openSoftKeyboard(tester);
      expectOnlyAccessoryRow(tester);
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel(KeyboardAccessoryRow.kDismissLabel), findsOneWidget);
      await expectAccessibleTapTargets(tester, within: accessoryRow);
      semantics.dispose();

      await closeSoftKeyboard(tester);
      expect(accessoryRow, findsNothing);
      expect(find.byType(WritingDock), findsOneWidget);
    });

    testWidgets('appears even when the Writing Dock is hidden, and the restore tab returns when the keyboard closes', (tester) async {
      await openEditor(tester);
      await tester.tap(find.byKey(const Key('writing_dock_hide_tab')));
      await tester.pumpAndSettle();
      expect(find.byType(WritingDock), findsNothing);

      await startWritingOn(tester, editorTextSheets(tester).first);
      await openSoftKeyboard(tester);
      expectOnlyAccessoryRow(tester);

      await closeSoftKeyboard(tester);
      expect(accessoryRow, findsNothing);
      expect(find.byKey(const Key('writing_dock_restore_tab')), findsOneWidget);
    });

    testWidgets('收起键盘 ends writing and puts the keyboard away', (tester) async {
      await openEditor(tester);
      final sheet = editorTextSheets(tester).first;
      await startWritingOn(tester, sheet);
      await openSoftKeyboard(tester);
      tester.testTextInput.log.clear();

      await tester.tap(dismissButton);
      await tester.pump();

      expect(sheet.focusNode.hasFocus, isFalse);
      expect(inputCalls(tester), contains('TextInput.hide'));
      expect(inputCalls(tester), isNot(contains('TextInput.show')));
    });

    testWidgets('收起键盘 also ends writing in the title field', (tester) async {
      await openEditor(tester);
      await tester.tap(find.descendant(of: find.byType(JournalLetterhead), matching: find.byType(TextField)));
      await tester.pump();
      await openSoftKeyboard(tester);
      expect(tester.testTextInput.hasAnyClients, isTrue);
      tester.testTextInput.log.clear();

      await tester.tap(dismissButton);
      await tester.pump();

      expect(tester.testTextInput.hasAnyClients, isFalse);
      expect(inputCalls(tester), contains('TextInput.hide'));
    });

    testWidgets('Tt and dictation keep writing focus and never show or hide the keyboard', (tester) async {
      await openEditor(tester, dictationService: DictationService(speech: FakeSpeechToText()));
      final sheet = editorTextSheets(tester).first;
      await startWritingOn(tester, sheet);
      await openSoftKeyboard(tester);
      tester.testTextInput.log.clear();

      await tester.tap(formatButton);
      await tester.pumpAndSettle();
      expect(find.byType(WritingDockFormattingRibbon), findsOneWidget);
      expect(
        tester.getRect(find.byType(WritingDockFormattingRibbon)).bottom,
        lessThanOrEqualTo(tester.getRect(formatButton).top),
        reason: 'the ribbon unfolds above the row',
      );
      await tester.tap(formatButton);
      await tester.pumpAndSettle();
      expect(find.byType(WritingDockFormattingRibbon), findsNothing);

      await tester.tap(dictationButton);
      await pumpSteps(tester);
      expect(find.byType(DictationBar), findsOneWidget);
      await tester.tap(dictationButton);
      await pumpSteps(tester);
      expect(find.byType(DictationBar), findsNothing);

      expect(sheet.focusNode.hasFocus, isTrue);
      expect(inputCalls(tester), isNot(contains('TextInput.show')));
      expect(inputCalls(tester), isNot(contains('TextInput.hide')));
    });
  });

  group('Keyboard steadiness', () {
    testWidgets('opening and closing the keyboard while writing neither shows nor hides it again', (tester) async {
      await openEditor(tester);
      await startWritingOn(tester, editorTextSheets(tester).first);
      tester.testTextInput.log.clear();

      await openSoftKeyboard(tester);
      expect(inputCalls(tester), isNot(contains('TextInput.show')));
      expect(inputCalls(tester), isNot(contains('TextInput.hide')));

      await closeSoftKeyboard(tester);
      expect(inputCalls(tester), isNot(contains('TextInput.show')), reason: 'the keyboard must not bounce back');
    });
  });
}
