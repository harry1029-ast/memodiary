import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/services/editor_pagination_coordinator.dart';

MediaAttachment _attachment(String id) => MediaAttachment(
      id: id,
      entryId: 'entry',
      mediaType: 'image',
      relativePath: 'media/$id.webp',
      createdAt: DateTime(2026, 11, 10),
    );

/// While the keyboard is hidden Quill requests it (and focuses an unfocused
/// editor) on every controller change, unless the change is flagged with
/// [QuillController.ignoreFocusOnTextChange]. Widget tests cannot see this,
/// because Quill treats them as having a keyboard always shown, so these tests
/// check the flag on every notification a desk edit sends.
void main() {
  late EditorPaginationCoordinator coordinator;
  late List<bool> flagsSeen;

  setUp(() {
    coordinator = EditorPaginationCoordinator(
      typography: const TypographySettings(fontSize: 16.0, lineSpacing: 1.5),
    )..initializeFromDelta(
        jsonEncode((Delta()..insert('疏影横斜。\n')).toJson()),
        attachments: [_attachment('a')],
      );
    flagsSeen = [];
    final sheet = coordinator.sheets.first as TextStationerySheet;
    sheet.controller.addListener(() => flagsSeen.add(sheet.controller.ignoreFocusOnTextChange));
  });

  tearDown(() => coordinator.dispose());

  test('mounting onto a sheet never reads as typing', () {
    expect(coordinator.media.mountOnActiveSheet('a'), isTrue);

    expect(flagsSeen, isNotEmpty);
    expect(flagsSeen, everyElement(isTrue));
  });

  test('unmounting from a sheet never reads as typing', () {
    coordinator.media.mountOnActiveSheet('a');
    flagsSeen.clear();

    expect(coordinator.media.unmount('a'), isTrue);

    expect(flagsSeen, isNotEmpty);
    expect(flagsSeen, everyElement(isTrue));
  });

  test('re-laying a sheet\'s text never reads as typing, and the flag is restored after', () {
    final sheet = coordinator.sheets.first as TextStationerySheet;

    sheet.setDelta(Delta()..insert('暗香浮动。\n'));

    expect(flagsSeen, isNotEmpty);
    expect(flagsSeen, everyElement(isTrue));
    expect(sheet.controller.ignoreFocusOnTextChange, isFalse);
  });
}
