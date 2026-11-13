import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/controllers/editor_chrome_controller.dart';
import 'package:memodiary/features/editor/widgets/desk_workstation/desk_space_budget.dart';

void main() {
  late EditorChromeController chrome;
  late int notifications;

  setUp(() {
    chrome = EditorChromeController();
    notifications = 0;
    chrome.addListener(() => notifications++);
  });

  tearDown(() => chrome.dispose());

  group('keyboard', () {
    test('starts closed', () {
      expect(chrome.isKeyboardVisible, isFalse);
      expect(chrome.keyboardInset, 0.0);
    });

    test('opening records the inset without reporting a close', () {
      expect(chrome.syncKeyboardInset(300.0), isFalse);
      expect(chrome.isKeyboardVisible, isTrue);
      expect(chrome.keyboardInset, 300.0);
    });

    test('closing reports the close exactly once', () {
      chrome.syncKeyboardInset(300.0);
      expect(chrome.syncKeyboardInset(0.0), isTrue);
      expect(chrome.isKeyboardVisible, isFalse);
      expect(chrome.syncKeyboardInset(0.0), isFalse);
    });

    test('resizing while open is not a close', () {
      chrome.syncKeyboardInset(300.0);
      expect(chrome.syncKeyboardInset(260.0), isFalse);
      expect(chrome.keyboardInset, 260.0);
    });

    test('syncing never notifies, since the view inset already rebuilds consumers', () {
      chrome.syncKeyboardInset(300.0);
      chrome.syncKeyboardInset(0.0);
      expect(notifications, 0);
    });
  });

  group('resting desk height', () {
    test('follows the desk while the keyboard is closed', () {
      expect(chrome.resolveRestingDeskHeight(600.0), 600.0);
      expect(chrome.resolveRestingDeskHeight(640.0), 640.0, reason: 'e.g. the Writing Dock was hidden');
    });

    test('holds while the keyboard is open, whatever chrome steps aside', () {
      chrome.resolveRestingDeskHeight(600.0);
      chrome.syncKeyboardInset(300.0);
      expect(chrome.resolveRestingDeskHeight(300.0), 600.0);
      chrome.syncAppBarHiddenExtent(56.0);
      expect(chrome.resolveRestingDeskHeight(368.0), 600.0);
    });

    test('discounts the part of the app bar still sliding back after the keyboard closes', () {
      chrome.resolveRestingDeskHeight(600.0);
      chrome.syncKeyboardInset(300.0);
      chrome.syncAppBarHiddenExtent(56.0);
      chrome.syncKeyboardInset(0.0);
      expect(chrome.resolveRestingDeskHeight(656.0), 600.0);
      chrome.syncAppBarHiddenExtent(20.0);
      expect(chrome.resolveRestingDeskHeight(620.0), 600.0);
      chrome.syncAppBarHiddenExtent(0.0);
      expect(chrome.resolveRestingDeskHeight(600.0), 600.0);
    });

    test('before any resting measure, adds the keyboard back and takes the slid-away app bar off', () {
      chrome.syncKeyboardInset(300.0);
      expect(chrome.resolveRestingDeskHeight(320.0), 620.0);
      chrome.syncAppBarHiddenExtent(56.0);
      expect(chrome.resolveRestingDeskHeight(376.0), 620.0);
    });

    test('resolving and syncing never notify', () {
      chrome.syncAppBarHiddenExtent(56.0);
      chrome.resolveRestingDeskHeight(600.0);
      expect(notifications, 0);
    });
  });

  DeskSpaceBudget resolveBudget({
    double restingDeskHeight = 690.0,
    double sheetHeight = 400.0,
    double sealBlockHeight = 64.0,
    bool isHandscrollEmpty = true,
    bool isLastSheet = false,
  }) =>
      chrome.resolveDeskBudget(
        restingDeskHeight: restingDeskHeight,
        sheetHeight: sheetHeight,
        sealBlockHeight: sealBlockHeight,
        isHandscrollEmpty: isHandscrollEmpty,
        isLastSheet: isLastSheet,
      );

  group('workstation', () {
    testWidgets('the first layout docks it when it fits, without notifying', (tester) async {
      final budget = resolveBudget(restingDeskHeight: 690.0, sheetHeight: 400.0);

      expect(budget.workstationFits, isTrue);
      expect(budget.showWorkstation, isTrue);
      expect(chrome.isWorkstationCollapsed, isFalse);
      await tester.pump();
      expect(notifications, 0);
    });

    testWidgets('the first layout collapses it on a short (< 420dp) viewport and notifies after the frame',
        (tester) async {
      final budget = resolveBudget(
        restingDeskHeight: 410.0,
        sheetHeight: 280.0,
        isLastSheet: true,
      );

      expect(budget.workstationFits, isFalse);
      expect(budget.showWorkstation, isFalse);
      expect(chrome.isWorkstationCollapsed, isTrue);
      expect(notifications, 0);

      tester.binding.scheduleFrame();
      await tester.pump();
      expect(notifications, 1);
      expect(chrome.isWorkstationCollapsed, isTrue);
    });

    testWidgets('only the first layout decides: docked choice sticks across non-fitting changes', (tester) async {
      resolveBudget(restingDeskHeight: 690.0, sheetHeight: 400.0);

      final second = resolveBudget(
        restingDeskHeight: 410.0,
        sheetHeight: 350.0,
        isHandscrollEmpty: false,
      );

      expect(second.workstationFits, isFalse);
      expect(second.showWorkstation, isTrue);
      expect(chrome.isWorkstationCollapsed, isFalse);
    });

    testWidgets('only the first layout decides: collapsed choice sticks across taller viewports', (tester) async {
      resolveBudget(restingDeskHeight: 410.0, sheetHeight: 280.0);
      tester.binding.scheduleFrame();
      await tester.pump();

      final second = resolveBudget(restingDeskHeight: 750.0, sheetHeight: 400.0);

      expect(second.workstationFits, isTrue);
      expect(second.showWorkstation, isFalse);
      expect(chrome.isWorkstationCollapsed, isTrue);
    });

    test('collapsing and expanding round-trip, and repeats are no-ops', () {
      chrome.collapseWorkstation();
      chrome.collapseWorkstation();
      expect(chrome.isWorkstationCollapsed, isTrue);
      chrome.expandWorkstation();
      expect(chrome.isWorkstationCollapsed, isFalse);
      expect(notifications, 2);
    });

    test('a collapse before the first layout wins over it', () {
      chrome.collapseWorkstation();
      final budget = resolveBudget(restingDeskHeight: 690.0, sheetHeight: 400.0);
      expect(chrome.isWorkstationCollapsed, isTrue);
      expect(budget.showWorkstation, isFalse);
    });

    test('resolveDeskBudget hides the workstation and seal while the keyboard is open', () {
      chrome.syncKeyboardInset(300.0);
      final budget = resolveBudget(restingDeskHeight: 690.0, sheetHeight: 400.0, isLastSheet: true);
      expect(chrome.isWorkstationCollapsed, isFalse);
      expect(budget.showWorkstation, isFalse);
      expect(budget.showSeal, isFalse);
    });

    test('expanding restores a collapsed workstation and is a no-op when docked', () {
      chrome.expandWorkstation();
      expect(notifications, 0);
      chrome.collapseWorkstation();
      chrome.expandWorkstation();
      expect(chrome.isWorkstationCollapsed, isFalse);
      expect(notifications, 2);
    });
  });

  group('dictation', () {
    test('toggling starts and stops dictation', () {
      expect(chrome.isDictating, isFalse);
      chrome.toggleDictation();
      expect(chrome.isDictating, isTrue);
      chrome.toggleDictation();
      expect(chrome.isDictating, isFalse);
      expect(notifications, 2);
    });

    test('stopping ends dictation and is a no-op when not dictating', () {
      chrome.stopDictation();
      expect(notifications, 0);
      chrome.toggleDictation();
      chrome.stopDictation();
      expect(chrome.isDictating, isFalse);
      expect(notifications, 2);
    });
  });

  group('writing dock', () {
    test('is shown by default', () {
      expect(chrome.isWritingDockVisible, isTrue);
    });

    test('hiding and showing it notifies only on change', () {
      chrome.setWritingDockVisible(false);
      expect(chrome.isWritingDockVisible, isFalse);
      chrome.setWritingDockVisible(false);
      chrome.setWritingDockVisible(true);
      expect(chrome.isWritingDockVisible, isTrue);
      expect(notifications, 2);
    });

    test('its restore tab floats on the desk only while the dock is hidden and the keyboard closed', () {
      expect(chrome.showsWritingDockRestoreTab, isFalse, reason: 'the dock is shown');
      chrome.setWritingDockVisible(false);
      expect(chrome.showsWritingDockRestoreTab, isTrue);
      chrome.syncKeyboardInset(300.0);
      expect(chrome.showsWritingDockRestoreTab, isFalse, reason: 'the accessory row toggles the dock while typing');
    });
  });

  group('formatting ribbon', () {
    test('starts closed and toggles with listener notifications', () {
      expect(chrome.isFormattingOpen, isFalse);

      chrome.toggleFormatting();
      expect(chrome.isFormattingOpen, isTrue);
      expect(notifications, 1);

      chrome.toggleFormatting();
      expect(chrome.isFormattingOpen, isFalse);
      expect(notifications, 2);
    });

    test('stays open across keyboard transitions, dock hide/restore, and workstation collapse/expand', () {
      chrome.toggleFormatting();
      expect(chrome.isFormattingOpen, isTrue);

      chrome.syncKeyboardInset(300.0);
      expect(chrome.isFormattingOpen, isTrue);

      chrome.setWritingDockVisible(false);
      expect(chrome.isFormattingOpen, isTrue);

      chrome.collapseWorkstation();
      expect(chrome.isFormattingOpen, isTrue);

      chrome.syncKeyboardInset(0.0);
      expect(chrome.isFormattingOpen, isTrue);

      chrome.setWritingDockVisible(true);
      chrome.expandWorkstation();
      expect(chrome.isFormattingOpen, isTrue);
    });
  });

  testWidgets('a deferred collapse after disposal does not notify', (tester) async {
    final disposable = EditorChromeController()..addListener(() => notifications++);
    disposable.resolveDeskBudget(
      restingDeskHeight: 410.0,
      sheetHeight: 280.0,
      sealBlockHeight: 64.0,
      isHandscrollEmpty: true,
      isLastSheet: false,
    );
    disposable.dispose();
    WidgetsBinding.instance.scheduleFrame();
    await tester.pump();
    expect(notifications, 0);
  });
}
