import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/models/media_embed_data.dart';

void main() {
  group('StationerySheetDescriptor Domain Tests', () {
    test('OpeningSheet initializes with 10-row capacity beneath 4-row letterhead', () {
      final sheet = OpeningSheet.empty(sheetIndex: 0);

      expect(sheet.sheetIndex, equals(0));
      expect(sheet.rowCapacity, equals(10));
      expect(OpeningSheet.kRowCapacity, equals(10));
      expect(OpeningSheet.kLetterheadRows, equals(4));
      expect(sheet.isOpeningSheet, isTrue);
      expect(sheet.isContinuationSheet, isFalse);
      expect(sheet.isEphemeraSheet, isFalse);
      expect(sheet.isTextSheet, isTrue);
      expect(sheet.isEmpty, isTrue);

      sheet.dispose();
    });

    test('ContinuationSheet initializes with 14-row capacity', () {
      final sheet = ContinuationSheet.empty(sheetIndex: 1);

      expect(sheet.sheetIndex, equals(1));
      expect(sheet.rowCapacity, equals(14));
      expect(ContinuationSheet.kRowCapacity, equals(14));
      expect(sheet.isOpeningSheet, isFalse);
      expect(sheet.isContinuationSheet, isTrue);
      expect(sheet.isEphemeraSheet, isFalse);
      expect(sheet.isTextSheet, isTrue);
      expect(sheet.isEmpty, isTrue);

      sheet.dispose();
    });

    test('OpeningSheet.fromDelta preserves Delta and initializes controller', () {
      final delta = Delta()
        ..insert('Opening diary line\n', {'bold': true});

      final sheet = OpeningSheet.fromDelta(sheetIndex: 0, delta: delta);

      expect(sheet.plainText.trim(), equals('Opening diary line'));
      expect(sheet.isEmpty, isFalse);
      expect(sheet.delta.operations.first.attributes?['bold'], isTrue);

      sheet.dispose();
    });

    test('TextStationerySheet setDelta updates document in place without disposing controller', () {
      final sheet = OpeningSheet.empty(sheetIndex: 0);
      final originalController = sheet.controller;
      var listenerCalls = 0;
      originalController.addListener(() {
        listenerCalls++;
      });

      final newDelta = Delta()
        ..insert('Updated heading')
        ..insert('\n', {'header': 1});

      sheet.setDelta(
        newDelta,
        selection: const TextSelection.collapsed(offset: 7),
      );

      expect(identical(sheet.controller, originalController), isTrue);
      expect(listenerCalls, greaterThan(0));
      expect(sheet.plainText.trim(), equals('Updated heading'));
      expect(sheet.controller.selection.baseOffset, equals(7));
      expect(sheet.delta.operations.last.attributes?['header'], equals(1));

      sheet.dispose();
    });

    test('copyWithIndex preserves controllers and state while updating index', () {
      final delta = Delta()..insert('Continuation content\n');
      final original = ContinuationSheet.fromDelta(
        sheetIndex: 1,
        delta: delta,
        hasTrailingSoftNewline: true,
      );

      final copied = original.copyWithIndex(2);

      expect(copied.sheetIndex, equals(2));
      expect(copied.controller, equals(original.controller));
      expect(copied.hasTrailingSoftNewline, isTrue);
      expect(copied.plainText.trim(), equals('Continuation content'));

      original.dispose();
    });

    test('EphemeraSheet parses BlockEmbed metadata with typed EphemeraMediaType', () {
      const embedData = MediaEmbedData(
        path: 'media/test_uuid.webp',
        caption: 'Classical Garden Pavilion',
        aspect: '4:3',
      );

      final sheet = EphemeraSheet(
        sheetIndex: 1,
        mediaType: EphemeraMediaType.image,
        mediaData: embedData,
      );

      expect(sheet.sheetIndex, equals(1));
      expect(sheet.isEphemeraSheet, isTrue);
      expect(sheet.isTextSheet, isFalse);
      expect(sheet.mediaType, equals(EphemeraMediaType.image));
      expect(sheet.mediaType.embedKey, equals('image'));
      expect(sheet.sandboxedRelativePath, equals('media/test_uuid.webp'));
      expect(sheet.caption, equals('Classical Garden Pavilion'));
      expect(sheet.aspect, equals('4:3'));

      sheet.captionController.text = 'Updated Autumn View';
      expect(sheet.caption, equals('Updated Autumn View'));
      expect(sheet.currentMediaData.caption, equals('Updated Autumn View'));

      final copied = sheet.copyWithIndex(3);
      expect(copied.sheetIndex, equals(3));
      expect(copied.caption, equals('Updated Autumn View'));

      sheet.dispose();
    });

    test('EphemeraSheet.fromEmbed handles raw json string representation', () {
      const rawJson = '{"path":"media/video_uuid.mp4","caption":"Mountain Stream","aspect":"1:1"}';
      final sheet = EphemeraSheet.fromEmbed(
        sheetIndex: 2,
        mediaType: EphemeraMediaType.video,
        rawData: rawJson,
      );

      expect(sheet.mediaType, equals(EphemeraMediaType.video));
      expect(sheet.mediaType.embedKey, equals('video'));
      expect(sheet.sandboxedRelativePath, equals('media/video_uuid.mp4'));
      expect(sheet.caption, equals('Mountain Stream'));
      expect(sheet.aspect, equals('1:1'));

      sheet.dispose();
    });
  });
}
