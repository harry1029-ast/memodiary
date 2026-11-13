import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memodiary/core/theme/ink_diary_theme.dart';
import 'package:memodiary/features/editor/widgets/writing_dock.dart';

void main() {
  group('WritingDock Widget Tests', () {
    late QuillController controller;

    setUp(() {
      controller = QuillController.basic();
      controller.document.insert(0, 'Hello Literati World\n');
      controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 5),
        ChangeSource.local,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    Widget buildTestWidget({
      VoidCallback? onPickImage,
      VoidCallback? onPickVideo,
      VoidCallback? onToggleDictation,
      VoidCallback? onShuffleSpark,
      bool isDictating = false,
      bool initialFormattingOpen = false,
      VoidCallback? onToggleFormatting,
    }) {
      var isFormattingOpen = initialFormattingOpen;
      return MaterialApp(
        theme: InkDiaryTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: StatefulBuilder(
              builder: (context, setState) {
                return WritingDock(
                  controller: controller,
                  onPickImage: onPickImage ?? () {},
                  onPickVideo: onPickVideo,
                  onToggleDictation: onToggleDictation ?? () {},
                  onShuffleSpark: onShuffleSpark,
                  isFormattingOpen: isFormattingOpen,
                  onToggleFormatting: onToggleFormatting ??
                      () => setState(() => isFormattingOpen = !isFormattingOpen),
                  isDictating: isDictating,
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('renders all 5 primary tools in Tier 1', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onPickVideo: () {},
        onShuffleSpark: () {},
      ));
      await tester.pumpAndSettle();

      // Check 5 primary tools
      expect(find.byKey(const Key('writing_dock_format_btn')), findsOneWidget);
      expect(find.byKey(const Key('writing_dock_photo_btn')), findsOneWidget);
      expect(find.byKey(const Key('writing_dock_video_btn')), findsOneWidget);
      expect(find.byKey(const Key('writing_dock_dictation_btn')), findsOneWidget);
      expect(find.byKey(const Key('writing_dock_spark_btn')), findsOneWidget);
    });

    testWidgets('tapping Aa expands and collapses the inline formatting ribbon', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Ribbon is initially closed
      expect(find.text('B'), findsNothing);
      expect(find.text('I'), findsNothing);

      // Tap Aa button
      await tester.tap(find.byKey(const Key('writing_dock_format_btn')));
      await tester.pumpAndSettle();

      // Ribbon is now visible
      expect(find.text('B'), findsOneWidget);
      expect(find.text('I'), findsOneWidget);

      // Tap Aa button again to collapse
      await tester.tap(find.byKey(const Key('writing_dock_format_btn')));
      await tester.pumpAndSettle();

      expect(find.text('B'), findsNothing);
    });

    testWidgets('tapping Bold in formatting ribbon applies bold format', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open formatting ribbon
      await tester.tap(find.byKey(const Key('writing_dock_format_btn')));
      await tester.pumpAndSettle();

      // Tap Bold
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();

      final style = controller.getSelectionStyle();
      expect(style.containsKey(Attribute.bold.key), isTrue);
    });

    testWidgets('media, dictation, and spark callbacks trigger properly', (tester) async {
      bool photoPicked = false;
      bool videoPicked = false;
      bool dictationToggled = false;
      bool sparkShuffled = false;

      await tester.pumpWidget(buildTestWidget(
        onPickImage: () => photoPicked = true,
        onPickVideo: () => videoPicked = true,
        onToggleDictation: () => dictationToggled = true,
        onShuffleSpark: () => sparkShuffled = true,
      ));
      await tester.pumpAndSettle();

      // Photo
      await tester.tap(find.byKey(const Key('writing_dock_photo_btn')));
      expect(photoPicked, isTrue);

      // Video
      await tester.tap(find.byKey(const Key('writing_dock_video_btn')));
      expect(videoPicked, isTrue);

      // Dictation
      await tester.tap(find.byKey(const Key('writing_dock_dictation_btn')));
      expect(dictationToggled, isTrue);

      // Spark
      await tester.tap(find.byKey(const Key('writing_dock_spark_btn')));
      expect(sparkShuffled, isTrue);
    });

    testWidgets('formatting ribbon contains interlinear note action with accessible semantics', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open formatting ribbon
      await tester.tap(find.byKey(const Key('writing_dock_format_btn')));
      await tester.pumpAndSettle();

      final noteBtnFinder = find.byKey(const Key('writing_dock_interlinear_note_btn'));
      expect(noteBtnFinder, findsOneWidget);
      expect(find.text('〘注〙'), findsOneWidget);

      final iconBtn = tester.widget<IconButton>(noteBtnFinder);
      expect(iconBtn.tooltip, equals('双行夹注 · Interlinear Note'));
    });

    testWidgets('tapping interlinear note at collapsed cursor inserts {夹注:} and positions cursor inside at offset + 4', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open formatting ribbon
      await tester.tap(find.byKey(const Key('writing_dock_format_btn')));
      await tester.pumpAndSettle();

      // Collapse selection at offset 6 (after "Hello ")
      controller.updateSelection(
        const TextSelection.collapsed(offset: 6),
        ChangeSource.local,
      );

      // Tap interlinear note button
      await tester.tap(find.byKey(const Key('writing_dock_interlinear_note_btn')));
      await tester.pumpAndSettle();

      final plainText = controller.document.toPlainText();
      expect(plainText, startsWith('Hello {夹注:}Literati World'));
      expect(controller.selection.isCollapsed, isTrue);
      // Offset was 6, insertion is {夹注:}, caret placed at offset + 4 = 10
      expect(controller.selection.baseOffset, equals(10));
    });

    testWidgets('tapping interlinear note with active selection wraps selected text and positions cursor after brace', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open formatting ribbon
      await tester.tap(find.byKey(const Key('writing_dock_format_btn')));
      await tester.pumpAndSettle();

      // Selection is [0, 5] -> "Hello"
      controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 5),
        ChangeSource.local,
      );

      // Tap interlinear note button
      await tester.tap(find.byKey(const Key('writing_dock_interlinear_note_btn')));
      await tester.pumpAndSettle();

      final plainText = controller.document.toPlainText();
      expect(plainText, startsWith('{夹注:Hello} Literati World'));
      expect(controller.selection.isCollapsed, isTrue);
      // Wrapped "{夹注:Hello}". Length is 11, cursor after '}' at index 11
      expect(controller.selection.baseOffset, equals('{夹注:Hello}'.length));
    });

    testWidgets('omitted optional callbacks do not crash and isFormattingOpen controls ribbon directly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: InkDiaryTheme.light,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: WritingDock(
                controller: controller,
                onPickImage: () {},
                onToggleDictation: () {},
                isFormattingOpen: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('B'), findsOneWidget);
      expect(find.byKey(const Key('writing_dock_video_btn')), findsNothing);
      expect(find.byKey(const Key('writing_dock_spark_btn')), findsNothing);

      // Tapping format button when onToggleFormatting is omitted is a safe no-op.
      await tester.tap(find.byKey(const Key('writing_dock_format_btn')));
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);
    });
  });
}

