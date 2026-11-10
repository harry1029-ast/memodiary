import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/widgets/editor_paper_canvas.dart';

/// The reference phone's status bar and gesture navigation bar, in dp.
const double kPhoneStatusBarHeight = 24.0;
const double kPhoneNavigationBarHeight = 24.0;

/// A typical software keyboard inset on the reference phone (keys, suggestion
/// strip and the navigation bar it covers), in dp.
const double kPhoneKeyboardInset = 300.0;

/// Gives the test view a phone's status and navigation bars, as the engine
/// reports them with the keyboard closed.
void simulatePhoneSystemBars(WidgetTester tester) {
  const bars = FakeViewPadding(top: kPhoneStatusBarHeight, bottom: kPhoneNavigationBarHeight);
  tester.view.padding = bars;
  tester.view.viewPadding = bars;
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
}

/// Opens the software keyboard as a phone reports it: the inset covers the
/// navigation bar, so the bottom padding drops to zero.
Future<void> openSoftKeyboard(WidgetTester tester, {double inset = kPhoneKeyboardInset}) async {
  tester.view.viewInsets = FakeViewPadding(bottom: inset);
  tester.view.padding = FakeViewPadding(top: tester.view.padding.top);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpAndSettle();
}

/// Closes the software keyboard, restoring the navigation bar's padding.
/// With [settle] false the caller pumps the frames itself.
Future<void> closeSoftKeyboard(WidgetTester tester, {bool settle = true}) async {
  tester.view.viewInsets = FakeViewPadding.zero;
  tester.view.padding = FakeViewPadding(top: tester.view.padding.top, bottom: tester.view.viewPadding.bottom);
  if (settle) await tester.pumpAndSettle();
}

/// The editor's text sheets, in order.
List<TextStationerySheet> editorTextSheets(WidgetTester tester) => tester
    .widget<EditorPaperCanvas>(find.byType(EditorPaperCanvas))
    .coordinator
    .sheets
    .whereType<TextStationerySheet>()
    .toList();

/// Focuses [sheet] and puts the caret at [offset] (default: the end of its text).
Future<void> startWritingOn(WidgetTester tester, TextStationerySheet sheet, {int? offset}) async {
  sheet.focusNode.requestFocus();
  await tester.pump();
  sheet.controller.updateSelection(
    TextSelection.collapsed(offset: offset ?? sheet.controller.document.length - 1),
    ChangeSource.local,
  );
  await tester.pumpAndSettle();
}

/// The caret of [sheet] in global coordinates.
Rect caretRectOf(TextStationerySheet sheet) {
  final renderEditor = sheet.editorKey.currentState!.renderEditor;
  final localCaret = renderEditor.getLocalRectForCaret(sheet.controller.selection.extent);
  return renderEditor.localToGlobal(localCaret.topLeft) & localCaret.size;
}
