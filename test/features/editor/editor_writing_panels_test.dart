import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/services/dictation_service.dart';
import 'package:memodiary/features/editor/widgets/dictation_bar.dart';
import 'package:memodiary/features/editor/widgets/writing_dock.dart';
import '../../helpers/editor_test_harness.dart';
import '../../helpers/fake_speech_to_text.dart';
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
}
