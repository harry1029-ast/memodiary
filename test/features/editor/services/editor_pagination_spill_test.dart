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

      // Append 15 lines of 17 chars each (each line = 1 row)
      final overflowingDelta = Delta();
      for (int i = 1; i <= 15; i++) {
        overflowingDelta.insert('第${i.toString().padLeft(2, '0')}行测试输入文字字\n');
      }
      final textLen = overflowingDelta.operations
          .fold<int>(0, (sum, op) => sum + (op.data is String ? (op.data as String).length : 1));
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

      // Sheet 1 must keep 10 lines
      final sheet1Lines = sheet1.plainText.trim().split('\n');
      expect(sheet1Lines.length, equals(10));
      expect(sheet1Lines.first, contains('第01行'));
      expect(sheet1Lines.last, contains('第10行'));

      // Sheet 2 must hold remaining 5 lines
      final sheet2 = coordinator.sheets[1] as ContinuationSheet;
      final sheet2Lines = sheet2.plainText.trim().split('\n');
      expect(sheet2Lines.length, equals(5));
      expect(sheet2Lines.first, contains('第11行'));
      expect(sheet2Lines.last, contains('第15行'));

      coordinator.dispose();
    });

    test('Multi-paragraph paste cascades across multiple continuation sheets', () {
      final coordinator = EditorPaginationCoordinator(typography: typography);
      coordinator.initializeFromDelta('');

      final sheet1 = coordinator.sheets.first as OpeningSheet;

      // 32 rows total: 10 on Sheet 1, 14 on Sheet 2, 8 on Sheet 3
      final pasteDelta = Delta();
      for (int i = 1; i <= 32; i++) {
        pasteDelta.insert('第${i.toString().padLeft(2, '0')}行大段粘贴测试\n');
      }
      sheet1.setDelta(
        pasteDelta,
        selection: TextSelection.collapsed(offset: pasteDelta.length - 1),
      );

      coordinator.checkAndPerformAutoSpill(0);

      expect(coordinator.totalSheets, equals(3));
      expect(coordinator.sheets[0], isA<OpeningSheet>());
      expect(coordinator.sheets[1], isA<ContinuationSheet>());
      expect(coordinator.sheets[2], isA<ContinuationSheet>());

      // Sheet 1 has 10 lines
      final sheet0 = coordinator.sheets[0] as TextStationerySheet;
      expect(sheet0.plainText.trim().split('\n').length, equals(10));

      // Sheet 2 has 14 lines
      final sheet1Parsed = coordinator.sheets[1] as TextStationerySheet;
      expect(sheet1Parsed.plainText.trim().split('\n').length, equals(14));

      // Sheet 3 has 8 lines
      final sheet2Parsed = coordinator.sheets[2] as TextStationerySheet;
      expect(sheet2Parsed.plainText.trim().split('\n').length, equals(8));

      // Total text re-synthesizes completely
      final (_, plainText) = coordinator.reSynthesize();
      expect(plainText.split('\n').length, equals(32));

      coordinator.dispose();
    });

    test('Active mobile IME composition defers Auto-Spill until commit', () {
      final coordinator = EditorPaginationCoordinator(typography: typography);
      coordinator.initializeFromDelta('');

      final sheet1 = coordinator.sheets.first as OpeningSheet;
      final overflowingDelta = Delta();
      for (int i = 1; i <= 14; i++) {
        overflowingDelta.insert('第${i.toString().padLeft(2, '0')}行拼音输入中字\n');
      }
      sheet1.setDelta(overflowingDelta);

      // Simulate active IME composing range ('pinyin' in progress)
      coordinator.isImeComposing = true;

      final deferredResult = coordinator.checkAndPerformAutoSpill(0);
      expect(deferredResult, isNull);
      expect(coordinator.totalSheets, equals(1)); // Did not spill!

      // User commits candidate selection (composition ends)
      coordinator.isImeComposing = false;

      final committedResult = coordinator.checkAndPerformAutoSpill(0);
      expect(committedResult, isNotNull);
      expect(coordinator.totalSheets, equals(2)); // Spilled immediately after commit!

      coordinator.dispose();
    });

    test('Spill-Back merges content backward and collapses empty continuation sheet', () {
      final coordinator = EditorPaginationCoordinator(typography: typography);
      // Sheet 1 has 5 rows (room for 5 more), Sheet 2 has 3 rows
      final delta = Delta();
      for (int i = 1; i <= 5; i++) {
        delta.insert('第一页第$i行\n');
      }

      coordinator.initializeFromDelta(delta.toJson().toString());
      expect(coordinator.totalSheets, equals(1));

      // Setup 2 sheets directly
      final customCoord = EditorPaginationCoordinator(typography: typography);
      customCoord.initializeFromDelta('');
      final firstSheet = customCoord.sheets[0] as OpeningSheet;
      firstSheet.setDelta(delta);

      final spillBackResult = customCoord.handleSpillBack(0);
      expect(spillBackResult, isNull); // Sheet 0 cannot spill back

      customCoord.dispose();
      coordinator.dispose();
    });

    test('Spill-Back at offset 0 collapses empty Sheet 2 and returns focus to Sheet 1', () {
      final coordinator = EditorPaginationCoordinator(typography: typography);

      // 12 lines total: Sheet 1 gets 10, Sheet 2 gets 2
      final delta = Delta();
      for (int i = 1; i <= 12; i++) {
        delta.insert('测试行第$i段文字\n');
      }
      final deltaJson = jsonEncode(delta.toJson());
      coordinator.initializeFromDelta(deltaJson);

      expect(coordinator.totalSheets, equals(2));

      // Clear text on Sheet 2
      final sheet2 = coordinator.sheets[1] as ContinuationSheet;
      sheet2.setDelta(Delta()..insert('\n'));

      // Press backspace at offset 0 of Sheet 2
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

      // 13 lines -> Spills to Sheet 2
      final delta = Delta();
      for (int i = 1; i <= 13; i++) {
        delta.insert('第${i.toString().padLeft(2, '0')}行日记\n');
      }
      coordinator.initializeFromDelta(jsonEncode(delta.toJson()));
      expect(coordinator.totalSheets, equals(2));

      // Clear Sheet 2
      final sheet2 = coordinator.sheets[1] as ContinuationSheet;
      sheet2.setDelta(Delta()..insert('\n'));

      final collapsed = coordinator.collapseEmptyContinuationSheets();
      expect(collapsed, isTrue);
      expect(coordinator.totalSheets, equals(1));
      expect(coordinator.sheets.first.isOpeningSheet, isTrue);

      // Now clear Sheet 1: Sheet 1 must NEVER be collapsed!
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
