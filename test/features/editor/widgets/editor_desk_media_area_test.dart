import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/widgets/desk_workstation/desk_space_budget.dart';
import 'package:memodiary/features/editor/widgets/editor_desk_media_area.dart';
import '../../../helpers/editor_test_harness.dart';

void main() {
  late Directory tempDirectory;

  setUp(() => tempDirectory = Directory.systemTemp.createTempSync('desk_media_area_test_'));
  tearDown(() => tempDirectory.deleteSync(recursive: true));

  final pullTab = find.byKey(const Key('workstation_pull_tab'));
  final pill = find.byKey(const Key('workstation_restore_pill'));

  Future<void> pumpArea(
    WidgetTester tester, {
    required bool isWorkstationCollapsed,
    required bool isKeyboardVisible,
    VoidCallback? onCollapse,
    VoidCallback? onRestore,
  }) async {
    final budget = DeskSpaceBudget.resolve(
      canvasHeight: 700.0,
      sheetHeight: 400.0,
      sealBlockHeight: 64.0,
      isHandscrollEmpty: true,
      isWorkstationCollapsed: isWorkstationCollapsed,
      isKeyboardVisible: isKeyboardVisible,
      isLastSheet: false,
    );
    await tester.pumpWidget(MaterialApp(
      theme: InkDiaryTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 400.0,
          height: 700.0,
          child: EditorDeskMediaArea(
            budget: budget,
            mountedItems: const [],
            stagedItems: const [],
            mediaSandboxService: SyncTestMediaSandboxService(tempDir: tempDirectory),
            activeSheetNumber: 1,
            isWorkstationCollapsed: isWorkstationCollapsed,
            onCollapseWorkstation: onCollapse ?? () {},
            onRestoreWorkstation: onRestore ?? () {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('EditorDeskMediaArea', () {
    testWidgets('a docked workstation shows its pull tab, which puts it away', (tester) async {
      var collapses = 0;
      await pumpArea(tester, isWorkstationCollapsed: false, isKeyboardVisible: false, onCollapse: () => collapses++);

      expect(pill, findsNothing);
      await tester.tap(pullTab);
      expect(collapses, 1);
    });

    testWidgets('a collapsed workstation shows only the Restore Pill, which brings it back', (tester) async {
      var restores = 0;
      await pumpArea(tester, isWorkstationCollapsed: true, isKeyboardVisible: false, onRestore: () => restores++);

      expect(pullTab, findsNothing);
      await tester.tap(pill);
      expect(restores, 1);
    });

    testWidgets('while the keyboard steps the docked workstation aside, neither control is built', (tester) async {
      await pumpArea(tester, isWorkstationCollapsed: false, isKeyboardVisible: true);

      expect(tester.takeException(), isNull);
      expect(pullTab, findsNothing);
      expect(pill, findsNothing);
    });
  });
}
