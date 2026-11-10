import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/controllers/editor_chrome_controller.dart';

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

  group('workstation', () {
    testWidgets('the first layout docks it when it fits, without notifying', (tester) async {
      expect(chrome.resolveInitialWorkstation(workstationFits: true), isFalse);
      await tester.pump();
      expect(chrome.isWorkstationCollapsed, isFalse);
      expect(notifications, 0);
    });

    testWidgets('the first layout collapses it when it does not fit and notifies after the frame',
        (tester) async {
      expect(chrome.resolveInitialWorkstation(workstationFits: false), isTrue);
      expect(notifications, 0);
      tester.binding.scheduleFrame();
      await tester.pump();
      expect(notifications, 1);
      expect(chrome.isWorkstationCollapsed, isTrue);
    });

    testWidgets('only the first layout decides', (tester) async {
      chrome.resolveInitialWorkstation(workstationFits: true);
      expect(chrome.resolveInitialWorkstation(workstationFits: false), isFalse);
      expect(chrome.isWorkstationCollapsed, isFalse);
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
      expect(chrome.resolveInitialWorkstation(workstationFits: true), isTrue);
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

  testWidgets('a deferred collapse after disposal does not notify', (tester) async {
    final disposable = EditorChromeController()..addListener(() => notifications++);
    disposable.resolveInitialWorkstation(workstationFits: false);
    disposable.dispose();
    WidgetsBinding.instance.scheduleFrame();
    await tester.pump();
    expect(notifications, 0);
  });
}
