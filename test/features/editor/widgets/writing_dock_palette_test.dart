import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/features/editor/widgets/writing_dock.dart';

void main() {
  group('WritingDock Semantic Scholar Palette & Contrast Tests', () {
    late QuillController controller;

    setUp(() {
      controller = QuillController.basic();
    });

    tearDown(() {
      controller.dispose();
    });

    Widget buildTestHarness({
      required ThemeData theme,
      required bool isPaperDark,
      required Color inkColor,
    }) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: WritingDock(
              controller: controller,
              onPickImage: () {},
              onToggleDictation: () {},
              onShuffleSpark: () {},
              isPaperDark: isPaperDark,
              inkColor: inkColor,
            ),
          ),
        ),
      );
    }

    testWidgets('adapts icon colors on light paper and displays semantic accents', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          theme: ThemeData.dark(), // System is in dark theme!
          isPaperDark: false, // Paper is light!
          inkColor: const Color(0xFF2D2D2D),
        ),
      );
      await tester.pumpAndSettle();

      // Voice dictation should use cinnabar accent (#B83B2E)
      final micIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('writing_dock_dictation_btn')),
          matching: find.byType(Icon),
        ),
      );
      expect(micIcon.color, equals(const Color(0xFFB83B2E)));

      // Thought spark should use amber gold (#D4AF37)
      final sparkIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('writing_dock_spark_btn')),
          matching: find.byType(Icon),
        ),
      );
      expect(sparkIcon.color, equals(const Color(0xFFD4AF37)));

      // Photo button should use deep ink, NOT dark mode nongmo (#DCD6CA)
      final photoIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('writing_dock_photo_btn')),
          matching: find.byType(Icon),
        ),
      );
      expect(photoIcon.color, equals(const Color(0xFF2D2D2D)));
    });

    testWidgets('adapts icon colors on dark paper', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          theme: ThemeData.light(),
          isPaperDark: true, // Paper is dark!
          inkColor: const Color(0xFFF0ECE3),
        ),
      );
      await tester.pumpAndSettle();

      // Photo button should use light parchment ink
      final photoIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('writing_dock_photo_btn')),
          matching: find.byType(Icon),
        ),
      );
      expect(photoIcon.color, equals(const Color(0xFFF0ECE3)));
    });
  });
}
