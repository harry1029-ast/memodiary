import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/features/editor/widgets/desk_workstation/desk_space_budget.dart';

void main() {
  const canvasHeight = 690.0;
  const sheetHeight = 400.0;
  const sealBlockHeight = 64.0;

  DeskSpaceBudget resolve({
    double canvasHeight = canvasHeight,
    bool isHandscrollEmpty = true,
    bool isWorkstationCollapsed = false,
    bool isKeyboardVisible = false,
    bool isLastSheet = false,
  }) =>
      DeskSpaceBudget.resolve(
        canvasHeight: canvasHeight,
        sheetHeight: sheetHeight,
        sealBlockHeight: sealBlockHeight,
        isHandscrollEmpty: isHandscrollEmpty,
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
      // No band below the sheet: all that is left (bar the seal's room) goes to the workstation.
      expect(budget.workstationHeight, 690.0 - 30.0 - 400.0 - 64.0);
    });

    test('the sheet sits at the same place on every page, with or without the seal', () {
      expect(resolve(isLastSheet: true).sheetTop, resolve().sheetTop);
      expect(resolve(isLastSheet: true).showSeal, isTrue);
      expect(resolve().showSeal, isFalse);
      expect(resolve(isLastSheet: true).workstationHeight, resolve().workstationHeight);
    });

    test('on a short desk the workstation keeps its floor: 150 open, 110 for the closed scroll', () {
      // 30 header + 400 sheet + 64 seal leaves 26: below either floor.
      const shortDesk = 520.0;

      expect(resolve(canvasHeight: shortDesk, isHandscrollEmpty: false).workstationHeight, 150.0);
      expect(resolve(canvasHeight: shortDesk).workstationHeight, 110.0);
      expect(resolve(canvasHeight: shortDesk, isLastSheet: true).showSeal, isFalse);
    });

    test('whether the workstation fits is judged against the sheet alone', () {
      // Room below the sheet (after the 10 gap): 590 - 30 - 400 - 10 = 150.
      expect(resolve(canvasHeight: 590.0, isHandscrollEmpty: false).workstationFits, isTrue);
      expect(resolve(canvasHeight: 589.0, isHandscrollEmpty: false).workstationFits, isFalse);
      expect(resolve(canvasHeight: 550.0).workstationFits, isTrue);
      expect(resolve(canvasHeight: 549.0).workstationFits, isFalse);
    });

    test('fitsWorkstation matches resolve.workstationFits across open, empty, and short viewports', () {
      const cases = <(double canvas, double sheet, bool empty, bool expected)>[
        (590.0, 400.0, false, true),
        (589.0, 400.0, false, false),
        (550.0, 400.0, true, true),
        (549.0, 400.0, true, false),
        (410.0, 280.0, true, false), // < 420dp short viewport: 410 - 30 - 280 - 10 = 90 < 110
      ];
      for (final (canvas, sheet, empty, expected) in cases) {
        expect(
          DeskSpaceBudget.fitsWorkstation(
            canvasHeight: canvas,
            sheetHeight: sheet,
            isHandscrollEmpty: empty,
          ),
          expected,
        );
        expect(
          DeskSpaceBudget.resolve(
            canvasHeight: canvas,
            sheetHeight: sheet,
            sealBlockHeight: sealBlockHeight,
            isHandscrollEmpty: empty,
            isWorkstationCollapsed: false,
            isKeyboardVisible: false,
            isLastSheet: false,
          ).workstationFits,
          expected,
        );
      }
    });

    test('collapsing the workstation centres the sheet on the desk', () {
      final budget = resolve(isWorkstationCollapsed: true);

      expect(budget.showWorkstation, isFalse);
      expect(budget.sheetTop, greaterThan(DeskSpaceBudget.kHeaderHeight));
      final roomAbove = budget.headerTop;
      final roomBelow = canvasHeight - budget.sheetTop - sheetHeight - sealBlockHeight;
      expect(roomAbove, closeTo(roomBelow, 0.5));
    });

    test('opening the keyboard never moves the sheet; the workstation and seal step aside', () {
      for (final collapsed in [false, true]) {
        for (final lastSheet in [false, true]) {
          final resting = resolve(isWorkstationCollapsed: collapsed, isLastSheet: lastSheet);
          final typing = resolve(
            isWorkstationCollapsed: collapsed,
            isLastSheet: lastSheet,
            isKeyboardVisible: true,
          );
          expect(typing.sheetTop, resting.sheetTop);
          expect(typing.showWorkstation, isFalse);
          expect(typing.showSeal, isFalse);
        }
      }
    });
  });
}
