import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/features/editor/widgets/desk_workstation/desk_space_budget.dart';

void main() {
  const canvasHeight = 690.0;
  const sheetHeight = 400.0;
  const sealBlockHeight = 64.0;

  DeskSpaceBudget resolve({
    bool hasMountedItems = false,
    bool isWorkstationCollapsed = false,
    bool isKeyboardVisible = false,
    bool isLastSheet = false,
  }) =>
      DeskSpaceBudget.resolve(
        canvasHeight: canvasHeight,
        sheetHeight: sheetHeight,
        sealBlockHeight: sealBlockHeight,
        hasMountedItems: hasMountedItems,
        isHandscrollEmpty: true,
        isWorkstationCollapsed: isWorkstationCollapsed,
        isKeyboardVisible: isKeyboardVisible,
        isLastSheet: isLastSheet,
      );

  group('DeskSpaceBudget', () {
    test('a docked workstation keeps the sheet under the header band and fills the desk beneath it', () {
      final budget = resolve();

      expect(budget.sheetTop, DeskSpaceBudget.kHeaderHeight);
      expect(budget.headerTop, 0.0);
      expect(budget.showWorkstation, isTrue);
      // No dead desk above the sheet: what is left goes to the workstation.
      expect(
        budget.workstationHeight,
        canvasHeight - DeskSpaceBudget.kHeaderHeight - sheetHeight - sealBlockHeight,
      );
    });

    test('the sheet sits at the same place on every page, with or without the seal', () {
      expect(resolve(isLastSheet: true).sheetTop, resolve().sheetTop);
      expect(resolve(isLastSheet: true).showSeal, isTrue);
      expect(resolve().showSeal, isFalse);
      expect(resolve(isLastSheet: true).workstationHeight, resolve().workstationHeight);
    });

    test('a mounted sheet keeps the sheet in place and lays the strip between it and the workstation', () {
      final budget = resolve(hasMountedItems: true);

      expect(budget.sheetTop, DeskSpaceBudget.kHeaderHeight);
      expect(budget.showStrip, isTrue);
      expect(budget.stripTop, budget.sheetTop + sheetHeight + DeskSpaceBudget.kSheetGap);
      expect(
        canvasHeight - budget.workstationHeight,
        greaterThanOrEqualTo(budget.stripTop + DeskSpaceBudget.kStripHeight),
      );
    });

    test('collapsing the workstation centres the sheet on the desk', () {
      final budget = resolve(isWorkstationCollapsed: true);

      expect(budget.showWorkstation, isFalse);
      expect(budget.sheetTop, greaterThan(DeskSpaceBudget.kHeaderHeight));
      final roomAbove = budget.headerTop;
      final roomBelow = canvasHeight - budget.sheetTop - sheetHeight - sealBlockHeight;
      expect(roomAbove, closeTo(roomBelow, 0.5));
    });

    test('opening the keyboard never moves the sheet; the strip and workstation step aside', () {
      for (final collapsed in [false, true]) {
        for (final mounted in [false, true]) {
          final resting = resolve(isWorkstationCollapsed: collapsed, hasMountedItems: mounted);
          final typing = resolve(
            isWorkstationCollapsed: collapsed,
            hasMountedItems: mounted,
            isKeyboardVisible: true,
          );
          expect(typing.sheetTop, resting.sheetTop);
          expect(typing.showWorkstation, isFalse);
          expect(typing.showStrip, isFalse);
        }
      }
    });
  });
}
