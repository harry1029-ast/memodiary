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
    }) {
      return MaterialApp(
        theme: InkDiaryTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: WritingDock(
              controller: controller,
              onPickImage: onPickImage ?? () {},
              onPickVideo: onPickVideo,
              onToggleDictation: onToggleDictation ?? () {},
              onShuffleSpark: onShuffleSpark,
              isDictating: isDictating,
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
  });
}

