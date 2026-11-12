import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:memodiary/core/database/app_database.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/models/mount_marker.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
import 'package:memodiary/features/editor/services/editor_delta_partitioner.dart';
import 'package:memodiary/features/editor/services/editor_pagination_coordinator.dart';

void main() {
  group('EditorPaginationCoordinator - Auto-Spill & Spill-Back Tests', () {
    const typography = TypographySettings(fontSize: 16.0, lineSpacing: 1.5);

    test('Typing past 10 rows on Sheet 1 triggers Auto-Spill allocating ContinuationSheet', () {
      final coordinator = EditorPaginationCoordinator(typography: typography);
      coordinator.initializeFromDelta('');

      final sheet1 = coordinator.sheets.first as OpeningSheet;
      expect(coordinator.totalSheets, equals(1));

      final overflowingDelta = Delta();
      for (int lineNumber = 1; lineNumber <= 15; lineNumber++) {
        overflowingDelta.insert('第${lineNumber.toString().padLeft(2, '0')}行测试输入文字字\n');
      }
      final textLen = overflowingDelta.operations.fold<int>(
        0,
        (sum, operation) =>
            sum + (operation.data is String ? (operation.data as String).length : 1),
      );
      sheet1.setDelta(
        overflowingDelta,
        selection: TextSelection.collapsed(offset: textLen),
      );

      final result = coordinator.checkAndPerformAutoSpill(0);

      expect(result, isNotNull);
      expect(result!.sourceSheetIndex, equals(0));
      expect(result.destinationSheetIndex, equals(1));
      expect(result.didAllocateNewSheet, isTrue);
      expect(coordinator.totalSheets, equals(2));
      expect(coordinator.sheets[1], isA<ContinuationSheet>());
      expect(coordinator.activeSheetIndex, equals(1));

      final sheet1Lines = sheet1.plainText.trim().split('\n');
      expect(sheet1Lines.length, equals(10));
      expect(sheet1Lines.first, contains('第01行'));
      expect(sheet1Lines.last, contains('第10行'));

      final sheet2 = coordinator.sheets[1] as ContinuationSheet;
      final sheet2Lines = sheet2.plainText.trim().split('\n');
      expect(sheet2Lines.length, equals(5));
      expect(sheet2Lines.first, contains('第11行'));
      expect(sheet2Lines.last, contains('第15行'));

      coordinator.dispose();
    });

    test('Multi-paragraph paste cascades across multiple sheets and emits final destination once', () {
      final coordinator = EditorPaginationCoordinator(typography: typography);
      coordinator.initializeFromDelta('');

      final emittedResults = <AutoSpillResult>[];
      coordinator.onAutoSpill = emittedResults.add;

      final sheet1 = coordinator.sheets.first as OpeningSheet;

      // 32 rows total: 10 on Sheet 1, 14 on Sheet 2, 8 on Sheet 3
      final pasteDelta = Delta();
      for (int lineNumber = 1; lineNumber <= 32; lineNumber++) {
        pasteDelta.insert('第${lineNumber.toString().padLeft(2, '0')}行大段粘贴测试\n');
      }
      final totalPasteChars = pasteDelta.operations.fold<int>(
        0,
        (sum, operation) => sum + (operation.data as String).length,
      );
      sheet1.setDelta(
        pasteDelta,
        selection: TextSelection.collapsed(offset: totalPasteChars - 1),
      );

      final spillResult = coordinator.checkAndPerformAutoSpill(0);

      expect(coordinator.totalSheets, equals(3));
      expect(coordinator.sheets[0], isA<OpeningSheet>());
      expect(coordinator.sheets[1], isA<ContinuationSheet>());
      expect(coordinator.sheets[2], isA<ContinuationSheet>());

      // Must emit onAutoSpill ONCE pointing to final Sheet 3 (index 2)
      expect(emittedResults.length, equals(1));
      expect(spillResult, isNotNull);
      expect(spillResult!.destinationSheetIndex, equals(2));
      expect(emittedResults.single.destinationSheetIndex, equals(2));
      expect(coordinator.activeSheetIndex, equals(2));

      final sheet0 = coordinator.sheets[0] as TextStationerySheet;
      expect(sheet0.plainText.trim().split('\n').length, equals(10));

      final sheet1Parsed = coordinator.sheets[1] as TextStationerySheet;
      expect(sheet1Parsed.plainText.trim().split('\n').length, equals(14));

      final sheet2Parsed = coordinator.sheets[2] as TextStationerySheet;
      expect(sheet2Parsed.plainText.trim().split('\n').length, equals(8));

      final (_, plainText) = coordinator.reSynthesize();
      expect(plainText.split('\n').length, equals(32));

      coordinator.dispose();
    });

    test('Active mobile IME composition defers Auto-Spill until commit', () {
      final coordinator = EditorPaginationCoordinator(typography: typography);
      coordinator.initializeFromDelta('');

      final sheet1 = coordinator.sheets.first as OpeningSheet;
      final overflowingDelta = Delta();
      for (int lineNumber = 1; lineNumber <= 14; lineNumber++) {
        overflowingDelta.insert('第${lineNumber.toString().padLeft(2, '0')}行拼音输入中字\n');
      }
      sheet1.setDelta(overflowingDelta);

      coordinator.isImeComposing = true;

      final deferredResult = coordinator.checkAndPerformAutoSpill(0);
      expect(deferredResult, isNull);
      expect(coordinator.totalSheets, equals(1));

      coordinator.isImeComposing = false;

      final committedResult = coordinator.checkAndPerformAutoSpill(0);
      expect(committedResult, isNotNull);
      expect(coordinator.totalSheets, equals(2));

      coordinator.dispose();
    });

    test('Spill-Back enforces precedingSheet rowCapacity without overflowing Sheet 1', () {
      final coordinator = EditorPaginationCoordinator(typography: typography);

      // Initialize 16 lines -> Sheet 1 gets 10, Sheet 2 gets 6
      final initialDelta = Delta();
      for (int lineNumber = 1; lineNumber <= 16; lineNumber++) {
        initialDelta.insert('测试段落第${lineNumber.toString().padLeft(2, '0')}行\n');
      }
      coordinator.initializeFromDelta(jsonEncode(initialDelta.toJson()));
      expect(coordinator.totalSheets, equals(2));

      // Trim Sheet 1 down to 8 lines so it has exactly 2 available rows
      final sheet1 = coordinator.sheets[0] as OpeningSheet;
      final eightLinesDelta = Delta();
      for (int lineNumber = 1; lineNumber <= 8; lineNumber++) {
        eightLinesDelta.insert('测试段落第${lineNumber.toString().padLeft(2, '0')}行\n');
      }
      sheet1.setDelta(eightLinesDelta);
      final joinCaretOffset = sheet1.document.length - 1;

      // Trigger Spill-Back at offset 0 of Sheet 2 (which has 6 rows > 2 available rows)
      final result = coordinator.handleSpillBack(1);

      expect(result, isNotNull);
      expect(result!.destinationSheetIndex, equals(0));
      expect(result.destinationCaretOffset, equals(joinCaretOffset));
      expect(result.didCollapse, isFalse);

      // Sheet 1 must have pulled 2 rows (total 10 rows, zero overflow!) and Sheet 2 retains 4 rows
      expect(coordinator.totalSheets, equals(2));
      expect(coordinator.activeSheetIndex, equals(0));
      expect(sheet1.plainText.trim().split('\n').length, equals(10));
      final updatedSheet2 = coordinator.sheets[1] as ContinuationSheet;
      expect(updatedSheet2.plainText.trim().split('\n').length, equals(4));

      coordinator.dispose();
    });

    test('Spill-Back at offset 0 collapses empty Sheet 2 and returns focus to Sheet 1', () {
      final coordinator = EditorPaginationCoordinator(typography: typography);

      final delta = Delta();
      for (int lineNumber = 1; lineNumber <= 12; lineNumber++) {
        delta.insert('测试行第$lineNumber段文字\n');
      }
      coordinator.initializeFromDelta(jsonEncode(delta.toJson()));
      expect(coordinator.totalSheets, equals(2));

      final sheet2 = coordinator.sheets[1] as ContinuationSheet;
      sheet2.setDelta(Delta()..insert('\n'));

      final result = coordinator.handleSpillBack(1);

      expect(result, isNotNull);
      expect(result!.didCollapse, isTrue);
      expect(result.destinationSheetIndex, equals(0));
      expect(coordinator.totalSheets, equals(1));
      expect(coordinator.activeSheetIndex, equals(0));

      coordinator.dispose();
    });

    test('collapseEmptyContinuationSheets removes empty continuation sheets while preserving Sheet 1', () {
      final coordinator = EditorPaginationCoordinator(typography: typography);

      final delta = Delta();
      for (int lineNumber = 1; lineNumber <= 13; lineNumber++) {
        delta.insert('第${lineNumber.toString().padLeft(2, '0')}行日记\n');
      }
      coordinator.initializeFromDelta(jsonEncode(delta.toJson()));
      expect(coordinator.totalSheets, equals(2));

      final sheet2 = coordinator.sheets[1] as ContinuationSheet;
      sheet2.setDelta(Delta()..insert('\n'));

      final collapsed = coordinator.collapseEmptyContinuationSheets();
      expect(collapsed, isTrue);
      expect(coordinator.totalSheets, equals(1));
      expect(coordinator.sheets.first.isOpeningSheet, isTrue);

      final sheet1 = coordinator.sheets.first as OpeningSheet;
      sheet1.setDelta(Delta()..insert('\n'));

      final secondCollapsed = coordinator.collapseEmptyContinuationSheets();
      expect(secondCollapsed, isFalse);
      expect(coordinator.totalSheets, equals(1));
      expect(coordinator.sheets.first.isOpeningSheet, isTrue);

      coordinator.dispose();
    });

    test('Splitting and merging across sheets preserves inline and block attributes with 1:1 cold-load parity', () {
      // 17 chars/row in unconstrained mode -> 10 rows on Sheet 1 = 170 chars.
      // Prefix: 160 bold red chars; middle: 20 italic chars crossing offset 170; suffix: 15 plain chars + header/list block.
      final boldPrefix = '前' * 160;
      final italicBridge = '中' * 20;
      final plainSuffix = '后' * 15;
      final delta = Delta()
        ..insert(boldPrefix, {'bold': true, 'color': '#FF0000'})
        ..insert(italicBridge, {'italic': true})
        ..insert('$plainSuffix\n', {'list': 'bullet'});

      final coordinator = EditorPaginationCoordinator(typography: typography);
      coordinator.initializeFromDelta('');
      final sheet1 = coordinator.sheets.first as OpeningSheet;
      sheet1.setDelta(delta);

      final spillResult = coordinator.checkAndPerformAutoSpill(0);
      expect(spillResult, isNotNull);
      expect(coordinator.totalSheets, equals(2));

      final sheet2 = coordinator.sheets[1] as ContinuationSheet;
      expect(sheet1.hasTrailingSoftNewline, isTrue);

      // Sheet 1 holds the 160 bold+red chars, the first 10 italic chars, and a soft newline preserving block attributes.
      expect(sheet1.delta.operations[0].data, equals(boldPrefix));
      expect(sheet1.delta.operations[0].attributes?['bold'], isTrue);
      expect(sheet1.delta.operations[0].attributes?['color'], equals('#FF0000'));
      expect(sheet1.delta.operations[1].data, equals('中' * 10));
      expect(sheet1.delta.operations[1].attributes?['italic'], isTrue);
      expect(sheet1.delta.operations.last.data, equals('\n'));
      expect(sheet1.delta.operations.last.attributes?['list'], equals('bullet'));

      // Sheet 2 holds the remaining 10 italic chars and the suffix with its terminating list attribute.
      expect(sheet2.delta.operations[0].data, equals('中' * 10));
      expect(sheet2.delta.operations[0].attributes?['italic'], isTrue);
      expect(sheet2.delta.operations[1].data, equals('$plainSuffix\n'));
      expect(sheet2.delta.operations[1].attributes?['list'], equals('bullet'));

      // Cold-load partitioning produces 1:1 identical sheet breaks and deltas.
      final partitioned = EditorDeltaPartitioner.partition(
        unifiedDelta: delta,
        typography: typography,
        contentWidth: null,
        templateStyle: coordinator.templateStyle,
      );
      expect(partitioned.sheets.length, equals(2));
      expect(
        (partitioned.sheets[0] as TextStationerySheet).delta.toJson(),
        equals(sheet1.delta.toJson()),
      );
      expect(
        (partitioned.sheets[1] as TextStationerySheet).delta.toJson(),
        equals(sheet2.delta.toJson()),
      );
      for (final sheet in partitioned.sheets) {
        sheet.dispose();
      }

      // Re-synthesizing strips the soft newline and losslessly reunites the original Delta.
      final (resynthesizedJson, _) = coordinator.reSynthesize();
      expect(jsonDecode(resynthesizedJson), equals(delta.toJson()));

      coordinator.dispose();
    });

    test('Splitting across sheet boundary snaps away from UTF-16 emoji surrogate pairs without corruption', () {
      // 169 CJK chars + '🌸' (2 UTF-16 code units at indices 169..170) + '墨韵\n'.
      // Target cut offset 170 falls inside '🌸' and must back off to 169.
      final prefix169 = '诗' * 169;
      final delta = Delta()..insert('$prefix169🌸墨韵\n');

      final coordinator = EditorPaginationCoordinator(typography: typography);
      coordinator.initializeFromDelta('');
      final sheet1 = coordinator.sheets.first as OpeningSheet;
      sheet1.setDelta(delta);

      final spillResult = coordinator.checkAndPerformAutoSpill(0);
      expect(spillResult, isNotNull);
      expect(coordinator.totalSheets, equals(2));

      final sheet2 = coordinator.sheets[1] as ContinuationSheet;
      expect(sheet1.plainText, equals('$prefix169\n'));
      expect(sheet1.hasTrailingSoftNewline, isTrue);
      expect(sheet2.plainText, equals('🌸墨韵\n'));

      final partitioned = EditorDeltaPartitioner.partition(
        unifiedDelta: delta,
        typography: typography,
        contentWidth: null,
        templateStyle: coordinator.templateStyle,
      );
      expect(
        (partitioned.sheets[0] as TextStationerySheet).delta.toJson(),
        equals(sheet1.delta.toJson()),
      );
      expect(
        (partitioned.sheets[1] as TextStationerySheet).delta.toJson(),
        equals(sheet2.delta.toJson()),
      );
      for (final sheet in partitioned.sheets) {
        sheet.dispose();
      }

      final (resynthesizedJson, _) = coordinator.reSynthesize();
      expect(jsonDecode(resynthesizedJson), equals(delta.toJson()));

      coordinator.dispose();
    });

    test('Empty trailing newlines overflowing a sheet retain mount markers on the source sheet across cold load and live Auto-Spill', () {
      final attachment = MediaAttachment(
        id: 'photo1',
        entryId: 'entry_1',
        mediaType: 'image',
        relativePath: 'media/photo1.webp',
        createdAt: DateTime(2026, 11, 12),
      );
      final delta = Delta();
      for (int lineIndex = 0; lineIndex < 10; lineIndex++) {
        delta.insert('\n');
      }
      delta.insert(MountMarker.embeddable('photo1').toJson());
      for (int lineIndex = 0; lineIndex < 5; lineIndex++) {
        delta.insert('\n');
      }

      // 1. Live Auto-Spill path
      final coordinator = EditorPaginationCoordinator(typography: typography);
      coordinator.initializeFromDelta(
        jsonEncode((Delta()..insert(MountMarker.embeddable('photo1').toJson())..insert('\n')).toJson()),
        attachments: [attachment],
      );
      final sheet1 = coordinator.sheets.first as OpeningSheet;
      sheet1.setDelta(delta);

      coordinator.checkAndPerformAutoSpill(0);
      expect(coordinator.totalSheets, equals(2));
      final sheet2 = coordinator.sheets[1] as ContinuationSheet;
      expect(MountMarker.mediaIdsIn(sheet1.delta), contains('photo1'));
      expect(MountMarker.mediaIdsIn(sheet2.delta), isEmpty);
      expect(sheet1.mediaAttachments.map((item) => item.id), ['photo1']);
      expect(sheet2.mediaAttachments, isEmpty);

      // 2. Cold-load partition path must match 1:1
      final partitioned = EditorDeltaPartitioner.partition(
        unifiedDelta: delta,
        media: [SheetMediaItem.fromMediaAttachment(attachment)],
        typography: typography,
        contentWidth: null,
        templateStyle: coordinator.templateStyle,
      );
      expect(partitioned.sheets.length, equals(2));
      final coldSheet1 = partitioned.sheets[0] as TextStationerySheet;
      final coldSheet2 = partitioned.sheets[1] as TextStationerySheet;
      expect(MountMarker.mediaIdsIn(coldSheet1.delta), contains('photo1'));
      expect(MountMarker.mediaIdsIn(coldSheet2.delta), isEmpty);
      expect(coldSheet1.mediaAttachments.map((item) => item.id), ['photo1']);
      expect(coldSheet2.mediaAttachments, isEmpty);

      for (final sheet in partitioned.sheets) {
        sheet.dispose();
      }
      coordinator.dispose();
    });

    test('Overflowing text carries its anchored mount marker onto the continuation sheet across cold load and live Auto-Spill', () {
      final attachment = MediaAttachment(
        id: 'photo1',
        entryId: 'entry_1',
        mediaType: 'image',
        relativePath: 'media/photo1.webp',
        createdAt: DateTime(2026, 11, 12),
      );
      final delta = Delta();
      for (int lineNumber = 1; lineNumber <= 15; lineNumber++) {
        delta.insert('Line $lineNumber');
        if (lineNumber == 12) {
          delta.insert(MountMarker.embeddable('photo1').toJson());
        }
        delta.insert('\n');
      }

      final coordinator = EditorPaginationCoordinator(typography: typography);
      coordinator.initializeFromDelta(
        jsonEncode((Delta()..insert('Line 1')..insert(MountMarker.embeddable('photo1').toJson())..insert('\n')).toJson()),
        attachments: [attachment],
      );
      final sheet1 = coordinator.sheets.first as OpeningSheet;
      sheet1.setDelta(delta);

      coordinator.checkAndPerformAutoSpill(0);
      expect(coordinator.totalSheets, equals(2));
      final updatedSheet1 = coordinator.sheets[0] as OpeningSheet;
      final sheet2 = coordinator.sheets[1] as ContinuationSheet;
      expect(MountMarker.mediaIdsIn(updatedSheet1.delta), isEmpty);
      expect(MountMarker.mediaIdsIn(sheet2.delta), contains('photo1'));
      expect(updatedSheet1.mediaAttachments, isEmpty);
      expect(sheet2.mediaAttachments.map((item) => item.id), ['photo1']);

      final partitioned = EditorDeltaPartitioner.partition(
        unifiedDelta: delta,
        media: [SheetMediaItem.fromMediaAttachment(attachment)],
        typography: typography,
        contentWidth: null,
        templateStyle: coordinator.templateStyle,
      );
      expect(partitioned.sheets.length, equals(2));
      final coldSheet1 = partitioned.sheets[0] as TextStationerySheet;
      final coldSheet2 = partitioned.sheets[1] as TextStationerySheet;
      expect(MountMarker.mediaIdsIn(coldSheet1.delta), isEmpty);
      expect(MountMarker.mediaIdsIn(coldSheet2.delta), contains('photo1'));
      expect(coldSheet1.mediaAttachments, isEmpty);
      expect(coldSheet2.mediaAttachments.map((item) => item.id), ['photo1']);

      for (final sheet in partitioned.sheets) {
        sheet.dispose();
      }
      coordinator.dispose();
    });
  });
}
