import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/services/dictation_service.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/controllers/editor_chrome_controller.dart';
import 'package:memodiary/features/editor/widgets/dictation_bar.dart';
import 'package:memodiary/features/editor/widgets/editor_writing_panels.dart';
import 'package:memodiary/features/editor/widgets/keyboard_accessory_row.dart';
import 'package:memodiary/features/editor/widgets/writing_dock.dart';
import 'package:memodiary/features/editor/widgets/writing_dock_formatting_ribbon.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/fake_speech_to_text.dart';
import '../../helpers/soft_keyboard_test_helpers.dart';
import '../../helpers/staged_editor_fixture.dart';

const _entryId = 'writing_panels_entry';

/// The panels below the desk follow the editor's chrome state: the dock's
/// dictation button opens the dictation bar above the dock, and closing the
/// bar or tapping the button again puts it away.
void main() {
  final fixture = StagedEditorFixture(entryId: _entryId);
  late FakeSpeechToText fakeSpeech;

  setUp(() async {
    await fixture.setUp();
    fakeSpeech = FakeSpeechToText();
  });
  tearDown(fixture.tearDown);

  Future<void> openEditor(WidgetTester tester) => pumpEntryEditorScreen(
        tester,
        database: fixture.database,
        mediaSandboxService: fixture.sandboxService,
        entryId: _entryId,
        dictationService: DictationService(speech: fakeSpeech),
        viewportSize: const Size(360.0, 780.0),
      );

  final dictationButton = find.byKey(const Key('writing_dock_dictation_btn'));

  // The dictation bar pulses forever, so frames are pumped in bounded steps.
  Future<void> pumpSteps(WidgetTester tester) async {
    for (var step = 0; step < 5; step++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('the dictation button opens the bar above the dock and closes it again', (tester) async {
    await openEditor(tester);
    expect(find.byType(DictationBar), findsNothing);

    await tester.tap(dictationButton);
    await pumpSteps(tester);
    expect(find.byType(DictationBar), findsOneWidget);
    expect(fakeSpeech.isListeningVal, isTrue);
    expect(
      tester.getRect(find.byType(DictationBar)).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(WritingDock)).top),
    );

    await tester.tap(dictationButton);
    await pumpSteps(tester);
    expect(find.byType(DictationBar), findsNothing);
  });

  testWidgets('cancelling from the bar puts it away and the dock stays', (tester) async {
    await openEditor(tester);
    await tester.tap(dictationButton);
    await pumpSteps(tester);

    await tester.tap(find.byTooltip('Cancel Dictation'));
    await pumpSteps(tester);
    expect(find.byType(DictationBar), findsNothing);
    expect(find.byType(WritingDock), findsOneWidget);
  });

  testWidgets('EditorWritingPanels keeps formatting ribbon open across keyboard and dock transitions', (tester) async {
    final chrome = EditorChromeController();
    final quillController = QuillController.basic();
    final dictationService = DictationService(speech: fakeSpeech);
    addTearDown(chrome.dispose);
    addTearDown(quillController.dispose);
    addTearDown(dictationService.dispose);

    var ensureCalls = 0;

    Future<void> pumpPanels(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ListenableBuilder(
                listenable: chrome,
                builder: (context, _) {
                  return EditorWritingPanels(
                    chrome: chrome,
                    controller: quillController,
                    onEnsureTextController: () {
                      ensureCalls++;
                      return quillController;
                    },
                    dictationService: dictationService,
                    onPickImage: () {},
                    onPickVideo: () {},
                    onShuffleSpark: () {},
                    paperColor: const Color(0xFFF9F6EE),
                    inkColor: const Color(0xFF2D2D2D),
                    isPaperDark: false,
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpPanels(tester);

    expect(find.byType(WritingDock), findsOneWidget);
    expect(find.byType(WritingDockFormattingRibbon), findsNothing);

    // Open formatting in WritingDock
    await tester.tap(find.byKey(const Key('writing_dock_format_btn')));
    await tester.pumpAndSettle();
    expect(chrome.isFormattingOpen, isTrue);
    expect(ensureCalls, 1);
    expect(find.byType(WritingDockFormattingRibbon), findsOneWidget);
    expect(find.text('B'), findsOneWidget);

    // Software keyboard opens -> switches to KeyboardAccessoryRow, ribbon stays open
    chrome.syncKeyboardInset(300.0);
    // syncKeyboardInset deliberately does not notify; simulate the MediaQuery rebuild.
    await pumpPanels(tester);
    expect(find.byType(KeyboardAccessoryRow), findsOneWidget);
    expect(find.byType(WritingDock), findsNothing);
    expect(find.byType(WritingDockFormattingRibbon), findsOneWidget);
    expect(find.text('B'), findsOneWidget);

    // Close formatting from KeyboardAccessoryRow -> does not re-call onEnsureTextController
    await tester.tap(find.byKey(const Key('keyboard_accessory_format_btn')));
    await tester.pumpAndSettle();
    expect(chrome.isFormattingOpen, isFalse);
    expect(ensureCalls, 1);
    expect(find.byType(WritingDockFormattingRibbon), findsNothing);

    // Open formatting from KeyboardAccessoryRow -> calls onEnsureTextController once more
    await tester.tap(find.byKey(const Key('keyboard_accessory_format_btn')));
    await tester.pumpAndSettle();
    expect(chrome.isFormattingOpen, isTrue);
    expect(ensureCalls, 2);
    expect(find.byType(WritingDockFormattingRibbon), findsOneWidget);

    // Keyboard closes -> returns to WritingDock with formatting still open
    chrome.syncKeyboardInset(0.0);
    await pumpPanels(tester);
    expect(find.byType(WritingDock), findsOneWidget);
    expect(find.byType(KeyboardAccessoryRow), findsNothing);
    expect(find.byType(WritingDockFormattingRibbon), findsOneWidget);
    expect(find.text('B'), findsOneWidget);

    // Hiding and restoring the WritingDock leaves formatting open
    chrome.setWritingDockVisible(false);
    await tester.pumpAndSettle();
    expect(find.byType(WritingDock), findsNothing);
    expect(chrome.isFormattingOpen, isTrue);

    chrome.setWritingDockVisible(true);
    await tester.pumpAndSettle();
    expect(find.byType(WritingDock), findsOneWidget);
    expect(find.byType(WritingDockFormattingRibbon), findsOneWidget);
  });

  testWidgets('opening formatting in WritingDock stays open when the software keyboard opens and closes',
      (tester) async {
    simulatePhoneSystemBars(tester);
    await openEditor(tester);

    // Open formatting ribbon in WritingDock at rest
    await tester.tap(find.byKey(const Key('writing_dock_format_btn')));
    await tester.pumpAndSettle();
    expect(find.byType(WritingDockFormattingRibbon), findsOneWidget);
    expect(find.text('B'), findsOneWidget);

    // Tap a sheet and open the software keyboard -> transitions to KeyboardAccessoryRow
    await startWritingOn(tester, editorTextSheets(tester).first);
    await openSoftKeyboard(tester);
    expect(find.byType(KeyboardAccessoryRow), findsOneWidget);
    expect(find.byType(WritingDock), findsNothing);
    expect(find.byType(WritingDockFormattingRibbon), findsOneWidget);
    expect(find.text('B'), findsOneWidget);

    // Close the software keyboard -> transitions back to WritingDock
    await closeSoftKeyboard(tester);
    expect(find.byType(WritingDock), findsOneWidget);
    expect(find.byType(KeyboardAccessoryRow), findsNothing);
    expect(find.byType(WritingDockFormattingRibbon), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });
}
