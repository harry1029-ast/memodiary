import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:memodiary/features/editor/domain/stationery_sheet_descriptor.dart';
import 'package:memodiary/features/editor/models/typography_settings.dart';
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
  });
}
