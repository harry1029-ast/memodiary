import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/ink_choreography/ink_choreography_controller.dart';
import 'package:memodiary/features/editor/ink_choreography/sheet_ink_choreographer.dart';
import 'package:memodiary/features/editor/services/editor_pagination_coordinator.dart';
import 'package:memodiary/features/editor/widgets/editor_paper_canvas.dart';
import 'package:memodiary/features/editor/widgets/sheet_ink/sheet_ink_stage.dart';

/// One display frame of animation time.
const Duration kInkTestFrame = Duration(milliseconds: 16);

/// Seeds an entry on lined paper holding [text] (or [delta]).
Future<void> seedInkEntry(
  AppDatabase database, {
  required String entryId,
  String text = '',
  Delta? delta,
  String templateId = 'template_lined_paper',
}) =>
    database.entriesDao.createEntry(
      EntriesCompanion.insert(
        id: entryId,
        notebookId: 'notebook_default',
        templateId: templateId,
        title: const Value('西湖夜泊'),
        contentDelta: jsonEncode((delta ?? (Delta()..insert('$text\n'))).toJson()),
        plainText: '',
        entryDate: DateTime(2026, 11, 17, 21),
      ),
    );

/// Drives Ink Choreography on the open editor's Stationery Sheets the way a
/// diarist's keyboard does, and reads back what the overlay is writing.
class SheetInkRobot {
  final WidgetTester tester;

  const SheetInkRobot(this.tester);

  EditorPaperCanvas get canvas => tester.widget<EditorPaperCanvas>(find.byType(EditorPaperCanvas));
  EditorPaginationCoordinator get coordinator => canvas.coordinator;
  InkChoreographyController get preferences => canvas.inkChoreography;

  TextStationerySheet sheet([int index = 0]) => coordinator.sheets[index] as TextStationerySheet;

  Finder stageFinder([int index = 0]) =>
      find.byWidgetPredicate((widget) => widget is SheetInkStage && widget.sheet.sheetIndex == index);

  SheetInkStageState stage([int index = 0]) => tester.state<SheetInkStageState>(stageFinder(index));

  SheetInkChoreographer ink([int index = 0]) => stage(index).ink;

  /// The live editor of sheet [index].
  QuillRawEditorState rawEditor([int index = 0]) => tester.state<QuillRawEditorState>(
        find.descendant(of: stageFinder(index), matching: find.byType(QuillRawEditor)),
      );

  /// The characters the overlay holds on sheet [index], oldest first.
  String slotted([int index = 0]) => ink(index).slots.map((slot) => slot.character).join();

  /// The sheet's text without its closing newline.
  String text([int index = 0]) {
    final plain = sheet(index).document.toPlainText();
    return plain.substring(0, plain.length - 1);
  }

  /// The entry's Delta as it would be saved.
  String get savedDelta => coordinator.reSynthesize().$1;

  /// Gives sheet [index] the keyboard, with the caret at the end of its text.
  Future<void> focus([int index = 0]) async {
    final target = sheet(index);
    target.focusNode.requestFocus();
    await tester.pump();
    target.controller.updateSelection(
      TextSelection.collapsed(offset: target.document.length - 1),
      ChangeSource.local,
    );
    await tester.pump();
  }

  /// Delivers the keyboard's editing value for sheet [index]: its whole
  /// [text], the caret (at the end unless [caret] is given) and the IME
  /// [composing] range.
  void keyboard(String text, {int? caret, TextRange composing = TextRange.empty, int index = 0}) {
    rawEditor(index).updateEditingValue(
      TextEditingValue(
        text: '$text\n',
        selection: TextSelection.collapsed(offset: caret ?? text.length),
        composing: composing,
      ),
    );
  }

  /// Types [typed] at the end of sheet [index] with no composition, and
  /// pumps the frame that shows it.
  Future<void> type(String typed, {int index = 0}) async {
    keyboard('${text(index)}$typed', index: index);
    await tester.pump();
  }

  /// Pumps [frames] display frames of animation.
  Future<void> pumpFrames(int frames) async {
    for (var frame = 0; frame < frames; frame++) {
      await tester.pump(kInkTestFrame);
    }
  }

  /// Pumps frames until sheet [index] has nothing left to animate, failing
  /// after [limit] of animation time.
  Future<void> pumpUntilSettled({int index = 0, Duration limit = const Duration(seconds: 30)}) async {
    var elapsed = Duration.zero;
    while (stage(index).isAnimating) {
      await tester.pump(kInkTestFrame);
      elapsed += kInkTestFrame;
      if (elapsed > limit) fail('Ink Choreography still animating after $limit');
    }
  }

  /// Where the glyph at [offset] of sheet [index] stands on screen, from the
  /// editor's own caret geometry: its left edge and advance.
  ({double left, double width, double centerY}) glyphOnScreen(int offset, {int index = 0}) {
    final editor = rawEditor(index).renderEditor;
    final caret = editor.getLocalRectForCaret(TextPosition(offset: offset));
    final next = editor.getLocalRectForCaret(TextPosition(offset: offset + 1));
    final origin = editor.localToGlobal(caret.topLeft);
    return (left: origin.dx, width: next.left - caret.left, centerY: origin.dy + caret.height / 2);
  }

  /// The paper mask of the slot at [slotIndex] on sheet [index], on screen.
  Rect maskOnScreen(int slotIndex, {int index = 0}) {
    final layer = tester.getTopLeft(
      find.descendant(of: stageFinder(index), matching: find.byKey(const Key('editor_ink_mask_layer'))),
    );
    return ink(index).slots[slotIndex].geometry!.maskRect.shift(layer);
  }
}
