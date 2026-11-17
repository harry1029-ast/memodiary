import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/features/editor/controllers/stationery_quill_controller.dart';
import 'package:memodiary/features/editor/models/mount_marker.dart';

/// Records what a sheet's controller reports, as readable lines.
class _RecordingObserver implements StationeryEditObserver {
  final List<String> events = [];

  @override
  void onTextReplaced(int index, int deletedLength, String insertedText, {required bool ignoreFocus}) =>
      events.add('replace@$index -$deletedLength +"$insertedText"${ignoreFocus ? ' ignoreFocus' : ''}');

  @override
  void onStructuralChange() => events.add('structural');
}

void main() {
  late StationeryQuillController controller;
  late _RecordingObserver observer;

  StationeryQuillController controllerWith(Delta delta) {
    final created = StationeryQuillController(document: Document.fromDelta(delta));
    addTearDown(created.dispose);
    return created..editObserver = observer;
  }

  setUp(() {
    observer = _RecordingObserver();
    controller = controllerWith(Delta()..insert('山高\n'));
  });

  test('a typed insertion is reported with its index, deleted length and text', () {
    controller.replaceText(2, 0, '水', const TextSelection.collapsed(offset: 3));

    expect(observer.events, ['replace@2 -0 +"水"']);
  });

  test('a replacement reports the deleted length; a programmatic edit carries ignoreFocus', () {
    controller.replaceText(0, 2, '云', const TextSelection.collapsed(offset: 1), ignoreFocus: true);

    expect(observer.events, ['replace@0 -2 +"云" ignoreFocus']);
  });

  test('the edit is reported after it is applied and before the controller notifies', () {
    final order = <String>[];
    controller.addListener(() => order.add('notified with "${controller.document.toPlainText().trim()}"'));
    controller.editObserver = _CallbackObserver(
      () => order.add('observed with "${controller.document.toPlainText().trim()}"'),
    );

    controller.replaceText(2, 0, '水', const TextSelection.collapsed(offset: 3));

    expect(order, ['observed with "山高水"', 'notified with "山高水"']);
  });

  test('a newline typed onto a mount marker reports the index shifted past the marker', () {
    controller = controllerWith(
      Delta()
        ..insert('山高')
        ..insert(MountMarker.embeddable('photo-1').toJson())
        ..insert('\n'),
    );

    controller.replaceText(2, 0, '\n', const TextSelection.collapsed(offset: 3));

    expect(observer.events, ['replace@3 -0 +"\n"']);
  });

  test('a Backspace redirected off a mount marker reports the character it really deleted', () {
    controller = controllerWith(
      Delta()
        ..insert('山高')
        ..insert(MountMarker.embeddable('photo-1').toJson())
        ..insert('\n'),
    );
    controller.updateSelection(const TextSelection.collapsed(offset: 3), ChangeSource.local);

    controller.replaceText(2, 1, '', const TextSelection.collapsed(offset: 2));

    expect(observer.events, ['replace@1 -1 +""']);
    expect(MountMarker.mediaIdsIn(controller.document.toDelta()), ['photo-1']);
  });

  test('a selection-only replaceText reports nothing', () {
    controller.replaceText(1, 0, '', const TextSelection.collapsed(offset: 1));

    expect(observer.events, isEmpty);
  });

  test('inserting an embed is a structural change', () {
    controller.replaceText(2, 0, MountMarker.embeddable('photo-1'), null, ignoreFocus: true);

    expect(observer.events, ['structural']);
  });

  test('undo and redo are structural changes', () {
    controller.replaceText(2, 0, '水', const TextSelection.collapsed(offset: 3));
    observer.events.clear();

    controller.undo();
    expect(observer.events, ['structural']);

    controller.redo();
    expect(observer.events, ['structural', 'structural']);
  });

  test('swapping the document is a structural change', () {
    controller.document = Document.fromDelta(Delta()..insert('云深\n'));

    expect(observer.events, ['structural']);
  });

  test('formatting text is a structural change', () {
    controller.formatText(0, 2, Attribute.bold);

    expect(observer.events, ['structural']);
  });
}

class _CallbackObserver implements StationeryEditObserver {
  final void Function() onEvent;

  _CallbackObserver(this.onEvent);

  @override
  void onTextReplaced(int index, int deletedLength, String insertedText, {required bool ignoreFocus}) => onEvent();

  @override
  void onStructuralChange() => onEvent();
}
