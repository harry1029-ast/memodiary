import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/widgets/writing_dock.dart';

void main() {
  group('WritingDock Collapse & Keyboard Interaction Tests', () {
    late QuillController controller;

    setUp(() {
      controller = QuillController.basic();
      controller.document.insert(0, 'Literati Journal\n');
    });

    tearDown(() {
      controller.dispose();
    });

    Widget buildTestHarness({
      double bottomViewInset = 0.0,
      bool initiallyCollapsed = false,
      ValueChanged<bool>? onCollapsedChanged,
    }) {
      return MaterialApp(
        theme: InkDiaryTheme.light,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              viewInsets: EdgeInsets.only(bottom: bottomViewInset),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: WritingDock(
                controller: controller,
                onPickImage: () {},
                onToggleDictation: () {},
                initiallyCollapsed: initiallyCollapsed,
                onCollapsedChanged: onCollapsedChanged,
                inkColor: const Color(0xFF2D2D2D),
                isPaperDark: false,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('dock renders expanded by default with collapse toggle handle', (tester) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      // Tool buttons are visible
      expect(find.byKey(const Key('writing_dock_format_btn')), findsOneWidget);
      expect(find.byKey(const Key('writing_dock_photo_btn')), findsOneWidget);
      expect(find.byKey(const Key('writing_dock_dictation_btn')), findsOneWidget);

      // Collapse toggle exists
      expect(find.byKey(const Key('writing_dock_collapse_toggle')), findsOneWidget);
    });

    testWidgets('tapping collapse toggle collapses dock into slim bottom tab', (tester) async {
      bool? latestCollapsed;
      await tester.pumpWidget(buildTestHarness(
        onCollapsedChanged: (collapsed) => latestCollapsed = collapsed,
      ));
      await tester.pumpAndSettle();

      // Tap collapse toggle
      await tester.tap(find.byKey(const Key('writing_dock_collapse_toggle')));
      await tester.pumpAndSettle();

      expect(latestCollapsed, isTrue);

      // Tools should now be hidden
      expect(find.byKey(const Key('writing_dock_format_btn')), findsNothing);
      expect(find.byKey(const Key('writing_dock_photo_btn')), findsNothing);

      // Collapsed tab is displayed
      expect(find.byKey(const Key('writing_dock_collapsed_tab')), findsOneWidget);

      // Tap collapsed tab to restore
      await tester.tap(find.byKey(const Key('writing_dock_collapsed_tab')));
      await tester.pumpAndSettle();

      expect(latestCollapsed, isFalse);
      expect(find.byKey(const Key('writing_dock_format_btn')), findsOneWidget);
    });

    testWidgets('downward drag gesture collapses dock', (tester) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      // Drag downward on the toggle handle
      await tester.drag(
        find.byKey(const Key('writing_dock_collapse_toggle')),
        const Offset(0, 50),
      );
      await tester.pumpAndSettle();

      // Should now be collapsed
      expect(find.byKey(const Key('writing_dock_collapsed_tab')), findsOneWidget);
      expect(find.byKey(const Key('writing_dock_format_btn')), findsNothing);
    });

    testWidgets('auto-expands when keyboard appears and returns to collapsed when dismissed', (tester) async {
      // Start collapsed
      await tester.pumpWidget(buildTestHarness(
        bottomViewInset: 0.0,
        initiallyCollapsed: true,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('writing_dock_collapsed_tab')), findsOneWidget);
      expect(find.byKey(const Key('writing_dock_format_btn')), findsNothing);

      // Soft keyboard appears (viewInsets.bottom = 280)
      await tester.pumpWidget(buildTestHarness(
        bottomViewInset: 280.0,
        initiallyCollapsed: true,
      ));
      await tester.pumpAndSettle();

      // Tools auto-reveal above the keyboard
      expect(find.byKey(const Key('writing_dock_format_btn')), findsOneWidget);
      expect(find.byKey(const Key('writing_dock_photo_btn')), findsOneWidget);

      // Soft keyboard dismisses (viewInsets.bottom = 0)
      await tester.pumpWidget(buildTestHarness(
        bottomViewInset: 0.0,
        initiallyCollapsed: true,
      ));
      await tester.pumpAndSettle();

      // Automatically returns to collapsed tab
      expect(find.byKey(const Key('writing_dock_collapsed_tab')), findsOneWidget);
      expect(find.byKey(const Key('writing_dock_format_btn')), findsNothing);
    });
  });
}

