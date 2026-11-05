import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/widgets/writing_dock.dart';

void main() {
  group('WritingDock footer handle toggles the Desk Workstation', () {
    late QuillController controller;

    setUp(() {
      controller = QuillController.basic();
      controller.document.insert(0, 'Literati Journal\n');
    });

    tearDown(() {
      controller.dispose();
    });

    /// Hosts the dock the way the editor does: the dock owns no collapse state,
    /// it reflects and toggles the workstation's.
    Widget buildTestHarness({bool initiallyCollapsed = false, ValueChanged<bool>? onToggled}) {
      bool isCollapsed = initiallyCollapsed;
      return MaterialApp(
        theme: InkDiaryTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (builderContext, setHostState) => Align(
              alignment: Alignment.bottomCenter,
              child: WritingDock(
                controller: controller,
                onPickImage: () {},
                onToggleDictation: () {},
                isWorkstationCollapsed: isCollapsed,
                onToggleWorkstation: () {
                  setHostState(() => isCollapsed = !isCollapsed);
                  onToggled?.call(isCollapsed);
                },
                inkColor: const Color(0xFF2D2D2D),
                isPaperDark: false,
              ),
            ),
          ),
        ),
      );
    }

    final handle = find.byKey(const Key('writing_dock_workstation_handle'));
    final grip = find.byKey(const Key('writing_dock_workstation_grip'));

    testWidgets('tools stay visible and the handle names the action it performs', (tester) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('writing_dock_format_btn')), findsOneWidget);
      expect(find.byKey(const Key('writing_dock_photo_btn')), findsOneWidget);
      expect(find.byKey(const Key('writing_dock_dictation_btn')), findsOneWidget);
      expect(handle, findsOneWidget);
      expect(find.bySemanticsLabel('收起画案'), findsOneWidget);
    });

    testWidgets('the handle offers a full 44px touch target while its bar stays slim', (tester) async {
      final toggles = <bool>[];
      await tester.pumpWidget(buildTestHarness(onToggled: toggles.add));
      await tester.pumpAndSettle();

      final handleRect = tester.getRect(handle);
      expect(handleRect.height, greaterThanOrEqualTo(44.0));
      expect(tester.getSize(grip).height, lessThan(44.0));

      // A tap below the grip, clear of the tool buttons, still reaches the handle.
      await tester.tapAt(Offset(handleRect.left + 6, handleRect.bottom - 6));
      await tester.pumpAndSettle();
      expect(toggles, [true]);
      expect(find.byKey(const Key('writing_dock_photo_btn')), findsOneWidget);
    });

    testWidgets('tapping the handle collapses the workstation and tapping again restores it', (tester) async {
      final toggles = <bool>[];
      await tester.pumpWidget(buildTestHarness(onToggled: toggles.add));
      await tester.pumpAndSettle();

      await tester.tap(grip);
      await tester.pumpAndSettle();
      expect(toggles, [true]);
      expect(find.bySemanticsLabel('展开画案'), findsOneWidget);
      expect(find.byKey(const Key('writing_dock_photo_btn')), findsOneWidget);

      await tester.tap(grip);
      await tester.pumpAndSettle();
      expect(toggles, [true, false]);
      expect(find.bySemanticsLabel('收起画案'), findsOneWidget);
    });

    testWidgets('dragging the handle down collapses and dragging it up restores', (tester) async {
      final toggles = <bool>[];
      await tester.pumpWidget(buildTestHarness(onToggled: toggles.add));
      await tester.pumpAndSettle();

      await tester.drag(grip, const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(toggles, [true]);

      await tester.drag(grip, const Offset(0, -40));
      await tester.pumpAndSettle();
      expect(toggles, [true, false]);
    });

    testWidgets('with the keyboard open the handle dismisses it instead of collapsing the workstation', (tester) async {
      final toggles = <bool>[];
      await tester.pumpWidget(buildTestHarness(onToggled: toggles.add));
      await tester.pumpAndSettle();

      tester.view.viewInsets = const FakeViewPadding(bottom: 280.0);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      await tester.tap(grip);
      await tester.pumpAndSettle();
      expect(toggles, isEmpty);
    });
  });
}
